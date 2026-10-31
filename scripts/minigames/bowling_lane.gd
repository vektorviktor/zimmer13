class_name BowlingLane
extends Node3D
## Bowlingbahn in der Bar (Spielkonzept 6.10, 28.10.; Spiel 01.11.): zehn Kegel im Dreieck am Ende der Bahn und ein
## Ständer mit Kugeln neben dem Anlauf. [E] am Ständer startet das Spiel (BowlingMatch): Man steht mittig im Anlauf
## und rollt die Kugel von der Foullinie (roll). Kugel und Kegel sind echte Körper und fallen, wie sie fallen; die Bahn
## meldet, wann alles liegt (settled), zählt (down), räumt nach dem ersten Wurf die gefallenen weg (sweep) und stellt
## zum neuen Frame alle wieder auf (reset) – wie ein Kegelaufsteller. Rollen und Poltern sind Lärm (bowling_roll,
## bowling_pins). Kein gespeicherter Zustand: nach dem Laden stehen alle Kegel.
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
const STAND := 1.0              ## so weit hinter der Foullinie steht man im Anlauf
const FALLEN_TILT := 0.85       ## Kegel gilt als gefallen, wenn seine Achse weniger als so steil steht …
const FALLEN_SHIFT := 0.12      ## … oder er so weit verrutscht ist
const QUIET_SPEED := 0.08       ## m/s: darunter gilt ein Körper als ruhig (Drehung: das Vierfache in rad/s)
const QUIET_TIME := 0.8         ## s alles ruhig, dann wird gezählt
const MAX_ROLL := 12.0          ## s nach dem Loslassen wird spätestens gezählt
const BALL_COLORS: Array[Color] = [Color(0.45, 0.04, 0.06), Color(0.06, 0.12, 0.4), Color(0.04, 0.04, 0.05),
	Color(0.08, 0.3, 0.14), Color(0.3, 0.08, 0.35)]
const RACK_SIZE := Vector3(0.4, 0.62, 1.0)   ## Ständer: Breite quer zur Bahn, Höhe, Länge entlang der Bahn

var lane := Rect2()             ## Bahn in x/z (Welt)
var foul_z := 0.0               ## z der Foullinie; Anlauf bei größerem z
var ball: RigidBody3D           ## die rollende Kugel (null, solange keine rollt)

var _pins: Array[RigidBody3D] = []
var _spots: Array[Vector3] = []
var _gone: Array[bool] = []     ## nach dem ersten Wurf weggeräumt
var _rack: StaticBody3D
var _rack_balls: Array[MeshInstance3D] = []
var _rolling := -1.0            ## s seit dem Loslassen, < 0 = keine Kugel unterwegs
var _quiet := 0.0
var _pin_mesh: ArrayMesh
var _pin_shape: ConvexPolygonShape3D


func setup(lane_rect: Rect2, foul: float) -> BowlingLane:
	lane = lane_rect
	foul_z = foul
	return self


func _ready() -> void:
	_pin_mesh = _lathe(PROFILE, 16)
	_pin_shape = _pin_hull()
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
		_gone.append(false)
	_build_rack()


func get_prompt(_player: Player) -> String:
	if Game.bowling and Game.bowling.active:
		return ""
	return "Bowling spielen [E]"


func interact(player: Player) -> void:
	if Game.bowling and not Game.bowling.active and not player.at_oche:
		Game.bowling.play(self)


## Hier steht man im Anlauf (offset = seitlich von der Mitte der Bahn).
func stand_spot(offset: float = 0.0) -> Vector3:
	return Vector3(lane.get_center().x + offset, global_position.y, foul_z + STAND)


## Mitte des Kegeldreiecks auf halber Kegelhöhe.
func deck_center() -> Vector3:
	return Vector3(lane.get_center().x, PIN_HEIGHT / 2.0, _spots[4].z)


## Platz des Kopfkegels.
func head_spot() -> Vector3:
	return _spots[_spots.size() - 1]


## So weit darf man im Anlauf zur Seite treten (von der Mitte der Bahn).
func max_offset() -> float:
	return lane.size.x / 2.0 - BALL_RADIUS - 0.03


## Kugel an der Foullinie bei x loslassen, Richtung yaw (rad, 0 = genau die Bahn hinunter), speed in m/s.
func roll(x: float, yaw: float, speed: float, color: Color, player: Player) -> void:
	var dir := Vector3(0, 0, -1).rotated(Vector3.UP, yaw)
	ball = _make_ball(color)
	add_child(ball)
	ball.global_position = Vector3(clampf(x, lane.position.x + BALL_RADIUS, lane.end.x - BALL_RADIUS),
		global_position.y + BALL_RADIUS + 0.01, foul_z - 0.15)
	ball.linear_velocity = dir * speed
	ball.angular_velocity = dir.cross(Vector3.UP) * speed / BALL_RADIUS   # rollt, statt zu rutschen
	for i in _pins.size():
		if not _gone[i]:
			_pins[i].freeze = false
	_rolling = 0.0
	_quiet = 0.0
	Game.noise("bowling_roll", ball.global_position, player)


