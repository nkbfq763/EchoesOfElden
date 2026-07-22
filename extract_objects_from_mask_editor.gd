extends EditorScript

func _run():
	print("マスク抽出開始…")

	var base_path = "res://assets/maps/settlements/s001_elden_village/objects/elden_village_objects.png"
	var mask_path = "res://assets/maps/settlements/s001_elden_village/masks/elden_village_objects_mask.png"

	var node := load("res://assets/maps/settlements/s001_elden_village/scripts/extract_objects_from_mask.gd").new()
	node.extract_objects(base_path, mask_path)

	print("抽出完了")
