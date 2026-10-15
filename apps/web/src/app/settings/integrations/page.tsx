import Link from "next/link";
import { getWebWorkspaceContext } from "@/lib/web-context";
import { IntegrationsPanel } from "../settings-workbench";
import { SettingsNav } from "../settings-nav";
import { DemoBanner } from "@/app/demo-banner";
import { getRequestLocale } from "@/lib/i18n/request-locale";
import { getMessages } from "@/lib/i18n/messages";

export default async function IntegrationsPage() {
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
          <span className="eyebrow">{m.integrationsEyebrow}</span>
          <h1>{m.integrationsTitle}</h1>
          <p>{m.integrationsIntro}</p>
        </div>
      </header>
      <SettingsNav locale={locale} />
      <IntegrationsPanel
        workspaceId={context?.workspaceId ?? null}
        locale={locale}
      />
    </main>
  );
}
