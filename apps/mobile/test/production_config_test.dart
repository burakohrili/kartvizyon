import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizyon_mobile/core/mobile_services.dart';
import 'package:kartvizyon_mobile/features/auth/login_screen.dart';

void main() {
  test('production API is the safe default', () {
    expect(
      MobileConfig.fromEnvironment().apiBaseUrl,
      'https://app.kartvizyon.app',
    );
  });

  test('auth callback uses the KartVizyon application scheme', () {
    expect(authCallbackUrl, 'app.kartvizyon.mobile://login-callback');
  });
}
