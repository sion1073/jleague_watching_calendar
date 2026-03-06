// Jリーグチーム情報の定数
//
// HOMEチームと対戦相手の選択肢を提供します。

/// チーム情報を保持するクラス
class TeamInfo {
  final String name;
  final String division; // 'J1', 'J2', 'J3', 'national'
  final String? emblemAssetPath;

  const TeamInfo({
    required this.name,
    required this.division,
    this.emblemAssetPath,
  });
}

/// 全チームの TeamInfo リスト（単一の定義元）
///
/// エンブレム画像を追加する際は emblemAssetPath に
/// Jリーグクラブは 'assets/emblems/jleague/[filename].png'、
/// 日本代表は 'assets/emblems/national/[filename].png' 形式で指定してください。
const List<TeamInfo> allTeamInfoList = [
  // 日本代表
  TeamInfo(
    name: '日本代表',
    division: 'national',
    emblemAssetPath: null, // 例: 'assets/emblems/national/japan.png'
  ),
  // J1
  TeamInfo(name: '鹿島アントラーズ', division: 'J1', emblemAssetPath: 'assets/emblems/jleague/kashima.png'),
  TeamInfo(name: '水戸ホーリーホック', division: 'J1', emblemAssetPath: null),
  TeamInfo(name: '浦和レッズ', division: 'J1', emblemAssetPath: null),
  TeamInfo(name: 'ジェフユナイテッド千葉', division: 'J1', emblemAssetPath: null),
  TeamInfo(name: '柏レイソル', division: 'J1', emblemAssetPath: null),
  TeamInfo(name: 'FC東京', division: 'J1', emblemAssetPath: 'assets/emblems/jleague/fctokyo.jpg'),
  TeamInfo(name: '東京ヴェルディ', division: 'J1', emblemAssetPath: null),
  TeamInfo(name: 'FC町田ゼルビア', division: 'J1', emblemAssetPath: null),
  TeamInfo(name: '川崎フロンターレ', division: 'J1', emblemAssetPath: null),
  TeamInfo(name: '横浜F・マリノス', division: 'J1', emblemAssetPath: null),
  TeamInfo(name: '清水エスパルス', division: 'J1', emblemAssetPath: null),
  TeamInfo(name: '名古屋グランパス', division: 'J1', emblemAssetPath: null),
  TeamInfo(name: '京都サンガF.C.', division: 'J1', emblemAssetPath: null),
  TeamInfo(name: 'ガンバ大阪', division: 'J1', emblemAssetPath: null),
  TeamInfo(name: 'セレッソ大阪', division: 'J1', emblemAssetPath: null),
  TeamInfo(name: 'ヴィッセル神戸', division: 'J1', emblemAssetPath: null),
  TeamInfo(name: 'ファジアーノ岡山', division: 'J1', emblemAssetPath: null),
  TeamInfo(name: 'サンフレッチェ広島', division: 'J1', emblemAssetPath: null),
  TeamInfo(name: 'アビスパ福岡', division: 'J1', emblemAssetPath: null),
  TeamInfo(name: 'V・ファーレン長崎', division: 'J1', emblemAssetPath: null),
  // J2
  TeamInfo(name: '北海道コンサドーレ札幌', division: 'J2', emblemAssetPath: null),
  TeamInfo(name: 'ヴァンラーレ八戸', division: 'J2', emblemAssetPath: null),
  TeamInfo(name: 'ベガルタ仙台', division: 'J2', emblemAssetPath: null),
  TeamInfo(name: 'ブラウブリッツ秋田', division: 'J2', emblemAssetPath: null),
  TeamInfo(name: 'モンテディオ山形', division: 'J2', emblemAssetPath: null),
  TeamInfo(name: 'いわきFC', division: 'J2', emblemAssetPath: null),
  TeamInfo(name: '栃木シティ', division: 'J2', emblemAssetPath: null),
  TeamInfo(name: 'RB大宮アルディージャ', division: 'J2', emblemAssetPath: null),
  TeamInfo(name: '横浜FC', division: 'J2', emblemAssetPath: null),
  TeamInfo(name: '湘南ベルマーレ', division: 'J2', emblemAssetPath: null),
  TeamInfo(name: 'ヴァンフォーレ甲府', division: 'J2', emblemAssetPath: null),
  TeamInfo(name: 'アルビレックス新潟', division: 'J2', emblemAssetPath: null),
  TeamInfo(name: 'カターレ富山', division: 'J2', emblemAssetPath: null),
  TeamInfo(name: 'ジュビロ磐田', division: 'J2', emblemAssetPath: null),
  TeamInfo(name: '藤枝MYFC', division: 'J2', emblemAssetPath: null),
  TeamInfo(name: '徳島ヴォルティス', division: 'J2', emblemAssetPath: null),
  TeamInfo(name: 'FC今治', division: 'J2', emblemAssetPath: null),
  TeamInfo(name: 'サガン鳥栖', division: 'J2', emblemAssetPath: null),
  TeamInfo(name: '大分トリニータ', division: 'J2', emblemAssetPath: null),
  TeamInfo(name: 'テゲバジャーロ宮崎', division: 'J2', emblemAssetPath: null),
  // J3
  TeamInfo(name: '福島ユナイテッドFC', division: 'J3', emblemAssetPath: null),
  TeamInfo(name: '栃木SC', division: 'J3', emblemAssetPath: null),
  TeamInfo(name: 'ザスパ群馬', division: 'J3', emblemAssetPath: null),
  TeamInfo(name: 'SC相模原', division: 'J3', emblemAssetPath: null),
  TeamInfo(name: '松本山雅FC', division: 'J3', emblemAssetPath: null),
  TeamInfo(name: 'AC長野パルセイロ', division: 'J3', emblemAssetPath: null),
  TeamInfo(name: 'ツエーゲン金沢', division: 'J3', emblemAssetPath: null),
  TeamInfo(name: 'FC岐阜', division: 'J3', emblemAssetPath: null),
  TeamInfo(name: 'レイラック滋賀FC', division: 'J3', emblemAssetPath: null),
  TeamInfo(name: 'FC大阪', division: 'J3', emblemAssetPath: null),
  TeamInfo(name: '奈良クラブ', division: 'J3', emblemAssetPath: null),
  TeamInfo(name: 'ガイナーレ鳥取', division: 'J3', emblemAssetPath: null),
  TeamInfo(name: 'レノファ山口FC', division: 'J3', emblemAssetPath: null),
  TeamInfo(name: 'カマタマーレ讃岐', division: 'J3', emblemAssetPath: null),
  TeamInfo(name: '愛媛FC', division: 'J3', emblemAssetPath: null),
  TeamInfo(name: '高知ユナイテッドSC', division: 'J3', emblemAssetPath: null),
  TeamInfo(name: 'ギラヴァンツ北九州', division: 'J3', emblemAssetPath: null),
  TeamInfo(name: 'ロアッソ熊本', division: 'J3', emblemAssetPath: null),
  TeamInfo(name: '鹿児島ユナイテッドFC', division: 'J3', emblemAssetPath: null),
  TeamInfo(name: 'FC琉球', division: 'J3', emblemAssetPath: null),
];

/// チーム名 → TeamInfo の検索マップ（高速ルックアップ用）
final Map<String, TeamInfo> teamInfoByName = {
  for (final team in allTeamInfoList) team.name: team,
};

/// division でチーム名リストを取得するヘルパー
List<String> _teamNamesByDivision(String division) =>
    allTeamInfoList
        .where((t) => t.division == division)
        .map((t) => t.name)
        .toList();

/// J1リーグのチーム名リスト
List<String> get j1Teams => _teamNamesByDivision('J1');

/// J2リーグのチーム名リスト
List<String> get j2Teams => _teamNamesByDivision('J2');

/// J3リーグのチーム名リスト
List<String> get j3Teams => _teamNamesByDivision('J3');

/// HOMEチームのデフォルト選択肢（日本代表）
List<String> get homeTeams =>
    allTeamInfoList
        .where((t) => t.division == 'national')
        .map((t) => t.name)
        .toList();

/// 全対戦相手チームのリスト（J1 + J2 + J3の全60チーム + その他）
/// アルファベット順にソート
List<String> get allOpponentTeams {
  final teams = allTeamInfoList
      .where((t) => t.division != 'national')
      .map((t) => t.name)
      .toSet()
    ..add('その他');
  return teams.toList()..sort();
}
