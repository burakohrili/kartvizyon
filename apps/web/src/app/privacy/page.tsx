import type { Metadata } from "next";
import { LegalPage } from "../legal-page";
export const metadata: Metadata = {
  title: "Gizlilik Politikası",
  alternates: { canonical: "https://kartvizyon.app/privacy" },
};
export default function PrivacyPage() {
  return (
    <LegalPage title="Gizlilik Politikası">
      <h2>Veri sorumlusu</h2>
      <p>
        KartVizyon, Noesis Social - Burak OHRİLİ tarafından işletilir. Gizlilik
        talepleri için kartvizyonapp@gmail.com adresine ulaşabilirsiniz.
      </p>
      <h2>İşlediğimiz veriler</h2>
      <p>
        Hesap ve profil bilgileri, çalışma alanı üyelikleri, müşteri ve ziyaret
        kayıtları, kullanıcının açık işlemiyle eklediği ses, belge, kartvizit ve
        yaklaşık konum verileri ile güvenlik/audit kayıtları işlenebilir.
      </p>
      <h2>Amaç ve hukuki sebep</h2>
      <p>
        Veriler hizmetin kurulması ve sunulması, güvenlik, destek, yasal
        yükümlülükler ve açık rıza verilen analitik/AI amaçlarıyla; sözleşmenin
        ifası, meşru menfaat, hukuki yükümlülük veya açık rızaya dayanarak
        işlenir.
      </p>
      <h2>AI ve insan kontrolü</h2>
      <p>
        Ses ve notlardan oluşturulan özetler taslaktır. Kullanıcı onayı olmadan
        kurumsal hafızaya kesin kayıt olarak eklenmez. AI girdileri reklam
        profillemesi amacıyla kullanılmaz.
      </p>
      <h2>Saklama ve güvenlik</h2>
      <p>
        Ham ses süreli saklanır ve politika sonunda silinir. Belgeler zararlı
        yazılım taramasından temiz sonuç almadan açılamaz. Erişim tenant, rol ve
        çalışma alanı kurallarıyla sınırlandırılır.
      </p>
      <h2>Aktarımlar ve hizmet sağlayıcılar</h2>
      <p>
        Barındırma, kimlik, e-posta, hata izleme ve AI hizmetleri için
        sözleşmeli altyapı sağlayıcıları kullanılabilir. Aktarım ve saklama
        süreçlerinde KVKK’nın yurt dışı aktarım hükümleri gözetilir.
      </p>
      <h2>Haklarınız</h2>
      <p>
        Uygulamadaki KVKK ve veri hakları merkezinden verilerinizi dışa
        aktarabilir, rızaları geri alabilir ve hesabınızın silinmesini
        başlatabilirsiniz.
      </p>
    </LegalPage>
  );
}
