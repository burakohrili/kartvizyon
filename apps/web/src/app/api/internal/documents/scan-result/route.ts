import { z } from "zod";
import { hasInternalSecret } from "@/lib/internal-auth";
import { createSupabaseAdminClient } from "@/lib/supabase/admin";

const inputSchema = z.object({
  documentId: z.uuid(),
  sha256: z.string().regex(/^[a-f0-9]{64}$/),
  status: z.enum(["clean", "blocked", "failed"]),
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
  const input = inputSchema.safeParse(await request.json());
  if (!input.success)
    return Response.json({ error: "Geçersiz tarama sonucu." }, { status: 400 });
  const document = await supabase
    .from("documents")
    .select("id,workspace_id,organization_id,sha256,scan_status")
    .eq("id", input.data.documentId)
    .single();
  if (document.error || !document.data)
    return Response.json({ error: "Belge bulunamadı." }, { status: 404 });
  if (document.data.sha256 !== input.data.sha256)
    return Response.json({ error: "Dosya özeti uyuşmuyor." }, { status: 409 });
  const updated = await supabase
    .from("documents")
    .update({ scan_status: input.data.status })
    .eq("id", input.data.documentId)
    .eq("scan_status", "pending");
  if (updated.error)
    return Response.json({ error: updated.error.message }, { status: 500 });
  await supabase.from("audit_logs").insert({
    organization_id: document.data.organization_id,
    workspace_id: document.data.workspace_id,
    actor_id: null,
    action: `document.scan_${input.data.status}`,
    resource_type: "document",
    resource_id: input.data.documentId,
  });
  return Response.json({ ok: true, status: input.data.status });
}
