import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizyon_mobile/app.dart';

void main() {
  testWidgets('Bugün gerçek boş özeti ve çalışan metrikleri gösterir', (
    tester,
  ) async {
    await tester.pumpWidget(const KartVizyonApp());
    await tester.pumpAndSettle();

    expect(find.text('Bugünün saha özeti'), findsOneWidget);
    expect(find.text('Planlanan ziyaret'), findsOneWidget);
    expect(find.text('Açık takip'), findsOneWidget);
    // Saha modu kartı eklendikten sonra bu satır liste altına indi.
    await tester.scrollUntilVisible(
      find.text('İlk müşterinizi ekleyin'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('İlk müşterinizi ekleyin'), findsOneWidget);

    await tester.tap(find.text('Planlanan ziyaret'));
    await tester.pumpAndSettle();
    expect(find.text('Ziyaretler'), findsOneWidget);
    expect(find.text('Henüz ziyaret yok'), findsOneWidget);
    expect(find.text('Bugün'), findsOneWidget);
    expect(find.text('Müşteriler'), findsOneWidget);
    expect(find.text('Görevler'), findsOneWidget);
    expect(find.text('Menü'), findsOneWidget);
  });

  testWidgets('Müşteriler boş durumu manuel ekleme ve tarama sunar', (
    tester,
  ) async {
    await tester.pumpWidget(const KartVizyonApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Müşteriler'));
    await tester.pumpAndSettle();
    expect(find.text('Henüz müşteri yok'), findsOneWidget);
    expect(find.text('Manuel müşteri ekle'), findsOneWidget);
    expect(find.text('Kartvizit tara'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_add_alt_1_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Firma adı *'), findsOneWidget);
    expect(find.text('İlgili kişi (isteğe bağlı)'), findsOneWidget);
    expect(find.text('Müşteriyi kaydet'), findsOneWidget);
  });

  testWidgets('Manuel müşteri formu klavye açıkken görünür kalır', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const KartVizyonApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Müşteriler'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_add_alt_1_outlined));
    await tester.pumpAndSettle();

    final dialogScroll = find.descendant(
      of: find.byType(Dialog),
      matching: find.byType(SingleChildScrollView),
    );
    final closedHeight = tester.getRect(dialogScroll).height;
    expect(closedHeight, greaterThan(200));

    // Klavye açılır. Dialog klavye boşluğunu kendisi uyguladığı için form
    // alanı daralır ama kaydırılabilir yüksekliğini korumalıdır.
    tester.view.viewInsets = const FakeViewPadding(bottom: 1000);
    await tester.pumpAndSettle();

    final openedHeight = tester.getRect(dialogScroll).height;
    expect(
      openedHeight,
      greaterThan(200),
      reason:
          'Klavye boşluğu iki kez uygulanırsa form yüksekliği sıfıra iner ve '
          'kullanıcı boş bir kutu görür.',
    );
    expect(find.text('Firma adı *'), findsOneWidget);
    expect(find.text('Müşteriyi kaydet'), findsOneWidget);
  });

  testWidgets('Görevler boş durumu ve manuel görev CTA gösterir', (
    tester,
  ) async {
    await tester.pumpWidget(const KartVizyonApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Görevler'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Henüz görev yok'), findsOneWidget);
    expect(find.text('Yeni görev'), findsOneWidget);
  });

  testWidgets('Menü uygulama sürümünü gösterir', (tester) async {
    // Kapalı testte hata bildiren kullanıcı hangi derlemeyi kullandığını
    // söyleyebilmeli; bu satır kaybolursa bildirimler izlenemez hale gelir.
    await tester.pumpWidget(const KartVizyonApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Menü'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Uygulama sürümü'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Uygulama sürümü'), findsOneWidget);
  });

  testWidgets('Menü alt sayfa bağlantılarını gösterir', (tester) async {
    await tester.pumpWidget(const KartVizyonApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Menü'));
    await tester.pumpAndSettle();
    expect(find.text('Daha fazla'), findsOneWidget);
    expect(find.text('Saha haritası'), findsOneWidget);
    expect(find.text('Ziyaretler ve sesli not'), findsOneWidget);
    expect(find.text('Eşitleme merkezi'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Rapor özeti'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Aktivite'), findsOneWidget);
    expect(find.text('Rapor özeti'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('KVKK ve veri hakları'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('KVKK ve veri hakları'), findsOneWidget);
    expect(find.text('Tüm cihazlardan çıkış'), findsOneWidget);
  });
}
