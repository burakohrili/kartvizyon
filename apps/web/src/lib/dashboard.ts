import { createSupabaseServerClient } from "@/lib/supabase/server";
import { getSelectedWorkspaceId } from "@/lib/reports";

export type DashboardActivity = {
  id: string;
  company: string;
  representative: string;
  summary: string;
  approvedAt: string;
};

export type DashboardNextVisit = {
  id: string;
  companyId: string;
  company: string;
  address: string | null;
  plannedStartAt: string;
  memorySummary: string | null;
  openTasks: number;
  sourceCount: number;
};

const demoActivities: DashboardActivity[] = [
  {
    id: "demo-activity-1",
    company: "Atlas Medikal",
    representative: "Ece Yılmaz",
    summary: "Yeni cihaz teklifi ve demo tarihi görüşüldü.",
    approvedAt: "2026-08-02T10:42:00+03:00",
  },
  {
    id: "demo-activity-2",
    company: "Nova Otomasyon",
    representative: "Selin Kaya",
    summary: "Bakım sözleşmesi için teknik ekip ziyareti planlandı.",
    approvedAt: "2026-08-01T16:20:00+03:00",
  },
];

export async function loadDashboard() {
  const supabase = await createSupabaseServerClient();
  if (!supabase) return demoDashboard();
  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) return demoDashboard();

  let workspaceId = await getSelectedWorkspaceId();
  if (!workspaceId || workspaceId.startsWith("demo-")) {
    const firstWorkspace = await supabase
      .from("workspaces")
      .select("id")
      .limit(1)
      .single();
    workspaceId = firstWorkspace.data?.id ?? null;
  }
  if (!workspaceId) return { ...demoDashboard(), demo: false, activities: [] };

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);
  const [
    workspace,
    activities,
    completedToday,
    overdueTasks,
    pendingReview,
    nextVisitResult,
  ] = await Promise.all([
    supabase
      .from("workspaces")
      .select("name,organization_id")
      .eq("id", workspaceId)
      .single(),
    supabase
      .from("visits")
      .select(
        "id,approved_at,ai_summary,company:companies(name),representative:profiles!visits_representative_id_fkey(full_name)",
      )
      .eq("workspace_id", workspaceId)
      .eq("status", "approved")
      .order("approved_at", { ascending: false })
      .limit(8),
    supabase
      .from("visits")
      .select("id", { count: "exact", head: true })
      .eq("workspace_id", workspaceId)
      .eq("status", "approved")
      .gte("approved_at", today.toISOString())
      .lt("approved_at", tomorrow.toISOString()),
    supabase
      .from("tasks")
      .select("id", { count: "exact", head: true })
      .eq("workspace_id", workspaceId)
      .eq("status", "open")
      .lt("due_at", new Date().toISOString()),
    supabase
      .from("visits")
      .select("id", { count: "exact", head: true })
      .eq("workspace_id", workspaceId)
      .eq("representative_id", user.id)
      .eq("status", "needs_review"),
    supabase
      .from("visits")
      .select("id,planned_start_at,company:companies!inner(id,name,address)")
      .eq("workspace_id", workspaceId)
      .gte("planned_start_at", new Date().toISOString())
      .order("planned_start_at", { ascending: true })
      .limit(1)
      .maybeSingle(),
  ]);

  const profile = await supabase
    .from("profiles")
    .select("full_name")
    .eq("id", user.id)
    .single();

  const nextCompany = nextVisitResult.data?.company as unknown as {
    id?: string;
    name?: string;
    address?: string | null;
  } | null;
  let nextVisit: DashboardNextVisit | null = null;
  if (
    nextVisitResult.data?.id &&
    nextVisitResult.data.planned_start_at &&
    nextCompany?.id
  ) {
    const [memoryCard, openTasks] = await Promise.all([
      supabase
        .from("customer_memory_cards")
        .select("summary,source_visit_ids")
        .eq("workspace_id", workspaceId)
        .eq("company_id", nextCompany.id)
        .maybeSingle(),
      supabase
        .from("tasks")
        .select("id", { count: "exact", head: true })
        .eq("workspace_id", workspaceId)
        .eq("company_id", nextCompany.id)
        .eq("status", "open"),
    ]);
    nextVisit = {
      id: nextVisitResult.data.id,
      companyId: nextCompany.id,
      company: nextCompany.name ?? "Firma belirtilmedi",
      address: nextCompany.address ?? null,
      plannedStartAt: nextVisitResult.data.planned_start_at,
      memorySummary: memoryCard.data?.summary ?? null,
      openTasks: openTasks.count ?? 0,
      sourceCount: memoryCard.data?.source_visit_ids?.length ?? 0,
    };
  }

  return {
    demo: false,
    userName:
      profile.data?.full_name ?? user.email?.split("@")[0] ?? "Kullanıcı",
    workspaceName: workspace.data?.name ?? "Çalışma alanı",
    completedToday: completedToday.count ?? 0,
    overdueTasks: overdueTasks.count ?? 0,
    pendingReview: pendingReview.count ?? 0,
    nextVisit,
    activities: (activities.data ?? []).map((row) => {
      const company = row.company as unknown as { name?: string } | null;
      const representative = row.representative as unknown as {
        full_name?: string;
      } | null;
      const summary = row.ai_summary as { summary?: string } | null;
      return {
        id: row.id,
        company: company?.name ?? "Firma belirtilmedi",
        representative: representative?.full_name ?? "Saha temsilcisi",
        summary: summary?.summary ?? "Onaylı ziyaret kaydı",
        approvedAt: row.approved_at ?? new Date().toISOString(),
      } satisfies DashboardActivity;
    }),
  };
}

function demoDashboard() {
  return {
    demo: true,
    userName: "Burak",
    workspaceName: "Vizyon Satış A.Ş.",
    completedToday: 18,
    overdueTasks: 7,
    pendingReview: 3,
    nextVisit: {
      id: "demo-visit-next",
      companyId: "demo-1",
      company: "Artemis Endüstri",
      address: "Ümraniye, İstanbul",
      plannedStartAt: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
      memorySummary:
        "Son görüşmede bakım paketi ve 3 yıllık garanti seçenekleri konuşuldu. Satın alma müdürü revize teklifi bekliyor.",
      openTasks: 2,
      sourceCount: 3,
    } satisfies DashboardNextVisit,
    activities: demoActivities,
  };
}
