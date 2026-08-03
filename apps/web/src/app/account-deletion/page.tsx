import type { Metadata } from "next";
import Link from "next/link";
import { LegalPage } from "../legal-page";
export const metadata: Metadata = {
  title: "Hesap ve Veri Silme",
  alternates: { canonical: "https://kartvizyon.app/account-deletion" },
};
export default function AccountDeletionPage() {
  return (
    <LegalPage title="Hesap ve Veri Silme">
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
