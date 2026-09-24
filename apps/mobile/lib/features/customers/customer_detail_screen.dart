import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../core/mobile_services.dart';

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
  }

  Future<Map<String, dynamic>> _load() async {
    if (!widget.services.config.hasSupabase) {
      return {
        'company': {'name': 'Müşteri'},
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
      _notify('Müşteri bilgileri güncellendi.');
    } catch (error) {
      _notify(
        error is MobileApiException ? error.message : 'Müşteri güncellenemedi.',
      );
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _editContact([Map? contact]) async {
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
      _notify(
        contact == null ? 'İlgili kişi eklendi.' : 'İlgili kişi güncellendi.',
      );
    } catch (error) {
      _notify(
        error is MobileApiException
            ? error.message
            : 'İlgili kişi kaydedilemedi.',
      );
    } finally {
      if (mounted) setState(() => _mutating = false);
    }
  }

  Future<void> _archive(String companyName, Map dependencies) async {
    String count(String key, String label) =>
        '${dependencies[key] ?? 0} $label';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$companyName arşivlensin mi?'),
        content: Text(
          'Bu müşteriye bağlı:\n\n'
          '${count('contacts', 'ilgili kişi')}\n'
          '${count('visits', 'ziyaret')}\n'
          '${count('openTasks', 'açık görev')}\n'
          '${count('opportunities', 'fırsat')}\n'
          '${count('orders', 'sipariş taslağı')}\n'
          '${count('documents', 'belge')}\n\n'
          'Bu kayıtlar silinmeyecek. Müşteri aktif müşteri listenizden kaldırılacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Arşivle'),
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
    } catch (error) {
      _notify(
        error is MobileApiException ? error.message : 'Müşteri arşivlenemedi.',
      );
      if (mounted) setState(() => _mutating = false);
    }
  }

  /// Ne kaydedileceğini, basmadan önce açıkça söyler.
  ///
  /// Kaydedilen şey müşterinin konumudur; kullanıcının hareket geçmişi
  /// tutulmaz. Kullanıcının bunu bilmeden onaylaması istenmemelidir.
  Future<bool> _confirmPin(String companyName) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konumu buraya sabitle'),
        content: Text(
          '$companyName kaydına şu anki konumunuz müşterinin konumu olarak '
          'yazılacak. Böylece bu müşterinin yakınına geldiğinizde hatırlatma '
          'alabilirsiniz.\n\n'
          'Yalnızca müşterinin konumu saklanır; sizin hareketleriniz '
          'kaydedilmez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sabitle'),
          ),
        ],
      ),
    );
    return accepted ?? false;
  }

  Future<void> _pinLocation(String companyName) async {
    if (_pinning) return;
    if (!await _confirmPin(companyName)) return;
    if (!mounted) return;
    setState(() => _pinning = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _notify('Konum servisi kapalı.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _notify('Konum izni verilmedi. Müşteri konumu kaydedilemedi.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      await widget.services.api.post(
        '/api/customers/${widget.companyId}/location',
        {'latitude': position.latitude, 'longitude': position.longitude},
      );
      if (!mounted) return;
      setState(() => _detail = _load());
      _notify('Müşteri konumu sabitlendi.');
    } catch (error) {
      _notify(error.toString());
    } finally {
      if (mounted) setState(() => _pinning = false);
    }
  }

  String _locationLabel(Map company) {
    final source = company['location_source']?.toString();
    if (source == 'pinned') return 'Konum sahada sabitlendi';
    if (source == 'geocoded') return 'Konum adresten tahmin edildi';
    return 'Konum kayıtlı değil — yakınlık hatırlatması çalışmaz';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Müşteri kartı')),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _detail,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                snapshot.error.toString(),
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
        final companyName = company['name']?.toString() ?? 'Firma';
        final hasLocation =
            company['latitude'] != null && company['longitude'] != null;
        return ListView(
          padding: const EdgeInsets.all(16),
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
              label: const Text('Müşteriyi düzenle'),
            ),
            const SizedBox(height: 14),
            // Brifinge yalnız Bugün ekranındaki "sıradaki ziyaret" kartından
            // ve onaylanmış ziyaret satırından gidilebiliyordu. Ziyarete
            // giderken insanın açtığı ilk yer müşteri kartı; ziyaret öncesi
            // bağlam buradan ulaşılabilir olmalı.
            FilledButton.icon(
              onPressed: () => context.push('/briefings/${widget.companyId}'),
              icon: const Icon(Icons.assignment_outlined),
              label: const Text('Ziyaret brifingini aç'),
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
                        Expanded(child: Text(_locationLabel(company))),
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
                            ? 'Konumu buradan güncelle'
                            : 'Konumu buraya sabitle',
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
                    const Text(
                      'Müşteri hafıza kartı',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      memory?['summary']?.toString() ??
                          'Onaylı hafıza kartı henüz oluşmadı.',
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
                    'İlgili kişiler (${contacts.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: _mutating ? null : () => _editContact(),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Kişi ekle'),
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
              'Açık görevler (${tasks.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ...tasks.map(
              (item) => ListTile(
                leading: const Icon(Icons.task_alt),
                title: Text((item as Map)['title']?.toString() ?? 'Görev'),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _mutating
                  ? null
                  : () => _archive(companyName, dependencies),
              icon: const Icon(Icons.archive_outlined),
              label: const Text('Müşteriyi arşivle'),
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
                    'Müşteriyi düzenle',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _field(
                    fields['name']!,
                    'Firma adı *',
                    validator: (value) => (value?.trim().length ?? 0) < 2
                        ? 'Firma adı en az 2 karakter olmalı.'
                        : null,
                  ),
                  _field(fields['displayName']!, 'Görünen ad / kısa ad'),
                  _field(fields['address']!, 'Adres'),
                  _field(
                    fields['phone']!,
                    'Telefon',
                    keyboardType: TextInputType.phone,
                  ),
                  _field(
                    fields['email']!,
                    'E-posta',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _field(
                    fields['website']!,
                    'Web sitesi',
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
                        child: const Text('Vazgeç'),
                      ),
                      FilledButton(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(dialogContext, {
                            for (final entry in fields.entries)
                              entry.key: entry.value.text.trim(),
                          });
                        },
                        child: const Text('Kaydet'),
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
                    contact == null
                        ? 'Yeni ilgili kişi'
                        : 'İlgili kişiyi düzenle',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  _field(
                    fields['firstName']!,
                    'Ad *',
                    validator: (value) =>
                        (value?.trim().isEmpty ?? true) ? 'Ad gerekli.' : null,
                  ),
                  _field(fields['lastName']!, 'Soyad'),
                  _field(fields['title']!, 'Görev / Ünvan'),
                  _field(
                    fields['phone']!,
                    'Telefon',
                    keyboardType: TextInputType.phone,
                  ),
                  _field(
                    fields['email']!,
                    'E-posta',
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
                        child: const Text('Vazgeç'),
                      ),
                      FilledButton(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(dialogContext, {
                            for (final entry in fields.entries)
                              entry.key: entry.value.text.trim(),
                          });
                        },
                        child: const Text('Kaydet'),
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
