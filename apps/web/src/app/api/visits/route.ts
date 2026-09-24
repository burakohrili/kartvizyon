import { visitCreateSchema } from "@kartvizyon/contracts";
import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";

export async function GET(request: Request) {
  const context = await getApiContext(request);
  if (!context.ok) return context.response;
  const url = new URL(request.url);
  const workspaceId = url.searchParams.get("workspaceId");
  const status = url.searchParams.get("status");
  if (!workspaceId)
    return Response.json({ error: "workspaceId gerekli." }, { status: 400 });
  if (workspaceId !== context.workspaceId)
    return Response.json(
      { error: "Çalışma alanı uyuşmuyor." },
      { status: 403 },
    );
  let query = context.supabase
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
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    if (input.workspaceId !== context.workspaceId) {
      return Response.json(
        { error: "Çalışma alanı uyuşmuyor." },
        { status: 403 },
      );
    }
    const company = await context.supabase
      .from("companies")
      .select("id")
      .eq("id", input.companyId)
      .eq("workspace_id", context.workspaceId)
      .is("archived_at", null)
      .maybeSingle();
    if (company.error) throw company.error;
    if (!company.data) {
      return Response.json(
        { error: "Müşteri bu çalışma alanında bulunamadı." },
        { status: 400 },
      );
    }

    const { data, error } = await context.supabase
      .from("visits")
      .insert({
        workspace_id: context.workspaceId,
        organization_id: context.organizationId,
        company_id: input.companyId,
        representative_id: context.user.id,
        client_mutation_id: input.clientMutationId,
        purpose: input.purpose,
        visit_type: input.visitType,
        planning_note: input.planningNote || null,
        planned_start_at: input.plannedStartAt,
        planned_end_at: input.plannedEndAt,
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
