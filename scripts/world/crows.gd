class_name Crows
extends Node3D
## Krähen im Garten (Spielkonzept 4.25): Sie hüpfen auf dem Rasen unter den Bäumen und picken, auch nachts – draußen ist
## immer Nacht (2.1), und diese Krähen schlafen nicht. Sie sind scheu wie die Fledermäuse: Wer ihnen zu nah kommt (mit
## Licht oder rennend schon von weiter weg, Senses.conspicuity), scheucht sie krächzend in die Kronen; Bedrohungen in der
## Nähe ebenso. Ein aufgescheuchter Trupp ist Lärm (4.15).
## Sie merken sich Gesichter: Trifft etwas, das der Spieler geworfen hat (3.13), neben ihnen auf, oder rennt er in sie
## hinein, steigt ihr Groll (`grudge`). Mit Groll krächzen sie ihn an, sobald er draußen in ihre Nähe kommt – das ist
## Lärm, das Monster hört ihn. Der Groll klingt über Tage ab (gespeichert unter „omens“).
## Glänzendes nehmen sie mit: Münzen, die draußen liegen, holt eine Krähe, wenn niemand hinsieht.
## Ein MultiMesh (shaders/psx_bird.gdshader), Flug, Hüpfen und Flügelschlag rechnet das Skript – in der Pause steht alles.
## Sonst nicht gespeichert: Nach dem Laden sitzen sie wieder auf dem Rasen.

enum Mode { GROUND, FLY, PERCH, LAND }

const COUNT := 11
const SCALE := 1.0
const GROUND_SPREAD := Vector2(2.5, 9.0)   ## Futterplätze so weit vom Stamm (Rasen)
const HOP_EVERY := Vector2(0.8, 3.5)       ## so oft hüpft eine Krähe ein Stück …
const HOP_LENGTH := Vector2(0.15, 0.45)    ## … so weit …
const HOP_TIME := 0.22                     ## … in dieser Zeit
const HOP_HEIGHT := 0.08
const WANDER := 2.0                        ## so weit vom eigenen Futterplatz hüpft sie höchstens
const PECK_RATE := 5.5                     ## Picken (rad/s im Kopfnicken)
const FLY_SPEED := 6.5
const ACCEL := 14.0
const FLAP_RATE := 5.0                     ## Flügelschläge je Sekunde
const PERCH_HEIGHT := Vector2(0.55, 0.85)  ## Sitzplatz in der Krone (Anteil der Baumhöhe)
const PERCH_TIME := Vector2(25.0, 70.0)    ## so lange bleibt sie oben, bevor sie wieder landet
## Scheu: so nah × Auffälligkeit des Spielers scheucht er sie auf, Bedrohungen schon ab THREAT_RANGE
const SHY_RANGE := 3.8
const THREAT_RANGE := 14.0
const FLOCK_RANGE := 3.5                   ## wer so nah bei einer Aufgescheuchten sitzt, fliegt mit
const CHECK_EVERY := 0.25
const NOISE_PAUSE := 5.0                   ## so oft höchstens Lärm vom Trupp
## Groll: ein Wurf, der so nah bei einer Krähe aufschlägt, so viel dazu; rennend aufgescheucht so viel
const GRUDGE_HIT_RANGE := 3.0
const GRUDGE_HIT := 0.35
const GRUDGE_RAM := 0.12
const GRUDGE_MIN := 0.25                   ## ab hier krächzen sie den Spieler an
const GRUDGE_DECAY := 0.3                  ## so viel weniger je Spieltag
## Mit Groll: so weit sehen sie ihn (draußen), so oft krächzt eine (bei vollem Groll; weniger Groll seltener)
const WATCH_RANGE := 22.0
const CAW_EVERY := 6.0
const COIN_RANGE := 7.0                    ## so nah muss eine Münze bei einer Krähe am Boden liegen
const COIN_CHECK := 5.0

