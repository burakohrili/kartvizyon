import { apiError, serviceUnavailable } from "@/lib/api";
import { createSupabaseServerClient } from "@/lib/supabase/server";

/**
 * İnceleme bekleyen ziyaretin AI çıktısını reddeder.
 *
 * Onay ekranının tek çıkışı "Onayla ve hafızaya ekle" idi. AI özeti işe
 * yaramaz çıktığında kullanıcının yapabileceği bir şey yoktu ve ziyaret
 * sonsuza kadar `needs_review` durumunda kalıyordu.
 *
 * Reddedilen ziyaret **silinmez**: not ve transkript yerinde kalır, ziyaret
 * `rejected` olur ve kurumsal hafızaya girmez. Böylece "AI çıktısı kullanıcı
 * onayı olmadan kayda geçmez" ilkesi iki yönde de çalışır.
 */
export async function POST(
  request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const { id } = await params;
    const supabase = await createSupabaseServerClient(request);
    if (!supabase) return serviceUnavailable();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user)
      return Response.json({ error: "Oturum gerekli." }, { status: 401 });

    const { data, error } = await supabase
      .from("visits")
      .update({ status: "rejected" })
      .eq("id", id)
      .eq("representative_id", user.id)
      // Yalnız inceleme bekleyen ziyaret reddedilebilir; onaylanmış bir
      // ziyaret bu yoldan geri alınamaz.
      .eq("status", "needs_review")
      .select("id,status")
      .single();
    if (error) return apiError(error);
    return Response.json({ data });
  } catch (error) {
    return apiError(error);
  }
}
