class_name Hud
extends CanvasLayer
## Minimales HUD: Fadenkreuz, Interaktions-Hinweis (darüber ein Aktions-Symbol, IconArt), Gegenstand in der Hand, Tasche (kleine Fächer unten rechts,
## mit [Q] gehalten groß über dem verschwommenen Spiel – Spielkonzept 3.2), Geld,
## Meldungen (Todesmeldungen mit Totenkopf), Versteck-Ansicht mit Atem-Anzeige, Debug-Werte (F3) und Bilder pro Sekunde (F10).
## Dazu: flackernde Kerze beim Autosave (Spielkonzept 8.6), Untertitel für Geräusche und ein roter
## Blitz, wenn dich ein Gast schlägt (6.3).

## Kantenlänge der Symbole über Hinweis und Meldung (Pixel, interne Auflösung)
const PROMPT_ICON := 24
const MESSAGE_ICON := 24

const WHITE_FADE := 3.5   ## flash_white: so schnell verblasst der Blitz (Deckkraft je Sekunde)
const THROW_BAR := 24.0    ## Breite des Kraftbalkens beim Ausholen (Pixel, interne Auflösung, 3.13)

var debug_enabled := false
var fps_enabled := false          ## Bilder pro Sekunde und Bildzeit rechts oben (F10, --fps)

