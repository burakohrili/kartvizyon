import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizyon_mobile/app.dart';
import 'package:kartvizyon_mobile/core/ui_locale_preference.dart';

class _EnglishLocaleStore implements UiLocalePreferenceStore {
  @override
  Future<String?> read() async => 'en';

  @override
  Future<void> write(String languageCode) async {}
}

void main() {
  testWidgets('English navigation and primary routes fit a compact phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final overflows = <String>[];
    final previousHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      overflows.add(details.exceptionAsString());
    };
    try {
      await tester.pumpWidget(
        KartVizyonApp(localePreferenceStore: _EnglishLocaleStore()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsOneWidget);

      for (final label in const ['Customers', 'Tasks', 'Menu']) {
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }
    } finally {
      FlutterError.onError = previousHandler;
    }

    expect(
      overflows.where((message) => message.contains('overflowed')),
      isEmpty,
      reason: 'English navigation labels must fit a 360×640 phone layout.',
    );
  });
}
