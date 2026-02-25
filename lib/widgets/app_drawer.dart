import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/settings_screen.dart';
import '../services/export_service.dart';
import '../services/import_service.dart';
import '../services/simple_auth_service.dart';

/// アプリケーション共通のドロワーメニュー
///
/// オプション機能へのアクセスを提供します。
/// - データエクスポート
/// - データインポート
/// - 設定
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
            onTap: () => _handleExport(context),
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('データインポート'),
            onTap: () => _handleImport(context),
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

  /// データエクスポート処理
  Future<void> _handleExport(BuildContext context) async {
    Navigator.pop(context);
    try {
      final exportService = ExportService();
      await exportService.exportToJson();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('データをエクスポートしました')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エクスポートに失敗しました: $e')),
        );
      }
    }
  }

  /// データインポート処理
  Future<void> _handleImport(BuildContext context) async {
    final importService = ImportService();

    // ドロワーが閉じられると context が unmounted になるため、
    // 事前に Navigator と ScaffoldMessenger の参照を取得しておく
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);

    // ドロワーを閉じる前にファイル選択を開始する
    // （Navigator.pop後はユーザージェスチャーとの接続が切れるため）
    final fileFuture = importService.pickJsonFile();

    // ドロワーを閉じる
    if (context.mounted) Navigator.pop(context);

    // ファイル読み込み完了を待つ
    final Map<String, dynamic>? data;
    try {
      data = await fileFuture;
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('ファイルの読み込みに失敗しました: $e')),
      );
      return;
    }

    if (data == null) return; // キャンセル

    // ドロワーが閉じられた後のため context は unmounted だが、
    // 事前に取得した navigator の context を使用する
    // ignore: use_build_context_synchronously
    final mode = await showDialog<ImportMode>(
      context: navigator.context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('データインポート'),
        content: const Text('既存のデータをどうしますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(ImportMode.append),
            child: const Text('既存データに追加'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(ImportMode.replace),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            child: const Text('全データを置き換え'),
          ),
        ],
      ),
    );

    if (mode == null) return; // キャンセル

    try {
      final count = await importService.importData(data, mode);
      messenger.showSnackBar(
        SnackBar(content: Text('$count シーズンをインポートしました')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('インポートに失敗しました: $e')),
      );
    }
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
