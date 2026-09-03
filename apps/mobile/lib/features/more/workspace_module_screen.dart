import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/mobile_services.dart';
import '../../core/refresh.dart';
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
  String get title => switch (this) {
    WorkspaceModule.calendar => 'Takvim',
    WorkspaceModule.activity => 'Aktivite',
    WorkspaceModule.reports => 'Rapor özeti',
    WorkspaceModule.notifications => 'Bildirimler',
    WorkspaceModule.opportunities => 'Fırsatlar',
    WorkspaceModule.products => 'Ürün ve fiyatlar',
    WorkspaceModule.orders => 'Sipariş taslakları',
    WorkspaceModule.documents => 'Belgeler',
    WorkspaceModule.forms => 'Saha formları',
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

  String get emptyTitle => switch (this) {
    WorkspaceModule.calendar => 'Planlanmış ziyaret yok',
    WorkspaceModule.activity => 'Henüz onaylanmış ziyaret yok',
    WorkspaceModule.reports => 'Gösterge üretecek kayıt yok',
    WorkspaceModule.notifications => 'Bildirim yok',
    WorkspaceModule.opportunities => 'Fırsat kaydı yok',
    WorkspaceModule.products => 'Katalogda ürün yok',
    WorkspaceModule.orders => 'Sipariş taslağı yok',
    WorkspaceModule.documents => 'Belge yok',
    WorkspaceModule.forms => 'Aktif form yok',
  };

  /// Ekranın ne olduğunu ve mobilde ilk kaydın nasıl oluştuğunu anlatır.
  String get emptyBody => switch (this) {
    WorkspaceModule.calendar =>
      'Tarihli ziyaretler ve son tarihi olan görevler burada listelenir. '
          'Sağ alttaki düğmeyle yeni ziyaret planlayabilirsiniz.',
    WorkspaceModule.activity =>
      'Onayladığınız ziyaretler buraya düşer. Bir ziyaret notu gönderip '
          'özeti onayladığınızda ilk kayıt görünecek.',
    WorkspaceModule.reports =>
      'Müşteri, ziyaret ve görev sayıları buradan okunur. İlk müşterinizi '
          'ekleyip bir ziyaret kaydettiğinizde göstergeler dolar.',
    WorkspaceModule.notifications =>
      'Yorum, görev ve onay olayları burada birikir. Yeni olay oluştuğunda '
          'mobilde okuyup işaretleyebilirsiniz.',
    WorkspaceModule.opportunities =>
      'Yeni fırsatı mobilde oluşturabilir, kayda dokunarak satış aşamasını '
          'güncelleyebilirsiniz.',
    WorkspaceModule.products =>
      'Aktif ürün kataloğu ve liste fiyatları burada görünür. Yeni ürünü '
          'mobilde kataloğa ekleyebilirsiniz.',
    WorkspaceModule.orders =>
      'Mobilde sipariş taslağı oluşturabilir; kayda dokunarak onaya '
          'gönderebilir veya yetkiniz varsa sonuçlandırabilirsiniz.',
    WorkspaceModule.documents =>
      'Yüklenen dosyalar ve zararlı yazılım tarama durumları burada görünür. '
          'Belgeyi fotoğraflayıp güvenlik taramasına gönderebilirsiniz.',
    WorkspaceModule.forms =>
      'Mobilde form şablonu oluşturabilir; şablona dokunup saha yanıtını '
          'gönderebilirsiniz.',
  };

  String get path => switch (this) {
    WorkspaceModule.calendar => '/api/calendar',
    WorkspaceModule.activity => '/api/visits',
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
          subtitle: 'Aktif müşteri',
          icon: Icons.apartment_outlined,
          raw: const {'route': '/customers'},
        ),
        _ModuleItem(
          title: '$approved',
          subtitle: 'Onaylanmış ziyaret',
          icon: Icons.verified_outlined,
          raw: const {'route': '/visits'},
        ),
        _ModuleItem(
          title: '$review',
          subtitle: 'İnceleme bekleyen ziyaret',
          icon: Icons.rate_review_outlined,
          raw: const {'route': '/visits'},
        ),
        _ModuleItem(
          title: '$openTasks',
          subtitle: 'Açık görev',
          icon: Icons.task_alt_outlined,
          raw: const {'route': '/tasks'},
        ),
      ];
    }
    final path = widget.module == WorkspaceModule.activity
        ? '${widget.module.path}?workspaceId=${widget.services.workspaceId}'
        : widget.module.path;
    final response =
        await widget.services.api.get(path) as Map<String, dynamic>;

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
              title: item['file_name']?.toString() ?? 'Fiyat listesi',
              subtitle: item['scan_status']?.toString() == 'clean'
                  ? _parts([_date(item['created_at']), 'Açmak için dokunun'])
                  : 'Güvenlik taraması sürüyor; henüz açılamaz',
              icon: Icons.picture_as_pdf_outlined,
              raw: item,
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
            title: _company(item) ?? item['purpose']?.toString() ?? 'Ziyaret',
            subtitle: _parts([
              item['purpose'],
              _date(item['planned_start_at']),
            ]),
            icon: Icons.event_outlined,
            raw: {...item, '_kind': 'visit'},
          ),
        ),
        ..._list(response['tasks']).map(
          (item) => _ModuleItem(
            title: item['title']?.toString() ?? 'Görev',
            subtitle: _parts([_company(item), _date(item['due_at'])]),
            icon: Icons.task_alt_outlined,
            raw: {...item, '_kind': 'task'},
          ),
        ),
      ],
      WorkspaceModule.activity =>
        _list(response['data'])
            .where((item) => item['status']?.toString() == 'approved')
            .map(
              (item) => _ModuleItem(
                title: _company(item) ?? 'Müşteri ziyareti',
                subtitle: _parts([item['purpose'], _date(item['approved_at'])]),
                icon: Icons.verified_outlined,
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
                    'Bildirim',
                subtitle:
                    item['body']?.toString() ??
                    item['message']?.toString() ??
                    '',
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
                title: item['title']?.toString() ?? 'Fırsat',
                subtitle: _parts([
                  _company(item),
                  _stage(item['stage']),
                  _money(item['estimated_value'], item['currency']),
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
            title: item['name']?.toString() ?? 'Ürün',
            subtitle: _parts([
              item['sku'],
              _money(item['list_price'], item['currency']),
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
                title: _company(item) ?? 'Sipariş taslağı',
                subtitle: _parts([
                  _stage(item['status']),
                  _money(item['grand_total'], item['currency']),
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
                title: item['file_name']?.toString() ?? 'Belge',
                subtitle: _parts([
                  _scanStatus(item['scan_status']),
                  _date(item['created_at']),
                  if (item['scan_status']?.toString() == 'clean')
                    'Açmak için dokunun',
                ]),
                icon: Icons.description_outlined,
                raw: item,
              ),
            )
            .toList(),
      WorkspaceModule.forms => [
        ..._list(response['templates']).map(
          (item) => _ModuleItem(
            title: item['name']?.toString() ?? 'Form şablonu',
            subtitle: item['description']?.toString() ?? 'Aktif form şablonu',
            icon: Icons.dynamic_form_outlined,
            raw: {...item, '_kind': 'template'},
          ),
        ),
        ..._list(response['submissions']).map(
          (item) => _ModuleItem(
            title: 'Gönderilmiş form',
            subtitle: _parts([
              (item['template'] as Map?)?['name'],
              _date(item['submitted_at']),
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
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is MobileApiException
                ? error.message
                : 'Belge açılamadı. Tekrar deneyin.',
          ),
        ),
      );
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
    WorkspaceModule.calendar => 'Ziyaret planla',
    WorkspaceModule.opportunities => 'Yeni fırsat',
    WorkspaceModule.products => 'Yeni ürün',
    WorkspaceModule.orders => 'Yeni taslak',
    WorkspaceModule.documents => 'Belge yükle',
    WorkspaceModule.forms => 'Yeni form',
    _ => 'Yeni kayıt',
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
      ).showSnackBar(const SnackBar(content: Text('Kayıt oluşturuldu.')));
      await refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is MobileApiException
                ? error.message
                : 'İşlem tamamlanamadı. Tekrar deneyin.',
          ),
        ),
      );
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
          return;
        case WorkspaceModule.documents:
        case WorkspaceModule.products:
          if (_isOpenableDocument(item)) await openDocument(item);
          return;
        case WorkspaceModule.calendar:
          context.go(item.raw?['_kind'] == 'task' ? '/tasks' : '/visits');
          return;
        case WorkspaceModule.activity:
          final id = item.raw?['id']?.toString();
          if (id != null) context.push('/visits/$id/review');
          return;
        case WorkspaceModule.reports:
          final route = item.raw?['route']?.toString();
          if (route != null) context.go(route);
          return;
        case WorkspaceModule.opportunities:
          if (item.raw != null &&
              await WorkspaceModuleActions.updateOpportunityStage(
                context,
                widget.services,
                item.raw!,
              )) {
            await refresh();
          }
          return;
        case WorkspaceModule.orders:
          if (item.raw != null &&
              await WorkspaceModuleActions.transitionOrder(
                context,
                widget.services,
                item.raw!,
              )) {
            await refresh();
          }
          return;
        case WorkspaceModule.forms:
          if (item.raw?['_kind'] == 'template' &&
              await WorkspaceModuleActions.submitForm(
                context,
                widget.services,
                item.raw!,
              )) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Form yanıtı gönderildi.')),
              );
            }
            await refresh();
          }
          return;
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is MobileApiException
                ? error.message
                : 'İşlem tamamlanamadı. Tekrar deneyin.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.module.title)),
    floatingActionButton: _canCreate
        ? FloatingActionButton.extended(
            onPressed: actionBusy ? null : createRecord,
            icon: actionBusy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_actionIcon),
            label: Text(actionBusy ? 'İşleniyor…' : _actionLabel),
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
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  TextButton(
                    onPressed: refresh,
                    child: const Text('Tekrar dene'),
                  ),
                ],
              ),
            ),
          );
        }
        final data = snapshot.data ?? [];
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
                  widget.module.emptyTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.module.emptyBody,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Yenile'),
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