var _prompt: Label
var _prompt_icon: TextureRect   ## Aktions-Symbol über dem Hinweis (IconArt, PROMPT_ICON Pixel)
var _message_icon: TextureRect  ## Symbol über einer Meldung (Totenkopf, MESSAGE_ICON Pixel)
var _held: Label
var _icons: ItemIcons
var _bag_mini: Control                    ## kleine Fächer unten rechts (immer, sobald etwas drin ist)
var _bag_mini_icons: Array[TextureRect] = []
var _bag_blur: ColorRect                  ## Tasche offen: das Spiel verschwimmt
var _bag_blur_material: ShaderMaterial
var _bag_menu: Control                    ## Tasche offen: große Fächer
var _bag_frames: Array[ColorRect] = []
var _bag_slot_icons: Array[TextureRect] = []
var _bag_info: Label
var _bag_count: Label
var _bag_filled := false
var _money: Label
var _message: Label
var _sleep_clock: Label   ## Uhrzeit beim Zeitsprung im Schlaf (Spielkonzept 3.6)
var _black: ColorRect     ## Schwarzblende (Beerdigen, Spielkonzept 5.15) – unter den Meldungen
var _debug: Label
var _crosshair: ColorRect
var _throw_bar: ColorRect    ## Wurfkraft unter dem Fadenkreuz beim Ausholen (Spielkonzept 3.13)
var _throw_fill: ColorRect
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
var _noted: Label                          ## „Notiert“ über der Autosave-Kerze (Notizbuch, Spielkonzept 3.10)
var _noted_time := 0.0
var _day := -1
var _debug_timer := 0.0
var _fps: Label
var _fps_timer := 0.0
var _hurt: ColorRect
var _white: ColorRect   ## Blitz übers ganze Bild (Spuk im Dachboden, flash_white)
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
	_black = ColorRect.new()
	_black.color = Color(0, 0, 0, 0)
	_black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_black)
	_black.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
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
	_white = ColorRect.new()
	_white.color = Color(0.85, 0.9, 1.0, 0.0)
	_white.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_white)
	_white.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_crosshair = ColorRect.new()
	_crosshair.color = Color(1, 1, 1, 0.6)
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_crosshair)
	_place(_crosshair, Vector4(0.5, 0.5, 0.5, 0.5), Vector4(-1, -1, 1, 1))
	_throw_bar = ColorRect.new()
	_throw_bar.color = Color(0, 0, 0, 0.45)
	_throw_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_throw_bar.visible = false
	add_child(_throw_bar)
	_place(_throw_bar, Vector4(0.5, 0.5, 0.5, 0.5), Vector4(-THROW_BAR / 2.0, 5, THROW_BAR / 2.0, 7))
	_throw_fill = ColorRect.new()
	_throw_fill.color = Color(1, 1, 1, 0.75)
	_throw_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_throw_bar.add_child(_throw_fill)

	_prompt = _label(10, HORIZONTAL_ALIGNMENT_CENTER)
	_place(_prompt, Vector4(0, 1, 1, 1), Vector4(8, -46, -8, -32))
	_prompt_icon = _symbol_rect()
	_place(_prompt_icon, Vector4(0.5, 1, 0.5, 1), Vector4(-PROMPT_ICON / 2.0, -48 - PROMPT_ICON, PROMPT_ICON / 2.0, -48))
	_held = _label(9, HORIZONTAL_ALIGNMENT_LEFT)
	_place(_held, Vector4(0, 1, 0.6, 1), Vector4(8, -18, 0, -4))
	_icons = ItemIcons.new()
	add_child(_icons)
	_build_bag_mini()
	_money = _label(9, HORIZONTAL_ALIGNMENT_RIGHT)
	_place(_money, Vector4(0.6, 0, 1, 0), Vector4(0, 4, -8, 18))
	_message = _label(10, HORIZONTAL_ALIGNMENT_CENTER)
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_place(_message, Vector4(0, 0.12, 1, 0.12), Vector4(16, 0, -16, 80))
	_message_icon = _symbol_rect()
	_place(_message_icon, Vector4(0.5, 0.12, 0.5, 0.12), Vector4(-MESSAGE_ICON / 2.0, -MESSAGE_ICON - 2, MESSAGE_ICON / 2.0, -2))
	_sleep_clock = _label(14, HORIZONTAL_ALIGNMENT_CENTER)
	_sleep_clock.modulate = Color(0.75, 0.72, 0.68, 0.55)
	_place(_sleep_clock, Vector4(0, 0.5, 1, 0.5), Vector4(0, -12, 0, 12))
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

	# Autosave: kleine Kerze in der Ecke (über den kleinen Fächern der Tasche)
	_autosave = Control.new()
	_autosave.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_autosave)
	_place(_autosave, Vector4(1, 1, 1, 1), Vector4(-62, -42, -6, -24))
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

	_noted = _label(8, HORIZONTAL_ALIGNMENT_RIGHT)
	_noted.text = "Notiert"
	_noted.label_settings.font_color = Color(0.9, 0.85, 0.7)
	_place(_noted, Vector4(1, 1, 1, 1), Vector4(-80, -58, -6, -44))
	_noted.visible = false

	_caption = _label(8, HORIZONTAL_ALIGNMENT_LEFT)
	_caption.label_settings.font_color = Color(0.85, 0.85, 0.75)
	_place(_caption, Vector4(0, 1, 0.6, 1), Vector4(8, -32, 0, -20))
	Game.caption_posted.connect(func(text: String) -> void:
		_caption.text = text
		_caption_time = 2.5)

	Game.money_changed.connect(_on_money_changed)
	Game.message_posted.connect(show_message)
	_on_money_changed(Game.money)
	_build_bag_menu()   # zuletzt: liegt über allem, die Unschärfe erfasst auch die übrigen Anzeigen


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
	if _noted_time > 0.0:
		_noted_time -= delta
		_noted.modulate.a = clampf(_noted_time, 0.0, 1.0)
		_noted.visible = _noted_time > 0.0
	if _caption_time > 0.0:
		_caption_time -= delta
		_caption.modulate.a = clampf(_caption_time, 0.0, 1.0)
		if _caption_time <= 0.0:
			_caption.text = ""
	if _hurt.color.a > 0.0:
		_hurt.color.a = maxf(0.0, _hurt.color.a - delta * 0.6)
	if _white.color.a > 0.0:
		_white.color.a = maxf(0.0, _white.color.a - delta * WHITE_FADE)
	if _bag_blur.visible:
		var amount: float = _bag_blur_material.get_shader_parameter("amount")
		_bag_blur_material.set_shader_parameter("amount", minf(1.0, amount + delta * 8.0))
	if _message_time > 0.0:
		_message_time -= delta
		_message.modulate.a = clampf(_message_time, 0.0, 1.0)
		_message_icon.modulate.a = _message.modulate.a
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


## Grellweißer Blitz übers Bild (amount = Deckkraft), verblasst mit WHITE_FADE je Sekunde – der Spuk im Dachboden
## (AtticSpook) versteckt darin den Dreh.
func flash_white(amount: float) -> void:
	_white.color.a = clampf(amount, 0.0, 1.0)


## Roter Blitz – je härter der Schlag, desto kräftiger.
func flash_hurt(amount: float) -> void:
	_hurt.color.a = clampf(0.25 + amount, 0.3, 0.6)


