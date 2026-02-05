# データモデル設計

J.LEAGUE観戦カレンダーで使用するデータモデルの設計と使用方法を説明します。

## データ構造

```
Season (シーズン)
├── name: String                    # シーズン名（例: "2024シーズン"）
├── year: int                       # シーズン年（検索・ソート用）
└── matches: List<MatchResult>      # 試合結果のリスト
    ├── matchDate: DateTime         # 試合日
    ├── homeTeam: String            # ホームチーム名
    ├── awayTeam: String            # 対戦相手チーム名
    ├── score: String               # スコア（例: "3-2"）
    ├── outcome: MatchOutcome       # 勝敗（win/lose/draw/tbd）
    ├── goalScorers: List<GoalScorer> # 得点者リスト
    │   ├── name: String            # 得点者名
    │   └── team: String            # 所属チーム
    └── memo: String                # メモ
```

## モデルクラス

### 1. Season（シーズン）

シーズン全体の情報を管理するクラスです。

**フィールド:**
- `name`: シーズン名（例: "2024シーズン", "2025 J1リーグ"）
- `year`: シーズン開始年（検索・ソート用）
- `matches`: 試合結果のリスト

**主なメソッド:**
- `addMatch(MatchResult)`: 試合を追加
- `removeMatch(MatchResult)`: 試合を削除
- `sortMatchesByDate({bool ascending})`: 試合を日付順にソート

**統計情報:**
- `totalWins`: 勝利数
- `totalLosses`: 敗北数
- `totalDraws`: 引き分け数
- `totalMatches`: 試合数（終了した試合のみ）
- `winRate`: 勝率

### 2. MatchResult（試合結果）

個々の試合の情報を管理するクラスです。

**フィールド:**
- `matchDate`: 試合日
- `homeTeam`: ホームチーム名
- `awayTeam`: 対戦相手チーム名
- `score`: スコア（例: "3-2"、試合前は空文字列）
- `outcome`: 勝敗（MatchOutcome enum）
- `goalScorers`: 得点者のリスト
- `memo`: メモ

**主なプロパティ:**
- `isFinished`: 試合が終了しているかどうか
- `isHomeWin`: ホームチームが勝ったかどうか

### 3. GoalScorer（得点者）

得点者の情報を管理するクラスです。

**フィールド:**
- `name`: 得点者名
- `team`: 所属チーム

### 4. MatchOutcome（勝敗）

試合の勝敗を表すenumです。

**値:**
- `win`: 勝ち
- `lose`: 負け
- `draw`: 引き分け
- `tbd`: 未定（試合前）

## Hive設定

各モデルクラスにはHiveのTypeIdが設定されています：

- `Season`: typeId = 0
- `MatchResult`: typeId = 1
- `GoalScorer`: typeId = 2

## セットアップ手順

### 1. 依存関係のインストール

```bash
flutter pub get
```

### 2. Hiveアダプターの生成

モデルクラスに対応するHiveアダプターを自動生成します。

```bash
dart run build_runner build --delete-conflicting-outputs
```

生成されるファイル:
- `lib/models/season.g.dart`
- `lib/models/match_result.g.dart`
- `lib/models/goal_scorer.g.dart`

### 3. main.dartでの初期化

アプリ起動時にHiveを初期化し、アダプターを登録します。

```dart
import 'package:hive_flutter/hive_flutter.dart';
import 'models/season.dart';
import 'models/match_result.dart';
import 'models/goal_scorer.dart';

Future<void> main() async {
  // Hive初期化
  await Hive.initFlutter();

  // アダプター登録
  Hive.registerAdapter(SeasonAdapter());
  Hive.registerAdapter(MatchResultAdapter());
  Hive.registerAdapter(GoalScorerAdapter());

  // Boxを開く
  await Hive.openBox<Season>('seasons');

  runApp(MyApp());
}
```

## 使用例

### シーズンの作成と試合の追加

```dart
// 新しいシーズンを作成
final season = Season(
  name: '2024シーズン',
  year: 2024,
);

// 試合を追加
final match = MatchResult(
  matchDate: DateTime(2024, 3, 15),
  homeTeam: 'FC東京',
  awayTeam: '鹿島アントラーズ',
  score: '3-2',
  outcomeIndex: MatchOutcome.win.index,
  goalScorers: [
    GoalScorer(name: '田中太郎', team: 'FC東京'),
    GoalScorer(name: '佐藤次郎', team: 'FC東京'),
    GoalScorer(name: '鈴木三郎', team: 'FC東京'),
    GoalScorer(name: '高橋四郎', team: '鹿島アントラーズ'),
    GoalScorer(name: '伊藤五郎', team: '鹿島アントラーズ'),
  ],
  memo: '素晴らしい試合だった！',
);

season.addMatch(match);

// Hiveに保存
final box = Hive.box<Season>('seasons');
box.add(season);
```

### シーズンの読み込みと統計表示

```dart
// Boxからシーズンを取得
final box = Hive.box<Season>('seasons');
final seasons = box.values.toList();

// 最新のシーズンを取得
final latestSeason = seasons.last;

// 統計情報を表示
print('シーズン名: ${latestSeason.name}');
print('総試合数: ${latestSeason.totalMatches}');
print('勝利数: ${latestSeason.totalWins}');
print('敗北数: ${latestSeason.totalLosses}');
print('引き分け数: ${latestSeason.totalDraws}');
print('勝率: ${(latestSeason.winRate * 100).toStringAsFixed(1)}%');
```

### 試合の検索とフィルタリング

```dart
// 特定の日付以降の試合を取得
final upcomingMatches = season.matches.where((match) {
  return match.matchDate.isAfter(DateTime.now());
}).toList();

// 勝利した試合のみを取得
final wonMatches = season.matches.where((match) {
  return match.outcome == MatchOutcome.win;
}).toList();

// 特定のチームとの試合を取得
final kashinaMatches = season.matches.where((match) {
  return match.awayTeam == '鹿島アントラーズ';
}).toList();
```

### JSONエクスポート/インポート

```dart
// シーズンデータをJSONにエクスポート
final jsonData = season.toJson();
final jsonString = jsonEncode(jsonData);

// JSONからシーズンデータをインポート
final importedData = jsonDecode(jsonString);
final importedSeason = Season.fromJson(importedData);
```

## 注意事項

1. **Hiveアダプターの再生成**: モデルクラスを変更した場合は、必ず `build_runner` を実行してアダプターを再生成してください。

2. **TypeIdの一意性**: 新しいモデルクラスを追加する場合は、既存のTypeIdと重複しないように注意してください。

3. **データマイグレーション**: モデルの構造を変更する場合は、既存データのマイグレーション処理が必要になる場合があります。

4. **パフォーマンス**: 大量のデータを扱う場合は、適切なインデックスやクエリ最適化を検討してください。

## 今後の拡張

以下の機能を追加する予定です：

- [ ] 大会・カップ戦の対応
- [ ] 観戦場所（スタジアム、TV、配信など）の記録
- [ ] 観戦メンバーの記録
- [ ] 写真・画像の添付
- [ ] タグ機能
- [ ] 検索機能の強化
