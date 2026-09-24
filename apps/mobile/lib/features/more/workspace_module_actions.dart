import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../core/mobile_services.dart';

class WorkspaceModuleActions {
  const WorkspaceModuleActions._();

  static Future<bool> planVisit(
    BuildContext context,
    MobileServices services,
  ) async => await context.push<bool>('/visits/plan') ?? false;

  static Future<bool> createOpportunity(
    BuildContext context,
    MobileServices services,
  ) async => await context.push<bool>('/opportunities/form') ?? false;

  static Future<bool> editOpportunity(
    BuildContext context,
    Map<String, dynamic> item,
  ) async =>
      await context.push<bool>('/opportunities/form', extra: item) ?? false;

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
  ) async => await context.push<bool>('/orders/form') ?? false;

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
  ) async => await context.push<bool>('/forms/new') ?? false;

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

  static Future<bool> transitionOrder(
    BuildContext context,
    MobileServices services,
    Map<String, dynamic> item, {
    required bool canApprove,
  }) async {
    final current = item['status']?.toString();
    final choices = switch (current) {
      'draft' => const {'pending_approval': 'Onaya gönder'},
      'pending_approval' when canApprove => const {
        'approved': 'Onayla',
        'rejected': 'Reddet',
      },
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
    if (!context.mounted) return false;
    String? reason;
    if (status == 'rejected') {
      final controller = TextEditingController();
      reason = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Sipariş taslağını reddet'),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              labelText: 'Red nedeni *',
              hintText: 'Örn. Fiyat güncellenmeli',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.length >= 2) Navigator.pop(dialogContext, value);
              },
              child: const Text('Reddet'),
            ),
          ],
        ),
      );
      controller.dispose();
      if (reason == null) return false;
    }
    if (!context.mounted) return false;
    await services.api.post('/api/orders/${item['id']}/transition', {
      'status': status,
      'rejectionReason': reason,
    });
    return true;
  }

  static double _number(String value, {double fallback = 0}) =>
      double.tryParse(value.trim().replaceAll(',', '.')) ?? fallback;
}
