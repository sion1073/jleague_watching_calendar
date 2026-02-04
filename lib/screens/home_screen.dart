import 'package:flutter/material.dart';
import '../services/simple_auth_service.dart';
import 'login_screen.dart';

/// ホーム画面
///
/// 認証後のメイン画面。
/// 今後、スケジュール一覧やメモなどの機能を追加していきます。
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
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

    if (confirmed == true && context.mounted) {
      final authService = SimpleAuthService();
      await authService.logout();

      if (context.mounted) {
        // ログイン画面に戻る
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('J.LEAGUE観戦カレンダー'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ログアウト',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 100,
              color: Colors.green.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'ログイン成功!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                '認証機能が正常に動作しています。\n今後、スケジュール管理機能などを追加していきます。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('この機能は次のフェーズで実装予定です'),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_month),
              label: const Text('スケジュール一覧（未実装）'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('この機能は次のフェーズで実装予定です'),
            ),
          );
        },
        tooltip: '新規予定を追加',
        child: const Icon(Icons.add),
      ),
    );
  }
}
