class_name SettingsPanel
extends VBoxContainer
## Einstellungen (Spielkonzept 8.4): Bild, Ton, Steuerung samt Tastenbelegung, Barrierefreiheit.
## Jede Änderung wirkt sofort und wird gespeichert (Autoload „Settings“).

signal closed

## Höhe der scrollbaren Liste – im Startmenü kleiner, dort ist unter dem Titel weniger Platz
var list_height := 175.0

var _calibration: Array[ColorRect] = []
## Tastenbelegung: Knopf je Aktion und Platz („aktion:platz“), [Aktion, Platz] solange auf eine Taste gewartet wird
var _key_buttons := {}
var _capture := []
var _key_note: Label
## Haken der Spiegelungen – die Grafikstufe setzt ihn mit
var _reflections: CheckBox


func _ready() -> void:
	add_theme_constant_override("separation", 3)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(320, list_height)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 2)
	scroll.add_child(list)

	_section(list, "Bild")
	_slider(list, "Helligkeit", "gamma", 0.6, 1.8, 0.05)
	list.add_child(_calibration_row())
	_check(list, "Vollbild", "fullscreen")
	_check(list, "VSync", "vsync")
	_slider(list, "Sichtfeld (FOV)", "fov", 60.0, 120.0, 1.0)
	_graphics_row(list)
	list.add_child(UiKit.wrap_label("Niedrig für Onboard-Grafik: geringere Auflösung, weniger Schatten, keine Spiegelungen, kürzere Sicht.", 8))
	_reflections = _check(list, "Spiegelungen", "reflections")
	list.add_child(UiKit.wrap_label("Marmor, Wasser und Lack spiegeln, was zu sehen ist. Aus, wenn das Spiel ruckelt.", 8))

	_section(list, "Ton")
	_slider(list, "Gesamt", "master_volume", 0.0, 1.0, 0.05)
	_slider(list, "Musik", "music_volume", 0.0, 1.0, 0.05)
	_slider(list, "Effekte", "effects_volume", 0.0, 1.0, 0.05)

	_section(list, "Steuerung")
	_slider(list, "Mausempfindlichkeit", "mouse_sensitivity", 0.3, 2.5, 0.05)
	_check(list, "Y-Achse invertieren", "invert_y")
	_check(list, "Ducken umschalten statt halten", "crouch_toggle")
	_key_list(list)

	_section(list, "Barrierefreiheit")
	_slider(list, "Flackern & Bildrauschen", "flicker_intensity", 0.2, 1.0, 0.05)
	list.add_child(UiKit.wrap_label("Weniger Flackern bei Lichtempfindlichkeit. Das Monster kündigt sich trotzdem an.", 8))
	_slider(list, "Blickzug", "look_pull", 0.2, 1.0, 0.05)
	list.add_child(UiKit.wrap_label("Wie stark der Lakengeist deinen Blick zu sich zieht. Darunter wird er nur sanft gelenkt.", 8))
	_check(list, "Untertitel für Geräusche", "subtitles")
	_check(list, "Spinnen als Kugeln (Arachnophobie)", "spider_blobs")

	add_child(UiKit.button("Zurück", func() -> void: closed.emit()))
	_update_calibration()


## Tastenbelegung (Spielkonzept 8.4): je Aktion Haupt- und Zweittaste. Anklicken, dann die neue Taste oder Maustaste
## drücken; liegt sie schon auf einer anderen Aktion, wird getauscht (Keys.assign) und der Tausch darunter genannt.
func _key_list(list: VBoxContainer) -> void:
	list.add_child(UiKit.wrap_label("Tasten: anklicken, dann die neue Taste oder Maustaste drücken. Esc bricht ab, Entf leert den Platz.", 8))
	for entry: Array in Keys.ACTIONS:
		var row := _row(list, entry[1])
		(row.get_child(0) as Label).clip_text = true   # Knöpfe stehen bündig untereinander
		for slot in Keys.SLOTS:
			var button := UiKit.button("", _start_capture.bind(entry[0], slot))
			button.custom_minimum_size = Vector2(84, 0)
			button.alignment = HORIZONTAL_ALIGNMENT_CENTER
			button.clip_text = true
			button.add_theme_font_size_override("font_size", 9)
			row.add_child(button)
			_key_buttons["%s:%d" % [entry[0], slot]] = button
	_key_note = UiKit.wrap_label("", 8, UiKit.ACCENT)
	list.add_child(_key_note)
	list.add_child(UiKit.button("Tasten: Standard wiederherstellen", func() -> void:
		_capture = []
		Keys.reset()
		Settings.store_key_bindings()
		_key_note.text = ""
		_update_keys()))
	_update_keys()


func _start_capture(action: String, slot: int) -> void:
	_update_keys()
	_capture = [action, slot]
	_key_buttons["%s:%d" % [action, slot]].text = "Taste …"
	_key_note.text = ""


