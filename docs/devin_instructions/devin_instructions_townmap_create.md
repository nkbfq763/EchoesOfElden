\# Devin 実装指示書：エルデン村マップ表示機能



\## 目的

ゲーム起動後、またはフィールド遷移時に、

エルデン村のマップ（bg\_screen\_a〜d）を正しく読み込み、

背景・オブジェクト・マスク・メタデータを統合して

1つのフィールドとして表示する機能を実装する。





\## 1. フォルダ構成



assets/maps/settlements/s001\_elden\_village/

├─ background/

│   ├─ bg\_screen\_a.png

│   ├─ bg\_screen\_b.png

│   ├─ bg\_screen\_c.png

│   └─ bg\_screen\_d.png

├─ masks/

│   ├─ house\_a\_mask.png

│   ├─ house\_b\_mask.png

│   └─ well\_mask.png

├─ objects/

│   ├─ house\_a.png

│   ├─ house\_b.png

│   └─ well.png

└─ meta/

&#x20;   ├─ bg\_screen\_a.json

&#x20;   ├─ bg\_screen\_b.json

&#x20;   ├─ bg\_screen\_c.json

&#x20;   └─ bg\_screen\_d.json



\## 2. メタデータ仕様（例：bg\_screen\_a.json）



{

&#x20; "screen\_id": "bg\_screen\_a",

&#x20; "background": "res://assets/maps/settlements/s001\_elden\_village/background/bg\_screen\_a.png",

&#x20; "objects": \[

&#x20;   {

&#x20;     "id": "house\_a",

&#x20;     "object\_ref": "res://assets/maps/settlements/s001\_elden\_village/objects/house\_a.png",

&#x20;     "mask\_ref": "res://assets/maps/settlements/s001\_elden\_village/masks/house\_a\_mask.png",

&#x20;     "position": { "x": 180, "y": 220 },

&#x20;     "z\_index": 220,

&#x20;     "collision": true,

&#x20;     "category": "Solid"

&#x20;   },

&#x20;   {

&#x20;     "id": "well",

&#x20;     "object\_ref": "res://assets/maps/settlements/s001\_elden\_village/objects/well.png",

&#x20;     "mask\_ref": "res://assets/maps/settlements/s001\_elden\_village/masks/well\_mask.png",

&#x20;     "position": { "x": 320, "y": 280 },

&#x20;     "z\_index": 280,

&#x20;     "collision": true,

&#x20;     "category": "SideStructure"

&#x20;   }

&#x20; ]

}



\## 3. Godot シーン構成



EldenVillage.tscn (Node2D)

├─ BackgroundLayer (Node2D)

│   └─ Background (Sprite2D)

├─ ObjectLayer (Node2D)

│   ├─ House\_A (Sprite2D)

│   ├─ Well (Sprite2D)

│   └─ ...

└─ CollisionLayer (Node2D)

&#x20;   ├─ House\_A\_Collision (CollisionPolygon2D)

&#x20;   ├─ Well\_Collision (CollisionPolygon2D)

&#x20;   └─ ...





extends Node2D



const META\_PATH := "res://assets/maps/settlements/s001\_elden\_village/meta/"



func \_ready() -> void:

&#x20;   load\_screen("bg\_screen\_a")



func load\_screen(screen\_id: String) -> void:

&#x20;   var meta\_file := META\_PATH + "%s.json" % screen\_id

&#x20;   var meta := load(meta\_file).get\_data()



&#x20;   load\_background(meta.background)

&#x20;   load\_objects(meta.objects)



func load\_background(path: String) -> void:

&#x20;   var bg := $BackgroundLayer/Background

&#x20;   bg.texture = load(path)



func load\_objects(objects: Array) -> void:

&#x20;   for obj in objects:

&#x20;       var sprite := Sprite2D.new()

&#x20;       sprite.texture = load(obj.object\_ref)

&#x20;       sprite.position = Vector2(obj.position.x, obj.position.y)

&#x20;       sprite.z\_index = obj.z\_index

&#x20;       $ObjectLayer.add\_child(sprite)



&#x20;       if obj.collision:

&#x20;           var col := CollisionPolygon2D.new()

&#x20;           # Devin が mask から polygon を生成する

&#x20;           col.polygon = generate\_polygon\_from\_mask(obj.mask\_ref)

&#x20;           col.position = sprite.position

&#x20;           $CollisionLayer.add\_child(col)



\## 4. Devin のタスク一覧



\### Task 1

EldenVillage.tscn を作成し、BackgroundLayer / ObjectLayer / CollisionLayer を配置する。



\### Task 2

meta/bg\_screen\_a.json〜bg\_screen\_d.json を作成する。



\### Task 3

eldenvillage.gd を作成し、背景・オブジェクト・衝突を読み込む処理を実装する。



\### Task 4

mask 画像から CollisionPolygon2D を生成する関数

generate\_polygon\_from\_mask(mask\_path) を実装する。



\### Task 5

bg\_screen\_a〜d の遷移処理（スクロール or 画面切替）を追加する。













