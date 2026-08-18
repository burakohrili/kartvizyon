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

  test('mobil kaynaklarda pazarlama sitesine yönlendirme yoktur', () {
    final violations = <String>[];
    for (final file in dartSources) {
      final content = file.readAsStringSync();
      // API tabanı `app.kartvizyon.app` meşrudur; yasak olan public pazarlama
      // sitesine (fiyat sayfası dahil) tıklanabilir yönlendirmedir.
      final matches = RegExp(
        r'https://(?!app\.)kartvizyon\.app[^\s"' r"'" r']*',
      ).allMatches(content);
      for (final match in matches) {
        violations.add('${file.path}: ${match.group(0)}');
      }
    }

    expect(violations, isEmpty);
  });
}
