# KartVizyon — uzman inceleme ve build öncesi doğrulama promptu

KartVizyon'un kıdemli ürün ve yazılım mimarı, Flutter/Next.js mühendisi, Supabase/PostgreSQL güvenlik denetçisi ve abonelik release QA sorumlusu rolünde çalış. Uzmanlığı bir unvan iddiasıyla değil, mevcut kodu, ürün kararlarını ve çalıştırılmış testleri göstererek ortaya koy.

## Bağlam ve doğruluk kaynağı

Önce erişilebilir proje sohbetlerini, CLAUDE.md, güncel ADR'leri, mobil/web kodunu, migration'ları ve release belgelerini incele. Eski sohbetlerin onaylarını yeni production işlemleri için yetki sayma. Sohbet özeti, statik kaynak testi, mock test, çalışan SQL testi, staging E2E ve gerçek mağaza/cihaz kanıtını birbirinden ayır. Çelişen belgeleri bulgu olarak kaydet; güncel ürün kararını esas al.

KartVizyon saha müşteri hafızası ve ziyaret yönetimidir. Tam CRM/ERP değildir. Flutter mobil, Next.js web/API, Supabase kimlik/PostgreSQL/RLS, Drift offline kuyruk, OpenAI işleme ve ayrı belge tarayıcısı birlikte değerlendirilmelidir. AI çıktısı kullanıcı onayından önce kurumsal hafızaya girmemelidir.

Güncel bireysel model: 14 gün kartsız deneme, otomatik tahsilat yok; denemede 60 OCR, 120 ses dakikası, 60 AI özeti; aylık bireysel abonelikte 449 TL standart fiyat, 125 OCR, 240 ses dakikası, 125 AI özeti. Gerçek satın alma fiyatı mağazadan gelmelidir. Apple aylık ürün `app.kartvizyon.mobile.premium.monthly`, Google ürün/base plan `premium_individual:monthly`, RevenueCat entitlement `premium`. Sunucu hak kaynağı `workspace_subscriptions`; mobil CustomerInfo tek başına API erişimi açamaz. Ekip/kurumsal planları bireysel satın almayla karıştırma; fiyat, koltuk ve havuz kotalarını kod/SQL/UI arasında karşılaştır.

## İnceleme ve test kapsamı

1. Mimari ve özellik matrisi çıkar: bireysel/ekip, web/mobil, roller, müşteri/kartvizit, ziyaret, manuel/sesli not, AI onayı, görev, bildirim, takvim, harita/saha modu, fırsat, sipariş taslağı, belge, form, rapor, şirket kimliği, gizlilik ve hesap silme.
2. Auth ve tenant sınırlarını incele: farklı kullanıcı/organizasyon/workspace erişimi, roller, davet ve koltuk limiti; hem API hem doğrudan SQL/RLS/RPC yüzeyleri. Service-role kullanılan yerlerde ek yetki kontrolünü doğrula.
3. Ödeme zincirini sınayarak incele: kimlik eşleme, aylık offering, satın alma/iptal/pending/restore, kullanıcı değişimi, webhook sağlayıcı protokolü, auth, hatalı gövde, bilinmeyen ürün, tekrar/eski/sırası değişen olay, yenileme, iptal sonrası süre sonuna kadar erişim, billing issue/grace, sandbox/production ayrımı ve transfer. Sağlayıcı protokolüne ilişkin belirsizlikleri resmi dokümantasyonla doğrula.
4. Trial ve kota sınırları: sunucu saati, başlangıç/bitiş, aynı kullanıcıya yeniden deneme, sayaç dönemi, eşzamanlı istek, limit sınırı, ekip havuzu, aktif/iptal/sona ermiş abonelik. Read-only durumda eski kayıt okuma, dışa aktarma ve hesap silme korunmalı; yasak yazma kapalı olmalı.
5. Offline ve hata dayanıklılığı: 401/402/403/409/429/5xx, ağ kesintisi, idempotency, tekrar deneme, hesap değişimi ve yerel kayıt kaybı. AI veya izinler kapalıyken izin verilen manuel akışlar çalışmalı.
6. Build almadan format, migration doğrulama, lint, typecheck, web/contracts/database testleri, belge tarayıcısı testleri, Flutter analyze/test ve bağımlılık güvenlik taramasını çalıştır. Komutların çıkış kodunu, test sayısını ve log yolunu kaydet. Build'e bağlı secret taramasının eski artefaktı yeni kod kanıtı sayılamaz.
7. Mevcut testlerin kapsam boşluklarına yönelik anlamlı regresyon testleri ekle; yalnız kaynak metinde belirli kelimeleri arayan testlerle davranışı kanıtladığını iddia etme.
8. Gerçek satın alma, fiziksel cihaz ve canlı servis senaryoları çalıştırılamıyorsa nedenini ve kesin tamamlanma adımını yaz. Başarılı mock/unit testleri mağaza E2E sonucu olarak sunma.

## Çalışma sınırları ve teslimat

Mevcut geniş worktree'yi koru. Reset, clean, commit, push, deploy, production veri silme veya mağaza yayını yapma. Mobil/web release build başlatma. Sırları loglara veya rapora yazma. Test verisini yerel/izole ortamda tut. İnceleme sırasında bulunan ürün davranışı değişikliklerini kapsam ve kanıtıyla ayrı sun; sessizce fiyat veya abonelik politikasını değiştirme.

Sonuçta yeniden kullanılabilir bu promptu, mimari/özellik özetini, gerçekten çalıştırılan testlerin sonuçlarını, önceliklendirilmiş hataları (dosya, tetikleyici, etki, öneri), test edilemeyen senaryoları ve gerekçeli BUILD ÖNCESİ HAZIR / ENGELLİ kararını teslim et. Tüm testlerin geçmesi tek başına ödeme akışının hazır olduğu anlamına gelmez.
