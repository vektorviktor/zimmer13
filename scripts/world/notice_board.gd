class_name NoticeBoard
extends Node3D
## Aushangbrett in der Lobby (Spielkonzept 2.5): Korktafel im dunklen Holzrahmen, oben ein Messingschild „Mitteilungen
## der Direktion“, darüber eine eigene kleine Bilderleuchte (brennt, solange das Lobbylicht an ist). Daran hängen
## einzelne Blätter (Sheet), jedes für sich lesbar wie ein Zettel; Inhalt und Wechsel setzt DoorContest (pin).
## Ursprung auf der Wandfläche in der Mitte der Tafel, +Z zeigt in den Raum.

const SIZE := Vector2(1.2, 0.9)
const FRAME := 0.05
const DEPTH := 0.03
const CORK := Color(0.52, 0.36, 0.21)
const WOOD := Color(0.2, 0.11, 0.06)
const BRASS := Color(0.62, 0.48, 0.2)
const PAPER := Color(0.9, 0.87, 0.78)
const INK := Color(0.1, 0.07, 0.05)
const PLATE_TEXT := "Mitteilungen der Direktion"
## Bilderleuchte: so hoch über der Tafel, so weit vor der Wand, so hell und weit
const LAMP_UP := 0.12
const LAMP_OUT := 0.32
const LAMP_ENERGY := 0.4
const LAMP_RANGE := 1.6
## Schrift auf den Blättern: Überschrift und Text – fein gerastert (PX), so groß im Raum (Höhe ≈ PX × TEXT_PIXEL)
const HEAD_PX := 96
const BODY_PX := 48
const PLATE_PX := 72
const TEXT_PIXEL := 0.0004

var _sheets := {}   ## id → Sheet
var _light: FlickerLight
var _switch: LightSwitch
var _check := 0.0


func _ready() -> void:
	add_to_group("notice_boards")
	_build()


## Blatt anheften bzw. ersetzen: Lage (Mitte, auf der Tafel), Größe, Überschrift und Text auf dem Papier, Titel und Text
## beim Lesen; jot: was sich die Figur davon beim Lesen notiert (Notizbuch, 3.10), einmal je jot_id.
func pin(id: String, at: Vector2, size: Vector2, headline: String, body: String, title: String, text: String,
		jot_id: String = "", jot: String = "") -> void:
	var sheet: Sheet = _sheets.get(id)
	if sheet == null:
		sheet = Sheet.new()
		add_child(sheet)
		_sheets[id] = sheet
	sheet.position = Vector3(at.x, at.y, DEPTH + 0.004)
	sheet.rotation.z = deg_to_rad(float(posmod(id.hash(), 5) - 2) * 0.8)   # leicht schief angeheftet
	sheet.show_text(size, headline, body, title, text)
	sheet.jot_id = jot_id
	sheet.jot = jot


## Blatt abnehmen (Spielstand von vorher geladen) – fehlt es, geschieht nichts.
func unpin(id: String) -> void:
	var sheet: Sheet = _sheets.get(id)
	if sheet:
		_sheets.erase(id)
		sheet.queue_free()


## Punkt vor der Tafel am Boden (Gäste lesen dort) – side verschiebt seitlich (m).
func reading_spot(side: float) -> Vector3:
	var p := global_transform * Vector3(side, 0, 1.1)
	return Vector3(p.x, global_position.y - position.y, p.z)


func _process(delta: float) -> void:
	_check -= delta
	if _check > 0.0:
		return
	_check = 0.5
	if _switch == null:
		_switch = LightSwitch.find(get_tree(), "lobby")
	if _light:
		_light.switched_off = _switch != null and not _switch.on


