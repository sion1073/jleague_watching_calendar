# J.LEAGUE観戦カレンダー

J.LEAGUEの試合スケジュールと個人的なメモを管理するPWA（Progressive Web App）です。

## 特徴

- **PWA対応**: ブラウザから直接アクセス可能、ホーム画面に追加してアプリのように使用可能
- **オフライン動作**: Service Workerによりオフラインでも動作
- **ローカルストレージ**: データはブラウザ内（IndexedDB）に安全に保存
- **認証機能**: 簡易パスワード認証でプライバシーを保護
- **データバックアップ**: JSONエクスポート/インポート機能

## 技術スタック

- **フロントエンド**: Flutter Web
- **ホスティング**: GitHub Pages
- **ストレージ**: Hive (IndexedDB wrapper)
- **認証**: SHA-256ハッシュベース簡易認証
- **将来予定**: Firebase Auth + GitHub OAuth、GitHub Gist連携

## 開発フェーズ

### フェーズ1: プロトタイプ（現在）
- [x] プロジェクトセットアップ
- [x] PWA設定
- [ ] 簡易パスワード認証実装
- [ ] データモデル設計
- [ ] 基本UI実装

### フェーズ2: コア機能開発
- [ ] 予定の登録・編集・削除
- [ ] メモ機能
- [ ] 検索・フィルタリング機能
- [ ] エクスポート/インポート機能

### フェーズ3: 本番化
- [ ] GitHub OAuth実装
- [ ] GitHub Gist連携（自動バックアップ）
- [ ] UI/UX改善

## セットアップ

### 必要な環境
- Flutter SDK 3.38.9以上
- Dart 3.10.8以上

### インストール

```bash
# リポジトリをクローン
git clone https://github.com/yourusername/jleague_watching_calendar.git
cd jleague_watching_calendar

# 依存関係をインストール
flutter pub get

# Web向けにビルド
flutter build web --release

# 開発サーバーで実行
flutter run -d chrome
```

## デプロイ

GitHub Pagesへのデプロイは自動化されています。

1. GitHubリポジトリの Settings > Pages に移動
2. Source を "GitHub Actions" に設定
3. `main` ブランチにプッシュすると自動デプロイ

デプロイ後、以下のURLでアクセス可能:
```
https://yourusername.github.io/jleague_watching_calendar/
```

## プロジェクト構造

```
jleague_watching_calendar/
├── lib/
│   ├── main.dart           # アプリのエントリーポイント
│   ├── models/             # データモデル
│   ├── services/           # ビジネスロジック（認証、ストレージ等）
│   ├── screens/            # 画面
│   ├── widgets/            # 再利用可能なウィジェット
│   └── utils/              # ユーティリティ関数
├── web/
│   ├── index.html          # HTMLエントリーポイント
│   ├── manifest.json       # PWA設定
│   └── icons/              # アプリアイコン
├── .github/
│   └── workflows/
│       └── deploy.yml      # GitHub Actions設定
└── pubspec.yaml            # 依存関係設定
```

## ライセンス

Private - 個人利用のみ

## 開発記録

詳細な開発経緯と技術的な決定事項については、`ai_chat_log/` ディレクトリの議事録を参照してください。
