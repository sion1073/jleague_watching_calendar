# データモデル使用ガイド

J.LEAGUE観戦カレンダーのデータモデルの実践的な使用方法を説明します。

## 目次

1. [初期設定](#初期設定)
2. [基本的な使い方](#基本的な使い方)
3. [実践例](#実践例)
4. [トラブルシューティング](#トラブルシューティング)

## 初期設定

### 1. Hiveアダプターの生成

モデルクラスを変更した場合は、以下のコマンドでHiveアダプターを再生成してください。

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 2. main.dartでの初期化

アプリの起動時に、Hiveを初期化してアダプターを登録します。

```dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/season.dart';
import 'models/match_result.dart';
import 'models/goal_scorer.dart';
import 'services/season_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive初期化
  await Hive.initFlutter();

  // アダプター登録
  Hive.registerAdapter(SeasonAdapter());
  Hive.registerAdapter(MatchResultAdapter());
  Hive.registerAdapter(GoalScorerAdapter());

  // SeasonServiceを初期化
  await SeasonService().initialize();

  runApp(const MyApp());
}
```

## 基本的な使い方

### シーズンの作成

```dart
import 'package:jleague_watching_calendar/models/season.dart';
import 'package:jleague_watching_calendar/services/season_service.dart';

// 新しいシーズンを作成
final season = Season(
  name: '2024 J1リーグ',
  year: 2024,
);

// データベースに保存
final seasonService = SeasonService();
final seasonKey = await seasonService.addSeason(season);
print('シーズンを保存しました: key=$seasonKey');
```

### 試合結果の登録

```dart
import 'package:jleague_watching_calendar/models/match_result.dart';
import 'package:jleague_watching_calendar/models/goal_scorer.dart';

// 試合結果を作成
final match = MatchResult(
  matchDate: DateTime(2024, 3, 15),
  homeTeam: 'FC東京',
  awayTeam: '鹿島アントラーズ',
  score: '3-2',
  outcomeIndex: MatchOutcome.win.index,
  goalScorers: [
    GoalScorer(name: 'ディエゴ・オリヴェイラ', team: 'FC東京'),
    GoalScorer(name: '中村帆高', team: 'FC東京'),
    GoalScorer(name: '安部柊斗', team: 'FC東京'),
    GoalScorer(name: '鈴木優磨', team: '鹿島アントラーズ'),
    GoalScorer(name: '上田綺世', team: '鹿島アントラーズ'),
  ],
  memo: '開幕戦で逆転勝利！',
);

// シーズンに試合を追加
await seasonService.addMatchToSeason(seasonKey, match);
```

### データの取得

```dart
// 全シーズンを取得
final allSeasons = seasonService.getAllSeasons();

// 年度順にソートして取得（新しい順）
final sortedSeasons = seasonService.getSeasonsOrderedByYear(ascending: false);

// 特定の年のシーズンを取得
final season2024 = seasonService.getSeasonByYear(2024);

// シーズンの試合を日付順にソート
season2024.sortMatchesByDate(ascending: true);
```

## 実践例

### 例1: サンプルデータの読み込み

開発中やデモ用に、サンプルデータを簡単に読み込めます。

```dart
import 'package:jleague_watching_calendar/utils/sample_data.dart';
import 'package:jleague_watching_calendar/services/season_service.dart';

Future<void> loadSampleData() async {
  final seasonService = SeasonService();

  // サンプルシーズンを作成
  final sampleSeasons = SampleData.createMultipleSeasons();

  // データベースに保存
  for (final season in sampleSeasons) {
    await seasonService.addSeason(season);
  }

  print('サンプルデータを読み込みました');
}
```

### 例2: 統計情報の表示

```dart
import 'package:jleague_watching_calendar/services/season_service.dart';

void displaySeasonStats(int seasonKey) {
  final seasonService = SeasonService();
  final season = seasonService.box.get(seasonKey);

  if (season == null) return;

  print('=== ${season.name} 統計情報 ===');
  print('総試合数: ${season.totalMatches}');
  print('勝利: ${season.totalWins}');
  print('引き分け: ${season.totalDraws}');
  print('敗北: ${season.totalLosses}');
  print('勝率: ${(season.winRate * 100).toStringAsFixed(1)}%');
}
```

### 例3: 試合のフィルタリング

```dart
void filterMatches(Season season) {
  // 今日以降の試合を取得
  final upcomingMatches = season.matches.where((match) {
    return match.matchDate.isAfter(DateTime.now());
  }).toList();

  print('今後の試合: ${upcomingMatches.length}件');

  // 勝利した試合のみを取得
  final wonMatches = season.matches.where((match) {
    return match.outcome == MatchOutcome.win;
  }).toList();

  print('勝利した試合: ${wonMatches.length}件');

  // 特定のチームとの試合を取得
  final kashimaMatches = season.matches.where((match) {
    return match.awayTeam == '鹿島アントラーズ' ||
           match.homeTeam == '鹿島アントラーズ';
  }).toList();

  print('鹿島アントラーズとの試合: ${kashimaMatches.length}件');

  // 得点者が記録されている試合を取得
  final matchesWithGoals = season.matches.where((match) {
    return match.goalScorers.isNotEmpty;
  }).toList();

  print('得点者が記録されている試合: ${matchesWithGoals.length}件');
}
```

### 例4: データのエクスポート/インポート

```dart
import 'dart:convert';
import 'package:jleague_watching_calendar/services/season_service.dart';

// データをJSONファイルにエクスポート
Future<String> exportToJson() async {
  final seasonService = SeasonService();
  final data = seasonService.exportAllData();

  // JSON文字列に変換
  final jsonString = const JsonEncoder.withIndent('  ').convert(data);

  // ファイルに保存する処理をここに追加
  // 例: await File('backup.json').writeAsString(jsonString);

  return jsonString;
}

// JSONファイルからデータをインポート
Future<void> importFromJson(String jsonString) async {
  final seasonService = SeasonService();

  // JSON文字列をパース
  final data = jsonDecode(jsonString) as Map<String, dynamic>;

  // データをインポート
  await seasonService.importData(data);

  print('データをインポートしました');
}
```

### 例5: Flutterウィジェットでの使用

```dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jleague_watching_calendar/models/season.dart';
import 'package:jleague_watching_calendar/services/season_service.dart';

class SeasonListWidget extends StatelessWidget {
  const SeasonListWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final seasonService = SeasonService();

    return ValueListenableBuilder(
      valueListenable: seasonService.box.listenable(),
      builder: (context, Box<Season> box, _) {
        final seasons = box.values.toList();

        if (seasons.isEmpty) {
          return const Center(
            child: Text('シーズンがありません'),
          );
        }

        return ListView.builder(
          itemCount: seasons.length,
          itemBuilder: (context, index) {
            final season = seasons[index];

            return Card(
              child: ListTile(
                title: Text(season.name),
                subtitle: Text(
                  '試合数: ${season.totalMatches} | '
                  '勝率: ${(season.winRate * 100).toStringAsFixed(1)}%'
                ),
                trailing: Text('${season.totalWins}勝 ${season.totalDraws}分 ${season.totalLosses}敗'),
                onTap: () {
                  // 詳細画面に遷移
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SeasonDetailScreen(season: season),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
```

### 例6: 試合結果の更新

```dart
import 'package:jleague_watching_calendar/models/match_result.dart';

// 試合前の試合結果を更新
void updateMatchResult(
  Season season,
  int matchIndex, {
  required String score,
  required MatchOutcome outcome,
  required List<GoalScorer> goalScorers,
  String? memo,
}) {
  final match = season.matches[matchIndex];

  // 試合結果を更新
  match.score = score;
  match.outcome = outcome;
  match.goalScorers.clear();
  match.goalScorers.addAll(goalScorers);

  if (memo != null) {
    match.memo = memo;
  }

  // Hiveに保存
  season.save();

  print('試合結果を更新しました: ${match.homeTeam} vs ${match.awayTeam}');
}
```

## トラブルシューティング

### エラー: "SeasonService is not initialized"

**原因**: SeasonServiceが初期化される前に使用しようとしています。

**解決方法**: main()関数でSeasonService().initialize()を呼び出してください。

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // アダプター登録
  Hive.registerAdapter(SeasonAdapter());
  Hive.registerAdapter(MatchResultAdapter());
  Hive.registerAdapter(GoalScorerAdapter());

  // これを忘れずに！
  await SeasonService().initialize();

  runApp(const MyApp());
}
```

### エラー: "Cannot write, unknown type"

**原因**: Hiveアダプターが登録されていないか、生成されていません。

**解決方法**:
1. `dart run build_runner build --delete-conflicting-outputs`を実行
2. main()でアダプターを登録

### データが保存されない

**原因**: HiveObjectのsave()メソッドを呼び出していない、または親オブジェクトが保存されていません。

**解決方法**:
```dart
// 方法1: 親オブジェクト（Season）を保存
season.addMatch(match); // 内部でsave()が呼ばれる

// 方法2: 直接save()を呼ぶ
match.score = '3-2';
season.save(); // 親を保存
```

### モデルを変更した後にエラーが出る

**原因**: 古いアダプターが使用されています。

**解決方法**:
1. `dart run build_runner clean`
2. `dart run build_runner build --delete-conflicting-outputs`
3. アプリを再起動

## 次のステップ

データモデルの使い方を理解したら、次は以下の機能の実装に進みましょう:

1. **画面の実装**: [lib/screens/README.md](lib/screens/README.md) を参照
2. **データ同期**: GitHub Gist連携の実装
3. **UI改善**: マテリアルデザインの適用
4. **検索機能**: 高度な検索・フィルタリング機能の追加

## 参考リンク

- [Hiveドキュメント](https://docs.hivedb.dev/)
- [Flutter公式ドキュメント](https://flutter.dev/docs)
- [プロジェクトREADME](../README.md)
