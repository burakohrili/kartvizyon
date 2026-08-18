import { apiError, serviceUnavailable } from "@/lib/api";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export async function GET(
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
      .select(
        "id,status,purpose,ai_summary,completed_at,company:companies(id,name)",
      )
      .eq("id", id)
      .eq("representative_id", user.id)
      .single();
    if (error) return apiError(error);

    // Onay ekranı özeti kaynağıyla karşılaştırabilsin diye transkript de
    // döner. "AI çıktısı siz onaylamadan hafızaya eklenmez" sözü, onaylayanın
    // neyi onayladığını görebilmesini gerektirir; ekran şimdiye kadar yalnız
    // AI'ın kendi özetini gösteriyordu.
    const transcript = await supabase
      .from("visit_transcripts")
      .select("transcript")
      .eq("visit_id", id)
      .maybeSingle();

    return Response.json({
      data: { ...data, transcript: transcript.data?.transcript ?? null },
    });
  } catch (error) {
    return apiError(error);
  }
}
