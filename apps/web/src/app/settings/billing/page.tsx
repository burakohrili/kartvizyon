import Link from "next/link";
import { getWebWorkspaceContext } from "@/lib/web-context";
import { BillingPanel } from "../settings-workbench";
import { SettingsNav } from "../settings-nav";

export default async function BillingPage() {
  const context = await getWebWorkspaceContext();
  return (
    <main className="customers-page">
      <header className="customers-header">
        <div>
          <Link href="/dashboard" className="back-link">
            ← Genel bakış
          </Link>
          <span className="eyebrow">TİCARİ</span>
          <h1>Paket ve kullanım</h1>
          <p>
            Koltuk, AI ve dosya tüketimini plan limitleriyle birlikte izleyin.
          </p>
        </div>
      </header>
      <SettingsNav />
      <BillingPanel enabled={Boolean(context)} />
    </main>
  );
}
