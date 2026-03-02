import 'package:flutter/material.dart';
import 'preferences_service.dart';

/// アプリ全体の設定を保持する ChangeNotifier
///
/// InheritedNotifier でウィジェットツリー上位に配置することで、
/// 設定変更を即座に全画面へ反映させます。
class AppSettings extends ChangeNotifier {
  final _preferencesService = PreferencesService();

  bool _includeStreaming = false;
  bool _matchSortAscending = false;
  List<String> _selectedLeagues = ['j1', 'j2', 'j3'];
  bool _isLoaded = false;

  bool get includeStreaming => _includeStreaming;
  bool get matchSortAscending => _matchSortAscending;
  List<String> get selectedLeagues => List.unmodifiable(_selectedLeagues);
  bool get isLoaded => _isLoaded;

  /// SharedPreferences から設定を読み込む（アプリ起動時に一度呼ぶ）
  Future<void> load() async {
    _includeStreaming = await _preferencesService.getIncludeStreaming();
    _matchSortAscending = await _preferencesService.getMatchSortAscending();
    _selectedLeagues = await _preferencesService.getSelectedLeagues();
    _isLoaded = true;
    notifyListeners();
  }

  /// 配信視聴を含める設定を変更
  Future<void> setIncludeStreaming(bool value) async {
    if (_includeStreaming == value) return;
    _includeStreaming = value;
    notifyListeners();
    await _preferencesService.setIncludeStreaming(value);
  }

  /// 試合リストのソート順を変更（true: 昇順、false: 降順）
  Future<void> setMatchSortAscending(bool value) async {
    if (_matchSortAscending == value) return;
    _matchSortAscending = value;
    notifyListeners();
    await _preferencesService.setMatchSortAscending(value);
  }

  /// 選択リーグを変更
  Future<void> setSelectedLeagues(List<String> leagues) async {
    _selectedLeagues = List<String>.from(leagues);
    notifyListeners();
    await _preferencesService.setSelectedLeagues(_selectedLeagues);
  }

  /// InheritedWidget ツリーから AppSettings を取得する
  static AppSettings of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_AppSettingsScope>()!
        .notifier!;
  }
}

/// AppSettings をウィジェットツリーに提供する InheritedNotifier
class AppSettingsScope extends StatelessWidget {
  final AppSettings settings;
  final Widget child;

  const AppSettingsScope({
    super.key,
    required this.settings,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _AppSettingsScope(
      notifier: settings,
      child: child,
    );
  }
}

class _AppSettingsScope extends InheritedNotifier<AppSettings> {
  const _AppSettingsScope({
    required super.notifier,
    required super.child,
  });
}
