import 'dart:io';

import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/mobile_services.dart';
import '../../core/billing_reconciliation.dart';
import '../../core/store_billing_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key, required this.services});
  final MobileServices services;

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  late final StoreBillingService billing = StoreBillingService(
    widget.services.config,
  );
  List<Package> packages = const [];
  Map<String, dynamic>? status;
  bool loading = true;
  bool busy = false;
  String? message;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      if (!widget.services.config.hasSupabase) {
        throw const StoreBillingException(
          'Premium işlemleri için hesabınızla giriş yapın.',
        );
      }
      final result = await widget.services.api.get('/api/settings/billing');
      final data = Map<String, dynamic>.from(result as Map);
      if (!mounted) return;
      status = data;
      widget.services.updateEntitlement(data['entitlement'] as Map?);
      if (data['workspaceKind'] == 'personal') {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) {
          throw const StoreBillingException('Oturum gerekli.');
        }
        await billing.identify(userId);
        packages = (await billing.packages())
            .where((p) => p.packageType == PackageType.monthly)
            .toList();
      }
    } catch (error) {
      message = error is StoreBillingException
          ? error.message
          : 'Premium bilgileri yüklenemedi.';
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> buy(Package package) async {
    if (busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final info = await billing.purchase(package);
      final serverConfirmed = await refreshServerStatus();
      final premium = info.entitlements.active['premium'];
      if (!mounted) return;
      setState(() {
        message = billingReconciliationMessage(
          restoring: false,
          storeActive: premium != null,
          serverConfirmed: serverConfirmed,
          sandboxPurchase: premium?.isSandbox ?? false,
          apiBaseUrl: widget.services.config.apiBaseUrl,
        );
      });
    } on StoreBillingException catch (error) {
      if (mounted) setState(() => message = error.message);
    } on MobileApiException catch (_) {
      if (mounted) {
        setState(
          () => message =
              'Satın alma mağazada tamamlandı; sunucu doğrulaması bekleniyor. Biraz sonra yeniden açarak kontrol edin.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> restore() async {
    if (busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final info = await billing.restore();
      final serverConfirmed = await refreshServerStatus();
      final premium = info.entitlements.active['premium'];
      if (!mounted) return;
      setState(() {
        message = billingReconciliationMessage(
          restoring: true,
          storeActive: premium != null,
          serverConfirmed: serverConfirmed,
          sandboxPurchase: premium?.isSandbox ?? false,
          apiBaseUrl: widget.services.config.apiBaseUrl,
        );
      });
    } on StoreBillingException catch (error) {
      if (mounted) setState(() => message = error.message);
    } on MobileApiException catch (_) {
      if (mounted) {
        setState(
          () => message =
              'Geri yükleme mağazada tamamlandı; sunucu doğrulaması bekleniyor. Biraz sonra yeniden deneyin.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<bool> refreshServerStatus() async {
    for (var attempt = 0; attempt < 5; attempt++) {
      final data = Map<String, dynamic>.from(
        await widget.services.api.get('/api/settings/billing') as Map,
      );
      if (!mounted) return false;
      setState(() => status = data);
      final entitlement = data['entitlement'] as Map?;
      widget.services.updateEntitlement(entitlement);
      if (serverPremiumConfirmed(entitlement)) {
        return true;
      }
      if (attempt < 4) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
    return false;
  }

  Future<void> openLegal(String path) async {
    await launchUrl(
      Uri.parse('${widget.services.config.apiBaseUrl}$path'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> manageSubscription() async {
    final uri = Platform.isIOS
        ? Uri.parse('https://apps.apple.com/account/subscriptions')
        : Uri.parse('https://play.google.com/store/account/subscriptions');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String periodLabel(Package package) => switch (package.packageType) {
    PackageType.monthly => 'Aylık',
    PackageType.annual => 'Yıllık',
    _ => 'Abonelik',
  };

  String get storeName => Platform.isIOS ? 'App Store' : 'Google Play';

  @override
  Widget build(BuildContext context) {
    final entitlement = status?['entitlement'] as Map?;
    final organization = status?['workspaceKind'] == 'organization';
    final usage = status?['usage'] as Map?;
    final limits = entitlement?['limits'] as Map?;
    final endsAt = DateTime.tryParse(
      entitlement?['trialEndsAt']?.toString() ?? '',
    );
    final daysLeft = endsAt == null
        ? 0
        : (endsAt.difference(DateTime.now()).inSeconds / 86400).ceil().clamp(
            0,
            14,
          );
    return Scaffold(
      appBar: AppBar(title: const Text('Premium ve abonelik')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (widget.services.config.isSandbox) ...[
                  const Text(
                    'Sandbox test ortamı — canlı hesabınızdan ayrıdır.',
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  entitlement?['planName']?.toString() ?? 'Mevcut plan',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  organization
                      ? 'Bu çalışma alanının planı kurum yöneticiniz tarafından yönetilir.'
                      : 'Ödeme $storeName hesabınız üzerinden güvenle tamamlanır.',
                ),
                const SizedBox(height: 12),
                if (!organization) ...[
                  const Text(
                    '14 gün ücretsiz deneyin. Kart gerekmez. Deneme sonunda otomatik ücret alınmaz. Devam etmek için abonelik başlatabilirsiniz.',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Deneme: toplam 60 tarama · 120 dakika ses işleme · 60 AI özeti.',
                  ),
                  const Text(
                    'Bireysel: ayda 125 tarama · 240 dakika ses işleme · 125 AI özeti. Güncel fiyat, mağaza hesabınızın ülke veya bölgesine göre satın alma düğmesinde gösterilir.',
                  ),
                  if (entitlement?['trialActive'] == true)
                    Text(
                      daysLeft <= 1
                          ? 'Denemenizin son günü.'
                          : 'Denemenizin bitmesine $daysLeft gün kaldı.',
                    ),
                  if (entitlement?['readOnly'] == true)
                    const Text(
                      'Yalnız görüntüleme: mevcut kayıtlarınız, dışa aktarma ve hesap silme açık. Yeni kayıt ve AI işlemleri için abonelik başlatın.',
                    ),
                  if (limits != null) ...[
                    Text("Tarama: ${usage?['ocr'] ?? 0} / ${limits['ocr']}"),
                    Text(
                      "Ses işleme: ${((usage?['audio_seconds'] as num? ?? 0) / 60).toStringAsFixed(1)} / ${limits['aiMinutes']} dakika",
                    ),
                    Text(
                      "AI özeti: ${usage?['ai_summary'] ?? 0} / ${limits['aiSummaries']}",
                    ),
                  ],
                  const Text(
                    'Ücretli abonelik başlattığınızda tam kota açılır. Kullanılmayan haklar devretmez. Kota aşımı otomatik ücret doğurmaz.',
                  ),
                ],
                const SizedBox(height: 20),
                if (!organization)
                  for (final package in packages)
                    Card(
                      child: ListTile(
                        title: Text(
                          '${package.storeProduct.title} · ${periodLabel(package)}',
                        ),
                        subtitle: Text(package.storeProduct.description),
                        trailing: FilledButton(
                          onPressed: busy ? null : () => buy(package),
                          child: Text(package.storeProduct.priceString),
                        ),
                      ),
                    ),
                if (!organization) ...[
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: busy ? null : restore,
                    child: const Text('Satın almaları geri yükle'),
                  ),
                  TextButton(
                    onPressed: manageSubscription,
                    child: Text('$storeName’da aboneliği yönet'),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Abonelik seçtiğiniz dönemde otomatik yenilenir. Yenilemeyi mağaza hesap ayarlarınızdan dönem bitiminden önce kapatabilirsiniz.',
                  ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => openLegal('/terms'),
                        child: const Text('Kullanım Koşulları'),
                      ),
                      TextButton(
                        onPressed: () => openLegal('/privacy'),
                        child: const Text('Gizlilik Politikası'),
                      ),
                    ],
                  ),
                ],
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(message!),
                ],
              ],
            ),
    );
  }
}
