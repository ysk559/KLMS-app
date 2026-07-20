import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers.dart';
import '../widgets/widget_bridge.dart';
import 'app_settings.dart';

/// Overridden in main() with the real instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('overridden in main()'),
);

final settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

/// SharedPreferences key for the serialized [AppSettings]. Shared with the
/// background isolate (see lib/background/background_sync.dart).
const String kSettingsPrefsKey = 'app_settings_v1';

class SettingsController extends Notifier<AppSettings> {
  static const _prefsKey = kSettingsPrefsKey;

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final stored = prefs.getString(_prefsKey);
    if (stored != null) {
      try {
        return AppSettings.fromJsonString(stored);
      } catch (_) {
        // Corrupt settings: fall back to defaults.
      }
    }
    return const AppSettings();
  }

  void update(AppSettings Function(AppSettings) updater) {
    state = updater(state);
    _persist();
    _refreshWidgets();
  }

  void _persist() {
    ref
        .read(sharedPreferencesProvider)
        .setString(_prefsKey, state.toJsonString());
  }

  /// Keep the home-screen widgets in sync with settings that affect them
  /// (excluded words/courses, timetable range, nicknames) without waiting for
  /// the next background sync. Fire-and-forget; failures are swallowed inside
  /// WidgetBridge.
  void _refreshWidgets() {
    WidgetBridge.updateFromRepos(
      taskRepository: ref.read(taskRepositoryProvider),
      courseRepository: ref.read(courseRepositoryProvider),
      settings: state,
    );
  }
}