## Wartet ein Platz auf eine Taste, nimmt _input sie vor allem anderen (auch vor Esc des Menüs). Das Mausrad rollt
## weiter die Liste.
func _input(event: InputEvent) -> void:
	if _capture.is_empty() or not event.is_pressed() or event.is_echo():
		return
	if not (event is InputEventKey or event is InputEventMouseButton):
		return
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index in Keys.WHEEL:
		return
	get_viewport().set_input_as_handled()
	var action: String = _capture[0]
	var slot: int = _capture[1]
	_capture = []
	var key := event as InputEventKey
	if key and key.physical_keycode == KEY_ESCAPE:
		_key_note.text = ""
	elif key and key.physical_keycode == KEY_DELETE:
		_key_note.text = Keys.clear(action, slot)
	else:
		_key_note.text = Keys.assign(action, slot, Keys.from_input(event))
	Settings.store_key_bindings()
	_update_keys()


func _update_keys() -> void:
	for id: String in _key_buttons:
		var event := Keys.slot_event(id.get_slice(":", 0), id.get_slice(":", 1).to_int())
		(_key_buttons[id] as Button).text = Keys.event_name(event) if event else "–"


func _section(list: VBoxContainer, title: String) -> void:
	var l := UiKit.label(title, 10, UiKit.ACCENT)
	list.add_child(l)


func _row(list: VBoxContainer, text: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	list.add_child(row)
	var l := UiKit.label(text, 9)
	l.custom_minimum_size = Vector2(130, 0)
	row.add_child(l)
	return row


func _slider(list: VBoxContainer, text: String, key: String, min_value: float, max_value: float, step: float) -> void:
	var row := _row(list, text)
	var slider := HSlider.new()
	slider.min_value = min_value
	slider.max_value = max_value
	slider.step = step
	slider.value = float(Settings.get(key))
	slider.custom_minimum_size = Vector2(120, 12)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)
	var value := UiKit.label("", 9, UiKit.INK_FAINT)
	value.custom_minimum_size = Vector2(34, 0)
	row.add_child(value)
	var show := func(v: float) -> void:
		value.text = ("%d %%" % roundi(v * 100.0)) if max_value <= 2.5 else ("%d°" % roundi(v))
	show.call(slider.value)
	slider.value_changed.connect(func(v: float) -> void:
		show.call(v)
		Settings.set_value(key, v)
		if key == "gamma":
			_update_calibration())


## Grafikstufe (Settings.GRAPHICS): wirkt sofort und stellt die Spiegelungen auf den Wert der Stufe.
func _graphics_row(list: VBoxContainer) -> void:
	var row := _row(list, "Grafikstufe")
	var pick := OptionButton.new()
	pick.add_theme_font_size_override("font_size", 9)
	pick.get_popup().add_theme_font_size_override("font_size", 9)
	for level: Dictionary in Settings.GRAPHICS:
		pick.add_item(level["name"])
	pick.select(clampi(Settings.graphics, 0, Settings.GRAPHICS.size() - 1))
	pick.custom_minimum_size = Vector2(120, 0)
	pick.item_selected.connect(func(i: int) -> void:
		Settings.set_graphics(i)
		_reflections.set_pressed_no_signal(Settings.reflections))
	row.add_child(pick)


func _check(list: VBoxContainer, text: String, key: String) -> CheckBox:
	var box := CheckBox.new()
	box.text = text
	box.button_pressed = bool(Settings.get(key))
	box.add_theme_font_size_override("font_size", 9)
	box.toggled.connect(func(on: bool) -> void: Settings.set_value(key, on))
	list.add_child(box)
	return box


## Kalibrierbild: dunkle Kürbis-Silhouette vor schwarzem Grund (Spielkonzept 8.4).
func _calibration_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var bg := ColorRect.new()
	bg.custom_minimum_size = Vector2(60, 30)
	bg.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bg.color = Color.BLACK
	row.add_child(bg)
	var body := ColorRect.new()
	body.position = Vector2(20, 9)
	body.size = Vector2(20, 16)
	bg.add_child(body)
	var stem := ColorRect.new()
	stem.position = Vector2(28, 5)
	stem.size = Vector2(4, 5)
	bg.add_child(stem)
	_calibration = [body, stem]
	var hint := UiKit.wrap_label("Der Kürbis soll gerade noch erkennbar sein.", 8)
	hint.custom_minimum_size = Vector2(200, 0)
	hint.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(hint)
	return row


func _update_calibration() -> void:
	if _calibration.size() < 2:
		return
	_calibration[0].color = Settings.preview(Color(0.045, 0.022, 0.006))
	_calibration[1].color = Settings.preview(Color(0.02, 0.025, 0.008))
