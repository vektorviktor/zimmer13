class_name BowlingLane
extends Node3D
## Bowlingbahn in der Bar (Spielkonzept 6.10, 28.10.): zehn Kegel im Dreieck am Ende der Bahn und ein Ständer mit
## Kugeln hinter der Foullinie. Wer im Anlauf steht und am Ständer [E] drückt, rollt eine Kugel von der Foullinie
## in Blickrichtung (höchstens AIM_LIMIT schräg, im Rausch zittert die Hand) – Kugel und Kegel sind echte Körper und
## fallen, wie sie fallen. Danach zählt die Bahn die gefallenen Kegel und stellt sie wieder auf (wie ein
## Kegelaufsteller). Rollen und Poltern sind Lärm (bowling_roll, bowling_pins). Ein Spiel mit Zählung, Einsatz und
## Gästen ist noch nicht entschieden. Kein gespeicherter Zustand: nach dem Laden stehen alle Kegel.
## Liegt in Weltkoordinaten (Ursprung = Welt), die Bahn läuft von der Foullinie nach Norden (−z).

const PIN_HEIGHT := 0.38
const PIN_MASS := 1.5
const PIN_SPACING := 0.305      ## Abstand der Kegel in einer Reihe (12 Zoll)
const PIN_ROW := 0.264          ## Abstand der Reihen (Dreieck)
const DECK_BACK := 0.45         ## so weit steht die hintere Reihe vor dem Ende der Bahn
## Umriss eines Kegels von unten nach oben: [Höhe, Halbmesser] (nach Regelmaß, leicht vereinfacht)
const PROFILE := [[0.0, 0.0], [0.0, 0.026], [0.02, 0.04], [0.06, 0.054], [0.11, 0.0605], [0.16, 0.055],
	[0.205, 0.038], [0.24, 0.024], [0.27, 0.022], [0.3, 0.027], [0.335, 0.031], [0.36, 0.027], [0.375, 0.016],
	[0.38, 0.0]]
const STRIPES: Array[float] = [0.237, 0.262]   ## rote Ringe am Hals
const BALL_RADIUS := 0.109
const BALL_MASS := 6.0
const BALL_SPEED := 7.5         ## m/s beim Loslassen
const AIM_LIMIT := 7.0          ## Grad: so schräg darf die Kugel höchstens laufen
const SWAY_DRUNK := 4.0         ## Grad Streuung bei vollem Rausch
const RESULT_AFTER := 6.0       ## s nach dem Loslassen: Kegel zählen
const RESET_AFTER := 8.5        ## s nach dem Loslassen: Kegel aufstellen, Kugel zurück
const FALLEN_TILT := 0.85       ## Kegel gilt als gefallen, wenn seine Achse weniger als so steil steht …
const FALLEN_SHIFT := 0.12      ## … oder er so weit verrutscht ist
const BALL_COLORS: Array[Color] = [Color(0.45, 0.04, 0.06), Color(0.06, 0.12, 0.4), Color(0.04, 0.04, 0.05),
	Color(0.08, 0.3, 0.14), Color(0.3, 0.08, 0.35)]
const RACK_SIZE := Vector3(0.4, 0.62, 1.0)   ## Ständer: Breite quer zur Bahn, Höhe, Länge entlang der Bahn

var lane := Rect2()             ## Bahn in x/z (Welt)
var foul_z := 0.0               ## z der Foullinie; Anlauf bei größerem z

var _pins: Array[RigidBody3D] = []
var _spots: Array[Vector3] = []
var _ball: RigidBody3D
var _rack: StaticBody3D
var _rack_balls: Array[MeshInstance3D] = []
var _rolling := -1.0            ## s seit dem Loslassen, < 0 = keine Kugel unterwegs
var _counted := false
var _pin_mesh: ArrayMesh


func setup(lane_rect: Rect2, foul: float) -> BowlingLane:
	lane = lane_rect
	foul_z = foul
	return self


func _ready() -> void:
	_pin_mesh = _lathe(PROFILE, 16)
	var cx := lane.get_center().x
	var back := lane.position.y + DECK_BACK
	for row in 4:   # hinten 4, vorn 1 – der Kopfkegel zeigt zur Foullinie
		var n := 4 - row
		for i in n:
			_spots.append(Vector3(cx + (i - (n - 1) / 2.0) * PIN_SPACING, 0.0, back + row * PIN_ROW))
	for spot in _spots:
		var pin := _make_pin()
		add_child(pin)
		pin.global_position = spot
		_pins.append(pin)
	_build_rack()


func get_prompt(player: Player) -> String:
	if _rolling >= 0.0:
		return "Die Kugel rollt …"
	if not _in_approach(player.global_position):
		return "Bowlingkugeln – zum Rollen in den Anlauf hinter die Foullinie stellen"
	return "Bowlingkugel rollen [E]"


