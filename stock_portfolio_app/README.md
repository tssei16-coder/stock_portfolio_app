# マイ株管理・リバランスアプリ セットアップガイド

Flutter + Firebase で構築した個人用株式ポートフォリオ管理アプリです。

---

## ステップ1: Flutter のインストール

1. [Flutter公式サイト](https://flutter.dev/docs/get-started/install/windows) からインストーラーをダウンロード
2. `flutter doctor` を実行して環境確認
3. Webサポートを有効化:
   ```bash
   flutter config --enable-web
   ```

---

## ステップ2: Firebase プロジェクトの作成

1. [Firebase Console](https://console.firebase.google.com/) を開く
2. **「プロジェクトを追加」** をクリック
3. プロジェクト名を入力（例: `my-stock-portfolio`）
4. Google Analyticsは無効でOK

### Authentication の設定
1. Firebase Console → **Authentication** → **始める**
2. **「Sign-in method」** タブ → **メール/パスワード** を有効化

### Firestore の設定
1. Firebase Console → **Firestore Database** → **データベースの作成**
2. **本番モード** で作成（後でセキュリティルールを設定）
3. ロケーション: `asia-northeast1`（東京）を推奨

### Firestoreセキュリティルールの適用
1. Firestore → **「ルール」** タブ
2. `firestore.rules` の内容をコピーして貼り付け
3. **「公開」** ボタンをクリック

---

## ステップ3: FlutterFire の設定

```bash
# FlutterFire CLI をインストール
dart pub global activate flutterfire_cli

# Firebaseプロジェクトと接続（プロジェクトディレクトリで実行）
cd stock_portfolio_app
flutterfire configure
```

→ `lib/firebase_options.dart` が自動生成されます

---

## ステップ4: Flutter アプリのビルド

```bash
cd stock_portfolio_app

# 依存パッケージのインストール
flutter pub get

# コード生成（freezed / riverpod_generator）
dart run build_runner build --delete-conflicting-outputs

# Web版で起動
flutter run -d chrome

# デスクトップ版で起動（Windows）
flutter run -d windows
```

---

## ステップ5: Python 株価更新スクリプトの設定

### 初回設定
```bash
cd stock_portfolio_app/python

# 依存パッケージのインストール
pip install -r requirements.txt
```

### Firebase Admin SDK キーの取得
1. Firebase Console → **プロジェクトの設定** → **サービスアカウント**
2. **「新しい秘密鍵の生成」** → JSONファイルをダウンロード
3. `stock_portfolio_app/python/` に `serviceAccountKey.json` として配置

### ユーザーUIDの確認
1. Firebase Console → **Authentication** → ユーザーを確認
2. アカウントのUID（長い文字列）をコピー
3. `stock_updater.py` の `FIREBASE_USER_UID` に貼り付け

### 動作テスト
```bash
# 強制実行（平日/時間外でも実行）
python stock_updater.py --force
```

### Windowsタスクスケジューラで自動実行
1. **タスクスケジューラ** を開く（`Win + S` → 「タスクスケジューラ」）
2. **「基本タスクの作成」**
3. 設定:
   - 名前: `株価自動更新`
   - トリガー: **「毎日」** → 時刻: `15:35`
   - 操作: **「プログラムの開始」**
   - プログラム: `python` のパス（例: `C:\Python312\python.exe`）
   - 引数: `C:\path\to\stock_portfolio_app\python\stock_updater.py`
4. **「条件」タブ** → 「コンピューターをAC電源で使用している場合のみ」のチェックを外す

---

## ファイル構成

```
stock_portfolio_app/
├── lib/
│   ├── main.dart              # エントリーポイント
│   ├── app.dart               # ルーティング
│   ├── firebase_options.dart  # ★自動生成（要設定）
│   ├── models/                # データモデル
│   ├── repositories/          # Firestoreアクセス
│   ├── providers/             # Riverpod状態管理
│   ├── features/
│   │   ├── auth/              # ログイン画面
│   │   ├── dashboard/         # ダッシュボード
│   │   ├── rebalance/         # リバランス計算
│   │   └── stock_edit/        # 銘柄追加・編集
│   └── utils/                 # ユーティリティ
├── python/
│   ├── stock_updater.py       # ★株価自動更新スクリプト
│   ├── requirements.txt
│   └── serviceAccountKey.json # ★要配置（.gitignoreに追加済み）
├── firestore.rules            # セキュリティルール
└── pubspec.yaml
```

---

## よくある質問

**Q: 株価はいつ更新されますか？**  
A: Pythonスクリプトをタスクスケジューラで平日15:35に実行することで、大引け（15:30）直後の終値が反映されます。

**Q: 友人のデータは見られますか？**  
A: Firestoreのセキュリティルールにより、各ユーザーは自分のデータのみアクセスできます。

**Q: 無料プランの制限は？**  
A: Sparkプランでは読み取り5万回/日、書き込み2万回/日が無料です。個人利用（数十銘柄）では全く問題ありません。
