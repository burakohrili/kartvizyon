import Link from "next/link";
import { getWebWorkspaceContext } from "@/lib/web-context";
import { BillingPanel } from "../settings-workbench";
import { SettingsNav } from "../settings-nav";
import { DemoBanner } from "@/app/demo-banner";
import { getRequestLocale } from "@/lib/i18n/request-locale";
import { getMessages } from "@/lib/i18n/messages";

export default async function BillingPage() {
  const context = await getWebWorkspaceContext();
  const locale = await getRequestLocale();
  const m = getMessages(locale).settings;
  return (
    <main className="customers-page">
      <DemoBanner />
      <header className="customers-header">
        <div>
          <Link href="/dashboard" className="back-link">
            {m.back}
          </Link>
          <span className="eyebrow">{m.billingEyebrow}</span>
          <h1>{m.billingTitle}</h1>
          <p>{m.billingIntro}</p>
        </div>
      </header>
      <SettingsNav locale={locale} />
      <BillingPanel enabled={Boolean(context)} locale={locale} />
    </main>
  );
}
