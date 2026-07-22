extends RefCounted

static func play_to_battle(tree: SceneTree) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	tree.root.add_child(layer)

	var left_panel := ColorRect.new()
	left_panel.color = Color(0.04, 0.04, 0.07, 1.0)
	left_panel.position = Vector2(-320, 0)
	left_panel.size = Vector2(320, 360)
	layer.add_child(left_panel)

	var right_panel := ColorRect.new()
	right_panel.color = Color(0.04, 0.04, 0.07, 1.0)
	right_panel.position = Vector2(640, 0)
	right_panel.size = Vector2(320, 360)
	layer.add_child(right_panel)

	var flash := ColorRect.new()
	flash.color = Color.WHITE
	flash.position = Vector2.ZERO
	flash.size = Vector2(640, 360)
	flash.modulate.a = 0.0
	layer.add_child(flash)

	var tween := layer.create_tween()
	tween.set_parallel(true)
	tween.tween_property(left_panel, "position:x", 0.0, 0.32)
	tween.tween_property(right_panel, "position:x", 320.0, 0.32)
	tween.set_parallel(false)
	tween.tween_property(flash, "modulate:a", 1.0, 0.08)
	tween.tween_property(flash, "modulate:a", 0.0, 0.12)
	tween.tween_callback(func() -> void:
		layer.queue_free()
		tree.change_scene_to_file("res://battle.tscn")
	)
