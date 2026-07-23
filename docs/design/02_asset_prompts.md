# 外部AI向け 素材生成プロンプト集 (GameDesigner → AssetManager)

対象読者: AssetManager（外部画像生成AIへ投入）
方針: DevinDesktop内では画像生成しない。以下プロンプトを外部AI(例: 画像生成モデル)に投入して素材を得る。
言語: プロンプトは英語（画像生成AIの精度が高いため）。日本語補足を併記。

## 共通スタイル・トークン（全プロンプトに付加）

```
STYLE: "Tales of Eternia" style, anime JRPG, hand-drawn cel-shaded 2D sprite,
bright saturated colors, bold clean outlines, soft anime shading,
game asset, transparent background, PNG, no text, no watermark, no border.
```

共通ネガティブ:
```
NEGATIVE: 3d render, photorealistic, blurry, jpeg artifacts, extra limbs,
drop shadow on background, text, signature, watermark, cropped, low-res.
```

> ポイント:
> - **transparent background** を必ず指定（透過PNG）。
> - スプライトシートは **grid layout / evenly spaced cells** を明記し、セル数を固定。
> - 生成後、セルサイズが崩れる場合はセル単体で生成 → AssetManagerが結合。

---

## 1. プレイヤーキャラ

キャラ設定（`00_game_design.md` §3）:
- `hero` Roland Hartwell（主人公）: 18歳 男、剣士。快活な少年、短めの茶髪、旅装+片手剣。
- `childhood_girl` Fiona Merrick（幼馴染）: 18歳 女、僧侶。柔らかな金/亜麻色ロングヘア、白と青のローブ、杖。
- `otherworld_girl` Selene Aurelis（異世界の少女）: 18歳 女、魔術士。神秘的な銀/白髪、異国風の淡い衣装、ミステリアス。
- `elder_youth` Gareth Vaughn（年上の青年）: 22歳 男、重戦士。落ち着いた黒髪、頼れるリーダー、重装+大剣。

### 1-1. フィールド歩行シート（各キャラ共通レイアウト）
```
A <キャラ英語説明> sprite sheet for a top-down 2D JRPG, Tales of Eternia style.
LEGACY LAYOUT: grid of 4 rows x 4 columns (16 cells), evenly spaced, each cell 32x48 px.
Row order: facing DOWN, UP, LEFT, RIGHT.
Column order: idle, walk-1, walk-2, walk-3.
Consistent character across all cells, transparent background.
現行のRolandフィールド実装はこのシート形式ではなく、8方向の個別PNGフレームを使用する。
[+ STYLE tokens] [+ NEGATIVE]
```
日本語: 行→下上左右、列→待機/歩1/歩2/歩3。32x48セルの4x4。各キャラの `<キャラ英語説明>` は上の設定を英訳して差し込む（例: hero = "a cheerful teenage boy swordsman, short brown hair, traveler outfit, one-handed sword"）。

### 1-2. バトル用シート（前衛=剣/重戦士）
```
A side-view battle sprite sheet for a 2D action JRPG (Tales of Eternia LMB style).
Character: <hero or elder_youth, 上と同一デザイン>, facing RIGHT.
LEGACY LAYOUT: grid 2 rows x 4 columns (8 cells), evenly spaced, each cell 64x64 px.
Cells in order: idle, step-forward, attack-1, attack-2, attack-3, guard, hurt, victory.
[+ STYLE] [+ NEGATIVE]
```

### 1-3. バトル用シート（後衛/術=僧侶・魔術士）
```
A side-view battle sprite sheet for a 2D action JRPG, Tales of Eternia style.
Character: <childhood_girl or otherworld_girl, 上と同一デザイン>, facing RIGHT.
LEGACY LAYOUT: grid 2 rows x 4 columns (8 cells), evenly spaced, each cell 64x64 px.
Cells in order: idle, step-forward, cast-charge, cast-release, staff-swing, guard, hurt, victory.
[+ STYLE] [+ NEGATIVE]
```

### 1-4. オープニング用 落下ポーズ (`otherworld_girl_falling`)
```
A single full-body illustration of the otherworld girl falling from the sky,
Tales of Eternia style, arms slightly outstretched, hair and clothes flowing upward,
soft light around her. Transparent background, no ground.
Character: <otherworld_girl 設定と同一デザイン>. [+ STYLE] [+ NEGATIVE]
```
用途: OPで空から降ってくる演出（主人公が抱きとめる）。

### 1-5. 顔グラフィック / 立ち絵 (`*_face`)
```
A character portrait bust for a JRPG dialogue window, Tales of Eternia style.
Character: <キャラ説明>. Head and shoulders, facing slightly to the side.
LAYOUT: 2x2 grid of expressions (neutral, smile, angry, surprised), each 256x256 px.
[+ STYLE] [+ NEGATIVE]
```

---

## 2. 敵

### 2-1. スライム (`slime_battle` / `slime_field`)
```
A cute slime enemy sprite sheet, side-view for a 2D JRPG battle, Tales of Eternia style.
Blue translucent slime with glossy highlight and simple eyes.
LAYOUT: grid 1 row x 5 columns, each cell 64x64 px.
Cells: idle, hop-move, attack, hurt, defeat(fading).
[+ STYLE] [+ NEGATIVE]
```
フィールド用シンボルは 32x32・待機2コマで別途生成（同デザイン）。

