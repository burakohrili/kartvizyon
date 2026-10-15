import 'dart:io';

import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'mobile_services.dart';

enum StoreBillingFailure {
  configurationUnavailable,
  offeringUnavailable,
  sessionRequired,
  purchaseCancelled,
  purchaseFailed,
  restoreFailed,
}

class StoreBillingException implements Exception {
  const StoreBillingException(this.failure, {this.cancelled = false});
  final StoreBillingFailure failure;
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
        StoreBillingFailure.configurationUnavailable,
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
        StoreBillingFailure.offeringUnavailable,
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
          StoreBillingFailure.purchaseCancelled,
          cancelled: true,
        );
      }
      throw const StoreBillingException(StoreBillingFailure.purchaseFailed);
    }
  }

  Future<CustomerInfo> restore() async {
    try {
      return await Purchases.restorePurchases();
    } on PlatformException {
      throw const StoreBillingException(StoreBillingFailure.restoreFailed);
    }
  }

  static Future<void> signOutIfConfigured() async {
    if (await Purchases.isConfigured && !(await Purchases.isAnonymous)) {
      await Purchases.logOut();
    }
  }
}
