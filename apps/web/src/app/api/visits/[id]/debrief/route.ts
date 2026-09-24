import { createHash, randomUUID } from "node:crypto";
import { audioBucketName } from "@/lib/storage-config";
import { z } from "zod";
import { apiError } from "@/lib/api";
import { parseBuffer } from "music-metadata";
import { reserveAiQuota, finishAiQuota, releaseAiQuota } from "@/lib/ai-quota";
import {
  summarizeVisitTranscript,
  transcribeVisitAudio,
  visitAiLimits,
} from "@/lib/openai/visit-ai";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export const runtime = "nodejs";

const transcriptSchema = z.string().trim().min(10).max(20_000);
const mutationIdSchema = z.uuid();

/// Bir `processing` satırının hâlâ gerçekten işlendiği varsayılan süre.
/// Transkripsiyon + özet en kötü ihtimalle bunun çok altında sürer; üstünde
/// kalan satır takılmıştır ve yeniden denenebilir olmalıdır.
const staleProcessingMs = 10 * 60 * 1000;

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
  let visitTouched = false;
  let operationId: string | null = null;
  let visit: {
    id: string;
    workspace_id: string;
    organization_id: string | null;
    representative_id: string;
    company_id: string;
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
        .select("id,workspace_id,organization_id,representative_id,company_id")
        .eq("id", id)
        .eq("representative_id", userId)
        .single();
      visit = visitResult.data;
      if (!visit)
        return Response.json({ error: "Ziyaret bulunamadı." }, { status: 404 });
    } else {
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

    const submittedAudio = form.get("audio");
    const audio =
      submittedAudio instanceof File && submittedAudio.size > 0
        ? submittedAudio
        : null;
    const manualTranscript = form.get("transcript");
    let transcript =
      typeof manualTranscript === "string" && manualTranscript.trim()
        ? transcriptSchema.parse(manualTranscript)
        : "";
    let audioAssetId: string | null = null;
    let transcriptionModel: string | null = null;
    let audioDurationSeconds = 0;

    // Doğrulama, `debrief_submissions` satırı yazılmadan ÖNCE yapılır.
    //
    // Sıra daha önce tersti: satır `processing` olarak yazılıyor, ardından
    // 413/415/402 ile erken dönülüyordu. Bu dönüşler `try` içinde düz `return`
    // olduğu için satırı `failed` yapan `catch` hiç çalışmıyordu; satır
    // sonsuza kadar `processing` kalıyor ve aynı `clientMutationId` ile her
    // yeniden deneme 409 alıyordu. Mobil kuyrukta o kayıt kalıcı olarak
    // ölüyordu (18 Ağustos 2026, testçi ekranı: http_409, 5 deneme).
    if (audio) {
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
    }

    if (supabase && userId && visit) {
      const existing = await supabase
        .from("debrief_submissions")
        .select("id,status,response,created_at")
        .eq("user_id", userId)
        .eq("client_mutation_id", clientMutationId)
        .maybeSingle();
      if (existing.data?.status === "completed" && existing.data.response) {
        return Response.json(existing.data.response);
      }
      // 409 yalnız gerçekten süren bir işleme için döner. Süre aşılmışsa satır
      // takılmış demektir ve yeniden denemenin önü açılır. Bu, yukarıdaki sıra
      // düzeltmesinin emniyet kemeri: süreç çökmesi ya da ileride eklenecek bir
      // erken dönüş bir kaydı kalıcı olarak kilitleyemesin.
      if (
        existing.data?.status === "processing" &&
        Date.now() - Date.parse(String(existing.data.created_at)) <
          staleProcessingMs
      ) {
        return Response.json(
          { error: "Bu not zaten işleniyor; kısa süre sonra tekrar deneyin." },
          { status: 409 },
        );
      }

      if (audio) {
        const metadata = await parseBuffer(
          new Uint8Array(await audio.arrayBuffer()),
          { mimeType: audio.type, size: audio.size },
          { duration: true },
        );
        const duration = metadata.format.duration;
        if (!duration || !Number.isFinite(duration) || duration <= 0) {
          return Response.json(
            { error: "Ses süresi doğrulanamadı. Kaydı yeniden oluşturun." },
            { status: 422 },
          );
        }
        audioDurationSeconds = Math.ceil(duration);
      }
      const reservation = await reserveAiQuota({
        workspaceId: visit.workspace_id,
        userId,
        key: `debrief:${id}:${clientMutationId}`,
        summaries: 1,
        audioSeconds: audioDurationSeconds,
      });
      if (reservation.denied) return reservation.denied;
      if (reservation.operation.completed)
        return Response.json(reservation.operation.response);
      operationId = reservation.operation.id;

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
            // Takılmış satır penceresi bu denemeye göre ölçülür; aksi halde
            // eski `created_at` yüzünden pencere hep açık kalırdı.
            created_at: new Date().toISOString(),
          },
          { onConflict: "user_id,client_mutation_id" },
        )
        .select("id")
        .single();
      if (submission.error) throw submission.error;
      submissionId = submission.data.id;
    }

    if (audio) {
      const bytes = Buffer.from(await audio.arrayBuffer());
      const sha256 = createHash("sha256").update(bytes).digest("hex");

      if (supabase && userId && visit) {
        const storagePath = `${userId}/${visit.id}/${randomUUID()}.${extensionFor(audio.type)}`;
        const upload = await supabase.storage
          .from(audioBucketName())
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
    const [workspaceResult, customerResult, organizationResult] =
      await Promise.all([
        supabase
          .from("workspaces")
          .select("name")
          .eq("id", visit.workspace_id)
          .single(),
        supabase
          .from("companies")
          .select("name")
          .eq("id", visit.company_id)
          .eq("workspace_id", visit.workspace_id)
          .single(),
        visit.organization_id
          ? supabase
              .from("organizations")
              .select("name")
              .eq("id", visit.organization_id)
              .single()
          : Promise.resolve(null),
      ]);
    if (workspaceResult.error) throw workspaceResult.error;
    if (customerResult.error) throw customerResult.error;
    if (organizationResult?.error) throw organizationResult.error;
    const sourceName =
      organizationResult?.data?.name ?? workspaceResult.data.name;
    const generated = await summarizeVisitTranscript(transcript, {
      workspaceCompanyName: sourceName === "Kişisel Alanım" ? null : sourceName,
      customerCompanyName: customerResult.data.name,
    });

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

      visitTouched = true;
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
        ["audio_seconds", audioDurationSeconds],
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
          unit: metric === "audio_seconds" ? "second" : "token",
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
    if (operationId) await finishAiQuota(operationId, responsePayload);
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
    if (operationId) await releaseAiQuota(operationId);
    if (supabase && userId && visit) {
      // Ziyaret yalnız gerçekten dokunulduysa geri alınır. Önce koşulsuzdu ve
      // ses yüklemesinde patlayan bir istek, o ziyaretin daha önce üretilmiş
      // özetini de silip durumu `draft`a çekiyordu.
      if (visitTouched) {
        await supabase
          .from("visits")
          .update({ status: "draft" })
          .eq("id", visit.id)
          .eq("representative_id", userId);
      }
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
