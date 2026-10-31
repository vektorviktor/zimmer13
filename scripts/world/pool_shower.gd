class_name PoolShower
extends Node3D
## Duschplatz am Pool (Spielkonzept 7.13, ZIM-144): an der Wand ein Drücker mit runder Wandmanschette, rechts daneben
## eine Ablage, darüber der Duschkopf an einem Wandarm. Alles gebürsteter Edelstahl wie die Badarmaturen (Mat.metal),
## die Düsen sind die Textur der Zimmerdusche. Ursprung auf dem Boden an der Wandfläche, lokale +Z in den Raum, +X ist
## von vorn gesehen rechts. Ohne Kollision (zu hoch bzw. zu flach, um daran hängen zu bleiben) – nur der Drücker hat
## einen Körper für die Interaktion: Ein Druck lässt das Wasser RUN_TIME Sekunden laufen (Selbstschluss, nochmal
## drücken verlängert), mit Strahl, Dampf und Rauschen (SynthAudio.pool_shower) – Lärm „shower“, das Monster hört es.
## Nicht gespeichert (läuft nur Sekunden). Dazu der Bodenablauf in der Raummitte (drain).

const NOZZLES := "res://assets/models/shower_shower_nozzles.png"

## Drücker: Mitte auf 1 m, Manschette 14 cm Durchmesser, schaut 8 cm aus der Wand
const BUTTON_Y := 1.0
## Ablage rechts neben dem Drücker, Mitte auf Drückerhöhe: 24 × 11 cm, Rand 3 cm hoch
const SHELF_SIZE := Vector3(0.24, 0.03, 0.11)
const SHELF_GAP := 0.05   ## Abstand Manschette – Ablage
const SHELF_EDGE := 0.008   ## Stärke des Rands
## Duschkopf: Mitte 40 cm vor der Wand, Unterkante auf 2,10 m, 25 cm Durchmesser; Wandarm Ø 22 mm
const HEAD_REACH := 0.4
const HEAD_Y := 2.1
const HEAD_R := 0.125
const ARM_Y := 2.26
const ARM_R := 0.011
const ARM_BEND := 0.06   ## Radius des Bogens nach unten
const JOINT_R := 0.016   ## Kugelgelenk über dem Kopf
## Bodenablauf (Foto 1.11.): 15 × 15 cm Edelstahl, 3 mm stark, 8 × 8 quadratische Löcher als Textur
const DRAIN := 0.15
const DRAIN_H := 0.003
const DRAIN_HOLES := 8

## Querschnitte als Drehkörper (Radius, Abstand) – beim Drücker von der Wand aus, beim Kopf von der Unterseite aus.
## Der Knopf ist eigen (er wird gedrückt) und steckt mit seinem Ende in der Hülse.
const BASE_PROFILE := [Vector2(0.07, 0.0), Vector2(0.07, 0.003), Vector2(0.066, 0.01), Vector2(0.062, 0.012),
	Vector2(0.034, 0.012), Vector2(0.033, 0.013), Vector2(0.033, 0.044), Vector2(0.031, 0.046), Vector2(0.026, 0.046)]
const KNOB_PROFILE := [Vector2(0.028, 0.038), Vector2(0.028, 0.054), Vector2(0.029, 0.055), Vector2(0.029, 0.066),
	Vector2(0.027, 0.072), Vector2(0.022, 0.0765), Vector2(0.013, 0.0793), Vector2(0.0, 0.08)]
const RUBBER_PROFILE := [Vector2(0.03, 0.046), Vector2(0.0305, 0.047), Vector2(0.0305, 0.053), Vector2(0.029, 0.0545)]
const ROSETTE_PROFILE := [Vector2(0.035, 0.0), Vector2(0.035, 0.006), Vector2(0.031, 0.01), Vector2(0.0, 0.01)]
const HEAD_PROFILE := [Vector2(HEAD_R - 0.006, 0.0), Vector2(HEAD_R, 0.003), Vector2(HEAD_R, 0.009),
	Vector2(HEAD_R - 0.006, 0.013), Vector2(0.04, 0.017), Vector2(0.016, 0.022), Vector2(0.011, 0.03)]

const RUBBER := Color(0.04, 0.04, 0.045)

