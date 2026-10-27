class_name DartBoard
extends GameTable
## Dartscheibe in der Bar (Spielkonzept 6.10): Sisalscheibe nach Turniermaß an der Wand (shaders/dartboard.gdshader),
## schwarzer Ring drumherum, Abwurflinie aus Messing OCHE m vor der Scheibe und ein Stehtisch daneben, auf dem die
## Pfeile (Item.Kind.DARTS) und die Einsätze liegen – ohne Pfeile kein Spiel, wie beim Würfelbecher. Ursprung am Fuß
## der Wand, lokal +Z in den Raum, +X nach rechts (vom Werfer aus). player_seat/guest_seat sind hier Stehplätze an
## der Linie: der Spieler links, der Gast rechts daneben.
##
## Geworfen wird über throw_dart: Der Pfeil fliegt sichtbar, steckt in Scheibe oder Ring oder fällt von der Wand,
## macht Lärm (dart, dart_wall) und meldet, was er getroffen hat (Darts.score_at). Nach jeder Aufnahme clear_darts.

const BOARD_Y := 1.73           ## Höhe des Bulls (Turniermaß)
const OCHE := 2.37              ## Abstand Scheibe – Abwurflinie
const SURROUND_DEPTH := 0.015
const BOARD_DEPTH := 0.038
const FACE_Z := SURROUND_DEPTH + BOARD_DEPTH   ## Vorderseite der Scheibe
const STICK := 0.012            ## so tief steckt die Spitze
const CHEAT_STEP := 0.45        ## so weit tritt man beim Schummeln über die Linie
const TABLE_TOP := 1.08
const TABLE_AT := Vector3(1.3, 0.0, 2.15)
const PLAYER_SPOT := Vector3(-0.25, 0.0, FACE_Z + OCHE + 0.12)
const GUEST_SPOT := Vector3(0.6, 0.0, FACE_Z + OCHE + 0.2)
const FLIGHT_TIME := 0.17
const RELEASE := 0.27           ## Gast: so lange nach dem Ausholen fliegt der Pfeil (Guest.DART_THROW_TIME)
const NUMBER_RADIUS := 0.199
const NUMBER_HEIGHT := 0.026

var _darts: Array[Node3D] = []


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	set_meta("interactable", self)
	_build_board()
	_build_table()
	var line := Geo.mesh(self, Geo.box(Vector3(0.9, 0.006, 0.035)), Mat.metal(Color(0.78, 0.62, 0.32)),
		Vector3(0.1, 0.003, FACE_Z + OCHE + 0.0175))   # Messingleiste, Vorderkante = Linie
	line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	player_seat = _spot(PLAYER_SPOT)
	guest_seat = _spot(GUEST_SPOT)


func _build_board() -> void:
	var surround := Geo.mesh(self, Geo.cylinder(Darts.R_SURROUND, SURROUND_DEPTH, 32), Mat.psx(Color(0.035, 0.035, 0.04)),
		Vector3(0, BOARD_Y, SURROUND_DEPTH / 2.0))
	surround.rotation.x = PI / 2.0
	var body := Geo.mesh(self, Geo.cylinder(Darts.R_BOARD, BOARD_DEPTH, 32), Mat.psx(Color(0.05, 0.05, 0.05)),
		Vector3(0, BOARD_Y, SURROUND_DEPTH + BOARD_DEPTH / 2.0))
	body.rotation.x = PI / 2.0
	var face := QuadMesh.new()
	face.size = Vector2.ONE * Darts.R_BOARD * 2.0
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/dartboard.gdshader")
	mat.set_shader_parameter("size", Darts.R_BOARD * 2.0)
	Geo.mesh(self, face, mat, Vector3(0, BOARD_Y, FACE_Z + 0.0005))
	# Zahlen aus Draht im Ring außen, aufrecht
	var silver := Mat.metal(Color(0.85, 0.85, 0.86))
	for i in Darts.SEGMENTS.size():
		var text := TextMesh.new()
		text.text = str(Darts.SEGMENTS[i])
		text.font_size = 32
		text.pixel_size = NUMBER_HEIGHT / 32.0
		text.depth = 0.002
		var angle := deg_to_rad(i * 18.0)
		var at := Vector3(sin(angle), cos(angle), 0) * NUMBER_RADIUS
		var number := Geo.mesh(self, text, silver, Vector3(at.x, BOARD_Y + at.y, FACE_Z + 0.001))
		number.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Geo.add_box_shape(self, Vector3(Darts.R_SURROUND * 2.0, Darts.R_SURROUND * 2.0, FACE_Z), Vector3(0, BOARD_Y, FACE_Z / 2.0))


