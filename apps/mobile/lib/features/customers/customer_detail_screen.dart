import 'package:flutter/material.dart';
import '../../core/mobile_services.dart';

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({
    super.key,
    required this.services,
    required this.companyId,
  });
  final MobileServices services;
  final String companyId;
  Future<Map<String, dynamic>> load() async {
    if (!services.config.hasSupabase) {
      return {
        'company': {'name': 'Atlas Medikal', 'address': 'Ümraniye, İstanbul'},
        'memory': {
          'summary':
              'Son görüşmede teknik demo ve revize teklif tarihi konuşuldu.',
          'open_promises': ['Teklif gönderimi'],
        },
        'contacts': [
          {
            'first_name': 'Ayşe',
            'last_name': 'Yılmaz',
            'title': 'Satın Alma Müdürü',
          },
        ],
        'tasks': [
          {'title': 'Demo tarihini netleştir'},
        ],
      };
    }
    return await services.api.get('/api/customers/$companyId')
        as Map<String, dynamic>;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Müşteri kartı')),
    body: FutureBuilder<Map<String, dynamic>>(
      future: load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final company = data['company'] as Map? ?? {};
        final memory = data['memory'] as Map?;
        final contacts = data['contacts'] as List? ?? [];
        final tasks = data['tasks'] as List? ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              company['name']?.toString() ?? 'Firma',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(company['address']?.toString() ?? ''),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Müşteri hafıza kartı',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      memory?['summary']?.toString() ??
                          'Onaylı hafıza kartı henüz oluşmadı.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'İlgili kişiler (${contacts.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ...contacts.map((item) {
              final value = item as Map;
              return ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(
                  '${value['first_name'] ?? ''} ${value['last_name'] ?? ''}',
                ),
                subtitle: Text(value['title']?.toString() ?? ''),
              );
            }),
            const Divider(),
            Text(
              'Açık görevler (${tasks.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ...tasks.map(
              (item) => ListTile(
                leading: const Icon(Icons.task_alt),
                title: Text((item as Map)['title']?.toString() ?? 'Görev'),
              ),
            ),
          ],
        );
      },
    ),
  );
}
