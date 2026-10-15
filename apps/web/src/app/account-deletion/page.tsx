import Link from "next/link";
import { LegalPage, localizedLegalMetadata } from "../legal-page";
import { getRequestLocale } from "@/lib/i18n/request-locale";
export const generateMetadata = () =>
  localizedLegalMetadata({
    turkishTitle: "Hesap ve Veri Silme",
    englishTitle: "Account and Data Deletion",
    canonical: "https://kartvizyon.app/account-deletion",
  });
export default async function AccountDeletionPage() {
  const locale = await getRequestLocale();
  if (locale === "en") {
    return (
      <LegalPage
        title="Account and Data Deletion"
        locale={locale}
        updated="September 12, 2026"
      >
        <h2>In the app</h2>
        <p>
          In the KartVizyon mobile app, go to More → Privacy and data rights →
          Delete account. On the web, use Settings → Privacy and data rights.
        </p>
        <h2>What is deleted?</h2>
        <p>
          The identity account, personal workspace, and its visit, task, audio,
          document, and profile data are subject to deletion. Organization
          records required for legal or audit purposes may be retained by the
          organization, separated from your identity, under its retention
          obligations.
        </p>
        <h2>Timing and subscriptions</h2>
        <p>
          You can track the request in the app. Except where security or
          organization-ownership checks are required, processing is completed
          within 30 days. An active store subscription must also be canceled in
          the relevant store&apos;s subscription settings; deleting your account
          does not cancel it.
        </p>
        <p>
          <Link
            className="marketing-secondary"
            href="https://app.kartvizyon.app/login"
          >
            Sign in to my account →
          </Link>
        </p>
      </LegalPage>
    );
  }
  return (
    <LegalPage title="Hesap ve Veri Silme" locale={locale}>
      <h2>Uygulama içinden</h2>
      <p>
        KartVizyon mobil uygulamasında Daha Fazla → KVKK ve veri hakları →
        Hesabı sil adımlarını izleyin. Web hesabınızda Ayarlar → KVKK ve veri
        hakları bölümünü kullanabilirsiniz.
      </p>
      <h2>Ne silinir?</h2>
      <p>
        Kimlik hesabınız, kişisel çalışma alanınız ve bu alandaki ziyaret,
        görev, ses, belge ve profil verileri silinir. Kurumsal çalışma
        alanındaki yasal/audit kayıtları kimliğinizden ayrıştırılarak kuruluşun
        saklama yükümlülüğüne göre tutulabilir.
      </p>
      <h2>Süre ve abonelik</h2>
      <p>
        Talep uygulamada izlenebilir. Güvenlik ve kurumsal sahiplik kontrolü
        gerektiren durumlar dışında işlem en geç 30 gün içinde tamamlanır. Aktif
        mağaza aboneliği varsa mağaza abonelik yönetiminden ayrıca iptal
        edilmelidir.
      </p>
      <p>
        <Link
          className="marketing-secondary"
          href="https://app.kartvizyon.app/login"
        >
          Hesabıma giriş yap →
        </Link>
      </p>
    </LegalPage>
  );
}
