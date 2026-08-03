import 'package:flutter/material.dart';
import '../../core/mobile_services.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.services});
  final MobileServices services;
  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late Future<List<Map<String, dynamic>>> tasks;
  @override
  void initState() {
    super.initState();
    tasks = load();
  }

  Future<void> toggle(Map<String, dynamic> item, bool completed) async {
    final previous = item['status'];
    setState(() => item['status'] = completed ? 'completed' : 'open');
    try {
      await widget.services.api.patch('/api/tasks', {
        'id': item['id'],
        'workspaceId': widget.services.workspaceId,
        'status': item['status'],
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => item['status'] = previous);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<List<Map<String, dynamic>>> load() async {
    if (!widget.services.config.hasSupabase) {
      return const [
        {
          'id': 'demo-1',
          'title': 'Revize teklifi gönder',
          'status': 'open',
          'company': {'name': 'Atlas Medikal'},
        },
        {
          'id': 'demo-2',
          'title': 'Teknik demo tarihini netleştir',
          'status': 'open',
          'company': {'name': 'Atlas Medikal'},
        },
      ];
    }
    final result =
        await widget.services.api.get(
              '/api/tasks?workspaceId=${widget.services.workspaceId}',
            )
            as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(result['data'] as List? ?? []);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Takipler')),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: tasks,
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: snapshot.data!.map((item) {
            final company = item['company'] as Map?;
            return Card(
              child: CheckboxListTile(
                value: item['status'] == 'completed',
                onChanged: item['id'].toString().startsWith('demo')
                    ? null
                    : (value) => toggle(item, value ?? false),
                title: Text(item['title']?.toString() ?? 'Görev'),
                subtitle: Text(company?['name']?.toString() ?? 'Müşteri'),
              ),
            );
          }).toList(),
        );
      },
    ),
  );
}
