\# Devin 実装指示書：メニューボタン押下でメニュー画面を表示する機能（Part 1）



\## 目的

ゲーム中に「メニューボタン」を押した際、

メニューUI（MenuScreen.tscn）をロードし、

Portrait（立ち絵）を含むメニュー画面を表示する機能を実装する。



\## 1. 対象ファイル構成



scenes/

├─ ui/

│   ├─ MenuScreen.tscn

│   └─ MenuButton.tscn

scripts/

├─ ui/

│   ├─ menu\_button.gd

│   └─ menu\_screen.gd

assets/

└─ characters/

&#x20;   └─ party/

&#x20;       └─ roland\_hartwell/

&#x20;           └─ portrait/

&#x20;               └─ common\_face.png

\## 2. MenuButton の仕様



MenuButton.tscn

\- Button ノード

\- script: menu\_button.gd



要求仕様

\- ボタン押下で MenuScreen をロード

\- UI レイヤーに追加

\- 既に開いている場合は再生成しない



extends Button



const MENU\_SCREEN\_PATH := "res://scenes/ui/MenuScreen.tscn"

var menu\_instance: Control = null



func \_ready() -> void:

&#x20;   pressed.connect(\_on\_pressed)



func \_on\_pressed() -> void:

&#x20;   if menu\_instance != null and is\_instance\_valid(menu\_instance):

&#x20;       return



&#x20;   var scene: PackedScene = load(MENU\_SCREEN\_PATH)

&#x20;   menu\_instance = scene.instantiate()



&#x20;   get\_tree().get\_root().add\_child(menu\_instance)



\## 3. MenuScreen.tscn ノード構成



MenuScreen (Control)

├─ Background (TextureRect)

├─ TabMenu (HBoxContainer)

├─ CharacterCards (HBoxContainer)

│   ├─ Card\_1 (VBoxContainer)

│   │   ├─ Portrait (TextureRect)

│   │   ├─ NameLabel (Label)

│   │   ├─ LvLabel (Label)

│   │   ├─ HPLabel (Label)

│   │   ├─ TPLabel (Label)

│   │   └─ ExpLabel (Label)

│   ├─ Card\_2 (...)

│   ├─ Card\_3 (...)

│   └─ Card\_4 (...)

└─ InfoBar (HBoxContainer)

&#x20;   ├─ GaldLabel (Label)

&#x20;   ├─ PlayTimeLabel (Label)

&#x20;   └─ HintLabel (Label)



\## 4. Portrait 読み込み仕様



画像パス:

assets/characters/party/roland\_hartwell/portrait/common\_face.png



使用領域（Crop）

\- x = 300〜700

\- y = 0〜1024

\- 幅 = 400

\- 高さ = 1024



表示方法

\- region\_enabled = true

\- region\_rect = Rect2(300, 0, 400, 1024)

\- stretch\_mode = KEEP\_ASPECT\_CENTERED

\- custom\_minimum\_size = Vector2(400, 800)



extends Control



var portrait\_config := {

&#x20;   "roland\_hartwell": {

&#x20;       "path": "res://assets/characters/party/roland\_hartwell/portrait/common\_face.png",

&#x20;       "crop\_x": 300,

&#x20;       "crop\_y": 0,

&#x20;       "crop\_w": 400,

&#x20;       "crop\_h": 1024,

&#x20;       "display\_w": 400,

&#x20;       "display\_h": 800,

&#x20;       "offset\_x": 0,

&#x20;       "offset\_y": 0

&#x20;   }

}



func \_ready() -> void:

&#x20;   load\_portrait("roland\_hartwell")



func load\_portrait(character\_name: String) -> void:

&#x20;   var cfg = portrait\_config\[character\_name]

&#x20;   var portrait\_node: TextureRect = $CharacterCards/Card\_1/Portrait



&#x20;   portrait\_node.texture = load(cfg.path)



&#x20;   portrait\_node.region\_enabled = true

&#x20;   portrait\_node.region\_rect = Rect2(

&#x20;       cfg.crop\_x,

&#x20;       cfg.crop\_y,

&#x20;       cfg.crop\_w,

&#x20;       cfg.crop\_h

&#x20;   )



&#x20;   portrait\_node.stretch\_mode = TextureRect.STRETCH\_KEEP\_ASPECT\_CENTERED

&#x20;   portrait\_node.custom\_minimum\_size = Vector2(

&#x20;       cfg.display\_w,

&#x20;       cfg.display\_h

&#x20;   )



&#x20;   portrait\_node.position = Vector2(

&#x20;       cfg.offset\_x,

&#x20;       cfg.offset\_y

&#x20;   )



\## 5. Devin が実装すべきタスク一覧



Task 1

MenuButton.tscn と menu\_button.gd を作成し、

メニューボタン押下で MenuScreen をロードする処理を実装する。



Task 2

MenuScreen.tscn の UI ノード構成を作成する。



Task 3

menu\_screen.gd を作成し、Portrait 読み込み処理を実装する。



Task 4

Portrait の Crop（領域指定）＋リサイズ＋位置調整処理を実装する。



Task 5

portrait\_config を外部 JSON に切り出し、

複数キャラに対応できるようにする。







