class_name SettingsPanel
extends VBoxContainer
## Einstellungen (Spielkonzept 8.4): Bild, PS1-Look, Ton, Steuerung, Barrierefreiheit.
## Jede Änderung wirkt sofort und wird gespeichert (Autoload „Settings“).

signal closed

## Höhe der scrollbaren Liste – im Startmenü kleiner, dort ist unter dem Titel weniger Platz
var list_height := 175.0

var _calibration: Array[ColorRect] = []


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
	_slider(list, "Sichtfeld (FOV)", "fov", 60.0, 95.0, 1.0)
	_check(list, "Spiegelungen", "reflections")
	list.add_child(UiKit.wrap_label("Marmor, Wasser und Lack spiegeln, was zu sehen ist. Aus, wenn das Spiel ruckelt.", 8))

	_section(list, "PS1-Look")
	var look := _check(list, "PS1-Look", "psx_look")
	var res := _option(list, "Interne Auflösung", "resolution")
	for r in Settings.RESOLUTIONS:
		res.add_item("%d × %d" % [r.x, r.y])
	res.select(Settings.resolution)
	# Ohne PS1-Look gelten die Einzelschalter nicht – sie bleiben gespeichert, sind aber gesperrt
	var parts: Array[BaseButton] = [res, _check(list, "Vertex-Wackeln", "vertex_wobble"), _check(list, "Dithering", "dithering")]
	var lock := func(on: bool) -> void:
		for part in parts:
			part.disabled = not on
	lock.call(Settings.psx_look)
	look.toggled.connect(lock)

	_section(list, "Ton")
	_slider(list, "Gesamt", "master_volume", 0.0, 1.0, 0.05)
	_slider(list, "Musik", "music_volume", 0.0, 1.0, 0.05)
	_slider(list, "Effekte", "effects_volume", 0.0, 1.0, 0.05)

	_section(list, "Steuerung")
	_slider(list, "Mausempfindlichkeit", "mouse_sensitivity", 0.3, 2.5, 0.05)
	_check(list, "Y-Achse invertieren", "invert_y")
	_check(list, "Ducken umschalten statt halten", "crouch_toggle")

	_section(list, "Barrierefreiheit")
	_slider(list, "Flackern & Bildrauschen", "flicker_intensity", 0.2, 1.0, 0.05)
	list.add_child(UiKit.wrap_label("Weniger Flackern bei Lichtempfindlichkeit. Das Monster kündigt sich trotzdem an.", 8))
	_check(list, "Untertitel für Geräusche", "subtitles")
	_check(list, "Spinnen als Kugeln (Arachnophobie)", "spider_blobs")

	add_child(UiKit.button("Zurück", func() -> void: closed.emit()))
	_update_calibration()


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


func _check(list: VBoxContainer, text: String, key: String) -> CheckBox:
	var box := CheckBox.new()
	box.text = text
	box.button_pressed = bool(Settings.get(key))
	box.add_theme_font_size_override("font_size", 9)
	box.toggled.connect(func(on: bool) -> void: Settings.set_value(key, on))
	list.add_child(box)
	return box


func _option(list: VBoxContainer, text: String, key: String) -> OptionButton:
	var row := _row(list, text)
	var option := OptionButton.new()
	option.add_theme_font_size_override("font_size", 9)
	option.item_selected.connect(func(index: int) -> void: Settings.set_value(key, index))
	row.add_child(option)
	return option


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
