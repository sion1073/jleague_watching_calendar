import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jleague_watching_calendar/models/season.dart';
import 'package:jleague_watching_calendar/models/match_result.dart';
import 'package:jleague_watching_calendar/models/goal_scorer.dart';

void main() {
  setUpAll(() async {
    // テスト用にHiveを初期化（メモリ上で実行）
    Hive.init('test');
    Hive.registerAdapter(SeasonAdapter());
    Hive.registerAdapter(MatchResultAdapter());
    Hive.registerAdapter(GoalScorerAdapter());
  });

  tearDown(() async {
    // 各テスト後にクリーンアップ
    if (Hive.isBoxOpen('test_seasons')) {
      await Hive.box('test_seasons').clear();
      await Hive.box('test_seasons').close();
    }
  });

  group('Season Model Tests', () {
    test('シーズンを作成できる', () {
      final season = Season(
        name: '2024シーズン',
        year: 2024,
      );

      expect(season.name, '2024シーズン');
      expect(season.year, 2024);
      expect(season.matches, isEmpty);
    });

    test('シーズンに試合を追加できる', () {
      final season = Season(
        name: '2024シーズン',
        year: 2024,
      );

      final match = MatchResult(
        matchDate: DateTime(2024, 3, 15),
        homeTeam: 'FC東京',
        awayTeam: '鹿島アントラーズ',
        score: '3-2',
        outcomeIndex: MatchOutcome.win.index,
      );

      season.matches.add(match);

      expect(season.matches.length, 1);
      expect(season.matches.first.homeTeam, 'FC東京');
    });

    test('統計情報が正しく計算される', () {
      final season = Season(
        name: '2024シーズン',
        year: 2024,
        matches: [
          MatchResult(
            matchDate: DateTime(2024, 3, 15),
            homeTeam: 'FC東京',
            awayTeam: '鹿島アントラーズ',
            score: '3-2',
            outcomeIndex: MatchOutcome.win.index,
          ),
          MatchResult(
            matchDate: DateTime(2024, 3, 22),
            homeTeam: 'FC東京',
            awayTeam: '浦和レッズ',
            score: '1-1',
            outcomeIndex: MatchOutcome.draw.index,
          ),
          MatchResult(
            matchDate: DateTime(2024, 3, 29),
            homeTeam: '川崎フロンターレ',
            awayTeam: 'FC東京',
            score: '2-0',
            outcomeIndex: MatchOutcome.lose.index,
          ),
        ],
      );

      expect(season.totalWins, 1);
      expect(season.totalDraws, 1);
      expect(season.totalLosses, 1);
      expect(season.totalMatches, 3);
      expect(season.winRate, closeTo(0.333, 0.01));
    });

    test('試合を日付順にソートできる', () {
      final season = Season(
        name: '2024シーズン',
        year: 2024,
        matches: [
          MatchResult(
            matchDate: DateTime(2024, 3, 29),
            homeTeam: 'FC東京',
            awayTeam: 'チームA',
          ),
          MatchResult(
            matchDate: DateTime(2024, 3, 15),
            homeTeam: 'FC東京',
            awayTeam: 'チームB',
          ),
          MatchResult(
            matchDate: DateTime(2024, 3, 22),
            homeTeam: 'FC東京',
            awayTeam: 'チームC',
          ),
        ],
      );

      season.sortMatchesByDate(ascending: true);

      expect(season.matches[0].matchDate, DateTime(2024, 3, 15));
      expect(season.matches[1].matchDate, DateTime(2024, 3, 22));
      expect(season.matches[2].matchDate, DateTime(2024, 3, 29));
    });
  });

  group('MatchResult Model Tests', () {
    test('試合結果を作成できる', () {
      final match = MatchResult(
        matchDate: DateTime(2024, 3, 15),
        homeTeam: 'FC東京',
        awayTeam: '鹿島アントラーズ',
        score: '3-2',
        outcomeIndex: MatchOutcome.win.index,
      );

      expect(match.homeTeam, 'FC東京');
      expect(match.awayTeam, '鹿島アントラーズ');
      expect(match.score, '3-2');
      expect(match.outcome, MatchOutcome.win);
      expect(match.isFinished, true);
    });

    test('得点者を追加できる', () {
      final match = MatchResult(
        matchDate: DateTime(2024, 3, 15),
        homeTeam: 'FC東京',
        awayTeam: '鹿島アントラーズ',
        goalScorers: [
          GoalScorer(name: '田中太郎', team: 'FC東京'),
          GoalScorer(name: '佐藤次郎', team: 'FC東京'),
          GoalScorer(name: '鈴木三郎', team: '鹿島アントラーズ'),
        ],
      );

      expect(match.goalScorers.length, 3);
      expect(match.goalScorers[0].name, '田中太郎');
    });

    test('試合前の状態を正しく判定できる', () {
      final match = MatchResult(
        matchDate: DateTime(2024, 3, 15),
        homeTeam: 'FC東京',
        awayTeam: '鹿島アントラーズ',
        outcomeIndex: MatchOutcome.tbd.index,
      );

      expect(match.isFinished, false);
      expect(match.outcome, MatchOutcome.tbd);
    });
  });

  group('JSON Serialization Tests', () {
    test('シーズンをJSONに変換・復元できる', () {
      final season = Season(
        name: '2024シーズン',
        year: 2024,
        matches: [
          MatchResult(
            matchDate: DateTime(2024, 3, 15),
            homeTeam: 'FC東京',
            awayTeam: '鹿島アントラーズ',
            score: '3-2',
            outcomeIndex: MatchOutcome.win.index,
            goalScorers: [
              GoalScorer(name: '田中太郎', team: 'FC東京'),
            ],
            memo: 'テストメモ',
          ),
        ],
      );

      // JSONに変換
      final json = season.toJson();

      // JSONから復元
      final restored = Season.fromJson(json);

      expect(restored.name, season.name);
      expect(restored.year, season.year);
      expect(restored.matches.length, season.matches.length);
      expect(restored.matches[0].homeTeam, season.matches[0].homeTeam);
      expect(restored.matches[0].goalScorers.length, 1);
      expect(restored.matches[0].memo, 'テストメモ');
    });
  });
}
