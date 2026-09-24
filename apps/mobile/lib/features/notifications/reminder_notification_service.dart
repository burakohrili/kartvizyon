import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/mobile_services.dart';
import '../customers/customer_identity.dart';

const _channelId = 'kartvizyon_reminders';

@immutable
class ReminderPlan {
  const ReminderPlan({
    required this.key,
    required this.title,
    required this.body,
    required this.when,
    required this.route,
  });

  final String key;
  final String title;
  final String body;
  final DateTime when;
  final String route;

  int get id => stableNotificationId(key);
  String get payload => jsonEncode({'key': key, 'route': route});
}

int stableNotificationId(String value) {
  var hash = 0x811c9dc5;
  for (final unit in value.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

String routeForNotificationPayload(String? payload) {
  try {
    final decoded = jsonDecode(payload ?? '') as Map<String, dynamic>;
    final route = decoded['route']?.toString();
    return route == '/visits' || route == '/tasks' ? route! : '/';
  } catch (_) {
    return '/';
  }
}

List<ReminderPlan> buildReminderPlans({
  required List<Map<String, dynamic>> visits,
  required List<Map<String, dynamic>> tasks,
  required Map<String, dynamic> preferences,
  required DateTime now,
  tz.Location? location,
}) {
  final plans = <ReminderPlan>[];
  final visitEnabled = preferences['visitReminders'] as bool? ?? true;
  final taskEnabled = preferences['taskReminders'] as bool? ?? true;
  final morningEnabled = preferences['fieldModeMorning'] as bool? ?? true;

  if (visitEnabled) {
    for (final visit in visits) {
      final id = visit['id']?.toString();
      final parsed = DateTime.tryParse(
        visit['planned_start_at']?.toString() ?? '',
      );
      final start = parsed == null
          ? null
          : location == null
          ? parsed.toLocal()
          : tz.TZDateTime.from(parsed, location);
      final terminal = const {
        'approved',
        'rejected',
        'archived',
      }.contains(visit['status']?.toString());
      if (id == null || start == null || terminal) continue;
      final company = visit['company'] is Map
          ? customerDisplayName(visit['company'] as Map)
          : 'Müşteri';
      for (final offset in const [
        (Duration(hours: 24), '24h', '24 saat'),
        (Duration(hours: 2), '2h', '2 saat'),
      ]) {
        final when = start.subtract(offset.$1);
        if (when.isAfter(now)) {
          plans.add(
            ReminderPlan(
              key: 'visit:$id:${offset.$2}',
              title: 'Yaklaşan ziyaret',
              body: '$company ziyaretiniz ${offset.$3} sonra.',
              when: when,
              route: '/visits',
            ),
          );
        }
      }
    }
  }

  if (taskEnabled) {
    for (final task in tasks) {
      final id = task['id']?.toString();
      final parsed = DateTime.tryParse(task['due_at']?.toString() ?? '');
      final due = parsed == null
          ? null
          : location == null
          ? parsed.toLocal()
          : tz.TZDateTime.from(parsed, location);
      if (id == null || due == null || task['status']?.toString() != 'open') {
        continue;
      }
      final title = task['title']?.toString() ?? 'Görev';
      final dueMorning = location == null
          ? DateTime(due.year, due.month, due.day, 8, 30)
          : tz.TZDateTime(location, due.year, due.month, due.day, 8, 30);
      if (dueMorning.isAfter(now)) {
        plans.add(
          ReminderPlan(
            key: 'task:$id:due',
            title: 'Bugünkü görev',
            body: 'Bugün: $title',
            when: dueMorning,
            route: '/tasks',
          ),
        );
      }
      final overdue = due.add(const Duration(hours: 1));
      if (overdue.isAfter(now)) {
        plans.add(
          ReminderPlan(
            key: 'task:$id:overdue',
            title: 'Görev gecikti',
            body: 'Görev gecikti: $title',
            when: overdue,
            route: '/tasks',
          ),
        );
      }
    }
  }

  if (morningEnabled) {
    final days = <DateTime, int>{};
    for (final visit in visits) {
      final parsed = DateTime.tryParse(
        visit['planned_start_at']?.toString() ?? '',
      );
      final start = parsed == null
          ? null
          : location == null
          ? parsed.toLocal()
          : tz.TZDateTime.from(parsed, location);
      final terminal = const {
        'approved',
        'rejected',
        'archived',
      }.contains(visit['status']?.toString());
      if (start == null || terminal || !start.isAfter(now)) continue;
      final day = location == null
          ? DateTime(start.year, start.month, start.day)
          : tz.TZDateTime(location, start.year, start.month, start.day);
      days[day] = (days[day] ?? 0) + 1;
    }
    for (final entry in days.entries) {
      final when = location == null
          ? DateTime(entry.key.year, entry.key.month, entry.key.day, 8, 30)
          : tz.TZDateTime(
              location,
              entry.key.year,
              entry.key.month,
              entry.key.day,
              8,
              30,
            );
      if (!when.isAfter(now)) continue;
      plans.add(
        ReminderPlan(
          key:
              'field-morning:${entry.key.year}-${entry.key.month.toString().padLeft(2, '0')}-${entry.key.day.toString().padLeft(2, '0')}',
          title: 'Bugünün saha planı',
          body:
              'Bugün ${entry.value} planlı ziyaretiniz var. Saha Modu’nu açmayı unutmayın.',
          when: when,
          route: '/',
        ),
      );
    }
  }
  return plans;
}

class ReminderNotificationService {
  ReminderNotificationService(
    this.services, {
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final MobileServices services;
  final FlutterLocalNotificationsPlugin _plugin;
  final ValueNotifier<bool> permissionDenied = ValueNotifier(false);
  final ValueNotifier<String?> pendingRoute = ValueNotifier(null);
  bool _initialised = false;
  bool _syncing = false;

  Future<void> initialise() async {
    if (_initialised) return;
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(services.timezone));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) =>
          _receivePayload(response.payload),
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    _receivePayload(launch?.notificationResponse?.payload);
    _initialised = true;
  }

  void _receivePayload(String? payload) {
    if (payload != null) {
      pendingRoute.value = routeForNotificationPayload(payload);
    }
  }

  Future<bool> _ensurePermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final apple = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final allowed = android != null
        ? await android.requestNotificationsPermission() ?? false
        : apple != null
        ? await apple.requestPermissions(alert: true, sound: true) ?? false
        : true;
    permissionDenied.value = !allowed;
    return allowed;
  }

  Future<void> sync() async {
    if (_syncing || !services.config.hasSupabase) return;
    _syncing = true;
    try {
      await initialise();
      try {
        tz.setLocalLocation(tz.getLocation(services.timezone));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
      final location = tz.local;
      final now = tz.TZDateTime.now(location);
      final from = tz.TZDateTime(
        location,
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 30)).toUtc().toIso8601String();
      final to = now.add(const Duration(days: 31)).toUtc().toIso8601String();
      final responses = await Future.wait([
        services.api.get('/api/calendar?from=$from&to=$to'),
        services.api.get('/api/settings/notifications'),
      ]);
      final calendar = responses[0] as Map;
      final settings = responses[1] as Map;
      var plans = buildReminderPlans(
        visits: List<Map<String, dynamic>>.from(
          calendar['visits'] as List? ?? const [],
        ),
        tasks: List<Map<String, dynamic>>.from(
          calendar['tasks'] as List? ?? const [],
        ),
        preferences: Map<String, dynamic>.from(settings['data'] as Map),
        now: now,
        location: location,
      );
      if (services.fieldMode.isActive.value) {
        plans = plans
            .where((plan) => !plan.key.startsWith('field-morning:'))
            .toList();
      }
      final managed = (await _plugin.pendingNotificationRequests())
          .where((item) => item.payload?.contains('"key"') ?? false)
          .toList();
      final desiredIds = plans.map((item) => item.id).toSet();
      for (final old in managed) {
        if (!desiredIds.contains(old.id)) await _plugin.cancel(old.id);
      }
      if (plans.isEmpty || !await _ensurePermission()) return;
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'Ziyaret ve görev hatırlatmaları',
          channelDescription: 'Planlı ziyaret ve görev zamanlarını hatırlatır.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(threadIdentifier: 'reminders'),
      );
      for (final plan in plans) {
        // Aynı stable ID önce iptal edilerek reschedule eski zamanı bırakmaz.
        await _plugin.cancel(plan.id);
        await _plugin.zonedSchedule(
          plan.id,
          plan.title,
          plan.body,
          tz.TZDateTime.from(plan.when, tz.local),
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: plan.payload,
        );
      }
    } catch (_) {
      // Notification Center canonical kalır; local scheduling ağ veya platform
      // hatası yüzünden uygulamanın açılışını bozmaz.
    } finally {
      _syncing = false;
    }
  }

  Future<void> cancelTodayMorningReminder() async {
    try {
      await initialise();
      final now = tz.TZDateTime.now(tz.local);
      final key =
          'field-morning:${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      await _plugin.cancel(stableNotificationId(key));
    } catch (_) {
      // Saha Modu yine açılır; platform notification arızası engel değildir.
    }
  }

  void dispose() {
    permissionDenied.dispose();
    pendingRoute.dispose();
  }
}
