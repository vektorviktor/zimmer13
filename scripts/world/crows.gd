class_name Crows
extends Node3D
## Krähen im Garten (Spielkonzept 4.25): Sie hüpfen auf dem Rasen unter den Bäumen und picken, auch nachts – draußen ist
## immer Nacht (2.1), und diese Krähen schlafen nicht. Sie sind scheu wie die Fledermäuse: Wer ihnen zu nah kommt (mit
## Licht oder rennend schon von weiter weg, Senses.conspicuity), scheucht sie krächzend in die Kronen; Bedrohungen in der
## Nähe ebenso. Ein aufgescheuchter Trupp ist Lärm (4.15).
## Ruf beim Trupp (`favor`, Erweiterung 4.25): ein Wert für alle Krähen von Groll (−1) bis Gunst (+1). Trifft etwas, das
## der Spieler geworfen hat, neben ihnen auf, oder rennt er in sie hinein, sinkt er; Füttern hebt ihn; er klingt über Tage
## zur Mitte ab. Mit Groll krächzen sie ihn an, sobald er draußen in ihre Nähe kommt – das ist Lärm, das Monster hört ihn.
## Glänzendes (SHINY), das draußen liegt, holt eine Krähe, wenn niemand hinsieht, und trägt es ins Nest im großen Baum
## gegenüber der Terrassentür von Zimmer 042; erschreckt man sie im Flug, fällt es herunter. Im Nest liegt von Anfang an
## der Messingschlüssel von 1987 (OLD_KEY, 6.19 (7)). Zwei Wege an den Inhalt: hineinwerfen (ein Stück fällt, laut, der
## Ruf fällt stark) oder füttern – Futter (Kürbiskerne, Brotkrumen) auf dem Futtertisch im Gärtchen von Zimmer 13
## (LevelBuilder.feed_table) ist nach FOOD_HOURS unbeobachtet weg, bei Gunst liegt dann ein Geschenk da.
## Verbotene Masken (5.19, leichte Wirkung): unter der Vogelscheuchen-Maske stehlen sie nicht und krächzen niemanden
## an (scarecrow_masked); wer das Futter mit der Krähenmaske hinlegt oder dabei am Tisch steht, dem zählt es doppelt.
## Ein MultiMesh (shaders/psx_bird.gdshader), Flug, Hüpfen und Flügelschlag rechnet das Skript – in der Pause steht alles.
## Gespeichert unter „omens“: Ruf, Nest, Fütterungen, wie lange das Futter schon liegt. Die Vögel selbst nicht: Nach dem
## Laden sitzen sie wieder auf dem Rasen.

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
## Ruf: ein Wurf, der so nah bei einer Krähe aufschlägt, so viel Richtung Groll; rennend aufgescheucht so viel; ein Wurf
## ins Nest so viel
const GRUDGE_HIT_RANGE := 3.0
const GRUDGE_HIT := 0.35
const GRUDGE_RAM := 0.12
const GRUDGE_NEST := 0.6
const GRUDGE_MIN := 0.25                   ## ab so viel Groll krächzen sie den Spieler an
const FAVOR_DECAY := 0.2                   ## so viel näher zur Mitte je Spieltag
## Füttern: die erste Mahlzeit eines Tages hebt den Ruf so viel, jede weitere am selben Tag so viel
const FAVOR_FEED := 0.35
const FAVOR_FEED_MORE := 0.1
## Geschenke (Spielkonzept 4.25, Entscheidung 3.11.): ab dieser Gunst liegt statt des Futters ein Geschenk da; der
## Schlüssel von 1987 erst ab KEY_FAVOR und nach Fütterungen an KEY_DAYS verschiedenen Tagen
const GIFT_FAVOR := 0.4
const KEY_FAVOR := 0.6
const KEY_DAYS := 3
const COIN_GIFT := Vector2i(1, 3)          ## Münzen als Geschenk: so viel Geld
## Statt Münzen mit dieser Chance nützliches Kleinzeug aus dem Hotel (kein eigener Gegenstand, ZIM-31)
const USEFUL_CHANCE := 0.35
const USEFUL := [Item.Kind.BATTERY, Item.Kind.MATCHBOX, Item.Kind.CANDLE]
## Mit Groll: so weit sehen sie ihn (draußen), so oft krächzt eine (bei vollem Groll; weniger Groll seltener)
const WATCH_RANGE := 22.0
const CAW_EVERY := 6.0
const SHINY_RANGE := 7.0                   ## so nah muss Glänzendes bei einer Krähe am Boden liegen
const LOOK_EVERY := 5.0                    ## so oft sehen sie nach Glänzendem und Futter
## Was sie stehlen (draußen, unbeobachtet) – der Ring eines Gastes gehört zum Dachnest (ZIM-50)
const SHINY := [Item.Kind.COINS, Item.Kind.KEY, Item.Kind.KNIFE, Item.Kind.COMPASS]
## Das Nest sitzt im großen Baum gegenüber der Terrassentür dieses Zimmers (6.19 (7)) – darin von Anfang an sein Schlüssel
const NEST_ROOM := "042"
const OLD_KEY := "zimmer_042"
const NEST_BELOW_CROWN := 0.25            ## so weit unter dem Ansatz der Krone (Laub) sitzt es …
const NEST_OUT := 0.2                      ## … so weit aus der Stammachse zur Tür von NEST_ROOM hin
const NEST_HIT := 0.9                      ## ein Wurf, der so nah am Nest aufschlägt, trifft es
const CRUISE_Y := 14.0                     ## weite Flüge (zum Nest und zurück) über die Dächer in dieser Höhe
const FAR_FLIGHT := 15.0                   ## ab so viel Abstand (waagerecht) ist ein Flug weit
const FOOD_HOURS := 3.0                    ## so lange liegt Futter auf dem Tisch, bis es (unbeobachtet) weg ist
const MASK_TABLE := 6.0                    ## so nah am Tisch zählt die Krähenmaske beim Futter (5.19)
const GLINT_EVERY := Vector2(0.8, 4.0)     ## so oft blitzt im Nest etwas auf …
const GLINT_TIME := 0.2                    ## … so lange

