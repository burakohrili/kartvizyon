import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/mobile_services.dart';

class CompanyIdentityScreen extends StatefulWidget {
  const CompanyIdentityScreen({
    super.key,
    required this.services,
    this.onboarding = false,
  });

  final MobileServices services;
  final bool onboarding;

  @override
  State<CompanyIdentityScreen> createState() => _CompanyIdentityScreenState();
}

class _CompanyIdentityScreenState extends State<CompanyIdentityScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController company;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    name = TextEditingController(text: widget.services.displayName ?? '');
    company = TextEditingController(
      text: widget.services.workspaceCompanyName ?? '',
    );
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate() || saving) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await widget.services.api.patch('/api/settings/company', {
        if (name.text.trim().isNotEmpty) 'displayName': name.text.trim(),
        'companyName': company.text.trim(),
      });
      widget.services.workspaceCompanyName = company.text.trim();
      if (name.text.trim().isNotEmpty) {
        widget.services.displayName = name.text.trim();
      }
      try {
        await widget.services.refreshContext(force: true);
      } catch (_) {
        // Kayıt sunucuda başarılıdır; geçici yenileme hatası bunu geri almaz.
      }
      if (!mounted) return;
      if (widget.onboarding) {
        context.go('/');
      } else {
        context.pop(true);
      }
    } catch (failure) {
      if (mounted) {
        setState(
          () => error = failure is MobileApiException
              ? failure.message
              : 'Firma bilgileri kaydedilemedi. Tekrar deneyin.',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    name.dispose();
    company.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.onboarding ? 'Başlamadan önce' : 'Firma bilgileri'),
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Sizi ve temsil ettiğiniz firmayı tanıyalım.'),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: name,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        (widget.onboarding ||
                                (value?.trim().isNotEmpty ?? false)) &&
                            (value?.trim().length ?? 0) < 2
                        ? 'Ad Soyad en az 2 karakter olmalı.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: company,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => save(),
                    decoration: const InputDecoration(
                      labelText: 'Firma adı',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => (value?.trim().length ?? 0) < 2
                        ? 'Firma adı en az 2 karakter olmalı.'
                        : null,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (!widget.services.canWrite)
                    const Text(
                      'Salt okunur erişimde firma adı değiştirilemez.',
                    ),
                  FilledButton(
                    onPressed: saving || !widget.services.canWrite
                        ? null
                        : save,
                    child: Text(saving ? 'Kaydediliyor…' : 'Kaydet'),
                  ),
                  if (widget.onboarding)
                    TextButton(
                      onPressed: saving ? null : () => context.go('/'),
                      child: const Text('Şimdilik geç'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
