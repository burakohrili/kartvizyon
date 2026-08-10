import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/local/app_database.dart';
import '../data/secure_session_store.dart';
import '../data/sync_engine.dart';
import '../data/sync_queue_repository.dart';

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
    http.Client? client,
  }) : client = client ?? http.Client();

  final Uri baseUrl;
  final SecureSessionStore sessions;
  final Future<String?> Function()? accessTokenProvider;
  final Future<String?> Function()? refreshAccessToken;
  final http.Client client;

  Future<String?> _accessToken() async {
    final provided = await accessTokenProvider?.call();
    if (provided != null && provided.isNotEmpty) return provided;
    final session = await sessions.read();
    return session?.accessToken;
  }

  Map<String, String> _headersFor(String? accessToken) {
    return {
      'accept': 'application/json',
      'content-type': 'application/json',
      if (accessToken != null) 'authorization': 'Bearer $accessToken',
    };
  }

  Future<http.Response> _send(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    var response = await request(_headersFor(await _accessToken()));
    if (response.statusCode != 401 || refreshAccessToken == null) {
      return response;
    }
    final refreshedToken = await refreshAccessToken!.call();
    if (refreshedToken == null || refreshedToken.isEmpty) return response;
    response = await request(_headersFor(refreshedToken));
    return response;
  }

  Future<dynamic> get(String path) async {
    final response = await _send(
      (headers) => client.get(baseUrl.resolve(path), headers: headers),
    );
    return _decode(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final encodedBody = jsonEncode(body);
    final response = await _send(
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

    final response = await _send(sendFile);
    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    final data = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map ? data['error']?.toString() : null;
      throw MobileApiException(
        response.statusCode,
        message ?? 'İşlem tamamlanamadı.',
      );
    }
    return data;
  }
}

class MobileApiException implements Exception {
  const MobileApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => message;
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

  factory MobileServices.create(MobileConfig config) {
    final database = AppDatabase();
    const sessions = SecureSessionStore();
    final api = MobileApiClient(
      baseUrl: Uri.parse(config.apiBaseUrl),
      sessions: sessions,
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
    );
    return MobileServices._(
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
  }

  final MobileConfig config;
  final AppDatabase database;
  final SecureSessionStore sessions;
  final MobileApiClient api;
  final SyncQueueRepository queue;
  final SyncEngine sync;
  String ownerId = 'demo-local';
  String workspaceId = '00000000-0000-4000-8000-000000000001';
  String? organizationId;

  Future<void> refreshContext() async {
    if (!config.hasSupabase) return;
    final result = await api.get('/api/session') as Map<String, dynamic>;
    ownerId = result['ownerId']?.toString() ?? ownerId;
    workspaceId = result['workspaceId']?.toString() ?? workspaceId;
    organizationId = result['organizationId']?.toString();
  }

  Future<void> dispose() async {
    api.client.close();
    sync.client.close();
    await database.close();
  }
}
