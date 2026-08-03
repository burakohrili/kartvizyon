import { cookies } from "next/headers";
import type { ReportFilters } from "@kartvizyon/contracts";
import { createSupabaseServerClient } from "@/lib/supabase/server";

export type ReportVisit = {
  id: string;
  approvedAt: string;
  companyName: string;
  representativeName: string;
  representativeId: string | null;
  companyId: string;
  summary: {
    summary?: string;
    outcome?: string;
    followUps?: unknown[];
  } | null;
};

export const demoReportVisits: ReportVisit[] = [
  {
    id: "demo-report-1",
    approvedAt: "2026-08-02T09:30:00.000Z",
    companyName: "Atlas Medikal",
    companyId: "00000000-0000-4000-8000-000000000101",
    representativeName: "Ayşe Yılmaz",
    representativeId: "00000000-0000-4000-8000-000000000201",
    summary: {
      summary: "Teknik demo talebi ve revize teklif tarihi netleştirildi.",
      outcome: "positive",
      followUps: [{ title: "Demo tarihini netleştir" }],
    },
  },
  {
    id: "demo-report-2",
    approvedAt: "2026-08-01T12:15:00.000Z",
    companyName: "Nova Otomasyon",
    companyId: "00000000-0000-4000-8000-000000000102",
    representativeName: "Mehmet Kaya",
    representativeId: "00000000-0000-4000-8000-000000000202",
    summary: {
      summary: "Bakım sözleşmesi kapsamı için yeni fiyat çalışması istendi.",
      outcome: "neutral",
      followUps: [{ title: "Fiyat çalışmasını gönder" }],
    },
  },
  {
    id: "demo-report-3",
    approvedAt: "2026-07-30T08:45:00.000Z",
    companyName: "Atlas Medikal",
    companyId: "00000000-0000-4000-8000-000000000101",
    representativeName: "Ayşe Yılmaz",
    representativeId: "00000000-0000-4000-8000-000000000201",
    summary: {
      summary: "Yeni cihaz serisinin karar vericileri belirlendi.",
      outcome: "positive",
      followUps: [{ title: "Karar vericiyle toplantı planla" }],
    },
  },
];

function filterDemo(visits: ReportVisit[], filters: ReportFilters) {
  return visits.filter((visit) => {
    const date = visit.approvedAt.slice(0, 10);
    return (
      (!filters.from || date >= filters.from) &&
      (!filters.to || date <= filters.to) &&
      (!filters.representativeId ||
        visit.representativeId === filters.representativeId) &&
      (!filters.companyId || visit.companyId === filters.companyId)
    );
  });
}

export async function getSelectedWorkspaceId() {
  return (await cookies()).get("kartvizyon_workspace")?.value ?? null;
}

export async function loadApprovedReport(
  filters: ReportFilters,
  request?: Request,
): Promise<{
  visits: ReportVisit[];
  workspaceId: string | null;
  demo: boolean;
  authenticated: boolean;
}> {
  const supabase = await createSupabaseServerClient(request);
  if (!supabase) {
    return {
      visits: filterDemo(demoReportVisits, filters),
      workspaceId: "demo-team",
      demo: true,
      authenticated: false,
    };
  }

  const {
    data: { user },
  } = await supabase.auth.getUser();
  if (!user) {
    return {
      visits: filterDemo(demoReportVisits, filters),
      workspaceId: "demo-team",
      demo: true,
      authenticated: false,
    };
  }

  let workspaceId = await getSelectedWorkspaceId();
  if (!workspaceId || workspaceId.startsWith("demo-")) {
    const workspace = await supabase
      .from("workspaces")
      .select("id")
      .limit(1)
      .single();
    workspaceId = workspace.data?.id ?? null;
  }
  if (!workspaceId) {
    return { visits: [], workspaceId: null, demo: false, authenticated: true };
  }

  let query = supabase
    .from("visits")
    .select(
      "id,approved_at,ai_summary,company_id,representative_id,company:companies(name),representative:profiles!visits_representative_id_fkey(full_name)",
    )
    .eq("workspace_id", workspaceId)
    .eq("status", "approved")
    .order("approved_at", { ascending: false })
    .limit(1000);
  if (filters.from)
    query = query.gte("approved_at", `${filters.from}T00:00:00Z`);
  if (filters.to) {
    const nextDay = new Date(`${filters.to}T00:00:00Z`);
    nextDay.setUTCDate(nextDay.getUTCDate() + 1);
    query = query.lt("approved_at", nextDay.toISOString());
  }
  if (filters.representativeId)
    query = query.eq("representative_id", filters.representativeId);
  if (filters.companyId) query = query.eq("company_id", filters.companyId);

  const { data, error } = await query;
  if (error) throw error;
  const visits = (data ?? []).map((row) => {
    const company = row.company as unknown as { name?: string } | null;
    const representative = row.representative as unknown as {
      full_name?: string;
    } | null;
    return {
      id: row.id,
      approvedAt: row.approved_at ?? "",
      companyName: company?.name ?? "Firma belirtilmedi",
      representativeName: representative?.full_name ?? "Temsilci belirtilmedi",
      representativeId: row.representative_id,
      companyId: row.company_id,
      summary: row.ai_summary as ReportVisit["summary"],
    } satisfies ReportVisit;
  });
  return { visits, workspaceId, demo: false, authenticated: true };
}

export function reportMetrics(visits: ReportVisit[]) {
  const positive = visits.filter(
    (visit) => visit.summary?.outcome === "positive",
  ).length;
  const followUps = visits.reduce(
    (total, visit) => total + (visit.summary?.followUps?.length ?? 0),
    0,
  );
  const companies = Object.entries(
    visits.reduce<Record<string, number>>((totals, visit) => {
      totals[visit.companyName] = (totals[visit.companyName] ?? 0) + 1;
      return totals;
    }, {}),
  ).sort((a, b) => b[1] - a[1]);
  return { positive, followUps, companies };
}
