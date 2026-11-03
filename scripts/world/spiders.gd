class_name Spiders
extends Node3D
## Spinnen (Spielkonzept 4.23, inspiriert von Doors): Sie krabbeln über den Boden – im Keller (und später im
## Dachgeschoss) ganz häufig, sonst selten. Es gibt sie nur in der Nähe des Spielers (höchstens MAX), neue tauchen
## dort auf, wo er nicht hinsieht. Sie sind scheu und fliehen vor nahen Füßen; wer auf eine tritt, zertritt sie
## (rennend erst recht). Wo Spinnen leben, wachsen Spinnweben schneller nach (5.10).
## Aus einer Schublade (Dresser) springt manchmal eine dem Spieler ins Gesicht – erst nach dem ersten Angriff, der
## friedliche Anfang bleibt friedlich (2.1). Man schnappt nach Luft (Lärm, 4.15) und muss sie abschütteln (Maus
## schnell hin und her), sonst beißt sie: Das wirkt wie ein Glas an der Bar (Rausch, 3.7 – also auch Schwäche, 4.18).
## Mutige Gäste zertreten Spinnen, ängstliche erschrecken. Einstellung „Spinnen als Kugeln“ (Settings.spider_blobs).
## Nicht gespeichert: Nach dem Laden krabbeln neue.

enum State { WALK, PAUSE, FLEE, DEAD }
enum Face { NONE, JUMP, ON }

const MAX := 30
const NEAR := 30.0                   ## weiter weg verschwinden sie (wo der Spieler nicht hinsieht)
## So viele um den Spieler herum je Stockwerk: Keller und Dachgeschoss viele, sonst wenige und nur mit Glück
const CELLAR_COUNT := 12
const ATTIC_COUNT := 12
const OTHER_COUNT := 2
const OTHER_CHANCE := 0.12           ## je Versuch in Erd- und Obergeschoss
const SPAWN_EVERY := 2.0
const SPAWN_RANGE := Vector2(5.0, 18.0)
const SIZE := Vector2(0.32, 0.39)    ## Größe: das Modell hat 15,4 cm Beinspanne – so 5 bis 6 cm
const SPEED := Vector2(0.12, 0.4)
const FLEE_SPEED := 0.75
const PAUSE := Vector2(0.6, 5.0)
const LEG := Vector2(0.8, 3.5)       ## so weit läuft sie in einem Zug
const STEP_RATE := 9.0               ## Laufphase je m (rad), dazu Zucken im Stehen
const FLEE_RANGE := 1.1              ## nahe Füße (Spieler läuft oder steht nicht geduckt still, Gäste)
const SQUASH_RANGE := 0.16           ## so nah unter dem Fuß eines Gehenden: zertreten
const SQUASH_SPEED := 0.6            ## so schnell muss man sich bewegen
const DEAD_TIME := 90.0              ## so lange bleibt eine Zertretene liegen
const CHECK_EVERY := 0.25
const COBWEB_RANGE := 6.0            ## Spinnen so nah an einer Spinnweben-Stelle lassen sie schneller nachwachsen …
const COBWEB_BOOST := 1.0            ## … je Spinne so viel schneller (höchstens dreifach)
## Schublade: Chance je Aufziehen, Pause danach
const DRAWER_CHANCE := 0.01
const DRAWER_PAUSE := 60.0
## Im Gesicht: Sprungzeit, so viel Kopfdrehen (rad) innerhalb von FACE_TIME schüttelt sie ab, sonst beißt sie
const JUMP_TIME := 0.18
const FACE_TIME := 1.8
const SHAKE := 1.5                   ## ein- bis zweimal hin und her
const FACE_POS := Vector3(0.0, -0.008, -0.065)
const FACE_SCALE := 0.4
const BITE := BarTap.DRINK           ## wie ein Glas
const FACE_SHOCK := 0.15
## Gäste: so nah an einer Spinne reagieren sie; ab so viel Mut zertreten, unter so viel erschrecken sie
const GUEST_RANGE := 0.5
const GUEST_BRAVE := 0.6
const GUEST_TIMID := 0.35
const GUEST_FEAR := 8.0
const GUEST_LINE_PAUSE := 30.0
const TIMID_LINES := ["Iiih, eine Spinne!", "Weg da! Eine Spinne!", "Nein, nein, nein – eine Spinne!"]
const BRAVE_LINES := ["Hab dich.", "Weg mit dir.", "Die krabbelt nicht mehr."]

