class_name Bats
extends Node3D
## Fledermäuse draußen (Spielkonzept 4.22, Stimmung ohne Biss – der kommt mit dem Vampir). Tagsüber (Morgen und Tag)
## hängen sie schlafend in den Baumkronen des Gartens, abends und nachts kreisen sie um die Bäume, zackig wie
## Fledermäuse. Sie sind scheu: Kommt man ihnen fliegend zu nah, drehen sie ab; wer unter ihrem Schlafbaum entlanggeht,
## schreckt sie auf – mit Licht oder rennend schon von weiter weg (Senses.conspicuity). Sie fliehen auch vor Monster,
## Kürbismann und Lakengeist: Ein Schwarm, der draußen auffliegt, warnt (wie die schwingenden Lakengespenster, 5.6).
## Ein aufgeschreckter Schwarm flattert hörbar und ist Lärm (4.15). Laute Geräusche in der Nähe wecken sie auch.
## Auf dem Dachboden hängen tagsüber kleine Kolonien unter den Balkenkreuzen der Stützbalken (LevelBuilder.attic_beams);
## Licht, Rennen, Lärm oder eine Bedrohung schrecken sie auf, dann flattern sie eine Weile in der Kammer um den Pfosten
## und hängen sich wieder hin. Nachts sind sie draußen (oben nicht zu sehen) – gewechselt wird nur, solange der Spieler
## nicht im Dachgeschoss ist. Dort beißen sie nie (4.22).
## Ein MultiMesh (shaders/psx_bat.gdshader), Flug und Flügelschlag rechnet das Skript – in der Pause steht alles.
## Noch nicht: Biss und Vampir.
## Nicht gespeichert: Nach dem Laden hängen bzw. fliegen sie, wie es die Uhrzeit will.

enum Mode { ROOST, FLY, HOME, FLEE, OUT }   ## OUT: vom Dachboden ausgeflogen (nachts)

const COUNT := 36                    ## draußen; dazu die auf dem Dachboden
## Dachboden: so viele, in Kolonien zu je ATTIC_COLONY an zufälligen Pfosten; nicht näher am Pfosten als ATTIC_ARM_GAP
## (Kopfband). Aufgeschreckt: Kreisbahn um den Pfosten (Halbmesser, Höhe über dem Boden), langsamer und ruhiger als draußen
const ATTIC_COUNT := 24
const ATTIC_COLONY := 4
const ATTIC_ARM_GAP := 0.75
const ATTIC_ORBIT := Vector2(0.9, 2.2)
const ATTIC_FLY_Y := Vector2(1.15, 1.7)
const ATTIC_SPEED := 0.6
const ATTIC_JITTER := 0.35
const ATTIC_THREAT := 9.0            ## Bedrohung so nah am Pfosten (im Dachgeschoss): Kolonie fliegt auf
## Der Spieler schreckt sie ab so viel × Auffälligkeit auf – kleiner als draußen, die Kammern sind eng: im Dunkeln
## geduckt kommt man unter ihnen durch, mit Taschenlampe oder rennend nicht
const ATTIC_DISTURB := 1.8
const SCALE := 1.25                  ## Modell (Spannweite ~0,4 m) so viel größer – sonst sieht man sie nachts kaum
const ROOST_DROP := 0.07             ## der Körper hängt so weit unter dem Ast
const ROOST_SPREAD := 0.55           ## Schlafplätze bis zu diesem Anteil des Kronenradius von der Stammachse
const ROOST_HEIGHT := Vector2(-0.03, 0.06)   ## um den unteren Rand der Krone (Anteil der Baumhöhe) – manche sieht man von unten
const ORBIT_RADIUS := Vector2(1.0, 4.5)   ## Kreisbahn außerhalb der Krone: Kronenradius + so viel
const ORBIT_HEIGHT := Vector2(3.5, 9.0)
const FLY_SPEED := Vector2(3.5, 5.5)
const FLEE_SPEED := 8.0
const ACCEL := 16.0
const JITTER := 3.0                  ## zackig: zufällige Querbeschleunigung …
const JITTER_EVERY := Vector2(0.15, 0.5)   ## … so oft neu
const MIN_Y := 1.6
const MAX_Y := 18.0
const ROOF_CLEAR := 10.0             ## über dieser Höhe darf er auch über dem Haus sein
const FLAP_RATE := 10.0              ## Flügelschläge je Sekunde
## Scheu: fliegend weicht er dem Spieler ab so viel aus; am Schlafbaum schreckt man sie ab so viel × Auffälligkeit auf
const SHY_RANGE := 3.5
const SHY_TIME := 1.2
const ROOST_DISTURB := 3.2
## Bedrohungen (Monster, Kürbismann, Lakengeist): so nah, dann fliegen sie auf bzw. davon
const THREAT_RANGE := 14.0
const FLEE_TIME := Vector2(5.0, 10.0)
const FLEE_UP := 0.7                 ## Fluchtrichtung: so viel nach oben
const CHECK_EVERY := 0.25
const NOISE_PAUSE := 4.0             ## je Baum höchstens so oft Lärm
## Ausflug am Abend und Heimkehr am Morgen: gestaffelt über so viele Sekunden (eine Spielstunde)
const STAGGER := 60.0
const SETTLE_PAUSE := Vector2(20.0, 50.0)   ## nach dem Aufschrecken am Tag so lange, bis sie wieder hängen
const DEBUG_STAND := 13.0

