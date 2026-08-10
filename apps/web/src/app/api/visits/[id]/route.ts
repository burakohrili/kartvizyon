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
      .select("id,status,purpose,ai_summary,company:companies(id,name)")
      .eq("id", id)
      .eq("representative_id", user.id)
      .single();
    if (error) return apiError(error);
    return Response.json({ data });
  } catch (error) {
    return apiError(error);
  }
}
