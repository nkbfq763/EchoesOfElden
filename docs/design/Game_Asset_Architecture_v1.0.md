\# Game Asset Architecture v1.0

\## Tales of Eternia Style JRPG

\### Godot 4.x Asset \& Content Pipeline Specification



\---



\# Document Information



| Item | Value |

|--------|--------|

| Version | 1.0 |

| Engine | Godot 4.x |

| Project Type | JRPG (Tales of Eternia Style) |

| Asset Workflow | Data Driven |

| Target Consumer | Devin |

| Status | Official Specification |



\---



\# 1. Design Goals



This specification defines the standard asset architecture for the project.



The objectives are:



\- Fully data-driven content pipeline

\- Consistent asset organization

\- Automatic content loading

\- AnimationTree compatibility

\- Easy expansion without folder restructuring

\- Separation of game systems and content

\- Clear ownership between maps, characters, and prefabs



Devin should be able to load and construct all game content from metadata and folder conventions.



\---



\# 2. Project Root Structure



The project uses a root-level `assets` directory.



```text

project\_root/

│

├─ assets/

├─ scenes/

├─ scripts/

├─ addons/

├─ tests/

└─ project.godot

```



All asset paths in this document are relative to:



```text

assets/

```



\---



\# 3. Global Asset Structure



```text

assets/

│

├─ characters/

│

├─ maps/

│

├─ prefabs/

│

├─ common/

│

├─ battle/

│

├─ ui/

│

└─ localization/

```



\---



\# 4. Character Asset Architecture



\---



\## 4.1 Character Categories



```text

assets/characters/



├─ party/

├─ enemies/

└─ npc/

```



\### party



Playable characters.



\### enemies



Battle enemies.



Field assets are optional.



\### npc



Field-only characters.



\---



\## 4.2 Character Structure



```text

<category>/<character\_id>/



├─ field/

│

├─ battle/

│

├─ portrait/

│

└─ meta/

```



\---



\## Example



```text

party/roland\_hartwell/



├─ field/

├─ battle/

├─ portrait/

└─ meta/

```



\---



\# 5. Field Character Assets



```text

field/



└─ animations/

&#x20;  │

&#x20;  ├─ idle/

&#x20;  └─ Run/

```



\---



\## idle



Single frame.



```text

idle/<direction>.png

（現在は8方向: east / north-east / north / north-west /
west / south-west / south / south-east）

```



\---



\## Run



```text

Run/east/frame\_000.png

Run/east/frame\_001.png

```



\---



\## run



```text

Run/east/frame\_000.png

Run/east/frame\_001.png

```



\---



\## Direction Standard



```text

east

north-east

north

north-west

west

south-west

south

south-east

```



\---



\# 6. Battle Character Assets



```text

battle/



└─ animations/

&#x20;  │

&#x20;  ├─ idle/

&#x20;  ├─ Run/

&#x20;  ├─ attack/Combo\_01..03/

&#x20;  ├─ Guard/

&#x20;  ├─ Parry/

&#x20;  └─ rotations/

```



\---



\## Combo Structure



```text

attack/



├─ Combo\_01/

├─ Combo\_02/

└─ Combo\_03/

```



Example:



```text

attack/Combo\_01/frame\_000.png

attack/Combo\_02/frame\_000.png

attack/Combo\_03/frame\_000.png

```



現行実装はAnimationTreeではなく、個別PNGフレームをGDScriptで実行時に`SpriteFrames`へ登録する。
入力素材はRoland/Wolfとも約124x124で、表示時におおむね`scale=0.4`を適用する。
`hit`/`death`等の専用素材は未実装で、現在はidle等へフォールバックする。



\---



\# 7. Portrait Assets



```text

portrait/



（Roland/Fiona等の顔画像。メニューの表示画像とCrop領域は`data/portrait_config.json`で指定）

```



File名は素材ごとの表情名を使用する。メニューは現在`common_face.png`のCrop領域を使用する。



\---



\# 8. Character Metadata



現行実装ではCharacter用meta JSONは未使用。表示スケール/offsetはGDScript、敵のアニメーションパスと背景は`EnemyData`、ポートレートは`data/portrait_config.json`で管理する。
以下は将来のデータ駆動化案である。

File:



```text

<character\_id>\_meta.json

```



Example:



```json

{

&#x20; "id": "roland\_hartwell",



&#x20; "display\_size": {

&#x20;   "w": 64,

&#x20;   "h": 96

&#x20; },



&#x20; "pivot": {

&#x20;   "x": 32,

&#x20;   "y": 88

&#x20; },



&#x20; "z\_index": 5,



&#x20; "field\_animations": \[

&#x20;   "idle",

&#x20;   "walk",

&#x20;   "run"

&#x20; ],



&#x20; "battle\_animations": \[

&#x20;   "idle",

&#x20;   "run",

&#x20;   "attack/combo\_01",

&#x20;   "attack/combo\_02",

&#x20;   "attack/combo\_03",

&#x20;   "guard",

&#x20;   "parry",

&#x20;   "hit",

&#x20;   "death"

&#x20; ],



&#x20; "portrait\_expressions": \[

&#x20;   "neutral",

&#x20;   "smile",

&#x20;   "angry",

&#x20;   "laugh"

&#x20; ]

}

```



\---



\# 9. Map Architecture



\---



\## 9.1 Top Level Structure



```text

assets/maps/



├─ world/

├─ settlements/

├─ dungeons/

└─ battle\_maps/

```



\---



\## 9.2 World Maps



Represents:



\- grasslands

\- forests

\- roads

\- snowfields

\- overworld areas



```text

world/



└─ w001\_elden\_region/

```



\---



\## 9.3 Settlements



Represents:



\- villages

\- towns

\- cities

\- castles

\- ports



```text

settlements/



├─ s001\_elden\_village/

├─ s002\_royal\_castle/

└─ s003\_port\_town/

```



\---



\## 9.4 Dungeons



Represents:



\- ruins

\- caves

\- towers

\- temples



```text

dungeons/



└─ d001\_ruins/

```



\---



\# 10. World / Settlement Structure



```text

<map>/



├─ background/

│

├─ objects/

│

├─ masks/

│

└─ meta/

```



Example:



```text

s001\_elden\_village/



├─ background/

│   ├─ bg\_screen\_a.png

│   ├─ bg\_screen\_b.png

│   ├─ bg\_screen\_c.png

│   └─ bg\_screen\_d.png

│

├─ objects/

│   └─ <object>.png

│

├─ masks/

│   └─ <object>\_mask.png

│

└─ meta/

&#x20;   ├─ bg\_screen\_a.json

&#x20;   ├─ bg\_screen\_b.json

&#x20;   ├─ bg\_screen\_c.json

&#x20;   └─ bg\_screen\_d.json

```

画面JSONのオブジェクト要素は `id`、`object_ref`、`mask_ref`、`position`、`scale`、`collision`、`category` を持つ。固定`z_index`やカテゴリフラグは現行実装では持たず、z-indexは足元Yから実行時に算出する。



\---



\# 11. Dungeon Structure



```text

d001\_ruins/



├─ r001\_entrance/

├─ r002\_hall/

├─ r003\_boss\_room/

└─ common/

```



Example Room:



```text

r001\_entrance/



├─ r001\_map.png

├─ r001\_walkable.png

├─ r001\_meta.json

└─ r001\_objects.json

```



\---



\# 12. Battle Map Structure



```text

assets/maps/battle\_maps/



└─ battle\_bg\_<biome>.png

（現在は単層PNG。多層bg、positions.json、walkable、metaは将来案）


```



\---



\# 13. Walkable Mask Specification



旧アーキテクチャでは全マップ必須としていたが、現行EldenVillageではオブジェクト単位マスクを使用する。



```text

\*\_walkable.png

```



Color meaning:

\*```text

不透明な近黒ピクセル（alpha >= 0.5 かつ RGB <= 0.2） = Solid

その他の色 = 現在はカテゴリ判定しない

```



Used by:



\- EldenVillageの`CollisionPolygon2D`生成



\---



\# 14. Encounter System\*

現行のエンカウントはフォルダ構造やマップメタデータではなく、`field.tscn`内のArea2D敵シンボル接触で決定する。
敵データは`GameData.pending_encounter`を経由してbattleへ渡す。
メタデータ制御のランダムエンカウントは将来案。



\---



\## Encounter Enabled（将来のメタデータ案）



```json

{

&#x20; "encounter\_enabl\*d": true

}

```



\---



\## No Encounter（将来のメタデータ案）



```json

{

&#x20; "encounter\_enabled"\* false

}

```



\---



\## World Example（将来のメタデータ案）



```json

{

&#x20; "id": "w001",



&#x20; "ty\*e": "world",



&#x20; "\*ncounter\_enabled": true,



&#x20; "\*ncounter\_table": "enc\_grassland"

}\*```