var _builder: LevelBuilder
var _trees: Array[Dictionary] = []   ## LevelBuilder.tree_spots, die draußen stehen
var _posts: Array[Dictionary] = []   ## LevelBuilder.attic_beams mit Kolonie – Gruppe _trees.size() + Index
var _attic_y := INF                  ## Boden des Dachgeschosses
var _n := COUNT                      ## alle Fledermäuse; ab COUNT die vom Dachboden
var _mm: MultiMesh
var _pos := PackedVector3Array()
var _vel := PackedVector3Array()
var _mode := PackedInt32Array()
var _tree := PackedInt32Array()      ## Schlafbaum je Fledermaus (Gruppe; ab _trees.size() ein Pfosten auf dem Dachboden)
var _roost := PackedVector3Array()
var _yaw := PackedFloat32Array()     ## Blickrichtung beim Hängen
var _center := PackedVector3Array()  ## Kreisbahn: Mitte (am Boden), Halbmesser, Höhe, Winkel, Tempo (rad/s, mit Richtung)
var _radius := PackedFloat32Array()
var _height := PackedFloat32Array()
var _angle := PackedFloat32Array()
var _spin := PackedFloat32Array()
var _timer := PackedFloat32Array()   ## FLEE: Rest der Flucht · ROOST/FLY: Verzögerung bis zum Ausflug bzw. zur Heimkehr
var _flee := PackedVector3Array()
var _jitter := PackedVector3Array()
var _jitter_t := PackedFloat32Array()
var _phase := PackedFloat32Array()
var _out_cache := {}                 ## Vector2i (1-m-Zelle) → draußen?
var _noise_at := {}                  ## Baum → Spielzeit des letzten Lärms
var _check := 0.0
var _night := false
var _debug_flush := -1.0             ## Debug (--fledermaus=schwarm): in so vielen Sekunden fliegen sie vom ersten Baum auf


func setup(builder: LevelBuilder) -> void:
	_builder = builder
	for t: Dictionary in builder.tree_spots:
		if _outdoor(t["pos"]):
			_trees.append(t)
	var beams := builder.attic_beams.duplicate()
	beams.shuffle()
	_posts.assign(beams.slice(0, mini(beams.size(), ATTIC_COUNT / ATTIC_COLONY)))
	if not _posts.is_empty():
		_attic_y = (_posts[0]["pos"] as Vector3).y
		_n = COUNT + ATTIC_COUNT
	_build_mesh()
	_night = _active_time()
	for i in _n:
		if i < COUNT:
			_spawn(i)
		else:
			_spawn_attic(i)


## Abend und Nacht fliegen sie (2.4), Morgen und Tag hängen sie.
func _active_time() -> bool:
	return Calendar.phase() in [Calendar.Phase.EVENING, Calendar.Phase.NIGHT]


