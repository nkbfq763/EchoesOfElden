extends Node2D

const MENU_SCREEN = preload("res://scripts/ui/menu_screen.gd")
const META_PATH := "res://assets/maps/settlements/s001_elden_village/meta/"
const PREFAB_PATH := "res://assets/prefabs/objects/"
const SCREEN_SIZE := {
	"bg_screen_a": Vector2i(500, 500),
	"bg_screen_b": Vector2i(500, 500),
	"bg_screen_c": Vector2i(500, 500),
	"bg_screen_d": Vector2i(504, 506),
}
const SCREEN_NEIGHBORS: Dictionary = {
	"bg_screen_a": {
		"right": "bg_screen_b",
		"down": "bg_screen_c",
	},
	"bg_screen_b": {
		"left": "bg_screen_a",
		"down": "bg_screen_d",
	},
	"bg_screen_c": {
		"up": "bg_screen_a",
		"right": "bg_screen_d",
	},
	"bg_screen_d": {
		"up": "bg_screen_b",
		"left": "bg_screen_c",
	},
}

# 色判定しきい値（0.0-1.0）
const COLOR_CHANNEL_HIGH := 0.78 # 200/255
const COLOR_CHANNEL_LOW := 0.32 # 80/255
const BLACK_CHANNEL_MAX := 0.24 # 60/255
const MASK_ALPHA_THRESHOLD := 0.5
const MASK_POLYGON_EPSILON := 2.5
const MIN_POLYGON_AREA := 8.0

# z_index
const Z_BACKGROUND := -100
const Z_OVERHANG := 100

const EDGE_TRIGGER_DISTANCE := 4.0
const ENTRY_MARGIN := 28.0
const TRANSITION_COOLDOWN := 0.35

@onready var background: Sprite2D = $BackgroundLayer/Background
@onready var object_layer: Node2D = $ObjectLayer
@onready var overhang_layer: Node2D = $OverhangLayer
@onready var collision_layer: Node2D = $CollisionLayer
@onready var player: CharacterBody2D = $FieldPlayer
@onready var camera: Camera2D = $FieldPlayer/Camera2D

var current_screen_id := "bg_screen_a"
var _player_initialized := false
var _transition_cooldown := 0.0
var _prefab_cache: Dictionary = {}

func _ready() -> void:
	load_screen("bg_screen_a")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		MENU_SCREEN.open(get_tree())
		get_viewport().set_input_as_handled()

func load_screen(screen_id: String, entry_direction: String = "") -> void:
	var meta := _load_screen_metadata(screen_id)
	if meta.is_empty():
		return

	current_screen_id = screen_id
	var background_path: String = str(meta.get("background", ""))
	background.texture = load(background_path) as Texture2D
	background.position = Vector2.ZERO
	background.centered = false
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	background.z_index = Z_BACKGROUND

	_clear_layer(object_layer)
	_clear_layer(overhang_layer)
	_clear_layer(collision_layer)

	var objects: Array = meta.get("objects", [])
	for object_data in objects:
		_load_object(object_data)

	_configure_camera(screen_id)
	if not _player_initialized:
		player.position = _screen_size(screen_id) * 0.5
		_player_initialized = true
	elif not entry_direction.is_empty():
		_place_player_at_entry(screen_id, entry_direction)

func change_screen(direction: String) -> void:
	var neighbors: Dictionary = SCREEN_NEIGHBORS.get(current_screen_id, {})
	var next_screen: String = str(neighbors.get(direction, ""))
	if next_screen.is_empty():
		return
	player.stop_movement()
	load_screen(next_screen, _opposite_direction(direction))
	_transition_cooldown = TRANSITION_COOLDOWN

# --------------------------------------------------------------------
# オブジェクト読み込み
# --------------------------------------------------------------------

