import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/mobile_services.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key, required this.services});
  final MobileServices services;
  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  late Future<List<Map<String, dynamic>>> visits;
  @override
  void initState() {
    super.initState();
    visits = load();
  }

  Future<List<Map<String, dynamic>>> load() async {
    if (!widget.services.config.hasSupabase) {
      return const [
        {
          'id': 'demo-draft',
          'status': 'draft',
          'purpose': 'Teknik demo',
          'company': {'name': 'Atlas Medikal'},
        },
        {
          'id': 'demo-approved',
          'status': 'approved',
          'purpose': 'Bakım sözleşmesi',
          'company': {'name': 'Nova Otomasyon'},
        },
      ];
    }
    final result =
        await widget.services.api.get(
              '/api/visits?workspaceId=${widget.services.workspaceId}',
            )
            as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(result['data'] as List? ?? []);
  }

  Future<void> createVisit() async {
    final purpose = TextEditingController();
    var customers = <Map<String, dynamic>>[];
    if (widget.services.config.hasSupabase) {
      final response =
          await widget.services.api.get(
                '/api/customers?workspaceId=${widget.services.workspaceId}',
              )
              as Map<String, dynamic>;
      customers = List<Map<String, dynamic>>.from(
        response['data'] as List? ?? [],
      );
    } else {
      customers = const [
        {'id': 'demo-atlas', 'name': 'Atlas Medikal'},
        {'id': 'demo-nova', 'name': 'Nova Otomasyon'},
      ];
    }
    if (!mounted) return;
    String? companyId = customers.isEmpty
        ? null
        : customers.first['id']?.toString();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yeni ziyaret'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (customers.isNotEmpty)
                DropdownButtonFormField<String>(
                  // Keep compatibility with the current local Flutter SDK.
                  // ignore: deprecated_member_use
                  value: companyId,
                  decoration: const InputDecoration(labelText: 'Müşteri'),
                  items: customers
                      .map(
                        (item) => DropdownMenuItem(
                          value: item['id'].toString(),
                          child: Text(item['name']?.toString() ?? 'Firma'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() => companyId = value),
                )
              else
                const Text('Ziyaret için önce bir müşteri kaydı gerekir.'),
              const SizedBox(height: 12),
              TextField(
                controller: purpose,
                decoration: const InputDecoration(labelText: 'Ziyaret amacı'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: companyId == null
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: const Text('Ziyareti başlat'),
            ),
          ],
        ),
      ),
    );
    if (accepted != true || companyId == null) {
      purpose.dispose();
      return;
    }
    final visitPurpose = purpose.text.trim();
    purpose.dispose();
    if (!widget.services.config.hasSupabase) {
      if (!mounted) return;
      context.push('/visits/demo-new/debrief');
      return;
    }
    try {
      final response =
          await widget.services.api.post('/api/visits', {
                'workspaceId': widget.services.workspaceId,
                'organizationId': widget.services.organizationId,
                'companyId': companyId,
                'purpose': visitPurpose,
                'startedAt': DateTime.now().toUtc().toIso8601String(),
                'clientMutationId': const Uuid().v4(),
              })
              as Map<String, dynamic>;
      final data = response['data'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() => visits = load());
      context.push('/visits/${data['id']}/debrief');
    } catch (_) {
      await widget.services.queue.enqueueVisitCreate(
        ownerId: widget.services.ownerId,
        workspaceId: widget.services.workspaceId,
        organizationId: widget.services.organizationId,
        companyId: companyId!,
        purpose: visitPurpose,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ziyaret çevrimdışı kuyruğa alındı; bağlantı gelince gönderilecek.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ziyaretler')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: createVisit,
      icon: const Icon(Icons.add),
      label: const Text('Yeni ziyaret'),
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: visits,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, index) {
            final item = snapshot.data![index];
            final company = item['company'] as Map? ?? {};
            final status = item['status']?.toString() ?? 'draft';
            return Card(
              child: ListTile(
                title: Text(company['name']?.toString() ?? 'Firma'),
                subtitle: Text(item['purpose']?.toString() ?? 'Ziyaret'),
                trailing: Chip(
                  label: Text(
                    status == 'approved'
                        ? 'Onaylandı'
                        : status == 'needs_review'
                        ? 'İncele'
                        : 'Not ekle',
                  ),
                ),
                onTap: () => context.push('/visits/${item['id']}/debrief'),
              ),
            );
          },
        );
      },
    ),
  );
}
