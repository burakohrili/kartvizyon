import Link from "next/link";
import { getWebWorkspaceContext } from "@/lib/web-context";
import { FormCenter } from "../interaction-workbench";
import { DemoBanner } from "@/app/demo-banner";
import { getRequestLocale } from "@/lib/i18n/request-locale";
import { getMessages } from "@/lib/i18n/messages";

const demoWorkspace = "00000000-0000-4000-8000-000000000001";
export default async function FormsPage() {
  const locale = await getRequestLocale();
  const m = getMessages(locale).operations;
  const context = await getWebWorkspaceContext();
  const [templates, submissions] = context
    ? await Promise.all([
        context.supabase
          .from("form_templates")
          .select("*")
          .eq("workspace_id", context.workspaceId)
          .eq("active", true)
          .order("name"),
        context.supabase
          .from("form_submissions")
          .select("*")
          .eq("workspace_id", context.workspaceId)
          .order("submitted_at", { ascending: false })
          .limit(100),
      ])
    : [{ data: [] }, { data: [] }];
  return (
    <main className="customers-page">
      <DemoBanner />
      <header className="customers-header">
        <div>
          <Link href="/dashboard" className="back-link">
            {m.back}
          </Link>
          <span className="eyebrow">{m.formsEyebrow}</span>
          <h1>{m.formsTitle}</h1>
          <p>{m.formsDescription}</p>
        </div>
      </header>
      {!context && <div className="demo-notice">{m.formsDemoBody}</div>}
      <FormCenter
        locale={locale}
        workspaceId={context?.workspaceId ?? demoWorkspace}
        initialTemplates={(templates.data ?? []) as Item[]}
        initialSubmissions={(submissions.data ?? []) as Item[]}
      />
    </main>
  );
}
type Item = Record<string, unknown>;
