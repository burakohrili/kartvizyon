import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/local/app_database.dart';
import '../data/secure_session_store.dart';
import '../data/sync_engine.dart';
import '../data/sync_queue_repository.dart';
import '../features/field_mode/field_mode_service.dart';

class MobileConfig {
  const MobileConfig({
    required this.apiBaseUrl,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.sentryDsn,
  });

  factory MobileConfig.fromEnvironment() => const MobileConfig(
    apiBaseUrl: String.fromEnvironment(
      'KARTVIZYON_API_URL',
      defaultValue: 'https://app.kartvizyon.app',
    ),
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
    sentryDsn: String.fromEnvironment('SENTRY_DSN'),
  );

  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String sentryDsn;
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
    if (response.statusCode != 401 || refreshAccessToken == null) {
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
    if (response.statusCode == 401) onSessionExpired?.call();
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
  }) async {
    Future<http.Response> sendFile(Map<String, String> headers) async {
      final request = http.MultipartRequest('POST', baseUrl.resolve(path));
      request.headers.addAll(headers);
      request.files.add(await http.MultipartFile.fromPath(field, filePath));
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
    502 || 503 || 504 => 'Sunucuya şu an ulaşılamıyor. Birkaç saniye sonra '
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
    if (failure.statusCode == 401) return;
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
  }) => MobileServices._(
    config: config,
    database: database,
    sessions: sessions,
    api: api,
    queue: SyncQueueRepository(database),
    sync: sync,
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
              } on AuthException {
                await sessions.clear();
                return null;
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

  /// Saha modu vardiya boyunca yaşadığı için servislerle birlikte tutulur;
  /// ekran değiştirildiğinde oturum kopmamalıdır.
  late final FieldModeService fieldMode = FieldModeService(this);

  /// Kayıtlı oturum ölünce true olur; yönlendirici bunu dinleyip kullanıcıyı
  /// giriş ekranına alır. Girişten sonra tekrar false'a çekilir.
  final ValueNotifier<bool> sessionExpired = ValueNotifier<bool>(false);

  String ownerId = 'demo-local';
  String workspaceId = '00000000-0000-4000-8000-000000000001';
  String? organizationId;

  /// Bağlamın son başarıyla okunduğu an; `contextFreshness` içinde tekrar
  /// sorulmaz.
  DateTime? _contextReadAt;

  /// Oturum bağlamı bir vardiya boyunca değişmez: mobilde çalışma alanı
  /// değiştirme yoktur, `ownerId` ve `workspaceId` girişten çıkışa sabittir.
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
    // Yalnız başarıda işaretlenir; hata sonrası bir sonraki ekran tekrar dener.
    _contextReadAt = DateTime.now();
  }

  Future<void> dispose() async {
    await fieldMode.stop();
    fieldMode.dispose();
    sessionExpired.dispose();
    api.client.close();
    sync.client.close();
    await database.close();
  }
}