var _builder: LevelBuilder
var _mm: MultiMesh
var _mmi: MultiMeshInstance3D
var _blobs := false
var _mesh_full: ArrayMesh
var _mesh_blob: ArrayMesh
# je Spinne
var _pos: Array[Vector3] = []
var _goal: Array[Vector3] = []
var _yaw: Array[float] = []
var _size: Array[float] = []
var _speed: Array[float] = []
var _state: Array[int] = []
var _timer: Array[float] = []
var _phase: Array[float] = []
var _floor_t: Array[float] = []      ## bis zur nächsten Bodenprüfung
var _spawn_t := 0.0
var _check := 0.0
var _cobweb_t := 0.0
var _guest_said := {}                ## Gast-ID → Spielzeit der letzten Bemerkung
# Gesicht
var _face := Face.NONE
var _face_node: MeshInstance3D
var _face_mat: ShaderMaterial
var _face_t := 0.0
var _face_from := Vector3.ZERO
var _shake := 0.0
var _last_look := Vector2.ZERO
var _drawer_pause := 0.0
var _force_drawer := false           ## Debug (--spinne=schublade): die nächste Schublade springt sicher


func setup(builder: LevelBuilder) -> void:
	_builder = builder
	_mesh_full = build_mesh(false)
	_mesh_blob = build_mesh(true)
	_blobs = Settings.spider_blobs
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/psx_spider.gdshader")
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_custom_data = true
	_mm.mesh = _mesh_blob if _blobs else _mesh_full
	_mm.instance_count = MAX
	_mm.visible_instance_count = 0
	_mmi = MultiMeshInstance3D.new()
	_mmi.multimesh = _mm
	_mmi.material_override = mat
	_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mmi.custom_aabb = AABB(Vector3(-500, -50, -500), Vector3(1000, 200, 1000))
	add_child(_mmi)
	_face_mat = ShaderMaterial.new()
	_face_mat.shader = mat.shader
	_face_mat.set_shader_parameter("single", true)
	_face_mat.set_shader_parameter("gait", 1.0)


# --- Modell -------------------------------------------------------------------------------------------

