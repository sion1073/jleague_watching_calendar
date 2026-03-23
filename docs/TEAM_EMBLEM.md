# チームエンブレム管理仕様

## 概要

チームエンブレム画像をアセットとして管理し、チーム一覧画面等で表示する仕組みです。
エンブレムが未登録のチームはサッカーボールアイコンにフォールバックするため、画像は段階的に追加できます。

---

## ファイル構成

```
assets/emblems/
├── jleague/    ← Jリーグ全クラブのエンブレム画像
└── national/   ← 日本代表等のエンブレム画像
```

ディビジョン（J1/J2/J3）ではなく `jleague/` に一括配置することで、昇降格があってもファイルパスの変更が不要です。

---

## 画像の推奨仕様

| 項目 | 推奨値 |
|------|--------|
| サイズ | 256×256px（最低 128×128px）、正方形 |
| 余白 | 全辺に約13〜15%（エンブレム実体を画像の約70〜75%以内に収める） |
| 形式 | PNG（背景透過） |
| ファイル名 | 半角英数スネークケース（例: `urawa_reds.png`） |

### 余白について

`TeamEmblemWidget` は `ClipOval` で円形にクリップするため、正方形画像の四隅が切れます。
エンブレムが欠けないよう、画像内に余白を設けてください。

```
┌──────────────┐
│  ╭────────╮  │  ← 四隅は切れる
│  │        │  │
│  │エンブレム│  │  ← エンブレムはこの円内に収める
│  │        │  │
│  ╰────────╯  │
└──────────────┘
  ↑ 全辺に約13〜15%の余白
```

---

## チームとエンブレムの紐づけ

`lib/constants/team_constants.dart` の `allTeamInfoList` で管理します。

```dart
const List<TeamInfo> allTeamInfoList = [
  TeamInfo(
    name: '浦和レッズ',
    division: 'J1',
    emblemAssetPath: 'assets/emblems/jleague/urawa_reds.png', // 設定済み
  ),
  TeamInfo(
    name: '水戸ホーリーホック',
    division: 'J1',
    emblemAssetPath: null, // 未設定 → フォールバック表示
  ),
  // ...
];
```

### TeamInfo クラス

| フィールド | 型 | 説明 |
|-----------|-----|------|
| `name` | `String` | チーム名（試合データの文字列キーと一致させる） |
| `division` | `String` | 現在所属ディビジョン（`'J1'` / `'J2'` / `'J3'` / `'national'`） |
| `emblemAssetPath` | `String?` | アセットパス。未設定の場合は `null` |

### 派生データ

`allTeamInfoList` を単一の定義元として、以下の getter が自動生成されます。

| getter | 内容 |
|--------|------|
| `j1Teams` | J1所属チームの名前リスト |
| `j2Teams` | J2所属チームの名前リスト |
| `j3Teams` | J3所属チームの名前リスト |
| `homeTeams` | HOMEチームのデフォルト候補（`national`） |
| `allOpponentTeams` | 対戦相手の全候補（`national` 以外 + `'その他'`） |
| `teamInfoByName` | チーム名 → `TeamInfo` の高速ルックアップ用 Map |

---

## エンブレム画像の追加手順

1. `assets/emblems/jleague/` に画像ファイルを配置する
2. `lib/constants/team_constants.dart` の該当チームの `emblemAssetPath` を設定する

```dart
// 変更前
TeamInfo(name: '浦和レッズ', division: 'J1', emblemAssetPath: null),

// 変更後
TeamInfo(name: '浦和レッズ', division: 'J1', emblemAssetPath: 'assets/emblems/jleague/urawa_reds.png'),
```

3. アプリをリビルドすれば反映される

---

## 昇降格時の対応

`division` フィールドを更新するだけで対応できます。`emblemAssetPath` の変更は不要です。

```dart
// 降格前
TeamInfo(name: '○○FC', division: 'J1', emblemAssetPath: 'assets/emblems/jleague/xxfc.png'),

// 降格後（emblemAssetPath はそのまま）
TeamInfo(name: '○○FC', division: 'J2', emblemAssetPath: 'assets/emblems/jleague/xxfc.png'),
```

---

## 表示Widget

`lib/widgets/team_emblem_widget.dart` の `TeamEmblemWidget` を使用します。

```dart
TeamEmblemWidget(
  teamName: '浦和レッズ',
  size: 40.0, // 省略可（デフォルト: 40.0）
)
```

| パラメータ | 型 | デフォルト | 説明 |
|-----------|-----|-----------|------|
| `teamName` | `String` | 必須 | チーム名（`teamInfoByName` のキーと照合） |
| `size` | `double` | `40.0` | CircleAvatar の直径（px） |

### 表示ロジック

```
emblemAssetPath が設定されている
  → Image.asset で表示
  → 画像ロードエラー時 → sports_soccer アイコンにフォールバック

emblemAssetPath が null
  → sports_soccer アイコンを表示
```
