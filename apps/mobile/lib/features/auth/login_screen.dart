import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/mobile_services.dart';

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
      authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
        (event) {
          final session = event.session;
          if (session != null) unawaited(_completeSession(session));
        },
        onError: _onAuthError,
      );
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
      _showMessage('Giriş tamamlanmadı. Dilerseniz tekrar deneyin.');
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
    if (error is! AuthException) {
      return 'Giriş tamamlanamadı. Lütfen tekrar deneyin.';
    }
    return switch (error.code) {
      // Bağlantı tek kullanımlık ve kısa ömürlüdür.
      'otp_expired' || 'access_denied' =>
        'Bağlantının süresi dolmuş veya daha önce kullanılmış. Aşağıdan yeni '
            'bir bağlantı isteyin.',
      // PKCE doğrulayıcısı bu cihazda başlatılan istekle eşleşmiyor: bağlantı
      // başka cihazda açılmış, ikinci kez tıklanmış ya da arada yeni bir
      // bağlantı istenmiş olabilir.
      'bad_code_verifier' =>
        'Bu bağlantı başka bir cihazda veya daha önce kullanılmış. Girişi bu '
            'cihazdan yeniden başlatın.',
      _ => error.message,
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
    FocusManager.instance.primaryFocus?.unfocus();
    if (!widget.services.config.hasSupabase) {
      await widget.onSignedIn();
      return;
    }

    final normalizedEmail = email.text.trim();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      _showMessage('Geçerli bir e-posta adresi girin.');
      return;
    }
    if (password.text.length < 6) {
      _showMessage('Şifreniz en az 6 karakter olmalıdır.');
      return;
    }

    setState(() {
      busy = true;
      message = register ? 'Hesabınız oluşturuluyor…' : 'Giriş yapılıyor…';
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
          _showMessage(
            'Bu e-posta zaten kayıtlı olabilir. “Hesabım var” ile giriş yapın veya şifrenizi yenileyin.',
          );
          return;
        }
        _showMessage(
          'Hesabınız oluşturuldu. E-postanıza gönderdiğimiz bağlantıya dokunun; doğrulama tamamlanınca uygulama otomatik açılır.',
          confirmation: true,
        );
        return;
      }
      await _completeSession(session);
    } on AuthException catch (error) {
      _showMessage(error.message);
    } catch (_) {
      _showMessage(
        'İşlem tamamlanamadı. Bağlantınızı kontrol edip tekrar deneyin.',
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resendConfirmation() async {
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
      _showMessage(
        'Yeni doğrulama e-postası gönderildi. En son gelen e-postadaki bağlantıyı kullanın.',
        confirmation: true,
      );
    } on AuthException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resetPassword() async {
    if (!widget.services.config.hasSupabase || email.text.trim().isEmpty) {
      _showMessage('Önce e-posta adresinizi girin.');
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    await Supabase.instance.client.auth.resetPasswordForEmail(
      email.text.trim(),
      redirectTo: authCallbackUrl,
    );
    _showMessage('Şifre yenileme e-postası gönderildi.');
  }

  Future<void> social(OAuthProvider provider) async {
    if (!widget.services.config.hasSupabase || busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      busy = true;
      message = provider == OAuthProvider.google
          ? 'Google güvenli giriş ekranı açılıyor…'
          : 'Apple güvenli giriş ekranı açılıyor…';
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
        _showMessage('Giriş ekranı açılamadı. Lütfen tekrar deneyin.');
      }
    } on AuthException catch (error) {
      awaitingOAuth = false;
      _showMessage(error.message);
    } catch (_) {
      awaitingOAuth = false;
      _showMessage('Giriş ekranı açılamadı. Lütfen tekrar deneyin.');
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
                    const Text(
                      'Saha müşteri hafızanıza güvenli erişim',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
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
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        if (!busy) unawaited(submit());
                      },
                      autofillHints: register
                          ? const [AutofillHints.newPassword]
                          : const [AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: 'Şifre',
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
                            ? 'Bekleyin…'
                            : awaitingEmailConfirmation
                            ? 'E-posta gönderildi'
                            : register
                            ? 'Hesap oluştur'
                            : 'Giriş yap',
                      ),
                    ),
                    if (awaitingEmailConfirmation)
                      TextButton(
                        onPressed: busy ? null : resendConfirmation,
                        child: const Text(
                          'Doğrulama e-postasını yeniden gönder',
                        ),
                      ),
                    TextButton(
                      onPressed: busy ? null : toggleRegister,
                      child: Text(
                        register ? 'Hesabım var' : 'Yeni hesap oluştur',
                      ),
                    ),
                    if (!register)
                      TextButton(
                        onPressed: busy ? null : resetPassword,
                        child: const Text('Şifremi unuttum'),
                      ),
                    const Divider(height: 30),
                    OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () => social(OAuthProvider.google),
                      icon: const Icon(Icons.g_mobiledata),
                      label: const Text('Google ile devam et'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () => social(OAuthProvider.apple),
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
