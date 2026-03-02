import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/season_service.dart';
import '../services/app_settings.dart';
import '../models/season.dart';
import '../models/match_result.dart';
import '../widgets/app_layout.dart';
import '../widgets/match_calendar_widget.dart';
import '../widgets/match_statistics_widget.dart';
import 'league_list_screen.dart';
import 'match_form_screen.dart';
import 'search_screen.dart';

/// ホーム画面
///
/// 認証後のメイン画面。
/// カレンダーと統計情報を表示します。
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _seasonService = SeasonService();
  List<Season> _seasons = [];
  bool _isLoading = true;

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

      setState(() {
        _seasons = seasons;
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
        // ホーム（現在の画面）
        break;
      case 2:
        // 検索画面への遷移
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SearchScreen()),
        );
        break;
    }
  }

  /// カレンダーの日付が選択された時のハンドラー
  void _onDaySelected(DateTime selectedDay, List<MatchResult> allMatches) {
    // 選択された日の試合があれば詳細を表示
    final matchesOnDay = allMatches.where((match) {
      return match.matchDate.year == selectedDay.year &&
          match.matchDate.month == selectedDay.month &&
          match.matchDate.day == selectedDay.day;
    }).toList();

    if (matchesOnDay.isNotEmpty) {
      _showMatchesDialog(selectedDay, matchesOnDay);
    }
  }

  /// その日の試合を表示するダイアログ
  void _showMatchesDialog(DateTime date, List<MatchResult> matches) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '${date.year}年${date.month}月${date.day}日の試合',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: matches.map((match) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${match.homeTeam} vs ${match.awayTeam}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      match.isFinished
                          ? '結果: ${match.score} (${_getResultText(match.outcome.name)})'
                          : '予定',
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// 試合結果を日本語テキストに変換
  String _getResultText(String? result) {
    switch (result?.toLowerCase()) {
      case 'win':
        return '勝利';
      case 'lose':
        return '敗北';
      case 'draw':
        return '引き分け';
      default:
        return '未定';
    }
  }

  /// デフォルトシーズンを取得または作成
  Future<Season> _getOrCreateDefaultSeason() async {
    final seasons = _seasonService.getAllSeasons();

    // 既存のシーズンがあればそれを使用
    if (seasons.isNotEmpty) {
      // 最新年度のシーズンを返す
      seasons.sort((a, b) => b.year.compareTo(a.year));
      return seasons.first;
    }

    // シーズンがない場合、現在の年度のデフォルトシーズンを作成
    final currentYear = DateTime.now().year;
    final defaultSeason = Season(
      name: '$currentYear' 'シーズン',
      year: currentYear,
      matches: [],
    );

    await _seasonService.addSeason(defaultSeason);
    return defaultSeason;
  }

  /// 試合登録画面を開く
  Future<void> _openMatchForm() async {
    try {
      final defaultSeason = await _getOrCreateDefaultSeason();
      if (!mounted) return;

      if (!context.mounted) return;
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MatchFormScreen(season: defaultSeason),
        ),
      );

      if (result == true && mounted) {
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.of(context);

    // 全試合を取得（観戦タイプでフィルタリング）
    final allMatches = <MatchResult>[];
    for (final season in _seasons) {
      for (final match in season.matches) {
        if (settings.includeStreaming ||
            match.viewingType == ViewingType.stadium) {
          allMatches.add(match);
        }
      }
    }

    return AppLayout(
      currentIndex: 1, // ホーム
      onNavigationChanged: _onNavigationChanged,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _seasons.isEmpty
              ? _buildEmptyState()
              : _buildContent(allMatches, settings.includeStreaming),
    );
  }

  /// データがない場合の表示
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '観戦記録がありません',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '試合を登録して観戦記録を始めましょう',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _openMatchForm,
            icon: const Icon(Icons.add),
            label: const Text('試合を登録する'),
          ),
        ],
      ),
    );
  }

  /// コンテンツを構築
  Widget _buildContent(List<MatchResult> allMatches, bool includeStreaming) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: [
          // カレンダーウィジェット
          MatchCalendarWidget(
            matchResults: allMatches,
            onDaySelected: (day) => _onDaySelected(day, allMatches),
          ),
          const SizedBox(height: 16),
          // 試合登録ボタン
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: _openMatchForm,
              icon: const Icon(Icons.add),
              label: const Text('試合を登録する'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 統計ウィジェット
          MatchStatisticsWidget(
            seasons: _seasons,
            includeStreaming: includeStreaming,
          ),
        ],
      ),
    );
  }
}
