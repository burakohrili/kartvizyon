import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../core/mobile_services.dart';

/// Saha modu: kullanıcının başlattığı, görünür çalışan yakınlık hatırlatması.
///
/// Uygulama tamamen kapalıyken bildirim göndermez — bunun için iOS'ta `Always`,
/// Android'de `ACCESS_BACKGROUND_LOCATION` gerekirdi ve ürün ilkesi
/// (`CLAUDE.md`: sürekli GPS takibi yapılmaz) buna izin vermiyor. Bunun yerine
/// vardiya boyunca çalışır: Android'de kalıcı bildirimli ön plan servisi,
/// iOS'ta mavi konum göstergesi. Kullanıcı her an durdurabilir ve süre
/// dolduğunda kendiliğinden kapanır.
///
/// Gerekçe ve reddedilen alternatifler: docs/product/decisions/0006-field-mode.md
class FieldModeService {
  FieldModeService(this.services, {FlutterLocalNotificationsPlugin? plugin})
    : _notifications = plugin ?? FlutterLocalNotificationsPlugin();

  final MobileServices services;
  final FlutterLocalNotificationsPlugin _notifications;

  /// Vardiya bu süre sonunda kendiliğinden kapanır.
  ///
  /// Unutulan bir oturumun gece boyu pil tüketmesini engeller; kullanıcı
  /// ertesi sabah "pilim bitmiş" diye uygulamayı silmemelidir.
  static const Duration sessionLimit = Duration(hours: 8);

  /// Bu saatten sonra saha modu açık kalmaz (yerel saat).
  static const int autoStopHour = 21;

  /// Sunucuya bu mesafeden az hareketlerde gidilmez.
  static const int movementThresholdMeters = 250;

  /// Bildirim yalnız bu yarıçap içindeki müşteri için üretilir.
  static const double notifyRadiusKm = 1.5;

  static const _nearbyChannelId = 'kartvizyon_nearby_customer';

  StreamSubscription<Position>? _positionSubscription;
  Timer? _sessionTimer;
  DateTime? _startedAt;

  /// Oturum içinde aynı müşteri tekrar bildirilmez.
  ///
  /// Sunucu da 24 saatlik kilit uygular (`geofence_events`); bu istemci tarafı
  /// koruma, aynı sokakta ileri geri geçerken oluşacak tekrarları önler.
  final Set<String> _notifiedCompanyIds = <String>{};

  final ValueNotifier<bool> isActive = ValueNotifier<bool>(false);
  final ValueNotifier<String?> lastMessage = ValueNotifier<String?>(null);

  DateTime? get startedAt => _startedAt;

  /// Karttaki "… kapanacak" saati. Oturum akşam kapanışında da bitebildiği
  /// için sekiz saatlik sınırı doğrudan yazmak yanlış saat gösterir: 16:00'da
  /// başlayan oturum gerçekte 21:00'de kapanırken kart 00:00 diyordu.
  DateTime? get endsAt {
    final startedAt = _startedAt;
    if (startedAt == null) return null;
    return sessionEndFor(startedAt);
  }

  /// Yerel başlangıç için kesin kapanış anı.
  ///
  /// Akşam sınırı geçmişse başlangıç anını döndürür; start bu durumda modu
  /// açmaz. Önceki hesap, 21.00'den sonra akşam sınırını yok sayıp sekiz saat
  /// eklediği için unutulan mod ertesi sabaha kadar açık kalabiliyordu.
  @visibleForTesting
  static DateTime sessionEndFor(DateTime startedAt) {
    final evening = DateTime(
      startedAt.year,
      startedAt.month,
      startedAt.day,
      autoStopHour,
    );
    if (!startedAt.isBefore(evening)) return startedAt;
    final durationLimit = startedAt.add(sessionLimit);
    return durationLimit.isBefore(evening) ? durationLimit : evening;
  }

