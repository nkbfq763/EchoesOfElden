extends Node2D

enum BattleState { ACTIVE, RESULT }
enum EnemyAIState { APPROACH, TELEGRAPH, ATTACK, RECOVER, REPOSITION }

const MELEE_RANGE := 78.0
const HEIGHT_RANGE := 30.0
const COMBO_TIMEOUT := 1.25

var state := BattleState.ACTIVE
var hero: BattleUnit
var hero_data: CharacterData
var enemies: Array[BattleUnit] = []
var enemy_ai: Dictionary = {}
var active_target: BattleUnit
var target_index := 0
var combo_hits := 0
var combo_timer := 0.0
var guard_regen_timer := 0.0
var result_label: Label
var combo_label: Label
var status_label: Label

func _ready() -> void:
	_set_battle_background(GameData.battle_background)
	hero_data = GameData.get_character_data()
	if not hero_data:
		hero_data = load("res://data/hero.tres")
		GameData.set_character_data(hero_data)
	hero_data.reset_for_battle()
	_create_hero()
	var encounter := GameData.pending_encounter.duplicate()
	if encounter.is_empty():
		encounter = [load("res://data/slime.tres")]
	for index in encounter.size():
		_create_enemy(encounter[index], index)
	active_target = enemies[0] if not enemies.is_empty() else null
	result_label = $Result
	combo_label = $Combo
	status_label = $Status
	_update_target_marker()
	_refresh_ui()

func _set_battle_background(path: String) -> void:
	var texture := load(path) as Texture2D
	if not texture:
		texture = load("res://assets/backgrounds/battle_bg_plains.png") as Texture2D
	$Background.texture = texture

func _unhandled_input(event: InputEvent) -> void:
	if state == BattleState.RESULT:
		if event.is_action_pressed("ui_accept"):
			_return_from_battle()
		return
	if event.is_action_pressed("attack"):
		hero.request_attack()
	elif event.is_action_pressed("jump"):
		hero.request_jump()
	elif event.is_action_pressed("step"):
		hero.request_step()
	elif event.is_action_pressed("target_next"):
		_switch_target()

func _physics_process(delta: float) -> void:
	if state == BattleState.RESULT:
		return
	hero.request_move(Input.get_axis("ui_left", "ui_right"))
	hero.request_guard(Input.is_action_pressed("guard"))
	if hero.is_guarding():
		guard_regen_timer -= delta
		if guard_regen_timer <= 0.0:
			hero_data.current_tp = mini(hero_data.max_tp, hero_data.current_tp + 1)
			guard_regen_timer = 0.25
	else:
		guard_regen_timer = 0.0
	_process_enemy_ai(delta)
	_update_facing()
	_update_combo(delta)
	_sync_hero_resource()
	_update_target_marker()
	_refresh_ui()
	_check_battle_result()

func _create_hero() -> void:
	hero = BattleUnit.new()
	hero.name = "Hero"
	add_child(hero)
	hero.configure(hero_data, false, Vector2(155, 270))
	hero.attack_window.connect(_on_attack_window)
	hero.state_changed.connect(_on_unit_state_changed)

func _create_enemy(data: EnemyData, index: int) -> void:
	var enemy := BattleUnit.new()
	enemy.name = "Enemy%d" % (index + 1)
	add_child(enemy)
	enemy.configure(data, true, Vector2(420 + index * 70, 270))
	enemy.attack_window.connect(_on_attack_window)
	enemy.state_changed.connect(_on_unit_state_changed)
	enemies.append(enemy)
	enemy_ai[enemy] = {
		"state": EnemyAIState.APPROACH,
		"timer": 0.15 * index,
	}

func _process_enemy_ai(delta: float) -> void:
	for enemy in enemies:
		if enemy.current_hp <= 0:
			enemy.request_move(0.0)
			continue
		var data: EnemyData = enemy.unit_data
		var record: Dictionary = enemy_ai[enemy]
		var distance := absf(hero.position.x - enemy.position.x)
		match int(record["state"]):
			EnemyAIState.APPROACH:
				enemy.telegraphing = false
				if distance > MELEE_RANGE:
					enemy.request_move(signf(hero.position.x - enemy.position.x))
				else:
					enemy.request_move(0.0)
					enemy.telegraphing = true
					record["state"] = EnemyAIState.TELEGRAPH
					record["timer"] = 0.32 / maxf(0.1, data.aggression)
			EnemyAIState.TELEGRAPH:
				enemy.request_move(0.0)
				enemy.telegraphing = true
				record["timer"] = float(record["timer"]) - delta
				if float(record["timer"]) <= 0.0:
					enemy.telegraphing = false
					enemy.request_attack()
					record["state"] = EnemyAIState.ATTACK
			EnemyAIState.ATTACK:
				enemy.request_move(0.0)
				if enemy.state not in [BattleUnit.State.ATTACK1, BattleUnit.State.ATTACK2, BattleUnit.State.ATTACK3]:
					record["state"] = EnemyAIState.RECOVER
					record["timer"] = 0.35
			EnemyAIState.RECOVER:
				enemy.request_move(0.0)
				record["timer"] = float(record["timer"]) - delta
				if float(record["timer"]) <= 0.0:
					record["state"] = EnemyAIState.REPOSITION
					record["timer"] = data.attack_interval / maxf(0.1, data.aggression)
			EnemyAIState.REPOSITION:
				enemy.request_move(signf(hero.position.x - enemy.position.x))
				record["timer"] = float(record["timer"]) - delta
				if float(record["timer"]) <= 0.0:
					record["state"] = EnemyAIState.APPROACH
		enemy.face_target(hero)

