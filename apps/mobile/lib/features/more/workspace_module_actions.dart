import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/mobile_services.dart';
import '../customers/customer_picker.dart';

class WorkspaceModuleActions {
  const WorkspaceModuleActions._();

  static Future<bool> planVisit(
    BuildContext context,
    MobileServices services,
  ) async {
    final purpose = TextEditingController();
    CustomerChoice? customer;
    var start = DateTime.now().add(const Duration(hours: 1));
    try {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Ziyaret planla'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _customerTile(
                    context,
                    services,
                    customer,
                    (value) => setState(() => customer = value),
                  ),
                  TextField(
                    controller: purpose,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Amaç *'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: Text(_dateTimeLabel(start)),
                    subtitle: const Text('Başlangıç; süre 1 saat'),
                    onTap: () async {
                      final picked = await _pickDateTime(context, start);
                      if (picked != null) setState(() => start = picked);
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
                onPressed: customer == null || purpose.text.trim().length < 2
                    ? null
                    : () => Navigator.pop(dialogContext, true),
                child: const Text('Planla'),
              ),
            ],
          ),
        ),
      );
      if (accepted != true || customer == null) return false;
      await services.api.post('/api/calendar', {
        'workspaceId': services.workspaceId,
        'companyId': customer!.id,
        'representativeId': services.ownerId,
        'purpose': purpose.text.trim(),
        'plannedStartAt': start.toUtc().toIso8601String(),
        'plannedEndAt': start
            .add(const Duration(hours: 1))
            .toUtc()
            .toIso8601String(),
      });
      return true;
    } finally {
      purpose.dispose();
    }
  }

  static Future<bool> createOpportunity(
    BuildContext context,
    MobileServices services,
  ) async {
    final title = TextEditingController();
    final value = TextEditingController(text: '0');
    CustomerChoice? customer;
    try {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Yeni fırsat'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _customerTile(
                    context,
                    services,
                    customer,
                    (selected) => setState(() => customer = selected),
                  ),
                  TextField(
                    controller: title,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Fırsat adı *',
                    ),
                  ),
                  TextField(
                    controller: value,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Tahmini değer (TRY)',
                    ),
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
                onPressed: customer == null || title.text.trim().length < 2
                    ? null
                    : () => Navigator.pop(dialogContext, true),
                child: const Text('Oluştur'),
              ),
            ],
          ),
        ),
      );
      if (accepted != true || customer == null) return false;
      await services.api.post('/api/opportunities', {
        'workspaceId': services.workspaceId,
        'companyId': customer!.id,
        'title': title.text.trim(),
        'stage': 'lead',
        'estimatedValue': _number(value.text),
        'currency': 'TRY',
        'probability': 10,
        'expectedCloseDate': null,
        'competitor': null,
        'assignedTo': null,
      });
      return true;
    } finally {
      title.dispose();
      value.dispose();
    }
  }

  static Future<bool> createProduct(
    BuildContext context,
    MobileServices services,
  ) async {
    final sku = TextEditingController();
    final name = TextEditingController();
    final price = TextEditingController(text: '0');
    try {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Yeni ürün'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: sku,
                  decoration: const InputDecoration(labelText: 'Stok kodu *'),
                ),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Ürün adı *'),
                ),
                TextField(
                  controller: price,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Liste fiyatı (TRY) *',
                  ),
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
              onPressed: () => Navigator.pop(
                dialogContext,
                sku.text.trim().isNotEmpty && name.text.trim().length >= 2,
              ),
              child: const Text('Ekle'),
            ),
          ],
        ),
      );
      if (accepted != true) return false;
      await services.api.post('/api/products', {
        'workspaceId': services.workspaceId,
        'sku': sku.text.trim(),
        'name': name.text.trim(),
        'unit': 'adet',
        'taxRate': 20,
        'listPrice': _number(price.text),
        'currency': 'TRY',
      });
      return true;
    } finally {
      sku.dispose();
      name.dispose();
      price.dispose();
    }
  }

  static Future<bool> createOrder(
    BuildContext context,
    MobileServices services,
  ) async {
    final response =
        await services.api.get('/api/products') as Map<String, dynamic>;
    final products = List<Map<String, dynamic>>.from(
      response['data'] as List? ?? const [],
    );
    if (!context.mounted) return false;
    if (products.isEmpty) {
      _message(context, 'Önce ürün kataloğuna en az bir ürün ekleyin.');
      return false;
    }
    CustomerChoice? customer;
    Map<String, dynamic>? product;
    final quantity = TextEditingController(text: '1');
    final discount = TextEditingController(text: '0');
    try {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Yeni sipariş taslağı'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _customerTile(
                    context,
                    services,
                    customer,
                    (selected) => setState(() => customer = selected),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: Text(product?['name']?.toString() ?? 'Ürün seç *'),
                    trailing: const Icon(Icons.search),
                    onTap: () async {
                      final selected = await _pickProduct(context, products);
                      if (selected != null) setState(() => product = selected);
                    },
                  ),
                  TextField(
                    controller: quantity,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Miktar'),
                  ),
                  TextField(
                    controller: discount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'İskonto %'),
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
                onPressed: customer == null || product == null
                    ? null
                    : () => Navigator.pop(dialogContext, true),
                child: const Text('Taslak oluştur'),
              ),
            ],
          ),
        ),
      );
      if (accepted != true || customer == null || product == null) return false;
      await services.api.post('/api/orders', {
        'workspaceId': services.workspaceId,
        'companyId': customer!.id,
        'opportunityId': null,
        'deliveryDate': null,
        'notes': null,
        'currency': product!['currency']?.toString() ?? 'TRY',
        'items': [
          {
            'productId': product!['id'],
            'quantity': _number(quantity.text, fallback: 1),
            'unitPrice': _number(product!['list_price']?.toString() ?? '0'),
            'discountPercent': _number(discount.text),
          },
        ],
      });
      return true;
    } finally {
      quantity.dispose();
      discount.dispose();
    }
  }

  static Future<bool> uploadDocument(
    BuildContext context,
    MobileServices services,
  ) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Belgeyi fotoğraflayın'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Galeriden görsel seçin'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return false;
    final file = await ImagePicker().pickImage(
      source: source,
      imageQuality: 90,
      maxWidth: 2400,
    );
    if (file == null) return false;
    final extension = file.name.toLowerCase();
    final png = extension.endsWith('.png');
    await services.api.postFile(
      '/api/documents',
      field: 'file',
      filePath: file.path,
      fields: const {'purpose': 'general'},
      contentType: png ? MediaType('image', 'png') : MediaType('image', 'jpeg'),
    );
    return true;
  }

  static Future<bool> createFormTemplate(
    BuildContext context,
    MobileServices services,
  ) async {
    final name = TextEditingController();
    final description = TextEditingController();
    final fieldLabel = TextEditingController(text: 'Ziyaret notu');
    try {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Yeni saha formu'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Form adı *'),
                ),
                TextField(
                  controller: description,
                  decoration: const InputDecoration(labelText: 'Açıklama'),
                ),
                TextField(
                  controller: fieldLabel,
                  decoration: const InputDecoration(
                    labelText: 'İlk alan etiketi *',
                  ),
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
              onPressed: () => Navigator.pop(
                dialogContext,
                name.text.trim().length >= 2 &&
                    fieldLabel.text.trim().length >= 2,
              ),
              child: const Text('Oluştur'),
            ),
          ],
        ),
      );
      if (accepted != true) return false;
      await services.api.post('/api/forms', {
        'kind': 'template',
        'data': {
          'workspaceId': services.workspaceId,
          'name': name.text.trim(),
          'description': description.text.trim().isEmpty
              ? null
              : description.text.trim(),
          'fields': [
            {
              'key': 'ziyaret_notu',
              'label': fieldLabel.text.trim(),
              'type': 'textarea',
              'required': true,
            },
          ],
        },
      });
      return true;
    } finally {
      name.dispose();
      description.dispose();
      fieldLabel.dispose();
    }
  }

  static Future<bool> submitForm(
    BuildContext context,
    MobileServices services,
    Map<String, dynamic> template,
  ) async {
    final fields = List<Map<String, dynamic>>.from(
      template['fields'] as List? ?? const [],
    );
    final controllers = <String, TextEditingController>{
      for (final field in fields)
        field['key'].toString(): TextEditingController(),
    };
    final formKey = GlobalKey<FormState>();
    try {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(template['name']?.toString() ?? 'Saha formu'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: fields.map((field) {
                  final key = field['key'].toString();
                  final required = field['required'] == true;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextFormField(
                      controller: controllers[key],
                      maxLines: field['type'] == 'textarea' ? 4 : 1,
                      keyboardType:
                          const {'number', 'money'}.contains(field['type'])
                          ? const TextInputType.numberWithOptions(decimal: true)
                          : TextInputType.text,
                      decoration: InputDecoration(
                        labelText:
                            '${field['label'] ?? key}${required ? ' *' : ''}',
                      ),
                      validator: required
                          ? (value) => (value?.trim().isEmpty ?? true)
                                ? 'Bu alan zorunlu.'
                                : null
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Gönder'),
            ),
          ],
        ),
      );
      if (accepted != true) return false;
      await services.api.post('/api/forms', {
        'kind': 'submission',
        'data': {
          'templateId': template['id'],
          'companyId': null,
          'visitId': null,
          'data': {
            for (final entry in controllers.entries)
              entry.key: entry.value.text.trim(),
          },
        },
      });
      return true;
    } finally {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    }
  }

  static Future<bool> updateOpportunityStage(
    BuildContext context,
    MobileServices services,
    Map<String, dynamic> item,
  ) async {
    const stages = {
      'lead': 'Aday',
      'qualified': 'Nitelikli',
      'proposal': 'Teklif',
      'negotiation': 'Müzakere',
      'won': 'Kazanıldı',
      'lost': 'Kaybedildi',
    };
    final stage = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: stages.entries
              .map(
                (entry) => ListTile(
                  leading: Icon(
                    item['stage']?.toString() == entry.key
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(entry.value),
                  onTap: () => Navigator.pop(sheetContext, entry.key),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (stage == null || stage == item['stage']) return false;
    await services.api.patch('/api/opportunities', {
      'id': item['id'],
      'stage': stage,
      'lossReason': stage == 'lost'
          ? 'Saha kullanıcısı tarafından kapatıldı'
          : null,
    });
    return true;
  }

  static Future<bool> transitionOrder(
    BuildContext context,
    MobileServices services,
    Map<String, dynamic> item,
  ) async {
    final current = item['status']?.toString();
    final choices = switch (current) {
      'draft' => const {'pending_approval': 'Onaya gönder'},
      'pending_approval' => const {'approved': 'Onayla', 'rejected': 'Reddet'},
      _ => const <String, String>{},
    };
    if (choices.isEmpty) return false;
    final status = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: choices.entries
              .map(
                (entry) => ListTile(
                  title: Text(entry.value),
                  onTap: () => Navigator.pop(sheetContext, entry.key),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (status == null) return false;
    await services.api.post('/api/orders/${item['id']}/transition', {
      'status': status,
      'rejectionReason': status == 'rejected'
          ? 'Mobil uygulamadan reddedildi'
          : null,
    });
    return true;
  }

  static Widget _customerTile(
    BuildContext context,
    MobileServices services,
    CustomerChoice? customer,
    ValueChanged<CustomerChoice> selected,
  ) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: const Icon(Icons.apartment_outlined),
    title: Text(customer?.name ?? 'Müşteri seç *'),
    subtitle: customer?.legalName == null ? null : Text(customer!.legalName!),
    trailing: const Icon(Icons.search),
    onTap: () async {
      final result = await showCustomerPicker(context, services: services);
      if (result != null) selected(result);
    },
  );

  static Future<DateTime?> _pickDateTime(
    BuildContext context,
    DateTime initial,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 1095)),
    );
    if (date == null || !context.mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  static Future<Map<String, dynamic>?> _pickProduct(
    BuildContext context,
    List<Map<String, dynamic>> products,
  ) => showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .65,
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: products.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, index) {
            final product = products[index];
            return ListTile(
              title: Text(product['name']?.toString() ?? 'Ürün'),
              subtitle: Text(
                '${product['sku'] ?? ''} · ${product['list_price'] ?? 0} ${product['currency'] ?? 'TRY'}',
              ),
              onTap: () => Navigator.pop(sheetContext, product),
            );
          },
        ),
      ),
    ),
  );

  static String _dateTimeLabel(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year} '
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  static double _number(String value, {double fallback = 0}) =>
      double.tryParse(value.trim().replaceAll(',', '.')) ?? fallback;

  static void _message(BuildContext context, String message) =>
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
}
