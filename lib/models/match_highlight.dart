import 'package:hive/hive.dart';

part 'match_highlight.g.dart';

/// ハイライト動画情報
@HiveType(typeId: 3)
class MatchHighlight extends HiveObject {
  /// YouTubeリンクのURL
  @HiveField(0)
  String url;

  /// ハイライトのタイトル（オプション）
  @HiveField(1)
  String title;

  MatchHighlight({
    required this.url,
    this.title = 'ハイライト',
  });

  /// JSONからMatchHighlightを生成
  factory MatchHighlight.fromJson(Map<String, dynamic> json) {
    return MatchHighlight(
      url: json['url'] as String,
      title: json['title'] as String? ?? 'ハイライト',
    );
  }

  /// MatchHighlightをJSONに変換
  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'title': title,
    };
  }

  /// YouTubeのビデオIDを抽出
  /// 対応形式: https://www.youtube.com/watch?v=xxx, https://youtu.be/xxx
  String? getYouTubeVideoId() {
    try {
      // URLをトリム
      final trimmedUrl = url.trim();
      if (trimmedUrl.isEmpty) return null;

      // youtu.be の短縮URLの場合
      if (trimmedUrl.contains('youtu.be/')) {
        final parts = trimmedUrl.split('youtu.be/');
        if (parts.length == 2) {
          // ?以降のクエリパラメータを削除
          return parts[1].split('?').first.split('&').first;
        }
      }

      // youtube.com の場合
      if (trimmedUrl.contains('youtube.com')) {
        try {
          final uri = Uri.parse(trimmedUrl);
          final videoId = uri.queryParameters['v'];
          if (videoId != null && videoId.isNotEmpty) {
            return videoId;
          }
        } catch (e) {
          // URL parse 失敗
        }
      }

      // 直接ビデオIDが入力されている場合（11文字のID）
      if (trimmedUrl.length == 11 && !trimmedUrl.contains('/') && !trimmedUrl.contains('?')) {
        return trimmedUrl;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// URLが有効なYouTubeリンクかどうか
  bool isValidYouTubeUrl() {
    return getYouTubeVideoId() != null;
  }

  @override
  String toString() => '$title ($url)';
}
