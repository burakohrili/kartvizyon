import { createHash, randomUUID } from "node:crypto";
import { z } from "zod";
import { apiError } from "@/lib/api";
import { assertQuota } from "@/lib/entitlements";
import {
  summarizeVisitTranscript,
  transcribeVisitAudio,
  visitAiLimits,
} from "@/lib/openai/visit-ai";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export const runtime = "nodejs";

const transcriptSchema = z.string().trim().min(10).max(20_000);
const mutationIdSchema = z.uuid();

function extensionFor(mime: string) {
  return (
    {
      "audio/webm": "webm",
      "audio/mp4": "m4a",
      "audio/x-m4a": "m4a",
      "audio/mpeg": "mp3",
      "audio/wav": "wav",
    }[mime] ?? "bin"
  );
}

export async function POST(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const { id } = await params;
  let supabase: Awaited<ReturnType<typeof createSupabaseServerClient>> = null;
  let userId: string | null = null;
  let submissionId: string | null = null;
  let visit: {
    id: string;
    workspace_id: string;
    organization_id: string | null;
    representative_id: string;
  } | null = null;

  try {
    supabase = await createSupabaseServerClient(request);
    if (supabase) {
      const { data } = await supabase.auth.getUser();
      userId = data.user?.id ?? null;
      if (!userId)
        return Response.json({ error: "Oturum gerekli." }, { status: 401 });

      const visitResult = await supabase
        .from("visits")
        .select("id,workspace_id,organization_id,representative_id")
        .eq("id", id)
        .eq("representative_id", userId)
        .single();
      visit = visitResult.data;
      if (!visit)
        return Response.json({ error: "Ziyaret bulunamadı." }, { status: 404 });
    } else if (!id.startsWith("demo-")) {
      return Response.json(
        {
          error:
            "Supabase bağlantısı olmadan yalnızca demo akışı kullanılabilir.",
        },
        { status: 503 },
      );
    }

    const form = await request.formData();
    const clientMutationId = mutationIdSchema.parse(
      form.get("clientMutationId"),
    );

    if (supabase && userId && visit) {
      const existing = await supabase
        .from("debrief_submissions")
        .select("id,status,response")
        .eq("user_id", userId)
        .eq("client_mutation_id", clientMutationId)
        .maybeSingle();
      if (existing.data?.status === "completed" && existing.data.response) {
        return Response.json(existing.data.response);
      }
      if (existing.data?.status === "processing") {
        return Response.json(
          { error: "Bu not zaten işleniyor; kısa süre sonra tekrar deneyin." },
          { status: 409 },
        );
      }

      const submission = await supabase
        .from("debrief_submissions")
        .upsert(
          {
            visit_id: visit.id,
            workspace_id: visit.workspace_id,
            organization_id: visit.organization_id,
            user_id: userId,
            client_mutation_id: clientMutationId,
            status: "processing",
            response: null,
            error_code: null,
          },
          { onConflict: "user_id,client_mutation_id" },
        )
        .select("id")
        .single();
      if (submission.error) throw submission.error;
      submissionId = submission.data.id;
    }

    const audio = form.get("audio");
    const manualTranscript = form.get("transcript");
    let transcript =
      typeof manualTranscript === "string" && manualTranscript.trim()
        ? transcriptSchema.parse(manualTranscript)
        : "";
    let audioAssetId: string | null = null;
    let transcriptionModel: string | null = null;

    if (audio instanceof File && audio.size > 0) {
      if (audio.size > visitAiLimits.maxAudioBytes) {
        return Response.json(
          { error: "Ses dosyası en fazla 25 MB olabilir." },
          { status: 413 },
        );
      }
      if (!visitAiLimits.acceptedAudioTypes.has(audio.type)) {
        return Response.json(
          { error: "Ses biçimi desteklenmiyor." },
          { status: 415 },
        );
      }
      // AI dakika kotası yalnız ses işlemede uygulanır; metin notu ve manuel
      // ziyaret kaydı kotadan bağımsız çalışmaya devam eder (offline ilkesi).
      if (supabase && visit) {
        const quotaDenied = await assertQuota(
          {
            supabase,
            workspaceId: visit.workspace_id,
            organizationId: visit.organization_id,
          },
          "ai_minutes",
        );
        if (quotaDenied) return quotaDenied;
      }

      const bytes = Buffer.from(await audio.arrayBuffer());
      const sha256 = createHash("sha256").update(bytes).digest("hex");

      if (supabase && userId && visit) {
        const storagePath = `${userId}/${visit.id}/${randomUUID()}.${extensionFor(audio.type)}`;
        const upload = await supabase.storage
          .from(process.env.SUPABASE_AUDIO_BUCKET ?? "visit-audio")
          .upload(storagePath, bytes, {
            contentType: audio.type,
            upsert: false,
          });
        if (upload.error) throw upload.error;
        const asset = await supabase
          .from("visit_audio_assets")
          .insert({
            visit_id: visit.id,
            workspace_id: visit.workspace_id,
            organization_id: visit.organization_id,
            owner_id: userId,
            storage_path: storagePath,
            mime_type: audio.type,
            byte_size: audio.size,
            sha256,
          })
          .select("id")
          .single();
        if (asset.error) throw asset.error;
        audioAssetId = asset.data.id;
      }

      const transcription = await transcribeVisitAudio(audio);
      transcript = transcriptSchema.parse(transcription.text);
      transcriptionModel = transcription.model;
    }

    transcript = transcriptSchema.parse(transcript);
    const generated = await summarizeVisitTranscript(transcript);

    if (supabase && userId && visit) {
      const transcriptResult = await supabase.from("visit_transcripts").upsert(
        {
          visit_id: visit.id,
          audio_asset_id: audioAssetId,
          workspace_id: visit.workspace_id,
          organization_id: visit.organization_id,
          owner_id: userId,
          transcript,
          language: "tr",
          provider: "openai",
          model: transcriptionModel,
          updated_at: new Date().toISOString(),
        },
        { onConflict: "visit_id" },
      );
      if (transcriptResult.error) throw transcriptResult.error;

      const visitResult = await supabase
        .from("visits")
        .update({
          ai_summary: generated.summary,
          ai_schema_version: "visit-summary.v1",
          status: "needs_review",
          completed_at: new Date().toISOString(),
        })
        .eq("id", visit.id)
        .eq("representative_id", userId);
      if (visitResult.error) throw visitResult.error;

      const jobs = [
        ...(transcriptionModel
          ? [{ kind: "transcription", model: transcriptionModel }]
          : []),
        { kind: "visit_summary", model: generated.model },
      ].map((job) => ({
        visit_id: visit!.id,
        audio_asset_id: audioAssetId,
        workspace_id: visit!.workspace_id,
        organization_id: visit!.organization_id,
        user_id: userId,
        kind: job.kind,
        status: "completed",
        model: job.model,
        attempts: 1,
        started_at: new Date().toISOString(),
        completed_at: new Date().toISOString(),
      }));
      await supabase.from("ai_jobs").insert(jobs);

      const usageRows = [
        ["input_tokens", generated.usage.inputTokens],
        ["output_tokens", generated.usage.outputTokens],
      ]
        .filter(([, quantity]) => Number(quantity) > 0)
        .map(([metric, quantity]) => ({
          workspace_id: visit!.workspace_id,
          organization_id: visit!.organization_id,
          user_id: userId,
          visit_id: visit!.id,
          metric,
          quantity,
          unit: "token",
          provider: "openai",
          model: generated.model,
        }));
      if (usageRows.length)
        await supabase.from("usage_records").insert(usageRows);
    }

    const responsePayload = {
      visitId: id,
      status: "needs_review",
      transcript,
      summary: generated.summary,
      reviewUrl: `/visits/${id}/review`,
    };
    if (supabase && submissionId) {
      await supabase
        .from("debrief_submissions")
        .update({
          status: "completed",
          response: responsePayload,
          completed_at: new Date().toISOString(),
        })
        .eq("id", submissionId);
    }
    return Response.json(responsePayload);
  } catch (error) {
    if (supabase && userId && visit) {
      await supabase
        .from("visits")
        .update({ status: "draft" })
        .eq("id", visit.id)
        .eq("representative_id", userId);
      if (submissionId) {
        await supabase
          .from("debrief_submissions")
          .update({ status: "failed", error_code: "processing_failed" })
          .eq("id", submissionId);
      }
    }
    return apiError(error);
  }
}
