import { createOrganization, selectWorkspace } from "./actions";
import { createSupabaseServerClient } from "@/lib/supabase/server";

type Workspace = {
  id: string;
  name: string;
  kind: "personal" | "organization";
  organization_id: string | null;
};

export default async function WorkspacesPage() {
  const supabase = await createSupabaseServerClient();
  let workspaces: Workspace[] = [
    {
      id: "demo-personal",
      name: "Kişisel Alanım",
      kind: "personal",
      organization_id: null,
    },
    {
      id: "demo-team",
      name: "Vizyon Satış A.Ş.",
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
      <section className="workspace-card">
        <div className="auth-brand">
          <span>KV</span>
          <div>
            <strong>Çalışma alanı seçin</strong>
            <small>Kişisel ve şirket verileri birbirinden ayrıdır</small>
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
                      ? "Veriler size aittir"
                      : "Kurumsal çalışma alanı"}
                  </small>
                </div>
                <b>→</b>
              </button>
            </form>
          ))}
        </div>
        <details className="create-org">
          <summary>Yeni şirket çalışma alanı oluştur</summary>
          <form action={createOrganization} className="auth-form">
            <label>
              Şirket adı
              <input name="name" minLength={2} maxLength={160} required />
            </label>
            <label>
              Kısa ad
              <input
                name="slug"
                pattern="[a-z0-9-]+"
                placeholder="vizyon-satis"
                required
              />
            </label>
            <button className="primary">Şirket alanını oluştur</button>
          </form>
        </details>
      </section>
    </main>
  );
}
