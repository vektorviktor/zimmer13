class_name Rats
extends Node3D
## Ratten im Untergeschoss (Spielkonzept 4.25): Sie huschen an den Wänden entlang, bleiben stehen, schnuppern und
## fliehen vor nahen Füßen. Es gibt sie nur in der Nähe des Spielers und nur unten; neue tauchen auf, wo er nicht
## hinsieht (wie die Spinnen, 4.23).
## **Frühwarnung unten:** Bricht das Monster aus dem Heizkeller auf oder kommt es näher als WAVE_RANGE, rennen alle
## Ratten um den Spieler quiekend in dieselbe Richtung davon – weg von ihm, oft am Spieler vorbei. Unten gibt es selten
## Katzen (6.11), die Ratten sind ihre Stimme. Ein Hinweis, keine Garantie.
## **Kerzen:** Eine Kerze, die unten am Boden liegt, schleppen sie nach einer Weile weg, wenn niemand hinsieht.
## Dazu im Müllraum ein Glas mit einem Rattenkönig (RatKing). Nur Klang, kein Lärm – das Monster mag sie nicht anders
## als die Katzen; Gäste gehen nicht hinunter. Nicht gespeichert.

enum State { WALK, PAUSE, FLEE, RUN }

const MAX := 9
const WANT := 5                       ## so viele um den Spieler herum
const NEAR := 28.0
const SPAWN_EVERY := 2.5
const SPAWN_RANGE := Vector2(5.0, 16.0)
const SIZE := Vector2(0.85, 1.15)
const SPEED := Vector2(0.5, 1.1)
const FLEE_SPEED := 3.2
const RUN_SPEED := 3.8
const PAUSE := Vector2(0.8, 4.0)
const LEG := Vector2(0.8, 3.0)
const STEP_RATE := 22.0
const FLEE_RANGE := 2.2
const CHECK_EVERY := 0.25
## Welle: das Monster so nah (gleiches Stockwerk) oder gerade aufgebrochen – sie rennen so lange und quieken so oft
const WAVE_RANGE := 30.0
const WAVE_TIME := 4.5
const WAVE_PAUSE := 40.0
const SQUEAK_EVERY := Vector2(0.4, 1.2)
## Kerzen: so nah an einer Ratte, so lange (Sekunden, aufgesammelt), dann ist sie weg
const CANDLE_RANGE := 1.2
const CANDLE_TIME := 45.0

var _builder: LevelBuilder
var _mm: MultiMesh
var _pos: Array[Vector3] = []
var _goal: Array[Vector3] = []
var _yaw: Array[float] = []
var _size: Array[float] = []
var _speed: Array[float] = []
var _state: Array[int] = []
var _timer: Array[float] = []
var _phase: Array[float] = []
var _spawn_t := 0.0
var _check := 0.0
var _wave_left := 0.0
var _wave_from := Vector3.ZERO
var _last_wave := -INF
var _squeak_t := 0.0
var _was_active := false
var _nibbled := {}                    ## Item → Sekunden, die schon an ihr genagt wurde
var _noted := false


func setup(builder: LevelBuilder) -> void:
	_builder = builder
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/psx_spider.gdshader")
	mat.set_shader_parameter("albedo", Color(0.16, 0.13, 0.11))
	mat.set_shader_parameter("step_swing", 0.05)
	mat.set_shader_parameter("step_lift", 0.02)
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_custom_data = true
	_mm.mesh = _build_mesh()
	_mm.instance_count = MAX
	_mm.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(Vector3(-500, -50, -500), Vector3(1000, 200, 1000))
	add_child(mmi)


## Ratte, vorn ist −Z, Körper gut 20 cm, Schwanz noch einmal so lang. Eckfarbe wie bei den Spinnen: r = Phase des
## Beins, g = Gewicht (die Füße und die Schwanzspitze bewegen sich).
func _build_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	Spiders._ellipsoid(st, Vector3(0, 0.05, 0.02), Vector3(0.045, 0.04, 0.09))   # Leib
	Spiders._ellipsoid(st, Vector3(0, 0.05, -0.08), Vector3(0.028, 0.026, 0.045))   # Kopf, spitz zur Schnauze
	Spiders._ellipsoid(st, Vector3(0, 0.045, -0.125), Vector3(0.012, 0.012, 0.018))
	for side in [1.0, -1.0]:
		Spiders._ellipsoid(st, Vector3(side * 0.02, 0.078, -0.07), Vector3(0.012, 0.012, 0.004))   # Ohren
		for k in 2:
			var z := -0.04 if k == 0 else 0.07
			var root := Vector3(side * 0.03, 0.03, z)
			var foot := Vector3(side * 0.04, 0.0, z - 0.01)
			Spiders._band(st, root, foot, 0.012, 0.5 * float((k + (0 if side > 0.0 else 1)) % 2), 0.2, 1.0)
	# Schwanz: dünnes Band nach hinten, die Spitze pendelt mit
	Spiders._band(st, Vector3(0, 0.04, 0.1), Vector3(0, 0.02, 0.2), 0.012, 0.25, 0.0, 0.4)
	Spiders._band(st, Vector3(0, 0.02, 0.2), Vector3(0.02, 0.008, 0.3), 0.007, 0.25, 0.4, 1.0)
	return st.commit()


