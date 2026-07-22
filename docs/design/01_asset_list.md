# 必要素材リスト (GameDesigner → AssetManager)

対象読者: AssetManager / Programmer
方針: 素材は**外部AIで生成**。本リストは「何が・いくつ・どの仕様で必要か」を定義する。
生成プロンプトは `02_asset_prompts.md` を参照。

共通規格:
- アートスタイル: テイルズ オブ エターニア風アニメ塗り（明るく彩度高め、太めの主線）。
- 透過PNG (RGBA)。ピクセルパーフェクト表示のため整数スケール前提。
- ネーミング: `snake_case`。配置は `assets/` 配下（下表の想定パス）。

凡例: 優先度 P1=今回必須 / P2=次回 / P3=後回し

---

## 1. キャラクター（プレイヤー）

キャラクター4名: `hero`(主人公18男/剣士)、`childhood_girl`(幼馴染18女/僧侶)、`otherworld_girl`(異世界18女/魔術士)、`elder_youth`(年上22男/重戦士)。設定は `00_game_design.md` §3 参照。

| ID | 用途 | 仕様 | 想定パス | 優先度 |
| --- | --- | --- | --- | --- |
| `hero_field` | 主人公・フィールド歩行 | 4方向(下/上/左/右) x 歩行3コマ + 待機1コマ。1コマ 32x48 | `assets/characters/hero/field.png` | P2 |
| `hero_battle` | 主人公・バトル | 待機/前進/攻撃1-3/被弾/ガード/勝利。横向き基準 64x64 | `assets/characters/hero/battle.png` | P3 |
| `childhood_girl_field` | 幼馴染・フィールド歩行 | 同上規格 | `assets/characters/childhood_girl/field.png` | P2 |
| `childhood_girl_battle` | 幼馴染・バトル | 待機/前進/詠唱/術発動/被弾/勝利 64x64 | `assets/characters/childhood_girl/battle.png` | P3 |
| `otherworld_girl_field` | 異世界の少女・フィールド歩行 | 同上規格 | `assets/characters/otherworld_girl/field.png` | P3 |
| `otherworld_girl_battle` | 異世界の少女・バトル | 待機/前進/詠唱/術発動/被弾/勝利 64x64 | `assets/characters/otherworld_girl/battle.png` | P3 |
| `elder_youth_field` | 年上青年・フィールド歩行 | 同上規格 | `assets/characters/elder_youth/field.png` | P3 |
| `elder_youth_battle` | 年上青年・バトル | 待機/前進/攻撃1-3/ガード/被弾/勝利 64x64 | `assets/characters/elder_youth/battle.png` | P3 |
| `*_face` | 会話用立ち絵/顔グラ | 256x256 表情差分(通常/笑/怒/驚) | `assets/characters/<id>/face.png` | P2 |
| `otherworld_girl_falling` | OP用・落下ポーズ | 空から降ってくる1枚絵(立ち絵) | `assets/characters/otherworld_girl/falling.png` | P3 |

> スプライトシートはグリッド整列（等間隔セル）。セル数・列数は `02_asset_prompts.md` に明記。

## 2. 敵キャラクター

| ID | 用途 | 仕様 | 想定パス | 優先度 |
| --- | --- | --- | --- | --- |
| `slime_field` | フィールド敵シンボル | 32x32 待機2コマ | `assets/enemies/slime/symbol.png` | P1(暫定単色可) |
| `slime_battle` | バトル | 64x64 待機/移動/攻撃/被弾/消滅 | `assets/enemies/slime/battle.png` | P2 |
| `goblin_battle` | バトル雑魚 | 64x64 同上 | `assets/enemies/goblin/battle.png` | P2 |
| `boss_golem` | ボス | 128x128 待機/攻撃/怒り/被弾/撃破 | `assets/enemies/boss_golem/battle.png` | P3 |

## 3. マップ / タイルセット

| ID | 用途 | 仕様 | 想定パス | 優先度 |
| --- | --- | --- | --- | --- |
| `town_tileset` | 町タイル | 16x16 or 32x32 グリッド。地面/道/草/壁/屋根/水 | `assets/tilesets/town.png` | P1 |
| `field_tileset` | フィールド | 同規格。草原/土/岩/木/花 | `assets/tilesets/field.png` | P1 |
| `dungeon_tileset` | ダンジョン | 同規格。石床/壁/扉/宝箱/松明 | `assets/tilesets/dungeon.png` | P2 |
| `town_objects` | 建物/装飾 | 家・看板・井戸・柵など単体オブジェクト | `assets/tilesets/town_objects.png` | P2 |
| `battle_bg_field` | バトル背景 | 640x360 横長。草原の1枚絵（多層パララックス可） | `assets/backgrounds/battle_field.png` | P1 |

> 現状 `assets/images/town.png` は暫定背景。P1でTileMapLayer用の `town_tileset` に移行する。

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
- P1で最優先なのは **tileset（town/field）・battle背景・UI基本(window/gauge/button)**。
- スプライトシートは**セルサイズ・列数・行の意味**を `02_asset_prompts.md` の通り固定して生成すること。
  ズレるとGodot側のフレーム切り出し(`hframes`/`vframes`)が破綻する。
- import後は `.import` の Filter を **Off (Nearest)** に設定（ピクセルのにじみ防止）。
- 命名/パスが変わる場合は Programmer に必ず共有（`res://` パス参照が壊れるため）。
