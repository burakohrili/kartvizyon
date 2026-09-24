import type { Metadata } from "next";
import Link from "next/link";
import { LegalPage } from "../legal-page";
export const metadata: Metadata = {
  title: "Kullanım Koşulları",
  alternates: { canonical: "https://kartvizyon.app/terms" },
};
export default function TermsPage() {
  return (
    <LegalPage title="Kullanım Koşulları">
      <h2>Hizmet</h2>
      <p>
        KartVizyon bireysel ve kurumsal saha satış süreçleri için yazılım
        hizmetidir. AI çıktıları öneri niteliğindedir; ticari kararların ve
        kayıt doğruluğunun sorumluluğu kullanıcıdadır.
      </p>
      <h2>Hesap güvenliği</h2>
      <p>
        Kullanıcı erişim bilgilerini korumak, yetkisiz erişimi bildirmek ve
        yalnız hukuka uygun verileri sisteme eklemekle yükümlüdür.
      </p>
      <h2>Kabul edilebilir kullanım</h2>
      <p>
        Zararlı yazılım, yetkisiz kişisel veri, hukuka aykırı içerik, tersine
        mühendislik, hizmeti aşırı yükleme veya başka kullanıcıların erişimini
        ihlal eden kullanım yasaktır.
      </p>
      <h2>14 günlük ücretsiz deneme</h2>
      <p>
        Kart gerekmez; deneme sonunda otomatik ücret alınmaz. E-posta
        doğrulaması sonrasındaki ilk başarılı girişte başlayan deneme hesap
        başına bir kez verilir: toplam 60 tarama, 120 dakika ses işleme ve 60 AI
        özeti. Süre sonunda abonelik başlatılana kadar yeni kayıt ve işlem
        özellikleri kapanır; mevcut verileri görüntüleme, dışa aktarma ve hesap
        silme açık kalır. Çevrimdışı taslaklar silinmez. AI ile işlenmeleri için
        geçerli abonelik gerekir.
      </p>
      <h2>Abonelikler</h2>
      <p>
        Bireysel standart fiyat KDV dahil 449 TL/aydır. Aylık haklar 125
        kartvizit taraması, 240 dakika ses işleme ve 125 AI özetidir.
        Kullanılmayan haklar devretmez. Denemeden ücretli aboneliğe geçişte yeni
        kullanım dönemi ve tam kota açılır. Mevcut yıllık aboneliklerin hakları
        da her ay yenilenir.
      </p>
      <p>
        Mobil uygulamadaki bireysel dijital abonelikler App Store veya Google
        Play üzerinden sunulur. Fiyat, para birimi, dönem ve geçerli deneme
        bilgisi satın alma onayından önce ilgili mağaza ekranında gösterilir.
        Abonelik mağaza hesabına tahsil edilir ve kullanıcı yenilemeyi aynı
        mağazanın abonelik ayarlarından kapatabilir. İptal, mağazanın veya
        emredici mevzuatın aksi gerektirmediği sürece ödenmiş dönemin sonunda
        hüküm doğurur.
      </p>
      <p>
        Kurumsal çalışma alanları uygulama içinde bireysel satın alma yapamaz;
        plan ve koltuklar yetkili kurum yöneticisi ile ayrı kurumsal kanaldan
        yönetilir. Daha önce webden edinilmiş erişim, aynı hesapla mobilde
        kullanılabilir; mobilde bireysel satış varsa yerel mağaza seçeneği de
        sunulur.
      </p>
      <p>
        Satışa açılan aboneliklerde satın alma öncesi bilgilendirme ve sözleşme
        için <Link href="/distance-sales">Mesafeli Satış Sözleşmesi</Link>,
        hizmet başlangıcı, iptal ve iade için{" "}
        <Link href="/delivery-refund">Teslim, İptal ve İade Koşulları</Link>
        uygulanır.
      </p>
      <h2>Fikri mülkiyet ve sorumluluk</h2>
      <p>
        Kullanıcı verisinin mülkiyeti kullanıcıda kalır. KartVizyon markası ve
        yazılımı Noesis Social - Burak OHRİLİ’ye aittir. Emredici hukuk saklı
        kalmak üzere hizmet makul özenle sunulur.
      </p>
      <h2>Yürürlük ve iletişim</h2>
      <p>
        Bu koşullar 20 Eylül 2026 tarihinde yürürlüğe girer. Esaslı
        değişiklikler yürürlüğe girmeden önce uygulama veya kayıtlı iletişim
        kanalı üzerinden bildirilir. Sorular için kartvizyonapp@gmail.com
        adresine ulaşılabilir.
      </p>
    </LegalPage>
  );
}
