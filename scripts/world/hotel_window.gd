class_name HotelWindow
extends Node3D
## Fenster (Spielkonzept 7.3): eine Barriere, durch die man hindurchsieht.
##   Klares Glas (Ebene 7): Blick in beide Richtungen – Monster und Gäste sehen auch hindurch.
##   Milchglas (Ebene 9): nur Licht und Umrisse – keine Sicht für Monster und Zeugen.
## Außenfenster haben Vorhänge: zugezogen kein Blick und kein Mondlicht (Ebene 2 blockiert
## Sicht- und Lichtprüfung). Spieler und Gäste ziehen sie auf und zu.
## Ursprung = Mitte der Fensteröffnung, lokale +Z zeigt in den Raum.

const LAYER_GLASS := 64
const LAYER_FROSTED := 256
const LAYER_BLOCK := 2

var width := 1.4
var height := 1.4
var frosted := false
var exterior := false
var room_id := ""
var closed := false

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
	var glass := Geo.mesh(pane, Geo.box(Vector3(width, height, 0.02)), Mat.frosted_glass() if frosted else Mat.glass(), Vector3.ZERO)
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Geo.add_box_shape(pane, Vector3(width, height, 0.06), Vector3.ZERO)
	# Fensterkreuz und Rahmen
	var frame := Mat.psx(Color(0.85, 0.82, 0.75))
	Geo.mesh(pane, Geo.box(Vector3(width, 0.05, 0.05)), frame, Vector3.ZERO)
	Geo.mesh(pane, Geo.box(Vector3(0.05, height, 0.05)), frame, Vector3.ZERO)
	Geo.mesh(pane, Geo.box(Vector3(width + 0.1, 0.06, 0.22)), frame, Vector3(0, -height / 2.0 - 0.03, 0.05))
	if not has_curtains():
		return
	pane.set_meta("interactable", self)
	var cloth := Mat.psx(Color(0.42, 0.12, 0.12), "", 1.0)
	Geo.mesh(self, Geo.box(Vector3(width + 0.5, 0.04, 0.04)), Mat.psx(Color(0.35, 0.25, 0.12)), Vector3(0, height / 2.0 + 0.2, 0.2))
	_left = _curtain(-1.0, cloth)
	_right = _curtain(1.0, cloth)
	# Unsichtbare Sperre, solange die Vorhänge zu sind: blockiert Blick und Licht
	_block = StaticBody3D.new()
	_block.collision_layer = 0
	_block.collision_mask = 0
	_block.set_meta("interactable", self)
	add_child(_block)
	Geo.add_box_shape(_block, Vector3(width + 0.3, height + 0.3, 0.05), Vector3(0, 0, 0.2))
	_apply(true)


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
	if not has_curtains() or (closed == value and not instant):
		return
	closed = value
	_apply(instant)
	if not instant and Game.player and Game.player.global_position.distance_to(global_position) < 8.0:
		Game.play_sound("creak", 0.15)


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
	closed = bool(data.get("closed", false))
	if has_curtains():
		_apply(true)
