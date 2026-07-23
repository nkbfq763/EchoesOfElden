# EchoesOfElden 開発状況・仕様 引き継ぎドキュメント

> 目的: 開発環境を **VSCode + Kimi** へ移行し、ゼロから引き継ぐための現状スナップショット。
> ゲームのコンセプト → 技術構成 → フォルダ構成 → 各機能の仕様 → データ構造 → 既知の課題 までを網羅する。
> 最終更新時点のブランチ: `main`（PR #1〜#4 マージ済み）。

---

## 0. TL;DR（最初に読むべき要点）

- **ジャンル**: テイルズ オブ エターニア風 2D アクションRPG（見下ろし探索 ＋ 横スクロールLMBS戦闘）。Godot 4系 / 2D。基本解像度 **640×360**。
- **主人公**: Roland Hartwell 固定（キャラ選択は廃止）。
- **実装済みの3本柱**: ①エルデン村マップ（4画面・メタ駆動・マスク衝突・8方向移動）、②LMBS戦闘（コンボ/特技/詠唱/敵AI/勝敗）、③メニュー画面（立ち絵カード）。
- **最大の構造的課題**: 通常プレイ導線（title→opening→**EldenVillage**）と、戦闘に到達する導線（legacy `main.tscn`→`field.tscn`→`battle.tscn`）が**分断**している。EldenVillage から戦闘・フィールドへ出る出口が未実装。
- **技術的負債**: 旧GodotTown由来の legacy シーン（`main.tscn`/`town_map.gd`/`player.gd`）と、3D地形プラグイン2種（`addons/zylann.hterrain`・`godot_terrain_plugin-master`）＋`demo/`＋`EternaWorld` 等の**本題と無関係な資産**がリポジトリに同居している。

---

## 1. コンセプト

テイルズ オブ エターニア風の 2D アクションRPG。フィールドはトップダウン（見下ろし・8方向移動）で探索し、敵シンボルに接触すると横スクロール型のアクションバトル（**Linear Motion Battle System / LMBS 風**）に切り替わる。

- プレイフィール: 軽快な移動 ＋ テンポの良い連携攻撃 ＋ 術技（スキル）。
- 想定ボリューム（縦割り1本）: `町 → フィールド → ダンジョン → ボス/戦闘 → 町`。
- 世界観: 大陸「エターナ」。精霊の力で術を使う。火/水/風/地/光/闇の属性。幼馴染×異世界の少女の恋愛群像。

### 主要キャラクター（設計上）
| ID | 名前 | クラス | 戦闘役割 | 状態 |
| --- | --- | --- | --- | --- |
| `hero` | Roland Hartwell | 剣士 | 前衛アタッカー（操作主体） | **実装済み**（フィールド/戦闘/立ち絵） |
| `childhood_girl` | Fiona Merrick | 僧侶/術士 | 後衛サポート | 立ち絵のみ（未playable） |
| `otherworld_girl` | Selene Aurelis | 魔術士 | 中衛アタッカー（術） | 未実装 |
| `elder_youth` | Gareth Vaughn | 重戦士 | 前衛タンク | 未実装 |

詳細は `docs/design/00_game_design.md` を参照。

---

## 2. 技術構成

| 項目 | 内容 |
| --- | --- |
| エンジン | Godot 4 系（`project.godot` の `config/features` は `"4.7"` と記録。**注意**: 検証は Godot 4.3 headless で実施してきた。手元のエディタ版を統一すること） |
| 言語 | GDScript（静的型付けスタイル。`Any`/`getattr` 等の緩い記法は不使用） |
| 描画 | 2D。全スプライトは `TEXTURE_FILTER_NEAREST`（ドット絵） |
| 解像度 | `viewport 640×360` / `window_override 1280×720` / `canvas_items` stretch / `integer` scale |
| メインシーン | `res://title.tscn` |
| Autoload | `GameData = res://game_data.gd`（唯一のグローバル状態） |
| 有効プラグイン | `addons/zylann.hterrain`（3D地形。**本題と無関係**、`EternaWorld`実験用） |

