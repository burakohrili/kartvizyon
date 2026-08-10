# KartVizyon belge tarayıcı

ClamAV tabanlı bu servis, Vercel'deki belge kuyruğunu sahiplenir, beş dakikalık imzalı URL'den dosyayı indirir, SHA-256 ve 20 MB sınırını doğrular, sonucu KartVizyon callback rotasına yollar.

## Ortam

- `DOCUMENT_SCAN_SECRET`: Vercel ile aynı, en az 32 bayt rastgele secret.
- `APP_BASE_URL`: `https://kartvizyon.app`.
- `PORT`: Cloud Run tarafından verilir; yerelde varsayılan `8080`.

`APP_BASE_URL` istekten kabul edilmez; callback hedefi yalnız ortamdan okunur. `/scan` Bearer secret ister. `/health`, ClamAV motoru, uygulama URL'si ve secret hazır değilse `503` döner.

## Yerel kontrol

```powershell
node --check src/server.mjs
npm.cmd test
```

Container testi için temiz bir PDF ve standart EICAR test dosyası kullanın. EICAR hiçbir zaman gerçek kullanıcı kovasına veya production dışı bir yere yüklenmemelidir.

## Cloud Run

Google Cloud CLI ile proje ve billing seçildikten sonra `services/document-scanner` dizininde:

```text
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com secretmanager.googleapis.com
gcloud run deploy kartvizyon-document-scanner --source . --region europe-west1 --allow-unauthenticated --memory 2Gi --cpu 1 --concurrency 1 --min-instances 0 --max-instances 3 --timeout 120 --set-env-vars APP_BASE_URL=https://kartvizyon.app --set-secrets DOCUMENT_SCAN_SECRET=kartvizyon-document-scan-secret:latest
```

Servis Vercel dışından çağrıldığı için Cloud Run endpoint'i ağ seviyesinde erişilebilir olur; uygulama seviyesinde güçlü Bearer secret ile korunur. `DOCUMENT_SCAN_SERVICE_URL` Vercel Production ortamına Cloud Run URL'si olarak eklenir ve yeniden deploy edilir.

Yayın kapısı:

1. `/health` → `200` ve ClamAV sürümü.
2. Temiz PDF → `clean`.
3. EICAR → `blocked` ve indirilemez.
4. Hash uyuşmazlığı/erişilemeyen URL → `failed`; stale iş üç denemeden sonra tekrar alınmaz.

Resmi dağıtım referansı: <https://docs.cloud.google.com/run/docs/deploying>
