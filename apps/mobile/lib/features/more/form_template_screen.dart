import 'package:flutter/material.dart';

import '../../core/mobile_services.dart';
import '../../l10n/app_localizations.dart';

Map<String, String> _formFieldTypes(AppLocalizations l10n) => {
  'text': l10n.formTemplateText,
  'textarea': l10n.formTemplateLongText,
  'number': l10n.formTemplateNumber,
  'boolean': l10n.formTemplateYesNo,
  'single_select': l10n.formTemplateSingleSelect,
  'multi_select': l10n.formTemplateMultiSelect,
  'date': l10n.formTemplateDate,
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
    final l10n = AppLocalizations.of(context)!;
    final typeLabels = _formFieldTypes(l10n);
    final label = TextEditingController();
    final help = TextEditingController();
    final options = TextEditingController();
    var type = 'text';
    var required = false;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.formTemplateAddFieldTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: label,
                  decoration: InputDecoration(
                    labelText: l10n.formTemplateFieldTitle,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.formTemplateFieldType,
                  ),
                  items: typeLabels.entries
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
                  decoration: InputDecoration(
                    labelText: l10n.formTemplateHelpText,
                  ),
                ),
                if (type == 'single_select' || type == 'multi_select')
                  TextField(
                    controller: options,
                    decoration: InputDecoration(
                      labelText: l10n.formTemplateOptions,
                      hintText: l10n.formTemplateOptionsHint,
                    ),
                    minLines: 3,
                    maxLines: 6,
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.formTemplateRequired),
                  value: required,
                  onChanged: (value) => setDialogState(() => required = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.formTemplateCancel),
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
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(l10n.formTemplateFieldTitleRequired),
                    ),
                  );
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
              child: Text(l10n.formTemplateAdd),
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
    final l10n = AppLocalizations.of(context)!;
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
    } on MobileApiException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.formTemplateSaveFailed)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.formTemplateSaveFailed)));
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final typeLabels = _formFieldTypes(l10n);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.formTemplateTitle)),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            Text(l10n.formTemplateIntro),
            const SizedBox(height: 16),
            TextFormField(
              controller: name,
              maxLength: 160,
              decoration: InputDecoration(
                labelText: l10n.formTemplateName,
                border: OutlineInputBorder(),
              ),
              validator: (value) => (value?.trim().length ?? 0) < 2
                  ? l10n.formTemplateNameRequired
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: description,
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.formTemplateDescription,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.formTemplateFields,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (var index = 0; index < fields.length; index++)
              Card(
                child: ListTile(
                  title: Text(fields[index]['label']),
                  subtitle: Text(
                    '${typeLabels[fields[index]['type']]}${fields[index]['required'] == true ? ' · ${l10n.formTemplateRequired}' : ''}${fields[index]['helpText'] == null ? '' : '\n${fields[index]['helpText']}'}',
                  ),
                  isThreeLine: fields[index]['helpText'] != null,
                  trailing: IconButton(
                    tooltip: l10n.formTemplateRemoveField,
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
              label: Text(l10n.formTemplateAddField),
            ),
            if (attempted && fields.isEmpty)
              Text(
                l10n.formTemplateNeedsField,
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
            child: Text(
              submitting ? l10n.formTemplateCreating : l10n.formTemplateCreate,
            ),
          ),
        ),
      ),
    );
  }
}
