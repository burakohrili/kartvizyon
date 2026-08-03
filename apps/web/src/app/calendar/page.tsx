import Link from "next/link";
import { getWebWorkspaceContext } from "@/lib/web-context";
import { CalendarWorkbench } from "../operations-workbench";

const demoWorkspace = "00000000-0000-4000-8000-000000000001";
const demoUser = "00000000-0000-4000-8000-000000000201";
const demoCompanies = [
  { id: "00000000-0000-4000-8000-000000000101", name: "Atlas Medikal" },
];
const demoVisits = [
  {
    id: "00000000-0000-4000-8000-000000000601",
    purpose: "Teknik demo",
    planned_start_at: new Date(Date.now() + 86400000).toISOString(),
    company: { name: "Atlas Medikal" },
  },
];

export default async function CalendarPage() {
  const context = await getWebWorkspaceContext();
  const [visits, companies] = context
    ? await Promise.all([
        context.supabase
          .from("visits")
          .select("id,purpose,planned_start_at,company:companies(name)")
          .eq("workspace_id", context.workspaceId)
          .not("planned_start_at", "is", null)
          .order("planned_start_at")
          .limit(100),
        context.supabase
          .from("companies")
          .select("id,name")
          .eq("workspace_id", context.workspaceId)
          .is("archived_at", null)
          .order("name"),
      ])
    : [{ data: demoVisits }, { data: demoCompanies }];
  return (
    <main className="customers-page">
      <header className="customers-header">
        <div>
          <Link href="/dashboard" className="back-link">
            ← Genel bakış
          </Link>
          <span className="eyebrow">TAKVİM VE PLAN</span>
          <h1>Ziyaret takvimi</h1>
          <p>
            Planlı ziyaretleri ve takip tarihlerini ortak görünümde yönetin.
          </p>
        </div>
      </header>
      {!context && (
        <div className="demo-notice">
          <strong>Demo görünümü.</strong> Kayıt işlemleri için Supabase
          bağlantısı gerekir.
        </div>
      )}
      <CalendarWorkbench
        workspaceId={context?.workspaceId ?? demoWorkspace}
        userId={context?.user.id ?? demoUser}
        companies={
          (companies.data ?? []) as Array<{ id: string; name: string }>
        }
        initialVisits={(visits.data ?? []) as Array<Record<string, unknown>>}
      />
    </main>
  );
}
