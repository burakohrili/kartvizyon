import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/mobile_services.dart';
import '../../core/refresh.dart';
import '../../l10n/app_localizations.dart';
import '../customers/customer_identity.dart';
import 'workspace_module_actions.dart';

enum WorkspaceModule {
  calendar,
  activity,
  reports,
  notifications,
  opportunities,
  products,
  orders,
  documents,
  forms,
}

/// Adlandırılmış, çünkü boş durum metinleri testten de okunuyor.
extension WorkspaceModuleCopy on WorkspaceModule {
  String localizedTitle(AppLocalizations l10n) => switch (this) {
    WorkspaceModule.calendar => l10n.calendar,
    WorkspaceModule.activity => l10n.activity,
    WorkspaceModule.reports => l10n.reportsSummary,
    WorkspaceModule.notifications => l10n.notifications,
    WorkspaceModule.opportunities => l10n.opportunities,
    WorkspaceModule.products => l10n.productsPrices,
    WorkspaceModule.orders => l10n.orderDrafts,
    WorkspaceModule.documents => l10n.documents,
    WorkspaceModule.forms => l10n.fieldForms,
  };

  IconData get emptyIcon => switch (this) {
    WorkspaceModule.calendar => Icons.calendar_month_outlined,
    WorkspaceModule.activity => Icons.history_toggle_off_outlined,
    WorkspaceModule.reports => Icons.analytics_outlined,
    WorkspaceModule.notifications => Icons.notifications_none,
    WorkspaceModule.opportunities => Icons.trending_up,
    WorkspaceModule.products => Icons.inventory_2_outlined,
    WorkspaceModule.orders => Icons.receipt_long_outlined,
    WorkspaceModule.documents => Icons.description_outlined,
    WorkspaceModule.forms => Icons.dynamic_form_outlined,
  };

  String localizedEmptyTitle(AppLocalizations l10n) => switch (this) {
    WorkspaceModule.calendar => l10n.moduleNoPlannedVisits,
    WorkspaceModule.activity => l10n.moduleNoApprovedVisits,
    WorkspaceModule.reports => l10n.moduleNoReportData,
    WorkspaceModule.notifications => l10n.moduleNoNotifications,
    WorkspaceModule.opportunities => l10n.moduleNoOpportunities,
    WorkspaceModule.products => l10n.moduleNoProducts,
    WorkspaceModule.orders => l10n.moduleNoOrderDrafts,
    WorkspaceModule.documents => l10n.moduleNoDocuments,
    WorkspaceModule.forms => l10n.moduleNoActiveForms,
  };

  /// Ekranın ne olduğunu ve mobilde ilk kaydın nasıl oluştuğunu anlatır.
  String localizedEmptyBody(AppLocalizations l10n) => switch (this) {
    WorkspaceModule.calendar => l10n.moduleCalendarEmptyHint,
    WorkspaceModule.activity => l10n.moduleActivityEmptyHint,
    WorkspaceModule.reports => l10n.moduleReportsEmptyHint,
    WorkspaceModule.notifications => l10n.moduleNotificationsEmptyHint,
    WorkspaceModule.opportunities => l10n.moduleOpportunitiesEmptyHint,
    WorkspaceModule.products => l10n.moduleProductsEmptyHint,
    WorkspaceModule.orders => l10n.moduleOrdersEmptyHint,
    WorkspaceModule.documents => l10n.moduleDocumentsEmptyHint,
    WorkspaceModule.forms => l10n.moduleFormsEmptyHint,
  };

  String get path => switch (this) {
    WorkspaceModule.calendar => '/api/calendar',
    WorkspaceModule.activity => '/api/activity',
    WorkspaceModule.reports => '/api/visits',
    WorkspaceModule.notifications => '/api/notifications',
    WorkspaceModule.opportunities => '/api/opportunities',
    WorkspaceModule.products => '/api/products',
    WorkspaceModule.orders => '/api/orders',
    WorkspaceModule.documents => '/api/documents',
    WorkspaceModule.forms => '/api/forms',
  };
}

class WorkspaceModuleScreen extends StatefulWidget {
  const WorkspaceModuleScreen({
    super.key,
    required this.services,
    required this.module,
  });

  final MobileServices services;
  final WorkspaceModule module;

  @override
  State<WorkspaceModuleScreen> createState() => _WorkspaceModuleScreenState();
}