var grudge := 0.0
var _builder: LevelBuilder
var _trees: Array[Dictionary] = []
var _mm: MultiMesh
var _pos := PackedVector3Array()
var _vel := PackedVector3Array()
var _yaw := PackedFloat32Array()
var _mode := PackedInt32Array()
var _home := PackedVector3Array()          ## Futterplatz am Boden
var _perch := PackedVector3Array()         ## Sitzplatz in der Krone
var _goal := PackedVector3Array()          ## LAND: wohin
var _timer := PackedFloat32Array()         ## GROUND: bis zum nächsten Hüpfer · PERCH: bis zur Landung
var _hop_from := PackedVector3Array()
var _hop_to := PackedVector3Array()
var _hop_t := PackedFloat32Array()         ## < 0: hüpft gerade nicht
var _flap := PackedFloat32Array()
var _peck := PackedFloat32Array()
var _carry: Array = []                     ## je Krähe: Münze, die sie holen will (Item) oder null
var _out_cache := {}
var _check := 0.0
var _coin_check := COIN_CHECK
var _caw_timer := 0.0
var _last_noise := -INF
var _warned := false                       ## Meldung „sie haben sich dich gemerkt“ schon gezeigt


func setup(builder: LevelBuilder) -> void:
	_builder = builder
	add_to_group("time_skip")
	for t: Dictionary in builder.tree_spots:
		if _outdoor(t["pos"]) and absf((t["pos"] as Vector3).y) < 1.0:
			_trees.append(t)
	if _trees.is_empty():
		return
	_build_mesh()
	for i in COUNT:
		_spawn(i)


## Zeitsprung im Schlaf (SleepSkip, Spielkonzept 3.6): der Groll klingt auch im Schlaf ab.
func skip_time(dt: float) -> void:
	grudge = maxf(0.0, grudge - GRUDGE_DECAY * dt / Calendar.DAY_SECONDS)


func save_state() -> Dictionary:
	return {"grudge": grudge}


func load_state(d: Dictionary) -> void:
	grudge = float(d.get("grudge", 0.0))


func _spawn(i: int) -> void:
	var tree: Dictionary = _trees[i % _trees.size()]
	var base: Vector3 = tree["pos"]
	var home := base
	for k in 12:   # ein Platz auf dem Rasen
		var a := randf() * TAU
		var p := base + Vector3(cos(a), 0, sin(a)) * randf_range(GROUND_SPREAD.x, GROUND_SPREAD.y)
		if _builder.is_lawn(Vector2(p.x, p.z)):
			home = p
			break
	home.y = base.y
	var a2 := randf() * TAU
	var h: float = tree["height"]
	var r: float = tree["radius"]
	_home.append(home)
	_perch.append(base + Vector3(cos(a2) * r * 0.45, h * randf_range(PERCH_HEIGHT.x, PERCH_HEIGHT.y), sin(a2) * r * 0.45))
	_pos.append(home)
	_vel.append(Vector3.ZERO)
	_yaw.append(randf() * TAU)
	_mode.append(Mode.GROUND)
	_goal.append(home)
	_timer.append(randf_range(HOP_EVERY.x, HOP_EVERY.y))
	_hop_from.append(home)
	_hop_to.append(home)
	_hop_t.append(-1.0)
	_flap.append(randf() * TAU)
	_peck.append(randf() * TAU)
	_carry.append(null)


func _outdoor(p: Vector3) -> bool:
	var cell := Vector2i(floori(p.x), floori(p.z))
	if not _out_cache.has(cell):
		_out_cache[cell] = _builder.is_outdoor(Vector3(cell.x + 0.5, 0.1, cell.y + 0.5))
	return _out_cache[cell]