## Körper (Vorderleib, Hinterleib) aus kleinen Ellipsoiden und acht Beine aus flachen Bändern (Knie oben, Fuß am
## Boden); vorn ist −Z. Eckfarbe r = Phase des Beins, g = Gewicht für den Shader. blob: nur eine Kugel.
static func build_mesh(blob: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	if blob:
		_ellipsoid(st, Vector3(0, 0.03, 0), Vector3(0.03, 0.03, 0.03))
		return st.commit()
	_ellipsoid(st, Vector3(0, 0.014, -0.012), Vector3(0.011, 0.008, 0.013))
	_ellipsoid(st, Vector3(0, 0.019, 0.019), Vector3(0.016, 0.013, 0.022))
	for side in [1.0, -1.0]:
		for k in 4:
			var t := lerpf(-0.95, 0.95, k / 3.0)   # vorn nach vorn, hinten nach hinten
			var dir := Vector3(side * cos(t), 0, sin(t) * 1.1)
			var root := Vector3(side * 0.009, 0.013, -0.018 + k * 0.006)
			var knee := root + dir * 0.034 + Vector3.UP * 0.024
			var tip := Vector3(root.x, 0.0, root.z) + dir * 0.072
			var phase := 0.5 * float((k + (0 if side > 0.0 else 1)) % 2)
			_band(st, root, knee, 0.0035, phase, 0.0, 0.5)
			_band(st, knee, tip, 0.0028, phase, 0.5, 1.0)
	return st.commit()


static func _ellipsoid(st: SurfaceTool, c: Vector3, r: Vector3) -> void:
	var seg := 6
	var rings := 4
	var pts := []
	for j in rings + 1:
		var v := PI * j / rings
		var row := []
		for i in seg:
			var u := TAU * i / seg
			row.append(Vector3(sin(v) * cos(u), cos(v), sin(v) * sin(u)))
		pts.append(row)
	for j in rings:
		for i in seg:
			var quad: Array[Vector3] = [pts[j][i], pts[j][(i + 1) % seg], pts[j + 1][(i + 1) % seg], pts[j + 1][i]]
			for tri in [[0, 1, 2], [0, 2, 3]]:
				for q in tri:
					st.set_color(Color(0, 0, 0))
					st.set_normal(quad[q])
					st.add_vertex(c + quad[q] * r)


## Flaches Band von a nach b (waagerecht breit, damit man es von oben sieht).
static func _band(st: SurfaceTool, a: Vector3, b: Vector3, width: float, phase: float, wa: float, wb: float) -> void:
	var along := b - a
	var side := along.cross(Vector3.UP).normalized() * width * 0.5
	if side.length() < 0.0001:
		side = Vector3(width * 0.5, 0, 0)
	var v: Array[Vector3] = [a - side, a + side, b + side, b - side]
	var w: Array[float] = [wa, wa, wb, wb]
	for tri in [[0, 1, 2], [0, 2, 3]]:
		for q in tri:
			st.set_color(Color(phase, w[q], 0))
			st.set_normal(Vector3.UP)
			st.add_vertex(v[q])


# --- Ablauf -------------------------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	var player := Game.player
	if _mm == null or player == null:
		return
	if Settings.spider_blobs != _blobs:
		_blobs = Settings.spider_blobs
		_mm.mesh = _mesh_blob if _blobs else _mesh_full
		if _face_node:
			_face_node.mesh = _mm.mesh
	_drawer_pause = maxf(0.0, _drawer_pause - delta)
	_spawn_t -= delta
	if _spawn_t <= 0.0:
		_spawn_t = SPAWN_EVERY
		_spawn_near(player)
		_despawn_far(player)
	_check -= delta
	if _check <= 0.0:
		_check = CHECK_EVERY
		_guests_react()
	_cobweb_t -= delta
	if _cobweb_t <= 0.0:
		_cobweb_t = 5.0
		_grow_cobwebs(5.0)
	for i in _pos.size():
		_step(i, delta, player)
	_draw()
	_update_face(delta, player)


## Neue Spinnen um den Spieler, wo er nicht hinsieht – so viele, wie das Stockwerk hergibt.
func _spawn_near(player: Player) -> void:
	var p := player.global_position
	var want := _wanted(p)
	var alive := 0
	for i in _pos.size():
		if _state[i] != State.DEAD and absf(_pos[i].y - p.y) < 2.0:
			alive += 1
	if alive >= want or _pos.size() >= MAX:
		return
	if want <= OTHER_COUNT and randf() >= OTHER_CHANCE:
		return
	var at := _floor_spot_near(p, SPAWN_RANGE, true)
	if at != Vector3.INF:
		_add(at)


## Wie viele Spinnen um diesen Punkt herum leben: Keller (unter dem Erdgeschoss) und Dachgeschoss viele, sonst wenige.
func _wanted(p: Vector3) -> int:
	if p.y < -0.3:
		return CELLAR_COUNT
	if p.y > LevelBuilder.UP_Y + 2.5:
		return ATTIC_COUNT
	return OTHER_COUNT


## Ein Punkt am Boden (NavMesh, dann Strahl nach unten) dist.x … dist.y vom Spieler, auf seinem Stockwerk;
## unseen: wo er nicht hinsieht. INF = keiner gefunden.
func _floor_spot_near(p: Vector3, dist: Vector2, unseen: bool) -> Vector3:
	var map := get_world_3d().navigation_map
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return Vector3.INF   # NavMesh noch nicht fertig
	for attempt in 6:
		var a := randf() * TAU
		var d := randf_range(dist.x, dist.y)
		var q := NavigationServer3D.map_get_closest_point(map, p + Vector3(cos(a) * d, 0.3, sin(a) * d))
		if absf(q.y - p.y) > 1.2 or Vector2(q.x - p.x, q.z - p.z).length() < dist.x * 0.7:
			continue
		var f := _floor_at(q)
		if f == Vector3.INF:
			continue
		if unseen and Game.director and Game.director.player_can_see(f + Vector3.UP * 0.05):
			continue
		return f
	return Vector3.INF


func _floor_at(p: Vector3) -> Vector3:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.5, p + Vector3.DOWN * 1.2, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return hit["position"] if not hit.is_empty() else Vector3.INF


func _add(at: Vector3) -> int:
	_pos.append(at)
	_goal.append(at)
	_yaw.append(randf() * TAU)
	_size.append(randf_range(SIZE.x, SIZE.y))
	_speed.append(randf_range(SPEED.x, SPEED.y))
	_state.append(State.PAUSE)
	_timer.append(randf_range(PAUSE.x, PAUSE.y))
	_phase.append(randf() * TAU)
	_floor_t.append(0.0)
	return _pos.size() - 1


func _remove(i: int) -> void:
	for arr in [_pos, _goal, _yaw, _size, _speed, _state, _timer, _phase, _floor_t]:
		arr.remove_at(i)


## Weit weg (oder auf einem anderen Stockwerk) und nicht im Blick: weg damit. Zertretene nach DEAD_TIME.
func _despawn_far(player: Player) -> void:
	for i in range(_pos.size() - 1, -1, -1):
		var gone := _state[i] == State.DEAD and _timer[i] <= 0.0
		var far := _pos[i].distance_to(player.global_position) > NEAR or absf(_pos[i].y - player.global_position.y) > 3.0
		if gone or (far and not Game.director.player_can_see(_pos[i] + Vector3.UP * 0.05)):
			_remove(i)


func _step(i: int, delta: float, player: Player) -> void:
	_timer[i] -= delta
	if _state[i] == State.DEAD:
		return
	var p := _pos[i]
	var feet := player.global_position
	var flat := Vector2(feet.x - p.x, feet.z - p.z)
	var same_floor := absf(feet.y - p.y) < 0.6
	var moving := Vector2(player.velocity.x, player.velocity.z).length()
	# zertreten?
	if same_floor and flat.length() < SQUASH_RANGE * _size[i] + 0.05 and moving > SQUASH_SPEED and not player.hiding:
		_squash(i, true)
		return
	# nahe Füße: fliehen
	if _state[i] != State.FLEE and same_floor and flat.length() < FLEE_RANGE and (moving > 0.2 or not player.crouching):
		_flee(i, feet)
	match _state[i]:
		State.PAUSE:
			_phase[i] += delta * 2.0
			if _timer[i] <= 0.0:
				_new_goal(i)
		State.WALK, State.FLEE:
			var to := _goal[i] - p
			to.y = 0.0
			var speed := FLEE_SPEED if _state[i] == State.FLEE else _speed[i]
			if to.length() < 0.03:
				_state[i] = State.PAUSE
				_timer[i] = randf_range(PAUSE.x, PAUSE.y)
				return
			var stepd := minf(speed * delta, to.length())
			var dir := to.normalized()
			_yaw[i] = lerp_angle(_yaw[i], atan2(-dir.x, -dir.z), minf(1.0, delta * 8.0))
			p += dir * stepd
			_phase[i] += stepd * STEP_RATE / (_size[i] * 0.1)
			_floor_t[i] -= stepd
			if _floor_t[i] <= 0.0:
				_floor_t[i] = 0.25
				var f := _floor_at(p)
				if f == Vector3.INF or absf(f.y - p.y) > 0.35:
					_goal[i] = _pos[i]   # Kante oder Wand – stehen bleiben, gleich ein neues Ziel
					return
				p.y = f.y
			_pos[i] = p


## Neues Ziel LEG entfernt in einer Richtung ohne Wand dazwischen (Strahl knapp über dem Boden).
func _new_goal(i: int) -> void:
	var p := _pos[i]
	var space := get_world_3d().direct_space_state
	for attempt in 4:
		var a := _yaw[i] + randf_range(-1.6, 1.6) if attempt < 2 else randf() * TAU
		var d := randf_range(LEG.x, LEG.y)
		var to := p + Vector3(-sin(a), 0, -cos(a)) * d
		var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.05, to + Vector3.UP * 0.05, 1)
		if space.intersect_ray(q).is_empty():
			_goal[i] = to
			_state[i] = State.WALK
			return
	_timer[i] = randf_range(PAUSE.x, PAUSE.y)


