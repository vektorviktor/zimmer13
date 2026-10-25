class_name Moths
extends Node3D
## Nachtfalter (Spielkonzept 4.25). Um brennende Lampen in der Nähe des Spielers taumeln ein paar Motten – reine
## Stimmung, auf einem MultiMesh (shaders/psx_bird.gdshader, matt).
## **Der Totenkopfschwärmer:** Ein großer brauner Falter mit gelber Schädelzeichnung sitzt auf dem Kopfkissen in dem
## Zimmer, dessen Tür gerade am schwächsten geschützt ist – dort, wo die Puppe als Nächstes säße
## (`MonsterDirector.forecast_room`, alle FORECAST_EVERY neu; mit Urteil das Zimmer des Urteils). Wer mehr schmückt,
## schickt ihn weiter. Er ist eine Tendenz, kein Urteil: Die Puppe (5.5) bleibt das Urteil. Kommt man ihm nah, piept er
## (wie der echte, er presst Luft durch den Rüssel) und fliegt auf; wo niemand hinsieht, ist er fort. Bewohner, die ihn
## sehen, bekommen Angst und sagen es. Erst nach dem ersten Angriff. Nicht gespeichert: Er setzt sich neu.

const AMBIENT := 8                    ## Motten insgesamt
const PER_LAMP := 3
const LAMP_RANGE := 14.0              ## brennende Lampen so nah beim Spieler bekommen Motten
const LAMP_CHECK := 1.5
const ORBIT := Vector2(0.18, 0.5)     ## so weit um die Lampe
const SPEED := 1.6
const JITTER := 2.5
const FLAP_RATE := 24.0
## Totenkopfschwärmer
const FORECAST_EVERY := Calendar.HOUR * 2.0
const OMEN_SIZE := 0.12               ## Spannweite (m), etwa wie der echte
const SQUEAK_RANGE := 1.6             ## so nah piept er und fliegt auf
const NOTICE_RANGE := 3.0             ## so nah sehen ihn Bewohner
const NOTICE_FEAR := 15.0
const NOTICE_LINES := ["Da sitzt ein Falter auf meinem Kissen … mit einem Totenkopf drauf.",
	"Ein Totenkopfschwärmer. Meine Großmutter sagte, die kommen, wenn jemand stirbt.",
	"Wie kommt dieser Falter in mein Zimmer? Und warum sieht er mich an?"]
const PLAYER_LINE := "Ein Totenkopfschwärmer auf deinem Kissen. Die Zeichnung auf seinem Rücken grinst."

var _builder: LevelBuilder
var _mm: MultiMesh
var _pos := PackedVector3Array()
var _vel := PackedVector3Array()
var _anchor: Array[Node3D] = []       ## Lampe, um die die Motte kreist (null = unterwegs zur nächsten)
var _flap := PackedFloat32Array()
var _lamp_t := 0.0
# Totenkopfschwärmer
var omen_room := ""
var _omen: Node3D
var _omen_mat: ShaderMaterial
var _forecast_t := 5.0
var _fled := false
var _fly_t := 0.0
var _fly_dir := Vector3.ZERO
var _noticed := {}


func setup(builder: LevelBuilder) -> void:
	_builder = builder
	_build_ambient()
	_build_omen()


