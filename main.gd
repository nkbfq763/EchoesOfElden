extends Node2D

@onready var town_map: Node2D = $TownMap
@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	if not GameData.get_character_data():
		GameData.set_character_data(load("res://data/hero.tres"))
	town_map.set_player(player)
	town_map.field_requested.connect(_on_field_requested)
	town_map.load_area(
		GameData.current_town_area,
		GameData.current_town_arrival_edge
	)

func _on_field_requested() -> void:
	GameData.current_town_area = "outskirts"
	GameData.current_town_arrival_edge = "down"
	get_tree().change_scene_to_file("res://field.tscn")
