import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/mobile_services.dart';
import '../../core/billing_reconciliation.dart';
import '../../core/store_billing_service.dart';
import '../../core/apple_subscription_management.dart';
import '../../l10n/app_localizations.dart';

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

  String billingFailureMessage(
    StoreBillingException error,
    AppLocalizations l10n,
  ) => switch (error.failure) {
    StoreBillingFailure.configurationUnavailable =>
      l10n.billingConfigurationUnavailable,
    StoreBillingFailure.offeringUnavailable => l10n.billingOfferingUnavailable,
    StoreBillingFailure.sessionRequired => l10n.billingSessionRequired,
    StoreBillingFailure.purchaseCancelled => l10n.billingPurchaseCancelled,
    StoreBillingFailure.purchaseFailed => l10n.billingPurchaseFailed,
    StoreBillingFailure.restoreFailed => l10n.billingRestoreFailed,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) load();
    });
  }

  Future<void> load() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      if (!widget.services.config.hasSupabase) {
        throw const StoreBillingException(StoreBillingFailure.sessionRequired);
      }
      final result = await widget.services.api.get('/api/settings/billing');
      final data = Map<String, dynamic>.from(result as Map);
      if (!mounted) return;
      status = data;
      widget.services.updateEntitlement(data['entitlement'] as Map?);
      if (data['workspaceKind'] == 'personal') {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId == null) {
          throw const StoreBillingException(
            StoreBillingFailure.sessionRequired,
          );
        }
        await billing.identify(userId);
        packages = (await billing.packages())
            .where((p) => p.packageType == PackageType.monthly)
            .toList();
      }
    } catch (error) {
      message = error is StoreBillingException
          ? billingFailureMessage(error, l10n)
          : l10n.billingLoadFailure;
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> buy(Package package) async {
    final l10n = AppLocalizations.of(context)!;
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
          l10n: l10n,
        );
      });
    } on StoreBillingException catch (error) {
      if (mounted) {
        setState(() => message = billingFailureMessage(error, l10n));
      }
    } on MobileApiException catch (_) {
      if (mounted) {
        setState(() => message = l10n.billingPurchaseServerPending);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> restore() async {
    final l10n = AppLocalizations.of(context)!;
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
          l10n: l10n,
        );
      });
    } on StoreBillingException catch (error) {
      if (mounted) {
        setState(() => message = billingFailureMessage(error, l10n));
      }
    } on MobileApiException catch (_) {
      if (mounted) {
        setState(() => message = l10n.billingRestoreServerPending);
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
    final l10n = AppLocalizations.of(context)!;
    if (busy) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      if (Platform.isIOS) {
        await AppleSubscriptionManagement.show();
        if (mounted) await load();
      } else {
        final opened = await launchUrl(
          Uri.parse('https://play.google.com/store/account/subscriptions'),
          mode: LaunchMode.externalApplication,
        );
        if (!opened) throw StateError('Subscription management unavailable');
      }
    } catch (_) {
      if (mounted) {
        setState(() => message = l10n.billingSubscriptionManagementUnavailable);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  String periodLabel(Package package, AppLocalizations l10n) =>
      switch (package.packageType) {
        PackageType.monthly => l10n.premiumMonthly,
        PackageType.annual => l10n.premiumAnnual,
        _ => l10n.subscription,
      };

  String get storeName => Platform.isIOS ? 'App Store' : 'Google Play';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entitlement = status?['entitlement'] as Map?;
    final organization = status?['workspaceKind'] == 'organization';
    final usage = status?['usage'] as Map?;
    final limits = entitlement?['limits'] as Map?;
    final endsAt = DateTime.tryParse(
      entitlement?['trialEndsAt']?.toString() ?? '',
    );
    final daysLeft = endsAt == null
        ? 0
        : (endsAt.difference(DateTime.now()).inSeconds / 86400)
              .ceil()
              .clamp(0, 14)
              .toInt();
    final numberFormat = NumberFormat.decimalPattern(l10n.localeName);
    final audioNumberFormat = NumberFormat.decimalPatternDigits(
      locale: l10n.localeName,
      decimalDigits: 1,
    );
    String quotaValue(dynamic value) =>
        value == null ? l10n.premiumUnlimited : numberFormat.format(value);
    final planName = organization
        ? l10n.organizationPlanName
        : entitlement?['trialActive'] == true
        ? l10n.trialPlanName
        : entitlement?['readOnly'] == true
        ? l10n.viewOnlyPlanName
        : l10n.activePlanName;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.premiumTitle)),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (widget.services.config.isSandbox) ...[
                  Text(l10n.sandboxNotice),
                  const SizedBox(height: 12),
                ],
                if (message != null) ...[
                  Text(message!),
                  const SizedBox(height: 12),
                ],
                Text(
                  planName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  organization
                      ? l10n.organizationPlanManaged
                      : l10n.paymentsThroughStore(storeName),
                ),
                const SizedBox(height: 12),
                if (!organization) ...[
                  Text(l10n.premiumTrialDisclosure),
                  const SizedBox(height: 8),
                  Text(l10n.premiumTrialQuota),
                  Text(l10n.premiumIndividualQuota),
                  if (entitlement?['trialActive'] == true)
                    Text(
                      daysLeft <= 1
                          ? l10n.premiumTrialLastDay
                          : l10n.premiumTrialDaysLeft(daysLeft),
                    ),
                  if (entitlement?['readOnly'] == true)
                    Text(l10n.premiumReadOnlyDisclosure),
                  if (limits != null) ...[
                    Text(
                      l10n.premiumUsageScans(
                        quotaValue(usage?['ocr'] ?? 0),
                        quotaValue(limits['ocr']),
                      ),
                    ),
                    Text(
                      l10n.premiumUsageAudio(
                        audioNumberFormat.format(
                          ((usage?['audio_seconds'] as num? ?? 0) / 60),
                        ),
                        quotaValue(limits['aiMinutes']),
                      ),
                    ),
                    Text(
                      l10n.premiumUsageSummaries(
                        quotaValue(usage?['ai_summary'] ?? 0),
                        quotaValue(limits['aiSummaries']),
                      ),
                    ),
                  ],
                  Text(l10n.premiumQuotaPolicy),
                ],
                const SizedBox(height: 20),
                if (!organization)
                  for (final package in packages)
                    Card(
                      child: ListTile(
                        title: Text(
                          '${package.storeProduct.title} · ${periodLabel(package, l10n)}',
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
                    child: Text(l10n.premiumRestorePurchases),
                  ),
                  TextButton(
                    onPressed: busy ? null : manageSubscription,
                    child: Text(l10n.premiumManageSubscription(storeName)),
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.premiumAutoRenewalDisclosure),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => openLegal('/terms'),
                        child: Text(l10n.premiumTermsOfUse),
                      ),
                      TextButton(
                        onPressed: () => openLegal('/privacy'),
                        child: Text(l10n.premiumPrivacyPolicy),
                      ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}
