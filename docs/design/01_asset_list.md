# 必要素材リスト (GameDesigner → AssetManager)

対象読者: AssetManager / Programmer
方針: 素材は**外部AIで生成**。本リストは「何が・いくつ・どの仕様で必要か」を定義する。
生成プロンプトは `02_asset_prompts.md` を参照。

共通規格:
- アートスタイル: テイルズ オブ エターニア風アニメ塗り（明るく彩度高め、太めの主線）。
- 透過PNG (RGBA)。ピクセルパーフェクト表示のため整数スケール前提。
- ネーミング: IDは `snake_case`。配置は `assets/` 配下。実装済みアニメーションのフォルダ名はLinuxの大文字小文字を含めて実物に合わせる。

凡例: 優先度 P1=今回必須 / P2=次回 / P3=後回し

---

## 1. キャラクター（プレイヤー）

キャラクター4名: `hero`(主人公18男/剣士)、`childhood_girl`(幼馴染18女/僧侶)、`otherworld_girl`(異世界18女/魔術士)、`elder_youth`(年上22男/重戦士)。設定は `00_game_design.md` §3 参照。

| ID | 用途 | 仕様 | 想定パス | 優先度 |
| --- | --- | --- | --- | --- |
| `roland_field` | 主人公・フィールド歩行 | 8方向。`Run/<direction>/frame_000..005.png` + `idle/<direction>.png`。入力フレームは約124x124 | `assets/characters/party/roland_hartwell/field/animations/` | 実装済み |
| `roland_battle` | 主人公・バトル | 約124x124の個別PNG。`idle / Run / attack/Combo_01..03 / Guard / Parry` | `assets/characters/party/roland_hartwell/battle/animations/` | 実装済み |
| `fiona_portrait` | Fiona・ポートレート | 顔グラ差分。Playableのfield/battleは未実装 | `assets/characters/party/fiona_merrick/portrait/` | 一部実装 |
| `*_field` / `*_battle` | Fiona/Selene/Gareth | 4人パーティ用の将来アセット。実装時は同じフォルダ規約を使用 | `assets/characters/party/<id>/{field,battle}/animations/` | 将来 |
| `*_portrait` | 会話/メニュー用顔グラ | character IDごとのポートレート。メニュー表示は`portrait_config.json`でCrop指定 | `assets/characters/party/<id>/portrait/` | Roland/Fiona一部実装 |

> スプライトシートはグリッド整列（等間隔セル）。セル数・列数は `02_asset_prompts.md` に明記。

## 2. 敵キャラクター

| ID | 用途 | 仕様 | 想定パス | 優先度 |
| --- | --- | --- | --- | --- |
| `slime_field` | フィールド敵シンボル | 現在はシンボルのデータのみ。描画は暫定 | `data/slime.tres` | 実装済み |
| `wolf_battle` | バトル雑魚 | `Idle / Run / Attack/Combo_01`。個別PNGフレーム | `assets/characters/enemies/wolf/animations/` | 実装済み |
| `slime_battle` / `goblin_battle` | バトル雑魚 | `animations_path`未設定のため矩形フォールバック | `data/slime.tres` / `data/goblin.tres` | 暫定実装 |
| `boss_golem` | ボス | 待機/攻撃/怒り/被弾/撃破を予定 | `assets/characters/enemies/boss_golem/` | 将来 |

## 3. マップ / タイルセット

| ID | 用途 | 仕様 | 想定パス | 優先度 |
| --- | --- | --- | --- | --- |
| `town_tileset` | 町タイル | 将来のTileMapLayer用。現在のEldenVillageは背景画像方式 | `assets/tilesets/town.png` | 将来 |
| `field_tileset` | フィールド | 将来のTileMapLayer用 | `assets/tilesets/field.png` | 将来 |
| `dungeon_tileset` | ダンジョン | 石床/壁/扉/宝箱/松明を予定 | `assets/tilesets/dungeon.png` | 将来 |
| `town_objects` | 建物/装飾 | 現在は画面別の個別PNGオブジェクトを使用 | `assets/maps/settlements/s001_elden_village/objects/` | 実装済み |
| `battle_bg_<biome>` | バトル背景 | 640x360。現在は単層PNG | `assets/maps/battle_maps/battle_bg_<biome>.png` | 実装済み |

> 現在のEldenVillageは `assets/maps/settlements/s001_elden_village/{background,masks,objects,meta}/` を使用する。TileMapLayerへの移行は将来対応。

## 4. UI

| ID | 用途 | 仕様 | 想定パス | 優先度 |
| --- | --- | --- | --- | --- |
| `ui_window` | メッセージ/メニュー枠 | 9-slice 対応の枠(青系半透明) | `assets/ui/window.png` | P1 |
| `ui_hpbar` | HP/TPゲージ | 枠+塗り(赤=HP,青=TP)。9-slice可 | `assets/ui/gauge.png` | P1 |
| `ui_button` | ボタン(通常/hover/押下) | キャラ選択・メニュー用 | `assets/ui/button.png` | P1 |
| `ui_icons` | 属性/アイテムアイコン | 32x32 グリッド。火水風地光闇+回復/剣/杖 | `assets/ui/icons.png` | P2 |
| `ui_cursor` | 選択カーソル | 手/矢印 | `assets/ui/cursor.png` | P2 |
| `title_logo` | タイトルロゴ | 透過。ゲーム名ロゴ | `assets/ui/title_logo.png` | P2 |

## 5. エフェクト

| ID | 用途 | 仕様 | 想定パス | 優先度 |
| --- | --- | --- | --- | --- |
| `fx_slash` | 斬撃 | 64x64 3-5コマ | `assets/fx/slash.png` | P2 |
| `fx_hit` | 被弾ヒット | 32x32 3コマ | `assets/fx/hit.png` | P2 |
| `fx_heal` | 回復術 | 64x64 4コマ | `assets/fx/heal.png` | P2 |
| `fx_fire` | 火術 | 64x64 5コマ | `assets/fx/fire.png` | P3 |

## 6. サウンド（AI生成 or フリー音源、任意）

| ID | 用途 | 優先度 |
| --- | --- | --- |
| `bgm_town` / `bgm_field` / `bgm_battle` / `bgm_boss` | BGM | P3 |
| `se_attack` / `se_hit` / `se_menu` / `se_heal` | 効果音 | P3 |

---

## AssetManager への引き継ぎ事項
- 現在の実装済み優先素材は **EldenVillage背景/オブジェクト/マスク、Roland/Wolfの個別フレーム、battle背景**。TileSet・外部UI素材は将来対応。
- スプライトシートは**セルサイズ・列数・行の意味**を `02_asset_prompts.md` の通り固定して生成すること。
  ズレるとGodot側のフレーム切り出し(`hframes`/`vframes`)が破綻する。
- import後は `.import` の Filter を **Off (Nearest)** に設定（ピクセルのにじみ防止）。
- 命名/パスが変わる場合は Programmer に必ず共有（`res://` パス参照が壊れるため）。
