import 'package:hive/hive.dart';
import 'match_result.dart';

part 'season.g.dart';

/// シーズン情報
@HiveType(typeId: 0)
class Season extends HiveObject {
  /// シーズン名（例: "2024シーズン", "2025 J1リーグ"）
  @HiveField(0)
  String name;

  /// シーズン開始年（検索・ソート用）
  @HiveField(1)
  int year;

  /// 試合結果リスト
  @HiveField(2)
  List<MatchResult> matches;

  Season({
    required this.name,
    required this.year,
    List<MatchResult>? matches,
  }) : matches = matches ?? [];

  /// JSONからSeasonを生成
  factory Season.fromJson(Map<String, dynamic> json) {
    return Season(
      name: json['name'] as String,
      year: json['year'] as int,
      matches: (json['matches'] as List<dynamic>?)
              ?.map((e) => MatchResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// SeasonをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'year': year,
      'matches': matches.map((e) => e.toJson()).toList(),
    };
  }

  /// 試合を追加
  void addMatch(MatchResult match) {
    matches.add(match);
    save(); // Hiveに保存
  }

  /// 試合を削除
  void removeMatch(MatchResult match) {
    matches.remove(match);
    save(); // Hiveに保存
  }

  /// 試合を日付順にソート
  void sortMatchesByDate({bool ascending = true}) {
    matches.sort((a, b) {
      final comparison = a.matchDate.compareTo(b.matchDate);
      return ascending ? comparison : -comparison;
    });
  }

  /// 統計情報: 勝利数
  int get totalWins =>
      matches.where((m) => m.outcome == MatchOutcome.win).length;

  /// 統計情報: 敗北数
  int get totalLosses =>
      matches.where((m) => m.outcome == MatchOutcome.lose).length;

  /// 統計情報: 引き分け数
  int get totalDraws =>
      matches.where((m) => m.outcome == MatchOutcome.draw).length;

  /// 統計情報: 試合数（終了した試合のみ）
  int get totalMatches =>
      matches.where((m) => m.isFinished).length;

  /// 統計情報: 勝率
  double get winRate {
    if (totalMatches == 0) return 0.0;
    return totalWins / totalMatches;
  }

  @override
  String toString() {
    return '$name (${matches.length}試合)';
  }
}
