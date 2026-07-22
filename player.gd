extends CharacterBody2D

const SPRITE_SIZE := Vector2i(32, 48)

@export var character_data: CharacterData

var speed: float
var walk_speed: float
var animated_sprite: AnimatedSprite2D
var _facing := "down"

func _ready() -> void:
	animated_sprite = $AnimatedSprite2D
	
	if not character_data and GameData.get_character_data():
		character_data = GameData.get_character_data()
	if not character_data:
		character_data = load("res://data/hero.tres") as CharacterData
	
	if character_data:
		speed = character_data.speed
		walk_speed = speed * 0.5
		setup_sprite()
	else:
		speed = 150.0
		walk_speed = 75.0

func _physics_process(_delta: float) -> void:
	var direction := Vector2.ZERO
	
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("d"):
		direction.x += 1
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("a"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down") or Input.is_action_pressed("s"):
		direction.y += 1
	if Input.is_action_pressed("ui_up") or Input.is_action_pressed("w"):
		direction.y -= 1
	
	if direction != Vector2.ZERO:
		direction = direction.normalized()

		_update_facing(direction)

		var walking := Input.is_action_pressed("walk_mod")
		if direction.y > 0:
			_set_facing("down")
		elif direction.y < 0:
			_set_facing("up")
		_play_animation("walk_" + _facing)
		velocity = direction * (walk_speed if walking else speed)
	else:
		_play_animation("idle_" + _facing)
		velocity = Vector2.ZERO

	move_and_slide()

func _set_facing(facing: String) -> void:
	_facing = facing
	animated_sprite.flip_h = facing == "right"

func _update_facing(direction: Vector2) -> void:
	if absf(direction.x) >= absf(direction.y):
		_set_facing("right" if direction.x > 0 else "left")
	elif direction.y > 0:
		_set_facing("down")
	else:
		_set_facing("up")

func _play_animation(anim_name: String) -> void:
	if animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation(anim_name):
		if animated_sprite.animation != anim_name:
			animated_sprite.play(anim_name)

func setup_sprite() -> void:
	var sprite_texture := create_character_sprite(character_data.character_type)
	if not sprite_texture:
		return
	
	animated_sprite.sprite_frames = SpriteFrames.new()
	animated_sprite.offset = Vector2(0, -8)
	animated_sprite.speed_scale = 1.0
	
	for anim in ["idle_down", "idle_up", "idle_left", "idle_right",
			"walk_down", "walk_up", "walk_left", "walk_right"]:
		animated_sprite.sprite_frames.add_animation(anim)
		animated_sprite.sprite_frames.set_animation_speed(anim, 6.0)
		animated_sprite.sprite_frames.add_frame(anim, sprite_texture)
	
	animated_sprite.play("idle_down")

func create_character_sprite(character_type: String) -> Texture2D:
	var image := Image.create(SPRITE_SIZE.x, SPRITE_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	
	_draw_female_character(image, _get_palette(character_type), character_type)
	
	return ImageTexture.create_from_image(image)

func _get_palette(character_type: String) -> Dictionary:
	if character_type == "warrior":
		return {
			"hair": Color(0.55, 0.28, 0.18),
			"hair_hi": Color(0.72, 0.42, 0.25),
			"skin": Color(0.96, 0.78, 0.68),
			"skin_shadow": Color(0.82, 0.62, 0.52),
			"eye": Color(0.15, 0.12, 0.22),
			"cheek": Color(0.95, 0.55, 0.55, 0.6),
			"outfit": Color(0.82, 0.28, 0.38),
			"outfit_hi": Color(0.95, 0.45, 0.52),
			"outfit_shadow": Color(0.55, 0.18, 0.28),
			"accent": Color(0.85, 0.72, 0.35),
			"boots": Color(0.35, 0.22, 0.18),
		}
	return {
		"hair": Color(0.22, 0.18, 0.28),
		"hair_hi": Color(0.38, 0.32, 0.42),
		"skin": Color(0.96, 0.78, 0.68),
		"skin_shadow": Color(0.82, 0.62, 0.52),
		"eye": Color(0.15, 0.12, 0.22),
		"cheek": Color(0.95, 0.55, 0.55, 0.6),
		"outfit": Color(0.92, 0.92, 0.96),
		"outfit_hi": Color(1.0, 1.0, 1.0),
		"outfit_shadow": Color(0.68, 0.68, 0.78),
		"accent": Color(0.45, 0.55, 0.85),
		"boots": Color(0.28, 0.24, 0.32),
	}

func _draw_female_character(img: Image, p: Dictionary, character_type: String) -> void:
	# ロングヘア（サイドに流れる女性らしいシルエット）
	_fill_rect(img, 10, 4, 12, 3, p.hair)
	_fill_rect(img, 9, 7, 14, 4, p.hair)
	_setMainChara(img, 9, 6, p.hair_hi)
	_setMainChara(img, 22, 6, p.hair_hi)
	_fill_rect(img, 8, 11, 3, 14, p.hair)
	_fill_rect(img, 21, 11, 3, 14, p.hair)
	_setMainChara(img, 8, 18, p.hair_hi)
	_setMainChara(img, 23, 20, p.hair_hi)
	# 後ろ髪
	_fill_rect(img, 11, 10, 10, 3, p.hair)
	
	# 顔（小さめ・丸顔）
	_fill_rect(img, 12, 9, 8, 7, p.skin)
	_setMainChara(img, 12, 15, p.skin_shadow)
	_setMainChara(img, 19, 15, p.skin_shadow)
	# 目（やや大きめ・まつげ風）
	_setMainChara(img, 13, 12, p.eye)
	_setMainChara(img, 14, 12, p.eye)
	_setMainChara(img, 17, 12, p.eye)
	_setMainChara(img, 18, 12, p.eye)
	_setMainChara(img, 13, 11, p.hair)
	_setMainChara(img, 18, 11, p.hair)
	# ほっぺ
	_setMainChara(img, 12, 14, p.cheek)
	_setMainChara(img, 19, 14, p.cheek)
	# 口
	_setMainChara(img, 15, 15, Color(0.85, 0.45, 0.48))
	_setMainChara(img, 16, 15, Color(0.85, 0.45, 0.48))
	
	# 首
	_fill_rect(img, 14, 16, 4, 2, p.skin)
	
	# 上半身（細身・女性の肩幅）
	_fill_rect(img, 13, 18, 6, 2, p.outfit_hi)
	_fill_rect(img, 12, 20, 8, 4, p.outfit)
	_setMainChara(img, 11, 20, p.outfit_shadow)
	_setMainChara(img, 20, 20, p.outfit_shadow)
	# ウエスト（くびれ）
	_fill_rect(img, 14, 24, 4, 2, p.outfit)
	_setMainChara(img, 13, 25, p.outfit_shadow)
	_setMainChara(img, 18, 25, p.outfit_shadow)
	
	# スカート（広がり）
	_fill_rect(img, 12, 26, 8, 2, p.outfit)
	_fill_rect(img, 11, 28, 10, 3, p.outfit)
	_fill_rect(img, 10, 31, 12, 3, p.outfit)
	_fill_rect(img, 10, 34, 12, 2, p.outfit_shadow)
	_setMainChara(img, 10, 33, p.outfit_shadow)
	_setMainChara(img, 21, 33, p.outfit_shadow)
	
	# アクセント（戦士=帯と剣、僧侶=十字架）
	if character_type == "warrior":
		_fill_rect(img, 13, 22, 6, 1, p.accent)
		_setMainChara(img, 22, 21, p.accent)
		_setMainChara(img, 23, 22, p.accent)
	else:
		_fill_rect(img, 15, 19, 2, 4, p.accent)
		_setMainChara(img, 14, 20, p.accent)
		_setMainChara(img, 17, 20, p.accent)
	
	# 足（スカート下）
	_setMainChara(img, 14, 36, p.skin)
	_setMainChara(img, 17, 36, p.skin)
	_setMainChara(img, 13, 37, p.boots)
	_setMainChara(img, 16, 37, p.boots)
	_setMainChara(img, 13, 38, p.boots)
	_setMainChara(img, 16, 38, p.boots)

func _setMainChara(img: Image, x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= SPRITE_SIZE.x or y >= SPRITE_SIZE.y:
		return
	img.set_pixel(x, y, color)

func _fill_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for px in range(x, x + w):
		for py in range(y, y + h):
			_setMainChara(img, px, py, color)
