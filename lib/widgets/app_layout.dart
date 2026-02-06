import 'package:flutter/material.dart';

/// 全画面共通レイアウト
///
/// ヘッダー（AppBar）とフッター（BottomNavigationBar）を持つ
/// 共通レイアウトウィジェット
class AppLayout extends StatelessWidget {
  /// 画面のメインコンテンツ
  final Widget body;

  /// 現在選択されているナビゲーションのインデックス
  /// 0: シーズン一覧, 1: ホーム, 2: 検索
  final int currentIndex;

  /// ナビゲーション変更時のコールバック
  final Function(int) onNavigationChanged;

  /// タイトル（AppBarに表示）
  final String title;

  /// AppBarのアクション（右上のアイコンボタンなど）
  final List<Widget>? actions;

  /// FloatingActionButton（オプション）
  final Widget? floatingActionButton;

  const AppLayout({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onNavigationChanged,
    this.title = 'J.LEAGUE観戦カレンダー',
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: actions,
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onNavigationChanged,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.table_chart),
            label: 'シーズン一覧',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: '検索',
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}
