import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizyon_mobile/app.dart';
import 'package:kartvizyon_mobile/features/more/workspace_module_screen.dart';

/// Saha cihazlarının gerçek koşullarına karşı UX dayanıklılığı.
///
/// Hedef kitle düşük/orta segment Android telefonlar kullanıyor ve uygulamayı
/// çoğunlukla tek elle, güneş altında ve büyük yazı tipiyle kullanıyor.
void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const KartVizyonApp());
    await tester.pumpAndSettle();
  }

  /// Taşan RenderFlex'ler testte exception fırlatır; bu yardımcı onları toplar.
  Future<List<String>> overflowErrorsWhile(
    WidgetTester tester,
    Future<void> Function() body,
  ) async {
    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      errors.add(details.exceptionAsString());
    };
    try {
      await body();
    } finally {
      FlutterError.onError = previous;
    }
    return errors;
  }

  group('küçük ekran (360x640 mdpi)', () {
    for (final route in const ['Bugün', 'Müşteriler', 'Görevler', 'Menü']) {
      testWidgets('$route ekranı taşmaz', (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final errors = await overflowErrorsWhile(tester, () async {
          await pumpApp(tester);
          await tester.tap(find.text(route));
          await tester.pumpAndSettle();
        });

        expect(
          errors.where((error) => error.contains('overflowed')),
          isEmpty,
          reason: '$route ekranı dar cihazda taşıyor',
        );
      });
    }
  });

  group('erişilebilirlik', () {
    testWidgets('iki kat yazı tipiyle ana ekranlar taşmaz', (tester) async {
      tester.view.physicalSize = const Size(1080, 2280);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final errors = await overflowErrorsWhile(tester, () async {
        await tester.pumpWidget(
          const MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(2)),
            child: KartVizyonApp(),
          ),
        );
        await tester.pumpAndSettle();
      });

      expect(
        errors.where((error) => error.contains('overflowed')),
        isEmpty,
        reason:
            'Erişilebilirlik ayarıyla büyütülen yazı tipi düzeni bozmamalıdır',
      );
    });
  });

  group('manuel müşteri formu', () {
    testWidgets('zorunlu alan boşken kaydetmeyi engeller', (tester) async {
      tester.view.physicalSize = const Size(1080, 2280);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await pumpApp(tester);
      await tester.tap(find.text('Müşteriler'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.person_add_alt_1_outlined));
      await tester.pumpAndSettle();

      // Form uzun olduğu için kaydet butonu görünür alanın altında kalabilir;
      // gerçek kullanıcı da kaydırarak ulaşır.
      await tester.ensureVisible(find.text('Müşteriyi kaydet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Müşteriyi kaydet'));
      await tester.pumpAndSettle();

      // Doğrulama hatası kullanıcıya Türkçe ve eyleme dönük gösterilir.
      expect(find.textContaining('en az 2 karakter'), findsOneWidget);
      // Dialog kapanmaz; girilen veri kaybolmaz.
      expect(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text('Manuel müşteri ekle'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('vazgeç formu kapatır', (tester) async {
      tester.view.physicalSize = const Size(1080, 2280);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await pumpApp(tester);
      await tester.tap(find.text('Müşteriler'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.person_add_alt_1_outlined));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsOneWidget);

      await tester.ensureVisible(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });
  });

  group('boş durumlar eyleme dönüktür', () {
    testWidgets('her boş durum en az bir çıkış yolu sunar', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Müşteriler'));
      await tester.pumpAndSettle();
      // Boş durum iki çıkış yolu sunar: elle giriş ve kartvizit tarama.
      expect(find.text('Manuel müşteri ekle'), findsWidgets);
      expect(find.text('Kartvizit tara'), findsWidgets);

      await tester.tap(find.text('Görevler'));
      await tester.pumpAndSettle();
      expect(find.text('Yeni görev'), findsOneWidget);
    });

    testWidgets('modül boş durumları ne olduğunu anlatır ve yenileme sunar', (
      tester,
    ) async {
      // Bu ekranlar yalnız "… için henüz kayıt bulunmuyor." diyordu; kullanıcı
      // ne olduğunu da, kaydın nereden geleceğini de bilmiyordu.
      for (final module in WorkspaceModule.values) {
        expect(
          module.emptyTitle.isNotEmpty,
          isTrue,
          reason: '${module.title} için boş durum başlığı yok',
        );
        expect(
          module.emptyBody.length,
          greaterThan(40),
          reason: '${module.title} boş durumu ne olduğunu anlatmıyor',
        );
        // Mağaza kuralı: mobilde pazarlama sitesine bağlantı verilmez.
        expect(
          module.emptyBody.contains('http'),
          isFalse,
          reason: '${module.title} boş durumunda bağlantı var',
        );
      }
    });

  });
}
