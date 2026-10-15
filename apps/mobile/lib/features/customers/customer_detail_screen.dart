import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../core/mobile_services.dart';
import '../../l10n/app_localizations.dart';

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({
    super.key,
    required this.services,
    required this.companyId,
  });

  final MobileServices services;
  final String companyId;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late Future<Map<String, dynamic>> _detail;
  bool _pinning = false;
  bool _mutating = false;

  @override
  void initState() {
    super.initState();
    _detail = _load();
    if (widget.services.fieldMode.isActive.value) {
      // Saha modu açıkken müşteri kaydına girmek de kontrol sinyalidir.
      // Yakın zamanda kontrol edildiyse servis yeni ağ isteği üretmez.
      unawaited(widget.services.fieldMode.checkCurrentLocation());
    }
  }

  Future<Map<String, dynamic>> _load() async {
    if (!widget.services.config.hasSupabase) {
      return {
        'company': {'name': ''},
        'memory': null,
        'contacts': const [],
        'tasks': const [],
      };
    }
    return await widget.services.api.get('/api/customers/${widget.companyId}')
        as Map<String, dynamic>;
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editCompany(Map company) async {
    final strings = AppLocalizations.of(context)!;
    final draft = await _showCompanyEditor(context, company);
    if (draft == null || !mounted) return;
    setState(() => _mutating = true);
    try {
      await widget.services.api.patch(
        '/api/customers/${widget.companyId}',
        draft,
      );
      if (!mounted) return;
      setState(() => _detail = _load());
      _notify(strings.customerUpdated);
    } catch (_) {
      _notify(strings.customerUpdateFailed);
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _editContact([Map? contact]) async {
    final strings = AppLocalizations.of(context)!;
    final draft = await _showContactEditor(context, contact);
    if (draft == null || !mounted) return;
    setState(() => _mutating = true);
    try {
      if (contact == null) {
        await widget.services.api.post('/api/contacts', {
          ...draft,
          'companyId': widget.companyId,
          'workspaceId': widget.services.workspaceId,
          'organizationId': widget.services.organizationId,
        });
      } else {
        await widget.services.api.patch('/api/contacts', {
          ...draft,
          'id': contact['id'],
        });
      }
      if (!mounted) return;
      setState(() => _detail = _load());
      _notify(contact == null ? strings.contactAdded : strings.contactUpdated);
    } catch (_) {
      _notify(strings.contactSaveGenericFailed);
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _archive(String companyName, Map dependencies) async {
    final strings = AppLocalizations.of(context)!;
    int count(String key) => (dependencies[key] as num?)?.toInt() ?? 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.archiveCustomerTitle(companyName)),
        content: Text(
          [
            strings.archiveCustomerIntro,
            '',
            strings.archiveContactsCount(count('contacts')),
            strings.archiveVisitsCount(count('visits')),
            strings.archiveOpenTasksCount(count('openTasks')),
            strings.archiveOpportunitiesCount(count('opportunities')),
            strings.archiveOrdersCount(count('orders')),
            strings.archiveDocumentsCount(count('documents')),
            '',
            strings.archivePreservesData,
          ].join('\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.archive),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _mutating = true);
    try {
      await widget.services.api.patch('/api/customers/${widget.companyId}', {
        'action': 'archive',
      });
      if (mounted) context.pop(true);
    } catch (_) {
      _notify(strings.customerArchiveFailed);
      if (mounted) setState(() => _mutating = false);
    }
  }

  /// Ne kaydedileceğini, basmadan önce açıkça söyler.
  ///
  /// Kaydedilen şey müşterinin konumudur; kullanıcının hareket geçmişi
  /// tutulmaz. Kullanıcının bunu bilmeden onaylaması istenmemelidir.
  Future<bool> _confirmPin(String companyName) async {
    final strings = AppLocalizations.of(context)!;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.pinCustomerLocationTitle),
        content: Text(
          '${strings.pinCustomerLocationBody(companyName)}\n\n'
          '${strings.pinCustomerLocationPrivacy}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.pinCustomerLocation),
          ),
        ],
      ),
    );
    return accepted ?? false;
  }

  Future<void> _pinLocation(String companyName) async {
    if (_pinning) return;
    final strings = AppLocalizations.of(context)!;
    if (!await _confirmPin(companyName)) return;
    if (!mounted) return;
    setState(() => _pinning = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _notify(strings.locationServiceOff);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _notify(strings.locationPermissionDeniedForCustomer);
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 20),
        ),
      );
      await widget.services.api
          .post('/api/customers/${widget.companyId}/location', {
            'latitude': position.latitude,
            'longitude': position.longitude,
          })
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      setState(() => _detail = _load());
      _notify(strings.customerLocationPinned);
    } catch (_) {
      _notify(strings.customerLocationPinFailed);
    } finally {
      if (mounted) setState(() => _pinning = false);
    }
  }

  String _locationLabel(Map company, AppLocalizations strings) {
    final source = company['location_source']?.toString();
    if (source == 'pinned') return strings.locationPinnedAtSite;
    if (source == 'geocoded') return strings.locationEstimatedFromAddress;
    return strings.customerLocationMissing;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(AppLocalizations.of(context)!.customerDetailTitle),
    ),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _detail,
      builder: (context, snapshot) {
        final strings = AppLocalizations.of(context)!;
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                strings.customerLoadFailed,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final data = snapshot.data!;
        final company = data['company'] as Map? ?? {};
        final memory = data['memory'] as Map?;
        final contacts = data['contacts'] as List? ?? [];
        final tasks = data['tasks'] as List? ?? [];
        final dependencies = data['dependencies'] as Map? ?? {};
        final companyName =
            company['name']?.toString() ?? strings.companyFallback;
        final hasLocation =
            company['latitude'] != null && company['longitude'] != null;
        return ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: [
            Text(
              companyName,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(company['address']?.toString() ?? ''),
            if ((company['phone']?.toString() ?? '').isNotEmpty)
              Text(company['phone'].toString()),
            if ((company['email']?.toString() ?? '').isNotEmpty)
              Text(company['email'].toString()),
            if ((company['website']?.toString() ?? '').isNotEmpty)
              Text(company['website'].toString()),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _mutating ? null : () => _editCompany(company),
              icon: const Icon(Icons.edit_outlined),
              label: Text(strings.editCustomer),
            ),
            const SizedBox(height: 14),
            // Brifinge yalnız Bugün ekranındaki "sıradaki ziyaret" kartından
            // ve onaylanmış ziyaret satırından gidilebiliyordu. Ziyarete
            // giderken insanın açtığı ilk yer müşteri kartı; ziyaret öncesi
            // bağlam buradan ulaşılabilir olmalı.
            FilledButton.icon(
              onPressed: () => context.push('/briefings/${widget.companyId}'),
              icon: const Icon(Icons.assignment_outlined),
              label: Text(strings.openVisitBriefing),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasLocation
                              ? Icons.location_on_outlined
                              : Icons.location_off_outlined,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_locationLabel(company, strings))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: _pinning
                          ? null
                          : () => _pinLocation(companyName),
                      icon: _pinning
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(
                        hasLocation
                            ? strings.updateCustomerLocation
                            : strings.pinCustomerLocation,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.customerMemoryCard,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      memory?['summary']?.toString() ??
                          strings.noApprovedSummary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    strings.customerContactsCount(contacts.length),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: _mutating ? null : () => _editContact(),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: Text(strings.addContact),
                ),
              ],
            ),
            ...contacts.map((item) {
              final value = item as Map;
              return ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(
                  '${value['first_name'] ?? ''} ${value['last_name'] ?? ''}',
                ),
                subtitle: Text(value['title']?.toString() ?? ''),
                trailing: const Icon(Icons.edit_outlined),
                onTap: _mutating ? null : () => _editContact(value),
              );
            }),
            const Divider(),
            Text(
              strings.openTasksCount(tasks.length),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ...tasks.map(
              (item) => ListTile(
                leading: const Icon(Icons.task_alt),
                title: Text(
                  (item as Map)['title']?.toString() ?? strings.taskFallback,
                ),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _mutating
                  ? null
                  : () => _archive(companyName, dependencies),
              icon: const Icon(Icons.archive_outlined),
              label: Text(strings.archiveCustomerAction),
            ),
          ],
        );
      },
    ),
  );
}