### 検証コマンド（headless import）
```bash
<godot4-bin> --headless --path <repo> --import
```
これで全スクリプトのパース/リソースロードエラーを確認できる（本プロジェクトは終了コード0を維持）。

---

## 3. フォルダ構成（プロジェクト本体のみ。addons/demo/legacy除く要点）

```
EchoesOfElden/
├─ project.godot              # 設定・入力アクション・autoload
├─ icon.svg
│
├─ title.tscn / title.gd      # タイトル（New/Continue → opening）
├─ opening.tscn / opening.gd  # オープニング演出（3ステップ → EldenVillage）
│
├─ EldenVillage.tscn / eldenvillage.gd   # ★現行の村マップ（4画面）
├─ FieldPlayer.tscn / field_player.gd    # ★8方向移動プレイヤー（村用）
│
├─ field.tscn / field/field.gd           # エンカウント用フィールド（legacy寄り）
│  └─ field/enemy_symbol.gd              # 敵シンボル（接触で戦闘へ）
│
├─ battle.tscn / battle.gd    # ★LMBS戦闘シーン・コントローラ
├─ battle_unit.gd             # ★戦闘ユニット（状態機械・アニメ・当たり）
├─ battle_transition.gd       # 画面割れ＋白フラッシュ遷移
│
├─ character_data.gd          # CharacterData リソース定義
├─ game_data.gd               # GameData（autoload）
│
├─ data/                      # ゲームデータ（.tres リソース）
│  ├─ enemy_data.gd / skill_data.gd
│  ├─ hero.tres               # Roland
│  ├─ wolf.tres / slime.tres / goblin.tres
│  ├─ skill_ember_blade.tres / skill_fireball.tres
│  └─ portrait_config.json    # メニュー立ち絵設定
│
├─ scenes/ui/                 # メニューUIシーン
│  ├─ MenuScreen.tscn / MenuButton.tscn
├─ scripts/ui/
│  ├─ menu_screen.gd / menu_button.gd / portrait_rect.gd
│
├─ ui/hud.tscn / ui/hud.gd    # 戦闘HUD（左下ステータス枠）
│
├─ assets/
│  ├─ characters/
│  │  ├─ party/roland_hartwell/
│  │  │  ├─ field/animations/{Run/<8方向>/frame_*.png, idle/<8方向>.png}
│  │  │  ├─ battle/animations/{idle,Run,attack/Combo_01..03,Guard,Parry,rotations}
│  │  │  └─ portrait/*.png   (common_face.png ほか表情差分)
│  │  ├─ party/fiona_merrick/portrait/*.png
│  │  └─ enemies/wolf/animations/{Idle,Run,Attack/Combo_01}/frame_*.png
│  └─ maps/
│     ├─ battle_maps/battle_bg_{plains,forest,cave,mountain,ruins,snow}.png
│     └─ settlements/s001_elden_village/
│        ├─ background/bg_screen_{a,b,c,d}.png
│        ├─ masks/*.png       (建物等ごとの衝突マスク)
│        ├─ objects/*.png     (建物等のスプライト)
│        └─ meta/bg_screen_{a,b,c,d}.json  (画面ごとの配置メタ)
│
├─ docs/
│  ├─ design/                 # 設計ドキュメント一式（00〜07）
│  └─ devin_instructions/     # 実装指示書（townmap/map_objects/battle/menu）
│
└─ 【legacy / 無関係】
   ├─ main.tscn / main.gd / town_map.tscn / town_map.gd / town_generator.gd
   ├─ player.tscn / player.gd
   ├─ addons/zylann.hterrain/ (3D地形)  ・ godot_terrain_plugin-master/ (Godot3構文・壊)
   ├─ demo/ ・ EternaWorld.tscn ・ GenerateHeightMap.tscn ・ terrain_data/ ・ maps/
   └─ node.tscn / node_2d.tscn (空/実験)
```