## Runder Stehtisch für Pfeile, Getränke und Einsätze.
func _build_table() -> void:
	var top := Geo.mesh(self, Geo.cylinder(0.32, 0.035, 24), Mat.wood(false, Color(0.55, 0.38, 0.26)),
		TABLE_AT + Vector3(0, TABLE_TOP - 0.0175, 0))
	top.name = "Stehtisch"
	var steel := Mat.metal(Color(0.3, 0.3, 0.32))
	Geo.mesh(self, Geo.cylinder(0.035, TABLE_TOP - 0.035, 12), steel, TABLE_AT + Vector3(0, (TABLE_TOP - 0.035) / 2.0, 0))
	Geo.mesh(self, Geo.cylinder(0.24, 0.02, 24), steel, TABLE_AT + Vector3(0, 0.01, 0))
	Geo.add_box_shape(self, Vector3(0.5, TABLE_TOP, 0.5), TABLE_AT + Vector3(0, TABLE_TOP / 2.0, 0))


func _spot(local: Vector3) -> Marker3D:
	var spot := Marker3D.new()
	spot.position = local
	spot.rotation.y = atan2(local.x, local.z - FACE_Z)   # Blick (−Z) zur Scheibe
	add_child(spot)
	return spot


# --- Für Spiel und Einsätze ---------------------------------------------------------

func top_center() -> Vector3:
	return to_global(TABLE_AT + Vector3.UP * TABLE_TOP)


func stake_spot(side: int) -> Vector3:
	var offset := Vector3(side * 0.15, 0.01, 0.1) if side != 0 else Vector3(0, 0.01, -0.15)
	return to_global(TABLE_AT + Vector3.UP * TABLE_TOP + offset)


func has_darts(player: Player) -> bool:
	return _has_gear(Item.Kind.DARTS, player)


## Mitte der Scheibe in Weltkoordinaten (dorthin sieht man an der Linie).
func bull() -> Vector3:
	return to_global(Vector3(0, BOARD_Y, FACE_Z))


## Punkt auf der Scheibe (m, x rechts, y oben) → Welt; depth = so weit hinter der Vorderseite.
func board_to_world(p: Vector2, depth: float = 0.0) -> Vector3:
	return to_global(Vector3(p.x, BOARD_Y + p.y, FACE_Z - depth))


## Wo der Strahl die Ebene der Scheibe trifft (Punkt auf der Scheibe) – null, wenn er nicht hinzeigt.
func ray_to_board(origin: Vector3, dir: Vector3) -> Variant:
	var o := to_local(origin)
	var d := global_basis.inverse() * dir
	if d.z >= -0.0001:
		return null
	var t := (FACE_Z - o.z) / d.z
	var hit := o + d * t
	return Vector2(hit.x, hit.y - BOARD_Y)


## Stehplatz an der Linie – über die Linie getreten (Schummeln) um CHEAT_STEP näher.
func throw_spot(over_line: bool) -> Vector3:
	return to_global(PLAYER_SPOT - Vector3(0, 0, CHEAT_STEP if over_line else 0.0))


# --- Werfen -----------------------------------------------------------------------------

