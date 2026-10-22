class_name UiKit
## Gemeinsame Bausteine für Menüs (Spielkonzept 8): Optik eines vergilbten
## Hotel-Meldezettels – Papier, braune Tinte, rote Hervorhebung.

const PAPER := Color(0.78, 0.71, 0.55)
const PAPER_DARK := Color(0.66, 0.58, 0.42)
const INK := Color(0.2, 0.12, 0.07)
const INK_FAINT := Color(0.38, 0.28, 0.18)
const ACCENT := Color(0.55, 0.08, 0.06)

static var _theme: Theme


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font_size = 10
	var paper := StyleBoxFlat.new()
	paper.bg_color = PAPER
	paper.border_color = Color(0.35, 0.25, 0.14)
	paper.set_border_width_all(1)
	paper.set_content_margin_all(8)
	paper.shadow_color = Color(0, 0, 0, 0.5)
	paper.shadow_size = 4
	t.set_stylebox("panel", "PanelContainer", paper)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0, 0, 0, 0)
	normal.set_content_margin_all(2)
	normal.content_margin_left = 6
	normal.content_margin_right = 6
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.55, 0.08, 0.06, 0.18)
	hover.border_color = ACCENT
	hover.border_width_left = 2
	var pressed := hover.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.55, 0.08, 0.06, 0.3)
	# Tastaturfokus: nur der rote Rand links (Maus-Hover: zusätzlich Hintergrund)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = ACCENT
	focus.border_width_left = 2
	for state in ["normal", "disabled"]:
		t.set_stylebox(state, "Button", normal)
	t.set_stylebox("hover", "Button", hover)
	t.set_stylebox("focus", "Button", focus)
	t.set_stylebox("pressed", "Button", pressed)
	t.set_color("font_color", "Button", INK)
	t.set_color("font_hover_color", "Button", ACCENT)
	t.set_color("font_focus_color", "Button", ACCENT)
	t.set_color("font_pressed_color", "Button", ACCENT)
	t.set_color("font_disabled_color", "Button", Color(0.45, 0.4, 0.32))
	t.set_constant("h_separation", "Button", 4)
	t.set_color("font_color", "Label", INK)
	t.set_color("font_color", "CheckBox", INK)
	t.set_color("font_hover_color", "CheckBox", ACCENT)
	t.set_color("font_pressed_color", "CheckBox", INK)
	t.set_color("font_focus_color", "CheckBox", ACCENT)
	for state in ["normal", "hover", "pressed", "focus", "hover_pressed"]:
		t.set_stylebox(state, "CheckBox", normal)

	var option := StyleBoxFlat.new()
	option.bg_color = PAPER_DARK
	option.set_content_margin_all(2)
	option.content_margin_left = 4
	for state in ["normal", "hover", "pressed", "focus"]:
		t.set_stylebox(state, "OptionButton", option)
	t.set_color("font_color", "OptionButton", INK)
	t.set_color("font_hover_color", "OptionButton", ACCENT)
	var popup := StyleBoxFlat.new()
	popup.bg_color = PAPER
	popup.border_color = INK_FAINT
	popup.set_border_width_all(1)
	t.set_stylebox("panel", "PopupMenu", popup)
	t.set_color("font_color", "PopupMenu", INK)
	t.set_color("font_hover_color", "PopupMenu", ACCENT)
	var popup_hover := StyleBoxFlat.new()
	popup_hover.bg_color = Color(0.55, 0.08, 0.06, 0.18)
	t.set_stylebox("hover", "PopupMenu", popup_hover)
	t.set_font_size("font_size", "PopupMenu", 10)

	var slider_track := StyleBoxFlat.new()
	slider_track.bg_color = PAPER_DARK
	slider_track.content_margin_top = 2
	slider_track.content_margin_bottom = 2
	var slider_fill := slider_track.duplicate() as StyleBoxFlat
	slider_fill.bg_color = Color(0.45, 0.25, 0.12)
	t.set_stylebox("slider", "HSlider", slider_track)
	t.set_stylebox("grabber_area", "HSlider", slider_fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", slider_fill)
	var grabber := _grabber_texture()
	t.set_icon("grabber", "HSlider", grabber)
	t.set_icon("grabber_highlight", "HSlider", grabber)

	var scroll := StyleBoxFlat.new()
	scroll.bg_color = Color(0.45, 0.3, 0.18, 0.6)
	t.set_stylebox("grabber", "VScrollBar", scroll)
	t.set_stylebox("grabber_highlight", "VScrollBar", scroll)
	t.set_stylebox("grabber_pressed", "VScrollBar", scroll)
	var scroll_bg := StyleBoxFlat.new()
	scroll_bg.bg_color = Color(0, 0, 0, 0.08)
	scroll_bg.content_margin_left = 3
	scroll_bg.content_margin_right = 3
	t.set_stylebox("scroll", "VScrollBar", scroll_bg)
	_theme = t
	return t


static func _grabber_texture() -> Texture2D:
	var img := Image.create(6, 10, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.3, 0.15, 0.08))
	return ImageTexture.create_from_image(img)


