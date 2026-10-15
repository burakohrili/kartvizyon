import { LegalPage, localizedLegalMetadata } from "../legal-page";
import { getRequestLocale } from "@/lib/i18n/request-locale";
export const generateMetadata = () =>
  localizedLegalMetadata({
    turkishTitle: "Destek",
    englishTitle: "Support",
    canonical: "https://kartvizyon.app/support",
  });
export default async function SupportPage() {
  const locale = await getRequestLocale();
  if (locale === "en") {
    return (
      <LegalPage
        title="KartVizyon Support"
        locale={locale}
        updated="September 12, 2026"
      >
        <p>
          For account, access, data-rights, or technical issues, email{" "}
          <a href="mailto:kartvizyonapp@gmail.com">kartvizyonapp@gmail.com</a>.
        </p>
        <h2>Include with your support request</h2>
        <p>
          The time of the issue, device and operating-system version, the
          visible error message, and a screenshot without personal data can help
          us investigate. Do not share your password, verification code, or API
          key.
        </p>
        <h2>Security reports</h2>
        <p>
          Report a suspected vulnerability to the same address with “Security”
          in the subject. Do not access user data or perform tests that could
          disrupt the service.
        </p>
      </LegalPage>
    );
  }
  return (
    <LegalPage title="KartVizyon Destek" locale={locale}>
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
