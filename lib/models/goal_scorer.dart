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

  GoalScorer({
    required this.name,
    required this.team,
  });

  /// JSONからGoalScorerを生成
  factory GoalScorer.fromJson(Map<String, dynamic> json) {
    return GoalScorer(
      name: json['name'] as String,
      team: json['team'] as String,
    );
  }

  /// GoalScorerをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'team': team,
    };
  }

  @override
  String toString() => '$name ($team)';
}
