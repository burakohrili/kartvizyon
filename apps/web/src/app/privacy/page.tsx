import type { Metadata } from "next";
import { LegalPage } from "../legal-page";
export const metadata: Metadata = {
  title: "Gizlilik Politikası",
  alternates: { canonical: "https://kartvizyon.app/privacy" },
};
export default function PrivacyPage() {
  return (
    <LegalPage title="Gizlilik Politikası">
      <h2>Deneme ve abonelik kayıtları</h2>
      <p>
        Denemenin başlangıç/bitiş zamanı, kullanım sayaçları ve mağaza işlem
        kimlikleri; hizmetin sunulması, satın almaların doğrulanması ve tekrar
        deneme kullanımının önlenmesi için işlenir. Kart bilgileri KartVizyon
        tarafından alınmaz; ücretli mağaza satın almaları Apple veya Google
        tarafından yönetilir. Deneme bittiğinde veri hakları erişimi kapanmaz.
        Hesap silme talebi abonelik yönetiminden ayrı yürütülür; yasal saklama
        yükümlülükleri saklıdır.
      </p>
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
        Barındırma ve kimlik için Supabase, AI işleme için OpenAI, hata izleme
        için Sentry, mobil abonelik doğrulama için RevenueCat; ödeme ve mağaza
        hesabı işlemleri için Apple veya Google kullanılabilir. Bu sağlayıcılara
        yalnız hizmet için gerekli veri aktarılır. Yurt dışı aktarımlarda KVKK
        madde 9 kapsamındaki uygun güvence mekanizması, aktarım envanteri ve
        gerekli standart sözleşme/bildirim adımları tamamlanır.
      </p>
      <h2>Ödeme verileri</h2>
      <p>
        KartVizyon tam kart veya mağaza ödeme bilgilerini görmez ve saklamaz.
        Mağaza, ürün, işlem kimliği, abonelik durumu ve dönem sonu gibi hak
        tanımlamak için gerekli sınırlı kayıtlar sahteciliği önleme ve destek
        amacıyla tutulur.
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
