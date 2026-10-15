import Link from "next/link";
import { getWebWorkspaceContext } from "@/lib/web-context";
import { PrivacyPanel } from "../settings-workbench";
import { SettingsNav } from "../settings-nav";
import { DemoBanner } from "@/app/demo-banner";
import { getRequestLocale } from "@/lib/i18n/request-locale";
import { getMessages } from "@/lib/i18n/messages";

export default async function PrivacyPage() {
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
          <span className="eyebrow">{m.privacyEyebrow}</span>
          <h1>{m.privacyTitle}</h1>
          <p>{m.privacyIntro}</p>
        </div>
      </header>
      <SettingsNav locale={locale} />
      <PrivacyPanel
        workspaceId={context?.workspaceId ?? null}
        locale={locale}
      />
    </main>
  );
}
