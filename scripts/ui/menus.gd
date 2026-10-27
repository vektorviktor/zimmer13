class_name Menus
extends CanvasLayer
## Spielmenü (Esc) und Tagebuch (Spielkonzept 8.3, 8.5; Meilensteine aufschreiben und nachlesen, 3.10). Solange etwas offen ist,
## pausiert das Spiel komplett. Esc schließt zuerst ein offenes Fenster (Dialog,
## Tagebuch, Untermenü) und öffnet sonst das Menü – auch im Versteck und im Minispiel.
## Hilfe (2.5): Tastenübersicht und ein paar Sätze zu den Grundlagen – Einträge zu Monster und Verstecken erst nach dem
## ersten Angriff, damit sie den friedlichen Anfang nicht verraten (2.1).

## Taste, Bedeutung – mit drittem Eintrag "danach" erst nach dem ersten Angriff, "debug" nur mit Debug-Konsole
const CONTROLS := [
	["W A S D / Maus", "Laufen / Umsehen"],
	["Shift", "Rennen (macht Lärm, kostet Ausdauer)"],
	["Leertaste", "Springen · Aufstehen"],
	["Strg / C", "Ducken"],
	["E", "Nehmen, Benutzen, Reden, Hinsetzen"],
	["G", "Ablegen · lange halten: werfen"],
	["Q (halten)", "Tasche: wählen, loslassen nimmt in die Hand"],
	["1–6", "Fach der Tasche gleich in die Hand"],
	["Rechtsklick (halten)", "Im Versteck Luft anhalten", "danach"],
	["Tab (halten)", "Notizbuch und Karte – Klick / Mausrad blättert"],
	["Rechtsklick", "mit Tab: nächstes Lesezeichen (Karte, Aufgaben, Notizen)"],
	["F (halten)", "Kompass ansehen"],
	["Linksklick / R", "Lampe an/aus / Licht ↔ UV · Dose trinken"],
	["1–9", "Antwort im Gespräch wählen"],
	["Esc", "Fenster schließen / Spielmenü"],
	["F3 / F5 / F6", "Debug-Werte / Monster rufen / Teleport", "debug"],
]
## Grundlagen – mit "danach" erst nach dem ersten Angriff
const BASICS := [
	["Was [E] tut, steht unten, sobald du etwas ansiehst – Tür, Licht, Gegenstand, Gast."],
	["Du trägst alles in der Hand. Kleines passt in die Tasche, Großes trägst du einzeln."],
	["Speichern kannst du nur am Tagebuch auf dem Schreibtisch in Zimmer 13."],
	["Tag und Uhrzeit: Wanduhr in der Lobby, Kalender in Zimmer 13, dieses Menü."],
	["Mitteilungen der Direktion hängen am Brett in der Lobby."],
	["Aufgaben, Durchsagen und was du liest, notiert die Figur im Notizbuch [Tab]."],
	["Flackert das Licht und rauscht es, ist es unterwegs. Schränke und Betten sind Verstecke.", "danach"],
	["Deko im Licht vor deiner Tür hält es fern – die Puppe zeigt, wessen Tür am schwächsten ist.", "danach"],
]

## Hilfe: Breite des Bogens und der Beschreibungen neben den Tasten (umbrechend), Schriftgröße, Zeilenabstand
## (Cinzel hat hohe Zeilen – enger gesetzt, sonst passt die Seite nicht in 270 Pixel Höhe)
const HELP_WIDTH := 464.0
const HELP_TEXT_WIDTH := 150.0
const HELP_FONT_SIZE := 7
const HELP_LINE_SPACING := -2

## Erfolge: Breite des Bogens, Höhe der Liste (rollt)
const ACHIEVEMENTS_WIDTH := 330.0
const ACHIEVEMENTS_HEIGHT := 200.0

## Tagebuch nachlesen: Einträge je Seite, Farbe der fremden Zeile (MonsterDirector.strange_diary)
const DIARY_PER_PAGE := 3
const FOREIGN_INK := Color(0.5, 0.08, 0.06)

var _root: Control
var _screen := ""
var _diary_thumb: Image
var _diary_text := ""


func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.theme = UiKit.menu_theme()
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.visible = false


func is_open() -> bool:
	return _screen != ""


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause") or Game.game_over or Game.creating:
		return
	if _screen != "":
		if _screen in ["load", "settings", "help", "confirm", "achievements"]:
			_show_pause()
		elif _screen == "diary_pages":
			_show_diary()
		else:
			close()
		get_viewport().set_input_as_handled()
		return
	if (Game.dialog and Game.dialog.visible) or (Game.phones and Game.phones.is_busy()):
		return   # Gespräch und Telefon schließen sich selbst (Esc legt auf)
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


