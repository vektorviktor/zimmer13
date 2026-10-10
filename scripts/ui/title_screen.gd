extends Control
## Titelbildschirm (Spielkonzept 8.2): langer Hotelflur im PS1-Look, flackernde Lampe,
## Bildrauschen – ab und zu steht am Flurende eine Silhouette … beim nächsten Flackern
## ist sie weg. Fortsetzen / Neues Spiel / Laden / Einstellungen / Beenden.
##
## Mit Debug-Startparametern (nach „--“) geht es direkt ins Spiel; --load=n lädt Slot n,
## --new=n startet ein neues Spiel in Slot n.

const NOISE_SHADER := """
shader_type canvas_item;
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	float n = hash(FRAGCOORD.xy + fract(TIME * 13.0) * 97.0);
	float line = step(0.5, fract(SCREEN_UV.y * 90.0 + TIME * 2.0));
	vec2 d = SCREEN_UV - 0.5;
	float vig = clamp(dot(d, d) * 2.2, 0.0, 1.0);
	COLOR = vec4(vec3(n * 0.5 + line * 0.04), 0.06 + vig * 0.55);
	COLOR.rgb *= 1.0 - vig;
}
"""
const VP := Vector2(300, 118)       ## Fluchtpunkt

var _scene: Control
var _menu: Control
var _flicker := 1.0
var _flicker_timer := 0.0
var _figure := false
var _figure_timer := 4.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	Game.reset()   # keine Verweise auf die alte Spielwelt
	theme = UiKit.theme()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if _handle_debug_args():
		return
	_scene = Control.new()
	_scene.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_scene)
	_scene.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scene.draw.connect(_draw_corridor)
	var noise := ColorRect.new()
	var shader := Shader.new()
	shader.code = NOISE_SHADER
	var mat := ShaderMaterial.new()
	mat.shader = shader
	noise.material = mat
	noise.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(noise)
	noise.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var title := UiKit.label("ZIMMER 13", 26, Color(0.75, 0.12, 0.08))
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.add_theme_constant_override("outline_size", 3)
	title.position = Vector2(20, 18)
	add_child(title)
	var sub := UiKit.label("Ein Hotel. Ein Monster. Halloween.", 9, Color(0.7, 0.62, 0.5))
	sub.position = Vector2(22, 52)
	add_child(sub)
	_menu = Control.new()
	add_child(_menu)
	_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not Settings.warning_shown:
		_show_warning()
	else:
		_show_main()


func _process(delta: float) -> void:
	if _scene == null:
		return
	_flicker_timer -= delta
	if _flicker_timer <= 0.0:
		_flicker_timer = randf_range(0.05, 0.18)
		var strength := Settings.flicker_intensity
		if randf() < 0.12 * strength:
			_flicker = randf_range(0.05, 0.4)
			if _figure and randf() < 0.5:
				_figure = false
				_figure_timer = randf_range(6.0, 12.0)
		else:
			_flicker = randf_range(0.85, 1.0)
	_figure_timer -= delta
	if not _figure and _figure_timer <= 0.0 and _flicker < 0.5:
		_figure = true
		_figure_timer = randf_range(3.0, 7.0)
	elif _figure and _figure_timer <= 0.0:
		_figure = false
		_figure_timer = randf_range(6.0, 12.0)
	_scene.queue_redraw()


# --- Menüs --------------------------------------------------------------------------

func _sheet(title: String, width: float) -> VBoxContainer:
	UiKit.clear(_menu)
	return UiKit.sheet(_menu, title, Vector2(width, 0))


func _show_main() -> void:
	var box := _sheet("", 150.0)
	var first: Button = null
	if SaveManager.has_any_save():
		first = UiKit.button("Fortsetzen", func() -> void: SaveManager.load_newest())
		box.add_child(first)
	var new_game := UiKit.button("Neues Spiel", _show_new_game)
	box.add_child(new_game)
	box.add_child(UiKit.button("Laden", _show_load, not SaveManager.has_any_save()))
	box.add_child(UiKit.button("Einstellungen", _show_settings))
	box.add_child(UiKit.button("Beenden", func() -> void: get_tree().quit()))
	(first if first else new_game).grab_focus.call_deferred()
	_reposition.call_deferred()


## Menübogen links unter den Titel setzen (Größe steht erst nach dem Layout fest).
func _reposition() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	for child in _menu.get_children():
		var panel := child as Control
		panel.reset_size()
		panel.position = Vector2(20.0, clampf(160.0 - panel.size.y / 2.0, 66.0, 265.0 - panel.size.y))


func _show_new_game() -> void:
	var box := _sheet("Neues Spiel – Slot wählen", 330.0)
	var list := SlotList.new().setup(SlotList.Mode.NEW)
	list.picked.connect(func(slot: int) -> void:
		if SaveManager.slot_exists(slot):
			_confirm_overwrite(slot)
		else:
			Game.start_new_game(slot))
	box.add_child(list)
	box.add_child(UiKit.button("Zurück", _show_main))
	_reposition.call_deferred()


func _confirm_overwrite(slot: int) -> void:
	var box := _sheet("Slot %d überschreiben?" % slot, 220.0)
	box.add_child(UiKit.wrap_label("Der alte Spielstand in diesem Slot geht verloren.", 9))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	row.add_child(UiKit.button("Überschreiben", func() -> void: Game.start_new_game(slot)))
	var no := UiKit.button("Abbrechen", _show_new_game)
	row.add_child(no)
	no.grab_focus.call_deferred()
	_reposition.call_deferred()