## Eine Krähe aus wenigen Flächen, vorn ist −Z, etwa 45 cm lang, Spannweite knapp 90 cm. Eckfarbe r = Kopf (nickt),
## g = Glanz.
func _build_mesh() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body: Array[Vector3] = [Vector3(0, 0.12, -0.12), Vector3(0.055, 0.1, -0.02), Vector3(0, 0.155, 0.0),
		Vector3(-0.055, 0.1, -0.02), Vector3(0, 0.06, -0.02), Vector3(0, 0.11, 0.12)]
	_octa(st, body, Color(0, 1, 0))
	var head: Array[Vector3] = [Vector3(0, 0.16, -0.2), Vector3(0.03, 0.16, -0.15), Vector3(0, 0.19, -0.14),
		Vector3(-0.03, 0.16, -0.15), Vector3(0, 0.135, -0.14), Vector3(0, 0.155, -0.1)]
	_octa(st, head, Color(1, 1, 0))
	# Schnabel: kräftig, nach vorn spitz
	var beak: Array[Vector3] = [Vector3(0, 0.155, -0.26), Vector3(0.012, 0.16, -0.195), Vector3(0, 0.172, -0.195),
		Vector3(-0.012, 0.16, -0.195), Vector3(0, 0.148, -0.195), Vector3(0, 0.16, -0.19)]
	_octa(st, beak, Color(1, 0.4, 0))
	# Schwanz: flacher Fächer nach hinten
	for v: Vector3 in [Vector3(0, 0.11, 0.1), Vector3(0.04, 0.1, 0.24), Vector3(-0.04, 0.1, 0.24)]:
		st.set_color(Color(0, 1, 0))
		st.set_normal(Vector3.UP)
		st.add_vertex(v)
	# Beine: zwei dünne Keile bis zum Boden
	for side in [0.025, -0.025]:
		for v: Vector3 in [Vector3(side, 0.07, -0.02), Vector3(side + 0.006, 0.0, -0.03), Vector3(side - 0.006, 0.0, -0.01)]:
			st.set_color(Color(0, 0, 0))
			st.set_normal(Vector3.BACK)
			st.add_vertex(v)
	# Flügel: gefingerte Hand am Ende, angelegt liegen sie flach auf dem Rücken
	for side in [1.0, -1.0]:
		var w: Array[Vector3] = [Vector3(0.03, 0.13, -0.07), Vector3(0.2, 0.135, -0.06), Vector3(0.44, 0.13, -0.02),
			Vector3(0.42, 0.13, 0.04), Vector3(0.34, 0.13, 0.05), Vector3(0.26, 0.13, 0.08), Vector3(0.03, 0.13, 0.06)]
		for tri in [[0, 1, 6], [1, 5, 6], [1, 2, 3], [1, 3, 4], [1, 4, 5]]:
			for k in tri:
				st.set_color(Color(0, 0.6, 0))
				st.set_normal(Vector3.UP)
				st.add_vertex(Vector3(w[k].x * side, w[k].y, w[k].z))
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/psx_bird.gdshader")
	mat.set_shader_parameter("neck_z", -0.12)
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_custom_data = true
	_mm.mesh = st.commit()
	_mm.instance_count = COUNT
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(Vector3(-500, -50, -500), Vector3(1000, 200, 1000))
	add_child(mmi)


## Doppelpyramide aus sechs Punkten (vorn, rechts, oben, links, unten, hinten).
func _octa(st: SurfaceTool, v: Array[Vector3], color: Color) -> void:
	var center := Vector3.ZERO
	for p in v:
		center += p / v.size()
	for tri in [[0, 1, 2], [0, 2, 3], [0, 3, 4], [0, 4, 1], [5, 2, 1], [5, 3, 2], [5, 4, 3], [5, 1, 4]]:
		for k in tri:
			st.set_color(color)
			st.set_normal((v[k] - center).normalized())
			st.add_vertex(v[k])