func _physics_process(delta: float) -> void:
	var player := Game.player
	if _mm == null or player == null:
		return
	_spawn_t -= delta
	if _spawn_t <= 0.0:
		_spawn_t = SPAWN_EVERY
		_spawn_near(player)
		_despawn_far(player)
	_check -= delta
	if _check <= 0.0:
		_check = CHECK_EVERY
		_check_monster(player)
		_nibble_candles(CHECK_EVERY)
	if _wave_left > 0.0:
		_wave_left -= delta
		_squeak_t -= delta
		if _squeak_t <= 0.0 and not _pos.is_empty():
			_squeak_t = randf_range(SQUEAK_EVERY.x, SQUEAK_EVERY.y)
			Game.sound_at("squeak", _pos[randi() % _pos.size()], 10.0, self)
	for i in _pos.size():
		_step(i, delta, player)
	_draw()


func _below(p: Vector3) -> bool:
	return p.y < LevelBuilder.CELLAR_Y + 2.0


func _spawn_near(player: Player) -> void:
	var p := player.global_position
	if not _below(p) or _wave_left > 0.0 or _pos.size() >= MAX:
		return
	var alive := 0
	for q in _pos:
		if absf(q.y - p.y) < 2.0:
			alive += 1
	if alive >= WANT:
		return
	var map := get_world_3d().navigation_map
	if NavigationServer3D.map_get_iteration_id(map) == 0:
		return
	for attempt in 6:
		var a := randf() * TAU
		var d := randf_range(SPAWN_RANGE.x, SPAWN_RANGE.y)
		var q := NavigationServer3D.map_get_closest_point(map, p + Vector3(cos(a) * d, 0.3, sin(a) * d))
		if absf(q.y - p.y) > 1.2 or Vector2(q.x - p.x, q.z - p.z).length() < SPAWN_RANGE.x * 0.7:
			continue
		var f := _floor_at(q)
		if f == Vector3.INF or (Game.director and Game.director.player_can_see(f + Vector3.UP * 0.1)):
			continue
		_add(f)
		return


func _floor_at(p: Vector3) -> Vector3:
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.5, p + Vector3.DOWN * 1.2, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	return hit["position"] if not hit.is_empty() else Vector3.INF


func _add(at: Vector3) -> void:
	_pos.append(at)
	_goal.append(at)
	_yaw.append(randf() * TAU)
	_size.append(randf_range(SIZE.x, SIZE.y))
	_speed.append(randf_range(SPEED.x, SPEED.y))
	_state.append(State.PAUSE)
	_timer.append(randf_range(PAUSE.x, PAUSE.y))
	_phase.append(randf() * TAU)


func _remove(i: int) -> void:
	for arr in [_pos, _goal, _yaw, _size, _speed, _state, _timer, _phase]:
		arr.remove_at(i)


func _despawn_far(player: Player) -> void:
	for i in range(_pos.size() - 1, -1, -1):
		var far := _pos[i].distance_to(player.global_position) > NEAR or absf(_pos[i].y - player.global_position.y) > 3.0
		var gone := _state[i] == State.RUN and _wave_left <= 0.0
		if (far or gone) and not Game.director.player_can_see(_pos[i] + Vector3.UP * 0.1):
			_remove(i)


func _step(i: int, delta: float, player: Player) -> void:
	_timer[i] -= delta
	var p := _pos[i]
	var feet := player.global_position
	var flat := Vector2(feet.x - p.x, feet.z - p.z)
	var moving := Vector2(player.velocity.x, player.velocity.z).length()
	if _state[i] in [State.WALK, State.PAUSE] and absf(feet.y - p.y) < 0.8 and flat.length() < FLEE_RANGE \
			and (moving > 0.2 or not player.crouching):
		_head_off(i, feet, State.FLEE)
	match _state[i]:
		State.PAUSE:
			_phase[i] += delta * 3.0   # schnuppert
			if _timer[i] <= 0.0:
				_new_goal(i)
		_:
			var to := _goal[i] - p
			to.y = 0.0
			var speed := _speed[i]
			if _state[i] == State.FLEE:
				speed = FLEE_SPEED
			elif _state[i] == State.RUN:
				speed = RUN_SPEED
			if to.length() < 0.05:
				if _state[i] == State.RUN and _wave_left > 0.0:   # weiter in dieselbe Richtung
					_head_off(i, _wave_from, State.RUN)
					return
				_state[i] = State.PAUSE
				_timer[i] = randf_range(PAUSE.x, PAUSE.y)
				return
			var stepd := minf(speed * delta, to.length())
			var dir := to.normalized()
			_yaw[i] = lerp_angle(_yaw[i], atan2(-dir.x, -dir.z), minf(1.0, delta * 12.0))
			p += dir * stepd
			_phase[i] += stepd * STEP_RATE
			var f := _floor_at(p)
			if f == Vector3.INF or absf(f.y - p.y) > 0.35:
				_goal[i] = _pos[i]
				return
			p.y = f.y
			_pos[i] = p