func _spawn(i: int) -> void:
	var t := i % maxi(1, _trees.size())
	var tree: Dictionary = _trees[t] if not _trees.is_empty() else {"pos": Vector3.ZERO, "radius": 4.0, "height": 9.0, "crown": Vector2(0.35, 1.0)}
	var base: Vector3 = tree["pos"]
	var r: float = tree["radius"]
	var h: float = tree["height"]
	var crown: Vector2 = tree["crown"]
	var a := randf() * TAU
	var d := sqrt(randf()) * r * ROOST_SPREAD
	_tree.append(t)
	_roost.append(base + Vector3(cos(a) * d, h * (crown.x + randf_range(ROOST_HEIGHT.x, ROOST_HEIGHT.y)), sin(a) * d))
	_yaw.append(randf() * TAU)
	var orbit_r := r + randf_range(ORBIT_RADIUS.x, ORBIT_RADIUS.y)
	_center.append(base)
	_radius.append(_fit_orbit(base, orbit_r))
	_height.append(randf_range(ORBIT_HEIGHT.x, ORBIT_HEIGHT.y))
	_angle.append(randf() * TAU)
	_spin.append(randf_range(FLY_SPEED.x, FLY_SPEED.y) / orbit_r * (1.0 if randf() < 0.5 else -1.0))
	_timer.append(0.0)
	_flee.append(Vector3.ZERO)
	_jitter.append(Vector3.ZERO)
	_jitter_t.append(0.0)
	_phase.append(randf() * TAU)
	_vel.append(Vector3.ZERO)
	if _night:
		_mode.append(Mode.FLY)
		_pos.append(_orbit_point(i))
	else:
		_mode.append(Mode.ROOST)
		_pos.append(_roost[i])


## Fledermaus auf dem Dachboden: hängt unter einem Arm des Balkenkreuzes ihres Pfostens, kreist aufgeschreckt um ihn –
## so weit, wie der kürzeste Arm reicht (dort beginnen Wand oder Schräge).
func _spawn_attic(i: int) -> void:
	var k := (i - COUNT) % _posts.size()
	var post: Dictionary = _posts[k]
	var base: Vector3 = post["pos"]
	var arms: Array = post["arms"]
	var arm: Array = arms.pick_random() if not arms.is_empty() else [Vector3.RIGHT, ATTIC_ARM_GAP]
	var length := float(arm[1])
	var along := randf_range(ATTIC_ARM_GAP, maxf(ATTIC_ARM_GAP, length - 0.15))
	var dir: Vector3 = arm[0]
	var side := Vector3(-dir.z, 0, dir.x) * randf_range(-0.05, 0.05)
	var reach := INF
	for a: Array in arms:
		reach = minf(reach, float(a[1]))
	if arms.size() < 4:
		reach = 0.0   # in einer Richtung steht die Wand gleich am Pfosten
	_tree.append(_trees.size() + k)
	_roost.append(base + dir * along + side + Vector3.UP * LevelBuilder.ATTIC_BEAM_BOTTOM)
	_yaw.append(atan2(dir.x, dir.z) + (PI / 2.0 if randf() < 0.5 else -PI / 2.0))
	_center.append(base)
	_radius.append(clampf(reach - 0.4, ATTIC_ORBIT.x, ATTIC_ORBIT.y) * randf_range(0.75, 1.0))
	_height.append(randf_range(ATTIC_FLY_Y.x, ATTIC_FLY_Y.y))
	_angle.append(randf() * TAU)
	_spin.append(randf_range(FLY_SPEED.x, FLY_SPEED.y) * ATTIC_SPEED / _radius[i] * (1.0 if randf() < 0.5 else -1.0))
	_timer.append(0.0)
	_flee.append(Vector3.ZERO)
	_jitter.append(Vector3.ZERO)
	_jitter_t.append(0.0)
	_phase.append(randf() * TAU)
	_vel.append(Vector3.ZERO)
	_mode.append(Mode.OUT if _night else Mode.ROOST)
	_pos.append(_roost[i])


func _is_attic(i: int) -> bool:
	return i >= COUNT


## Steht der Spieler im Dachgeschoss? Solange wechseln die Fledermäuse dort nicht zwischen hängen und ausgeflogen.
func _player_in_attic() -> bool:
	var p := Game.player
	return p != null and not p.dead and absf(p.global_position.y - _attic_y) < 1.5


## Kleinere Kreisbahn, bis sie ganz über Garten oder Hof liegt (acht Punkte).
func _fit_orbit(c: Vector3, r: float) -> float:
	while r > 1.5:
		var ok := true
		for k in 8:
			var a := TAU * k / 8.0
			if not _outdoor(c + Vector3(cos(a) * r, 0, sin(a) * r)):
				ok = false
				break
		if ok:
			return r
		r *= 0.8
	return 1.5


