import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/mobile_services.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key, required this.services});

  final MobileServices services;

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  late Future<List<Map<String, dynamic>>> customers;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    customers = load();
  }

  Future<List<Map<String, dynamic>>> load() async {
    if (!widget.services.config.hasSupabase) return const [];
    await widget.services.refreshContext();
    final result =
        await widget.services.api.get(
              '/api/customers?workspaceId=${widget.services.workspaceId}',
            )
            as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(result['data'] as List? ?? []);
  }

  Future<void> scanCard() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 88,
      maxWidth: 1800,
    );
    if (!mounted || image == null) return;
    try {
      final result =
          await widget.services.api.postFile(
                '/api/contacts/ocr',
                field: 'image',
                filePath: image.path,
              )
              as Map<String, dynamic>;
      final data = Map<String, dynamic>.from(result['data'] as Map);
      await openCustomerForm(
        initial: _CustomerDraft(
          companyName: data['companyName']?.toString() ?? '',
          firstName: data['firstName']?.toString() ?? '',
          lastName: data['lastName']?.toString() ?? '',
          title: data['title']?.toString() ?? '',
          phone: data['phone']?.toString() ?? '',
          email: data['email']?.toString() ?? '',
          website: data['website']?.toString() ?? '',
        ),
        fromOcr: true,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> openCustomerForm({
    _CustomerDraft? initial,
    bool fromOcr = false,
  }) async {
    final draft = await _showCustomerDialog(
      context,
      initial ?? const _CustomerDraft(),
      fromOcr: fromOcr,
    );
    if (draft == null || !mounted) return;
    await saveCustomer(draft);
  }

  Future<void> saveCustomer(_CustomerDraft draft) async {
    if (saving) return;
    setState(() => saving = true);
    try {
      final companyResponse =
          await widget.services.api.post('/api/customers', {
                'workspaceId': widget.services.workspaceId,
                'organizationId': widget.services.organizationId,
                'name': draft.companyName.trim(),
                'phone': draft.phone.trim(),
                'email': draft.email.trim(),
                'website': draft.website.trim(),
                'address': draft.address.trim(),
                'clientMutationId': const Uuid().v4(),
              })
              as Map<String, dynamic>;
      final company = companyResponse['data'] as Map;
      final companyId = company['id'].toString();
      String? contactWarning;
      if (draft.firstName.trim().isNotEmpty) {
        try {
          await widget.services.api.post('/api/contacts', {
            'companyId': companyId,
            'workspaceId': widget.services.workspaceId,
            'organizationId': widget.services.organizationId,
            'firstName': draft.firstName.trim(),
            'lastName': draft.lastName.trim(),
            'title': draft.title.trim(),
            'phone': draft.phone.trim(),
            'email': draft.email.trim(),
          });
        } catch (error) {
          contactWarning =
              'Firma kaydedildi; ilgili kişi kaydedilemedi: $error';
        }
      }
      if (!mounted) return;
      setState(() => customers = load());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(contactWarning ?? 'Müşteri başarıyla kaydedildi.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Müşteriler'),
      actions: [
        IconButton(
          onPressed: saving ? null : () => openCustomerForm(),
          tooltip: 'Manuel müşteri ekle',
          icon: const Icon(Icons.person_add_alt_1_outlined),
        ),
        IconButton(
          onPressed: saving ? null : scanCard,
          tooltip: 'Kartvizit tara',
          icon: const Icon(Icons.document_scanner_outlined),
        ),
      ],
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: customers,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ErrorView(
            message: snapshot.error.toString(),
            retry: () => setState(() => customers = load()),
          );
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.apartment_outlined, size: 54),
                  const SizedBox(height: 12),
                  Text(
                    'Henüz müşteri yok',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Bilgileri elle girebilir veya kartvizit tarayabilirsiniz.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: saving ? null : () => openCustomerForm(),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Manuel müşteri ekle'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: saving ? null : scanCard,
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: const Text('Kartvizit tara'),
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            final next = load();
            setState(() => customers = next);
            await next;
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final item = items[index];
              final name = item['name']?.toString() ?? 'Firma';
              final initials = name.isEmpty
                  ? 'M'
                  : name.substring(0, name.length < 2 ? name.length : 2);
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(initials.toUpperCase())),
                  title: Text(name),
                  subtitle: Text(
                    item['address']?.toString() ?? 'Adres belirtilmedi',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/customers/${item['id']}'),
                ),
              );
            },
          ),
        );
      },
    ),
  );
}

Future<_CustomerDraft?> _showCustomerDialog(
  BuildContext context,
  _CustomerDraft initial, {
  required bool fromOcr,
}) {
  final formKey = GlobalKey<FormState>();
  final companyName = TextEditingController(text: initial.companyName);
  final address = TextEditingController(text: initial.address);
  final firstName = TextEditingController(text: initial.firstName);
  final lastName = TextEditingController(text: initial.lastName);
  final title = TextEditingController(text: initial.title);
  final phone = TextEditingController(text: initial.phone);
  final email = TextEditingController(text: initial.email);
  final website = TextEditingController(text: initial.website);
  return showDialog<_CustomerDraft>(
    context: context,
    builder: (dialogContext) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.viewInsetsOf(dialogContext).bottom,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    fromOcr
                        ? 'Kartvizit alanlarını doğrulayın'
                        : 'Manuel müşteri ekle',
                    style: Theme.of(dialogContext).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: companyName,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Firma adı *'),
                    validator: (value) => (value?.trim().length ?? 0) < 2
                        ? 'Firma adı en az 2 karakter olmalı.'
                        : null,
                  ),
                  TextFormField(
                    controller: address,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Adres'),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'İlgili kişi (isteğe bağlı)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextFormField(
                    controller: firstName,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Ad'),
                  ),
                  TextFormField(
                    controller: lastName,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Soyad'),
                  ),
                  TextFormField(
                    controller: title,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Unvan'),
                  ),
                  TextFormField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Telefon'),
                  ),
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'E-posta'),
                  ),
                  TextFormField(
                    controller: website,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(labelText: 'Web sitesi'),
                  ),
                  if (fromOcr) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'AI çıktısı siz kaydetmeden veritabanına eklenmez.',
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Vazgeç'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(
                            dialogContext,
                            _CustomerDraft(
                              companyName: companyName.text,
                              address: address.text,
                              firstName: firstName.text,
                              lastName: lastName.text,
                              title: title.text,
                              phone: phone.text,
                              email: email.text,
                              website: website.text,
                            ),
                          );
                        },
                        child: const Text('Müşteriyi kaydet'),
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
    companyName.dispose();
    address.dispose();
    firstName.dispose();
    lastName.dispose();
    title.dispose();
    phone.dispose();
    email.dispose();
    website.dispose();
  });
}

class _CustomerDraft {
  const _CustomerDraft({
    this.companyName = '',
    this.address = '',
    this.firstName = '',
    this.lastName = '',
    this.title = '',
    this.phone = '',
    this.email = '',
    this.website = '',
  });

  final String companyName;
  final String address;
  final String firstName;
  final String lastName;
  final String title;
  final String phone;
  final String email;
  final String website;
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.retry});

  final String message;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 40),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          TextButton(onPressed: retry, child: const Text('Tekrar dene')),
        ],
      ),
    ),
  );
}
