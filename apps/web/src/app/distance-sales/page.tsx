import type { Metadata } from "next";
import Link from "next/link";
import {
  formatTry,
  PUBLIC_PLANS,
  TOP_UP_PACKAGES,
  TRIAL_DAYS,
} from "@/lib/pricing";
import { LegalPage } from "../legal-page";

export const metadata: Metadata = {
  title: "Mesafeli Satış Sözleşmesi",
  alternates: { canonical: "https://kartvizyon.app/distance-sales" },
};

export default function DistanceSalesPage() {
  return (
    <LegalPage title="Mesafeli Satış Sözleşmesi">
      <p>
        Bu metin KartVizyon dijital aboneliğinin satışa açılmasıyla birlikte,
        satın alma ekranında gösterilen plan, dönem, toplam bedel ve tüketici
        bilgileriyle sözleşmenin ayrılmaz parçası olarak uygulanır. Ödeme
        etkinleştirilmeden ücret tahsil edilmez.
      </p>
      <h2>Satıcı / hizmet sağlayıcı</h2>
      <p>
        Noesis Social - Burak OHRİLİ · Ege Vergi Dairesi · VKN 6360302767 · Gazi
        Osmanpaşa Mahallesi 5499/1 Sokak No:9 Bornova / İzmir ·{" "}
        <a href="tel:+905327449434">+90 532 744 94 34</a> ·{" "}
        <a href="mailto:kartvizyonapp@gmail.com">kartvizyonapp@gmail.com</a>
      </p>
      <h2>Hizmet ve sözleşmenin kurulması</h2>
      <p>
        KartVizyon, bireysel ve kurumsal saha satış süreçleri için sunulan
        süreli bir yazılım aboneliğidir. Seçilen planın kapsamı, kullanım
        limitleri, vergiler dâhil toplam bedeli, yenileme dönemi ve ödeme
        yöntemi kullanıcı siparişi onaylamadan önce ayrıca gösterilir. Kullanıcı
        ön bilgilendirme ve sözleşmeyi onayladığında sözleşme elektronik ortamda
        kurulur.
      </p>

      <h2>Plan, dönem ve bedel</h2>
      <p>
        Aşağıdaki bedeller KDV hariç liste fiyatlarıdır. Vergiler dâhil tahsil
        edilecek toplam tutar, seçtiğiniz koltuk sayısı ve dönemle birlikte
        siparişi onaylamadan önce ödeme ekranında ayrıca gösterilir.
      </p>
      <table className="legal-table">
        <thead>
          <tr>
            <th>Plan</th>
            <th>Aylık</th>
            <th>Yıllık</th>
            <th>En az koltuk</th>
          </tr>
        </thead>
        <tbody>
          {PUBLIC_PLANS.map((plan) => (
            <tr key={plan.id}>
              <td>{plan.name}</td>
              <td>
                {plan.monthlyTry === null
                  ? "Teklif usulü"
                  : `${formatTry(plan.monthlyTry)}${plan.perSeat ? " / koltuk" : ""}`}
              </td>
              <td>
                {plan.annualTry === null
                  ? "Teklif usulü"
                  : `${formatTry(plan.annualTry)}${plan.perSeat ? " / koltuk" : ""}`}
              </td>
              <td>{plan.minSeats}</td>
            </tr>
          ))}
        </tbody>
      </table>
      <p>
        Aylık AI kotası dolduğunda kullanım durmaz; tek seferlik ek paketler
        alınabilir:{" "}
        {TOP_UP_PACKAGES.map(
          (pack) => `${pack.name} (${pack.detail}) ${formatTry(pack.priceTry)}`,
        ).join(" · ")}
        . Ek paketlerin süresi yoktur ve aylık kota tükendikten sonra
        kullanılır.
      </p>
      <p>
        Her hesap {TRIAL_DAYS} gün tam erişimli ücretsiz denemeyle başlar.
        Deneme süresi içinde iptal edilirse ücret tahsil edilmez; süre sonunda
        hesap ücretsiz katmana geçer ve mevcut veriler silinmez.
      </p>
      <h2>İfa, süre ve yenileme</h2>
      <p>
        Ödeme doğrulandıktan sonra seçilen plan hesaba elektronik olarak
        tanımlanır. Aylık veya yıllık abonelik, satın alma ekranında açıklanan
        dönemde yenilenir. Kullanıcı yenilemeyi iptal edebilir; iptal, zorunlu
        mevzuat veya ayrıca belirtilen daha elverişli koşullar saklı kalmak
        üzere mevcut dönemin sonunda hüküm doğurur.
      </p>
      <h2>Cayma, iptal ve iade</h2>
      <p>
        Tüketicinin emredici mevzuattan doğan hakları saklıdır. Elektronik
        ortamda anında ifaya başlanan hizmetlerde gerekli açık talep ve
        bilgilendirme satın alma sırasında ayrıca alınır. Ayıplı, hiç sunulmayan
        veya hatalı sunulan hizmetlere ilişkin talepler incelenerek mevzuata
        uygun çözüm sağlanır. Ayrıntılar{" "}
        <Link href="/delivery-refund">Teslim, İptal ve İade Koşulları</Link>
        sayfasındadır.
      </p>
      <h2>Uyuşmazlık ve kayıtlar</h2>
      <p>
        Sipariş, sözleşme onayı ve ödeme kayıtları güvenli biçimde saklanır ve
        kullanıcıya elektronik olarak erişilebilir bir nüsha sunulur.
        Tüketiciler, yürürlükteki parasal sınırlar kapsamında Tüketici Hakem
        Heyetlerine veya Tüketici Mahkemelerine başvurabilir.
      </p>
    </LegalPage>
  );
}
