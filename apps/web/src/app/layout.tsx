import type { Metadata } from "next";
import "./globals.css";
import { OfflineStatus } from "./offline-status";
import { getRequestLocale } from "@/lib/i18n/request-locale";
import { LocaleSwitcher } from "./locale-switcher";

export async function generateMetadata(): Promise<Metadata> {
  const locale = await getRequestLocale();
  const english = locale === "en";
  const description = english
    ? "AI-powered customer memory and visit management for field sales teams."
    : "Saha satış ekipleri için yapay zekâ destekli müşteri hafızası ve ziyaret yönetimi.";
  const tagline = english
    ? "Keep every field promise in reach."
    : "Müşteri bağlamı, ekip değişse bile kaybolmasın.";
  return {
    metadataBase: new URL("https://kartvizyon.app"),
    title: { default: "KartVizyon AI", template: "%s | KartVizyon" },
    description,
    applicationName: "KartVizyon AI",
    authors: [{ name: "Noesis Social - Burak OHRİLİ" }],
    openGraph: {
      type: "website",
      locale: english ? "en_US" : "tr_TR",
      siteName: "KartVizyon",
      title: "KartVizyon AI",
      description: tagline,
      url: "https://kartvizyon.app",
      images: [
        {
          url: "/og-kartvizyon.png",
          width: 1200,
          height: 630,
          alt: english
            ? "KartVizyon — Keep every field promise in reach."
            : "KartVizyon — Sahada verilen söz, ofiste kaybolmasın.",
        },
      ],
    },
    twitter: {
      card: "summary_large_image",
      title: "KartVizyon AI",
      description: tagline,
      images: ["/og-kartvizyon.png"],
    },
  };
}

export default async function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  const locale = await getRequestLocale();
  return (
    <html lang={locale}>
      <body>
        <OfflineStatus />
        <LocaleSwitcher locale={locale} />
        {children}
      </body>
    </html>
  );
}
