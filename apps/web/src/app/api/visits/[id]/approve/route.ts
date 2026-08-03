import { visitApprovalSchema } from "@kartvizyon/contracts";
import { apiError, serviceUnavailable } from "@/lib/api";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export async function POST(
  _request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  try {
    const { id } = await params;
    const input = visitApprovalSchema.parse({
      visitId: id,
      expectedStatus: "needs_review",
    });
    const supabase = await createSupabaseServerClient();
    if (!supabase) return serviceUnavailable();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user)
      return Response.json({ error: "Oturum gerekli." }, { status: 401 });

    const { data, error } = await supabase
      .from("visits")
      .update({
        status: "approved",
        approved_by: user.id,
        approved_at: new Date().toISOString(),
      })
      .eq("id", input.visitId)
      .eq("representative_id", user.id)
      .eq("status", input.expectedStatus)
      .select("id,status,approved_at")
      .single();
    if (error) return apiError(error);
    return Response.json({ data });
  } catch (error) {
    return apiError(error);
  }
}