func _load_object(object_data: Dictionary) -> void:
	# prefab_ref があれば既定値を読み込み、object_data で上書き
	var data := object_data.duplicate()
	var prefab_ref: String = str(object_data.get("prefab_ref", ""))
	if not prefab_ref.is_empty():
		var prefab := _load_prefab(prefab_ref)
		if prefab.is_empty():
			return
		var merged := prefab.duplicate()
		for key in data.keys():
			merged[key] = data[key]
		data = merged

	var object_path: String = str(data.get("object_ref", ""))
	var texture := load(object_path) as Texture2D
	if not texture:
		push_warning("Missing object texture: %s" % object_path)
		return

	var position_data: Dictionary = data.get("position", {})
	var obj_position := Vector2(
		float(position_data.get("x", 0.0)),
		float(position_data.get("y", 0.0))
	)
	var object_scale := float(data.get("scale", 1.0))
	var category: String = str(data.get("category", "SolidOnly"))
	var collision_depth := float(data.get("collision_depth", 0.0))
	var mask_path: String = str(data.get("mask_ref", ""))

	# 本体スプライト（Yソート空間。足元Yで前後関係が決まる）
	var sprite := Sprite2D.new()
	sprite.name = str(data.get("id", "Object"))
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.position = obj_position
	sprite.scale = Vector2(object_scale, object_scale)
	object_layer.add_child(sprite)

	# Overhang（赤部分）は前面レイヤに分離（衝突なし・常にキャラより前）
	var overhang_tex := _build_color_texture(mask_path, object_path, "overhang")
	if overhang_tex:
		var overhang := Sprite2D.new()
		overhang.name = "%s_Overhang" % sprite.name
		overhang.texture = overhang_tex
		overhang.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		overhang.centered = false
		overhang.position = obj_position
		overhang.scale = Vector2(object_scale, object_scale)
		overhang.z_index = Z_OVERHANG
		overhang_layer.add_child(overhang)

	# 衝突（カテゴリに応じて黒=全身 / 青=足元帯）
	# Walkable（緑）は無衝突。Overhang（赤）も通行可能なので衝突を作らない。
	if bool(data.get("collision", false)) and category != "Walkable":
		_add_object_collisions(sprite, mask_path, category, collision_depth)

# --------------------------------------------------------------------
# 衝突生成（案B：色分け）
# --------------------------------------------------------------------

func _add_object_collisions(sprite: Sprite2D, mask_path: String, category: String, collision_depth: float) -> void:
	var image := _load_image(mask_path)
	if image.is_empty():
		return

	var w := image.get_width()
	var h := image.get_height()
	var bitmap := BitMap.new()
	bitmap.create(Vector2i(w, h))

	var has_pixel := false
	match category:
		"SolidOnly":
			# 黒（Solid）を全身衝突
			for y in h:
				for x in w:
					var solid := _is_solid(image.get_pixel(x, y))
					bitmap.set_bit(x, y, solid)
					has_pixel = has_pixel or solid
		"SideStructure":
			# 青（SideStructure）のうち足元帯（下端から collision_depth px）のみ衝突
			var depth := int(maxf(collision_depth, 1.0))
			var y_start := maxi(h - depth, 0)
			for y in range(y_start, h):
				for x in w:
					var side := _is_side(image.get_pixel(x, y)) or _is_solid(image.get_pixel(x, y))
					bitmap.set_bit(x, y, side)
					has_pixel = has_pixel or side
		"Walkable":
			# 緑（Walkable）は無衝突（明示）
			return
		_:
			# Overhang・その他カテゴリは衝突なし
			return

	if not has_pixel:
		return

	var bounds := Rect2(Vector2.ZERO, Vector2(w, h))
	var polygons := bitmap.opaque_to_polygons(bounds, MASK_POLYGON_EPSILON)
	if polygons.is_empty():
		return

	var body := StaticBody2D.new()
	body.name = "%s_Collision" % sprite.name
	body.position = sprite.position
	body.scale = sprite.scale
	body.collision_layer = 1
	body.collision_mask = 1
	collision_layer.add_child(body)

	for index in polygons.size():
		var collision := CollisionPolygon2D.new()
		collision.name = "Polygon%d" % index
		collision.polygon = polygons[index]
		body.add_child(collision)

# --------------------------------------------------------------------
# Overhang（赤部分）の描画用テクスチャ生成
# --------------------------------------------------------------------

func _build_color_texture(mask_path: String, object_path: String, color_kind: String) -> Texture2D:
	var mask_image := _load_image(mask_path)
	if mask_image.is_empty():
		return null

	# 対応するオブジェクト画像から赤マスク部分だけを切り出す
	# object_ref を正本として使い、マスクパスからの推定には依存しない
	var object_texture := load(object_path) as Texture2D
	if not object_texture:
		return null
	var object_image := object_texture.get_image()
	if object_image.is_empty():
		return null

	# マスクとオブジェクト画像でサイズが異なる場合に備えて共通範囲のみ処理
	var w := mini(mask_image.get_width(), object_image.get_width())
	var h := mini(mask_image.get_height(), object_image.get_height())
	var out_image := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var found := false
	for y in h:
		for x in w:
			var mp := mask_image.get_pixel(x, y)
			var is_target := false
			match color_kind:
				"overhang":
					is_target = _is_overhang(mp)
			if is_target:
				var op := object_image.get_pixel(x, y)
				out_image.set_pixel(x, y, op)
				found = true
			else:
				out_image.set_pixel(x, y, Color(0, 0, 0, 0))

	if not found:
		return null
	return ImageTexture.create_from_image(out_image)

