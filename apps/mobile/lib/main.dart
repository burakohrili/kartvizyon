import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/mobile_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = MobileConfig.fromEnvironment();
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