func interact(player: Player) -> void:
	if _rolling >= 0.0 or not _in_approach(player.global_position):
		return
	var look := -player.global_transform.basis.z
	var yaw := rad_to_deg(atan2(-look.x, -look.z))   # 0 = genau die Bahn hinunter (−z)
	yaw = clampf(yaw, -AIM_LIMIT, AIM_LIMIT) + randf_range(-1.0, 1.0) * SWAY_DRUNK * player.drunk
	var dir := Vector3(0, 0, -1).rotated(Vector3.UP, deg_to_rad(yaw))
	var x := clampf(player.global_position.x, lane.position.x + 0.2, lane.end.x - 0.2)
	_ball = _make_ball(BALL_COLORS[randi() % BALL_COLORS.size()])
	add_child(_ball)
	_ball.global_position = Vector3(x, BALL_RADIUS + 0.01, foul_z - 0.15)
	_ball.linear_velocity = dir * BALL_SPEED
	_ball.angular_velocity = dir.cross(Vector3.UP) * BALL_SPEED / BALL_RADIUS   # rollt, statt zu rutschen
	for pin in _pins:
		pin.freeze = false
	_rolling = 0.0
	_counted = false
	Game.noise("bowling_roll", _ball.global_position, player)


func _physics_process(delta: float) -> void:
	if _rolling < 0.0:
		return
	_rolling += delta
	if not _counted and _rolling >= RESULT_AFTER:
		_counted = true
		_announce(fallen())
	if _rolling >= RESET_AFTER:
		reset()


## Wie viele Kegel liegen oder sind verrutscht?
func fallen() -> int:
	var n := 0
	for i in _pins.size():
		var pin := _pins[i]
		var flat := Vector2(pin.global_position.x - _spots[i].x, pin.global_position.z - _spots[i].z)
		if pin.global_transform.basis.y.dot(Vector3.UP) < FALLEN_TILT or flat.length() > FALLEN_SHIFT:
			n += 1
	return n


## Kegel wieder aufstellen und festhalten, Kugel zurück in den Ständer.
func reset() -> void:
	_rolling = -1.0
	if is_instance_valid(_ball):
		_ball.queue_free()
	_ball = null
	for i in _pins.size():
		var pin := _pins[i]
		pin.freeze = true
		pin.linear_velocity = Vector3.ZERO
		pin.angular_velocity = Vector3.ZERO
		pin.global_transform = Transform3D(Basis.IDENTITY, _spots[i])


func _announce(n: int) -> void:
	if n > 0:
		Game.noise("bowling_pins", _spots[0], Game.player)
	if Game.tracing:
		print("[Bowling] %d Kegel gefallen" % n)
	if not Game.player or Game.player.global_position.distance_to(Vector3(lane.get_center().x, 0, foul_z)) > 6.0:
		return
	if n >= _pins.size():
		Game.say("Alle zehn! Ein Strike.", 3.0)
	elif n == 0:
		Game.say("Daneben – kein einziger Kegel.", 2.5)
	else:
		Game.say("%d %s gefallen." % [n, "Kegel ist" if n == 1 else "Kegel sind"], 2.5)


func _in_approach(p: Vector3) -> bool:
	return p.z > foul_z and p.z < foul_z + 3.5 and p.x > lane.position.x - 0.6 and p.x < lane.end.x + 0.6 \
		and absf(p.y - global_position.y) < 1.5


func _make_pin() -> RigidBody3D:
	var pin := RigidBody3D.new()
	pin.mass = PIN_MASS
	pin.collision_layer = Item.LAYER
	pin.collision_mask = 1 | Item.LAYER
	pin.freeze = true   # steht fest, bis eine Kugel rollt (spart Physik, kein Zittern)
	pin.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	pin.physics_material_override = _bounce(0.35, 0.4)
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.055
	cyl.height = PIN_HEIGHT
	shape.shape = cyl
	shape.position.y = PIN_HEIGHT / 2.0
	pin.add_child(shape)
	pin.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	pin.center_of_mass = Vector3(0, 0.15, 0)   # der Bauch ist schwer, der Hals leicht
	var body := MeshInstance3D.new()
	body.mesh = _pin_mesh
	body.material_override = Mat.psx(Color(0.93, 0.92, 0.88))
	pin.add_child(body)
	for y in STRIPES:
		Geo.mesh(pin, Geo.cylinder(_radius_at(y) + 0.0015, 0.009, 16), Mat.psx(Color(0.75, 0.05, 0.05)), Vector3(0, y, 0))
	return pin