# --------------------------------------------------------------------
# 色判定
# --------------------------------------------------------------------

func _is_overhang(p: Color) -> bool:
	return p.a >= MASK_ALPHA_THRESHOLD and p.r >= COLOR_CHANNEL_HIGH and p.g <= COLOR_CHANNEL_LOW and p.b <= COLOR_CHANNEL_LOW

func _is_side(p: Color) -> bool:
	return p.a >= MASK_ALPHA_THRESHOLD and p.b >= COLOR_CHANNEL_HIGH and p.r <= COLOR_CHANNEL_LOW and p.g <= COLOR_CHANNEL_LOW

func _is_solid(p: Color) -> bool:
	return p.a >= MASK_ALPHA_THRESHOLD and p.r <= BLACK_CHANNEL_MAX and p.g <= BLACK_CHANNEL_MAX and p.b <= BLACK_CHANNEL_MAX

# --------------------------------------------------------------------
# prefab
# --------------------------------------------------------------------

func _load_prefab(prefab_id: String) -> Dictionary:
	if _prefab_cache.has(prefab_id):
		return _prefab_cache[prefab_id]
	var path := "%s%s/%s.json" % [PREFAB_PATH, prefab_id, prefab_id]
	if not FileAccess.file_exists(path):
		push_warning("Missing prefab: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	_prefab_cache[prefab_id] = parsed
	return parsed

# --------------------------------------------------------------------
# 画面メタ
# --------------------------------------------------------------------

func _load_screen_metadata(screen_id: String) -> Dictionary:
	var metadata_path := META_PATH + "%s.json" % screen_id
	if not FileAccess.file_exists(metadata_path):
		push_warning("Missing screen metadata: %s" % metadata_path)
		return {}

	var file := FileAccess.open(metadata_path, FileAccess.READ)
	if not file:
		push_warning("Unable to open screen metadata: %s" % metadata_path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_warning("Invalid screen metadata: %s" % metadata_path)
		return {}
	return parsed

# --------------------------------------------------------------------
# カメラ / 遷移
# --------------------------------------------------------------------

func _configure_camera(screen_id: String) -> void:
	var size := _screen_size(screen_id)
	camera.position = Vector2.ZERO
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = size.x
	camera.limit_bottom = size.y
	camera.enabled = true

func _screen_size(screen_id: String) -> Vector2i:
	return SCREEN_SIZE.get(screen_id, Vector2i(500, 500))

func _place_player_at_entry(screen_id: String, entry_direction: String) -> void:
	var size := Vector2(_screen_size(screen_id))
	var position := player.position
	match entry_direction:
		"left":
			position.x = ENTRY_MARGIN
			position.y = clampf(position.y, ENTRY_MARGIN, size.y - ENTRY_MARGIN)
		"right":
			position.x = size.x - ENTRY_MARGIN
			position.y = clampf(position.y, ENTRY_MARGIN, size.y - ENTRY_MARGIN)
		"up":
			position.y = ENTRY_MARGIN
			position.x = clampf(position.x, ENTRY_MARGIN, size.x - ENTRY_MARGIN)
		"down":
			position.y = size.y - ENTRY_MARGIN
			position.x = clampf(position.x, ENTRY_MARGIN, size.x - ENTRY_MARGIN)
	player.position = position

func _opposite_direction(direction: String) -> String:
	match direction:
		"left":
			return "right"
		"right":
			return "left"
		"up":
			return "down"
		"down":
			return "up"
	return ""

func _process(delta: float) -> void:
	if _transition_cooldown > 0.0:
		_transition_cooldown = maxf(0.0, _transition_cooldown - delta)
		return
	var direction := _get_edge_direction()
	if direction.is_empty():
		return
	var neighbors: Dictionary = SCREEN_NEIGHBORS.get(current_screen_id, {})
	if not neighbors.has(direction):
		return
	change_screen(direction)

func _get_edge_direction() -> String:
	var size := Vector2(_screen_size(current_screen_id))
	var position := player.position
	if position.x <= EDGE_TRIGGER_DISTANCE:
		return "left"
	if position.x >= size.x - EDGE_TRIGGER_DISTANCE:
		return "right"
	if position.y <= EDGE_TRIGGER_DISTANCE:
		return "up"
	if position.y >= size.y - EDGE_TRIGGER_DISTANCE:
		return "down"
	return ""

func _clear_layer(layer: Node2D) -> void:
	for child in layer.get_children():
		child.free()

func _load_image(path: String) -> Image:
	var texture := load(path) as Texture2D
	if texture:
		return texture.get_image()

	var image := Image.new()
	if image.load(path) == OK:
		return image
	return Image.new()