static func label(text: String, size: int = 10, color: Color = INK, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func wrap_label(text: String, size: int = 9, color: Color = INK_FAINT) -> Label:
	var l := label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(120, 0)
	return l


## Bogen auf seine Mindestgröße schrumpfen, sobald das Layout steht (Zeilenumbrüche
## kennen ihre Höhe erst danach), und wieder mittig setzen.
static func fit(panel: Control, centered: bool = true) -> void:
	await panel.get_tree().process_frame
	if not is_instance_valid(panel):
		return
	panel.reset_size()
	if centered:
		panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	panel.modulate.a = 1.0


static func button(text: String, callback: Callable, disabled: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.disabled = disabled
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(callback)
	return b


## Papierbogen mit Überschrift; Inhalt kommt in das zurückgegebene VBox.
static func sheet(parent: Control, title: String, min_size: Vector2) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.theme = theme()
	panel.custom_minimum_size = min_size
	parent.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	panel.modulate.a = 0.0
	fit(panel)
	if title != "":
		box.add_child(label(title, 13, ACCENT))
		var line := ColorRect.new()
		line.color = Color(0.35, 0.22, 0.12, 0.6)
		line.custom_minimum_size = Vector2(0, 1)
		box.add_child(line)
	return box


## Dunkler Kasten über dem Spiel (Gespräch, Telefon, Teleport – nicht im Papier-Stil): Anker als (links, oben,
## rechts, unten). Inhalt kommt in das zurückgegebene VBox.
static func dark_panel(parent: Node, bg: Color, border: Color, anchors: Vector4) -> VBoxContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(1)
	style.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	panel.anchor_left = anchors.x
	panel.anchor_top = anchors.y
	panel.anchor_right = anchors.z
	panel.anchor_bottom = anchors.w
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	return box


## Zweispaltiges Raster für Antwortknöpfe (Gespräch, Telefon, Teleport).
static func option_grid(parent: Node) -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 0)
	parent.add_child(grid)
	return grid


## Schlichte Antwortzeile (Gespräch, Telefon): flach, eng, ohne Tastaturfokus – gewählt wird mit Maus oder Ziffer.
static func flat_option(text: String, callback: Callable, disabled: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.disabled = disabled
	button.flat = true
	button.add_theme_font_size_override("font_size", 9)
	button.custom_minimum_size = Vector2(190, 0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tight := StyleBoxEmpty.new()
	tight.content_margin_top = 1
	tight.content_margin_bottom = 1
	for style_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(style_name, tight)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	return button


## Zifferntaste 1–9 (0 = zehnte Zeile) drückt den passenden Knopf. true = getroffen (Eingabe verbraucht).
static func press_number(event: InputEvent, buttons: Array[Button]) -> bool:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return false
	var index: int = 9 if key.keycode == KEY_0 else key.keycode - KEY_1
	if index < 0 or index >= buttons.size() or buttons[index].disabled:
		return false
	buttons[index].pressed.emit()
	return true


## Label mit eigenen LabelSettings (HUD, Gespräch, Telefon) – optional mit schwarzem Umriss.
static func plain_label(font_size: int, color: Color = Color.WHITE, outline: int = 0) -> Label:
	var label := Label.new()
	var settings := LabelSettings.new()
	settings.font_size = font_size
	settings.font_color = color
	if outline > 0:
		settings.outline_size = outline
		settings.outline_color = Color.BLACK
	label.label_settings = settings
	return label


## Abdunkelnder Hintergrund für Menüs über dem Spiel.
static func dimmer(parent: Control, alpha: float = 0.55) -> ColorRect:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, alpha)
	parent.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return dim


static func clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


static func playtime_text(seconds: float) -> String:
	var minutes := int(seconds / 60.0)
	if minutes < 60:
		return "%d min" % minutes
	return "%d h %02d min" % [minutes / 60, minutes % 60]


static func date_text(unix: int) -> String:
	var d := Time.get_datetime_dict_from_unix_time(unix + int(Time.get_time_zone_from_system()["bias"]) * 60)
	return "%02d.%02d. %02d:%02d" % [d["day"], d["month"], d["hour"], d["minute"]]
