import Link from "next/link";
import { signOutEverywhere } from "./actions";
import { DemoBanner } from "@/app/demo-banner";
import { getRequestLocale } from "@/lib/i18n/request-locale";
import { getMessages } from "@/lib/i18n/messages";

export default async function SecuritySettingsPage() {
  const m = getMessages(await getRequestLocale()).workspaceAdmin;
  return (
    <main className="form-page">
      <DemoBanner />
      <section className="form-card security-card">
        <Link href="/dashboard" className="back-link">
          {m.back}
        </Link>
        <span className="eyebrow">{m.securityEyebrow}</span>
        <h1>{m.sessionsDevices}</h1>
        <p>{m.securityDescription}</p>
        <section className="security-action">
          <div>
            <strong>{m.signOutAllTitle}</strong>
            <p>{m.signOutAllBody}</p>
          </div>
          <form action={signOutEverywhere}>
            <button className="danger-button">{m.signOutAllAction}</button>
          </form>
        </section>
        <p className="security-note">{m.auditNote}</p>
      </section>
    </main>
  );
}
