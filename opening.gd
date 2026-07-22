extends Control

var step := 0
@onready var message: Label = $Message

func _ready() -> void:
	var hero: CharacterData = load("res://data/hero.tres")
	GameData.set_character_data(hero)
	_update_step()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		step += 1
		if step >= 3:
			get_tree().change_scene_to_file("res://EldenVillage.tscn")
		else:
			_update_step()

func _update_step() -> void:
	match step:
		0:
			message.text = "A quiet day in Elden Village..."
			$Selene.color = Color(0.35, 0.55, 0.95, 0.8)
			$Selene.position = Vector2(470, 45)
		1:
			message.text = "Selene falls from the sky!"
			$Selene.position = Vector2(470, 185)
		2:
			message.text = "Roland catches her. A new journey begins."
			$Roland.color = Color(0.8, 0.35, 0.3, 1)
