import Link from "next/link";
import { getWebWorkspaceContext } from "@/lib/web-context";
import { FormCenter } from "../interaction-workbench";

const demoWorkspace = "00000000-0000-4000-8000-000000000001";
export default async function FormsPage() {
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
      <header className="customers-header">
        <div>
          <Link href="/dashboard" className="back-link">
            ← Genel bakış
          </Link>
          <span className="eyebrow">ÖZEL SAHA FORMLARI</span>
          <h1>Form tasarımcısı</h1>
          <p>
            Teknik keşif, numune ve ziyaret formlarını sürümlü şablonlarla
            yönetin.
          </p>
        </div>
      </header>
      {!context && (
        <div className="demo-notice">
          Form kaydetmek için Supabase oturumu gerekir.
        </div>
      )}
      <FormCenter
        workspaceId={context?.workspaceId ?? demoWorkspace}
        initialTemplates={(templates.data ?? []) as Item[]}
        initialSubmissions={(submissions.data ?? []) as Item[]}
      />
    </main>
  );
}
type Item = Record<string, unknown>;
