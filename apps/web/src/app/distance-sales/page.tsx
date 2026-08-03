import type { Metadata } from "next";
import Link from "next/link";
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
        Noesis Social - Burak OHRİLİ · Ege Vergi Dairesi · VKN 35509755908 ·
        Gazi Osmanpaşa Mahallesi 5499/1 Sokak No:9 Bornova / İzmir ·{" "}
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
