/// Görev listesini açık ve tamamlanmış olarak ayırır.
///
/// Liste sunucudan tek parça geliyordu ve tamamlanmış bir görev, tarih
/// yuvasında açık görevlerin arasında kalıyordu; yalnız tik farkıyla
/// ayrılıyordu. Web sayfası bu ayrımı zaten yapıyor
/// (`apps/web/src/app/tasks/page.tsx`), mobil yapmıyordu.
({List<Map<String, dynamic>> open, List<Map<String, dynamic>> completed})
splitTasks(List<Map<String, dynamic>> tasks) {
  final open = <Map<String, dynamic>>[];
  final completed = <Map<String, dynamic>>[];
  for (final task in tasks) {
    (task['status']?.toString() == 'completed' ? completed : open).add(task);
  }
  open.sort(_byDueDate);
  completed.sort(_byDueDate);
  return (open: open, completed: completed);
}

/// Tarihi olan görev önce; tarihsizler sona.
int _byDueDate(Map<String, dynamic> a, Map<String, dynamic> b) {
  final left = taskDueDate(a);
  final right = taskDueDate(b);
  if (left == null && right == null) return 0;
  if (left == null) return 1;
  if (right == null) return -1;
  return left.compareTo(right);
}

DateTime? taskDueDate(Map<String, dynamic> task) {
  final raw = task['due_at']?.toString();
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw)?.toLocal();
}

/// Kart alt satırında gösterilecek tarih; tarihsiz görevde boş döner.
String taskDueLabel(Map<String, dynamic> task) {
  final due = taskDueDate(task);
  if (due == null) return '';
  final day = due.day.toString().padLeft(2, '0');
  final month = due.month.toString().padLeft(2, '0');
  return '$day.$month.${due.year}';
}
