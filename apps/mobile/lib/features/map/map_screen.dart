import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/mobile_services.dart';

String formatNearbyDistance(num? distanceKm) {
  if (distanceKm == null || !distanceKm.toDouble().isFinite) {
    return 'Mesafe bilinmiyor';
  }
  final distance = distanceKm.toDouble();
  if (distance < 1) return '${(distance * 1000).round()} m';
  return '${distance.toStringAsFixed(1).replaceAll('.', ',')} km';
}

String nearbyVisitLabel(Map<String, dynamic> candidate) {
  final days = candidate['daysSinceVisit'] as int?;
  return days == null
      ? 'Henüz ziyaret edilmedi'
      : 'Son ziyaret: $days gün önce';
}

String nearbyTaskLabel(Map<String, dynamic> candidate) {
  final count = (candidate['overdueTaskCount'] as num?)?.toInt() ?? 0;
  return count > 0 ? '$count geciken görev' : 'Geciken görev yok';
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.services});
  final MobileServices services;
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool busy = false;
  String? message;
  bool searched = false;
  List<Map<String, dynamic>> candidates = const [];

  void _updateState(VoidCallback callback) {
    if (!mounted) return;
    setState(callback);
  }

  /// Konumu alır; alınamazsa sebebini söyleyip `null` döner.
  ///
  /// Konum alma ile müşteri çekme ayrı tutulur. Önce ikisi tek bir `catch (_)`
  /// içindeydi: sunucudan gelen 401 ya da 400 de "Konum alınamadı" olarak
  /// görünüyordu ve kullanıcı konum izniyle uğraşırken sorun bambaşka yerdeydi.
  Future<Position?> _currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _updateState(
        () => message = 'Konum servisi kapalı. Cihaz ayarlarından açın.',
      );
      return null;
    }
    if (!mounted) return null;

    var permission = await Geolocator.checkPermission();
    if (!mounted) return null;
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (!mounted) return null;
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _updateState(
        () => message =
            'Yakındaki müşterileri göstermek için konum izni gerekiyor. '
            'Müşterilerinizi konum kullanmadan da arayabilirsiniz.',
      );
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        // Süre sınırı yoktu; kapalı alanda soğuk GPS denemesi ekranı
        // süresiz "Hesaplanıyor…" durumunda bırakabiliyordu.
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
    } catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) return last;
      _updateState(
        () => message =
            'Konum alınamadı. Açık alanda tekrar deneyin ya da müşteri '
            'kartından "konumu buraya sabitle" seçeneğini kullanın.',
      );
      return null;
    }
  }

  Future<void> locate() async {
    _updateState(() {
      busy = true;
      message = null;
    });
    try {
      final position = await _currentPosition();
      if (position == null || !mounted) return;

      if (!widget.services.config.hasSupabase) {
        _updateState(() {
          message =
              'Sunucu bağlantısı yapılandırılmadığı için müşteri aranamadı.';
          candidates = const [];
        });
        return;
      }

      try {
        // Diğer veri ekranlarının hepsi bunu yapıyor; harita yapmıyordu ve
        // eski bir çalışma alanı kimliğiyle 400 alabiliyordu.
        await widget.services.refreshContext();
        final result =
            await widget.services.api.get(
                  '/api/geofence/candidates?workspaceId=${widget.services.workspaceId}&latitude=${position.latitude}&longitude=${position.longitude}&sort=distance',
                )
                as Map<String, dynamic>;
        _updateState(() {
          candidates =
              List<Map<String, dynamic>>.from(result['data'] as List? ?? [])
                ..sort(
                  (a, b) =>
                      ((a['distanceKm'] as num?)?.toDouble() ?? double.infinity)
                          .compareTo(
                            (b['distanceKm'] as num?)?.toDouble() ??
                                double.infinity,
                          ),
                );
          searched = true;
          message =
              'Konum yalnızca aday hesaplamak için kullanıldı; sunucuda saklanmadı.';
        });
      } catch (error) {
        _updateState(
          () => message = error is MobileApiException
              ? error.message
              : 'Yakındaki müşteriler getirilemedi. Tekrar deneyin.',
        );
      }
    } catch (_) {
      _updateState(
        () => message =
            'Konum alınamadı. Konum ayarlarınızı kontrol edip tekrar deneyin.',
      );
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
        if (searched && candidates.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('Bu bölgede kayıtlı müşteri bulunamadı.'),
          ),
        ...candidates.map((item) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name']?.toString() ?? 'Firma',
                    style: Theme.of(context).textTheme.titleMedium,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(formatNearbyDistance(item['distanceKm'] as num?)),
                  if ((item['address']?.toString() ?? '').isNotEmpty)
                    Text(
                      item['address'].toString(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Text(nearbyVisitLabel(item)),
                  Text(nearbyTaskLabel(item)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: item['id'] == null
                            ? null
                            : () => context.push('/briefings/${item['id']}'),
                        icon: const Icon(Icons.summarize_outlined),
                        label: const Text('Brifing'),
                      ),
                      TextButton.icon(
                        onPressed: () => navigate(item),
                        icon: const Icon(Icons.navigation_outlined),
                        label: const Text('Navigasyon'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    ),
  );
}
