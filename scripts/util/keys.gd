class_name Keys
## Tastenbelegung (Spielkonzept 8.4): welche Spielaktionen sich umbelegen lassen, Namen der Tasten für Hinweise und
## Hilfe, Umbelegen mit Tausch. Die Belegung selbst steckt in der InputMap – Game._setup_input legt den Standard an,
## danach setzt apply_saved() die Abweichungen aus dem Profil (Settings.key_bindings in settings.cfg, nicht im
## Spielstand). Je Aktion zwei Plätze: Haupttaste und Zweittaste.
##
## Spieltexte schreiben weiter die Standardtaste in eckigen Klammern („Öffnen [E]“); das Hud setzt mit localize()
## beim Anzeigen die aktuelle ein (TAGS). So bleiben die vielen Hinweise im Code unverändert lesbar.

## Umbelegbar, in der Reihenfolge der Einstellungen: Aktion, Bezeichnung. Fest bleiben Esc (Menü), die Fächer 1–6,
## das Mausrad, die Debug-Tasten und die Tasten in Fenstern (Telefon, Gespräch, Diashow, Brettspiele).
const ACTIONS := [
	["move_forward", "Vorwärts"],
	["move_back", "Rückwärts"],
	["move_left", "Links"],
	["move_right", "Rechts"],
	["run", "Rennen"],
	["jump", "Springen · Aufstehen"],
	["crouch", "Ducken"],
	["interact", "Nehmen · Reden"],
	["drop", "Ablegen · Werfen"],
	["bag", "Tasche"],
	["map", "Notizbuch & Karte"],
	["compass", "Kompass"],
	["use_item", "Lampe · Benutzen"],
	["light_mode", "Licht ↔ UV · Pusten"],
	["hold_breath", "Luft anhalten"],
]
const SLOTS := 2
## Nie belegbar: F8 stoppt im Godot-Editor das laufende Spiel
const FORBIDDEN_KEYS := [KEY_F8]
## Standardtaste in Spieltexten → Aktion, deren Taste localize() einsetzt
const TAGS := {"E": "interact", "G": "drop", "R": "light_mode", "Q": "bag", "F": "compass", "Tab": "map",
	"Leertaste": "jump", "Linksklick": "use_item", "Rechtsklick": "hold_breath"}
## Deutsche Namen für Tasten ohne Zeichen
const KEY_NAMES := {KEY_SPACE: "Leertaste", KEY_SHIFT: "Shift", KEY_CTRL: "Strg", KEY_ALT: "Alt", KEY_META: "Win",
	KEY_TAB: "Tab", KEY_ENTER: "Enter", KEY_KP_ENTER: "Enter", KEY_BACKSPACE: "Rücktaste", KEY_DELETE: "Entf",
	KEY_INSERT: "Einfg", KEY_HOME: "Pos1", KEY_END: "Ende", KEY_PAGEUP: "Bild auf", KEY_PAGEDOWN: "Bild ab",
	KEY_UP: "Pfeil hoch", KEY_DOWN: "Pfeil runter", KEY_LEFT: "Pfeil links", KEY_RIGHT: "Pfeil rechts",
	KEY_CAPSLOCK: "Feststell", KEY_ESCAPE: "Esc", KEY_MENU: "Menütaste"}
const MOUSE_NAMES := {MOUSE_BUTTON_LEFT: "Linksklick", MOUSE_BUTTON_RIGHT: "Rechtsklick", MOUSE_BUTTON_MIDDLE: "Mittelklick",
	MOUSE_BUTTON_XBUTTON1: "Maustaste 4", MOUSE_BUTTON_XBUTTON2: "Maustaste 5"}
const WHEEL := [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]

## Standardbelegung je umbelegbarer Aktion (Liste gespeicherter Tasten, siehe encode)
static var _defaults := {}
static var _tag_regex: RegEx
static var _fill_regex: RegEx


## Nach Game._setup_input: beim ersten Mal den Standard merken, dann die gespeicherte Belegung anwenden.
static func apply_saved(saved: Dictionary) -> void:
	if _defaults.is_empty():
		for entry: Array in ACTIONS:
			_defaults[entry[0]] = _codes(entry[0])
	for action: String in saved:
		if _defaults.has(action) and saved[action] is Array:
			var codes: Array = (saved[action] as Array).filter(func(c) -> bool: return decode(str(c)) != null and allowed(decode(str(c)), action) == "")
			if not codes.is_empty():
				_set_codes(action, codes)


