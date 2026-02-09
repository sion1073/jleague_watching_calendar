import 'package:hive/hive.dart';

part 'goal_scorer.g.dart';

/// 得点者情報
@HiveType(typeId: 2)
class GoalScorer extends HiveObject {
  /// 得点者名
  @HiveField(0)
  String name;

  /// 所属チーム（ホーム or 対戦相手のチーム名）
  @HiveField(1)
  String team;

  /// 得点時間（分）※未入力の場合はnull
  @HiveField(2)
  int? minuteScored;

  GoalScorer({
    required this.name,
    required this.team,
    this.minuteScored,
  });

  /// JSONからGoalScorerを生成
  factory GoalScorer.fromJson(Map<String, dynamic> json) {
    return GoalScorer(
      name: json['name'] as String,
      team: json['team'] as String,
      minuteScored: json['minuteScored'] as int?,
    );
  }

  /// GoalScorerをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'team': team,
      'minuteScored': minuteScored,
    };
  }

  /// 得点者を文字列で表示（得点時間を含む）
  String toDisplayString() {
    if (minuteScored != null) {
      return '$minuteScored\' $name ($team)';
    }
    return '$name ($team)';
  }

  @override
  String toString() => toDisplayString();
}
