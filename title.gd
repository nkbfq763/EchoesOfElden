extends Control

func _ready() -> void:
	$Panel/NewButton.grab_focus()

func _on_new_button_pressed() -> void:
	get_tree().change_scene_to_file("res://opening.tscn")

func _on_continue_button_pressed() -> void:
	get_tree().change_scene_to_file("res://opening.tscn")
