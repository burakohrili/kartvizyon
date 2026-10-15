import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/mobile_services.dart';
import 'core/ui_locale_preference.dart';
import 'core/theme.dart';
import 'features/auth/login_screen.dart';
import 'features/customers/customer_detail_screen.dart';
import 'features/customers/customers_screen.dart';
import 'features/home/home_screen.dart';
import 'features/map/map_screen.dart';
import 'features/more/more_screen.dart';
import 'features/more/company_identity_screen.dart';
import 'features/more/premium_screen.dart';
import 'features/more/opportunity_form_screen.dart';
import 'features/more/order_draft_form_screen.dart';
import 'features/more/form_template_screen.dart';
import 'features/more/privacy_screen.dart';
import 'features/more/workspace_module_screen.dart';
import 'features/offline/offline_center_screen.dart';
import 'features/tasks/tasks_screen.dart';
import 'features/visits/debrief_screen.dart';
import 'features/visits/briefing_screen.dart';
import 'features/visits/review_screen.dart';
import 'features/visits/visits_screen.dart';
import 'features/visits/visit_planning_screen.dart';
import 'l10n/app_localizations.dart';

class KartVizyonApp extends StatefulWidget {
  const KartVizyonApp({super.key, this.services, this.localePreferenceStore});
  final MobileServices? services;
  final UiLocalePreferenceStore? localePreferenceStore;

  @override
  State<KartVizyonApp> createState() => _KartVizyonAppState();
}

class _KartVizyonAppState extends State<KartVizyonApp>
    with WidgetsBindingObserver {
  late final MobileServices services;
  late final bool ownsServices;
  late final GoRouter router;
  late bool authenticated;
  late final UiLocalePreferenceStore localePreferenceStore;
  Locale appLocale = const Locale('tr', 'TR');

  @override
  void initState() {
    super.initState();
    ownsServices = widget.services == null;
    localePreferenceStore =
        widget.localePreferenceStore ?? SecureUiLocalePreferenceStore();
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
    unawaited(_restoreLocale());
    authenticated =
        !services.config.hasSupabase ||
        Supabase.instance.client.auth.currentSession != null;
    services.sessionExpired.addListener(_onSessionExpired);
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
              services.sessionExpired.value = false;
              services.clearIdentityContext();
              try {
                // Zorunlu: `MobileServices` çıkış ve girişten sağ çıkıyor.
                // Önbelleğe güvenilirse başka bir kullanıcıyla giren cihaz,
                // öncekinin çalışma alanını taşımaya devam eder.
                await services.refreshContext(force: true);
              } catch (_) {
                // Oturum geçerlidir; geçici ağ/API hatasında çevrimdışı açılışa
                // izin ver ve sonraki eşitlemede bağlamı yeniden yükle.
              }
              services.invalidateScreens();
              router.go(
                services.workspaceCompanyName == null ? '/company-setup' : '/',
              );
              unawaited(services.reminders.sync());
            },
          ),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) => _MobileShell(
            location: state.uri.path,
            services: services,
            navigationShell: navigationShell,
          ),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, __) => HomeScreen(services: services),
                ),
                GoRoute(
                  path: '/map',
                  builder: (_, __) => MapScreen(services: services),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/customers',
                  builder: (_, __) => CustomersScreen(services: services),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/visits',
                  builder: (_, __) => VisitsScreen(services: services),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/tasks',
                  builder: (_, __) => TasksScreen(services: services),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/more',
                  builder: (_, __) => MoreScreen(
                    services: services,
                    locale: appLocale,
                    onLocaleChanged: _setLocale,
                    onSignedOut: () {
                      authenticated = false;
                      router.go('/login');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/visits/plan',
          builder: (_, __) => VisitPlanningScreen(services: services),
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
          path: '/company-setup',
          builder: (_, __) =>
              CompanyIdentityScreen(services: services, onboarding: true),
        ),
        GoRoute(
          path: '/company-info',
          builder: (_, __) => CompanyIdentityScreen(services: services),
        ),
        GoRoute(
          path: '/opportunities/form',
          builder: (_, state) => OpportunityFormScreen(
            services: services,
            opportunity: state.extra as Map<String, dynamic>?,
          ),
        ),
        GoRoute(
          path: '/orders/form',
          builder: (_, state) => OrderDraftFormScreen(
            services: services,
            order: state.extra as Map<String, dynamic>?,
          ),
        ),
        GoRoute(
          path: '/forms/new',
          builder: (_, __) => FormTemplateScreen(services: services),
        ),
        GoRoute(
          path: '/premium',
          builder: (_, __) => PremiumScreen(services: services),
        ),
        GoRoute(
          path: '/privacy',
          builder: (_, state) => PrivacyScreen(
            services: services,
            openDeletion: state.uri.queryParameters['delete'] == 'true',
          ),
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
    WidgetsBinding.instance.addObserver(this);
    services.reminders.pendingRoute.addListener(_onReminderTap);
    if (authenticated) unawaited(_syncReminders());
  }

  Future<void> _syncReminders() async {
    try {
      await services.refreshContext();
      await services.reminders.sync();
    } catch (_) {
      // Notification Center canonical kalır; açılış/resume scheduling hatası
      // uygulamanın kullanılmasını engellemez.
    }
  }

  Future<void> _restoreLocale() async {
    try {
      final languageCode = await localePreferenceStore.read();
      if (!mounted || languageCode == null) return;
      if (languageCode != 'en' && languageCode != 'tr') return;
      setState(() {
        appLocale = Locale(languageCode, languageCode == 'en' ? 'US' : 'TR');
      });
      services.reminders.setLocale(languageCode);
      if (authenticated) unawaited(services.reminders.sync());
    } catch (_) {
      // Tercih okunamazsa Türkçe varsayılanla aç; oturum veya veri akışı etkilenmez.
    }
  }

  Future<void> _setLocale(Locale locale) async {
    if (locale.languageCode != 'en' && locale.languageCode != 'tr') return;
    await localePreferenceStore.write(locale.languageCode);
    if (!mounted) return;
    services.reminders.setLocale(locale.languageCode);
    if (authenticated) unawaited(services.reminders.sync());
    setState(() {
      appLocale = Locale(
        locale.languageCode,
        locale.languageCode == 'en' ? 'US' : 'TR',
      );
    });
  }

  void _onReminderTap() {
    final route = services.reminders.pendingRoute.value;
    if (route == null || !authenticated) return;
    services.reminders.pendingRoute.value = null;
    router.go(route);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && authenticated) {
      unawaited(_syncReminders());
      unawaited(services.fieldMode.onAppResumed());
    }
  }

  /// Kayıtlı oturum ölünce kullanıcıyı giriş ekranına al.
  ///
  /// Supabase oturumu cihazda kalıcıdır. Oturum sunucu tarafında geçersiz
  /// hale gelmişse `currentSession` hâlâ dolu görünür; uygulama kendini
  /// girişli sanıp Bugün ekranını açar ve oradaki her istek 401 döner.
  /// Yönlendiriciyi yalnız açılışta hesaplanan bir bayrağa bağlamak,
  /// kullanıcıyı "Oturum gerekli. (HTTP 401)" ekranında kilitliyordu: giriş
  /// ekranına, dolayısıyla Google ve Apple düğmelerine, hiçbir yol kalmıyordu.
  void _onSessionExpired() {
    if (!services.sessionExpired.value || !authenticated) return;
    authenticated = false;
    services.clearIdentityContext();
    // Ölü oturum cihazda kalırsa uygulama bir sonraki açılışta yine kendini
    // girişli sanır. `local` kapsam sunucuya gitmez; ağ yokken de temizler.
    if (services.config.hasSupabase) {
      Supabase.instance.client.auth
          .signOut(scope: SignOutScope.local)
          .catchError((_) {});
    }
    router.go('/login');
  }

  @override
  void dispose() {
    services.sessionExpired.removeListener(_onSessionExpired);
    WidgetsBinding.instance.removeObserver(this);
    services.reminders.pendingRoute.removeListener(_onReminderTap);
    router.dispose();
    if (ownsServices) services.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'KartVizyon AI',
    debugShowCheckedModeBanner: false,
    locale: appLocale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: KartVizyonTheme.light,
    routerConfig: router,
  );
}

