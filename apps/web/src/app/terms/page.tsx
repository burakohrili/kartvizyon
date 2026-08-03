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
      <h2>Abonelikler</h2>
      <p>
        Bireysel ve kurumsal paketlerin fiyat, yenileme, iptal ve iade şartları
        satın alma kanalında açıkça gösterilecektir. Ödeme özellikleri
        etkinleştirilmeden ücret tahsil edilmez.
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
    </LegalPage>
  );
}
