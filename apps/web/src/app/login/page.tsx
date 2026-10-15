import { signIn, signUp } from "./actions";
import { getMessages } from "@/lib/i18n/messages";
import { getRequestLocale } from "@/lib/i18n/request-locale";

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string; message?: string }>;
}) {
  const query = await searchParams;
  const messages = getMessages(await getRequestLocale()).auth;
  return (
    <main className="auth-page">
      <section className="auth-card">
        <div className="auth-brand">
          <span>KV</span>
          <div>
            <strong>KartVizyon AI</strong>
            <small>{messages.brandSubtitle}</small>
          </div>
        </div>
        <h1>{messages.welcomeTitle}</h1>
        <p>{messages.welcomeBody}</p>
        {query.error && (
          <div className="form-message error-message">
            {messages.errors[query.error as keyof typeof messages.errors] ??
              messages.errors.unknown}
          </div>
        )}
        {query.message === "verify" && (
          <div className="form-message success-message">
            {messages.verificationSent}
          </div>
        )}
        <form action={signIn} className="auth-form">
          <label>
            {messages.email}
            <input name="email" type="email" autoComplete="email" required />
          </label>
          <label>
            {messages.password}
            <input
              name="password"
              type="password"
              autoComplete="current-password"
              minLength={8}
              required
            />
          </label>
          <button className="primary" type="submit">
            {messages.signIn}
          </button>
        </form>
        <details>
          <summary>{messages.createAccount}</summary>
          <form action={signUp} className="auth-form signup-form">
            <label>
              {messages.fullName}
              <input name="fullName" minLength={2} maxLength={120} required />
            </label>
            <label>
              {messages.email}
              <input name="email" type="email" autoComplete="email" required />
            </label>
            <label>
              {messages.password}
              <input
                name="password"
                type="password"
                autoComplete="new-password"
                minLength={8}
                required
              />
            </label>
            <button className="secondary light" type="submit">
              {messages.createFreeAccount}
            </button>
          </form>
        </details>
        <small className="privacy-note">{messages.privacyNote}</small>
      </section>
    </main>
  );
}