func _orbit_point(i: int) -> Vector3:
	var c := _center[i]
	var wave := 0.15 if _is_attic(i) else 0.8
	return Vector3(c.x + cos(_angle[i]) * _radius[i], c.y + _height[i] + sin(_angle[i] * 2.3 + i) * wave, c.z + sin(_angle[i]) * _radius[i])


## Draußen am Boden (Garten, Hof, Terrasse) – je Quadratmeter einmal beim LevelBuilder nachgefragt.
func _outdoor(p: Vector3) -> bool:
	var cell := Vector2i(floori(p.x), floori(p.z))
	if not _out_cache.has(cell):
		_out_cache[cell] = _builder.is_outdoor(Vector3(cell.x + 0.5, 0.1, cell.y + 0.5))
	return _out_cache[cell]


## Ein Körper (Raute mit Ohren) und zwei Flügel mit gezacktem Hinterrand; vorn ist −Z.
func _build_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body: Array[Vector3] = [Vector3(0, 0, -0.07), Vector3(0.02, 0, -0.01), Vector3(0, 0.022, 0), Vector3(-0.02, 0, -0.01),
		Vector3(0, -0.018, 0), Vector3(0, 0, 0.06)]
	for tri in [[0, 1, 2], [0, 2, 3], [0, 3, 4], [0, 4, 1], [5, 2, 1], [5, 3, 2], [5, 4, 3], [5, 1, 4]]:
		for k in tri:
			st.set_normal(body[k].normalized())
			st.add_vertex(body[k])
	for side in [1.0, -1.0]:
		for ear in [[Vector3(0.006, 0.012, -0.045), Vector3(0.016, 0.012, -0.04), Vector3(0.012, 0.04, -0.05)]]:
			for v: Vector3 in ear:
				st.set_normal(Vector3.BACK)
				st.add_vertex(Vector3(v.x * side, v.y, v.z))
		var w: Array[Vector3] = [Vector3(0.02, 0, -0.03), Vector3(0.2, 0.01, -0.01), Vector3(0.16, 0, 0.065),
			Vector3(0.11, 0, 0.035), Vector3(0.07, 0, 0.075), Vector3(0.02, 0, 0.045)]
		for tri in [[0, 1, 2], [0, 2, 3], [0, 3, 4], [0, 4, 5]]:
			for k in tri:
				st.set_normal(Vector3.UP)
				st.add_vertex(Vector3(w[k].x * side, w[k].y, w[k].z))
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/psx_bat.gdshader")
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_custom_data = true
	_mm.mesh = st.commit()
	_mm.instance_count = _n
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(Vector3(-500, -50, -500), Vector3(1000, 200, 1000))   # Instanzen fliegen überall herum
	add_child(mmi)


func _physics_process(delta: float) -> void:
	if _mm == null:
		return
	var night := _active_time()
	if night != _night:   # Ausflug bzw. Heimkehr, gestaffelt
		_night = night
		for i in _n:
			if _mode[i] != Mode.FLEE and not (_is_attic(i) and _mode[i] == Mode.FLY):   # Aufgeschreckte flattern zu Ende
				_timer[i] = randf() * STAGGER
	_check -= delta
	if _check <= 0.0:
		_check = CHECK_EVERY
		_look_around()
	if _debug_flush >= 0.0:
		_debug_flush -= delta
		if _debug_flush < 0.0 and Game.player:
			# der Baum, auf den du siehst – aufgescheucht von hinten, damit der Schwarm über dich hinwegzieht
			var base: Vector3 = _trees[0]["pos"]
			_flush(0, base * 2.0 - Game.player.global_position, true)
	for i in _n:
		_step(i, delta)
		_draw(i)


