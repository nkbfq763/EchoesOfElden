extends Node2D

signal field_requested

const MAP_SIZE := Vector2i(1536, 1024)
const SPAWN_POINT := Vector2(768, 900)
const COLLISION_ALPHA_THRESHOLD := 0.5
const COLLISION_POLYGON_EPSILON := 3.0
const FLOOD_SCALE := 4
const APPROACH_RADIUS := 120.0
const TRANSITION_RADIUS := 40.0
const ARRIVAL_INSET := 80.0

const AREA_DATA: Dictionary = {
	"square": {
		"background": "res://assets/town/elden/square.png",
		"collision": "res://assets/town/elden/square_collision.png",
		"gates": {
			"left": "residential",
			"up": "chiefs_house",
			"down": "outskirts",
		},
	},
	"residential": {
		"background": "res://assets/town/elden/residential.png",
		"collision": "res://assets/town/elden/residential_collision.png",
		"gates": {
			"right": "square",
		},
	},
	"chiefs_house": {
		"background": "res://assets/town/elden/chiefs_house.png",
		"collision": "res://assets/town/elden/chiefs_house_collision.png",
		"gates": {
			"down": "square",
		},
	},
	"outskirts": {
		"background": "res://assets/town/elden/outskirts.png",
		"collision": "res://assets/town/elden/outskirts_collision.png",
		"gates": {
			"up": "square",
			"down": "field",
		},
	},
}

var current_area_id := "square"
var player: CharacterBody2D
var background: Sprite2D
var _transitioning := false
var _disarmed_direction := ""
var _gate_nodes: Array[Node] = []
var _gate_transition_areas: Dictionary = {}

func _ready() -> void:
	background = $Background

func set_player(player_node: CharacterBody2D) -> void:
	player = player_node

func load_area(area_id: String, arrival_edge := "") -> void:
	if not AREA_DATA.has(area_id):
		push_warning("Unknown town area: %s" % area_id)
		return

	var area: Dictionary = AREA_DATA[area_id]
	current_area_id = area_id
	_transitioning = false
	_disarmed_direction = arrival_edge
	background.texture = load(area["background"]) as Texture2D
	_clear_gates()
	_clear_collisions()

	var mask_image := _load_image(area["collision"])
	var ground_points: Dictionary = {}
	if not mask_image.is_empty():
		_generate_mask_collisions(mask_image)
		ground_points = _find_ground_gate_points(mask_image)
	else:
		push_warning("Unable to load town collision mask: %s" % area["collision"])

	for direction in area["gates"]:
		var gate_point: Vector2 = ground_points.get(
			direction,
			_fallback_gate_point(direction)
		)
		_create_gate(
			direction,
			area["gates"][direction],
			gate_point,
			direction != _disarmed_direction
		)

	if player:
		if arrival_edge.is_empty():
			player.global_position = SPAWN_POINT
		else:
			var arrival_point: Vector2 = ground_points.get(
				arrival_edge,
				_fallback_gate_point(arrival_edge)
			)
			player.global_position = _arrival_position(arrival_edge, arrival_point)

	GameData.current_town_area = area_id
	GameData.current_town_arrival_edge = ""

func _load_image(path: String) -> Image:
	var texture := load(path) as Texture2D
	if texture:
		return texture.get_image()

	var image := Image.new()
	if image.load(path) == OK:
		return image
	return Image.new()

func _generate_mask_collisions(image: Image) -> void:
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(image, COLLISION_ALPHA_THRESHOLD)
	var bounds := Rect2(Vector2.ZERO, image.get_size())
	var polygons: Array[PackedVector2Array] = bitmap.opaque_to_polygons(
		bounds,
		COLLISION_POLYGON_EPSILON
	)
	for index in polygons.size():
		var body := StaticBody2D.new()
		body.name = "MaskCollision%d" % index
		body.collision_layer = 1
		body.collision_mask = 1

		var collision := CollisionPolygon2D.new()
		collision.polygon = polygons[index]
		body.add_child(collision)
		add_child(body)

func _clear_collisions() -> void:
	for child in get_children():
		if child is StaticBody2D:
			child.queue_free()

