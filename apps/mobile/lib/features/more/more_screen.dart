import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/mobile_services.dart';
import '../../core/store_billing_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../l10n/app_localizations.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({
    super.key,
    required this.services,
    required this.locale,
    required this.onLocaleChanged,
    required this.onSignedOut,
  });
  final MobileServices services;
  final Locale locale;
  final Future<void> Function(Locale) onLocaleChanged;
  final VoidCallback onSignedOut;

  Future<void> chooseLanguage(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final target = await showModalBottomSheet<Locale>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(l10n.interfaceLanguage)),
            ListTile(
              title: Text(l10n.turkish),
              trailing: locale.languageCode == 'tr'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () =>
                  Navigator.pop(sheetContext, const Locale('tr', 'TR')),
            ),
            ListTile(
              title: Text(l10n.english),
              trailing: locale.languageCode == 'en'
                  ? const Icon(Icons.check)
                  : null,
              onTap: () =>
                  Navigator.pop(sheetContext, const Locale('en', 'US')),
            ),
          ],
        ),
      ),
    );
    if (target == null || target.languageCode == locale.languageCode) return;
    try {
      await onLocaleChanged(target);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.languageUpdateFailed)));
      }
    }
  }

  Future<void> chooseWorkspace(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final response =
          await services.api.get('/api/workspaces') as Map<String, dynamic>;
      if (!context.mounted) return;
      final workspaces = List<Map<String, dynamic>>.from(
        response['data'] as List? ?? [],
      );
      final target = await showModalBottomSheet<String>(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(title: Text(l10n.chooseWorkspace)),
              for (final item in workspaces)
                ListTile(
                  title: Text(item['name']?.toString() ?? l10n.workspace),
                  trailing: item['id'] == services.workspaceId
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () =>
                      Navigator.pop(sheetContext, item['id']?.toString()),
                ),
            ],
          ),
        ),
      );
      if (target == null || target == services.workspaceId) return;
      await services.switchWorkspace(target);
      if (context.mounted) context.go('/');
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.workspaceChangeFailed)));
      }
    }
  }

  Future<void> signOut() async {
    try {
      await StoreBillingService.signOutIfConfigured();
    } catch (_) {
      // Mağaza servisi çıkışı, uygulama oturumundan çıkmayı engellememeli.
    }
    if (services.config.hasSupabase) {
      await Supabase.instance.client.auth.signOut(scope: SignOutScope.global);
    }
    await services.sessions.clear();
    services.clearIdentityContext();
    onSignedOut();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreTitle)),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: Text(l10n.fieldMap),
            subtitle: Text(l10n.nearbyCustomersRoute),
            onTap: () => context.push('/map'),
          ),
          ListTile(
            leading: const Icon(Icons.mic_none),
            title: Text(l10n.visitsVoiceNote),
            subtitle: Text(l10n.preApprovalPromise),
            onTap: () => context.push('/visits'),
          ),
          ListTile(
            leading: const Icon(Icons.sync),
            title: Text(l10n.syncCenter),
            subtitle: Text(l10n.pendingRecordsErrors),
            onTap: () => context.push('/offline'),
          ),
          const Divider(),
          if (services.config.hasSupabase)
            ListTile(
              leading: const Icon(Icons.swap_horiz_outlined),
              title: Text(l10n.switchWorkspace),
              onTap: () => chooseWorkspace(context),
            ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: Text(l10n.calendar),
            subtitle: Text(l10n.plannedVisitsDatedTasks),
            onTap: () => context.push('/calendar'),
          ),
          ListTile(
            leading: const Icon(Icons.history_toggle_off_outlined),
            title: Text(l10n.activity),
            subtitle: Text(l10n.activityHistory),
            onTap: () => context.push('/activity'),
          ),
          ListTile(
            leading: const Icon(Icons.analytics_outlined),
            title: Text(l10n.reportsSummary),
            subtitle: Text(l10n.customerVisitTaskMetrics),
            onTap: () => context.push('/reports'),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_none),
            title: Text(l10n.notifications),
            subtitle: Text(l10n.commentsTasksApprovalEvents),
            onTap: () => context.push('/notifications'),
          ),
          ListTile(
            leading: const Icon(Icons.trending_up),
            title: Text(l10n.opportunities),
            subtitle: Text(l10n.salesPipelineStages),
            onTap: () => context.push('/opportunities'),
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined),
            title: Text(l10n.productsPrices),
            subtitle: Text(l10n.activeProductCatalogPrices),
            onTap: () => context.push('/products'),
          ),
          ListTile(
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text(l10n.orderDrafts),
            subtitle: Text(l10n.draftApprovalStatus),
            onTap: () => context.push('/orders'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.documents),
            subtitle: Text(l10n.fileSecurityScanning),
            onTap: () => context.push('/documents'),
          ),
          ListTile(
            leading: const Icon(Icons.dynamic_form_outlined),
            title: Text(l10n.fieldForms),
            subtitle: Text(l10n.activeTemplatesSubmissions),
            onTap: () => context.push('/forms'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.business_outlined),
            title: Text(l10n.companyInfo),
            subtitle: Text(l10n.editWorkspaceCompanyName),
            onTap: () => context.push('/company-info'),
          ),
          ListTile(
            leading: const Icon(Icons.workspace_premium_outlined),
            title: Text(l10n.premiumSubscription),
            subtitle: Text(l10n.viewPlanManagePurchase),
            onTap: () => context.push('/premium'),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.interfaceLanguage),
            subtitle: Text(
              locale.languageCode == 'en' ? l10n.english : l10n.turkish,
            ),
            onTap: () => chooseLanguage(context),
          ),
          // Bu iki madde ayar değil, ürünün verdiği sözdür.
          _PromiseCard(
            icon: Icons.location_off_outlined,
            title: l10n.locationPrivacy,
            body: l10n.locationPrivacyBody,
          ),
          _PromiseCard(
            icon: Icons.graphic_eq,
            title: l10n.audioRetention,
            body: l10n.audioRetentionBody,
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.privacyRights),
            subtitle: Text(l10n.privacyDataCenter),
            onTap: () => context.push('/privacy'),
          ),
          ListTile(
            leading: Icon(
              Icons.delete_forever_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              l10n.deleteAccount,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            subtitle: Text(l10n.permanentlyDeletePersonalData),
            onTap: () => context.push('/privacy?delete=true'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(l10n.signOutAllDevices),
            onTap: signOut,
          ),
          const _AppVersionTile(),
        ],
      ),
    );
  }
}