## Ruf beim Trupp: −1 voller Groll … 0 gleichgültig … +1 volle Gunst
var favor := 0.0
## Inhalt des Nests: {kind, extra} je Stück (wie Item.create), was zuerst hineinkam, liegt vorn
var nest: Array = []
## Fütterungen: an so vielen verschiedenen Tagen, zuletzt an diesem Spieltag
var fed_days := 0
var last_fed_day := -1
## So lange liegt Futter schon auf dem Tisch (s, mit Zeitsprung)
var food_time := 0.0
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
var _carry: Array = []                     ## je Krähe: Glänzendes, das sie holen will bzw. im Schnabel trägt, oder null
var _out_cache := {}
var _check := 0.0
var _look_check := LOOK_EVERY
var _caw_timer := 0.0
var _last_noise := -INF
var _warned := false                       ## Meldung „sie haben sich dich gemerkt“ schon gezeigt
var _nest_pos := Vector3.INF               ## Mitte des Nests (INF = kein Baum dafür)
var _nest_bits: Node3D                     ## Glänzendes oben im Nest – sichtbar, solange etwas darin liegt
var _glint: MeshInstance3D
var _glint_timer := 0.0
var _feed_table := {}                      ## LevelBuilder.feed_table bzw. der Ersatztisch aus dem Debug
var _debug_useful := false                 ## Debug „geschenk“: das nächste Geschenk ist sicher Kleinzeug
var _crow_food := false                    ## das Futter auf dem Tisch kam unter der Krähenmaske (nicht gespeichert)


func setup(builder: LevelBuilder) -> void:
	_builder = builder
	add_to_group("time_skip")
	for t: Dictionary in builder.tree_spots:
		if _outdoor(t["pos"]) and absf((t["pos"] as Vector3).y) < 1.0:
			_trees.append(t)
	_feed_table = builder.feed_table
	nest = _first_nest()
	if _trees.is_empty():
		return
	_build_mesh()
	for i in COUNT:
		_spawn(i)
	_build_nest()


## Zeitsprung im Schlaf (SleepSkip, Spielkonzept 3.6): Der Ruf klingt auch im Schlaf ab, Futter auf dem Tisch ist weg,
## wenn die Zeit reicht – wer schläft, sieht nicht hin.
func skip_time(dt: float) -> void:
	favor = move_toward(favor, 0.0, FAVOR_DECAY * dt / Calendar.DAY_SECONDS)
	var food := _table_food()
	if food.is_empty():
		food_time = 0.0
		return
	food_time += dt
	if food_time >= FOOD_HOURS * Calendar.HOUR:
		_eat(food)


func save_state() -> Dictionary:
	return {"favor": favor, "nest": nest.duplicate(true), "fed_days": fed_days, "last_fed_day": last_fed_day,
		"food_time": food_time}


## Ältere Stände (vor Speicherformat 59) kennen nur den Groll – das Nest ist dann wie am Anfang.
func load_state(d: Dictionary) -> void:
	favor = float(d.get("favor", -float(d.get("grudge", 0.0))))
	nest = (d["nest"] as Array).duplicate(true) if d.has("nest") else _first_nest()
	fed_days = int(d.get("fed_days", 0))
	last_fed_day = int(d.get("last_fed_day", -1))
	food_time = float(d.get("food_time", 0.0))
	_update_nest()


