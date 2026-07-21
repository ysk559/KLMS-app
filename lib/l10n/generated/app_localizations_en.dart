// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'KLMS';

  @override
  String get tabHome => 'Home';

  @override
  String get tabTasks => 'Tasks';

  @override
  String get tabPages => 'Pages';

  @override
  String get tabTimetable => 'Timetable';

  @override
  String get tabSettings => 'Settings';

  @override
  String lastUpdated(String time) {
    return 'Last updated: $time';
  }

  @override
  String get neverUpdated => 'Never updated';

  @override
  String get refreshNow => 'Refresh now';

  @override
  String get syncing => 'Syncing...';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String get upcomingTasks => 'Upcoming tasks';

  @override
  String get homeNextClass => 'Next class';

  @override
  String get homeCurrentClass => 'In class now';

  @override
  String get homeNoClass => 'No upcoming classes';

  @override
  String get recentAnnouncements => 'Recent announcements';

  @override
  String get seeAll => 'See all';

  @override
  String get noTasks => 'No tasks';

  @override
  String get noAnnouncements => 'No announcements';

  @override
  String get notLoggedIn => 'Not signed in to KLMS';

  @override
  String get loginPrompt =>
      'Sign in to fetch your assignments and courses. Your ID and password are never stored in the app.';

  @override
  String get loginButton => 'Sign in to KLMS';

  @override
  String get loginTitle => 'KLMS Sign-in';

  @override
  String get loginSuccess => 'Signed in';

  @override
  String get logout => 'Sign out';

  @override
  String get logoutConfirm =>
      'Sign out? Stored session credentials will be removed.';

  @override
  String get loggedInAs => 'Signed in';

  @override
  String get filterAll => 'All';

  @override
  String get filterIncomplete => 'To do';

  @override
  String get filterCompleted => 'Done';

  @override
  String get filterHidden => 'Hidden';

  @override
  String get markComplete => 'Mark as done';

  @override
  String get markIncomplete => 'Mark as not done';

  @override
  String dueAt(String time) {
    return 'Due: $time';
  }

  @override
  String get noDueDate => 'No due date';

  @override
  String get completedOnLms => 'Submitted on LMS';

  @override
  String get completedByUser => 'Completed manually';

  @override
  String get conflictWarning =>
      'Marked done manually, but not submitted on the LMS';

  @override
  String get conflictNotificationTitle => 'Unsubmitted assignment';

  @override
  String conflictNotificationBody(String task) {
    return '\"$task\" is marked done, but not submitted on the LMS';
  }

  @override
  String get deadlineNotificationTitle => 'Assignment due soon';

  @override
  String deadlineNotificationBody(String task, String time) {
    return '\"$task\" is due at $time';
  }

  @override
  String get announcementNotificationTitle => 'New announcement';

  @override
  String get courses => 'Courses';

  @override
  String get modules => 'Modules';

  @override
  String get announcements => 'Announcements';

  @override
  String get assignments => 'Assignments';

  @override
  String get grades => 'Grades';

  @override
  String get noModules => 'No modules';

  @override
  String get openInBrowser => 'Open in browser';

  @override
  String get openOnLms => 'Open on LMS';

  @override
  String points(String points) {
    return '$points pts';
  }

  @override
  String get today => 'Today';

  @override
  String get noClassToday => 'No classes today';

  @override
  String get nextClass => 'Next class';

  @override
  String period(int n) {
    return 'Period $n';
  }

  @override
  String get settings => 'Settings';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get themeMode => 'Theme';

  @override
  String get themeSystem => 'Follow system';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Follow system';

  @override
  String get sectionNotifications => 'Notifications';

  @override
  String get announcementNotifications => 'Announcement notifications';

  @override
  String get announcementNotificationsDesc =>
      'Push a notification for new announcements';

  @override
  String get deadlineReminder => 'Deadline reminders';

  @override
  String get deadlineReminderDesc =>
      'Notify before due time of incomplete assignments';

  @override
  String get reminderTiming => 'Reminder timing';

  @override
  String reminderTimingValue(int h, int m) {
    return '${h}h ${m}m before due';
  }

  @override
  String get hoursUnit => 'h';

  @override
  String get minutesUnit => 'min';

  @override
  String get minutesBeforeUnit => 'min before';

  @override
  String get excludeApplyToList => 'Also hide from the task list';

  @override
  String get excludeApplyToListDesc =>
      'When off, exclusions only apply to reminders';

  @override
  String get close => 'Close';

  @override
  String get excludeWords => 'Excluded words';

  @override
  String get excludeWordsDesc =>
      'Skip assignments whose title contains these words (e.g. resubmission)';

  @override
  String get addWord => 'Add word';

  @override
  String get excludeCourses => 'Excluded courses';

  @override
  String get excludeCoursesDesc => 'Skip assignments from selected courses';

  @override
  String get sectionCourses => 'Courses';

  @override
  String get courseNicknames => 'Course nicknames';

  @override
  String get courseNicknamesDesc => 'Shown as [nickname] before task titles';

  @override
  String get nicknameHint => 'Nickname (e.g. Jexp)';

  @override
  String get sectionTimetable => 'Timetable';

  @override
  String get timetableSettings => 'Timetable settings';

  @override
  String get timetableDays => 'Days';

  @override
  String timetableDaysValue(String start, String end) {
    return '$start - $end';
  }

  @override
  String get periodsPerDay => 'Periods per day';

  @override
  String get periodTimes => 'Period times';

  @override
  String get startTime => 'Start';

  @override
  String get endTime => 'End';

  @override
  String get sectionSync => 'Sync';

  @override
  String get backgroundSync => 'Background sync';

  @override
  String get backgroundSyncDesc =>
      'Fetch assignments and announcements automatically even when the app is closed (required for announcement notifications)';

  @override
  String get syncIntervalOff => 'Off';

  @override
  String everyMinutes(int m) {
    return 'Every $m min';
  }

  @override
  String everyHours(int h) {
    return 'Every $h h';
  }

  @override
  String get iosSyncNote =>
      'On iOS the actual interval is decided by the OS (depends on usage)';

  @override
  String get googleCalendarSync => 'Google Calendar sync';

  @override
  String get googleCalendarSyncDesc =>
      'Add incomplete task deadlines to your own Google Calendar';

  @override
  String get googleTasksSync => 'Sync to Google Tasks';

  @override
  String get googleTasksSyncDesc =>
      'Add incomplete tasks to a dedicated Google Tasks list';

  @override
  String googleCalendarConnected(String email) {
    return 'Connected: $email';
  }

  @override
  String get googleCalendarDisconnect =>
      'Disconnect (also removes created events)';

  @override
  String get googleCalendarConnectFailed =>
      'Failed to connect your Google account';

  @override
  String get sectionAccount => 'Account';

  @override
  String get accessToken => 'Access token (advanced)';

  @override
  String get accessTokenDesc =>
      'Enter a token generated in KLMS settings to use token auth';

  @override
  String get sectionAbout => 'About';

  @override
  String get contact => 'Contact';

  @override
  String get licenses => 'Licenses';

  @override
  String get version => 'Version';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get ok => 'OK';

  @override
  String get retry => 'Retry';
}