func _physics_process(delta: float) -> void:
	if _rolling < 0.0:
		return
	_rolling += delta
	var calm := _ball_done()
	for i in _pins.size():
		if calm and not _gone[i] and (_pins[i].linear_velocity.length() > QUIET_SPEED
				or _pins[i].angular_velocity.length() > QUIET_SPEED * 4.0):
			calm = false
	_quiet = _quiet + delta if calm else 0.0


## Ist die Kugel durch – hinten angekommen, liegengeblieben oder seitlich von der Bahn?
func _ball_done() -> bool:
	if not is_instance_valid(ball):
		return true
	var p := ball.global_position
	return p.z < lane.position.y + 0.3 or ball.linear_velocity.length() < 0.3 or p.y < global_position.y - 0.5 \
		or (_rolling > 1.0 and (p.x < lane.position.x - 0.05 or p.x > lane.end.x + 0.05) and p.z < _spots[0].z + 2.0)


## Liegt alles still (oder ist die Zeit um)? Dann kann gezählt werden.
func settled() -> bool:
	return _rolling >= 0.0 and (_quiet >= QUIET_TIME or _rolling >= MAX_ROLL)


func rolling() -> bool:
	return _rolling >= 0.0


## Kegel, die seit dem letzten Aufstellen bzw. Abräumen gefallen oder verrutscht sind.
func down() -> int:
	var n := 0
	for i in _pins.size():
		if not _gone[i] and _is_down(i):
			n += 1
	return n


func _is_down(i: int) -> bool:
	var pin := _pins[i]
	var flat := Vector2(pin.global_position.x - _spots[i].x, pin.global_position.z - _spots[i].z)
	return pin.global_transform.basis.y.dot(Vector3.UP) < FALLEN_TILT or flat.length() > FALLEN_SHIFT


## Nach dem Zählen: Kugel weg, Poltern, wenn etwas gefallen ist.
func finish_roll(fallen: int) -> void:
	_rolling = -1.0
	if fallen > 0:
		Game.noise("bowling_pins", deck_center(), Game.player)
	if is_instance_valid(ball):
		ball.queue_free()
	ball = null


## Nach dem ersten Wurf: Gefallene wegräumen, die stehenden bleiben, wo sie stehen.
func sweep() -> void:
	for i in _pins.size():
		var pin := _pins[i]
		if not _gone[i] and _is_down(i):
			_gone[i] = true
			pin.visible = false
			pin.collision_layer = 0
		_hold(pin)


## Alle zehn wieder aufstellen und festhalten, Kugel weg (neuer Frame, Spielende).
func reset() -> void:
	_rolling = -1.0
	if is_instance_valid(ball):
		ball.queue_free()
	ball = null
	for i in _pins.size():
		var pin := _pins[i]
		_gone[i] = false
		pin.visible = true
		pin.collision_layer = Item.LAYER
		_hold(pin)
		pin.global_transform = Transform3D(Basis.IDENTITY, _spots[i])


func _hold(pin: RigidBody3D) -> void:
	pin.freeze = true
	pin.linear_velocity = Vector3.ZERO
	pin.angular_velocity = Vector3.ZERO


## Eine Kugel aus dem Ständer nehmen (ihre Farbe rollt dann) bzw. alle zurücklegen.
func take_ball() -> Color:
	for i in _rack_balls.size():
		if _rack_balls[i].visible:
			_rack_balls[i].visible = false
			return BALL_COLORS[i]
	return BALL_COLORS[0]


func return_ball() -> void:
	for b in _rack_balls:
		b.visible = true


## Kugel in der Hand (vor der Kamera) – wie im Ständer, mit Grifflöchern.
func ball_model(color: Color) -> Node3D:
	var root := Node3D.new()
	Geo.mesh(root, Geo.sphere(BALL_RADIUS, BALL_RADIUS * 2.0, 16, 8), Mat.psx(color), Vector3.ZERO)
	_finger_holes(root, Vector3.ZERO)
	return root


func _make_pin() -> RigidBody3D:
	var pin := RigidBody3D.new()
	pin.mass = PIN_MASS
	pin.collision_layer = Item.LAYER
	pin.collision_mask = 1 | Item.LAYER
	pin.freeze = true   # steht fest, bis eine Kugel rollt (spart Physik, kein Zittern)
	pin.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	pin.continuous_cd = true   # schnelle Stöße unter Kegeln gehen sonst durch (60 Physikbilder/s)
	pin.physics_material_override = _bounce(0.35, 0.4)
	var shape := CollisionShape3D.new()
	shape.shape = _pin_shape
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
## mit mehr Platz. [E] daran startet das Spiel (interactable = die Bahn).
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


## Kollisionsform des Kegels: konvexe Hülle des Umrisses. Wie der echte Kegel steht er auf einem schmalen Fuß
## (Ø 5 cm) und kippt leicht – als Zylinder in Bauchbreite stand er doppelt so breit und fiel kaum.
static func _pin_hull() -> ConvexPolygonShape3D:
	var points := PackedVector3Array()
	for p: Array in PROFILE:
		if float(p[1]) <= 0.0:
			points.append(Vector3(0, float(p[0]), 0))
			continue
		for s in 12:
			var t := TAU * s / 12.0
			points.append(Vector3(cos(t) * float(p[1]), float(p[0]), sin(t) * float(p[1])))
	var hull := ConvexPolygonShape3D.new()
	hull.points = points
	return hull


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