func _flee(i: int, from: Vector3) -> void:
	var away := _pos[i] - from
	away.y = 0.0
	if away.length() < 0.01:
		away = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	var p := _pos[i]
	var space := get_world_3d().direct_space_state
	for attempt in 4:
		var dir := away.normalized().rotated(Vector3.UP, randf_range(-0.8, 0.8) * (attempt + 1))
		var to := p + dir * randf_range(1.2, 2.2)
		var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.05, to + Vector3.UP * 0.05, 1)
		if space.intersect_ray(q).is_empty():
			_goal[i] = to
			_state[i] = State.FLEE
			return


func _squash(i: int, by_player: bool) -> void:
	_state[i] = State.DEAD
	_timer[i] = DEAD_TIME
	if by_player:
		Game.play_sound("thud", 0.12)
		if Game.tracing:
			print("[Spinnen] zertreten")


func _draw() -> void:
	_mm.visible_instance_count = _pos.size()
	for i in _pos.size():
		var dead := _state[i] == State.DEAD
		var b := Basis(Vector3.UP, _yaw[i]).scaled(Vector3(_size[i], _size[i] * (0.25 if dead else 1.0), _size[i]))
		_mm.set_instance_transform(i, Transform3D(b, _pos[i] + Vector3.UP * 0.002))
		var walking := _state[i] in [State.WALK, State.FLEE]
		_mm.set_instance_custom_data(i, Color(fmod(_phase[i], TAU), 1.0 if walking else 0.0, 0, 0))


