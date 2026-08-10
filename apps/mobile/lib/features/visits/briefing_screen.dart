import 'package:flutter/material.dart';

import '../../core/mobile_services.dart';

class BriefingScreen extends StatefulWidget {
  const BriefingScreen({
    super.key,
    required this.services,
    required this.companyId,
  });

  final MobileServices services;
  final String companyId;

  @override
  State<BriefingScreen> createState() => _BriefingScreenState();
}

class _BriefingScreenState extends State<BriefingScreen> {
  late Future<Map<String, dynamic>> briefing;

  @override
  void initState() {
    super.initState();
    briefing = load();
  }

  Future<Map<String, dynamic>> load() async {
    final response =
        await widget.services.api.get('/api/briefings/${widget.companyId}')
            as Map<String, dynamic>;
    return Map<String, dynamic>.from(response['data'] as Map);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ziyaret brifingi')),
    body: FutureBuilder<Map<String, dynamic>>(
      future: briefing,
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
                    onPressed: () => setState(() => briefing = load()),
                    child: const Text('Tekrar dene'),
                  ),
                ],
              ),
            ),
          );
        }
        final data = snapshot.data!;
        final company = data['company'] as Map? ?? {};
        final memory = data['memory'] as Map?;
        final tasks = List<Map<String, dynamic>>.from(
          data['openTasks'] as List? ?? [],
        );
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              company['name']?.toString() ?? 'Müşteri',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if ((company['address']?.toString() ?? '').isNotEmpty)
              Text(company['address'].toString()),
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
                          'Henüz onaylanmış ziyaret özeti bulunmuyor.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Açık takipler (${tasks.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Bu müşteri için açık takip bulunmuyor.'),
              )
            else
              ...tasks.map(
                (task) => ListTile(
                  leading: const Icon(Icons.task_alt_outlined),
                  title: Text(task['title']?.toString() ?? 'Görev'),
                ),
              ),
          ],
        );
      },
    ),
  );
}