func _show_load() -> void:
	var box := _sheet("Spielstand laden", 330.0)
	var list := SlotList.new().setup(SlotList.Mode.LOAD, Game.current_slot)
	list.picked.connect(func(slot: int) -> void: SaveManager.load_slot(slot))
	box.add_child(list)
	box.add_child(UiKit.button("Zurück", _show_main))
	_reposition.call_deferred()


func _show_settings() -> void:
	var box := _sheet("Einstellungen", 330.0)
	var panel := SettingsPanel.new()
	panel.closed.connect(_show_main)
	box.add_child(panel)
	_reposition.call_deferred()


## Hinweis zur Lichtempfindlichkeit beim ersten Start (Spielkonzept 8.4).
func _show_warning() -> void:
	var box := _sheet("Hinweis", 300.0)
	box.add_child(UiKit.wrap_label("Dieses Spiel enthält flackernde Lichter, Bildrauschen und plötzliche Schreckmomente. "
		+ "Bei Lichtempfindlichkeit kannst du die Stärke des Flackerns in den Einstellungen (Barrierefreiheit) verringern.", 9, UiKit.INK))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var ok := UiKit.button("Verstanden", func() -> void:
		Settings.set_value("warning_shown", true)
		_show_main())
	row.add_child(ok)
	row.add_child(UiKit.button("Einstellungen", func() -> void:
		Settings.set_value("warning_shown", true)
		_show_settings()))
	ok.grab_focus.call_deferred()
	_reposition.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and _menu:
		_show_main()
		get_viewport().set_input_as_handled()


# --- Hintergrund: der Flur ------------------------------------------------------------

func _shade(c: Color, k: float = 1.0) -> Color:
	var f := _flicker * k
	return Settings.preview(Color(c.r * f, c.g * f, c.b * f))


func _draw_corridor() -> void:
	var s := _scene
	var w := 480.0
	var h := 270.0
	s.draw_rect(Rect2(0, 0, w, h), Color.BLACK)
	var far := Rect2(VP.x - 14, VP.y - 22, 28, 40)   # Flurende
	# Decke, Wände, Boden als Trapeze zum Flurende
	s.draw_colored_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), far.position + Vector2(far.size.x, 0), far.position]),
		_shade(Color(0.2, 0.17, 0.13)))
	s.draw_colored_polygon(PackedVector2Array([Vector2(0, 0), far.position, far.position + Vector2(0, far.size.y), Vector2(0, h)]),
		_shade(Color(0.3, 0.24, 0.15)))
	s.draw_colored_polygon(PackedVector2Array([Vector2(w, 0), Vector2(w, h), far.end, far.position + Vector2(far.size.x, 0)]),
		_shade(Color(0.26, 0.2, 0.13)))
	s.draw_colored_polygon(PackedVector2Array([Vector2(0, h), far.position + Vector2(0, far.size.y), far.end, Vector2(w, h)]),
		_shade(Color(0.32, 0.07, 0.06)))
	s.draw_rect(far, Color(0.02, 0.02, 0.025))
	# Türen links und rechts, perspektivisch kleiner
	for i in 4:
		var t := 0.18 + i * 0.2
		var t2 := t + 0.08
		for side in [-1.0, 1.0]:
			var edge := 0.0 if side < 0 else w
			var corner_top := far.position + (Vector2(far.size.x, 0) if side > 0 else Vector2.ZERO)
			var corner_bot := corner_top + Vector2(0, far.size.y)
			var top1 := Vector2(edge, 0).lerp(corner_top, t)
			var bot1 := Vector2(edge, h).lerp(corner_bot, t)
			var top2 := Vector2(edge, 0).lerp(corner_top, t2)
			var bot2 := Vector2(edge, h).lerp(corner_bot, t2)
			var door_top1 := bot1.lerp(top1, 0.62)
			var door_top2 := bot2.lerp(top2, 0.62)
			s.draw_colored_polygon(PackedVector2Array([door_top1, door_top2, bot2, bot1]), _shade(Color(0.1, 0.055, 0.03), 0.9 - i * 0.15))
	# Lampe an der Decke
	var lamp := Vector2(VP.x - 3, 40)
	s.draw_rect(Rect2(lamp - Vector2(16, 2), Vector2(32, 4)), _shade(Color(1.0, 0.85, 0.55), 1.0))
	s.draw_circle(lamp + Vector2(0, 30), 70.0, Color(1.0, 0.8, 0.5, 0.05 * _flicker))
	# Die Silhouette am Flurende
	if _figure:
		var base := Vector2(VP.x, far.end.y)
		var dark := Color(0, 0, 0, 0.95)
		s.draw_rect(Rect2(base + Vector2(-3, -26), Vector2(6, 26)), dark)
		s.draw_circle(base + Vector2(0, -29), 3.2, dark)
		s.draw_rect(Rect2(base + Vector2(-6, -25), Vector2(2, 17)), dark)
		s.draw_rect(Rect2(base + Vector2(4, -25), Vector2(2, 19)), dark)
		s.draw_rect(Rect2(base + Vector2(-1.5, -30), Vector2(1, 1)), Color(0.9, 0.2, 0.1))
		s.draw_rect(Rect2(base + Vector2(1.0, -30), Vector2(1, 1)), Color(0.9, 0.2, 0.1))


# --- Debug -----------------------------------------------------------------------------

func _handle_debug_args() -> bool:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		return false
	for arg in args:
		if arg.begins_with("--load=") and SaveManager.slot_exists(arg.substr(7).to_int()):
			SaveManager.load_slot.call_deferred(arg.substr(7).to_int())
			return true
	if "--title" in args:
		return false
	var slot := 0
	for arg in args:
		if arg.begins_with("--new="):
			slot = arg.substr(6).to_int()   # neues Spiel in diesem Slot
	Game.start_new_game.call_deferred(slot)
	return true
