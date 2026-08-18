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

    // Arka plan/"Always" konum anahtarı, geolocator'ın iOS'ta Always yetkisi
    // istemesine yol açar. Ürün sözü "sürekli GPS takibi yapılmaz" olduğu için
    // bu anahtar bulunmamalıdır (App Review 5.1.1).
    expect(
      plist.contains('NSLocationAlwaysAndWhenInUseUsageDescription'),
      isFalse,
      reason:
          'Uygulama arka plan konumu kullanmıyor; Always anahtarı beyan edilmemeli.',
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
    expect(manifest.contains('ACCESS_BACKGROUND_LOCATION'), isFalse);
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
}
