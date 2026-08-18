import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/mobile_services.dart';
import '../../core/refresh.dart';

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

  /// Ekranın ne olduğunu ve kaydın nerede oluştuğunu anlatır.
  ///
  /// Bu modüllerin çoğu mobilde bilinçli olarak salt okunurdur; saha çalışanı
  /// fırsat ya da ürün yayınlamaz, sahada bunları okur
  /// (bkz. `docs/MOBILE_WEB_PARITY.md`).
  String get emptyBody => switch (this) {
    WorkspaceModule.calendar =>
      'Tarihli ziyaretler ve son tarihi olan görevler burada listelenir. '
          'Planlı ziyaret web çalışma alanındaki takvimden oluşturulur; '
          'görevlere tarihi Görevler ekranından verebilirsiniz.',
    WorkspaceModule.activity =>
      'Onayladığınız ziyaretler buraya düşer. Bir ziyaret notu gönderip '
          'özeti onayladığınızda ilk kayıt görünecek.',
    WorkspaceModule.reports =>
      'Müşteri, ziyaret ve görev sayıları buradan okunur. İlk müşterinizi '
          'ekleyip bir ziyaret kaydettiğinizde göstergeler dolar.',
    WorkspaceModule.notifications =>
      'Yorum, görev ve onay olayları burada birikir. Bu olaylar web çalışma '
          'alanındaki yorumlardan üretilir; yalnız mobil kullanıyorsanız bu '
          'liste boş kalır.',
    WorkspaceModule.opportunities =>
      'Satış pipeline\'ı sahada salt okunur gösterilir. Fırsat kayıtları web '
          'çalışma alanında oluşturulur ve aşaması orada güncellenir.',
    WorkspaceModule.products =>
      'Aktif ürün kataloğu ve liste fiyatları sahada salt okunur gösterilir. '
          'Ürünler ve fiyat listesi web çalışma alanında yönetilir.',
    WorkspaceModule.orders =>
      'Sipariş taslaklarının durumu ve tutarı sahada salt okunur gösterilir. '
          'Taslaklar web çalışma alanında oluşturulur.',
    WorkspaceModule.documents =>
      'Yüklenen dosyalar ve zararlı yazılım tarama durumları burada görünür. '
          'Belge yükleme web çalışma alanında yapılır.',
    WorkspaceModule.forms =>
      'Saha formu şablonları ve gönderimleri burada listelenir. Şablonlar web '
          'çalışma alanında tanımlanır.',
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
      final customers = _list((responses[0] as Map)['data']);
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
          title: '${customers.length}',
          subtitle: 'Aktif müşteri',
          icon: Icons.apartment_outlined,
        ),
        _ModuleItem(
          title: '$approved',
          subtitle: 'Onaylanmış ziyaret',
          icon: Icons.verified_outlined,
        ),
        _ModuleItem(
          title: '$review',
          subtitle: 'İnceleme bekleyen ziyaret',
          icon: Icons.rate_review_outlined,
        ),
        _ModuleItem(
          title: '$openTasks',
          subtitle: 'Açık görev',
          icon: Icons.task_alt_outlined,
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
          ),
        ),
        ..._list(response['tasks']).map(
          (item) => _ModuleItem(
            title: item['title']?.toString() ?? 'Görev',
            subtitle: _parts([_company(item), _date(item['due_at'])]),
            icon: Icons.task_alt_outlined,
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
                ]),
                icon: Icons.description_outlined,
              ),
            )
            .toList(),
      WorkspaceModule.forms => [
        ..._list(response['templates']).map(
          (item) => _ModuleItem(
            title: item['name']?.toString() ?? 'Form şablonu',
            subtitle: item['description']?.toString() ?? 'Aktif form şablonu',
            icon: Icons.dynamic_form_outlined,
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

  bool _isOpenablePriceList(_ModuleItem item) =>
      widget.module == WorkspaceModule.products &&
      item.raw?['scan_status']?.toString() == 'clean';

  /// Temiz çıkmış fiyat listesini kısa ömürlü imzalı bağlantıyla açar.
  ///
  /// Karantinadaki dosya doğrudan sunulmaz; sunucu tarama sonucu `clean`
  /// değilse bağlantı üretmez.
  Future<void> openPriceList(_ModuleItem item) async {
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
                : 'Fiyat listesi açılamadı. Tekrar deneyin.',
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.module.title)),
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
                  onTap: widget.module == WorkspaceModule.notifications
                      ? () => markNotificationRead(item)
                      : _isOpenablePriceList(item)
                      ? () => openPriceList(item)
                      : null,
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
    (item['company'] as Map?)?['name']?.toString();

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
