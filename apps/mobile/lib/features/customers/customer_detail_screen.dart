import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/mobile_services.dart';

class CustomerDetailScreen extends StatefulWidget {
  const CustomerDetailScreen({
    super.key,
    required this.services,
    required this.companyId,
  });

  final MobileServices services;
  final String companyId;

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late Future<Map<String, dynamic>> _detail;
  bool _pinning = false;

  @override
  void initState() {
    super.initState();
    _detail = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    if (!widget.services.config.hasSupabase) {
      return {
        'company': {'name': 'Müşteri'},
        'memory': null,
        'contacts': const [],
        'tasks': const [],
      };
    }
    return await widget.services.api.get('/api/customers/${widget.companyId}')
        as Map<String, dynamic>;
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Ne kaydedileceğini, basmadan önce açıkça söyler.
  ///
  /// Kaydedilen şey müşterinin konumudur; kullanıcının hareket geçmişi
  /// tutulmaz. Kullanıcının bunu bilmeden onaylaması istenmemelidir.
  Future<bool> _confirmPin(String companyName) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konumu buraya sabitle'),
        content: Text(
          '$companyName kaydına şu anki konumunuz müşterinin konumu olarak '
          'yazılacak. Böylece bu müşterinin yakınına geldiğinizde hatırlatma '
          'alabilirsiniz.\n\n'
          'Yalnızca müşterinin konumu saklanır; sizin hareketleriniz '
          'kaydedilmez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sabitle'),
          ),
        ],
      ),
    );
    return accepted ?? false;
  }

  Future<void> _pinLocation(String companyName) async {
    if (_pinning) return;
    if (!await _confirmPin(companyName)) return;
    if (!mounted) return;
    setState(() => _pinning = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _notify('Konum servisi kapalı.');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _notify('Konum izni verilmedi. Müşteri konumu kaydedilemedi.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      await widget.services.api.post(
        '/api/customers/${widget.companyId}/location',
        {'latitude': position.latitude, 'longitude': position.longitude},
      );
      if (!mounted) return;
      setState(() => _detail = _load());
      _notify('Müşteri konumu sabitlendi.');
    } catch (error) {
      _notify(error.toString());
    } finally {
      if (mounted) setState(() => _pinning = false);
    }
  }

  String _locationLabel(Map company) {
    final source = company['location_source']?.toString();
    if (source == 'pinned') return 'Konum sahada sabitlendi';
    if (source == 'geocoded') return 'Konum adresten tahmin edildi';
    return 'Konum kayıtlı değil — yakınlık hatırlatması çalışmaz';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Müşteri kartı')),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _detail,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                snapshot.error.toString(),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final data = snapshot.data!;
        final company = data['company'] as Map? ?? {};
        final memory = data['memory'] as Map?;
        final contacts = data['contacts'] as List? ?? [];
        final tasks = data['tasks'] as List? ?? [];
        final companyName = company['name']?.toString() ?? 'Firma';
        final hasLocation =
            company['latitude'] != null && company['longitude'] != null;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              companyName,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(company['address']?.toString() ?? ''),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasLocation
                              ? Icons.location_on_outlined
                              : Icons.location_off_outlined,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_locationLabel(company))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: _pinning
                          ? null
                          : () => _pinLocation(companyName),
                      icon: _pinning
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(
                        hasLocation
                            ? 'Konumu buradan güncelle'
                            : 'Konumu buraya sabitle',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Müşteri hafıza kartı',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      memory?['summary']?.toString() ??
                          'Onaylı hafıza kartı henüz oluşmadı.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'İlgili kişiler (${contacts.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ...contacts.map((item) {
              final value = item as Map;
              return ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(
                  '${value['first_name'] ?? ''} ${value['last_name'] ?? ''}',
                ),
                subtitle: Text(value['title']?.toString() ?? ''),
              );
            }),
            const Divider(),
            Text(
              'Açık görevler (${tasks.length})',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ...tasks.map(
              (item) => ListTile(
                leading: const Icon(Icons.task_alt),
                title: Text((item as Map)['title']?.toString() ?? 'Görev'),
              ),
            ),
          ],
        );
      },
    ),
  );
}
