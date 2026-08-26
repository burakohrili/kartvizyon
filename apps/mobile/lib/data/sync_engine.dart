import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'local/app_database.dart';
import 'secure_session_store.dart';

/// Bir kuyruk kaydının yeniden denenip denenmeyeceği.
///
/// `retryItem` ile `retryRun` ayrımı 18 Ağustos 2026'da eklendi. Öncesinde
/// ikisi de tek bir `retryLater` idi ve döngüyü `break` ediyordu: sunucudan
/// 409 alan **tek** bir sesli not, arkasındaki bütün kayıtların hiç
/// denenmemesine yol açıyordu. Testçinin eşitleme merkezi ekranı tam olarak
/// bunu gösterdi — bir kayıt "http_409, 5 deneme", arkasındaki iki kayıt
/// "0 deneme".
enum SyncDisposition {
  success,

  /// Oturum yenilenmeli; bu turda başka kayıt denenmez.
  authRequired,

  /// Yalnız bu kayıt şimdilik gönderilemez, sıradakine geçilir.
  retryItem,

  /// Sunucu genelinde bir sorun var (429/5xx); turu bitir, sunucuyu dövme.
  retryRun,

  /// İstek olduğu haliyle asla kabul edilmeyecek; tekrar denemek anlamsız.
  permanentFailure,
}

SyncDisposition classifySyncStatus(int status) {
  if (status >= 200 && status < 300) return SyncDisposition.success;
  if (status == 401 || status == 403) return SyncDisposition.authRequired;
  // 409 idempotency çakışmasıdır ve yalnız o kaydı ilgilendirir.
  if (status == 409) return SyncDisposition.retryItem;
  if (status == 429 || status >= 500) return SyncDisposition.retryRun;
  return SyncDisposition.permanentFailure;
}

/// Kalıcı hataya düşen kaydın `lastError` değerine konan önek.
///
/// Drift şema sürümünü yükseltmemek için ayrı bir kolon yerine bu önek
/// kullanılır; uygulama zaten TestFlight'ta ve bir migration stratejisi
/// gerektirmeyen çözüm tercih edildi. Kayıt **silinmez**: yakalanmış saha
/// verisi kullanıcınındır, silmeyi kullanıcı eşitleme merkezinden seçer.
const syncBlockedPrefix = 'permanent:';

bool isSyncBlocked(String? lastError) =>
    lastError != null && lastError.startsWith(syncBlockedPrefix);

class SyncRunResult {
  const SyncRunResult({
    required this.synced,
    required this.remaining,
    required this.authRequired,
    this.blocked = 0,
  });
  final int synced;
  final int remaining;
  final bool authRequired;

  /// Kalıcı hataya düşmüş, kullanıcı müdahalesi bekleyen kayıt sayısı.
  final int blocked;
}

class SyncEngine {
  SyncEngine({
    required this.database,
    required this.sessions,
    required this.baseUrl,
    http.Client? client,
  }) : client = client ?? http.Client();
  final AppDatabase database;
  final SecureSessionStore sessions;
  final Uri baseUrl;
  final http.Client client;

  Future<SyncRunResult> run({required String ownerId}) async {
    final session = await sessions.read();
    final items = await database.pendingForOwner(ownerId);
    if (session == null) {
      return SyncRunResult(
        synced: 0,
        remaining: items.length,
        authRequired: true,
        blocked: items.where((item) => isSyncBlocked(item.lastError)).length,
      );
    }
    var synced = 0;
    var authRequired = false;

    for (final item in items) {
      // Kalıcı hataya düşmüş kayıt tekrar denenmez; kullanıcı eşitleme
      // merkezinden ya siler ya da "tekrar dene" ile bu işareti kaldırır.
      if (isSyncBlocked(item.lastError)) continue;

      final disposition = await _send(item, session.accessToken);
      if (disposition == null) {
        // Ağ hatası: sıradaki kayıt da büyük olasılıkla gidemez.
        break;
      }
      if (disposition == SyncDisposition.success) {
        synced += 1;
        continue;
      }
      if (disposition == SyncDisposition.authRequired) {
        authRequired = true;
        break;
      }
      if (disposition == SyncDisposition.retryRun) break;
      // retryItem ve permanentFailure: sıradaki kayda geç.
      //
      // Bu, kuyruktaki katı FIFO teslimini bozar. Bugün güvenli, çünkü bir
      // sesli not ancak sunucuda gerçekten oluşmuş bir ziyaretten sonra
      // kuyruğa girebiliyor: çevrimdışı ziyaret oluşturma yalnız kuyruğa
      // yazıyor, debrief ekranına geçmiyor (visits_screen.dart, catch dalı).
      // Çevrimdışı ziyaret → çevrimdışı debrief zinciri eklenirse bu varsayım
      // düşer ve debrief, ziyaretinden önce gidip 404 alabilir.
    }

    final remaining = await database.pendingForOwner(ownerId);
    return SyncRunResult(
      synced: synced,
      remaining: remaining.length,
      authRequired: authRequired,
      blocked: remaining.where((item) => isSyncBlocked(item.lastError)).length,
    );
  }

