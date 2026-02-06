import 'package:flutter/material.dart';
import '../models/season.dart';

/// 観戦統計情報を表示するウィジェット
///
/// 全シーズンを通した観戦数、勝利数、敗戦数、引き分け数を表示
class MatchStatisticsWidget extends StatelessWidget {
  /// 統計を計算する対象のシーズンリスト
  final List<Season> seasons;

  const MatchStatisticsWidget({
    super.key,
    required this.seasons,
  });

  /// 全シーズンの統計を計算
  Map<String, int> _calculateTotalStatistics() {
    int totalMatches = 0;
    int totalWins = 0;
    int totalLosses = 0;
    int totalDraws = 0;

    for (final season in seasons) {
      totalMatches += season.totalMatches;
      totalWins += season.totalWins;
      totalLosses += season.totalLosses;
      totalDraws += season.totalDraws;
    }

    return {
      'totalMatches': totalMatches,
      'wins': totalWins,
      'losses': totalLosses,
      'draws': totalDraws,
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateTotalStatistics();
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
                  '観戦統計',
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