## Abweichungen vom Standard zum Speichern (Aktion → Liste gespeicherter Tasten).
static func changed() -> Dictionary:
	var out := {}
	for action: String in _defaults:
		if _codes(action) != _defaults[action]:
			out[action] = _codes(action)
	return out


## Alles auf den Standard zurück.
static func reset() -> void:
	for action: String in _defaults:
		_set_codes(action, _defaults[action])


static func label(action: String) -> String:
	for entry: Array in ACTIONS:
		if entry[0] == action:
			return entry[1]
	return action


## Taste auf Platz `slot` (0 = Haupttaste) oder null.
static func slot_event(action: String, slot: int) -> InputEvent:
	var events := _events(action)
	return events[slot] if slot < events.size() else null


## Name der Haupttaste, z. B. „E“ – „–“ ohne Taste.
static func key_name(action: String) -> String:
	var event := slot_event(action, 0)
	return event_name(event) if event else "–"


## Alle Tasten einer Aktion, z. B. „Strg / C“.
static func key_names(action: String) -> String:
	var names: Array[String] = []
	for event in _events(action):
		names.append(event_name(event))
	return " / ".join(names) if not names.is_empty() else "–"


## Taste in Klammern für Hinweise: „[E]“.
static func tag(action: String) -> String:
	return "[%s]" % key_name(action)


static func event_name(event: InputEvent) -> String:
	if event is InputEventMouseButton:
		var button := (event as InputEventMouseButton).button_index
		return MOUSE_NAMES.get(button, "Maustaste %d" % button)
	var key := event as InputEventKey
	if key == null:
		return "?"
	var code := key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode
	if KEY_NAMES.has(code):
		return KEY_NAMES[code]
	# Beschriftung auf der eingestellten Tastatur (deutsch: Z und Y getauscht, ^ statt `)
	var shown: int = code
	if key.physical_keycode != KEY_NONE and DisplayServer.get_name() != "headless":   # headless kennt kein Layout
		shown = DisplayServer.keyboard_get_label_from_physical(code)
	if shown == KEY_NONE:
		shown = code
	if shown & KEY_SPECIAL == 0 and shown > KEY_SPACE:
		return String.chr(shown).to_upper()
	return OS.get_keycode_string(shown)


## Spieltext mit Standardtasten in Klammern („[E] …“) auf die aktuelle Belegung umschreiben – in einem Durchgang,
## damit getauschte Tasten nicht zweimal ersetzt werden. Andere Klammern (Untertitel) bleiben, wie sie sind.
static func localize(text: String) -> String:
	if not "[" in text:
		return text
	if _tag_regex == null:
		_tag_regex = RegEx.create_from_string("\\[([^\\[\\]]+)\\]")
	var out := ""
	var from := 0
	for m in _tag_regex.search_all(text):
		var action: String = TAGS.get(m.get_string(1), "")
		if action == "" or not InputMap.has_action(action):
			continue
		out += text.substr(from, m.get_start() - from) + tag(action)
		from = m.get_end()
	return out + text.substr(from)


## Platzhalter der Hilfe: „{crouch}“ = alle Tasten, „{move_forward.1}“ = nur die Haupttaste.
static func fill(text: String) -> String:
	if _fill_regex == null:
		_fill_regex = RegEx.create_from_string("\\{([a-z_]+)(\\.1)?\\}")
	var out := ""
	var from := 0
	for m in _fill_regex.search_all(text):
		var action := m.get_string(1)
		out += text.substr(from, m.get_start() - from) + (key_name(action) if m.get_string(2) != "" else key_names(action))
		from = m.get_end()
	return out + text.substr(from)


## Darf `event` auf `action`? "" = ja, sonst der Grund (für die Einstellungen).
static func allowed(event: InputEvent, action: String) -> String:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index in WHEEL:
		return "Das Mausrad ist fest belegt (Tasche, Notizbuch, Schlafdauer)."
	if event is InputEventKey and (event as InputEventKey).physical_keycode in FORBIDDEN_KEYS:
		return "F8 geht nicht – die Taste hält im Godot-Editor das Spiel an."
	var holder := holder_of(event)
	if holder != "" and holder != action and not _defaults.has(holder):
		return "%s ist fest belegt (%s)." % [event_name(event), _fixed_label(holder)]
	return ""


