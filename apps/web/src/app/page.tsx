import type { Metadata } from "next";
import Link from "next/link";

export const metadata: Metadata = {
  title: "Saha satış ekipleri için yapay zekâ destekli müşteri hafızası",
  description:
    "KartVizyon; ziyaretleri, sesli notları, görevleri ve müşteri bağlamını ekip onaylı kurumsal hafızaya dönüştürür.",
  alternates: { canonical: "https://kartvizyon.app" },
};

const outcomes = [
  [
    "Ziyaret öncesi",
    "Son görüşmeler, açık sözler ve kritik müşteri bağlamı tek brifingde.",
  ],
  [
    "Ziyaret sırasında",
    "Not, kartvizit, belge ve konum destekli saha akışı; gereksiz veri takibi olmadan.",
  ],
  [
    "Ziyaret sonrası",
    "Sesli debrief taslağa dönüşür; kullanıcı onayı olmadan kurumsal hafızaya yazılmaz.",
  ],
  [
    "Yönetim için",
    "Takipler, fırsatlar, sipariş taslakları ve ekip görünürlüğü aynı doğrulanmış kaynaktan.",
  ],
];

const trust = [
  "Tenant ve rol bazlı veri izolasyonu",
  "Temiz tarama olmadan açılamayan belgeler",
  "Ham ses için süreli saklama ve otomatik silme",
  "KVKK veri dışa aktarma ve hesap silme akışları",
];

