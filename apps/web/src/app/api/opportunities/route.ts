import {
  opportunityCreateSchema,
  opportunityStageSchema,
} from "@kartvizyon/contracts";
import { z } from "zod";
import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";

const updateSchema = z.object({
  id: z.uuid(),
  stage: opportunityStageSchema,
  lossReason: z.string().trim().max(500).nullable().optional(),
});

export async function GET(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const { data, error } = await context.supabase
      .from("opportunities")
      .select("*,company:companies(name,display_name)")
      .eq("workspace_id", context.workspaceId)
      .order("updated_at", { ascending: false });
    if (error) throw error;
    return Response.json({ data });
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
    const input = updateSchema.parse(await request.json());
    const closed = input.stage === "won" || input.stage === "lost";
    const { data, error } = await context.supabase
      .from("opportunities")
      .update({
        stage: input.stage,
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
