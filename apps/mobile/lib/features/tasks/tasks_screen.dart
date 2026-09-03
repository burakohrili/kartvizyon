import 'package:flutter/material.dart';

import '../../core/mobile_services.dart';
import '../../core/refresh.dart';
import '../customers/customer_identity.dart';
import '../customers/customer_picker.dart';
import 'task_list.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key, required this.services});

  final MobileServices services;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  late Future<List<Map<String, dynamic>>> tasks;
  bool creatingTask = false;

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
    // Tamamlamak tek dokunuşla olur; geri almak onay ister. Yanlışlıkla
    // kaldırılan bir tik, tamamlandığı bilgisini ve `completed_at` damgasını
    // sunucuda da siliyor.
    if (!completed) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Görev yeniden açılsın mı?'),
          content: Text(
            '"${item['title'] ?? 'Görev'}" tamamlandı olarak işaretli. '
            'Geri alırsanız tamamlanma zamanı silinir.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Yeniden aç'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
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
    if (creatingTask) return;
    setState(() => creatingTask = true);
    final title = TextEditingController();
    CustomerChoice? customer;
    DateTime? dueAt;
    try {
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
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.apartment_outlined),
                    title: Text(customer?.name ?? 'Müşteri seç (isteğe bağlı)'),
                    subtitle: customer?.legalName == null
                        ? null
                        : Text(
                            customer!.legalName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                    trailing: customer == null
                        ? const Icon(Icons.search)
                        : IconButton(
                            tooltip: 'Müşteriyi kaldır',
                            onPressed: () =>
                                setDialogState(() => customer = null),
                            icon: const Icon(Icons.clear),
                          ),
                    onTap: () async {
                      final selected = await showCustomerPicker(
                        context,
                        services: widget.services,
                      );
                      if (selected != null) {
                        setDialogState(() => customer = selected);
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: Text(
                      dueAt == null
                          ? 'Bitiş tarihi (isteğe bağlı)'
                          : '${dueAt!.day.toString().padLeft(2, '0')}.'
                                '${dueAt!.month.toString().padLeft(2, '0')}.'
                                '${dueAt!.year}',
                    ),
                    trailing: dueAt == null
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Tarihi kaldır',
                            onPressed: () => setDialogState(() => dueAt = null),
                          ),
                    onTap: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: dueAt ?? now,
                        firstDate: DateTime(now.year - 1),
                        lastDate: DateTime(now.year + 3),
                      );
                      if (picked != null) setDialogState(() => dueAt = picked);
                    },
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
      if (accepted != true || taskTitle.isEmpty) return;
      await widget.services.api.post('/api/tasks', {
        'workspaceId': widget.services.workspaceId,
        'organizationId': widget.services.organizationId,
        'companyId': customer?.id,
        'visitId': null,
        'title': taskTitle,
        // Gün sonu değil, mesai saati: 09:00 yerel.
        'dueAt': dueAt == null
            ? null
            : DateTime(
                dueAt!.year,
                dueAt!.month,
                dueAt!.day,
                9,
              ).toUtc().toIso8601String(),
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
    } finally {
      title.dispose();
      if (mounted) setState(() => creatingTask = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Görevler')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: creatingTask ? null : createTask,
      icon: creatingTask
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.add_task),
      label: Text(creatingTask ? 'Açılıyor…' : 'Yeni görev'),
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
          child: Builder(
            builder: (context) {
              final split = splitTasks(items);
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  if (split.open.isNotEmpty) ...[
                    _SectionTitle('Açık görevler (${split.open.length})'),
                    ...split.open.map(_tile),
                  ],
                  if (split.completed.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _SectionTitle('Tamamlananlar (${split.completed.length})'),
                    ...split.completed.map(_tile),
                  ],
                ],
              );
            },
          ),
        );
      },
    ),
  );

  Widget _tile(Map<String, dynamic> item) {
    final company = item['company'] as Map?;
    final completed = item['status']?.toString() == 'completed';
    final due = taskDueLabel(item);
    return Card(
      child: CheckboxListTile(
        value: completed,
        onChanged: (value) => toggle(item, value ?? false),
        title: Text(
          item['title']?.toString() ?? 'Görev',
          style: completed
              ? const TextStyle(decoration: TextDecoration.lineThrough)
              : null,
        ),
        subtitle: Text(
          [
            company == null ? 'Genel görev' : customerDisplayName(company),
            if (due.isNotEmpty) 'Son tarih $due',
          ].join(' · '),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
    child: Text(label, style: Theme.of(context).textTheme.titleSmall),
  );
}
