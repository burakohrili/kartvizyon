import Link from "next/link";

export function LegalPage({
  title,
  updated = "3 Ağustos 2026",
  children,
}: {
  title: string;
  updated?: string;
  children: React.ReactNode;
}) {
  return (
    <main className="legal-shell">
      <header>
        <Link href="/">← KartVizyon</Link>
        <Link href="/contact">İletişim</Link>
      </header>
      <article>
        <span className="marketing-kicker">KARTVİZYON</span>
        <h1>{title}</h1>
        <p className="legal-updated">Son güncelleme: {updated}</p>
        {children}
      </article>
      <footer>
        Noesis Social - Burak OHRİLİ · Gazi Osmanpaşa Mah. 5499/1 Sok. No:9
        Bornova / İzmir · Ege VD. 35509755908
      </footer>
    </main>
  );
}