# --- Tuning: Wasser -----------------------------------------------------------------
const RUN_TIME := 25.0          ## so lange läuft das Wasser nach einem Druck (Selbstschluss)
const PRESS_DEPTH := 0.006      ## so tief geht der Knopf hinein …
const PRESS_TIME := 0.3         ## … und kommt so schnell zurück
const WATER_FADE := 4.0         ## Wasser an und aus: Anteil je Sekunde
const WATER_RANGE := 8.0        ## Hörweite des Rauschens für den Spieler (m, gedämpft durch Wände)
const WATER_VOLUME := 0.5
const NOISE_EVERY := 3.0        ## so oft Lärm „shower“, solange es läuft
## Strahl: feine Striche (shaders/rain_streak.gdshader) aus der Düsenplatte bis zum Boden
const JETS := 180
const JET_SPEED := 2.6          ## m/s beim Austritt
const JET_COLOR := Color(0.78, 0.82, 0.88, 0.45)
const JET_STREAK := Vector2(0.16, 0.0012)   ## Länge, Breite (m)
## Dampf: weiche Ballen, die erst nach STEAM_WARMUP dicht werden (warmes Wasser)
const STEAM := 18
const STEAM_LIFE := 6.0
const STEAM_SIZE := 0.9
const STEAM_COLOR := Color(0.92, 0.93, 0.95, 0.07)
const STEAM_WARMUP := 6.0

static var _nozzles: ShaderMaterial
static var _arm: ArrayMesh
static var _plate: ArrayMesh
static var _jet_mat: ShaderMaterial
static var _steam_mat: StandardMaterial3D
static var _drain_mat: StandardMaterial3D
## Rauschen aller Duschplätze: id → [Pegel, dumpf]; der lauteste bestimmt SynthAudio.pool_shower
static var _sounds := {}

var _builder: LevelBuilder
var _knob: MeshInstance3D
var _jet: CPUParticles3D
var _steam: CPUParticles3D
var _left := 0.0                ## Restlaufzeit
var _water := 0.0               ## 0..1, weich an und aus
var _warm := 0.0                ## Sekunden seit Wasser an (Dampf)
var _press := 0.0               ## 1 = Knopf ganz drin
var _noise_timer := 0.0
var _sound_timer := 0.0
var _heard := 0.0
var _muffle := 1.0


func setup(builder: LevelBuilder) -> PoolShower:
	_builder = builder
	return self


## Debug --duschen[=an]: vor den ersten Duschplatz (von Westen), Blick zur Wand – an: das Wasser läuft.
static func debug_show(tree: SceneTree, on: bool) -> void:
	var first: PoolShower = null
	for s: PoolShower in tree.get_nodes_in_group("pool_showers"):
		if first == null or s.global_position.x < first.global_position.x:
			first = s
	if first == null:
		push_warning("--duschen: kein Duschplatz im Plan")
		return
	var out := first.global_basis.z
	TeleportUI.place_player(first.global_position + out * 1.6, -out)
	if on:
		first.press()


## Bodenablauf auf dem Boden bei pos (Mitte): Platte aus Edelstahl, darüber die Löcher als Textur.
static func drain(pos: Vector3) -> Node3D:
	var node := Node3D.new()
	node.position = pos
	Geo.mesh(node, Geo.rounded_box(Vector3(DRAIN, DRAIN_H, DRAIN), 0.0015, 1), Mat.metal(), Vector3(0, DRAIN_H / 2.0, 0))
	var quad := PlaneMesh.new()
	quad.size = Vector2(DRAIN, DRAIN)
	var holes := Geo.mesh(node, quad, _drain_material(), Vector3(0, DRAIN_H + 0.0004, 0))
	holes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return node


