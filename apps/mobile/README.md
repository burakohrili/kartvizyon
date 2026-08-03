# KartVizyon Flutter mobil uygulaması

Android ve iOS saha uygulaması; offline-first ziyaret/debrief, müşteri hafızası, görev, kamera, mikrofon ve açık kullanıcı eylemine bağlı konum akışlarını içerir.

## Gereksinimler

- Flutter stable / Dart 3.8+
- Android Studio + Android SDK 36, Java 17
- iOS için Codemagic macOS/Xcode (yerel Mac zorunlu değil)
- Supabase project URL ve publishable/anon key

## Yerel çalışma

```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run `
  --dart-define=KARTVIZYON_API_URL=http://10.0.2.2:3000 `
  --dart-define=SUPABASE_URL=https://PROJECT.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=PUBLIC_KEY
```

Secret/service role anahtarları `--dart-define` ile verilmez. Mobil pakete giren değerler public kabul edilir.

## Offline mimari

- Drift/SQLite yerel okuma modeli ve mutation kuyruğu kullanılır.
- Her debrief `clientMutationId` ile idempotent gönderilir.
- Bağlantı yokken ziyaret/not kaydı devam eder; AI zorunlu değildir.
- Secure storage yalnız oturum token’ları içindir; uygulama verisi loglanmaz.
- Ham ses kullanıcı başlatmadan kaydedilmez; sync sonrasında retention politikası uygulanır.

## Production kimlikleri

- Android applicationId/namespace: `app.kartvizyon.mobile`
- iOS bundle ID: `app.kartvizyon.mobile`
- Auth callback: `app.kartvizyon.mobile://login-callback`

Bu kimlikler başka uygulamalarla paylaşılmaz. Android release build `android/key.properties` yoksa hata verir; debug key production’da kullanılamaz.

## Kalite

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

Production AAB/IPA için kökteki `codemagic.yaml` kullanılır. Codemagic kurulum ve mağaza adımları `docs/STORE_RELEASE.md`, UX sistemi `docs/DESIGN.md` içindedir.

Launcher icon kaynağı `assets/branding/app-icon-1024.png` dosyasıdır. Platform icon setleri production imzalama adımından önce bu opak 1024×1024 kaynaktan üretilir.
