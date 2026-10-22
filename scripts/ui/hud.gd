class_name Hud
extends CanvasLayer
## Minimales HUD: Fadenkreuz, Interaktions-Hinweis, Gegenstand in der Hand, Geld,
## Meldungen, Versteck-Ansicht mit Atem-Anzeige, Debug-Werte (F3) und Bilder pro Sekunde (F10).
## Dazu: flackernde Kerze beim Autosave (Spielkonzept 8.6), Untertitel für Geräusche und ein roter
## Blitz, wenn dich ein Gast schlägt (6.3).

var debug_enabled := false
var fps_enabled := false          ## Bilder pro Sekunde und Bildzeit rechts oben (F10, --fps)

var _prompt: Label
var _held: Label
var _money: Label
var _message: Label
var _debug: Label
var _crosshair: ColorRect
var _hide_overlay: ColorRect
var _hide_material: ShaderMaterial
var _breath_bg: ColorRect
var _breath_fill: ColorRect
var _struggle_bg: ColorRect
var _struggle_fill: ColorRect
var _message_time := 0.0
var _autosave: Control
var _autosave_flame: ColorRect
var _autosave_time := 0.0
var _caption: Label
var _caption_time := 0.0
var _day := -1
var _debug_timer := 0.0
var _fps: Label
var _fps_timer := 0.0
var _hurt: ColorRect
var _sheet_overlay: ColorRect   ## unter dem Bettlaken: Sicht durch die Augenlöcher (5.9)


func _ready() -> void:
	layer = 10
	_hide_material = ShaderMaterial.new()
	_hide_material.shader = load("res://shaders/hide_overlay.gdshader")
	_hide_overlay = ColorRect.new()
	_hide_overlay.material = _hide_material
	_hide_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hide_overlay.visible = false
	add_child(_hide_overlay)
	_hide_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var sheet_material := ShaderMaterial.new()
	sheet_material.shader = load("res://shaders/sheet_overlay.gdshader")
	_sheet_overlay = ColorRect.new()
	_sheet_overlay.material = sheet_material
	_sheet_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sheet_overlay.visible = false
	add_child(_sheet_overlay)
	_sheet_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sheet_overlay.resized.connect(func() -> void:
		sheet_material.set_shader_parameter("aspect", _sheet_overlay.size.x / maxf(_sheet_overlay.size.y, 1.0)))

	_hurt = ColorRect.new()
	_hurt.color = Color(0.6, 0.0, 0.0, 0.0)
	_hurt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hurt)
	_hurt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_crosshair = ColorRect.new()
	_crosshair.color = Color(1, 1, 1, 0.6)
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_crosshair)
	_place(_crosshair, Vector4(0.5, 0.5, 0.5, 0.5), Vector4(-1, -1, 1, 1))

	_prompt = _label(10, HORIZONTAL_ALIGNMENT_CENTER)
	_place(_prompt, Vector4(0, 1, 1, 1), Vector4(8, -46, -8, -32))
	_held = _label(9, HORIZONTAL_ALIGNMENT_LEFT)
	_place(_held, Vector4(0, 1, 0.6, 1), Vector4(8, -18, 0, -4))
	_money = _label(9, HORIZONTAL_ALIGNMENT_RIGHT)
	_place(_money, Vector4(0.6, 0, 1, 0), Vector4(0, 4, -8, 18))
	_message = _label(10, HORIZONTAL_ALIGNMENT_CENTER)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place(_message, Vector4(0, 0.12, 1, 0.12), Vector4(16, 0, -16, 80))
	_fps = _label(8, HORIZONTAL_ALIGNMENT_RIGHT)
	_place(_fps, Vector4(0.6, 0, 1, 0), Vector4(0, 20, -8, 32))
	_fps.visible = false
	_debug = _label(8, HORIZONTAL_ALIGNMENT_LEFT)
	_place(_debug, Vector4(0, 0, 0.7, 0.7), Vector4(4, 4, 0, 0))
	_debug.visible = false

	_breath_bg = ColorRect.new()
	_breath_bg.color = Color(0, 0, 0, 0.6)
	add_child(_breath_bg)
	_place(_breath_bg, Vector4(0.5, 1, 0.5, 1), Vector4(-40, -27, 40, -23))
	_breath_fill = ColorRect.new()
	_breath_fill.color = Color(0.7, 0.8, 0.9, 0.9)
	_breath_bg.add_child(_breath_fill)
	_breath_fill.position = Vector2(1, 1)
	_breath_fill.size = Vector2(78, 2)
	_breath_bg.visible = false

	# Losreißen vom Lakengeist (Spielkonzept 4.18)
	_struggle_bg = ColorRect.new()
	_struggle_bg.color = Color(0, 0, 0, 0.6)
	add_child(_struggle_bg)
	_place(_struggle_bg, Vector4(0.5, 1, 0.5, 1), Vector4(-60, -40, 60, -34))
	_struggle_fill = ColorRect.new()
	_struggle_fill.color = Color(0.85, 0.85, 0.9, 0.9)
	_struggle_bg.add_child(_struggle_fill)
	_struggle_fill.position = Vector2(1, 1)
	_struggle_fill.size = Vector2(0, 4)
	_struggle_bg.visible = false

	# Autosave: kleine Kerze in der Ecke
	_autosave = Control.new()
	_autosave.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_autosave)
	_place(_autosave, Vector4(1, 1, 1, 1), Vector4(-62, -40, -6, -22))
	var wax := ColorRect.new()
	wax.color = Color(0.9, 0.86, 0.72)
	wax.position = Vector2(2, 7)
	wax.size = Vector2(4, 9)
	_autosave.add_child(wax)
	_autosave_flame = ColorRect.new()
	_autosave_flame.color = Color(1.0, 0.65, 0.2)
	_autosave_flame.position = Vector2(2.5, 2)
	_autosave_flame.size = Vector2(3, 5)
	_autosave.add_child(_autosave_flame)
	var saved := _label(8, HORIZONTAL_ALIGNMENT_LEFT, _autosave)
	saved.text = "Gespeichert"
	saved.position = Vector2(9, 4)
	_autosave.visible = false
	SaveManager.autosaved.connect(func() -> void:
		_autosave_time = 2.5
		_autosave.visible = true)

	_caption = _label(8, HORIZONTAL_ALIGNMENT_LEFT)
	_caption.label_settings.font_color = Color(0.85, 0.85, 0.75)
	_place(_caption, Vector4(0, 1, 0.6, 1), Vector4(8, -32, 0, -20))
	Game.caption_posted.connect(func(text: String) -> void:
		_caption.text = text
		_caption_time = 2.5)

	Game.money_changed.connect(_on_money_changed)
	Game.message_posted.connect(show_message)
	_on_money_changed(Game.money)


