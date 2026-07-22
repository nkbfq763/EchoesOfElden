extends Node

var character_data: CharacterData
var party: Array[CharacterData] = []
var gald: int = 100
var progress_flags: Dictionary = {}
var current_town_area: String = "square"
var current_town_arrival_edge: String = ""
var battle_background: String = "res://assets/backgrounds/battle_bg_plains.png"
var pending_encounter: Array[EnemyData] = []
var pending_symbol_id: String = ""
var battle_won: bool = false
var defeated_symbol_id: String = ""

func set_character_data(data: CharacterData) -> void:
	character_data = data
	if party.is_empty():
		party.append(data)
	else:
		party[0] = data
	data.reset_for_battle()

func get_character_data() -> CharacterData:
	if character_data:
		return character_data
	if not party.is_empty():
		return party[0]
	return null

func set_encounter(enemies: Array[EnemyData], symbol_id: String) -> void:
	pending_encounter = enemies
	pending_symbol_id = symbol_id
	battle_won = false
	defeated_symbol_id = ""

func finish_battle(won: bool) -> void:
	battle_won = won
	if won:
		defeated_symbol_id = pending_symbol_id
	pending_encounter.clear()
