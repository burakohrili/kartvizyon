import Link from "next/link";
import { getWebWorkspaceContext } from "@/lib/web-context";
import { OpportunityWorkbench } from "../operations-workbench";
import { DemoBanner } from "@/app/demo-banner";
import { getRequestLocale } from "@/lib/i18n/request-locale";
import { getMessages } from "@/lib/i18n/messages";
import { getDemoRecords } from "@/lib/i18n/demo-records";

const demoWorkspace = "00000000-0000-4000-8000-000000000001";
export default async function OpportunitiesPage() {
  const locale = await getRequestLocale();
  const m = getMessages(locale).operations;
  const demo = getDemoRecords(locale);
  const demoCompanies = [
    { id: "00000000-0000-4000-8000-000000000101", name: demo.companies[0] },
  ];
  const demoItems = [
    {
      id: "00000000-0000-4000-8000-000000000301",
      title: demo.opportunity,
      stage: "proposal",
      estimated_value: 850000,
      currency: "TRY",
      company: { name: demo.companies[0] },
    },
  ];
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
      <DemoBanner />
      <header className="customers-header">
        <div>
          <Link href="/dashboard" className="back-link">
            {m.back}
          </Link>
          <span className="eyebrow">{m.opportunitiesEyebrow}</span>
          <h1>{m.opportunitiesTitle}</h1>
          <p>{m.opportunitiesDescription}</p>
        </div>
      </header>
      {!context && (
        <div className="demo-notice">
          <strong>{m.demoTitle}</strong> {m.demoBody}
        </div>
      )}
      <OpportunityWorkbench
        locale={locale}
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
