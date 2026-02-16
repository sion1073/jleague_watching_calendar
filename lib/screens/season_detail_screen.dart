import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/season.dart';
import '../models/match_result.dart';
import '../services/preferences_service.dart';
import '../widgets/match_list_statistics_widget.dart';
import '../widgets/app_drawer.dart';
import 'match_form_screen.dart';

/// シーズン詳細画面
///
/// 特定のシーズンの試合一覧と詳細情報を表示します。
class SeasonDetailScreen extends StatefulWidget {
  final Season season;

  const SeasonDetailScreen({
    super.key,
    required this.season,
  });

  @override
  State<SeasonDetailScreen> createState() => _SeasonDetailScreenState();
}

class _SeasonDetailScreenState extends State<SeasonDetailScreen> {
  final _preferencesService = PreferencesService();
  bool _showDetails = false;
  bool _includeStreaming = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// 設定を読み込む
  Future<void> _loadSettings() async {
    final includeStreaming = await _preferencesService.getIncludeStreaming();
    setState(() {
      _includeStreaming = includeStreaming;
      _isLoading = false;
    });
  }

  /// 試合結果を日本語テキストに変換
  String _getResultText(MatchOutcome? result) {
    switch (result) {
      case MatchOutcome.win:
        return '勝利';
      case MatchOutcome.lose:
        return '敗北';
      case MatchOutcome.draw:
        return '引き分け';
      case MatchOutcome.tbd:
      default:
        return '予定';
    }
  }

  /// 勝敗に応じた色を取得
  Color _getResultColor(MatchOutcome? result) {
    switch (result) {
      case MatchOutcome.win:
        return Colors.green;
      case MatchOutcome.lose:
        return Colors.red;
      case MatchOutcome.draw:
        return Colors.orange;
      case MatchOutcome.tbd:
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.season.name),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        endDrawer: const AppDrawer(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 試合を観戦タイプでフィルタリングして日付降順でソート
    final matches = widget.season.matches.where((match) {
      return _includeStreaming || match.viewingType == ViewingType.stadium;
    }).toList()
      ..sort((a, b) => b.matchDate.compareTo(a.matchDate));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.season.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      endDrawer: const AppDrawer(),
      body: Column(
        children: [
          // 予定を追加ボタン
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MatchFormScreen(season: widget.season),
                  ),
                );
                if (result == true && mounted) {
                  setState(() {});
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('予定を追加'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),

          // 詳細情報表示トグルボタン
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Icon(
                  _showDetails ? Icons.expand_less : Icons.expand_more,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  '詳細情報を表示',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Switch(
                  value: _showDetails,
                  onChanged: (value) {
                    setState(() {
                      _showDetails = value;
                    });
                  },
                ),
              ],
            ),
          ),

          const Divider(),

          // 観戦統計
          if (matches.isNotEmpty)
            MatchListStatisticsWidget(
              matches: matches,
              title: '観戦統計（表示中の試合）',
            ),

          // 試合一覧
          Expanded(
            child: matches.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    itemCount: matches.length,
                    padding: const EdgeInsets.all(8.0),
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      return _buildMatchCard(match);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 空状態の表示
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_soccer_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '試合がありません',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    );
  }

  /// 試合カードを構築
  Widget _buildMatchCard(MatchResult match) {
    final dateFormatter = DateFormat('yyyy/MM/dd');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 基本情報
            Row(
              children: [
                // 観戦タイプアイコン
                Icon(
                  match.viewingType == ViewingType.stadium
                      ? Icons.stadium
                      : Icons.tv,
                  size: 16,
                  color: match.viewingType == ViewingType.stadium
                      ? Colors.blue
                      : Colors.purple,
                ),
                const SizedBox(width: 8),
                // 日付
                Expanded(
                  flex: 2,
                  child: Text(
                    dateFormatter.format(match.matchDate),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                // 対戦カード
                Expanded(
                  flex: 4,
                  child: Text(
                    '${match.homeTeam} vs ${match.awayTeam}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                // 結果
                Expanded(
                  flex: 2,
                  child: match.isFinished
                      ? Text(
                          match.score,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getResultColor(match.outcome),
                          ),
                        )
                      : Text(
                          _getResultText(match.outcome),
                          style: TextStyle(
                            color: _getResultColor(match.outcome),
                          ),
                        ),
                ),
                // 編集ボタン
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MatchFormScreen(
                          season: widget.season,
                          match: match,
                        ),
                      ),
                    );
                    if (result == true && mounted) {
                      setState(() {});
                    }
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            // 詳細情報（トグルONの場合のみ表示）
            if (_showDetails && match.isFinished) ...[
              const SizedBox(height: 8),
              const Divider(),
              // 勝敗
              Row(
                children: [
                  Icon(
                    _getResultIcon(match.outcome),
                    size: 16,
                    color: _getResultColor(match.outcome),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getResultText(match.outcome),
                    style: TextStyle(
                      color: _getResultColor(match.outcome),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // 得点者
              if (match.goalScorers.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.sports_soccer, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '得点者: ${match.getSortedGoalScorers().map((s) => s.toDisplayString()).join(', ')}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
              // メモ
              if (match.memo.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'メモ: ${match.memo}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// 勝敗に応じたアイコンを取得
  IconData _getResultIcon(MatchOutcome? result) {
    switch (result) {
      case MatchOutcome.win:
        return Icons.check_circle;
      case MatchOutcome.lose:
        return Icons.cancel;
      case MatchOutcome.draw:
        return Icons.horizontal_rule;
      case MatchOutcome.tbd:
      default:
        return Icons.schedule;
    }
  }
}
