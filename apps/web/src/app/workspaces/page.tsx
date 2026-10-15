import { createOrganization, selectWorkspace } from "./actions";
import { createSupabaseServerClient } from "@/lib/supabase/server";
import { DemoBanner } from "@/app/demo-banner";
import { getRequestLocale } from "@/lib/i18n/request-locale";
import { getMessages } from "@/lib/i18n/messages";
import { getDemoRecords } from "@/lib/i18n/demo-records";

type Workspace = {
  id: string;
  name: string;
  kind: "personal" | "organization";
  organization_id: string | null;
};

export default async function WorkspacesPage() {
  const locale = await getRequestLocale();
  const m = getMessages(locale).workspaceAdmin;
  const demo = getDemoRecords(locale);
  const supabase = await createSupabaseServerClient();
  let workspaces: Workspace[] = [
    {
      id: "demo-personal",
      name: m.personalData,
      kind: "personal",
      organization_id: null,
    },
    {
      id: "demo-team",
      name: demo.workspace,
      kind: "organization",
      organization_id: "demo-organization",
    },
  ];
  if (supabase) {
    const { data } = await supabase
      .from("workspaces")
      .select("id,name,kind,organization_id")
      .order("created_at");
    if (data) workspaces = data as Workspace[];
  }
  return (
    <main className="auth-page">
      <DemoBanner />
      <section className="workspace-card">
        <div className="auth-brand">
          <span>KV</span>
          <div>
            <strong>{m.chooseWorkspace}</strong>
            <small>{m.separatedData}</small>
          </div>
        </div>
        <div className="workspace-list">
          {workspaces.map((workspace) => (
            <form action={selectWorkspace} key={workspace.id}>
              <input type="hidden" name="workspaceId" value={workspace.id} />
              <button>
                <span className={`workspace-symbol ${workspace.kind}`}>
                  {workspace.kind === "personal" ? "K" : "Ş"}
                </span>
                <div>
                  <strong>{workspace.name}</strong>
                  <small>
                    {workspace.kind === "personal"
                      ? m.personalData
                      : m.organizationWorkspace}
                  </small>
                </div>
                <b>→</b>
              </button>
            </form>
          ))}
        </div>
        <details className="create-org">
          <summary>{m.createCompanyWorkspace}</summary>
          <form action={createOrganization} className="auth-form">
            <label>
              {m.companyName}
              <input name="name" minLength={2} maxLength={160} required />
            </label>
            <label>
              {m.shortName}
              <input
                name="slug"
                pattern="[a-z0-9-]+"
                placeholder="vizyon-satis"
                required
              />
            </label>
            <button className="primary">{m.createWorkspace}</button>
          </form>
        </details>
      </section>
    </main>
  );
}
