import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/mobile_services.dart';
import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/customers/customer_detail_screen.dart';
import 'features/customers/customers_screen.dart';
import 'features/home/home_screen.dart';
import 'features/map/map_screen.dart';
import 'features/more/more_screen.dart';
import 'features/more/privacy_screen.dart';
import 'features/offline/offline_center_screen.dart';
import 'features/tasks/tasks_screen.dart';
import 'features/visits/debrief_screen.dart';
import 'features/visits/visits_screen.dart';
import 'l10n/app_localizations.dart';

class KartVizyonApp extends StatefulWidget {
  const KartVizyonApp({super.key, this.services});
  final MobileServices? services;

  @override
  State<KartVizyonApp> createState() => _KartVizyonAppState();
}

class _KartVizyonAppState extends State<KartVizyonApp> {
  late final MobileServices services;
  late final bool ownsServices;
  late final GoRouter router;
  late bool authenticated;

  @override
  void initState() {
    super.initState();
    ownsServices = widget.services == null;
    services =
        widget.services ??
        MobileServices.create(
          const MobileConfig(
            apiBaseUrl: 'http://10.0.2.2:3000',
            supabaseUrl: '',
            supabaseAnonKey: '',
          ),
        );
    authenticated =
        !services.config.hasSupabase ||
        Supabase.instance.client.auth.currentSession != null;
    router = GoRouter(
      initialLocation: authenticated ? '/' : '/login',
      redirect: (_, state) {
        final onLogin = state.matchedLocation == '/login';
        if (!authenticated && !onLogin) return '/login';
        if (authenticated && onLogin) return '/';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (_, __) => LoginScreen(
            services: services,
            onSignedIn: () async {
              authenticated = true;
              await services.refreshContext();
              router.go('/');
            },
          ),
        ),
        ShellRoute(
          builder: (context, state, child) =>
              _MobileShell(location: state.uri.path, child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => HomeScreen(services: services),
            ),
            GoRoute(
              path: '/customers',
              builder: (_, __) => CustomersScreen(services: services),
            ),
            GoRoute(
              path: '/map',
              builder: (_, __) => MapScreen(services: services),
            ),
            GoRoute(
              path: '/tasks',
              builder: (_, __) => TasksScreen(services: services),
            ),
            GoRoute(
              path: '/more',
              builder: (_, __) => MoreScreen(
                services: services,
                onSignedOut: () {
                  authenticated = false;
                  router.go('/login');
                },
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/visits',
          builder: (_, __) => VisitsScreen(services: services),
        ),
        GoRoute(
          path: '/visits/:id/debrief',
          builder: (_, state) => DebriefScreen(
            services: services,
            visitId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/customers/:id',
          builder: (_, state) => CustomerDetailScreen(
            services: services,
            companyId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/offline',
          builder: (_, __) => OfflineCenterScreen(services: services),
        ),
        GoRoute(
          path: '/privacy',
          builder: (_, __) => PrivacyScreen(services: services),
        ),
      ],
    );
    if (authenticated) services.refreshContext().catchError((_) {});
  }

  @override
  void dispose() {
    router.dispose();
    if (ownsServices) services.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'KartVizyon AI',
    debugShowCheckedModeBanner: false,
    locale: const Locale('tr', 'TR'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: KartVizyonTheme.light,
    routerConfig: router,
  );
}

class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const paths = ['/', '/customers', '/map', '/tasks', '/more'];
    final index = paths.indexOf(location).clamp(0, paths.length - 1);
    return Scaffold(
      body: SafeArea(child: child),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Hızlı ziyaret kaydı',
        onPressed: () => context.push('/visits'),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => context.go(paths[value]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Bugün',
          ),
          NavigationDestination(
            icon: Icon(Icons.apartment_outlined),
            selectedIcon: Icon(Icons.apartment),
            label: 'Müşteriler',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Harita',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt),
            label: 'Takipler',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            label: 'Daha fazla',
          ),
        ],
      ),
    );
  }
}