func _physics_process(delta: float) -> void:
	if _mm == null:
		return
	grudge = maxf(0.0, grudge - GRUDGE_DECAY * delta / Calendar.DAY_SECONDS)
	_check -= delta
	if _check <= 0.0:
		_check = CHECK_EVERY
		_look_around()
	_coin_check -= delta
	if _coin_check <= 0.0:
		_coin_check = COIN_CHECK
		_look_for_coins()
	_update_cawing(delta)
	for i in COUNT:
		_step(i, delta)
		_draw(i)


func _step(i: int, delta: float) -> void:
	_timer[i] -= delta
	match _mode[i]:
		Mode.GROUND:
			_peck[i] += delta * PECK_RATE * (0.4 + 0.6 * absf(sin(_peck[i] * 0.13)))
			if _hop_t[i] >= 0.0:
				_hop_t[i] += delta / HOP_TIME
				var k := minf(1.0, _hop_t[i])
				_pos[i] = _hop_from[i].lerp(_hop_to[i], k) + Vector3.UP * sin(PI * k) * HOP_HEIGHT
				if k >= 1.0:
					_hop_t[i] = -1.0
			elif _timer[i] <= 0.0:
				_timer[i] = randf_range(HOP_EVERY.x, HOP_EVERY.y)
				_hop(i)
		Mode.PERCH:
			if _timer[i] <= 0.0:
				_mode[i] = Mode.LAND
				_goal[i] = _home[i]
		Mode.FLY, Mode.LAND:
			var goal := _perch[i] if _mode[i] == Mode.FLY else _goal[i]
			var to := goal - _pos[i]
			if to.length() < 0.2:
				_arrive(i)
				return
			var want := to.normalized() * minf(FLY_SPEED, 1.5 + to.length() * 2.0)
			# aufsteigen statt flach in Hecken und Wände: unter der Krone erst nach oben
			if _mode[i] == Mode.FLY and _pos[i].y < goal.y - 1.0:
				want.y = maxf(want.y, 2.5)
			_vel[i] = _vel[i].move_toward(want, ACCEL * delta)
			_pos[i] += _vel[i] * delta
			if _vel[i].length() > 0.3:
				_yaw[i] = atan2(-_vel[i].x, -_vel[i].z)
			_flap[i] = fmod(_flap[i] + TAU * FLAP_RATE * delta, TAU)


func _arrive(i: int) -> void:
	_vel[i] = Vector3.ZERO
	if _mode[i] == Mode.FLY:
		_mode[i] = Mode.PERCH
		_pos[i] = _perch[i]
		_timer[i] = randf_range(PERCH_TIME.x, PERCH_TIME.y)
		var coin: Item = _carry[i] if is_instance_valid(_carry[i]) else null
		if coin:   # die Münze verschwindet im Nest
			coin.queue_free()
		_carry[i] = null
		return
	_pos[i] = _goal[i]
	var coin: Item = _carry[i] if is_instance_valid(_carry[i]) else null
	if coin and not coin.is_held and coin.global_position.distance_to(_pos[i]) < 0.6 \
			and not _seen(coin.global_position):
		coin.visible = false   # im Schnabel – sie fliegt damit in die Krone
		coin.set_meta("interactable", null)
		_mode[i] = Mode.FLY
		return
	_carry[i] = null
	_mode[i] = Mode.GROUND
	_timer[i] = randf_range(HOP_EVERY.x, HOP_EVERY.y)


## Ein Hüpfer in eine neue Richtung, nicht weiter als WANDER vom Futterplatz.
func _hop(i: int) -> void:
	var a := _yaw[i] + randf_range(-1.4, 1.4)
	var to := _pos[i] + Vector3(-sin(a), 0, -cos(a)) * randf_range(HOP_LENGTH.x, HOP_LENGTH.y)
	if Vector2(to.x - _home[i].x, to.z - _home[i].z).length() > WANDER:
		var back := _home[i] - _pos[i]
		a = atan2(-back.x, -back.z)
		to = _pos[i] + Vector3(-sin(a), 0, -cos(a)) * HOP_LENGTH.y
	to.y = _home[i].y
	_yaw[i] = a
	_hop_from[i] = _pos[i]
	_hop_to[i] = to
	_hop_t[i] = 0.0


