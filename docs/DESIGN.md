# KartVizyon mobil deneyim sistemi

Durum: Uygulama planı · Sürüm 1.0 · 3 Ağustos 2026

## Uygulanan temel

- Gece laciverti, elektrik mavi, lime ve sıcak kırık beyaz tokenları Flutter temasına işlendi.
- Kalıcı navigasyon `Bugün / Müşteriler / Ziyaret / Görevler / Menü` olarak uygulandı; harita Menü içindeki saha aracına taşındı.
- Orta ziyaret eylemi en az 48 pt dokunma hedefi, semantik etiket ve tek adımlı ziyaret akışı taşır.
- Tab geçişleri 280 ms kısa fade/slide kullanır; cihazda hareket azaltma açıksa 120 ms fade'e düşer.
- Kart, buton ve form radius/boşlukları tasarım tokenlarıyla birleştirildi.
- Özgün, yazısız ve opak 1024×1024 mağaza ikonu `assets/store/app-icon-1024.png`; mobil kaynak `apps/mobile/assets/branding/app-icon-1024.png` olarak eklendi.

Sonraki görsel QA; Codemagic iOS simülatör ekran görüntüsü, fiziksel Android 200% metin ölçeği ve VoiceOver/TalkBack turudur. Bu kontroller yapılmadan ödül/mağaza hazır iddiası kullanılmaz.

## Tasarım hedefi

KartVizyon “saha satışının hafıza katmanı” gibi hissettirmelidir: hızlı, sakin, bağlamı kaybetmeyen ve AI’ın ne yaptığını açıkça gösteren. Görsel iddia; alışılmadık menülerden değil, doğru bilgi hiyerarşisi, akıcı durum geçişleri ve ayrıntı kalitesinden gelir.