## Groll (0..1) – die andere Seite der Gunst
func grudge() -> float:
	return maxf(0.0, -favor)


func _change_favor(by: float, why: String) -> void:
	favor = clampf(favor + by, -1.0, 1.0)
	if Game.tracing:
		print("[Krähen] Ruf %+.2f (%s)" % [favor, why])


func _first_nest() -> Array:
	return [{"kind": int(Item.Kind.KEY), "extra": OLD_KEY}]


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
	favor = move_toward(favor, 0.0, FAVOR_DECAY * delta / Calendar.DAY_SECONDS)
	_check -= delta
	if _check <= 0.0:
		_check = CHECK_EVERY
		_look_around()
	_look_check -= delta
	if _look_check <= 0.0:
		_look_check = LOOK_EVERY
		_look_for_shiny()
		_check_food(LOOK_EVERY)
	_update_cawing(delta)
	_update_glint(delta)
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
			var goal := _flight_goal(i)
			var to := goal - _pos[i]
			if to.length() < 0.2:
				_arrive(i)
				return
			var flat := Vector2(to.x, to.z).length()
			if flat > FAR_FLIGHT:   # weit: erst über die Dächer, oben bleiben, bis das Ziel nah ist
				to = Vector3(to.x * (0.15 if _pos[i].y < CRUISE_Y - 1.0 else 1.0), CRUISE_Y - _pos[i].y, to.z * (0.15 if _pos[i].y < CRUISE_Y - 1.0 else 1.0))
			var want := to.normalized() * minf(FLY_SPEED, 1.5 + to.length() * 2.0)
			# aufsteigen statt flach in Hecken und Wände: unter der Krone erst nach oben
			if _mode[i] == Mode.FLY and _pos[i].y < goal.y - 1.0:
				want.y = maxf(want.y, 2.5)
			_vel[i] = _vel[i].move_toward(want, ACCEL * delta)
			_pos[i] += _vel[i] * delta
			if _vel[i].length() > 0.3:
				_yaw[i] = atan2(-_vel[i].x, -_vel[i].z)
			_flap[i] = fmod(_flap[i] + TAU * FLAP_RATE * delta, TAU)


## Wohin sie fliegt: mit Glänzendem im Schnabel zum Nest (am Rand), sonst in ihre Krone bzw. zum Landeplatz.
func _flight_goal(i: int) -> Vector3:
	if _mode[i] == Mode.LAND:
		return _goal[i]
	if _carried(i) and _nest_pos != Vector3.INF:
		return _nest_pos + Vector3(0.25, 0.12, 0).rotated(Vector3.UP, i * 1.3)
	return _perch[i]


## Das Glänzende, das Krähe i gerade im Schnabel trägt (null = keins).
func _carried(i: int) -> Item:
	var item: Item = _carry[i] if is_instance_valid(_carry[i]) else null
	return item if item and not item.visible else null


func _arrive(i: int) -> void:
	_vel[i] = Vector3.ZERO
	if _mode[i] == Mode.FLY:
		_pos[i] = _flight_goal(i)
		_mode[i] = Mode.PERCH
		_timer[i] = randf_range(PERCH_TIME.x, PERCH_TIME.y)
		var item := _carried(i)
		if item:   # ins Nest
			_stash(item)
		_carry[i] = null
		return
	_pos[i] = _goal[i]
	var item: Item = _carry[i] if is_instance_valid(_carry[i]) else null
	if item and not item.is_held and item.visible and item.global_position.distance_to(_pos[i]) < 0.6 \
			and not _seen(item.global_position):
		item.visible = false   # im Schnabel – sie fliegt damit zum Nest
		item.freeze = true
		item.set_meta("interactable", null)
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


# --- Scheu, Ruf, Glänzendes -----------------------------------------------------------------------

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
				_change_favor(-GRUDGE_RAM, "hineingerannt")
			_flush(i, true)
		elif _mode[i] == Mode.FLY and _carried(i) and player.camera.global_position.distance_to(_pos[i]) < reach * 1.5:
			_drop(i)   # Schreck im Flug


## Krähe i und ihre Nachbarn fliegen krächzend in die Kronen. Lärm höchstens alle NOISE_PAUSE Sekunden.
func _flush(i: int, by_player: bool) -> void:
	var center := _pos[i]
	for k in COUNT:
		if _mode[k] in [Mode.GROUND, Mode.LAND] and _pos[k].distance_to(center) < FLOCK_RANGE:
			_mode[k] = Mode.FLY
			_vel[k] = Vector3.UP * 2.5
			_carry[k] = null   # was sie holen wollte, liegt noch am Boden
		elif _mode[k] == Mode.FLY and _carried(k) and _pos[k].distance_to(center) < FLOCK_RANGE:
			_drop(k)
	_caw(center, by_player)


