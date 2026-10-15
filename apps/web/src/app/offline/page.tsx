import Link from "next/link";
import { getMessages } from "@/lib/i18n/messages";
import { getRequestLocale } from "@/lib/i18n/request-locale";

export default async function OfflinePage() {
  const messages = getMessages(await getRequestLocale()).offline;
  return (
    <main className="offline-page">
      <section>
        <span>{messages.eyebrow}</span>
        <h1>{messages.title}</h1>
        <p>{messages.body}</p>
        <Link href="/visits">{messages.retry}</Link>
      </section>
    </main>
  );
}
