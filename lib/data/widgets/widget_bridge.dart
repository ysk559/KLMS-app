import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:home_widget/home_widget.dart';

import '../models/course.dart';
import '../models/task_item.dart';
import '../repositories/course_repository.dart';
import '../repositories/task_repository.dart';
import '../settings/app_settings.dart';

/// Pushes task/timetable snapshots to the platform widget storage
/// (Android: SharedPreferences via home_widget / iOS: App Group) and asks
/// the OS to redraw the home-screen widgets.
class WidgetBridge {
  WidgetBridge._();

  /// Must match the App Group configured for the iOS widget extension.
  static const String iosAppGroup = 'group.jp.keio.klms.klmsApp';

  static const _androidWidgets = [
    'NextClassWidgetProvider',
    'TodayTimetableWidgetProvider',
    'TaskListWidgetProvider',
  ];

  static bool get _supported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> updateFromRepos({
    required TaskRepository taskRepository,
    required CourseRepository courseRepository,
    required AppSettings settings,
  }) async {
    if (!_supported) return;
    try {
      final tasks = await taskRepository.getIncomplete();
      final courses = await courseRepository.getAll();
      await _update(tasks: tasks, courses: courses, settings: settings);
    } catch (_) {}
  }

  static Future<void> _update({
    required List<TaskItem> tasks,
    required List<Course> courses,
    required AppSettings settings,
  }) async {
    if (Platform.isIOS) {
      await HomeWidget.setAppGroupId(iosAppGroup);
    }
    final coursesById = {for (final c in courses) c.id: c};

    final visibleTasks = settings.excludeAlsoFromList
        ? tasks.where((t) => !settings.excludesTask(t.title, t.courseId))
        : tasks;
    final taskJson = jsonEncode([
      for (final t in visibleTasks.take(10))
        {
          't': t.title,
          // Course label (nickname when set) rendered separately by widgets.
          'c': coursesById[t.courseId]?.shortLabel ?? '',
          if (t.dueAt != null) 'd': t.dueAt!.toLocal().toIso8601String(),
        },
    ]);

    final entries = <Map<String, dynamic>>[];
    for (final course in courses) {
      if (course.hidden) continue;
      for (final slot in course.parsed.slots) {
        entries.add({
          'd': slot.weekday,
          'p': slot.period,
          // Timetable always shows the real course title (no nicknames).
          'n': course.parsed.displayName,
          'id': course.id,
          if (course.parsed.room != null) 'r': course.parsed.room,
        });
      }
    }
    final timetableJson = jsonEncode({
      'firstDay': settings.timetableFirstDay,
      'lastDay': settings.timetableLastDay,
      'periods': settings.periodsPerDay,
      'times': [
        for (final t in settings.periodTimes)
          {'s': t.startMinutes, 'e': t.endMinutes},
      ],
      'entries': entries,
    });

    await HomeWidget.saveWidgetData<String>('widget_tasks', taskJson);
    await HomeWidget.saveWidgetData<String>('widget_timetable', timetableJson);
    await HomeWidget.saveWidgetData<String>(
        'widget_updated_at', DateTime.now().toIso8601String());

    for (final name in _androidWidgets) {
      await HomeWidget.updateWidget(
        qualifiedAndroidName: 'jp.keio.klms.klms_app.widgets.$name',
        iOSName: 'KlmsWidgets',
      );
    }
  }
}
