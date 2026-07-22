extends Node2D
class_name BattleUnit

signal attack_window(attacker: BattleUnit)
signal state_changed(unit: BattleUnit, new_state: State)

enum State {
	IDLE,
	MOVE,
	JUMP,
	ATTACK1,
	ATTACK2,
	ATTACK3,
	GUARD,
	STEP,
	HURT,
	DOWN,
	KO,
}

const ATTACK_DURATION := 0.42
const ATTACK_ACTIVE_START := 0.16
const ATTACK_ACTIVE_END := 0.29
const STEP_DURATION := 0.18
const HURT_DURATION := 0.22
const JUMP_SPEED := -245.0
const GRAVITY := 720.0

var unit_data: Resource
var is_enemy := false
var state: State = State.IDLE
var move_intent := 0.0
var guard_requested := false
var state_time := 0.0
var attack_stage := 0
var attack_queued := false
var attack_active_emitted := false
var attack_hit_targets: Array[BattleUnit] = []
var vertical_velocity := 0.0
var ground_y := 270.0
var facing_right := true
var target: BattleUnit
var telegraphing := false
var current_hp := 1
var max_hp := 1
var sprite: AnimatedSprite2D
var enemy_color := Color(0.25, 0.8, 0.45)

func configure(data: Resource, enemy: bool, start_position: Vector2) -> void:
	unit_data = data
	is_enemy = enemy
	position = start_position
	ground_y = start_position.y
	max_hp = int(data.get("health") if not enemy else data.get("max_hp"))
	current_hp = max_hp
	if not enemy and int(data.get("current_hp")) > 0:
		current_hp = int(data.get("current_hp"))
	if is_enemy:
		var enemy_name := str(data.get("enemy_name"))
		enemy_color = Color(0.8, 0.32, 0.25) if enemy_name == "Goblin" else Color(0.2, 0.78, 0.45)
	else:
		_create_hero_sprite()
	queue_redraw()

func _create_hero_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.name = "BattleSprite"
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.sprite_frames = load("res://assets/characters/hero/hero_battle.tres")
	sprite.position = Vector2(0, -32)
	add_child(sprite)

func _physics_process(delta: float) -> void:
	if state == State.KO:
		queue_redraw()
		return
	state_time += delta
	match state:
		State.IDLE, State.MOVE:
			_process_ground_movement(delta)
			if guard_requested and state == State.IDLE:
				_set_state(State.GUARD)
		State.GUARD:
			if guard_requested:
				_process_ground_movement(delta, false)
			else:
				_set_state(State.IDLE)
		State.JUMP:
			_process_jump(delta)
		State.ATTACK1, State.ATTACK2, State.ATTACK3:
			_process_attack()
		State.STEP:
			_process_step(delta)
		State.HURT:
			if state_time >= HURT_DURATION:
				_set_state(State.IDLE)
		State.DOWN:
			if state_time >= 0.45:
				_set_state(State.KO)
	update_visual()
	queue_redraw()

func _process_ground_movement(_delta: float, allow_move := true) -> void:
	if allow_move and absf(move_intent) > 0.01:
		position.x = clampf(position.x + move_intent * get_move_speed() * get_physics_process_delta_time(), 45.0, 595.0)
		facing_right = move_intent > 0.0
		if state == State.IDLE:
			_set_state(State.MOVE)
	elif state == State.MOVE:
		_set_state(State.IDLE)

func _process_jump(delta: float) -> void:
	position.y += vertical_velocity * delta
	vertical_velocity += GRAVITY * delta
	if position.y >= ground_y:
		position.y = ground_y
		vertical_velocity = 0.0
		_set_state(State.IDLE)

func _process_attack() -> void:
	if not attack_active_emitted and state_time >= ATTACK_ACTIVE_START:
		attack_active_emitted = true
		attack_window.emit(self)
	if state_time >= ATTACK_ACTIVE_END:
		attack_active_emitted = true
	if state_time < ATTACK_DURATION:
		return
	if attack_queued and attack_stage < 3:
		_start_attack(attack_stage + 1)
	else:
		_set_state(State.IDLE)

func _process_step(delta: float) -> void:
	var direction := move_intent
	if absf(direction) < 0.01:
		direction = 1.0 if facing_right else -1.0
	position.x = clampf(position.x + direction * 300.0 * delta, 45.0, 595.0)
	if state_time >= STEP_DURATION:
		_set_state(State.IDLE)