\---



\## Settlement Example



`\*`json

{

&#x20; "id": "s001",



&#x20; "\*ype": "settlement",



&#x20; "encounter\_\*nabled": false

}

```



\---



\# 15. O\*ject Placement



All map objects ar\* JSON driven.



\---



\## File\*

```text

\*\_objects.json

```



Examp\*e:



```json

{

&#x20; "\*ap\_id": "d001\_r002",



&#x20; "units": \[\*    {

&#x20;     "id": "chest\_001",

&#x20;  \*  "type": "chest",



&#x20;     "\*refab\*: "assets/prefabs/chest\_common.tsc\*",



&#x20;     "position": {

&#x20;       "x\*: 512,

&#x20;       "y": 128

&#x20;     },



\*     "z\_index": 10,



\*     "loot\_table": "chest\_ruins\_co\*mon"

&#x20;   }

&#x20; ]

}

```



\---



\# 16. M\*p Transition System



Location:



``\*text

entrances/

```



File:



```tex\*

<source>\_enter\_<target>.json

```

\*Example:



```text

w001\_enter\_s001.\*son

```



Structure:



```json

{

&#x20; "\*rom": "w001",



&#x20; "to": "s001",



&#x20; \*from\_point": "village\_gate",



&#x20; "t\*\_point": "south\_gate",



&#x20; "require\*\_flag": null,



&#x20; "facing": "north"\*



&#x20; "transition\_type": "fade",



&#x20; \*spawn\_position": {

&#x20;   "x": 64,

&#x20; \* "y": 32

&#x20; }

}

```



\---



\# 17. Pre\*ab Architecture



Location:



```tex\*

assets/prefabs/

```



Examples:



`\*`text

chest\_common.tscn



pot\_break\*ble.tscn



save\_point.tscn



npc\_ven\*or.tscn



npc\_guard.tscn



healing\_c\*ystal.tscn

```



All interactable g\*me objects should be implemented a\* prefabs.



\---



\# 18. Common Asset\*



```text

assets/common/



├─ tiles\*ts/

├─ bgm/

├─ sfx/

├─ shaders/

├─\*fonts/

└─ icons/

```



\---



\# 19. N\*ming Convention



\---



\## Character\*

```text

roland\_hartwell

```



\---

\*## Map



```text

w001\_elden\_region

\*001\_elden\_village

d001\_ruins

b001\_\*orest

```



\---



\## Room



```text

r\*01\_entrance

r002\_hall

r003\_boss\_ro\*m

```



\---



\## Animation



```text

\*ombo\_01

combo\_02

```



\---



\## Fram\*



```text

frame\_000.png

frame\_001.\*ng

frame\_002.png

```



\---



\## Port\*ait



```text

neutral.png

smile.png\*angry.png

```



\---



\# 20. Devin Lo\*ding Pipeline



Character Loading:

\*```text

1\. Read meta.json

2\. Disco\*er animations

3\. Build AnimationFr\*mes

4\. Build AnimationTree

5\. Regi\*ter portrait expressions

```



\---

\*Map Loading:



```text

1\. Load meta\*json

2\. Load walkable mask

3\. Load\*graphics

4\. Load entrances

5\. Load\*objects.json

6\. Instantiate prefab\*

7\. Build encounter settings

8\. Sp\*wn entities

```



\---



\# 21. Future\*Expansion



Reserved for:



```text

\*attle/animations/cast/



battle/ani\*ations/skill/



battle/animations/d\*dge/



battle/animations/hit\_front/\*

battle/animations/hit\_back/



fiel\*/animations/dash/



field/animation\*/swim/

```



and



```text

assets/ma\*s/world\_events/



assets/maps/cutsc\*nes/



assets/maps/raid/

```



witho\*t restructuring existing folders.

\*---



\# 22. Final Rules



The follow\*ng principles are mandatory:



\- Folder structure defines content category（現行/将来共通）

\- Metadata defines game behavior（EldenVillageの現行JSONを含む）

\- Encounters are currently controlled by Area2D enemy symbols; metadata-only encounters are future

\- Animation states are currently built as runtime `SpriteFrames`; AnimationTree is future

\- EldenVillage placements are JSON driven

\- Reusable objects are prefabs where applicable

\- Whole-map walkable masks are legacy/future; current collision uses object masks

\- New content should avoid hardcoded assets

\- New content should not require changing the architecture



This document is the official asset architecture specification for the project.
