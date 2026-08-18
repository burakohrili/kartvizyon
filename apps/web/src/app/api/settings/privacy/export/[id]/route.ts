import { z } from "zod";
import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";

export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const id = z.uuid().parse((await params).id);
    const privacyRequest = await context.supabase
      .from("privacy_requests")
      .select("export_storage_path,status")
      .eq("id", id)
      .eq("workspace_id", context.workspaceId)
      .eq("user_id", context.user.id)
      .eq("kind", "export")
      .single();
    if (
      privacyRequest.error ||
      privacyRequest.data.status !== "ready" ||
      !privacyRequest.data.export_storage_path
    )
      return Response.json(
        { error: "Dışa aktarma henüz hazır değil." },
        { status: 404 },
      );
    const signed = await context.supabase.storage
      .from("privacy-exports")
      .createSignedUrl(privacyRequest.data.export_storage_path, 60);
    if (signed.error) throw signed.error;

    // Mobil istemci 303'ü kullanamıyor: `http` paketi yönlendirmeyi izliyor ve
    // gelen dosyayı JSON diye çözmeye çalışıyor. JSON isteyen istemciye
    // bağlantının kendisi verilir, tarayıcı yönlendirmeye devam eder.
    if (request.headers.get("accept")?.includes("application/json")) {
      return Response.json({ url: signed.data.signedUrl, expiresIn: 60 });
    }
    return Response.redirect(signed.data.signedUrl, 303);
  } catch (error) {
    return apiError(error);
  }
}
