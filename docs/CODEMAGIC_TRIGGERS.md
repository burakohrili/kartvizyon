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
varsayılanı `false`'tur. Push ile tetiklendiğinde varsayılan uygulanır: **imzalı
IPA üretilir ama TestFlight'a yüklenmez.** Yükleme istendiğinde build elle
`submitToTestFlight=true` ile ya da yukarıdaki `--testflight` bayrağıyla başlatılır.

Bu bilinçli bir tercihtir; her push'un otomatik olarak TestFlight'a sürüm
göndermesi test kullanıcılarını gereksiz bildirimle yorar.
