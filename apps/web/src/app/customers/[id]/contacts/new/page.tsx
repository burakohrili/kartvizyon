import Link from "next/link";
import { ContactForm } from "./contact-form";
import { DemoBanner } from "@/app/demo-banner";
import { getRequestLocale } from "@/lib/i18n/request-locale";
import { getMessages } from "@/lib/i18n/messages";

export default async function NewContactPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const locale = await getRequestLocale();
  const messages = getMessages(locale).customerForms;
  return (
    <main className="form-page">
      <DemoBanner />
      <section className="form-card">
        <Link href={`/customers/${id}`} className="back-link">
          {messages.contactBack}
        </Link>
        <span className="eyebrow">{messages.contactEyebrow}</span>
        <h1>{messages.contactTitle}</h1>
        <p>{messages.contactIntro}</p>
        <ContactForm companyId={id} locale={locale} />
      </section>
    </main>
  );
}