## Krächzen und Flügelschlagen des auffliegenden Trupps: Lärm höchstens alle NOISE_PAUSE Sekunden.
func _caw(at: Vector3, by_player: bool) -> void:
	var now := Game.director.elapsed if Game.director else 0.0
	if now - _last_noise < NOISE_PAUSE:
		return
	_last_noise = now
	if Game.tracing:
		print("[Krähen] fliegen auf (%s)" % ("Spieler" if by_player else "Bedrohung"))
	Game.noise("crows", at + Vector3.UP * 0.5, self)
	Game.sound_at("wings", at, Senses.NOISE["crows"]["range"], self, 0.7)


## Erschreckt im Flug: Was sie im Schnabel trägt, fällt herunter.
func _drop(i: int) -> void:
	var item := _carried(i)
	_carry[i] = null
	if item == null:
		return
	item.global_position = _pos[i]
	item.visible = true
	item.freeze = false
	item.linear_velocity = _vel[i] * 0.3
	item.set_meta("interactable", item)
	if Game.tracing:
		print("[Krähen] lässt %s fallen" % item.display_name)


## Lärm in der Welt (Game.noise): Trifft ein Wurf des Spielers das Nest, fällt ein Stück heraus. Schlägt er neben
## ihnen auf, merken sie es sich. Laute Geräusche scheuchen sie auf.
func on_noise(pos: Vector3, loudness: float, source: Node) -> void:
	if _mm == null or source == self:
		return
	var thrown := source as Item
	if thrown and thrown.thrower == Game.player and pos.distance_to(_nest_pos) < NEST_HIT:
		_nest_hit()
		return
	for i in COUNT:
		if _mode[i] == Mode.PERCH:
			continue
		var d := _pos[i].distance_to(pos)
		if thrown and thrown.thrower == Game.player and d < GRUDGE_HIT_RANGE:
			_change_favor(-GRUDGE_HIT, "ein Wurf schlug neben ihnen auf")
			if _mode[i] == Mode.FLY:
				_drop(i)
			_flush(i, true)
			return
		if d < loudness * 0.5 and loudness >= Senses.LOUD:
			if _mode[i] == Mode.FLY:
				_drop(i)
			_flush(i, false)
			return


## Mit Groll: Ist der Spieler draußen in ihrer Nähe, krächzt die nächste Krähe ihn an (Lärm – das Monster hört es).
func _update_cawing(delta: float) -> void:
	_caw_timer -= delta
	var g := grudge()
	if g < GRUDGE_MIN or _caw_timer > 0.0 or scarecrow_masked():
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
	_caw_timer = CAW_EVERY / g * randf_range(0.7, 1.3)
	var to := player.global_position - _pos[best]
	if _mode[best] in [Mode.GROUND, Mode.PERCH]:
		_yaw[best] = atan2(-to.x, -to.z)
	Game.noise("crow", _pos[best] + Vector3.UP * 0.2, self)
	if not _warned:
		_warned = true
		Game.say("Die Krähen krächzen dich an. Sie haben sich dein Gesicht gemerkt.", 4.0)
		if Game.notebook:
			Game.notebook.add_note("crows", "Seit ich nach ihnen geworfen habe, krächzen mich die Krähen im Garten an. Das hört man weit.", "Garten")


## Glänzendes, das draußen liegt: Die nächste Krähe am Boden holt es, wenn niemand hinsieht. Was auf dem Futtertisch
## liegt (ihre Geschenke), lassen sie liegen.
func _look_for_shiny() -> void:
	if scarecrow_masked():
		return
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if not item.kind in SHINY or item.is_held or not item.visible or item.hung or item.freeze \
				or absf(item.global_position.y) > 2.0 or not _outdoor(item.global_position) or _carry.has(item) \
				or _on_table(item):   # _outdoor kennt nur die Zelle – der Keller darunter wäre auch „draußen“
			continue
		var best := -1
		for i in COUNT:
			if _mode[i] == Mode.GROUND and _carry[i] == null and _pos[i].distance_to(item.global_position) < SHINY_RANGE \
					and (best < 0 or _pos[i].distance_to(item.global_position) < _pos[best].distance_to(item.global_position)):
				best = i
		if best >= 0 and not _seen(item.global_position):
			_carry[best] = item
			_mode[best] = Mode.LAND
			_goal[best] = item.global_position
			_vel[best] = Vector3.UP * 1.5
			return


func _seen(p: Vector3) -> bool:
	return Game.director != null and Game.player != null and Game.director.player_can_see(p)


## Vogelscheuchen-Maske (Spielkonzept 5.19, 2026-11-03): Solange der Spieler sie trägt, stehlen die Krähen nichts und
## krächzen ihn nicht an – egal wo er ist (ein Wert für den ganzen Trupp wie der Ruf).
func scarecrow_masked() -> bool:
	return Game.player != null and not Game.player.dead and Game.player.mask == "scarecrow"


