class_name CharacterCreation
extends CanvasLayer
## Erwachen am Waschbecken und Charaktererstellung (Spielkonzept 3.9). Neues Spiel: Das Bild ist schwarz, Wasser
## läuft, ein Klatsch ins Gesicht. Dann blendet das Bad langsam ein, erst verschwommen, dann klar, und der Blick hebt
## sich vom Becken zum Spiegel (Mirror, Spiegelbild auch ohne „Spiegelungen“). Rechts ein Papierbogen: Frau oder Mann,
## Alter (die sechs erwachsenen Grundkörper – kein Kind, Kinder haben Vorteile), Größe 1,45–2,00 m, Statur im Dreieck
## (schlank, definiert, kräftig), Haut, Haare, Oberteil und Hose aus den Gastpaletten. Jede Änderung sieht man sofort
## im Spiegel, die Augenhöhe wandert mit. „So sehe ich aus.“ fragt noch einmal nach – später lässt sich nichts ändern.
## Solange pausiert das Spiel (Uhr steht, Game.creating sperrt das Spielmenü); Spiegel, Spielerfigur und Klang laufen.

signal finished

## Ablauf in Sekunden: Wasserhahn, Klatsch, Schwarz blendet aus, Unschärfe klärt sich, Blick hebt sich, Bogen erscheint
const T_TAP := 0.4
const T_SPLASH := 2.0
const T_FADE := Vector2(3.2, 6.0)
const T_CLEAR := Vector2(3.6, 9.0)
const T_LOOK := Vector2(6.8, 9.6)
const T_UI := 9.8
const T_PAUSE := 0.15        ## erst nach ein paar Bildern pausieren (Schattenbudget, Lampen sind dann gesetzt)
const DOWN_PITCH := -1.05    ## Blick ins Becken
## Blick in den Spiegel, leicht nach unten: Das eigene Spiegelbild liegt immer auf Augenhöhe – so bleiben Scheitel
## und Spiegelunterkante bei jeder Größe (1,45–2,00 m) und jedem Sichtfeld (60–120°) im Bild
const MIRROR_PITCH := -0.17
const MIRROR_EYE := 0.95     ## so weit steht das Auge vor dem Spiegel
const SEARCH := 12.0         ## Waschbecken höchstens so weit vom Startpunkt
const PANEL_W := 156.0
const CAPTION_W := 34.0
const SWATCH := 9.0
const APPLY_EVERY := 0.08    ## Figur höchstens so oft neu bauen (Schieberegler)
const AGES := {"young": "jung", "mid": "mittel", "old": "alt"}

var quick := false   ## --figur=schnell: gleich der Bogen, ohne Erwachen
var _t := 0.0
var _mirror: Mirror
var _look: Dictionary
var _root: Control
var _black: ColorRect
var _panel: PanelContainer
var _box: VBoxContainer
var _dirty := false
var _since_apply := 0.0
var _sounds := 0
var _ui_shown := false


func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.creating = true
	Mirror.force = true
	if Game.hud:
		Game.hud.visible = false
	_root = Control.new()
	_root.theme = UiKit.theme()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_black = ColorRect.new()
	_black.color = Color.BLACK
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_black)
	_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var p := Game.player
	_look = p.body.look.duplicate()
	_mirror = _find_mirror(p.global_position)
	_place(p)
	if quick:
		_t = T_UI
		_black.visible = false
		p.head.rotation.x = MIRROR_PITCH
	else:
		p.head.rotation.x = DOWN_PITCH
		p.intro_blur = 1.0


