class_name Door
extends Node3D
## Drehtür, einfach oder doppelt. Lokale +X = Türbreite, Scharnier im Ursprung,
## Boden auf y = 0. Türen liegen auf Kollisionsebene 2 und gehen nicht ins NavMesh ein,
## damit das Monster durch Türöffnungen planen kann (es öffnet sie dann selbst).

## Kollisionstiefe des Türblatts (= Wandstärke, siehe LevelBuilder.T)
const COLLISION_DEPTH := 0.2

var width := 1.2
var height := 2.1
var open_angle := deg_to_rad(-100.0)
var double := false
var locked := false
var key_id := ""
var locked_text := "Abgeschlossen."
var monster_can_open := true
var glass := false          ## Glastür: man sieht hindurch (Ebene 7 statt 2)
var is_open := false
## Zuletzt vom Monster aufgerissen (nicht vom Spieler oder einem Gast)
var opened_by_monster := false

var _pivots: Array[Node3D] = []
var _bodies: Array[Node3D] = []
var _tween: Tween


func setup(p_width: float, p_height: float, p_open_angle_deg: float, p_double: bool = false, p_glass: bool = false) -> Door:
	width = p_width
	height = p_height
	open_angle = deg_to_rad(p_open_angle_deg)
	double = p_double
	glass = p_glass
	return self


func _ready() -> void:
	add_to_group("doors")
	if double:
		_pivots.append(_make_leaf(Vector3.ZERO, width / 2.0, 1.0))
		_pivots.append(_make_leaf(Vector3(width, 0, 0), width / 2.0, -1.0))
	else:
		_pivots.append(_make_leaf(Vector3.ZERO, width, 1.0))


func center() -> Vector3:
	return global_transform * Vector3(width / 2.0, height / 2.0, 0.0)


func get_prompt(player: Player) -> String:
	if locked:
		if player.has_key(key_id):
			return "Hände voll" if player.hands_blocked() else "Aufschließen [E]"
		return "Verschlossen"
	if player.hands_blocked():
		return "Hände voll"
	return "Tür schließen [E]" if is_open else "Tür öffnen [E]"


func interact(player: Player) -> void:
	if locked:
		if player.has_key(key_id) and player.hands_blocked():
			Game.say("Mit vollen Händen kommst du nicht an den Schlüssel.")
		elif player.has_key(key_id):
			locked = false
			Game.say("Aufgeschlossen.")
			Game.noise("unlock", center(), player)
			set_open(true, false, false, player)
			SaveManager.request_autosave("Tür aufgeschlossen")
		else:
			Game.say(locked_text)
			Game.noise("rattle", center(), player)
			_rattle()
		return
	if player.hands_blocked():
		Game.say("Mit vollen Händen geht das nicht.")
		return
	set_open(not is_open, false, false, player)


## `source`: wer die Tür bewegt (hört das eigene Knarren nicht als Lärm, 4.15).
func set_open(open: bool, fast: bool = false, quiet: bool = false, source: Node = null) -> void:
	is_open = open
	opened_by_monster = false
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	for i in _pivots.size():
		var side := 1.0 if i == 0 else -1.0
		var target := open_angle * side if open else 0.0
		_tween.tween_property(_pivots[i], "rotation:y", target, 0.25 if fast else 0.6).set_trans(Tween.TRANS_SINE)
	if not quiet:
		Game.noise("door", center(), source)


## Das Monster reißt die Tür auf (auch abgeschlossene – außer der Lobbytür).
func monster_open() -> void:
	if is_open or not monster_can_open:
		return
	locked = false
	set_open(true, true, true)
	opened_by_monster = true
	Game.noise("door_burst", center(), Game.monster)


## Spur auf dem (ersten) Türflügel anbringen; side = Seite der Tür (lokale ±Z).
func attach_mark(mark: TraceMark, side: float) -> void:
	var leaf_width := width / 2.0 if double else width
	mark.solid = false
	mark.set_meta("door_side", side)
	_bodies[0].add_child(mark)
	mark.position = Vector3(leaf_width * 0.45, 1.35, side * 0.04)
	mark.rotation.y = 0.0 if side > 0.0 else PI


func _rattle() -> void:
	if is_open:
		return
	for pivot in _pivots:
		var tw := create_tween()
		for offset in [0.025, -0.025, 0.02, 0.0]:
			tw.tween_property(pivot, "rotation:y", offset, 0.05)


func _make_leaf(origin: Vector3, leaf_width: float, dir: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = origin
	add_child(pivot)
	var body := AnimatableBody3D.new()
	body.collision_layer = 64 if glass else 2
	body.collision_mask = 0
	body.sync_to_physics = false
	body.set_meta("interactable", self)
	pivot.add_child(body)
	_bodies.append(body)
	var leaf_size := Vector3(leaf_width - 0.02, height - 0.02, 0.06)
	var cx := dir * leaf_width / 2.0
	if glass:
		var frame := Mat.psx(Color(0.85, 0.85, 0.8))
		Geo.mesh(body, Geo.box(Vector3(leaf_width - 0.2, height - 0.2, 0.02)), Mat.glass(), Vector3(cx, height / 2.0, 0))
		Geo.mesh(body, Geo.box(Vector3(leaf_width - 0.02, 0.1, 0.06)), frame, Vector3(cx, 0.05, 0))
		Geo.mesh(body, Geo.box(Vector3(leaf_width - 0.02, 0.1, 0.06)), frame, Vector3(cx, height - 0.05, 0))
		Geo.mesh(body, Geo.box(Vector3(0.1, height - 0.02, 0.06)), frame, Vector3(dir * 0.05, height / 2.0, 0))
		Geo.mesh(body, Geo.box(Vector3(0.1, height - 0.02, 0.06)), frame, Vector3(dir * (leaf_width - 0.06), height / 2.0, 0))
		Geo.mesh(body, Geo.box(Vector3(leaf_width - 0.02, 0.05, 0.05)), frame, Vector3(cx, height * 0.55, 0))
	else:
		Geo.mesh(body, Geo.box(leaf_size), Mat.psx(Color(0.3, 0.17, 0.1)), Vector3(cx, height / 2.0, 0))
		# Kassetten als Relief
		var panel := Mat.psx(Color(0.24, 0.13, 0.08))
		for y in [0.6, 1.5]:
			Geo.mesh(body, Geo.box(Vector3(leaf_width * 0.6, 0.55, 0.075)), panel, Vector3(cx, y * height / 2.1, 0))
	# Kollision so tief wie die Wand: Ein dünnes Türblatt bildet eine Nische, in der die
	# Spielerkapsel beim schrägen Entlanglaufen an der Wand hängenbleibt.
	Geo.add_box_shape(body, Vector3(leaf_size.x, leaf_size.y, COLLISION_DEPTH), Vector3(cx, height / 2.0, 0))
	var brass := Mat.psx(Color(0.8, 0.65, 0.25))
	for z in [0.05, -0.05]:
		Geo.mesh(body, Geo.sphere(0.035, 0.07, 6, 3), brass, Vector3(dir * (leaf_width - 0.1), 1.0, z))
	return pivot
