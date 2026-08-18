import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizyon_mobile/features/home/home_summary.dart';
import 'package:kartvizyon_mobile/features/tasks/task_list.dart';

Map<String, dynamic> visit({
  String status = 'draft',
  String? plannedStartAt,
  String? completedAt,
  String? companyId,
}) => {
  'id': 'visit-$status-$plannedStartAt-$completedAt',
  'status': status,
  'planned_start_at': plannedStartAt,
  'completed_at': completedAt,
  if (companyId != null) 'company': {'id': companyId, 'name': 'Firma'},
};

void main() {
  final now = DateTime(2026, 8, 18, 14);

  group('Bugün sayaçları', () {
    test('biten ziyaret artık planlanan sayılmaz', () {
      // Ziyaret sonrası not gönderilince sunucu `completed_at` yazıp durumu
      // `needs_review` yapıyor. Eski sayaç bunu hâlâ "planlanan" gösteriyordu.
      final summary = summarize(
        visits: [
          visit(
            status: 'needs_review',
            plannedStartAt: '2026-08-18T09:00:00Z',
            completedAt: '2026-08-18T11:30:00Z',
          ),
        ],
        tasks: const [],
        now: now,
      );

      expect(summary.plannedToday, 0);
      expect(summary.awaitingReview, 1);
    });

    test('bugüne planlanmış ve bitmemiş ziyaret sayılır', () {
      final summary = summarize(
        visits: [
          visit(status: 'draft', plannedStartAt: '2026-08-18T09:00:00Z'),
          // Yarına planlanan bugünün sayacına girmez.
          visit(status: 'draft', plannedStartAt: '2026-08-19T09:00:00Z'),
        ],
        tasks: const [],
        now: now,
      );

      expect(summary.plannedToday, 1);
    });

    test('planı olmayan başlamış ziyaret açık sayılır', () {
      final summary = summarize(
        visits: [visit(status: 'draft')],
        tasks: const [],
        now: now,
      );

      expect(summary.plannedToday, 0);
      expect(summary.openVisits, 1);
    });

    test('sıradaki ziyaret tamamlanmamış ve firması olan ziyarettir', () {
      final summary = summarize(
        visits: [
          visit(
            status: 'approved',
            completedAt: '2026-08-18T10:00:00Z',
            companyId: 'firma-1',
          ),
          visit(status: 'draft', companyId: 'firma-2'),
        ],
        tasks: const [],
        now: now,
      );

      expect((summary.nextVisit?['company'] as Map?)?['id'], 'firma-2');
    });

    test('açık görev sayısı yalnız open durumunu sayar', () {
      final summary = summarize(
        visits: const [],
        tasks: const [
          {'status': 'open'},
          {'status': 'completed'},
          {'status': 'cancelled'},
        ],
        now: now,
      );

      expect(summary.openTasks, 1);
    });
  });

  group('görev listesi ayrımı', () {
    test('tamamlananlar ayrılır, tarihsizler sona iner', () {
      final split = splitTasks([
        {'title': 'tarihsiz açık', 'status': 'open'},
        {'title': 'geç tarihli açık', 'status': 'open', 'due_at': '2026-09-01'},
        {'title': 'erken açık', 'status': 'open', 'due_at': '2026-08-20'},
        {'title': 'biten', 'status': 'completed', 'due_at': '2026-08-19'},
      ]);

      expect(split.open.map((task) => task['title']), [
        'erken açık',
        'geç tarihli açık',
        'tarihsiz açık',
      ]);
      expect(split.completed.map((task) => task['title']), ['biten']);
    });

    test('tarih etiketi tarihsiz görevde boş kalır', () {
      expect(taskDueLabel({'due_at': '2026-08-20T09:00:00Z'}), '20.08.2026');
      expect(taskDueLabel(const {}), '');
    });
  });
}
