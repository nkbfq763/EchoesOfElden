extends Node2D

const META_PATH := "res://assets/maps/settlements/s001_elden_village/meta/"
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
const SOLID_CHANNEL_THRESHOLD := 0.2
const SOLID_ALPHA_THRESHOLD := 0.5
const MASK_POLYGON_EPSILON := 2.5

@onready var background: Sprite2D = $BackgroundLayer/Background
@onready var object_layer: Node2D = $ObjectLayer
@onready var collision_layer: Node2D = $CollisionLayer
@onready var camera: Camera2D = $Camera2D

var current_screen_id := "bg_screen_a"

func _ready() -> void:
	load_screen("bg_screen_a")

func load_screen(screen_id: String) -> void:
	var meta := _load_screen_metadata(screen_id)
	if meta.is_empty():
		return

	current_screen_id = screen_id
	var background_path: String = str(meta.get("background", ""))
	background.texture = load(background_path) as Texture2D
	background.position = Vector2.ZERO
	background.centered = false
	background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	_clear_layer(object_layer)
	_clear_layer(collision_layer)

	var objects: Array = meta.get("objects", [])
	for object_data in objects:
		_load_object(object_data)

	_configure_camera(screen_id)

func change_screen(direction: String) -> void:
	var neighbors: Dictionary = SCREEN_NEIGHBORS.get(current_screen_id, {})
	var next_screen: String = str(neighbors.get(direction, ""))
	if next_screen.is_empty():
		return
	load_screen(next_screen)

func generate_polygon_from_mask(mask_path: String) -> Array[PackedVector2Array]:
	var image := _load_image(mask_path)
	if image.is_empty():
		return []

	var bitmap := BitMap.new()
	bitmap.create(Vector2i(image.get_width(), image.get_height()))
	var has_solid_pixel := false
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			var is_solid := (
				pixel.a >= SOLID_ALPHA_THRESHOLD
				and pixel.r <= SOLID_CHANNEL_THRESHOLD
				and pixel.g <= SOLID_CHANNEL_THRESHOLD
				and pixel.b <= SOLID_CHANNEL_THRESHOLD
			)
			bitmap.set_bit(x, y, is_solid)
			has_solid_pixel = has_solid_pixel or is_solid

	if not has_solid_pixel:
		return []

	var bounds := Rect2(Vector2.ZERO, Vector2(image.get_width(), image.get_height()))
	return bitmap.opaque_to_polygons(bounds, MASK_POLYGON_EPSILON)

func _load_screen_metadata(screen_id: String) -> Dictionary:
	var metadata_path := META_PATH + "%s.json" % screen_id
	if not FileAccess.file_exists(metadata_path):
		push_warning("Missing Elden Village screen metadata: %s" % metadata_path)
		return {}

	var file := FileAccess.open(metadata_path, FileAccess.READ)
	if not file:
		push_warning("Unable to open Elden Village screen metadata: %s" % metadata_path)
		return {}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		push_warning("Invalid Elden Village screen metadata: %s" % metadata_path)
		return {}
	return parsed

func _load_object(object_data: Dictionary) -> void:
	var object_path: String = str(object_data.get("object_ref", ""))
	var texture := load(object_path) as Texture2D
	if not texture:
		push_warning("Missing Elden Village object texture: %s" % object_path)
		return

	var sprite := Sprite2D.new()
	sprite.name = str(object_data.get("id", "Object"))
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	var position_data: Dictionary = object_data.get("position", {})
	sprite.position = Vector2(
		float(position_data.get("x", 0.0)),
		float(position_data.get("y", 0.0))
	)
	var object_scale := float(object_data.get("scale", 1.0))
	sprite.scale = Vector2(object_scale, object_scale)
	sprite.z_index = _object_z_index(sprite)
	object_layer.add_child(sprite)

	if bool(object_data.get("collision", false)):
		_add_object_collisions(object_data, sprite)

func _add_object_collisions(object_data: Dictionary, sprite: Sprite2D) -> void:
	var mask_path: String = str(object_data.get("mask_ref", ""))
	var polygons := generate_polygon_from_mask(mask_path)
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

func _object_z_index(sprite: Sprite2D) -> int:
	if not sprite.texture:
		return int(sprite.position.y)
	return roundi(sprite.position.y + sprite.texture.get_height() * sprite.scale.y)

func _configure_camera(screen_id: String) -> void:
	var size: Vector2i = SCREEN_SIZE.get(screen_id, Vector2i(500, 500))
	camera.position = Vector2(size) * 0.5
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = size.x
	camera.limit_bottom = size.y
	camera.enabled = true

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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_right"):
		change_screen("right")
	elif event.is_action_pressed("ui_left"):
		change_screen("left")
	elif event.is_action_pressed("ui_up"):
		change_screen("up")
	elif event.is_action_pressed("ui_down"):
		change_screen("down")
