# データモデル設計概要

## 概要

J.LEAGUE観戦カレンダーのデータモデル設計が完了しました。このドキュメントでは、設計されたデータ構造と実装内容を説明します。

## データ構造

```
Season (シーズン) - typeId: 0
├── name: String                      # シーズン名（例: "2024 J1リーグ"）
├── year: int                         # シーズン年（検索・ソート用）
└── matches: List<MatchResult>        # 試合結果のリスト
    │
    ├── MatchResult (試合結果) - typeId: 1
    │   ├── matchDate: DateTime       # 試合日
    │   ├── homeTeam: String          # ホームチーム名
    │   ├── awayTeam: String          # 対戦相手チーム名
    │   ├── score: String             # スコア（例: "3-2"）
    │   ├── outcomeIndex: int         # 勝敗のインデックス
    │   ├── goalScorers: List<GoalScorer> # 得点者リスト
    │   │   │
    │   │   └── GoalScorer (得点者) - typeId: 2
    │   │       ├── name: String      # 得点者名
    │   │       └── team: String      # 所属チーム
    │   │
    │   └── memo: String              # メモ
    │
    └── outcome: MatchOutcome (enum)
        ├── win                       # 勝ち
        ├── lose                      # 負け
        ├── draw                      # 引き分け
        └── tbd                       # 未定（試合前）
```

## 実装ファイル

### モデルクラス

| ファイル | 説明 | Hive TypeId |
|---------|------|-------------|
| [lib/models/season.dart](../lib/models/season.dart) | シーズン情報を管理 | 0 |
| [lib/models/match_result.dart](../lib/models/match_result.dart) | 試合結果を管理 | 1 |
| [lib/models/goal_scorer.dart](../lib/models/goal_scorer.dart) | 得点者情報を管理 | 2 |

### サービスクラス

| ファイル | 説明 |
|---------|------|
| [lib/services/season_service.dart](../lib/services/season_service.dart) | シーズンデータのCRUD操作を提供 |

### ユーティリティ

| ファイル | 説明 |
|---------|------|
| [lib/utils/sample_data.dart](../lib/utils/sample_data.dart) | サンプルデータ生成用ユーティリティ |

### テスト

| ファイル | 説明 |
|---------|------|
| [test/models/season_test.dart](../test/models/season_test.dart) | データモデルのユニットテスト |

### ドキュメント

| ファイル | 説明 |
|---------|------|
| [lib/models/README.md](../lib/models/README.md) | モデルクラスの詳細説明 |
| [docs/DATA_MODEL_USAGE.md](DATA_MODEL_USAGE.md) | 実践的な使用方法ガイド |

## 主な機能

### 1. Season（シーズン）クラス

- **基本機能**
  - シーズン名と年の管理
  - 試合結果のリスト管理
  - 試合の追加・削除
  - 日付順のソート

- **統計情報**
  - 総試合数
  - 勝利数・敗北数・引き分け数
  - 勝率の計算

### 2. MatchResult（試合結果）クラス

- **基本機能**
  - 試合日時、チーム名、スコアの管理
  - 勝敗の記録
  - 得点者リストの管理
  - メモ機能

- **判定機能**
  - 試合終了の判定
  - ホームチーム勝利の判定

### 3. GoalScorer（得点者）クラス

- 得点者名の記録
- 所属チームの記録

### 4. SeasonService（サービス）クラス

- **CRUD操作**
  - シーズンの作成・読み込み・更新・削除
  - 試合の追加

- **検索・フィルタリング**
  - 年度順のソート
  - 特定年のシーズン取得

- **データ管理**
  - JSONエクスポート
  - JSONインポート
  - 全データクリア

## 技術的特徴

### 1. Hiveによる永続化

- **IndexedDB（Web）対応**
  - ブラウザのローカルストレージに保存
  - オフライン動作をサポート

- **型安全性**
  - TypeAdapterによる型安全な保存・読み込み
  - コード生成による自動化

### 2. JSON対応

- **エクスポート/インポート**
  - toJson() / fromJson() メソッド
  - バックアップ・復元機能の基盤

- **互換性**
  - 外部システムとのデータ交換
  - GitHub Gist連携への対応

### 3. リアクティブUI対応

- **ValueListenableBuilder対応**
  - Hive BoxのlisteningをFlutterウィジェットで監視
  - データ変更時の自動UI更新

## テスト結果

全8テストが成功しています：

- ✅ シーズンの作成
- ✅ 試合の追加
- ✅ 統計情報の計算
- ✅ 日付順ソート
- ✅ 試合結果の作成
- ✅ 得点者の追加
- ✅ 試合前状態の判定
- ✅ JSONシリアライゼーション

## 次のステップ

データモデルの設計が完了したので、次は以下の実装に進みます：

### フェーズ1: 基本UI実装
- [ ] ホーム画面（シーズン一覧）
- [ ] シーズン詳細画面（試合一覧）
- [ ] 試合登録・編集画面
- [ ] 統計情報表示

### フェーズ2: 機能拡張
- [ ] 検索・フィルタリング機能
- [ ] データのエクスポート/インポート（UI）
- [ ] サンプルデータの読み込み機能

### フェーズ3: 認証・同期
- [ ] 簡易パスワード認証の統合
- [ ] GitHub OAuth実装（将来）
- [ ] GitHub Gist連携（将来）

## 開発環境セットアップ

### 必須コマンド

```bash
# 依存関係のインストール
flutter pub get

# Hiveアダプターの生成
dart run build_runner build --delete-conflicting-outputs

# テストの実行
flutter test test/models/season_test.dart

# 全テストの実行
flutter test
```

### モデル変更時の手順

1. モデルクラスを編集
2. `dart run build_runner build --delete-conflicting-outputs` を実行
3. テストを実行して動作確認
4. アプリを再起動

## よくある質問

### Q: なぜHiveを使うのか？

A: 以下の理由からHiveを選択しました：
- Webでの動作（IndexedDB対応）
- オフライン動作のサポート
- 高速な読み書き性能
- 型安全性
- Flutterとの統合の良さ

### Q: データのバックアップは？

A: SeasonService.exportAllData()でJSON形式にエクスポートできます。将来的にはGitHub Gist連携で自動バックアップを実装予定です。

### Q: データの容量制限は？

A: IndexedDBには容量制限があります（ブラウザにより異なる）が、テキストデータなので数千試合分でも問題なく保存できます。

### Q: 複数デバイスでの同期は？

A: フェーズ3でGitHub Gist連携により実装予定です。現在はエクスポート/インポート機能で手動同期が可能です。

## 参考資料

- [Hive公式ドキュメント](https://docs.hivedb.dev/)
- [Flutter公式ドキュメント](https://flutter.dev/docs)
- [プロジェクトREADME](../README.md)

## 変更履歴

| 日付 | バージョン | 変更内容 |
|------|-----------|---------|
| 2026-02-05 | 1.0.0 | 初版リリース - 基本データモデル完成 |

## ライセンス

Private - 個人利用のみ
