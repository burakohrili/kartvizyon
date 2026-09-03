import 'sync_engine.dart';

/// Kuyruk hatasını kullanıcının okuyabileceği bir cümleye çevirir.
///
/// Eşitleme merkezi bu satırda ham kodu (`http_409`, `network_error`)
/// gösteriyordu. Testçi ekranda "http_409" görüp ne olduğunu da, ne yapması
/// gerektiğini de anlayamadı. Etiket sebebi **ve çıkış yolunu** birlikte söyler.
String syncErrorLabel(String? lastError) {
  if (lastError == null || lastError.isEmpty) {
    return 'Gönderilmeyi bekliyor';
  }
  final code = lastError.startsWith(syncBlockedPrefix)
      ? lastError.substring(syncBlockedPrefix.length)
      : lastError;

  return switch (code) {
    'network_error' =>
      'Bağlantı kurulamadı. Ağ geldiğinde kendiliğinden denenecek.',
    'http_401' ||
    'http_403' => 'Oturum süresi doldu. Çıkıp yeniden giriş yapın.',
    'http_402' =>
      'AI dakika kotanız doldu. Metin notu kotasız gönderilir; '
          'sesli notu silip notu yazarak gönderebilirsiniz.',
    'http_404' =>
      'Bu notun bağlı olduğu ziyaret bulunamadı. Kayıt silinebilir.',
    'http_409' =>
      'Bu not sunucuda hâlâ işleniyor. Kısa süre sonra kendiliğinden '
          'tamamlanacak.',
    'http_413' =>
      'Ses kaydı 25 MB sınırını aşıyor. Daha kısa bir not kaydedin; '
          'bu kaydı silebilirsiniz.',
    'http_415' =>
      'Ses biçimi sunucu tarafından kabul edilmedi. Kaydı silip yeniden '
          'kaydedin.',
    'http_429' => 'Çok fazla istek gönderildi. Biraz sonra tekrar deneyin.',
    'visit_id_missing' => 'Kayıt eksik oluşmuş; gönderilemez, silinebilir.',
    'unsupported_entity' =>
      'Bu kayıt türü uygulamanın bu sürümü tarafından gönderilemiyor.',
    _ when code.startsWith('http_5') =>
      'Sunucu şu an yanıt veremiyor. Kısa süre sonra tekrar denenecek.',
    _ => 'Gönderilemedi. Tekrar deneyebilir ya da kaydı silebilirsiniz.',
  };
}

/// Kalıcı hataya düşmüş kayıt için başlıkta gösterilecek uyarı.
String blockedQueueNotice(int blocked) => blocked == 1
    ? '1 kayıt gönderilemiyor. Aşağıdan tekrar deneyin ya da silin.'
    : '$blocked kayıt gönderilemiyor. Aşağıdan tekrar deneyin ya da silin.';
