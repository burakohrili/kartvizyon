import Link from "next/link";
import {
  formatTry,
  IAP_INDIVIDUAL_MONTHLY_TRY,
  PUBLIC_PLANS,
  TRIAL_MESSAGE,
} from "@/lib/pricing";
import { LegalPage, localizedLegalMetadata } from "../legal-page";
import { getRequestLocale } from "@/lib/i18n/request-locale";

export const generateMetadata = () =>
  localizedLegalMetadata({
    turkishTitle: "Mesafeli Satış Sözleşmesi",
    englishTitle: "Distance Sales Agreement (Türkiye)",
    canonical: "https://kartvizyon.app/distance-sales",
  });

export default async function DistanceSalesPage() {
  const locale = await getRequestLocale();
  if (locale === "en") {
    return (
      <LegalPage
        title="Distance Sales Agreement (Türkiye)"
        locale={locale}
        updated="September 12, 2026"
      >
        <p>
          This English text is a convenience translation of terms prepared for
          Türkiye. It does not create a separate offer for another country or
          replace local legal advice. The Turkish agreement, the order details
          shown at purchase, and applicable mandatory law govern. For App Store
          and Google Play purchases, the store order, billing, and store terms
          also apply.
        </p>
        <h2>Seller and service provider</h2>
        <p>
          Noesis Social - Burak OHRİLİ · Aegean Tax Office · Tax ID 6360302767 ·
          5499/1 Street No:9, Gazi Osmanpaşa Neighborhood, Bornova / İzmir,
          Türkiye · <a href="tel:+905327449434">+90 532 744 94 34</a> ·{" "}
          <a href="mailto:kartvizyonapp@gmail.com">kartvizyonapp@gmail.com</a>
        </p>
        <h2>Service and contract formation</h2>
        <p>
          KartVizyon is a time-based software subscription for individual and
          organization field-sales workflows. The selected plan, limits, total
          amount including applicable taxes, renewal period, and payment method
          are shown before order confirmation. The electronic contract is formed
          when the user confirms the pre-contract information and agreement.
        </p>
        <h2>Plan, period, and price</h2>
        <p>
          The standard Türkiye individual monthly price is{" "}
          {formatTry(IAP_INDIVIDUAL_MONTHLY_TRY)}, including VAT. Organization
          plan prices are stated exclusive of VAT. The total amount payable,
          including taxes, is shown before confirming the order based on the
          selected seat count and period.
        </p>
        <p>
          App-store prices may vary by country, currency, and tax. For a mobile
          purchase, the total amount displayed by Apple or Google Play at the
          time of purchase takes precedence over web list prices.
        </p>
        <h2>Free trial and usage allowances</h2>
        <p>
          The 14-day trial requires no card and does not automatically charge at
          expiry. It starts after email verification at the first successful
          sign-in, is offered once per account, and includes 60 scans, 120
          minutes of audio processing, and 60 AI summaries in total. The
          individual subscription includes 125 scans, 240 minutes of audio
          processing, and 125 AI summaries per monthly usage period.
        </p>
        <p>
          Audio transcription consumes audio minutes and summarization consumes
          one summary allowance. Text-to-summary also consumes one summary
          allowance. Failed processing does not consume quota; viewing the same
          completed result again does not consume another allowance. Unused
          allowances do not roll over.
        </p>
        <p>
          When a trial ends without a subscription, creating or editing records,
          uploads, and AI processing are unavailable. Viewing existing records
          and offline drafts, exporting existing data, and requesting account
          deletion remain available. Trial expiry alone does not delete data;
          the retention periods in the privacy policy apply.
        </p>
        <p>
          A subscription may be started during the trial. The paid period begins
          after purchase verification and provides the full allowance; trial
          usage is not deducted from the paid plan. Existing annual plans renew
          usage allowances monthly. Monthly periods follow the purchase date; if
          a month has no corresponding date, its last day applies. Exceeding a
          quota does not create an automatic extra charge.
        </p>
        <h2>Performance, term, and renewal</h2>
        <p>
          After payment is verified, the plan is assigned electronically to the
          account. Monthly or annual subscriptions renew as described at
          purchase. Users may turn off renewal; unless mandatory law or more
          favorable terms provide otherwise, cancellation takes effect at the
          end of the current period.
        </p>
        <h2>Withdrawal, cancellation, and refunds</h2>
        <p>
          Mandatory consumer rights are reserved. Any required express request
          and disclosure for immediate performance of digital services is
          presented separately at purchase. Claims about defective, unavailable,
          or incorrectly provided service are reviewed and addressed under
          applicable law. See the{" "}
          <Link href="/delivery-refund">
            Delivery, Cancellation and Refund Policy
          </Link>
          .
        </p>
        <h2>Disputes and records</h2>
        <p>
          Order, contract-acceptance, and payment records are retained securely,
          and an electronic copy is made available to the user. In Türkiye,
          consumers may apply to Consumer Arbitration Committees or Consumer
          Courts within the applicable monetary thresholds.
        </p>
      </LegalPage>
    );
  }
  return (
    <LegalPage title="Mesafeli Satış Sözleşmesi" locale={locale}>
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
        Bireysel standart aylık fiyat {formatTry(IAP_INDIVIDUAL_MONTHLY_TRY)}{" "}
        olup KDV dahildir. Kurumsal planların bedelleri KDV hariçtir. Vergiler
        dâhil tahsil edilecek toplam tutar, seçtiğiniz koltuk sayısı ve dönemle
        birlikte siparişi onaylamadan önce ödeme ekranında ayrıca gösterilir.
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
