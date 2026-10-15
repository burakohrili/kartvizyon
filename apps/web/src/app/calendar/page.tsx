import Link from "next/link";
import { getWebWorkspaceContext } from "@/lib/web-context";
import { CalendarWorkbench } from "../operations-workbench";
import { DemoBanner } from "@/app/demo-banner";
import { getMessages } from "@/lib/i18n/messages";
import { getRequestLocale } from "@/lib/i18n/request-locale";
import { getDemoRecords } from "@/lib/i18n/demo-records";

const demoWorkspace = "00000000-0000-4000-8000-000000000001";
const demoUser = "00000000-0000-4000-8000-000000000201";
export default async function CalendarPage() {
  const [context, locale] = await Promise.all([
    getWebWorkspaceContext(),
    getRequestLocale(),
  ]);
  const m = getMessages(locale).calendar;
  const demo = getDemoRecords(locale);
  const demoCompanies = [
    { id: "00000000-0000-4000-8000-000000000101", name: demo.companies[0] },
  ];
  const demoVisits = [
    {
      id: "00000000-0000-4000-8000-000000000601",
      purpose: demo.demoVisitPurpose,
      planned_start_at: "2026-10-15T10:00:00.000Z",
      company: { name: demo.companies[0] },
    },
  ];
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
      <DemoBanner />
      <header className="customers-header">
        <div>
          <Link href="/dashboard" className="back-link">
            {m.back}
          </Link>
          <span className="eyebrow">{m.eyebrow}</span>
          <h1>{m.title}</h1>
          <p>{m.description}</p>
        </div>
      </header>
      {!context && (
        <div className="demo-notice">
          <strong>{m.demoTitle}</strong> {m.demoBody}
        </div>
      )}
      <CalendarWorkbench
        workspaceId={context?.workspaceId ?? demoWorkspace}
        userId={context?.user.id ?? demoUser}
        companies={
          (companies.data ?? []) as Array<{ id: string; name: string }>
        }
        initialVisits={(visits.data ?? []) as Array<Record<string, unknown>>}
        locale={locale}
      />
    </main>
  );
}
