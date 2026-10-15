import Link from "next/link";
import type { AppLocale } from "@/lib/i18n/locale";
import { getMessages } from "@/lib/i18n/messages";

export function SettingsNav({ locale }: { locale: AppLocale }) {
  const m = getMessages(locale).settings;
  return (
    <nav className="settings-nav" aria-label={m.navLabel}>
      <Link href="/settings/organization">{m.organization}</Link>
      <Link href="/settings/team">{m.team}</Link>
      <Link href="/settings/billing">{m.billingNav}</Link>
      <Link href="/settings/integrations">{m.integrationsNav}</Link>
      <Link href="/settings/privacy">{m.privacyNav}</Link>
      <Link href="/settings/security">{m.securityNav}</Link>
    </nav>
  );
}
