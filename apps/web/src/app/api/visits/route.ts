import { visitCreateSchema } from "@kartvizyon/contracts";
import { apiError, serviceUnavailable } from "@/lib/api";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export async function GET(request: Request) {
  const supabase = await createSupabaseServerClient(request);
  if (!supabase) return serviceUnavailable();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user)
    return Response.json({ error: "Oturum gerekli." }, { status: 401 });
  const url = new URL(request.url);
  const workspaceId = url.searchParams.get("workspaceId");
  const status = url.searchParams.get("status");
  if (!workspaceId)
    return Response.json({ error: "workspaceId gerekli." }, { status: 400 });
  let query = supabase
    .from("visits")
    .select(
      "id,status,purpose,planned_start_at,started_at,completed_at,approved_at,company:companies(id,name,display_name),representative:profiles!visits_representative_id_fkey(full_name)",
    )
    .eq("workspace_id", workspaceId)
    .order("created_at", { ascending: false })
    .limit(100);
  if (status) query = query.eq("status", status);
  const { data, error } = await query;
  if (error) return apiError(error);
  return Response.json({ data });
}

export async function POST(request: Request) {
  try {
    const input = visitCreateSchema.parse(await request.json());
    const supabase = await createSupabaseServerClient(request);
    if (!supabase) return serviceUnavailable();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user)
      return Response.json({ error: "Oturum gerekli." }, { status: 401 });

    const { data, error } = await supabase
      .from("visits")
      .insert({
        workspace_id: input.workspaceId,
        organization_id: input.organizationId,
        company_id: input.companyId,
        representative_id: user.id,
        client_mutation_id: input.clientMutationId,
        purpose: input.purpose,
        started_at: input.startedAt,
        status: "draft",
      })
      .select("id,status,created_at")
      .single();
    if (error) return apiError(error);
    return Response.json(
      { data, clientMutationId: input.clientMutationId },
      { status: 201 },
    );
  } catch (error) {
    return apiError(error);
  }
}