## Aktion, auf der `event` schon liegt (ohne die eingebauten ui_*), sonst "".
static func holder_of(event: InputEvent) -> String:
	var code := encode(event)
	for action in InputMap.get_actions():
		if String(action).begins_with("ui_"):
			continue
		for other in InputMap.action_get_events(action):
			if encode(other) == code:
				return action
	return ""


## `event` auf Platz `slot` legen. Liegt es schon auf einer anderen umbelegbaren Aktion, wird getauscht: die bekommt
## die bisherige Taste dieses Platzes (oder verliert sie, wenn der Platz leer war). Rückgabe: Hinweis für die
## Einstellungen ("" = nichts zu sagen) – Grund der Ablehnung oder was getauscht wurde.
static func assign(action: String, slot: int, event: InputEvent) -> String:
	var reason := allowed(event, action)
	if reason != "":
		return reason
	var code := encode(event)
	var mine := _slot_codes(action)
	if mine[slot] == code:
		return ""
	var old: String = mine[slot]
	var note := ""
	if code in mine:   # dieselbe Taste auf dem anderen Platz derselben Aktion: Plätze tauschen
		mine[mine.find(code)] = old
	else:
		var holder := holder_of(event)
		if holder != "":
			var theirs := _slot_codes(holder)
			theirs[theirs.find(code)] = old
			_set_codes(holder, theirs)
			note = ("Getauscht: %s liegt jetzt auf %s." % [label(holder), event_name(decode(old))]) if old != "" \
				else ("Achtung: %s hat jetzt keine Taste mehr." % label(holder) if _codes(holder).is_empty() \
				else "%s hat nur noch %s." % [label(holder), key_name(holder)])
	mine[slot] = code
	_set_codes(action, mine)
	return note


## Platz leeren – die letzte Taste einer Aktion bleibt.
static func clear(action: String, slot: int) -> String:
	var mine := _slot_codes(action)
	if mine[slot] == "":
		return ""
	if _codes(action).size() <= 1:
		return "Jede Aktion braucht eine Taste."
	mine[slot] = ""
	_set_codes(action, mine)
	return ""


## Taste als Text für settings.cfg: „key:69“ (physische Taste) bzw. „mouse:1“.
static func encode(event: InputEvent) -> String:
	if event is InputEventMouseButton:
		return "mouse:%d" % (event as InputEventMouseButton).button_index
	if event is InputEventKey:
		var key := event as InputEventKey
		return "key:%d" % (key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode)
	return ""


static func decode(code: String) -> InputEvent:
	var parts := code.split(":")
	if parts.size() != 2 or not parts[1].is_valid_int() or parts[1].to_int() <= 0:
		return null
	if parts[0] == "mouse":
		var button := InputEventMouseButton.new()
		button.button_index = parts[1].to_int() as MouseButton
		return button
	if parts[0] == "key":
		var key := InputEventKey.new()
		key.physical_keycode = parts[1].to_int() as Key
		return key
	return null


## Neue Taste aus einem Tastendruck bzw. Klick (ohne Umschalttasten-Zusatz, wie der Standard)
static func from_input(event: InputEvent) -> InputEvent:
	if event is InputEventKey:
		var key := event as InputEventKey
		return decode("key:%d" % (key.physical_keycode if key.physical_keycode != KEY_NONE else key.keycode))
	if event is InputEventMouseButton:
		return decode("mouse:%d" % (event as InputEventMouseButton).button_index)
	return null


static func _events(action: String) -> Array[InputEvent]:
	return InputMap.action_get_events(action) if InputMap.has_action(action) else ([] as Array[InputEvent])


static func _codes(action: String) -> Array:
	var codes := []
	for event in _events(action):
		codes.append(encode(event))
	return codes


## Codes auf SLOTS Plätze aufgefüllt ("" = leer)
static func _slot_codes(action: String) -> Array:
	var codes := _codes(action).slice(0, SLOTS)
	while codes.size() < SLOTS:
		codes.append("")
	return codes


static func _set_codes(action: String, codes: Array) -> void:
	InputMap.action_erase_events(action)
	for code in codes:
		var event := decode(str(code))
		if event:
			InputMap.action_add_event(action, event)


static func _fixed_label(action: String) -> String:
	if action.begins_with("bag_"):
		return "Taschenfach"
	if action == "pause":
		return "Menü"
	if action.begins_with("debug_"):
		return "Debug"
	return action
