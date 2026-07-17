# 次のステップと引き継ぎメモ

最終更新: 2026-07-12。開発機能(Phase 1〜3+実機フィードバック2巡)は実装済みで、
CI(解析/テスト/Android APK/iOSビルド)はグリーン。ここから先はリリース準備が中心。

## あなた(オーナー)側で行う手続き

### 1. Apple Developer Program 加入 【iOS配布の前提・最優先】
1. https://developer.apple.com/programs/ から Apple ID で加入(個人、年間¥12,980)。
   審査に数日かかることがある。
2. 加入後、App Store Connect (https://appstoreconnect.apple.com) で:
   - 「ユーザとアクセス → 統合 → App Store Connect API」で **チームキー** を作成
     (ロール: App Manager)。**Issuer ID / Key ID / .p8ファイル** を控える
     (.p8 は一度しかダウンロードできない)。
3. GitHub リポジトリの Settings → Secrets and variables → Actions →
   **Secrets タブ → Repository secrets**(「New repository secret」)に登録。
   ※ Variables ではなく Secrets(機密情報のため)。Environment secrets も不要。
   - `ASC_ISSUER_ID`: Issuer ID(UUID形式)
   - `ASC_KEY_ID`: キーのKey ID(10文字程度)
   - `ASC_KEY_P8`: .p8 ファイルの中身全体
     (`-----BEGIN PRIVATE KEY-----`〜`-----END PRIVATE KEY-----` を改行ごとそのまま)
4. ~~開発セッションに伝える~~ → **完了済み**。TestFlight アップロードは
   GitHub Actions の **TestFlight ワークフロー**(手動実行)として実装済み:
   - GitHub → Actions タブ → 左の「TestFlight」→「Run workflow」で実行。
   - fastlane が App ID / ウィジェットの App ID / App Group の登録と
     App Store Connect のアプリレコード作成(名前: KLMSアプリ)まで自動で試みる。
     署名は Xcode クラウド署名(証明書ファイル不要)。ビルド番号は run number。
   - **初回は失敗しやすい**(アプリ名の重複、produce の権限まわり等)。
     失敗したら Actions のログのエラー部分を開発セッションに貼れば修正できる。
     アプリレコードだけ手動で作る場合: App Store Connect → マイApp →「+」
     (Bundle ID は一度ワークフローを走らせると選択肢に現れる)。
   - アップロード成功後: App Store Connect → TestFlight → 内部テスターに
     自分を追加 → iPhone に TestFlight アプリを入れてインストール。

### 2. Google Calendar 同期 → **クライアントID作成済み・アプリ実装済み**
作成済みの OAuth クライアントID(公開識別子。シークレットではない):
- Android: `476074577270-u6e0sqir46klgselaar4tkm9nkdcfmve.apps.googleusercontent.com`
- iOS: `476074577270-moc50h7bti10rj7emjkrj3v8a5b451op.apps.googleusercontent.com`
設定 → 同期 → Google Calendar同期 をオンにするとGoogleサインインが開き、
未完了課題の締切が自分のカレンダーに登録される(完了/除外で自動削除)。
以下は当時の手順(参考):

<details><summary>初期設定手順(完了済み)</summary>
1. https://console.cloud.google.com でプロジェクト作成(無料)。
2. 「APIとサービス → ライブラリ」で **Google Calendar API を有効化**
   (有効化しないとスコープ選択画面に calendar が出てこない)。
3. OAuth同意画面(新UIでは左メニュー「**Google Auth Platform**」):
   External、アプリ名等を入力。「対象(Audience)」でテストユーザーに自分を追加。
   スコープは「データアクセス」タブ →「スコープを追加または削除」→
   `.../auth/calendar.events` にチェック。
   ※テスト公開モードの間はスコープ未登録でも動作するので、見つからなければ
   後回しで可(一般公開の審査時に必要になるだけ)。
4. 「認証情報 → OAuthクライアントID」を **Android用**(パッケージ名
   `jp.keio.klms.klms_app` + SHA-1)と **iOS用**(バンドルID
   `jp.keio.klms.klmsApp`)の2つ作成。
   - SHA-1 の取得(Windows): `cd KLMS-app\android` → `.\gradlew signingReport`
     の Variant: debug の SHA1 を使う。または
     `keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android`
     (keytool は Android Studio 同梱: `C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe`)。
   - これはデバッグ署名用。将来リリース用キーストアを作ったら、その SHA-1 を
     Android クライアントに追加登録すること。
4. クライアントIDを開発セッションに伝える → `google_sign_in` +
   Calendar API 書き込みを実装する。
   ※一般公開時はセンシティブスコープのため Google の審査が必要
   (テスト公開のままなら最大100ユーザーまで審査不要)。

</details>

### 3. その他の小物
- 問い合わせ先(メール/Instagram/Google Form)を決めて伝える
  → `lib/core/constants.dart` の `contactUrl` を差し替え。
- Android を野良APK以外で配るなら Google Play Developer 登録($25買い切り)。

## 開発側(次のセッション)が行うこと

優先順:
1. **TestFlight 自動化**(上記1の完了待ち): fastlane 追加、署名設定、
   App Group 有効化、CI ワークフロー拡張。
2. **iOSウィジェットの実機データ疎通確認**(App Group有効化後)と
   iOS課題ウィジェットのタップ完了(iOS 17 AppIntents)。
3. **Google Calendar 同期**(上記2の完了待ち): google_sign_in + Calendar API。
   課題締切をユーザー自身のカレンダーに書き込み(サービスアカウントは使わない)。
4. **Phase 4 デザイン刷新**: アプリ+ウィジェットのビジュアル一新
   (テーマ、カード、タイポグラフィ、アイコン)。アプリアイコンも未作成。
5. ストア公開準備: プライバシーポリシー、スクリーンショット、説明文。

## 開発環境メモ(新しいセッション向け)

- Flutter stable 3.32.5 / ブランチ `claude/keio-lms-app-zna3tl`
- 検証: `flutter analyze` と `flutter test`(16件)を常にグリーンに保つ。
  Kotlin/Swift はローカルでコンパイルできないため、プッシュ後に
  GitHub Actions(ci.yml: analyze-test / build-android / build-ios)で確認する。
- 設計は docs/ARCHITECTURE.md、決定事項は docs/QUESTIONS.md、
  計画は docs/ROADMAP.md を参照。
- 既知の実機未検証ポイント: Android課題ウィジェットのチェックアイコン完了
  (home_widget のバックグラウンド起動)、PDFのアプリ内表示(pdfx)。
