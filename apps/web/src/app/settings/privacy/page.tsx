import Link from "next/link";
import { getWebWorkspaceContext } from "@/lib/web-context";
import { PrivacyPanel } from "../settings-workbench";
import { SettingsNav } from "../settings-nav";

export default async function PrivacyPage() {
  const context = await getWebWorkspaceContext();
  return (
    <main className="customers-page">
      <header className="customers-header">
        <div>
          <Link href="/" className="back-link">
            ← Genel bakış
          </Link>
          <span className="eyebrow">KVKK</span>
          <h1>Gizlilik ve veri hakları</h1>
          <p>
            Açık rızalarınızı yönetin; dışa aktarma veya silme talebi oluşturun.
          </p>
        </div>
      </header>
      <SettingsNav />
      <PrivacyPanel workspaceId={context?.workspaceId ?? null} />
    </main>
  );
}
