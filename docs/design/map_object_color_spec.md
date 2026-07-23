\# JRPG マップ構造：色分類 × 機能カテゴリ × Z-order × 衝突  

\*\*Godot 4.x 実装仕様書（機能ベース名称版 / 最終版）\*\*



\---



\## 1. カラー仕様（マスク画像）

以下の赤/青/黒/緑の対応は将来のカテゴリ分類仕様である。現行実装はオブジェクト単位マスクの近黒Solid判定のみを使用する。



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

\- 背景/オブジェクト/マスクは `assets/maps/settlements/s001_elden_village/{background,objects,masks,meta}/` に分割配置する。
\- 各画面のJSONが `object_ref` と `mask_ref` を指定する。



\### 2.2 抽出アルゴリズム

1\. 各オブジェクトの `mask_ref` を読み込む

2\. 1px の途切れは dilation で補正  

3\. 塊ごとに bounding box を算出  

4\. オブジェクト画像を `object_ref` からロード

5\. マスク画像を `mask_ref` からロード

6\. 塊ピクセルのみ visited に登録  

7\. 小さすぎる塊は破棄



\---



\## 3. カテゴリ判定ロジック（機能ベース名称）



\### 3.1 マスク画像の走査

将来のカテゴリ分類では各ピクセルを走査し、以下を判定する。現在の実装では赤/青/緑は判定しない。



\- 赤 → `has\_overhang = true`（将来）

\- 青 → `has\_sidestructure = true`（将来）

\- 緑 → `has\_walkable = true`（将来）

\- 黒 → `has\_solid = true`（現在実装）



\### 3.2 category の決定ルール（優先順位）

1\. `has\_overhang == true` → \*\*Overhang\*\*  

2\. `has\_sidestructure == true` → \*\*SideStructure\*\*  

3\. `has\_walkable == true` → \*\*Walkable\*\*  

4\. 上記が全て false かつ `has\_solid == true` → \*\*SolidOnly\*\*



\---



\## 4. 衝突仕様（Godot 4.x）



\### 4.1 Solid の扱い

\- 現在は、不透明な近黒ピクセル（alpha >= 0.5、red/green/blue <= 0.2）のみSolidとして扱う。

\- Solid 部分から `CollisionPolygon2D` を生成  

\- 赤/青/緑のカテゴリによる追加判定は未実装。



\### 4.2 通行可否



| カテゴリ | 通行 | 衝突 |

|----------|--------|--------|

| 近黒Solid | 通れない | あり |

| その他の色/透明 | 通れる | なし |

Overhang / SideStructure / Walkableの意味付けは将来拡張。



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



\### Overhang（頭上構造 / 将来カテゴリ）

\- キャラは下を通れる  

\- キャラが後ろに行くと隠れる  

\- 影を落とす  

\- 雨・雪を遮る  

\- 例：井戸の屋根、家の屋根、東屋、木の枝



\### SideStructure（側面構造 / 将来カテゴリ）

\- キャラが後ろに行くと隠れる  

\- 黒がなければ通れる（支柱など）  

\- 黒があれば通れない（井戸枠・建物の壁）  

\- 高さ情報を持てる（影の落ち方）



\### Solid（物理障害物 / 現行実装）

\- 黒部分は必ず通れない  

\- CollisionPolygon2D を生成  

\- 例：石、壁、柵、井戸枠の石部分



\### Walkable（地面 / 将来カテゴリ）

\- 常に通れる  

\- 背面描画  

\- タイルマップと同じ扱い



\---



\## 7. zobject JSON 仕様（Devin生成用）



```json

{

&#x20; "id": "house_a",

&#x20; "object_ref": "res://assets/maps/settlements/s001_elden_village/objects/house_a.png",

&#x20; "mask_ref": "res://assets/maps/settlements/s001_elden_village/masks/house_a_mask.png",

&#x20; "position": { "x": 370, "y": 175 },

&#x20; "scale": 0.5,

&#x20; "collision": true,

&#x20; "category": "SolidOnly"

}
```

固定`z_index`や`has_overhang`等のカテゴリフラグは現行JSONには存在しない。z-indexはスプライトの足元Yから実行時に算出する。
