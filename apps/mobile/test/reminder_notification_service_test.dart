import 'package:flutter_test/flutter_test.dart';
import 'package:kartvizyon_mobile/features/notifications/reminder_notification_service.dart';

Map<String, dynamic> _visit({
  String id = 'visit-1',
  String status = 'draft',
  required DateTime start,
}) => {
  'id': id,
  'status': status,
  'planned_start_at': start.toUtc().toIso8601String(),
  'company': {'name': 'Çok Uzun ABC Makina Sanayi ve Ticaret Anonim Şirketi'},
};

Map<String, dynamic> _task({
  String id = 'task-1',
  String status = 'open',
  required DateTime due,
}) => {
  'id': id,
  'status': status,
  'due_at': due.toUtc().toIso8601String(),
  'title': 'Çok uzun teklif dosyasını satın alma ekibine eksiksiz gönder',
};

void main() {
  final now = DateTime(2026, 9, 21, 7);
  const enabled = {
    'visitReminders': true,
    'taskReminders': true,
    'fieldModeMorning': true,
  };

  test('visit için T-24 ve T-2 stable kimlikle schedule edilir', () {
    final plans = buildReminderPlans(
      visits: [_visit(start: now.add(const Duration(days: 2)))],
      tasks: const [],
      preferences: enabled,
      now: now,
    );
    expect(
      plans.map((item) => item.key),
      containsAll(['visit:visit-1:24h', 'visit:visit-1:2h']),
    );
    expect(plans.map((item) => item.id).toSet().length, plans.length);
  });

  test('reschedule aynı stable ID ile yeni zamanı değiştirir', () {
    final before = buildReminderPlans(
      visits: [_visit(start: now.add(const Duration(days: 2)))],
      tasks: const [],
      preferences: {...enabled, 'fieldModeMorning': false},
      now: now,
    );
    final after = buildReminderPlans(
      visits: [_visit(start: now.add(const Duration(days: 3)))],
      tasks: const [],
      preferences: {...enabled, 'fieldModeMorning': false},
      now: now,
    );
    expect(after.first.id, before.first.id);
    expect(after.first.when, isNot(before.first.when));
  });

  test(
    'cancelled/completed eşdeğeri terminal visit ve preference OFF iptal listesine düşer',
    () {
      for (final status in ['approved', 'rejected', 'archived']) {
        expect(
          buildReminderPlans(
            visits: [
              _visit(status: status, start: now.add(const Duration(days: 2))),
            ],
            tasks: const [],
            preferences: enabled,
            now: now,
          ),
          isEmpty,
        );
      }
      expect(
        buildReminderPlans(
          visits: [_visit(start: now.add(const Duration(days: 2)))],
          tasks: const [],
          preferences: {
            ...enabled,
            'visitReminders': false,
            'fieldModeMorning': false,
          },
          now: now,
        ),
        isEmpty,
      );
    },
  );

  test(
    'task due ve overdue schedule edilir; completed veya OFF schedule edilmez',
    () {
      final due = DateTime(2026, 9, 22, 9);
      final plans = buildReminderPlans(
        visits: const [],
        tasks: [_task(due: due)],
        preferences: enabled,
        now: now,
      );
      expect(
        plans.map((item) => item.key),
        containsAll(['task:task-1:due', 'task:task-1:overdue']),
      );
      expect(
        buildReminderPlans(
          visits: const [],
          tasks: [_task(status: 'completed', due: due)],
          preferences: enabled,
          now: now,
        ),
        isEmpty,
      );
      expect(
        buildReminderPlans(
          visits: const [],
          tasks: [_task(due: due)],
          preferences: {...enabled, 'taskReminders': false},
          now: now,
        ),
        isEmpty,
      );
    },
  );

  test(
    'morning yalnız gelecekte planlı ziyaret varken ve tercih açıkken oluşur',
    () {
      final visit = _visit(start: DateTime(2026, 9, 22, 11));
      final plans = buildReminderPlans(
        visits: [visit],
        tasks: const [],
        preferences: {...enabled, 'visitReminders': false},
        now: now,
      );
      expect(plans.single.key, 'field-morning:2026-09-22');
      expect(plans.single.body, contains('1 planlı ziyaretiniz var'));
      expect(
        buildReminderPlans(
          visits: const [],
          tasks: const [],
          preferences: enabled,
          now: now,
        ),
        isEmpty,
      );
      expect(
        buildReminderPlans(
          visits: [visit],
          tasks: const [],
          preferences: {
            ...enabled,
            'visitReminders': false,
            'fieldModeMorning': false,
          },
          now: now,
        ),
        isEmpty,
      );
    },
  );

  test(
    'tekrarlanan sync planı duplicate ID üretmez ve çok kayıt destekler',
    () {
      final visits = List.generate(
        20,
        (index) => _visit(
          id: 'visit-$index',
          start: now.add(Duration(days: index + 2)),
        ),
      );
      final first = buildReminderPlans(
        visits: visits,
        tasks: const [],
        preferences: {...enabled, 'fieldModeMorning': false},
        now: now,
      );
      final second = buildReminderPlans(
        visits: visits,
        tasks: const [],
        preferences: {...enabled, 'fieldModeMorning': false},
        now: now,
      );
      expect(
        first.map((item) => item.id),
        orderedEquals(second.map((item) => item.id)),
      );
      expect(first.map((item) => item.id).toSet(), hasLength(first.length));
    },
  );

  test('tap payload geçerliyse hedefe, silinmiş/geçersizse Home’a gider', () {
    expect(routeForNotificationPayload('{"route":"/visits"}'), '/visits');
    expect(routeForNotificationPayload('{"route":"/tasks"}'), '/tasks');
    expect(routeForNotificationPayload('{"route":"/deleted/1"}'), '/');
    expect(routeForNotificationPayload('bozuk'), '/');
  });
}
