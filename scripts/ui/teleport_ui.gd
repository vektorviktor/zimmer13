class_name TeleportUI
extends CanvasLayer
## Debug-Menü (F6): Liste wichtiger Orte zum Hinspringen, der Lakengeist zum 1.–4. Mal und – wo die Debug-Konsole
## erlaubt ist (DebugConsole.enabled) – alle Konsolenbefehle nach Gruppen. Pausiert das Spiel, solange es offen ist.
## Die Liste scrollt (Mausrad, Bild↑/↓, Pos1/Ende); Auswahl per Maus, ↑/↓ + Enter oder 1–9 für die ersten Orte,
## Esc oder F6 schließt.
## Ein Befehl ohne Werte läuft sofort; mit Werten öffnet sich unten eine Eingabezeile mit dem Format aus der Hilfe
## (Werte gibt man selbst an), Enter führt ihn aus. Ausgeführt wird über `DebugConsole.submit()`, also genau wie
## getippt – Auskünfte (guests) und Fehler zeigt danach die Konsole.
## Neue Orte: in `_destinations()` einen Eintrag ergänzen. Ein vierter Eintrag (Callable) läuft nach dem Sprung.
## Neue Konsolenbefehle erscheinen von selbst (DebugConsole.COMMANDS) – in `GROUPS` einsortieren, sonst stehen sie
## unter „Sonstiges“.

## Gruppen der Konsolenbefehle in dieser Reihenfolge („Teleport“ und „Lakengeist“ hängen an die festen Einträge an)
const GROUPS := [
	["Teleport", ["tp", "pos"]],
	["Lakengeist", ["ghost", "awake"]],
	["Monster", ["warn", "doll", "lure", "monster", "intent", "bold", "attacks", "kill", "knock", "noise"]],
	["Kürbismann", ["pumpkin"]],
	["Wettbewerb", ["siegerehrung", "brett", "brief", "zettel"]],
	["Gäste", ["guests", "talk", "look", "shock", "wound", "friend", "enemy", "relation", "pals", "rival", "follow",
		"visit", "attack", "punch", "bulb-thief", "steal-test"]],
	["Spiele", ["dice", "chess", "challenge", "autoplay"]],
	["Feiern & Deko", ["party", "trick", "prank", "mess", "decorate", "search", "cook", "costumes", "player-deco"]],
	["Telefon", ["call", "dial"]],
	["Zeit & Schlaf", ["time", "day", "uhr", "sleep"]],
	["Welt", ["weather", "wallblood", "pool", "splash", "rot"]],
	["Spieler", ["pocket", "flashlight", "bag", "deco", "show", "sprint", "winded", "disguise", "drunk", "cat"]],
	["Speichern & Ansicht", ["save", "load", "savetest", "menu", "fps", "psx", "no-psx", "debug", "trace"]],
]
## Nicht im Menü: nur in der Konsole sinnvoll (help, clear) bzw. beendet das Spiel (navcheck)
const HIDDEN := ["help", "clear", "navcheck"]
const ACCENT := Color(0.6, 0.8, 0.95)

## Zuletzt eingegebene Werte je Befehl (bleiben bis zum Beenden)
static var _last_values: Dictionary = {}

## [Name, Standpunkt, Blickrichtung, optional: Aktion nach dem Sprung]
var _targets: Array = []
var _scroll: ScrollContainer
var _list: VBoxContainer
var _value_box: VBoxContainer
var _value_name: Label
var _value_line: LineEdit
var _value_hint: Label
var _command := ""
var _first: Button
var _last_pressed: Button


func setup(builder: LevelBuilder) -> void:
	_targets = _destinations(builder)


