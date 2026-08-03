import { z } from "zod";
import { hasInternalSecret } from "@/lib/internal-auth";
import { createSupabaseAdminClient } from "@/lib/supabase/admin";

export const runtime = "nodejs";

const requestSchema = z.object({
  limit: z.number().int().min(1).max(20).default(5),
});

export async function POST(request: Request) {
  if (!hasInternalSecret(request, "DOCUMENT_SCAN_SECRET"))
    return Response.json({ error: "Yetkisiz." }, { status: 401 });
  const supabase = createSupabaseAdminClient();
  if (!supabase)
    return Response.json(
      { error: "Supabase admin bağlantısı yok." },
      { status: 503 },
    );

  const parsed = requestSchema.safeParse(
    await request.json().catch(() => ({})),
  );
  if (!parsed.success)
    return Response.json({ error: "Geçersiz istek." }, { status: 400 });

  const claimed = await supabase.rpc("claim_document_scan_jobs", {
    batch_size: parsed.data.limit,
  });
  if (claimed.error)
    return Response.json({ error: claimed.error.message }, { status: 500 });

  const jobs = await Promise.all(
    (claimed.data ?? []).map(async (document: Record<string, unknown>) => {
      const signed = await supabase.storage
        .from("document-quarantine")
        .createSignedUrl(String(document.storage_path), 300);
      if (signed.error) {
        await supabase
          .from("documents")
          .update({
            scan_status: "failed",
            scan_completed_at: new Date().toISOString(),
            scan_error: "İmzalı tarama bağlantısı üretilemedi.",
          })
          .eq("id", document.id);
        return null;
      }
      return {
        documentId: document.id,
        sha256: document.sha256,
        mimeType: document.mime_type,
        sizeBytes: document.size_bytes,
        downloadUrl: signed.data.signedUrl,
      };
    }),
  );

  return Response.json({ jobs: jobs.filter(Boolean) });
}
