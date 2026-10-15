import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/mobile_services.dart';
import '../../l10n/app_localizations.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({
    super.key,
    required this.services,
    this.openDeletion = false,
  });
  final MobileServices services;
  final bool openDeletion;
  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  Map<String, bool> consents = {};
  List<Map<String, dynamic>> requests = [];
  String? message;
  bool submittingRequest = false;

  bool _hasOpenRequest(String kind) => requests.any((item) {
    final status = item['status']?.toString();
    return item['kind'] == kind &&
        const {'requested', 'processing', 'ready'}.contains(status);
  });

  String _openRequestMessage(String kind, AppLocalizations l10n) =>
      kind == 'deletion'
      ? l10n.privacyOpenDeletionRequest
      : l10n.privacyOpenExportRequest;

  String _apiFailure(
    Object error,
    AppLocalizations l10n, {
    required String fallback,
  }) {
    if (error is MobileApiException && error.statusCode == 401) {
      return l10n.privacySignInRequired;
    }
    if (error is MobileApiException && error.statusCode == 429) {
      return l10n.privacyRequestRateLimited;
    }
    return fallback;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      load();
      if (widget.openDeletion) confirmDeletion();
    });
  }

  Future<void> confirmDeletion() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.privacyDeleteConfirmTitle),
        content: Text(l10n.privacyDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteAccount),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await createRequest('deletion');
  }

  Future<void> load() async {
    final l10n = AppLocalizations.of(context)!;
    if (!widget.services.config.hasSupabase) {
      if (mounted) setState(() => message = l10n.privacySignInRequired);
      return;
    }
    try {
      final result =
          await widget.services.api.get('/api/settings/privacy')
              as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        consents = {
          for (final item in List<Map<String, dynamic>>.from(
            result['consents'] as List? ?? [],
          ))
            item['purpose'].toString(): item['granted'] == true,
        };
        requests = List<Map<String, dynamic>>.from(
          result['requests'] as List? ?? [],
        );
      });
    } catch (error) {
      if (mounted) {
        setState(
          () => message = _apiFailure(
            error,
            l10n,
            fallback: l10n.privacyLoadFailed,
          ),
        );
      }
    }
  }

  Future<void> update(String purpose, bool granted) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => consents[purpose] = granted);
    try {
      await widget.services.api.patch('/api/settings/privacy', {
        'workspaceId': widget.services.workspaceId,
        'purpose': purpose,
        'granted': granted,
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          consents[purpose] = !granted;
          message = _apiFailure(
            error,
            l10n,
            fallback: l10n.privacyConsentUpdateFailed,
          );
        });
      }
    }
  }

  Future<void> createRequest(String kind) async {
    final l10n = AppLocalizations.of(context)!;
    if (!widget.services.config.hasSupabase) {
      setState(() => message = l10n.privacyDemoRequestUnavailable);
      return;
    }
    if (submittingRequest) return;
    if (_hasOpenRequest(kind)) {
      setState(() => message = _openRequestMessage(kind, l10n));
      return;
    }

    setState(() {
      submittingRequest = true;
      message = null;
    });
    try {
      final result =
          await widget.services.api.post('/api/settings/privacy', {
                'workspaceId': widget.services.workspaceId,
                'kind': kind,
              })
              as Map<String, dynamic>;
      if (!mounted) return;
      setState(
        () => message = result['duplicate'] == true
            ? _openRequestMessage(kind, l10n)
            : kind == 'deletion'
            ? l10n.privacyDeletionRequestSubmitted
            : l10n.privacyRequestReceived,
      );
      await load();
    } on MobileApiException catch (error) {
      if (!mounted) return;
      // Sunucu güncellenmeden çalışan eski dağıtımlarda da 409 kullanıcıya
      // hata gibi görünmesin. Listeyi yenileyip mevcut talebi gösteririz.
      if (error.statusCode == 409) {
        await load();
        if (mounted) {
          setState(() => message = _openRequestMessage(kind, l10n));
        }
        return;
      }
      setState(
        () => message = _apiFailure(
          error,
          l10n,
          fallback: l10n.privacyRequestFailed,
        ),
      );
    } catch (error) {
      if (mounted) setState(() => message = l10n.privacyRequestFailed);
    } finally {
      if (mounted) setState(() => submittingRequest = false);
    }
  }

  /// Hazır dışa aktarmayı imzalı bağlantıyla açar.
  ///
  /// Bağlantı 60 saniye geçerlidir; loglanmaz ve ekranda bırakılmaz.
  Future<void> download(String? id) async {
    final l10n = AppLocalizations.of(context)!;
    if (id == null) return;
    try {
      final result =
          await widget.services.api.get('/api/settings/privacy/export/$id')
              as Map<String, dynamic>;
      final url = result['url']?.toString();
      if (url == null || url.isEmpty) {
        throw StateError('Missing signed export URL');
      }
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) throw StateError('Could not open signed export URL');
    } catch (error) {
      if (!mounted) return;
      setState(
        () => message = _apiFailure(
          error,
          l10n,
          fallback: l10n.privacyExportDownloadFailed,
        ),
      );
    }
  }

  static String _statusLabel(String status, AppLocalizations l10n) =>
      switch (status) {
        'requested' => l10n.privacyStatusReceived,
        'processing' => l10n.privacyStatusProcessing,
        'ready' => l10n.privacyStatusReady,
        'completed' => l10n.privacyStatusCompleted,
        'failed' => l10n.privacyStatusFailed,
        'rejected' => l10n.privacyStatusRejected,
        _ => l10n.privacyStatusUnknown,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyScreenTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.privacyIntro),
          const SizedBox(height: 12),
          SwitchListTile(
            title: Text(l10n.privacyConsentAnalytics),
            value: consents['product_analytics'] ?? false,
            onChanged: widget.services.config.hasSupabase
                ? (value) => update('product_analytics', value)
                : null,
          ),
          SwitchListTile(
            title: Text(l10n.privacyConsentAiProcessing),
            value: consents['ai_processing'] ?? false,
            onChanged: widget.services.config.hasSupabase
                ? (value) => update('ai_processing', value)
                : null,
          ),
          SwitchListTile(
            title: Text(l10n.privacyConsentEmailNotifications),
            value: consents['email_notifications'] ?? false,
            onChanged: widget.services.config.hasSupabase
                ? (value) => update('email_notifications', value)
                : null,
          ),
          const Divider(),
          FilledButton.tonalIcon(
            onPressed: submittingRequest || _hasOpenRequest('export')
                ? null
                : () => createRequest('export'),
            icon: const Icon(Icons.download_outlined),
            label: Text(
              _hasOpenRequest('export')
                  ? l10n.privacyExportRequestOpen
                  : l10n.privacyExportMyData,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: submittingRequest || _hasOpenRequest('deletion')
                ? null
                : confirmDeletion,
            icon: const Icon(Icons.delete_outline),
            label: Text(
              _hasOpenRequest('deletion')
                  ? l10n.privacyDeletionRequestOpen
                  : l10n.privacyDeleteAccountPermanently,
            ),
          ),
          if (message != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(message!),
            ),
          if (requests.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              l10n.privacyMyRequests,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ...requests.map((item) {
              final status = item['status']?.toString() ?? 'requested';
              final ready = item['kind'] == 'export' && status == 'ready';
              return ListTile(
                title: Text(
                  item['kind'] == 'export'
                      ? l10n.privacyExportRequestKind
                      : l10n.privacyDeletionRequestKind,
                ),
                subtitle: Text(_statusLabel(status, l10n)),
                // Dosya hazır olduğu halde ekranda yalnız "ready" yazıyordu ve
                // indirme yolu hiç sunulmuyordu.
                trailing: ready
                    ? FilledButton.tonalIcon(
                        onPressed: () => download(item['id']?.toString()),
                        icon: const Icon(Icons.download),
                        label: Text(l10n.privacyDownload),
                      )
                    : null,
              );
            }),
          ],
        ],
      ),
    );
  }
}
