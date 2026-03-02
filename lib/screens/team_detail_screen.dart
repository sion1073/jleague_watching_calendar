import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../services/season_service.dart';
import '../services/app_settings.dart';
import '../models/season.dart';
import '../models/match_result.dart';
import '../widgets/match_list_statistics_widget.dart';
import '../widgets/app_drawer.dart';
import 'match_form_screen.dart';
import 'season_form_screen.dart';

/// HOMEチーム詳細画面
///
/// 特定のチームの全シーズン横断での試合一覧を表示します。
class TeamDetailScreen extends StatefulWidget {
  final String teamName;

  const TeamDetailScreen({
    super.key,
    required this.teamName,
  });

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  final _seasonService = SeasonService();
  bool _showDetails = false;
  bool _showStatistics = false;
  bool _isLoading = true;

  /// 全シーズンの試合データ（フィルタ前）
  List<_MatchWithSeason> _allMatches = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// データを読み込む
  Future<void> _loadData() async {
    try {
      // Hiveの初期化（まだ初期化されていない場合）
      if (!Hive.isBoxOpen('seasons')) {
        await Hive.initFlutter();
        await _seasonService.initialize();
      }

      // 全シーズンを取得
      final seasons = _seasonService.getAllSeasons();

      // 該当チームの試合を抽出（フィルタはbuildで行う）
      final List<_MatchWithSeason> matches = [];
      for (final season in seasons) {
        for (final match in season.matches) {
          if (match.homeTeam == widget.teamName) {
            matches.add(_MatchWithSeason(
              season: season,
              match: match,
            ));
          }
        }
      }

      setState(() {
        _allMatches = matches;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('データの読み込みに失敗しました: $e')),
        );
      }
    }
  }

  /// 日本代表用のシーズンを取得または作成
  Future<Season> _getOrCreateJapanSeason() async {
    final seasons = _seasonService.getAllSeasons();

    // 既存の日本代表シーズンを検索
    for (final season in seasons) {
      if (season.name == '日本代表') {
        return season;
      }
    }

    // 存在しない場合は新規作成
    final japanSeason = Season(
      name: '日本代表',
      year: 9999, // 特別な年度番号
      matches: [],
    );

    await _seasonService.addSeason(japanSeason);
    return japanSeason;
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

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.of(context);
    final isJapanNationalTeam = widget.teamName == '日本代表';

    // 観戦タイプでフィルタリングしてソート
    final matches = _allMatches.where((m) {
      return settings.includeStreaming ||
          m.match.viewingType == ViewingType.stadium;
    }).toList()
      ..sort(
        (a, b) => settings.matchSortAscending
            ? a.match.matchDate.compareTo(b.match.matchDate)
            : b.match.matchDate.compareTo(a.match.matchDate),
      );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.teamName),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 日本代表の場合のみシーズン編集ボタンを表示
          if (isJapanNationalTeam)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () async {
                final japanSeason = await _getOrCreateJapanSeason();
                if (!context.mounted) return;

                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SeasonFormScreen(season: japanSeason),
                  ),
                );
                if (result == true && context.mounted) {
                  _loadData();
                }
              },
              tooltip: 'シーズン設定',
            ),
        ],
      ),
      endDrawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 予定を追加ボタン（日本代表の場合のみ表示）
                if (isJapanNationalTeam)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final japanSeason = await _getOrCreateJapanSeason();
                        if (!context.mounted) return;

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MatchFormScreen(season: japanSeason),
                          ),
                        );
                        if (result == true && context.mounted) {
                          _loadData();
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('予定を追加'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ),

                // 観戦統計トグル
                if (matches.isNotEmpty) ...[
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showStatistics = !_showStatistics;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.bar_chart,
                            size: 18,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            '観戦統計',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Icon(
                            _showStatistics ? Icons.expand_less : Icons.expand_more,
                            color: Theme.of(context).primaryColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showStatistics)
                    MatchListStatisticsWidget(
                      matches: matches.map((m) => m.match).toList(),
                      title: '観戦統計（表示中の試合）',
                    ),
                  const Divider(height: 1),
                ],

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

                const Divider(height: 1),

                // 試合一覧
                Expanded(
                  child: matches.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: matches.length,
                          padding: const EdgeInsets.all(8.0),
                          itemBuilder: (context, index) {
                            return _buildMatchCard(matches[index]);
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
  Widget _buildMatchCard(_MatchWithSeason matchWithSeason) {
    final season = matchWithSeason.season;
    final match = matchWithSeason.match;
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
                // 日付（固定幅で改行防止）
                SizedBox(
                  width: 88,
                  child: Text(
                    dateFormatter.format(match.matchDate),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                // 対戦相手
                Expanded(
                  child: Text(
                    'vs ${match.awayTeam}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                // 結果
                SizedBox(
                  width: 56,
                  child: match.isFinished
                      ? Text(
                          match.score,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getResultColor(match.outcome),
                          ),
                          maxLines: 1,
                        )
                      : Text(
                          _getResultText(match.outcome),
                          style: TextStyle(
                            color: _getResultColor(match.outcome),
                          ),
                          maxLines: 1,
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
                          season: season,
                          match: match,
                        ),
                      ),
                    );
                    if (result == true && mounted) {
                      _loadData();
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
}

/// 試合とシーズンのペア
class _MatchWithSeason {
  final Season season;
  final MatchResult match;

  _MatchWithSeason({
    required this.season,
    required this.match,
  });
}
