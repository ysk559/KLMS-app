import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/formatting.dart';
import '../../l10n/generated/app_localizations.dart';
import '../api/canvas_client.dart';
import '../calendar/google_calendar_service.dart';
import '../notifications/notification_service.dart';
import '../repositories/announcement_repository.dart';
import '../repositories/course_repository.dart';
import '../repositories/task_repository.dart';
import '../settings/app_settings.dart';
import '../widgets/widget_bridge.dart';

/// Orchestrates one full refresh: API → local DB → notifications.
class SyncService {
  SyncService({
    required this.client,
    required this.courseRepository,
    required this.taskRepository,
    required this.announcementRepository,
    required this.notifications,
    GoogleCalendarService? calendar,
  }) : _calendar = calendar;

  final CanvasClient client;
  final CourseRepository courseRepository;
  final TaskRepository taskRepository;
  final AnnouncementRepository announcementRepository;
  final NotificationService notifications;

  /// Lazily constructed when not injected (e.g. from the background isolate,
  /// where there's no shared Riverpod container to source it from).
  GoogleCalendarService? _calendar;

  static const _assignmentConcurrency = 4;
  static const _announcementWindow = Duration(days: 21);

  /// [isFirstSync] suppresses announcement notifications on the very first
  /// sync (everything would be "new").
  Future<void> sync({
    required AppSettings settings,
    required AppLocalizations l10n,
    required bool isFirstSync,
  }) async {
    // 1. Courses.
    final apiCourses = await client.getCourses();
    await courseRepository.upsertFromApi(apiCourses);
    final courses = await courseRepository.getAll();
    final coursesById = {for (final c in courses) c.id: c};

    // 2. Assignments per course (bounded concurrency). Fetching per course —
    // instead of the dashboard/planner feed — also captures assignments that
    // never show up on the dashboard.
    final ids = coursesById.keys.toList();
    for (var i = 0; i < ids.length; i += _assignmentConcurrency) {
      final chunk = ids.skip(i).take(_assignmentConcurrency);
      await Future.wait(chunk.map((courseId) async {
        final items = await client.getAssignments(courseId);
        await taskRepository.upsertFromApi(items);
        await taskRepository.deleteMissing(
            courseId, items.map((e) => e.id).toSet());
      }));
    }

    // 3. Canvas planner: the LMS-side "mark as done" checkmark also counts
    // as completed on the LMS. Optional — older Canvas instances may not
    // expose the planner API, so failures are non-fatal.
    try {
      final plannerDone = await client.getPlannerCompletedAssignmentIds();
      await taskRepository.markLmsCompleted(plannerDone);
    } on CanvasAuthException {
      rethrow;
    } catch (_) {}

    // 4. Completion conflicts: done in app, not done on LMS → notify once.
    final conflicts = await taskRepository.getUnnotifiedConflicts();
    for (final task in conflicts) {
      final decorated =
          decorateTaskTitle(task.title, coursesById[task.courseId]);
      await notifications.showConflict(
        task,
        l10n.conflictNotificationTitle,
        l10n.conflictNotificationBody(decorated),
      );
    }
    await taskRepository.markConflictNotified(conflicts.map((t) => t.id));

    // 5. Announcements.
    final announcements = await client.getAnnouncements(
      ids,
      since: DateTime.now().subtract(_announcementWindow),
    );
    final fresh = await announcementRepository.upsertFromApi(announcements);
    if (!isFirstSync && settings.announcementNotifications) {
      for (final a in fresh.take(5)) {
        final course = a.courseId != null ? coursesById[a.courseId!] : null;
        final prefix = course != null ? '${course.shortLabel}: ' : '';
        await notifications.showAnnouncement(
            a, l10n.announcementNotificationTitle, '$prefix${a.title}');
      }
    }

    // 6. Deadline reminders.
    final incomplete = await taskRepository.getIncomplete();
    await notifications.rescheduleDeadlineReminders(
      incompleteTasks: incomplete,
      offset: settings.reminderOffset,
      enabled: settings.deadlineReminderEnabled,
      excludeWords: settings.excludeWords,
      excludedCourseIds: settings.excludedCourseIds,
      titleFor: (t) => decorateTaskTitle(t.title, coursesById[t.courseId]),
      notificationText: (t, decorated) => (
        l10n.deadlineNotificationTitle,
        l10n.deadlineNotificationBody(
            decorated, formatDateTimeShort(t.dueAt!)),
      ),
    );

    // 7. Home-screen widgets.
    await WidgetBridge.updateFromRepos(
      taskRepository: taskRepository,
      courseRepository: courseRepository,
      settings: settings,
    );

    // 8. Google Calendar (one-way, on-device OAuth). Guarded so any failure
    // (offline, revoked consent, API error) never breaks the caller's sync.
    try {
      if (settings.googleCalendarSync) {
        final calendar = _calendar ??= GoogleCalendarService();
        final prefs = await SharedPreferences.getInstance();
        final allTasks = await taskRepository.getAll();
        await calendar.syncTasks(
          tasks: allTasks,
          coursesById: coursesById,
          settings: settings,
          prefs: prefs,
        );
      }
    } catch (_) {}
  }
}
