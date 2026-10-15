"use client";

import * as Sentry from "@sentry/nextjs";
import { useEffect } from "react";
import { getMessages } from "@/lib/i18n/messages";
import { useDocumentLocale } from "@/lib/i18n/use-document-locale";

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  const locale = useDocumentLocale();
  useEffect(() => {
    Sentry.captureException(error);
  }, [error]);
  const messages = getMessages(locale).errorPage;

  return (
    <html lang={locale}>
      <body>
        <main className="legal-shell">
          <article>
            <span className="marketing-kicker">KARTVİZYON</span>
            <h1>{messages.unexpected}</h1>
            <p>{messages.help}</p>
            <button className="marketing-cta" onClick={reset}>
              {messages.retry}
            </button>
          </article>
        </main>
      </body>
    </html>
  );
}