func request_move(direction: float) -> void:
	if state in [State.KO, State.DOWN, State.HURT, State.ATTACK1, State.ATTACK2, State.ATTACK3, State.STEP]:
		return
	move_intent = clampf(direction, -1.0, 1.0)
	if absf(move_intent) > 0.01:
		facing_right = move_intent > 0.0

func request_jump() -> void:
	if state in [State.KO, State.DOWN, State.HURT, State.JUMP, State.ATTACK1, State.ATTACK2, State.ATTACK3, State.STEP]:
		return
	vertical_velocity = JUMP_SPEED
	_set_state(State.JUMP)

func request_attack() -> void:
	if state in [State.KO, State.DOWN, State.HURT, State.JUMP, State.STEP, State.GUARD]:
		return
	if state in [State.ATTACK1, State.ATTACK2, State.ATTACK3]:
		if attack_stage < 3 and state_time >= 0.2:
			attack_queued = true
		return
	_start_attack(1)

func request_guard(held: bool) -> void:
	guard_requested = held
	if held and state in [State.IDLE, State.MOVE] and absf(move_intent) < 0.01:
		_set_state(State.GUARD)
	elif not held and state == State.GUARD:
		_set_state(State.IDLE)

func request_step() -> void:
	if state in [State.KO, State.DOWN, State.HURT]:
		return
	attack_queued = false
	_set_state(State.STEP)

func receive_damage(amount: int) -> void:
	current_hp = maxi(0, current_hp - amount)
	telegraphing = false
	if current_hp == 0:
		_set_state(State.DOWN)
	else:
		_set_state(State.HURT)

func face_target(new_target: BattleUnit) -> void:
	target = new_target
	if target:
		facing_right = target.position.x >= position.x

func is_guarding() -> bool:
	return state == State.GUARD

func get_attack() -> int:
	return int(unit_data.get("attack"))

func get_defense() -> int:
	return int(unit_data.get("defense"))

func get_move_speed() -> float:
	if is_enemy:
		return float(unit_data.get("move_speed"))
	return float(unit_data.get("speed"))

func get_attack_power() -> float:
	return 1.0

func _start_attack(stage: int) -> void:
	attack_stage = stage
	attack_queued = false
	attack_active_emitted = false
	attack_hit_targets.clear()
	state_time = 0.0
	_set_state(State.ATTACK1 + stage - 1)

func _set_state(new_state: State) -> void:
	if state == new_state:
		state_time = 0.0
		return
	state = new_state
	state_time = 0.0
	if new_state != State.HURT:
		telegraphing = false
	state_changed.emit(self, new_state)

func update_visual() -> void:
	if not sprite:
		return
	sprite.flip_h = not facing_right
	if state == State.GUARD:
		if sprite.animation != "cast":
			sprite.play("cast")
		sprite.frame = 0
		sprite.pause()
		return
	var animation := "idle"
	match state:
		State.MOVE:
			animation = "walk"
		State.JUMP:
			animation = "walk"
		State.ATTACK1:
			animation = "attack1"
		State.ATTACK2:
			animation = "attack2"
		State.ATTACK3:
			animation = "attack3"
		State.HURT:
			animation = "hurt"
		State.DOWN, State.KO:
			animation = "down"
	if sprite.animation != animation:
		sprite.play(animation)

func _draw() -> void:
	if not is_enemy:
		return
	var body_color := Color(1.0, 0.85, 0.25) if telegraphing else enemy_color
	draw_rect(Rect2(-30, -64, 60, 64), body_color)
	draw_rect(Rect2(-22, -54, 10, 10), Color.WHITE)
	draw_rect(Rect2(12, -54, 10, 10), Color.WHITE)
	draw_rect(Rect2(-19, -51, 4, 4), Color(0.1, 0.1, 0.1))
	draw_rect(Rect2(15, -51, 4, 4), Color(0.1, 0.1, 0.1))
	draw_rect(Rect2(-32, -76, 64, 6), Color(0.08, 0.08, 0.08))
	draw_rect(Rect2(-32, -76, 64.0 * float(current_hp) / max_hp, 6), Color(0.25, 0.9, 0.3))
	if telegraphing:
		draw_circle(Vector2(0, -84), 7.0 + sin(state_time * 24.0) * 2.0, Color(1.0, 0.35, 0.15, 0.85))
