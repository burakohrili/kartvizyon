import 'dart:io';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';

import 'package:flutter/material.dart';

import '../../core/mobile_services.dart';
import '../../data/local/app_database.dart';
import '../../data/sync_engine.dart';
import '../../data/sync_error_labels.dart';
import '../../l10n/app_localizations.dart';

class OfflineCenterScreen extends StatefulWidget {
  const OfflineCenterScreen({super.key, required this.services});
  final MobileServices services;
  @override
  State<OfflineCenterScreen> createState() => _OfflineCenterScreenState();
}

class _OfflineCenterScreenState extends State<OfflineCenterScreen> {
  // Future `build` içinde kurulursa her rebuild yeni bir sorgu açar ve
  // yüklenirken "0 bekleyen kayıt" yazıp kullanıcıya yalan söyler.
  late Future<List<SyncQueueItem>> items;
  bool busy = false;
  String? message;

  @override
  void initState() {
    super.initState();
    items = load();
  }

  Future<List<SyncQueueItem>> load() =>
      widget.services.database.pendingForOwner(widget.services.ownerId);

  void reload() => setState(() => items = load());

  Future<void> sync() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => busy = true);
    try {
      await widget.services.refreshContext();
    } catch (_) {
      // SyncEngine aşağıda oturum/ağ durumunu sonuç nesnesine dönüştürür.
    }
    final result = await widget.services.sync.run(
      ownerId: widget.services.ownerId,
    );
    if (!mounted) return;
    setState(() {
      busy = false;
      items = load();
      message = [
        l10n.syncResult(result.synced, result.remaining),
        if (result.authRequired) l10n.syncAuthRefreshRequired,
      ].join(' ');
    });
  }

  Future<void> retry(SyncQueueItem item) async {
    await widget.services.database.clearFailure(item.clientMutationId);
    if (!mounted) return;
    reload();
    await sync();
  }

  Future<void> exportDraft(SyncQueueItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final attachment = item.attachmentPath;
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        title: l10n.offlineDraftTitle,
        text: const JsonEncoder.withIndent(
          '  ',
        ).convert(jsonDecode(item.payloadJson)),
        files: attachment != null && await File(attachment).exists()
            ? [XFile(attachment)]
            : null,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> viewDraft(SyncQueueItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final payload = jsonDecode(item.payloadJson) as Map;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.offlineDraftTitle),
        content: SingleChildScrollView(
          child: SelectableText(
            payload['transcript']?.toString() ??
                payload['purpose']?.toString() ??
                l10n.offlineAudioDraftHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.close),
          ),
        ],
      ),
    );
  }

  Future<void> discard(SyncQueueItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteQueuedRecordTitle),
        content: Text(l10n.deleteQueuedRecordWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.services.database.removeByMutationId(item.clientMutationId);
    final attachment = item.attachmentPath;
    if (attachment != null) {
      await File(attachment).delete().catchError((_) => File(attachment));
    }
    if (!mounted) return;
    setState(() {
      items = load();
      message = l10n.recordDeleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.offlineCenterTitle)),
      body: FutureBuilder<List<SyncQueueItem>>(
        future: items,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data ?? const <SyncQueueItem>[];
          final blocked = data.where((item) => isSyncBlocked(item.lastError));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.cloud_sync_outlined),
                  title: Text(l10n.offlineQueuedCount(data.length)),
                  subtitle: Text(
                    blocked.isEmpty
                        ? l10n.offlineStorageNotice
                        : blockedQueueNotice(blocked.length, l10n),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: busy ? null : sync,
                icon: const Icon(Icons.sync),
                label: Text(busy ? l10n.syncing : l10n.syncNow),
              ),
              if (message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(message!),
                ),
              ...data.map(
                (item) => Card(
                  child: ListTile(
                    isThreeLine: true,
                    leading: Icon(
                      isSyncBlocked(item.lastError)
                          ? Icons.error_outline
                          : Icons.schedule,
                    ),
                    title: Text(
                      '${item.entityType == 'visit_debrief'
                          ? l10n.syncEntityVisitNote
                          : item.entityType == 'visit_create'
                          ? l10n.syncEntityVisit
                          : l10n.syncEntityGeneric} · '
                      '${isSyncBlocked(item.lastError)
                          ? l10n.syncBlockedStatus
                          : busy
                          ? l10n.syncSendingStatus
                          : l10n.syncWaitingStatus}',
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(syncErrorLabel(item.lastError, l10n)),
                        // Ham kod hata bildirimi için burada kalır; kullanıcının
                        // okuduğu satır yukarıdaki cümledir.
                        Text(
                          '${l10n.syncAttemptsCount(item.attempts > 12 ? '12+' : '${item.attempts}')}'
                          '${item.lastError == null ? '' : ' · ${l10n.syncErrorCode(item.lastError!)}'}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'view':
                            viewDraft(item);
                          case 'export':
                            exportDraft(item);
                          case 'retry':
                            retry(item);
                          case 'discard':
                            discard(item);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'view',
                          child: Text(l10n.viewDraft),
                        ),
                        PopupMenuItem(
                          value: 'export',
                          child: Text(l10n.exportDraft),
                        ),
                        PopupMenuItem(
                          value: 'retry',
                          child: Text(l10n.retrySync),
                        ),
                        PopupMenuItem(
                          value: 'discard',
                          child: Text(l10n.delete),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
