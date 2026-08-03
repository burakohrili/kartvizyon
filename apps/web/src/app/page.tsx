import type { Metadata } from "next";
import Image from "next/image";
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

const features = [
  {
    title: "AI destekli ziyaret debrief’i",
    how: "Ziyaret sonrası sesli not otomatik transkript edilir ve taslak özete dönüşür.",
    value:
      "Rapor yazma süresini kısaltır; taslak kullanıcı onaylamadan kurumsal kayda geçmez.",
  },
  {
    title: "Kartvizit ve belge OCR",
    how: "Kamerayla taranan kartvizit veya belge otomatik olarak kişi/şirket alanlarına dönüşür.",
    value: "Manuel veri girişini ortadan kaldırır, saha temposunu bozmaz.",
  },
  {
    title: "Offline-first saha çalışması",
    how: "Ziyaret, not ve debrief taslakları cihazda kuyruklanır; bağlantı gelince idempotent senkronize olur.",
    value: "Kırsalda veya bodrum katta bile veri kaybı yaşanmaz.",
  },
  {
    title: "Bağlamsal konum hatırlatması",
    how: "Kullanıcı yakın müşteriye geldiğinde tek seferlik öneri gösterir.",
    value:
      "Unutulan ziyaretleri azaltır; sürekli arka plan takibi hiç yapılmaz.",
  },
  {
    title: "Belge karantina ve zararlı yazılım taraması",
    how: "Yüklenen her belge ayrı bir tarama servisinde ClamAV ile taranır; temiz onay almadan açılmaz.",
    value: "Ekibinizi ve müşteri belgelerinizi zararlı dosya riskinden korur.",
  },
  {
    title: "Yönetici raporları",
    how: "Yalnızca onaylı ziyaretlerden filtrelenen veriler Türkçe PDF/XLSX olarak dışa aktarılır.",
    value: "Yöneticiye doğrulanmış, tahmin içermeyen saha görünürlüğü sağlar.",
  },
  {
    title: "Rol ve çalışma alanı bazlı yetkilendirme",
    how: "Her organizasyon kendi çalışma alanında izole edilir; davetler rol bazlı sınırlandırılır.",
    value: "Ekip büyürken veri karışması veya yetki sızıntısı yaşanmaz.",
  },
  {
    title: "KVKK uyumlu veri yaşam döngüsü",
    how: "Veri dışa aktarma, rıza kaydı ve hesap silme talepleri uçtan uca desteklenir.",
    value:
      "Yasal uyum ve müşteri güveni için ekstra süreç kurmanıza gerek kalmaz.",
  },
];

type PricingTier = {
  name: string;
  audience: string;
  highlight?: boolean;
  items: string[];
};

const pricing: PricingTier[] = [
  {
    name: "Bireysel",
    audience: "Tek başına saha çalışan profesyoneller için",
    items: [
      "Sınırsız müşteri ve ziyaret kaydı",
      "AI destekli debrief ve kartvizit OCR",
      "Offline mobil kullanım",
      "Kişisel takip ve hatırlatmalar",
    ],
  },
  {
    name: "Ekip",
    audience: "Büyüyen saha satış ekipleri için",
    highlight: true,
    items: [
      "Bireysel plandaki her şey",
      "Rol bazlı yetkilendirme ve ekip davetleri",
      "Fırsat, sipariş taslağı ve ürün/fiyat listesi",
      "Yönetici raporları ve paylaşılabilir bağlantılar",
    ],
  },
  {
    name: "Kurumsal",
    audience: "Bölge/takım yapısı olan organizasyonlar için",
    items: [
      "Ekip plandaki her şey",
      "Bölge/takım yönetimi ve entegrasyon webhookları",
      "Genişletilmiş audit log ve veri saklama politikaları",
      "Öncelikli destek ve kurulum danışmanlığı",
    ],
  },
];

const faqs = [
  {
    q: "KartVizyon bir kartvizit arşivi mi, yoksa tam bir CRM mi?",
    a: "İkisi de değil. KartVizyon; saha satış ekiplerinin müşteri hafızasını ve ziyaret yönetimini hedefler. Stok, cari hesap, e-fatura veya karmaşık rota optimizasyonu kapsam dışıdır.",
  },
  {
    q: "AI ürettiği özetler doğrudan kayda mı geçiyor?",
    a: "Hayır. Her AI çıktısı 'incelemede' durumunda başlar; kullanıcı onaylamadan kurumsal hafızaya, rapora veya yönetici akışına girmez.",
  },
  {
    q: "İnternet olmayan bir bölgede ziyaret kaydedebilir miyim?",
    a: "Evet. Mobil uygulama offline-first çalışır; ziyaret, not ve debrief taslakları cihazda kuyruklanır ve bağlantı geldiğinde güvenli şekilde senkronize olur.",
  },
  {
    q: "Konumumu sürekli mi takip ediyorsunuz?",
    a: "Hayır. Konum yalnızca kullanıcının açık bir eylemiyle (ör. yakındaki müşteri önerisi) alınır; arka planda sürekli GPS takibi yapılmaz.",
  },
  {
    q: "Verilerimiz diğer şirketlerin verileriyle karışır mı?",
    a: "Hayır. Her kurumsal veri çalışma alanı ve organizasyon kapsamında satır bazlı güvenlik (RLS) ile izole edilir; bu izolasyon yetkilendirme testleriyle doğrulanır.",
  },
  {
    q: "Fiyatlandırma nasıl işliyor?",
    a: "Hem bireysel hem kurumsal kullanım için plan yapıyoruz. Ödeme altyapımız tamamlanma aşamasında; güncel fiyat ve plan detayları için demo talebiyle bize ulaşabilirsiniz.",
  },
  {
    q: "Belgelerim yüklenirken güvende mi?",
    a: "Her belge ayrı bir karantina alanında ClamAV ile taranır; temiz sonuç alınmadan belge açılamaz veya paylaşılamaz.",
  },
];

