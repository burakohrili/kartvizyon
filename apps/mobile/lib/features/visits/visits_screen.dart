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
    if (!widget.services.config.hasSupabase) return const [];
    await widget.services.refreshContext();
    final result =
        await widget.services.api.get(
              '/api/visits?workspaceId=${widget.services.workspaceId}',
            )
            as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(result['data'] as List? ?? []);
  }

  Future<void> createVisit() async {
    final purpose = TextEditingController();
    List<Map<String, dynamic>> customers;
    try {
      final response =
          await widget.services.api.get(
                '/api/customers?workspaceId=${widget.services.workspaceId}',
              )
              as Map<String, dynamic>;
      customers = List<Map<String, dynamic>>.from(
        response['data'] as List? ?? [],
      );
    } on MobileApiException catch (error) {
      purpose.dispose();
      if (!mounted) return;
      final message = error.statusCode == 401
          ? 'Oturumunuzun süresi doldu. Lütfen yeniden giriş yapın.'
          : error.message;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    } catch (_) {
      purpose.dispose();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Müşteriler yüklenemedi. Bağlantınızı kontrol edin.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    if (customers.isEmpty) {
      purpose.dispose();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ziyaret oluşturmadan önce bir müşteri ekleyin.'),
        ),
      );
      context.go('/customers');
      return;
    }

    String? companyId = customers.first['id']?.toString();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yeni ziyaret'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
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
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: purpose,
                  decoration: const InputDecoration(labelText: 'Ziyaret amacı'),
                ),
              ],
            ),
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
    } on MobileApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
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

  Future<void> refresh() async {
    final next = load();
    setState(() => visits = next);
    await next;
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
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  TextButton(
                    onPressed: refresh,
                    child: const Text('Tekrar dene'),
                  ),
                ],
              ),
            ),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.route_outlined, size: 52),
                  const SizedBox(height: 12),
                  Text(
                    'Henüz ziyaret yok',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'İlk ziyaretinizi başlatmak için önce bir müşteri seçin.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: createVisit,
                    icon: const Icon(Icons.add),
                    label: const Text('Yeni ziyaret'),
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final item = items[index];
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
                  onTap: () {
                    if (status == 'needs_review') {
                      context.push('/visits/${item['id']}/review');
                      return;
                    }
                    final companyId = company['id']?.toString();
                    if (status == 'approved' && companyId != null) {
                      context.push('/briefings/$companyId');
                      return;
                    }
                    context.push('/visits/${item['id']}/debrief');
                  },
                ),
              );
            },
          ),
        );
      },
    ),
  );
}
