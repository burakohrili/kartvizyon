import type { Metadata } from "next";
import { LegalPage } from "../legal-page";
export const metadata: Metadata = {
  title: "Destek",
  alternates: { canonical: "https://kartvizyon.app/support" },
};
export default function SupportPage() {
  return (
    <LegalPage title="KartVizyon Destek">
      <p>
        Hesap, erişim, veri hakları ve teknik sorunlar için{" "}
        <a href="mailto:kartvizyonapp@gmail.com">kartvizyonapp@gmail.com</a>{" "}
        adresine yazın.
      </p>
      <h2>Destek talebine ekleyin</h2>
      <p>
        İşlemin zamanı, kullandığınız cihaz ve işletim sistemi, görünen hata
        mesajı ve kişisel veri içermeyen ekran görüntüsü çözümü hızlandırır.
        Parolanızı, doğrulama kodunuzu veya API anahtarınızı paylaşmayın.
      </p>
      <h2>Güvenlik bildirimi</h2>
      <p>
        Olası güvenlik açığını aynı adrese “Güvenlik” başlığıyla bildirin.
        Kullanıcı verisine erişmeyin ve hizmeti aksatacak test yapmayın.
      </p>
    </LegalPage>
  );
}