func _find_ground_gate_points(image: Image) -> Dictionary:
	var sample_width := ceili(float(image.get_width()) / FLOOD_SCALE)
	var sample_height := ceili(float(image.get_height()) / FLOOD_SCALE)
	var seed := _find_ground_seed(image, sample_width, sample_height)
	if seed.x < 0:
		return {}

	var visited := PackedByteArray()
	visited.resize(sample_width * sample_height)
	var queue: Array[int] = [seed.y * sample_width + seed.x]
	visited[seed.y * sample_width + seed.x] = 1
	var points: Array[Vector2i] = []
	var head := 0

	while head < queue.size():
		var index: int = queue[head]
		head += 1
		var point := Vector2i(index % sample_width, index / sample_width)
		points.append(point)

		for neighbor in [
			Vector2i(point.x - 1, point.y),
			Vector2i(point.x + 1, point.y),
			Vector2i(point.x, point.y - 1),
			Vector2i(point.x, point.y + 1),
		]:
			if neighbor.x < 0 or neighbor.x >= sample_width:
				continue
			if neighbor.y < 0 or neighbor.y >= sample_height:
				continue
			var neighbor_index: int = neighbor.y * sample_width + neighbor.x
			if visited[neighbor_index] or not _sample_is_walkable(image, neighbor):
				continue
			visited[neighbor_index] = 1
			queue.append(neighbor_index)

	if points.is_empty():
		return {}

	var min_x := points[0].x
	var max_x := points[0].x
	var min_y := points[0].y
	var max_y := points[0].y
	for point in points:
		min_x = mini(min_x, point.x)
		max_x = maxi(max_x, point.x)
		min_y = mini(min_y, point.y)
		max_y = maxi(max_y, point.y)

	var left_y := _average_axis(points, "x", min_x, "y")
	var right_y := _average_axis(points, "x", max_x, "y")
	var up_x := _average_axis(points, "y", min_y, "x")
	var down_x := _average_axis(points, "y", max_y, "x")

	return {
		"left": _sample_to_world(Vector2(min_x, left_y)),
		"right": _sample_to_world(Vector2(max_x, right_y)),
		"up": _sample_to_world(Vector2(up_x, min_y)),
		"down": _sample_to_world(Vector2(down_x, max_y)),
		"bounds_min": _sample_to_world(Vector2(min_x, min_y)),
		"bounds_max": _sample_to_world(Vector2(max_x, max_y)),
	}

func _find_ground_seed(
	image: Image,
	sample_width: int,
	sample_height: int
) -> Vector2i:
	var preferred := Vector2i(
		clampi(roundi(SPAWN_POINT.x / FLOOD_SCALE), 0, sample_width - 1),
		clampi(roundi(SPAWN_POINT.y / FLOOD_SCALE), 0, sample_height - 1)
	)
	if _sample_is_walkable(image, preferred):
		return preferred

	var center_x := clampi(sample_width / 2, 0, sample_width - 1)
	for y in range(sample_height - 1, -1, -1):
		for distance in range(sample_width):
			var left := center_x - distance
			if left >= 0 and _sample_is_walkable(image, Vector2i(left, y)):
				return Vector2i(left, y)
			var right := center_x + distance
			if right < sample_width and _sample_is_walkable(image, Vector2i(right, y)):
				return Vector2i(right, y)
	return Vector2i(-1, -1)

func _sample_is_walkable(image: Image, sample_point: Vector2i) -> bool:
	var start_x := sample_point.x * FLOOD_SCALE
	var start_y := sample_point.y * FLOOD_SCALE
	var transparent_pixels := 0
	var total_pixels := 0
	for offset_y in range(FLOOD_SCALE):
		for offset_x in range(FLOOD_SCALE):
			var x := start_x + offset_x
			var y := start_y + offset_y
			if x >= image.get_width() or y >= image.get_height():
				continue
			total_pixels += 1
			if image.get_pixel(x, y).a < COLLISION_ALPHA_THRESHOLD:
				transparent_pixels += 1
	return total_pixels > 0 and transparent_pixels * 2 >= total_pixels

func _average_axis(
	points: Array[Vector2i],
	filter_axis: String,
	filter_value: int,
	result_axis: String
) -> float:
	var total := 0
	var count := 0
	for point in points:
		var filter_coordinate := point.x if filter_axis == "x" else point.y
		if filter_coordinate != filter_value:
			continue
		total += point.x if result_axis == "x" else point.y
		count += 1
	if count == 0:
		return 0.0
	return float(total) / count

func _sample_to_world(sample_point: Vector2) -> Vector2:
	return (sample_point + Vector2(0.5, 0.5)) * FLOOD_SCALE

