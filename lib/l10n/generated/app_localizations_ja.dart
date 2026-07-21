// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'KLMS';

  @override
  String get tabHome => 'ホーム';

  @override
  String get tabTasks => '課題一覧';

  @override
  String get tabPages => 'ページ';

  @override
  String get tabTimetable => '時間割';

  @override
  String get tabSettings => '設定';

  @override
  String lastUpdated(String time) {
    return '最終更新: $time';
  }

  @override
  String get neverUpdated => '未更新';

  @override
  String get refreshNow => '今すぐ更新';

  @override
  String get syncing => '同期中...';

  @override
  String get syncFailed => '同期に失敗しました';

  @override
  String get upcomingTasks => '直近の課題';

  @override
  String get homeNextClass => '次の授業';

  @override
  String get homeCurrentClass => '今の授業';

  @override
  String get homeNoClass => '今後の授業予定はありません';

  @override
  String get recentAnnouncements => '最近のアナウンス';

  @override
  String get seeAll => 'すべて見る';

  @override
  String get noTasks => '課題はありません';

  @override
  String get noAnnouncements => 'アナウンスはありません';

  @override
  String get notLoggedIn => 'KLMSにログインしていません';

  @override
  String get loginPrompt => 'ログインすると課題やコースを取得できます。ID・パスワードはアプリに保存されません。';

  @override
  String get loginButton => 'KLMSにログイン';

  @override
  String get loginTitle => 'KLMSログイン';

  @override
  String get loginSuccess => 'ログインしました';

  @override
  String get logout => 'ログアウト';

  @override
  String get logoutConfirm => 'ログアウトしますか?保存された認証情報が削除されます。';

  @override
  String get loggedInAs => 'ログイン済み';

  @override
  String get filterAll => 'すべて';

  @override
  String get filterIncomplete => '未完了';

  @override
  String get filterCompleted => '完了';

  @override
  String get filterHidden => '非表示';

  @override
  String get markComplete => '完了にする';

  @override
  String get markIncomplete => '未完了に戻す';

  @override
  String dueAt(String time) {
    return '締切: $time';
  }

  @override
  String get noDueDate => '締切なし';

  @override
  String get completedOnLms => 'LMSで提出済み';

  @override
  String get completedByUser => '手動で完了';

  @override
  String get conflictWarning => '手動で完了にしましたが、LMS上では未提出です';

  @override
  String get conflictNotificationTitle => '未提出の課題があります';

  @override
  String conflictNotificationBody(String task) {
    return '「$task」は完了にしましたが、LMS上では未提出です';
  }

  @override
  String get deadlineNotificationTitle => '課題の締切が近づいています';

  @override
  String deadlineNotificationBody(String task, String time) {
    return '「$task」の締切は $time です';
  }

  @override
  String get announcementNotificationTitle => '新しいアナウンス';

  @override
  String get courses => 'コース一覧';

  @override
  String get modules => 'モジュール';

  @override
  String get announcements => 'アナウンス';

  @override
  String get assignments => '課題';

  @override
  String get grades => '成績';

  @override
  String get noModules => 'モジュールがありません';

  @override
  String get openInBrowser => 'ブラウザで開く';

  @override
  String get openOnLms => 'LMSで開く';

  @override
  String points(String points) {
    return '$points点';
  }

  @override
  String get today => '今日';

  @override
  String get noClassToday => '今日の授業はありません';

  @override
  String get nextClass => '次の授業';

  @override
  String period(int n) {
    return '$n限';
  }

  @override
  String get settings => '設定';

  @override
  String get sectionAppearance => '外観';

  @override
  String get themeMode => 'テーマ';

  @override
  String get themeSystem => '端末の設定に従う';

  @override
  String get themeLight => 'ライト';

  @override
  String get themeDark => 'ダーク';

  @override
  String get language => '言語';

  @override
  String get languageSystem => '端末の設定に従う';

  @override
  String get sectionNotifications => '通知';

  @override
  String get announcementNotifications => 'アナウンス通知';

  @override
  String get announcementNotificationsDesc => '新しいアナウンスをプッシュ通知します';

  @override
  String get deadlineReminder => '締切リマインダー';

  @override
  String get deadlineReminderDesc => '未完了の課題を締切前に通知します';

  @override
  String get reminderTiming => '通知タイミング';

  @override
  String reminderTimingValue(int h, int m) {
    return '締切の$h時間$m分前';
  }

  @override
  String get hoursUnit => '時間';

  @override
  String get minutesUnit => '分';

  @override
  String get minutesBeforeUnit => '分前';

  @override
  String get excludeApplyToList => '課題一覧からも隠す';

  @override
  String get excludeApplyToListDesc => 'オフにすると除外は通知のみに適用されます';

  @override
  String get close => '閉じる';

  @override
  String get excludeWords => '除外ワード';

  @override
  String get excludeWordsDesc => 'タイトルに含まれる課題を通知しません(例: 再提出)';

  @override
  String get addWord => 'ワードを追加';

  @override
  String get excludeCourses => '除外コース';

  @override
  String get excludeCoursesDesc => '選んだコースの課題を通知しません';

  @override
  String get sectionCourses => 'コース';

  @override
  String get courseNicknames => 'コース略称';

  @override
  String get courseNicknamesDesc => '課題名の前に [略称] として表示されます';

  @override
  String get nicknameHint => '略称(例: Jexp)';

  @override
  String get sectionTimetable => '時間割';

  @override
  String get timetableSettings => '時間割設定';

  @override
  String get timetableDays => '曜日';

  @override
  String timetableDaysValue(String start, String end) {
    return '$start〜$end';
  }

  @override
  String get periodsPerDay => '1日のコマ数';

  @override
  String get periodTimes => '時限の時間';

  @override
  String get startTime => '開始';

  @override
  String get endTime => '終了';

  @override
  String get sectionSync => '同期';

  @override
  String get backgroundSync => 'バックグラウンド同期';

  @override
  String get backgroundSyncDesc => 'アプリを開いていなくても課題・アナウンスを自動取得します(アナウンス通知に必要)';

  @override
  String get syncIntervalOff => 'オフ';

  @override
  String everyMinutes(int m) {
    return '$m分ごと';
  }

  @override
  String everyHours(int h) {
    return '$h時間ごと';
  }

  @override
  String get iosSyncNote => 'iOSでは実行間隔はOSが決定します(利用状況に依存)';

  @override
  String get googleCalendarSync => 'Google Calendar同期';

  @override
  String get googleCalendarSyncDesc => '未完了課題の締切を自分のGoogleカレンダーに登録します';

  @override
  String get googleTasksSync => 'Google Tasksに同期';

  @override
  String get googleTasksSyncDesc => '未完了課題を専用のGoogle Tasksリスト「課題」に追加します';

  @override
  String googleCalendarConnected(String email) {
    return '連携中: $email';
  }

  @override
  String get googleCalendarDisconnect => '連携解除(カレンダーから予定も削除)';

  @override
  String get googleCalendarConnectFailed => 'Googleアカウントの連携に失敗しました';

  @override
  String get sectionAccount => 'アカウント';

  @override
  String get accessToken => 'アクセストークン(上級者向け)';

  @override
  String get accessTokenDesc => 'KLMSの設定で発行したトークンを使う場合は入力してください';

  @override
  String get sectionAbout => 'このアプリについて';

  @override
  String get contact => 'お問い合わせ';

  @override
  String get licenses => 'ライセンス';

  @override
  String get version => 'バージョン';

  @override
  String get save => '保存';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get ok => 'OK';

  @override
  String get retry => '再試行';
}
