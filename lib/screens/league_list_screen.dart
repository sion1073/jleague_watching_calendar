import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/simple_auth_service.dart';
import '../services/season_service.dart';
import '../services/preferences_service.dart';
import '../models/season.dart';
import '../models/match_result.dart';
import '../widgets/app_layout.dart';
import 'season_detail_screen.dart';
import 'season_form_screen.dart';
import 'team_detail_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'search_screen.dart';

/// シーズン一覧画面（リーグ一覧）
///
/// シーズンタブとチームタブで構成されます。
class LeagueListScreen extends StatefulWidget {
  const LeagueListScreen({super.key});

  @override
  State<LeagueListScreen> createState() => _LeagueListScreenState();
}

class _LeagueListScreenState extends State<LeagueListScreen> {
  final _seasonService = SeasonService();
  final _preferencesService = PreferencesService();
  List<Season> _seasons = [];
  bool _isLoading = true;
  bool _includeStreaming = false;

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

      // 設定を読み込む
      final includeStreaming = await _preferencesService.getIncludeStreaming();

      // 全シーズンを取得
      final seasons = _seasonService.getSeasonsOrderedByYear(ascending: false);

      setState(() {
        _seasons = seasons;
        _includeStreaming = includeStreaming;
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

  /// ログアウト処理
  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authService = SimpleAuthService();
      await authService.logout();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  /// ナビゲーション変更ハンドラー
  void _onNavigationChanged(int index) {
    switch (index) {
      case 0:
        // シーズン一覧（現在の画面）
        break;
      case 1:
        // ホーム画面へ遷移
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
      case 2:
        // 検索画面への遷移
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // シーズン、チーム
      child: AppLayout(
        currentIndex: 0, // シーズン一覧
        onNavigationChanged: _onNavigationChanged,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ログアウト',
            onPressed: _handleLogout,
          ),
        ],
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // タブバー
                  Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: const TabBar(
                      tabs: [
                        Tab(text: 'シーズン'),
                        Tab(text: 'チーム'),
                      ],
                    ),
                  ),
                  // タブビュー
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildSeasonTab(),
                        _buildTeamTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// シーズン追加画面を開く
  Future<void> _openSeasonForm({Season? season}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => SeasonFormScreen(season: season),
      ),
    );

    // 保存/削除された場合はリロード
    if (result == true) {
      await _loadData();
    }
  }

  /// シーズンタブを構築
  Widget _buildSeasonTab() {
    // 日本代表を除外
    final seasonsWithoutJapan = _seasons.where((s) => s.name != '日本代表').toList();

    if (seasonsWithoutJapan.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_chart_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'シーズンがありません',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _openSeasonForm(),
              icon: const Icon(Icons.add),
              label: const Text('シーズンを追加'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadData,
          child: ListView.builder(
            itemCount: seasonsWithoutJapan.length,
            padding: const EdgeInsets.only(bottom: 80),
            itemBuilder: (context, index) {
              final season = seasonsWithoutJapan[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${season.year}'),
                  ),
                  title: Text(
                    season.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${_getFilteredMatchCount(season)}試合'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        tooltip: '編集',
                        onPressed: () => _openSeasonForm(season: season),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SeasonDetailScreen(season: season),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        // フローティングアクションボタン（シーズン追加）
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            onPressed: () => _openSeasonForm(),
            tooltip: 'シーズンを追加',
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  /// 観戦タイプでフィルタリングした試合数を取得
  int _getFilteredMatchCount(Season season) {
    if (_includeStreaming) {
      return season.matches.length;
    }
    return season.matches.where((match) => match.viewingType == ViewingType.stadium).length;
  }

  /// チームタブを構築
  Widget _buildTeamTab() {
    // 全試合からHOMEチーム別に集計（観戦タイプでフィルタリング）
    final Map<String, int> teamMatchCounts = {};
    for (final season in _seasons) {
      for (final match in season.matches) {
        // 配信視聴を含める設定がONの場合はすべてカウント
        // OFFの場合はスタジアム観戦のみカウント
        if (_includeStreaming || match.viewingType == ViewingType.stadium) {
          teamMatchCounts[match.homeTeam] = (teamMatchCounts[match.homeTeam] ?? 0) + 1;
        }
      }
    }

    // 試合数降順でソート
    final sortedTeams = teamMatchCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedTeams.isEmpty) {
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
              'チームがありません',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: sortedTeams.length,
        itemBuilder: (context, index) {
          final teamName = sortedTeams[index].key;
          final matchCount = sortedTeams[index].value;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  teamName[0],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                teamName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('$matchCount試合'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TeamDetailScreen(teamName: teamName),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