func _fallback_gate_point(direction: String) -> Vector2:
	if direction == "left":
		return Vector2(120, MAP_SIZE.y * 0.65)
	if direction == "right":
		return Vector2(MAP_SIZE.x - 120, MAP_SIZE.y * 0.65)
	if direction == "up":
		return Vector2(MAP_SIZE.x * 0.5, 360)
	return Vector2(MAP_SIZE.x * 0.5, MAP_SIZE.y - 40)

func _create_gate(
	direction: String,
	target_area: String,
	gate_point: Vector2,
	armed: bool
) -> void:
	var gate := Node2D.new()
	gate.name = "Gate_%s" % direction
	gate.position = gate_point
	add_child(gate)
	_gate_nodes.append(gate)

	var transition_band := Area2D.new()
	transition_band.name = "TransitionBand"
	_configure_gate_area(transition_band, TRANSITION_RADIUS)
	transition_band.monitoring = armed
	transition_band.monitorable = armed
	gate.add_child(transition_band)
	_gate_transition_areas[direction] = transition_band
	transition_band.body_entered.connect(
		_on_transition_body_entered.bind(direction, target_area)
	)

	var approach_zone := Area2D.new()
	approach_zone.name = "ApproachZone"
	_configure_gate_area(approach_zone, APPROACH_RADIUS)
	gate.add_child(approach_zone)

	var arrow := Label.new()
	arrow.name = "Arrow"
	arrow.text = _direction_arrow(direction) + "\n" + _area_label(target_area)
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.position = Vector2(-80, -30)
	arrow.size = Vector2(160, 58)
	arrow.visible = false
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.add_theme_color_override("font_color", Color.WHITE)
	arrow.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.12, 1))
	arrow.add_theme_constant_override("outline_size", 6)
	gate.add_child(arrow)

	approach_zone.body_entered.connect(
		_on_approach_entered.bind(arrow)
	)
	approach_zone.body_exited.connect(
		_on_approach_exited.bind(arrow, direction)
	)

func _configure_gate_area(area: Area2D, radius: float) -> void:
	area.collision_layer = 2
	area.collision_mask = 1
	var shape_node := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	shape_node.shape = shape
	area.add_child(shape_node)

func _arrival_position(direction: String, gate_point: Vector2) -> Vector2:
	if direction == "left":
		return gate_point + Vector2(ARRIVAL_INSET, 0)
	if direction == "right":
		return gate_point + Vector2(-ARRIVAL_INSET, 0)
	if direction == "up":
		return gate_point + Vector2(0, ARRIVAL_INSET)
	return gate_point + Vector2(0, -ARRIVAL_INSET)

func _direction_arrow(direction: String) -> String:
	if direction == "left":
		return "◀"
	if direction == "right":
		return "▶"
	if direction == "up":
		return "▲"
	return "▼"

func _area_label(area_id: String) -> String:
	if area_id == "chiefs_house":
		return "Chief's House"
	if area_id == "residential":
		return "Residential"
	if area_id == "outskirts":
		return "Outskirts"
	if area_id == "field":
		return "World Map"
	return area_id.capitalize()

func _on_approach_entered(body: Node2D, arrow: Label) -> void:
	if body is CharacterBody2D:
		arrow.visible = true

func _on_approach_exited(body: Node2D, arrow: Label, direction: String) -> void:
	if not body is CharacterBody2D:
		return
	arrow.visible = false
	if direction == _disarmed_direction:
		var transition_band: Area2D = _gate_transition_areas.get(direction)
		if transition_band:
			transition_band.monitoring = true
			transition_band.monitorable = true
		_disarmed_direction = ""

func _on_transition_body_entered(body: Node2D, direction: String, target_area: String) -> void:
	if not body is CharacterBody2D or _transitioning:
		return
	_transitioning = true
	if target_area == "field":
		GameData.current_town_area = "outskirts"
		GameData.current_town_arrival_edge = "down"
		field_requested.emit()
		return

	var arrival_edge := _opposite_direction(direction)
	GameData.current_town_area = target_area
	GameData.current_town_arrival_edge = arrival_edge
	call_deferred("load_area", target_area, arrival_edge)

func _opposite_direction(direction: String) -> String:
	if direction == "left":
		return "right"
	if direction == "right":
		return "left"
	if direction == "up":
		return "down"
	return "up"

func _clear_gates() -> void:
	for gate in _gate_nodes:
		if is_instance_valid(gate):
			gate.free()
	_gate_nodes.clear()
	_gate_transition_areas.clear()
