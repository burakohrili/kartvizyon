"use client";

import { getMessages } from "@/lib/i18n/messages";
import { useDocumentLocale } from "@/lib/i18n/use-document-locale";

export default function ErrorPage({ reset }: { reset: () => void }) {
  const locale = useDocumentLocale();
  const messages = getMessages(locale).errorPage;
  return (
    <main style={{ padding: 48 }}>
      <h1>{messages.title}</h1>
      <p>{messages.body}</p>
      <button onClick={reset}>{messages.retry}</button>
    </main>
  );
}
