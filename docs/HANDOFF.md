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
   - 署名は Xcode クラウド署名(証明書ファイル不要、Team ID: NNU983LGZU は
     Fastfile に記載)。Bundle ID(本体+ウィジェット)と App Groups 等の
     capability は初回アーカイブ時に自動登録される。ビルド番号は run number。
   - **App Store Connect のアプリレコードだけは手動で1回作成が必要**
     (fastlane produce が API キー認証に非対応のため):
     App Store Connect → マイApp → 「+」→ 新規App → プラットフォーム iOS、
     名前(例: KLMSアプリ)、プライマリ言語 日本語、
     Bundle ID `jp.keio.klms.klmsApp`(初回ワークフロー実行後に選択肢に出る)、
     SKU 任意(例: klmsapp-001)。
     レコードが無い間はワークフロー最後のアップロード段階で
     「Could not find app」で失敗する(署名・ビルドの検証はできる)。
   - App Group `group.jp.keio.klms.klmsApp` が自動登録されない場合は
     developer.apple.com → Identifiers → App Groups で手動作成し、
     両 App ID の App Groups capability に割り当てて再実行。
   - アップロード成功後: App Store Connect → TestFlight → 内部テスターに
     自分を追加 → iPhone に TestFlight アプリを入れてインストール。
   - **デバッグ経緯**(後続セッション向け):
     1. produce系はAPIキー認証非対応 → 全削除済み
     2. 「Signing requires a development team」→ Team ID指定で解消
     3. 「Your team has no devices」→ Development署名がデバイス登録を要求
     4. CODE_SIGN_IDENTITY=Apple Distribution のグローバル上書き
        → Pods全ターゲットと「conflicting provisioning settings」で衝突
     5. 無署名アーカイブ→exportArchive → export時に
        「no provisioning profile mapping」で失敗
     6. **現状の構成**(最終・コミット d65e830): 署名設定を project.pbxproj の
        Runner と KlmsWidgets の各構成にのみ設定
        (DEVELOPMENT_TEAM=NNU983LGZU + CODE_SIGN_STYLE=Automatic、Podsは非対象)。
        Fastfile は allowProvisioningUpdates + APIキーでクラウド署名。
        → **`Authentication failed: Make sure a bearer token was provided` で失敗**。
     - **根本原因(判明)**: App Store Connect API キーのロールが「App Manager」だと、
       Developer Portal のプロビジョニング操作(証明書・プロファイル自動生成)が
       できない。fastlane 自身のAPI認証(アップロード)は通るが、xcodebuild の
       cloud signing が Developer Portal アクセスで弾かれる。
     - **推奨される次の一手(ユーザー作業)**: App Store Connect API キーを
       **「Admin」ロール**で新規作成し直し、GitHub Secrets の
       ASC_KEY_ID / ASC_ISSUER_ID / ASC_KEY_P8 を更新 → ワークフロー再実行。
       (App Store Connect → ユーザーとアクセス → 統合 → キー → ロール Admin)
     7. Adminキーに更新後も「Authentication failed: bearer token not
        properly signed」が継続。p8を厳格PEM(BEGIN/END+64文字改行)に
        再構成しても変わらず(コミット cfdae4e)。
     - **最有力の残り原因(未確認・ユーザー作業)**: p8とKey IDの不一致。
       Adminキーを新規作成すると **Key ID は新しい値になる**(Issuer ID は
       チーム共通で不変、p8 は新ファイル)。`ASC_KEY_P8` を新キーのものに
       替えても `ASC_KEY_ID` を旧キーのIDのままにしていると、鍵とIDが
       食い違い bearer token 署名検証が必ず失敗する。
       → **確認**: GitHub Secrets の ASC_KEY_ID が「今の Admin キーの Key ID」に
         なっているか。ASC_ISSUER_ID は変えなくてよい。3つが同一キー由来で
         揃っているのが必須。
     - コード側の署名戦略はすべて出し尽くした(手動auth / Distribution強制 /
       無署名→export / project.pbxproj限定 / api_key委譲 / p8正規化)。
       残るのはユーザー環境(キーの整合)側の問題。
     - それでもダメな場合の代替案: (a) fastlane match(証明書用の私有リポジトリ+
       APPLE_ID/パスワードかAPIキーが必要)、(b) Mac を一度だけ借りて Xcode で
       手動アーカイブ&アップロード(初回さえ通れば以降の証明書も揃う)。
       ※ UDID登録は「開発用インストール」向けで、TestFlight(配布署名)には
         無関係なので不可。

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
