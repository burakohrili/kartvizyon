import 'dart:io';

import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'mobile_services.dart';

class StoreBillingException implements Exception {
  const StoreBillingException(this.message, {this.cancelled = false});
  final String message;
  final bool cancelled;
}

class StoreBillingService {
  StoreBillingService(this.config);
  final MobileConfig config;

  Future<void> identify(String userId) async {
    final apiKey = Platform.isIOS
        ? config.revenueCatAppleApiKey
        : config.revenueCatGoogleApiKey;
    if (apiKey.isEmpty) {
      throw const StoreBillingException(
        'Mağaza ödeme yapılandırması henüz tamamlanmadı.',
      );
    }
    if (!await Purchases.isConfigured) {
      await Purchases.setLogLevel(LogLevel.warn);
      final configuration = PurchasesConfiguration(apiKey)..appUserID = userId;
      await Purchases.configure(configuration);
      return;
    }
    if (await Purchases.appUserID != userId) await Purchases.logIn(userId);
  }

  Future<List<Package>> packages() async {
    final offering = (await Purchases.getOfferings()).current;
    if (offering == null) {
      throw const StoreBillingException(
        'Bu mağaza için satın alınabilir plan bulunamadı.',
      );
    }
    return offering.availablePackages;
  }

  Future<CustomerInfo> purchase(Package package) async {
    try {
      return (await Purchases.purchase(
        PurchaseParams.package(package),
      )).customerInfo;
    } on PlatformException catch (error) {
      final code = PurchasesErrorHelper.getErrorCode(error);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        throw const StoreBillingException(
          'Satın alma iptal edildi.',
          cancelled: true,
        );
      }
      throw const StoreBillingException(
        'Satın alma tamamlanamadı. Mağaza hesabınızı kontrol edip yeniden deneyin.',
      );
    }
  }

  Future<CustomerInfo> restore() async {
    try {
      return await Purchases.restorePurchases();
    } on PlatformException {
      throw const StoreBillingException(
        'Satın almalar geri yüklenemedi. Mağaza hesabınızı kontrol edin.',
      );
    }
  }

  static Future<void> signOutIfConfigured() async {
    if (await Purchases.isConfigured && !(await Purchases.isAnonymous)) {
      await Purchases.logOut();
    }
  }
}