# --- Nest -------------------------------------------------------------------------------------------

## Der Baum am Punkt „Krähennest“ im Plan (ZIM-158, der nächste dazu). Ohne ihn der große Baum gegenüber der
## Terrassentür von NEST_ROOM: der Baum, der am geradesten vor der Tür steht; ohne die Tür der in der Mitte aller Bäume.
func _nest_tree() -> Dictionary:
	var doors: Array = _builder.garden_doors.get(NEST_ROOM, [])
	var best := {}
	var score := INF
	if _builder.planned.has("crow_nest"):
		var mark: Vector3 = _builder.planned["crow_nest"][0]["at"]
		for t: Dictionary in _trees:
			var d := Vector2((t["pos"] as Vector3).x - mark.x, (t["pos"] as Vector3).z - mark.z).length()
			if d < score:
				score = d
				best = t
		return best
	for t: Dictionary in _trees:
		var p: Vector3 = t["pos"]
		if doors.is_empty():
			var mid := Vector3.ZERO
			for o: Dictionary in _trees:
				mid += (o["pos"] as Vector3) / _trees.size()
			if p.distance_to(mid) < score:
				score = p.distance_to(mid)
				best = t
			continue
		var door: Dictionary = doors[0]
		var v: Vector3 = p - (door["pos"] as Vector3)
		v.y = 0.0
		var along := v.dot(door["out"])
		if along <= 0.0:
			continue
		var s := (v - (door["out"] as Vector3) * along).length() + along * 0.05
		if s < score:
			score = s
			best = t
	return best


