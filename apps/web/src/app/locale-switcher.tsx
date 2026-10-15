"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import type { AppLocale } from "@/lib/i18n/locale";
import { getMessages } from "@/lib/i18n/messages";

export function LocaleSwitcher({ locale }: { locale: AppLocale }) {
  const router = useRouter();
  const [pending, setPending] = useState(false);
  const [failed, setFailed] = useState(false);
  const messages = getMessages(locale);

  async function selectLocale(nextLocale: AppLocale) {
    if (pending || nextLocale === locale) return;
    setPending(true);
    setFailed(false);
    try {
      const response = await fetch("/api/locale", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ locale: nextLocale }),
      });
      if (!response.ok) throw new Error(messages.languageSaveFailed);
      router.refresh();
    } catch {
      setFailed(true);
    } finally {
      setPending(false);
    }
  }

  return (
    <div
      className="locale-switcher"
      role="group"
      aria-label={messages.switchLanguage}
    >
      <span>{messages.language}</span>
      <button
        type="button"
        aria-pressed={locale === "tr"}
        disabled={pending}
        onClick={() => selectLocale("tr")}
      >
        TR
      </button>
      <button
        type="button"
        aria-pressed={locale === "en"}
        disabled={pending}
        onClick={() => selectLocale("en")}
      >
        EN
      </button>
      <span className="sr-only" role="status" aria-live="polite">
        {failed ? messages.languageSaveFailed : ""}
      </span>
    </div>
  );
}
