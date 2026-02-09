import 'package:flutter/material.dart';
import '../models/match_result.dart';

/// 試合リストからの観戦統計情報を表示するウィジェット
///
/// 指定された試合リストの統計を計算して表示します。
/// ホーム試合用とアウェイ試合用の統計を分けて表示できます。
class MatchListStatisticsWidget extends StatelessWidget {
  /// 統計を計算する対象の試合リスト
  final List<MatchResult> matches;

  /// ホーム試合の統計のみを表示するか
  final bool showHomeOnly;

  /// タイトルテキスト（省略可能）
  final String? title;

  const MatchListStatisticsWidget({
    super.key,
    required this.matches,
    this.showHomeOnly = false,
    this.title,
  });

  /// 試合リストの統計を計算
  Map<String, int> _calculateStatistics() {
    // 終了した試合のみを対象にする
    final finishedMatches = matches.where((m) => m.isFinished).toList();

    int totalMatches = finishedMatches.length;
    int totalWins = finishedMatches.where((m) => m.outcome == MatchOutcome.win).length;
    int totalLosses = finishedMatches.where((m) => m.outcome == MatchOutcome.lose).length;
    int totalDraws = finishedMatches.where((m) => m.outcome == MatchOutcome.draw).length;

    return {
      'totalMatches': totalMatches,
      'wins': totalWins,
      'losses': totalLosses,
      'draws': totalDraws,
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStatistics();
    final totalMatches = stats['totalMatches'] ?? 0;
    final wins = stats['wins'] ?? 0;
    final losses = stats['losses'] ?? 0;
    final draws = stats['draws'] ?? 0;

    // 勝率を計算（0除算を防ぐ）
    final winRate = totalMatches > 0 ? (wins / totalMatches * 100) : 0.0;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // タイトル
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  title ?? '観戦統計',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(height: 24),
            // 統計テーブル
            _buildStatRow(
              context,
              '観戦数',
              totalMatches.toString(),
              Colors.blue,
              Icons.stadium,
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              context,
              '勝利数',
              wins.toString(),
              Colors.green,
              Icons.check_circle,
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              context,
              '敗戦数',
              losses.toString(),
              Colors.red,
              Icons.cancel,
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              context,
              '引き分け数',
              draws.toString(),
              Colors.orange,
              Icons.horizontal_rule,
            ),
            const Divider(height: 24),
            // 勝率
            _buildStatRow(
              context,
              '勝率',
              '${winRate.toStringAsFixed(1)}%',
              Colors.purple,
              Icons.trending_up,
            ),
          ],
        ),
      ),
    );
  }

  /// 統計行を構築
  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}