---

## 4. シーン遷移フロー（重要）

### 4.1 現行の通常プレイ導線
```
title.tscn ──New/Continue──▶ opening.tscn ──(ui_accept×3)──▶ EldenVillage.tscn
                                                                   │
                                                          (村内 4画面を端で移動)
                                                                   │
                                                          ※ここから先の出口が未実装 ★課題
```

### 4.2 戦闘に到達できる（legacy寄りの）導線
```
main.tscn ──▶ town_map(旧町) ⇄ field.tscn ──(敵シンボル接触)──▶ battle_transition ──▶ battle.tscn
                                  ▲                                                        │
                                  └───────────── 勝利 ──────────────────────────────────────┘
                                                 敗北 ──▶ title.tscn
```
- `field/field.gd._on_town_exit_body_entered()` は `main.tscn`（旧町）へ戻る。
- `main.gd` は `town_map`（旧GodotTownの町）をロードするが、旧町アセットは移行で欠落している可能性が高く**実質未使用/壊れている**。

### 4.3 まとめ（引き継ぎ者が最初に直すべき点）
- **EldenVillage と battle/field が繋がっていない。** 現状 `title→opening→EldenVillage` で遊ぶと戦闘に入れない。
- 戦闘は `field.tscn` を直接起動（F6）するか、コードから `GameData.set_encounter([...])` → `battle.tscn` へ切替でのみ確認可能。
- 望ましい統合: EldenVillage の特定の端（例: outskirts相当）に「フィールドへの出口」を置き、`field.tscn` を新アセット前提で作り直す or EldenVillage 内にエンカウントを持たせる。

---

## 5. 各システム仕様

### 5.1 タイトル / オープニング
- `title.gd`: New も Continue も `opening.tscn` へ（**セーブ/ロードは未実装**、Continue は New と同じ）。
- `opening.gd`: `GameData.set_character_data(hero.tres)` を実行し、`ui_accept` 3回の簡易演出後に `EldenVillage.tscn` へ。Selene/Roland は仮の `ColorRect` 表現。

### 5.2 エルデン村マップ（`eldenvillage.gd`）
- **4画面構成**（2×2）: `bg_screen_a/b/c/d`。隣接関係は `SCREEN_NEIGHBORS` 定数で定義（a↔b右, a↔c下, b↔d下, c↔d右）。
- **メタ駆動**: 各画面 `meta/bg_screen_X.json` を読み、背景差替＋オブジェクト（`objects/*.png`）配置。
- **衝突生成**: オブジェクトの `mask_ref`（`masks/*.png`）から `BitMap.opaque_to_polygons()` で `CollisionPolygon2D` を生成。判定は「**黒（RGB≤0.2）かつ 不透明（α≥0.5）= Solid**」のピクセル。
- **Z順**: オブジェクトは「足元Y（position.y ＋ 画像高×scale）」で `z_index` を決定（キャラとの前後関係）。
- **画面遷移**: プレイヤーが画面端（`EDGE_TRIGGER_DISTANCE=4px`）に到達で隣画面へ。到着側は反対端に再配置（`ENTRY_MARGIN=28px`）。クールダウン0.35s。
- **カメラ**: FieldPlayer 子の `Camera2D`。各画面サイズに `limit` を設定。
- **メニュー起動**: `_unhandled_input` で `menu` アクション（Esc/M）→ `MenuScreen.open()`。

### 5.3 フィールドプレイヤー（`field_player.gd`）
- `CharacterBody2D`。8方向の Run/idle を**実行時に `SpriteFrames` 構築**（`assets/.../field/animations/Run/<方向>/frame_*.png` を走査、idle は `idle/<方向>.png` 1枚）。
- 通常＝走り（速度は `CharacterData.speed`、既定150）、`walk_mod`（Shift）長押しで歩き（0.5倍）。
- 入力方向 → 角度 → 8オクタントで facing 決定。`character_id` でキャラ差替できるデータ駆動（現状 roland のみ登録）。
- スケール0.4・`offset (0,-62)`（124px素材を足元基準に配置）。

