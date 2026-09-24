import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/mobile_services.dart';
import '../customers/customer_picker.dart';

class VisitPlanningScreen extends StatefulWidget {
  const VisitPlanningScreen({super.key, required this.services});

  final MobileServices services;

  @override
  State<VisitPlanningScreen> createState() => _VisitPlanningScreenState();
}

class _VisitPlanningScreenState extends State<VisitPlanningScreen> {
  static const visitTypes = <(String, String)>[
    ('sales_meeting', 'Satış görüşmesi'),
    ('quote_follow_up', 'Teklif takibi'),
    ('order_follow_up', 'Sipariş takibi'),
    ('introduction', 'Tanışma'),
    ('technical', 'Teknik görüşme'),
    ('other', 'Diğer'),
  ];
  static const durations = [30, 45, 60, 90, 120];

  final formKey = GlobalKey<FormState>();
  final purpose = TextEditingController();
  final note = TextEditingController();
  CustomerChoice? customer;
  String visitType = visitTypes.first.$1;
  DateTime start = DateTime.now().add(const Duration(hours: 1));
  int durationMinutes = 60;
  bool submitting = false;
  bool attempted = false;

  @override
  void dispose() {
    purpose.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> pickCustomer() async {
    final selected = await showCustomerPicker(
      context,
      services: widget.services,
    );
    if (selected != null && mounted) setState(() => customer = selected);
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 1095)),
    );
    if (selected == null || !mounted) return;
    setState(() {
      start = DateTime(
        selected.year,
        selected.month,
        selected.day,
        start.hour,
        start.minute,
      );
    });
  }

  Future<void> pickTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(start),
    );
    if (selected == null || !mounted) return;
    setState(() {
      start = DateTime(
        start.year,
        start.month,
        start.day,
        selected.hour,
        selected.minute,
      );
    });
  }

  Future<void> submit() async {
    if (submitting) return;
    FocusScope.of(context).unfocus();
    setState(() => attempted = true);
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (customer == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Müşteri seçin.')));
      return;
    }
    if (!start.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gelecekte bir başlangıç seçin.')),
      );
      return;
    }

    setState(() => submitting = true);
    final end = start.add(Duration(minutes: durationMinutes));
    final mutationId = const Uuid().v4();
    try {
      await widget.services.requireWriteAccess();
      await widget.services.api.post('/api/calendar', {
        'workspaceId': widget.services.workspaceId,
        'companyId': customer!.id,
        'representativeId': widget.services.ownerId,
        'clientMutationId': mutationId,
        'purpose': purpose.text.trim(),
        'visitType': visitType,
        'planningNote': note.text.trim().isEmpty ? null : note.text.trim(),
        'plannedStartAt': start.toUtc().toIso8601String(),
        'plannedEndAt': end.toUtc().toIso8601String(),
      });
      await widget.services.reminders.sync();
      if (!mounted) return;
      Navigator.pop(context, true);
    } on MobileApiException catch (error) {
      if (error.statusCode == 408) {
        await _enqueueOffline(end, mutationId);
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      await _enqueueOffline(end, mutationId);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  Future<void> _enqueueOffline(DateTime end, String mutationId) async {
    await widget.services.queue.enqueuePlannedVisitCreate(
      ownerId: widget.services.ownerId,
      workspaceId: widget.services.workspaceId,
      organizationId: widget.services.organizationId,
      companyId: customer!.id,
      purpose: purpose.text.trim(),
      visitType: visitType,
      planningNote: note.text.trim(),
      plannedStartAt: start,
      plannedEndAt: end,
      clientMutationId: mutationId,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Planlı ziyaret çevrimdışı kuyruğa alındı. Hatırlatmalar senkronizasyondan sonra oluşturulur.',
        ),
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final selectedType = visitTypes.firstWhere(
      (entry) => entry.$1 == visitType,
    );
    final customerError = customer == null && attempted;
    return Scaffold(
      appBar: AppBar(title: const Text('Ziyaret planla')),
      body: SafeArea(
        child: Form(
          key: formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              Text('Müşteri', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 6),
              Semantics(
                button: true,
                label: customer == null
                    ? 'Müşteri seçilmedi, zorunlu alan'
                    : 'Seçili müşteri ${customer!.name}',
                child: Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    minTileHeight: 64,
                    leading: const Icon(Icons.apartment_outlined),
                    title: Text(
                      customer?.name ?? 'Müşteri seç *',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: (customer?.address ?? '').trim().isEmpty
                        ? null
                        : Text(
                            customer!.address!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                    trailing: const Icon(Icons.search),
                    onTap: submitting ? null : pickCustomer,
                  ),
                ),
              ),
              if (customerError)
                const Padding(
                  padding: EdgeInsets.only(top: 6, left: 12),
                  child: Text(
                    'Müşteri seçin.',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: visitType,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Ziyaret türü',
                  border: OutlineInputBorder(),
                ),
                items: visitTypes
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.$1,
                        child: Text(entry.$2),
                      ),
                    )
                    .toList(),
                onChanged: submitting
                    ? null
                    : (value) => setState(() => visitType = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: purpose,
                maxLength: 500,
                minLines: 1,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Amaç *',
                  hintText: 'Örn. Yeni teklif üzerinden geçmek',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final length = value?.trim().length ?? 0;
                  if (length < 2) return 'Amacı en az 2 karakter yazın.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Tarih ve saat',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: submitting ? null : pickDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(_dateLabel(start)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: submitting ? null : pickTime,
                      icon: const Icon(Icons.schedule_outlined),
                      label: Text(_timeLabel(start)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: durationMinutes,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Süre',
                  border: OutlineInputBorder(),
                ),
                items: durations
                    .map(
                      (minutes) => DropdownMenuItem(
                        value: minutes,
                        child: Text(_durationLabel(minutes)),
                      ),
                    )
                    .toList(),
                onChanged: submitting
                    ? null
                    : (value) => setState(() => durationMinutes = value!),
              ),
              const SizedBox(height: 20),
              Card(
                margin: EdgeInsets.zero,
                child: const ListTile(
                  minTileHeight: 72,
                  leading: Icon(Icons.notifications_active_outlined),
                  title: Text('Genel ziyaret hatırlatmaları'),
                  subtitle: Text(
                    'Bildirim Merkezi ayarınız açıksa 1 gün ve 2 saat önce',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: note,
                maxLength: 2000,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Planlama notu',
                  hintText: 'Görüşme öncesi kısa hazırlık notu',
                  helperText: 'Ziyaret sonrası değerlendirme notundan ayrıdır.',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Seçim: ${selectedType.$2} · ${_durationLabel(durationMinutes)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: submitting || !widget.services.canWrite ? null : submit,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: submitting
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    widget.services.canWrite
                        ? 'Ziyareti planla'
                        : 'Abonelik gerekli',
                  ),
          ),
        ),
      ),
    );
  }

  static String _dateLabel(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';

  static String _timeLabel(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  static String _durationLabel(int minutes) => switch (minutes) {
    60 => '1 saat',
    90 => '1 saat 30 dk',
    120 => '2 saat',
    _ => '$minutes dk',
  };
}
