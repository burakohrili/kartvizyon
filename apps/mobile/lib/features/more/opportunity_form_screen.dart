import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/mobile_services.dart';
import '../../l10n/app_localizations.dart';
import '../customers/customer_picker.dart';

const opportunityStageKeys = <String>[
  'lead',
  'qualified',
  'proposal',
  'negotiation',
  'won',
  'lost',
];

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
  bool ownersLoadStarted = false;
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!ownersLoadStarted) {
      ownersLoadStarted = true;
      _loadOwners();
    }
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
              (row['profile'] as Map?)?['full_name']?.toString() ?? '',
            ),
          )
          .where((entry) => entry.$1.isNotEmpty)
          .toList();
      if (!mounted) return;
      setState(() {
        owners = next.isEmpty
            ? [(widget.services.ownerId, widget.services.displayName ?? '')]
            : next;
        assignedTo ??= widget.services.ownerId;
        loadingOwners = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        owners = [(widget.services.ownerId, widget.services.displayName ?? '')];
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
    final l10n = AppLocalizations.of(context)!;
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
    } on MobileApiException catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.opportunityNetworkError)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.opportunityNetworkError)));
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final stageLabel = <String, String>{
      'lead': l10n.opportunityStageLead,
      'qualified': l10n.opportunityStageQualified,
      'proposal': l10n.opportunityStageProposal,
      'negotiation': l10n.opportunityStageNegotiation,
      'won': l10n.opportunityStageWon,
      'lost': l10n.opportunityStageLost,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(
          editing ? l10n.opportunityEditTitle : l10n.opportunityNewTitle,
        ),
      ),
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
                decoration: InputDecoration(
                  labelText: l10n.opportunityName,
                  border: OutlineInputBorder(),
                ),
                validator: (text) => (text?.trim().length ?? 0) < 2
                    ? l10n.opportunityNameTooShort
                    : null,
              ),
              const SizedBox(height: 8),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  minTileHeight: 64,
                  leading: const Icon(Icons.apartment_outlined),
                  title: Text(
                    customer == null
                        ? l10n.opportunityCustomerSelect
                        : customer!.name.trim().isEmpty
                        ? l10n.companyFallback
                        : customer!.name,
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
                Padding(
                  padding: EdgeInsets.only(left: 12, top: 6),
                  child: Text(
                    l10n.opportunityCustomerRequired,
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
                    decoration: InputDecoration(
                      labelText: l10n.opportunityEstimatedValue,
                      border: OutlineInputBorder(),
                    ),
                    validator: (_) {
                      final parsed = _parsedValue();
                      if (parsed == null) return l10n.opportunityInvalidAmount;
                      if (parsed < 0) return l10n.opportunityNegativeAmount;
                      if (parsed > 1000000000) {
                        return l10n.opportunityAmountTooHigh;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: currency,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n.opportunityCurrency,
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
                decoration: InputDecoration(
                  labelText: l10n.opportunityStage,
                  border: OutlineInputBorder(),
                ),
                items: opportunityStageKeys
                    .map(
                      (key) => DropdownMenuItem(
                        value: key,
                        child: Text(stageLabel[key]!),
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
                decoration: InputDecoration(
                  labelText: l10n.opportunityWinProbability,
                  border: OutlineInputBorder(),
                ),
                items: const [0, 10, 25, 50, 75, 90, 100]
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          NumberFormat.percentPattern(
                            locale,
                          ).format(item / 100),
                        ),
                      ),
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
                      ? l10n.opportunityExpectedCloseChoose
                      : l10n.opportunityExpectedClose(
                          _date(expectedClose!, locale),
                        ),
                ),
              ),
              if (expectedClose != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: submitting
                        ? null
                        : () => setState(() => expectedClose = null),
                    child: Text(l10n.opportunityRemoveDate),
                  ),
                ),
              const SizedBox(height: 8),
              TextFormField(
                controller: competitor,
                maxLength: 160,
                decoration: InputDecoration(
                  labelText: l10n.opportunityCompetitor,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                key: ValueKey('$loadingOwners-$assignedTo-${owners.length}'),
                initialValue: loadingOwners ? null : assignedTo,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.opportunityOwner,
                  border: OutlineInputBorder(),
                ),
                items: owners
                    .map(
                      (owner) => DropdownMenuItem(
                        value: owner.$1,
                        child: Text(
                          owner.$2.isNotEmpty
                              ? owner.$2
                              : owner.$1 == widget.services.ownerId
                              ? l10n.opportunityMe
                              : l10n.opportunityUserFallback,
                        ),
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
                  decoration: InputDecoration(
                    labelText: l10n.opportunityLossReason,
                    border: OutlineInputBorder(),
                  ),
                  validator: (text) =>
                      stage == 'lost' && (text?.trim().length ?? 0) < 2
                      ? l10n.opportunityLossReasonRequired
                      : null,
                ),
              ],
              const SizedBox(height: 8),
              Text(l10n.opportunityModelNotice),
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
                : Text(
                    widget.services.canWrite
                        ? l10n.opportunitySave
                        : l10n.visitPlanSubscriptionRequired,
                  ),
          ),
        ),
      ),
    );
  }

  static String _date(DateTime value, String locale) =>
      DateFormat.yMd(locale).format(value);
}