## Spiegel über dem Waschbecken im Bad von Zimmer 13 – nicht einfach das nächste: Das Bad des Nachbarzimmers hinter
## der Wand kann näher am Startpunkt liegen, dann wachte man in einem fremden, abgeschlossenen Zimmer auf. Ohne Bad
## das nächste Becken im Zimmer selbst, sonst das nächste überhaupt.
func _find_mirror(from: Vector3) -> Mirror:
	var builder: LevelBuilder = Game.social.builder if Game.social else null
	var best: Mirror = null
	var best_rank := INF
	for m: Mirror in get_tree().get_nodes_in_group("sink_mirrors"):
		var d := m.global_position.distance_to(from)
		if d >= SEARCH:
			continue
		var front := m.global_position + m.global_basis.z.normalized() * 0.3   # vor dem Spiegel, nicht in der Wand
		front.y = from.y   # am Boden – das Stockwerk erkennt room_at an der Höhe
		var own := builder != null and builder.home_room_at(front) == LevelBuilder.PLAYER_ROOM
		var rank := d if own else d + SEARCH   # Becken in Zimmer 13 (oder seinem Bad) zuerst
		if rank < best_rank:
			best = m
			best_rank = rank
	return best


## Mittig vor das Becken stellen (der Spiegel hängt genau darüber), Blick genau auf die Mitte des Spiegels.
func _place(p: Player) -> void:
	if _mirror == null:
		return
	var n := _mirror.global_basis.z
	n.y = 0.0
	n = n.normalized()
	var floor_y := p.global_position.y
	var at := _mirror.global_position + n * MIRROR_EYE
	p.global_position = Vector3(at.x, floor_y, at.z)
	p.rotation.y = atan2(n.x, n.z)


func _process(delta: float) -> void:
	var p := Game.player
	if p == null:
		return
	_t += delta
	if _t >= T_PAUSE and not get_tree().paused:
		get_tree().paused = true
	if not quick:
		if _sounds == 0 and _t >= T_TAP:
			Game.audio.play_shot("tap", 0.9)
			_sounds = 1
		if _sounds == 1 and _t >= T_SPLASH:
			Game.audio.play_shot("splash", 1.0)
			_sounds = 2
		_black.color.a = 1.0 - smoothstep(T_FADE.x, T_FADE.y, _t)
		p.intro_blur = 1.0 - smoothstep(T_CLEAR.x, T_CLEAR.y, _t)
	p.head.rotation.x = lerpf(DOWN_PITCH, MIRROR_PITCH, smoothstep(T_LOOK.x, T_LOOK.y, _t))
	if Game.director and Game.director.post_material:
		Game.director.post_material.set_shader_parameter("blur", maxf(p.sight_blur, p.intro_blur))
	if _t >= T_UI and not _ui_shown:
		_ui_shown = true
		_black.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_show_sheet()
	_since_apply += delta
	if _dirty and _since_apply >= APPLY_EVERY:
		_dirty = false
		_since_apply = 0.0
		p.set_look(_look)


func _changed() -> void:
	_dirty = true


# --- Bogen ----------------------------------------------------------------------------

func _new_panel() -> VBoxContainer:
	if _panel:
		_panel.queue_free()
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(PANEL_W, 0)
	_root.add_child(_panel)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 2)
	_panel.add_child(_box)
	_place_panel.call_deferred()
	return _box


func _place_panel() -> void:
	await get_tree().process_frame
	if is_instance_valid(_panel):
		_panel.reset_size()
		_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT, Control.PRESET_MODE_MINSIZE, 6)


func _show_sheet() -> void:
	var box := _new_panel()
	box.add_child(UiKit.label("Wer bin ich?", 11, UiKit.ACCENT))
	var info: Dictionary = GuestBody.BODIES[_look["body"]]
	box.add_child(_choice("Ich bin", [["f", "Frau"], ["m", "Mann"]], info["sex"], func(sex: String) -> void:
		_pick_body(sex, String(GuestBody.BODIES[_look["body"]].get("gen", "mid")))))
	var ages: Array = []
	for gen in GuestBody.GENERATIONS:
		ages.append([gen, AGES[gen]])
	box.add_child(_choice("Alter", ages, info.get("gen", "mid"), func(gen: String) -> void:
		_pick_body(String(GuestBody.BODIES[_look["body"]]["sex"]), gen)))
	box.add_child(_height_row())
	var tri := ShapeTriangle.new()
	tri.set_weights(float(_look["slim"]), float(_look["fit"]))
	tri.changed.connect(func(slim: float, fit: float) -> void:
		_look["slim"] = slim
		_look["fit"] = fit
		_changed())
	box.add_child(_captioned("Statur", tri))
	box.add_child(_swatch_row("Haut", GuestGenerator.SKIN, "skin", 8))
	box.add_child(_swatch_row("Haare", GuestGenerator.HAIR, "hair", 6))
	box.add_child(_swatch_row("Oberteil", GuestGenerator.COATS, "coat", 10))
	box.add_child(_swatch_row("Hose", GuestGenerator.PANTS, "pants", 7))
	var done := UiKit.button("So sehe ich aus.", _ask_done)
	box.add_child(done)


