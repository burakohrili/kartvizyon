import 'package:flutter/services.dart';

/// Uses StoreKit's in-app sheet, including for TestFlight subscriptions.
class AppleSubscriptionManagement {
  static const channel = MethodChannel('app.kartvizyon.mobile/subscriptions');

  static Future<void> show() =>
      channel.invokeMethod<void>('showManageSubscriptions');
}
