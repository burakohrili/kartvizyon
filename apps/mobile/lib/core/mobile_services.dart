import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/local/app_database.dart';
import '../data/secure_session_store.dart';
import '../data/sync_engine.dart';
import '../data/sync_queue_repository.dart';
import '../features/field_mode/field_mode_service.dart';
import '../features/notifications/reminder_notification_service.dart';

class MobileConfig {
  const MobileConfig({
    required this.apiBaseUrl,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.sentryDsn,
    this.revenueCatAppleApiKey = '',
    this.revenueCatGoogleApiKey = '',
  });

  factory MobileConfig.fromEnvironment() => const MobileConfig(
    apiBaseUrl: String.fromEnvironment(
      'KARTVIZYON_API_URL',
      defaultValue: 'https://app.kartvizyon.app',
    ),
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    sentryDsn: String.fromEnvironment('SENTRY_DSN'),
    revenueCatAppleApiKey: String.fromEnvironment(
      'REVENUECAT_APPLE_PUBLIC_API_KEY',
    ),
    revenueCatGoogleApiKey: String.fromEnvironment(
      'REVENUECAT_GOOGLE_PUBLIC_API_KEY',
    ),
  );

  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String sentryDsn;
  final String revenueCatAppleApiKey;
  final String revenueCatGoogleApiKey;
  bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

class MobileApiClient {
  MobileApiClient({
    required this.baseUrl,
    required this.sessions,
    this.accessTokenProvider,
    this.refreshAccessToken,
    this.onSessionExpired,
    this.workspaceId,
    this.timeout = const Duration(seconds: 20),
    this.fileTimeout = const Duration(seconds: 60),
    http.Client? client,
  }) : client = client ?? http.Client();

  final Uri baseUrl;
  final SecureSessionStore sessions;
  final Future<String?> Function()? accessTokenProvider;
  final Future<String?> Function()? refreshAccessToken;

  /// Oturum yenilemeyle de kurtarılamadığında çağrılır.
  ///
  /// Yönlendirici açılışta bir kez `authenticated` hesaplıyor ve bunu yalnız
  /// menüden çıkış yapılınca değiştiriyordu. Supabase oturumu cihazda kalıcı
  /// olduğu için, kayıtlı oturum ölmüşse uygulama kendini "girişli" sanıp
  /// Bugün ekranını açıyor, oradaki her istek 401 dönüyor ve kullanıcı
  /// "Oturum gerekli. (HTTP 401)" ekranında kilitleniyordu — giriş ekranına,
  /// yani Google ve Apple düğmelerine, hiçbir yoldan ulaşamadan.
  final VoidCallback? onSessionExpired;

  /// Aktif çalışma alanı; her isteğe başlık olarak eklenir.
  ///
  /// Değer `MobileServices` üzerinde `refreshContext()` ile değiştiği için
  /// kopyalanmaz, çağrıyla okunur.
  final String? Function()? workspaceId;

  /// Sıradan istek için üst sınır.
  ///
  /// Daha önce hiç zaman aşımı yoktu: takılan bir istek, tamamen hareketsiz
  /// görünen bir ekran olarak sonsuza kadar bekliyordu. Kullanıcı bunu
  /// "hiçbir şey olmuyor, hata var galiba" diye bildirdi.
  final Duration timeout;

  /// Dosya yüklemesi için ayrı ve daha uzun sınır; kartvizit OCR'ı ve ses
  /// transkripsiyonu modelde gerçekten saniyeler sürer.
  final Duration fileTimeout;
  final http.Client client;

  Future<String?> _accessToken() async {
    final provided = await accessTokenProvider?.call();
    if (provided != null && provided.isNotEmpty) return provided;
    final session = await sessions.read();
    return session?.accessToken;
  }