### 5.4 エンカウント遷移（`enemy_symbol.gd` / `battle_transition.gd`）
- `field.tscn` 内の敵シンボル（`Area2D`、緑の丸）に `CharacterBody2D` が接触 → `GameData.set_encounter([enemy_data], symbol_id)` → `battle_transition.play_to_battle()`。
- 遷移演出: 中央から左右パネルが閉じる → 白フラッシュ → `battle.tscn` へ `change_scene_to_file`（`CanvasLayer layer=100`）。
- 勝利後 `field.gd` は `defeated_symbol_id` のシンボルを消す。

### 5.5 LMBS 戦闘

#### コントローラ `battle.gd`（`BattleState { ACTIVE, RESULT }`）
- `_ready`: 主人公生成 → `GameData.pending_encounter`（空なら slime）から敵生成 → 背景設定 → UI取得。
- 背景選択優先度: `敵の battle_bg` → `GameData.battle_background` → `battle_bg_plains`。
- 入力（`_unhandled_input`）: attack(J)/tech(U)/cast(I)/jump(Space)/step(L)/target_next(Tab)。移動とガードは `_physics_process` で `ui_left/right` と `guard(K)` を毎フレーム反映。
- **ダメージ式**（`calculate_damage_with_roll`、指示書準拠）:
  ```
  base   = attacker.attack * skill_power
  raw    = base - defender.defense
  elem   = raw * element_multiplier            # none1.0 fire1.1 ice0.9 lightning1.0
  combo  = elem * (1 + min(combo_hits*0.01, 0.3))
  damage = max(1, floor(combo) + randi_range(-5,5))
  ```
  ガード成功（正面被弾かつGUARD中）はダメージ0.3倍＋TP回復。攻撃命中でTP+2、ガード中は0.25s毎にTP+1。
- ヒット判定: 横 `MELEE_RANGE=78`、縦 `HEIGHT_RANGE=30`、正面のみ。1振りにつき同一対象へ1回。
- 敵AI（`EnemyAIState`）: `APPROACH → TELEGRAPH → ATTACK → RECOVER → REPOSITION` のループ。間合い・`aggression`・`attack_interval`・`move_speed` で挙動が変化。TELEGRAPH中は頭上に警告円。
- 勝敗（`_check_battle_result`）: 主人公HP0 → 敗北 → タイトルへ。全敵撃破 → 各敵の `gald`/`exp` を合算し `GameData` に加算 → 勝利表示 → `field.tscn` へ。
- UI: ターゲットマーカー、コンボ「N HIT」、詠唱ゲージ（`CastProgress`）、フローティングダメージ数字、敵HPラベル、左下HUD。

#### ユニット `battle_unit.gd`（`class_name BattleUnit`、`Node2D`）
- 状態機械 `State`: `IDLE, MOVE, JUMP, ATTACK1/2/3, TECH, CAST, GUARD, STEP, HURT, DOWN, KO`。
- アニメは**実行時 `SpriteFrames` 構築**（フォルダ走査、`frame_*.png` をソートして追加）:
  - 主人公: `idle / run / attack1(Combo_01) / attack2(Combo_02) / attack3(Combo_03) / guard / parry`
  - 敵: `idle(Idle) / run(Run) / attack(Attack/Combo_01)`
  - `animations_path` 未設定の敵（slime/goblin）は **`_draw()` の矩形フォールバック**で描画。
