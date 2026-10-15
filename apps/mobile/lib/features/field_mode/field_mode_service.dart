import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Locale;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../core/mobile_services.dart';
import '../../l10n/app_localizations.dart';

enum FieldModeMessage {
  locationServiceOff,
  locationPermission,
  afterHours,
  notificationPermission,
  locationUnavailable,
  sessionExpired,
  accessRequired,
  startFailed,
  locationCheckFailed,
  nearbyCustomersUpdateFailed,
  sessionEnded,
  stopped,
  workspaceChanged,
}

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
  FieldModeService(
    this.services, {
    FlutterLocalNotificationsPlugin? plugin,
    Future<bool> Function()? notificationPermissionCheck,
    DateTime Function()? now,
  }) : _notifications = plugin ?? FlutterLocalNotificationsPlugin(),
       _notificationPermissionCheck = notificationPermissionCheck,
       _now = now ?? DateTime.now;

  final MobileServices services;
  final FlutterLocalNotificationsPlugin _notifications;
  final Future<bool> Function()? _notificationPermissionCheck;
  final DateTime Function() _now;
  String _localeCode = 'tr';

  void setLocale(String languageCode) {
    _localeCode = languageCode == 'en' ? 'en' : 'tr';
  }

  /// Vardiya bu süre sonunda kendiliğinden kapanır.
  ///
  /// Unutulan bir oturumun gece boyu pil tüketmesini engeller; kullanıcı
  /// ertesi sabah "pilim bitmiş" diye uygulamayı silmemelidir.
  static const Duration sessionLimit = Duration(hours: 8);

  /// Bu saatten sonra saha modu açık kalmaz (yerel saat).
  static const int autoStopHour = 21;

  /// Sunucuya bu mesafeden az hareketlerde gidilmez.
  static const int movementThresholdMeters = 250;

  /// Sabit dururken konum akışı yeni nokta üretmeyebilir; açık vardiyada
  /// konumu seyrek olarak tekrar kontrol et.
  static const Duration stationaryCheckInterval = Duration(minutes: 5);
  static const Duration minimumCandidateCheckInterval = Duration(minutes: 2);

  /// Bildirim yalnız bu yarıçap içindeki müşteri için üretilir.
  static const double notifyRadiusKm = 1.5;

  static const _nearbyChannelId = 'kartvizyon_nearby_customer';

  StreamSubscription<Position>? _positionSubscription;
  bool _starting = false;
  Timer? _sessionTimer;
  Timer? _stationaryCheckTimer;
  DateTime? _startedAt;
  DateTime? _lastCandidateCheckAt;
  bool _candidateCheckInFlight = false;
  bool _currentPositionInFlight = false;

  /// Oturum içinde aynı müşteri tekrar bildirilmez.
  ///
  /// Sunucu da 24 saatlik kilit uygular (`geofence_events`); bu istemci tarafı
  /// koruma, aynı sokakta ileri geri geçerken oluşacak tekrarları önler.
  final Set<String> _notifiedCompanyIds = <String>{};

  final ValueNotifier<bool> isActive = ValueNotifier<bool>(false);
  final ValueNotifier<FieldModeMessage?> lastMessage =
      ValueNotifier<FieldModeMessage?>(null);

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

  /// Saha modu, yerel kapanış saatinden sonra başlatılamaz.
  static bool canStartAt(DateTime now) => sessionEndFor(now).isAfter(now);

  Future<void> initialise() async {
    await services.reminders.initialise();
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
      lastMessage.value = FieldModeMessage.locationServiceOff;
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      lastMessage.value = FieldModeMessage.locationPermission;
      return false;
    }
    return true;
  }

  LocationSettings _locationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final english = _localeCode == 'en';
      return AndroidSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: movementThresholdMeters,
        // Kalıcı bildirim, servisin çalıştığını kullanıcıdan gizlemez.
        foregroundNotificationConfig: ForegroundNotificationConfig(
          notificationTitle: english
              ? 'KartVizyon Field Mode is on'
              : 'KartVizyon saha modu açık',
          notificationText: english
              ? 'Reminding you about nearby customers. Tap to stop.'
              : 'Yakınındaki müşterileri hatırlatıyor. Durdurmak için dokunun.',
          notificationChannelName: english ? 'Field Mode' : 'Saha modu',
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
    if (_starting) return false;
    _starting = true;
    try {
      // İlk konum akışı açılmadan gerçek oturum ve aktif workspace doğrulanır.
      // Önbellekteki yazma hakkı, ağ/oturum hatasını gizlememelidir.
      await services.refreshContext(force: true);
      await services.requireWriteAccess();
      final startedAt = _now();
      final endAt = sessionEndFor(startedAt);
      if (!endAt.isAfter(startedAt)) {
        lastMessage.value = FieldModeMessage.afterHours;
        return false;
      }
      // Ortak local-notification platformu ve tap callback'i bir kez kurulur.
      // Yakınlık kanalı ayrı kalır; reminder kanalını değiştirmez.
      if (_notificationPermissionCheck == null) {
        await services.reminders.initialise();
      }
      if (!await _ensureLocationPermission()) return false;
      if (!await (_notificationPermissionCheck?.call() ??
          _ensureNotificationPermission())) {
        lastMessage.value = FieldModeMessage.notificationPermission;
        return false;
      }
      var streamFailed = false;
      final subscription =
          Geolocator.getPositionStream(
            locationSettings: _locationSettings(),
          ).listen(
            _onPosition,
            onError: (Object _) {
              streamFailed = true;
              unawaited(stop(reason: FieldModeMessage.locationUnavailable));
            },
          );
      if (streamFailed) {
        await subscription.cancel();
        lastMessage.value = FieldModeMessage.locationUnavailable;
        return false;
      }
      _positionSubscription = subscription;
      _startedAt = startedAt;
      _notifiedCompanyIds.clear();
      _lastCandidateCheckAt = null;
      isActive.value = true;
      lastMessage.value = null;
      unawaited(services.reminders.cancelTodayMorningReminder());
      _sessionTimer = Timer(endAt.difference(startedAt), () {
        unawaited(stop(reason: FieldModeMessage.sessionEnded));
      });
      _stationaryCheckTimer = Timer.periodic(stationaryCheckInterval, (_) {
        unawaited(checkCurrentLocation());
      });
      // Konum akışının ilk değişikliğini bekleme: kullanıcı sahada zaten
      // müşterinin yanındayken modu açmış olabilir.
      unawaited(checkCurrentLocation(force: true));
      _markSentryState(true);
      return true;
    } on MobileApiException catch (error) {
      lastMessage.value = error.statusCode == 402
          ? FieldModeMessage.accessRequired
          : error.statusCode == 401
          ? FieldModeMessage.sessionExpired
          : FieldModeMessage.startFailed;
      return false;
    } catch (_) {
      lastMessage.value = FieldModeMessage.startFailed;
      return false;
    } finally {
      _starting = false;
    }
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
    try {
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
    } catch (_) {
      // Telemetri başlatılamadıysa saha servisini yarı açık bırakma.
    }
  }

  Future<void> stop({FieldModeMessage? reason}) async {
    if (!isActive.value) return;
    try {
      await _positionSubscription?.cancel();
    } catch (_) {
      // Platform servisi kapanmış olabilir; yerel durum yine temizlenir.
    }
    _positionSubscription = null;
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _stationaryCheckTimer?.cancel();
    _stationaryCheckTimer = null;
    _startedAt = null;
    _lastCandidateCheckAt = null;
    isActive.value = false;
    _markSentryState(false);
    if (reason != null) lastMessage.value = reason;
  }

  Future<void> _onPosition(Position position) => _checkCandidates(position);

  /// Uygulama arka plandan dönünce çağrılır; force yalnız zaman aralığı
  /// sınırını aşar, aynı anda çalışan sorguları yine birleştirir.
  Future<void> checkCurrentLocation({bool force = false}) async {
    if (!isActive.value ||
        _candidateCheckInFlight ||
        _currentPositionInFlight) {
      return;
    }
    final lastCheck = _lastCandidateCheckAt;
    if (!force &&
        lastCheck != null &&
        _now().difference(lastCheck) < minimumCandidateCheckInterval) {
      return;
    }
    _currentPositionInFlight = true;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 12),
        ),
      );
      await _checkCandidates(position, force: force);
    } catch (_) {
      // Arka plan/ilk konum edinimi geçici olarak başarısız olabilir. Saha
      // modu kapanmaz; konum akışı veya sonraki zamanlanmış kontrol dener.
      if (isActive.value) {
        lastMessage.value = FieldModeMessage.locationCheckFailed;
      }
    } finally {
      _currentPositionInFlight = false;
    }
  }

  Future<void> onAppResumed() => checkCurrentLocation(force: true);

  Future<void> _checkCandidates(Position position, {bool force = false}) async {
    if (!isActive.value || _candidateCheckInFlight) return;
    final lastCheck = _lastCandidateCheckAt;
    if (!force &&
        lastCheck != null &&
        _now().difference(lastCheck) < minimumCandidateCheckInterval) {
      return;
    }
    _candidateCheckInFlight = true;
    _lastCandidateCheckAt = _now();
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
      lastMessage.value = null;
      if (candidates.isEmpty) return;

      final candidate = candidates.first;
      final companyId = candidate['id']?.toString();
      if (companyId == null || _notifiedCompanyIds.contains(companyId)) return;

      await _notifyNearby(candidate);
      // Yalnız bildirim gerçekten gösterildiyse oturum içi tekrarları engelle.
      // Platform bildirimi hata verirse sonraki konum kontrolü yeniden dener.
      _notifiedCompanyIds.add(companyId);
      await recordOutcome(candidate, 'shown');
    } catch (_) {
      // Saha modu ağ hatasında sessizce devam eder; vardiyayı bölmez.
      lastMessage.value = FieldModeMessage.nearbyCustomersUpdateFailed;
    } finally {
      _candidateCheckInFlight = false;
    }
  }

  String describeCandidate(
    Map<String, dynamic> candidate,
    AppLocalizations strings,
  ) {
    final distanceKm = (candidate['distanceKm'] as num?)?.toDouble() ?? 0;
    final distance = distanceKm < 1
        ? '${(distanceKm * 1000).round()} m'
        : '${distanceKm.toStringAsFixed(1).replaceAll('.', _localeCode == 'en' ? '.' : ',')} km';
    final days = candidate['daysSinceVisit'] as int?;
    final visit = days == null
        ? strings.notVisitedYet
        : strings.lastVisitedDays(days);
    final overdue = (candidate['overdueTaskCount'] as num?)?.toInt() ?? 0;
    final follow = overdue > 0
        ? ' · ${strings.overdueFollowUpCount(overdue)}'
        : '';
    return '${strings.distanceAway(distance)} · $visit$follow';
  }

  Future<void> _notifyNearby(Map<String, dynamic> candidate) async {
    final strings = await AppLocalizations.delegate.load(Locale(_localeCode));
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _nearbyChannelId,
        strings.fieldModeNotificationChannel,
        channelDescription: strings.fieldModeNotificationDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _notifications.show(
      candidate['id'].hashCode,
      candidate['name']?.toString() ?? strings.fieldModeReminderTitle,
      describeCandidate(candidate, strings),
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