func _ready() -> void:
	add_to_group("pool_showers")
	var steel := Mat.metal()
	# Drücker: Manschette mit Hülse, dunkler Dichtring, Knopf; ein Körper zum Ansehen und Drücken
	var base := Geo.mesh(self, Geo.lathe(BASE_PROFILE, 32), steel, Vector3(0, BUTTON_Y, 0))
	base.rotation.x = PI / 2.0   # Drehachse aus der Wand (+Y → +Z)
	var ring := Geo.mesh(self, Geo.lathe(RUBBER_PROFILE, 32), Mat.psx(RUBBER), Vector3(0, BUTTON_Y, 0))
	ring.rotation.x = PI / 2.0
	_knob = Geo.mesh(self, Geo.lathe(KNOB_PROFILE, 32), steel, Vector3(0, BUTTON_Y, 0))
	_knob.rotation.x = PI / 2.0
	var body := StaticBody3D.new()
	body.collision_layer = 4
	body.collision_mask = 0
	body.set_meta("interactable", self)
	add_child(body)
	Geo.add_box_shape(body, Vector3(0.16, 0.16, 0.1), Vector3(0, BUTTON_Y, 0.05))
	_shelf(steel, Vector3(0.07 + SHELF_GAP + SHELF_SIZE.x / 2.0, BUTTON_Y - SHELF_SIZE.y / 2.0, 0))
	# Duschkopf: Rosette an der Wand, Arm mit Bogen nach unten, Kugelgelenk, Kopf mit Düsenplatte
	var rosette := Geo.mesh(self, Geo.lathe(ROSETTE_PROFILE, 24), steel, Vector3(0, ARM_Y, 0))
	rosette.rotation.x = PI / 2.0
	Geo.mesh(self, _arm_mesh(), steel, Vector3.ZERO)
	Geo.mesh(self, Geo.sphere(JOINT_R, JOINT_R * 2.0, 16, 8), steel, Vector3(0, HEAD_Y + 0.03 + JOINT_R * 0.6, HEAD_REACH))
	Geo.mesh(self, Geo.lathe(HEAD_PROFILE, 48), steel, Vector3(0, HEAD_Y, HEAD_REACH))
	Geo.mesh(self, _plate_mesh(), _nozzle_material(), Vector3(0, HEAD_Y, HEAD_REACH))
	_build_water()
	set_process(false)


func get_prompt(_player: Player) -> String:
	return "Duschknopf drücken [E]" + ("  – das Wasser läuft" if _left > 0.0 else "")


func interact(_player: Player) -> void:
	press()


## Knopf drücken: Wasser läuft (wieder) RUN_TIME Sekunden.
func press() -> void:
	_left = RUN_TIME
	_press = 1.0
	if _noise_timer <= 0.0:
		_noise_timer = 0.01   # gleich der erste Lärm
	Game.noise("shower_button", to_global(Vector3(0, BUTTON_Y, 0.08)))
	set_process(true)


func running() -> bool:
	return _left > 0.0


func _process(delta: float) -> void:
	_left = maxf(_left - delta, 0.0)
	_press = maxf(_press - delta / PRESS_TIME, 0.0)
	_knob.position.z = -PRESS_DEPTH * _press
	_water = move_toward(_water, 1.0 if _left > 0.0 else 0.0, delta * WATER_FADE)
	_warm = _warm + delta if _left > 0.0 else maxf(minf(_warm, STEAM_WARMUP) - delta * 2.0, 0.0)
	_jet.emitting = _left > 0.0
	_steam.emitting = _left > 0.0 and _warm > STEAM_WARMUP * 0.3
	_steam.color.a = STEAM_COLOR.a * clampf(_warm / STEAM_WARMUP, 0.0, 1.0)   # wird mit dem warmen Wasser dichter
	if _left > 0.0:
		_noise_timer -= delta
		if _noise_timer <= 0.0:
			_noise_timer = NOISE_EVERY
			Game.noise("shower", to_global(Vector3(0, 1.0, HEAD_REACH)))
	_update_sound(delta)
	if _left <= 0.0 and _water <= 0.0 and _press <= 0.0 and _warm <= 0.0:
		_noise_timer = 0.0
		_sounds.erase(get_instance_id())
		_mix_sounds()
		set_process(false)


## Rauschen: alle 0,25 s, wie laut der Spieler es hier hört; dumpf, wenn er nicht im selben Raum steht.
func _update_sound(delta: float) -> void:
	_sound_timer -= delta
	if _sound_timer <= 0.0:
		_sound_timer = 0.25
		var at := to_global(Vector3(0, 0.3, HEAD_REACH))
		_heard = Game.hearing(at, WATER_RANGE)
		if _builder and Game.player:
			_muffle = 0.0 if _builder.room_at(Game.player.global_position) == _builder.room_at(at) else 1.0
	_sounds[get_instance_id()] = [_heard * _water * WATER_VOLUME, _muffle]
	_mix_sounds()


static func _mix_sounds() -> void:
	if Game.audio == null:
		return
	var level := 0.0
	var muffle := 1.0
	for s: Array in _sounds.values():
		if s[0] > level:
			level = s[0]
			muffle = s[1]
	Game.audio.pool_shower = level
	Game.audio.pool_shower_muffle = muffle


func _exit_tree() -> void:
	_sounds.erase(get_instance_id())
	_mix_sounds()


