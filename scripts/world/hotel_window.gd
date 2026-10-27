class_name HotelWindow
extends Node3D
## Fenster (Spielkonzept 7.3): eine Barriere, durch die man hindurchsieht.
##   Klares Glas (Ebene 7): Blick in beide Richtungen – Monster und Gäste sehen auch hindurch.
##   Milchglas (Ebene 9): nur Licht und Umrisse – keine Sicht für Monster und Zeugen.
## Außenfenster haben Vorhänge: zugezogen kein Blick und kein Mondlicht (Ebene 10 blockiert
## nur Sicht- und Lichtprüfung, nicht die Bewegung). Spieler und Gäste ziehen sie auf und zu.
## Ursprung = Mitte der Fensteröffnung, lokale +Z zeigt in den Raum.

const LAYER_GLASS := 64
const LAYER_FROSTED := 256
const LAYER_BLOCK := 512
## Kollision der Scheibe so tief wie die Wand – eine Nische in der Wand fängt die
## Spielerkapsel ein, wenn man schräg daran entlangläuft.
const PANE_DEPTH := 0.2
## Regentropfen: so weit (m) vor der Außenseite des Glases
const DROPS_GAP := 0.006

static var _drops_mat: ShaderMaterial

var width := 1.4
var height := 1.4
var frosted := false
var exterior := false
var room_id := ""
var closed := false
## Fenster eines noch gesperrten Zimmers (Bauphase, Spielkonzept 7.5): Vorhang immer zu, nicht bedienbar
var sealed := false

var _left: Node3D
var _right: Node3D
var _block: StaticBody3D
var _tween: Tween


func setup(p_width: float, p_height: float, p_frosted: bool, p_exterior: bool, p_room: String) -> HotelWindow:
	width = p_width
	height = p_height
	frosted = p_frosted
	exterior = p_exterior
	room_id = p_room
	return self


func _ready() -> void:
	add_to_group("windows")
	var pane := StaticBody3D.new()
	pane.collision_layer = LAYER_FROSTED if frosted else LAYER_GLASS
	pane.collision_mask = 0
	add_child(pane)
	# Eine einzelne Fläche statt einer dünnen Box: Vorder- und Rückseite einer durchsichtigen Box
	# sortieren sich je nach Winkel falsch, und die Unterkante flimmert mit der Fensterbank.
	var quad := QuadMesh.new()
	quad.size = Vector2(width, height)
	var glass := Geo.mesh(pane, quad, Mat.frosted_glass() if frosted else Mat.glass(), Vector3.ZERO)
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Geo.add_box_shape(pane, Vector3(width, height, PANE_DEPTH), Vector3.ZERO)
	# Zarge, Bekleidung, Fensterbank und Rahmen; dazu das Fensterkreuz
	add_child(OpeningFrame.new().setup(-width / 2.0, -height / 2.0, width, height, PANE_DEPTH, true))
	var frame := Mat.psx(OpeningFrame.COLOR)
	Geo.mesh(pane, Geo.box(Vector3(width, 0.05, 0.05)), frame, Vector3.ZERO)
	Geo.mesh(pane, Geo.box(Vector3(0.05, height, 0.05)), frame, Vector3.ZERO)
	if exterior and not frosted:
		_rain_drops(quad)
	if not has_curtains():
		return
	if sealed:
		closed = true
	else:
		pane.set_meta("interactable", self)
	var cloth := Mat.psx(Color(0.42, 0.12, 0.12), "", 1.0)
	Geo.mesh(self, Geo.box(Vector3(width + 0.5, 0.04, 0.04)), Mat.psx(Color(0.35, 0.25, 0.12)), Vector3(0, height / 2.0 + 0.2, 0.2))
	_left = _curtain(-1.0, cloth)
	_right = _curtain(1.0, cloth)
	# Unsichtbare Sperre, solange die Vorhänge zu sind: blockiert Blick und Licht
	_block = StaticBody3D.new()
	_block.collision_layer = 0
	_block.collision_mask = 0
	if not sealed:
		_block.set_meta("interactable", self)
	add_child(_block)
	Geo.add_box_shape(_block, Vector3(width + 0.3, height + 0.3, 0.05), Vector3(0, 0, 0.2))
	_apply(true)


## Regen an der Scheibe (Spielkonzept 7.8): Tropfen auf der Außenseite, knapp vor dem Glas. Weather schaltet alle
## (Gruppe „rain_panes“) nur sichtbar, solange die Scheiben nass sind.
func _rain_drops(quad: QuadMesh) -> void:
	if _drops_mat == null:
		_drops_mat = ShaderMaterial.new()
		_drops_mat.shader = load("res://shaders/window_rain.gdshader")
		_drops_mat.render_priority = 1   # nach dem Glas zeichnen, das fast an derselben Stelle liegt
	var drops := Geo.mesh(self, quad, _drops_mat, Vector3(0, 0, -DROPS_GAP))
	drops.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	drops.visible = Game.weather != null and Game.weather.panes_wet()
	drops.add_to_group("rain_panes")


func has_curtains() -> bool:
	return exterior and not frosted


## Fällt Mondlicht herein?
func lets_moonlight() -> bool:
	return exterior and not closed


func inside_point() -> Vector3:
	return global_transform * Vector3(0, 0, 0.4)


func get_prompt(_player: Player) -> String:
	return "Vorhang aufziehen [E]" if closed else "Vorhang zuziehen [E]"


func interact(_player: Player) -> void:
	set_closed(not closed)


func set_closed(value: bool, instant: bool = false) -> void:
	if not has_curtains() or sealed or (closed == value and not instant):
		return
	closed = value
	_apply(instant)
	if not instant:
		Game.noise("curtain", global_position)


func _apply(instant: bool) -> void:
	_block.collision_layer = LAYER_BLOCK if closed else 0
	var target_scale := 1.0 if closed else 0.25
	if _tween:
		_tween.kill()
	if instant:
		for pivot in [_left, _right]:
			pivot.scale.x = target_scale
		return
	_tween = create_tween().set_parallel(true)
	for pivot in [_left, _right]:
		_tween.tween_property(pivot, "scale:x", target_scale, 0.5).set_trans(Tween.TRANS_SINE)


## Vorhangbahn, die vom Rand aus zur Mitte gezogen wird (Pivot am äußeren Rand).
func _curtain(side: float, cloth: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(side * (width / 2.0 + 0.25), 0.05, 0.2)
	add_child(pivot)
	var w := width / 2.0 + 0.25
	for i in 3:
		var fold := Geo.mesh(pivot, Geo.box(Vector3(w / 3.0, height + 0.35, 0.03)), cloth,
			Vector3(-side * (w / 6.0 + i * w / 3.0), 0, 0.02 * (i % 2)))
		fold.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return pivot


func save_state() -> Dictionary:
	return {"closed": closed}


func load_state(data: Dictionary) -> void:
	closed = sealed or bool(data.get("closed", false))
	if has_curtains():
		_apply(true)
