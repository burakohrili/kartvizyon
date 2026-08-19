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
import 'features/more/workspace_module_screen.dart';
import 'features/offline/offline_center_screen.dart';
import 'features/tasks/tasks_screen.dart';
import 'features/visits/debrief_screen.dart';
import 'features/visits/briefing_screen.dart';
import 'features/visits/review_screen.dart';
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
            sentryDsn: '',
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
              try {
                await services.refreshContext();
              } catch (_) {
                // Oturum geçerlidir; geçici ağ/API hatasında çevrimdışı açılışa
                // izin ver ve sonraki eşitlemede bağlamı yeniden yükle.
              }
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
              path: '/visits',
              builder: (_, __) => VisitsScreen(services: services),
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
          path: '/visits/:id/debrief',
          builder: (_, state) => DebriefScreen(
            services: services,
            visitId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/visits/:id/review',
          builder: (_, state) => VisitReviewScreen(
            services: services,
            visitId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: '/briefings/:companyId',
          builder: (_, state) => BriefingScreen(
            services: services,
            companyId: state.pathParameters['companyId']!,
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
        ...[
          ('/calendar', WorkspaceModule.calendar),
          ('/activity', WorkspaceModule.activity),
          ('/reports', WorkspaceModule.reports),
          ('/notifications', WorkspaceModule.notifications),
          ('/opportunities', WorkspaceModule.opportunities),
          ('/products', WorkspaceModule.products),
          ('/orders', WorkspaceModule.orders),
          ('/documents', WorkspaceModule.documents),
          ('/forms', WorkspaceModule.forms),
        ].map(
          (entry) => GoRoute(
            path: entry.$1,
            builder: (_, __) =>
                WorkspaceModuleScreen(services: services, module: entry.$2),
          ),
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
    const paths = ['/', '/customers', '/visits', '/tasks', '/more'];
    final index = switch (location) {
      '/' => 0,
      String value when value.startsWith('/customers') => 1,
      String value when value.startsWith('/visits') => 2,
      String value when value.startsWith('/tasks') => 3,
      '/more' => 4,
      // Harita kabuğun içinde ama alt çubukta sekmesi yok. Varsayılana
      // düşürülünce "Daha fazla" seçili görünüyor ve kullanıcı nerede olduğunu
      // yanlış okuyordu; hiçbir sekme seçili olmamalı.
      _ => -1,
    };
    return Scaffold(
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: _FieldNavigation(
        selectedIndex: index,
        onSelected: (value) =>
            value == 2 ? context.push('/visits') : context.go(paths[value]),
      ),
    );
  }
}

class _FieldNavigation extends StatelessWidget {
  const _FieldNavigation({
    required this.selectedIndex,
    required this.onSelected,
  });
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    minimum: const EdgeInsets.fromLTRB(12, 4, 12, 10),
    child: Material(
      color: KartVizyonTheme.navy,
      elevation: 12,
      shadowColor: KartVizyonTheme.navy.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      // Alt çubuk sabit yükseklikli bir kapsül. Sistem yazı tipi ölçeği 2x
      // yapıldığında etiketler bu yüksekliği taşırıyordu; Material'ın önerdiği
      // yaklaşım kompakt navigasyonda ölçeği sınırlamaktır. Uygulamanın geri
      // kalanı tam erişilebilirlik ölçeğini uygulamaya devam eder.
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              _NavItem(
                index: 0,
                selected: selectedIndex == 0,
                icon: Icons.today_outlined,
                selectedIcon: Icons.today,
                label: 'Bugün',
                onTap: onSelected,
              ),
              _NavItem(
                index: 1,
                selected: selectedIndex == 1,
                icon: Icons.apartment_outlined,
                selectedIcon: Icons.apartment,
                label: 'Müşteriler',
                onTap: onSelected,
              ),
              _VisitAction(onTap: () => onSelected(2)),
              _NavItem(
                index: 3,
                selected: selectedIndex == 3,
                icon: Icons.task_alt_outlined,
                selectedIcon: Icons.task_alt,
                label: 'Görevler',
                onTap: onSelected,
              ),
              _NavItem(
                index: 4,
                selected: selectedIndex == 4,
                icon: Icons.grid_view_outlined,
                selectedIcon: Icons.grid_view_rounded,
                label: 'Menü',
                onTap: onSelected,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.index,
    required this.selected,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.onTap,
  });
  final int index;
  final bool selected;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      selected: selected,
      button: true,
      label: label,
      child: InkWell(
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? selectedIcon : icon,
              color: selected ? KartVizyonTheme.lime : Colors.white70,
              size: 23,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : Colors.white70,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _VisitAction extends StatelessWidget {
  const _VisitAction({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      button: true,
      label: 'Yeni ziyaret',
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: KartVizyonTheme.lime,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: KartVizyonTheme.navy,
                size: 28,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Ziyaret',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
