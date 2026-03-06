import 'package:flutter/material.dart';
import '../constants/team_constants.dart';

/// チームエンブレムを表示するWidget
///
/// emblemAssetPath が設定されている場合は画像を表示し、
/// 未設定の場合はフォールバックとしてサッカーボールアイコンを表示します。
///
/// 使用例:
/// ```dart
/// TeamEmblemWidget(teamName: '浦和レッズ', size: 40)
/// ```
///
/// エンブレム画像を追加する手順:
/// 1. `assets/emblems/jleague/`（または `national/`）に画像ファイル（PNG推奨）を配置
/// 2. `team_constants.dart` の `allTeamInfoList` で該当チームの
///    `emblemAssetPath` に `'assets/emblems/jleague/[filename].png'` を設定
class TeamEmblemWidget extends StatelessWidget {
  final String teamName;

  /// CircleAvatar の直径（デフォルト: 40.0）
  final double size;

  const TeamEmblemWidget({
    super.key,
    required this.teamName,
    this.size = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    final teamInfo = teamInfoByName[teamName];
    final emblemPath = teamInfo?.emblemAssetPath;

    if (emblemPath != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: Image.asset(
            emblemPath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(context),
          ),
        ),
      );
    }

    return _buildFallbackIcon(context);
  }

  Widget _buildFallbackIcon(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      child: Icon(
        Icons.sports_soccer,
        size: size * 0.55,
      ),
    );
  }
}
