import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/mobile_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = MobileConfig.fromEnvironment();

  if (config.sentryDsn.isNotEmpty) {
    await SentryFlutter.init((options) {
      options.dsn = config.sentryDsn;
      options.environment = const String.fromEnvironment(
        'APP_ENVIRONMENT',
        defaultValue: 'production',
      );
      options.sendDefaultPii = false;
      options.tracesSampleRate = 0.1;
      options.attachScreenshot = false;
    }, appRunner: () => _bootstrap(config));
    return;
  }

  await _bootstrap(config);
}

Future<void> _bootstrap(MobileConfig config) async {
  if (config.hasSupabase) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabaseAnonKey,
    );
  }
  final services = MobileServices.create(config);
  if (config.hasSupabase) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      await services.sessions.save(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken ?? '',
      );
    }
  }
  runApp(KartVizyonApp(services: services));
}