  Future<void> initialise() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _notifications.initialize(settings);
  }

  /// Bildirim iznini saha modu başlarken ister — onboarding'de topluca değil.
  Future<bool> _ensureNotificationPermission() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final apple = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (apple != null) {
      return await apple.requestPermissions(alert: true, sound: true) ?? false;
    }
    return true;
  }

  Future<bool> _ensureLocationPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      lastMessage.value = 'Konum servisi kapalı.';
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      lastMessage.value =
          'Konum izni verilmedi. Saha modu yerine Harita ekranından '
          '"Yakınımdakileri bul" diyebilirsiniz.';
      return false;
    }
    return true;
  }

  LocationSettings _locationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: movementThresholdMeters,
        // Kalıcı bildirim, servisin çalıştığını kullanıcıdan gizlemez.
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'KartVizyon saha modu açık',
          notificationText:
              'Yakınındaki müşterileri hatırlatıyor. Durdurmak için dokunun.',
          notificationChannelName: 'Saha modu',
          enableWakeLock: false,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: movementThresholdMeters,
        allowBackgroundLocationUpdates: true,
        // Mavi konum çubuğu görünür kalır; kullanıcıdan gizli arka plan
        // konumu alınmaz. Always yetkisi istenmediği için bu zorunludur.
        showBackgroundLocationIndicator: true,
        pauseLocationUpdatesAutomatically: false,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.medium,
      distanceFilter: movementThresholdMeters,
    );
  }

  Future<bool> start() async {
    if (isActive.value) return true;
    final startedAt = DateTime.now();
    final endAt = sessionEndFor(startedAt);
    if (!endAt.isAfter(startedAt)) {
      lastMessage.value =
          'Saha modu saat 21.00’den sonra başlatılamaz. '
          'Yarın çalışma saatinde yeniden deneyin.';
      return false;
    }
    if (!await _ensureLocationPermission()) return false;
    if (!await _ensureNotificationPermission()) {
      lastMessage.value =
          'Bildirim izni verilmedi; saha modu hatırlatma gönderemez.';
      return false;
    }

    _startedAt = startedAt;
    _notifiedCompanyIds.clear();
    isActive.value = true;
    lastMessage.value = null;

    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: _locationSettings(),
        ).listen(
          _onPosition,
          onError: (Object error) {
            lastMessage.value = error.toString();
          },
        );

    _sessionTimer = Timer(endAt.difference(startedAt), () {
      stop(reason: 'Saha modu süre dolduğu için kapandı.');
    });
    _markSentryState(true);
    return true;
  }

  /// Saha modunun açık olduğunu Sentry olaylarına iliştir.
  ///
  /// 25 Ağustos 2026'da iOS'ta bir `WatchdogTermination` düştü (sürüm
  /// `1.0.0+46`). Bu olay gözlemlenmez, **çıkarsanır**: çökme raporu yoktur,
  /// SDK yalnız "uygulama temiz kapanmadı" durumundan tahmin eder. Elimizdeki
  /// tek olayla sebebini söylemek mümkün değil.
  ///
  /// Saha modu, uygulamayı iOS'ta saatlerce arka planda canlı tutabilen tek
  /// yerimiz (`UIBackgroundModes: location`, `allowBackgroundLocationUpdates`,
  /// `pauseLocationUpdatesAutomatically: false`). iOS belleği önce arka plan
  /// uygulamalarından geri alır. Bu yüzden bir sonraki olayda modun açık olup
  /// olmadığını bilmek, tahmin etmekle ölçmek arasındaki farkı yaratır.
  ///
  /// Yalnız açık/kapalı bilgisi ve süre gider; konum gitmez.
  void _markSentryState(bool active) {
    Sentry.configureScope((scope) {
      scope.setTag('field_mode.active', active.toString());
    });
    Sentry.addBreadcrumb(
      Breadcrumb(
        category: 'field_mode',
        message: active ? 'saha modu başladı' : 'saha modu durdu',
        level: SentryLevel.info,
        data: {
          if (active && _startedAt != null)
            'endsAt': endsAt?.toIso8601String() ?? 'bilinmiyor',
        },
      ),
    );
  }

  Future<void> stop({String? reason}) async {
    if (!isActive.value) return;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _startedAt = null;
    isActive.value = false;
    _markSentryState(false);
    if (reason != null) lastMessage.value = reason;
  }

  Future<void> _onPosition(Position position) async {
    try {
      final response =
          await services.api.get(
                '/api/geofence/candidates'
                '?workspaceId=${services.workspaceId}'
                '&latitude=${position.latitude}'
                '&longitude=${position.longitude}'
                '&maxDistanceKm=$notifyRadiusKm',
              )
              as Map<String, dynamic>;
      final candidates = List<Map<String, dynamic>>.from(
        response['data'] as List? ?? const [],
      );
      if (candidates.isEmpty) return;

      final candidate = candidates.first;
      final companyId = candidate['id']?.toString();
      if (companyId == null || _notifiedCompanyIds.contains(companyId)) return;
      _notifiedCompanyIds.add(companyId);

      await _notifyNearby(candidate);
      await recordOutcome(candidate, 'shown');
    } catch (error) {
      // Saha modu ağ hatasında sessizce devam eder; vardiyayı bölmez.
      lastMessage.value = error.toString();
    }
  }

  String describeCandidate(Map<String, dynamic> candidate) {
    final distanceKm = (candidate['distanceKm'] as num?)?.toDouble() ?? 0;
    final distance = distanceKm < 1
        ? '${(distanceKm * 1000).round()} m'
        : '${distanceKm.toStringAsFixed(1)} km';
    final days = candidate['daysSinceVisit'] as int?;
    final visit = days == null
        ? 'Henüz ziyaret edilmedi'
        : 'Son ziyaret $days gün önce';
    final overdue = (candidate['overdueTaskCount'] as num?)?.toInt() ?? 0;
    final follow = overdue > 0 ? ' · $overdue geciken takip' : '';
    return '$distance uzakta · $visit$follow';
  }

  Future<void> _notifyNearby(Map<String, dynamic> candidate) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _nearbyChannelId,
        'Yakındaki müşteri',
        channelDescription:
            'Saha modu açıkken yakınındaki müşteriyi hatırlatır.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _notifications.show(
      candidate['id'].hashCode,
      candidate['name']?.toString() ?? 'Yakındaki müşteri',
      describeCandidate(candidate),
      details,
      payload: candidate['id']?.toString(),
    );
  }

  /// `geofence_events` tablosuna sonucu yazar.
  ///
  /// 24 saatlik tekrar kilidi bu kayıtlara dayandığı için `shown` yazılmazsa
  /// aynı müşteri ertesi gün yine bildirilir.
  Future<void> recordOutcome(
    Map<String, dynamic> candidate,
    String outcome,
  ) async {
    try {
      final priority = candidate['priority'] as Map?;
      final distanceKm = (candidate['distanceKm'] as num?)?.toDouble() ?? 0;
      await services.api.post('/api/geofence/events', {
        'workspaceId': services.workspaceId,
        'organizationId': services.organizationId,
        'companyId': candidate['id'],
        'priorityScore': ((priority?['total'] as num?)?.toInt() ?? 0).clamp(
          0,
          100,
        ),
        'distanceMeters': (distanceKm * 1000).round(),
        'outcome': outcome,
      });
    } catch (_) {
      // Ölçüm kaybı vardiyayı durdurmaz.
    }
  }

  void dispose() {
    _positionSubscription?.cancel();
    _sessionTimer?.cancel();
    isActive.dispose();
    lastMessage.dispose();
  }
}