String? _company(Map<String, dynamic> item) =>
    item['company'] is Map ? customerDisplayName(item['company'] as Map) : null;

String _parts(List<dynamic> values) => values
    .where((value) => value != null && value.toString().trim().isNotEmpty)
    .map((value) => value.toString())
    .join(' · ');

String? _date(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  if (date == null) return null;
  final local = date.toLocal();
  return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String? _money(dynamic value, dynamic currency) {
  if (value is! num) return null;
  return '${value.toStringAsFixed(2)} ${currency ?? 'TRY'}';
}

String _stage(dynamic value) => switch (value?.toString()) {
  'lead' => 'Aday',
  'qualified' => 'Nitelikli',
  'proposal' => 'Teklif',
  'negotiation' => 'Müzakere',
  'won' => 'Kazanıldı',
  'lost' => 'Kaybedildi',
  'draft' => 'Taslak',
  'pending_approval' => 'Onay bekliyor',
  'approved' => 'Onaylandı',
  'rejected' => 'Reddedildi',
  final value? => value,
  null => '',
};

String _scanStatus(dynamic value) => switch (value?.toString()) {
  'pending' => 'Tarama bekliyor',
  'clean' => 'Temiz',
  'infected' => 'Zararlı içerik bulundu',
  'error' => 'Tarama hatası',
  _ => 'Durum bilinmiyor',
};
