import 'package:flutter/material.dart';
import '../models/season.dart';
import '../models/match_result.dart';

/// 観戦統計情報を表示するウィジェット
///
/// 全シーズンを通した観戦数、勝利数、敗戦数、引き分け数を表示
class MatchStatisticsWidget extends StatelessWidget {
  /// 統計を計算する対象のシーズンリスト
  final List<Season> seasons;

  /// 配信視聴を含めるかどうか
  final bool includeStreaming;

  const MatchStatisticsWidget({
    super.key,
    required this.seasons,
    required this.includeStreaming,
  });

  /// 全シーズンの統計を計算（観戦タイプでフィルタリング）
  Map<String, int> _calculateTotalStatistics() {
    int totalMatches = 0;
    int rankedMatches = 0;
    int totalWins = 0;
    int totalLosses = 0;
    int totalDraws = 0;
    int totalWatches = 0;

    for (final season in seasons) {
      for (final match in season.matches) {
        if (includeStreaming || match.viewingType == ViewingType.stadium) {
          if (match.isFinished) {
            totalMatches++;
            switch (match.outcome) {
              case MatchOutcome.win:
                rankedMatches++;
                totalWins++;
                break;
              case MatchOutcome.lose:
                rankedMatches++;
                totalLosses++;
                break;
              case MatchOutcome.draw:
                rankedMatches++;
                totalDraws++;
                break;
              case MatchOutcome.watch:
                totalWatches++;
                break;
              default:
                break;
            }
          }
        }
      }
    }

    return {
      'totalMatches': totalMatches,
      'rankedMatches': rankedMatches,
      'wins': totalWins,
      'losses': totalLosses,
      'draws': totalDraws,
      'watches': totalWatches,
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateTotalStatistics();
    final totalMatches = stats['totalMatches'] ?? 0;
    final rankedMatches = stats['rankedMatches'] ?? 0;
    final wins = stats['wins'] ?? 0;
    final losses = stats['losses'] ?? 0;
    final draws = stats['draws'] ?? 0;
    final watches = stats['watches'] ?? 0;

    final winRate = rankedMatches > 0 ? (wins / rankedMatches * 100) : 0.0;

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  '観戦統計',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildStatRow(context, '総観戦数', totalMatches.toString(), Colors.blue, Icons.stadium),
            if (watches > 0) ...[
              const SizedBox(height: 12),
              _buildStatRow(context, '非統計観戦数', watches.toString(), Colors.blueGrey, Icons.visibility),
            ],
            const SizedBox(height: 12),
            _buildStatRow(context, '勝利数', wins.toString(), Colors.green, Icons.check_circle),
            const SizedBox(height: 12),
            _buildStatRow(context, '引き分け数', draws.toString(), Colors.orange, Icons.horizontal_rule),
            const SizedBox(height: 12),
            _buildStatRow(context, '敗戦数', losses.toString(), Colors.red, Icons.cancel),
            const Divider(height: 24),
            _buildStatRow(context, '勝率', '${winRate.toStringAsFixed(1)}%', Colors.purple, Icons.trending_up),
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
