import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis/tasks/v1.dart' as gtasks;
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
      : _googleSignIn = GoogleSignIn(scopes: [
          // Full calendar scope so we can create a dedicated calendar, plus
          // the Tasks scope for the optional Google Tasks sync. Requested
          // together so the user consents once.
          gcal.CalendarApi.calendarScope,
          gtasks.TasksApi.tasksScope,
        ]);

  final GoogleSignIn _googleSignIn;

  /// SharedPreferences key for the persisted taskId -> Google eventId map.
  static const String _eventMapPrefsKey = 'gcal_event_map_v1';

  /// SharedPreferences key for the dedicated calendar's id.
  static const String _calendarIdPrefsKey = 'gcal_calendar_id_v1';

  /// SharedPreferences keys for the Google Tasks sync (task list + id map).
  static const String _taskListIdPrefsKey = 'gtasks_list_id_v1';
  static const String _taskMapPrefsKey = 'gtasks_map_v1';

  /// Title of the dedicated calendar / task list deadlines are written to.
  static const String _calendarSummary = '課題';

  /// Returns the id of the dedicated "KLMS 課題" calendar, creating it (once)
  /// if needed. Falls back to 'primary' if creation is not permitted.
  Future<String> _resolveCalendarId(
      gcal.CalendarApi api, SharedPreferences prefs) async {
    final stored = prefs.getString(_calendarIdPrefsKey);
    if (stored != null && stored.isNotEmpty) {
      try {
        await api.calendars.get(stored);
        return stored;
      } on gcal.DetailedApiRequestError catch (e) {
        if (e.status != 404) return stored;
        // Calendar was deleted on Google's side: recreate below.
      } catch (_) {
        return stored;
      }
    }
    try {
      final created =
          await api.calendars.insert(gcal.Calendar(summary: _calendarSummary));
      final id = created.id;
      if (id != null) {
        await prefs.setString(_calendarIdPrefsKey, id);
        return id;
      }
    } catch (e) {
      debugPrint('GoogleCalendarService: create calendar failed: $e');
    }
    return 'primary';
  }

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
      final calendarId = await _resolveCalendarId(api, prefs);

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
              await api.events.patch(event, calendarId, existingEventId);
              continue;
            } on gcal.DetailedApiRequestError catch (e) {
              if (e.status != 404) rethrow;
              // Event was deleted on the calendar side: fall through to
              // recreating it.
            }
          }
          final created = await api.events.insert(event, calendarId);
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
            await api.events.delete(calendarId, eventId);
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

  /// Returns the id of the dedicated "課題" task list, creating it once if
  /// needed.
  Future<String?> _resolveTaskListId(
      gtasks.TasksApi api, SharedPreferences prefs) async {
    final stored = prefs.getString(_taskListIdPrefsKey);
    if (stored != null && stored.isNotEmpty) {
      try {
        await api.tasklists.get(stored);
        return stored;
      } on gtasks.DetailedApiRequestError catch (e) {
        if (e.status != 404) return stored;
      } catch (_) {
        return stored;
      }
    }
    try {
      final created = await api.tasklists
          .insert(gtasks.TaskList(title: _calendarSummary));
      final id = created.id;
      if (id != null) {
        await prefs.setString(_taskListIdPrefsKey, id);
        return id;
      }
    } catch (e) {
      debugPrint('GoogleCalendarService: create task list failed: $e');
    }
    return null;
  }

  /// One-way sync of incomplete, non-excluded, dated tasks into a dedicated
  /// Google Tasks list. Completed / removed / excluded tasks are deleted.
  Future<void> syncToTasks({
    required List<TaskItem> tasks,
    required Map<int, Course> coursesById,
    required AppSettings settings,
    required SharedPreferences prefs,
  }) async {
    try {
      if (!settings.googleTasksSync) return;
      final account = await currentOrSilent;
      if (account == null) return;
      final client = await _googleSignIn.authenticatedClient();
      if (client == null) return;
      final api = gtasks.TasksApi(client);
      final listId = await _resolveTaskListId(api, prefs);
      if (listId == null) return;

      final mapping = _loadNamedMapping(prefs, _taskMapPrefsKey);

      final targets = {
        for (final t in tasks)
          if (!t.isCompleted &&
              t.dueAt != null &&
              !settings.excludesTask(t.title, t.courseId))
            t.id: t,
      };

      for (final entry in targets.entries) {
        final t = entry.value;
        final key = entry.key.toString();
        final task = gtasks.Task(
          title: decorateTaskTitle(t.title, coursesById[t.courseId]),
          notes: t.htmlUrl,
          // Google Tasks only honours the date part of `due` (RFC3339).
          due: t.dueAt!.toUtc().toIso8601String(),
        );
        try {
          final existing = mapping[key];
          if (existing != null) {
            try {
              await api.tasks.patch(task, listId, existing);
              continue;
            } on gtasks.DetailedApiRequestError catch (e) {
              if (e.status != 404) rethrow;
            }
          }
          final created = await api.tasks.insert(task, listId);
          if (created.id != null) mapping[key] = created.id!;
        } catch (e) {
          debugPrint('GoogleCalendarService: task sync failed $key: $e');
        }
      }

      final staleKeys =
          mapping.keys.where((k) => !targets.containsKey(int.tryParse(k)));
      for (final key in staleKeys.toList()) {
        final id = mapping[key];
        if (id != null) {
          try {
            await api.tasks.delete(listId, id);
          } catch (e) {
            debugPrint('GoogleCalendarService: task delete failed $key: $e');
          }
        }
        mapping.remove(key);
      }
      await _saveNamedMapping(prefs, _taskMapPrefsKey, mapping);
    } catch (e) {
      debugPrint('GoogleCalendarService.syncToTasks failed: $e');
    }
  }

  /// Removes the dedicated Google Tasks list (and its tasks), used when the
  /// user turns Google Tasks sync off.
  Future<void> deleteAllTasks(SharedPreferences prefs) async {
    try {
      final account = await currentOrSilent;
      final client =
          account == null ? null : await _googleSignIn.authenticatedClient();
      final listId = prefs.getString(_taskListIdPrefsKey);
      if (client != null && listId != null && listId.isNotEmpty) {
        final api = gtasks.TasksApi(client);
        try {
          await api.tasklists.delete(listId);
        } catch (e) {
          debugPrint('GoogleCalendarService.deleteAllTasks: $e');
        }
      }
    } catch (e) {
      debugPrint('GoogleCalendarService.deleteAllTasks failed: $e');
    } finally {
      await prefs.remove(_taskListIdPrefsKey);
      await prefs.remove(_taskMapPrefsKey);
    }
  }

  /// Best-effort removal of everything this app created, used when the user
  /// disconnects Google Calendar sync entirely: deletes the dedicated calendar
  /// (which takes its events with it), falling back to per-event deletion.
  Future<void> deleteAll(SharedPreferences prefs) async {
    try {
      final account = await currentOrSilent;
      final client =
          account == null ? null : await _googleSignIn.authenticatedClient();
      if (client == null) {
        await prefs.remove(_eventMapPrefsKey);
        await prefs.remove(_calendarIdPrefsKey);
        return;
      }
      final api = gcal.CalendarApi(client);
      final calendarId = prefs.getString(_calendarIdPrefsKey);
      if (calendarId != null && calendarId.isNotEmpty) {
        try {
          await api.calendars.delete(calendarId);
        } catch (e) {
          debugPrint('GoogleCalendarService.deleteAll: calendar delete: $e');
          // Fall back to deleting the individual events we tracked.
          final mapping = _loadMapping(prefs);
          for (final eventId in mapping.values) {
            try {
              await api.events.delete(calendarId, eventId);
            } catch (_) {}
          }
        }
      }
      await prefs.remove(_eventMapPrefsKey);
      await prefs.remove(_calendarIdPrefsKey);
    } catch (e) {
      debugPrint('GoogleCalendarService.deleteAll failed: $e');
      await prefs.remove(_eventMapPrefsKey);
      await prefs.remove(_calendarIdPrefsKey);
    }
  }

  Map<String, String> _loadMapping(SharedPreferences prefs) =>
      _loadNamedMapping(prefs, _eventMapPrefsKey);

  Future<void> _saveMapping(
          SharedPreferences prefs, Map<String, String> mapping) =>
      _saveNamedMapping(prefs, _eventMapPrefsKey, mapping);

  Map<String, String> _loadNamedMapping(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v as String));
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveNamedMapping(
      SharedPreferences prefs, String key, Map<String, String> mapping) async {
    await prefs.setString(key, jsonEncode(mapping));
  }
}
