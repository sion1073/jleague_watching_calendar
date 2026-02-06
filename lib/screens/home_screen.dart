import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/simple_auth_service.dart';
import '../services/season_service.dart';
import '../models/season.dart';
import '../models/match_result.dart';
import '../widgets/app_layout.dart';
import '../widgets/match_calendar_widget.dart';
import '../widgets/match_statistics_widget.dart';
import 'login_screen.dart';
import 'league_list_screen.dart';

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
  List<MatchResult> _allMatches = [];
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

      // 全試合を取得
      final allMatches = <MatchResult>[];
      for (final season in seasons) {
        allMatches.addAll(season.matches);
      }

      setState(() {
        _seasons = seasons;
        _allMatches = allMatches;
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
        // シーズン一覧画面へ遷移
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LeagueListScreen()),
        );
        break;
      case 1:
        // ホーム（現在の画面）
        break;
      case 2:
        // 検索画面への遷移（未実装）
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('検索画面は次のフェーズで実装予定です')),
        );
        break;
    }
  }

  /// カレンダーの日付が選択された時のハンドラー
  void _onDaySelected(DateTime selectedDay) {
    // 選択された日の試合があれば詳細を表示
    final matchesOnDay = _allMatches.where((match) {
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

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: 1, // ホーム
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
          : _seasons.isEmpty
              ? _buildEmptyState()
              : _buildContent(),
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('試合登録機能は次のフェーズで実装予定です'),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('試合を登録する'),
          ),
        ],
      ),
    );
  }

  /// コンテンツを構築
  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        children: [
          // カレンダーウィジェット
          MatchCalendarWidget(
            matchResults: _allMatches,
            onDaySelected: _onDaySelected,
          ),
          const SizedBox(height: 16),
          // 統計ウィジェット
          MatchStatisticsWidget(
            seasons: _seasons,
          ),
        ],
      ),
    );
  }
}