func _now() -> float:
	return Game.director.elapsed if Game.director else 0.0


## Wo Spinnen leben, wächst Spinnweben schneller nach (ResourceSpot.grow).
func _grow_cobwebs(seconds: float) -> void:
	if _pos.is_empty():
		return
	for node in get_tree().get_nodes_in_group("resource_spots"):
		var spot := node as ResourceSpot
		if spot.kind != Item.Kind.COBWEB:
			continue
		var n := 0
		for i in _pos.size():
			if _state[i] != State.DEAD and _pos[i].distance_to(spot.global_position) < COBWEB_RANGE:
				n += 1
		if n > 0:
			spot.grow(seconds * minf(2.0, COBWEB_BOOST * n))


# --- Gäste ------------------------------------------------------------------------------------------------

## Mutige zertreten Spinnen vor ihren Füßen, ängstliche erschrecken (etwas Angst), die übrigen lassen sie laufen.
func _guests_react() -> void:
	if Game.social == null or _pos.is_empty():
		return
	var player := Game.player
	for guest in Game.social.guests:
		var g: Guest = guest
		if g.dead or g.hiding != null or g.global_position.distance_to(player.global_position) > 15.0 \
				or g.state in [Guest.State.SLEEP, Guest.State.TALKING, Guest.State.MINIGAME]:
			continue
		for i in _pos.size():
			if _state[i] == State.DEAD or absf(_pos[i].y - g.global_position.y) > 0.6:
				continue
			var d := Vector2(_pos[i].x - g.global_position.x, _pos[i].z - g.global_position.z).length()
			if d > GUEST_RANGE:
				continue
			var brave := float(g.profile["brave"])
			if brave >= GUEST_BRAVE and not g.is_child():
				_squash(i, false)
				_guest_line(g, BRAVE_LINES)
			else:
				_flee(i, g.global_position)
				if brave < GUEST_TIMID or g.is_child():
					g.fear = minf(100.0, g.fear + GUEST_FEAR)
					_guest_line(g, TIMID_LINES)
			break


