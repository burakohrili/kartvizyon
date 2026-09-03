import { randomUUID } from "node:crypto";
import { plannedVisitCreateSchema } from "@kartvizyon/contracts";
import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";

export async function GET(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const from =
      new URL(request.url).searchParams.get("from") ?? new Date().toISOString();
    const until =
      new URL(request.url).searchParams.get("to") ??
      new Date(Date.now() + 30 * 86400000).toISOString();
    const [visits, tasks] = await Promise.all([
      context.supabase
        .from("visits")
        .select(
          "id,purpose,planned_start_at,planned_end_at,status,company:companies(name,display_name)",
        )
        .eq("workspace_id", context.workspaceId)
        .gte("planned_start_at", from)
        .lte("planned_start_at", until)
        .order("planned_start_at"),
      context.supabase
        .from("tasks")
        .select("id,title,due_at,status,company:companies(name,display_name)")
        .eq("workspace_id", context.workspaceId)
        .gte("due_at", from)
        .lte("due_at", until)
        .order("due_at"),
    ]);
    if (visits.error) throw visits.error;
    if (tasks.error) throw tasks.error;
    return Response.json({ visits: visits.data, tasks: tasks.data });
  } catch (error) {
    return apiError(error);
  }
}

export async function POST(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const input = plannedVisitCreateSchema.parse(await request.json());
    if (input.workspaceId !== context.workspaceId)
      return Response.json(
        { error: "Çalışma alanı uyuşmuyor." },
        { status: 403 },
      );
    const { data, error } = await context.supabase
      .from("visits")
      .insert({
        workspace_id: context.workspaceId,
        organization_id: context.organizationId,
        company_id: input.companyId,
        representative_id: input.representativeId,
        client_mutation_id: randomUUID(),
        purpose: input.purpose,
        planned_start_at: input.plannedStartAt,
        planned_end_at: input.plannedEndAt,
        status: "draft",
      })
      .select("*")
      .single();
    if (error) throw error;
    return Response.json({ data }, { status: 201 });
  } catch (error) {
    return apiError(error);
  }
}