func _step(i: int, delta: float) -> void:
	var mode := _mode[i]
	var attic := _is_attic(i)
	_timer[i] -= delta
	if mode == Mode.ROOST:
		if _night and _timer[i] <= 0.0:
			if not attic:
				_mode[i] = Mode.FLY
			elif not _player_in_attic():
				_mode[i] = Mode.OUT
		return
	if mode == Mode.OUT:
		if not _night and _timer[i] <= 0.0 and not _player_in_attic():
			_mode[i] = Mode.ROOST
			_pos[i] = _roost[i]
		return
	var want := Vector3.ZERO
	match mode:
		Mode.FLY:
			if (not _night or attic) and _timer[i] <= 0.0:
				_mode[i] = Mode.HOME
			_angle[i] += _spin[i] * delta
			want = (_orbit_point(i) - _pos[i]).normalized() * absf(_spin[i]) * _radius[i]
		Mode.HOME:
			var to := _roost[i] - _pos[i]
			if to.length() < 0.25:
				_mode[i] = Mode.ROOST
				_pos[i] = _roost[i]
				_vel[i] = Vector3.ZERO
				return
			want = to.normalized() * minf(FLY_SPEED.y, 1.0 + to.length() * 1.5)
		Mode.FLEE:
			want = _flee[i] * FLEE_SPEED
			if _timer[i] <= 0.0:   # danach kreisen – am Tag nur eine Weile, dann heim
				_mode[i] = Mode.FLY
				_timer[i] = 0.0 if _night else randf_range(SETTLE_PAUSE.x, SETTLE_PAUSE.y)
	_jitter_t[i] -= delta
	if _jitter_t[i] <= 0.0:
		_jitter_t[i] = randf_range(JITTER_EVERY.x, JITTER_EVERY.y)
		_jitter[i] = Vector3(randf_range(-1, 1), randf_range(-0.6, 0.6), randf_range(-1, 1)) * JITTER * (ATTIC_JITTER if attic else 1.0)
	if mode != Mode.HOME:
		want += _jitter[i]
	var p := _pos[i]
	# draußen bleiben: unterhalb der Dächer nicht über das Haus, sondern hinauf und zurück zur Bahn
	if not attic and p.y < ROOF_CLEAR and not _outdoor(p + _vel[i] * 0.4):
		var back := _center[i] - p
		back.y = 0.0
		want = back.normalized() * FLY_SPEED.y + Vector3.UP * 3.0
	_vel[i] = _vel[i].move_toward(want, ACCEL * delta)
	p += _vel[i] * delta
	if attic:   # in der Kammer bleiben: unter den Balken, nicht weiter vom Pfosten als die Bahn
		var c := _center[i]
		var flat := Vector2(p.x - c.x, p.z - c.z).limit_length(_radius[i] + 0.3)
		p = Vector3(c.x + flat.x, clampf(p.y, c.y + 0.5, c.y + LevelBuilder.ATTIC_BEAM_BOTTOM), c.z + flat.y)
	else:
		p.y = clampf(p.y, MIN_Y if mode != Mode.HOME else 0.0, MAX_Y)
	_pos[i] = p
	_phase[i] = fmod(_phase[i] + TAU * FLAP_RATE * delta, TAU)


func _draw(i: int) -> void:
	var b: Basis
	var fold := 0.0
	if _mode[i] == Mode.OUT:   # ausgeflogen
		_mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), _roost[i]))
		return
	if _mode[i] == Mode.ROOST:   # kopfüber, Flügel angelegt
		b = Basis(Vector3.UP, _yaw[i]) * Basis(Vector3.RIGHT, -PI / 2.0)
		fold = 1.0
	else:
		var v := _vel[i]
		if v.length() < 0.05:
			v = Vector3.FORWARD
		var dir := v.normalized()
		b = Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.95 else Vector3.BACK)
	var at := _pos[i] - (Vector3(0, ROOST_DROP, 0) if _mode[i] == Mode.ROOST else Vector3.ZERO)
	_mm.set_instance_transform(i, Transform3D(b.scaled(Vector3.ONE * SCALE), at))
	_mm.set_instance_custom_data(i, Color(_phase[i], fold, 0, 0))


# --- Scheu und Warnung --------------------------------------------------------------------------

