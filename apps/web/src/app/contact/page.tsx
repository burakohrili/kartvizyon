import type { Metadata } from "next";
import { LegalPage } from "../legal-page";

export const metadata: Metadata = {
  title: "İletişim",
  description: "KartVizyon işletme ve iletişim bilgileri.",
  alternates: { canonical: "https://kartvizyon.app/contact" },
};

export default function ContactPage() {
  return (
    <LegalPage title="İletişim">
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