class _MobileShell extends StatefulWidget {
  const _MobileShell({
    required this.location,
    required this.services,
    required this.navigationShell,
  });
  final MobileServices services;
  final String location;
  final StatefulNavigationShell navigationShell;

  @override
  State<_MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<_MobileShell> {
  late int _lastBranch;

  @override
  void initState() {
    super.initState();
    _lastBranch = widget.navigationShell.currentIndex;
  }

  @override
  void didUpdateWidget(covariant _MobileShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentBranch = widget.navigationShell.currentIndex;
    if (_lastBranch == currentBranch) return;
    _lastBranch = currentBranch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.services.activeTab.value = currentBranch;
    });
  }

  @override
  Widget build(BuildContext context) {
    final index = switch (widget.location) {
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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ValueListenableBuilder<Map<String, dynamic>?>(
              valueListenable: widget.services.entitlement,
              builder: (context, data, _) {
                if (data == null) return const SizedBox.shrink();
                final l10n = AppLocalizations.of(context)!;
                final trial = data['trialActive'] == true;
                final readOnly = !widget.services.canWrite;
                if (!trial && !readOnly) return const SizedBox.shrink();
                final end = DateTime.tryParse(
                  data['trialEndsAt']?.toString() ?? '',
                );
                final days = end == null
                    ? 0
                    : (end.difference(DateTime.now()).inSeconds / 86400)
                          .ceil()
                          .clamp(0, 14);
                return MaterialBanner(
                  content: Text(
                    readOnly
                        ? l10n.readOnlyBanner
                        : days <= 1
                        ? l10n.trialBannerLastDay
                        : l10n.trialBannerDays(days),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => context.push('/premium'),
                      child: Text(l10n.subscription),
                    ),
                  ],
                );
              },
            ),
            Expanded(child: widget.navigationShell),
          ],
        ),
      ),
      bottomNavigationBar: _FieldNavigation(
        selectedIndex: index,
        onSelected: (value) => widget.navigationShell.goBranch(value),
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
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
                  label: l10n.todayTab,
                  onTap: onSelected,
                ),
                _NavItem(
                  index: 1,
                  selected: selectedIndex == 1,
                  icon: Icons.apartment_outlined,
                  selectedIcon: Icons.apartment,
                  label: l10n.customersTab,
                  onTap: onSelected,
                ),
                _VisitAction(
                  label: l10n.visitTab,
                  semanticLabel: l10n.newVisit,
                  onTap: () => onSelected(2),
                ),
                _NavItem(
                  index: 3,
                  selected: selectedIndex == 3,
                  icon: Icons.task_alt_outlined,
                  selectedIcon: Icons.task_alt,
                  label: l10n.tasksTab,
                  onTap: onSelected,
                ),
                _NavItem(
                  index: 4,
                  selected: selectedIndex == 4,
                  icon: Icons.grid_view_outlined,
                  selectedIcon: Icons.grid_view_rounded,
                  label: l10n.menuTab,
                  onTap: onSelected,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
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
  const _VisitAction({
    required this.label,
    required this.semanticLabel,
    required this.onTap,
  });
  final String label;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      button: true,
      label: semanticLabel,
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
            Text(
              label,
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