## Ein Heft mit mehreren Seiten lesen (Notizbuch des Hausmeisters, 7.4): je Seite ein Text, blättern mit den Knöpfen.
func open_pages(title: String, pages: Array, page: int = 0) -> void:
	_open()
	page = clampi(page, 0, pages.size() - 1)
	var box := _new_sheet("note", "%s – Seite %d/%d" % [title, page + 1, pages.size()] if pages.size() > 1 else title, 330.0)
	var text := UiKit.wrap_label(String(pages[page]), 9, UiKit.INK)
	text.add_theme_constant_override("line_spacing", HELP_LINE_SPACING)   # Cinzel hat hohe Zeilen (wie die Hilfe)
	box.add_child(text)
	var back := _flip_row(box, open_pages.bind(title, pages, page - 1), page == 0,
		open_pages.bind(title, pages, page + 1), page >= pages.size() - 1)
	back.grab_focus.call_deferred()


## Das Hotelregister an der Rezeption (Spielkonzept 2.3): eine Doppelseite, aufgeschlagen beim laufenden Oktober;
## zurückblättern bis 1987.
func open_register(register: HotelRegister, page: int = -1) -> void:
	_open()
	var pages := register.pages()
	page = register.current_page() if page < 0 else clampi(page, 0, pages.size() - 1)
	page -= page % 2
	var shown: Array = pages.slice(page, page + 2)
	var box := _new_sheet("note", "", RegisterView.SIZE.x)
	box.add_child(RegisterView.new().setup(shown[0], shown[1] if shown.size() > 1 else {}))
	var back := _flip_row(box, open_register.bind(register, page - 2), page == 0,
		open_register.bind(register, page + 2), page + 2 >= pages.size())
	back.grab_focus.call_deferred()
	register.on_pages_read(shown)


## Knöpfe unter einem Heft: zurück, weiter, weglegen – gibt „Weglegen“ zurück.
func _flip_row(box: VBoxContainer, prev: Callable, no_prev: bool, next: Callable, no_next: bool) -> Button:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	box.add_child(row)
	row.add_child(UiKit.button("« Zurückblättern", prev, no_prev))
	row.add_child(UiKit.button("Weiterblättern »", next, no_next))
	var done := UiKit.button("Weglegen", close)
	row.add_child(done)
	return done


## Ein Foto aus der Nähe (Fotowand, Spielkonzept 5.14): Bild, darunter, was man darauf sieht.
func open_photo(title: String, picture: Texture2D, text: String) -> void:
	_open()
	var box := _new_sheet("note", title, 260.0)
	var pic := TextureRect.new()
	pic.texture = picture
	pic.custom_minimum_size = Vector2(240, 150)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	box.add_child(pic)
	box.add_child(UiKit.wrap_label(text, 8, UiKit.INK))
	var back := UiKit.button("Weglegen", close)
	box.add_child(back)
	back.grab_focus.call_deferred()


func close() -> void:
	_screen = ""
	UiKit.clear(_root)
	_root.visible = false
	get_tree().paused = false
	var keep_mouse := (Game.dialog and Game.dialog.visible) or (Game.dice and Game.dice.active) \
		or (Game.chess and Game.chess.active) or (Game.phones and Game.phones.is_busy())
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
	box.add_child(UiKit.label("%s · %s" % [Calendar.date_text(Game.director.elapsed), Calendar.time_text(Game.director.elapsed)], 9,
		UiKit.INK_FAINT))
	var first := UiKit.button("Fortsetzen", close)
	box.add_child(first)
	box.add_child(UiKit.button("Laden", _show_load))
	box.add_child(UiKit.button("Einstellungen", _show_settings))
	box.add_child(UiKit.button("Erfolge", _show_achievements))
	box.add_child(UiKit.button("Hilfe", _show_help))
	box.add_child(UiKit.button("Zum Hauptmenü", _confirm.bind("Zum Hauptmenü?", Game.go_to_title)))
	box.add_child(UiKit.button("Spiel beenden", _confirm.bind("Spiel beenden?", func() -> void: get_tree().quit())))
	box.add_child(UiKit.wrap_label("Speichern nur am Tagebuch in Zimmer 13.", 8, Color(0.45, 0.4, 0.32)))
	box.add_child(UiKit.wrap_label(_last_saved_text(), 8, Color(0.45, 0.4, 0.32)))
	first.grab_focus.call_deferred()