func _build() -> void:
	var wood := Mat.psx(WOOD)
	var brass := Mat.psx(BRASS)
	Geo.mesh(self, Geo.box(Vector3(SIZE.x, SIZE.y, DEPTH)), Mat.psx(CORK), Vector3(0, 0, DEPTH / 2.0))
	var w := SIZE.x + FRAME * 2.0
	for y: float in [-1.0, 1.0]:
		Geo.mesh(self, Geo.box(Vector3(w, FRAME, DEPTH + 0.015)), wood, Vector3(0, y * (SIZE.y + FRAME) / 2.0, (DEPTH + 0.015) / 2.0))
	for x: float in [-1.0, 1.0]:
		Geo.mesh(self, Geo.box(Vector3(FRAME, SIZE.y, DEPTH + 0.015)), wood, Vector3(x * (SIZE.x + FRAME) / 2.0, 0, (DEPTH + 0.015) / 2.0))
	# Messingschild auf der oberen Leiste
	var top := SIZE.y / 2.0 + FRAME
	Geo.mesh(self, Geo.box(Vector3(0.56, 0.075, 0.008)), brass, Vector3(0, top + 0.03, 0.004))
	var plate := _label(PLATE_TEXT, PLATE_PX, load(LevelBuilder.SIGN_FONT))
	plate.position = Vector3(0, top + 0.03, 0.0095)
	plate.modulate = Color(0.16, 0.1, 0.04)
	add_child(plate)
	# Bilderleuchte: Arm aus der Wand, Schirm über der Tafel, Licht nach unten auf die Blätter
	var lamp_y := top + LAMP_UP + 0.04
	Geo.mesh(self, Geo.box(Vector3(0.02, 0.02, LAMP_OUT)), brass, Vector3(0, lamp_y, LAMP_OUT / 2.0))
	var hood := Geo.mesh(self, Geo.box(Vector3(0.5, 0.05, 0.09)), brass, Vector3(0, lamp_y - 0.02, LAMP_OUT))
	hood.rotation.x = -0.35
	var bulb := Mat.psx(Color(1, 0.9, 0.7), "", 1.0, Color(1, 0.85, 0.55), 2.0, false)
	Geo.mesh(self, Geo.box(Vector3(0.44, 0.012, 0.02)), bulb, Vector3(0, lamp_y - 0.05, LAMP_OUT - 0.01))
	_light = FlickerLight.new()
	_light.position = Vector3(0, top - 0.2, 0.3)   # unter dem Schirm, vor den Blättern – die Tapete darüber bleibt dunkel
	_light.light_color = Color(1.0, 0.82, 0.58)
	_light.base_energy = LAMP_ENERGY
	_light.omni_range = LAMP_RANGE
	_light.shadow_enabled = false
	_light.distance_fade_enabled = true
	_light.distance_fade_begin = 20.0
	_light.distance_fade_length = 5.0
	_light.add_to_group("lamps")
	add_child(_light)


static func _label(text: String, px: int, font: Font = null) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = px
	if font:
		label.font = font
	label.pixel_size = TEXT_PIXEL
	label.modulate = INK
	label.outline_size = 0
	label.shaded = true
	label.double_sided = false
	label.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	return label


## Ein Blatt Papier an der Tafel: Überschrift und Text im Raum (beleuchtet wie alles andere), [E] liest es ganz.
class Sheet:
	extends StaticBody3D

	var title := ""
	var text := ""
	var jot_id := ""
	var jot := ""
	var _paper: MeshInstance3D
	var _head: Label3D
	var _body: Label3D

	func _ready() -> void:
		collision_layer = 4
		collision_mask = 0
		set_meta("interactable", self)

	func show_text(size: Vector2, headline: String, body: String, p_title: String, p_text: String) -> void:
		title = p_title
		text = p_text
		for child in get_children():
			child.queue_free()
		_paper = Geo.mesh(self, Geo.box(Vector3(size.x, size.y, 0.003)), Mat.psx(PAPER), Vector3.ZERO)
		Geo.mesh(self, Geo.sphere(0.008, 0.008, 6, 3), Mat.psx(Color(0.6, 0.08, 0.06)), Vector3(0, size.y / 2.0 - 0.025, 0.004))   # Reißzwecke
		Geo.add_box_shape(self, Vector3(size.x, size.y, 0.04), Vector3.ZERO)
		var margin := 0.035
		var y := size.y / 2.0 - margin - 0.01
		if headline != "":
			_head = NoticeBoard._label(headline, HEAD_PX, load(LevelBuilder.SIGN_FONT))
			_head.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			_head.position = Vector3(0, y, 0.002)
			add_child(_head)
			y -= float(headline.count("\n") + 1) * HEAD_PX * TEXT_PIXEL * 1.25 + 0.015
		_body = NoticeBoard._label(body, BODY_PX)
		_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_body.width = (size.x - margin * 2.0) / TEXT_PIXEL
		_body.position = Vector3(0, y, 0.002)
		add_child(_body)

	func get_prompt(_player: Player) -> String:
		return "Aushang lesen [E]"

	func interact(_player: Player) -> void:
		if Game.menus:
			Game.menus.open_note(title, text)
		if Game.notebook and jot != "":
			Game.notebook.add_note(jot_id, jot, "Brett in der Lobby")
