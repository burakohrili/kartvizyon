import type { Metadata } from "next";
import { LegalPage } from "../legal-page";
export const metadata: Metadata = {
  title: "KVKK Aydınlatma Metni",
  alternates: { canonical: "https://kartvizyon.app/kvkk" },
};
export default function KvkkPage() {
  return (
    <LegalPage title="KVKK Aydınlatma Metni">
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
