import { createHash, randomUUID } from "node:crypto";
import { documentMetadataSchema } from "@kartvizyon/contracts";
import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";

export const runtime = "nodejs";

const allowed = new Set([
  "application/pdf",
  "image/jpeg",
  "image/png",
  "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
]);

function signatureMatches(bytes: Uint8Array, type: string) {
  if (type === "application/pdf")
    return String.fromCharCode(...bytes.slice(0, 5)) === "%PDF-";
  if (type === "image/jpeg")
    return bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff;
  if (type === "image/png")
    return (
      bytes[0] === 0x89 && String.fromCharCode(...bytes.slice(1, 4)) === "PNG"
    );
  if (type.includes("openxmlformats"))
    return bytes[0] === 0x50 && bytes[1] === 0x4b;
  return false;
}

export async function GET(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const { data, error } = await context.supabase
      .from("documents")
      .select(
        "id,file_name,mime_type,size_bytes,scan_status,company_id,visit_id,created_at",
      )
      .eq("workspace_id", context.workspaceId)
      .order("created_at", { ascending: false })
      .limit(200);
    if (error) throw error;
    return Response.json({ data });
  } catch (error) {
    return apiError(error);
  }
}

export async function POST(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const form = await request.formData();
    const file = form.get("file");
    if (!(file instanceof File))
      return Response.json({ error: "Dosya gerekli." }, { status: 400 });
    if (
      !allowed.has(file.type) ||
      file.size < 1 ||
      file.size > 20 * 1024 * 1024
    )
      return Response.json(
        { error: "Dosya tipi veya boyutu desteklenmiyor." },
        { status: 400 },
      );
    const bytes = new Uint8Array(await file.arrayBuffer());
    if (!signatureMatches(bytes, file.type))
      return Response.json(
        { error: "Dosya içeriği uzantıyla uyuşmuyor." },
        { status: 400 },
      );
    const sha256 = createHash("sha256").update(bytes).digest("hex");
    const extension =
      file.name
        .split(".")
        .pop()
        ?.replace(/[^a-z0-9]/gi, "")
        .toLowerCase() || "bin";
    const storagePath = `${context.user.id}/${randomUUID()}.${extension}`;
    const metadata = documentMetadataSchema.parse({
      workspaceId: context.workspaceId,
      companyId: form.get("companyId") || null,
      visitId: form.get("visitId") || null,
      fileName: file.name,
      mimeType: file.type,
      sizeBytes: file.size,
      sha256,
      storagePath,
    });
    const upload = await context.supabase.storage
      .from("document-quarantine")
      .upload(storagePath, bytes, { contentType: file.type, upsert: false });
    if (upload.error) throw upload.error;
    const { data, error } = await context.supabase
      .from("documents")
      .insert({
        workspace_id: context.workspaceId,
        organization_id: context.organizationId,
        company_id: metadata.companyId ?? null,
        visit_id: metadata.visitId ?? null,
        owner_id: context.user.id,
        file_name: metadata.fileName,
        mime_type: metadata.mimeType,
        size_bytes: metadata.sizeBytes,
        sha256: metadata.sha256,
        storage_path: metadata.storagePath,
        scan_status: "pending",
      })
      .select("id,file_name,scan_status,created_at")
      .single();
    if (error) {
      await context.supabase.storage
        .from("document-quarantine")
        .remove([storagePath]);
      throw error;
    }
    await context.supabase.from("usage_records").insert({
      organization_id: context.organizationId,
      workspace_id: context.workspaceId,
      user_id: context.user.id,
      metric: "storage_bytes",
      quantity: file.size,
      unit: "byte",
      provider: "kartvizyon",
      model: "document-upload",
    });
    return Response.json(
      {
        data,
        message:
          "Dosya karantinaya alındı; temiz tarama sonucu olmadan indirilemez.",
      },
      { status: 202 },
    );
  } catch (error) {
    return apiError(error);
  }
}
