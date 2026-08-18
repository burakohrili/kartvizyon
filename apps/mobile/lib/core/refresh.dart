/// Aşağı çekip yenileme sırasında oluşan hatayı yutar.
///
/// `RefreshIndicator.onRefresh` içinden fırlatılan hata Flutter tarafından
/// yakalanmaz; `PlatformDispatcher.onError` üzerinden uygulamayı çökertir.
/// Nitekim 18 Ağustos 2026'da production'da bu yaşandı: `/api/session`
/// çağrısı başarısız olunca Bugün ekranında yenileme yapan kullanıcının
/// uygulaması fatal hata ile kapandı (Sentry `MobileApiException`).
///
/// Hata zaten ekrandaki `FutureBuilder` tarafından gösterildiği için burada
/// yutmak bilgi kaybettirmez; kullanıcı hata mesajını ve "tekrar dene"
/// düğmesini görmeye devam eder.
Future<void> settleRefresh(Future<Object?> reload) async {
  try {
    await reload;
  } catch (_) {
    // Ekrandaki FutureBuilder hatayı gösterir; yeniden fırlatmak çökertir.
  }
}