func _new_goal(i: int) -> void:
	var p := _pos[i]
	var space := get_world_3d().direct_space_state
	for attempt in 4:
		var a := _yaw[i] + randf_range(-1.6, 1.6) if attempt < 2 else randf() * TAU
		var to := p + Vector3(-sin(a), 0, -cos(a)) * randf_range(LEG.x, LEG.y)
		var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.06, to + Vector3.UP * 0.06, 1)
		if space.intersect_ray(q).is_empty():
			_goal[i] = to
			_state[i] = State.WALK
			return
	_timer[i] = randf_range(PAUSE.x, PAUSE.y)


## Weg von `from` (Spieler oder Monster), ein Stück weit an einer freien Stelle.
func _head_off(i: int, from: Vector3, state: State) -> void:
	var away := _pos[i] - from
	away.y = 0.0
	if away.length() < 0.01:
		away = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	var p := _pos[i]
	var space := get_world_3d().direct_space_state
	for attempt in 5:
		var dir := away.normalized().rotated(Vector3.UP, randf_range(-0.6, 0.6) * (attempt + 1))
		var to := p + dir * randf_range(2.0, 4.0)
		var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.06, to + Vector3.UP * 0.06, 1)
		var hit := space.intersect_ray(q)
		if hit.is_empty() or (hit["position"] as Vector3).distance_to(p) > 1.0:
			_goal[i] = to if hit.is_empty() else (hit["position"] as Vector3) - dir * 0.3
			_state[i] = state
			return


## Monster unterwegs und nah (gleiches Stockwerk) oder eben aus dem Heizkeller aufgebrochen → die Welle.
func _check_monster(player: Player) -> void:
	var m := Game.monster
	var active := m != null and m.is_active()
	var started := active and not _was_active
	_was_active = active
	if not active or not _below(player.global_position) or _pos.is_empty():
		return
	var now := Game.director.elapsed if Game.director else 0.0
	var near := absf(m.global_position.y - player.global_position.y) < 2.5 \
		and m.global_position.distance_to(player.global_position) < WAVE_RANGE
	if not (started or near) or now - _last_wave < WAVE_PAUSE:
		return
	_last_wave = now
	start_wave(m.global_position)


func start_wave(from: Vector3) -> void:
	_wave_from = from
	_wave_left = WAVE_TIME
	_squeak_t = 0.0
	for i in _pos.size():
		_head_off(i, from, State.RUN)
	if Game.tracing:
		print("[Ratten] Welle – %d rennen weg von %s" % [_pos.size(), from.snapped(Vector3.ONE * 0.1)])
	if not _noted and Game.notebook:
		_noted = true
		Game.notebook.add_note("rats", "Im Keller rannten auf einmal alle Ratten in dieselbe Richtung, quiekend, an mir vorbei.", "Keller")


## Kerzen, die unten am Boden liegen, verschwinden nach einer Weile, wenn Ratten in der Nähe sind und niemand hinsieht.
func _nibble_candles(dt: float) -> void:
	if _pos.is_empty():
		return
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.kind != Item.Kind.CANDLE or item.is_held or not _below(item.global_position):
			continue
		var close := _pos.any(func(p: Vector3) -> bool: return p.distance_to(item.global_position) < CANDLE_RANGE)
		if not close:
			continue
		_nibbled[item] = float(_nibbled.get(item, 0.0)) + dt
		if float(_nibbled[item]) >= CANDLE_TIME and not Game.director.player_can_see(item.global_position + Vector3.UP * 0.05):
			_nibbled.erase(item)
			if Game.tracing:
				print("[Ratten] schleppen eine Kerze weg")
			item.queue_free()


func _draw() -> void:
	_mm.visible_instance_count = _pos.size()
	for i in _pos.size():
		var b := Basis(Vector3.UP, _yaw[i]).scaled(Vector3.ONE * _size[i])
		_mm.set_instance_transform(i, Transform3D(b, _pos[i] + Vector3.UP * 0.002))
		var moving := _state[i] != State.PAUSE
		_mm.set_instance_custom_data(i, Color(fmod(_phase[i], TAU), 1.0 if moving else 0.25, 0, 0))


## Debug (--ratten[=welle]): fünf Ratten 3–8 m um dich im Keller (vorher mit --tp=keller hinstellen, sonst springst
## du in den Heizkeller) · welle: nach 2 s rennen sie, als käme das Monster aus dem Heizkeller.
func debug(what: String) -> void:
	var player := Game.player
	if not _below(player.global_position):
		TeleportUI.place_player(_builder.cellar_center() + Vector3(0, 0.05, 6.0), Vector3(0, 0, 1))
	var p := player.global_position
	for k in WANT:
		var a := TAU * k / WANT + 0.3
		var f := _floor_at(p + Vector3(cos(a), 0.3, sin(a)) * randf_range(3.0, 8.0))
		if f != Vector3.INF:
			_add(f)
	if what == "welle":
		get_tree().create_timer(2.0, false).timeout.connect(func() -> void:
			start_wave(_builder.cellar_center()))