  Map<String, String> _headersFor(String? accessToken) {
    final workspace = workspaceId?.call();
    return {
      'accept': 'application/json',
      'content-type': 'application/json',
      if (accessToken != null) 'authorization': 'Bearer $accessToken',
      // Sunucu çalışma alanını çerezden okuyor; mobil istemci çerez
      // göndermediği için "RLS'in gösterdiği ilk çalışma alanı"na düşüyordu.
      if (workspace != null && workspace.isNotEmpty)
        'x-kartvizyon-workspace': workspace,
    };
  }

  bool _isAuthenticationFailure(http.Response response) {
    if (response.statusCode != 401) return false;
    try {
      final body = jsonDecode(response.body);
      if (body is! Map) return false;
      final code = body['code']?.toString();
      final message = body['error']?.toString();
      return code == 'bad_jwt' ||
          code == 'session_not_found' ||
          code == 'session_expired' ||
          message == 'Oturum gerekli.';
    } catch (_) {
      return false;
    }
  }

  Future<http.Response> _send(
    String path,
    Future<http.Response> Function(Map<String, String> headers) request, {
    Duration? limit,
  }) async {
    Future<http.Response> attempt(Map<String, String> headers) =>
        request(headers).timeout(
          limit ?? timeout,
          onTimeout: () {
            const failure = MobileApiException(
              408,
              'Sunucu zamanında yanıt vermedi. Bağlantınızı kontrol edip '
              'tekrar deneyin.',
            );
            // Zaman aşımı yanıt üretmediği için `_decode` yolundan geçmez;
            // bildirilmezse yavaş uç hiçbir yerde görünmez.
            _capture(failure, path: path);
            throw failure;
          },
        );

    var response = await attempt(_headersFor(await _accessToken()));
    if (!_isAuthenticationFailure(response) || refreshAccessToken == null) {
      return response;
    }
    final refreshedToken = await refreshAccessToken!.call();
    if (refreshedToken == null || refreshedToken.isEmpty) {
      onSessionExpired?.call();
      return response;
    }
    response = await attempt(_headersFor(refreshedToken));
    // Taze token da 401 alıyorsa yenilenecek bir şey kalmamıştır; kullanıcı
    // yeniden giriş yapmalı ve bunu ona söyleyebilmeliyiz.
    if (_isAuthenticationFailure(response)) onSessionExpired?.call();
    return response;
  }

  Future<dynamic> get(String path) async {
    final response = await _send(
      path,
      (headers) => client.get(baseUrl.resolve(path), headers: headers),
    );
    return _decode(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final encodedBody = jsonEncode(body);
    final response = await _send(
      path,
      (headers) => client.post(
        baseUrl.resolve(path),
        headers: headers,
        body: encodedBody,
      ),
    );
    return _decode(response);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final encodedBody = jsonEncode(body);
    final response = await _send(
      path,
      (headers) => client.patch(
        baseUrl.resolve(path),
        headers: headers,
        body: encodedBody,
      ),
    );
    return _decode(response);
  }

  Future<dynamic> postFile(
    String path, {
    required String field,
    required String filePath,
    Map<String, String> fields = const {},
    MediaType? contentType,
  }) async {
    Future<http.Response> sendFile(Map<String, String> headers) async {
      final request = http.MultipartRequest('POST', baseUrl.resolve(path));
      request.headers.addAll(headers);
      // MultipartRequest sınır (boundary) içeren doğru Content-Type değerini
      // kendisi üretir. JSON istemcinin varsayılan başlığı bunu bozmamalı.
      request.headers.remove('content-type');
      request.fields.addAll(fields);
      request.files.add(
        await http.MultipartFile.fromPath(
          field,
          filePath,
          contentType: contentType,
        ),
      );
      return http.Response.fromStream(await client.send(request));
    }

    final response = await _send(path, sendFile, limit: fileTimeout);
    return _decode(response);
  }

  /// Gövdesiz hata yanıtları için kullanıcıya ne yapacağını söyleyen metin.
  ///
  /// Ağ geçidi hatalarının gövdesi boştur; okunacak bir `error` alanı yoktur.
  /// Kullanıcı bu durumda "İşlem tamamlanamadı. (HTTP 504)" görüyordu — ne
  /// olduğunu da ne yapması gerektiğini de anlatmayan bir metin. Nitekim
  /// 19 Ağustos 2026'da `/api/session` bir kez 504 döndü ve testçiye tam
  /// olarak bu göründü.
  String _fallbackMessage(int statusCode) => switch (statusCode) {
    502 || 503 || 504 =>
      'Sunucuya şu an ulaşılamıyor. Birkaç saniye sonra '
          'tekrar deneyin.',
    408 =>
      'Sunucu zamanında yanıt vermedi. Bağlantınızı kontrol edip tekrar '
          'deneyin.',
    _ => 'İşlem tamamlanamadı.',
  };

  dynamic _decode(http.Response response) {
    final data = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map ? data['error']?.toString() : null;
      final failure = MobileApiException(
        response.statusCode,
        message ?? _fallbackMessage(response.statusCode),
      );
      _report(response, failure);
      throw failure;
    }
    return data;
  }

