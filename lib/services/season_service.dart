import 'package:hive/hive.dart';
import '../models/season.dart';
import '../models/match_result.dart';

/// シーズンデータを管理するサービスクラス
class SeasonService {
  static const String _boxName = 'seasons';
  Box<Season>? _box;

  /// シングルトンインスタンス
  static final SeasonService _instance = SeasonService._internal();
  factory SeasonService() => _instance;
  SeasonService._internal();

  /// サービスを初期化（アプリ起動時に呼び出す）
  Future<void> initialize() async {
    if (!Hive.isBoxOpen(_boxName)) {
      _box = await Hive.openBox<Season>(_boxName);
    } else {
      _box = Hive.box<Season>(_boxName);
    }
  }

  /// Boxを取得
  Box<Season> get box {
    if (_box == null || !_box!.isOpen) {
      throw StateError(
          'SeasonService is not initialized. Call initialize() first.');
    }
    return _box!;
  }

  /// 全シーズンを取得
  List<Season> getAllSeasons() {
    return box.values.toList();
  }

  /// シーズンを年度順にソートして取得
  List<Season> getSeasonsOrderedByYear({bool ascending = false}) {
    final seasons = getAllSeasons();
    seasons.sort((a, b) {
      final comparison = a.year.compareTo(b.year);
      return ascending ? comparison : -comparison;
    });
    return seasons;
  }

  /// シーズンを追加
  Future<int> addSeason(Season season) async {
    return await box.add(season);
  }

  /// シーズンを更新
  Future<void> updateSeason(int key, Season season) async {
    await box.put(key, season);
  }

  /// シーズンを削除
  Future<void> deleteSeason(int key) async {
    await box.delete(key);
  }

  /// 特定の年のシーズンを取得
  Season? getSeasonByYear(int year) {
    return box.values.firstWhere(
      (season) => season.year == year,
      orElse: () => throw StateError('Season for year $year not found'),
    );
  }

  /// 特定のシーズンに試合を追加
  Future<void> addMatchToSeason(int seasonKey, MatchResult match) async {
    final season = box.get(seasonKey);
    if (season == null) {
      throw StateError('Season with key $seasonKey not found');
    }
    season.addMatch(match);
    await season.save();
  }

  /// 全データをJSON形式でエクスポート
  Map<String, dynamic> exportAllData() {
    final seasons = getAllSeasons();
    return {
      'version': '1.0.0',
      'exportDate': DateTime.now().toIso8601String(),
      'seasons': seasons.map((s) => s.toJson()).toList(),
    };
  }

  /// JSON形式からデータをインポート
  Future<void> importData(Map<String, dynamic> data) async {
    final seasonsData = data['seasons'] as List<dynamic>;
    for (final seasonData in seasonsData) {
      final season = Season.fromJson(seasonData as Map<String, dynamic>);
      await box.add(season);
    }
  }

  /// 全データを削除（初期化）
  Future<void> clearAllData() async {
    await box.clear();
  }

  /// サービスを閉じる
  Future<void> dispose() async {
    await box.close();
    _box = null;
  }
}
