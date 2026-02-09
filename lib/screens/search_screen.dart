import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/season.dart';
import '../models/match_result.dart';
import '../services/season_service.dart';
import '../widgets/app_layout.dart';
import 'season_detail_screen.dart';
import 'league_list_screen.dart';
import 'home_screen.dart';

/// 検索画面
///
/// キーワード、シーズン、チーム、勝敗などでフィルタリングして
/// 試合を検索します。検索結果は常に詳細情報を含めて表示します。
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _seasonService = SeasonService();
  final _keywordController = TextEditingController();

  // フィルター条件
  String? _selectedSeasonKey;
  String? _selectedHomeTeam;
  String? _selectedAwayTeam;
  MatchOutcome? _selectedOutcome;
  ViewingType? _selectedViewingType;

  // 検索結果
  List<_SearchResultItem> _searchResults = [];
  bool _hasSearched = false;

  // 検索エリアの開閉状態
  bool _isSearchAreaExpanded = true;

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  /// 検索を実行
  void _performSearch() {
    final keyword = _keywordController.text.trim().toLowerCase();
    final allSeasons = _seasonService.getAllSeasons();
    final results = <_SearchResultItem>[];

    for (final season in allSeasons) {
      // 「日本代表」シーズンは除外しない（検索対象に含める）
      for (final match in season.matches) {
        // フィルター条件のチェック
        if (!_matchesFilters(season, match, keyword)) {
          continue;
        }

        results.add(_SearchResultItem(
          season: season,
          match: match,
        ));
      }
    }

    // 日付降順でソート
    results.sort((a, b) => b.match.matchDate.compareTo(a.match.matchDate));

    setState(() {
      _searchResults = results;
      _hasSearched = true;
    });
  }

  /// 試合がフィルター条件に一致するかチェック
  bool _matchesFilters(Season season, MatchResult match, String keyword) {
    // キーワード検索（チーム名、メモ、スコア）
    if (keyword.isNotEmpty) {
      final matchText = '${match.homeTeam} ${match.awayTeam} ${match.memo} ${match.score}'
          .toLowerCase();
      if (!matchText.contains(keyword)) {
        return false;
      }
    }

    // シーズンフィルター
    if (_selectedSeasonKey != null && season.key.toString() != _selectedSeasonKey) {
      return false;
    }

    // HOMEチームフィルター
    if (_selectedHomeTeam != null && match.homeTeam != _selectedHomeTeam) {
      return false;
    }

    // 対戦相手フィルター
    if (_selectedAwayTeam != null && match.awayTeam != _selectedAwayTeam) {
      return false;
    }

    // 勝敗フィルター
    if (_selectedOutcome != null && match.outcome != _selectedOutcome) {
      return false;
    }

    // 観戦タイプフィルター
    if (_selectedViewingType != null && match.viewingType != _selectedViewingType) {
      return false;
    }

    return true;
  }

  /// 利用可能なHOMEチームリストを取得
  List<String> _getAvailableHomeTeams() {
    final teams = <String>{};
    for (final season in _seasonService.getAllSeasons()) {
      for (final match in season.matches) {
        teams.add(match.homeTeam);
      }
    }
    return teams.toList()..sort();
  }

  /// 利用可能な対戦相手リストを取得
  List<String> _getAvailableAwayTeams() {
    final teams = <String>{};
    for (final season in _seasonService.getAllSeasons()) {
      for (final match in season.matches) {
        teams.add(match.awayTeam);
      }
    }
    return teams.toList()..sort();
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

  /// 観戦タイプを日本語テキストに変換
  String _getViewingTypeLabel(ViewingType type) {
    switch (type) {
      case ViewingType.stadium:
        return 'スタジアム観戦';
      case ViewingType.dazn:
        return 'DAZN配信';
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

  /// 検索条件の簡易サマリーを構築
  Widget _buildCompactSearchSummary() {
    final conditions = <String>[];

    // キーワード
    if (_keywordController.text.isNotEmpty) {
      conditions.add('キーワード: ${_keywordController.text}');
    }

    // シーズン
    if (_selectedSeasonKey != null) {
      final season = _seasonService.getAllSeasons().firstWhere(
        (s) => s.key.toString() == _selectedSeasonKey,
        orElse: () => _seasonService.getAllSeasons().first,
      );
      conditions.add('シーズン: ${season.name}');
    }

    // HOMEチーム
    if (_selectedHomeTeam != null) {
      conditions.add('HOME: $_selectedHomeTeam');
    }

    // 対戦相手
    if (_selectedAwayTeam != null) {
      conditions.add('vs $_selectedAwayTeam');
    }

    // 勝敗
    if (_selectedOutcome != null) {
      conditions.add('勝敗: ${_getResultText(_selectedOutcome)}');
    }

    // 観戦タイプ
    if (_selectedViewingType != null) {
      conditions.add('観戦: ${_getViewingTypeLabel(_selectedViewingType!)}');
    }

    if (conditions.isEmpty) {
      return const Text(
        '検索条件を設定してください',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey,
        ),
      );
    }

    return Text(
      conditions.join(' / '),
      style: const TextStyle(
        fontSize: 14,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// ナビゲーション変更ハンドラー
  void _onNavigationChanged(int index) {
    switch (index) {
      case 0:
        // シーズン一覧画面へ遷移
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LeagueListScreen()),
        );
        break;
      case 1:
        // ホーム画面へ遷移
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
      case 2:
        // 検索（現在の画面）
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final seasons = _seasonService.getAllSeasons();
    final homeTeams = _getAvailableHomeTeams();
    final awayTeams = _getAvailableAwayTeams();

    return AppLayout(
      currentIndex: 2, // 検索
      onNavigationChanged: _onNavigationChanged,
      title: '検索',
      body: Column(
      children: [
        // 検索フォーム
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 検索エリアの開閉ボタンと簡易表示
              InkWell(
                onTap: () {
                  setState(() {
                    _isSearchAreaExpanded = !_isSearchAreaExpanded;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    children: [
                      Icon(
                        _isSearchAreaExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _isSearchAreaExpanded
                            ? const Text(
                                '検索条件',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : _buildCompactSearchSummary(),
                      ),
                      Icon(
                        Icons.tune,
                        color: Theme.of(context).primaryColor,
                      ),
                    ],
                  ),
                ),
              ),

              // 詳細検索フォーム（開閉可能）
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 300),
                crossFadeState: _isSearchAreaExpanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // キーワード検索
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _keywordController,
                              decoration: const InputDecoration(
                                labelText: 'キーワード',
                                hintText: 'チーム名、メモなどで検索',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.search),
                              ),
                              onSubmitted: (_) => _performSearch(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _performSearch,
                            child: const Text('検索'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // シーズンフィルター
                      DropdownButtonFormField<String>(
                        initialValue: _selectedSeasonKey,
                        decoration: const InputDecoration(
                          labelText: 'シーズン',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('すべて'),
                          ),
                          ...seasons.map((season) => DropdownMenuItem(
                                value: season.key.toString(),
                                child: Text(season.name),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSeasonKey = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // HOMEチームフィルター
                      DropdownButtonFormField<String>(
                        initialValue: _selectedHomeTeam,
                        decoration: const InputDecoration(
                          labelText: 'HOMEチーム',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('すべて'),
                          ),
                          ...homeTeams.map((team) => DropdownMenuItem(
                                value: team,
                                child: Text(team),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedHomeTeam = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // 対戦相手フィルター
                      DropdownButtonFormField<String>(
                        initialValue: _selectedAwayTeam,
                        decoration: const InputDecoration(
                          labelText: '対戦相手',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('すべて'),
                          ),
                          ...awayTeams.map((team) => DropdownMenuItem(
                                value: team,
                                child: Text(team),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedAwayTeam = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // 勝敗フィルター
                      DropdownButtonFormField<MatchOutcome>(
                        initialValue: _selectedOutcome,
                        decoration: const InputDecoration(
                          labelText: '勝敗',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('すべて'),
                          ),
                          ...MatchOutcome.values.map((outcome) => DropdownMenuItem(
                                value: outcome,
                                child: Text(_getResultText(outcome)),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedOutcome = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      // 観戦タイプフィルター
                      DropdownButtonFormField<ViewingType>(
                        initialValue: _selectedViewingType,
                        decoration: const InputDecoration(
                          labelText: '観戦タイプ',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('すべて'),
                          ),
                          ...ViewingType.values.map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(_getViewingTypeLabel(type)),
                              )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedViewingType = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                secondChild: const SizedBox.shrink(),
              ),
            ],
          ),
        ),

        // 検索結果
        Expanded(
          child: _buildSearchResults(),
        ),
      ],
      ),
    );
  }

  /// 検索結果を構築
  Widget _buildSearchResults() {
    if (!_hasSearched) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'キーワードや条件を指定して検索してください',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '検索結果がありません',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '${_searchResults.length}件の結果',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ..._searchResults.map((result) => _buildSearchResultItem(result)),
      ],
    );
  }

  /// 検索結果アイテムを構築
  Widget _buildSearchResultItem(_SearchResultItem result) {
    final dateFormat = DateFormat('yyyy/MM/dd');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          // シーズン詳細画面またはチーム詳細画面へ遷移
          // デフォルトはシーズン詳細画面
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SeasonDetailScreen(season: result.season),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 試合情報（1行目）
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${dateFormat.format(result.match.matchDate)} ${result.match.homeTeam} vs ${result.match.awayTeam}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getResultColor(result.match.outcome),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getResultText(result.match.outcome),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // スコア
              if (result.match.score.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'スコア: ${result.match.score}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],

              // 得点者
              if (result.match.goalScorers.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  '得点者: ${result.match.getSortedGoalScorers().map((g) => g.toDisplayString()).join(', ')}',
                  style: const TextStyle(fontSize: 14, color: Colors.blue),
                ),
              ],

              // メモ
              if (result.match.memo.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'メモ: ${result.match.memo}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],

              // シーズン名
              const SizedBox(height: 8),
              Text(
                'シーズン: ${result.season.name}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 検索結果アイテム（シーズンと試合のペア）
class _SearchResultItem {
  final Season season;
  final MatchResult match;

  _SearchResultItem({
    required this.season,
    required this.match,
  });
}
