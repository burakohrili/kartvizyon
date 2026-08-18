import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizyon_mobile/data/sync_engine.dart';

void main() {
  test('başarılı istek kuyruktan silinmeye uygundur', () {
    expect(classifySyncStatus(200), SyncDisposition.success);
    expect(classifySyncStatus(201), SyncDisposition.success);
  });
  test('oturum ve geçici hata durumlarını ayırır', () {
    expect(classifySyncStatus(401), SyncDisposition.authRequired);
    expect(classifySyncStatus(409), SyncDisposition.retryLater);
    expect(classifySyncStatus(503), SyncDisposition.retryLater);
    expect(classifySyncStatus(422), SyncDisposition.permanentFailure);
  });

  test('sesli not sunucunun kabul ettiği bir türle gönderilir', () {
    // MultipartFile.fromPath tür verilmezse parçayı application/octet-stream
    // olarak gönderir; sunucu bunu 415 ile reddeder ve 415 kalıcı hata
    // sayıldığı için sesli not kuyrukta sonsuza kadar kalır — ekranda ise
    // "bağlantı gelince gönderilecek" yazar. Sunucunun kabul ettiği liste
    // apps/web/src/lib/openai/visit-ai.ts içindeki acceptedAudioTypes'tır.
    const accepted = {
      'audio/webm',
      'audio/mp4',
      'audio/mpeg',
      'audio/wav',
      'audio/x-m4a',
    };
    final source = File('lib/data/sync_engine.dart').readAsStringSync();
    final start = source.indexOf('MultipartFile.fromPath(');
    expect(start, greaterThan(-1), reason: 'sesli not yüklemesi bulunamadı');
    final call = source.substring(start, source.indexOf(');', start));
    expect(
      call.contains('contentType:'),
      isTrue,
      reason: 'ses parçası tür beyan etmeden gönderilemez',
    );
    final media = RegExp("MediaType[(]'([^']+)', *'([^']+)'[)]").firstMatch(
      call,
    );
    expect(media, isNotNull, reason: 'beyan edilen tür okunamadı');
    expect(accepted, contains('${media!.group(1)}/${media.group(2)}'));
  });
}
