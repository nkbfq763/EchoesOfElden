# 最初の仕様書 (GameDesigner → Programmer)

対象読者: Programmer（コーディングエージェント）
スコープ: **Phase 1 (P1)**。素材はプレースホルダで進め、後でAI素材に差し替える前提。
原則: Usage削減のため**コードは最小限**・データ駆動・シーンは責務分割。

---

## 0. 現状（P0 完了分）
- `character_select.tscn` (現main_scene): warrior/priest 選択 → `GameData` に格納 → `main.tscn` へ。
  → **この選択方式は廃止**。主人公固定のオープニングに置き換える（T2）。warrior/priestは踏襲せず新規4キャラを作成。
- `main.tscn`: `TownMap`(背景1枚絵+矩形コリジョン) + `Player`。
- `player.gd`: 8方向移動、`AnimatedSprite2D`、スプライトはコード描画（暫定）。
- `game_data.gd`: autoload。選択キャラを保持。

> キャラは新規4名: `hero`/`childhood_girl`/`otherworld_girl`/`elder_youth`（設定は `00_game_design.md` §3）。
> P1の操作キャラは **主人公(`hero`)固定**。

---

## 1. P1 で実装するもの（受け入れ条件つき）

### T1. 解像度・表示の統一
- `project.godot` の表示を **640x360 (16:9)** に設定。
  - `display/window/size/viewport_width=640`, `viewport_height=360`
  - `window/stretch/mode="canvas_items"`, `aspect="keep"`, integer scale 推奨。
- **受け入れ**: 起動時にタイトル/選択画面が16:9で崩れず表示される。

### T2. タイトル + オープニング（キャラ選択の廃止）
- `title.tscn`: New Game / Continue(仮・無効可) ボタン。`run/main_scene` を `title.tscn` に変更。
- **既存 `character_select.tscn`/`.gd` は削除**（または `opening.tscn` へ置換）。warrior/priest選択は行わない。
- New → `opening.tscn`(導入イベント) → 町(`main.tscn`)。
  - オープニングは「空から `otherworld_girl` が落下 → 主人公が抱きとめる」導入。P1では**簡易演出（立ち絵/テキスト送り）でよい**（本格演出はP2以降）。
- 主人公(`hero`)の `CharacterData` を新規作成し `GameData.party` の先頭に設定（コードで生成 or `.tres`）。
- **受け入れ**: 起動→タイトル→New→オープニング→町、まで一連で遷移でき、主人公が操作できる。

### T3. フィールドシーン `field.tscn`
- 町(`main.tscn`)の出口(Area2D)に触れると `field.tscn` へ遷移。逆も可（相互遷移）。
- フィールドにも Player を配置（同じ `player.gd` / `player.tscn` を再利用）。
- 敵シンボル(`enemy_symbol.tscn`)を2〜3体配置。プレイヤー接触で **バトルへ遷移**。
  - 遷移前に「どの敵と当たったか」を `BattleContext`(autoload or 一時データ)に渡す。
- **受け入れ**: 町⇄フィールド往復でき、敵シンボル接触でバトルシーンに入る。

### T4. バトルシーン雛形 `battle.tscn`（挙動の骨組み）
- サイドビュー。左に味方(操作キャラ)、右に敵1〜3体を並べる。
- 最低限の状態機械: `START → PLAYER_TURN(リアルタイム操作) → RESULT`。
  - P1では**通常攻撃1発が当たれば敵HP減少 → 敵全滅で勝利 → フィールドへ戻る**まで。
  - 詳細コンボ/TP/術技は P2。P1は「入って・殴って・勝って・戻れる」が通ればよい。
- 勝利時: フィールドの該当敵シンボルを消す（撃破反映）。
- **受け入れ**: 敵接触→バトル→攻撃で敵を倒す→フィールド復帰、が1ループ動く。

### T5. HUD `hud.tscn`（プレースホルダUIで可）
- フィールド: 先頭キャラ HP/TP バー + ガルド表示。
- バトル: パーティ HP/TP ゲージ。
- 素材未到着のため **ColorRect/ProgressBar 等の暫定UI** で作る（後でAI素材に差し替え）。
- **受け入れ**: HP変化がバーに反映される。

### T6. データ駆動化（コードを増やさないための土台）
- `character_data.gd`(既存 Resource) を活用しつつ、以下を追加:
  - `enemy_data.gd` (Resource): `enemy_name, max_hp, attack, defense, exp, gald, battle_sprite`.
  - `skill_data.gd` (Resource, P2先取り可): `skill_name, tp_cost, power, element`.
- 敵/キャラの具体値は `.tres` リソースで定義（コードにベタ書きしない）。
- **受け入れ**: 新しい敵を `.tres` 追加だけで登場させられる（コード変更不要）。

---

## 2. シーン/ファイル構成（提案）

```
res://
├─ title.tscn/.gd  /  opening.tscn/.gd  (T2, 旧character_selectを置換・削除)
├─ field/
│   ├─ main.tscn (=町) / main.gd        (既存, 出口Area2D追加)
│   ├─ field.tscn / field.gd            (T3)
│   └─ enemy_symbol.tscn / enemy_symbol.gd (T3)
├─ battle/
│   ├─ battle.tscn / battle.gd          (T4)
│   └─ battle_unit.gd                    (味方/敵共通の戦闘ユニット)
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
`GameData` に以下を追加していく:
```
party: Array[CharacterData]      # 選択キャラ + 加入キャラ
gald: int
progress_flags: Dictionary       # 進行状況
pending_encounter: EnemyData の配列 (バトルへ渡す一時データ)
```
バトル結果（勝敗・撃破した敵シンボルID）もここ経由でフィールドに返す。

---

## 4. 入力（既存踏襲 + 追加）
- 移動: WASD / 矢印（既存）。
- 決定/攻撃: `ui_accept`(Enter/Space) を追加割当。
- キャンセル/メニュー: `ui_cancel`(Esc) を追加割当。
- バトル攻撃ボタンは P1 では `ui_accept` で代用可。

---

## 5. ダメージ計算（P1簡易版）
```
damage = max(1, attacker.attack * power - defender.defense)   # power: 通常攻撃=1.0
```
`enemy_data`/`character_data` に `defense` を追加（初期値0でも可）。

---

## 6. プレースホルダ方針（重要）
- スプライト未到着でも進めるため、P1は以下で代用:
  - プレイヤー: 既存の procedural スプライト or 単色矩形。
  - 敵/背景/UI: `ColorRect` などの単色。
- **画像パスは `01_asset_list.md` の想定パスに合わせて仮参照**しておくと、
  AssetManager が素材を置くだけで差し替わる。
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
