\# Devin 実装指示書：Linear Motion Battle System（LMBS）構築



\## 目的

本プロジェクトの戦闘システムは、テイルズオブエターニア風の

\*\*Linear Motion Battle System（LMBS）を強く採用する。\*\*



横1ラインでのリアルタイム戦闘を構築し、

「間合い管理 × コンボ連携 × 詠唱術 × 敵AI」を中心に据える。



\## 1. 戦闘導入（ランダムエンカウント）



\- フィールド・ダンジョンでは encounter\_enabled = true

\- 町では encounter\_enabled = false

\- 歩数または時間ベースで乱数判定し戦闘へ移行する



\### 画面割れ演出

\- 画面中央から左右に割れるアニメーション

\- 白フラッシュを挟む

\- 完了後 battle\_scene.tscn をロードする



\## 2. 戦闘MAP（Battle Background）



戦闘背景は以下のフォルダから読み込む：



assets/maps/battle\_maps/

&#x20;├─ battle\_bg\_cave.png

&#x20;├─ battle\_bg\_forest.png

&#x20;└─ battle\_bg\_plain.png



敵データ（JSON）に battle\_bg を指定し、戦闘開始時に背景をロードする。



\## 3. 敵アセット構成（LMBS標準）



assets/characters/enemies/<enemy\_id>/

&#x20;├─ Attack/

&#x20;│   └─ Combo\_01/

&#x20;│        frame\_000.png

&#x20;│        frame\_001.png

&#x20;│        ...

&#x20;├─ Idle/

&#x20;│        frame\_000.png

&#x20;│        frame\_001.png

&#x20;│        ...

&#x20;└─ Run/

&#x20;        frame\_000.png

&#x20;        frame\_001.png

&#x20;        ...



必須モーション:

\- Idle

\- Run

\- Attack/Combo\_01



敵データは JSON で管理し、モーションフォルダをパスで指定する。



\## 4. 味方アセット構成（Roland）



assets/characters/party/roland\_hartwell/battle/animations/

&#x20;├─ attack/

&#x20;│   ├─ Combo\_01/

&#x20;│   ├─ Combo\_02/

&#x20;│   └─ Combo\_03/

&#x20;├─ Guard/

&#x20;├─ idle/

&#x20;├─ Parry/

&#x20;├─ rotations/

&#x20;└─ Run/



rotations は 8方向の向き画像。



\## 5. battle\_scene.tscn 構成



battle\_scene.tscn (Node2D)

&#x20;├─ Background (Sprite2D)

&#x20;├─ PlayerLayer (Node2D)

&#x20;│   └─ Roland (AnimatedSprite2D or AnimationTree)

&#x20;├─ EnemyLayer (Node2D)

&#x20;│   └─ Wolf (AnimatedSprite2D or AnimationTree)

&#x20;├─ UILayer (CanvasLayer)

&#x20;│   ├─ CommandMenu

&#x20;│   └─ StatusBars

&#x20;└─ BattleController (Node)



\## 6. BattleUnit の行動ステート



IDLE

MOVE（前進/後退）

JUMP

ATTACK（1/2/3）

TECH（特技）

CAST（詠唱→発動）

GUARD

STEP（回避）

HURT（のけぞり）

DOWN（ダウン）

KO（戦闘不能）

VICTORY（勝利ポーズ）



攻撃中は硬直があり、ステップや特技でキャンセル可能。



\## 7. コンボ連携



通常攻撃は 1 → 2 → 3 の3段。

通常 → 特技 → 奥義 の順で連携可能。



ステップで硬直キャンセルし再度攻撃へ派生できる。



コンボ数に応じて軽いダメージ補正を加える。



\## 8. 詠唱術（アーツ）



\- 術は詠唱 → 発動の2段階

\- 詠唱中は無防備

\- 被弾で詠唱中断

\- 前衛が敵を拘束し、後衛が詠唱を通す構造を重視する



\## 9. ダメージ計算式



base   = attacker.attack \* skill\_power

raw    = base - defender.defense

elem   = raw \* element\_multiplier

combo  = elem \* (1 + min(combo\_hits \* 0.01, 0.3))

damage = max(1, floor(combo)) ± 乱数(±5)



\## 10. 敵AI



APPROACH → ATTACK → RECOVER → REPOSITION を巡回。



攻撃前に予備動作（テレグラフ）を入れ、

プレイヤーがガード/ステップで対応できるようにする。



敵ごとに aggressiveness / attack\_interval を JSON で設定。



\## 11. バトルUI



\- HPバー / TPバー

\- コンボカウンタ

\- ダメージ数字

\- 詠唱ゲージ

\- ターゲットマーカー



素材が揃うまでは暫定UIで実装してよい。



\## 12. 勝敗処理



勝利:

\- 敵全滅

\- 経験値・ガルド・アイテム獲得

\- 元マップへ復帰



敗北:

\- 味方全滅

\- ゲームオーバー



\## 13. Devin 実装タスク一覧（LMBS）



\### Task 1

ランダムエンカウント処理を実装する。



\### Task 2

画面割れエフェクト → battle\_scene.tscn への遷移を実装する。



\### Task 3

battle\_scene.tscn を構築し、背景・味方・敵・UI を配置する。



\### Task 4

BattleUnit（味方/敵共通）の行動ステートを実装する。



\### Task 5

通常攻撃3段コンボ、特技、詠唱術、ステップ回避を実装する。



\### Task 6

敵AI（APPROACH → ATTACK → RECOVER → REPOSITION）を実装する。



\### Task 7

ダメージ計算式を実装する。



\### Task 8

勝敗処理（勝利/敗北）を実装する。



\### Task 9

敵データ（JSON）とモーションフォルダを読み込む仕組みを作る。



\### Task 10

味方アニメーション（Roland）を AnimationTree で制御する。



