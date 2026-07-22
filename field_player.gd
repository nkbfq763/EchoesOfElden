extends CharacterBody2D

const CHARACTER_ANIMATION_BASES: Dictionary = {
	"roland_hartwell": "res://assets/characters/party/roland_hartwell/field/animations",
}
const DIRECTIONS := [
	"north",
	"north-east",
	"east",
	"south-east",
	"south",
	"south-west",
	"west",
	"north-west",
]
const OCTANT_DIRECTIONS := [
	"east",
	"south-east",
	"south",
	"south-west",
	"west",
	"north-west",
	"north",
	"north-east",
]
const RUN_FPS := 10.0
const WALK_SPEED_FACTOR := 0.5
const RUN_ANIMATION_SPEED_SCALE := 1.5
const WALK_ANIMATION_SPEED_SCALE := 1.0

@export var character_id := "roland_hartwell"
@export var character_data: Resource

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var facing := "south"
var run_speed := 150.0

func _ready() -> void:
	run_speed = _resolve_speed()
	animated_sprite.sprite_frames = _build_sprite_frames()
	animated_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	animated_sprite.scale = Vector2(0.4, 0.4)
	animated_sprite.offset = Vector2(0.0, -62.0)
	_play_idle()

func _physics_process(_delta: float) -> void:
	var input_direction := _read_input_direction()
	var is_moving := input_direction.length_squared() > 0.0
	if is_moving:
		facing = get_facing_for_vector(input_direction)
		var walking := Input.is_action_pressed("walk_mod")
		var movement_speed := run_speed
		if walking:
			movement_speed *= WALK_SPEED_FACTOR
		velocity = input_direction * movement_speed
		animated_sprite.speed_scale = (
			WALK_ANIMATION_SPEED_SCALE if walking else RUN_ANIMATION_SPEED_SCALE
		)
		animated_sprite.play("run_%s" % facing)
	else:
		velocity = Vector2.ZERO
		_play_idle()
	move_and_slide()

func get_facing_for_vector(direction: Vector2) -> String:
	if direction.length_squared() <= 0.0:
		return facing
	var angle := direction.angle()
	var octant := posmod(roundi(angle / (PI / 4.0)), 8)
	return OCTANT_DIRECTIONS[octant]

func stop_movement() -> void:
	velocity = Vector2.ZERO
	_play_idle()

func _read_input_direction() -> Vector2:
	var horizontal := 0.0
	var vertical := 0.0
	if Input.is_action_pressed("ui_left"):
		horizontal -= 1.0
	if Input.is_action_pressed("ui_right"):
		horizontal += 1.0
	if Input.is_action_pressed("a"):
		horizontal -= 1.0
	if Input.is_action_pressed("d"):
		horizontal += 1.0
	if Input.is_action_pressed("ui_up"):
		vertical -= 1.0
	if Input.is_action_pressed("ui_down"):
		vertical += 1.0
	if Input.is_action_pressed("w"):
		vertical -= 1.0
	if Input.is_action_pressed("s"):
		vertical += 1.0
	return Vector2(clampf(horizontal, -1.0, 1.0), clampf(vertical, -1.0, 1.0)).normalized()

func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	for direction in DIRECTIONS:
		var run_animation := "run_%s" % direction
		frames.add_animation(run_animation)
		frames.set_animation_loop(run_animation, true)
		frames.set_animation_speed(run_animation, RUN_FPS)
		for texture in _load_run_frames(direction):
			frames.add_frame(run_animation, texture)

		var idle_animation := "idle_%s" % direction
		frames.add_animation(idle_animation)
		frames.set_animation_loop(idle_animation, false)
		frames.set_animation_speed(idle_animation, 1.0)
		var idle_texture := _load_texture(_animation_base_path() + "/idle/%s.png" % direction)
		if idle_texture:
			frames.add_frame(idle_animation, idle_texture)
	return frames

func _load_run_frames(direction: String) -> Array[Texture2D]:
	var result: Array[Texture2D] = []
	var directory := DirAccess.open(_animation_base_path() + "/Run/%s" % direction)
	if not directory:
		return result
	var file_names := directory.get_files()
	file_names.sort()
	for file_name in file_names:
		if not file_name.begins_with("frame_") or not file_name.ends_with(".png"):
			continue
		var texture := _load_texture(
			_animation_base_path() + "/Run/%s/%s" % [direction, file_name]
		)
		if texture:
			result.append(texture)
	return result

func _load_texture(path: String) -> Texture2D:
	return load(path) as Texture2D

func _animation_base_path() -> String:
	return str(CHARACTER_ANIMATION_BASES.get(character_id, ""))

func _resolve_speed() -> float:
	if character_data:
		var configured_speed: Variant = character_data.get("speed")
		if configured_speed is float or configured_speed is int:
			return float(configured_speed)
	if has_node("/root/GameData"):
		var game_data := get_node("/root/GameData")
		if game_data.has_method("get_character_data"):
			var data: Resource = game_data.get_character_data()
			if data:
				var game_speed: Variant = data.get("speed")
				if game_speed is float or game_speed is int:
					return float(game_speed)
	return 150.0

func _play_idle() -> void:
	animated_sprite.speed_scale = 1.0
	animated_sprite.play("idle_%s" % facing)
