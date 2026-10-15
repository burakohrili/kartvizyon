import Link from "next/link";
import { formatTry, IAP_INDIVIDUAL_MONTHLY_TRY } from "@/lib/pricing";
import { LegalPage, localizedLegalMetadata } from "../legal-page";
import { getRequestLocale } from "@/lib/i18n/request-locale";
export const generateMetadata = () =>
  localizedLegalMetadata({
    turkishTitle: "Kullanım Koşulları",
    englishTitle: "Terms of Use",
    canonical: "https://kartvizyon.app/terms",
  });
export default async function TermsPage() {
  const locale = await getRequestLocale();
  if (locale === "en") {
    return (
      <LegalPage
        title="Terms of Use"
        locale={locale}
        updated="September 20, 2026"
      >
        <p>
          This English version is a convenience translation of terms prepared
          for Türkiye. It is not tailored legal advice or a representation that
          the service complies with the laws of another country. The Turkish
          terms and applicable mandatory law govern.
        </p>
        <h2>Service</h2>
        <p>
          KartVizyon is software for individual and business field-sales
          workflows. AI output is a suggestion; users remain responsible for
          business decisions and the accuracy of records.
        </p>
        <h2>Account security</h2>
        <p>
          Users must protect their sign-in credentials, report unauthorized
          access, and only submit data they are legally entitled to use.
        </p>
        <h2>Acceptable use</h2>
        <p>
          Malware, unauthorized personal data, unlawful content, reverse
          engineering, excessive load, or attempts to interfere with access by
          any other user are prohibited.
        </p>
        <h2>14-day free trial</h2>
        <p>
          No card is required and the trial does not automatically charge at
          expiry. The trial starts at the first successful sign-in after email
          verification, is offered once per account, and includes 60 scans, 120
          minutes of audio processing, and 60 AI summaries in total. When it
          expires, new records and processing are unavailable until a
          subscription is started; viewing existing records, export, and account
          deletion remain available. Offline drafts are not deleted, but AI
          processing requires an active subscription.
        </p>
        <h2>Subscriptions</h2>
        <p>
          The Türkiye individual standard price is{" "}
          {formatTry(IAP_INDIVIDUAL_MONTHLY_TRY)}
          /month, including VAT. The individual plan includes 125 business-card
          scans, 240 minutes of audio processing, and 125 AI summaries per
          month. Unused allowances do not roll over. Starting a paid plan after
          a trial begins a new usage period with the full allowance. Existing
          annual subscriptions also renew usage allowances monthly.
        </p>
        <p>
          Individual mobile subscriptions are offered through the App Store or
          Google Play. The purchase confirmation shown by the store shows the
          applicable price, currency, period, and any trial information before
          purchase. The subscription is billed to the store account; renewal can
          be turned off in the store settings. Unless mandatory law or more
          favorable terms require otherwise, cancellation takes effect at the
          end of the paid period.
        </p>
        <p>
          Organization workspaces cannot make individual in-app purchases; plans
          and seats are managed separately by an authorized organization
          administrator. Previously acquired web access may be used in the
          mobile app with the same account; where individual mobile sales are
          offered, the local store option is also presented.
        </p>
        <p>
          For Türkiye sales, the pre-purchase information and agreement are
          described in the{" "}
          <Link href="/distance-sales">Distance Sales Agreement</Link>; service
          delivery, cancellation, and refunds are covered by the{" "}
          <Link href="/delivery-refund">
            Delivery, Cancellation and Refund Policy
          </Link>
          .
        </p>
        <h2>Intellectual property and responsibility</h2>
        <p>
          Users retain ownership of their data. The KartVizyon brand and
          software belong to Noesis Social - Burak OHRİLİ. The service is
          provided with reasonable care, subject to mandatory law.
        </p>
        <h2>Effective date and contact</h2>
        <p>
          These terms took effect on September 20, 2026. Material changes will
          be notified through the app or a registered communication channel
          before they take effect. Contact{" "}
          <a href="mailto:kartvizyonapp@gmail.com">kartvizyonapp@gmail.com</a>{" "}
          with questions.
        </p>
      </LegalPage>
    );
  }
  return (
    <LegalPage title="Kullanım Koşulları" locale={locale}>
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
        Bireysel standart fiyat KDV dahil{" "}
        {formatTry(IAP_INDIVIDUAL_MONTHLY_TRY)}/aydır. Aylık haklar 125
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