## Nest aus Zweigen in der Stammgabel knapp unter dem Laub (sonst sähe man es nicht), etwas zur Tür von NEST_ROOM hin.
## Ein Körper (Ebene 1) fängt Würfe; oben liegt Glänzendes, das ab und zu aufblitzt.
func _build_nest() -> void:
	var tree := _nest_tree()
	if tree.is_empty():
		return
	var base: Vector3 = tree["pos"]
	var crown: Vector2 = tree["crown"]
	var out := Vector3.RIGHT
	var doors: Array = _builder.garden_doors.get(NEST_ROOM, [])
	if not doors.is_empty():
		out = (doors[0]["pos"] as Vector3) - base
		out.y = 0.0
		out = out.normalized()
	_nest_pos = base + out * NEST_OUT + Vector3.UP * (float(tree["height"]) * crown.x - NEST_BELOW_CROWN)
	if Game.tracing:
		print("[Krähen] Nest im Baum bei (%.1f, %.1f), %.1f m hoch" % [base.x, base.z, _nest_pos.y])
	var holder := Node3D.new()
	holder.name = "Kraehennest"
	add_child(holder)
	holder.global_position = _nest_pos
	var twig := Mat.psx(Color(0.27, 0.21, 0.15))
	var dry := Mat.psx(Color(0.46, 0.38, 0.28))
	var bowl := Geo.mesh(holder, Geo.sphere(0.24, 0.3, 10, 5), Mat.psx(Color(0.16, 0.12, 0.08)), Vector3(0, -0.04, 0))
	bowl.scale = Vector3(1.0, 0.55, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1987
	for i in 56:   # Zweige rund um die Mulde, kreuz und quer, einige stehen heraus
		var a := rng.randf() * TAU
		var ring := rng.randf_range(0.14, 0.3)
		var dir := Vector3(-sin(a) + rng.randf_range(-0.5, 0.5), rng.randf_range(-0.45, 0.45), cos(a) + rng.randf_range(-0.5, 0.5)).normalized()
		var stick := Geo.mesh(holder, Geo.cylinder(rng.randf_range(0.005, 0.011), rng.randf_range(0.28, 0.6), 4), dry if i % 3 == 0 else twig,
			Vector3(cos(a) * ring, rng.randf_range(-0.1, 0.08), sin(a) * ring))
		stick.basis = Basis(Quaternion(Vector3.UP, dir))
	_nest_bits = Node3D.new()
	holder.add_child(_nest_bits)
	var metal := Mat.metal(Color(0.85, 0.72, 0.42))
	for i in 3:   # obenauf: Messing und Blech
		var bit := Geo.mesh(_nest_bits, Geo.box(Vector3(0.05, 0.008, 0.02)), metal if i != 1 else Mat.metal(), Vector3(-0.06 + i * 0.06, 0.07, 0.03 * (i - 1)))
		bit.rotation = Vector3(0.3, i * 1.1, 0.2)
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape3D.new()
	var ball := SphereShape3D.new()
	ball.radius = 0.32
	shape.shape = ball
	body.add_child(shape)
	holder.add_child(body)
	# Aufblitzen: ein weicher Lichtpunkt, der sich zum Betrachter dreht
	var quad := QuadMesh.new()
	quad.size = Vector2(0.14, 0.14)
	var tex := GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.gradient = Gradient.new()
	tex.gradient.colors = PackedColorArray([Color(1, 0.95, 0.8, 1), Color(1, 0.9, 0.7, 0)])
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	glow.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	glow.albedo_texture = tex
	_glint = Geo.mesh(holder, quad, glow, Vector3(0, 0.1, 0))
	_glint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_glint.visible = false
	_update_nest()


func _update_nest() -> void:
	if _nest_bits:
		_nest_bits.visible = not nest.is_empty()


## Im Nest blitzt ab und zu etwas auf – nur, wenn etwas darin liegt und der Spieler draußen in der Nähe ist.
func _update_glint(delta: float) -> void:
	if _glint == null:
		return
	_glint_timer -= delta
	if _glint.visible:
		var k := clampf(-_glint_timer / GLINT_TIME, 0.0, 1.0)
		_glint.scale = Vector3.ONE * sin(PI * k)
		if k >= 1.0:
			_glint.visible = false
			_glint_timer = randf_range(GLINT_EVERY.x, GLINT_EVERY.y)
		return
	if _glint_timer > 0.0 or nest.is_empty() or Game.player == null \
			or Game.player.global_position.distance_to(_nest_pos) > 40.0:
		return
	_glint.position = Vector3(randf_range(-0.08, 0.08), 0.09, randf_range(-0.08, 0.08))
	_glint.visible = true
	_glint_timer = 0.0


## Eine Krähe bringt Glänzendes ins Nest: Es liegt dort als Eintrag (gespeichert), der Gegenstand verschwindet.
func _stash(item: Item) -> void:
	nest.append({"kind": int(item.kind), "extra": item.create_extra()})
	if Game.tracing:
		print("[Krähen] %s liegt jetzt im Nest (%d Stück)" % [item.display_name, nest.size()])
	item.queue_free()
	_update_nest()


## Stück at aus dem Nest als neuer Gegenstand (noch nicht in der Szene).
func _from_nest(at: int) -> Item:
	var entry: Dictionary = nest[at]
	nest.remove_at(at)
	_update_nest()
	return Item.create(int(entry["kind"]) as Item.Kind, String(entry["extra"]))


## Ein Wurf trifft das Nest (Gewalt): Ein Stück fällt heraus, der Trupp fliegt krächzend auf, der Ruf fällt stark.
func _nest_hit() -> void:
	_change_favor(-GRUDGE_NEST, "Wurf ins Nest")
	for i in COUNT:
		if _mode[i] in [Mode.GROUND, Mode.LAND] and _pos[i].distance_to(_nest_pos) < 15.0:
			_mode[i] = Mode.FLY
			_vel[i] = Vector3.UP * 2.5
			_carry[i] = null
	_last_noise = -INF
	_caw(_nest_pos, true)
	if nest.is_empty():
		return
	var item := _from_nest(randi() % nest.size())
	_builder.world.add_child(item)
	item.global_position = _nest_pos + Vector3(randf_range(-0.2, 0.2), -0.25, randf_range(-0.2, 0.2))
	item.linear_velocity = Vector3(randf_range(-0.6, 0.6), 0.3, randf_range(-0.6, 0.6))
	if Game.tracing:
		print("[Krähen] aus dem Nest fällt %s" % item.display_name)
	if Game.notebook:
		Game.notebook.add_note("crows_nest", "Im großen Baum gegenüber von Zimmer 042 sitzt ein Krähennest. Was sie draußen stehlen, tragen sie dorthin – mit einem Wurf fällt etwas heraus, aber sie nehmen es übel.", "Garten")


# --- Futtertisch und Geschenke ----------------------------------------------------------------------

## Liegt der Gegenstand auf dem Futtertisch?
func _on_table(item: Item) -> bool:
	if _feed_table.is_empty():
		return false
	var top: Vector3 = _feed_table["pos"]
	var size: Vector2 = _feed_table["size"]
	var p := item.global_position
	return absf(p.x - top.x) < size.x / 2.0 + 0.05 and absf(p.z - top.z) < size.y / 2.0 + 0.05 \
		and p.y > top.y - 0.1 and p.y < top.y + 0.4


## Futter (Kürbiskerne, Brotkrumen), das gerade auf dem Futtertisch liegt.
func _table_food() -> Array[Item]:
	var food: Array[Item] = []
	if _feed_table.is_empty():
		return food
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.kind == Item.Kind.PUMPKIN_SEEDS and not item.is_held and item.visible and _on_table(item):
			food.append(item)
	return food


## Alle LOOK_EVERY Sekunden: Liegt Futter auf dem Tisch, läuft die Zeit; nach FOOD_HOURS ist es weg, sobald niemand
## hinsieht.
func _check_food(dt: float) -> void:
	var food := _table_food()
	if food.is_empty():
		food_time = 0.0
		_crow_food = false
		return
	var p := Game.player
	if p != null and p.mask == "crow" and p.global_position.distance_to(_feed_table["pos"]) < MASK_TABLE:
		_crow_food = true
	food_time += dt
	if food_time >= FOOD_HOURS * Calendar.HOUR and not _seen(_feed_table["pos"]):
		_eat(food)


## Das Futter ist weg: Der Ruf steigt (am ersten Tag einer Fütterung mehr), bei Gunst liegt ein Geschenk da.
func _eat(food: Array[Item]) -> void:
	var parent := food[0].get_parent()
	for item in food:
		item.queue_free()
	food_time = 0.0
	var k := 2.0 if _crow_food else 1.0
	var why := " (Krähenmaske)" if _crow_food else ""
	_crow_food = false
	var today := Calendar.today()
	if today != last_fed_day:
		last_fed_day = today
		fed_days += 1
		_change_favor(FAVOR_FEED * k, "gefüttert, %d. Tag%s" % [fed_days, why])
	else:
		_change_favor(FAVOR_FEED_MORE * k, "noch einmal gefüttert" + why)
	if favor < GIFT_FAVOR:
		return
	var gift := _gift()
	parent.add_child(gift)
	var top: Vector3 = _feed_table["pos"]
	gift.global_position = top + Vector3(randf_range(-0.15, 0.15), 0.02, randf_range(-0.1, 0.1))
	gift.rotation.y = randf() * TAU
	if Game.tracing:
		print("[Krähen] Geschenk auf dem Tisch: %s" % gift.display_name)
	if Game.notebook:
		if gift.kind == Item.Kind.KEY and gift.key_id == OLD_KEY:
			Game.notebook.add_note("crows_key", "Die Krähen haben mir einen alten Messingschlüssel auf den Tisch gelegt. Am Anhänger steht 042 – das Zimmer gegenüber ihrem Nest.", "Garten")
		else:
			Game.notebook.add_note("crows_gift", "Statt des Futters lag etwas anderes auf dem Tisch im Gärtchen. Die Krähen bringen Geschenke.", "Garten")


## Was sie bringen: den Schlüssel von 1987 erst bei hoher Gunst nach Fütterungen über Tage, sonst Gestohlenes aus dem
## Nest, sonst gelegentlich Kleinzeug (Batterie, Streichhölzer, Kerze), meist Münzen.
func _gift() -> Item:
	var key_at := -1
	var stolen: Array[int] = []
	for k in nest.size():
		if int(nest[k]["kind"]) == Item.Kind.KEY and String(nest[k]["extra"]) == OLD_KEY:
			key_at = k
		else:
			stolen.append(k)
	if key_at >= 0 and favor >= KEY_FAVOR and fed_days >= KEY_DAYS:
		return _from_nest(key_at)
	if not stolen.is_empty():
		return _from_nest(stolen.pick_random())
	if _debug_useful or randf() < USEFUL_CHANCE:
		_debug_useful = false
		return Item.create(USEFUL.pick_random() as Item.Kind)
	return Item.create(Item.Kind.COINS, str(randi_range(COIN_GIFT.x, COIN_GIFT.y)))


# --- Debug ------------------------------------------------------------------------------------------

## Debug (--kraehen[=groll|gunst|stehlen|nest|werfen|futter|schluessel]):
## leer: du stehst im Garten 7 m vor den Krähen des ersten Baums · groll: dazu voller Groll, gleich krächzt eine ·
## gunst: volle Gunst · stehlen: eine Münze und ein Messer liegen 2 m vor den Krähen, du siehst weg · nest: 2,5 m vor dem
## Nest, Blick hinauf, darin dazu Münzen und ein Kompass · werfen: wie nest, nach 1 s wirfst du eine Münze hinein ·
## futter: vor dem Futtertisch, Brotkrumen darauf, die Zeit ist fast um – sieh weg · schluessel: wie futter, mit hoher
## Gunst nach drei Tagen, es kommt der Schlüssel von 1987 · geschenk: wie futter, mit Gunst knapp über der Schwelle,
## es kommt Kleinzeug (ZIM-31). Ohne Tisch im Plan steht für futter, schluessel und geschenk ein Ersatztisch vor
## Zimmer 13 (nur im Debug).
func debug_show(what: String) -> void:
	if _mm == null:
		Game.say("Krähen: Draußen steht kein Baum.", 2.5)
		return
	var player := Game.player
	match what:
		"nest", "werfen":
			if _nest_pos == Vector3.INF:
				Game.say("Krähen: kein Baum fürs Nest.", 2.5)
				return
			nest.append({"kind": int(Item.Kind.COINS), "extra": "3"})
			nest.append({"kind": int(Item.Kind.COMPASS), "extra": ""})
			_update_nest()
			var out := Vector3.RIGHT
			var doors: Array = _builder.garden_doors.get(NEST_ROOM, [])
			if not doors.is_empty():
				out = (doors[0]["out"] as Vector3)
			var stand := Vector3(_nest_pos.x, 0.0, _nest_pos.z) - out * 2.5
			_look_from(stand, _nest_pos)
			if what == "werfen":
				get_tree().create_timer(1.0).timeout.connect(_debug_throw)
			return
		"futter", "schluessel", "geschenk":
			if _feed_table.is_empty():
				_debug_table()
			if what == "schluessel":
				favor = KEY_FAVOR
				fed_days = KEY_DAYS
			elif what == "geschenk":
				favor = GIFT_FAVOR
				_debug_useful = true
			var top: Vector3 = _feed_table["pos"]
			var food := Item.create(Item.Kind.PUMPKIN_SEEDS, "brot")
			_builder.world.add_child(food)
			food.global_position = top + Vector3(0, 0.02, 0)
			food_time = FOOD_HOURS * Calendar.HOUR - LOOK_EVERY * 2.0
			var doors: Array = _builder.garden_doors.get(LevelBuilder.PLAYER_ROOM, [])
			var stand := top + Vector3(1.6, 0, 0)
			if not doors.is_empty():
				stand = (doors[0]["pos"] as Vector3) + (doors[0]["out"] as Vector3) * 1.0
			stand.y = 0.0
			_look_from(stand, top)
			get_tree().create_timer(3.0).timeout.connect(_debug_look_away)
			return
	var c := _home[0]
	var stand := c + Vector3(7.0, 0, 0)
	for k in 12:
		var a := TAU * k / 12.0
		var p := c + Vector3(cos(a), 0, sin(a)) * 7.0
		if _outdoor(p):
			stand = p
			break
	_look_from(stand, c)
	match what:
		"groll":
			favor = -1.0
			_caw_timer = 1.5
		"gunst":
			favor = 1.0
		"stehlen":
			for k in 2:
				var item := Item.create(Item.Kind.COINS if k == 0 else Item.Kind.KNIFE, "2" if k == 0 else "")
				_builder.world.add_child(item)
				item.global_position = c + Vector3(0.5 - k, 0.05, 0.6)
			player.rotation.y += PI   # wegsehen


func _debug_look_away() -> void:
	Game.player.rotation.y += PI


func _look_from(stand: Vector3, target: Vector3) -> void:
	var player := Game.player
	player.global_position = stand + Vector3(0, 0.05, 0)
	var look := target - player.camera.global_position
	player.rotation.y = atan2(-look.x, -look.z)
	player.head.rotation.x = clampf(atan2(look.y, Vector2(look.x, look.z).length()), -1.2, 1.2)


## Debug: Der Spieler wirft eine Münze ins Nest (wie Player beim Werfen, 3.13).
func _debug_throw() -> void:
	var coin := Item.create(Item.Kind.COINS, "1")
	_builder.world.add_child(coin)
	var from := Game.player.camera.global_position
	var to := _nest_pos - from
	var flat := Vector2(to.x, to.z).length()
	var t := 0.6   # Flugzeit
	var velocity := Vector3(to.x / t, (to.y + 0.5 * 9.8 * t * t) / t, to.z / t)
	if Game.tracing:
		print("[Krähen] Debug: Wurf ins Nest (%.1f m)" % flat)
	coin.throw_from(from, velocity, Game.player)


## Debug: Ersatztisch vor der ersten Gartentür von Zimmer 13, solange im Plan keiner steht.
func _debug_table() -> void:
	var doors: Array = _builder.garden_doors.get(LevelBuilder.PLAYER_ROOM, [])
	var at := Vector3.ZERO
	if not doors.is_empty():
		at = (doors[0]["pos"] as Vector3) + (doors[0]["out"] as Vector3) * 2.5
	at.y = 0.0
	var body := StaticBody3D.new()
	body.name = "Futtertisch_Debug"
	_builder.world.add_child(body)
	body.global_position = at
	Geo.box_part(body, Vector3(0.9, 0.75, 0.6), Vector3(0, 0.375, 0), Mat.psx(Color(0.42, 0.3, 0.2)))
	_feed_table = {"pos": at + Vector3(0, 0.75, 0), "size": Vector2(0.9, 0.6)}
	Game.say("Krähen: Im Plan steht noch kein Futtertisch – hier ein Ersatz.", 3.0)
