class_name DebugConsole
extends CanvasLayer
## Debug-Konsole: [^] (oder F1) klappt sie auf, das Spiel pausiert. Getippt werden dieselben Befehle wie die
## Startparameter, nur ohne „--“: „shock edna,ghost3“ oder „shock=edna,ghost3“. Ausgeführt werden sie von
## `main.run_debug()`, es gibt also keine zweite Liste von Aktionen. Eine Aktion schließt die Konsole, damit
## man sieht, was passiert; Auskünfte (help, guests) und Fehler bleiben offen. ↑/↓ blättert durch frühere
## Eingaben (bleiben bis zum Beenden), Tab ergänzt Befehle und Gast-IDs.
## Nur in Debug-Builds (Editor) oder mit --debug – im exportierten Spiel sonst nicht erreichbar.

## Befehl → [Werte, Beschreibung]. Neuer Startparameter → auch hier eintragen (Tab, help).
const COMMANDS := {
	"tp": ["ort|zimmer|gast", "dorthin springen (lobby, bar, küche, garten, keller, obergeschoss, 13, edna …)"],
	"time": ["+n|-n", "Spieltage vor- oder zurückspulen"],
	"day": ["n", "zu Tag n im Oktober springen"],
	"save": ["n", "nach 2 s in Slot n speichern (wie am Tagebuch)"],
	"load": ["n", "Spielstand n laden (0 = Autosave)"],
	"savetest": ["", "Speichern → Laden → Vergleichen (Konsole)"],
	"shock": ["gast[,blood|corpse|ghostN]", "Gast erschrecken (6.12)"],
	"ghost": ["n|flur|schrank", "Lakengeist zum n. Mal (Zimmer 13), im Flur bzw. vor deinem Schrank"],
	"awake": ["n", "so viele Nächte ohne Schlaf (Lakengeist, 4.18)"],
	"sleep": ["[bett]", "Nachtruhe beginnen (bett: du schläfst in Zimmer 13)"],
	"warn": ["", "Vorwarnung → Monster erscheint"],
	"monster": ["x,y,z", "Monster an dieser Stelle zeigen"],
	"intent": ["roam|one|rampage|n", "Absicht beim nächsten Aufbruch"],
	"bold": ["0–100", "Dreistigkeit setzen"],
	"attacks": ["n", "so viele Angriffe gab es schon"],
	"first-attack": ["", "Feier, kurz darauf der erste Angriff"],
	"kill": ["gast", "Gast nach 3 s vom Monster holen lassen"],
	"knock": ["", "Klopfen an Zimmer 13"],
	"call": ["gast|creepy|dead|door", "Telefon in Zimmer 13 klingelt"],
	"dial": ["n|lobby", "vom Telefon in Zimmer 13 anrufen"],
	"party": ["", "Feier in der Lobby starten"],
	"talk": ["gast", "Gespräch öffnen"],
	"look": ["gast[,pose]", "Gast ansehen (carry, panic, dance, sit, walk)"],
	"friend": ["gast", "mit dem Gast befreundet"],
	"enemy": ["gast", "mit dem Gast verfeindet"],
	"dice": ["gast", "Mäxchen mit dem Gast"],
	"chess": ["gast", "Schach mit dem Gast"],
	"challenge": ["gast[,chess]", "Gast fordert dich heraus (Mäxchen oder Schach)"],
	"bulb-thief": ["gast", "Gast klaut eine Birne aus Zimmer 13"],
	"cat": ["minka|socke|kasimir", "Katze vor den Spieler setzen"],
	"pos": ["x,y,z[,winkel[,neigung]]", "Spieler versetzen"],
	"pocket": ["", "Kompass, Kartenblätter, Schlüssel 18"],
	"flashlight": ["[uv]", "Taschenlampe in die Hand"],
	"show": ["map|keys|compass", "Karte/Kompass hervorholen"],
	"menu": ["pause|diary|settings|load|controls", "Menü öffnen"],
	"noise": ["art", "alle 6 s Lärm am Spieler"],
	"no-psx": ["", "PS1-Look aus"],
	"debug": ["", "Debug-Werte einblenden"],
	"trace": ["", "Monster und Lärm in die Konsole schreiben"],
	"guests": ["", "alle Gäste: Ort, Zustand, Angst, Beziehung"],
	"help": ["[befehl]", "diese Liste"],
	"clear": ["", "Ausgabe leeren"],
}
## Wirken nur beim Start (andere Stellen lesen sie aus den Startparametern)
const START_ONLY := ["title", "nointro", "shot", "frames", "shot-on", "trace-nav", "knock-fake", "answer"]
## Getippter Name → Startparameter
const ALIASES := {"save": "diary", "load": "load-slot"}
## Befehle, deren erster Wert eine Gast-ID ist (wird vorher geprüft)
const GUEST_FIRST := ["shock", "kill", "talk", "look", "friend", "enemy", "dice", "chess", "challenge", "bulb-thief"]

