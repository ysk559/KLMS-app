import 'dart:io' show Platform;
import 'dart:ui' show DartPluginRegistrant, PlatformDispatcher;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' show Locale, WidgetsFlutterBinding;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../data/api/canvas_client.dart';
import '../data/auth/auth_service.dart';
import '../data/db/app_database.dart';
import '../data/notifications/notification_service.dart';
import '../data/repositories/announcement_repository.dart';
import '../data/repositories/course_repository.dart';
import '../data/repositories/task_repository.dart';
import '../data/settings/app_settings.dart';
import '../data/settings/settings_controller.dart';
import '../data/sync/sync_service.dart';
import '../l10n/generated/app_localizations.dart';

/// Android WorkManager unique task name.
const String kAndroidSyncTask = 'klms_periodic_sync';

/// iOS BGAppRefreshTask identifier — must match Info.plist
/// (BGTaskSchedulerPermittedIdentifiers) and AppDelegate.swift.
const String kIosSyncTask = 'jp.keio.klms.klmsApp.periodicSync';

/// Entry point invoked by the OS in a background isolate.
@pragma('vm:entry-point')
void backgroundSyncDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      return await runBackgroundSync();
    } catch (_) {
      // Report failure so the OS may retry later.
      return false;
    }
  });
}

/// Runs one headless sync (no UI): fetch → DB → notifications.
Future<bool> runBackgroundSync() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  // The background isolate has its own SharedPreferences cache.
  await prefs.reload();
  final stored = prefs.getString(kSettingsPrefsKey);
  var settings = stored != null
      ? AppSettings.fromJsonString(stored)
      : const AppSettings();

  final auth = AuthService();
  if (!await auth.isLoggedIn()) return true; // nothing to do, don't retry

  final notifications = NotificationService();
  await notifications.init();

  final database = await AppDatabase.open();
  try {
    final client = CanvasClient(auth);
    final sync = SyncService(
      client: client,
      courseRepository: CourseRepository(database),
      taskRepository: TaskRepository(database),
      announcementRepository: AnnouncementRepository(database),
      notifications: notifications,
    );
    await sync.sync(
      settings: settings,
      l10n: _resolveL10n(settings.localeCode),
      isFirstSync: settings.lastSyncedAt == null,
    );
    settings = settings.copyWith(lastSyncedAt: DateTime.now());
    await prefs.setString(kSettingsPrefsKey, settings.toJsonString());
    return true;
  } on CanvasAuthException {
    // Session expired: the user must sign in again from the UI.
    return true;
  } finally {
    await database.close();
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

/// Registers / re-registers / cancels the periodic background sync
/// according to the current settings.
class BackgroundSyncScheduler {
  BackgroundSyncScheduler._();

  static bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static bool _initialized = false;

  static Future<void> ensureInitialized() async {
    if (!_supported || _initialized) return;
    try {
      await Workmanager().initialize(backgroundSyncDispatcher);
      _initialized = true;
    } catch (_) {
      // Workmanager unavailable (e.g. tests): background sync is skipped.
    }
  }

  static Future<void> apply(AppSettings settings) async {
    if (!_supported) return;
    await ensureInitialized();
    if (!_initialized) return;
    try {
      if (settings.backgroundSyncMinutes <= 0) {
        await Workmanager().cancelAll();
        return;
      }
      if (Platform.isAndroid) {
        await Workmanager().registerPeriodicTask(
          kAndroidSyncTask,
          kAndroidSyncTask,
          frequency: Duration(
              minutes: settings.backgroundSyncMinutes.clamp(15, 24 * 60)),
          constraints: Constraints(networkType: NetworkType.connected),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        );
      } else {
        // iOS frequency is fixed natively in AppDelegate.swift; the OS
        // decides the actual cadence based on app usage.
        await Workmanager().registerPeriodicTask(kIosSyncTask, kIosSyncTask);
      }
    } catch (_) {}
  }
}
