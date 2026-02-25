import 'dart:convert' show JsonEncoder;
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'season_service.dart';

/// データエクスポートサービス
///
/// Hiveに保存されたシーズンデータをJSON形式でエクスポートし、
/// ブラウザのダウンロード機能でファイルとして保存する。
class ExportService {
  final SeasonService _seasonService;

  ExportService({SeasonService? seasonService})
      : _seasonService = seasonService ?? SeasonService();

  /// 全シーズンデータをJSONファイルとしてダウンロード
  ///
  /// ファイル名: jleague_data_YYYYMMDD_HHmmss.json
  Future<void> exportToJson() async {
    final data = _seasonService.exportAllData();
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    final now = DateTime.now();
    final timestamp =
        '${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    final fileName = 'jleague_data_$timestamp.json';

    final blob = web.Blob(
      [jsonString.toJS].toJS,
      web.BlobPropertyBag(type: 'application/json'),
    );
    final url = web.URL.createObjectURL(blob);

    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..setAttribute('download', fileName)
      ..click();

    web.URL.revokeObjectURL(anchor.href);
  }
}
