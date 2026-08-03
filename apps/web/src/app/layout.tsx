import type { Metadata } from "next";
import "./globals.css";
import { OfflineStatus } from "./offline-status";

export const metadata: Metadata = {
  metadataBase: new URL("https://kartvizyon.app"),
  title: { default: "KartVizyon AI", template: "%s | KartVizyon" },
  description:
    "Saha satış ekipleri için yapay zekâ destekli müşteri hafızası ve ziyaret yönetimi.",
  applicationName: "KartVizyon AI",
  authors: [{ name: "Noesis Social - Burak OHRİLİ" }],
  openGraph: {
    type: "website",
    locale: "tr_TR",
    siteName: "KartVizyon",
    title: "KartVizyon AI",
    description: "Müşteri bağlamı, ekip değişse bile kaybolmasın.",
    url: "https://kartvizyon.app",
  },
  twitter: {
    card: "summary_large_image",
    title: "KartVizyon AI",
    description: "Saha satışının yapay zekâ destekli hafıza katmanı.",
  },
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="tr">
      <body>
        <OfflineStatus />
        {children}
      </body>
    </html>
  );
}
