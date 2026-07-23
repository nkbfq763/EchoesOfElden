extends Control

const MENU_SCENE_PATH := "res://scenes/ui/MenuScreen.tscn"
const PORTRAIT_CONFIG_PATH := "res://data/portrait_config.json"
const MAX_PARTY_SIZE := 4

var portrait_config: Dictionary = {}
var play_time_seconds := 0.0

func _ready() -> void:
	add_to_group("menu_screen")
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().paused = true
	_load_portrait_config()
	_build_character_cards()
	_update_info_bar()

func _process(delta: float) -> void:
	play_time_seconds += delta
	_update_info_bar()

static func open(tree: SceneTree) -> void:
	if not tree.get_nodes_in_group("menu_screen").is_empty():
		return
	var scene := load(MENU_SCENE_PATH) as PackedScene
	if not scene:
		push_warning("Unable to load menu scene: %s" % MENU_SCENE_PATH)
		return
	var menu := scene.instantiate() as Control
	if menu:
		tree.root.add_child(menu)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu") or event.is_action_pressed("ui_cancel"):
		_close()

func _close() -> void:
	get_tree().paused = false
	queue_free()

func _load_portrait_config() -> void:
	if not FileAccess.file_exists(PORTRAIT_CONFIG_PATH):
		return
	var file := FileAccess.open(PORTRAIT_CONFIG_PATH, FileAccess.READ)
	if not file:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		portrait_config = parsed

func _build_character_cards() -> void:
	var party: Array[CharacterData] = []
	for member in GameData.party:
		if member:
			party.append(member)

	var cards := $CharacterCards.get_children()
	for index in cards.size():
		var card := cards[index] as VBoxContainer
		if not card:
			continue
		card.visible = index < mini(party.size(), MAX_PARTY_SIZE)
		if not card.visible:
			continue
		_populate_card(card, party[index])

func _populate_card(card: VBoxContainer, data: CharacterData) -> void:
	var portrait := card.get_node("Portrait") as TextureRect
	var config := _portrait_for_character(data)
	_configure_portrait(portrait, config)

	var max_hp := maxi(1, data.health)
	var current_hp := data.health if data.current_hp < 0 else clampi(data.current_hp, 0, max_hp)
	var max_tp := maxi(1, data.max_tp)
	var current_tp := data.max_tp if data.current_tp < 0 else clampi(data.current_tp, 0, max_tp)
	(card.get_node("NameLabel") as Label).text = data.character_name
	(card.get_node("LvLabel") as Label).text = "Lv 1"
	(card.get_node("HPLabel") as Label).text = "HP %d/%d" % [current_hp, max_hp]
	(card.get_node("TPLabel") as Label).text = "TP %d/%d" % [current_tp, max_tp]
	(card.get_node("ExpLabel") as Label).text = "Exp %d" % GameData.exp

func _portrait_for_character(data: CharacterData) -> Dictionary:
	var key := data.character_name.to_lower().replace(" ", "_")
	if portrait_config.has(key) and portrait_config[key] is Dictionary:
		return portrait_config[key]
	if portrait_config.is_empty():
		return {}
	var first_key: Variant = portrait_config.keys()[0]
	var fallback: Variant = portrait_config.get(first_key)
	return fallback if fallback is Dictionary else {}

func _configure_portrait(portrait: TextureRect, config: Dictionary) -> void:
	portrait.texture = null
	portrait.region_enabled = false
	if config.is_empty():
		return
	var texture := load(str(config.get("path", ""))) as Texture2D
	if not texture:
		return
	var region := Rect2(
		float(config.get("crop_x", 0)),
		float(config.get("crop_y", 0)),
		float(config.get("crop_w", texture.get_width())),
		float(config.get("crop_h", texture.get_height()))
	)
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = region
	portrait.texture = atlas
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.region_enabled = true
	portrait.region_rect = region
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.custom_minimum_size = Vector2(
		float(config.get("display_w", 90)),
		float(config.get("display_h", 180))
	)
	portrait.position = Vector2(
		float(config.get("offset_x", 0)),
		float(config.get("offset_y", 0))
	)

func _update_info_bar() -> void:
	if not is_node_ready():
		return
	$InfoBar/GaldLabel.text = "Gald: %d" % GameData.gald
	$InfoBar/PlayTimeLabel.text = "Time: %s" % _format_play_time()
	$InfoBar/HintLabel.text = "Esc/M: 閉じる"

func _format_play_time() -> String:
	var total_seconds := maxi(0, int(play_time_seconds))
	return "%02d:%02d" % [total_seconds / 60, total_seconds % 60]
