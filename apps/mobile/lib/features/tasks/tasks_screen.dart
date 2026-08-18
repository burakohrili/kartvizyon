import 'package:flutter/material.dart';

import '../../core/mobile_services.dart';
import '../../core/refresh.dart';

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

  Future<List<Map<String, dynamic>>> load() async {
    if (!widget.services.config.hasSupabase) return const [];
    await widget.services.refreshContext();
    final result =
        await widget.services.api.get(
              '/api/tasks?workspaceId=${widget.services.workspaceId}',
            )
            as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(result['data'] as List? ?? []);
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

  Future<void> createTask() async {
    final title = TextEditingController();
    var customers = <Map<String, dynamic>>[];
    try {
      final response =
          await widget.services.api.get(
                '/api/customers?workspaceId=${widget.services.workspaceId}',
              )
              as Map<String, dynamic>;
      customers = List<Map<String, dynamic>>.from(
        response['data'] as List? ?? [],
      );
    } catch (error) {
      title.dispose();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
      return;
    }
    if (!mounted) return;
    String? companyId;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yeni görev'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Görev *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  // ignore: deprecated_member_use
                  value: companyId,
                  decoration: const InputDecoration(
                    labelText: 'Müşteri (isteğe bağlı)',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Müşteri seçmeden devam et'),
                    ),
                    ...customers.map(
                      (customer) => DropdownMenuItem<String?>(
                        value: customer['id']?.toString(),
                        child: Text(customer['name']?.toString() ?? 'Firma'),
                      ),
                    ),
                  ],
                  onChanged: (value) => setDialogState(() => companyId = value),
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
              onPressed: () =>
                  Navigator.pop(dialogContext, title.text.trim().isNotEmpty),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
    final taskTitle = title.text.trim();
    title.dispose();
    if (accepted != true || taskTitle.isEmpty) return;
    try {
      await widget.services.api.post('/api/tasks', {
        'workspaceId': widget.services.workspaceId,
        'organizationId': widget.services.organizationId,
        'companyId': companyId,
        'visitId': null,
        'title': taskTitle,
        'dueAt': null,
        'assignedTo': null,
      });
      if (!mounted) return;
      setState(() => tasks = load());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Görev kaydedildi.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Görevler')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: createTask,
      icon: const Icon(Icons.add_task),
      label: const Text('Yeni görev'),
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: tasks,
      builder: (_, snapshot) {
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
                    onPressed: () => setState(() => tasks = load()),
                    child: const Text('Tekrar dene'),
                  ),
                ],
              ),
            ),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Text(
                'Henüz görev yok. Yeni görev düğmesiyle ilk takibinizi oluşturun.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            final next = load();
            setState(() => tasks = next);
            await settleRefresh(next);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: items.map((item) {
              final company = item['company'] as Map?;
              return Card(
                child: CheckboxListTile(
                  value: item['status'] == 'completed',
                  onChanged: (value) => toggle(item, value ?? false),
                  title: Text(item['title']?.toString() ?? 'Görev'),
                  subtitle: Text(company?['name']?.toString() ?? 'Genel görev'),
                ),
              );
            }).toList(),
          ),
        );
      },
    ),
  );
}
