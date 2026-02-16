import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/settings_screen.dart';
import '../services/simple_auth_service.dart';

/// アプリケーション共通のドロワーメニュー
///
/// オプション機能へのアクセスを提供します。
/// - データエクスポート（未実装）
/// - データインポート（未実装）
/// - 設定（未実装）
/// - ログアウト
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.sports_soccer,
                  size: 48,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(height: 8),
                Text(
                  'J.LEAGUE観戦カレンダー',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.file_upload),
            title: const Text('データエクスポート'),
            subtitle: const Text('未実装'),
            enabled: false,
            onTap: () {
              Navigator.pop(context);
              // TODO: エクスポート機能の実装
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('データエクスポート機能は未実装です')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('データインポート'),
            subtitle: const Text('未実装'),
            enabled: false,
            onTap: () {
              Navigator.pop(context);
              // TODO: インポート機能の実装
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('データインポート機能は未実装です')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('設定'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('ログアウト'),
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  /// ログアウト処理
  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('ログアウト'),
        content: const Text('ログアウトしますか?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // ドロワーを閉じる
      if (context.mounted) {
        Navigator.pop(context);
      }

      // ログアウト処理
      final authService = SimpleAuthService();
      await authService.logout();

      // ログイン画面に遷移
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }
}
