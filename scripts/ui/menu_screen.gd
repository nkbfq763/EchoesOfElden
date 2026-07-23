extends Control

const MENU_SCENE_PATH := "res://scenes/ui/MenuScreen.tscn"
const PORTRAIT_CONFIG_PATH := "res://data/portrait_config.json"
const MAX_PARTY_SIZE := 4

const TAB_NAMES: Array[String] = [
	"術・技", "装備", "術式", "作戦", "アイテム", "称号", "ライブラリ", "システム"
]
const SELECTED_TAB_NAME := "ビジュアル"

var portrait_config: Dictionary = {}
var play_time_seconds := 0.0

func _ready() -> void:
	add_to_group("menu_screen")
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().paused = true
	_load_portrait_config()
	_style_icon_bar()
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
	if not menu:
		return
	var layer := CanvasLayer.new()
	layer.layer = 128
	layer.add_child(menu)
	tree.root.add_child(layer)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu") or event.is_action_pressed("ui_cancel"):
		_close()

func _close() -> void:
	get_tree().paused = false
	var host := get_parent()
	if host is CanvasLayer:
		host.queue_free()
	else:
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

func _style_icon_bar() -> void:
	var icon_bar := $IconBar as HBoxContainer
	if not icon_bar:
		return
	var normal_style := _make_panel_style(
		Color(0.10, 0.13, 0.20, 0.95), Color(0.35, 0.42, 0.58, 1.0), 1, 4
	)
	for index in icon_bar.get_child_count():
		var button := icon_bar.get_child(index) as Button
		if not button:
			continue
		if index < TAB_NAMES.size():
			button.text = TAB_NAMES[index]
		button.add_theme_stylebox_override("normal", normal_style)
		button.add_theme_stylebox_override("hover", normal_style)
		button.add_theme_stylebox_override("pressed", normal_style)
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		button.add_theme_font_size_override("font_size", 10)
		button.add_theme_color_override("font_color", Color(0.82, 0.87, 0.96, 1.0))
	var selected_label := $SelectedTabLabel as Label
	if selected_label:
		selected_label.text = SELECTED_TAB_NAME

func _build_character_cards() -> void:
	var party: Array[CharacterData] = []
	for member in GameData.party:
		if member:
			party.append(member)

	var cards := $CharacterCards.get_children()
	for index in cards.size():
		var card := cards[index] as Control
		if not card:
			continue
		card.visible = index < mini(party.size(), MAX_PARTY_SIZE)
		if not card.visible:
			continue
		_populate_card(card, party[index])

func _populate_card(card: Control, data: CharacterData) -> void:
	var portrait := card.get_node("Portrait") as TextureRect
	var config := _portrait_for_character(data)
	_configure_portrait(portrait, config)

	var max_hp := maxi(1, data.health)
	var current_hp := data.health if data.current_hp < 0 else clampi(data.current_hp, 0, max_hp)
	var max_tp := maxi(1, data.max_tp)
	var current_tp := data.max_tp if data.current_tp < 0 else clampi(data.current_tp, 0, max_tp)
	(card.get_node("NameLabel") as Label).text = data.character_name
	(card.get_node("LvBadge") as Label).text = "Lv 1"
	(card.get_node("HPLabel") as Label).text = "%d/%d" % [current_hp, max_hp]
	(card.get_node("TPLabel") as Label).text = "TP %d" % current_tp

	var hp_bar := card.get_node("HPBar") as ProgressBar
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp
		_style_hp_bar(hp_bar)

func _style_hp_bar(hp_bar: ProgressBar) -> void:
	var bg_style := _make_panel_style(Color(0.06, 0.06, 0.10, 1.0), Color(0.20, 0.22, 0.30, 1.0), 1, 1)
	var fill_style := _make_panel_style(Color(0.82, 0.62, 0.18, 1.0), Color(0.95, 0.80, 0.40, 1.0), 1, 1)
	hp_bar.add_theme_stylebox_override("background", bg_style)
	hp_bar.add_theme_stylebox_override("fill", fill_style)

func _make_panel_style(bg_color: Color, border_color: Color, border_width: int, corner_radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(corner_radius)
	return style

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
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

func _update_info_bar() -> void:
	if not is_node_ready():
		return
	$InfoBar/GaldLabel.text = "GALD  %d" % GameData.gald
	$InfoBar/PlayTimeLabel.text = "PLAYTIME  %s" % _format_play_time()
	$InfoBar/HintLabel.text = "Esc/M: 閉じる"

func _format_play_time() -> String:
	var total_seconds := maxi(0, int(play_time_seconds))
	var hours := total_seconds / 3600
	var minutes := (total_seconds % 3600) / 60
	var seconds := total_seconds % 60
	return "%03d:%02d:%02d" % [hours, minutes, seconds]