## Pfeil von from (Welt) auf den Punkt p der Scheibe werfen. Er fliegt FLIGHT_TIME lang in einem flachen Bogen, dann
## steckt er (Scheibe, Ring) oder prallt von der Wand ab und fällt. done(hit) bekommt Darts.score_at(p).
func throw_dart(from: Vector3, p: Vector2, flight: Color, done: Callable = Callable()) -> void:
	var hit := Darts.score_at(p)
	var dart := DartModel.build(flight)
	add_child(dart)
	_darts.append(dart)
	var start := to_local(from)
	var sticks := bool(hit["board"]) or bool(hit["surround"])
	var face := FACE_Z if hit["board"] else SURROUND_DEPTH
	var end := Vector3(p.x, BOARD_Y + p.y, face - (STICK if sticks else 0.0))
	var tilt := Vector3(randf_range(-0.12, 0.12), randf_range(-0.05, 0.25), 0)   # hinten meist etwas höher
	var dir := (end - start).normalized()
	dart.position = start
	dart.basis = Basis.looking_at(dir)
	# Am Pfeil, nicht an der Scheibe: räumt clear_darts ihn mitten im Flug weg (Aufgabe, Ende), endet der Flug mit ihm
	var tween := dart.create_tween()
	tween.tween_method(func(t: float) -> void:
		dart.position = start.lerp(end, t) + Vector3.UP * sin(PI * t) * 0.05
		dart.basis = Basis.looking_at((dir + Vector3.DOWN * (t - 0.5) * 0.1).normalized()), 0.0, 1.0, FLIGHT_TIME)
	tween.tween_callback(func() -> void:
		dart.basis = Basis.looking_at((dir - tilt).normalized())
		if sticks:
			Game.noise("dart", to_global(end))
		else:
			Game.noise("dart_wall", to_global(end))
			_fall(dart, end)
		if done.is_valid():
			done.call(hit))


## Von der Wand abgeprallt: fällt vor ihr auf den Boden und bleibt liegen.
func _fall(dart: Node3D, at: Vector3) -> void:
	var floor_at := Vector3(at.x + randf_range(-0.1, 0.1), 0.012, randf_range(0.15, 0.45))
	var lying := Basis(Vector3.UP, randf() * TAU) * Basis(Vector3.BACK, PI / 4.0)   # flach, die Flights über Kreuz
	var tween := dart.create_tween().set_parallel()
	tween.tween_property(dart, "position", floor_at, 0.45).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(dart, "basis", lying, 0.45)


## Gast wirft (Partie oder Spiel unter Gästen): holt aus und lässt nach RELEASE s los – aus seiner Hand, mit seiner
## Streuung, auf aim.
func guest_throw(guest: Guest, aim: Vector2, sigma: float, flight: Color, done: Callable = Callable()) -> void:
	guest.throw_dart_pose()
	create_tween().tween_callback(func() -> void:
		if not is_instance_valid(guest):
			return
		var hand := guest.global_position + Vector3.UP * 1.55 + guest.global_basis.x * 0.18 - guest.global_basis.z * 0.3
		throw_dart(hand, Darts.scatter(aim, sigma), flight, done)).set_delay(RELEASE)


## Pfeile aus Scheibe und vom Boden holen (nach jeder Aufnahme, am Ende).
func clear_darts() -> void:
	for dart in _darts:
		if is_instance_valid(dart):
			dart.queue_free()
	_darts.clear()


# --- Interaktion ------------------------------------------------------------------------

func get_prompt(player: Player) -> String:
	if busy:
		return "Hier wird gerade Darts gespielt …"
	if not has_darts(player):
		return "Dartscheibe – die Pfeile fehlen!"
	return "Dartscheibe – allein werfen [E] (Gäste lädst du im Gespräch ein)"


func interact(player: Player) -> void:
	if busy or not has_darts(player) or Game.darts == null:
		return
	Game.darts.practice()
