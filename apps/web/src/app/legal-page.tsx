import Link from "next/link";
import type { Metadata } from "next";
import type { AppLocale } from "@/lib/i18n/locale";
import { getRequestLocale } from "@/lib/i18n/request-locale";

export async function localizedLegalMetadata(input: {
  turkishTitle: string;
  englishTitle: string;
  canonical: string;
  turkishDescription?: string;
  englishDescription?: string;
}): Promise<Metadata> {
  const locale = await getRequestLocale();
  return {
    title: locale === "en" ? input.englishTitle : input.turkishTitle,
    ...(input.turkishDescription || input.englishDescription
      ? {
          description:
            locale === "en"
              ? (input.englishDescription ?? input.turkishDescription)
              : (input.turkishDescription ?? input.englishDescription),
        }
      : {}),
    alternates: { canonical: input.canonical },
  };
}

export function LegalPage({
  title,
  locale = "tr",
  updated = "12 Eylül 2026",
  children,
}: {
  title: string;
  locale?: AppLocale;
  updated?: string;
  children: React.ReactNode;
}) {
  return (
    <main className="legal-shell">
      <header>
        <Link href="/">← KartVizyon</Link>
        <Link href="/contact">{locale === "en" ? "Contact" : "İletişim"}</Link>
      </header>
      <article>
        <span className="marketing-kicker">KARTVİZYON</span>
        <h1>{title}</h1>
        <p className="legal-updated">
          {locale === "en" ? "Last updated:" : "Son güncelleme:"} {updated}
        </p>
        {children}
      </article>
      <footer>
        Noesis Social - Burak OHRİLİ · Gazi Osmanpaşa Mah. 5499/1 Sok. No:9
        Bornova / İzmir · Ege VD. 6360302767 · +90 532 744 94 34
      </footer>
    </main>
  );
}