const faqJsonLd = {
  "@context": "https://schema.org",
  "@type": "FAQPage",
  mainEntity: faqs.map((faq) => ({
    "@type": "Question",
    name: faq.q,
    acceptedAnswer: { "@type": "Answer", text: faq.a },
  })),
};

export default function MarketingHome() {
  return (
    <main className="marketing-shell">
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(faqJsonLd) }}
      />
      <header className="marketing-nav">
        <Link
          className="marketing-brand"
          href="/"
          aria-label="KartVizyon ana sayfa"
        >
          <Image
            src="/brand/logo-mark.png"
            alt=""
            width={36}
            height={36}
            priority
          />
          <strong>KartVizyon</strong>
        </Link>
        <nav aria-label="Tanıtım menüsü">
          <a href="#cozum">Çözüm</a>
          <a href="#ozellikler">Özellikler</a>
          <a href="#guven">Güven</a>
          <a href="#fiyatlandirma">Fiyatlandırma</a>
          <a href="#sss">SSS</a>
          <a href="#iletisim">İletişim</a>
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

      <section className="marketing-section" id="ozellikler">
        <div className="section-heading">
          <span>NASIL ÇALIŞIR, NE İŞE YARAR</span>
          <h2>Her özellik saha akışının bir adımını doğrudan çözer.</h2>
          <p>
            Gösteriş için değil, ziyaret öncesi, sırası ve sonrasındaki gerçek
            sürtünmeyi azaltmak için tasarlandı.
          </p>
        </div>
        <div className="feature-grid">
          {features.map((feature) => (
            <article key={feature.title}>
              <h3>{feature.title}</h3>
              <p className="feature-how">
                <strong>Nasıl:</strong> {feature.how}
              </p>
              <p className="feature-value">
                <strong>Ne işe yarar:</strong> {feature.value}
              </p>
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

      <section className="marketing-section pricing-section" id="fiyatlandirma">
        <div className="section-heading">
          <span>FİYATLANDIRMA</span>
          <h2>Tek kişiden kurumsal organizasyona kadar aynı ürün.</h2>
          <p>
            Ödeme altyapımız tamamlanma aşamasında. Şu an erken kullanıcılarla
            birlikte plan ve fiyatları netleştiriyoruz; demo görüşmesinde
            ihtiyacınıza göre güncel koşulları paylaşıyoruz.
          </p>
        </div>
        <div className="pricing-grid">
          {pricing.map((tier) => (
            <article
              key={tier.name}
              className={
                tier.highlight ? "pricing-card featured" : "pricing-card"
              }
            >
              {tier.highlight && (
                <span className="pricing-badge">En çok tercih edilen</span>
              )}
              <h3>{tier.name}</h3>
              <p className="pricing-audience">{tier.audience}</p>
              <ul>
                {tier.items.map((item) => (
                  <li key={item}>{item}</li>
                ))}
              </ul>
              <a
                className="marketing-secondary"
                href={`mailto:kartvizyonapp@gmail.com?subject=KartVizyon%20${encodeURIComponent(tier.name)}%20plan%20bilgisi`}
              >
                Plan bilgisi al →
              </a>
            </article>
          ))}
        </div>
      </section>

      <section className="marketing-section faq-section" id="sss">
        <div className="section-heading">
          <span>SIKÇA SORULAN SORULAR</span>
          <h2>Merak edilenler</h2>
        </div>
        <div className="faq-list">
          {faqs.map((faq) => (
            <details key={faq.q}>
              <summary>{faq.q}</summary>
              <p>{faq.a}</p>
            </details>
          ))}
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

      <section className="marketing-section" id="iletisim">
        <div className="section-heading">
          <span>İLETİŞİM</span>
          <h2>KartVizyon ve Noesis Social</h2>
          <p>
            Ürün, demo, destek ve veri hakları talepleriniz için doğrudan bize
            ulaşabilirsiniz.
          </p>
        </div>
        <div className="persona-grid">
          <article>
            <h3>İşletme</h3>
            <p>Noesis Social - Burak OHRİLİ</p>
            <p>Ege Vergi Dairesi · VKN 35509755908</p>
          </article>
          <article>
            <h3>Adres</h3>
            <p>Gazi Osmanpaşa Mahallesi 5499/1 Sokak No:9 Bornova / İzmir</p>
          </article>
          <article>
            <h3>E-posta</h3>
            <p>
              <a href="mailto:kartvizyonapp@gmail.com">
                kartvizyonapp@gmail.com
              </a>
            </p>
            <Link href="/contact">Tüm iletişim bilgileri →</Link>
          </article>
        </div>
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
          <Link href="/about">Hakkımızda</Link>
          <Link href="/contact">İletişim</Link>
          <Link href="/privacy">Gizlilik</Link>
          <Link href="/kvkk">KVKK Aydınlatma</Link>
          <Link href="/terms">Kullanım Koşulları</Link>
          <Link href="/distance-sales">Mesafeli Satış</Link>
          <Link href="/delivery-refund">Teslim, İptal ve İade</Link>
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
