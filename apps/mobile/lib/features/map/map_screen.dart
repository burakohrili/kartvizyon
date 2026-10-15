import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/mobile_services.dart';
import '../../l10n/app_localizations.dart';

String formatNearbyDistance(num? distanceKm, {String locale = 'tr'}) {
  if (distanceKm == null || !distanceKm.toDouble().isFinite) {
    return locale == 'en' ? 'Distance unavailable' : 'Mesafe bilinmiyor';
  }
  final distance = distanceKm.toDouble();
  if (distance < 1) return '${(distance * 1000).round()} m';
  final formatted = distance.toStringAsFixed(1);
  return '${locale == 'en' ? formatted : formatted.replaceAll('.', ',')} km';
}

String nearbyVisitLabel(
  Map<String, dynamic> candidate, {
  String locale = 'tr',
}) {
  final days = candidate['daysSinceVisit'] as int?;
  return days == null
      ? (locale == 'en' ? 'Not visited yet' : 'Henüz ziyaret edilmedi')
      : locale == 'en'
      ? 'Last visit: $days days ago'
      : 'Son ziyaret: $days gün önce';
}

String nearbyTaskLabel(Map<String, dynamic> candidate, {String locale = 'tr'}) {
  final count = (candidate['overdueTaskCount'] as num?)?.toInt() ?? 0;
  return count > 0
      ? (locale == 'en' ? '$count overdue tasks' : '$count geciken görev')
      : (locale == 'en' ? 'No overdue tasks' : 'Geciken görev yok');
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
    final l10n = AppLocalizations.of(context)!;
    if (!await Geolocator.isLocationServiceEnabled()) {
      _updateState(() => message = l10n.locationServiceOff);
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
      _updateState(() => message = l10n.nearbyLocationPermission);
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
      _updateState(() => message = l10n.locationUnavailable);
      return null;
    }
  }

  Future<void> locate() async {
    final l10n = AppLocalizations.of(context)!;
    _updateState(() {
      busy = true;
      message = null;
    });
    try {
      final position = await _currentPosition();
      if (position == null || !mounted) return;

      if (!widget.services.config.hasSupabase) {
        _updateState(() {
          message = l10n.serverNotConfigured;
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
          message = l10n.locationNotStored;
        });
      } catch (_) {
        _updateState(() => message = l10n.nearbyFetchFailed);
      }
    } catch (_) {
      _updateState(() => message = l10n.locationSettingsRetry);
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.nearbyCustomersTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.mapLocationPrivacy),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: busy ? null : locate,
                    icon: const Icon(Icons.my_location),
                    label: Text(
                      busy ? l10n.findingNearby : l10n.findNearbyCustomers,
                    ),
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
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(l10n.noCustomersInArea),
            ),
          ...candidates.map((item) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name']?.toString() ?? l10n.companyFallback,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatNearbyDistance(
                        item['distanceKm'] as num?,
                        locale: locale,
                      ),
                    ),
                    if ((item['address']?.toString() ?? '').isNotEmpty)
                      Text(
                        item['address'].toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Text(nearbyVisitLabel(item, locale: locale)),
                    Text(nearbyTaskLabel(item, locale: locale)),
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
                          label: Text(l10n.briefing),
                        ),
                        TextButton.icon(
                          onPressed: () => navigate(item),
                          icon: const Icon(Icons.navigation_outlined),
                          label: Text(l10n.navigation),
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
}
