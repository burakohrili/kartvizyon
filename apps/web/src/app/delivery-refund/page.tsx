import type { Metadata } from "next";
import { LegalPage } from "../legal-page";

export const metadata: Metadata = {
  title: "Hizmet Teslim, İptal ve İade Koşulları",
  alternates: { canonical: "https://kartvizyon.app/delivery-refund" },
};

export default function DeliveryRefundPage() {
  return (
    <LegalPage title="Hizmet Teslim, İptal ve İade Koşulları">
      <h2>Elektronik teslim</h2>
      <p>
        KartVizyon fiziksel ürün göndermez. Abonelik, başarılı ödeme
        doğrulamasının ardından ilgili çalışma alanına elektronik olarak
        tanımlanır. Kullanıcı hesabına giriş yaptığında etkin planını ve
        kullanım limitlerini görebilir.
      </p>
      <h2>İptal</h2>
      <p>
        Aylık veya yıllık yenileme, web abonelik yönetimi üzerinden ya da destek
        kanalına yazılı talep ile durdurulabilir. İptal, emredici mevzuat veya
        satın alma sırasında açıklanan daha elverişli koşullar saklı kalmak
        üzere mevcut ücretli dönemin sonunda yürürlüğe girer ve sonraki dönem
        için ücret alınmaz.
      </p>
      <h2>İade ve hizmet sorunu</h2>
      <p>
        Çifte tahsilat, yetkisiz işlem, hizmetin hiç etkinleşmemesi veya ayıplı
        sunulması iddiaları işlem bilgileriyle birlikte incelenir. Uygun bulunan
        iadeler ödemenin yapıldığı yönteme gönderilir; bankanın yansıtma süresi
        ayrıca değişebilir. Tüketicinin kanuni seçimlik ve cayma hakları
        saklıdır.
      </p>
      <h2>Talep kanalı</h2>
      <p>
        İptal veya iade talebinizi sipariş/işlem tarihi ve hesap e-postasıyla{" "}
        <a href="mailto:kartvizyonapp@gmail.com">kartvizyonapp@gmail.com</a>
        adresine iletin. Kart numarası, CVV, parola veya doğrulama kodu
        göndermeyin.
      </p>
    </LegalPage>
  );
}