## Viermal je Sekunde: Bedrohungen in der Nähe scheuchen auf (Schlafbaum) bzw. davon (im Flug); der Spieler scheucht
## Hängende nach seiner Auffälligkeit auf, Fliegende weichen ihm nur kurz aus.
func _look_around() -> void:
	var threats: Array[Vector3] = []
	if Game.monster and Game.monster.is_active():
		threats.append(Game.monster.global_position)
	if Game.pumpkin and Game.pumpkin.in_house():
		threats.append(Game.pumpkin.global_position)
	if Game.ghost and Game.ghost.is_active() and Game.ghost.visible:
		threats.append(Game.ghost.global_position)
	for t in _trees.size():
		var base: Vector3 = _trees[t]["pos"]
		for p in threats:
			if _flat(p, base) < THREAT_RANGE and absf(p.y - base.y) < 6.0:
				_flush(t, p, false)
	for k in _posts.size():
		for p in threats:
			if p.distance_to(_roost_center(_trees.size() + k)) < ATTIC_THREAT:
				_flush(_trees.size() + k, p, false)
	for i in COUNT:   # die vom Dachboden flattern nur in ihrer Kammer
		if _mode[i] == Mode.FLEE:
			continue
		for p in threats:
			if p.distance_to(_pos[i]) < THREAT_RANGE:
				_flee_from(i, p)
	var player := Game.player
	if player == null or player.dead:
		return
	var eye := player.camera.global_position
	var reach := ROOST_DISTURB * Senses.conspicuity(player, 0.0)
	if _player_in_attic():
		reach *= ATTIC_DISTURB / ROOST_DISTURB
		for k in _posts.size():
			var t := _trees.size() + k
			for i in range(COUNT, _n):
				if _tree[i] == t and _mode[i] == Mode.ROOST and eye.distance_to(_roost[i]) < reach:
					_flush(t, eye, true)
					break
		return
	if not _outdoor(player.global_position) or absf(player.global_position.y) > 2.0:
		return
	for t in _trees.size():
		for i in COUNT:
			if _tree[i] == t and _mode[i] == Mode.ROOST and eye.distance_to(_roost[i]) < reach:
				_flush(t, eye, true)
				break
	for i in COUNT:
		if _mode[i] in [Mode.FLY, Mode.HOME] and eye.distance_to(_pos[i]) < SHY_RANGE:
			_flee_from(i, eye, SHY_TIME)


## Alle, die an Baum t hängen, fliegen auf – weg von `from`. Ein Schwarm flattert hörbar (Lärm, je Baum gedrosselt).
func _flush(t: int, from: Vector3, loud: bool) -> void:
	var any := false
	for i in _n:
		if _tree[i] == t and _mode[i] == Mode.ROOST:
			if _is_attic(i):
				_flutter(i)
			else:
				_flee_from(i, from)
			any = true
	if not any or t < 0:
		return
	var now := Game.director.elapsed if Game.director else 0.0
	if now - float(_noise_at.get(t, -INF)) < NOISE_PAUSE:
		return
	_noise_at[t] = now
	var crown := _roost_center(t)
	if Game.tracing:
		var where := "Baum %d" % t if t < _trees.size() else "Dachboden, Pfosten %d" % (t - _trees.size())
		print("[Fledermäuse] Schwarm fliegt auf (%s, %s)" % [where, "Spieler" if loud else "Bedrohung"])
	Game.noise("bats", crown, self)


func _flee_from(i: int, from: Vector3, time: float = -1.0) -> void:
	var away := _pos[i] - from
	away.y = 0.0
	if away.length() < 0.1:
		away = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
	away = away.normalized().rotated(Vector3.UP, randf_range(-0.6, 0.6))
	_flee[i] = (away + Vector3.UP * FLEE_UP * randf_range(0.6, 1.2)).normalized()
	_mode[i] = Mode.FLEE
	_timer[i] = time if time > 0.0 else randf_range(FLEE_TIME.x, FLEE_TIME.y)
	if _vel[i].length() < 1.0:
		_vel[i] = _flee[i] * 2.0   # vom Ast weg


## Dachboden: vom Balken herunter und eine Weile um den Pfosten flattern, dann wieder hinauf (HOME).
func _flutter(i: int) -> void:
	_mode[i] = Mode.FLY
	_timer[i] = randf_range(SETTLE_PAUSE.x, SETTLE_PAUSE.y)
	_angle[i] = atan2(_pos[i].z - _center[i].z, _pos[i].x - _center[i].x)
	_vel[i] = Vector3(randf_range(-1, 1), -1.5, randf_range(-1, 1))


## Laute Geräusche wecken sie (Game.noise): Hängt in Hörweite ein Schwarm, fliegt er auf.
func on_noise(pos: Vector3, loudness: float, source: Node) -> void:
	if source == self or _mm == null:
		return
	for t in _trees.size() + _posts.size():
		if _roost_center(t).distance_to(pos) < loudness * 0.6:
			_flush(t, pos, false)