func _process(delta: float) -> void:
	if Game.director:
		var day := Calendar.today()
		if _day != -1 and day != _day:
			show_message(Calendar.date_text(Game.director.elapsed), 3.0)
		_day = day
	if _autosave_time > 0.0:
		_autosave_time -= delta
		_autosave_flame.size.y = randf_range(3.5, 5.5)
		_autosave.modulate.a = clampf(_autosave_time, 0.0, 1.0)
		_autosave.visible = _autosave_time > 0.0
	if _caption_time > 0.0:
		_caption_time -= delta
		_caption.modulate.a = clampf(_caption_time, 0.0, 1.0)
		if _caption_time <= 0.0:
			_caption.text = ""
	if _hurt.color.a > 0.0:
		_hurt.color.a = maxf(0.0, _hurt.color.a - delta * 0.6)
	if _message_time > 0.0:
		_message_time -= delta
		_message.modulate.a = clampf(_message_time, 0.0, 1.0)
	if Input.is_action_just_pressed("debug_overlay"):
		debug_enabled = not debug_enabled
	if Input.is_action_just_pressed("debug_fps"):
		fps_enabled = not fps_enabled
		_fps_timer = 0.0
	_fps.visible = fps_enabled
	if fps_enabled:
		_fps_timer -= delta
		if _fps_timer <= 0.0:
			_fps_timer = 0.25
			var fps := Engine.get_frames_per_second()
			_fps.text = "%d FPS · %s ms" % [fps, String.num(1000.0 / maxf(fps, 1.0), 1).replace(".", ",")]
	_debug.visible = debug_enabled
	if debug_enabled and Game.director:
		_debug_timer -= delta
		if _debug_timer <= 0.0:
			_debug_timer = 0.25
			_debug.text = Game.director.debug_text()


## Roter Blitz – je härter der Schlag, desto kräftiger.
func flash_hurt(amount: float) -> void:
	_hurt.color.a = clampf(0.25 + amount, 0.3, 0.6)


func set_prompt(text: String) -> void:
	_prompt.text = text


func set_held(item_name: String) -> void:
	_held.text = "" if item_name == "" else "In der Hand: %s" % item_name


func show_message(text: String, duration: float = 3.5) -> void:
	_message.text = text
	_message_time = duration
	_message.modulate.a = 1.0


## Losreißen: Balken 0..1, < 0 blendet ihn aus.
func set_struggle(value: float) -> void:
	_struggle_bg.visible = value >= 0.0
	_struggle_fill.size.x = 118.0 * clampf(value, 0.0, 1.0)


## Bettlaken übergeworfen (Spielkonzept 5.9): Stoff ringsum, Blick durch zwei Augenlöcher – auch im Versteck.
func set_disguised(on: bool) -> void:
	_sheet_overlay.visible = on


## 0 = kein Versteck, 1 = Schrank, 2 = unter dem Bett, 3 = im Bett schlafen (Augen zu)
func set_hide_mode(mode: int) -> void:
	_hide_overlay.visible = mode > 0
	_hide_material.set_shader_parameter("mode", mode)
	_crosshair.visible = mode == 0
	if mode == 0:
		_breath_bg.visible = false


func set_hide_state(stress: float, breath_ratio: float, holding: bool) -> void:
	_hide_material.set_shader_parameter("stress", stress)
	_breath_bg.visible = holding or breath_ratio < 0.999
	_breath_fill.size.x = 78.0 * breath_ratio
	_breath_fill.color = Color(0.9, 0.4, 0.3, 0.9) if breath_ratio < 0.3 else Color(0.7, 0.8, 0.9, 0.9)


func _on_money_changed(amount: int) -> void:
	_money.text = "Geld: %d" % amount


## Weiße Schrift mit schwarzem Umriss, im HUD (oder unter `parent`).
func _label(font_size: int, align: HorizontalAlignment, parent: Node = null) -> Label:
	var label := UiKit.plain_label(font_size, Color.WHITE, 3)
	label.horizontal_alignment = align
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	(parent if parent else self).add_child(label)
	return label


## anchors/offsets jeweils als (links, oben, rechts, unten)
func _place(control: Control, anchors: Vector4, offsets: Vector4) -> void:
	control.anchor_left = anchors.x
	control.anchor_top = anchors.y
	control.anchor_right = anchors.z
	control.anchor_bottom = anchors.w
	control.offset_left = offsets.x
	control.offset_top = offsets.y
	control.offset_right = offsets.z
	control.offset_bottom = offsets.w
