import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ADR-0004 değişmez kuralı: mobil uygulamada fiyat, satın alma yüzeyi veya
/// `kartvizyon.app` fiyat sayfasına tıklanabilir yönlendirme bulunmaz.
/// Apple 3.1.1 ve Google Play ödeme politikası reddi bu kuralla önlenir.
void main() {
  final dartSources = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList();

  test('mobil kaynaklarda satın alma yüzeyi yoktur', () {
    // Sadece ödeme/abonelik satışına özgü ifadeler aranır. Ürün kataloğundaki
    // "ürün ve fiyatlar" ekranı müşteriye satılan malın listesidir, abonelik
    // değildir; bu yüzden genel "fiyat" kelimesi kapsam dışıdır.
    final forbidden = <RegExp>[
      RegExp(r'satın al', caseSensitive: false),
      RegExp(r'abonelik', caseSensitive: false),
      RegExp(r'\bpaywall\b', caseSensitive: false),
      RegExp(r'in_app_purchase'),
      RegExp(r'billingclient', caseSensitive: false),
      RegExp(r'planı yükselt', caseSensitive: false),
    ];

    final violations = <String>[];
    for (final file in dartSources) {
      final content = file.readAsStringSync();
      for (final pattern in forbidden) {
        if (pattern.hasMatch(content)) {
          violations.add('${file.path}: ${pattern.pattern}');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'ADR-0004: mobilde satın alma yüzeyi açılacaksa önce IAP entegrasyonu '
          've kurumsal/bireysel ayrımı uygulanmalıdır.',
    );
  });

  test('iOS yalnız fiilen kullanılan izinleri beyan eder', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final sources = dartSources.map((f) => f.readAsStringSync()).join();

    // Korunan asıl değişmez: When In Use anahtarı bulunmalı.
    //
    // geolocator (geolocator_apple PermissionHandler.m) önce bu anahtara bakar
    // ve varsa `requestWhenInUseAuthorization` çağırır; Always dalına yalnız bu
    // anahtar YOKKEN girer. Yani bu anahtar kaldırılırsa uygulama sessizce
    // "Her Zaman" yetkisi istemeye başlar ve ürün sözü çiğnenir.
    //
    // `NSLocationAlwaysAndWhenInUseUsageDescription` 19 Ağustos 2026'da
    // bilinçli olarak eklendi: Apple'ın statik denetimi bağlı SDK'lar
    // yüzünden ITMS-90683 üretiyordu. Anahtarın varlığı yukarıdaki dal
    // sırasını değiştirmediği için yetki yükselmesi olmaz (ADR-0006).
    expect(
      plist.contains('NSLocationWhenInUseUsageDescription'),
      isTrue,
      reason:
          'Bu anahtar kaldırılırsa geolocator Always yetkisi istemeye başlar.',
    );

    // Eski, iOS 11 öncesi Always anahtarı hiç kullanılmamalı; onun tek etkisi
    // Always yetkisi istemek olurdu.
    expect(
      plist.contains('<key>NSLocationAlwaysUsageDescription</key>'),
      isFalse,
      reason: 'Yalnız Always anahtarı beyan edilmemeli.',
    );

    // Beyan edilen her izin kodda fiilen kullanılmalıdır.
    final kullanim = {
      'NSCameraUsageDescription': 'ImageSource.camera',
      'NSPhotoLibraryUsageDescription': 'ImageSource.gallery',
      'NSMicrophoneUsageDescription': 'record',
      'NSLocationWhenInUseUsageDescription': 'Geolocator',
    };
    kullanim.forEach((anahtar, iz) {
      if (plist.contains(anahtar)) {
        expect(
          sources.contains(iz),
          isTrue,
          reason: '$anahtar beyan edilmiş ama kodda $iz kullanımı yok.',
        );
      }
    });
  });

  test(
    'konum izni reddedilirse belgelenen alternatifler koda karsilik gelir',
    () {
      // docs/STORE_RELEASE.md izin tablosu: konumun alternatifi "müşteri arama
      // ve manuel adres", kameranınki "galeri veya manuel giriş". Alternatif
      // koda karşılık gelmezse hem reviewer hem kullanıcı çıkmazda kalır.
      final customers = File(
        'lib/features/customers/customers_screen.dart',
      ).readAsStringSync();

      expect(
        customers.contains('q=') ||
            customers.contains('Uri.encodeQueryComponent'),
        isTrue,
        reason: 'Konum alternatifi olarak beyan edilen müşteri araması yok.',
      );
      expect(
        customers.contains('ImageSource.gallery'),
        isTrue,
        reason: 'Kamera alternatifi olarak beyan edilen galeri seçimi yok.',
      );

      // Mikrofon alternatifi metin notudur.
      final debrief = File(
        'lib/features/visits/debrief_screen.dart',
      ).readAsStringSync();
      expect(
        debrief.contains('TextField'),
        isTrue,
        reason: 'Mikrofon alternatifi olarak beyan edilen metin notu yok.',
      );
    },
  );

  test('Android arka plan konum izni istemez', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    // Yalnız gerçek izin beyanı aranır; açıklama satırında geçmesi sorun
    // değildir, hatta neden eklenmediğini anlatması istenir.
    final declared = RegExp(
      r'<uses-permission[^>]*android:name="android\.permission\.([A-Z_]+)"',
    ).allMatches(manifest).map((m) => m.group(1)).toSet();

    expect(
      declared.contains('ACCESS_BACKGROUND_LOCATION'),
      isFalse,
      reason:
          'Arka plan konum izni Play beyan formunu ve haftalarca süren '
          'incelemeyi tetikler; saha modu ön plan servisiyle çalışır.',
    );
  });

  test('saha modu durdurulabilir ve kendiliğinden kapanır', () {
    // Başlatılıp kapatılamayan ya da unutulunca gece boyu pil yakan bir mod
    // yayınlanamaz.
    final service = File(
      'lib/features/field_mode/field_mode_service.dart',
    ).readAsStringSync();

    expect(service.contains('Future<void> stop('), isTrue);
    expect(service.contains('sessionLimit'), isTrue);
    expect(service.contains('autoStopHour'), isTrue);
  });

  test('arka planda konum alınıyorsa gösterge gizlenmez', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final service = File(
      'lib/features/field_mode/field_mode_service.dart',
    ).readAsStringSync();

    if (plist.contains('UIBackgroundModes')) {
      expect(
        service.contains('showBackgroundLocationIndicator: true'),
        isTrue,
        reason:
            'iOS mavi konum çubuğu kapatılırsa kullanıcı arka plan konumundan '
            'habersiz kalır; Always yetkisi istemediğimiz için bu zorunludur.',
      );
    }
  });

  test('yenileme hatasi uygulamayi cokertmez', () {
    // 18 Ağustos 2026 production çökmesi: RefreshIndicator.onRefresh içinden
    // fırlatılan hata Flutter tarafından yakalanmıyor ve uygulama fatal
    // hatayla kapanıyor (Sentry: MobileApiException, /api/session).
    // Hata zaten FutureBuilder'da gösterildiği için yenileme yolunda
    // yutulmalıdır; her yenileyen ekran settleRefresh kullanmalıdır.
    final violations = <String>[];
    for (final file in dartSources) {
      if (file.path.endsWith('refresh.dart')) continue;
      final content = file.readAsStringSync();
      if (!content.contains('onRefresh')) continue;
      if (!content.contains('settleRefresh')) violations.add(file.path);
    }
    expect(
      violations,
      isEmpty,
      reason:
          'Yenileyen ekran settleRefresh kullanmalı; aksi halde ağ hatası '
          'uygulamayı çökertir.',
    );
  });

  test('mobil kaynaklarda pazarlama sitesine yönlendirme yoktur', () {
    final violations = <String>[];
    for (final file in dartSources) {
      final content = file.readAsStringSync();
      // API tabanı `app.kartvizyon.app` meşrudur; yasak olan public pazarlama
      // sitesine (fiyat sayfası dahil) tıklanabilir yönlendirmedir.
      final matches = RegExp(
        r'https://(?!app\.)kartvizyon\.app[^\s"'
        r"'"
        r']*',
      ).allMatches(content);
      for (final match in matches) {
        violations.add('${file.path}: ${match.group(0)}');
      }
    }

    expect(violations, isEmpty);
  });

  test('Android derlemesi API 36 hedefler', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();

    expect(gradle.contains('compileSdk = 36'), isTrue);
    expect(
      gradle.contains('targetSdk = 36'),
      isTrue,
      reason:
          'Google Play 31 Ağustos 2026 itibarıyla güncellemelerde Android 16 '
          '(API 36) hedefi ister; Flutter varsayılanı dolaylı kullanılmamalı.',
    );
  });
}
