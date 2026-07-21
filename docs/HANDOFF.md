# 次のステップと引き継ぎメモ

最終更新: 2026-07-20。開発機能(Phase 1〜3+実機フィードバック2巡)は実装済みで、
CI(解析/テスト/Android APK/iOSビルド)はグリーン。**TestFlight への初回
アップロードも成功**(手動署名+Xcode 26、詳細は下記1のデバッグ経緯9)。
ここから先はリリース準備と、署名の恒久化(fastlane match)が中心。

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
     7. Adminキーに更新後も「bearer token not properly signed」が継続。
        p8を厳格PEMに再構成、正規名(AuthKey_<KEYID>.p8)で既定パスに配置、
        Key ID差し替えも試したが変わらず。
     8. **原因判明・突破**: 別途 ASC Key Check ワークフロー(ubuntu, 署名JWTで
        ASC API を直接叩く)で **HTTP 200 = 3 Secret は完全に整合・有効** と確定。
        つまり認証情報は正常で、犯人は **Xcode のバージョン**だった。
        `macos-latest` は現在 **Xcode 26.5** で、そのAPIキー cloud signing が
        有効な鍵でも bearer token 署名検証に失敗する(バグ)。
        → **`runs-on: macos-15`(Xcode 16.x)に変更して bearer token エラーが解消**
        (コミット 93f32e4)。DEVELOPER_DIR も明示固定。
     - **現在の残課題**: 認証は通るようになったが、アーカイブ時に
       「No profiles ... iOS App Development provisioning profiles」で失敗。
       = 自動署名のアーカイブが**開発用プロファイル**を要求するが、アカウントに
       **登録デバイスが0台**のため生成できない(開発用プロファイルはデバイス必須)。
     - **次の一手(ユーザー作業・最小)**: iPhone を1台デバイス登録する。
       developer.apple.com → Devices → 「+」→ Platform iOS、UDID を入力。
       UDID の取得(Macなし): iPhone で get.udid.io 等を開く / Windows の
       iTunes でシリアル番号をクリックして UDID 表示、のいずれか。
       登録後にワークフロー再実行すれば、`-allowProvisioningUpdates` が
       Bundle ID 登録・**App Groups 有効化**・証明書・配布プロファイル生成を
       すべて自動で行う想定。
     9. **✅ 解決(コミット d5e3ab3、2026-07-20 アップロード成功)**。最終構成:
        - **手動署名**に切替(Fastfile): setup_ci → cert(Apple Distribution,
          development:false, keychain_path は fastlane_tmp_keychain-db を明示) →
          sigh(appstore, APP_ID と WIDGET_ID の2本) →
          update_code_signing_settings で Runner/KlmsWidgets を manual+
          profile 指定 → build_app(export_options: signingStyle manual +
          provisioningProfiles マッピング) → upload_to_testflight。
        - **ランナーは macos-latest (Xcode 26 / iOS 26 SDK)**。App Store Connect が
          アップロードに iOS 26 SDK 以上を必須化したため。手動署名では
          xcodebuild が Developer portal と通信しないので、Xcode 26 の
          cloud signing bearer-token 不具合は該当しない。
        - ワークフロー(testflight.yml)は p8 を厳格PEMで
          ~/.appstoreconnect/private_keys/AuthKey_<KEYID>.p8 等に配置し
          ASC_KEY_P8_PATH を渡すのみ(cloud signing 用の allowProvisioningUpdates
          は撤去)。
     - **ユーザー側の前提(完了済み)**: App ID 2種(自動登録)+ App Group
       `group.jp.keio.klms.klmsApp` を両App IDに割当、App Store Connect の
       アプリレコード作成、デバイス1台登録(※手動署名では本来不要だが登録済み)。
     10. **✅ 証明書churn恒久解決(コミット 288ee55)**: `cert` は使い捨てCIで
        毎回新規の Apple Distribution 証明書を作り上限(2)に達していた。
        **fastlane match** に移行して解決:
        - Fastfile は `match(type: "appstore", app_identifier: [APP_ID,
          WIDGET_ID], readonly: false)` で証明書+プロファイルを取得。初回に
          作成し暗号化して保存、以後は再利用。プロファイル名は
          `lane_context[SharedValues::MATCH_PROVISIONING_PROFILE_MAPPING]` から。
        - 保存先は **同リポジトリの `match-storage` ブランチ**(ユーザー選択)。
          workflow が `permissions: contents: write` と GITHUB_TOKEN を
          base64 の `MATCH_GIT_BASIC_AUTHORIZATION` にして push。
          env: MATCH_PASSWORD(新規Secret)/ MATCH_GIT_URL(=このリポジトリ)/
          MATCH_GIT_BRANCH=match-storage。
        - **前提**: 初回 match 実行前に既存の配布証明書を全Revoke(枠を空ける)。
        - **MATCH_PASSWORD を紛失した場合**: 配布証明書をRevoke →
          match-storage ブランチ削除 → MATCH_PASSWORD 更新 → 再実行で再生成。
     - **Actions分の注意**: private リポジトリだと macOS ランナーは10倍消費で
       無料枠(月2000分)をすぐ使い切る。デバッグ中は一時的に public 化して
       無制限にした。ビルドが落ち着いたら private に戻してよい(戻すと枠制限が
       復活する点に注意)。

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