func _destinations(b: LevelBuilder) -> Array:
	var cellar := b.cellar_center()
	return [
		_room(b, LevelBuilder.PLAYER_ROOM, "Zimmer 13 (eigenes, 013)"),
		["Lobby", b.lobby_center + Vector3(0, 0, 8.0), Vector3.FORWARD],
		_room(b, LevelBuilder.COMPASS_ROOM, "Zimmer %s (Kompass)" % LevelBuilder.COMPASS_ROOM),
		["Bar", b.bar_spots[0] + Vector3(0, 0, 2.0), Vector3.FORWARD],
		["Küche", b.kitchen_spot + Vector3(0, 0, 2.0), Vector3.FORWARD],
		["Garten", b.garden_spots[0] + Vector3(0, 0, -2.0), Vector3.FORWARD],
		["Galerie (Obergeschoss)", b.lobby_center + Vector3(-5.5, LevelBuilder.UP_Y, -2.0), Vector3.RIGHT],
		["Treppenhaus Ost (EG)", b.stairwell_point + Vector3(0, 0, 2.2), Vector3.FORWARD],
		["Keller (Heizkeller)", cellar, Vector3.BACK],
		_room(b, "017", "Zimmer 017 (verlassen)"),
		_zone(b, "Partyraum", func(n: String) -> bool: return n == "Partyraum"),
		_zone(b, "Westflügel (Flur)", func(n: String) -> bool: return n.begins_with("Westflügel")),
		_zone(b, "Obergeschoss, Flur", func(n: String) -> bool: return n.ends_with("(oben)")),
		_zone(b, "Katzenraum (Obergeschoss)", func(n: String) -> bool: return n == "Katzenraum"),
		_zone(b, "Bibliothek (Obergeschoss)", func(n: String) -> bool: return n == "Bibliothek"),
		_cellar_hall(b),
		_zone(b, "Technikraum (Untergeschoss)", func(n: String) -> bool: return n == "Technikraum"),
		_zone(b, "Wäscherei (Untergeschoss)", func(n: String) -> bool: return n == "Wäscherei"),
	].filter(func(entry: Array) -> bool: return not entry.is_empty())


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
	var box := UiKit.dark_panel(self, Color(0.03, 0.04, 0.06, 0.94), Color(0.3, 0.45, 0.6), Vector4(0.1, 0.06, 0.9, 0.94))
	var title := UiKit.plain_label(10, ACCENT)
	title.text = "Debug  (Maus/Rad · ↑/↓ Enter · 1–9 Orte · Esc schließt)"
	box.add_child(title)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color(0.3, 0.45, 0.6, 0.7)
	for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
		_scroll.get_v_scroll_bar().add_theme_stylebox_override(state, grabber)
	box.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 2)
	_scroll.add_child(_list)
	# Eingabezeile für Befehle mit Werten
	_value_box = VBoxContainer.new()
	_value_box.visible = false
	box.add_child(_value_box)
	var row := HBoxContainer.new()
	_value_box.add_child(row)
	_value_name = UiKit.plain_label(10, ACCENT)
	row.add_child(_value_name)
	_value_line = LineEdit.new()
	_value_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_value_line.add_theme_font_size_override("font_size", 10)
	_value_line.keep_editing_on_text_submit = true
	_value_line.text_submitted.connect(_submit_value)
	_value_line.gui_input.connect(_on_value_key)
	row.add_child(_value_line)
	_value_hint = UiKit.plain_label(8, Color(0.55, 0.62, 0.7))
	_value_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_value_box.add_child(_value_hint)


func open() -> void:
	var p := Game.player
	if get_tree().paused or Game.game_over or p == null or p.dead or p.in_dialog:
		return   # Menü offen, Gespräch, Spieltisch …
	_build()
	_value_box.visible = false
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _first:
		_first.grab_focus.call_deferred()


func close() -> void:
	visible = false
	get_viewport().gui_release_focus()   # sonst drückt die Leertaste (Springen) noch den gewählten Knopf
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


## Liste neu aufbauen: Orte, Lakengeist, dann die Konsolenbefehle nach GROUPS (Rest unter „Sonstiges“).
func _build() -> void:
	UiKit.clear(_list)
	_first = null
	var grids := {}
	var grid := _section(grids, "Teleport")
	for i in _targets.size():
		var label := String(_targets[i][0])
		_add(grid, ("%d. %s" % [i + 1, label]) if i < 9 else ("    " + label), "", go_to.bind(_targets[i]))
	# Kein Sprung: Der Geist kommt sofort zum n. Mal ans Außenfenster bzw. an die Fenstertür des Raums, in dem man
	# steht (Licht aus, Vorhang auf, beim 4. Mal zu) – Spielkonzept 4.18
	grid = _section(grids, "Lakengeist")
	var stages := ["1. Mal am Fenster (hier)", "2. Mal: Handabdrücke, Hypnose", "3. Mal: kommt herein",
		"4. Mal: auch durch den Vorhang"]
	for i in stages.size():
		_add(grid, "Lakengeist " + stages[i], "", _act.bind(Game.ghost.debug_summon.bind(i + 1)))
	_add(grid, "Lakengeist im Flur (hier, alle schlafen)", "", _act.bind(Game.ghost.debug_summon_hall))
	if _console() == null:
		return   # exportiertes Spiel ohne --debug: nur Orte und Lakengeist
	var rest: Array = DebugConsole.COMMANDS.keys().filter(func(cmd: String) -> bool: return not cmd in HIDDEN)
	for group in GROUPS:
		grid = _section(grids, group[0])
		for cmd in group[1]:
			if cmd in rest:
				_add_command(grid, cmd)
				rest.erase(cmd)
	if not rest.is_empty():
		grid = _section(grids, "Sonstiges")
		for cmd in rest:
			_add_command(grid, cmd)


## Überschrift und zweispaltiges Raster einer Gruppe – gibt es sie schon, das vorhandene Raster.
func _section(grids: Dictionary, title: String) -> GridContainer:
	if grids.has(title):
		return grids[title]
	var head := UiKit.plain_label(9, Color(0.85, 0.68, 0.4))
	head.text = title
	_list.add_child(head)
	grids[title] = UiKit.option_grid(_list)
	return grids[title]


func _add_command(grid: GridContainer, cmd: String) -> void:
	var entry: Array = DebugConsole.COMMANDS[cmd]
	var takes_value := String(entry[0]) != ""
	_add(grid, "%s%s – %s" % [cmd, " …" if takes_value else "", entry[1]], "%s %s\n%s" % [cmd, entry[0], entry[1]],
		_choose.bind(cmd))


