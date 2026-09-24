import type { Metadata } from "next";
import Link from "next/link";
import { formatTry, PUBLIC_PLANS, TRIAL_MESSAGE } from "@/lib/pricing";
import { LegalPage } from "../legal-page";

export const metadata: Metadata = {
  title: "Mesafeli Satış Sözleşmesi",
  alternates: { canonical: "https://kartvizyon.app/distance-sales" },
};

export default function DistanceSalesPage() {
  return (
    <LegalPage title="Mesafeli Satış Sözleşmesi">
      <p>
        Bu metin KartVizyon dijital aboneliğinin satışıyla birlikte, satın alma
        ekranında gösterilen plan, dönem, toplam bedel ve tüketici bilgileriyle
        sözleşmenin ayrılmaz parçası olarak uygulanır. Ödeme kanalına göre
        uygulanır. Mobil App Store/Google Play satın almalarında mağazanın
        sipariş ekranı, tahsilat ve mağaza koşulları da sözleşmenin parçasıdır.
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
        Bireysel standart aylık fiyat 449 TL olup KDV dahildir. Kurumsal
        planların bedelleri KDV hariçtir. Vergiler dâhil tahsil edilecek toplam
        tutar, seçtiğiniz koltuk sayısı ve dönemle birlikte siparişi onaylamadan
        önce ödeme ekranında ayrıca gösterilir.
      </p>
      <p>
        Mobil mağaza fiyatı ülke, para birimi ve vergiye göre değişebilir; bu
        sayfadaki web liste fiyatı yerine satın alma anında App Store veya
        Google Play tarafından gösterilen toplam tutar esas alınır.
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
                  ? plan.id === "individual"
                    ? "Satışa açık değil"
                    : "Teklif usulü"
                  : `${formatTry(plan.annualTry)}${plan.perSeat ? " / koltuk" : ""}`}
              </td>
              <td>{plan.minSeats}</td>
            </tr>
          ))}
        </tbody>
      </table>
      <h2>Kartsız deneme ve kullanım hakları</h2>
      <p>{TRIAL_MESSAGE}</p>
      <p>
        Deneme, e-posta doğrulandıktan sonraki ilk başarılı girişte başlar ve
        kesintisiz 14 gün sürer. Hesap başına bir kez sunulur. Uygulamayı
        yeniden yüklemek veya çalışma alanı değiştirmek yeni deneme sağlamaz.
        Deneme boyunca toplam 60 kartvizit taraması, 120 dakika ses işleme ve 60
        AI özeti kullanılabilir. Bireysel abonelikte her aylık kullanım
        döneminde 125 tarama, 240 dakika ses işleme ve 125 AI özeti sunulur.
      </p>
      <p>
        Sesli notun yazıya çevrilmesi ses süresinden, özetlenmesi bir özet
        hakkından düşer. Metinden AI özeti üretmek de bir özet hakkı kullanır.
        Başarısız işlemler kullanıcı kotasından düşülmez; aynı tamamlanmış
        işlemi yeniden görüntülemek yeni hak tüketmez. Kullanılmayan haklar
        devretmez.
      </p>
      <p>
        Deneme sonunda abonelik yoksa yeni kayıt, düzenleme, yükleme ve AI
        işlemleri kapanır. Mevcut kayıtları ve çevrimdışı taslakları
        görüntüleme, mevcut verileri dışa aktarma ve hesap silme açık kalır.
        Sürenin dolması tek başına verileri silmez; gizlilik politikasındaki
        saklama süreleri uygulanır.
      </p>
      <p>
        Deneme sırasında abonelik başlatılabilir; ücretli dönem satın alma
        doğrulandığında başlar ve tam paket hakkı verilir. Deneme tüketimi
        ücretli paketten düşülmez. Yıllık faturalandırılan mevcut aboneliklerde
        de kullanım hakları aylık yenilenir. Aylık dönem satın alma tarihine
        bağlıdır; ilgili ayda aynı gün yoksa ayın son günü esas alınır. Kota
        aşımı otomatik ek ücret doğurmaz.
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
