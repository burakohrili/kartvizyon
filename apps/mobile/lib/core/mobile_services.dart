import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/local/app_database.dart';
import '../data/secure_session_store.dart';
import '../data/sync_engine.dart';
import '../data/sync_queue_repository.dart';

class MobileConfig {
  const MobileConfig({
    required this.apiBaseUrl,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  factory MobileConfig.fromEnvironment() => const MobileConfig(
    apiBaseUrl: String.fromEnvironment(
      'KARTVIZYON_API_URL',
      defaultValue: 'http://10.0.2.2:3000',
    ),
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  final String apiBaseUrl;
  final String supabaseUrl;
  final String supabaseAnonKey;
  bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

class MobileApiClient {
  MobileApiClient({
    required this.baseUrl,
    required this.sessions,
    http.Client? client,
  }) : client = client ?? http.Client();

  final Uri baseUrl;
  final SecureSessionStore sessions;
  final http.Client client;

  Future<Map<String, String>> _headers() async {
    final session = await sessions.read();
    return {
      'accept': 'application/json',
      'content-type': 'application/json',
      if (session != null) 'authorization': 'Bearer ${session.accessToken}',
    };
  }

  Future<dynamic> get(String path) async {
    final response = await client.get(
      baseUrl.resolve(path),
      headers: await _headers(),
    );
    return _decode(response);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final response = await client.post(
      baseUrl.resolve(path),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    final response = await client.patch(
      baseUrl.resolve(path),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<dynamic> postFile(
    String path, {
    required String field,
    required String filePath,
  }) async {
    final session = await sessions.read();
    final request = http.MultipartRequest('POST', baseUrl.resolve(path));
    if (session != null) {
      request.headers['authorization'] = 'Bearer ${session.accessToken}';
    }
    request.files.add(await http.MultipartFile.fromPath(field, filePath));
    final streamed = await client.send(request);
    final response = await http.Response.fromStream(streamed);
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
