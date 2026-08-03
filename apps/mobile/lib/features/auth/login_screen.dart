import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/mobile_services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.services,
    required this.onSignedIn,
  });
  final MobileServices services;
  final VoidCallback onSignedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool register = false;
  bool busy = false;
  String? message;

  Future<void> submit() async {
    if (!widget.services.config.hasSupabase) {
      widget.onSignedIn();
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final auth = Supabase.instance.client.auth;
      final response = register
          ? await auth.signUp(email: email.text.trim(), password: password.text)
          : await auth.signInWithPassword(
              email: email.text.trim(),
              password: password.text,
            );
      final session = response.session;
      if (session == null) {
        setState(
          () => message = 'E-posta doğrulama bağlantısını kontrol edin.',
        );
        return;
      }
      await widget.services.sessions.save(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken ?? '',
      );
      widget.onSignedIn();
    } on AuthException catch (error) {
      setState(() => message = error.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resetPassword() async {
    if (!widget.services.config.hasSupabase || email.text.trim().isEmpty) {
      return;
    }
    await Supabase.instance.client.auth.resetPasswordForEmail(
      email.text.trim(),
    );
    setState(() => message = 'Şifre yenileme e-postası gönderildi.');
  }

  Future<void> social(OAuthProvider provider) async {
    if (!widget.services.config.hasSupabase) {
      return;
    }
    await Supabase.instance.client.auth.signInWithOAuth(provider);
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CircleAvatar(radius: 30, child: Text('KV')),
                const SizedBox(height: 20),
                Text(
                  'KartVizyon AI',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Saha müşteri hafızanıza güvenli erişim',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: busy ? null : submit,
                  child: Text(
                    busy
                        ? 'Bekleyin…'
                        : register
                        ? 'Hesap oluştur'
                        : 'Giriş yap',
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => register = !register),
                  child: Text(register ? 'Hesabım var' : 'Yeni hesap oluştur'),
                ),
                TextButton(
                  onPressed: resetPassword,
                  child: const Text('Şifremi unuttum'),
                ),
                const Divider(height: 30),
                OutlinedButton.icon(
                  onPressed: () => social(OAuthProvider.google),
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text('Google ile devam et'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => social(OAuthProvider.apple),
                  icon: const Icon(Icons.apple),
                  label: const Text('Apple ile devam et'),
                ),
                if (!widget.services.config.hasSupabase) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Demo yapılandırması etkin. Giriş yap düğmesi yerel önizlemeyi açar.',
                    textAlign: TextAlign.center,
                  ),
                ],
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(message!, textAlign: TextAlign.center),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
