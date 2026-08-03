import { duplicateCheckSchema } from "@kartvizyon/contracts";
import { apiError, serviceUnavailable } from "@/lib/api";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export async function POST(request: Request) {
  try {
    const input = duplicateCheckSchema.parse(await request.json());
    const supabase = await createSupabaseServerClient();
    if (!supabase) return serviceUnavailable();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user)
      return Response.json({ error: "Oturum gerekli." }, { status: 401 });
    const { data, error } = await supabase.rpc("find_company_duplicates", {
      target_workspace_id: input.workspaceId,
      candidate_name: input.name,
      candidate_email: input.email ?? null,
      candidate_phone: input.phone ?? null,
    });
    if (error) return apiError(error);
    return Response.json({ data });
  } catch (error) {
    return apiError(error);
  }
}