/// Ayar değil, bilgi. Dokunulabilir görünmemesi için `ListTile` kullanılmaz.
class _PromiseCard extends StatelessWidget {
  const _PromiseCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2, right: 14),
          child: Icon(icon, size: 22),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(body, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Sürüm ve derleme numarasını gösterir.
///
/// Kapalı testte her yükleme "1.0.0" göründüğü için testçi hangi derlemeyi
/// kullandığını söyleyemiyordu; hata bildirimlerinde derleme numarası şart.
class _AppVersionTile extends StatelessWidget {
  const _AppVersionTile();

  @override
  Widget build(BuildContext context) => FutureBuilder<PackageInfo>(
    future: PackageInfo.fromPlatform(),
    builder: (context, snapshot) {
      final info = snapshot.data;
      final l10n = AppLocalizations.of(context)!;
      final label = info == null
          ? l10n.versionLoading
          : l10n.versionBuild(info.version, info.buildNumber);
      return ListTile(
        leading: const Icon(Icons.info_outline),
        title: Text(l10n.appVersion),
        subtitle: Text(label),
        // Hata bildirirken kopyalanabilsin.
        onTap: info == null
            ? null
            : () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${info.packageName} $label'),
                  duration: const Duration(seconds: 4),
                ),
              ),
      );
    },
  );
}