## Grundkörper zu Geschlecht und Alter
func _pick_body(sex: String, gen: String) -> void:
	for key in PlayerBody.adult_bodies():
		if GuestBody.BODIES[key]["sex"] == sex and GuestBody.BODIES[key].get("gen", "") == gen:
			_look["body"] = key
			_changed()
			return


func _caption(text: String) -> Label:
	var l := UiKit.label(text, 8, UiKit.INK_FAINT)
	l.custom_minimum_size = Vector2(CAPTION_W, 0)
	return l


## Beschriftung links, Inhalt rechts daneben
func _captioned(text: String, content: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	var title := _caption(text)
	title.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(title)
	row.add_child(content)
	return row


## Zeile mit Knöpfen zum Umschalten: options = [[wert, text], …]
func _choice(text: String, options: Array, current: String, on_pick: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 1)
	row.add_child(_caption(text))
	var group := ButtonGroup.new()
	var tight := StyleBoxEmpty.new()
	tight.content_margin_left = 3
	tight.content_margin_right = 3
	for option: Array in options:
		var b := Button.new()
		b.text = option[1]
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = option[0] == current
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 9)
		b.add_theme_constant_override("outline_size", 0)
		for state in ["normal", "focus"]:
			b.add_theme_stylebox_override(state, tight)
		var value: String = option[0]
		b.pressed.connect(func() -> void: on_pick.call(value))
		row.add_child(b)
	return row


func _height_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_child(_caption("Größe"))
	var slider := HSlider.new()
	slider.min_value = PlayerBody.HEIGHT_RANGE.x
	slider.max_value = PlayerBody.HEIGHT_RANGE.y
	slider.step = 0.01
	slider.value = float(_look["height"])
	slider.custom_minimum_size = Vector2(70, 12)
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.focus_mode = Control.FOCUS_NONE
	row.add_child(slider)
	var value := UiKit.label("", 9, UiKit.INK)
	row.add_child(value)
	var show := func(v: float) -> void: value.text = ("%.2f m" % v).replace(".", ",")
	show.call(slider.value)
	slider.value_changed.connect(func(v: float) -> void:
		show.call(v)
		_look["height"] = v
		_changed())
	return row


## Farbfelder einer Palette; das gewählte hat einen roten Rand
func _swatch_row(text: String, colors: Array, key: String, columns: int) -> HBoxContainer:
	var grid := GridContainer.new()
	grid.columns = columns
	grid.add_theme_constant_override("h_separation", 1)
	grid.add_theme_constant_override("v_separation", 1)
	var col := _captioned(text, grid)
	var current := _nearest(colors, Color.html(String(_look[key])))
	var buttons: Array[Button] = []
	for i in colors.size():
		var b := Button.new()
		b.custom_minimum_size = Vector2(SWATCH, SWATCH)
		b.focus_mode = Control.FOCUS_NONE
		buttons.append(b)
		grid.add_child(b)
		b.pressed.connect(func() -> void:
			_look[key] = (colors[i] as Color).to_html(false)
			_style_swatches(buttons, colors, i)
			_changed())
	_style_swatches(buttons, colors, current)
	return col


func _style_swatches(buttons: Array[Button], colors: Array, selected: int) -> void:
	for i in buttons.size():
		var style := StyleBoxFlat.new()
		style.bg_color = colors[i]
		style.border_color = UiKit.ACCENT if i == selected else Color(0.3, 0.22, 0.14)
		style.set_border_width_all(2 if i == selected else 1)
		for state in ["normal", "hover", "pressed", "focus"]:
			buttons[i].add_theme_stylebox_override(state, style)


