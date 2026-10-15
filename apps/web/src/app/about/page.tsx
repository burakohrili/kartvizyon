import { LegalPage, localizedLegalMetadata } from "../legal-page";
import { getRequestLocale } from "@/lib/i18n/request-locale";

export const generateMetadata = () =>
  localizedLegalMetadata({
    turkishTitle: "Hakkımızda",
    englishTitle: "About KartVizyon",
    turkishDescription: "KartVizyon ve Noesis Social hakkında.",
    englishDescription: "About KartVizyon and Noesis Social.",
    canonical: "https://kartvizyon.app/about",
  });

export default async function AboutPage() {
  const locale = await getRequestLocale();
  if (locale === "en") {
    return (
      <LegalPage
        title="About KartVizyon"
        locale={locale}
        updated="September 12, 2026"
      >
        <p>
          KartVizyon is software developed by Noesis Social - Burak OHRİLİ. It
          helps field professionals and sales teams manage customer context,
          visits, and follow-ups in a shared workspace.
        </p>
        <h2>The problem we address</h2>
        <p>
          KartVizyon helps keep meeting notes from getting lost across personal
          memory, messages, and disconnected files. It brings pre-visit
          briefings, offline field notes, human-reviewed AI debriefs, tasks, and
          manager reports together on a customer timeline.
        </p>
        <h2>Product principles</h2>
        <p>
          AI output is a draft until a person approves it. Organization data is
          separated by workspace. Location is used only after a user-initiated
          action or while the user-visible Field Mode is active; the product is
          not designed for covert continuous tracking. Users can initiate data
          export and account deletion requests in the product.
        </p>
        <h2>Business</h2>
        <p>
          Noesis Social - Burak OHRİLİ · Aegean Tax Office · Tax ID 6360302767 ·
          5499/1 Street No:9, Gazi Osmanpaşa Neighborhood, Bornova / İzmir,
          Türkiye
        </p>
      </LegalPage>
    );
  }
  return (
    <LegalPage title="Hakkımızda" locale={locale}>
      <p>
        KartVizyon, Noesis Social - Burak OHRİLİ tarafından geliştirilen;
        bireysel saha profesyonelleri ile satış ekiplerinin müşteri bağlamını,
        ziyaretlerini ve takiplerini güvenli bir çalışma alanında yönetmesini
        sağlayan yazılım hizmetidir.
      </p>
      <h2>Çözdüğümüz problem</h2>
      <p>
        Görüşme notlarının kişisel hafızada, mesajlarda ve farklı dosyalarda
        kaybolmasını önler. Ziyaret öncesi brifing, çevrimdışı saha kaydı, insan
        onaylı AI debrief’i, görevler ve yönetici raporlarını aynı müşteri zaman
        çizgisinde birleştirir.
      </p>
      <h2>Ürün ilkeleri</h2>
      <p>
        İnsan onayı olmadan AI çıktısı kesin kayda dönüşmez. Kurumsal veriler
        çalışma alanına göre ayrılır. Konum yalnız kullanıcının açık işlemiyle
        alınır; arka planda sürekli takip yapılmaz. Kullanıcılar veri dışa
        aktarma ve hesap silme haklarını uygulama içinden başlatabilir.
      </p>
      <h2>İşletme</h2>
      <p>
        Noesis Social - Burak OHRİLİ · Ege Vergi Dairesi · VKN 6360302767 · Gazi
        Osmanpaşa Mahallesi 5499/1 Sokak No:9 Bornova / İzmir
      </p>
    </LegalPage>
  );
}
