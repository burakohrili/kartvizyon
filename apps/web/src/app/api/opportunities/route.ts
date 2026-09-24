import {
  opportunityCreateSchema,
  opportunityUpdateSchema,
} from "@kartvizyon/contracts";
import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";

async function validCompany(
  context: Awaited<ReturnType<typeof getApiContext>> & { ok: true },
  companyId: string,
) {
  const result = await context.supabase
    .from("companies")
    .select("id")
    .eq("id", companyId)
    .eq("workspace_id", context.workspaceId)
    .is("archived_at", null)
    .maybeSingle();
  if (result.error) throw result.error;
  return !!result.data;
}

async function validOwner(
  context: Awaited<ReturnType<typeof getApiContext>> & { ok: true },
  ownerId: string | null | undefined,
) {
  if (!ownerId || ownerId === context.user.id) return true;
  if (!context.organizationId) return false;
  const result = await context.supabase
    .from("memberships")
    .select("id")
    .eq("organization_id", context.organizationId)
    .eq("user_id", ownerId)
    .is("revoked_at", null)
    .maybeSingle();
  if (result.error) throw result.error;
  return !!result.data;
}

export async function GET(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const [opportunities, memberships] = await Promise.all([
      context.supabase
        .from("opportunities")
        .select(
          "*,company:companies(id,name,display_name,address),owner:profiles!opportunities_assigned_to_fkey(full_name)",
        )
        .eq("workspace_id", context.workspaceId)
        .order("updated_at", { ascending: false }),
      context.organizationId
        ? context.supabase
            .from("memberships")
            .select("user_id,profile:profiles(full_name)")
            .eq("organization_id", context.organizationId)
            .is("revoked_at", null)
        : Promise.resolve({
            data: [
              {
                user_id: context.user.id,
                profile: { full_name: context.user.email ?? "Ben" },
              },
            ],
            error: null,
          }),
    ]);
    const { data, error } = opportunities;
    if (error) throw error;
    if (memberships.error) throw memberships.error;
    return Response.json({ data, owners: memberships.data });
  } catch (error) {
    return apiError(error);
  }
}

export async function POST(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const input = opportunityCreateSchema.parse(await request.json());
    if (input.workspaceId !== context.workspaceId)
      return Response.json(
        { error: "Çalışma alanı uyuşmuyor." },
        { status: 403 },
      );
    if (!(await validCompany(context, input.companyId)))
      return Response.json(
        { error: "Müşteri bu çalışma alanında bulunamadı." },
        { status: 400 },
      );
    if (!(await validOwner(context, input.assignedTo)))
      return Response.json(
        { error: "Sorumlu bu çalışma alanına ait değil." },
        { status: 400 },
      );
    const { data, error } = await context.supabase
      .from("opportunities")
      .insert({
        workspace_id: context.workspaceId,
        organization_id: context.organizationId,
        company_id: input.companyId,
        title: input.title,
        stage: input.stage,
        estimated_value: input.estimatedValue,
        currency: input.currency,
        probability: input.probability,
        expected_close_date: input.expectedCloseDate ?? null,
        competitor: input.competitor ?? null,
        assigned_to: input.assignedTo ?? context.user.id,
        created_by: context.user.id,
      })
      .select("*")
      .single();
    if (error) throw error;
    return Response.json({ data }, { status: 201 });
  } catch (error) {
    return apiError(error);
  }
}

export async function PATCH(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const input = opportunityUpdateSchema.parse(await request.json());
    if (!(await validOwner(context, input.assignedTo)))
      return Response.json(
        { error: "Sorumlu bu çalışma alanına ait değil." },
        { status: 400 },
      );
    const closed = input.stage === "won" || input.stage === "lost";
    const { data, error } = await context.supabase
      .from("opportunities")
      .update({
        title: input.title,
        stage: input.stage,
        estimated_value: input.estimatedValue,
        currency: input.currency,
        probability: input.probability,
        expected_close_date: input.expectedCloseDate ?? null,
        competitor: input.competitor ?? null,
        assigned_to: input.assignedTo ?? context.user.id,
        loss_reason: input.stage === "lost" ? (input.lossReason ?? null) : null,
        closed_at: closed ? new Date().toISOString() : null,
        updated_at: new Date().toISOString(),
      })
      .eq("id", input.id)
      .eq("workspace_id", context.workspaceId)
      .select("*")
      .single();
    if (error) throw error;
    return Response.json({ data });
  } catch (error) {
    return apiError(error);
  }
}
