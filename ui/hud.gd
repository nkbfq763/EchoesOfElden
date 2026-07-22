extends CanvasLayer

@export var battle_mode := false

var character: CharacterData
var panel: PanelContainer
var entries: VBoxContainer
var gald_label: Label
var entry_controls: Array[Dictionary] = []
var party_size := 0

func _ready() -> void:
	panel = $Panel
	entries = $Panel/Content/Entries
	gald_label = $Panel/Content/Gald
	character = GameData.get_character_data()
	_configure_layout()
	_rebuild_entries()

func set_character(data: CharacterData) -> void:
	character = data
	_rebuild_entries()

func _process(_delta: float) -> void:
	if _current_party().size() != party_size:
		_rebuild_entries()
	_refresh()

func _current_party() -> Array[CharacterData]:
	var party: Array[CharacterData] = []
	for data in GameData.party:
		party.append(data)
	if party.is_empty() and character:
		party.append(character)
	return party

func _configure_layout() -> void:
	if battle_mode:
		panel.position = Vector2(12, 218)
	else:
		panel.position = Vector2(12, 12)
	panel.size = Vector2(233, 130)

func _rebuild_entries() -> void:
	for child in entries.get_children():
		child.free()
	entry_controls.clear()
	var party := _current_party()
	party_size = party.size()
	panel.size.y = maxf(130.0, 42.0 + party_size * 76.0)
	if battle_mode:
		panel.position.y = 360.0 - panel.size.y - 12.0
	for data in party:
		data.reset_for_battle()
		var frame := PanelContainer.new()
		frame.custom_minimum_size = Vector2(215, 72)
		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 1)
		frame.add_child(content)
		var name_label := Label.new()
		name_label.text = data.character_name
		content.add_child(name_label)
		var hp_bar := ProgressBar.new()
		hp_bar.custom_minimum_size = Vector2(195, 16)
		hp_bar.show_percentage = false
		content.add_child(hp_bar)
		var hp_label := Label.new()
		content.add_child(hp_label)
		var tp_bar := ProgressBar.new()
		tp_bar.custom_minimum_size = Vector2(195, 16)
		tp_bar.show_percentage = false
		content.add_child(tp_bar)
		var tp_label := Label.new()
		content.add_child(tp_label)
		entries.add_child(frame)
		entry_controls.append({
			"data": data,
			"hp_bar": hp_bar,
			"hp_label": hp_label,
			"tp_bar": tp_bar,
			"tp_label": tp_label,
		})
	_refresh()

func _refresh() -> void:
	for controls in entry_controls:
		var data: CharacterData = controls["data"]
		var hp_bar: ProgressBar = controls["hp_bar"]
		var tp_bar: ProgressBar = controls["tp_bar"]
		hp_bar.max_value = data.health
		hp_bar.value = data.current_hp
		tp_bar.max_value = data.max_tp
		tp_bar.value = data.current_tp
		controls["hp_label"].text = "HP %d/%d" % [data.current_hp, data.health]
		controls["tp_label"].text = "TP %d/%d" % [data.current_tp, data.max_tp]
	gald_label.text = "Gald: %d" % GameData.gald
