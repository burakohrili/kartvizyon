import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizyon_mobile/features/field_mode/field_mode_service.dart';

void main() {
  group('saha modu yerel kapanış saati', () {
    test('erken başlayan vardiyayı sekiz saat sonra kapatır', () {
      final start = DateTime(2026, 9, 3, 9, 15);

      expect(
        FieldModeService.sessionEndFor(start),
        DateTime(2026, 9, 3, 17, 15),
      );
    });

    test('geç başlayan vardiyayı aynı gün 21.00’de kapatır', () {
      final start = DateTime(2026, 9, 3, 16, 30);

      expect(FieldModeService.sessionEndFor(start), DateTime(2026, 9, 3, 21));
    });

    test('21.00 sonrası ertesi sabaha taşımak yerine başlangıcı reddeder', () {
      final start = DateTime(2026, 9, 3, 22);

      expect(FieldModeService.sessionEndFor(start), start);
    });
  });
}