- 通常攻撃: 3段コンボ（`request_attack` を連打で `attack_queued`→次段）。`_process_attack` の `attack_window` シグナルで当たり判定発火。
- 特技 TECH（`request_tech`）: TPを消費した近接アーツ（`skill_power>1`）。通常コンボ後派生可。
- 詠唱 CAST（`request_cast`）: `CAST_DURATION=1.2s` の詠唱後 `cast_completed` シグナルで発動。**詠唱中に被弾すると `active_skill` がクリアされ不発**（`receive_damage` 内）。
- ガード: 静止中のみ。ステップ: `STEP_DURATION=0.18s` の短い回避移動。ジャンプ: 重力あり。
- signals: `attack_window(attacker)` / `cast_completed(caster, skill)` / `state_changed(unit, new_state)`。

### 5.6 メニュー画面（`menu_screen.gd` / `MenuScreen.tscn`）
- 起動: `MenuButton`（村の右上「≡」）または Esc/M。`MenuScreen.open(tree)` static ヘルパが**専用 `CanvasLayer(layer=128)`** に載せて全画面・最前面化（PR #4 で修正。Camera2D変形やオブジェクト z_index の影響を回避）。
- グループ `"menu_screen"` による**多重生成防止**。開いている間 `get_tree().paused = true`（メニューは `PROCESS_MODE_ALWAYS`）。Esc/M/ui_cancel で閉じ pause 解除。
- カード: `GameData.party` から最大4人分を動的表示（Portrait/Name/Lv/HP/TP/Exp）。人数超過カードは非表示。HP/TP が `-1`（戦闘前）なら最大値表示。
- 立ち絵: `common_face.png` を `AtlasTexture` で `Rect2(300,0,400,1024)` にcrop。640×360向けに90×180で表示。
  - **補足**: Godot 4 の `TextureRect` に `region_enabled/region_rect` は無いため、Portraitノードに軽量スクリプト `portrait_rect.gd`（メタ変数保持）を付け、実crop は `AtlasTexture` で行っている。
- 設定は `data/portrait_config.json`（`character_name`→キー、例 `Roland Hartwell`→`roland_hartwell`。未登録は先頭エントリにフォールバック）。**キャラ追加時は JSON に足すだけ**。
- **未実装**: タブ（ステータス/アイテム）は表示のみで切替なし。Lv は `CharacterData` に項目が無く "Lv 1" 固定。

### 5.7 HUD（`ui/hud.gd`、`battle.tscn` に内包）
- 左下のテイルズ風ステータス枠。`GameData.party` 人数に応じて名前＋HP/TPバーを縦積み。Gald 表示。`battle_mode` で配置を変える。

---

## 6. データ構造

### GameData（autoload / `game_data.gd`）
```gdscript
character_data: CharacterData        # 操作キャラ
party: Array[CharacterData]          # パーティ（現状Rolandのみ）
gald: int = 100
exp: int = 0                         # 戦闘勝利で加算。※レベルには未接続
progress_flags: Dictionary
current_town_area / current_town_arrival_edge   # legacy town用
battle_background: String            # 既定 battle_bg_plains
pending_encounter: Array[EnemyData]  # 次戦闘の敵
pending_symbol_id / battle_won / defeated_symbol_id
# メソッド: set_character_data / get_character_data / set_encounter / finish_battle
```

### CharacterData（`character_data.gd`）
`character_name, character_type, sprite_texture, speed(150), health(100), defense(0), max_tp(100), current_hp(-1), current_tp(-1), attack(10)`。`reset_for_battle()` で current 値を最大に。
- ※**Lv/経験値フィールドは無し**（メニューLvが固定表示の理由）。

### EnemyData（`data/enemy_data.gd`）
`enemy_name, max_hp(30), attack(5), defense(0), exp(5), gald(3), attack_interval(2.0), aggression(0.1〜2.0), move_speed(45), battle_sprite, animations_path, battle_bg`。

### SkillData（`data/skill_data.gd`）
`skill_name, tp_cost(0), power(1.0), element("none")`。