export default function MarketingHome() {
  return (
    <main className="marketing-shell">
      <header className="marketing-nav">
        <Link
          className="marketing-brand"
          href="/"
          aria-label="KartVizyon ana sayfa"
        >
          <span>KV</span>
          <strong>KartVizyon</strong>
        </Link>
        <nav aria-label="Tanıtım menüsü">
          <a href="#cozum">Çözüm</a>
          <a href="#guven">Güven</a>
          <a href="#kimler-icin">Kimler için?</a>
          <Link href="/support">Destek</Link>
        </nav>
        <div className="marketing-actions">
          <a
            className="marketing-login"
            href="https://app.kartvizyon.app/login"
          >
            Giriş yap
          </a>
          <a
            className="marketing-cta small"
            href="mailto:kartvizyonapp@gmail.com?subject=KartVizyon%20demo%20talebi"
          >
            Demo iste
          </a>
        </div>
      </header>

      <section className="marketing-hero">
        <div className="marketing-hero-copy">
          <span className="marketing-kicker">
            SAHA SATIŞININ HAFIZA KATMANI
          </span>
          <h1>Müşteri bağlamı, ekip değişse bile kaybolmasın.</h1>
          <p>
            KartVizyon, saha görüşmelerini doğrulanmış aksiyonlara dönüştürür.
            Ekibiniz her ziyarete hazırlıklı gider, verdiği sözleri izler ve
            müşteriye kaldığı yerden devam eder.
          </p>
          <div className="marketing-hero-actions">
            <a
              className="marketing-cta"
              href="mailto:kartvizyonapp@gmail.com?subject=KartVizyon%20demo%20talebi"
            >
              Ücretsiz ürün görüşmesi
            </a>
            <a className="marketing-secondary" href="#cozum">
              Nasıl çalışır? ↓
            </a>
          </div>
          <small>
            Kredi kartı gerekmez · Bireysel ve kurumsal kullanım için tasarlandı
          </small>
        </div>
        <div
          className="marketing-visual"
          aria-label="KartVizyon ziyaret akışı özeti"
        >
          <div className="visual-orbit orbit-one" />
          <div className="visual-orbit orbit-two" />
          <article className="visual-card main-card">
            <span>BUGÜNÜN BRİFİNGİ</span>
            <strong>Artemis Endüstri</strong>
            <p>Revize teklif bekleniyor · 2 açık takip</p>
            <div className="visual-progress">
              <i />
            </div>
          </article>
          <article className="visual-card note-card">
            <span>AI TASLAĞI</span>
            <strong>Onay sizde</strong>
            <p>Kurumsal hafızaya yazılmadan önce kontrol edin.</p>
          </article>
          <article className="visual-card task-card">
            <span>TAKİP</span>
            <strong>Teklif · Cuma 14:00</strong>
          </article>
        </div>
      </section>

      <section className="marketing-proof" aria-label="Ürün ilkeleri">
        <span>Offline-first mobil çalışma</span>
        <span>İnsan onaylı AI</span>
        <span>Türkiye ve KVKK odaklı</span>
        <span>Web + iOS + Android</span>
      </section>

      <section className="marketing-section" id="cozum">
        <div className="section-heading">
          <span>TEK VE DOĞRU AKIŞ</span>
          <h2>Not toplamaktan öte, satışın devamlılığını kurar.</h2>
          <p>
            Dağınık mesajlar ve kişisel hafıza yerine ekip tarafından
            doğrulanmış bir müşteri zaman çizgisi.
          </p>
        </div>
        <div className="outcome-grid">
          {outcomes.map(([title, description], index) => (
            <article key={title}>
              <span>0{index + 1}</span>
              <h3>{title}</h3>
              <p>{description}</p>
            </article>
          ))}
        </div>
      </section>

      <section className="marketing-section split-section" id="guven">
        <div>
          <span className="marketing-kicker">GÜVEN VARSAYILAN AYAR</span>
          <h2>AI hızlıdır. Son söz yine insandadır.</h2>
          <p>
            KartVizyon özet ve takip önerir; çalışan onaylamadan kurumsal kaydı
            değiştirmez. Hassas veriler, rol ve çalışma alanı sınırlarının
            dışına çıkmaz.
          </p>
          <Link className="marketing-secondary" href="/privacy">
            Gizlilik yaklaşımını incele →
          </Link>
        </div>
        <ul className="trust-list">
          {trust.map((item) => (
            <li key={item}>{item}</li>
          ))}
        </ul>
      </section>

      <section className="marketing-section persona-section" id="kimler-icin">
        <div className="section-heading">
          <span>BİREYSELDEN KURUMSALA</span>
          <h2>
            Tek temsilcinin odağından, satış organizasyonunun görünürlüğüne.
          </h2>
        </div>
        <div className="persona-grid">
          <article>
            <h3>Bireysel saha profesyoneli</h3>
            <p>
              Görüşme hafızasını, kişisel takiplerini ve günlük rotasını tek
              yerde tutar.
            </p>
          </article>
          <article>
            <h3>Büyüyen satış ekibi</h3>
            <p>
              Müşteri devrini kolaylaştırır, verilen sözleri ve ekip
              aktivitesini görünür kılar.
            </p>
          </article>
          <article>
            <h3>Kurumsal organizasyon</h3>
            <p>
              Rol, bölge, entegrasyon, audit ve veri saklama politikalarıyla
              kontrollü ölçeklenir.
            </p>
          </article>
        </div>
      </section>

      <section className="marketing-final-cta">
        <span>Bir sonraki müşteri görüşmeniz kaybolmasın.</span>
        <h2>KartVizyon’u kendi satış akışınızla birlikte değerlendirelim.</h2>
        <a
          className="marketing-cta light"
          href="mailto:kartvizyonapp@gmail.com?subject=KartVizyon%20ürün%20görüşmesi"
        >
          Görüşme planla
        </a>
      </section>

      <footer className="marketing-footer">
        <div>
          <strong>KartVizyon</strong>
          <p>
            Noesis Social - Burak OHRİLİ
            <br />
            Bornova / İzmir · Türkiye
          </p>
        </div>
        <nav aria-label="Yasal bağlantılar">
          <Link href="/privacy">Gizlilik</Link>
          <Link href="/kvkk">KVKK Aydınlatma</Link>
          <Link href="/terms">Kullanım Koşulları</Link>
          <Link href="/account-deletion">Hesap Silme</Link>
          <Link href="/support">Destek</Link>
        </nav>
        <small>
          © {new Date().getFullYear()} Noesis Social - Burak OHRİLİ. Tüm hakları
          saklıdır.
        </small>
      </footer>
    </main>
  );
}
