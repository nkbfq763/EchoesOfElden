# 戦闘アセット生成プロンプト集（PixelLab.ai 向け）

作成: 設計エージェント (GameDesigner) → AssetManager
対象: PixelLab.ai（ピクセルアート特化・キャラ生成＋モーション/アニメーション生成）
関連: 必要アニメは `05_battle_system.md` §14。キャラ設定は `00_game_design.md` §3。

> PixelLab は「①ベースキャラ生成 → ②同一キャラにアニメーション（モーション）を付ける」ワークフローが得意。
> **まずベースキャラを1体作り、それを基準に全モーションを生成**すると絵柄がブレない。

---

## 0. PixelLab 共通設定（全キャラ共通で指定）

| 項目 | 推奨値 | 備考 |
| --- | --- | --- |
| Style | **pixel art, anime JRPG (Tales of Eternia風)** | 明るく彩度高め・太めの主線 |
| View / 向き | **side view, facing right** | バトルは右向き基準（左は水平反転） |
| Canvas size | **現行素材は約124x124（Roland/Wolf）**。旧案は味方/雑魚64x64、ボス128x128、エフェクト64x64 | 現行は個別PNGフレームを実行時にSpriteFramesへ登録 |
| Directions | side（1方向でよい。歩きも左右のみ） | フィールド用は別途4/8方向 |
| Background | **transparent** | 透過必須 |
| Palette | ベースキャラの色を固定し全モーションで統一 | consistencyを最優先 |
| Outline | selective/black outline（統一） | |

共通ネガティブ（PixelLabで指定できる場合）: `blurry, 3d render, extra limbs, text, watermark, drop shadow on background`.

**手順の推奨**:
1. 「Create Character（text→sprite）」で §1 のベース説明からベースキャラを生成。
2. そのキャラを選び「Animate（skeleton / template / text）」で §2 の各アクションを生成。
3. 出力（各アニメのフレーム）を `01_asset_list.md` の想定パスへ配置。Godot import は Filter=Off。

---

## 1. ベースキャラ説明（Create Character 用）

そのまま “character description” に入れる短い英語説明。4名は同一世界観・同一絵柄で。

- **hero（Roland Hartwell / 主人公18・剣士）**
  `A cheerful teenage boy swordsman, short brown hair, light traveler's armor and tunic, one-handed sword, side view, anime JRPG pixel art.`
- **childhood_girl（Fiona Merrick / 幼馴染18・僧侶）**
  `A gentle teenage girl priest, long flaxen hair, white-and-blue robe, wooden holy staff, side view, anime JRPG pixel art.`
- **otherworld_girl（Selene Aurelis / 異世界18・魔術士）**
  `A mysterious teenage girl mage, silver-white hair, exotic pale-colored dress, glowing spell energy, side view, anime JRPG pixel art.`
- **elder_youth（Gareth Vaughn / 年上22・重戦士）**
  `A calm young man heavy warrior, dark hair, heavy plate armor, large two-handed sword, reliable leader, side view, anime JRPG pixel art.`

- **敵**
  - slime: `A cute blue translucent slime with glossy highlight and simple eyes, side view, anime JRPG pixel art.`
  - goblin: `A small green goblin with a crude dagger, mischievous, side view, anime JRPG pixel art.`
  - boss_golem: `A large stone golem boss, cracked rocky body, imposing, side view, anime JRPG pixel art.` (128x128)

---

## 2. モーション（Animate 用）— アクション別プロンプト

各ベースキャラに対し、下記アクションを1つずつ生成（PixelLabの「action / animation description」に入れる）。下表は将来アセット要件を含む。
フレーム数は目安（PixelLabのテンプレに合わせて調整可）。基準は**右向き**。

### 2.1 前衛（hero / elder_youth）
| アニメ名(Godot) | PixelLab action 説明 | 目安フレーム |
| --- | --- | --- |
| `idle` | `standing idle, slight breathing, holding sword` | 2–4 |
| `walk_fwd` | `walking forward` | 4–6 |
| `walk_back` | `stepping backward` | 4 |
| `jump` | `jumping up` | 3–4 |
| `attack1` | `sword horizontal slash, step 1 of combo` | 3–5 |
| `attack2` | `sword upward slash, step 2 of combo` | 3–5 |
| `attack3` | `sword strong downward finisher, step 3 of combo` | 4–6 |
| `tech` | `special technique: forward thrust with energy trail` (heroは突進技 / elder_youthは大振り) | 4–6 |
| `guard` | `raising sword/shield to guard, bracing` | 2–3 |
| `step` | `quick dodge step` | 2–3 |
| `hurt` | `flinching, hit reaction` | 2–3 |
| `down` | `knocked down on the ground` | 2–3 |
| `victory` | `victory pose, raising weapon` | 3–5 |

