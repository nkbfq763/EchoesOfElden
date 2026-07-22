\# Devin 実行指示書（Map Object Pipeline / Godot 4.x）

\*\*対象:\*\* Godot 4.x / JRPG マップオブジェクト抽出・カテゴリ判定・衝突生成・Z-order  

\*\*目的:\*\* 航大が定義した「機能ベース名称（Overhang / SideStructure / Solid / Walkable）」に基づき、  

マップオブジェクトを自動抽出し、Godot で利用可能な Scene / JSON / Collision を生成する。



\---



\# 0. 入力ファイル



assets\maps\settlements\

├─ s001_elden_village\objects

&#x20; → 非透明ピクセルがオブジェクトの塊  

└─ s001_elden_village\masks

&#x20; → 色分類（赤/青/黒/緑）で機能カテゴリを示す



\---



\# 1. 色分類（機能カテゴリ）



| 色 | RGB | 機能名 | 機能概要 | 通行 | 衝突 |

|----|------|--------|-----------|--------|--------|

| 赤 | 255,0,0 | \*\*Overhang\*\* | 頭上構造（屋根・枝・庇） | 通れる | なし |

| 青 | 0,0,255 | \*\*SideStructure\*\* | 側面構造（柱・壁面・井戸枠） | 黒がなければ通れる | 黒があれば通れない |

| 黒 | 0,0,0 | \*\*Solid\*\* | 物理障害物 | 通れない | あり |

| 緑 | 0,255,0 | \*\*Walkable\*\* | 地面 | 通れる | なし |



\---



\# 2. オブジェクト抽出処理（zobject extraction）



\## 2.1 処理内容

1\. `elden\_village\_objects.png` の非透明ピクセルを flood-fill  

2\. 1px の途切れは dilation で補正  

3\. 塊ごとに bounding box（Rect2i）を算出  

4\. 元画像を矩形で切り出し `object\_{id}.png` を生成  

5\. マスク画像も同じ矩形で切り出し `object\_{id}\_mask.png` を生成  

6\. 塊ピクセルのみ visited に登録  

7\. 小さすぎる塊は破棄（閾値は 8px × 8px）



\## 2.2 出力先



objects/

├─ object\_001.png

├─ object\_001\_mask.png

├─ object\_001.json

├─ object\_002.png

├─ object\_002\_mask.png

├─ object\_002.json

...





\---



\# 3. カテゴリ判定ロジック（mask → metadata）



\## 3.1 マスク画像走査

各ピクセルを走査し、以下のフラグを立てる：



\- 赤 → `has\_overhang = true`

\- 青 → `has\_sidestructure = true`

\- 緑 → `has\_walkable = true`

\- 黒 → `has\_solid = true`



\## 3.2 category の決定（優先順位）



if has\_overhang: category = "Overhang"

elif has\_sidestructure: category = "SideStructure"

elif has\_walkable: category = "Walkable"

elif has\_solid: category = "SolidOnly"





\## 3.3 JSON 出力形式



```json

{

&#x20; "id": 12,

&#x20; "rect": { "x": 100, "y": 200, "w": 64, "h": 48 },

&#x20; "category": "SideStructure",

&#x20; "has\_overhang": false,

&#x20; "has\_sidestructure": true,

&#x20; "has\_walkable": false,

&#x20; "has\_solid": true

}



\# 4. 衝突生成（CollisionPolygon2D）

\## 4.1 Solid の扱い

黒（Solid）がある部分は必ず通れない



黒ピクセル領域を polygon 化し、CollisionPolygon2D を生成



Overhang / SideStructure / Walkable は黒がなければ衝突なし



\## 4.2 出力

Godot Scene (.tscn) を生成：



objects\_scenes/

&#x20;├─ object\_001.tscn

&#x20;├─ object\_002.tscn

&#x20;...



Scene 内容：



Sprite（object\_001.png）



CollisionPolygon2D（黒領域がある場合のみ）



5\. Z-order（描画順）

5.1 基本ルール

Godot の描画順は 足元の Y 座標で決定する。



Y が大きい（画面下） → 前面



Y が小さい（画面上） → 背面



5.2 色は描画順に影響しない

Overhang / SideStructure / Solid / Walkable

→ 描画順は Y座標のみで決まる。



5.3 キャラとの前後関係

キャラの足元Y > オブジェクトの足元Y → キャラが前面



キャラの足元Y < オブジェクトの足元Y → オブジェクトが前面



6\. Devin が実行すべきタスク一覧（順番）

Task 1: オブジェクト抽出スクリプトの実装

flood-fill



dilation



bounding box



切り出し



visited 管理



出力ファイル生成



Task 2: マスク画像からカテゴリ判定ロジックを実装

色走査



フラグ判定



category 決定



JSON 出力



Task 3: Solid から CollisionPolygon2D を生成

黒領域抽出



polygon 化



Godot Scene 生成



Task 4: Z-order 描画ロジックの実装

足元Yの取得



Node の z\_index 設定



キャラとの前後関係処理



Task 5: Godot Scene 自動生成パイプラインの構築

Sprite + CollisionPolygon2D の Scene 化



Scene を objects\_scenes/ に保存



JSON と Scene を紐付ける



7\. 出力ディレクトリ構成（最終形）

コード

project\_root/

&#x20;├─ maps/

&#x20;│   ├─ elden\_village\_objects.png

&#x20;│   └─ elden\_village\_objects\_mask.png

&#x20;├─ objects/

&#x20;│   ├─ object\_001.png

&#x20;│   ├─ object\_001\_mask.png

&#x20;│   └─ object\_001.json

&#x20;├─ objects\_scenes/

&#x20;│   ├─ object\_001.tscn

&#x20;│   └─ object\_002.tscn

&#x20;├─ scripts/

&#x20;│   ├─ zobject\_extractor.gd

&#x20;│   ├─ zobject\_classifier.gd

&#x20;│   ├─ zobject\_collision\_builder.gd

&#x20;│   └─ zobject\_scene\_builder.gd

&#x20;└─ docs/

&#x20;    └─ map\_object\_color\_spec.md

8\. Devin への最終指示

この指示書に従い、

抽出 → 分類 → 衝突生成 → Scene 化 → Z-order 実装  

までの全工程を自動化するコードを生成すること。



コード

必須条件:

\- Godot 4.x の API を使用すること

\- JSON / PNG / Scene の入出力を正確に行うこと

\- 色分類は Overhang / SideStructure / Solid / Walkable の機能名を使用すること

\- 衝突は Solid のみ生成すること

\- 描画順は Y座標で決定すること