### 既存 .tres インスタンス
| ファイル | 種別 | 主な値 |
| --- | --- | --- |
| `data/hero.tres` | CharacterData | Roland / hp120 / tp40 / atk14 / def4 |
| `data/wolf.tres` | EnemyData | hp42 atk10 def3 exp12 gald14 / 実スプライト・forest背景 |
| `data/slime.tres` | EnemyData | 矩形フォールバック（animations_path無） |
| `data/goblin.tres` | EnemyData | 矩形フォールバック |
| `data/skill_ember_blade.tres` | SkillData | 特技 tp8 power1.6 fire |
| `data/skill_fireball.tres` | SkillData | 術 tp12 power1.8 fire |

> **設計方針**: ゲームデータはJSONではなく Godot `.tres` リソースで統一（`portrait_config.json` と各画面 `meta/*.json` は例外的にJSON）。指示書はJSONを想定していたが、既存の流儀に合わせて `.tres` を採用している。

---

## 7. 入力アクション（`project.godot`）

| アクション | キー | 用途 |
| --- | --- | --- |
| `ui_left/right/up/down` | 矢印 | 移動/UI |
| `w/a/s/d` | WASD | 移動（フィールド） |
| `attack` | J | 通常攻撃（3段コンボ） |
| `guard` | K | ガード |
| `step` | L | ステップ回避 |
| `jump` | Space | ジャンプ |
| `tech` | U | 特技（TP消費・近接） |
| `cast` | I | 詠唱術（TP消費・遠隔） |
| `target_next` | Tab | 対象切替 |
| `walk_mod` | Shift | 歩き（長押し中） |
| `menu` | Esc / M | メニュー開閉 |
| `ui_accept` | Enter 等 | 決定/オープニング進行/戦闘結果 |

---

## 8. アセット規約（実行時ロードの前提）

- キャラ/敵アニメは **フォルダ内の連番 `frame_000.png, frame_001.png ...`** を名前昇順で読み込み `SpriteFrames` 化する（`.tres` の SpriteFrames は作らない）。
- 主人公フィールド: `party/<id>/field/animations/Run/<8方向>/frame_*.png` ＋ `idle/<方向>.png`。方向名は `north, north-east, east, ... , north-west`。
- 主人公戦闘: `party/<id>/battle/animations/{idle, Run, attack/Combo_01..03, Guard, Parry}`。
- 敵戦闘: `enemies/<id>/animations/{Idle, Run, Attack/Combo_01}`。`EnemyData.animations_path` にこのルートを指定。
- 素材は全て124×124目安 → 表示時 `scale 0.4` ＋ `offset (0,-62)` で足元基準。
- 戦闘背景: `assets/maps/battle_maps/battle_bg_*.png`（6種）。
- 村: `assets/maps/settlements/s001_elden_village/{background,masks,objects,meta}`。
- **素材生成はプロジェクト内で行わず外部AI（PixelLab等）で生成 → 想定パスへ配置**、が設計方針（`docs/design/02_,06_,07_` にプロンプト）。

---

## 9. ドキュメント群

- `docs/design/00〜07`: 設計仕様（ゲーム基本/素材リスト/生成プロンプト/実装仕様/テイルズ分析/戦闘/戦闘素材/戦闘背景）。
- `docs/design/Game_Asset_Architecture_v1.0.md`, `map_object_color_spec.md`: アセット構成・マスク色分類仕様。
- `docs/devin_instructions/`: 実装指示書4本（townmap_create / map_objects / battle / menu_create）。**①③④は実装済み、②map_objects は部分的**（村の衝突生成は実装済みだが、指示書が想定する `scripts/zobject_*` フルパイプラインや色分類=赤/青/緑/黒の完全対応は未実装）。

---

## 10. 実装済み範囲（PR履歴）

| PR | 内容 | 状態 |
| --- | --- | --- |
| #1 | エルデン村マップ表示（townmap_create Task1-5）＋ 8方向Roland ＋ legacy起動導線の修復 | merged |
| #2 | LMBS戦闘拡充（battle Task1-10）：実スプライト・ダメージ式・特技/詠唱・画面割れ遷移・exp報酬 | merged |
| #3 | メニュー画面（menu_create Task1-5） | merged |
| #4 | メニューを専用CanvasLayerで全画面・最前面化（不具合修正） | merged |