func _on_attack_window(attacker: BattleUnit) -> void:
	var defender := active_target if attacker == hero else hero
	if not defender or defender.current_hp <= 0:
		return
	if attacker.attack_hit_targets.has(defender):
		return
	if not _is_melee_hit(attacker, defender):
		return
	attacker.attack_hit_targets.append(defender)
	var damage := _calculate_damage(attacker, defender)
	if defender == hero and hero.is_guarding() and _is_front_hit(defender, attacker):
		damage = maxi(1, int(round(damage * 0.3)))
		hero_data.current_tp = mini(hero_data.max_tp, hero_data.current_tp + 2)
	defender.receive_damage(damage)
	if attacker == hero:
		hero_data.current_tp = mini(hero_data.max_tp, hero_data.current_tp + 2)
	combo_hits += 1
	combo_timer = COMBO_TIMEOUT
	status_label.text = "%s hit for %d damage!" % [attacker.name, damage]
	_refresh_ui()

func _calculate_damage(attacker: BattleUnit, defender: BattleUnit) -> int:
	var raw := float(attacker.get_attack()) * attacker.get_attack_power() - float(defender.get_defense())
	var combo_multiplier := 1.0 + minf(combo_hits * 0.01, 0.3)
	var damage := maxf(1.0, raw * combo_multiplier)
	return maxi(1, int(floor(damage * randf_range(0.95, 1.05))))

func _is_melee_hit(attacker: BattleUnit, defender: BattleUnit) -> bool:
	if absf(attacker.position.x - defender.position.x) > MELEE_RANGE:
		return false
	if absf(attacker.position.y - defender.position.y) > HEIGHT_RANGE:
		return false
	return _is_front_hit(attacker, defender)

func _is_front_hit(attacker: BattleUnit, defender: BattleUnit) -> bool:
	var direction := 1.0 if attacker.facing_right else -1.0
	return (defender.position.x - attacker.position.x) * direction >= -8.0

func _switch_target() -> void:
	if enemies.is_empty():
		return
	var alive: Array[BattleUnit] = enemies.filter(func(enemy: BattleUnit) -> bool: return enemy.current_hp > 0)
	if alive.is_empty():
		return
	target_index = (target_index + 1) % alive.size()
	active_target = alive[target_index]
	_update_target_marker()

func _update_facing() -> void:
	if active_target and active_target.current_hp > 0:
		hero.face_target(active_target)
	for enemy in enemies:
		if enemy.current_hp > 0:
			enemy.face_target(hero)

func _update_combo(delta: float) -> void:
	if combo_hits == 0:
		return
	combo_timer -= delta
	if combo_timer <= 0.0:
		combo_hits = 0

func _sync_hero_resource() -> void:
	hero_data.current_hp = hero.current_hp

func _update_target_marker() -> void:
	if not active_target:
		$TargetMarker.visible = false
		return
	$TargetMarker.visible = active_target.current_hp > 0
	$TargetMarker.position = active_target.position + Vector2(-10, -96)

func _refresh_ui() -> void:
	combo_label.text = "%d HIT" % combo_hits if combo_hits > 0 else ""
	for index in enemies.size():
		var enemy := enemies[index]
		var label: Label = $EnemyList.get_child(index)
		label.text = "%s  HP %d/%d" % [enemy.unit_data.get("enemy_name"), enemy.current_hp, enemy.max_hp]

func _check_battle_result() -> void:
	if hero.current_hp <= 0:
		state = BattleState.RESULT
		GameData.finish_battle(false)
		result_label.text = "Defeat\nPress Enter to return to title"
		status_label.text = "Roland was defeated."
		return
	for enemy in enemies:
		if enemy.current_hp > 0:
			return
	state = BattleState.RESULT
	var reward := 0
	for enemy in enemies:
		reward += int(enemy.unit_data.get("gald"))
	GameData.gald += reward
	GameData.finish_battle(true)
	result_label.text = "Victory!  +%d Gald\nPress Enter to return" % reward
	status_label.text = "All enemies defeated."

func _return_from_battle() -> void:
	if GameData.battle_won:
		get_tree().change_scene_to_file("res://field.tscn")
	else:
		get_tree().change_scene_to_file("res://title.tscn")

func _on_unit_state_changed(unit: BattleUnit, new_state: BattleUnit.State) -> void:
	if unit == hero and new_state == BattleUnit.State.HURT:
		status_label.text = "Roland is staggered!"
