# KartVizyon nihai yayın denetimi promptu

> KartVizyon'u yalnız testleri geçen bir yazılım olarak değil, sahada gerçek müşteri verisi taşıyan güvenilir bir ürün olarak denetle. `CLAUDE.md`, ürün ADR'leri, `MOBILE_WEB_PARITY.md`, `PRE_RELEASE_TESTS.md`, `STORE_RELEASE.md` ve mağaza beyanlarını bağlayıcı kabul et. Her sonucu kod, test, derleme çıktısı veya canlı uç nokta kanıtıyla doğrula.
>
> Web, mobil, API, sözleşmeler, migration'lar, offline kuyruk ve CI tanımlarını birlikte incele. Bugün, Müşteriler, Ziyaret, Görevler ve Menü altındaki Takvim, Aktivite, Raporlar, Bildirimler, Fırsatlar, Ürün ve fiyatlar, Sipariş taslakları, Belgeler, Saha formları, Harita, Eşitleme ve KVKK akışlarını tek tek karşılaştır. Mobilde ürün kararı gereği salt okunur olmayan hiçbir web işlemini salt okunur bırakma. Oluşturma, düzenleme, arama, seçim, boş durum, yenileme, hata ve geri dönüş yollarını; uzun firma adları, kısa ad, yüzlerce kayıt, dar ekran, büyük yazı, klavye, çift dokunma ve yavaş ağ koşullarında doğrula.
>
> E-posta, Google, Apple, doğrulama bağlantısı, süresi dolmuş oturum, reviewer hesabı ve hesap silmeyi denetle. Yeni hesapta başka kullanıcıya veya demo hesaba ait veri görünmemeli. Her sorgu ve mutation `organizationId`/`workspaceId` sınırında olmalı; IDOR, yetki yükseltme, eksik RLS, istemci tarafından seçilebilen sahiplik/rol ve yarış koşullarını ara. Yetkisiz API'ler 401/403 dönmeli; iç uçlar secret olmadan açılmamalı. Log, Sentry, hata metni, istemci bundle'ı ve repoda parola, token, service-role anahtarı, müşteri PII'si veya imzalı URL sızıntısı olmamalı.
>
> Girdilerde şema doğrulaması; dosyalarda boyut, MIME ve içerik kontrolü; SSRF, path traversal, webhook imzası, replay/idempotency, rate limit, açık yönlendirme, XSS, SQL injection ve prompt injection savunmalarını test et. AI çıktıları `needs_review` başlamalı ve kullanıcı onayı olmadan kurumsal kayda taşınmamalı. AI, ağ veya cihaz izni çalışmadığında manuel ve offline temel akış devam etmeli; yeniden deneme çift kayıt üretmemeli.
>
> Android manifest ve iOS plist izinlerini gerçek kod ve mağaza beyanlarıyla karşılaştır. Rehber, SMS, reklam kimliği, ATT ve `ACCESS_BACKGROUND_LOCATION` bulunmamalı. Saha modu yalnız kullanıcı tarafından başlatılmalı, görünür gösterge üretmeli, durdurulabilmeli ve başladığı yerel saate göre en fazla 8 saat veya aynı gün 21:00'de kapanmalı; 21:00 sonrasında başlamamalı. İzin reddinde kullanıcı çıkmazda kalmamalı.
>
> Yalnız doğrulanmış sorunları en küçük güvenli değişiklikle düzelt ve regresyon testi ekle. Format, migration up/down, lint, typecheck, tüm testler, production web build'i, istemci secret taraması, production bağımlılık audit'i ve gerçek Android derlemesini çalıştır. Hiçbir kırmızı kapı varken mağaza build'i başlatma.
>
> Tüm kapılar yeşil olduğunda değişiklikleri `main`e gönder; Vercel production dağıtımını ve health 200 yanıtını doğrula. Ardından tam olarak bu commit için Android signed AAB/Play kapalı test ve iOS signed IPA/TestFlight workflow'larını çalıştır. İki workflow'un test, imza, artifact, upload ve publishing adımlarını build ID, commit SHA ve mağaza build numarasıyla doğrulamadan tamamlandı deme. Harici konsolda eksik beyan veya inceleme varsa kesin engeli bildir.

## Zorunlu sonuç

Bulunan/düzeltilen sorunları, regresyon testlerini, kesin test sayılarını, canlı kontrolleri, commit ve deployment/build kimliklerini, mağaza numaralarını, otomatik doğrulanamayan maddeleri ve `YAYINA HAZIR`, `KOŞULLU HAZIR` ya da `YAYINA HAZIR DEĞİL` kararını tek raporda ver.
