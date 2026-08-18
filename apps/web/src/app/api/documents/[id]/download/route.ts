import { z } from "zod";
import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";

/**
 * Taranmış ve temiz çıkmış belge için kısa ömürlü imzalı bağlantı üretir.
 *
 * Karantinadaki dosya doğrudan sunulmaz: `scan_status` `clean` değilse bağlantı
 * hiç üretilmez. Bağlantı 120 saniye geçerlidir ve loglanmaz.
 */
export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const id = z.uuid().parse((await params).id);

    const document = await context.supabase
      .from("documents")
      .select("storage_path,scan_status,file_name")
      .eq("id", id)
      .eq("workspace_id", context.workspaceId)
      .single();
    if (document.error || !document.data)
      return Response.json({ error: "Belge bulunamadı." }, { status: 404 });
    if (document.data.scan_status !== "clean")
      return Response.json(
        {
          error: "Belge henüz taranmadı ya da güvenli bulunmadı; indirilemez.",
        },
        { status: 409 },
      );

    const signed = await context.supabase.storage
      .from("document-quarantine")
      .createSignedUrl(document.data.storage_path, 120);
    if (signed.error) throw signed.error;

    // Mobil istemci 303'ü kullanamaz: `http` paketi yönlendirmeyi izler ve
    // gelen dosyayı JSON diye çözmeye çalışır (KVKK dışa aktarmasıyla aynı
    // gerekçe).
    if (request.headers.get("accept")?.includes("application/json")) {
      return Response.json({
        url: signed.data.signedUrl,
        fileName: document.data.file_name,
        expiresIn: 120,
      });
    }
    return Response.redirect(signed.data.signedUrl, 303);
  } catch (error) {
    return apiError(error);
  }
}