  /// Yakalanan API hatasını Sentry'ye bildirir.
  ///
  /// Ekranlar bu hatayı yakalayıp kullanıcıya gösterdiği için Sentry'nin
  /// yakalanmamış hata kancası devreye girmiyordu: test kullanıcısı
  /// "İşlem tamamlanamadı." görüyor, biz hiçbir yerde göremiyorduk.
  /// 18 Ağustos 2026'da iOS testçilerinin bildirdiği arıza böyle görünmez
  /// kalmıştı.
  ///
  /// Yalnız yol ve durum kodu gönderilir; istek gövdesi, sorgu değerleri ve
  /// yanıt içeriği gönderilmez (bkz. sunucudaki sentry-scrub deseni).
  void _report(http.Response response, MobileApiException failure) => _capture(
    failure,
    path: response.request?.url.path,
    method: response.request?.method,
  );

  void _capture(MobileApiException failure, {String? path, String? method}) {
    // 401 oturum yenilemesinin normal parçasıdır; gürültü yapmasın.
    // Gizlilik talebindeki 409 da kullanıcının aynı açık talebi yeniden
    // göndermesidir. Beklenen alan durumunu üretim hatası gibi raporlamayız.
    if (failure.statusCode == 401 ||
        (failure.statusCode == 409 && path == '/api/settings/privacy')) {
      return;
    }
    final safePath = path ?? 'bilinmiyor';
    Sentry.captureException(
      failure,
      stackTrace: StackTrace.current,
      withScope: (scope) {
        scope.level = SentryLevel.error;
        scope.setTag('api.path', safePath);
        scope.setTag('api.status', failure.statusCode.toString());
        scope.setContexts('api', {
          'path': safePath,
          'status': failure.statusCode,
          'method': method,
        });
      },
    );
  }
}

class MobileApiException implements Exception {
  const MobileApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  // Durum kodu mesaja katılır: Sentry raporunda 401 mi 500 mü olduğu
  // görünmezse aynı hata bir daha araştırılamaz.
  @override
  String toString() => statusCode > 0 ? '$message (HTTP $statusCode)' : message;
}

class MobileServices {
  MobileServices._({
    required this.config,
    required this.database,
    required this.sessions,
    required this.api,
    required this.queue,
    required this.sync,
    this.fieldModeNotificationPermissionCheck,
    this.fieldModeNow,
  });

