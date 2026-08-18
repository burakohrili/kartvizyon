import type { Metadata } from "next";
import { LegalPage } from "../legal-page";

export const metadata: Metadata = {
  title: "Hakkımızda",
  description: "KartVizyon ve Noesis Social hakkında.",
  alternates: { canonical: "https://kartvizyon.app/about" },
};

export default function AboutPage() {
  return (
    <LegalPage title="Hakkımızda">
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