Future<Map<String, dynamic>?> _showCompanyEditor(
  BuildContext context,
  Map company,
) {
  final strings = AppLocalizations.of(context)!;
  final formKey = GlobalKey<FormState>();
  final fields = {
    'name': TextEditingController(text: company['name']?.toString() ?? ''),
    'displayName': TextEditingController(
      text: company['display_name']?.toString() ?? '',
    ),
    'address': TextEditingController(
      text: company['address']?.toString() ?? '',
    ),
    'phone': TextEditingController(text: company['phone']?.toString() ?? ''),
    'email': TextEditingController(text: company['email']?.toString() ?? ''),
    'website': TextEditingController(
      text: company['website']?.toString() ?? '',
    ),
  };
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    strings.editCustomer,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _field(
                    fields['name']!,
                    strings.companyNameRequired,
                    validator: (value) => (value?.trim().length ?? 0) < 2
                        ? strings.companyNameTooShort
                        : null,
                  ),
                  _field(fields['displayName']!, strings.shortNameField),
                  _field(fields['address']!, strings.address),
                  _field(
                    fields['phone']!,
                    strings.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  _field(
                    fields['email']!,
                    strings.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _field(
                    fields['website']!,
                    strings.website,
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(strings.cancel),
                      ),
                      FilledButton(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(dialogContext, {
                            for (final entry in fields.entries)
                              entry.key: entry.value.text.trim(),
                          });
                        },
                        child: Text(strings.saveCustomer),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ).whenComplete(() {
    for (final controller in fields.values) {
      controller.dispose();
    }
  });
}

Future<Map<String, dynamic>?> _showContactEditor(
  BuildContext context, [
  Map? contact,
]) {
  final strings = AppLocalizations.of(context)!;
  final formKey = GlobalKey<FormState>();
  final fields = {
    'firstName': TextEditingController(
      text: contact?['first_name']?.toString() ?? '',
    ),
    'lastName': TextEditingController(
      text: contact?['last_name']?.toString() ?? '',
    ),
    'title': TextEditingController(text: contact?['title']?.toString() ?? ''),
    'phone': TextEditingController(text: contact?['phone']?.toString() ?? ''),
    'email': TextEditingController(text: contact?['email']?.toString() ?? ''),
  };
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    contact == null ? strings.newContact : strings.editContact,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _field(
                    fields['firstName']!,
                    '${strings.firstName} *',
                    validator: (value) => (value?.trim().isEmpty ?? true)
                        ? strings.firstNameRequired
                        : null,
                  ),
                  _field(fields['lastName']!, strings.lastName),
                  _field(fields['title']!, strings.jobTitle),
                  _field(
                    fields['phone']!,
                    strings.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  _field(
                    fields['email']!,
                    strings.email,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(strings.cancel),
                      ),
                      FilledButton(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(dialogContext, {
                            for (final entry in fields.entries)
                              entry.key: entry.value.text.trim(),
                          });
                        },
                        child: Text(strings.saveCustomer),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  ).whenComplete(() {
    for (final controller in fields.values) {
      controller.dispose();
    }
  });
}

Widget _field(
  TextEditingController controller,
  String label, {
  TextInputType? keyboardType,
  String? Function(String?)? validator,
}) => TextFormField(
  controller: controller,
  keyboardType: keyboardType,
  textInputAction: TextInputAction.next,
  decoration: InputDecoration(labelText: label),
  validator: validator,
);