## Interaktions-Hinweis; icon: Aktions-Symbol darüber (IconArt-Name, "" = keins).
func set_prompt(text: String, icon: String = "") -> void:
	_prompt.text = text
	_prompt_icon.texture = IconArt.texture(icon, PROMPT_ICON) if text != "" else null


## Wurfkraft beim Ausholen (Spielkonzept 3.13): 0 … 1 als schmaler Balken unter dem Fadenkreuz, 0 = weg.
func set_throw_power(power: float) -> void:
	_throw_bar.visible = power > 0.0
	_throw_fill.size = Vector2(THROW_BAR * power, 2.0)


func set_held(item_name: String) -> void:
	_held.text = "" if item_name == "" else "In der Hand: %s" % item_name


# --- Tasche (Spielkonzept 3.2) ---------------------------------------------------------------

const BAG_SLOT := 46       ## große Fächer: Kantenlänge (Pixel, interne Auflösung)
const BAG_GAP := 6
const BAG_MINI := 18       ## kleine Fächer unten rechts
const SLOT_COLOR := Color(0.05, 0.04, 0.04, 0.7)
const SELECT_COLOR := Color(1.0, 0.62, 0.15)   ## Kürbisorange


## Kleine Fächer unten rechts: immer sichtbar, sobald etwas in der Tasche ist.
func set_bag(items: Array[Item], slots: int) -> void:
	for i in _bag_mini_icons.size():
		_bag_mini_icons[i].texture = _icons.icon(items[i]) if i < items.size() else null
	_bag_filled = not items.is_empty()
	_bag_mini.visible = _bag_filled and not _bag_menu.visible
	_bag_count.text = "Tasche %d/%d" % [items.size(), slots]


## [Q] gehalten: große Fächer über dem verschwommenen Spiel, `sel` hervorgehoben, darunter was beim Loslassen passiert.
func show_bag_menu(open: bool, items: Array[Item] = [], slots: int = 0, sel: int = -1, held: Item = null) -> void:
	if open and not _bag_menu.visible:
		_bag_blur_material.set_shader_parameter("amount", 0.0)
	_bag_menu.visible = open
	_bag_blur.visible = open
	_crosshair.visible = not open and not _hide_overlay.visible
	_bag_mini.visible = not open and _bag_filled
	if not open:
		return
	for i in _bag_frames.size():
		_bag_slot_icons[i].texture = _icons.icon(items[i]) if i < items.size() else null
		_bag_frames[i].color = SELECT_COLOR if i == sel else Color(0.4, 0.35, 0.3, 0.6)
	var text := "Maus nach links oder rechts zeigt auf ein Fach"
	if sel >= 0 and sel < items.size():
		text = "%s in die Hand nehmen" % items[sel].display_name
		if held:
			text += " – %s fällt zu Boden" % held.display_name
	elif sel >= 0 and held and held.fits_pocket():
		text = "%s einstecken" % held.display_name
	elif sel >= 0 and held:
		text = "Leeres Fach – %s passt nicht hinein" % held.display_name
	elif sel >= 0:
		text = "Leeres Fach"
	_bag_info.text = text
	_bag_count.text = "Tasche %d/%d" % [items.size(), slots]


func _build_bag_mini() -> void:
	_bag_mini = Control.new()
	_bag_mini.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bag_mini.modulate.a = 0.8
	add_child(_bag_mini)
	var width := Player.BAG_SLOTS * (BAG_MINI + 2) - 2
	_place(_bag_mini, Vector4(1, 1, 1, 1), Vector4(-8 - width, -4 - BAG_MINI, -8, -4))
	for i in Player.BAG_SLOTS:
		var bg := ColorRect.new()
		bg.color = SLOT_COLOR
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.position = Vector2(i * (BAG_MINI + 2), 0)
		bg.size = Vector2(BAG_MINI, BAG_MINI)
		_bag_mini.add_child(bg)
		_bag_mini_icons.append(_icon_rect(bg, BAG_MINI - 2))
	_bag_mini.visible = false


