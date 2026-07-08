# アーキテクチャ

## 技術選定

| 項目 | 選定 | 理由 |
|---|---|---|
| フレームワーク | Flutter | Windows上で開発可能・iOS/Android同一コード・ウィジェットは `home_widget` でネイティブ連携可能 |
| 状態管理 | Riverpod | シンプルでテスト容易 |
| DB | sqflite | コース/課題/アナウンスのリレーショナルなキャッシュ。コード生成不要で堅牢 |
| HTTP | dio | インターセプタで認証ヘッダ/クッキーを一元管理 |
| WebView | flutter_inappwebview | Cookie 管理 API が充実(認証スキップの要) |
| 通知 | flutter_local_notifications | 締切リマインダーはローカル通知で完結(サーバー不要) |

## 認証(Webブラウザでの認証スキップ)

方針: **ID/パスワードは一切保存しない。Canvas のセッション Cookie とアクセストークンのみ扱う。**

1. ユーザーはアプリ内 WebView (`flutter_inappwebview`) で `https://lms.keio.jp/login` を開き、
   keio.jp → Okta の多要素認証を **1回だけ** 通す。
2. ログイン完了(lms.keio.jp に戻り `canvas_session` Cookie が付与される)を検知したら、
   WebView の永続 Cookie ストアにそのまま保持する。
   - iOS: WKWebsiteDataStore / Android: CookieManager はアプリプロセスを跨いで永続。
   - 通常のブラウザと違い「閉じたら消える」ことはない。Okta 側のセッション上限
     (大学設定に依存)までログイン状態が続く。
3. API 呼び出しは Cookie ストアから `lms.keio.jp` の Cookie を取り出し、
   `Cookie:` ヘッダとして dio に付与する(Canvas は REST API `/api/v1/*` の GET を
   セッション Cookie で認可する)。書き込み系は `_csrf_token` Cookie を
   `X-CSRF-Token` ヘッダに転記する。
4. セッション失効(401/リダイレクト検知)時は再ログインを促す。WebView には
   Okta 側 Cookie が残っているため、多くの場合パスワード再入力なしで再認可される。
5. 代替: KLMS がユーザーによるアクセストークン発行を許可している場合は、
   設定画面からトークンを入力して `Authorization: Bearer` 方式に切替可能
   (こちらの方が長寿命で安定)。トークンは `flutter_secure_storage`
   (iOS Keychain / Android EncryptedSharedPreferences) に保存する。

アプリ内からKLMSのページを開くときは同じ WebView 環境を使うため、認証済みのまま閲覧できる。

## データフロー

```
Canvas REST API (lms.keio.jp/api/v1)
        │  CanvasClient (dio; cookie or token auth)
        ▼
   SyncService ──────────────► NotificationService
        │  courses/assignments/       (締切リマインダー再スケジュール,
        │  announcements を差分同期      完了矛盾通知, 新着アナウンス通知)
        ▼
   AppDatabase (sqflite)
        │  Repository 経由
        ▼
   Riverpod providers ──► UI (5タブ) / (Phase 3: ウィジェット)
```

## 課題の完了状態

- `lmsCompleted`: LMS 側の状態(submission が submitted/graded、または planner override)
- `userCompleted`: アプリ内でユーザーがチェックした状態
- 表示上の完了 = `lmsCompleted || userCompleted`
- 同期時に `userCompleted && !lmsCompleted` を検知したら、その課題について
  **1回だけ** 通知する(`conflictNotified` フラグ)。LMS 側が完了になれば
  フラグはリセット。

## コース名パーサー

KLMS のコース名 `[コース番号][学期]［[曜日時限]+］[教師名] [コース名]［[教室]］`
(例: `3-12春［月2月3月4］今井倫太 情報工学実験第 1B［矢上12-204］`)を
`core/utils/course_name_parser.dart` で正規表現パースし、時間割を自動生成する。
パース不能なコース(集中講義など)は時間割から除外し、コース一覧にのみ表示する。

## ディレクトリ構成

```
lib/
  main.dart               エントリポイント(通知初期化など)
  app.dart                MaterialApp / テーマ / 5タブシェル
  core/
    constants.dart        KLMSのURL等
    theme/app_theme.dart  #021951ベースのM3テーマ(ライト/ダーク)
    utils/course_name_parser.dart
  data/
    api/canvas_client.dart      Canvas REST APIクライアント
    auth/auth_service.dart      Cookie/トークン管理・ログイン状態
    db/app_database.dart        sqflite スキーマ&マイグレーション
    models/                     Course / TaskItem / Announcement / CourseModule
    repositories/               DBアクセス(courses/tasks/announcements)
    sync/sync_service.dart      同期の統括(API→DB→通知再スケジュール)
    notifications/notification_service.dart
  features/
    home/       ホーム
    tasks/      課題一覧
    pages/      コースページ(モジュール閲覧)
    timetable/  時間割
    settings/   設定(略称・通知・時間割・アカウント)
    auth/       ログインWebView
  l10n/         ja / en / fr
```

## バックグラウンド同期(Phase 2 予定)

- Android: `workmanager` で15分〜間隔の定期同期。
- iOS: BGAppRefreshTask(OS任せで実行頻度は不定。ユーザーのアプリ利用頻度に依存)。
- どちらも同期後に締切リマインダーを再スケジュール、新着アナウンスをローカル通知。
- **リアルタイム性が必要なら push サーバーが必要**だが、認証情報を外部サーバーに
  預けることになるため採用しない(プライバシー優先)。締切リマインダーは
  事前スケジュール型なのでバックグラウンド実行に依存せず正確に発火する。

## ウィジェット(Phase 3 予定)

`home_widget` パッケージ + ネイティブ実装(Android: Glance / iOS: WidgetKit)。
- タスク一覧ウィジェット
- 時間割: 次の授業(Apple Watch コンプリケーション含む) / 今日 / 全体
- データは同期時に `home_widget` 経由で共有ストレージへ書き出す。
