import Link from "next/link";

import { createCompany } from "./actions";
import { DemoBanner } from "@/app/demo-banner";
import { getMessages } from "@/lib/i18n/messages";
import { getRequestLocale } from "@/lib/i18n/request-locale";

export default async function NewCustomerPage({
  searchParams,
}: {
  searchParams: Promise<{ error?: string }>;
}) {
  const { error } = await searchParams;
  const messages = getMessages(await getRequestLocale()).customerForms;
  return (
    <main className="form-page">
      <DemoBanner />
      <section className="form-card">
        <Link href="/customers" className="back-link">
          {messages.back}
        </Link>
        <span className="eyebrow">{messages.createEyebrow}</span>
        <h1>{messages.createTitle}</h1>
        <p>{messages.createDescription}</p>
        {error && (
          <div className="form-message error-message">
            {messages.errors[error as keyof typeof messages.errors] ??
              messages.errors.unknown}
          </div>
        )}
        <form action={createCompany} className="entity-form">
          <label>
            {messages.companyName}
            <input
              name="name"
              minLength={2}
              maxLength={200}
              required
              autoFocus
            />
          </label>
          <label>
            {messages.displayName}
            <input
              name="displayName"
              maxLength={80}
              placeholder={messages.displayNamePlaceholder}
            />
            <small>{messages.displayNameHint}</small>
          </label>
          <div className="form-row">
            <label>
              {messages.phone}
              <input name="phone" type="tel" maxLength={40} />
            </label>
            <label>
              {messages.email}
              <input name="email" type="email" />
            </label>
          </div>
          <label>
            {messages.website}
            <input name="website" type="url" placeholder="https://" />
          </label>
          <label>
            {messages.address}
            <textarea name="address" rows={4} maxLength={500} />
          </label>

          <div className="form-section">
            <h2>{messages.contactSection}</h2>
            <p>{messages.contactHint}</p>
            <div className="form-row">
              <label>
                {messages.firstName}
                <input name="contactFirstName" maxLength={100} />
              </label>
              <label>
                {messages.lastName}
                <input name="contactLastName" maxLength={100} />
              </label>
            </div>
            <label>
              {messages.jobTitle}
              <input name="contactTitle" maxLength={120} />
            </label>
            <div className="form-row">
              <label>
                {messages.contactPhone}
                <input name="contactPhone" type="tel" maxLength={40} />
              </label>
              <label>
                {messages.contactEmail}
                <input name="contactEmail" type="email" />
              </label>
            </div>
          </div>

          <div className="form-actions">
            <Link href="/customers">{messages.cancel}</Link>
            <button className="primary" type="submit">
              {messages.saveCompany}
            </button>
          </div>
        </form>
      </section>
    </main>
  );
}
