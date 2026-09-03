import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/mobile_services.dart';
import 'customer_identity.dart';

class CustomerChoice {
  const CustomerChoice({
    required this.id,
    required this.name,
    this.legalName,
    this.address,
  });

  factory CustomerChoice.fromMap(Map<String, dynamic> value) => CustomerChoice(
    id: value['id']?.toString() ?? '',
    name: customerDisplayName(value),
    legalName: customerLegalName(value),
    address: value['address']?.toString(),
  );

  final String id;
  final String name;
  final String? legalName;
  final String? address;
}

Future<CustomerChoice?> showCustomerPicker(
  BuildContext context, {
  required MobileServices services,
  bool allowNone = false,
}) => showModalBottomSheet<CustomerChoice>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (_) => FractionallySizedBox(
    heightFactor: .9,
    child: _CustomerPickerSheet(services: services, allowNone: allowNone),
  ),
);

class _CustomerPickerSheet extends StatefulWidget {
  const _CustomerPickerSheet({required this.services, required this.allowNone});

  final MobileServices services;
  final bool allowNone;

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  static const pageSize = 30;
  final query = TextEditingController();
  final scroll = ScrollController();
  final items = <CustomerChoice>[];
  Timer? debounce;
  bool loading = false;
  bool hasMore = true;
  String? error;
  int generation = 0;

  @override
  void initState() {
    super.initState();
    scroll.addListener(_onScroll);
    _reload();
  }

  @override
  void dispose() {
    debounce?.cancel();
    query.dispose();
    scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (scroll.position.extentAfter < 240) _loadMore();
  }

  void _onQueryChanged(String _) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 300), _reload);
  }

  Future<void> _reload() async {
    generation += 1;
    // Eski arama isteği sürerken yazılan yeni sorgu da hemen başlayabilsin.
    // Eski yanıt, generation kontrolü sayesinde yeni listeyi ezemez.
    loading = false;
    items.clear();
    hasMore = true;
    error = null;
    if (mounted) setState(() {});
    await _loadMore(expectedGeneration: generation);
  }

  Future<void> _loadMore({int? expectedGeneration}) async {
    if (loading || !hasMore) return;
    final requestGeneration = expectedGeneration ?? generation;
    setState(() => loading = true);
    try {
      await widget.services.refreshContext();
      final search = query.text.trim();
      final response =
          await widget.services.api.get(
                '/api/customers?limit=$pageSize&offset=${items.length}'
                '${search.isEmpty ? '' : '&q=${Uri.encodeQueryComponent(search)}'}',
              )
              as Map<String, dynamic>;
      if (!mounted || requestGeneration != generation) return;
      final next = List<Map<String, dynamic>>.from(
        response['data'] as List? ?? const [],
      ).map(CustomerChoice.fromMap).where((item) => item.id.isNotEmpty);
      final page = response['page'] as Map?;
      setState(() {
        items.addAll(next);
        hasMore = page?['hasMore'] == true;
        error = null;
      });
    } catch (caught) {
      if (!mounted || requestGeneration != generation) return;
      setState(() => error = caught.toString());
    } finally {
      if (mounted && requestGeneration == generation) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Müşteri seç',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: 'Kapat',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: TextField(
          controller: query,
          autofocus: true,
          onChanged: _onQueryChanged,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Kısa ad, firma, adres veya e-posta ara',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      if (widget.allowNone)
        ListTile(
          leading: const Icon(Icons.not_interested_outlined),
          title: const Text('Müşteri seçmeden devam et'),
          onTap: () => Navigator.pop(context),
        ),
      const Divider(height: 1),
      Expanded(
        child: error != null && items.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error!, textAlign: TextAlign.center),
                      TextButton(
                        onPressed: _reload,
                        child: const Text('Tekrar dene'),
                      ),
                    ],
                  ),
                ),
              )
            : items.isEmpty && loading
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
            ? const Center(child: Text('Aramaya uygun müşteri bulunamadı.'))
            : ListView.separated(
                controller: scroll,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: items.length + (loading ? 1 : 0),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index == items.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final item = items[index];
                  return ListTile(
                    leading: const Icon(Icons.apartment_outlined),
                    title: Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      [
                        if (item.legalName != null) item.legalName!,
                        if ((item.address ?? '').trim().isNotEmpty)
                          item.address!,
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => Navigator.pop(context, item),
                  );
                },
              ),
      ),
    ],
  );
}
