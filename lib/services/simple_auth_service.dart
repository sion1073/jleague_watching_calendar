import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 簡易パスワード認証サービス
///
/// フェーズ1のプロトタイプ用の認証サービス。
/// SHA-256ハッシュでパスワードを検証し、セッション情報をSharedPreferencesで管理します。
///
/// セキュリティ注意:
/// - このサービスは簡易的な認証であり、本番環境での使用は推奨されません
/// - パスワードのハッシュがソースコードに含まれているため、解析可能です
/// - 個人利用のプロトタイプとしての使用を想定しています
class SimpleAuthService {
  static const String _sessionKey = 'auth_session';
  static const String _sessionTimestampKey = 'auth_session_timestamp';

  // セッションの有効期限（7日間）
  static const Duration _sessionDuration = Duration(days: 7);

  // デフォルトパスワード: "password123" のSHA-256ハッシュ
  // 実際の使用時は環境変数や設定ファイルで管理することを推奨
  static const String _passwordHash =
      'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f';

  /// パスワードをSHA-256でハッシュ化
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// パスワードを検証
  ///
  /// [password] 検証するパスワード
  /// 戻り値: 認証成功の場合true、失敗の場合false
  Future<bool> authenticate(String password) async {
    if (password.isEmpty) {
      return false;
    }

    final hashedPassword = _hashPassword(password);

    if (hashedPassword == _passwordHash) {
      // 認証成功時、セッション情報を保存
      await _saveSession();
      return true;
    }

    return false;
  }

  /// セッション情報を保存
  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionKey, true);
    await prefs.setInt(_sessionTimestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// 現在のセッションが有効かどうかをチェック
  ///
  /// 戻り値: セッションが有効な場合true、無効な場合false
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final isSessionActive = prefs.getBool(_sessionKey) ?? false;

    if (!isSessionActive) {
      return false;
    }

    // セッションのタイムスタンプをチェック
    final timestamp = prefs.getInt(_sessionTimestampKey);
    if (timestamp == null) {
      return false;
    }

    final sessionTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(sessionTime);

    // セッションの有効期限をチェック
    if (difference > _sessionDuration) {
      // 期限切れの場合、セッションをクリア
      await logout();
      return false;
    }

    return true;
  }

  /// ログアウト処理
  ///
  /// セッション情報をクリアします。
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_sessionTimestampKey);
  }

  /// パスワードのハッシュ値を生成するユーティリティメソッド
  ///
  /// 開発時に新しいパスワードのハッシュを生成する際に使用します。
  /// 本番環境では使用しないでください。
  ///
  /// [password] ハッシュ化するパスワード
  /// 戻り値: SHA-256ハッシュ文字列
  static String generatePasswordHash(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
