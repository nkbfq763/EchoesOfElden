# 最初の仕様書 (GameDesigner → Programmer)

対象読者: Programmer（コーディングエージェント）
スコープ: **Phase 1 (P1)**。素材はプレースホルダで進め、後でAI素材に差し替える前提。
原則: Usage削減のため**コードは最小限**・データ駆動・シーンは責務分割。

---

## 0. 現状（P0/P1 完了分）
- `title.tscn` (現main_scene) → `opening.tscn` → `EldenVillage.tscn`。
  `opening.gd` が `data/hero.tres` をロードし、Roland Hartwellを固定主人公として `GameData.party` に設定する。
- `EldenVillage.tscn`: 4画面の背景/オブジェクト/マスクをJSONメタデータからロードする新しい自己完結マップ。
- `FieldPlayer.tscn` / `field_player.gd`: 8方向移動、個別PNGから実行時に構築する`AnimatedSprite2D`。
- `field.tscn`: 旧 `player.tscn` を使用するレガシーなフィールドシーン。EldenVillageとは別系統で、現時点では統合していない。
- `game_data.gd`: autoload。主人公、party、エンカウント、報酬、村/バトル状態を保持する。

> キャラは新規4名: `hero`/`childhood_girl`/`otherworld_girl`/`elder_youth`（設定は `00_game_design.md` §3）。
> P1の操作キャラは **主人公(`hero`)固定**。

---

## 1. P1 で実装するもの（受け入れ条件つき）

### T1. 解像度・表示の統一
- `project.godot` の表示は **640x360 (16:9)** に設定済み。初期ウィンドウは1280x720。
  - `display/window/size/viewport_width=640`, `viewport_height=360`
  - `window/stretch/mode="canvas_items"`, `window/stretch/scale_mode="integer"`。`window_width_override=1280`, `window_height_override=720`。
- **現状**: 起動時にタイトル/オープニング/EldenVillageが16:9で表示される。

### T2. タイトル + オープニング（キャラ選択の廃止）
- `title.tscn`: New Game / Continue(仮・無効可) ボタン。`run/main_scene` を `title.tscn` に変更。
- **既存 `character_select.tscn`/`.gd` は現行フローでは使用しない**。warrior/priest選択は行わない。
- New → `opening.tscn`(導入イベント) → `EldenVillage.tscn`。
  - オープニングは「空から `otherworld_girl` が落下 → 主人公が抱きとめる」導入。P1では**簡易演出（立ち絵/テキスト送り）でよい**（本格演出はP2以降）。
- 主人公(`hero`)の `CharacterData` を新規作成し `GameData.party` の先頭に設定（コードで生成 or `.tres`）。
- **現状**: 起動→タイトル→New→オープニング→EldenVillage、まで一連で遷移でき、Rolandを操作できる。

### T3. フィールドシーン `field.tscn`
- `EldenVillage.tscn` は4画面の端遷移を実装している。EldenVillageから`field.tscn`への出口接続は未実装。
- `field.tscn`には旧 `player.tscn` を配置している。新しい`FieldPlayer.tscn`との統合は将来対応。
- 敵シンボル(`enemy_symbol.tscn`)を2〜3体配置。プレイヤー接触で **バトルへ遷移**。
  - 遷移前に「どの敵と当たったか」を `BattleContext`(autoload or 一時データ)に渡す。
- **現状**: legacy `field.tscn`では敵シンボル接触でバトルシーンに入る。EldenVillageとの往復接続は未実装。

### T4. バトルシーン雛形 `battle.tscn`（挙動の骨組み）
- サイドビュー。左に味方(操作キャラ)、右に敵1〜3体を並べる。
- 現在の状態機械: `BattleState { ACTIVE, RESULT }`。
  - `BattleUnit.State`: `IDLE, MOVE, JUMP, ATTACK1, ATTACK2, ATTACK3, TECH, CAST, GUARD, STEP, HURT, DOWN, KO`。
  - 敵AI: `APPROACH → TELEGRAPH → ATTACK → RECOVER → REPOSITION`。
  - 3段コンボ、TECH、CAST、ガード、ステップ、ジャンプ、勝敗、報酬まで実装済み。
- 勝利時: フィールドの該当敵シンボルを消す（撃破反映）。
- **現状**: legacy `field.tscn`で敵接触→バトル→勝利→field復帰のループが動く。

### T5. HUD `hud.tscn`（プレースホルダUIで可）
- フィールド: 先頭キャラ HP/TP バー + ガルド表示。
- バトル: パーティ HP/TP ゲージ。
- 素材未到着のため **ColorRect/ProgressBar 等の暫定UI** で作る（後でAI素材に差し替え）。
- **受け入れ**: HP変化がバーに反映される。

### T6. データ駆動化（コードを増やさないための土台）
- `character_data.gd`(既存 Resource) を活用しつつ、以下を追加:
  - `enemy_data.gd` (Resource): `enemy_name, max_hp, attack, defense, exp, gald, attack_interval, aggression, move_speed, battle_sprite, animations_path, battle_bg`.
  - `skill_data.gd` (Resource, P2先取り可): `skill_name, tp_cost, power, element`.