  /// Tek bir kaydı gönderir. Ağ hatasında `null` döner.
  Future<SyncDisposition?> _send(SyncQueueItem item, String accessToken) async {
    if (item.entityType == 'visit_create') {
      try {
        final response = await client.post(
          baseUrl.resolve('/api/visits'),
          headers: {
            'authorization': 'Bearer $accessToken',
            'content-type': 'application/json',
          },
          body: item.payloadJson,
        );
        // `await` olmadan döndürülürse `_settle` içindeki bir hata aşağıdaki
        // catch'e uğramaz ve kuyruk kaydı hiçbir sonuç işaretlenmeden kalır.
        return await _settle(item, response.statusCode, attachment: null);
      } catch (_) {
        await database.markFailure(item.clientMutationId, 'network_error');
        return null;
      }
    }

    if (item.entityType != 'visit_debrief') {
      await database.markFailure(
        item.clientMutationId,
        '${syncBlockedPrefix}unsupported_entity',
      );
      return SyncDisposition.permanentFailure;
    }

    final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
    final visitId = payload['visitId'] as String?;
    if (visitId == null) {
      await database.markFailure(
        item.clientMutationId,
        '${syncBlockedPrefix}visit_id_missing',
      );
      return SyncDisposition.permanentFailure;
    }

    final request =
        http.MultipartRequest(
            'POST',
            baseUrl.resolve('/api/visits/$visitId/debrief'),
          )
          ..headers['authorization'] = 'Bearer $accessToken'
          ..fields['clientMutationId'] = item.clientMutationId
          ..fields['transcript'] = (payload['transcript'] as String?) ?? '';
    final attachment = item.attachmentPath;
    if (attachment != null && await File(attachment).exists()) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          attachment,
          // MultipartFile.fromPath tür belirtilmezse parçayı
          // `application/octet-stream` olarak gönderir; sunucu ise izinli
          // ses türlerini beyan edilen türe bakarak süzüyor ve 415 dönüyor.
          // 415 kalıcı hata sayıldığı için sesli not kuyrukta sonsuza kadar
          // kalıyor, ekranda ise "bağlantı gelince gönderilecek" yazıyordu.
          // Kaydedici AAC-LC ile .m4a üretir; doğru tür audio/mp4'tür.
          contentType: MediaType('audio', 'mp4'),
        ),
      );
    }

    try {
      final response = await client.send(request);
      // Yanıt gövdesi okunmazsa bağlantı açık kalır; her başarısız gönderimde
      // bir soket sızıyordu.
      await response.stream.drain<void>();
      return await _settle(item, response.statusCode, attachment: attachment);
    } catch (_) {
      await database.markFailure(item.clientMutationId, 'network_error');
      return null;
    }
  }

  Future<SyncDisposition> _settle(
    SyncQueueItem item,
    int statusCode, {
    required String? attachment,
  }) async {
    final disposition = classifySyncStatus(statusCode);
    if (disposition == SyncDisposition.success) {
      await database.removeByMutationId(item.clientMutationId);
      if (attachment != null) {
        await File(attachment).delete().catchError((_) => File(attachment));
      }
      return disposition;
    }
    final code = 'http_$statusCode';
    await database.markFailure(
      item.clientMutationId,
      disposition == SyncDisposition.permanentFailure
          ? '$syncBlockedPrefix$code'
          : code,
    );
    return disposition;
  }
}