func _draw(i: int) -> void:
	var fold := 1.0 if _mode[i] in [Mode.GROUND, Mode.PERCH] else 0.0
	var b := Basis(Vector3.UP, _yaw[i])
	if fold < 0.5 and _vel[i].length() > 0.5:
		var dir := _vel[i].normalized()
		b = Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.95 else Vector3.BACK)
	var nod := 0.0
	if _mode[i] == Mode.GROUND and _hop_t[i] < 0.0:
		nod = maxf(0.0, sin(_peck[i])) * (1.0 if sin(_peck[i] * 0.31) > 0.0 else 0.15)
	_mm.set_instance_transform(i, Transform3D(b.scaled(Vector3.ONE * SCALE), _pos[i]))
	_mm.set_instance_custom_data(i, Color(_flap[i], fold, nod, 0))


# --- Scheu, Groll, Münzen ---------------------------------------------------------------------

func _look_around() -> void:
	var threats: Array[Vector3] = []
	if Game.monster and Game.monster.is_active():
		threats.append(Game.monster.global_position)
	if Game.pumpkin and Game.pumpkin.in_house():
		threats.append(Game.pumpkin.global_position)
	if Game.ghost and Game.ghost.is_active() and Game.ghost.visible:
		threats.append(Game.ghost.global_position)
	for i in COUNT:
		if _mode[i] in [Mode.FLY, Mode.PERCH]:
			continue
		for p in threats:
			if p.distance_to(_pos[i]) < THREAT_RANGE:
				_flush(i, false)
				break
	var player := Game.player
	if player == null or player.dead or absf(player.global_position.y) > 2.0 or not _outdoor(player.global_position):
		return
	var feet := player.global_position
	var reach := SHY_RANGE * Senses.conspicuity(player, 0.0)
	for i in COUNT:
		if _mode[i] in [Mode.GROUND, Mode.LAND] and feet.distance_to(_pos[i]) < reach:
			if player.running:
				grudge = minf(1.0, grudge + GRUDGE_RAM)
			_flush(i, true)


## Krähe i und ihre Nachbarn fliegen krächzend in die Kronen. Lärm höchstens alle NOISE_PAUSE Sekunden.
func _flush(i: int, by_player: bool) -> void:
	var center := _pos[i]
	for k in COUNT:
		if _mode[k] in [Mode.GROUND, Mode.LAND] and _pos[k].distance_to(center) < FLOCK_RANGE:
			_mode[k] = Mode.FLY
			_vel[k] = Vector3.UP * 2.5
			var coin: Item = _carry[k] if is_instance_valid(_carry[k]) else null
			if coin and not coin.visible:   # Schreck: die Münze fällt herunter
				coin.visible = true
				coin.set_meta("interactable", coin)
			_carry[k] = null
	var now := Game.director.elapsed if Game.director else 0.0
	if now - _last_noise < NOISE_PAUSE:
		return
	_last_noise = now
	if Game.tracing:
		print("[Krähen] fliegen auf (%s)" % ("Spieler" if by_player else "Bedrohung"))
	Game.noise("crows", center + Vector3.UP * 0.5, self)


## Lärm in der Welt (Game.noise): Schlägt etwas, das der Spieler geworfen hat, neben ihnen auf, merken sie es sich.
## Laute Geräusche scheuchen sie auf.
func on_noise(pos: Vector3, loudness: float, source: Node) -> void:
	if _mm == null or source == self:
		return
	var thrown := source as Item
	for i in COUNT:
		if _mode[i] == Mode.PERCH:
			continue
		var d := _pos[i].distance_to(pos)
		if thrown and thrown.thrower == Game.player and d < GRUDGE_HIT_RANGE:
			grudge = minf(1.0, grudge + GRUDGE_HIT)
			if Game.tracing:
				print("[Krähen] Groll %.2f – ein Wurf schlug neben ihnen auf" % grudge)
			_flush(i, true)
			return
		if d < loudness * 0.5 and loudness >= Senses.LOUD:
			_flush(i, false)
			return


