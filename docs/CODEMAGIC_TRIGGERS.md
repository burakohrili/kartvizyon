# Codemagic build tetikleme

## Neden build'ler kendiliğinden başlamıyordu

GitHub deposunda **hiçbir webhook tanımlı değildi** (`gh api repos/burakohrili/kartvizyon/hooks`
boş dizi dönüyordu). Codemagic push olaylarından haberdar olmadığı için her build
elle başlatılmak zorundaydı. `codemagic.yaml` içinde `triggering` bölümü de yoktu.

İki eksik de giderildi:

1. **Webhook** — GitHub → `https://api.codemagic.io/hooks/6a7095935947019139a67709`,
   `push`, `pull_request` ve `create` olayları, JSON içerik tipi.
2. **`triggering`** — her iki workflow `main` dalına push'ta çalışır.

Doğrulama: webhook teslimatı `202 Accepted` döndü ve commit `348cd26` her iki
workflow'u da tetikledi.

## Hangi commit build tetikler

Mobil build dakikası boşa harcanmasın diye tetikleme `changeset` ile daraltıldı:

```yaml
when:
  changeset:
    includes:
      - "apps/mobile"
      - "codemagic.yaml"
```

Yalnız `apps/mobile` altını veya `codemagic.yaml`'ı değiştiren commit'ler build
başlatır. Doküman, web ve veritabanı değişiklikleri mobil derleme tetiklemez.

**Önemli ayrıntı:** Codemagic changeset'i son push'a göre değil, o workflow'un
**son başarılı build'inden bu yana** biriken commit'lere göre değerlendirir. Bu
yüzden başarılı bir build yokken doküman commit'i de build başlatabilir; aradaki
commit'lerden biri `apps/mobile`'a dokunmuştur. Bir kez başarılı build oluştuktan
sonra doküman commit'leri tetikleme yapmaz.

`cancel_previous_builds: true` olduğu için arka arkaya push'larda yalnız en son
commit derlenir.

## Elle veya API ile başlatma

Otomatik tetikleme dışında build başlatmak ya da iOS derlemesini TestFlight'a
göndermek için:

```bash
node scripts/codemagic-build.mjs ios --testflight
```

Kısayollar:

| Komut                          | Ne yapar                                 |
| ------------------------------ | ---------------------------------------- |
| `npm run build:android`        | Android signed AAB                       |
| `npm run build:ios`            | Signed IPA üretir, TestFlight'a yüklemez |
| `npm run build:ios:testflight` | Signed IPA üretir ve TestFlight'a yükler |

Token gereklidir ve komut satırına yazılmaz:

```bash
export CODEMAGIC_API_TOKEN="..."
```

PowerShell'de `$env:CODEMAGIC_API_TOKEN = "..."`. Token
**Codemagic → Account settings → Integrations → Codemagic API** altından üretilir.

## Otomatik tetiklemede TestFlight

`kartvizyon-ios-testflight` workflow'u `submitToTestFlight` girdisini taşır ve
varsayılanı **`true`**'dur. `main`'e giden her başarılı build doğrudan dahili
TestFlight grubuna teslim edilir; ayrıca bir işlem gerekmez.

Test grubu şu an yalnız iç testçilerden oluştuğu için bu bildirim gürültüsü
yaratmaz. **Dış (external) test grubu açıldığında** varsayılan tekrar `false`
yapılmalı ve yükleme elle ya da `npm run build:ios:testflight` ile
tetiklenmelidir; aksi halde her commit dış testçilere sürüm gönderir.

## Flutter sürümü sabittir

`codemagic.yaml` daha önce `flutter: stable` kullanıyordu. `stable` kayan bir
kanaldır ve `.github/workflows/ci.yml` 3.32.6'ya sabitlenmiş olduğu için
**testlerin geçtiği sürüm ile mağazaya giden ikilinin sürümü ayrışıyordu** —
release build'i hiç doğrulanmamış bir toolchain'le üretiliyordu.

18 Ağustos 2026'da bu fiilen kırılmaya yol açtı: stable kanal Gradle 8.14+
istemeye başladı, projenin wrapper'ı 8.12 olduğu için `bundleRelease` şu hatayla
durdu:

```
Your project's Gradle version (8.12.0) is lower than Flutter's
minimum supported version of 8.14.0.
```

Her iki workflow artık `flutter: 3.32.6` ile sabittir. Flutter yükseltmesi
yapılacağında Gradle wrapper'ı (`apps/mobile/android/gradle/wrapper/gradle-wrapper.properties`,
şu an 8.12) birlikte yükseltilmeli ve değişiklik `npm run check` ile
doğrulandıktan sonra üç yerde birden (yerel, CI, Codemagic) aynı sürüme
çekilmelidir.

## Android otomatik yayın

18 Ağustos 2026'dan itibaren Android AAB'si de elle indirilip yüklenmez;
`kartvizyon-android-release` workflow'u kapalı test (`alpha`) kanalına doğrudan
yayınlar:

```yaml
publishing:
  google_play:
    credentials: $GCLOUD_SERVICE_ACCOUNT_CREDENTIALS
    track: alpha
    submit_as_draft: false
```

Gereken kurulum (yapıldı):

1. Google Cloud `kartvizyon` projesinde **Google Play Android Developer API** etkin.
2. `codemagic-play-publisher@kartvizyon.iam.gserviceaccount.com` service account'u —
   Cloud projesinde **hiçbir rolü yok**, yetkiyi yalnız Play Console'dan alır.
3. Play Console → Kullanıcılar ve izinler → bu hesap davetli, **yalnız KartVizyon AI**
   uygulamasının sürüm izniyle. Hesap seviyesinde ve diğer uygulamalarda yetkisi yok.
4. Codemagic → uygulama ayarları → **Environment variables** sekmesi →
   `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS`, grup `mobile_runtime`, **Secure** işaretli,
   değer service account JSON dosyasının tamamı.

Doğrulama: commit `5d8d231` ile tetiklenen build, versionCode 24'ü kapalı test
kanalına yayınladı.

Artık her iki platform da aynı yolu izler: `main`'e push → imzalı build →
iOS TestFlight, Android kapalı test.
