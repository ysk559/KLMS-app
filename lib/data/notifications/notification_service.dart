import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/announcement.dart';
import '../models/task_item.dart';

/// Local notifications: deadline reminders, completion conflicts and
/// new-announcement alerts. Everything stays on-device (no push server).
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  // Notification id namespaces (32-bit int limit on Android).
  static const int _deadlineBase = 100000000;
  static const int _conflictBase = 200000000;
  static const int _announcementBase = 300000000;
  static const int _idRange = 100000000;

  static const _deadlineChannel = AndroidNotificationDetails(
    'deadline_reminders',
    'Deadline reminders',
    channelDescription: 'Reminds before assignment deadlines',
    importance: Importance.high,
    priority: Priority.high,
  );
  static const _conflictChannel = AndroidNotificationDetails(
    'completion_conflicts',
    'Completion conflicts',
    channelDescription:
        'Marked done in the app but still unsubmitted on the LMS',
    importance: Importance.high,
    priority: Priority.high,
  );
  static const _announcementChannel = AndroidNotificationDetails(
    'announcements',
    'Announcements',
    channelDescription: 'New course announcements',
    importance: Importance.defaultImportance,
  );

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final name = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(name));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('Asia/Tokyo'));
      }
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      _initialized = true;
    } catch (_) {
      // Platform channels unavailable (tests); notifications become no-ops.
    }
  }

  Future<void> requestPermissions() async {
    if (!_initialized) return;
    try {
      await _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    } catch (_) {}
  }

  static int _idFor(int base, int entityId) => base + (entityId % _idRange);

  /// Cancels and re-creates every scheduled deadline reminder.
  ///
  /// [titleFor] decorates the task title (e.g. `[Jexp]課題名`), and
  /// [notificationText] builds the localized (title, body) pair.
  Future<void> rescheduleDeadlineReminders({
    required List<TaskItem> incompleteTasks,
    required Duration offset,
    required bool enabled,
    required List<String> excludeWords,
    required Set<int> excludedCourseIds,
    required String Function(TaskItem) titleFor,
    required (String, String) Function(TaskItem, String decoratedTitle)
        notificationText,
  }) async {
    if (!_initialized) return;
    try {
      final pending = await _plugin.pendingNotificationRequests();
      for (final p in pending) {
        if (p.id >= _deadlineBase && p.id < _deadlineBase + _idRange) {
          await _plugin.cancel(p.id);
        }
      }
      if (!enabled) return;

      final now = DateTime.now();
      for (final task in incompleteTasks) {
        final due = task.dueAt?.toLocal();
        if (due == null) continue;
        if (excludedCourseIds.contains(task.courseId)) continue;
        final lowerTitle = task.title.toLowerCase();
        if (excludeWords
            .any((w) => w.isNotEmpty && lowerTitle.contains(w.toLowerCase()))) {
          continue;
        }
        final fireAt = due.subtract(offset);
        if (!fireAt.isAfter(now)) continue;

        final decorated = titleFor(task);
        final (title, body) = notificationText(task, decorated);
        await _plugin.zonedSchedule(
          _idFor(_deadlineBase, task.id),
          title,
          body,
          tz.TZDateTime.from(fireAt, tz.local),
          const NotificationDetails(
            android: _deadlineChannel,
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'task:${task.id}',
        );
      }
    } catch (_) {}
  }

  Future<void> showConflict(TaskItem task, String title, String body) async {
    if (!_initialized) return;
    try {
      await _plugin.show(
        _idFor(_conflictBase, task.id),
        title,
        body,
        const NotificationDetails(
          android: _conflictChannel,
          iOS: DarwinNotificationDetails(),
        ),
        payload: 'task:${task.id}',
      );
    } catch (_) {}
  }

  Future<void> showAnnouncement(
      Announcement announcement, String title, String body) async {
    if (!_initialized) return;
    try {
      await _plugin.show(
        _idFor(_announcementBase, announcement.id),
        title,
        body,
        const NotificationDetails(
          android: _announcementChannel,
          iOS: DarwinNotificationDetails(),
        ),
        payload: 'announcement:${announcement.id}',
      );
    } catch (_) {}
  }
}
