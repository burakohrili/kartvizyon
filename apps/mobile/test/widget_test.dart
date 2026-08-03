import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizyon_mobile/app.dart';

void main() {
  testWidgets('Türkçe saha özeti ve navigasyonu açılır', (tester) async {
    await tester.pumpWidget(const KartVizyonApp());
    await tester.pumpAndSettle();
    expect(find.text('Bugünün saha özeti'), findsOneWidget);
    expect(find.text('Müşteriler'), findsOneWidget);
    expect(find.text('Harita'), findsOneWidget);
    expect(find.text('Takipler'), findsOneWidget);
    expect(find.text('Daha fazla'), findsOneWidget);

    await tester.tap(find.byTooltip('Hızlı ziyaret kaydı'));
    await tester.pumpAndSettle();
    expect(find.text('Ziyaretler'), findsOneWidget);
  });
}
