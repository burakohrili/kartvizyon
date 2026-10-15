import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/mobile_services.dart';
import '../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
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
    } catch (_) {
      if (mounted) {
        setState(() => error = l10n.companyIdentitySaveFailed);
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.onboarding
              ? l10n.companyIdentityOnboardingTitle
              : l10n.companyIdentityTitle,
        ),
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
                    Text(l10n.companyIdentityIntro),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: name,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.companyIdentityName,
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          (widget.onboarding ||
                                  (value?.trim().isNotEmpty ?? false)) &&
                              (value?.trim().length ?? 0) < 2
                          ? l10n.companyIdentityNameTooShort
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: company,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => save(),
                      decoration: InputDecoration(
                        labelText: l10n.companyIdentityCompany,
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value?.trim().length ?? 0) < 2
                          ? l10n.companyIdentityCompanyTooShort
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
                      Text(l10n.companyIdentityReadOnly),
                    FilledButton(
                      onPressed: saving || !widget.services.canWrite
                          ? null
                          : save,
                      child: Text(
                        saving
                            ? l10n.companyIdentitySaving
                            : l10n.companyIdentitySave,
                      ),
                    ),
                    if (widget.onboarding)
                      TextButton(
                        onPressed: saving ? null : () => context.go('/'),
                        child: Text(l10n.companyIdentitySkip),
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
}