func _guest_line(g: Guest, lines: Array) -> void:
	var now := _now()
	if now - float(_guest_said.get(g.id, -INF)) < GUEST_LINE_PAUSE:
		return
	_guest_said[g.id] = now
	g.say(lines.pick_random())
	if Game.tracing:
		print("[Spinnen] %s: %s" % [g.display_name, "zertritt eine" if lines == BRAVE_LINES else "erschrickt"])


# --- Schublade und Gesicht ------------------------------------------------------------------------------

## Eine Schublade wurde aufgezogen (Dresser): Mit DRAWER_CHANCE springt eine Spinne heraus – erst nach dem ersten
## Angriff, nicht während einer anderen Spinne im Gesicht, danach DRAWER_PAUSE Ruhe.
func on_drawer_opened(at: Vector3) -> void:
	var player := Game.player
	if _face != Face.NONE or player.dead or player.sleeping or player.hiding != null or player.in_dialog \
			or Game.director == null or not Game.director.first_attack_done:
		return
	if not _force_drawer:
		if _drawer_pause > 0.0:
			return
		if randf() >= DRAWER_CHANCE:
			return
	_force_drawer = false
	jump_at_face(at)


## Die Spinne springt von `from` ins Gesicht: Schreck, man schnappt nach Luft (Lärm).
func jump_at_face(from: Vector3) -> void:
	var player := Game.player
	_drawer_pause = DRAWER_PAUSE
	if _face_node == null:
		_face_node = MeshInstance3D.new()
		_face_node.material_override = _face_mat
		_face_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_face_node.mesh = _mm.mesh
	if _face_node.get_parent() != player.camera:
		if _face_node.get_parent():
			_face_node.get_parent().remove_child(_face_node)
		player.camera.add_child(_face_node)
	_face_node.visible = true
	_face = Face.JUMP
	_face_t = 0.0
	_face_from = from
	_shake = 0.0
	_last_look = Vector2(player.rotation.y, player.head.rotation.x)
	player.add_shock(FACE_SHOCK, false)
	Game.noise("gasp", player.camera.global_position, player)
	Game.caption("[Eine Spinne springt dir ins Gesicht!]")
	Game.say("Schüttel sie ab! (Maus schnell hin und her)", FACE_TIME)
	if Game.tracing:
		print("[Spinnen] springt dir ins Gesicht")


