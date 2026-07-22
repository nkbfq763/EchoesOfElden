extends Node2D

const SLIME: EnemyData = preload("res://data/slime.tres")
const GOBLIN: EnemyData = preload("res://data/goblin.tres")

func _ready() -> void:
	if GameData.battle_won and not GameData.defeated_symbol_id.is_empty():
		for symbol in get_children():
			if symbol.get("symbol_id") == GameData.defeated_symbol_id:
				symbol.queue_free()
				break
		GameData.battle_won = false
		GameData.defeated_symbol_id = ""
	$Player.global_position = Vector2(110, 180)

func _on_town_exit_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		GameData.current_town_area = "outskirts"
		GameData.current_town_arrival_edge = "down"
		get_tree().change_scene_to_file("res://main.tscn")