func _show_load() -> void:
	var box := _new_sheet("load", "Spielstand laden", 330.0)
	var list := SlotList.new().setup(SlotList.Mode.LOAD, Game.current_slot)
	list.picked.connect(func(slot: int) -> void:
		_confirm("Diesen Spielstand laden?", func() -> void:
			if not SaveManager.load_slot(slot):   # unlesbar geworden – zurück zur Liste, das Spiel bleibt pausiert
				_show_load()))
	box.add_child(list)
	box.add_child(UiKit.button("Zurück", _show_pause))


func _show_settings() -> void:
	var box := _new_sheet("settings", "Einstellungen", 330.0)
	var panel := SettingsPanel.new()
	panel.closed.connect(_show_pause)
	box.add_child(panel)


## Erfolge (Spielkonzept 8.11): alle in der Reihenfolge von Achievements.LIST, Zähler und „Zurück“ in der Kopfzeile.
## Freigeschaltet mit Symbol, Name in der Farbe der Stufe und Beschreibung; gesperrte blass, geheime als „???“.
func _show_achievements() -> void:
	var box := _new_sheet("achievements", "", ACHIEVEMENTS_WIDTH)
	var ach := Game.achievements
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	box.add_child(head)
	head.add_child(UiKit.label("Erfolge", 13, UiKit.ACCENT))
	var counter := UiKit.label("%d von %d" % [ach.count(), Achievements.LIST.size()], 8, UiKit.INK_FAINT)
	counter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	counter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	head.add_child(counter)
	var back := UiKit.button("Zurück", _show_pause)
	head.add_child(back)
	var rule := ColorRect.new()
	rule.color = Color(0.35, 0.22, 0.12, 0.6)
	rule.custom_minimum_size = Vector2(0, 1)
	box.add_child(rule)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, ACHIEVEMENTS_HEIGHT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 4)
	scroll.add_child(list)
	for id: String in Achievements.LIST:
		var entry: Dictionary = Achievements.LIST[id]
		var open := ach.has(id)
		var hidden: bool = not open and entry.get("secret", false)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		list.add_child(row)
		row.add_child(ach.medal(id, open))
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		var top := HBoxContainer.new()
		col.add_child(top)
		var tier: int = entry["tier"]
		var name_label := UiKit.label("???" if hidden else String(entry["name"]), 9,
			Achievements.TIER_COLORS[tier].darkened(0.45) if open else Color(0.45, 0.4, 0.32))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(name_label)
		top.add_child(UiKit.label(Achievements.TIER_NAMES[tier], 7,
			Achievements.TIER_COLORS[tier].darkened(0.45) if open else Color(0.45, 0.4, 0.32)))
		var text := _help_label("Geheimer Erfolg." if hidden else String(entry["text"]),
			UiKit.INK if open else Color(0.45, 0.4, 0.32), 0.0)
		col.add_child(text)
	back.grab_focus.call_deferred()


## Hilfe: oben die Tasten in zwei Spalten, darunter die Grundlagen über die ganze Breite, „Zurück“ in der Kopfzeile –
## passt mit Cinzel (breiter und höher als die alte Schrift) auch nach dem ersten Angriff und mit Debug-Zeile in 480 × 270.
func _show_help() -> void:
	var box := _new_sheet("help", "", HELP_WIDTH)
	var head := HBoxContainer.new()
	box.add_child(head)
	var title := UiKit.label("Hilfe", 13, UiKit.ACCENT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(UiKit.button("Zurück", _show_pause))
	var rule := ColorRect.new()
	rule.color = Color(0.35, 0.22, 0.12, 0.6)
	rule.custom_minimum_size = Vector2(0, 1)
	box.add_child(rule)
	var after := Game.director != null and Game.director.first_attack_done
	var shown: Array = []
	for entry: Array in CONTROLS:
		var tag := String(entry[2]) if entry.size() > 2 else ""
		if not ((tag == "danach" and not after) or (tag == "debug" and not DebugConsole.enabled())):
			shown.append(entry)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	box.add_child(row)
	var half := ceili(shown.size() / 2.0) + 1   # rechts stehen die längeren Beschreibungen (mehr Umbrüche)
	for part: Array in [shown.slice(0, half), shown.slice(half)]:
		var grid := GridContainer.new()
		grid.columns = 2
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 1)
		row.add_child(grid)
		for entry: Array in part:
			grid.add_child(_help_label(entry[0], UiKit.ACCENT))
			grid.add_child(_help_label(entry[1], UiKit.INK, HELP_TEXT_WIDTH))
	var line := ColorRect.new()
	line.color = Color(0.35, 0.22, 0.12, 0.35)
	line.custom_minimum_size = Vector2(0, 1)
	box.add_child(line)
	var basics := VBoxContainer.new()
	basics.add_theme_constant_override("separation", 1)
	box.add_child(basics)
	basics.add_child(UiKit.label("Grundlagen", 8, UiKit.ACCENT))
	for entry: Array in BASICS:
		if entry.size() > 1 and not after:
			continue
		basics.add_child(_help_label(entry[0], UiKit.INK, 0.0))


