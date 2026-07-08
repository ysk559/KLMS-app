# KLMS App

Keio LMS (KLMS / Canvas LMS, https://lms.keio.jp) のための非公式学習支援アプリ。

iOS / Android 対応。課題の取得・同期・通知、コースページの閲覧、時間割の自動生成、
ホーム画面ウィジェットなどを提供する。

## 主な機能

| 機能 | 説明 | 状態 |
|---|---|---|
| 認証 | アプリ内WebViewでOkta込みのログインを1回行い、セッションCookieを永続化。ID/Passは保存しない | Phase 1 ✅ |
| 課題一覧 | ダッシュボード外の課題も含めて取得。LMS側の完了を反映しつつ、ユーザー側でも完了可能。矛盾時は通知 | Phase 1 ✅ |
| コースページ | コース → ドロップダウン(モジュール)→ アイテム(ファイル/課題/アナウンス等)の閲覧 | Phase 1 ✅ |
| 時間割 | コース名(例: `3-12春［月2月3月4］今井倫太 情報工学実験第 1B［矢上12-204］`)をパースして自動生成 | Phase 1 ✅ |
| 締切リマインダー | 未完了課題の n時間m分前にローカル通知。除外ワード・除外コース設定可 | Phase 1 ✅ |
| コース略称 | コースごとに略称を設定し `[Jexp]課題名` のように表示 | Phase 1 ✅ |
| バックグラウンド同期 | Android: WorkManager / iOS: BGTaskScheduler | Phase 2 |
| アナウンスのプッシュ通知 | バックグラウンド同期時に新着を検知してローカル通知 | Phase 2 |
| ウィジェット | タスク一覧 / 時間割(次の授業・今日・全体) | Phase 3 |
| Google Calendar 同期 | 課題締切をカレンダーに反映 | Phase 3 |
| 多言語 | 日本語 / 英語 (+フランス語予定) | Phase 1 ✅(ja/en) |

ロードマップの詳細は [docs/ROADMAP.md](docs/ROADMAP.md)、
設計は [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)、
ユーザーへの確認事項は [docs/QUESTIONS.md](docs/QUESTIONS.md) を参照。

## 開発環境 (Windows)

1. [Flutter SDK](https://docs.flutter.dev/get-started/install/windows) (stable, 3.32+) をインストール
2. Android Studio + Android SDK をインストール(Android 実機/エミュレータ用)
3. このリポジトリをクローンして:

```powershell
flutter pub get
flutter run          # 接続中の Android 実機/エミュレータで起動
flutter test         # ユニットテスト
flutter analyze      # 静的解析
```

### iOS ビルドについて

iOS のビルド・署名には macOS が必要なため、Windows のみの環境では
GitHub Actions (macOS ランナー) でビルドする。`.github/workflows/` に
CI 設定を用意している。実機インストールは TestFlight (要 Apple Developer
Program) もしくは AltStore 等のサイドロードを利用する。