static var _history: Array[String] = []

var _runner: Callable
var _log: RichTextLabel
var _line: LineEdit
var _browse := -1


## Konsole erlaubt? Im Editor immer, im exportierten Spiel nur mit --debug.
static func enabled() -> bool:
	return OS.is_debug_build() or "--debug" in OS.get_cmdline_user_args()


func setup(runner: Callable) -> void:
	_runner = runner


func _ready() -> void:
	layer = 17
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.03, 0.04, 0.93)
	style.border_color = Color(0.3, 0.45, 0.6)
	style.border_width_bottom = 1
	style.set_content_margin_all(5)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	panel.anchor_right = 1.0
	panel.anchor_bottom = 0.45
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_following = true
	_log.selection_enabled = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.add_theme_font_size_override("normal_font_size", 9)
	_log.add_theme_color_override("default_color", Color(0.75, 0.82, 0.88))
	box.add_child(_log)
	_line = LineEdit.new()
	_line.placeholder_text = "Befehl (help für alle) – z. B. shock edna,ghost3 · tp lobby · guests"
	_line.add_theme_font_size_override("font_size", 10)
	_line.keep_editing_on_text_submit = true
	_line.text_submitted.connect(submit)
	_line.gui_input.connect(_on_input_key)
	box.add_child(_line)
	_print("[color=#7ab]Debug-Konsole[/color] – Befehle wie die Startparameter, ohne „--“. [^] oder Esc schließt.")


func open() -> void:
	var p := Game.player
	if get_tree().paused or Game.game_over or p == null or p.dead or p.in_dialog:
		return   # Menü, Teleport-Liste, Gespräch …
	visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_browse = -1
	_line.clear()
	_line.grab_focus.call_deferred()


func close() -> void:
	if not visible:
		return
	visible = false
	_line.release_focus()
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	# Vor der Eingabezeile abfangen, damit das ^ nicht im Text landet
	if event.is_action_pressed("debug_console"):
		if visible:
			close()
		else:
			open()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()


