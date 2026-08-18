# ADR-0006 — Saha modu: kullanıcının başlattığı yakınlık hatırlatması

- Durum: kabul edildi
- Tarih: 18 Ağustos 2026
- İlgili: ADR-0002 (production servisleri), `CLAUDE.md` ürün ilkeleri

## Bağlam

Pazarlama sayfası "Kullanıcı yakın müşteriye **geldiğinde** tek seferlik öneri
gösterir" diyordu. Kod ise yalnız kullanıcı Harita ekranını açıp
**"Yakınımdakileri bul"** butonuna bastığında çalışıyordu. Mobil uygulamada
hiçbir bildirim altyapısı yoktu.

Yani vaat ile uygulama arasında bir boşluk vardı ve bu boşluk aylardır
görünmüyordu; kullanıcı "elle girdiğim müşteri için nasıl bildirim gidecek"
diye sorana kadar kimse fark etmedi.

Sunucu tarafı bu iş için zaten tasarlanmıştı ve kullanılmıyordu:

- `/api/geofence/candidates` — mesafe, geciken görev ve son ziyaret tarihine
  göre önceliklendirme
- `geofence_events` — kullanıcı × müşteri bazında 24 saatlik tekrar kilidi,
  `outcome` alanı `shown` / `briefing_opened` / `navigation_opened` / `dismissed`
- `/api/briefings/[id]` ve brifing ekranı — "son ziyaretinde ne olmuş"

Eksik olan tek şey tetikleyiciydi.

## Karar

**Kullanıcının başlattığı, görünür çalışan, kendiliğinden kapanan saha modu.**

- Kullanıcı Bugün ekranından **"Saha modunu başlat"** der.
- Android: konum tipli **ön plan servisi**, kalıcı sistem bildirimiyle.
- iOS: `When In Use` + `allowsBackgroundLocationUpdates` + **mavi konum
  göstergesi açık**.
- 250 m hareket eşiği; 1,5 km yarıçaptaki müşteri için yerel bildirim.
- Bildirim firma adı, mesafe, **son ziyaretten bu yana geçen gün** ve geciken
  takip sayısını taşır; dokununca brifing açılır.
- Oturum 8 saat sonra **veya** saat 21:00'de kendiliğinden kapanır; kullanıcı
  her an durdurabilir.

**Uygulama tamamen kapalıyken bildirim gönderilmez.** Bu bilinçli bir sınırdır.

## Reddedilen alternatifler

### Tam arka plan geofencing

Uygulama kapalıyken de bildirim üretirdi. Reddedilme gerekçeleri:

| Maliyet          | Ayrıntı                                                                                                                     |
| ---------------- | --------------------------------------------------------------------------------------------------------------------------- |
| Play beyan formu | `ACCESS_BACKGROUND_LOCATION` ayrı beyan + 3-5 gün manuel inceleme; sonrasında haftalarca "pending publication" ve red riski |
| Apple `Always`   | Gerekçelendirme zorunlu; uygulama sonlandırıldıktan sonra geofence ile yeniden başlatma yalnız bu yetkiyle mümkün           |
| Mağaza beyanları | App Privacy ve Data Safety yeniden beyan edilir                                                                             |
| Ürün ilkesi      | `CLAUDE.md` "sürekli GPS takibi yapılmaz" maddesi değiştirilmek zorunda kalırdı                                             |
| Güvenilirlik     | Samsung/Xiaomi pil yönetimi servisi sessizce öldürür; kullanıcı "bildirim gelmiyor" der, sebebi görünmez                    |

Türkiye pazarının OEM dağılımı düşünüldüğünde, izin alınsa bile özelliğin
güvenilir çalışmayacağı değerlendirildi.

### GPRS / baz istasyonu üzerinden konum

İzin sorununu çözmez: `ACCESS_COARSE_LOCATION` da arka planda aynı izin
rejimine tabidir — hassasiyet düşer, izin gereksinimi aynı kalır. Operatör
tabanlı LBS API'leri bireysel geliştiriciye kapalıdır ve gizlilik açısından
daha ağır bir yüzey açar.

### Konumsuz, yalnız plan tabanlı hatırlatma

Sabah planlanan rotaya göre saat tabanlı bildirim. Konum izni hiç gerektirmez
ama "yolun üstünden geçerken" senaryosunu karşılamaz. Saha modunu tamamlayıcı
ikinci katman olarak ileride değerlendirilebilir; bu ADR kapsamı dışında.

## `CLAUDE.md` ilkesiyle ilişki

**"Sürekli GPS takibi yapılmaz" ilkesi korunmaktadır.** Gerekçe:

1. Mod **kullanıcı tarafından başlatılır**; varsayılan kapalıdır.
2. Çalıştığı **gizlenmez** — Android'de kalıcı bildirim, iOS'ta mavi çubuk.
3. **Kendiliğinden kapanır**; unutulan oturum gece boyu çalışmaz.
4. **Kullanıcının konumu hiçbir yere yazılmaz.** `geofence_events` yalnız
   firma kimliği, mesafe, öncelik puanı ve sonuç tutar; enlem/boylam saklanmaz.

Bu dört madde birlikte sağlanmadıkça saha modu genişletilmemelidir.

## Sonuçlar

**Eklenen izinler**

- Android: `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`, `POST_NOTIFICATIONS`
- iOS: `UIBackgroundModes: location`

**Bilinçli olarak eklenmeyenler**

- `ACCESS_BACKGROUND_LOCATION`
- `NSLocationAlwaysAndWhenInUseUsageDescription`

Ön plan servisi uygulama görünürken başlatıldığı için arka plan konum izni
gerekmez; bu, Play beyan formunu tetiklememenin de tek yoludur.

**App Privacy ve Data Safety değişmez** — konum zaten `Precise Location` /
`App Functionality` / izleme yok olarak beyan edilmiştir, amaç değişmemiştir.

**Testlerle sabitlenenler** (`apps/mobile/test/store_compliance_test.dart`)

- `ACCESS_BACKGROUND_LOCATION` beyan edilmemeli
- `NSLocationAlwaysAndWhenInUseUsageDescription` bulunmamalı
- `UIBackgroundModes` varsa `showBackgroundLocationIndicator: true` olmalı —
  arka plan konumu kullanıcıdan gizlenemez
- Saha modu bir durdurma yolu ve otomatik kapanma süresi içermeli

**Mağaza metinleri** — "arka plan konumu kullanılmaz" ifadesi artık yanlıştır
ve düzeltilmiştir; reviewer notu saha modunu açıkça anlatır.
