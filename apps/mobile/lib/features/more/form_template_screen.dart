import 'package:flutter/material.dart';

import '../../core/mobile_services.dart';

const formFieldTypes = <String, String>{
  'text': 'Kısa metin',
  'textarea': 'Uzun metin',
  'number': 'Sayı',
  'boolean': 'Evet / Hayır',
  'single_select': 'Tek seçim',
  'multi_select': 'Çoklu seçim',
  'date': 'Tarih',
};

class FormTemplateScreen extends StatefulWidget {
  const FormTemplateScreen({super.key, required this.services});
  final MobileServices services;
  @override
  State<FormTemplateScreen> createState() => _FormTemplateScreenState();
}

class _FormTemplateScreenState extends State<FormTemplateScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final description = TextEditingController();
  final fields = <Map<String, dynamic>>[];
  bool submitting = false;
  bool attempted = false;

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  String _keyFor(String label) {
    const replacements = {
      'ı': 'i',
      'İ': 'i',
      'ş': 's',
      'Ş': 's',
      'ğ': 'g',
      'Ğ': 'g',
      'ü': 'u',
      'Ü': 'u',
      'ö': 'o',
      'Ö': 'o',
      'ç': 'c',
      'Ç': 'c',
    };
    var value = label;
    replacements.forEach((from, to) => value = value.replaceAll(from, to));
    value = value
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (value.length < 2) value = 'alan';
    if (RegExp('^[0-9]').hasMatch(value)) value = 'alan_$value';
    return '${value}_${fields.length + 1}';
  }

  Future<void> _addField() async {
    final label = TextEditingController();
    final help = TextEditingController();
    final options = TextEditingController();
    var type = 'text';
    var required = false;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Alan ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: label,
                  decoration: const InputDecoration(labelText: 'Başlık *'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Alan türü'),
                  items: formFieldTypes.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setDialogState(() => type = value!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: help,
                  maxLength: 240,
                  decoration: const InputDecoration(labelText: 'Yardım metni'),
                ),
                if (type == 'single_select' || type == 'multi_select')
                  TextField(
                    controller: options,
                    decoration: const InputDecoration(
                      labelText: 'Seçenekler *',
                      hintText: 'Her satıra bir seçenek',
                    ),
                    minLines: 3,
                    maxLines: 6,
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Zorunlu alan'),
                  value: required,
                  onChanged: (value) => setDialogState(() => required = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                final title = label.text.trim();
                final values = options.text
                    .split('\n')
                    .map((item) => item.trim())
                    .where((item) => item.isNotEmpty)
                    .toList();
                if (title.length < 2 ||
                    ((type == 'single_select' || type == 'multi_select') &&
                        values.isEmpty)) {
                  return;
                }
                Navigator.pop(dialogContext, {
                  'key': _keyFor(title),
                  'label': title,
                  'type': type,
                  'required': required,
                  'helpText': help.text.trim().isEmpty
                      ? null
                      : help.text.trim(),
                  if (values.isNotEmpty) 'options': values,
                });
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );
    label.dispose();
    help.dispose();
    options.dispose();
    if (result != null && mounted) setState(() => fields.add(result));
  }

  Future<void> _submit() async {
    if (submitting) return;
    setState(() => attempted = true);
    if (!(formKey.currentState?.validate() ?? false) || fields.isEmpty) return;
    setState(() => submitting = true);
    try {
      await widget.services.requireWriteAccess();
      await widget.services.api.post('/api/forms', {
        'kind': 'template',
        'data': {
          'workspaceId': widget.services.workspaceId,
          'name': name.text.trim(),
          'description': description.text.trim().isEmpty
              ? null
              : description.text.trim(),
          'fields': fields,
        },
      });
      if (mounted) Navigator.pop(context, true);
    } on MobileApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bağlantı kurulamadı. Formunuz korunuyor.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Yeni saha formu')),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [
          const Text(
            'Mağaza kontrolü, rakip analizi, servis kontrolü veya özel ziyaret kontrol listeleri oluşturun.',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: name,
            maxLength: 160,
            decoration: const InputDecoration(
              labelText: 'Form adı *',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                (value?.trim().length ?? 0) < 2 ? 'Form adını yazın.' : null,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: description,
            maxLength: 500,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Açıklama',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('Alanlar', style: Theme.of(context).textTheme.titleMedium),
          for (var index = 0; index < fields.length; index++)
            Card(
              child: ListTile(
                title: Text(fields[index]['label']),
                subtitle: Text(
                  '${formFieldTypes[fields[index]['type']]}${fields[index]['required'] == true ? ' · Zorunlu' : ''}${fields[index]['helpText'] == null ? '' : '\n${fields[index]['helpText']}'}',
                ),
                isThreeLine: fields[index]['helpText'] != null,
                trailing: IconButton(
                  tooltip: 'Alanı kaldır',
                  onPressed: submitting
                      ? null
                      : () => setState(() => fields.removeAt(index)),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: submitting ? null : _addField,
            icon: const Icon(Icons.add),
            label: const Text('Alan ekle'),
          ),
          if (attempted && fields.isEmpty)
            const Text(
              'En az bir alan ekleyin.',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.all(16),
      child: FilledButton(
        onPressed: submitting || !widget.services.canWrite ? null : _submit,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(submitting ? 'Oluşturuluyor…' : 'Formu oluştur'),
        ),
      ),
    ),
  );
}
