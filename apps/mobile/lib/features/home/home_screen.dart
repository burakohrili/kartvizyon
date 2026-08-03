import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/mobile_services.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.services});
  final MobileServices services;
  @override
  Widget build(BuildContext context) => ListView(
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
      const _Metric(label: 'Planlanan ziyaret', value: '6', icon: Icons.route),
      const SizedBox(height: 12),
      const _Metric(label: 'Açık takip', value: '4', icon: Icons.task_alt),
      const SizedBox(height: 20),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hızlı işlemler',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.mic, size: 18),
                    label: const Text('Ziyaret notu'),
                    onPressed: () => context.push('/visits'),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.camera_alt_outlined, size: 18),
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
      Card(
        child: ListTile(
          leading: const Icon(Icons.memory),
          title: const Text('Sıradaki ziyaret'),
          subtitle: const Text(
            'Atlas Medikal · 3 onaylı kaynaktan brifing hazır',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/customers'),
        ),
      ),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
    ),
  );
}