func _build_ambient() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body: Array[Vector3] = [Vector3(0, 0, -0.012), Vector3(0.003, 0, 0), Vector3(0, 0.003, 0), Vector3(-0.003, 0, 0),
		Vector3(0, -0.003, 0), Vector3(0, 0, 0.014)]
	for tri in [[0, 1, 2], [0, 2, 3], [0, 3, 4], [0, 4, 1], [5, 2, 1], [5, 3, 2], [5, 4, 3], [5, 1, 4]]:
		for k in tri:
			st.set_color(Color(0, 0, 0))
			st.set_normal(body[k].normalized())
			st.add_vertex(body[k])
	for side in [1.0, -1.0]:
		var w: Array[Vector3] = [Vector3(0.003, 0, -0.008), Vector3(0.022, 0, -0.012), Vector3(0.026, 0, 0.002),
			Vector3(0.016, 0, 0.012), Vector3(0.003, 0, 0.008)]
		for tri in [[0, 1, 2], [0, 2, 3], [0, 3, 4]]:
			for k in tri:
				st.set_color(Color(0, 0, 0))
				st.set_normal(Vector3.UP)
				st.add_vertex(Vector3(w[k].x * side, w[k].y, w[k].z))
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/psx_bird.gdshader")
	mat.set_shader_parameter("albedo", Color(0.62, 0.56, 0.46))
	mat.set_shader_parameter("shoulder", 0.003)
	mat.set_shader_parameter("flap_amp", 1.1)
	mat.set_shader_parameter("roughness_base", 0.9)
	_mm = MultiMesh.new()
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_custom_data = true
	_mm.mesh = st.commit()
	_mm.instance_count = AMBIENT
	_mm.visible_instance_count = 0
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = _mm
	mmi.material_override = mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mmi.custom_aabb = AABB(Vector3(-500, -50, -500), Vector3(1000, 200, 1000))
	add_child(mmi)
	for i in AMBIENT:
		_pos.append(Vector3.ZERO)
		_vel.append(Vector3.ZERO)
		_anchor.append(null)
		_flap.append(randf() * TAU)


## Der Totenkopfschwärmer: dicker Körper, Vorderflügel dachförmig angelegt (sitzend), auf dem Rücken die Zeichnung
## (eigene kleine Textur aus TexGen-freien Pixeln: dunkelbraun gesprenkelt, gelber Schädel, Hinterleib gelb geringelt).
func _build_omen() -> void:
	_omen = Node3D.new()
	_omen.visible = false
	add_child(_omen)
	_omen_mat = ShaderMaterial.new()
	_omen_mat.shader = load("res://shaders/psx_surface.gdshader")
	_omen_mat.set_shader_parameter("albedo", Color(1, 1, 1))
	_omen_mat.set_shader_parameter("albedo_tex", _omen_texture())
	var s := OMEN_SIZE
	# Flügel als ein flaches Dach über dem Körper, die Spitzen leicht nach hinten
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var v: Array[Vector3] = [Vector3(0, s * 0.1, -s * 0.28), Vector3(s * 0.5, s * 0.03, s * 0.12), Vector3(s * 0.34, s * 0.03, s * 0.3),
		Vector3(0, s * 0.11, s * 0.22), Vector3(-s * 0.34, s * 0.03, s * 0.3), Vector3(-s * 0.5, s * 0.03, s * 0.12)]
	var uv: Array[Vector2] = [Vector2(0.5, 0.0), Vector2(1.0, 0.6), Vector2(0.84, 1.0), Vector2(0.5, 0.85), Vector2(0.16, 1.0), Vector2(0.0, 0.6)]
	for tri in [[0, 1, 2], [0, 2, 3], [0, 3, 4], [0, 4, 5]]:
		for k in tri:
			st.set_uv(uv[k])
			st.set_normal(Vector3.UP)
			st.add_vertex(v[k])
	var wings := MeshInstance3D.new()
	wings.mesh = st.commit()
	wings.material_override = _omen_mat
	_omen.add_child(wings)
	Geo.mesh(_omen, Geo.sphere(s * 0.09, s * 0.5, 8, 4), Mat.psx(Color(0.2, 0.14, 0.08)), Vector3(0, s * 0.06, -s * 0.02)).rotation.x = PI / 2.0
	Geo.mesh(_omen, Geo.sphere(s * 0.07, s * 0.12, 6, 3), Mat.psx(Color(0.14, 0.1, 0.06)), Vector3(0, s * 0.07, -s * 0.28))