  /// Testlerde bellek içi bir veritabanı ve sahte istemcilerle kurmak için.
  ///
  /// `MobileServices.create` gerçek `AppDatabase()` açar ve o da
  /// path_provider'a bağlıdır; widget testinde kuyruk sorgulanır sorgulanmaz
  /// patlar. `AppDatabase.forTesting` ile aynı gerekçe.
  factory MobileServices.forTesting({
    required MobileConfig config,
    required AppDatabase database,
    required MobileApiClient api,
    required SyncEngine sync,
    SecureSessionStore sessions = const SecureSessionStore(),
    Future<bool> Function()? fieldModeNotificationPermissionCheck,
    DateTime Function()? fieldModeNow,
  }) => MobileServices._(
    config: config,
    database: database,
    sessions: sessions,
    api: api,
    queue: SyncQueueRepository(database),
    sync: sync,
    fieldModeNotificationPermissionCheck: fieldModeNotificationPermissionCheck,
    fieldModeNow: fieldModeNow,
  );

  factory MobileServices.create(MobileConfig config) {
    final database = AppDatabase();
    const sessions = SecureSessionStore();
    // Aktif çalışma alanı `refreshContext()` ile değiştiği için istemciye
    // değer değil, okuyucu verilir; kurulum sırasında örnek henüz yok.
    late final MobileServices services;
    final api = MobileApiClient(
      baseUrl: Uri.parse(config.apiBaseUrl),
      sessions: sessions,
      workspaceId: () => services.workspaceId,
      accessTokenProvider: config.hasSupabase
          ? () async =>
                Supabase.instance.client.auth.currentSession?.accessToken
          : null,
      refreshAccessToken: config.hasSupabase
          ? () async {
              try {
                final response = await Supabase.instance.client.auth
                    .refreshSession();
                final session = response.session;
                if (session == null) {
                  await sessions.clear();
                  return null;
                }
                await sessions.save(
                  accessToken: session.accessToken,
                  refreshToken: session.refreshToken ?? '',
                );
                return session.accessToken;
              } on AuthSessionMissingException {
                await sessions.clear();
                return null;
              } on AuthApiException catch (error) {
                if (const {
                  'refresh_token_not_found',
                  'refresh_token_already_used',
                  'session_not_found',
                  'session_expired',
                  'invalid_credentials',
                }.contains(error.code)) {
                  await sessions.clear();
                  return null;
                }
                rethrow;
              }
            }
          : null,
      onSessionExpired: () => services.sessionExpired.value = true,
    );
    services = MobileServices._(
      config: config,
      database: database,
      sessions: sessions,
      api: api,
      queue: SyncQueueRepository(database),
      sync: SyncEngine(
        database: database,
        sessions: sessions,
        baseUrl: Uri.parse(config.apiBaseUrl),
      ),
    );
    return services;
  }

  final MobileConfig config;
  final AppDatabase database;
  final SecureSessionStore sessions;
  final MobileApiClient api;
  final SyncQueueRepository queue;
  final SyncEngine sync;
  final Future<bool> Function()? fieldModeNotificationPermissionCheck;
  final DateTime Function()? fieldModeNow;

  /// Saha modu vardiya boyunca yaşadığı için servislerle birlikte tutulur;
  /// ekran değiştirildiğinde oturum kopmamalıdır.
  late final FieldModeService fieldMode = FieldModeService(
    this,
    notificationPermissionCheck: fieldModeNotificationPermissionCheck,
    now: fieldModeNow,
  );
  late final ReminderNotificationService reminders =
      ReminderNotificationService(this);

  /// Kayıtlı oturum ölünce true olur; yönlendirici bunu dinleyip kullanıcıyı
  /// giriş ekranına alır. Girişten sonra tekrar false'a çekilir.
  final ValueNotifier<Map<String, dynamic>?> entitlement = ValueNotifier(null);
  Timer? _accessTimer;
  bool get canWrite {
    if (!config.hasSupabase) return true;
    final data = entitlement.value;
    final endsAt = DateTime.tryParse(data?['accessEndsAt']?.toString() ?? '');
    return data?['readOnly'] == false &&
        endsAt != null &&
        DateTime.now().isBefore(endsAt);
  }

