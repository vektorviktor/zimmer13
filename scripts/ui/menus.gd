class_name Menus
extends CanvasLayer
## Spielmenü (Esc) und Tagebuch (Spielkonzept 8.3, 8.5). Solange etwas offen ist,
## pausiert das Spiel komplett. Esc schließt zuerst ein offenes Fenster (Dialog,
## Tagebuch, Untermenü) und öffnet sonst das Menü – auch im Versteck und im Minispiel.

const CONTROLS := [
	["W A S D / Maus", "Laufen / Umsehen"],
	["Shift", "Rennen (macht Lärm, kostet Ausdauer)"],
	["Leertaste", "Springen"],
	["Strg / C", "Ducken"],
	["E", "Nehmen, Benutzen, Türen, Licht, Vorhänge, Reden, Verstecken"],
	["G / Q", "Gegenstand ablegen"],
	["Rechtsklick (halten)", "Im Versteck Luft anhalten"],
	["Tab (halten)", "Kartenblätter ansehen – Linksklick / Mausrad blättert"],
	["F (halten)", "Kompass ansehen"],
	["Linksklick / R", "Taschenlampe an/aus / normales Licht ↔ UV"],
	["1–9", "Antwort im Gespräch wählen"],
	["Esc", "Fenster schließen / Spielmenü"],
	["F3 / F5 / F6", "Debug-Werte / Monster rufen / Teleport"],
]

var _root: Control
var _screen := ""
var _diary_thumb: Image
var _diary_text := ""


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.theme = UiKit.theme()
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.visible = false


func is_open() -> bool:
	return _screen != ""


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause") or Game.game_over:
		return
	if _screen != "":
		if _screen in ["load", "settings", "controls", "confirm"]:
			_show_pause()
		else:
			close()
		get_viewport().set_input_as_handled()
		return
	if Game.dialog and Game.dialog.visible:
		return   # das Gespräch schließt sich selbst
	open_pause()
	get_viewport().set_input_as_handled()


func open_pause() -> void:
	_open()
	_show_pause()


func open_diary() -> void:
	# Vorschaubild vor dem Öffnen aufnehmen (zeigt das Zimmer, nicht das Menü)
	_diary_thumb = get_viewport().get_texture().get_image()
	_diary_text = SaveManager.diary_sentence()
	_open()
	_show_diary()


## Einen Zettel lesen (pausiert, Esc oder Knopf schließt).
func open_note(title: String, text: String) -> void:
	_open()
	var box := _new_sheet("note", title, 260.0)
	box.add_child(UiKit.wrap_label(text, 9, UiKit.INK))
	var back := UiKit.button("Weglegen", close)
	box.add_child(back)
	back.grab_focus.call_deferred()


func close() -> void:
	_screen = ""
	UiKit.clear(_root)
	_root.visible = false
	get_tree().paused = false
	var keep_mouse := (Game.dialog and Game.dialog.visible) or (Game.dice and Game.dice.active) or (Game.chess and Game.chess.active)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if keep_mouse else Input.MOUSE_MODE_CAPTURED


func _open() -> void:
	get_tree().paused = true
	_root.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _new_sheet(screen: String, title: String, width: float = 200.0) -> VBoxContainer:
	_screen = screen
	UiKit.clear(_root)
	UiKit.dimmer(_root)
	return UiKit.sheet(_root, title, Vector2(width, 0))


# --- Seiten -------------------------------------------------------------------------