## Strahl aus der Düsenplatte und Dampf darunter (beide aus, bis gedrückt wird).
func _build_water() -> void:
	if _jet_mat == null:
		_jet_mat = ShaderMaterial.new()
		_jet_mat.shader = load("res://shaders/rain_streak.gdshader")
		_jet_mat.set_shader_parameter("color", JET_COLOR)
		_jet_mat.set_shader_parameter("fall", Vector3(0, -1, 0))
		_jet_mat.set_shader_parameter("streak_length", JET_STREAK.x)
		_jet_mat.set_shader_parameter("streak_width", JET_STREAK.y)
		_jet_mat.set_shader_parameter("min_pixels", 1.2)
		_jet_mat.set_shader_parameter("near_fade", 0.3)
	_jet = CPUParticles3D.new()
	_jet.amount = JETS
	_jet.lifetime = _fall_time()
	_jet.local_coords = false
	_jet.mesh = QuadMesh.new()   # 1 × 1, der Shader streckt ihn
	_jet.material_override = _jet_mat
	_jet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_jet.emission_shape = CPUParticles3D.EMISSION_SHAPE_POINTS   # Düsen gleichmäßig über die Platte
	var points := PackedVector3Array()
	for k in 64:
		var r := HEAD_R * 0.85 * sqrt((k + 0.5) / 64.0)
		var a := k * 2.39996   # goldener Winkel
		points.append(Vector3(cos(a) * r, 0, sin(a) * r))
	_jet.emission_points = points
	_jet.direction = Vector3.DOWN
	_jet.spread = 4.0
	_jet.initial_velocity_min = JET_SPEED * 0.9
	_jet.initial_velocity_max = JET_SPEED * 1.1
	_jet.gravity = Vector3(0, -9.8, 0)
	_jet.position = Vector3(0, HEAD_Y - 0.005, HEAD_REACH)
	_jet.emitting = false
	add_child(_jet)
	if _steam_mat == null:
		var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
		for y in 32:
			for x in 32:
				var d := Vector2(x - 15.5, y - 15.5).length() / 16.0
				img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d, 0.0, 1.0) ** 2.0))
		_steam_mat = StandardMaterial3D.new()
		_steam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_steam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_steam_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		_steam_mat.vertex_color_use_as_albedo = true
		_steam_mat.albedo_texture = ImageTexture.create_from_image(img)
	_steam = Geo.particles(STEAM, STEAM_LIFE, STEAM_SIZE, _steam_mat, 0.3, 0.4)
	_steam.color = STEAM_COLOR
	_steam.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_steam.emission_box_extents = Vector3(0.3, 0.6, 0.3)
	_steam.position = Vector3(0, 1.3, HEAD_REACH)
	_steam.direction = Vector3.UP
	_steam.spread = 30.0
	_steam.initial_velocity_min = 0.1
	_steam.initial_velocity_max = 0.25
	_steam.gravity = Vector3.ZERO
	_steam.damping_min = 0.02
	_steam.damping_max = 0.05
	_steam.scale_amount_min = 0.7
	_steam.scale_amount_max = 1.8
	_steam.emitting = false
	add_child(_steam)


## Fallzeit vom Kopf bis zum Boden (dort endet der Strahl).
static func _fall_time() -> float:
	return (-JET_SPEED + sqrt(JET_SPEED * JET_SPEED + 2.0 * 9.8 * HEAD_Y)) / 9.8


## Löcher des Bodenablaufs: DRAIN_HOLES² dunkle Quadrate, sonst durchsichtig (Platte darunter); mit Mipmaps, damit es
## in der Ferne zu einem dunkleren Feld verschwimmt statt zu flimmern.
static func _drain_material() -> StandardMaterial3D:
	if _drain_mat == null:
		var size := 256
		var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var margin := 22
		var pitch := float(size - 2 * margin) / DRAIN_HOLES
		var hole := int(pitch * 0.55)
		for i in DRAIN_HOLES:
			for j in DRAIN_HOLES:
				var x := margin + int(pitch * (i + 0.5)) - hole / 2
				var y := margin + int(pitch * (j + 0.5)) - hole / 2
				img.fill_rect(Rect2i(x, y, hole, hole), Color(0.02, 0.02, 0.022, 1))
		img.generate_mipmaps()
		_drain_mat = StandardMaterial3D.new()
		_drain_mat.albedo_texture = ImageTexture.create_from_image(img)
		_drain_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_drain_mat.roughness = 0.9
		_drain_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return _drain_mat


