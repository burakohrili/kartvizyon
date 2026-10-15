import Link from "next/link";
import { getWebWorkspaceContext } from "@/lib/web-context";
import { DocumentCenter } from "../interaction-workbench";
import { DemoBanner } from "@/app/demo-banner";
import { getRequestLocale } from "@/lib/i18n/request-locale";
import { getMessages } from "@/lib/i18n/messages";

export default async function DocumentsPage() {
  const locale = await getRequestLocale();
  const m = getMessages(locale).operations;
  const context = await getWebWorkspaceContext();
  const result = context
    ? await context.supabase
        .from("documents")
        .select("id,file_name,mime_type,size_bytes,scan_status,created_at")
        .eq("workspace_id", context.workspaceId)
        .order("created_at", { ascending: false })
        .limit(200)
    : { data: [] };
  return (
    <main className="customers-page">
      <DemoBanner />
      <header className="customers-header">
        <div>
          <Link href="/dashboard" className="back-link">
            {m.back}
          </Link>
          <span className="eyebrow">{m.documentsEyebrow}</span>
          <h1>{m.documentsTitle}</h1>
          <p>{m.documentsDescription}</p>
        </div>
      </header>
      {!context && <div className="demo-notice">{m.documentsDemoBody}</div>}
      <DocumentCenter
        locale={locale}
        initialItems={(result.data ?? []) as Array<Record<string, unknown>>}
      />
    </main>
  );
}
