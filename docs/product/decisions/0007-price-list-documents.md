# ADR-0007 — PDF fiyat listesi belge hattının üstünde

- Durum: kabul edildi
- Tarih: 18 Ağustos 2026
- İlgili: ADR-0002 (production servisleri), `docs/MOBILE_WEB_PARITY.md`

## Bağlam

Ürün kataloğu tek tek ürün ve liste fiyatı tutuyor. Sahadaki gerçek ihtiyaç
bundan farklı: müşteriyle konuşurken bakılan şey çoğu zaman **kurumun yayınladığı
PDF fiyat listesi**. Kullanıcı bunu doğrudan istedi.

Sıfırdan bir dosya hattı kurmak gerekmedi. `documents` üzerinde şunlar zaten
çalışıyor ve fiyat listesi bunların hepsine ihtiyaç duyuyor:

- karantina kovası (`document-quarantine`) — dosya taranmadan yayına çıkmaz
- MIME ve **imza** doğrulaması — uzantısı PDF olan her dosya PDF değildir
- ClamAV tarama kuyruğu (`document_scan_jobs`, 0018) — atomik sahiplenme,
  15 dakika stale retry, üç deneme sınırı
- boyut sınırı ve `usage_records` üzerinden depolama ölçümü

## Karar

**Fiyat listesi ayrı bir tablo değil, belgenin bir amacıdır.**

`documents` tablosuna `purpose` kolonu eklendi (`general` | `price_list`,
migration `0023`). Fiyat listesi yüklemesi aynı uca gider, aynı doğrulamadan ve
aynı taramadan geçer.

**İndirme yalnız `scan_status = 'clean'` olduğunda mümkündür.**
`GET /api/documents/[id]/download` 120 saniyelik imzalı bağlantı üretir; tarama
temiz değilse bağlantı hiç üretilmez ve uç 409 döner. Bağlantı loglanmaz.

**Yükleme yalnız webde, okuma her iki kanalda.** Saha çalışanı kurumun fiyat
listesini yayınlamaz; müşterinin yanında açar. Bu, `docs/MOBILE_WEB_PARITY.md`
içindeki mevcut ayrımın aynısıdır ve o dosyaya yeni bir istisna eklemez.

## Reddedilen alternatifler

**Ayrı `price_lists` dosya tablosu.** Karantina, imza doğrulaması, tarama
kuyruğu ve saklama mantığının ikinci bir kopyası gerekirdi. İki kopyadan biri er
geç geri kalır; taranmamış dosyanın indirilebildiği yol tam olarak böyle açılır.

**Fiyatı PDF'ten okuyup ürün kataloğuna yazmak.** Cazip ama yanlış: PDF'ten
okunan fiyat, kullanıcı onayı olmadan kurumsal kayda giren bir AI çıktısı olurdu.
`CLAUDE.md` bunu açıkça yasaklıyor. İleride yapılacaksa çıktı `needs_review`
durumunda başlamalı ve ayrı bir karar gerektirir.

**Mobilde fiyat listesi yükleme.** Saha çalışanına kurum çapında geçerli bir
belge yayınlama yetkisi vermek, küçük ekranda yanlış dosya seçme riskiyle
birlikte gelir. Okuma yeter.

## Sonuçlar

- `documents.purpose` (`0023_document_purpose`), rollback ile birlikte
- `GET /api/documents?purpose=price_list` — süzülmüş listeleme
- `GET /api/documents/[id]/download` — imzalı bağlantı; JSON isteyen istemciye
  bağlantı, tarayıcıya 303 yönlendirme (bearer token ile çalışan Dart istemcisi
  yönlendirmeyi kullanamıyor)
- Web: ürün sayfasında fiyat listesi yükleme ve indirme
- Mobil: "Ürün ve fiyatlar" ekranında fiyat listeleri katalogun üstünde; tarama
  sürerken dokunulamaz, temizse harici tarayıcıda açılır
- Fiyat listesi PDF olmak zorundadır; başka tür 415 döner