func _build_bag_menu() -> void:
	_bag_blur_material = ShaderMaterial.new()
	_bag_blur_material.shader = load("res://shaders/bag_blur.gdshader")
	_bag_blur = ColorRect.new()
	_bag_blur.material = _bag_blur_material
	_bag_blur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bag_blur.visible = false
	add_child(_bag_blur)
	_bag_blur.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_bag_menu = Control.new()
	_bag_menu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bag_menu.visible = false
	add_child(_bag_menu)
	_bag_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var width := Player.BAG_SLOTS * (BAG_SLOT + BAG_GAP) - BAG_GAP
	var row := Control.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bag_menu.add_child(row)
	_place(row, Vector4(0.5, 0.5, 0.5, 0.5), Vector4(-width / 2.0, -BAG_SLOT / 2.0, width / 2.0, BAG_SLOT / 2.0))
	for i in Player.BAG_SLOTS:
		var frame := ColorRect.new()   # Rahmen: hervorgehoben, wenn gewählt
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.position = Vector2(i * (BAG_SLOT + BAG_GAP) - 1, -1)
		frame.size = Vector2(BAG_SLOT + 2, BAG_SLOT + 2)
		row.add_child(frame)
		_bag_frames.append(frame)
		var bg := ColorRect.new()
		bg.color = SLOT_COLOR
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.position = Vector2(1, 1)
		bg.size = Vector2(BAG_SLOT, BAG_SLOT)
		frame.add_child(bg)
		_bag_slot_icons.append(_icon_rect(bg, BAG_SLOT - 6))
		var number := _label(8, HORIZONTAL_ALIGNMENT_LEFT, bg)
		number.text = str(i + 1)
		number.position = Vector2(3, 1)
	var title := _label(10, HORIZONTAL_ALIGNMENT_CENTER, _bag_menu)
	_place(title, Vector4(0, 0.5, 1, 0.5), Vector4(0, -BAG_SLOT / 2.0 - 22, 0, -BAG_SLOT / 2.0 - 6))
	_bag_count = title
	_bag_info = _label(10, HORIZONTAL_ALIGNMENT_CENTER, _bag_menu)
	_place(_bag_info, Vector4(0, 0.5, 1, 0.5), Vector4(8, BAG_SLOT / 2.0 + 8, -8, BAG_SLOT / 2.0 + 24))
	var hint := _label(8, HORIZONTAL_ALIGNMENT_CENTER, _bag_menu)
	hint.label_settings.font_color = Color(0.75, 0.72, 0.65)
	hint.text = "Maus · Mausrad · 1–6 wählen   ·   Q loslassen: in die Hand   ·   Rechtsklick: abbrechen"
	_place(hint, Vector4(0, 0.5, 1, 0.5), Vector4(8, BAG_SLOT / 2.0 + 26, -8, BAG_SLOT / 2.0 + 40))


## Bild eines Gegenstands mittig in einem Fach
func _icon_rect(parent: Control, size: int) -> TextureRect:
	var rect := TextureRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.position = (parent.size - Vector2(size, size)) / 2.0
	rect.size = Vector2(size, size)
	parent.add_child(rect)
	return rect


## Meldung oben; icon: Symbol darüber (IconArt-Name, z. B. „dead“ bei Todesmeldungen).
func show_message(text: String, duration: float = 3.5, icon: String = "") -> void:
	_message.text = text
	_message_time = duration
	_message.modulate.a = 1.0
	_message_icon.texture = IconArt.texture(icon, MESSAGE_ICON)
	_message_icon.modulate.a = 1.0


## Neuer Eintrag im Notizbuch (3.10): kurz „Notiert“ – mehr nicht.
func show_noted() -> void:
	_noted_time = 2.5
	_noted.visible = true


## Losreißen: Balken 0..1, < 0 blendet ihn aus.
func set_struggle(value: float) -> void:
	_struggle_bg.visible = value >= 0.0
	_struggle_fill.size.x = 118.0 * clampf(value, 0.0, 1.0)


## Bettlaken übergeworfen (Spielkonzept 5.9): Stoff ringsum, Blick durch zwei Augenlöcher – auch im Versteck.
func set_disguised(on: bool) -> void:
	_sheet_overlay.visible = on


## 0 = kein Versteck, 1 = Schrank, 2 = unter dem Bett, 3 = im Bett schlafen (Augen zu)
## Ab- (black) oder wieder aufblenden in t Sekunden.
func fade_black(black: bool, t: float) -> void:
	var tween := create_tween()
	tween.tween_property(_black, "color:a", 1.0 if black else 0.0, t)


## Uhrzeit mitten im Bild, solange die Zeit im Schlaf springt ("" = aus).
func set_sleep_clock(text: String) -> void:
	_sleep_clock.text = text
	_sleep_clock.visible = text != ""


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


func _symbol_rect() -> TextureRect:
	var rect := TextureRect.new()
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	return rect


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
