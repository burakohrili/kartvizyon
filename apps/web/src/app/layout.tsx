import type { Metadata } from "next";
import "./globals.css";
import { OfflineStatus } from "./offline-status";

export const metadata: Metadata = {
  title: "KartVizyon AI",
  description: "Saha müşteri hafızası ve ziyaret yönetimi",
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
