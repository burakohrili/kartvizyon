import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizyon_mobile/core/apple_subscription_management.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(
    () => messenger.setMockMethodCallHandler(
      AppleSubscriptionManagement.channel,
      null,
    ),
  );

  test(
    'opens the native StoreKit subscription sheet without account URLs',
    () async {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(AppleSubscriptionManagement.channel, (
        call,
      ) async {
        calls.add(call);
        return null;
      });
      await AppleSubscriptionManagement.show();
      expect(calls.single.method, 'showManageSubscriptions');
      expect(calls.single.arguments, isNull);
    },
  );

  test('propagates native errors so the screen can display failure', () async {
    messenger.setMockMethodCallHandler(
      AppleSubscriptionManagement.channel,
      (_) async => throw PlatformException(code: 'NO_ACTIVE_SCENE'),
    );
    await expectLater(
      AppleSubscriptionManagement.show(),
      throwsA(isA<PlatformException>()),
    );
  });
}
