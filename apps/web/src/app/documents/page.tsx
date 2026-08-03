import Link from "next/link";
import { getWebWorkspaceContext } from "@/lib/web-context";
import { DocumentCenter } from "../interaction-workbench";

export default async function DocumentsPage() {
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
      <header className="customers-header">
        <div>
          <Link href="/dashboard" className="back-link">
            ← Genel bakış
          </Link>
          <span className="eyebrow">GÜVENLİ DOSYALAR</span>
          <h1>Belgeler</h1>
          <p>
            Dosyalar hash ve içerik imzasıyla doğrulanır, tarama tamamlanana
            kadar karantinada tutulur.
          </p>
        </div>
      </header>
      {!context && (
        <div className="demo-notice">
          Belge yüklemek için Supabase ve document-quarantine kovası gerekir.
        </div>
      )}
      <DocumentCenter
        initialItems={(result.data ?? []) as Array<Record<string, unknown>>}
      />
    </main>
  );
}
