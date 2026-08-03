import Link from "next/link";

export default function OfflinePage() {
  return (
    <main className="offline-page">
      <section>
        <span>ÇEVRİMDIŞI MOD</span>
        <h1>Bağlantı şu anda yok</h1>
        <p>
          Açık ziyaret notu ekranında çalışmaya devam edebilirsin. Kaydettiğin
          metin ve ses cihazda tutulur, bağlantı geldiğinde otomatik gönderilir.
        </p>
        <Link href="/visits">Tekrar dene</Link>
      </section>
    </main>
  );
}
