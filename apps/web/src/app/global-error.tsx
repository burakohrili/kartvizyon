"use client";

import * as Sentry from "@sentry/nextjs";
import { useEffect } from "react";

export default function GlobalError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    Sentry.captureException(error);
  }, [error]);

  return (
    <html lang="tr">
      <body>
        <main className="legal-shell">
          <article>
            <span className="marketing-kicker">KARTVİZYON</span>
            <h1>Beklenmeyen bir sorun oluştu.</h1>
            <p>
              Güvenli biçimde tekrar deneyebilirsiniz. Sorun sürerse destek
              ekibimize ulaşın.
            </p>
            <button className="marketing-cta" onClick={reset}>
              Tekrar dene
            </button>
          </article>
        </main>
      </body>
    </html>
  );
}
