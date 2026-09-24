import 'package:flutter/material.dart';

import '../../core/mobile_services.dart';
import '../customers/customer_picker.dart';

const opportunityStages = <String, String>{
  'lead': 'Potansiyel',
  'qualified': 'Nitelikli',
  'proposal': 'Teklif',
  'negotiation': 'Müzakere',
  'won': 'Kazanıldı',
  'lost': 'Kaybedildi',
};

const _stageProbability = <String, int>{
  'lead': 10,
  'qualified': 25,
  'proposal': 50,
  'negotiation': 75,
  'won': 100,
  'lost': 0,
};

class OpportunityFormScreen extends StatefulWidget {
  const OpportunityFormScreen({
    super.key,
    required this.services,
    this.opportunity,
  });

  final MobileServices services;
  final Map<String, dynamic>? opportunity;

  @override
  State<OpportunityFormScreen> createState() => _OpportunityFormScreenState();
}

class _OpportunityFormScreenState extends State<OpportunityFormScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController title;
  late final TextEditingController value;
  late final TextEditingController competitor;
  late final TextEditingController lossReason;
  CustomerChoice? customer;
  String stage = 'lead';
  String currency = 'TRY';
  int probability = 10;
  DateTime? expectedClose;
  String? assignedTo;
  List<(String, String)> owners = const [];
  bool loadingOwners = true;
  bool submitting = false;
  bool attempted = false;
  bool probabilityTouched = false;

  bool get editing => widget.opportunity != null;

  @override
  void initState() {
    super.initState();
    final item = widget.opportunity;
    title = TextEditingController(text: item?['title']?.toString() ?? '');
    value = TextEditingController(
      text: item?['estimated_value']?.toString() ?? '0',
    );
    competitor = TextEditingController(
      text: item?['competitor']?.toString() ?? '',
    );
    lossReason = TextEditingController(
      text: item?['loss_reason']?.toString() ?? '',
    );
    stage = item?['stage']?.toString() ?? stage;
    currency = item?['currency']?.toString() ?? currency;
    probability = (item?['probability'] as num?)?.toInt() ?? probability;
    assignedTo = item?['assigned_to']?.toString();
    expectedClose = DateTime.tryParse(
      item?['expected_close_date']?.toString() ?? '',
    );
    final company = item?['company'];
    if (company is Map) {
      customer = CustomerChoice.fromMap(Map<String, dynamic>.from(company));
    }
    _loadOwners();
  }

  Future<void> _loadOwners() async {
    try {
      await widget.services.refreshContext();
      final response =
          await widget.services.api.get('/api/opportunities') as Map;
      final data = List<Map<String, dynamic>>.from(
        response['owners'] as List? ?? const [],
      );
      final next = data
          .map(
            (row) => (
              row['user_id']?.toString() ?? '',
              (row['profile'] as Map?)?['full_name']?.toString() ?? 'Kullanıcı',
            ),
          )
          .where((entry) => entry.$1.isNotEmpty)
          .toList();
      if (!mounted) return;
      setState(() {
        owners = next.isEmpty
            ? [(widget.services.ownerId, widget.services.displayName ?? 'Ben')]
            : next;
        assignedTo ??= widget.services.ownerId;
        loadingOwners = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        owners = [
          (widget.services.ownerId, widget.services.displayName ?? 'Ben'),
        ];
        assignedTo ??= widget.services.ownerId;
        loadingOwners = false;
      });
    }
  }

  @override
  void dispose() {
    title.dispose();
    value.dispose();
    competitor.dispose();
    lossReason.dispose();
    super.dispose();
  }

  Future<void> _pickCustomer() async {
    final selected = await showCustomerPicker(
      context,
      services: widget.services,
    );
    if (selected != null && mounted) setState(() => customer = selected);
  }

  Future<void> _pickCloseDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: expectedClose ?? now.add(const Duration(days: 30)),
      firstDate: editing
          ? DateTime(2000)
          : DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 10),
    );
    if (selected != null && mounted) setState(() => expectedClose = selected);
  }

  double? _parsedValue() => double.tryParse(
    value.text.trim().replaceAll(' ', '').replaceAll(',', '.'),
  );

  Future<void> _submit() async {
    if (submitting) return;
    FocusScope.of(context).unfocus();
    setState(() => attempted = true);
    if (!(formKey.currentState?.validate() ?? false) || customer == null) {
      return;
    }
    setState(() => submitting = true);
    final body = <String, dynamic>{
      if (editing) 'id': widget.opportunity!['id'],
      if (!editing) 'workspaceId': widget.services.workspaceId,
      if (!editing) 'companyId': customer!.id,
      'title': title.text.trim(),
      'stage': stage,
      'estimatedValue': _parsedValue(),
      'currency': currency,
      'probability': probability,
      'expectedCloseDate': expectedClose == null
          ? null
          : '${expectedClose!.year.toString().padLeft(4, '0')}-${expectedClose!.month.toString().padLeft(2, '0')}-${expectedClose!.day.toString().padLeft(2, '0')}',
      'competitor': competitor.text.trim().isEmpty
          ? null
          : competitor.text.trim(),
      'assignedTo': assignedTo,
      if (editing)
        'lossReason': stage == 'lost' ? lossReason.text.trim() : null,
    };
    try {
      await widget.services.requireWriteAccess();
      if (editing) {
        await widget.services.api.patch('/api/opportunities', body);
      } else {
        await widget.services.api.post('/api/opportunities', body);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } on MobileApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bağlantı kurulamadı. Form bilgileriniz korunuyor.'),
        ),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(editing ? 'Fırsatı düzenle' : 'Yeni fırsat')),
    body: SafeArea(
      child: Form(
        key: formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            TextFormField(
              controller: title,
              maxLength: 180,
              decoration: const InputDecoration(
                labelText: 'Fırsat adı *',
                border: OutlineInputBorder(),
              ),
              validator: (text) => (text?.trim().length ?? 0) < 2
                  ? 'Fırsat adını en az 2 karakter yazın.'
                  : null,
            ),
            const SizedBox(height: 8),
            Card(
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
                trailing: editing
                    ? const Icon(Icons.lock_outline)
                    : const Icon(Icons.search),
                onTap: editing || submitting ? null : _pickCustomer,
              ),
            ),
            if (attempted && customer == null)
              const Padding(
                padding: EdgeInsets.only(left: 12, top: 6),
                child: Text(
                  'Müşteri seçin.',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 16),
            Column(
              children: [
                TextFormField(
                  controller: value,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Tahmini değer',
                    border: OutlineInputBorder(),
                  ),
                  validator: (_) {
                    final parsed = _parsedValue();
                    if (parsed == null) return 'Geçerli bir tutar yazın.';
                    if (parsed < 0) return 'Tutar negatif olamaz.';
                    if (parsed > 1000000000) return 'Tutar çok yüksek.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: currency,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Para birimi',
                    border: OutlineInputBorder(),
                  ),
                  items: const ['TRY', 'USD', 'EUR']
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: submitting
                      ? null
                      : (item) => setState(() => currency = item!),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: stage,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Aşama',
                border: OutlineInputBorder(),
              ),
              items: opportunityStages.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              onChanged: submitting
                  ? null
                  : (next) => setState(() {
                      stage = next!;
                      if (!editing && !probabilityTouched) {
                        probability = _stageProbability[next]!;
                      }
                    }),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              key: const ValueKey('opportunity-probability'),
              initialValue: probability,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Kazanma olasılığı',
                border: OutlineInputBorder(),
              ),
              items: const [0, 10, 25, 50, 75, 90, 100]
                  .map(
                    (item) =>
                        DropdownMenuItem(value: item, child: Text('%$item')),
                  )
                  .toList(),
              onChanged: submitting
                  ? null
                  : (next) => setState(() {
                      probability = next!;
                      probabilityTouched = true;
                    }),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              key: const ValueKey('opportunity-close-date'),
              onPressed: submitting ? null : _pickCloseDate,
              icon: const Icon(Icons.event_outlined),
              label: Text(
                expectedClose == null
                    ? 'Tahmini kapanış tarihi seç'
                    : 'Tahmini kapanış: ${_date(expectedClose!)}',
              ),
            ),
            if (expectedClose != null)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: submitting
                      ? null
                      : () => setState(() => expectedClose = null),
                  child: const Text('Tarihi kaldır'),
                ),
              ),
            const SizedBox(height: 8),
            TextFormField(
              controller: competitor,
              maxLength: 160,
              decoration: const InputDecoration(
                labelText: 'Rakip',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              key: ValueKey('$loadingOwners-$assignedTo-${owners.length}'),
              initialValue: loadingOwners ? null : assignedTo,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Sorumlu',
                border: OutlineInputBorder(),
              ),
              items: owners
                  .map(
                    (owner) => DropdownMenuItem(
                      value: owner.$1,
                      child: Text(owner.$2),
                    ),
                  )
                  .toList(),
              onChanged: loadingOwners || submitting
                  ? null
                  : (next) => setState(() => assignedTo = next),
            ),
            if (stage == 'lost') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: lossReason,
                maxLength: 500,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Kaybetme nedeni *',
                  border: OutlineInputBorder(),
                ),
                validator: (text) =>
                    stage == 'lost' && (text?.trim().length ?? 0) < 2
                    ? 'Kaybetme nedenini yazın.'
                    : null,
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'Not ve sonraki adım alanları mevcut fırsat modelinde bulunmadığı için bu sürümde eklenmedi.',
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.all(16),
      child: FilledButton(
        onPressed: submitting || !widget.services.canWrite ? null : _submit,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: submitting
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.services.canWrite ? 'Kaydet' : 'Abonelik gerekli'),
        ),
      ),
    ),
  );

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
}
