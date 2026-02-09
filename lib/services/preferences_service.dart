import 'package:shared_preferences/shared_preferences.dart';

/// アプリの設定を管理するサービス
class PreferencesService {
  static const String _keyIncludeStreaming = 'include_streaming';

  /// 配信視聴を含めるかどうか
  Future<bool> getIncludeStreaming() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIncludeStreaming) ?? false; // デフォルトはfalse
  }

  /// 配信視聴を含めるかどうかを設定
  Future<void> setIncludeStreaming(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIncludeStreaming, value);
  }
}
