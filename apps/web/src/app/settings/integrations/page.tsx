import Link from "next/link";
import { getWebWorkspaceContext } from "@/lib/web-context";
import { IntegrationsPanel } from "../settings-workbench";
import { SettingsNav } from "../settings-nav";

export default async function IntegrationsPage() {
  const context = await getWebWorkspaceContext();
  return (
    <main className="customers-page">
      <header className="customers-header">
        <div>
          <Link href="/dashboard" className="back-link">
            ← Genel bakış
          </Link>
          <span className="eyebrow">GÜVENLİ BAĞLANTILAR</span>
          <h1>Entegrasyonlar</h1>
          <p>Salt okunur API anahtarları ve imzalı webhook uçlarını yönetin.</p>
        </div>
      </header>
      <SettingsNav />
      <IntegrationsPanel workspaceId={context?.workspaceId ?? null} />
    </main>
  );
}
