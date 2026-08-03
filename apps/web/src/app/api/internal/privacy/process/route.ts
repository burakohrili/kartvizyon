import { hasInternalSecret } from "@/lib/internal-auth";
import { createSupabaseAdminClient } from "@/lib/supabase/admin";

export const runtime = "nodejs";

export async function POST(request: Request) {
  if (
    !hasInternalSecret(request, "PRIVACY_WORKER_SECRET") &&
    !hasInternalSecret(request, "CRON_SECRET")
  )
    return Response.json({ error: "Yetkisiz." }, { status: 401 });
  const supabase = createSupabaseAdminClient();
  if (!supabase)
    return Response.json(
      { error: "Supabase admin bağlantısı yok." },
      { status: 503 },
    );
  const pending = await supabase
    .from("privacy_requests")
    .select("id,user_id,workspace_id,organization_id")
    .eq("kind", "export")
    .eq("status", "requested")
    .order("requested_at")
    .limit(10);
  if (pending.error)
    return Response.json({ error: pending.error.message }, { status: 500 });
  let ready = 0;
  let failed = 0;
  for (const item of pending.data ?? []) {
    await supabase
      .from("privacy_requests")
      .update({ status: "processing" })
      .eq("id", item.id)
      .eq("status", "requested");
    try {
      const [
        profile,
        memberships,
        companies,
        contacts,
        visits,
        createdTasks,
        assignedTasks,
        comments,
        consents,
        transcripts,
        audioAssets,
      ] = await Promise.all([
        supabase
          .from("profiles")
          .select("*")
          .eq("id", item.user_id)
          .maybeSingle(),
        supabase.from("memberships").select("*").eq("user_id", item.user_id),
        supabase
          .from("companies")
          .select("*")
          .eq("workspace_id", item.workspace_id)
          .eq("created_by", item.user_id),
        supabase
          .from("contacts")
          .select("*")
          .eq("workspace_id", item.workspace_id)
          .eq("created_by", item.user_id),
        supabase
          .from("visits")
          .select("*")
          .eq("workspace_id", item.workspace_id)
          .eq("representative_id", item.user_id),
        supabase
          .from("tasks")
          .select("*")
          .eq("workspace_id", item.workspace_id)
          .eq("created_by", item.user_id),
        supabase
          .from("tasks")
          .select("*")
          .eq("workspace_id", item.workspace_id)
          .eq("assigned_to", item.user_id),
        supabase
          .from("activity_comments")
          .select("*")
          .eq("workspace_id", item.workspace_id)
          .eq("author_id", item.user_id),
        supabase
          .from("user_consents")
          .select("*")
          .eq("workspace_id", item.workspace_id)
          .eq("user_id", item.user_id),
        supabase
          .from("visit_transcripts")
          .select("id,visit_id,transcript,language,created_at")
          .eq("workspace_id", item.workspace_id)
          .eq("owner_id", item.user_id),
        supabase
          .from("visit_audio_assets")
          .select(
            "id,visit_id,mime_type,size_bytes,duration_seconds,created_at,delete_after,deleted_at",
          )
          .eq("workspace_id", item.workspace_id)
          .eq("owner_id", item.user_id),
      ]);
      const errors = [
        profile,
        memberships,
        companies,
        contacts,
        visits,
        createdTasks,
        assignedTasks,
        comments,
        consents,
        transcripts,
        audioAssets,
      ]
        .map((result) => result.error)
        .filter(Boolean);
      if (errors.length) throw errors[0];
      const tasks = new Map<string, unknown>();
      for (const task of [
        ...(createdTasks.data ?? []),
        ...(assignedTasks.data ?? []),
      ])
        tasks.set(task.id, task);
      const exportData = {
        schemaVersion: "1.0",
        generatedAt: new Date().toISOString(),
        requestId: item.id,
        profile: profile.data,
        memberships: memberships.data,
        companies: companies.data,
        contacts: contacts.data,
        visits: visits.data,
        tasks: [...tasks.values()],
        comments: comments.data,
        consents: consents.data,
        transcripts: transcripts.data,
        audioMetadata: audioAssets.data,
      };
      const path = `${item.user_id}/${item.id}.json`;
      const upload = await supabase.storage
        .from("privacy-exports")
        .upload(path, Buffer.from(JSON.stringify(exportData, null, 2)), {
          contentType: "application/json",
          upsert: true,
        });
      if (upload.error) throw upload.error;
      const update = await supabase
        .from("privacy_requests")
        .update({
          status: "ready",
          export_storage_path: path,
          completed_at: new Date().toISOString(),
        })
        .eq("id", item.id);
      if (update.error) throw update.error;
      ready += 1;
    } catch (error) {
      await supabase
        .from("privacy_requests")
        .update({ status: "requested" })
        .eq("id", item.id);
      console.error(
        JSON.stringify({
          level: "error",
          event: "privacy.export_failed",
          requestId: item.id,
          error: error instanceof Error ? error.message : "unknown",
        }),
      );
      failed += 1;
    }
  }
  return Response.json({
    processed: (pending.data ?? []).length,
    ready,
    failed,
  });
}

export const GET = POST;