## Zeile der Hilfe: klein und eng gesetzt; mit Breite (auch 0 = so breit wie Platz ist) umbrechend.
func _help_label(text: String, color: Color, wrap_width := -1.0) -> Label:
	var label := UiKit.label(text, HELP_FONT_SIZE, color)
	label.add_theme_constant_override("line_spacing", HELP_LINE_SPACING)
	if wrap_width >= 0.0:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size.x = wrap_width
	return label


## Rückfrage mit Hinweis, wann zuletzt gespeichert wurde.
func _confirm(question: String, action: Callable) -> void:
	var previous := _screen
	var box := _new_sheet("confirm", question, 220.0)
	box.add_child(UiKit.wrap_label(_last_saved_text() + " Ungespeicherter Fortschritt geht verloren.", 9))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	row.add_child(UiKit.button("Ja", action))   # Szenenwechsel bzw. Laden heben die Pause selbst auf
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
	if Game.diary and not Game.diary.pending.is_empty():   # Meilensteine seit dem letzten Mal (3.10)
		var n := Game.diary.pending.size()
		box.add_child(UiKit.wrap_label("Seit dem letzten Eintrag ist %s geschehen, das ich aufschreiben will." % (
			"etwas" if n == 1 else "einiges"), 8, UiKit.INK_FAINT))
	box.add_child(UiKit.label("In welche Seite schreiben?", 9, UiKit.INK_FAINT))
	var list := SlotList.new().setup(SlotList.Mode.SAVE, Game.current_slot)
	list.picked.connect(_write_diary)
	box.add_child(list)
	if Game.diary and not Game.diary.entries.is_empty():
		box.add_child(UiKit.button("Im Tagebuch blättern", _show_diary_pages.bind(-1)))
	box.add_child(UiKit.button("Tagebuch weglegen", close))


## Die aufgeschriebenen Meilensteine nachlesen (3.10) – page -1 = die letzte Seite.
func _show_diary_pages(page: int) -> void:
	var entries: Array[Dictionary] = Game.diary.entries
	var pages := maxi(1, ceili(entries.size() / float(DIARY_PER_PAGE)))
	page = pages - 1 if page < 0 else clampi(page, 0, pages - 1)
	var box := _new_sheet("diary_pages", "Tagebuch – Seite %d/%d" % [page + 1, pages], 330.0)
	for e in entries.slice(page * DIARY_PER_PAGE, (page + 1) * DIARY_PER_PAGE):
		var at := float(e["at"])
		box.add_child(UiKit.label("%s, %s" % [Calendar.date_text(at), Calendar.time_text(at)], 8, UiKit.INK_FAINT))
		box.add_child(UiKit.wrap_label(String(e["text"]), 9, FOREIGN_INK if e["foreign"] else UiKit.INK))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	box.add_child(row)
	var back := UiKit.button("« Zurück", _show_diary_pages.bind(page - 1))
	back.disabled = page == 0
	row.add_child(back)
	var next := UiKit.button("Weiter »", _show_diary_pages.bind(page + 1))
	next.disabled = page >= pages - 1
	row.add_child(next)
	var done := UiKit.button("Zum Tagebuch", _show_diary)
	box.add_child(done)
	done.grab_focus.call_deferred()


func _write_diary(slot: int) -> void:
	close()
	var written := Game.diary.write_pending(Game.director.strange_diary) if Game.diary else 0
	if SaveManager.save_to(slot, _diary_text, _diary_thumb):
		Game.current_slot = slot
		Game.director.strange_diary = false
		Game.say("Du schreibst ein paar Zeilen in dein Tagebuch. (Gespeichert – Slot %d)" % slot, 3.0)
		Game.play_sound("creak", 0.2)
	else:
		if Game.diary:
			Game.diary.unwrite(written)
		Game.say("Die Seite lässt sich nicht beschreiben … (Speichern fehlgeschlagen)", 3.0)
