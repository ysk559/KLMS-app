import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/formatting.dart';
import '../models/course.dart';
import '../models/task_item.dart';
import '../settings/app_settings.dart';

/// One-way sync of incomplete task deadlines into the signed-in user's own
/// Google Calendar ("primary"). No service account, no server: everything
/// runs on-device using an OAuth client the user consents to.
///
/// Every public method here is defensive: a failure (no network, revoked
/// consent, API error, ...) must never break the caller's own sync flow, so
/// all of them catch broadly, log, and return.
class GoogleCalendarService {
  GoogleCalendarService()
      : _googleSignIn =
            GoogleSignIn(scopes: [gcal.CalendarApi.calendarEventsScope]);

  final GoogleSignIn _googleSignIn;

  /// SharedPreferences key for the persisted taskId -> Google eventId map.
  static const String _eventMapPrefsKey = 'gcal_event_map_v1';

  /// Interactive sign-in (shows the Google account picker / consent screen).
  /// Only ever call this from user-initiated UI actions — never from a
  /// background isolate.
  Future<GoogleSignInAccount?> connect() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      debugPrint('GoogleCalendarService.connect failed: $e');
      return null;
    }
  }

  /// Signs out of the Google account used for calendar sync. Does not touch
  /// any events already created; callers that want that should use
  /// [deleteAll] first.
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('GoogleCalendarService.disconnect failed: $e');
    }
  }

  /// The currently signed-in account, or a silent (non-interactive) sign-in
  /// attempt. Safe to call from a background isolate.
  Future<GoogleSignInAccount?> get currentOrSilent async {
    try {
      return _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    } catch (e) {
      debugPrint('GoogleCalendarService.currentOrSilent failed: $e');
      return null;
    }
  }

  /// Pushes the current set of incomplete, non-excluded, dated tasks to
  /// Google Calendar, and removes any previously-created events that no
  /// longer qualify (completed / removed / newly excluded).
  Future<void> syncTasks({
    required List<TaskItem> tasks,
    required Map<int, Course> coursesById,
    required AppSettings settings,
    required SharedPreferences prefs,
  }) async {
    try {
      if (!settings.googleCalendarSync) return;
      final account = await currentOrSilent;
      if (account == null) return;

      final client = await _googleSignIn.authenticatedClient();
      if (client == null) return;
      final api = gcal.CalendarApi(client);

      final mapping = _loadMapping(prefs);

      final targets = {
        for (final t in tasks)
          if (!t.isCompleted &&
              t.dueAt != null &&
              !settings.excludesTask(t.title, t.courseId))
            t.id: t,
      };

      for (final entry in targets.entries) {
        final task = entry.value;
        final due = task.dueAt!.toUtc();
        final event = gcal.Event(
          summary: decorateTaskTitle(task.title, coursesById[task.courseId]),
          description: task.htmlUrl,
          start: gcal.EventDateTime(
              dateTime: due.subtract(const Duration(minutes: 30))),
          end: gcal.EventDateTime(dateTime: due),
        );

        final key = entry.key.toString();
        final existingEventId = mapping[key];
        try {
          if (existingEventId != null) {
            try {
              await api.events.patch(event, 'primary', existingEventId);
              continue;
            } on gcal.DetailedApiRequestError catch (e) {
              if (e.status != 404) rethrow;
              // Event was deleted on the calendar side: fall through to
              // recreating it.
            }
          }
          final created = await api.events.insert(event, 'primary');
          if (created.id != null) mapping[key] = created.id!;
        } catch (e) {
          debugPrint('GoogleCalendarService: failed to sync task $key: $e');
        }
      }

      final staleKeys =
          mapping.keys.where((k) => !targets.containsKey(int.tryParse(k)));
      for (final key in staleKeys.toList()) {
        final eventId = mapping[key];
        if (eventId != null) {
          try {
            await api.events.delete('primary', eventId);
          } catch (e) {
            // Already deleted / not found / offline: ignore, drop mapping
            // anyway so we don't retry forever.
            debugPrint('GoogleCalendarService: delete failed for $key: $e');
          }
        }
        mapping.remove(key);
      }

      await _saveMapping(prefs, mapping);
    } catch (e) {
      debugPrint('GoogleCalendarService.syncTasks failed: $e');
    }
  }

  /// Best-effort removal of every event this app has ever created, used
  /// when the user disconnects Google Calendar sync entirely.
  Future<void> deleteAll(SharedPreferences prefs) async {
    try {
      final account = await currentOrSilent;
      if (account == null) {
        await prefs.remove(_eventMapPrefsKey);
        return;
      }
      final client = await _googleSignIn.authenticatedClient();
      if (client == null) {
        await prefs.remove(_eventMapPrefsKey);
        return;
      }
      final api = gcal.CalendarApi(client);
      final mapping = _loadMapping(prefs);
      for (final eventId in mapping.values) {
        try {
          await api.events.delete('primary', eventId);
        } catch (e) {
          debugPrint('GoogleCalendarService.deleteAll: delete failed: $e');
        }
      }
      await prefs.remove(_eventMapPrefsKey);
    } catch (e) {
      debugPrint('GoogleCalendarService.deleteAll failed: $e');
      await prefs.remove(_eventMapPrefsKey);
    }
  }

  Map<String, String> _loadMapping(SharedPreferences prefs) {
    final raw = prefs.getString(_eventMapPrefsKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveMapping(
      SharedPreferences prefs, Map<String, String> mapping) async {
    await prefs.setString(_eventMapPrefsKey, jsonEncode(mapping));
  }
}
