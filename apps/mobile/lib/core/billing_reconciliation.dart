bool serverPremiumConfirmed(Map? entitlement) =>
    entitlement?['readOnly'] == false && entitlement?['trialActive'] == false;

String billingReconciliationMessage({
  required bool restoring,
  required bool storeActive,
  required bool serverConfirmed,
  required bool sandboxPurchase,
  required String apiBaseUrl,
}) {
  if (!storeActive) {
    return restoring
        ? 'Bu mağaza hesabında geri yüklenecek aktif satın alma bulunamadı.'
        : 'Satın alma alındı; mağaza doğrulaması bekleniyor.';
  }
  final host = Uri.tryParse(apiBaseUrl)?.host;
  if (sandboxPurchase &&
      (host == 'app.kartvizyon.app' || host == 'kartvizyon.app')) {
    return 'Test satın almanız mağazada aktif. Bu sürüm canlı sunucuya bağlı; '
        'Sandbox satın almaları canlı erişimi açmaz. Test sunucusuna bağlı '
        'TestFlight sürümünü kullanın. Tekrar satın almayın.';
  }
  if (!serverConfirmed) {
    return 'Premium mağazada aktif, ancak sunucu erişiminiz henüz açılmadı. '
        'Geri yükleme ve erişim doğrulaması tamamlanmadı. Tekrar satın almayın; '
        'destek ile iletişime geçin.';
  }
  return restoring
      ? 'Premium satın almanız geri yüklendi ve sunucu erişiminiz doğrulandı.'
      : 'Premium etkinleşti ve sunucu erişiminiz doğrulandı.';
}
