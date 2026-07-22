extends Node3D

@onready var terrain := $HTerrain
@onready var cam := $Camera3D

func _ready():
	terrain.load_heightmap("res://terrain_data/heightmap.png")
