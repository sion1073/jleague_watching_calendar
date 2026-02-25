import 'dart:async';
import 'dart:convert' show jsonDecode;
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'season_service.dart';

/// インポートモード
enum ImportMode {
  /// 既存データに追加
  append,

  /// 既存データをすべて置き換え
  replace,
}

/// データインポートサービス
///
/// ブラウザのファイル選択ダイアログでJSONファイルを選択し、
/// Hiveにデータをインポートする。
class ImportService {
  final SeasonService _seasonService;

  ImportService({SeasonService? seasonService})
      : _seasonService = seasonService ?? SeasonService();

  /// ファイル選択ダイアログを開き、JSONファイルを読み込む
  ///
  /// 返り値: ファイルから読み込んだJSONの内容（Map）、キャンセル時はnull
  Future<Map<String, dynamic>?> pickJsonFile() async {
    final completer = Completer<Map<String, dynamic>?>();

    final input = web.document.createElement('input') as web.HTMLInputElement
      ..type = 'file'
      ..accept = '.json,application/json'
      ..style.display = 'none';

    web.document.body!.append(input);

    input.addEventListener(
      'change',
      (web.Event event) {
        final files = input.files;
        if (files == null || files.length == 0) {
          input.remove();
          if (!completer.isCompleted) scheduleMicrotask(() => completer.complete(null));
          return;
        }
        final file = files.item(0)!;
        final reader = web.FileReader();

        reader.addEventListener(
          'load',
          (web.Event _) {
            input.remove();
            if (completer.isCompleted) return;
            try {
              final result = reader.result;
              final text = (result as JSString).toDart;
              final json = jsonDecode(text) as Map<String, dynamic>;
              // JSコールバックからDartのイベントループへ戻してからcomplete
              scheduleMicrotask(() => completer.complete(json));
            } catch (e) {
              scheduleMicrotask(() => completer.completeError(
                  Exception('JSONファイルの読み込みに失敗しました: $e')));
            }
          }.toJS,
        );

        reader.addEventListener(
          'error',
          (web.Event _) {
            input.remove();
            if (!completer.isCompleted) {
              scheduleMicrotask(() => completer.completeError(Exception('ファイルの読み込みに失敗しました')));
            }
          }.toJS,
        );

        reader.readAsText(file);
      }.toJS,
    );

    input.click();

    return completer.future;
  }

  /// JSONデータをインポートする
  ///
  /// [data]: エクスポートされたJSONデータ
  /// [mode]: インポートモード（追加 or 置き換え）
  ///
  /// 返り値: インポートしたシーズン数
  Future<int> importData(Map<String, dynamic> data, ImportMode mode) async {
    if (data['seasons'] == null) {
      throw Exception('不正なデータ形式です。"seasons" フィールドが見つかりません。');
    }

    if (mode == ImportMode.replace) {
      await _seasonService.clearAllData();
    }

    await _seasonService.importData(data);

    return (data['seasons'] as List<dynamic>).length;
  }
}
