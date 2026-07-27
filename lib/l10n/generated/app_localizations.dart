import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_ja.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('ja'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ja, this message translates to:
  /// **'KLMS'**
  String get appTitle;

  /// No description provided for @tabHome.
  ///
  /// In ja, this message translates to:
  /// **'ホーム'**
  String get tabHome;

  /// No description provided for @tabTasks.
  ///
  /// In ja, this message translates to:
  /// **'課題一覧'**
  String get tabTasks;

  /// No description provided for @tabPages.
  ///
  /// In ja, this message translates to:
  /// **'ページ'**
  String get tabPages;

  /// No description provided for @tabTimetable.
  ///
  /// In ja, this message translates to:
  /// **'時間割'**
  String get tabTimetable;

  /// No description provided for @tabSettings.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get tabSettings;

  /// No description provided for @lastUpdated.
  ///
  /// In ja, this message translates to:
  /// **'最終更新: {time}'**
  String lastUpdated(String time);

  /// No description provided for @neverUpdated.
  ///
  /// In ja, this message translates to:
  /// **'未更新'**
  String get neverUpdated;

  /// No description provided for @refreshNow.
  ///
  /// In ja, this message translates to:
  /// **'今すぐ更新'**
  String get refreshNow;

  /// No description provided for @syncing.
  ///
  /// In ja, this message translates to:
  /// **'同期中...'**
  String get syncing;

  /// No description provided for @syncFailed.
  ///
  /// In ja, this message translates to:
  /// **'同期に失敗しました'**
  String get syncFailed;

  /// No description provided for @upcomingTasks.
  ///
  /// In ja, this message translates to:
  /// **'直近の課題'**
  String get upcomingTasks;

  /// No description provided for @homeNextClass.
  ///
  /// In ja, this message translates to:
  /// **'次の授業'**
  String get homeNextClass;

  /// No description provided for @homeCurrentClass.
  ///
  /// In ja, this message translates to:
  /// **'今の授業'**
  String get homeCurrentClass;

  /// No description provided for @homeNoClass.
  ///
  /// In ja, this message translates to:
  /// **'今後の授業予定はありません'**
  String get homeNoClass;

  /// No description provided for @homeThenLabel.
  ///
  /// In ja, this message translates to:
  /// **'この後'**
  String get homeThenLabel;

  /// No description provided for @syncLog.
  ///
  /// In ja, this message translates to:
  /// **'同期ログ'**
  String get syncLog;

  /// No description provided for @syncLogDesc.
  ///
  /// In ja, this message translates to:
  /// **'バックグラウンド更新が動いているか確認できます'**
  String get syncLogDesc;

  /// No description provided for @syncLogEmpty.
  ///
  /// In ja, this message translates to:
  /// **'まだ記録がありません'**
  String get syncLogEmpty;

  /// No description provided for @syncLogClear.
  ///
  /// In ja, this message translates to:
  /// **'ログを消去'**
  String get syncLogClear;

  /// No description provided for @googleAccount.
  ///
  /// In ja, this message translates to:
  /// **'Google連携アカウント'**
  String get googleAccount;

  /// No description provided for @googleNotConnected.
  ///
  /// In ja, this message translates to:
  /// **'未連携'**
  String get googleNotConnected;

  /// No description provided for @googleConnect.
  ///
  /// In ja, this message translates to:
  /// **'Googleアカウントを連携'**
  String get googleConnect;

  /// No description provided for @googleDisconnect.
  ///
  /// In ja, this message translates to:
  /// **'連携を解除'**
  String get googleDisconnect;

  /// No description provided for @googleDisconnectConfirm.
  ///
  /// In ja, this message translates to:
  /// **'連携を解除すると、このアプリが作成したカレンダーとタスクリストを削除します。よろしいですか?'**
  String get googleDisconnectConfirm;

  /// No description provided for @recentAnnouncements.
  ///
  /// In ja, this message translates to:
  /// **'最近のアナウンス'**
  String get recentAnnouncements;

  /// No description provided for @seeAll.
  ///
  /// In ja, this message translates to:
  /// **'すべて見る'**
  String get seeAll;

  /// No description provided for @noTasks.
  ///
  /// In ja, this message translates to:
  /// **'課題はありません'**
  String get noTasks;

  /// No description provided for @noAnnouncements.
  ///
  /// In ja, this message translates to:
  /// **'アナウンスはありません'**
  String get noAnnouncements;

  /// No description provided for @notLoggedIn.
  ///
  /// In ja, this message translates to:
  /// **'KLMSにログインしていません'**
  String get notLoggedIn;

  /// No description provided for @loginPrompt.
  ///
  /// In ja, this message translates to:
  /// **'ログインすると課題やコースを取得できます。ID・パスワードはアプリに保存されません。'**
  String get loginPrompt;

  /// No description provided for @loginButton.
  ///
  /// In ja, this message translates to:
  /// **'KLMSにログイン'**
  String get loginButton;

  /// No description provided for @loginTitle.
  ///
  /// In ja, this message translates to:
  /// **'KLMSログイン'**
  String get loginTitle;

  /// No description provided for @loginSuccess.
  ///
  /// In ja, this message translates to:
  /// **'ログインしました'**
  String get loginSuccess;

  /// No description provided for @logout.
  ///
  /// In ja, this message translates to:
  /// **'ログアウト'**
  String get logout;

  /// No description provided for @logoutConfirm.
  ///
  /// In ja, this message translates to:
  /// **'ログアウトしますか?保存された認証情報が削除されます。'**
  String get logoutConfirm;

  /// No description provided for @loggedInAs.
  ///
  /// In ja, this message translates to:
  /// **'ログイン済み'**
  String get loggedInAs;

  /// No description provided for @filterAll.
  ///
  /// In ja, this message translates to:
  /// **'すべて'**
  String get filterAll;

  /// No description provided for @filterIncomplete.
  ///
  /// In ja, this message translates to:
  /// **'未完了'**
  String get filterIncomplete;

  /// No description provided for @filterCompleted.
  ///
  /// In ja, this message translates to:
  /// **'完了'**
  String get filterCompleted;

  /// No description provided for @filterHidden.
  ///
  /// In ja, this message translates to:
  /// **'非表示'**
  String get filterHidden;

  /// No description provided for @markComplete.
  ///
  /// In ja, this message translates to:
  /// **'完了にする'**
  String get markComplete;

  /// No description provided for @markIncomplete.
  ///
  /// In ja, this message translates to:
  /// **'未完了に戻す'**
  String get markIncomplete;

  /// No description provided for @dueAt.
  ///
  /// In ja, this message translates to:
  /// **'締切: {time}'**
  String dueAt(String time);

  /// No description provided for @noDueDate.
  ///
  /// In ja, this message translates to:
  /// **'締切なし'**
  String get noDueDate;

  /// No description provided for @completedOnLms.
  ///
  /// In ja, this message translates to:
  /// **'LMSで提出済み'**
  String get completedOnLms;

  /// No description provided for @completedByUser.
  ///
  /// In ja, this message translates to:
  /// **'手動で完了'**
  String get completedByUser;

  /// No description provided for @conflictWarning.
  ///
  /// In ja, this message translates to:
  /// **'手動で完了にしましたが、LMS上では未提出です'**
  String get conflictWarning;

  /// No description provided for @conflictNotificationTitle.
  ///
  /// In ja, this message translates to:
  /// **'未提出の課題があります'**
  String get conflictNotificationTitle;

  /// No description provided for @conflictNotificationBody.
  ///
  /// In ja, this message translates to:
  /// **'「{task}」は完了にしましたが、LMS上では未提出です'**
  String conflictNotificationBody(String task);

  /// No description provided for @deadlineNotificationTitle.
  ///
  /// In ja, this message translates to:
  /// **'課題の締切が近づいています'**
  String get deadlineNotificationTitle;

  /// No description provided for @deadlineNotificationBody.
  ///
  /// In ja, this message translates to:
  /// **'「{task}」の締切は {time} です'**
  String deadlineNotificationBody(String task, String time);

  /// No description provided for @announcementNotificationTitle.
  ///
  /// In ja, this message translates to:
  /// **'新しいアナウンス'**
  String get announcementNotificationTitle;

  /// No description provided for @courses.
  ///
  /// In ja, this message translates to:
  /// **'コース一覧'**
  String get courses;

  /// No description provided for @modules.
  ///
  /// In ja, this message translates to:
  /// **'モジュール'**
  String get modules;

  /// No description provided for @announcements.
  ///
  /// In ja, this message translates to:
  /// **'アナウンス'**
  String get announcements;

  /// No description provided for @assignments.
  ///
  /// In ja, this message translates to:
  /// **'課題'**
  String get assignments;

  /// No description provided for @grades.
  ///
  /// In ja, this message translates to:
  /// **'成績'**
  String get grades;

  /// No description provided for @noModules.
  ///
  /// In ja, this message translates to:
  /// **'モジュールがありません'**
  String get noModules;

  /// No description provided for @openInBrowser.
  ///
  /// In ja, this message translates to:
  /// **'ブラウザで開く'**
  String get openInBrowser;

  /// No description provided for @openOnLms.
  ///
  /// In ja, this message translates to:
  /// **'LMSで開く'**
  String get openOnLms;

  /// No description provided for @points.
  ///
  /// In ja, this message translates to:
  /// **'{points}点'**
  String points(String points);

  /// No description provided for @today.
  ///
  /// In ja, this message translates to:
  /// **'今日'**
  String get today;

  /// No description provided for @noClassToday.
  ///
  /// In ja, this message translates to:
  /// **'今日の授業はありません'**
  String get noClassToday;

  /// No description provided for @nextClass.
  ///
  /// In ja, this message translates to:
  /// **'次の授業'**
  String get nextClass;

  /// No description provided for @period.
  ///
  /// In ja, this message translates to:
  /// **'{n}限'**
  String period(int n);

  /// No description provided for @settings.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get settings;

  /// No description provided for @sectionAppearance.
  ///
  /// In ja, this message translates to:
  /// **'外観'**
  String get sectionAppearance;

  /// No description provided for @themeMode.
  ///
  /// In ja, this message translates to:
  /// **'テーマ'**
  String get themeMode;

  /// No description provided for @themeSystem.
  ///
  /// In ja, this message translates to:
  /// **'端末の設定に従う'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In ja, this message translates to:
  /// **'ライト'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In ja, this message translates to:
  /// **'ダーク'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In ja, this message translates to:
  /// **'言語'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In ja, this message translates to:
  /// **'端末の設定に従う'**
  String get languageSystem;

  /// No description provided for @sectionNotifications.
  ///
  /// In ja, this message translates to:
  /// **'通知'**
  String get sectionNotifications;

  /// No description provided for @announcementNotifications.
  ///
  /// In ja, this message translates to:
  /// **'アナウンス通知'**
  String get announcementNotifications;

  /// No description provided for @announcementNotificationsDesc.
  ///
  /// In ja, this message translates to:
  /// **'新しいアナウンスをプッシュ通知します'**
  String get announcementNotificationsDesc;

  /// No description provided for @deadlineReminder.
  ///
  /// In ja, this message translates to:
  /// **'締切リマインダー'**
  String get deadlineReminder;

  /// No description provided for @deadlineReminderDesc.
  ///
  /// In ja, this message translates to:
  /// **'未完了の課題を締切前に通知します'**
  String get deadlineReminderDesc;

  /// No description provided for @reminderTiming.
  ///
  /// In ja, this message translates to:
  /// **'通知タイミング'**
  String get reminderTiming;

  /// No description provided for @reminderTimingValue.
  ///
  /// In ja, this message translates to:
  /// **'締切の{h}時間{m}分前'**
  String reminderTimingValue(int h, int m);

  /// No description provided for @hoursUnit.
  ///
  /// In ja, this message translates to:
  /// **'時間'**
  String get hoursUnit;

  /// No description provided for @minutesUnit.
  ///
  /// In ja, this message translates to:
  /// **'分'**
  String get minutesUnit;

  /// No description provided for @minutesBeforeUnit.
  ///
  /// In ja, this message translates to:
  /// **'分前'**
  String get minutesBeforeUnit;

  /// No description provided for @excludeApplyToList.
  ///
  /// In ja, this message translates to:
  /// **'課題一覧からも隠す'**
  String get excludeApplyToList;

  /// No description provided for @excludeApplyToListDesc.
  ///
  /// In ja, this message translates to:
  /// **'オフにすると除外は通知のみに適用されます'**
  String get excludeApplyToListDesc;

  /// No description provided for @close.
  ///
  /// In ja, this message translates to:
  /// **'閉じる'**
  String get close;

  /// No description provided for @excludeWords.
  ///
  /// In ja, this message translates to:
  /// **'除外ワード'**
  String get excludeWords;

  /// No description provided for @excludeWordsDesc.
  ///
  /// In ja, this message translates to:
  /// **'タイトルに含まれる課題を通知しません(例: 再提出)'**
  String get excludeWordsDesc;

  /// No description provided for @addWord.
  ///
  /// In ja, this message translates to:
  /// **'ワードを追加'**
  String get addWord;

  /// No description provided for @excludeCourses.
  ///
  /// In ja, this message translates to:
  /// **'除外コース'**
  String get excludeCourses;

  /// No description provided for @excludeCoursesDesc.
  ///
  /// In ja, this message translates to:
  /// **'選んだコースの課題を通知しません'**
  String get excludeCoursesDesc;

  /// No description provided for @sectionCourses.
  ///
  /// In ja, this message translates to:
  /// **'コース'**
  String get sectionCourses;

  /// No description provided for @courseNicknames.
  ///
  /// In ja, this message translates to:
  /// **'コース略称'**
  String get courseNicknames;

  /// No description provided for @courseNicknamesDesc.
  ///
  /// In ja, this message translates to:
  /// **'課題名の前に [略称] として表示されます'**
  String get courseNicknamesDesc;

  /// No description provided for @nicknameHint.
  ///
  /// In ja, this message translates to:
  /// **'略称(例: Jexp)'**
  String get nicknameHint;

  /// No description provided for @sectionTimetable.
  ///
  /// In ja, this message translates to:
  /// **'時間割'**
  String get sectionTimetable;

  /// No description provided for @timetableSettings.
  ///
  /// In ja, this message translates to:
  /// **'時間割設定'**
  String get timetableSettings;

  /// No description provided for @timetableDays.
  ///
  /// In ja, this message translates to:
  /// **'曜日'**
  String get timetableDays;

  /// No description provided for @timetableDaysValue.
  ///
  /// In ja, this message translates to:
  /// **'{start}〜{end}'**
  String timetableDaysValue(String start, String end);

  /// No description provided for @periodsPerDay.
  ///
  /// In ja, this message translates to:
  /// **'1日のコマ数'**
  String get periodsPerDay;

  /// No description provided for @periodTimes.
  ///
  /// In ja, this message translates to:
  /// **'時限の時間'**
  String get periodTimes;

  /// No description provided for @startTime.
  ///
  /// In ja, this message translates to:
  /// **'開始'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In ja, this message translates to:
  /// **'終了'**
  String get endTime;

  /// No description provided for @sectionSync.
  ///
  /// In ja, this message translates to:
  /// **'同期'**
  String get sectionSync;

  /// No description provided for @backgroundSync.
  ///
  /// In ja, this message translates to:
  /// **'バックグラウンド同期'**
  String get backgroundSync;

  /// No description provided for @backgroundSyncDesc.
  ///
  /// In ja, this message translates to:
  /// **'アプリを開いていなくても課題・アナウンスを自動取得します(アナウンス通知に必要)'**
  String get backgroundSyncDesc;

  /// No description provided for @syncIntervalOff.
  ///
  /// In ja, this message translates to:
  /// **'オフ'**
  String get syncIntervalOff;

  /// No description provided for @everyMinutes.
  ///
  /// In ja, this message translates to:
  /// **'{m}分ごと'**
  String everyMinutes(int m);

  /// No description provided for @everyHours.
  ///
  /// In ja, this message translates to:
  /// **'{h}時間ごと'**
  String everyHours(int h);

  /// No description provided for @iosSyncNote.
  ///
  /// In ja, this message translates to:
  /// **'iOSでは実行間隔はOSが決定します(利用状況に依存)'**
  String get iosSyncNote;

  /// No description provided for @googleCalendarSync.
  ///
  /// In ja, this message translates to:
  /// **'Google Calendar同期'**
  String get googleCalendarSync;

  /// No description provided for @googleCalendarSyncDesc.
  ///
  /// In ja, this message translates to:
  /// **'未完了課題の締切を自分のGoogleカレンダーに登録します'**
  String get googleCalendarSyncDesc;

  /// No description provided for @googleTasksSync.
  ///
  /// In ja, this message translates to:
  /// **'Google Tasksに同期'**
  String get googleTasksSync;

  /// No description provided for @googleTasksSyncDesc.
  ///
  /// In ja, this message translates to:
  /// **'未完了課題を専用のGoogle Tasksリスト「課題」に追加します'**
  String get googleTasksSyncDesc;

  /// No description provided for @googleCalendarConnected.
  ///
  /// In ja, this message translates to:
  /// **'連携中: {email}'**
  String googleCalendarConnected(String email);

  /// No description provided for @googleCalendarDisconnect.
  ///
  /// In ja, this message translates to:
  /// **'連携解除(カレンダーから予定も削除)'**
  String get googleCalendarDisconnect;

  /// No description provided for @googleCalendarConnectFailed.
  ///
  /// In ja, this message translates to:
  /// **'Googleアカウントの連携に失敗しました'**
  String get googleCalendarConnectFailed;

  /// No description provided for @sectionAccount.
  ///
  /// In ja, this message translates to:
  /// **'アカウント'**
  String get sectionAccount;

  /// No description provided for @accessToken.
  ///
  /// In ja, this message translates to:
  /// **'アクセストークン(上級者向け)'**
  String get accessToken;

  /// No description provided for @accessTokenDesc.
  ///
  /// In ja, this message translates to:
  /// **'KLMSの設定で発行したトークンを使う場合は入力してください'**
  String get accessTokenDesc;

  /// No description provided for @sectionAbout.
  ///
  /// In ja, this message translates to:
  /// **'このアプリについて'**
  String get sectionAbout;

  /// No description provided for @contact.
  ///
  /// In ja, this message translates to:
  /// **'お問い合わせ'**
  String get contact;

  /// No description provided for @licenses.
  ///
  /// In ja, this message translates to:
  /// **'ライセンス'**
  String get licenses;

  /// No description provided for @version.
  ///
  /// In ja, this message translates to:
  /// **'バージョン'**
  String get version;

  /// No description provided for @save.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get delete;

  /// No description provided for @ok.
  ///
  /// In ja, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @retry.
  ///
  /// In ja, this message translates to:
  /// **'再試行'**
  String get retry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'ja':
      return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