---

## 11. 既知の課題・技術的負債

### 構造・導線
1. **EldenVillage ↔ field/battle が未接続**（最重要）。通常プレイで戦闘に入れない。
2. `main.tscn`/`town_map.gd`/`town_generator.gd`/`player.gd` は**旧GodotTownのlegacy**。旧町アセットは欠落見込みで実質壊れ。`field.gd` の町出口が `main.tscn` を指しており、繋ぐなら要再設計。
3. `field.tscn` は legacy 寄り（`slime/goblin` をpreload、プレイヤー配置がハードコード）。新アセット前提で作り直すか、EldenVillage側にエンカウントを内包するのが望ましい。

### 無関係資産（削除/分離を検討）
4. 3D地形プラグイン **`addons/zylann.hterrain`**（有効化中）と **`godot_terrain_plugin-master`**（Godot3構文でパースエラーを出す・未使用）。`demo/`, `EternaWorld.tscn`, `GenerateHeightMap.tscn`, `terrain_data/`, `maps/eterna_height.png`, `scripts/eterna_world_loader.gd` 等の3D実験群も本題と無関係。リポジトリを軽く保つため整理推奨（ただし削除は要ユーザー確認）。
5. `node.tscn` / `node_2d.tscn` は空/実験ファイル。

### 機能の穴
6. **セーブ/ロード未実装**（Continue=New）。
7. **レベル/経験値システム未実装**（`GameData.exp` は貯まるが消費先なし。メニューLvは "Lv 1" 固定）。
8. パーティは Roland のみ。Fiona/Selene/Gareth は未playable（Fiona立ち絵のみ）。
9. 敵は wolf のみ実スプライト。slime/goblin は矩形フォールバック。
10. メニューのタブ切替（アイテム等）未実装。
11. ランダムエンカウント未実装（シンボル接触のみ）。ダンジョン/ボスも未実装。

### エンジン/運用
12. `project.godot` の `config/features` が `"4.7"`。検証は 4.3 で実施。**エディタのGodotバージョンを統一**し、開いた際の自動マイグレーションによる差分に注意（`git stash` 運用が過去に必要だった）。
13. Godot がプロジェクトを開くと `.import` や `project.godot` を自動更新することがある。**`.import` 系のノイズはコミットしない**運用。
14. リポジトリに CI/テスト/pre-commit は未設定。lint は headless import での確認のみ。

---

## 12. 引き継ぎ後の推奨ステップ（提案）

1. **導線統合**: EldenVillage に「フィールド/戦闘への出口」を実装（例: 特定画面の端に Area2D、`field.tscn` を新アセットで再構築 or 村内エンカウント）。
2. **legacy整理**: `main/town_map/player`・3D地形一式・`demo/` を別ブランチへ退避 or 削除（要確認）。無効プラグインの整理でパースエラー解消。
3. **セーブ/ロード**: `GameData` を JSON/`ConfigFile` で永続化し Continue を実装。
4. **成長要素**: `CharacterData` に `level/experience` を追加し、戦闘勝利の `exp` を接続。メニューLv表示も連動。
5. **パーティ拡張**: Fiona 等を `CharacterData` .tres ＋ field/battle アニメ規約に沿って追加。`portrait_config.json` にも追記。
6. **敵/コンテンツ拡充**: 敵アニメ付き `.tres` を増やし、ダンジョン→ボスを実装。

---

## 付録: よく使うパス

- 戦闘を直接確認: Godotエディタで `field.tscn` を F6 起動 → 緑シンボルに接触。
- コードから戦闘起動:
  ```gdscript
  GameData.set_encounter([preload("res://data/wolf.tres")], "wolf_1")
  get_tree().change_scene_to_file("res://battle.tscn")
  ```
- 主人公データ: `res://data/hero.tres` / 立ち絵設定: `res://data/portrait_config.json`