func _make_ball(color: Color) -> RigidBody3D:
	var ball := RigidBody3D.new()
	ball.mass = BALL_MASS
	ball.collision_layer = Item.LAYER
	ball.collision_mask = 1 | Item.LAYER
	ball.continuous_cd = true
	ball.physics_material_override = _bounce(0.1, 0.25)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = BALL_RADIUS
	shape.shape = sphere
	ball.add_child(shape)
	Geo.mesh(ball, Geo.sphere(BALL_RADIUS, BALL_RADIUS * 2.0, 16, 8), Mat.psx(color), Vector3.ZERO)
	_finger_holes(ball, Vector3.ZERO)
	return ball


## Drei Grifflöcher (dunkle Punkte) oben auf einer Kugel.
func _finger_holes(parent: Node3D, center: Vector3) -> void:
	var hole := Mat.psx(Color(0.02, 0.02, 0.02))
	for d in [Vector3(-0.022, 0.0, -0.02), Vector3(0.022, 0.0, -0.02), Vector3(0.0, 0.0, 0.035)]:
		var at: Vector3 = (Vector3(0, 1, 0) * BALL_RADIUS + d).normalized() * (BALL_RADIUS - 0.004)
		Geo.mesh(parent, Geo.sphere(0.012, 0.024, 6, 3), hole, center + at)


## Ständer mit Kugeln: niedriger Holzrahmen mit zwei Metallschienen neben dem Anlauf, an der Wand auf der Seite
## mit mehr Platz. Ist zugleich der Knopf zum Rollen (interactable = die Bahn).
func _build_rack() -> void:
	_rack = StaticBody3D.new()
	_rack.collision_layer = 1 | 4
	_rack.collision_mask = 0
	_rack.set_meta("interactable", self)
	add_child(_rack)
	_rack.global_position = Vector3(lane.end.x + RACK_SIZE.x / 2.0 + 0.04, 0.0, foul_z + 0.35 + RACK_SIZE.z / 2.0)
	var wood := Mat.wood(false, Color(0.55, 0.38, 0.25))
	var rail := Mat.metal()
	for side in [-1.0, 1.0]:
		Geo.box_part(_rack, Vector3(0.05, RACK_SIZE.y - 0.04, RACK_SIZE.z), Vector3(side * (RACK_SIZE.x / 2.0 - 0.025),
			(RACK_SIZE.y - 0.04) / 2.0, 0), wood)
		Geo.mesh(_rack, Geo.box(Vector3(0.025, 0.025, RACK_SIZE.z)), rail, Vector3(side * 0.07, RACK_SIZE.y - 0.02, 0))
	for i in BALL_COLORS.size():
		var z := -RACK_SIZE.z / 2.0 + 0.11 + i * 0.195
		var ball := Geo.mesh(_rack, Geo.sphere(BALL_RADIUS, BALL_RADIUS * 2.0, 16, 8), Mat.psx(BALL_COLORS[i]),
			Vector3(0, RACK_SIZE.y + BALL_RADIUS - 0.05, z))
		ball.rotation = Vector3(randf() * TAU, randf() * TAU, 0)
		_finger_holes(ball, Vector3.ZERO)
		_rack_balls.append(ball)
	Geo.add_box_shape(_rack, Vector3(RACK_SIZE.x, 0.25, RACK_SIZE.z), Vector3(0, RACK_SIZE.y + 0.1, 0))   # zum Anschauen


func _bounce(bounce: float, friction: float) -> PhysicsMaterial:
	var m := PhysicsMaterial.new()
	m.bounce = bounce
	m.friction = friction
	return m


static func _radius_at(y: float) -> float:
	for i in PROFILE.size() - 1:
		var a: Array = PROFILE[i]
		var b: Array = PROFILE[i + 1]
		if y >= float(a[0]) and y <= float(b[0]) and float(b[0]) > float(a[0]):
			return lerpf(float(a[1]), float(b[1]), (y - float(a[0])) / (float(b[0]) - float(a[0])))
	return 0.0


## Drehkörper aus einem Umriss [[Höhe, Halbmesser] …] um die y-Achse.
static func _lathe(profile: Array, segments: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(0)
	for i in profile.size() - 1:
		var a: Array = profile[i]
		var b: Array = profile[i + 1]
		for s in segments:
			var t0 := TAU * s / segments
			var t1 := TAU * (s + 1) / segments
			var p00 := Vector3(cos(t0) * float(a[1]), float(a[0]), sin(t0) * float(a[1]))
			var p01 := Vector3(cos(t1) * float(a[1]), float(a[0]), sin(t1) * float(a[1]))
			var p10 := Vector3(cos(t0) * float(b[1]), float(b[0]), sin(t0) * float(b[1]))
			var p11 := Vector3(cos(t1) * float(b[1]), float(b[0]), sin(t1) * float(b[1]))
			for p in [p00, p10, p11, p00, p11, p01]:
				st.add_vertex(p)
	st.index()   # gemeinsame Ecken → weiche Normalen
	st.generate_normals()
	return st.commit()
