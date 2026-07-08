import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

/// Overridden in main() with the real instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('overridden in main()'),
);

final settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

class SettingsController extends Notifier<AppSettings> {
  static const _prefsKey = 'app_settings_v1';

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
  }

  void _persist() {
    ref
        .read(sharedPreferencesProvider)
        .setString(_prefsKey, state.toJsonString());
  }
}
