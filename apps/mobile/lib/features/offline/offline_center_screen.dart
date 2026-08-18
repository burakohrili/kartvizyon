import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/mobile_services.dart';
import '../../data/local/app_database.dart';
import '../../data/sync_engine.dart';
import '../../data/sync_error_labels.dart';

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
      message =
          '${result.synced} kayıt gönderildi, ${result.remaining} kayıt bekliyor'
          '${result.authRequired ? '. Oturum yenilenmeli' : ''}.';
    });
  }

  Future<void> retry(SyncQueueItem item) async {
    await widget.services.database.clearFailure(item.clientMutationId);
    if (!mounted) return;
    reload();
    await sync();
  }

  Future<void> discard(SyncQueueItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kayıt silinsin mi?'),
        content: const Text(
          'Bu kayıt gönderilmeden silinecek ve geri alınamaz. '
          'Varsa sesli not da cihazdan kaldırılır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sil'),
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
      message = 'Kayıt silindi.';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Eşitleme merkezi')),
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
                title: Text('${data.length} bekleyen kayıt'),
                subtitle: Text(
                  blocked.isEmpty
                      ? 'Kayıtlar kullanıcıya göre şifreli uygulama alanında '
                            'izole edilir.'
                      : blockedQueueNotice(blocked.length),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: busy ? null : sync,
              icon: const Icon(Icons.sync),
              label: Text(busy ? 'Eşitleniyor…' : 'Şimdi eşitle'),
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
                    item.entityType == 'visit_debrief'
                        ? 'Ziyaret notu'
                        : item.entityType == 'visit_create'
                        ? 'Ziyaret kaydı'
                        : item.entityType,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(syncErrorLabel(item.lastError)),
                      // Ham kod hata bildirimi için burada kalır; kullanıcının
                      // okuduğu satır yukarıdaki cümledir.
                      Text(
                        '${item.attempts > 12 ? '12+' : item.attempts} deneme'
                        '${item.lastError == null ? '' : ' · ${item.lastError}'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) =>
                        value == 'retry' ? retry(item) : discard(item),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'retry', child: Text('Tekrar dene')),
                      PopupMenuItem(value: 'discard', child: Text('Kaydı sil')),
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
