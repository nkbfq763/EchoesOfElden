extends Area2D

@export var symbol_id: String = "slime_1"
@export var enemy_data: EnemyData
var triggered := false

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 18.0
	shape.shape = circle
	add_child(shape)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 16.0, Color(0.2, 0.8, 0.45, 1))
	draw_circle(Vector2(-5, -3), 2.0, Color.WHITE)
	draw_circle(Vector2(5, -3), 2.0, Color.WHITE)
	draw_circle(Vector2(-5, -3), 1.0, Color.DARK_GREEN)
	draw_circle(Vector2(5, -3), 1.0, Color.DARK_GREEN)

func _on_body_entered(body: Node2D) -> void:
	if triggered or not body is CharacterBody2D:
		return
	triggered = true
	GameData.set_encounter([enemy_data], symbol_id)
	get_tree().change_scene_to_file("res://battle.tscn")
