import { LegalPage, localizedLegalMetadata } from "../legal-page";
import { getRequestLocale } from "@/lib/i18n/request-locale";
export const generateMetadata = () =>
  localizedLegalMetadata({
    turkishTitle: "KVKK Aydınlatma Metni",
    englishTitle: "Personal Data Notice (Türkiye)",
    canonical: "https://kartvizyon.app/kvkk",
  });
export default async function KvkkPage() {
  const locale = await getRequestLocale();
  if (locale === "en") {
    return (
      <LegalPage
        title="Personal Data Notice (Türkiye)"
        locale={locale}
        updated="September 12, 2026"
      >
        <p>
          This English translation is provided for convenience. The Turkish
          notice and applicable mandatory law govern. Under Türkiye&apos;s
          Personal Data Protection Law No. 6698 (KVKK), the data controller is
          Noesis Social - Burak OHRİLİ.
        </p>
        <h2>How data is collected</h2>
        <p>
          Data may be collected electronically through forms and uploads in the
          web and mobile apps, user permissions, support communications, and
          security records.
        </p>
        <h2>Purposes of processing</h2>
        <p>
          Data is processed to provide accounts and authentication, field-sales
          and customer-memory features, security, troubleshooting, customer
          support, legal compliance, and product-improvement purposes where
          consent is obtained when required.
        </p>
        <h2>Sharing</h2>
        <p>
          Data may be shared, limited to what is necessary, with infrastructure
          providers that support the service, competent public authorities, and
          recipients where disclosure is legally required. International
          transfers are subject to the requirements of applicable law.
        </p>
        <h2>Your rights</h2>
        <p>
          You may exercise rights under Article 11 of KVKK, including access,
          correction, deletion/destruction, information about recipients, and
          objection, by contacting{" "}
          <a href="mailto:kartvizyonapp@gmail.com">kartvizyonapp@gmail.com</a>.
          Identity verification may be required.
        </p>
      </LegalPage>
    );
  }
  return (
    <LegalPage title="KVKK Aydınlatma Metni" locale={locale}>
      <p>
        6698 sayılı Kişisel Verilerin Korunması Kanunu kapsamında veri sorumlusu
        Noesis Social - Burak OHRİLİ’dir.
      </p>
      <h2>Toplama yöntemi</h2>
      <p>
        Veriler web ve mobil uygulamadaki formlar, yüklemeler, kullanıcı
        izinleri, destek iletişimi ve güvenlik kayıtları üzerinden elektronik
        olarak toplanır.
      </p>
      <h2>İşleme amaçları</h2>
      <p>
        Üyelik ve kimlik doğrulama, saha satış ve müşteri hafızası
        özelliklerinin sunulması, güvenlik, hata giderme, müşteri desteği, yasal
        yükümlülük ve açık rıza verilen geliştirme amaçları.
      </p>
      <h2>Aktarım</h2>
      <p>
        Veriler yalnız hizmetin sunulması için gerekli altyapı sağlayıcılarına,
        yetkili kamu kurumlarına ve hukuken zorunlu alıcılara amaçla sınırlı
        olarak aktarılabilir.
      </p>
      <h2>Başvuru hakları</h2>
      <p>
        KVKK madde 11 kapsamındaki bilgi alma, düzeltme, silme, yok etme,
        aktarılan üçüncü kişileri öğrenme ve itiraz haklarınızı
        kartvizyonapp@gmail.com üzerinden kullanabilirsiniz. Kimlik doğrulaması
        gerekebilir.
      </p>
    </LegalPage>
  );
}
