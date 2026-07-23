extends Resource
class_name EnemyData

@export var enemy_name: String
@export var max_hp: int = 30
@export var attack: int = 5
@export var defense: int = 0
@export var exp: int = 5
@export var gald: int = 3
@export var attack_interval: float = 2.0
@export_range(0.1, 2.0) var aggression: float = 1.0
@export var move_speed: float = 45.0
@export_file("*.png") var battle_sprite: String = "res://assets/enemies/slime/battle.png"
@export_dir var animations_path: String = ""
@export var battle_bg: String = ""
