# Tales-like JRPG 設計ドキュメント

テイルズ オブ エターニア風 2D アクションRPG (Godot Engine 4.7 feature target / 2D) の設計資料。
プロジェクトのfeature設定は4.7だが、現行の検証環境はGodot 4.3。
設計エージェント (GameDesigner) が作成し、各エージェントへ共有する起点となるドキュメント群。

## ドキュメント一覧
| ファイル | 内容 | 主対象 |
| --- | --- | --- |
| [`00_game_design.md`](00_game_design.md) | ゲーム基本仕様（ジャンル/世界観/戦闘/マップ） | 全員 |
| [`01_asset_list.md`](01_asset_list.md) | 必要素材リスト | AssetManager |
| [`02_asset_prompts.md`](02_asset_prompts.md) | 外部AI向け素材生成プロンプト | AssetManager |
| [`03_programmer_spec.md`](03_programmer_spec.md) | 最初の実装仕様書（Phase 1） | Programmer |
| [`04_tales_reference.md`](04_tales_reference.md) | テイルズ オブ エターニア設計分析（参考） | 全員 |
| [`05_battle_system.md`](05_battle_system.md) | 戦闘システム(LMBS)詳細仕様（再設計） | Programmer |
| [`06_battle_assets_pixellab.md`](06_battle_assets_pixellab.md) | 戦闘アセットのPixelLab.ai向けプロンプト | AssetManager |
| [`07_battle_backgrounds.md`](07_battle_backgrounds.md) | 戦闘背景パターンの生成プロンプト | AssetManager |

## エージェント体制と進行ルール
```
GameDesigner ──仕様──▶ Programmer ──実装──▶ AssetManager ──素材──▶ Tester ──報告──▶ (GameDesignerへ改善還元)
```
- 進行順: 設計 → コーディング → アセット管理 → テスト。
- 各エージェントは次のエージェントに「タスク依頼」を送る。
- 不明点は必ず前のエージェントに質問してから進める。
- Usage削減のため、コードは必要最小限にまとめる。
- 素材は外部AIで生成し、DevinDesktop内では素材生成を行わない。

## 主要キャラ
Roland Hartwell（主人公18/剣士）/ Fiona Merrick（幼馴染18/僧侶）/ Selene Aurelis（異世界の少女18/魔術士）/ Gareth Vaughn（年上青年22/重戦士）。

## ストーリー要約
開始地点の町で育った幼馴染3人（Roland18男/Fiona18女/Gareth22男）が主軸。年上青年は18歳の頃に世界の異変に気付き単身旅立った。物語は空から降ってきた異世界の少女18を主人公が抱きとめて始まる。幼馴染女は年上青年に憧れつつ主人公への好意は未自覚、異世界の少女は主人公に恋する——という恋愛群像を背景に、少女の目的を果たす旅に出る。詳細は `00_game_design.md` §3。

## 現在地
- **旧Phase 0**: 町探索 + プレイヤー移動。warrior/priestのキャラ選択は廃止済み。
- **現行実装**: `title.tscn → opening.tscn → EldenVillage.tscn`、Roland固定、EldenVillage 4画面、8方向FieldPlayer、敵シンボル、LMBSバトル拡張（3段コンボ/TECH/CAST/敵AI/Wolfアニメ/背景/報酬）、MenuScreen/CanvasLayerを実装済み。
- **表示/環境**: viewportは640×360、初期ウィンドウは1280×720。project feature targetはGodot 4.7、検証環境はGodot 4.3。
- **未接続**: EldenVillageからlegacy `field.tscn`/`main.tscn`への出口。Fiona/Selene/Garethのparty加入。
- **将来**: 味方AI、作戦、アイテム/装備/セーブ、ダンジョン、ボス、追加演出。

## 各エージェントへの最初のタスク依頼
- **Programmer**: `03_programmer_spec.md` と現行コードの差分を同期し、未接続の将来機能を実装。
- **AssetManager**: `01_asset_list.md` の現行不足素材（追加キャラクター、追加敵、追加背景、エフェクト）を
  `02_asset_prompts.md` のプロンプトで外部AI生成し、想定パスへ配置。
- **Tester**: title→opening→EldenVillage、field→battle→field、メニュー、各Resource/アセットパスを確認し、未実装の将来項目と区別して報告。
