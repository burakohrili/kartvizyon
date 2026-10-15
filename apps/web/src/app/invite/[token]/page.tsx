import Link from "next/link";
import { InviteAccept } from "./invite-accept";
import { getMessages } from "@/lib/i18n/messages";
import { getRequestLocale } from "@/lib/i18n/request-locale";

export default async function InvitePage({
  params,
}: {
  params: Promise<{ token: string }>;
}) {
  const { token } = await params;
  const messages = getMessages(await getRequestLocale()).auth;
  return (
    <main className="auth-page">
      <section className="auth-card">
        <div className="auth-brand">
          <span>KV</span>
          <div>
            <strong>KartVizyon AI</strong>
            <small>{messages.inviteSubtitle}</small>
          </div>
        </div>
        <h1>{messages.inviteTitle}</h1>
        <p>{messages.inviteBody}</p>
        {/^[a-f0-9]{64}$/i.test(token) ? (
          <InviteAccept token={token} locale={await getRequestLocale()} />
        ) : (
          <div className="form-message error-message">
            {messages.inviteInvalid}
          </div>
        )}
        <Link href="/login" className="invite-login-link">
          {messages.inviteLogin}
        </Link>
      </section>
    </main>
  );
}
