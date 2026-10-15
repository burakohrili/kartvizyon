import { LegalPage, localizedLegalMetadata } from "../legal-page";
import { getRequestLocale } from "@/lib/i18n/request-locale";

export const generateMetadata = () =>
  localizedLegalMetadata({
    turkishTitle: "Hizmet Teslim, İptal ve İade Koşulları",
    englishTitle: "Delivery, Cancellation and Refund (Türkiye)",
    canonical: "https://kartvizyon.app/delivery-refund",
  });

export default async function DeliveryRefundPage() {
  const locale = await getRequestLocale();
  if (locale === "en") {
    return (
      <LegalPage
        title="Delivery, Cancellation and Refund (Türkiye)"
        locale={locale}
        updated="September 12, 2026"
      >
        <p>
          This English translation summarizes the Türkiye-focused policy. It is
          not tailored to other countries; the Turkish text and applicable
          mandatory law govern.
        </p>
        <h2>Digital delivery</h2>
        <p>
          KartVizyon does not ship physical goods. After successful payment
          verification, the subscription is assigned electronically to the
          relevant workspace. The active plan and usage limits are visible when
          you sign in.
        </p>
        <h2>Cancellation</h2>
        <p>
          Cancel App Store subscriptions in Subscriptions in your Apple Account.
          Cancel Google Play subscriptions under Payments and subscriptions in
          your Play account. Deleting the app or your KartVizyon account does
          not itself cancel a store subscription. Unless mandatory law or more
          favorable purchase terms require otherwise, cancellation takes effect
          at the end of the current paid period and prevents the next renewal
          charge.
        </p>
        <h2>Free trial</h2>
        <p>
          The 14-day trial requires no card and does not automatically charge
          when it ends; no cancellation is needed. A paid subscription starts
          only after a separate purchase confirmation. Trial eligibility and
          statutory withdrawal rights are separate matters.
        </p>
        <h2>Refunds and service issues</h2>
        <p>
          For purchases billed by an app store, you may use the Apple or Google
          Play refund request channel and contact us for support. Statutory
          rights are not removed by store policies.
        </p>
        <p>
          Claims involving duplicate charges, unauthorized transactions, failure
          to activate, or defective service are reviewed using the transaction
          details. Approved refunds are returned to the original payment method;
          the time for the bank to post a refund may vary. Statutory consumer
          choices and withdrawal rights remain unaffected.
        </p>
        <h2>Contact</h2>
        <p>
          Send cancellation or refund questions with the order/transaction date
          and account email to{" "}
          <a href="mailto:kartvizyonapp@gmail.com">kartvizyonapp@gmail.com</a>.
          Do not send card numbers, CVV, passwords, or verification codes.
        </p>
      </LegalPage>
    );
  }
  return (
    <LegalPage title="Hizmet Teslim, İptal ve İade Koşulları" locale={locale}>
      <h2>Elektronik teslim</h2>
      <p>
        KartVizyon fiziksel ürün göndermez. Abonelik, başarılı ödeme
        doğrulamasının ardından ilgili çalışma alanına elektronik olarak
        tanımlanır. Kullanıcı hesabına giriş yaptığında etkin planını ve
        kullanım limitlerini görebilir.
      </p>
      <h2>İptal</h2>
      <p>
        App Store satın almalarında yenileme Apple hesabındaki Abonelikler,
        Google Play satın almalarında Play hesabındaki Ödemeler ve abonelikler
        bölümünden kapatılır. Uygulamayı veya KartVizyon hesabını silmek mağaza
        aboneliğini kendiliğinden iptal etmez. İptal, emredici mevzuat veya
        satın alma sırasında açıklanan daha elverişli koşullar saklı kalmak
        üzere mevcut ücretli dönemin sonunda yürürlüğe girer ve sonraki dönem
        için ücret alınmaz.
      </p>
      <h2>Kartsız deneme</h2>
      <p>
        14 günlük deneme için kart istenmez ve süre sonunda otomatik tahsilat
        yapılmaz; iptal işlemi gerekmez. Ücretli abonelik yalnız ayrıca satın
        alma onayınızla başlar. Deneme hakkı ile mevzuattaki cayma hakkı ayrı
        konulardır.
      </p>
      <h2>İade ve hizmet sorunu</h2>
      <p>
        Mağaza üzerinden ödenen tutarlar için Apple veya Google Play iade
        başvuru kanalları kullanılabilir; destek taleplerinizi bize de
        iletebilirsiniz. Kanuni haklarınız mağaza kurallarıyla ortadan kalkmaz.
      </p>
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
