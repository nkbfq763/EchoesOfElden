extends Resource
class_name CharacterData

@export var character_name: String
@export var character_type: String # "warrior", "priest", etc.
@export var sprite_texture: Texture2D
@export var speed: float = 150.0
@export var health: int = 100
@export var defense: int = 0
@export var max_tp: int = 100
@export var current_hp: int = -1
@export var current_tp: int = -1
@export var attack: int = 10

func reset_for_battle() -> void:
	if current_hp < 0:
		current_hp = health
	if current_tp < 0:
		current_tp = max_tp
