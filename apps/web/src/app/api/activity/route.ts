import { apiError } from "@/lib/api";
import { getApiContext } from "@/lib/api-context";

type ActivityItem = {
  id: string;
  kind: "visit" | "task" | "opportunity" | "order";
  title: string;
  detail: string | null;
  occurredAt: string;
  resourceId: string;
};

export async function GET(request: Request) {
  try {
    const context = await getApiContext(request);
    if (!context.ok) return context.response;
    const [visits, tasks, opportunities, orders] = await Promise.all([
      context.supabase
        .from("visits")
        .select("id,purpose,completed_at,company:companies(name,display_name)")
        .eq("workspace_id", context.workspaceId)
        .not("completed_at", "is", null)
        .order("completed_at", { ascending: false })
        .limit(50),
      context.supabase
        .from("tasks")
        .select("id,title,completed_at,company:companies(name,display_name)")
        .eq("workspace_id", context.workspaceId)
        .not("completed_at", "is", null)
        .order("completed_at", { ascending: false })
        .limit(50),
      context.supabase
        .from("opportunities")
        .select(
          "id,title,stage,updated_at,company:companies(name,display_name)",
        )
        .eq("workspace_id", context.workspaceId)
        .order("updated_at", { ascending: false })
        .limit(50),
      context.supabase
        .from("order_drafts")
        .select("id,status,updated_at,company:companies(name,display_name)")
        .eq("workspace_id", context.workspaceId)
        .order("updated_at", { ascending: false })
        .limit(50),
    ]);
    for (const result of [visits, tasks, opportunities, orders]) {
      if (result.error) throw result.error;
    }
    const companyName = (row: Record<string, unknown>) => {
      const company = row.company as Record<string, unknown> | null;
      return String(company?.display_name ?? company?.name ?? "Müşteri");
    };
    const items: ActivityItem[] = [
      ...(visits.data ?? []).map((row) => ({
        id: `visit-${row.id}`,
        kind: "visit" as const,
        title: `${companyName(row)} ziyareti tamamlandı`,
        detail: row.purpose,
        occurredAt: row.completed_at!,
        resourceId: row.id,
      })),
      ...(tasks.data ?? []).map((row) => ({
        id: `task-${row.id}`,
        kind: "task" as const,
        title: `${row.title} görevi tamamlandı`,
        detail: companyName(row),
        occurredAt: row.completed_at!,
        resourceId: row.id,
      })),
      ...(opportunities.data ?? []).map((row) => ({
        id: `opportunity-${row.id}`,
        kind: "opportunity" as const,
        title: `${row.title} fırsatı güncellendi`,
        detail: String(row.stage),
        occurredAt: row.updated_at,
        resourceId: row.id,
      })),
      ...(orders.data ?? []).map((row) => ({
        id: `order-${row.id}`,
        kind: "order" as const,
        title: `${companyName(row)} sipariş taslağı güncellendi`,
        detail: String(row.status),
        occurredAt: row.updated_at,
        resourceId: row.id,
      })),
    ];
    items.sort((a, b) => b.occurredAt.localeCompare(a.occurredAt));
    return Response.json({ data: items.slice(0, 100) });
  } catch (error) {
    return apiError(error);
  }
}