  void updateEntitlement(Map? data) {
    entitlement.value = data == null ? null : Map<String, dynamic>.from(data);
    _accessTimer?.cancel();
    final endsAt = DateTime.tryParse(data?['accessEndsAt']?.toString() ?? '');
    if (canWrite && endsAt != null) {
      _accessTimer = Timer(endsAt.difference(DateTime.now()), () {
        entitlement.value = {...?entitlement.value, 'readOnly': true};
        unawaited(fieldMode.stop());
      });
    } else if (fieldMode.isActive.value) {
      unawaited(fieldMode.stop());
    }
  }

  Future<void> requireWriteAccess() async {
    try {
      await refreshContext();
    } catch (_) {
      // Son doğrulanmış erişim bitişi çevrimdışıyken de uygulanır.
    }
    if (!canWrite) {
      throw const MobileApiException(
        402,
        'Yeni işlemler için abonelik gerekli. Mevcut kayıtlarınız ve taslaklarınız korunur.',
      );
    }
  }

  final ValueNotifier<bool> sessionExpired = ValueNotifier<bool>(false);

  String ownerId = 'demo-local';
  String workspaceId = '00000000-0000-4000-8000-000000000001';
  String? organizationId;
  String? displayName;
  String? workspaceCompanyName;
  String? workspaceKind;
  String timezone = 'UTC';

  void clearIdentityContext() {
    ownerId = 'demo-local';
    workspaceId = '00000000-0000-4000-8000-000000000001';
    organizationId = null;
    displayName = null;
    workspaceCompanyName = null;
    workspaceKind = null;
    timezone = 'UTC';
    _contextReadAt = null;
  }

  /// Bağlamın son başarıyla okunduğu an; `contextFreshness` içinde tekrar
  /// sorulmaz.
  DateTime? _contextReadAt;

  /// Aktif çalışma alanı değişene kadar bağlam kısa süre önbellekte tutulur.
  static const contextFreshness = Duration(minutes: 5);

  /// Oturum bağlamını tazeler.
  ///
  /// Her ekran açılışında çağrılıyordu — Bugün, Müşteriler, Harita, modüller,
  /// eşitleme merkezi. Yani hiç değişmeyen bir veri için uygulama boyunca
  /// onlarca kez `/api/session` isteği gidiyor ve her biri Supabase'e bir
  /// kimlik doğrulama turu açıyordu. Uç bir kez yavaşladığında bunun bedeli
  /// tek bir ekran değil, açılan her ekran oluyordu; 19 Ağustos 2026'daki
  /// 504 tam olarak bu uçta görüldü.
  Future<void> refreshContext({bool force = false}) async {
    if (!config.hasSupabase) return;
    final readAt = _contextReadAt;
    if (!force &&
        readAt != null &&
        DateTime.now().difference(readAt) < contextFreshness) {
      return;
    }
    final result = await api.get('/api/session') as Map<String, dynamic>;
    ownerId = result['ownerId']?.toString() ?? ownerId;
    workspaceId = result['workspaceId']?.toString() ?? workspaceId;
    organizationId = result['organizationId']?.toString();
    displayName = result['displayName']?.toString();
    workspaceCompanyName = result['workspaceCompanyName']?.toString();
    workspaceKind = result['workspaceKind']?.toString();
    timezone = result['timezone']?.toString() ?? timezone;
    updateEntitlement(result['entitlement'] as Map?);
    // Yalnız başarıda işaretlenir; hata sonrası bir sonraki ekran tekrar dener.
    _contextReadAt = DateTime.now();
  }

  Future<void> switchWorkspace(String targetId) async {
    final previousId = workspaceId;
    workspaceId = targetId;
    try {
      await refreshContext(force: true);
    } catch (_) {
      workspaceId = previousId;
      rethrow;
    }
  }

  Future<void> dispose() async {
    _accessTimer?.cancel();
    entitlement.dispose();
    await fieldMode.stop();
    fieldMode.dispose();
    reminders.dispose();
    sessionExpired.dispose();
    api.client.close();
    sync.client.close();
    await database.close();
  }
}
