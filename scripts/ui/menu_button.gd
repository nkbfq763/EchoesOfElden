extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	preload("res://scripts/ui/menu_screen.gd").open(get_tree())
