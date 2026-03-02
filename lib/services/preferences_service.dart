import 'package:shared_preferences/shared_preferences.dart';
import '../constants/team_constants.dart';

/// アプリの設定を管理するサービス
class PreferencesService {
  static const String _keyIncludeStreaming = 'include_streaming';
  static const String _keyHomeTeams = 'home_teams';
  static const String _keyMatchSortAscending = 'match_sort_ascending';

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

  /// 試合リストを昇順にするかどうか（trueで昇順、falseで降順）
  Future<bool> getMatchSortAscending() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMatchSortAscending) ?? false; // デフォルトは降順
  }

  /// 試合リストのソート順を設定
  Future<void> setMatchSortAscending(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMatchSortAscending, value);
  }

  /// HOMEチームのリストを取得
  Future<List<String>> getHomeTeams() async {
    final prefs = await SharedPreferences.getInstance();
    final teams = prefs.getStringList(_keyHomeTeams);
    // デフォルトは元のhomeTeams（FC東京、鹿島アントラーズ、日本代表）
    return teams ?? List<String>.from(homeTeams);
  }

  /// HOMEチームのリストを設定
  Future<void> setHomeTeams(List<String> teams) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyHomeTeams, teams);
  }
}
