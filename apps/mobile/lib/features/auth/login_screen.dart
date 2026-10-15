import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/mobile_services.dart';
import '../../l10n/app_localizations.dart';

const authCallbackUrl = 'app.kartvizyon.mobile://login-callback';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.services,
    required this.onSignedIn,
  });

  final MobileServices services;
  final Future<void> Function() onSignedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final email = TextEditingController();
  final password = TextEditingController();
  final scrollController = ScrollController();
  final feedbackKey = GlobalKey();
  StreamSubscription<AuthState>? authSubscription;
  bool register = false;
  bool busy = false;
  bool awaitingEmailConfirmation = false;
  bool sessionHandled = false;
  bool appleAuthAvailable = false;
  bool googleAuthAvailable = false;

  /// Tarayıcı açıldı ve henüz bir sonuç dönmedi.
  ///
  /// `signInWithOAuth` yalnız tarayıcının açıldığını söyler, girişin başarılı
  /// olduğunu değil. Kullanıcı tarayıcıda vazgeçip geri döndüğünde ekranda
  /// "giriş ekranı açılıyor…" yazısı asılı kalıyordu.
  bool awaitingOAuth = false;
  Timer? _oauthReturnTimer;
  String? message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.services.config.hasSupabase) {
      unawaited(_loadProviderAvailability());
      authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
        (event) {
          final session = event.session;
          if (session != null) unawaited(_completeSession(session));
        },
        onError: _onAuthError,
      );
    }
  }

  Future<void> _loadProviderAvailability() async {
    try {
      final response = await http.get(
        Uri.parse('${widget.services.config.supabaseUrl}/auth/v1/settings'),
        headers: {'apikey': widget.services.config.supabaseAnonKey},
      );
      if (response.statusCode != 200) return;
      final settings = jsonDecode(response.body) as Map<String, dynamic>;
      final external =
          settings['external'] as Map<String, dynamic>? ?? const {};
      if (!mounted) return;
      setState(() {
        appleAuthAvailable = external['apple'] == true;
        googleAuthAvailable = external['google'] == true;
      });
    } catch (_) {
      // Sağlayıcı durumu doğrulanamazsa bozuk bir düğme göstermek yerine
      // e-posta/parola girişini açık bırakırız.
    }
  }

  /// Tarayıcıdan sonuçsuz dönüldüyse ekranı serbest bırak.
  ///
  /// Geri dönüş anında derin bağlantı hâlâ işleniyor olabilir; oturum birkaç
  /// yüz milisaniye sonra gelir. Bu yüzden hemen değil, kısa bir bekleyişten
  /// sonra ve yalnız hâlâ sonuç yoksa temizlenir.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !awaitingOAuth) return;
    _oauthReturnTimer?.cancel();
    _oauthReturnTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || !awaitingOAuth || sessionHandled) return;
      awaitingOAuth = false;
      setState(() => busy = false);
      _showMessage(AppLocalizations.of(context)!.loginIncomplete);
    });
  }

  /// Giriş bağlantısı geçersizse kullanıcıya söyle; uygulamayı kapatma.
  ///
  /// `supabase_flutter` derin bağlantı hatasını yakalayıp `notifyException`
  /// ile bu akışa **stream hatası** olarak veriyor. `onError` tanımlı
  /// olmadığında bu hata zone'un yakalanmamış hata yoluna düşüyor ve uygulama
  /// çöküyordu — 21 Ağustos 2026'da iki testçide böyle oldu (Sentry
  /// `7618402c` ve `4e9d9c26`, ikisi de `level=fatal`).
  ///
  /// Kapı e-postaya özel değil: Google ve Apple girişi de aynı callback
  /// adresinden döndüğü için tarayıcıda vazgeçmek ya da uygulamanın arka
  /// planda öldürülmesi de buraya düşer.
  void _onAuthError(Object error, StackTrace stackTrace) {
    awaitingOAuth = false;
    if (!mounted) return;
    setState(() => busy = false);
    _showMessage(_authErrorMessage(error));
  }

  String _authErrorMessage(Object error) {
    final l10n = AppLocalizations.of(context)!;
    if (error is! AuthException) {
      return l10n.authFailed;
    }
    return switch (error.code) {
      // Bağlantı tek kullanımlık ve kısa ömürlüdür.
      'otp_expired' || 'access_denied' => l10n.authLinkExpired,
      // PKCE doğrulayıcısı bu cihazda başlatılan istekle eşleşmiyor: bağlantı
      // başka cihazda açılmış, ikinci kez tıklanmış ya da arada yeni bir
      // bağlantı istenmiş olabilir.
      'bad_code_verifier' => l10n.authLinkWrongDevice,
      // Provider/server messages can be English or expose implementation
      // details. Keep the UI language consistent and avoid leaking them.
      _ => l10n.authFailed,
    };
  }

  void _showMessage(String value, {bool confirmation = false}) {
    if (!mounted) return;
    setState(() {
      message = value;
      awaitingEmailConfirmation = confirmation;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final feedbackContext = feedbackKey.currentContext;
      if (feedbackContext != null) {
        Scrollable.ensureVisible(
          feedbackContext,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          alignment: 0.35,
        );
      }
    });
  }

  Future<void> _completeSession(Session session) async {
    if (sessionHandled) return;
    sessionHandled = true;
    await widget.services.sessions.save(
      accessToken: session.accessToken,
      refreshToken: session.refreshToken ?? '',
    );
    if (mounted) await widget.onSignedIn();
  }

  Future<void> submit() async {
    final l10n = AppLocalizations.of(context)!;
    FocusManager.instance.primaryFocus?.unfocus();
    if (!widget.services.config.hasSupabase) {
      await widget.onSignedIn();
      return;
    }

    final normalizedEmail = email.text.trim();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      _showMessage(l10n.emailInvalid);
      return;
    }
    if (password.text.length < 6) {
      _showMessage(l10n.passwordTooShort);
      return;
    }

    setState(() {
      busy = true;
      message = register ? l10n.accountCreating : l10n.signingIn;
      awaitingEmailConfirmation = false;
    });
    try {
      final auth = Supabase.instance.client.auth;
      final response = register
          ? await auth.signUp(
              email: normalizedEmail,
              password: password.text,
              emailRedirectTo: authCallbackUrl,
            )
          : await auth.signInWithPassword(
              email: normalizedEmail,
              password: password.text,
            );
      final session = response.session;
      if (session == null) {
        // Supabase intentionally returns an obfuscated user with no identities
        // when sign-up is repeated for an existing address. Do not claim that
        // another message was sent in that case.
        if (register && (response.user?.identities?.isEmpty ?? false)) {
          _showMessage(l10n.accountMayExist);
          return;
        }
        _showMessage(l10n.confirmAccountEmail, confirmation: true);
        return;
      }
      await _completeSession(session);
    } on AuthException catch (error) {
      _showMessage(_authErrorMessage(error));
    } catch (_) {
      _showMessage(l10n.networkOperationFailed);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resendConfirmation() async {
    final l10n = AppLocalizations.of(context)!;
    final normalizedEmail = email.text.trim();
    if (normalizedEmail.isEmpty || busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => busy = true);
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: normalizedEmail,
        emailRedirectTo: authCallbackUrl,
      );
      _showMessage(l10n.verificationResent, confirmation: true);
    } on AuthException catch (error) {
      _showMessage(_authErrorMessage(error));
    } catch (_) {
      _showMessage(l10n.networkOperationFailed);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resetPassword() async {
    final l10n = AppLocalizations.of(context)!;
    if (!widget.services.config.hasSupabase || email.text.trim().isEmpty) {
      _showMessage(l10n.enterEmailFirst);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => busy = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email.text.trim(),
        redirectTo: authCallbackUrl,
      );
      _showMessage(l10n.passwordResetSent);
    } on AuthException catch (error) {
      _showMessage(_authErrorMessage(error));
    } catch (_) {
      _showMessage(l10n.networkOperationFailed);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> social(OAuthProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    if (!widget.services.config.hasSupabase || busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      busy = true;
      message = provider == OAuthProvider.google
          ? l10n.googleAuthOpening
          : l10n.appleAuthOpening;
      awaitingEmailConfirmation = false;
      awaitingOAuth = true;
    });
    try {
      final opened = await Supabase.instance.client.auth.signInWithOAuth(
        provider,
        redirectTo: authCallbackUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      if (!opened) {
        awaitingOAuth = false;
        _showMessage(l10n.loginScreenCouldNotOpen);
      }
    } on AuthException catch (error) {
      awaitingOAuth = false;
      _showMessage(_authErrorMessage(error));
    } catch (_) {
      awaitingOAuth = false;
      _showMessage(l10n.loginScreenCouldNotOpen);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void toggleRegister() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      register = !register;
      awaitingEmailConfirmation = false;
      message = null;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _oauthReturnTimer?.cancel();
    authSubscription?.cancel();
    email.dispose();
    password.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          'assets/branding/app-icon-1024.png',
                          width: 88,
                          height: 88,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'KartVizyon AI',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(l10n.loginDescription, textAlign: TextAlign.center),
                    const SizedBox(height: 28),
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(
                        labelText: l10n.email,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: password,
                      obscureText: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (!busy) unawaited(submit());
                      },
                      autofillHints: register
                          ? const [AutofillHints.newPassword]
                          : const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (message != null) ...[
                      const SizedBox(height: 12),
                      Semantics(
                        key: feedbackKey,
                        liveRegion: true,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: awaitingEmailConfirmation
                                ? colors.primaryContainer
                                : colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                awaitingEmailConfirmation
                                    ? Icons.mark_email_read_outlined
                                    : busy
                                    ? Icons.hourglass_top_rounded
                                    : Icons.info_outline_rounded,
                                size: 21,
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(message!)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: busy || awaitingEmailConfirmation
                          ? null
                          : submit,
                      child: Text(
                        busy
                            ? l10n.wait
                            : awaitingEmailConfirmation
                            ? l10n.emailSent
                            : register
                            ? l10n.createAccount
                            : l10n.signIn,
                      ),
                    ),
                    if (awaitingEmailConfirmation)
                      TextButton(
                        onPressed: busy ? null : resendConfirmation,
                        child: Text(l10n.resendVerificationEmail),
                      ),
                    TextButton(
                      onPressed: busy ? null : toggleRegister,
                      child: Text(
                        register ? l10n.existingAccount : l10n.createNewAccount,
                      ),
                    ),
                    if (!register)
                      TextButton(
                        onPressed: busy ? null : resetPassword,
                        child: Text(l10n.forgotPassword),
                      ),
                    if (googleAuthAvailable || appleAuthAvailable)
                      const Divider(height: 30),
                    if (googleAuthAvailable)
                      OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () => social(OAuthProvider.google),
                        icon: const Icon(Icons.g_mobiledata),
                        label: Text(l10n.continueWithGoogle),
                      ),
                    if (googleAuthAvailable && appleAuthAvailable)
                      const SizedBox(height: 8),
                    if (appleAuthAvailable)
                      OutlinedButton.icon(
                        onPressed: busy
                            ? null
                            : () => social(OAuthProvider.apple),
                        icon: const Icon(Icons.apple),
                        label: Text(l10n.continueWithApple),
                      ),
                    if (!widget.services.config.hasSupabase) ...[
                      const SizedBox(height: 16),
                      Text(l10n.demoConfiguration, textAlign: TextAlign.center),
                    ],
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
