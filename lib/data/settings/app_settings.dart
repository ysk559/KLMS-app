import 'dart:convert';

import 'package:flutter/material.dart';

/// Start/end of one class period, as minutes from midnight.
class PeriodTime {
  const PeriodTime({required this.startMinutes, required this.endMinutes});

  final int startMinutes;
  final int endMinutes;

  TimeOfDay get start => TimeOfDay(hour: startMinutes ~/ 60, minute: startMinutes % 60);
  TimeOfDay get end => TimeOfDay(hour: endMinutes ~/ 60, minute: endMinutes % 60);

  String get startLabel => _fmt(startMinutes);
  String get endLabel => _fmt(endMinutes);

  static String _fmt(int m) =>
      '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {'s': startMinutes, 'e': endMinutes};

  factory PeriodTime.fromJson(Map<String, dynamic> json) =>
      PeriodTime(startMinutes: json['s'] as int, endMinutes: json['e'] as int);
}

/// Keio standard period times (used as defaults; user-configurable).
const List<PeriodTime> kDefaultPeriodTimes = [
  PeriodTime(startMinutes: 9 * 60, endMinutes: 10 * 60 + 30),
  PeriodTime(startMinutes: 10 * 60 + 45, endMinutes: 12 * 60 + 15),
  PeriodTime(startMinutes: 13 * 60, endMinutes: 14 * 60 + 30),
  PeriodTime(startMinutes: 14 * 60 + 45, endMinutes: 16 * 60 + 15),
  PeriodTime(startMinutes: 16 * 60 + 30, endMinutes: 18 * 60),
  PeriodTime(startMinutes: 18 * 60 + 10, endMinutes: 19 * 60 + 40),
];

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.localeCode,
    this.announcementNotifications = true,
    this.deadlineReminderEnabled = true,
    this.reminderHours = 1,
    this.reminderMinutes = 0,
    this.excludeWords = const [],
    this.excludedCourseIds = const {},
    this.excludeAlsoFromList = true,
    this.timetableFirstDay = DateTime.monday,
    this.timetableLastDay = DateTime.friday,
    this.periodsPerDay = 6,
    this.periodTimes = kDefaultPeriodTimes,
    this.backgroundSyncMinutes = 30,
    this.lastSyncedAt,
    this.googleCalendarSync = false,
    this.googleTasksSync = false,
  });

  final ThemeMode themeMode;

  /// null = follow system locale.
  final String? localeCode;
  final bool announcementNotifications;
  final bool deadlineReminderEnabled;
  final int reminderHours;
  final int reminderMinutes;
  final List<String> excludeWords;
  final Set<int> excludedCourseIds;

  /// Whether excluded words/courses also hide tasks from the task list
  /// (and widgets), not just from reminders.
  final bool excludeAlsoFromList;
  final int timetableFirstDay;
  final int timetableLastDay;
  final int periodsPerDay;
  final List<PeriodTime> periodTimes;

  /// Background sync interval in minutes; 0 disables background sync.
  /// (Android: WorkManager honors this, min 15. iOS: cadence is up to the OS.)
  final int backgroundSyncMinutes;
  final DateTime? lastSyncedAt;

  /// Whether incomplete task deadlines are pushed to the user's own Google
  /// Calendar (one-way, on-device OAuth; see GoogleCalendarService).
  final bool googleCalendarSync;
  final bool googleTasksSync;

  Duration get reminderOffset =>
      Duration(hours: reminderHours, minutes: reminderMinutes);

  /// True when a task matches the exclusion rules (word or course).
  bool excludesTask(String title, int courseId) {
    if (excludedCourseIds.contains(courseId)) return true;
    final lower = title.toLowerCase();
    return excludeWords
        .any((w) => w.isNotEmpty && lower.contains(w.toLowerCase()));
  }

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? localeCode,
    bool clearLocale = false,
    bool? announcementNotifications,
    bool? deadlineReminderEnabled,
    int? reminderHours,
    int? reminderMinutes,
    List<String>? excludeWords,
    Set<int>? excludedCourseIds,
    bool? excludeAlsoFromList,
    int? timetableFirstDay,
    int? timetableLastDay,
    int? periodsPerDay,
    List<PeriodTime>? periodTimes,
    int? backgroundSyncMinutes,
    DateTime? lastSyncedAt,
    bool? googleCalendarSync,
    bool? googleTasksSync,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      localeCode: clearLocale ? null : (localeCode ?? this.localeCode),
      announcementNotifications:
          announcementNotifications ?? this.announcementNotifications,
      deadlineReminderEnabled:
          deadlineReminderEnabled ?? this.deadlineReminderEnabled,
      reminderHours: reminderHours ?? this.reminderHours,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      excludeWords: excludeWords ?? this.excludeWords,
      excludedCourseIds: excludedCourseIds ?? this.excludedCourseIds,
      excludeAlsoFromList: excludeAlsoFromList ?? this.excludeAlsoFromList,
      timetableFirstDay: timetableFirstDay ?? this.timetableFirstDay,
      timetableLastDay: timetableLastDay ?? this.timetableLastDay,
      periodsPerDay: periodsPerDay ?? this.periodsPerDay,
      periodTimes: periodTimes ?? this.periodTimes,
      backgroundSyncMinutes:
          backgroundSyncMinutes ?? this.backgroundSyncMinutes,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      googleCalendarSync: googleCalendarSync ?? this.googleCalendarSync,
      googleTasksSync: googleTasksSync ?? this.googleTasksSync,
    );
  }

  String toJsonString() => jsonEncode({
        'themeMode': themeMode.name,
        'localeCode': localeCode,
        'announcementNotifications': announcementNotifications,
        'deadlineReminderEnabled': deadlineReminderEnabled,
        'reminderHours': reminderHours,
        'reminderMinutes': reminderMinutes,
        'excludeWords': excludeWords,
        'excludedCourseIds': excludedCourseIds.toList(),
        'excludeAlsoFromList': excludeAlsoFromList,
        'timetableFirstDay': timetableFirstDay,
        'timetableLastDay': timetableLastDay,
        'periodsPerDay': periodsPerDay,
        'periodTimes': periodTimes.map((e) => e.toJson()).toList(),
        'backgroundSyncMinutes': backgroundSyncMinutes,
        'lastSyncedAt': lastSyncedAt?.toIso8601String(),
        'googleCalendarSync': googleCalendarSync,
        'googleTasksSync': googleTasksSync,
      });

  factory AppSettings.fromJsonString(String source) {
    final json = jsonDecode(source) as Map<String, dynamic>;
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      localeCode: json['localeCode'] as String?,
      announcementNotifications:
          json['announcementNotifications'] as bool? ?? true,
      deadlineReminderEnabled: json['deadlineReminderEnabled'] as bool? ?? true,
      reminderHours: json['reminderHours'] as int? ?? 1,
      reminderMinutes: json['reminderMinutes'] as int? ?? 0,
      excludeWords:
          (json['excludeWords'] as List?)?.cast<String>() ?? const [],
      excludedCourseIds:
          ((json['excludedCourseIds'] as List?)?.cast<int>() ?? const [])
              .toSet(),
      excludeAlsoFromList: json['excludeAlsoFromList'] as bool? ?? true,
      timetableFirstDay: json['timetableFirstDay'] as int? ?? DateTime.monday,
      timetableLastDay: json['timetableLastDay'] as int? ?? DateTime.friday,
      periodsPerDay: json['periodsPerDay'] as int? ?? 6,
      periodTimes: (json['periodTimes'] as List?)
              ?.map((e) => PeriodTime.fromJson(e as Map<String, dynamic>))
              .toList() ??
          kDefaultPeriodTimes,
      backgroundSyncMinutes: json['backgroundSyncMinutes'] as int? ?? 30,
      lastSyncedAt: json['lastSyncedAt'] != null
          ? DateTime.tryParse(json['lastSyncedAt'] as String)
          : null,
      googleCalendarSync: json['googleCalendarSync'] as bool? ?? false,
      googleTasksSync: json['googleTasksSync'] as bool? ?? false,
    );
  }
}
