import Link from "next/link";
import { getWebWorkspaceContext } from "@/lib/web-context";
import { OpportunityWorkbench } from "../operations-workbench";

const demoWorkspace = "00000000-0000-4000-8000-000000000001";
const demoCompanies = [
  { id: "00000000-0000-4000-8000-000000000101", name: "Atlas Medikal" },
];
const demoItems = [
  {
    id: "00000000-0000-4000-8000-000000000301",
    title: "Yeni cihaz parkı",
    stage: "proposal",
    estimated_value: 850000,
    currency: "TRY",
    company: { name: "Atlas Medikal" },
  },
];

export default async function OpportunitiesPage() {
  const context = await getWebWorkspaceContext();
  const [opportunities, companies] = context
    ? await Promise.all([
        context.supabase
          .from("opportunities")
          .select("*,company:companies(name)")
          .eq("workspace_id", context.workspaceId)
          .order("updated_at", { ascending: false }),
        context.supabase
          .from("companies")
          .select("id,name")
          .eq("workspace_id", context.workspaceId)
          .is("archived_at", null)
          .order("name"),
      ])
    : [{ data: demoItems }, { data: demoCompanies }];
  return (
    <main className="customers-page">
      <header className="customers-header">
        <div>
          <Link href="/" className="back-link">
            ← Genel bakış
          </Link>
          <span className="eyebrow">SATIŞ PIPELINE</span>
          <h1>Fırsatlar</h1>
          <p>Değeri, olasılığı ve aşaması açıklanabilir fırsat akışı.</p>
        </div>
      </header>
      {!context && (
        <div className="demo-notice">
          <strong>Demo görünümü.</strong> Kayıt işlemleri için Supabase
          bağlantısı gerekir.
        </div>
      )}
      <OpportunityWorkbench
        workspaceId={context?.workspaceId ?? demoWorkspace}
        initialItems={
          (opportunities.data ?? []) as Array<Record<string, unknown>>
        }
        companies={
          (companies.data ?? []) as Array<{ id: string; name: string }>
        }
      />
    </main>
  );
}
