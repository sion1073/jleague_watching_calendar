import 'package:hive/hive.dart';
import 'goal_scorer.dart';

part 'match_result.g.dart';

/// 勝敗の種類
enum MatchOutcome {
  win,    // 勝ち
  lose,   // 負け
  draw,   // 引き分け
  tbd,    // 未定（試合前）
}

/// 観戦タイプ
enum ViewingType {
  stadium,  // スタジアム観戦
  dazn,     // DAZN配信視聴
}

/// 試合結果
@HiveType(typeId: 1)
class MatchResult extends HiveObject {
  /// 試合日
  @HiveField(0)
  DateTime matchDate;

  /// ホームチーム名
  @HiveField(1)
  String homeTeam;

  /// 対戦相手チーム名
  @HiveField(2)
  String awayTeam;

  /// 試合結果のスコア（例: "3-2"、試合前は空文字列）
  @HiveField(3)
  String score;

  /// 勝敗
  @HiveField(4)
  int outcomeIndex; // MatchOutcomeのindexを保存

  /// 得点者リスト
  @HiveField(5)
  List<GoalScorer> goalScorers;

  /// メモ
  @HiveField(6)
  String memo;

  /// 観戦タイプ
  @HiveField(7)
  int viewingTypeIndex; // ViewingTypeのindexを保存

  MatchResult({
    required this.matchDate,
    required this.homeTeam,
    required this.awayTeam,
    this.score = '',
    this.outcomeIndex = 3, // デフォルトはtbd
    this.viewingTypeIndex = 0, // デフォルトはstadium
    List<GoalScorer>? goalScorers,
    this.memo = '',
  }) : goalScorers = goalScorers ?? [];

  /// 勝敗を取得
  MatchOutcome get outcome => MatchOutcome.values[outcomeIndex];

  /// 勝敗を設定
  set outcome(MatchOutcome value) {
    outcomeIndex = value.index;
  }

  /// 観戦タイプを取得
  ViewingType get viewingType => ViewingType.values[viewingTypeIndex];

  /// 観戦タイプを設定
  set viewingType(ViewingType value) {
    viewingTypeIndex = value.index;
  }

  /// JSONからMatchResultを生成
  factory MatchResult.fromJson(Map<String, dynamic> json) {
    return MatchResult(
      matchDate: DateTime.parse(json['matchDate'] as String),
      homeTeam: json['homeTeam'] as String,
      awayTeam: json['awayTeam'] as String,
      score: json['score'] as String? ?? '',
      outcomeIndex: _parseOutcome(json['outcome'] as String?),
      viewingTypeIndex: _parseViewingType(json['viewingType'] as String?),
      goalScorers: (json['goalScorers'] as List<dynamic>?)
              ?.map((e) => GoalScorer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      memo: json['memo'] as String? ?? '',
    );
  }

  /// MatchResultをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'matchDate': matchDate.toIso8601String(),
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'score': score,
      'outcome': outcome.name,
      'viewingType': viewingType.name,
      'goalScorers': goalScorers.map((e) => e.toJson()).toList(),
      'memo': memo,
    };
  }

  /// 勝敗文字列をインデックスに変換
  static int _parseOutcome(String? outcome) {
    if (outcome == null) return MatchOutcome.tbd.index;
    switch (outcome.toLowerCase()) {
      case 'win':
        return MatchOutcome.win.index;
      case 'lose':
        return MatchOutcome.lose.index;
      case 'draw':
        return MatchOutcome.draw.index;
      default:
        return MatchOutcome.tbd.index;
    }
  }

  /// 観戦タイプ文字列をインデックスに変換
  static int _parseViewingType(String? viewingType) {
    if (viewingType == null) return ViewingType.stadium.index;
    switch (viewingType.toLowerCase()) {
      case 'stadium':
        return ViewingType.stadium.index;
      case 'dazn':
        return ViewingType.dazn.index;
      default:
        return ViewingType.stadium.index;
    }
  }

  /// 試合が終了しているかどうか
  bool get isFinished => outcome != MatchOutcome.tbd;

  /// ホームチームが勝ったかどうか
  bool get isHomeWin => outcome == MatchOutcome.win;

  /// 得点者を時間順にソートして取得
  /// 得点時間が入力されているものを昇順で並べ、未入力のものを最後に配置
  List<GoalScorer> getSortedGoalScorers() {
    final scorers = List<GoalScorer>.from(goalScorers);
    scorers.sort((a, b) {
      // 両方とも得点時間がある場合は昇順
      if (a.minuteScored != null && b.minuteScored != null) {
        return a.minuteScored!.compareTo(b.minuteScored!);
      }
      // aのみ得点時間がある場合はaを先に
      if (a.minuteScored != null) {
        return -1;
      }
      // bのみ得点時間がある場合はbを先に
      if (b.minuteScored != null) {
        return 1;
      }
      // 両方とも得点時間がない場合は元の順序を維持
      return 0;
    });
    return scorers;
  }

  @override
  String toString() {
    final outcomeStr = outcome.name.toUpperCase();
    if (isFinished) {
      return '$matchDate: $homeTeam vs $awayTeam ($score) - $outcomeStr';
    }
    return '$matchDate: $homeTeam vs $awayTeam - $outcomeStr';
  }
}
