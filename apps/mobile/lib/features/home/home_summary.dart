/// Bugün ekranının sayaçları.
///
/// Sayaçlar daha önce ziyareti `draft`, `processing` ya da `needs_review`
/// olduğu sürece "planlanan" sayıyordu. Ziyaret sonrası not gönderildiğinde
/// sunucu `completed_at` yazıp durumu `needs_review` yapıyor, yani **biten
/// ziyaret hâlâ planlanan görünüyordu**. `planned_start_at` ve `completed_at`
/// API'den geliyor, mobil ikisini de hiç okumuyordu.
class HomeSummary {
  const HomeSummary({
    required this.plannedToday,
    required this.awaitingReview,
    required this.openVisits,
    required this.openTasks,
    this.nextVisit,
  });

  /// Bugüne planlanmış ve henüz tamamlanmamış ziyaret sayısı.
  final int plannedToday;

  /// Kullanıcı onayı bekleyen ziyaret; temsilcinin asıl işi budur.
  final int awaitingReview;

  /// Başlamış ama bitmemiş ziyaret. Web takvimini hiç kullanmayan temsilci
  /// sürekli sıfır görmesin diye planlanan yoksa bu gösterilir.
  final int openVisits;

  final int openTasks;
  final Map<String, dynamic>? nextVisit;
}

DateTime? _parse(Object? value) {
  final raw = value?.toString();
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toLocal();
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

HomeSummary summarize({
  required List<Map<String, dynamic>> visits,
  required List<Map<String, dynamic>> tasks,
  required DateTime now,
}) {
  var plannedToday = 0;
  var awaitingReview = 0;
  var openVisits = 0;
  Map<String, dynamic>? nextVisit;

  for (final visit in visits) {
    final status = visit['status']?.toString();
    final completedAt = _parse(visit['completed_at']);
    final plannedStart = _parse(visit['planned_start_at']);

    if (completedAt == null &&
        plannedStart != null &&
        _isSameDay(plannedStart, now)) {
      plannedToday += 1;
    }
    if (status == 'needs_review') awaitingReview += 1;
    if (completedAt == null && (status == 'draft' || status == 'processing')) {
      openVisits += 1;
    }
    final company = visit['company'];
    if (nextVisit == null &&
        completedAt == null &&
        company is Map &&
        company['id'] != null) {
      nextVisit = visit;
    }
  }

  return HomeSummary(
    plannedToday: plannedToday,
    awaitingReview: awaitingReview,
    openVisits: openVisits,
    openTasks: tasks
        .where((task) => task['status']?.toString() == 'open')
        .length,
    nextVisit: nextVisit,
  );
}