## Ablage (Bild: flache Schale mit Rand), base = Mitte der Unterkante an der Wand: Rückenplatte, Boden etwas über der
## Unterkante, ringsum der Rand. Die Halterung darunter entfällt.
func _shelf(steel: Material, base: Vector3) -> void:
	var s := SHELF_SIZE
	var e := SHELF_EDGE
	var parts := [
		[Vector3(s.x, 0.05, 0.006), Vector3(0, 0.025, 0.003)],   # Rückenplatte, höher als der Rand
		[Vector3(s.x - 2.0 * e, 0.004, s.z - e), Vector3(0, 0.008, (s.z - e) / 2.0)],   # Boden
		[Vector3(s.x, s.y, e), Vector3(0, s.y / 2.0, s.z - e / 2.0)],   # vorn
		[Vector3(e, s.y, s.z), Vector3(-(s.x - e) / 2.0, s.y / 2.0, s.z / 2.0)],
		[Vector3(e, s.y, s.z), Vector3((s.x - e) / 2.0, s.y / 2.0, s.z / 2.0)],
	]
	for p in parts:
		Geo.mesh(self, Geo.rounded_box(p[0], 0.003, 2), steel, base + p[1])


## Wandarm als Rohr: waagerecht aus der Wand, im Bogen nach unten bis über das Kugelgelenk.
static func _arm_mesh() -> ArrayMesh:
	if _arm == null:
		var path: Array[Vector3] = [Vector3(0, ARM_Y, 0.005)]
		for k in 9:
			var t := PI / 2.0 * k / 8.0
			path.append(Vector3(0, ARM_Y - ARM_BEND + ARM_BEND * cos(t), HEAD_REACH - ARM_BEND + ARM_BEND * sin(t)))
		path.append(Vector3(0, HEAD_Y + 0.03 + JOINT_R * 1.2, HEAD_REACH))
		_arm = _tube(path, ARM_R, 16)
	return _arm


## Rohr entlang path in der YZ-Ebene (der Querschnitt dreht um X), offene Enden.
static func _tube(path: Array[Vector3], radius: float, sides: int) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for i in path.size():
		var a := path[maxi(i - 1, 0)]
		var b := path[mini(i + 1, path.size() - 1)]
		var v := (b - a).normalized().cross(Vector3.RIGHT)
		for j in sides + 1:
			var phi := TAU * j / sides
			var n := Vector3.RIGHT * cos(phi) + v * sin(phi)
			verts.append(path[i] + n * radius)
			normals.append(n)
	for i in path.size() - 1:
		for j in sides:
			var q := i * (sides + 1) + j
			_tri(indices, verts, normals, q, q + 1, q + sides + 2)
			_tri(indices, verts, normals, q, q + sides + 2, q + sides + 1)
	return Geo.add_surface(ArrayMesh.new(), verts, normals, indices)


## Düsenplatte: Scheibe unter dem Kopf, Normale nach unten; die Textur der Zimmerdusche einmal über den Durchmesser.
static func _plate_mesh() -> ArrayMesh:
	if _plate == null:
		var r := HEAD_R - 0.005
		var sides := 48
		var verts := PackedVector3Array([Vector3(0, -0.0005, 0)])
		var normals := PackedVector3Array([Vector3.DOWN])
		var uvs := PackedVector2Array([Vector2(0.5, 0.5)])
		var indices := PackedInt32Array()
		for j in sides + 1:
			var d := Vector3(cos(TAU * j / sides), 0, sin(TAU * j / sides))
			verts.append(d * r + Vector3(0, -0.0005, 0))
			normals.append(Vector3.DOWN)
			uvs.append(Vector2(0.5 + d.x / 2.0, 0.5 + d.z / 2.0))
		for j in sides:
			_tri(indices, verts, normals, 0, j + 1, j + 2)
		_plate = Geo.add_surface(ArrayMesh.new(), verts, normals, indices, uvs)
	return _plate


## Dreieck a, b, c mit der Vorderseite in Richtung der Normalen (Godot: im Uhrzeigersinn von vorn).
static func _tri(indices: PackedInt32Array, verts: PackedVector3Array, normals: PackedVector3Array, a: int, b: int, c: int) -> void:
	var n := normals[a] + normals[b] + normals[c]
	if (verts[b] - verts[a]).cross(verts[c] - verts[a]).dot(n) > 0.0:
		indices.append_array([a, c, b])
	else:
		indices.append_array([a, b, c])


static func _nozzle_material() -> ShaderMaterial:
	if _nozzles == null:
		_nozzles = Mat.psx(Color(0.85, 0.86, 0.88), "", 1.0, Color.BLACK, 0.0, false)
		_nozzles.set_shader_parameter("albedo_tex", load(NOZZLES))
	return _nozzles