## Mitte eines Schlafplatzes: unterer Rand der Krone bzw. Balkenkreuz über dem Pfosten.
func _roost_center(t: int) -> Vector3:
	if t >= _trees.size():
		return (_posts[t - _trees.size()]["pos"] as Vector3) + Vector3.UP * LevelBuilder.ATTIC_BEAM_BOTTOM
	var tree: Dictionary = _trees[t]
	var crown: Vector2 = tree["crown"]
	return (tree["pos"] as Vector3) + Vector3.UP * float(tree["height"]) * crown.x


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


# --- Debug ------------------------------------------------------------------------------------------

## Debug (--fledermaus[=tag|schwarm]): Der Spieler steht im Garten DEBUG_STAND vor dem ersten Baum und sieht hinauf
## (nachts in den Himmel über der Krone, tags auf ihren unteren Rand). Ohne Wert ist es 21 Uhr (sie kreisen), tag:
## 12 Uhr (sie hängen), schwarm: 12 Uhr, nach 3 s fliegen sie auf – wie von der anderen Seite des Baums aufgeschreckt,
## über dich hinweg. dachboden: 12 Uhr, du stehst auf dem Dachboden neben einem Pfosten mit Kolonie und siehst zum
## Balkenkreuz hinauf (Taschenlampe an oder rennen scheucht sie auf).
func debug_show(what: String) -> void:
	if what == "dachboden":
		_debug_attic()
		return
	if _trees.is_empty():
		Game.say("Fledermäuse: Draußen steht kein Baum.", 2.5)
		return
	var day := Calendar.day_of(Game.director.elapsed)
	Game.director.elapsed = maxf(Game.director.elapsed, Calendar.at(day, 21.0 if what == "" else 12.0))
	if what != "" and Calendar.hour_of(Game.director.elapsed) >= 18.0:
		Game.director.elapsed = Calendar.at(day + 1, 12.0)
	_night = _active_time()
	for i in COUNT:
		_mode[i] = Mode.FLY if _night else Mode.ROOST
		_pos[i] = _orbit_point(i) if _night else _roost[i]
		_vel[i] = Vector3.ZERO
		_timer[i] = 0.0
	var tree: Dictionary = _trees[0]
	var base: Vector3 = tree["pos"]
	var stand := base
	for k in 16:   # ein Platz draußen in DEBUG_STAND Abstand
		var a := TAU * k / 16.0
		var p := base + Vector3(cos(a) * DEBUG_STAND, 0, sin(a) * DEBUG_STAND)
		if _outdoor(p) and _builder.is_outdoor(p + Vector3(0, 0.1, 0)):
			stand = p
			break
	var player := Game.player
	player.global_position = stand + Vector3(0, 0.05, 0)
	var look := _roost_center(0) + Vector3.UP * (3.0 if _night else 0.0) - player.camera.global_position
	player.rotation.y = atan2(-look.x, -look.z)
	player.head.rotation.x = clampf(atan2(look.y, Vector2(look.x, look.z).length()), -1.2, 1.2)
	if what == "schwarm":
		_debug_flush = 3.0


func _debug_attic() -> void:
	if _posts.is_empty():
		Game.say("Fledermäuse: Auf dem Dachboden steht kein Pfosten.", 2.5)
		return
	var day := Calendar.day_of(Game.director.elapsed)
	Game.director.elapsed = maxf(Game.director.elapsed, Calendar.at(day, 12.0))
	if Calendar.hour_of(Game.director.elapsed) >= 18.0:
		Game.director.elapsed = Calendar.at(day + 1, 12.0)
	_night = _active_time()
	for i in range(COUNT, _n):
		_mode[i] = Mode.ROOST
		_pos[i] = _roost[i]
		_vel[i] = Vector3.ZERO
		_timer[i] = 0.0
	# schräg zwischen zwei Armen, außer Reichweite, Blick zurück zum Balkenkreuz
	var post: Dictionary = _posts[0]
	var base: Vector3 = post["pos"]
	var arms: Array = post["arms"]
	var dir := Vector3(1, 0, 1)
	for a: Array in arms:
		for b: Array in arms:
			if absf((a[0] as Vector3).dot(b[0])) < 0.1 and minf(float(a[1]), float(b[1])) > 1.8:
				dir = (a[0] as Vector3) + (b[0] as Vector3)
	var stand := base + dir.normalized() * 2.6
	TeleportUI.place_player(stand, base - stand)
	var player := Game.player
	var look := _roost_center(_trees.size()) - player.camera.global_position
	player.head.rotation.x = clampf(atan2(look.y, Vector2(look.x, look.z).length()), -1.2, 1.2)
