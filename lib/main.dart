import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'background/background_sync.dart';
import 'data/auth/auth_service.dart';
import 'data/db/app_database.dart';
import 'data/notifications/notification_service.dart';
import 'data/providers.dart';
import 'data/settings/app_settings.dart';
import 'data/settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load locale data so weekday/date names follow the app language.
  await initializeDateFormatting();

  final prefs = await SharedPreferences.getInstance();
  final database = await AppDatabase.open();
  final notifications = NotificationService();
  await notifications.init();

  // Restore persisted LMS cookies into the WebView store so a logged-in
  // session survives app restarts (iOS drops session-only cookies on kill).
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await AuthService().restoreCookies();
    } catch (_) {}
  }

  final stored = prefs.getString(kSettingsPrefsKey);
  final settings = stored != null
      ? AppSettings.fromJsonString(stored)
      : const AppSettings();
  await BackgroundSyncScheduler.apply(settings);

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      // Enables tap-to-complete on the Android task-list widget's check
      // icon (see lib/background/background_sync.dart).
      await HomeWidget.registerInteractivityCallback(widgetInteractivityCallback);
    } catch (_) {
      // Not fatal: the widget's check icon simply won't respond.
    }
  }

  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appDatabaseProvider.overrideWithValue(database),
      notificationServiceProvider.overrideWithValue(notifications),
    ],
    child: const KlmsApp(),
  ));
}
