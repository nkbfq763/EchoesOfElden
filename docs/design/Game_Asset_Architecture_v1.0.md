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

&#x20;  ├─ walk/

&#x20;  └─ run/

```



\---



\## idle



Single frame.



```text

idle/east.png

idle/north.png

idle/west.png

idle/south.png

```



\---



\## walk



```text

walk/east/frame\_000.png

walk/east/frame\_001.png

```



\---



\## run



```text

run/east/frame\_000.png

run/east/frame\_001.png

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

&#x20;  ├─ run/

&#x20;  ├─ attack/

&#x20;  ├─ guard/

&#x20;  ├─ parry/

&#x20;  ├─ hit/

&#x20;  └─ death/

```



\---



\## Combo Structure



```text

attack/



├─ combo\_01/

├─ combo\_02/

└─ combo\_03/

```



Example:



```text

attack/combo\_01/frame\_000.png

attack/combo\_02/frame\_000.png

attack/combo\_03/frame\_000.png

```



AnimationTree state names must exactly match folder paths.



\---



\# 7. Portrait Assets



```text

portrait/



├─ angry.png

├─ smile.png

├─ laugh.png

└─ neutral.png

```



File name equals expression name.



\---



\# 8. Character Metadata



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



├─ graphics/

│

├─ objects/

│

├─ entrances/

│

└─ meta/

```



Example:



```text

w001\_elden\_region/



├─ graphics/

│   └─ map.png

│

├─ objects/

│   └─ w001\_objects.json

│

├─ entrances/

│   ├─ w001\_enter\_s001.json

│   └─ w001\_enter\_d001.json

│

└─ meta/

&#x20;   ├─ w001\_meta.json

&#x20;   └─ w001\_walkable.png

```



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

b001\_forest/



├─ bg/

│   ├─ back.png

│   ├─ middle.png

│   └─ front.png

│

├─ positions.json

│

├─ b001\_walkable.png

│

└─ b001\_meta.json

```



\---



\# 13. Walkable Mask Specification



Required for all maps.



```text

\*\_walkable.png

```



Color meaning:

\*```text

White = Walkable



Black =\*Blocked

```



Used by:



\- player\*navigation\*- NPC movement

\- enemy movement

\- \*ollision generation

\- battle posit\*oning



\---



\# 14. Encounter System\*

Folder\*structure\*must never determine encounters.



\*ncounters are controlled only thro\*gh metadata.



\---



\## Encounter En\*bled



```json

{

&#x20; "encounter\_enabl\*d": true

}

```



\---



\## No Encount\*r



```json

{

&#x20; "encounter\_enabled"\* false

}

```



\---



\## World Exampl\*



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



\- Fo\*der structure defines content cate\*ory

\- Metadata defines game behavi\*r

\- Encounters are controlled by m\*tadata only

\- AnimationTree states\*must match folder paths

\- All plac\*ments are JSON driven

\- All reusab\*e objects are prefabs

\- All maps r\*quire walkable masks

\- Devin must \*e able to construct content withou\* hardcoded assets

\- New content must never require changing the architecture



This document is the official asset architecture specification for the project.