func _show_pause() -> void:
	var box := _new_sheet("pause", "Zimmer 13 – Pause", 190.0)
	box.add_child(UiKit.label(Calendar.date_text(Game.director.elapsed), 9, UiKit.INK_FAINT))
	var first := UiKit.button("Fortsetzen", close)
	box.add_child(first)
	box.add_child(UiKit.button("Laden", _show_load))
	box.add_child(UiKit.button("Einstellungen", _show_settings))
	box.add_child(UiKit.button("Steuerung", _show_controls))
	box.add_child(UiKit.button("Zum Hauptmenü", _confirm.bind("Zum Hauptmenü?", Game.go_to_title)))
	box.add_child(UiKit.button("Spiel beenden", _confirm.bind("Spiel beenden?", func() -> void: get_tree().quit())))
	box.add_child(UiKit.wrap_label("Speichern nur am Tagebuch in Zimmer 13.", 8, Color(0.45, 0.4, 0.32)))
	box.add_child(UiKit.wrap_label(_last_saved_text(), 8, Color(0.45, 0.4, 0.32)))
	first.grab_focus.call_deferred()


func _show_load() -> void:
	var box := _new_sheet("load", "Spielstand laden", 330.0)
	var list := SlotList.new().setup(SlotList.Mode.LOAD, Game.current_slot)
	list.picked.connect(func(slot: int) -> void:
		_confirm("Diesen Spielstand laden?", func() -> void: SaveManager.load_slot(slot)))
	box.add_child(list)
	box.add_child(UiKit.button("Zurück", _show_pause))


func _show_settings() -> void:
	var box := _new_sheet("settings", "Einstellungen", 330.0)
	var panel := SettingsPanel.new()
	panel.closed.connect(_show_pause)
	box.add_child(panel)


func _show_controls() -> void:
	var box := _new_sheet("controls", "Steuerung", 300.0)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 1)
	box.add_child(grid)
	for entry in CONTROLS:
		grid.add_child(UiKit.label(entry[0], 9, UiKit.ACCENT))
		grid.add_child(UiKit.label(entry[1], 9))
	box.add_child(UiKit.button("Zurück", _show_pause))


## Rückfrage mit Hinweis, wann zuletzt gespeichert wurde.
func _confirm(question: String, action: Callable) -> void:
	var previous := _screen
	var box := _new_sheet("confirm", question, 220.0)
	box.add_child(UiKit.wrap_label(_last_saved_text() + " Ungespeicherter Fortschritt geht verloren.", 9))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var yes := UiKit.button("Ja", func() -> void:
		get_tree().paused = false
		action.call())
	row.add_child(yes)
	var no := UiKit.button("Nein", _show_load if previous == "load" else _show_pause)
	row.add_child(no)
	no.grab_focus.call_deferred()


func _last_saved_text() -> String:
	if SaveManager.last_save_msec < 0:
		return "Noch nicht gespeichert."
	var minutes := int((Time.get_ticks_msec() - SaveManager.last_save_msec) / 60000.0)
	if minutes < 1:
		return "Zuletzt gespeichert: gerade eben."
	return "Zuletzt gespeichert vor %d %s." % [minutes, "Minute" if minutes == 1 else "Minuten"]


# --- Tagebuch -----------------------------------------------------------------------

func _show_diary() -> void:
	var box := _new_sheet("diary", "Tagebuch", 330.0)
	var entry := UiKit.wrap_label("„%s“" % _diary_text, 9, UiKit.INK)
	box.add_child(entry)
	box.add_child(UiKit.label("In welche Seite schreiben?", 9, UiKit.INK_FAINT))
	var list := SlotList.new().setup(SlotList.Mode.SAVE, Game.current_slot)
	list.picked.connect(_write_diary)
	box.add_child(list)
	box.add_child(UiKit.button("Tagebuch weglegen", close))


func _write_diary(slot: int) -> void:
	close()
	if SaveManager.save_to(slot, _diary_text, _diary_thumb):
		Game.current_slot = slot
		Game.director.strange_diary = false
		Game.say("Du schreibst ein paar Zeilen in dein Tagebuch. (Gespeichert – Slot %d)" % slot, 3.0)
		Game.play_sound("creak", 0.2)
	else:
		Game.say("Die Seite lässt sich nicht beschreiben … (Speichern fehlgeschlagen)", 3.0)
