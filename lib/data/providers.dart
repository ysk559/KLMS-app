import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/generated/app_localizations.dart';
import 'api/canvas_client.dart';
import 'auth/auth_service.dart';
import 'calendar/google_calendar_service.dart';
import 'db/app_database.dart';
import 'models/announcement.dart';
import 'models/course.dart';
import 'models/course_module.dart';
import 'models/task_item.dart';
import 'notifications/notification_service.dart';
import 'repositories/announcement_repository.dart';
import 'repositories/course_repository.dart';
import 'repositories/task_repository.dart';
import 'settings/settings_controller.dart';
import 'sync/sync_log.dart';
import 'sync/sync_service.dart';
import 'widgets/widget_bridge.dart';

/// Overridden in main() after async initialization.
final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('overridden in main()'),
);
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => throw UnimplementedError('overridden in main()'),
);

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final canvasClientProvider =
    Provider<CanvasClient>((ref) => CanvasClient(ref.watch(authServiceProvider)));

final courseRepositoryProvider = Provider<CourseRepository>(
    (ref) => CourseRepository(ref.watch(appDatabaseProvider)));
final taskRepositoryProvider = Provider<TaskRepository>(
    (ref) => TaskRepository(ref.watch(appDatabaseProvider)));
final announcementRepositoryProvider = Provider<AnnouncementRepository>(
    (ref) => AnnouncementRepository(ref.watch(appDatabaseProvider)));

final googleCalendarServiceProvider =
    Provider<GoogleCalendarService>((ref) => GoogleCalendarService());

final syncServiceProvider = Provider<SyncService>((ref) => SyncService(
      client: ref.watch(canvasClientProvider),
      courseRepository: ref.watch(courseRepositoryProvider),
      taskRepository: ref.watch(taskRepositoryProvider),
      announcementRepository: ref.watch(announcementRepositoryProvider),
      notifications: ref.watch(notificationServiceProvider),
      calendar: ref.watch(googleCalendarServiceProvider),
    ));

/// Bumped after any local DB write so data providers reload.
final dbVersionProvider = StateProvider<int>((ref) => 0);

/// Whether we currently hold credentials (token or session cookie).
final authStatusProvider = FutureProvider<bool>((ref) async {
  ref.watch(dbVersionProvider);
  return ref.watch(authServiceProvider).isLoggedIn();
});

final coursesProvider = FutureProvider<List<Course>>((ref) {
  ref.watch(dbVersionProvider);
  return ref.watch(courseRepositoryProvider).getAll();
});

/// Courses keyed by id (empty until [coursesProvider] resolves).
final courseMapProvider = Provider<Map<int, Course>>((ref) {
  final courses = ref.watch(coursesProvider).value ?? const <Course>[];
  return {for (final c in courses) c.id: c};
});

final tasksProvider = FutureProvider<List<TaskItem>>((ref) {
  ref.watch(dbVersionProvider);
  return ref.watch(taskRepositoryProvider).getAll();
});

/// Tasks after applying the exclusion rules (when the user opted to hide
/// excluded tasks from the list, which is the default).
final visibleTasksProvider = Provider<AsyncValue<List<TaskItem>>>((ref) {
  final tasks = ref.watch(tasksProvider);
  final settings = ref.watch(settingsProvider);
  if (!settings.excludeAlsoFromList) return tasks;
  return tasks.whenData((list) => list
      .where((t) => !settings.excludesTask(t.title, t.courseId))
      .toList());
});

final announcementsProvider = FutureProvider<List<Announcement>>((ref) {
  ref.watch(dbVersionProvider);
  return ref.watch(announcementRepositoryProvider).getRecent();
});

/// Modules of one course, fetched on demand (kept in memory only).
final modulesProvider = FutureProvider.family<List<CourseModule>, int>(
    (ref, courseId) => ref.watch(canvasClientProvider).getModules(courseId));

final syncControllerProvider =
    AsyncNotifierProvider<SyncController, void>(SyncController.new);

class SyncController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> syncNow() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final settings = ref.read(settingsProvider);
      final l10n = _resolveL10n(settings.localeCode);
      final sync = ref.read(syncServiceProvider);

      Future<void> run() => sync.sync(
            settings: settings,
            l10n: l10n,
            isFirstSync: settings.lastSyncedAt == null,
          );

      try {
        await run();
      } on CanvasAuthException {
        // The Canvas session expired. While the upstream SSO session is still
        // alive we can renew it silently and carry on without bothering the
        // user with a login screen.
        final refreshed =
            await ref.read(authServiceProvider).refreshSessionSilently();
        await SyncLog.add('foreground',
            refreshed ? 'reauth' : 'auth', detail: refreshed ? null : 'expired');
        if (!refreshed) rethrow;
        await run();
      }

      ref
          .read(settingsProvider.notifier)
          .update((s) => s.copyWith(lastSyncedAt: DateTime.now()));
      ref.read(dbVersionProvider.notifier).state++;
      await SyncLog.add('foreground', 'ok');
    });
    if (state.hasError) {
      await SyncLog.add('foreground', 'error',
          detail: state.error.toString().split('\n').first);
    }
  }

  AppLocalizations _resolveL10n(String? localeCode) {
    final locale = localeCode != null
        ? Locale(localeCode)
        : PlatformDispatcher.instance.locale;
    try {
      return lookupAppLocalizations(locale);
    } catch (_) {
      return lookupAppLocalizations(const Locale('ja'));
    }
  }
}

/// Toggles manual completion and refreshes dependent providers and widgets.
Future<void> setTaskCompleted(WidgetRef ref, int taskId, bool completed) async {
  await ref.read(taskRepositoryProvider).setUserCompleted(taskId, completed);
  ref.read(dbVersionProvider.notifier).state++;
  await WidgetBridge.updateFromRepos(
    taskRepository: ref.read(taskRepositoryProvider),
    courseRepository: ref.read(courseRepositoryProvider),
    settings: ref.read(settingsProvider),
  );
}