class _WorkspaceModuleScreenState extends State<WorkspaceModuleScreen> {
  late Future<List<_ModuleItem>> items;
  bool actionBusy = false;
  String opportunityFilter = 'open';
  String orderFilter = 'open';
  bool canApproveOrders = false;
  String activityFilter = 'all';

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    items = load();
  }

  Future<List<_ModuleItem>> load() async {
    await widget.services.refreshContext();
    if (widget.module == WorkspaceModule.reports) {
      final responses = await Future.wait([
        widget.services.api.get(
          '/api/customers?workspaceId=${widget.services.workspaceId}',
        ),
        widget.services.api.get(
          '/api/visits?workspaceId=${widget.services.workspaceId}',
        ),
        widget.services.api.get(
          '/api/tasks?workspaceId=${widget.services.workspaceId}',
        ),
      ]);
      final customerResponse = responses[0] as Map;
      final customers = _list(customerResponse['data']);
      final customerTotal =
          (customerResponse['page'] as Map?)?['total'] as int? ??
          customers.length;
      final visits = _list((responses[1] as Map)['data']);
      final tasks = _list((responses[2] as Map)['data']);
      final approved = visits
          .where((item) => item['status']?.toString() == 'approved')
          .length;
      final review = visits
          .where((item) => item['status']?.toString() == 'needs_review')
          .length;
      final openTasks = tasks
          .where((item) => item['status']?.toString() == 'open')
          .length;
      return [
        _ModuleItem(
          title: '$customerTotal',
          subtitle: l10n.moduleActiveCustomer,
          icon: Icons.apartment_outlined,
          raw: const {'route': '/customers'},
        ),
        _ModuleItem(
          title: '$approved',
          subtitle: l10n.moduleApprovedVisit,
          icon: Icons.verified_outlined,
          raw: const {'route': '/visits'},
        ),
        _ModuleItem(
          title: '$review',
          subtitle: l10n.moduleReviewVisit,
          icon: Icons.rate_review_outlined,
          raw: const {'route': '/visits'},
        ),
        _ModuleItem(
          title: '$openTasks',
          subtitle: l10n.moduleOpenTask,
          icon: Icons.task_alt_outlined,
          raw: const {'route': '/tasks'},
        ),
      ];
    }
    final path = widget.module.path;
    final response =
        await widget.services.api.get(path) as Map<String, dynamic>;
    if (widget.module == WorkspaceModule.orders) {
      canApproveOrders = response['canApprove'] == true;
    }

    // Fiyat listesi ayrı bir ekran değil, ürün kataloğunun devamı. Sahada
    // salt okunurdur; yükleme web çalışma alanında yapılır (ADR-0007).
    final priceLists = <_ModuleItem>[];
    if (widget.module == WorkspaceModule.products) {
      try {
        final documents =
            await widget.services.api.get('/api/documents?purpose=price_list')
                as Map<String, dynamic>;
        priceLists.addAll(
          _list(documents['data']).map(
            (item) => _ModuleItem(
              title:
                  item['file_name']?.toString() ?? l10n.modulePriceListFallback,
              subtitle: item['scan_status']?.toString() == 'clean'
                  ? _parts([
                      _date(item['created_at'], l10n.localeName),
                      l10n.moduleOpenDocument,
                    ])
                  : l10n.moduleScanPending,
              icon: Icons.picture_as_pdf_outlined,
              raw: {...item, '_kind': 'price_list'},
            ),
          ),
        );
      } catch (_) {
        // Fiyat listesi getirilemezse ürün kataloğu yine de gösterilir;
        // katalog asıl içeriktir.
      }
    }
    return switch (widget.module) {
      WorkspaceModule.calendar => [
        ..._list(response['visits']).map(
          (item) => _ModuleItem(
            title:
                _company(item, l10n) ??
                item['purpose']?.toString() ??
                l10n.moduleVisit,
            subtitle: _parts([
              item['purpose'],
              _date(item['planned_start_at'], l10n.localeName),
            ]),
            icon: Icons.event_outlined,
            raw: {...item, '_kind': 'visit'},
          ),
        ),
        ..._list(response['tasks']).map(
          (item) => _ModuleItem(
            title: item['title']?.toString() ?? l10n.moduleTask,
            subtitle: _parts([
              _company(item, l10n),
              _date(item['due_at'], l10n.localeName),
            ]),
            icon: Icons.task_alt_outlined,
            raw: {...item, '_kind': 'task'},
          ),
        ),
      ],
      WorkspaceModule.activity =>
        _list(response['data'])
            .map(
              (item) => _ModuleItem(
                title: item['title']?.toString() ?? l10n.moduleActivity,
                subtitle: _parts([
                  item['detail'],
                  _date(item['occurredAt'], l10n.localeName),
                ]),
                icon: _activityIcon(item['kind']),
                raw: item,
              ),
            )
            .toList(),
      WorkspaceModule.reports => const [],
      WorkspaceModule.notifications =>
        _list(response['data'])
            .map(
              (item) => _ModuleItem(
                title:
                    item['title']?.toString() ??
                    item['kind']?.toString() ??
                    l10n.moduleNotification,
                subtitle: _parts([
                  item['body']?.toString() ?? item['message']?.toString(),
                  _notificationTime(item['created_at'], l10n),
                ]),
                icon: item['read_at'] == null
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_none,
                raw: item,
              ),
            )
            .toList(),
      WorkspaceModule.opportunities =>
        _list(response['data'])
            .map(
              (item) => _ModuleItem(
                title: item['title']?.toString() ?? l10n.moduleOpportunity,
                subtitle: _parts([
                  _company(item, l10n),
                  _stage(item['stage'], l10n),
                  _money(
                    item['estimated_value'],
                    item['currency'],
                    l10n.localeName,
                  ),
                ]),
                icon: Icons.trending_up,
                raw: item,
              ),
            )
            .toList(),
      WorkspaceModule.products => [
        ...priceLists,
        ..._list(response['data']).map(
          (item) => _ModuleItem(
            title: item['name']?.toString() ?? l10n.moduleProduct,
            subtitle: _parts([
              item['sku'],
              _money(item['list_price'], item['currency'], l10n.localeName),
            ]),
            icon: Icons.inventory_2_outlined,
            raw: item,
          ),
        ),
      ],
      WorkspaceModule.orders =>
        _list(response['data'])
            .map(
              (item) => _ModuleItem(
                title: _company(item, l10n) ?? l10n.moduleOrderDraft,
                subtitle: _parts([
                  _stage(item['status'], l10n),
                  _money(
                    item['grand_total'],
                    item['currency'],
                    l10n.localeName,
                  ),
                ]),
                icon: Icons.receipt_long_outlined,
                raw: item,
              ),
            )
            .toList(),
      WorkspaceModule.documents =>
        _list(response['data'])
            .map(
              (item) => _ModuleItem(
                title:
                    item['file_name']?.toString() ??
                    l10n.moduleDocumentFallback,
                subtitle: _parts([
                  _scanStatus(item['scan_status'], l10n),
                  _date(item['created_at'], l10n.localeName),
                  if (item['scan_status']?.toString() == 'clean')
                    l10n.moduleOpenDocument,
                ]),
                icon: Icons.description_outlined,
                raw: item,
              ),
            )
            .toList(),
      WorkspaceModule.forms => [
        ..._list(response['templates']).map(
          (item) => _ModuleItem(
            title: item['name']?.toString() ?? l10n.moduleFormTemplate,
            subtitle:
                item['description']?.toString() ??
                l10n.moduleActiveFormTemplate,
            icon: Icons.dynamic_form_outlined,
            raw: {...item, '_kind': 'template'},
          ),
        ),
        ..._list(response['submissions']).map(
          (item) => _ModuleItem(
            title: l10n.moduleSubmittedForm,
            subtitle: _parts([
              (item['template'] as Map?)?['name'],
              _date(item['submitted_at'], l10n.localeName),
            ]),
            icon: Icons.fact_check_outlined,
            raw: {...item, '_kind': 'submission'},
          ),
        ),
      ],
    };
  }

  Future<void> markNotificationRead(_ModuleItem item) async {
    final id = item.raw?['id']?.toString();
    if (id == null || item.raw?['read_at'] != null) return;
    try {
      await widget.services.api.patch('/api/notifications', {'id': id});
      if (!mounted) return;
      final next = load();
      setState(() => items = next);
      await next;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.moduleActionFailed)));
    }
  }

  Future<void> openNotificationSettings() async {
    try {
      final response =
          await widget.services.api.get('/api/settings/notifications') as Map;
      final data = Map<String, dynamic>.from(response['data'] as Map);
      var visits = data['visitReminders'] as bool? ?? true;
      var tasks = data['taskReminders'] as bool? ?? true;
      var morning = data['fieldModeMorning'] as bool? ?? true;
      if (!mounted) return;
      final saved = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(l10n.modulePreferencesTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: widget.services.reminders.permissionDenied,
                    builder: (context, denied, _) => denied
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(l10n.moduleSystemNotificationsDisabled),
                          )
                        : const SizedBox.shrink(),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.moduleVisitReminders),
                    value: visits,
                    onChanged: (value) => setDialogState(() => visits = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.moduleTaskReminders),
                    value: tasks,
                    onChanged: (value) => setDialogState(() => tasks = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.moduleMorningReminder),
                    subtitle: Text(l10n.moduleMorningReminderTime),
                    value: morning,
                    onChanged: (value) => setDialogState(() => morning = value),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      );
      if (saved != true) return;
      await widget.services.api.patch('/api/settings/notifications', {
        'visitReminders': visits,
        'taskReminders': tasks,
        'fieldModeMorning': morning,
      });
      await widget.services.reminders.sync();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.modulePreferencesSaved)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.modulePreferencesFailed)));
    }
  }

  /// Temiz tarama sonucu olan belge açılabilir. Sunucu da aynı kontrolü
  /// yapar; burası yalnız dokunulabilirliği belirler.
  bool _isOpenableDocument(_ModuleItem item) =>
      (widget.module == WorkspaceModule.products ||
          widget.module == WorkspaceModule.documents) &&
      item.raw?['scan_status']?.toString() == 'clean';

  /// Temiz çıkmış belgeyi kısa ömürlü imzalı bağlantıyla açar.
  ///
  /// Karantinadaki dosya doğrudan sunulmaz; sunucu tarama sonucu `clean`
  /// değilse bağlantı üretmez.
  Future<void> openDocument(_ModuleItem item) async {
    final id = item.raw?['id']?.toString();
    if (id == null) return;
    try {
      final result =
          await widget.services.api.get('/api/documents/$id/download')
              as Map<String, dynamic>;
      final url = result['url']?.toString();
      if (url == null || url.isEmpty) throw StateError('boş bağlantı');
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.moduleDocumentsFailed)));
    }
  }

  Future<void> refresh() async {
    final next = load();
    setState(() => items = next);
    await settleRefresh(next);
  }

  bool get _canCreate => switch (widget.module) {
    WorkspaceModule.calendar ||
    WorkspaceModule.opportunities ||
    WorkspaceModule.products ||
    WorkspaceModule.orders ||
    WorkspaceModule.documents ||
    WorkspaceModule.forms => true,
    _ => false,
  };

  String get _actionLabel => switch (widget.module) {
    WorkspaceModule.calendar => l10n.modulePlanVisit,
    WorkspaceModule.opportunities => l10n.moduleNewOpportunity,
    WorkspaceModule.products => l10n.moduleNewProduct,
    WorkspaceModule.orders => l10n.moduleNewOrderDraft,
    WorkspaceModule.documents => l10n.moduleUploadDocument,
    WorkspaceModule.forms => l10n.moduleNewForm,
    _ => l10n.moduleRegistrationFallback,
  };

  IconData get _actionIcon => switch (widget.module) {
    WorkspaceModule.calendar => Icons.event_available_outlined,
    WorkspaceModule.opportunities => Icons.add_chart_outlined,
    WorkspaceModule.products => Icons.add_box_outlined,
    WorkspaceModule.orders => Icons.post_add_outlined,
    WorkspaceModule.documents => Icons.upload_file_outlined,
    WorkspaceModule.forms => Icons.playlist_add_outlined,
    _ => Icons.add,
  };

  Future<void> createRecord() async {
    if (actionBusy) return;
    setState(() => actionBusy = true);
    try {
      final changed = switch (widget.module) {
        WorkspaceModule.calendar => WorkspaceModuleActions.planVisit(
          context,
          widget.services,
        ),
        WorkspaceModule.opportunities =>
          WorkspaceModuleActions.createOpportunity(context, widget.services),
        WorkspaceModule.products => WorkspaceModuleActions.createProduct(
          context,
          widget.services,
        ),
        WorkspaceModule.orders => WorkspaceModuleActions.createOrder(
          context,
          widget.services,
        ),
        WorkspaceModule.documents => WorkspaceModuleActions.uploadDocument(
          context,
          widget.services,
        ),
        WorkspaceModule.forms => WorkspaceModuleActions.createFormTemplate(
          context,
          widget.services,
        ),
        _ => Future.value(false),
      };
      if (!await changed || !mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.moduleRecordCreated)));
      await refresh();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.moduleActionFailed)));
    } finally {
      if (mounted) setState(() => actionBusy = false);
    }
  }

  bool _canActivate(_ModuleItem item) =>
      widget.module == WorkspaceModule.notifications ||
      _isOpenableDocument(item) ||
      widget.module == WorkspaceModule.calendar ||
      widget.module == WorkspaceModule.activity ||
      widget.module == WorkspaceModule.reports ||
      widget.module == WorkspaceModule.opportunities ||
      widget.module == WorkspaceModule.orders ||
      (widget.module == WorkspaceModule.forms &&
          item.raw?['_kind'] == 'template');

  Future<void> activateItem(_ModuleItem item) async {
    try {
      switch (widget.module) {
        case WorkspaceModule.notifications:
          await markNotificationRead(item);
          if (!mounted) return;
          final action = item.raw?['action_url']?.toString();
          if (action == '/tasks') {
            context.go('/tasks');
          } else if (action == '/visits' ||
              item.raw?['resource_type']?.toString() == 'visit') {
            context.go('/visits');
          } else {
            // Silinmiş/geçersiz kaynaklar ve sabah saha hatırlatması için
            // güvenli hedef: Saha Modu kartını içeren Ana Sayfa.
            context.go('/');
          }
          return;
        case WorkspaceModule.documents:
        case WorkspaceModule.products:
          if (_isOpenableDocument(item)) await openDocument(item);
          return;
        case WorkspaceModule.calendar:
          context.go(item.raw?['_kind'] == 'task' ? '/tasks' : '/visits');
          return;
        case WorkspaceModule.activity:
          final id = item.raw?['resourceId']?.toString();
          if (id != null && item.raw?['kind'] == 'visit') {
            context.push('/visits/$id/review');
          }
          return;
        case WorkspaceModule.reports:
          final route = item.raw?['route']?.toString();
          if (route != null) context.go(route);
          return;
        case WorkspaceModule.opportunities:
          if (item.raw != null &&
              await WorkspaceModuleActions.editOpportunity(
                context,
                item.raw!,
              )) {
            await refresh();
          }
          return;
        case WorkspaceModule.orders:
          if (item.raw != null) await _openOrder(item.raw!);
          return;
        case WorkspaceModule.forms:
          if (item.raw?['_kind'] == 'template' &&
              await WorkspaceModuleActions.submitForm(
                context,
                widget.services,
                item.raw!,
              )) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.moduleFormSubmitted)));
            }
            await refresh();
          }
          return;
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.moduleActionFailed)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.module.localizedTitle(l10n)),
      actions: [
        if (widget.module == WorkspaceModule.notifications)
          IconButton(
            tooltip: l10n.modulePreferencesTitle,
            onPressed: openNotificationSettings,
            icon: const Icon(Icons.tune),
          ),
      ],
    ),
    floatingActionButton: _canCreate
        ? FloatingActionButton.extended(
            onPressed: actionBusy || !widget.services.canWrite
                ? null
                : createRecord,
            icon: actionBusy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_actionIcon),
            label: Text(actionBusy ? l10n.sending : _actionLabel),
          )
        : null,
    body: FutureBuilder<List<_ModuleItem>>(
      future: items,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.moduleLoadFailed, textAlign: TextAlign.center),
                  TextButton(onPressed: refresh, child: Text(l10n.retrySync)),
                ],
              ),
            ),
          );
        }
        final data = snapshot.data ?? [];
        if (widget.module == WorkspaceModule.opportunities) {
          return _buildOpportunities(data);
        }
        if (widget.module == WorkspaceModule.orders) {
          return _buildOrders(data);
        }
        if (widget.module == WorkspaceModule.activity) {
          return _buildActivity(data);
        }
        if (widget.module == WorkspaceModule.products) {
          return _buildProducts(data);
        }
        if (data.isEmpty) {
          // Boş durum yalnız "kayıt bulunmuyor" diyordu; kullanıcı ekranın ne
          // olduğunu da, kaydın nereden geleceğini de bilmiyordu. Metinde
          // pazarlama sitesine tıklanabilir bağlantı verilmez
          // (store_compliance_test.dart bunu kesiyor).
          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(28),
              children: [
                const SizedBox(height: 40),
                Icon(widget.module.emptyIcon, size: 44),
                const SizedBox(height: 14),
                Text(
                  widget.module == WorkspaceModule.notifications
                      ? l10n.moduleNoNewNotifications
                      : widget.module.localizedEmptyTitle(l10n),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.module.localizedEmptyBody(l10n),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: refresh,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.moduleRefresh),
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, index) {
              final item = data[index];
              return Card(
                child: ListTile(
                  leading: Icon(item.icon),
                  title: Text(item.title),
                  subtitle: item.subtitle.isEmpty ? null : Text(item.subtitle),
                  trailing: _canActivate(item)
                      ? const Icon(Icons.chevron_right)
                      : null,
                  onTap: _canActivate(item) ? () => activateItem(item) : null,
                ),
              );
            },
          ),
        );
      },
    ),
  );

  Widget _buildOpportunities(List<_ModuleItem> all) {
    bool visible(_ModuleItem item) => switch (opportunityFilter) {
      'open' => !const {'won', 'lost'}.contains(item.raw?['stage']),
      'won' => item.raw?['stage'] == 'won',
      'lost' => item.raw?['stage'] == 'lost',
      _ => true,
    };

    final items = all.where(visible).toList();
    final open = all
        .where((item) => !const {'won', 'lost'}.contains(item.raw?['stage']))
        .toList();
    final totals = <String, double>{'TRY': 0, 'USD': 0, 'EUR': 0};
    for (final item in open) {
      final currency = item.raw?['currency']?.toString();
      final value = item.raw?['estimated_value'];
      if (currency != null && value is num && totals.containsKey(currency)) {
        totals[currency] = totals[currency]! + value.toDouble();
      }
    }

    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          Text(
            l10n.moduleOpportunityOpenCount(open.length),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: totals.entries
                .where((entry) => entry.value > 0)
                .map(
                  (entry) => Chip(
                    label: Text(
                      _compactMoney(entry.value, entry.key, l10n.localeName),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children:
                {
                      'open': l10n.moduleOpportunityOpen,
                      'won': l10n.moduleOpportunityWon,
                      'lost': l10n.moduleOpportunityLost,
                      'all': l10n.moduleAll,
                    }.entries
                    .map(
                      (entry) => FilterChip(
                        label: Text(entry.value),
                        selected: opportunityFilter == entry.key,
                        onSelected: (_) =>
                            setState(() => opportunityFilter = entry.key),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(
                children: [
                  Text(
                    all.isEmpty
                        ? WorkspaceModule.opportunities.localizedEmptyTitle(
                            l10n,
                          )
                        : l10n.moduleFilteredOpportunitiesEmpty,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (all.isEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      WorkspaceModule.opportunities.localizedEmptyBody(l10n),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: refresh,
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.moduleRefresh),
                    ),
                  ],
                ],
              ),
            )
          else
            ...items.map((item) {
              final raw = item.raw!;
              final stage = raw['stage']?.toString();
              final close = _dateOnly(
                raw['expected_close_date'],
                l10n.localeName,
              );
              return Card(
                child: InkWell(
                  onTap: widget.services.canWrite
                      ? () => activateItem(item)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (_company(raw, l10n) case final company?)
                          Text(
                            company,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              _money(
                                    raw['estimated_value'],
                                    raw['currency'],
                                    l10n.localeName,
                                  ) ??
                                  '0 ${raw['currency'] ?? 'TRY'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Chip(label: Text(_stage(stage, l10n))),
                            Text(
                              NumberFormat.percentPattern(
                                l10n.localeName,
                              ).format(
                                ((raw['probability'] as num?) ?? 0) / 100,
                              ),
                            ),
                          ],
                        ),
                        if (close != null)
                          Text(l10n.moduleEstimateClose(close)),
                        if (stage == 'lost' &&
                            (raw['loss_reason']?.toString() ?? '').isNotEmpty)
                          Text(
                            l10n.moduleReason(raw['loss_reason'].toString()),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _openOrder(Map<String, dynamic> order) async {
    final status = order['status']?.toString() ?? 'draft';
    final editable = status == 'draft' || status == 'rejected';
    final action = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _company(order, l10n) ?? l10n.orderDrafts,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Chip(label: Text(_stage(status, l10n))),
              Text(_orderExplanation(status, l10n)),
              const SizedBox(height: 16),
              for (final item in _list(order['items']))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          (item['product'] as Map?)?['name']?.toString() ??
                              l10n.productsPrices,
                        ),
                      ),
                      Text(
                        '${NumberFormat.decimalPattern(l10n.localeName).format((item['quantity'] as num?) ?? 0)} × ${_money(item['unit_price'], order['currency'], l10n.localeName) ?? item['unit_price']}',
                      ),
                    ],
                  ),
                ),
              const Divider(),
              Text(
                l10n.moduleOrderTotal(
                  _money(
                        order['grand_total'],
                        order['currency'],
                        l10n.localeName,
                      ) ??
                      '0 ${order['currency']}',
                ),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (order['delivery_date'] != null)
                Text(
                  l10n.moduleDeliveryDate(
                    _dateOnly(order['delivery_date'], l10n.localeName) ?? '',
                  ),
                ),
              if ((order['notes']?.toString() ?? '').isNotEmpty)
                Text(l10n.moduleNote(order['notes'].toString())),
              if (status == 'rejected') ...[
                const SizedBox(height: 12),
                Text(
                  l10n.moduleReason(
                    (order['rejected_reason'] ?? '-').toString(),
                  ),
                ),
                if (order['decision_actor_name'] != null)
                  Text(
                    l10n.moduleRejectedBy(
                      order['decision_actor_name'].toString(),
                    ),
                  ),
                if (order['rejected_at'] != null)
                  Text(
                    l10n.moduleDate(
                      _date(order['rejected_at'], l10n.localeName) ?? '',
                    ),
                  ),
              ],
              const SizedBox(height: 20),
              if (editable)
                OutlinedButton.icon(
                  onPressed: widget.services.canWrite
                      ? () => Navigator.pop(sheetContext, 'edit')
                      : null,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(
                    status == 'rejected'
                        ? l10n.moduleEditAndReturnToDraft
                        : l10n.moduleEdit,
                  ),
                ),
              if (status == 'draft')
                FilledButton(
                  onPressed: widget.services.canWrite
                      ? () => Navigator.pop(sheetContext, 'transition')
                      : null,
                  child: Text(l10n.moduleSubmitForApproval),
                ),
              if (status == 'pending_approval' && canApproveOrders)
                FilledButton(
                  onPressed: widget.services.canWrite
                      ? () => Navigator.pop(sheetContext, 'transition')
                      : null,
                  child: Text(l10n.moduleMakeDecision),
                ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || action == null) return;
    bool changed = false;
    if (action == 'edit') {
      changed = await context.push<bool>('/orders/form', extra: order) ?? false;
    } else {
      changed = await WorkspaceModuleActions.transitionOrder(
        context,
        widget.services,
        order,
        canApprove: canApproveOrders,
      );
    }
    if (changed && mounted) await refresh();
  }

  Widget _buildOrders(List<_ModuleItem> all) {
    bool visible(_ModuleItem item) => switch (orderFilter) {
      'open' => const {
        'draft',
        'pending_approval',
      }.contains(item.raw?['status']),
      'approved' => item.raw?['status'] == 'approved',
      'rejected' => item.raw?['status'] == 'rejected',
      _ => true,
    };
    final filtered = all.where(visible).toList();
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                {
                      'open': l10n.moduleOpportunityOpen,
                      'approved': l10n.moduleOrderApproved,
                      'rejected': l10n.moduleOrderRejected,
                      'all': l10n.moduleAll,
                    }.entries
                    .map(
                      (entry) => FilterChip(
                        label: Text(entry.value),
                        selected: orderFilter == entry.key,
                        onSelected: (_) =>
                            setState(() => orderFilter = entry.key),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Text(
                all.isEmpty
                    ? WorkspaceModule.orders.localizedEmptyTitle(l10n)
                    : l10n.moduleFilteredOrdersEmpty,
                textAlign: TextAlign.center,
              ),
            )
          else
            ...filtered.map((item) {
              final raw = item.raw!;
              return Card(
                child: InkWell(
                  onTap: () => _openOrder(raw),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _money(
                                raw['grand_total'],
                                raw['currency'],
                                l10n.localeName,
                              ) ??
                              '0 ${raw['currency'] ?? 'TRY'}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Chip(label: Text(_stage(raw['status'], l10n))),
                            Text(
                              _dateOnly(raw['created_at'], l10n.localeName) ??
                                  '',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildActivity(List<_ModuleItem> all) {
    final filtered = activityFilter == 'all'
        ? all
        : all.where((item) => item.raw?['kind'] == activityFilter).toList();
    String dayLabel(dynamic value) {
      final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
      if (date == null) return l10n.unknown;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final day = DateTime(date.year, date.month, date.day);
      if (day == today) return l10n.today;
      if (day == today.subtract(const Duration(days: 1))) return l10n.yesterday;
      return _dateOnly(value, l10n.localeName) ?? l10n.unknown;
    }

    String? previousDay;
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                {
                      'all': l10n.moduleAll,
                      'visit': l10n.moduleActivityVisits,
                      'task': l10n.moduleActivityTasks,
                      'opportunity': l10n.moduleActivityOpportunities,
                      'order': l10n.moduleActivityOrders,
                    }.entries
                    .map(
                      (entry) => FilterChip(
                        label: Text(entry.value),
                        selected: activityFilter == entry.key,
                        onSelected: (_) =>
                            setState(() => activityFilter = entry.key),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Text(
                all.isEmpty
                    ? WorkspaceModule.activity.localizedEmptyTitle(l10n)
                    : l10n.moduleFilteredActivityEmpty,
                textAlign: TextAlign.center,
              ),
            ),
          ...filtered.expand((item) {
            final day = dayLabel(item.raw?['occurredAt']);
            final showDay = day != previousDay;
            previousDay = day;
            return [
              if (showDay)
                Padding(
                  padding: const EdgeInsets.only(top: 14, bottom: 6),
                  child: Text(
                    day,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(item.icon),
                title: Text(item.title),
                subtitle: item.subtitle.isEmpty ? null : Text(item.subtitle),
              ),
            ];
          }),
        ],
      ),
    );
  }

  Widget _buildProducts(List<_ModuleItem> all) {
    final priceLists = all.where((item) => item.raw?['_kind'] == 'price_list');
    final products = all.where((item) => item.raw?['_kind'] != 'price_list');
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          Text(
            l10n.modulePriceLists,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(l10n.moduleCleanPriceListHint),
          const SizedBox(height: 8),
          if (priceLists.isEmpty)
            Card(child: ListTile(title: Text(l10n.moduleNoPriceLists))),
          ...priceLists.map(
            (item) => Card(
              child: ListTile(
                leading: Icon(item.icon),
                title: Text(item.title),
                subtitle: Text(item.subtitle),
                trailing: item.raw?['scan_status'] == 'clean'
                    ? const Icon(Icons.open_in_new)
                    : null,
                onTap: item.raw?['scan_status'] == 'clean'
                    ? () => openDocument(item)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.moduleProductCatalog,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (products.isEmpty)
            Card(child: ListTile(title: Text(l10n.moduleNoActiveProducts))),
          ...products.map(
            (item) => Card(
              child: ListTile(
                leading: Icon(item.icon),
                title: Text(item.title),
                subtitle: item.subtitle.isEmpty ? null : Text(item.subtitle),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleItem {
  const _ModuleItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.raw,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Map<String, dynamic>? raw;
}

List<Map<String, dynamic>> _list(dynamic value) =>
    List<Map<String, dynamic>>.from(value as List? ?? []);

String? _company(Map<String, dynamic> item, AppLocalizations l10n) =>
    item['company'] is Map
    ? customerDisplayName(
        item['company'] as Map,
        fallback: l10n.companyFallback,
      )
    : null;

String _parts(List<dynamic> values) => values
    .where((value) => value != null && value.toString().trim().isNotEmpty)
    .map((value) => value.toString())
    .join(' · ');

String? _date(dynamic value, String locale) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  if (date == null) return null;
  return DateFormat.yMd(locale).add_jm().format(date.toLocal());
}

String? _notificationTime(dynamic value, AppLocalizations l10n) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return null;
  final now = DateTime.now();
  final day = DateTime(date.year, date.month, date.day);
  final today = DateTime(now.year, now.month, now.day);
  final label = day == today
      ? l10n.today
      : day == today.subtract(const Duration(days: 1))
      ? l10n.yesterday
      : DateFormat.yMd(l10n.localeName).format(date);
  return '$label ${DateFormat.jm(l10n.localeName).format(date)}';
}

String? _money(dynamic value, dynamic currency, String locale) {
  if (value is! num) return null;
  final code = currency?.toString() ?? 'TRY';
  return NumberFormat.currency(locale: locale, name: code).format(value);
}

String _compactMoney(double value, String currency, String locale) =>
    NumberFormat.compactCurrency(locale: locale, name: currency).format(value);

String? _dateOnly(dynamic value, String locale) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  if (date == null) return null;
  return DateFormat.yMd(locale).format(date.toLocal());
}

String _stage(dynamic value, AppLocalizations l10n) =>
    switch (value?.toString()) {
      'lead' => l10n.moduleStageLead,
      'qualified' => l10n.moduleStageQualified,
      'proposal' => l10n.moduleStageProposal,
      'negotiation' => l10n.moduleStageNegotiation,
      'won' => l10n.moduleStageWon,
      'lost' => l10n.moduleStageLost,
      'draft' => l10n.moduleStageDraft,
      'pending_approval' => l10n.moduleStagePendingApproval,
      'approved' => l10n.moduleStageApproved,
      'rejected' => l10n.moduleStageRejected,
      final value? => value,
      null => '',
    };

String _orderExplanation(String status, AppLocalizations l10n) =>
    switch (status) {
      'draft' => l10n.moduleOrderDraftExplanation,
      'pending_approval' => l10n.moduleOrderPendingExplanation,
      'approved' => l10n.moduleOrderApprovedExplanation,
      'rejected' => l10n.moduleOrderRejectedExplanation,
      _ => '',
    };

String _scanStatus(dynamic value, AppLocalizations l10n) =>
    switch (value?.toString()) {
      'pending' => l10n.moduleScanStatusPending,
      'clean' => l10n.moduleScanStatusClean,
      'infected' => l10n.moduleScanStatusInfected,
      'error' => l10n.moduleScanStatusError,
      _ => l10n.moduleScanStatusUnknown,
    };

IconData _activityIcon(dynamic kind) => switch (kind?.toString()) {
  'visit' => Icons.handshake_outlined,
  'task' => Icons.task_alt_outlined,
  'opportunity' => Icons.trending_up,
  'order' => Icons.receipt_long_outlined,
  _ => Icons.history,
};
