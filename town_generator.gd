extends Node2D

const MAP_SIZE := Vector2(640, 480)
const SPAWN_POINT := Vector2(320, 240)

# 背景画像と衝突判定で共通の建物配置（左上原点 + サイズ）
const BUILDINGS: Array[Rect2] = [
	Rect2(40, 40, 100, 80),
	Rect2(500, 40, 100, 80),
	Rect2(40, 360, 100, 80),
	Rect2(500, 360, 100, 80),
	Rect2(120, 120, 60, 50),
	Rect2(460, 120, 60, 50),
	Rect2(120, 310, 60, 50),
	Rect2(460, 310, 60, 50),
]

@export var background: Sprite2D

func _ready() -> void:
	if not background:
		background = $Background
	
	if not background.texture:
		background.texture = load("res://assets/images/town.png")
	
	setup_collision_for_background()

func get_spawn_point() -> Vector2:
	return SPAWN_POINT

func setup_collision_for_background() -> void:
	for building in BUILDINGS:
		create_rect_collision(building)

func create_rect_collision(rect: Rect2) -> void:
	var static_body := StaticBody2D.new()
	static_body.position = rect.get_center()
	static_body.collision_layer = 1
	static_body.collision_mask = 1
	
	var collision_shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = rect.size
	collision_shape.shape = rect_shape
	
	static_body.add_child(collision_shape)
	add_child(static_body)
