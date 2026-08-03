import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizyon_mobile/app.dart';

void main() {
  testWidgets('Türkçe saha özeti ve navigasyonu açılır', (tester) async {
    await tester.pumpWidget(const KartVizyonApp());
    await tester.pumpAndSettle();
    expect(find.text('Bugünün saha özeti'), findsOneWidget);
    expect(find.text('Müşteriler'), findsOneWidget);
    expect(find.text('Ziyaret'), findsOneWidget);
    expect(find.text('Görevler'), findsOneWidget);
    expect(find.text('Menü'), findsOneWidget);

    await tester.tap(find.text('Ziyaret'));
    await tester.pumpAndSettle();
    expect(find.text('Ziyaretler'), findsOneWidget);
  });
}
