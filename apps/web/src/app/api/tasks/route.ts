import { taskCreateSchema, taskStatusSchema } from "@kartvizyon/contracts";
import { z } from "zod";
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
  const companyId = url.searchParams.get("companyId");
  if (!workspaceId)
    return Response.json({ error: "workspaceId gerekli." }, { status: 400 });
  let query = supabase
    .from("tasks")
    .select(
      "id,title,status,due_at,company_id,visit_id,assigned_to,company:companies(name,display_name)",
    )
    .eq("workspace_id", workspaceId)
    // Tarihi olmayan görevler sona. Varsayılan sırada bunlar öngörülemeyen
    // yerlere düşüyordu; web sayfası zaten böyle sıralıyor.
    .order("due_at", { ascending: true, nullsFirst: false });
  if (companyId) query = query.eq("company_id", companyId);
  const { data, error } = await query;
  if (error) return apiError(error);
  return Response.json({ data });
}

export async function PATCH(request: Request) {
  try {
    const input = z
      .object({ id: z.uuid(), workspaceId: z.uuid(), status: taskStatusSchema })
      .parse(await request.json());
    const supabase = await createSupabaseServerClient(request);
    if (!supabase) return serviceUnavailable();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user)
      return Response.json({ error: "Oturum gerekli." }, { status: 401 });
    const { data, error } = await supabase
      .from("tasks")
      .update({
        status: input.status,
        completed_at:
          input.status === "completed" ? new Date().toISOString() : null,
      })
      .eq("id", input.id)
      .eq("workspace_id", input.workspaceId)
      .select("id,title,status,due_at")
      .single();
    if (error) return apiError(error);
    return Response.json({ data });
  } catch (error) {
    return apiError(error);
  }
}

export async function POST(request: Request) {
  try {
    const input = taskCreateSchema.parse(await request.json());
    const supabase = await createSupabaseServerClient(request);
    if (!supabase) return serviceUnavailable();
    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user)
      return Response.json({ error: "Oturum gerekli." }, { status: 401 });
    const { data, error } = await supabase
      .from("tasks")
      .insert({
        workspace_id: input.workspaceId,
        organization_id: input.organizationId,
        company_id: input.companyId,
        visit_id: input.visitId,
        title: input.title,
        due_at: input.dueAt,
        assigned_to: input.assignedTo ?? user.id,
        created_by: user.id,
      })
      .select("id,title,status,due_at")
      .single();
    if (error) return apiError(error);
    return Response.json({ data }, { status: 201 });
  } catch (error) {
    return apiError(error);
  }
}