Referans çerçevesi: [Awwwards Mobile Excellence](https://www.awwwards.com/mobile-excellence-guidelines.pdf), [Apple HIG tasarım ilkeleri](https://developer.apple.com/design/human-interface-guidelines/design-principles), [Apple HIG motion](https://developer.apple.com/design/human-interface-guidelines/motion) ve Material 3 uyarlanabilir bileşenleri. Tasarım hiçbir ürünü kopyalamaz; ölçütleri KartVizyon’un saha bağlamına çevirir.

## Ana navigasyon

Beş kalıcı hedef kullanılır; tab bar yalnız navigasyon içindir:

1. **Bugün** — brifing, yaklaşan ziyaret, geciken takip, offline durum.
2. **Müşteriler** — arama, yakın müşteriler, hafıza kartı.
3. **Ziyaret** — ortadaki belirgin “oluştur” girişi; tab gibi görünse de yeni ziyaret akışını açar.
4. **Görevler** — kişisel ve ekip takipleri.
5. **Daha Fazla** — raporlar, belgeler, formlar, profil, güvenlik ve veri hakları.

Tab seçimi çalışma oturumu boyunca korunur. Detay sayfaları aynı tabın üstüne push edilir; geri hareketi kullanıcıyı önceki filtre ve scroll konumuna döndürür. Yöneticiye özel içerik tab eklemez, rol içinde görünür.

## Bilgi mimarisi

```text
Bugün
├── Günlük odak
├── Sıradaki ziyaret brifingi
├── Geciken takipler
└── Senkronizasyon durumu
Müşteriler
├── Arama / filtre / yakınlık
├── Müşteri hafıza kartı
├── Zaman çizgisi
└── Kişiler / fırsatlar / belgeler
Ziyaret
├── Müşteri seç
├── Amaç ve zaman
├── Saha modu
└── Debrief → AI taslak → insan onayı
Görevler
├── Bugün / geciken / yaklaşan
└── Görev detayı
Daha Fazla
├── Raporlar / formlar / belgeler
├── Offline ve eşitleme merkezi
├── Paket ve kullanım (ödeme kararı sonrası)
└── Güvenlik / KVKK / hesabı sil
```

## Görsel dil

- **Ana renk:** gece laciverti `#101C3D`; güven ve kurumsal hafıza.
- **Eylem:** elektrik mavi `#2D5BFF`; aynı ekranda yalnız bir birincil eylem.
- **Canlı vurgu:** lime `#DFFF65`; başarı, online ve AI taslak işareti. Uzun metinde kullanılmaz.
- **Zemin:** sıcak kırık beyaz `#F5F1E9`; parlak beyaz kartlarla katman.
- **Durum:** hata `#B42318`, uyarı `#B54708`, başarı `#16794B`; renk her zaman ikon ve metinle desteklenir.
- 8 pt grid; ekran yatay boşluğu 20 pt, kart radius 22–28 pt, tab bar dokunma alanı en az 48 pt.
- Başlıklar yoğun ama kısa; gövde 16 pt ve en az 1.45 satır yüksekliği. Dynamic Type / text scaling 200%’e kadar kırılmadan çalışır.

## İmza etkileşimleri

### Brifing kartı

Kart açılırken müşteri adı ve zaman bilgisi shared-axis ile devam eder; zaman çizelgesi bölümleri 40 ms kademeyle görünür. “3 onaylı kaynaktan” etiketi AI güvenini somutlaştırır.

### Sesli debrief

Kayıt düğmesi waveform’dan bağımsız, sürekli görünür. Süre, durdur ve iptal metinle desteklenir. Upload/senkron beklerken kayıt cihazda şifreli kuyrukta kalır. Transkripsiyon tamamlanınca kullanıcı doğrudan taslak düzenleme ekranına gelir; “Onayla” ve “Taslağa dön” ayrıdır.

### Offline durum

Bağlantı kaybı tam ekran hata değildir. Üstte sakin bir durum kapsülü ve ilgili kayıtta “Cihazda güvenli” işareti gösterilir. Senkron geri geldiğinde liste yeniden sıçramaz; yalnız durum etiketi morph eder.

## Hareket sistemi

- Mikro geri bildirim 120–180 ms; sayfa geçişi 260–340 ms; modal 220 ms.
- Liste → detay: shared axis; eş düzey tab: kısa cross-fade; doğrulama: hafif scale + haptic.
- Scroll ile içerik kaybolmaz; büyük başlık kompakt başlığa dönüşür.
- `reduceMotion` açıkken konum/ölçek/blur animasyonları kaldırılır, 100–150 ms fade kullanılır.
- Hareket önemli bilgiyi tek başına anlatmaz. Sonsuz dekoratif loop ve güçlü paralaks yoktur.

## Erişilebilirlik kabul kriterleri

- Metin kontrastı WCAG AA; kritik metin 4.5:1.
- Tüm dokunma hedefleri en az 44×44 iOS, 48×48 Android.
- VoiceOver/TalkBack sırası görsel sırayla aynı; ikon düğmeleri eylem adı taşır.
- Renk körlüğünde durumlar ikon + metinle ayrılır.
- Kamera, mikrofon ve konum reddedildiğinde manuel alternatif vardır.
- Hesap silme iki açık onay adımı ister; diğer işlemler gereksiz zaman aşımı kullanmaz.

## Performans bütçesi

- 60 fps hedef; orta segment cihazda frame build/raster 16 ms altında.
- İlk anlamlı ekran, sıcak açılışta 800 ms; soğuk açılışta 2.5 sn hedef.
- Skeleton yalnız ağ verisi için, hazır yerel veri hemen gösterilir.
- Hero animasyonu video/GIF değildir; native compositing kullanır.
- Görseller cihaz ölçüsüne göre sıkıştırılır; gereksiz blur ve büyük shadow katmanları sınırlandırılır.

## Uygulama sırası

1. Tokenlar, tipografi, erişilebilir tab bar ve motion primitives.
2. Bugün ve müşteri zaman çizelgesi.
3. Ziyaret/debrief/AI onay akışı.
4. Offline eşitleme ve hata durumları.
5. Yönetici görünümü, rapor ve belge akışları.
6. VoiceOver/TalkBack, reduce motion, golden test ve gerçek cihaz performans profili.

Ödül iddiası teslim kriteri değildir. Mağaza kuralları, anlaşılırlık, erişilebilirlik ve saha hızından taviz veren dekorasyon kabul edilmez.