static func _nearest(colors: Array, c: Color) -> int:
	var best := 0
	for i in colors.size():
		var a: Color = colors[i]
		var b: Color = colors[best]
		if Vector3(a.r - c.r, a.g - c.g, a.b - c.b).length() < Vector3(b.r - c.r, b.g - c.g, b.b - c.b).length():
			best = i
	return best


func _ask_done() -> void:
	var box := _new_panel()
	box.add_child(UiKit.label("So sehe ich aus?", 12, UiKit.ACCENT))
	box.add_child(UiKit.wrap_label("Das lässt sich später nicht mehr ändern."))
	box.add_child(UiKit.button("Ja", _finish))
	box.add_child(UiKit.button("Noch nicht", _show_sheet))


func _finish() -> void:
	var p := Game.player
	p.set_look(_look)
	p.intro_blur = 0.0
	Mirror.force = false
	Game.creating = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if Game.hud:
		Game.hud.visible = true
	finished.emit()
	queue_free()


## Statur-Dreieck: Ecken schlank (unten links), definiert (oben), kräftig (unten rechts). Ziehen mit der Maus setzt
## den Punkt; changed meldet die Anteile von „schlank“ und „definiert“ (der Rest ist „kräftig“).
class ShapeTriangle:
	extends Control

	signal changed(slim: float, fit: float)

	const PAD := Vector2(20, 9)
	var _w := Vector3(1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0)   ## schlank, definiert, kräftig

	func _init() -> void:
		custom_minimum_size = Vector2(112, 48)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func set_weights(slim: float, fit: float) -> void:
		_w = Vector3(slim, fit, maxf(0.0, 1.0 - slim - fit))
		queue_redraw()

	func _corners() -> Array[Vector2]:
		var s := size - PAD * 2.0
		return [PAD + Vector2(0, s.y), PAD + Vector2(s.x / 2.0, 0), PAD + s]

	func _draw() -> void:
		var c := _corners()
		draw_colored_polygon(PackedVector2Array(c), Color(0.55, 0.08, 0.06, 0.12))
		draw_polyline(PackedVector2Array([c[0], c[1], c[2], c[0]]), UiKit.INK_FAINT, 1.0)
		var font := get_theme_default_font()
		draw_string(font, c[0] + Vector2(-PAD.x, 8), "schlank", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UiKit.INK)
		draw_string(font, c[1] + Vector2(-16, -1), "definiert", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UiKit.INK)
		draw_string(font, c[2] + Vector2(-PAD.x + 4, 8), "kräftig", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, UiKit.INK)
		var at: Vector2 = c[0] * _w.x + c[1] * _w.y + c[2] * _w.z
		draw_circle(at, 3.0, UiKit.ACCENT)

	func _gui_input(event: InputEvent) -> void:
		var button := event as InputEventMouseButton
		var motion := event as InputEventMouseMotion
		if (button and button.pressed and button.button_index == MOUSE_BUTTON_LEFT) or \
				(motion and motion.button_mask & MOUSE_BUTTON_MASK_LEFT):
			_set_from((event as InputEventMouse).position)
			accept_event()

	## Baryzentrische Anteile des Punkts, ins Dreieck geklemmt
	func _set_from(pos: Vector2) -> void:
		var c := _corners()
		var v0 := c[1] - c[0]
		var v1 := c[2] - c[0]
		var v2 := pos - c[0]
		var den := v0.x * v1.y - v1.x * v0.y
		var b := (v2.x * v1.y - v1.x * v2.y) / den
		var g := (v0.x * v2.y - v2.x * v0.y) / den
		var w := Vector3(1.0 - b - g, b, g)
		w = Vector3(maxf(w.x, 0.0), maxf(w.y, 0.0), maxf(w.z, 0.0))
		w /= maxf(w.x + w.y + w.z, 0.0001)
		_w = w
		queue_redraw()
		changed.emit(w.x, w.y)
