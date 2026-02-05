import '../models/season.dart';
import '../models/match_result.dart';
import '../models/goal_scorer.dart';

/// サンプルデータを生成するユーティリティクラス
class SampleData {
  /// 2024シーズンのサンプルデータを生成
  static Season createSampleSeason2024() {
    return Season(
      name: '2024 J1リーグ',
      year: 2024,
      matches: [
        // 第1節: 勝利
        MatchResult(
          matchDate: DateTime(2024, 2, 23),
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
          memo: '開幕戦で逆転勝利！素晴らしいスタート',
        ),

        // 第2節: 引き分け
        MatchResult(
          matchDate: DateTime(2024, 3, 1),
          homeTeam: '浦和レッズ',
          awayTeam: 'FC東京',
          score: '1-1',
          outcomeIndex: MatchOutcome.draw.index,
          goalScorers: [
            GoalScorer(name: '興梠慎三', team: '浦和レッズ'),
            GoalScorer(name: 'ディエゴ・オリヴェイラ', team: 'FC東京'),
          ],
          memo: 'アウェイで粘り強く勝ち点1を獲得',
        ),

        // 第3節: 敗北
        MatchResult(
          matchDate: DateTime(2024, 3, 8),
          homeTeam: 'FC東京',
          awayTeam: '川崎フロンターレ',
          score: '1-2',
          outcomeIndex: MatchOutcome.lose.index,
          goalScorers: [
            GoalScorer(name: '長友佑都', team: 'FC東京'),
            GoalScorer(name: '家長昭博', team: '川崎フロンターレ'),
            GoalScorer(name: 'レアンドロ・ダミアン', team: '川崎フロンターレ'),
          ],
          memo: '惜敗。次節は必ず勝つ',
        ),

        // 第4節: 勝利
        MatchResult(
          matchDate: DateTime(2024, 3, 15),
          homeTeam: '横浜F・マリノス',
          awayTeam: 'FC東京',
          score: '0-2',
          outcomeIndex: MatchOutcome.win.index,
          goalScorers: [
            GoalScorer(name: '中村帆高', team: 'FC東京'),
            GoalScorer(name: 'ディエゴ・オリヴェイラ', team: 'FC東京'),
          ],
          memo: '完封勝利！守備陣が素晴らしかった',
        ),

        // 第5節: 試合前
        MatchResult(
          matchDate: DateTime(2024, 3, 22),
          homeTeam: 'FC東京',
          awayTeam: 'ヴィッセル神戸',
          score: '',
          outcomeIndex: MatchOutcome.tbd.index,
          memo: 'ホームで絶対勝つ！',
        ),
      ],
    );
  }

  /// 2023シーズンのサンプルデータを生成
  static Season createSampleSeason2023() {
    return Season(
      name: '2023 J1リーグ',
      year: 2023,
      matches: [
        MatchResult(
          matchDate: DateTime(2023, 2, 18),
          homeTeam: 'FC東京',
          awayTeam: 'サンフレッチェ広島',
          score: '2-1',
          outcomeIndex: MatchOutcome.win.index,
          goalScorers: [
            GoalScorer(name: 'ディエゴ・オリヴェイラ', team: 'FC東京'),
            GoalScorer(name: '長友佑都', team: 'FC東京'),
            GoalScorer(name: 'ドウグラス・ヴィエイラ', team: 'サンフレッチェ広島'),
          ],
          memo: '2023シーズン開幕戦勝利',
        ),
        MatchResult(
          matchDate: DateTime(2023, 2, 25),
          homeTeam: '名古屋グランパス',
          awayTeam: 'FC東京',
          score: '3-2',
          outcomeIndex: MatchOutcome.lose.index,
          goalScorers: [
            GoalScorer(name: '稲垣祥', team: '名古屋グランパス'),
            GoalScorer(name: 'マテウス', team: '名古屋グランパス'),
            GoalScorer(name: '永井謙佑', team: '名古屋グランパス'),
            GoalScorer(name: 'ディエゴ・オリヴェイラ', team: 'FC東京'),
            GoalScorer(name: '安部柊斗', team: 'FC東京'),
          ],
          memo: '惜しい試合だった',
        ),
      ],
    );
  }

  /// 複数シーズンのサンプルデータを生成
  static List<Season> createMultipleSeasons() {
    return [
      createSampleSeason2023(),
      createSampleSeason2024(),
    ];
  }

  /// 空のシーズンを生成（新規作成用）
  static Season createEmptySeason(String name, int year) {
    return Season(
      name: name,
      year: year,
      matches: [],
    );
  }

  /// 試合のテンプレートを生成（新規登録用）
  static MatchResult createMatchTemplate({
    required DateTime matchDate,
    String homeTeam = 'FC東京',
    String awayTeam = '',
  }) {
    return MatchResult(
      matchDate: matchDate,
      homeTeam: homeTeam,
      awayTeam: awayTeam,
      score: '',
      outcomeIndex: MatchOutcome.tbd.index,
      memo: '',
    );
  }
}
