import 'package:flutter/material.dart';
import '../../core/mobile_services.dart';

class OfflineCenterScreen extends StatefulWidget {
  const OfflineCenterScreen({super.key, required this.services});
  final MobileServices services;
  @override
  State<OfflineCenterScreen> createState() => _OfflineCenterScreenState();
}

class _OfflineCenterScreenState extends State<OfflineCenterScreen> {
  bool busy = false;
  String? message;
  Future<void> sync() async {
    setState(() => busy = true);
    final result = await widget.services.sync.run(
      ownerId: widget.services.ownerId,
    );
    if (!mounted) return;
    setState(() {
      busy = false;
      message =
          '${result.synced} kayıt gönderildi, ${result.remaining} kayıt bekliyor${result.authRequired ? '. Oturum yenilenmeli' : ''}.';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Eşitleme merkezi')),
    body: FutureBuilder(
      future: widget.services.database.pendingForOwner(widget.services.ownerId),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.cloud_sync_outlined),
                title: Text('${items.length} bekleyen kayıt'),
                subtitle: const Text(
                  'Kayıtlar kullanıcıya göre şifreli uygulama alanında izole edilir.',
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
            ...items.map(
              (item) => Card(
                child: ListTile(
                  title: Text(
                    item.entityType == 'visit_debrief'
                        ? 'Ziyaret notu'
                        : item.entityType,
                  ),
                  subtitle: Text(item.lastError ?? 'Gönderilmeyi bekliyor'),
                  trailing: Text('${item.attempts} deneme'),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}
