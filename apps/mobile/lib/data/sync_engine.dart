import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'local/app_database.dart';
import 'secure_session_store.dart';

enum SyncDisposition { success, authRequired, retryLater, permanentFailure }

SyncDisposition classifySyncStatus(int status) {
  if (status >= 200 && status < 300) return SyncDisposition.success;
  if (status == 401 || status == 403) return SyncDisposition.authRequired;
  if (status == 409 || status == 429 || status >= 500) {
    return SyncDisposition.retryLater;
  }
  return SyncDisposition.permanentFailure;
}

class SyncRunResult {
  const SyncRunResult({
    required this.synced,
    required this.remaining,
    required this.authRequired,
  });
  final int synced;
  final int remaining;
  final bool authRequired;
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
      );
    }
    var synced = 0;
    var authRequired = false;

    for (final item in items) {
      if (item.entityType == 'visit_create') {
        try {
          final response = await client.post(
            baseUrl.resolve('/api/visits'),
            headers: {
              'authorization': 'Bearer ${session.accessToken}',
              'content-type': 'application/json',
            },
            body: item.payloadJson,
          );
          final disposition = classifySyncStatus(response.statusCode);
          if (disposition == SyncDisposition.success) {
            await database.removeByMutationId(item.clientMutationId);
            synced += 1;
            continue;
          }
          if (disposition == SyncDisposition.authRequired) authRequired = true;
          await database.markFailure(
            item.clientMutationId,
            'http_${response.statusCode}',
          );
          if (authRequired || disposition == SyncDisposition.retryLater) break;
          continue;
        } catch (_) {
          await database.markFailure(item.clientMutationId, 'network_error');
          break;
        }
      }
      if (item.entityType != 'visit_debrief') {
        await database.markFailure(item.clientMutationId, 'unsupported_entity');
        continue;
      }
      final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
      final visitId = payload['visitId'] as String?;
      if (visitId == null) {
        await database.markFailure(item.clientMutationId, 'visit_id_missing');
        continue;
      }
      final request =
          http.MultipartRequest(
              'POST',
              baseUrl.resolve('/api/visits/$visitId/debrief'),
            )
            ..headers['authorization'] = 'Bearer ${session.accessToken}'
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
        switch (classifySyncStatus(response.statusCode)) {
          case SyncDisposition.success:
            await database.removeByMutationId(item.clientMutationId);
            if (attachment != null) {
              await File(
                attachment,
              ).delete().catchError((_) => File(attachment));
            }
            synced += 1;
          case SyncDisposition.authRequired:
            authRequired = true;
            break;
          case SyncDisposition.retryLater:
            await database.markFailure(
              item.clientMutationId,
              'http_${response.statusCode}',
            );
            break;
          case SyncDisposition.permanentFailure:
            await database.markFailure(
              item.clientMutationId,
              'http_${response.statusCode}',
            );
        }
        if (authRequired ||
            classifySyncStatus(response.statusCode) ==
                SyncDisposition.retryLater) {
          break;
        }
      } catch (_) {
        await database.markFailure(item.clientMutationId, 'network_error');
        break;
      }
    }
    return SyncRunResult(
      synced: synced,
      remaining: (await database.pendingForOwner(ownerId)).length,
      authRequired: authRequired,
    );
  }
}
