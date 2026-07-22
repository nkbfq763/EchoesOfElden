extends Node

const OUTPUT_DIR = "res://assets/maps/settlements/s001_elden_village/objects_extracted/"
const DILATION_RADIUS = 2      # 1px途切れを繋げるための膨張半径
const MIN_REGION_SIZE = 100    # 小さすぎる塊は無視（ノイズ除去）

func _ready():
	extract_objects_rect(
		"res://assets/maps/settlements/s001_elden_village/objects/elden_village_objects.png",
        "res://assets/maps/settlements/s001_elden_village/masks/elden_village_objects_mask.png"
	)
	print("矩形オブジェクト抽出完了")


func extract_objects_rect(base_path: String, mask_path: String):
	ensure_dir(OUTPUT_DIR)

	var base_img := Image.load_from_file(base_path)
	var mask_img := Image.load_from_file(mask_path)

	base_img.convert(Image.FORMAT_RGBA8)
	mask_img.convert(Image.FORMAT_RGBA8)

	# 元画像の非透明ピクセルを膨張して「1px途切れ」を繋げる
	var dilated := dilate_mask(base_img, DILATION_RADIUS)

	var visited := {}
	var object_index := 0

	var w = dilated.get_width()
	var h = dilated.get_height()

	for x in w:
		for y in h:
			var c = dilated.get_pixel(x, y)

			# 非透明ピクセルだけ対象（色は使わない）
			if c.a == 0.0:
				continue

			var key = Vector2i(x, y)
			if visited.has(key):
				continue

			# 塊抽出（膨張後の元画像で flood-fill）
			var region = flood_fill(dilated, x, y, visited)

			# 小さすぎる塊は無視
			if region.size() < MIN_REGION_SIZE:
				continue

			# 塊の bounding box
			var rect = get_bounding_box(region)

			# 元画像とマスク画像を同じ矩形で切り出す
			var obj_img = crop_image(base_img, rect)
			var mask_sub = crop_image(mask_img, rect)

			# 保存
			obj_img.save_png(OUTPUT_DIR + "object_%d.png" % object_index)
			mask_sub.save_png(OUTPUT_DIR + "object_%d_mask.png" % object_index)

			object_index += 1


func dilate_mask(img: Image, radius: int) -> Image:
	var w = img.get_width()
	var h = img.get_height()
	var out = img.duplicate()

	for x in w:
		for y in h:
			if img.get_pixel(x, y).a > 0.0:
				for dx in range(-radius, radius + 1):
					for dy in range(-radius, radius + 1):
						var nx = x + dx
						var ny = y + dy
						if nx >= 0 and ny >= 0 and nx < w and ny < h:
							out.set_pixel(nx, ny, Color(1,1,1,1)) # 非透明化
	return out


func flood_fill(img: Image, sx: int, sy: int, visited: Dictionary) -> Array:
	var stack = [Vector2i(sx, sy)]
	var region := []

	while stack.size() > 0:
		var p = stack.pop_back()
		if visited.has(p):
			continue

		var c = img.get_pixel(p.x, p.y)
		if c.a == 0.0:
			continue

		# 塊のピクセルだけ visited に入れる（矩形は入れない）
		visited[p] = true
		region.append(p)

		for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var np = p + dir
			if np.x >= 0 and np.y >= 0 and np.x < img.get_width() and np.y < img.get_height():
				if not visited.has(np):
					stack.append(np)

	return region


func get_bounding_box(region: Array) -> Rect2i:
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF

	for p in region:
		min_x = min(min_x, p.x)
		min_y = min(min_y, p.y)
		max_x = max(max_x, p.x)
		max_y = max(max_y, p.y)

	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)


func crop_image(img: Image, rect: Rect2i) -> Image:
	var out = Image.create(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8)
	out.fill(Color(0,0,0,0))

	for x in rect.size.x:
		for y in rect.size.y:
			var c = img.get_pixel(rect.position.x + x, rect.position.y + y)
			out.set_pixel(x, y, c)

	return out


func ensure_dir(path: String):
	var da = DirAccess.open("res://")
	if not DirAccess.dir_exists_absolute(path):
		da.make_dir_recursive(path)