func _add(grid: GridContainer, text: String, tooltip: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.flat = true
	button.clip_text = true
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.add_theme_font_size_override("font_size", 9)
	button.custom_minimum_size = Vector2(150, 0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tight := StyleBoxEmpty.new()   # eng, damit viel auf eine Seite passt
	tight.content_margin_top = 1
	tight.content_margin_bottom = 1
	tight.content_margin_left = 6
	for style_name in ["normal", "hover", "pressed", "hover_pressed"]:
		button.add_theme_stylebox_override(style_name, tight)
	var focus := StyleBoxFlat.new()   # Tastaturfokus: heller Rand links
	focus.draw_center = false
	focus.border_color = ACCENT
	focus.border_width_left = 2
	button.add_theme_stylebox_override("focus", focus)
	button.pressed.connect(func() -> void:
		_last_pressed = button
		action.call())
	grid.add_child(button)
	if _first == null:
		_first = button


## Feste Aktion ohne Sprung (Lakengeist): Menü zu, dann ausführen.
func _act(action: Callable) -> void:
	close()
	action.call()


## Befehl gewählt: ohne Werte sofort, sonst die Eingabezeile öffnen (mit dem zuletzt eingegebenen Wert).
func _choose(cmd: String) -> void:
	var entry: Array = DebugConsole.COMMANDS[cmd]
	if String(entry[0]) == "":
		_run(cmd)
		return
	_command = cmd
	_value_name.text = cmd
	_value_line.placeholder_text = entry[0]
	_value_line.text = _last_values.get(cmd, "")
	_value_line.caret_column = _value_line.text.length()
	var hint := String(entry[1])
	if cmd in DebugConsole.GUEST_FIRST or "gast" in String(entry[0]):
		hint += "\n" + _guest_ids()
	_value_hint.text = hint
	_value_box.visible = true
	_value_line.grab_focus()
	# Die Zeile macht die Liste kürzer, die rutscht dabei nach oben – erst danach den Eintrag zurück ins Bild
	await get_tree().process_frame
	if is_instance_valid(_last_pressed):
		_scroll.ensure_control_visible(_last_pressed)


## Lebende Gäste kurz: benannte einzeln, die nummerierten als Bereich („gast1 … gast64“).
func _guest_ids() -> String:
	var named: Array = []
	var numbered: Array = []
	for guest in Game.social.living_guests():
		var id := String(guest.id)
		if id.begins_with("gast") and id.substr(4).is_valid_int():
			numbered.append(id.substr(4).to_int())
		else:
			named.append(id)
	if not numbered.is_empty():
		numbered.sort()
		named.append("gast%d … gast%d" % [numbered[0], numbered.back()])
	return "Gäste: %s  (wer wo ist: guests)" % ", ".join(named)


## Enter in der Eingabezeile. Leer geht nur bei Befehlen mit freiwilligem Wert („[…]“).
func _submit_value(text: String) -> void:
	text = text.strip_edges()
	if text == "" and not String(DebugConsole.COMMANDS[_command][0]).begins_with("["):
		return
	_last_values[_command] = text
	_run(_command if text == "" else "%s %s" % [_command, text])


## Esc in der Eingabezeile: zurück zur Liste (das Menü bleibt offen).
func _on_value_key(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_value_box.visible = false
		if is_instance_valid(_last_pressed):
			_last_pressed.grab_focus()
		else:
			_value_line.release_focus()
		_value_line.accept_event()


## Wie in der Konsole getippt: Menü zu, ausführen. Auskunft oder Fehler → Konsole öffnen, dort steht er.
func _run(line: String) -> void:
	close()
	var console := _console()
	if not console.submit(line):
		console.open()


func _console() -> DebugConsole:
	return get_node_or_null("../DebugConsole") as DebugConsole


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
	elif event is InputEventKey and event.pressed:
		var key := (event as InputEventKey).keycode
		var page := int(_scroll.size.y * 0.9)
		match key:
			KEY_PAGEUP, KEY_PAGEDOWN:
				_scroll.scroll_vertical += page if key == KEY_PAGEDOWN else -page
			KEY_HOME:
				_scroll.scroll_vertical = 0
			KEY_END:
				_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)
			_:
				var index: int = key - KEY_1
				if event.is_echo() or index < 0 or index >= mini(9, _targets.size()):
					return
				go_to(_targets[index])
		get_viewport().set_input_as_handled()


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
	place_player(entry[1], entry[2])
	close()
	Game.say("Teleport: %s" % entry[0], 2.0)
	if entry.size() > 3:
		(entry[3] as Callable).call()


## Spieler an einen Standpunkt setzen (aus dem Versteck heraus), Blick waagerecht in Richtung `look` – auch für --tp.
static func place_player(pos: Vector3, look: Vector3) -> void:
	var p := Game.player
	if p.hiding:
		p.exit_hide()
	p.leave_seat(true)
	p.global_position = pos + Vector3(0, 0.05, 0)
	p.velocity = Vector3.ZERO
	p.rotation = Vector3(0, atan2(-look.x, -look.z), 0)
	p.head.rotation.x = 0.0