static func _omen_texture() -> ImageTexture:
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	for y in n:
		for x in n:
			var c := Color(0.23, 0.16, 0.1).lerp(Color(0.38, 0.27, 0.16), rng.randf() * 0.6)
			if absf(x - n / 2.0) < 2.5:
				c = Color(0.12, 0.08, 0.05)   # dunkle Mittelnaht
			img.set_pixel(x, y, c)
	# der Schädel: gelbliche Stirn, zwei dunkle Augenhöhlen, Kiefer – auf dem Bruststück vorn in der Mitte
	var center := Vector2(n / 2.0, n * 0.3)
	for y in n:
		for x in n:
			var d := (Vector2(x, y) - center) / Vector2(9.0, 8.0)
			if d.length() < 1.0:
				img.set_pixel(x, y, Color(0.85, 0.7, 0.3))
			for eye: Vector2 in [Vector2(-3.5, -1.0), Vector2(3.5, -1.0)]:
				if (Vector2(x, y) - center - eye).length() < 2.2:
					img.set_pixel(x, y, Color(0.1, 0.06, 0.03))
			if absf(x - center.x) < 4.0 and y > center.y + 5.0 and y < center.y + 9.0 and x % 2 == 0:
				img.set_pixel(x, y, Color(0.8, 0.65, 0.3))
	# Querbänder auf den Flügeln, nach hinten gelb und schwarz geringelt (der Hinterleib schaut hervor)
	for y in range(int(n * 0.75), n):
		for x in range(int(n * 0.42), int(n * 0.58)):
			img.set_pixel(x, y, Color(0.85, 0.7, 0.2) if (y / 3) % 2 == 0 else Color(0.1, 0.07, 0.04))
	var tex := ImageTexture.create_from_image(img)
	return tex


func _physics_process(delta: float) -> void:
	_lamp_t -= delta
	if _lamp_t <= 0.0:
		_lamp_t = LAMP_CHECK
		_assign_lamps()
	for i in AMBIENT:
		_step(i, delta)
	_update_omen(delta)


## Bis zu zwei brennende Lampen in der Nähe des Spielers bekommen je PER_LAMP Motten (im Stromausfall keine).
func _assign_lamps() -> void:
	var player := Game.player
	if player == null:
		return
	var lamps: Array[Node3D] = []
	for node in get_tree().get_nodes_in_group("lamps"):
		var light := node as FlickerLight
		if light == null or light.soft or light.light_energy < 0.2 or not light.is_visible_in_tree() \
				or light.global_position.distance_to(player.global_position) > LAMP_RANGE \
				or absf(light.global_position.y - player.global_position.y) > 3.0:
			continue
		lamps.append(light)
	lamps.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return a.global_position.distance_to(player.global_position) < b.global_position.distance_to(player.global_position))
	lamps = lamps.slice(0, mini(2, AMBIENT / PER_LAMP))
	var shown := 0
	for i in AMBIENT:
		var lamp: Node3D = lamps[i / PER_LAMP] if i / PER_LAMP < lamps.size() else null
		if lamp != _anchor[i]:
			_anchor[i] = lamp
			if lamp:
				_pos[i] = lamp.global_position + Vector3(randf_range(-0.4, 0.4), randf_range(-0.2, 0.3), randf_range(-0.4, 0.4))
		if lamp:
			shown = i + 1
	_mm.visible_instance_count = shown


func _step(i: int, delta: float) -> void:
	var lamp := _anchor[i]
	if lamp == null or not is_instance_valid(lamp):
		return
	var c := lamp.global_position
	var to := c - _pos[i]
	var r := to.length()
	# taumeln: zur Lampe hin, wenn zu weit, weg, wenn zu nah, dazu kräftiges Zittern
	var want := to.normalized() * SPEED * (1.0 if r > ORBIT.y else (-0.6 if r < ORBIT.x else 0.1))
	want += Vector3(randf_range(-1, 1), randf_range(-0.7, 0.7), randf_range(-1, 1)) * JITTER
	_vel[i] = _vel[i].move_toward(want, 12.0 * delta)
	_pos[i] += _vel[i] * delta
	_flap[i] = fmod(_flap[i] + TAU * FLAP_RATE * delta, TAU)
	var dir := _vel[i].normalized() if _vel[i].length() > 0.05 else Vector3.FORWARD
	var b := Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.95 else Vector3.BACK)
	_mm.set_instance_transform(i, Transform3D(b, _pos[i]))
	_mm.set_instance_custom_data(i, Color(_flap[i], 0, 0, 0))


# --- Totenkopfschwärmer -----------------------------------------------------------------------------

