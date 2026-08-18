import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/mobile_services.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.services});
  final MobileServices services;
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool busy = false;
  String? message;
  List<Map<String, dynamic>> candidates = const [];

  void _updateState(VoidCallback callback) {
    if (!mounted) return;
    setState(callback);
  }

  Future<void> locate() async {
    _updateState(() {
      busy = true;
      message = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _updateState(() => message = 'Konum servisi kapalı.');
        return;
      }
      if (!mounted) return;

      var permission = await Geolocator.checkPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _updateState(
          () => message =
              'Konum izni verilmedi. Uygulama sürekli konum takibi yapmaz.',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
      if (!mounted) return;

      if (!widget.services.config.hasSupabase) {
        _updateState(() {
          message =
              'Sunucu bağlantısı yapılandırılmadığı için müşteri aranamadı.';
          candidates = const [];
        });
        return;
      }

      final result =
          await widget.services.api.get(
                '/api/geofence/candidates?workspaceId=${widget.services.workspaceId}&latitude=${position.latitude}&longitude=${position.longitude}',
              )
              as Map<String, dynamic>;
      _updateState(() {
        candidates = List<Map<String, dynamic>>.from(
          result['data'] as List? ?? [],
        );
        message =
            'Konum yalnızca aday hesaplamak için kullanıldı; sunucuda saklanmadı.';
      });
    } catch (_) {
      _updateState(() => message = 'Konum alınamadı. Lütfen tekrar deneyin.');
    } finally {
      _updateState(() => busy = false);
    }
  }

  Future<void> navigate(Map<String, dynamic> item) => launchUrl(
    Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${item['latitude']},${item['longitude']}',
    ),
    mode: LaunchMode.externalApplication,
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Yakındaki müşteriler')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Sürekli GPS kullanılmaz. Konum yalnızca siz istediğinizde yakın ve gecikmiş müşterileri hesaplamak için alınır.',
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: busy ? null : locate,
                  icon: const Icon(Icons.my_location),
                  label: Text(busy ? 'Hesaplanıyor…' : 'Yakınımdakileri bul'),
                ),
              ],
            ),
          ),
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(message!),
          ),
        ...candidates.map((item) {
          final priority = item['priority'] as Map?;
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Text('${priority?['total'] ?? 0}')),
              title: Text(item['name']?.toString() ?? 'Firma'),
              subtitle: Text(
                '${item['address'] ?? ''}\n${(item['distanceKm'] as num? ?? 0).toStringAsFixed(1)} km',
              ),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.navigation_outlined),
                tooltip: 'Navigasyonu aç',
                onPressed: () => navigate(item),
              ),
            ),
          );
        }),
      ],
    ),
  );
}
