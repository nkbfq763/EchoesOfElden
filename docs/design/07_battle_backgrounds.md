# 戦闘背景 パターン生成プロンプト集

作成: 設計エージェント (GameDesigner) → AssetManager
対象: 外部画像生成AI（背景=シーン絵。キャラ/モーションは PixelLab＝`06_battle_assets_pixellab.md`）
関連: 戦場仕様は `05_battle_system.md` §2、マップ/世界観は `00_game_design.md`。

戦闘はサイドビュー横1ライン（`05`§2）。背景は**横長の1シーン**で、地面ラインの上に味方（左）・敵（右）が乗る。
本書は「共通テンプレ」＋「バイオメごとのパターン差し替え」で、多数の背景を量産する方式。

---

## 0. 共通規格（全背景で固定）

| 項目 | 値 |
| --- | --- |
| 解像度 | **640x360（16:9）** を基準。横スクロール余裕を持たせるなら 960x360 / 1280x360 |
| 構図 | サイドビュー。**下1/4〜1/3が地面（キャラが立つ床）**、上が空/奥景 |
| レイヤー | 可能なら**パララックス3層**（far=空/遠景, mid=中景, near+ground=近景と地面）を別PNGで出力 |
| 視点 | 地平線はやや低め。キャラが映えるよう中央〜手前は開けておく（オブジェクトで埋めない） |
| キャラ配置域 | 画面中央帯（横方向）に大きな障害物を置かない。左右端に装飾を寄せる |
| タイル性 | 横スクロールする層（遠景/雲/地面）は**左右シームレス**に |
| 形式 | PNG。単層なら不透明、パララックス出力なら各層透過 |

## 共通スタイルトークン（全プロンプトに付加）
```
STYLE: "Tales of Eternia" style, anime JRPG battle background, side-scrolling side view,
hand-painted, bright saturated colors, soft anime lighting, depth with parallax,
lower third is the ground where characters stand, open center area (no big obstacles),
no characters, no UI, no text. horizontal 640x360 (16:9).
```
共通ネガティブ:
```
NEGATIVE: characters, people, monsters, UI, HUD, text, watermark, signature,
top-down view, isometric, portrait orientation, cluttered center, blurry, 3d render.
```

## パララックス出力を求める場合の追記（任意）
```
Provide as separate horizontal layers: (1) far background (sky/distant scenery),
(2) mid layer (trees/hills/structures), (3) near ground layer (floor + foreground props).
Each layer on transparent background, seamless left-right tiling.
```

---

## 1. バイオメ別パターン（world/mapに対応）

各項目の英文を「共通スタイル＋共通ネガティブ」に挟んで投入。`res://assets/backgrounds/` へ配置想定。

### 1-1. 草原/平原 (`battle_bg_plains`) ※フィールド標準
```
A grassy plain battlefield, distant rolling green hills, blue sky with soft clouds,
scattered flowers and a few bushes at the edges, dirt-and-grass ground.
```

### 1-2. 森 (`battle_bg_forest`)
```
A forest clearing battlefield, tall trees framing the sides, dappled sunlight through
leaves, ferns and mushrooms at edges, mossy grass ground.
```

### 1-3. 洞窟/地下 (`battle_bg_cave`)
```
An underground cave battlefield, rocky stalactites above, faint glowing crystals,
dark stone walls receding into darkness, uneven rocky ground.
```

### 1-4. 遺跡/ダンジョン (`battle_bg_ruins`)
```
An ancient stone ruins battlefield, broken pillars and crumbling arches at the sides,
faded murals, torch light, cracked stone floor.
```

### 1-5. 村/町の広場 (`battle_bg_town`)
```
A village square battlefield (Elden Village), cobblestone ground, wooden houses with
red-brown roofs and a well at the sides, warm daylight, peaceful pastoral mood.
```

### 1-6. 山道/崖 (`battle_bg_mountain`)
```
A mountain path battlefield, tall cliffs and distant snow-capped peaks, windy sky,
scattered rocks and pine trees at edges, rocky dirt ground.
```

### 1-7. 砂漠 (`battle_bg_desert`)
```
A desert battlefield, rolling sand dunes, distant heat haze and a lone ruin silhouette,
bright hot sky, dry cracked sand ground.
```

### 1-8. 雪原 (`battle_bg_snow`)
```
A snowfield battlefield, snow-covered ground, distant frosted pine forest and mountains,
pale cold sky, gently falling snow, snow ground with footprints.
```

### 1-9. 沼地 (`battle_bg_swamp`)
```
A swamp battlefield, murky water pools and gnarled dead trees at the sides, mist,
dim greenish light, muddy ground with reeds.
```

### 1-10. 城内 (`battle_bg_castle`)
```
A castle interior battlefield, grand stone hall with tall stained-glass windows and
banners at the sides, red carpet, polished stone floor, dramatic light.
```

### 1-11. ボスアリーナ (`battle_bg_boss`)
```
A dramatic boss arena battlefield, ominous sky with swirling clouds and distant magic
energy, imposing ruined temple or dark throne backdrop, cracked ground with glowing
runes, tense atmosphere. (still: open center, no characters)
```

---

## 2. 時間帯 / 天候バリエーション（各バイオメに掛け合わせ）

同じ地形でも印象を変えるための修飾。プロンプト末尾に足す。
- 時間帯: `at dawn (pink sky)` / `at midday (bright)` / `at sunset (orange sky)` / `at night (moonlit, stars)`
- 天候: `rainy, wet ground reflections` / `foggy, low visibility` / `stormy with lightning` / `clear`
- 異変演出: `ominous purple sky with cracks in the air (Grand Fall anomaly)` ※物語の「異変」表現用

> 例: 草原×夕暮れ = `battle_bg_plains` の英文 ＋ `at sunset (orange sky)` ＋ 共通トークン。

---

## 3. 運用メモ（AssetManager）
- まず**フィールド標準の `battle_bg_plains` を最優先**（B1テスト用）。次いで forest / cave / boss。
- 640x360の単層1枚から開始。横スクロール/パララックスは必要になってから多層出力。
- 中央帯を開けること（キャラが被ると視認性が落ちる）。生成物が中央を埋めていたら再生成 or 端に寄せる指示を追加。
- 命名は `battle_bg_<biome>[_<variant>].png`、配置は `res://assets/backgrounds/`。パララックス層は `_far/_mid/_near` サフィックス。
- `01_asset_list.md` の `battle_bg_field` は本書の `battle_bg_plains` に統合（同一用途）。変更時はProgrammerへ共有。
- Godot import は（ピクセル調なら）Filter=Off、滑らかな絵なら Filter=On を素材の描き方に合わせて選択。
