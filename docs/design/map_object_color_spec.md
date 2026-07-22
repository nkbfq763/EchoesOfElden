\# JRPG マップ構造：色分類 × 機能カテゴリ × Z-order × 衝突  

\*\*Devin + Godot 4.x 実装仕様書（機能ベース名称版 / 最終版）\*\*



\---



\## 1. カラー仕様（マスク画像）



\### 1.1 色と機能カテゴリの対応



| 色 | RGB | 機能名 | 機能概要 | 通行 | 衝突 |

|----|------|--------|-----------|--------|--------|

| 赤 | 255,0,0 | \*\*Overhang\*\* | 頭上構造（屋根・枝・庇） | 通れる | なし |

| 青 | 0,0,255 | \*\*SideStructure\*\* | 側面構造（柱・壁面・井戸枠） | 黒がなければ通れる | 黒があれば通れない |

| 黒 | 0,0,0 | \*\*Solid\*\* | 物理障害物 | 通れない | あり |

| 緑 | 0,255,0 | \*\*Walkable\*\* | 地面 | 通れる | なし |



\---



\## 2. オブジェクト抽出（zobject生成）



\### 2.1 入力画像

\- 元画像: `elden\_village\_objects.png`  

\- マスク画像: `elden\_village\_objects\_mask.png`



\### 2.2 抽出アルゴリズム

1\. 非透明ピクセルを flood-fill  

2\. 1px の途切れは dilation で補正  

3\. 塊ごとに bounding box を算出  

4\. 元画像を矩形で切り出し `object\_N.png`  

5\. マスク画像も同じ矩形で切り出し `object\_N\_mask.png`  

6\. 塊ピクセルのみ visited に登録  

7\. 小さすぎる塊は破棄



\---



\## 3. カテゴリ判定ロジック（機能ベース名称）



\### 3.1 マスク画像の走査

各ピクセルを走査し、以下を判定:



\- 赤 → `has\_overhang = true`

\- 青 → `has\_sidestructure = true`

\- 緑 → `has\_walkable = true`

\- 黒 → `has\_solid = true`



\### 3.2 category の決定ルール（優先順位）

1\. `has\_overhang == true` → \*\*Overhang\*\*  

2\. `has\_sidestructure == true` → \*\*SideStructure\*\*  

3\. `has\_walkable == true` → \*\*Walkable\*\*  

4\. 上記が全て false かつ `has\_solid == true` → \*\*SolidOnly\*\*



\---



\## 4. 衝突仕様（Godot 4.x）



\### 4.1 Solid の扱い

\- 黒（Solid）がある部分は必ず通れない  

\- Solid 部分から `CollisionPolygon2D` を生成  

\- Overhang / SideStructure / Walkable は黒がなければ衝突なし



\### 4.2 通行可否



| カテゴリ | 通行 | 衝突 |

|----------|--------|--------|

| Overhang | 通れる | なし |

| SideStructure | 黒がなければ通れる | 黒があれば通れない |

| Solid | 通れない | あり |

| Walkable | 通れる | なし |



\---



\## 5. Z-order（描画順）仕様



\### 5.1 基本ルール

Godot の描画順は \*\*足元の Y 座標\*\*で決まる。



\- Y が大きい（画面下）ほど前面  

\- Y が小さい（画面上）ほど背面  



\### 5.2 色は描画順に影響しない

Overhang / SideStructure / Solid / Walkable  

→ 描画順は \*\*Y座標のみ\*\*で決定。



\### 5.3 キャラとの前後関係

\- キャラの足元Y > オブジェクトの足元Y → キャラが前面  

\- キャラの足元Y < オブジェクトの足元Y → オブジェクトが前面  



\---



\## 6. 機能カテゴリの意味（ゲーム挙動）



\### Overhang（頭上構造 / 通行可能）

\- キャラは下を通れる  

\- キャラが後ろに行くと隠れる  

\- 影を落とす  

\- 雨・雪を遮る  

\- 例：井戸の屋根、家の屋根、東屋、木の枝



\### SideStructure（側面構造 / 通行可否は黒次第）

\- キャラが後ろに行くと隠れる  

\- 黒がなければ通れる（支柱など）  

\- 黒があれば通れない（井戸枠・建物の壁）  

\- 高さ情報を持てる（影の落ち方）



\### Solid（物理障害物 / 通れない）

\- 黒部分は必ず通れない  

\- CollisionPolygon2D を生成  

\- 例：石、壁、柵、井戸枠の石部分



\### Walkable（地面 / 通行可能）

\- 常に通れる  

\- 背面描画  

\- タイルマップと同じ扱い



\---



\## 7. zobject JSON 仕様（Devin生成用）



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



