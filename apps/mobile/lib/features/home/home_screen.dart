import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/mobile_services.dart';
import '../field_mode/field_mode_card.dart';
import '../../core/refresh.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.services});

  final MobileServices services;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeSummary> summary;

  @override
  void initState() {
    super.initState();
    summary = load();
  }

  Future<_HomeSummary> load() async {
    if (!widget.services.config.hasSupabase) {
      return const _HomeSummary(plannedVisits: 0, openTasks: 0);
    }
    await widget.services.refreshContext();
    final results = await Future.wait([
      widget.services.api.get(
        '/api/visits?workspaceId=${widget.services.workspaceId}',
      ),
      widget.services.api.get(
        '/api/tasks?workspaceId=${widget.services.workspaceId}',
      ),
    ]);
    final visitsResponse = results[0] as Map<String, dynamic>;
    final tasksResponse = results[1] as Map<String, dynamic>;
    final visits = List<Map<String, dynamic>>.from(
      visitsResponse['data'] as List? ?? [],
    );
    final tasks = List<Map<String, dynamic>>.from(
      tasksResponse['data'] as List? ?? [],
    );
    final activeVisits = visits.where(
      (visit) => const {
        'draft',
        'processing',
        'needs_review',
      }.contains(visit['status']?.toString()),
    );
    Map<String, dynamic>? nextVisit;
    for (final visit in activeVisits) {
      if (visit['company'] is Map && (visit['company'] as Map)['id'] != null) {
        nextVisit = visit;
        break;
      }
    }
    return _HomeSummary(
      plannedVisits: activeVisits.length,
      openTasks: tasks.where((task) => task['status'] == 'open').length,
      nextVisit: nextVisit,
    );
  }

  Future<void> refresh() async {
    final next = load();
    setState(() => summary = next);
    await settleRefresh(next);
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: refresh,
    child: FutureBuilder<_HomeSummary>(
      future: summary,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              SizedBox(height: 280),
              Center(child: CircularProgressIndicator()),
            ],
          );
        }
        if (snapshot.hasError) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 180),
              const Icon(Icons.cloud_off_outlined, size: 42),
              const SizedBox(height: 12),
              Text(snapshot.error.toString(), textAlign: TextAlign.center),
              TextButton(onPressed: refresh, child: const Text('Tekrar dene')),
            ],
          );
        }
        final data = snapshot.data!;
        final nextCompany = data.nextVisit?['company'] as Map?;
        final nextCompanyId = nextCompany?['id']?.toString();
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            Text('Günaydın', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(
              'Bugünün saha özeti',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            FieldModeCard(service: widget.services.fieldMode),
            const SizedBox(height: 12),
            _Metric(
              label: 'Planlanan ziyaret',
              value: '${data.plannedVisits}',
              icon: Icons.route,
              onTap: () => context.go('/visits'),
            ),
            const SizedBox(height: 12),
            _Metric(
              label: 'Açık takip',
              value: '${data.openTasks}',
              icon: Icons.task_alt,
              onTap: () => context.go('/tasks'),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hızlı işlemler',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.mic, size: 18),
                          label: const Text('Ziyaret notu'),
                          onPressed: () => context.go('/visits'),
                        ),
                        ActionChip(
                          avatar: const Icon(
                            Icons.camera_alt_outlined,
                            size: 18,
                          ),
                          label: const Text('Kartvizit tara'),
                          onPressed: () => context.go('/customers'),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.sync, size: 18),
                          label: const Text('Eşitleme'),
                          onPressed: () => context.push('/offline'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (data.nextVisit != null && nextCompanyId != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.memory),
                  title: const Text('Sıradaki ziyaret'),
                  subtitle: Text(
                    '${nextCompany?['name'] ?? 'Müşteri'} · Brifingi görüntüle',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/briefings/$nextCompanyId'),
                ),
              )
            else
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_add_alt_1_outlined),
                  title: const Text('İlk müşterinizi ekleyin'),
                  subtitle: const Text(
                    'Müşteri kaydından sonra ziyaret ve takip oluşturabilirsiniz.',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/customers'),
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _HomeSummary {
  const _HomeSummary({
    required this.plannedVisits,
    required this.openTasks,
    this.nextVisit,
  });

  final int plannedVisits;
  final int openTasks;
  final Map<String, dynamic>? nextVisit;
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      onTap: onTap,
    ),
  );
}