## Mit Groll: Ist der Spieler draußen in ihrer Nähe, krächzt die nächste Krähe ihn an (Lärm – das Monster hört es).
func _update_cawing(delta: float) -> void:
	_caw_timer -= delta
	if grudge < GRUDGE_MIN or _caw_timer > 0.0:
		return
	var player := Game.player
	if player == null or player.dead or player.hiding or not _outdoor(player.global_position):
		return
	var best := -1
	for i in COUNT:
		if _pos[i].distance_to(player.global_position) < WATCH_RANGE \
				and (best < 0 or _pos[i].distance_to(player.global_position) < _pos[best].distance_to(player.global_position)):
			best = i
	if best < 0:
		return
	_caw_timer = CAW_EVERY / grudge * randf_range(0.7, 1.3)
	var to := player.global_position - _pos[best]
	if _mode[best] in [Mode.GROUND, Mode.PERCH]:
		_yaw[best] = atan2(-to.x, -to.z)
	Game.noise("crow", _pos[best] + Vector3.UP * 0.2, self)
	if not _warned:
		_warned = true
		Game.say("Die Krähen krächzen dich an. Sie haben sich dein Gesicht gemerkt.", 4.0)
		if Game.notebook:
			Game.notebook.add_note("crows", "Seit ich nach ihnen geworfen habe, krächzen mich die Krähen im Garten an. Das hört man weit.", "Garten")


## Münzen, die draußen liegen: die nächste Krähe am Boden holt sie, wenn niemand hinsieht.
func _look_for_coins() -> void:
	for node in get_tree().get_nodes_in_group("items"):
		var coin := node as Item
		if coin.kind != Item.Kind.COINS or coin.is_held or not coin.visible or not _outdoor(coin.global_position) \
				or _carry.has(coin):
			continue
		var best := -1
		for i in COUNT:
			if _mode[i] == Mode.GROUND and _carry[i] == null and _pos[i].distance_to(coin.global_position) < COIN_RANGE \
					and (best < 0 or _pos[i].distance_to(coin.global_position) < _pos[best].distance_to(coin.global_position)):
				best = i
		if best >= 0 and not _seen(coin.global_position):
			_carry[best] = coin
			_mode[best] = Mode.LAND
			_goal[best] = coin.global_position
			_vel[best] = Vector3.UP * 1.5
			return


func _seen(p: Vector3) -> bool:
	return Game.director != null and Game.player != null and Game.director.player_can_see(p)


# --- Debug ------------------------------------------------------------------------------------------

## Debug (--kraehen[=groll]): du stehst im Garten 7 m vor den Krähen des ersten Baums und siehst sie an · groll: sie
## haben sich dich gemerkt (voller Groll), gleich krächzt eine.
func debug_show(what: String) -> void:
	if _mm == null:
		Game.say("Krähen: Draußen steht kein Baum.", 2.5)
		return
	var c := _home[0]
	var player := Game.player
	var stand := c + Vector3(7.0, 0, 0)
	for k in 12:
		var a := TAU * k / 12.0
		var p := c + Vector3(cos(a), 0, sin(a)) * 7.0
		if _outdoor(p):
			stand = p
			break
	player.global_position = stand + Vector3(0, 0.05, 0)
	var look := c - player.camera.global_position
	player.rotation.y = atan2(-look.x, -look.z)
	player.head.rotation.x = clampf(atan2(look.y, Vector2(look.x, look.z).length()), -1.2, 1.2)
	if what == "groll":
		grudge = 1.0
		_caw_timer = 1.5
