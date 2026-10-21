class_name TeleportUI
extends CanvasLayer
## Debug (F6): Liste wichtiger Orte zum Hinspringen. Pausiert das Spiel, solange das Fenster
## offen ist. Auswahl per Maus oder Zifferntasten 1–9, Esc oder F6 schließt.
## Neue Orte: in `_destinations()` einen Eintrag ergänzen. Ein vierter Eintrag (Callable) läuft nach dem
## Sprung; ohne Standpunkt (null) bleibt der Spieler stehen und nur die Aktion läuft – so ruft das Menü den
## Lakengeist dorthin, wo man gerade ist (Spielkonzept 4.18).

## [Name, Standpunkt, Blickrichtung, optional: Aktion] – Standpunkt null: kein Sprung
var _targets: Array = []
var _options: GridContainer


func setup(builder: LevelBuilder) -> void:
	_targets = _destinations(builder)


func _destinations(b: LevelBuilder) -> Array:
	var cellar := b.cellar_center()
	return [
		_room(b, LevelBuilder.PLAYER_ROOM, "Zimmer 13 (eigenes, 0113)"),
		["Lobby", b.lobby_center + Vector3(0, 0, 8.0), Vector3.FORWARD],
		_room(b, LevelBuilder.COMPASS_ROOM, "Zimmer %s (Kompass)" % LevelBuilder.COMPASS_ROOM),
		["Bar", b.bar_spots[0] + Vector3(0, 0, 2.0), Vector3.FORWARD],
		["Küche", b.kitchen_spot + Vector3(0, 0, 2.0), Vector3.FORWARD],
		["Garten", b.garden_spots[0] + Vector3(0, 0, -2.0), Vector3.FORWARD],
		["Galerie (Obergeschoss)", b.lobby_center + Vector3(-5.5, LevelBuilder.UP_Y, -2.0), Vector3.RIGHT],
		["Treppenhaus Ost (EG)", b.stairwell_point + Vector3(0, 0, 2.2), Vector3.FORWARD],
		["Keller (Heizkeller)", cellar, Vector3.BACK],
		_room(b, "0117", "Zimmer 0117 (verlassen)"),
		_room(b, "0116", "Zimmer 0116 (Wäscherei)"),
		_zone(b, "Partyraum", func(n: String) -> bool: return n == "Partyraum"),
		_zone(b, "Westflügel (Flur)", func(n: String) -> bool: return n.begins_with("Westflügel")),
		_zone(b, "Obergeschoss, Flur", func(n: String) -> bool: return n.ends_with("(oben)")),
		_zone(b, "Katzenraum (Obergeschoss)", func(n: String) -> bool: return n == "Katzenraum"),
		_zone(b, "Bibliothek (Obergeschoss)", func(n: String) -> bool: return n == "Bibliothek"),
		_cellar_hall(b),
		_zone(b, "Technikraum (Untergeschoss)", func(n: String) -> bool: return n == "Technikraum"),
		_zone(b, "Wäscherei (Untergeschoss)", func(n: String) -> bool: return n == "Wäscherei"),
		_ghost(1, "Lakengeist 1. Mal am Fenster (hier)"),
		_ghost(2, "Lakengeist 2. Mal: Handabdrücke, Hypnose"),
		_ghost(3, "Lakengeist 3. Mal: kommt herein"),
		_ghost(4, "Lakengeist 4. Mal: auch durch den Vorhang"),
		["Lakengeist im Flur (hier, alle schlafen)", null, null, Game.ghost.debug_summon_hall],
	].filter(func(entry: Array) -> bool: return not entry.is_empty())


## Kein Sprung: Der Geist kommt sofort zum n. Mal ans Außenfenster des Raums, in dem man steht (Licht aus,
## Vorhang auf, beim 4. Mal zu).
func _ghost(stage: int, label: String) -> Array:
	return [label, null, null, Game.ghost.debug_summon.bind(stage)]


## Mitte der ersten Zone, deren Name passt (LevelBuilder.zones), danach aufs NavMesh gerückt – die Mitte kann in
## Möbeln liegen (Kratzbaum, Regale). Lange Flure sind eine Kette gleichnamiger Zonen – dort geht der Blick zur
## nächsten den Gang entlang, sonst nach Norden. Leer, wenn der Plan keine solche Zone hat.
func _zone(b: LevelBuilder, label: String, matches: Callable) -> Array:
	for zone in b.zones:
		if matches.call(String(zone["name"])):
			var center: Vector3 = zone["center"]
			var look := Vector3.FORWARD
			for other in b.zones:
				if other != zone and other["name"] == zone["name"]:
					look = ((other["center"] as Vector3) - center) * Vector3(1, 0, 1)
					look = look.normalized() if look.length() > 0.1 else Vector3.FORWARD
					break
			return [label, center, look, _onto_navmesh]
	return []


## Gang unten am Treppenhaus (Spielkonzept 7.9): das Kellerstück, das dem Treppenhaus am nächsten liegt.
func _cellar_hall(b: LevelBuilder) -> Array:
	var best: Dictionary = {}
	for zone in b.zones:
		if zone["name"] == "Keller" and (best.is_empty() or (zone["center"] as Vector3).distance_to(b.stairwell_point)
				< (best["center"] as Vector3).distance_to(b.stairwell_point)):
			best = zone
	if best.is_empty():
		return []
	return ["Kellergang (Untergeschoss)", best["center"], Vector3.FORWARD, _onto_navmesh]


## Nach dem Sprung auf den nächsten begehbaren Punkt – nur in der Nähe, sonst bleibt der Spieler, wo er ist.
## Beim Start (--tp) ist die Karte noch nicht synchronisiert: dann ein paar Physik-Frames warten.
func _onto_navmesh() -> void:
	var p := Game.player
	var map := p.get_world_3d().navigation_map
	for i in 30:
		if NavigationServer3D.map_get_iteration_id(map) > 0:
			break
		await get_tree().physics_frame
	var to := NavigationServer3D.map_get_closest_point(map, p.global_position)
	if to.distance_to(p.global_position) < 3.0:
		p.global_position = to + Vector3(0, 0.05, 0)


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
	go_to(_targets[index])


## Eintrag zu einem getippten Namen (Debug-Konsole, „tp keller“): erst ein Eintrag, dessen erstes Wort genau
## passt, sonst einer, der so anfängt. Leer, wenn keiner passt.
func find(query: String) -> Array:
	query = query.to_lower()
	var starts: Array = []
	for entry in _targets:
		var label := String(entry[0]).to_lower()
		var first := label.split(" ")[0].trim_suffix(",")
		if first == query:
			return entry
		if starts.is_empty() and label.begins_with(query):
			starts = entry
	return starts


func go_to(entry: Array) -> void:
	if entry[1] == null:   # bleibt stehen, nur die Aktion
		close()
		(entry[3] as Callable).call()
		return
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
	if entry.size() > 3:
		(entry[3] as Callable).call()


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