func _update_face(delta: float, player: Player) -> void:
	if _face == Face.NONE:
		return
	_face_t += delta
	var look := Vector2(player.rotation.y, player.head.rotation.x)
	_shake += absf(angle_difference(_last_look.x, look.x)) + absf(look.y - _last_look.y)
	_last_look = look
	_face_mat.set_shader_parameter("phase", _face_t * 22.0)
	var cam := player.camera
	if _face == Face.JUMP:
		var k := clampf(_face_t / JUMP_TIME, 0.0, 1.0)
		var from_local := cam.global_transform.affine_inverse() * _face_from
		_face_node.position = from_local.lerp(FACE_POS, k * k)
		_face_node.rotation = Vector3(-PI / 2.0, 0, randf_range(-0.05, 0.05))
		_face_node.scale = Vector3.ONE * lerpf(0.5, FACE_SCALE, k)
		if k >= 1.0:
			_face = Face.ON
			_face_t = 0.0
			_shake = 0.0
		return
	_face_node.position = FACE_POS + Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * 0.0015   # krabbelt
	if _shake >= SHAKE:
		_end_face(player, false)
	elif _face_t >= FACE_TIME or player.dead:
		_end_face(player, not player.dead)


## Abgeschüttelt (sie fällt vor einem zu Boden und flieht) oder Biss: wirkt wie ein Glas.
func _end_face(player: Player, bitten: bool) -> void:
	_face = Face.NONE
	_face_node.visible = false
	if bitten:
		player.drunk = minf(1.0, player.drunk + BITE)
		Game.play_sound("gasp", 0.6)
		Game.say("Au! Sie hat mich gebissen … mir wird schwindlig.", 3.0)
		Game.caption("[Ein Biss]")
	else:
		Game.say("Weg damit!", 1.5)
	if Game.tracing:
		print("[Spinnen] %s (Kopfdrehen %.1f rad, Rausch %.2f)" % ["gebissen" if bitten else "abgeschüttelt", _shake, player.drunk])
	var fwd := -player.global_transform.basis.z
	var f := _floor_at(player.global_position + fwd * 0.8)
	if f != Vector3.INF and _pos.size() < MAX:
		var i := _add(f)
		_flee(i, player.global_position)


func face_active() -> bool:
	return _face != Face.NONE


# --- Debug ------------------------------------------------------------------------------------------------

## Debug (--spinne[=gesicht|schublade]): ohne Wert krabbeln sofort acht Spinnen 1,5–4 m vor dir; gesicht: eine
## springt dir sofort ins Gesicht; schublade: du stehst vor der nächsten Kommode, nach 1 s ziehst du die oberste
## Schublade auf, und es springt eine heraus. Mit gesicht und schublade gilt der erste Angriff als geschehen.
func debug(what: String) -> void:
	var player := Game.player
	match what:
		"gesicht":
			Game.director.first_attack_done = true
			var fwd := -player.camera.global_transform.basis.z
			jump_at_face(player.camera.global_position + fwd * 0.6 + Vector3.DOWN * 0.5)
		"schublade":
			Game.director.first_attack_done = true
			_force_drawer = true
			var best: Dresser = null
			for node in get_tree().get_nodes_in_group("dressers"):
				if best == null or (node as Node3D).global_position.distance_to(player.global_position) < best.global_position.distance_to(player.global_position):
					best = node
			if best == null:
				Game.say("Spinne: Hier gibt es keine Kommode.", 2.5)
				return
			var front := best.global_transform.basis.z.normalized()
			player.global_position = best.global_position + front * 1.1 + Vector3.UP * 0.05
			var to := best.global_position - player.global_position
			player.rotation.y = atan2(-to.x, -to.z)
			player.head.rotation.x = -0.5
			get_tree().create_timer(1.0, false).timeout.connect(func() -> void:
				if is_instance_valid(best) and not best.is_open[-1]:
					best.use_drawer(best.is_open.size() - 1, player))
		_:
			var fwd := -player.global_transform.basis.z
			for n in 8:
				var at := player.global_position + fwd.rotated(Vector3.UP, randf_range(-0.7, 0.7)) * randf_range(1.5, 4.0)
				var f := _floor_at(at)
				if f != Vector3.INF and _pos.size() < MAX:
					var i := _add(f)
					_timer[i] = randf_range(0.0, 1.0)
			player.head.rotation.x = -0.6   # zu Boden sehen