## ↑/↓: frühere Eingaben, Tab: ergänzen.
func _on_input_key(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed:
		return
	match key.keycode:
		KEY_UP:
			if not _history.is_empty():
				_browse = _history.size() - 1 if _browse < 0 else maxi(0, _browse - 1)
				_set_text(_history[_browse])
			_line.accept_event()
		KEY_DOWN:
			if _browse >= 0:
				_browse += 1
				_set_text(_history[_browse] if _browse < _history.size() else "")
				if _browse >= _history.size():
					_browse = -1
			_line.accept_event()
		KEY_TAB:
			_complete()
			_line.accept_event()


func _set_text(text: String) -> void:
	_line.text = text
	_line.caret_column = text.length()


## Eine Zeile ausführen wie getippt (auch --console=befehl beim Start).
func submit(text: String) -> void:
	text = text.strip_edges()
	_line.clear()
	_browse = -1
	if text == "":
		return
	if _history.is_empty() or _history.back() != text:
		_history.append(text)
	_print("[color=#9bd]> %s[/color]" % text)
	if _run(text):
		close()


## Führt eine Zeile aus. true = eine Aktion lief (Konsole schließt), false = Auskunft oder Fehler.
func _run(text: String) -> bool:
	text = text.trim_prefix("--")
	var space := text.find(" ")
	var eq := text.find("=")
	var cut := space if space >= 0 and (eq < 0 or space < eq) else eq
	var cmd := (text if cut < 0 else text.left(cut)).to_lower()
	var value := "" if cut < 0 else text.substr(cut + 1).strip_edges().replace(" ", "")
	match cmd:
		"help":
			_help(value)
			return false
		"guests":
			_guests()
			return false
		"clear":
			_log.clear()
			return false
	if cmd in START_ONLY:
		_print("[color=#d96]„%s“ wirkt nur als Startparameter (--%s).[/color]" % [cmd, cmd])
		return false
	if cmd in GUEST_FIRST and Game.social.guest_by_id(value.split(",")[0]) == null:
		_print("[color=#d96]Keinen Gast „%s“ gefunden – IDs zeigt „guests“.[/color]" % value.split(",")[0])
		return false
	var arg := "--" + String(ALIASES.get(cmd, cmd)) + ("" if value == "" else "=" + value)
	if not _runner.is_valid() or not _runner.call(arg):
		_print("[color=#d96]Unbekannt: %s – „help“ zeigt alle Befehle.[/color]" % arg)
		return false
	return true


func _help(about: String) -> void:
	for cmd in COMMANDS:
		if about != "" and not String(cmd).begins_with(about):
			continue
		var entry: Array = COMMANDS[cmd]
		_print("[color=#9bd]%s[/color] %s  [color=#789]– %s[/color]" % [cmd, entry[0], entry[1]])
	_print("[color=#789]Nur beim Start: %s[/color]" % ", ".join(START_ONLY))


func _guests() -> void:
	for guest in Game.social.guests:
		var g: Guest = guest
		var where := Game.director.zone_name_at(g.global_position)
		var state := "tot" if g.dead else String(Guest.State.keys()[g.state]).to_lower()
		_print("[color=#9bd]%s[/color] (%s, Zi. %s) – %s bei %s · Angst %d · Beziehung %d%s" % [g.display_name, g.id,
			g.home["no"], state, where, roundi(g.fear), roundi(g.relation),
			"" if g.experiences.is_empty() else " · erlebt: " + ", ".join(g.experiences.map(func(e: Dictionary) -> String: return e["kind"]))])


## Tab: Befehlsname ergänzen, nach dem Namen eine Gast-ID. Mehrere Treffer → alle zeigen und das
## Gemeinsame einsetzen.
func _complete() -> void:
	var text := _line.text.trim_prefix("--")
	var cut := maxi(text.rfind(" "), maxi(text.rfind("="), text.rfind(",")))
	var head := text.left(cut + 1)
	var word := text.substr(cut + 1).to_lower()
	var options: Array = []
	if cut < 0:
		options = COMMANDS.keys()
	else:
		for guest in Game.social.guests:
			options.append(guest.id)
		options.append_array(["blood", "corpse", "ghost1", "ghost2", "ghost3", "ghost4", "flur"])
	var hits := options.filter(func(o: String) -> bool: return o.begins_with(word))
	if hits.is_empty():
		return
	var common: String = hits[0]
	for hit in hits:
		while not String(hit).begins_with(common):
			common = common.left(-1)
	_set_text(head + common + (" " if hits.size() == 1 and cut < 0 else ""))
	if hits.size() > 1:
		_print("[color=#789]%s[/color]" % "  ".join(hits))


func _print(line: String) -> void:
	_log.append_text(line + "\n")