func _update_omen(delta: float) -> void:
	var d := Game.director
	if d == null or not d.first_attack_done:
		_omen.visible = false
		return
	if _fly_t > 0.0:   # aufgescheucht: flattert davon und ist fort, sobald niemand mehr hinsieht
		_fly_t -= delta
		_omen.global_position += _fly_dir * 1.5 * delta + Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * 0.02
		_omen.rotation.y += delta * 6.0
		if _fly_t <= 0.0 or not d.player_can_see(_omen.global_position):
			_fly_t = 0.0
			_omen.visible = false
		return
	_forecast_t -= delta
	if _forecast_t <= 0.0:
		_forecast_t = FORECAST_EVERY
		var room := d.forecast_room()
		if room != omen_room:
			_settle(room)
	if not _omen.visible:
		return
	var player := Game.player
	if player and player.global_position.distance_to(_omen.global_position) < SQUEAK_RANGE \
			and absf(player.global_position.y - _omen.global_position.y) < 2.0:
		_take_off()
		return
	if Game.social:
		for g in Game.social.living_guests():
			if g.is_child() or _noticed.has(g.id) or String(g.home.get("no", "")) != omen_room \
					or g.global_position.distance_to(_omen.global_position) > NOTICE_RANGE:
				continue
			_noticed[g.id] = true
			g.fear = minf(100.0, g.fear + NOTICE_FEAR)
			g.say(NOTICE_LINES.pick_random())


## Der Falter zieht um – nur, wenn der Spieler weder den alten noch den neuen Platz sieht (wie die Puppe).
func _settle(room: String) -> void:
	var spot := _pillow_of(room)
	var d := Game.director
	if _omen.visible and d.player_can_see(_omen.global_position):
		return
	if spot.is_empty() or d.player_can_see(spot["pos"]):
		return
	omen_room = room
	_noticed.clear()
	_omen.global_position = spot["pos"]
	_omen.rotation = Vector3(0, float(spot["yaw"]) + randf_range(-0.5, 0.5), 0)
	_omen.visible = true
	if Game.tracing:
		print("[Totenkopfschwärmer] sitzt in Zimmer %s" % room)


## Kopfkissen des ersten Betts im Zimmer: {pos, yaw} – {} = kein Bett.
func _pillow_of(room: String) -> Dictionary:
	if room == "" or not Game.director.rooms.has(room):
		return {}
	for spot in Game.director.rooms[room].get("spots", []):
		var bed := spot as HideSpot
		if bed == null or bed.type != HideSpot.Type.BED:
			continue
		var inner := BedModel.inner(bed.bed_size)
		var local := Vector3(bed.head_x * (inner.x / 2.0 - 0.3), BedModel.TOP + 0.13, -0.08)
		return {"pos": bed.to_global(local), "yaw": bed.global_rotation.y}
	return {}


func _take_off() -> void:
	Game.sound_at("moth", _omen.global_position, 4.0, self)
	_fly_t = 2.5
	_fly_dir = (Vector3(randf_range(-1, 1), 0.8, randf_range(-1, 1))).normalized()
	if omen_room == LevelBuilder.PLAYER_ROOM:
		Game.say(PLAYER_LINE, 4.0)
	if Game.notebook:
		Game.notebook.add_note("death_moth", "Ein Totenkopfschwärmer saß auf einem Kopfkissen in Zimmer %s. Er piepte, als ich kam." % \
			String(Game.director.rooms[omen_room]["sign"]) if Game.director.rooms.has(omen_room) else omen_room, "gesehen")


## Debug (--falter[=zimmer]): Der Totenkopfschwärmer setzt sich sofort ins Zimmer der Vorhersage (oder dieses, Nummer
## wie am Schild), du stehst in der Tür – der erste Angriff gilt als geschehen.
func debug_show(room: String) -> void:
	var d := Game.director
	d.first_attack_done = true
	var no := room
	for key in d.rooms:
		if String(d.rooms[key]["sign"]) == room:
			no = key
	if not d.rooms.has(no):
		no = d.forecast_room()
	_forecast_t = FORECAST_EVERY
	_omen.visible = false
	_fly_t = 0.0
	var spot := _pillow_of(no)
	if spot.is_empty():
		Game.say("Totenkopfschwärmer: In Zimmer %s steht kein Bett." % room, 2.5)
		return
	omen_room = no
	_omen.global_position = spot["pos"]
	_omen.rotation.y = spot["yaw"]
	_omen.visible = true
	var info: Dictionary = d.rooms[no]
	var stand: Vector3 = info["door_inside"]
	TeleportUI.place_player(stand, (spot["pos"] as Vector3) - stand)
