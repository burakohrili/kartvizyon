import '../l10n/app_localizations.dart';

bool serverPremiumConfirmed(Map? entitlement) =>
    entitlement?['readOnly'] == false && entitlement?['trialActive'] == false;

String billingReconciliationMessage({
  required bool restoring,
  required bool storeActive,
  required bool serverConfirmed,
  required bool sandboxPurchase,
  required String apiBaseUrl,
  required AppLocalizations l10n,
}) {
  if (!storeActive) {
    return restoring
        ? l10n.billingRestoreNoActivePurchase
        : l10n.billingPurchaseAwaitingStore;
  }
  final host = Uri.tryParse(apiBaseUrl)?.host;
  if (sandboxPurchase &&
      (host == 'app.kartvizyon.app' || host == 'kartvizyon.app')) {
    return l10n.billingSandboxLiveServerWarning;
  }
  if (!serverConfirmed) {
    return l10n.billingServerAccessPending;
  }
  return restoring ? l10n.billingRestoreSuccess : l10n.billingPurchaseSuccess;
}
