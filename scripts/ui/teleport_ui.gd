class_name TeleportUI
extends CanvasLayer
## Debug (F6): Liste wichtiger Orte zum Hinspringen. Pausiert das Spiel, solange das Fenster
## offen ist. Auswahl per Maus oder Zifferntasten 1–9, Esc oder F6 schließt.
## Neue Orte: in `_destinations()` einen Eintrag ergänzen.

## [Name, Standpunkt, Blickrichtung]
var _targets: Array = []
var _options: GridContainer


func setup(builder: LevelBuilder) -> void:
	_targets = _destinations(builder)


func _destinations(b: LevelBuilder) -> Array:
	var cellar := Vector3(LevelBuilder.STAIR_BOTTOM + LevelBuilder.CELLAR_LEN / 2.0, LevelBuilder.CELLAR_Y, 0.3)
	return [
		_room(b, "13", "Zimmer 13 (eigenes)"),
		["Lobby", b.lobby_center, Vector3.LEFT],
		_room(b, LevelBuilder.COMPASS_ROOM, "Zimmer %s (Kompass)" % LevelBuilder.COMPASS_ROOM),
		["Bar", Vector3(-3.0, 0, 8.2), Vector3.BACK],
		["Küche", Vector3(-10.0, 0, 8.0), Vector3.BACK],
		["Garten", Vector3(-6.0, 0, -8.2), Vector3.FORWARD],
		["Treppenhaus (EG)", Vector3(LevelBuilder.STAIRWELL_X, 0, -3.0), Vector3.FORWARD],
		["Obergeschoss, Flur", Vector3(18.0, LevelBuilder.UP_Y, 0), Vector3.RIGHT],
		["Kellertreppe (oben)", Vector3(LevelBuilder.MAIN_END - 1.5, 0, 0), Vector3.RIGHT],
		["Keller", cellar, Vector3.RIGHT],
		_room(b, "17", "Zimmer 17 (verlassen)"),
		_room(b, "16", "Zimmer 16 (Wäscherei)"),
	]


## Mitten im Zimmer, Blick zur Tür.
func _room(b: LevelBuilder, no: String, label: String) -> Array:
	var info: Dictionary = b.rooms[no]
	return [label, info["center"], -(info["into"] as Vector3)]


func _ready() -> void:
	layer = 16
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.04, 0.06, 0.94)
	style.border_color = Color(0.3, 0.45, 0.6)
	style.set_border_width_all(1)
	style.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	panel.anchor_left = 0.15
	panel.anchor_right = 0.85
	panel.anchor_top = 0.2
	panel.anchor_bottom = 0.8
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	var title := Label.new()
	var settings := LabelSettings.new()
	settings.font_size = 10
	settings.font_color = Color(0.6, 0.8, 0.95)
	title.label_settings = settings
	title.text = "Debug: Teleport  (1–9 / Maus, Esc schließt)"
	box.add_child(title)
	_options = GridContainer.new()
	_options.columns = 2
	_options.add_theme_constant_override("h_separation", 8)
	_options.add_theme_constant_override("v_separation", 0)
	box.add_child(_options)


func open() -> void:
	var p := Game.player
	if get_tree().paused or Game.game_over or p == null or p.dead or p.in_dialog:
		return   # Menü offen, Gespräch, Spieltisch …
	UiKit.clear(_options)
	for i in _targets.size():
		var entry: Array = _targets[i]
		_option(i, String(entry[0]))
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_teleport"):
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()
		return
	if not visible:
		return
	if event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		var index: int = (event as InputEventKey).keycode - KEY_1
		if index >= 0 and index < mini(9, _targets.size()):
			_go(index)
			get_viewport().set_input_as_handled()


func _go(index: int) -> void:
	var entry: Array = _targets[index]
	var p := Game.player
	if p.hiding:
		p.exit_hide()
	var look: Vector3 = entry[2]
	p.global_position = (entry[1] as Vector3) + Vector3(0, 0.05, 0)
	p.velocity = Vector3.ZERO
	p.rotation = Vector3(0, atan2(-look.x, -look.z), 0)
	p.head.rotation.x = 0.0
	close()
	Game.say("Teleport: %s" % entry[0], 2.0)


func _option(index: int, text: String) -> void:
	var button := Button.new()
	button.text = ("%d. %s" % [index + 1, text]) if index < 9 else ("    " + text)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.flat = true
	button.add_theme_font_size_override("font_size", 9)
	button.custom_minimum_size = Vector2(150, 0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_go.bind(index))
	_options.add_child(button)
