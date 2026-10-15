import { LegalPage, localizedLegalMetadata } from "../legal-page";
import { getRequestLocale } from "@/lib/i18n/request-locale";

export const generateMetadata = () =>
  localizedLegalMetadata({
    turkishTitle: "İletişim",
    englishTitle: "Contact",
    turkishDescription: "KartVizyon işletme ve iletişim bilgileri.",
    englishDescription: "KartVizyon business and contact information.",
    canonical: "https://kartvizyon.app/contact",
  });

export default async function ContactPage() {
  const locale = await getRequestLocale();
  if (locale === "en") {
    return (
      <LegalPage title="Contact" locale={locale} updated="September 12, 2026">
        <h2>Business details</h2>
        <p>
          Business: Noesis Social - Burak OHRİLİ
          <br />
          Tax office and ID: Aegean Tax Office · 6360302767
          <br />
          Address: 5499/1 Street No:9, Gazi Osmanpaşa Neighborhood, Bornova /
          İzmir, Türkiye
        </p>
        <h2>Phone</h2>
        <p>
          <a href="tel:+905327449434">+90 532 744 94 34</a> · weekdays,
          09:00–18:00 Türkiye time
        </p>
        <h2>Email</h2>
        <p>
          Product, sales, and support:{" "}
          <a href="mailto:kartvizyonapp@gmail.com">kartvizyonapp@gmail.com</a>
        </p>
        <h2>Requests and complaints</h2>
        <p>
          Include your name, a reachable email address, and the subject of your
          request. Never send passwords, verification codes, payment-card
          details, or API keys. We may need to verify your identity before
          handling a data-rights request.
        </p>
      </LegalPage>
    );
  }
  return (
    <LegalPage title="İletişim" locale={locale}>
      <h2>İşletme bilgileri</h2>
      <p>
        İşletme adı: Noesis Social - Burak OHRİLİ
        <br />
        Vergi dairesi ve numarası: Ege Vergi Dairesi · 6360302767
        <br />
        Adres: Gazi Osmanpaşa Mahallesi 5499/1 Sokak No:9 Bornova / İzmir
      </p>
      <h2>Telefon</h2>
      <p>
        <a href="tel:+905327449434">+90 532 744 94 34</a> · hafta içi
        09:00–18:00
      </p>
      <h2>E-posta</h2>
      <p>
        Ürün, satış ve destek:{" "}
        <a href="mailto:kartvizyonapp@gmail.com">kartvizyonapp@gmail.com</a>
      </p>
      <h2>Başvuru ve şikâyetler</h2>
      <p>
        Talebinizde adınızı, ulaşılabilir e-posta adresinizi ve talebin konusunu
        belirtin. Parola, doğrulama kodu, kart bilgisi veya API anahtarı
        göndermeyin. KVKK kapsamındaki başvurularda güvenli kimlik doğrulaması
        istenebilir.
      </p>
    </LegalPage>
  );
}
