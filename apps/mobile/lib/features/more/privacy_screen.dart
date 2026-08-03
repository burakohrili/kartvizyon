import 'package:flutter/material.dart';
import '../../core/mobile_services.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key, required this.services});
  final MobileServices services;
  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  Map<String, bool> consents = {};
  List<Map<String, dynamic>> requests = [];
  String? message;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (!widget.services.config.hasSupabase) return;
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
      if (mounted) setState(() => message = error.toString());
    }
  }

  Future<void> update(String purpose, bool granted) async {
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
          message = error.toString();
        });
      }
    }
  }

  Future<void> createRequest(String kind) async {
    if (!widget.services.config.hasSupabase) {
      setState(() => message = 'Demo modunda talep oluşturulmaz.');
      return;
    }
    try {
      await widget.services.api.post('/api/settings/privacy', {
        'workspaceId': widget.services.workspaceId,
        'kind': kind,
      });
      setState(() => message = 'Talebiniz güvenli biçimde alındı.');
      await load();
    } catch (error) {
      if (mounted) setState(() => message = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('KVKK ve veri hakları')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Rıza tercihlerinizi değiştirebilir, verilerinizi dışa aktarma veya silme talebi oluşturabilirsiniz.',
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          title: const Text('Ürün analitiği'),
          value: consents['product_analytics'] ?? false,
          onChanged: (value) => update('product_analytics', value),
        ),
        SwitchListTile(
          title: const Text('AI ile not işleme'),
          value: consents['ai_processing'] ?? false,
          onChanged: (value) => update('ai_processing', value),
        ),
        SwitchListTile(
          title: const Text('E-posta bildirimleri'),
          value: consents['email_notifications'] ?? false,
          onChanged: (value) => update('email_notifications', value),
        ),
        const Divider(),
        FilledButton.tonalIcon(
          onPressed: () => createRequest('export'),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Verilerimi dışa aktar'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => createRequest('deletion'),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Silme talebi oluştur'),
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(message!),
          ),
        if (requests.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'Taleplerim',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ...requests.map(
            (item) => ListTile(
              title: Text(item['kind'] == 'export' ? 'Dışa aktarma' : 'Silme'),
              trailing: Text(item['status']?.toString() ?? 'requested'),
            ),
          ),
        ],
      ],
    ),
  );
}
