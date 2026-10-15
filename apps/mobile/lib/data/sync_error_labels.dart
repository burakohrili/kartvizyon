import 'sync_engine.dart';
import '../l10n/app_localizations.dart';

/// Kuyruk hatasını kullanıcının okuyabileceği bir cümleye çevirir.
///
/// Eşitleme merkezi bu satırda ham kodu (`http_409`, `network_error`)
/// gösteriyordu. Testçi ekranda "http_409" görüp ne olduğunu da, ne yapması
/// gerektiğini de anlayamadı. Etiket sebebi **ve çıkış yolunu** birlikte söyler.
String syncErrorLabel(String? lastError, AppLocalizations l10n) {
  if (lastError == null || lastError.isEmpty) {
    return l10n.syncErrorWaiting;
  }
  final code = lastError.startsWith(syncBlockedPrefix)
      ? lastError.substring(syncBlockedPrefix.length)
      : lastError;

  return switch (code) {
    'network_error' => l10n.syncErrorNetwork,
    'http_401' || 'http_403' => l10n.syncErrorAuth,
    'http_402' => l10n.syncErrorAccess,
    'http_404' => l10n.syncErrorVisitMissing,
    'http_409' => l10n.syncErrorProcessing,
    'http_413' => l10n.syncErrorAudioTooLarge,
    'http_415' => l10n.syncErrorAudioUnsupported,
    'http_429' => l10n.syncErrorRateLimit,
    'visit_id_missing' => l10n.syncErrorVisitMissing,
    'unsupported_entity' => l10n.syncErrorUnsupportedEntity,
    _ when code.startsWith('http_5') => l10n.syncErrorServer,
    _ => l10n.syncErrorGeneric,
  };
}

/// Kalıcı hataya düşmüş kayıt için başlıkta gösterilecek uyarı.
String blockedQueueNotice(int blocked, AppLocalizations l10n) =>
    blocked == 1 ? l10n.syncBlockedOne : l10n.syncBlockedCount(blocked);