- 敵/キャラの具体値は `.tres` リソースで定義（コードにベタ書きしない）。
- `CharacterData` の現在のフィールドは `character_name, character_type, sprite_texture, speed, health, defense, max_tp, current_hp, current_tp, attack`。`level`/個別`experience`はなく、`GameData.exp`はグローバル値として保持する。メニューのレベル表示は暫定`Lv 1`。
- 現在の`GameData.party`はRolandのみ。MenuScreenは最大4人に対応するが、Fiona/Selene/Garethの加入データは未実装。
- **受け入れ**: 新しい敵を `.tres` 追加だけで登場させられる（コード変更不要）。

---

## 2. シーン/ファイル構成（提案）

```
res://
├─ title.tscn/.gd  /  opening.tscn/.gd  (T2)
├─ EldenVillage.tscn / eldenvillage.gd
├─ FieldPlayer.tscn / field_player.gd
├─ field/
│   ├─ main.tscn / main.gd              (旧町シーン)
│   ├─ field.tscn / field.gd            (T3)
│   └─ enemy_symbol.tscn / enemy_symbol.gd (T3)
├─ battle.tscn / battle.gd              (T4)
├─ battle_unit.gd                        (味方/敵共通の戦闘ユニット)
├─ ui/
│   └─ hud.tscn / hud.gd                 (T5)
├─ data/
│   ├─ character_data.gd (既存) / *.tres
│   ├─ enemy_data.gd / slime.tres, goblin.tres
│   └─ skill_data.gd / *.tres            (P2)
└─ autoload: game_data.gd (既存, パーティ/所持金/進行フラグを保持)
```

> 既存ファイルの移動はimportパス(`res://`)修正が伴うため、**急がず段階移行**でよい。
> まずは新規シーン追加を優先し、フォルダ整理は任意。

---

## 3. 状態共有 (autoload)
現行の`GameData`フィールド:
```
character_data: CharacterData
party: Array[CharacterData]      # 現在はRolandのみ。最大4人を想定
gald: int
exp: int                         # 現在はグローバル値。レベル計算未接続
progress_flags: Dictionary       # 進行状況
pending_encounter: EnemyData の配列 (バトルへ渡す一時データ)
current_town_area: String
current_town_arrival_edge: String
battle_background: String
pending_symbol_id: String
battle_won: bool
defeated_symbol_id: String
```
バトル結果（勝敗・撃破した敵シンボルID）もここ経由でフィールドに返す。

---

## 4. 入力（既存踏襲 + 追加）
- 移動: WASD / 矢印（既存）。
- 攻撃: `attack` (J)
- 特技: `tech` (U)
- 術: `cast` (I)
- ガード: `guard` (K)
- ステップ: `step` (L)
- ジャンプ: `jump` (Space)
- 対象切替: `target_next` (Tab)
- 低速歩行: `walk_mod` (Shift)
- メニュー: `menu` (Escape / M)

---

## 5. ダメージ計算（現行実装）
```
base   = attacker.attack * skill_power
raw    = base - defender.defense
elem   = raw * element_multiplier
combo  = elem * (1 + min(combo_hits * 0.01, 0.3))
damage = max(1, floor(combo) + randi_range(-5, 5))
```
`skill_power` は通常攻撃=1.0、技/術は`SkillData.power`。現在の属性は`none/fire/ice/lightning`で、その他の属性は将来対応。

---

## 6. プレースホルダ方針（重要）
- スプライト未到着でも進めるため、P1は以下で代用:
  - プレイヤー: 既存の procedural スプライト or 単色矩形。
  - 敵/背景/UI: `ColorRect` などの単色。
- 現行アセットは `assets/characters/party/<id>/...`、`assets/characters/enemies/<id>/...`、
  `assets/maps/settlements/...`、`assets/maps/battle_maps/...` を使用する。
- DevinDesktop内で画像生成はしない（AI素材待ち）。

---

## 7. Programmer からの確認事項（着手前に GameDesigner へ質問）
以下、判断に迷う場合は着手前に GameDesigner へ確認すること:
1. P1バトルは「1体操作+味方AIなし（ソロ）」で開始してよいか、最初からパーティ表示か。
   → **推奨: P1はソロ(操作1体)で骨組み。パーティ加入はP2。**
2. 既存の町(`main.tscn`)フォルダ移動をP1で行うか、後回しか。
   → **推奨: 後回し（パス破損リスク回避）。新規シーン追加を優先。**
3. セーブ形式（`user://` の JSON か `ConfigFile`）。
   → **推奨: P4で `ConfigFile`。P1は未実装でよい。**

---

## 8. 完了の定義（P1 DoD）
- [ ] 起動→タイトル→オープニング→町→フィールド→(敵接触)→バトル→勝利→フィールド、が一連で動く
- [ ] HUDにHP/TPが表示され、ダメージで減る
- [ ] 敵は `.tres` データから生成される
- [ ] 16:9で表示が崩れない
- [ ] プレースホルダ素材で動作（AI素材差し替え口が用意されている）

→ 完了後、AssetManager へ「素材差し替え依頼」、Tester へ「動作確認依頼」を送る。