### 2.2 後衛/術者（childhood_girl / otherworld_girl）
| アニメ名(Godot) | PixelLab action 説明 | 目安フレーム |
| --- | --- | --- |
| `idle` | `standing idle, holding staff` | 2–4 |
| `walk_fwd` | `walking forward` | 4–6 |
| `walk_back` | `stepping backward` | 4 |
| `cast_charge` | `raising staff, gathering glowing magic energy (casting charge)` | 3–5 |
| `cast_loop` | `channeling magic, energy swirling (loopable)` | 2–4 |
| `cast_release` | `releasing the spell, staff thrust forward, burst of light` | 3–5 |
| `staff_swing` | `melee staff swing (weak attack)` | 3–4 |
| `guard` | `guarding with staff, bracing` | 2–3 |
| `hurt` | `flinching, hit reaction` | 2–3 |
| `down` | `knocked down` | 2–3 |
| `victory` | `victory pose, spinning staff / happy` | 3–5 |

### 2.3 敵
| 敵 | アニメ | action 説明 |
| --- | --- | --- |
| slime | `idle / move / attack / hurt / defeat` | `hopping idle` / `hopping forward` / `lunge body-slam attack` / `squished hit reaction` / `melting/fading defeat` |
| goblin | `idle / move / attack / hurt / defeat` | `idle with dagger` / `running forward` / `dagger stab` / `stagger hit` / `falling defeat` |
| boss_golem | `idle / move / attack1 / attack2 / enrage / hurt / defeat` (128x128) | `heavy idle` / `slow step` / `arm smash` / `ground pound shockwave` / `enrage roar, glowing cracks` / `stagger` / `crumbling defeat` |

---

## 3. エフェクト（キャラ非依存・64x64）

PixelLabで作れなければ通常の画像生成AIでも可。1行アニメ（横並びフレーム）想定。

| ID | action / 説明 | 目安 |
| --- | --- | --- |
| `fx_slash` | `white-blue slash arc effect` | 4–5 |
| `fx_hit_spark` | `small impact spark on hit` | 3 |
| `fx_guard_spark` | `blue guard block spark` | 3 |
| `fx_heal` | `green healing sparkles rising` | 4 |
| `fx_cast_circle` | `magic circle appearing under caster` | 4 |
| `fx_fire` | `fireball / fire burst` | 5 |
| `fx_water` | `water splash spell` | 5 |
| `fx_wind` | `wind slash spell` | 5 |
| `fx_earth` | `rock spikes spell` | 5 |
| `fx_light` | `holy light beam` | 5 |
| `fx_dark` | `dark energy burst` | 5 |

---

## 4. AssetManager 運用メモ（重要）
- **同一キャラは同じベースから全モーションを生成**（絵柄・色ブレ防止）。PixelLabのキャラ複製→アニメ追加を活用。
- セルサイズは §0 の値で固定。1シート化する場合は**等間隔グリッド**（列＝フレーム）にし、Godotで `hframes` を合わせる。
- 基準向きは右。左向きは Godot 側で `flip_h`（別途生成しない）。
- 現行の出力パスは `assets/characters/party/<id>/battle/animations/`。Rolandは `idle`、`Run`、`attack/Combo_01..03`、`Guard`、`Parry`、Wolfは `Idle`、`Run`、`Attack/Combo_01` を使用する。旧 `assets/characters/hero/*` は使用しない。
- 現行は1アニメ1シートではなく、個別PNGフレームをフォルダへ配置し、GDScriptが実行時にSpriteFramesを構築する。`hframes`/`vframes`は使用しない。
- 命名/セル数を変更したら**必ずProgrammerへ共有**（アニメ名・フレーム数がコードと一致している必要がある。`05_battle_system.md` §14 のアニメ名を正とする）。
- PixelLab は API もあるため、量産する場合はキャラID×アクションのバッチ生成を検討（本ドキュメントのaction文をそのまま流用可）。
