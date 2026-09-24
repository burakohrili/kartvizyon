# App Store ve Google Play premium yayın yol haritası

Bu dosya kodda tamamlanan işleri, hesap sahibi tarafından mağaza panolarında
yapılacak adımları ve yayın kapısını tek yerde toplar. Hukuki metinler uygulama
hazırlığıdır; Türkiye'de çalışan bir avukatın son incelemesi yayın kapısıdır.

## 1. Kod ve veri katmanı — tamamlandı

- [x] `purchases_flutter` ile yerel satın alma ve geri yükleme
- [x] Kişisel/kurumsal çalışma alanı ayrımı
- [x] App Store In-App Purchase capability ve Android `singleTop`
- [x] RevenueCat Authorization + HMAC webhook doğrulaması
- [x] Tekrarlanan/eski olay koruması ve atomik subscription güncellemesi
- [x] İstemcinin `workspace_subscriptions` yazma RLS açığının kapatılması
- [x] OpenAI gerçek ses süresinin `audio_seconds` sayacına yazılması
- [x] Belge depolama kotasının yüklemeden önce uygulanması

## 2. Supabase ve Vercel

1. Staging'de `0026_native_store_billing.up.sql` migration'ını uygulayın.
2. Anon kullanıcıyla `workspace_subscriptions` insert/update/delete deneyin;
   tümü reddedilmelidir. Okuma yalnız erişilen workspace için çalışmalıdır.
3. Vercel Production/Preview'a farklı değerlerle şunları ekleyin:
   `REVENUECAT_WEBHOOK_AUTHORIZATION`, `REVENUECAT_WEBHOOK_SIGNING_SECRET` ve
   preview için `SANDBOX`, production için `PRODUCTION` değerli
   `REVENUECAT_ALLOWED_ENVIRONMENT`.
4. RevenueCat webhook URL'sini
   `https://app.kartvizyon.app/api/internal/webhooks/revenuecat` yapın.
5. Dashboard'da aynı Authorization değerini ve HMAC signing'i etkinleştirin.
   Sandbox ve production için iki ayrı webhook kullanın.
6. RevenueCat test olayının 200; yanlış başlık, yanlış HMAC ve 5 dakikadan eski
   imzanın 401 döndüğünü doğrulayın.

## 3. RevenueCat

1. Apple ve Google uygulamalarını `app.kartvizyon.mobile` kimliğiyle bağlayın.
2. Entitlement: `premium`; Offering: `default` oluşturun.
3. Offering'e yalnız aylık package ekleyip ADR-0008 kimliğine bağlayın.
4. Public Apple/Google SDK anahtarlarını Codemagic'te gizli değişken olarak
   `REVENUECAT_APPLE_PUBLIC_API_KEY` ve `REVENUECAT_GOOGLE_PUBLIC_API_KEY`
   adlarıyla tanımlayın; derleme komutuna `--dart-define` olarak ekleyin.
5. RevenueCat project transfer behavior'ını “transfer to new App User ID”
   yerine destek politikasına göre seçin; farklı KartVizyon hesapları arasında
   mağaza aboneliği paylaşım testini zorunlu yapın.

## 4. App Store Connect — adım adım

1. Agreements, Tax and Banking bölümünde Paid Apps Agreement, banka ve vergi
   durumlarını tamamlayın.
2. KartVizyon altında bir Subscription Group (`KartVizyon Premium`) açın.
3. Aylık auto-renewable ürünü ADR-0008 kimliğiyle oluşturun. Yıllık ürün açmayın.
4. Türkçe/İngilizce görünen ad, açıklama, fiyat, availability ve review
   screenshot alanlarını doldurun. Dönem ve otomatik yenileme açıkça görünmeli.
5. App Privacy formunu Supabase, OpenAI, Sentry, RevenueCat ve mağaza işlem
   verisi envanteriyle güncelleyin; gizlilik URL'si `/privacy` olmalı.
6. İlk auto-renewable subscription grubunu yeni uygulama sürümüyle birlikte
   incelemeye ekleyin. Review Notes'a Premium ekran yolu, restore düğmesi ve
   kişisel test hesabı yazın.
7. Sandbox tester ile satın alma → yenileme → iptal → süre sonu → restore
   senaryolarını tamamlayın. Ask to Buy/pending işlemde ikinci ödeme açılmamalı.

## 5. Google Play Console — adım adım

1. Monetize setup altında payment profile, merchant ve vergi bilgilerini
   tamamlayın.
2. Subscription `premium_individual`; auto-renewing `monthly` base planını
   oluşturup etkinleştirin. `annual` base planı açmayın.
3. Ülke/fiyat, grace period, account hold ve yeniden abonelik ayarlarını yapın.
4. RevenueCat service account'a yalnız gerekli Play Developer API abonelik
   izinlerini verin; JSON anahtarını uygulamaya/Codemagic'e koymayın.
5. Data safety, ödeme ve hesap silme beyanlarını güncel gizlilik envanteriyle
   eşleştirin.
6. License tester ve internal track ile satın alma, pending ödeme, yenileme,
   grace/hold, iptal, expiry ve restore testlerini tamamlayın.
7. Kapalı test şartı ve testçi geri bildirimleri bitmeden production rollout
   başlatmayın.

## 6. Güvenlik ve kötüye kullanım testi

- [ ] Webhook sırrı yokken 503; yanlış auth/HMAC/replay 401
- [ ] Aynı event ID iki kez gönderildiğinde tek entitlement değişikliği
- [ ] Daha eski cancellation yeni renewal'ı geri alamıyor
- [ ] Başka kullanıcı UUID'si ve kurumsal workspace eşlemesi reddediliyor
- [ ] Bilinmeyen product/base plan 422 ve premium açılmıyor
- [ ] İstemci Supabase REST/RPC ile plan/status yükseltemiyor
- [ ] Sandbox olayı production satın alma kaydıyla karışmıyor
- [ ] Service role ve webhook sırları Flutter binary/string taramasında yok
- [ ] Satın alma sonrası backend gecikmesinde premium API erken açılmıyor

## 7. Bug-fix ve yayın kapısı

Build almadan çalıştırılabilen kapı:

```text
npm run format:check
npm run migration:validate
npm run lint
npm run typecheck
npm run test
npm run verify:secrets
npm run security:audit
cd apps/mobile && flutter analyze && flutter test
```

Son build ancak ürün sahibi açıkça istediğinde alınır. O zaman tek aday build
üretilir; gerçek iPhone/Android smoke turu, TestFlight/internal test, Sentry
regresyon kontrolü ve mağaza metadata karşılaştırması tamamlanmadan gönderilmez.