### 2-2. ゴブリン (`goblin_battle`)
```
A goblin enemy sprite sheet, side-view battle, Tales of Eternia style.
Small green goblin with a crude dagger, mischievous.
LAYOUT: grid 1 row x 5 columns, each cell 64x64 px.
Cells: idle, move, attack, hurt, defeat.
[+ STYLE] [+ NEGATIVE]
```

### 2-3. ボス ゴーレム (`boss_golem`)
```
A large stone golem boss, side-view battle, Tales of Eternia style, imposing.
LAYOUT: grid 1 row x 5 columns, each cell 128x128 px.
Cells: idle, attack-smash, enrage, hurt, defeat(crumbling).
[+ STYLE] [+ NEGATIVE]
```

---

## 3. タイルセット / 背景

### 3-1. 町タイルセット (`town_tileset`)
```
A top-down RPG town tileset, Tales of Eternia style, anime fantasy village.
Seamless tiles on a grid, each tile 32x32 px, evenly spaced.
Include: grass, dirt path, cobblestone, stone wall, wooden house wall, red roof,
water edge, fence, flowers. Tileable/seamless edges.
[+ STYLE] [+ NEGATIVE]
```

### 3-1b. 町オブジェクト (`town_objects`)
```
A set of top-down RPG village objects, Tales of Eternia style, anime fantasy,
transparent background, evenly spaced on a grid. Rustic pastoral farming village.
Include: cottage with red-brown triangular roof, larger house, well, wooden fence,
flower bed, signboard, water wheel, wooden cart, barrels, lamp post.
[+ STYLE] [+ NEGATIVE]
```
用途: 始まりの町「エルデン村」の建物/装飾（`00_game_design.md` §5.1）。

### 3-2. フィールドタイルセット (`field_tileset`)
```
A top-down RPG overworld field tileset, anime fantasy, 32x32 tiles on a grid.
Include: grassland, dirt, rocks, tree, bush, flowers, cliff edge, path.
Seamless tileable. [+ STYLE] [+ NEGATIVE]
```

### 3-3. ダンジョンタイルセット (`dungeon_tileset`)
```
A top-down dungeon tileset, dark stone ruins, anime style, 32x32 tiles.
Include: stone floor, stone wall, wooden door, treasure chest, torch, stairs.
Seamless tileable. [+ STYLE] [+ NEGATIVE]
```

### 3-4. バトル背景 (`battle_bg_plains`)
```
A side-scrolling battle background for a 2D JRPG, Tales of Eternia style.
Grassy plain with distant hills and blue sky, horizontal 640x360, no characters.
Optional parallax layers. [+ STYLE] [+ NEGATIVE]
```

---

## 4. UI

### 4-1. ウィンドウ枠 (`ui_window`)
```
A JRPG message/menu window frame, Tales of Eternia style, semi-transparent deep blue,
ornate but clean gold trim corners. Designed for 9-slice scaling (repeatable edges,
distinct corners). Transparent center. PNG. [+ NEGATIVE]
```

### 4-2. ゲージ (`ui_hpbar`)
```
A JRPG status gauge asset set: an empty bar frame plus two fill bars
(red for HP, blue for TP), clean anime UI, 9-slice friendly. Transparent bg.
[+ NEGATIVE]
```

### 4-3. ボタン (`ui_button`)
```
A JRPG UI button in 3 states (normal, hover-highlight, pressed), rounded,
blue with gold trim, anime style, transparent background. [+ NEGATIVE]
```

### 4-4. アイコン (`ui_icons`)
```
A JRPG icon sheet, 32x32 cells on a grid, flat anime style, transparent bg.
Icons: fire, water, wind, earth, light, dark, heal-cross, sword, staff, potion.
[+ NEGATIVE]
```

---

## 5. エフェクト

```
# fx_slash
A slash effect animation sprite sheet, white-blue arc, anime JRPG,
1 row x 4 columns, each 64x64 px, transparent background. [+ NEGATIVE]

# fx_heal
A green healing sparkle effect sprite sheet, 1 row x 4 columns, 64x64 cells,
transparent background, anime JRPG. [+ NEGATIVE]

# fx_fire
A fireball / fire burst effect sprite sheet, 1 row x 5 columns, 64x64 cells,
transparent background, anime JRPG. [+ NEGATIVE]
```

---

## AssetManager 運用メモ
- **セル数がプロンプト通りか必ず検品**。ズレたら列/行を指定し直すか単体生成→結合。
- 生成物は `01_asset_list.md` の想定パスへ配置し、Godot import時 Filter=Off。
- 旧プロンプトではスプライトシートをGodotの `hframes`/`vframes` で切り出す想定だった。現行のRoland/Wolfは、約124x124の個別PNGフレームをフォルダへ配置し、GDScriptが実行時に `SpriteFrames` を構築する。実フォルダ名は `Run`、`Guard`、`Parry`、`attack/Combo_01` 等の大文字小文字を厳密に維持する。
  この列数・行数を変えると Programmer 実装と食い違うので、変更時は必ず共有。
