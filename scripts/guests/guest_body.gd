class_name GuestBody
extends Node3D
## Gastmodell aus einem Grundkörper (Spielkonzept 6.0, „Gastmodelle“): Meshy-Figur mit Mixamo-Skelett,
## gebaut von tools/build_guest.py. Je Gast verschieden: Größe, Schulterbreite, Körperbau
## (Formschlüssel „build“), die Farben von Oberteil, Hose und Haaren und der Hautton (psx_guest.gdshader).
##
## Bewegung: Gehen, Rennen und die Tänze (Mixamo, umgerechnet von tools/build_guest.py) kommen aus
## der GLB, alles andere aus den Arm-Pivots des Gastes – die Posen in Guest (Tragen, Panik, Sitzen)
## drehen weiter nur _arm_l/_arm_r, hier zielen die Oberarmknochen in dieselbe Richtung.

## Grundkörper. Werte gibt tools/build_guest.py aus (Höhe und Schulterbreite in m, Laufweite der
## Animationen in m/s, mittlere Helligkeit der Färbebereiche). Kinderkörper (Spielkonzept 6.13) haben
## "age" – sie gehen nur an Kinder, die übrigen nur an Erwachsene, nach der Generation des Vornamens
## ("gen", GuestGenerator.generation).
const BODIES := {
	"man": {
		"path": "res://assets/models/guest_man.glb", "sex": "m", "gen": "mid",
		"height": 1.700, "width": 0.433, "walk": 1.40, "run": 2.44, "ref": Vector3(0.383, 0.125, 0.199),
	},
	"woman": {
		"path": "res://assets/models/guest_woman.glb", "sex": "f", "gen": "mid",
		"height": 1.650, "width": 0.398, "walk": 1.42, "run": 2.48, "ref": Vector3(0.410, 0.035, 0.148),
	},
	"man_young": {
		"path": "res://assets/models/guest_man_young.glb", "sex": "m", "gen": "young",
		"height": 1.650, "width": 0.409, "walk": 1.44, "run": 2.55, "ref": Vector3(0.533, 0.049, 0.089),
	},
	"man_old": {
		"path": "res://assets/models/guest_man_old.glb", "sex": "m", "gen": "old",
		"height": 1.640, "width": 0.444, "walk": 1.53, "run": 2.64, "ref": Vector3(0.432, 0.050, 0.324),
	},
	"woman_young": {
		"path": "res://assets/models/guest_woman_young.glb", "sex": "f", "gen": "young",
		"height": 1.700, "width": 0.392, "walk": 1.49, "run": 2.62, "ref": Vector3(0.518, 0.046, 0.024),
	},
	"woman_old": {
		"path": "res://assets/models/guest_woman_old.glb", "sex": "f", "gen": "old",
		"height": 1.640, "width": 0.418, "walk": 1.42, "run": 2.49, "ref": Vector3(0.354, 0.052, 0.248),
	},
	"girl7": {
		"path": "res://assets/models/guest_girl7.glb", "sex": "f", "age": 7,
		"height": 1.690, "width": 0.371, "walk": 1.45, "run": 2.56, "ref": Vector3(0.438, 0.147, 0.098),
	},
	"girl10": {
		"path": "res://assets/models/guest_girl10.glb", "sex": "f", "age": 10,
		"height": 1.640, "width": 0.394, "walk": 1.46, "run": 2.55, "ref": Vector3(0.416, 0.080, 0.047),
	},
	"boy7": {
		"path": "res://assets/models/guest_boy7.glb", "sex": "m", "age": 7,
		"height": 1.690, "width": 0.393, "walk": 1.31, "run": 2.31, "ref": Vector3(0.404, 0.132, 0.078),
	},
	"boy10": {
		"path": "res://assets/models/guest_boy10.glb", "sex": "m", "age": 10,
		"height": 1.650, "width": 0.400, "walk": 1.47, "run": 2.53, "ref": Vector3(0.366, 0.126, 0.116),
	},
}
## Generationen der Erwachsenenkörper in Altersfolge (fehlt eine, nimmt pick() die nächste)
const GENERATIONS := ["young", "mid", "old"]
## Breite wird nur so weit gestreckt (sonst sieht man es an Armen und Beinen)
const WIDTH_LIMIT := Vector2(0.88, 1.15)
## Sitzen: so tief sinkt die Hüfte, bis die Oberschenkel waagerecht liegen (Anteil der Körpergröße)
const SIT_DROP := 0.27
const ARMS := [["LeftArm", "LeftForeArm"], ["RightArm", "RightForeArm"]]
const LEGS := [["LeftUpLeg", "LeftLeg", "LeftFoot"], ["RightUpLeg", "RightLeg", "RightFoot"]]
## Tänze bei Feiern (Spielkonzept 7.1) – Animationen in jeder Gast-GLB (assets/source/anim/<name>.fbx)
const DANCES := ["dance_chicken", "dance_macarena", "dance_hiphop"]

static var _scenes := {}
static var _material: Dictionary = {}
static var _skin: Dictionary = {}   ## mittlere Textur-Haut je Grundkörper (_skin_ref)

var body_id := ""
var _skeleton: Skeleton3D
var _player: AnimationPlayer
var _mesh: MeshInstance3D
var _bone := {}
var _info: Dictionary
var _scale := 1.0
var _width := 1.0
var _head := 1.0           ## Kopfgröße (Kinder größer, Spielkonzept 6.13)
var _breath := 0.0
var head_shrink := 1.0   ## unter dem Bettlaken-Kostüm kleiner, damit er nicht durch den Stoff sticht (Costume)
var dance := ""   ## Name aus DANCES, solange der Gast tanzt (setzt Guest._dance_pose)


## Grundkörper für einen Gast – "" = keiner passt (dann bleibt die Klötzchenfigur). Feste Gäste
## bekommen später eigene Modelle. Erwachsene den Körper ihrer Generation (fehlt er, den der nächsten),
## bei mehreren reihum nach der Gastnummer, nicht zufällig, damit sich keiner häuft; Kinder den
## Kinderkörper, der ihrem Alter am nächsten ist.
static func pick(profile: Dictionary, guest_id: String) -> String:
	if not profile.get("generated", false):
		return ""
	var child: bool = profile.get("child", false)
	var fits: Array = []
	for key in BODIES:
		if BODIES[key]["sex"] == profile.get("sex", "") and BODIES[key].has("age") == child:
			fits.append(key)
	if fits.is_empty():
		return ""
	fits.sort()
	if child:
		var age := int(profile.get("age", 8))
		fits.sort_custom(func(a: String, b: String) -> bool:
			return absi(int(BODIES[a]["age"]) - age) < absi(int(BODIES[b]["age"]) - age))
		return fits[0]
	var gen := GENERATIONS.find(String(profile.get("gen", "mid")))
	var gap := func(key: String) -> int: return absi(GENERATIONS.find(String(BODIES[key].get("gen", "mid"))) - gen)
	var best: int = fits.map(gap).min()
	fits = fits.filter(func(key: String) -> bool: return gap.call(key) == best)
	return fits[int(guest_id.trim_prefix("gast")) % fits.size()]


func setup(id: String, profile: Dictionary) -> void:
	body_id = id
	_info = BODIES[id]
	var path: String = _info["path"]
	if not _scenes.has(path):
		_scenes[path] = load(path)
	var model: Node3D = (_scenes[path] as PackedScene).instantiate()
	add_child(model)
	_skeleton = model.find_children("*", "Skeleton3D", true, false)[0]
	_player = model.find_children("*", "AnimationPlayer", true, false)[0]
	_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	for anim in ["walk", "run"] + DANCES:
		_player.get_animation(anim).loop_mode = Animation.LOOP_LINEAR
	for i in _skeleton.get_bone_count():
		_bone[_skeleton.get_bone_name(i)] = i
	_mesh = model.find_children("*", "MeshInstance3D", true, false)[0]
	_mesh.material_override = _material_for(_info, _mesh)
	# Color rechnet Godot bei Instanz-Uniforms selbst nach linear um – hier nicht noch einmal (sonst zu dunkel und satt)
	_mesh.set_instance_shader_parameter("tint_top", profile["coat"])
	_mesh.set_instance_shader_parameter("tint_bottom", profile["pants"])
	_mesh.set_instance_shader_parameter("tint_hair", profile["hair"])
	if profile.has("skin"):
		# Faktor als Vector3 (wird nicht umgerechnet): Zielton / mittlere Haut der Textur, beides linear
		var target := (profile["skin"] as Color).srgb_to_linear()
		var ref: Color = _skin[path]
		_mesh.set_instance_shader_parameter("tint_skin", Vector3(target.r / ref.r, target.g / ref.g, target.b / ref.b))
	var shape := _mesh.find_blend_shape_by_name("build")
	if shape >= 0:
		_mesh.set_blend_shape_value(shape, float(profile.get("build", 0.0)))
	_scale = float(profile.get("height_cm", _info["height"] * 100.0)) / 100.0 / float(_info["height"])
	_width = clampf(float(profile.get("width_cm", _info["width"] * 100.0)) / 100.0 / (float(_info["width"]) * _scale),
		WIDTH_LIMIT.x, WIDTH_LIMIT.y)
	scale = Vector3(_scale * _width, _scale, _scale)
	# Kinderkörper haben schon Kinderproportionen – nur Erwachsenenkörper als Ersatz bekämen den großen Kopf
	_head = 1.0 if _info.has("age") else float(profile.get("head", 1.0))
	_breath = randf() * TAU


## Ein Material je Grundkörper (Textur und Färbebereiche gleich, die Farben sind Instanz-Uniforms).
static func _material_for(info: Dictionary, mesh: MeshInstance3D) -> ShaderMaterial:
	var path: String = info["path"]
	if not _material.has(path):
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/psx_guest.gdshader")
		m.set_shader_parameter("albedo_tex", (mesh.get_active_material(0) as BaseMaterial3D).albedo_texture)
		m.set_shader_parameter("ref_lum", info["ref"])
		_material[path] = m
		_skin[path] = _skin_ref(m.get_shader_parameter("albedo_tex"))
	return _material[path]


## Mittlere Hautfarbe (linear) der Textur – wie die Hauterkennung in psx_guest.gdshader (rot > grün > blau,
## mäßig gesättigt, kein Gelb), nur helle Texel, damit Brauen, Lippen und Schuhe nicht mitzählen.
static func _skin_ref(tex: Texture2D) -> Color:
	var img := tex.get_image()
	if img.is_compressed():
		img.decompress()
	img.resize(128, 128, Image.INTERPOLATE_NEAREST)
	var sum := Color(0, 0, 0)
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y).srgb_to_linear()
			var lum := 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
			var sat := maxf(c.r, maxf(c.g, c.b)) - minf(c.r, minf(c.g, c.b))
			if c.r >= c.g and c.g >= c.b and sat > 0.08 and lum > 0.15 and (c.g - c.b) / maxf(c.r - c.b, 0.001) < 0.75:
				sum += c
				n += 1
	return Color(0.5, 0.35, 0.3) if n == 0 else Color(sum.r / n, sum.g / n, sum.b / n)


## Kopfknochen in Weltkoordinaten – Hut und Kürbis des Kostüms sitzen darauf (Costume.follow)
func head_origin() -> Vector3:
	return (_skeleton.global_transform * _skeleton.get_bone_global_pose(_bone["Head"])).origin


## Knoten, der dem Knochen folgt (Verletzungsmarken, Spielkonzept 6.17) – null, wenn es den Knochen nicht gibt.
func attach(bone_name: String) -> Node3D:
	if not _bone.has(bone_name):
		return null
	var at := BoneAttachment3D.new()
	at.bone_idx = _bone[bone_name]
	_skeleton.add_child(at)
	var holder := Node3D.new()
	# Marken in Metern: Maßstab des Skeletts ausgleichen (manche Modelle sind intern in Zentimetern, dazu die Größe des Gasts)
	var s := _skeleton.global_basis.get_scale() if _skeleton.is_inside_tree() else Vector3.ONE * _scale
	holder.scale = Vector3(1.0 / maxf(s.x, 0.0001), 1.0 / maxf(s.y, 0.0001), 1.0 / maxf(s.z, 0.0001))
	at.add_child(holder)
	return holder


## Wie tief die Figur beim Sitzen sinkt (m)
func sit_drop() -> float:
	return SIT_DROP * float(_info["height"]) * _scale


## Pro Frame aus Guest._animate. arms: die Arm-Pivots des Gastes (rotation = Pose, (0,0,0) = Arm hängt);
## arms_free = die Animation darf die Arme schwingen.
func animate(delta: float, speed: float, running: bool, arms: Array, arms_free: bool, sitting: bool) -> void:
	if speed > 0.1 and not sitting:
		var anim := "run" if running else "walk"
		if _player.current_animation != anim:
			_player.play(anim)
		_player.advance(delta * speed / (float(_info[anim]) * _scale))
	elif dance != "":
		if _player.current_animation != dance:
			_player.play(dance)
			_player.seek(randf() * _player.current_animation_length, true)   # nicht alle im Gleichtakt
		_player.advance(delta)
	else:
		if _player.is_playing():
			_player.stop()
		_skeleton.reset_bone_poses()
		# Atmen, sonst stünde die Figur starr
		_breath += delta * 1.6
		_turn("Spine1", Vector3.RIGHT, sin(_breath) * 0.02)
	# Der Kopf bleibt schmal, wenn der Körper breiter wird – bei Kindern ist er größer
	_skeleton.set_bone_pose_scale(_bone["Head"], Vector3(_head / _width, _head, _head) * head_shrink)
	if sitting:
		for leg in LEGS:
			_aim(leg[0], leg[1], Vector3(0, -0.15, -1))
			_aim(leg[1], leg[2], Vector3(0, -1, 0.1))
	if not arms_free and dance == "":
		for i in 2:
			var pivot: Node3D = arms[i]
			var dir := pivot.basis * Vector3.DOWN
			dir.z = -dir.z   # die Posen in Guest drehen mit −x nach vorn (Blick −Z)
			_skeleton.set_bone_pose_rotation(_bone[ARMS[i][1]], _skeleton.get_bone_rest(_bone[ARMS[i][1]]).basis.get_rotation_quaternion())
			_aim(ARMS[i][0], ARMS[i][1], dir)


## Dreht einen Knochen so, dass er (zum Kindknochen hin) in Richtung dir zeigt – dir im Raum dieses
## Knotens (vor der Breitenstreckung), also wie die Pivots des Gastes.
func _aim(bone_name: String, child_name: String, dir: Vector3) -> void:
	var bone: int = _bone[bone_name]
	var to_skel := (_skeleton.global_transform.affine_inverse() * global_transform).basis.orthonormalized()
	var want := (to_skel * dir).normalized()
	var pose := _skeleton.get_bone_global_pose(bone)
	var cur := (_skeleton.get_bone_global_pose(_bone[child_name]).origin - pose.origin).normalized()
	# Null-Richtungen (entarteter Knochen) und (fast) parallele ergäben einen kaputten Quaternion (NaN)
	if not cur.is_normalized() or not want.is_normalized() or absf(cur.dot(want)) > 0.9999:
		return
	var turned := Basis(Quaternion(cur, want)) * pose.basis
	var parent := _skeleton.get_bone_parent(bone)
	var parent_basis := _skeleton.get_bone_global_pose(parent).basis if parent >= 0 else Basis()
	_skeleton.set_bone_pose_rotation(bone, (parent_basis.inverse() * turned).get_rotation_quaternion())


func _turn(bone_name: String, axis: Vector3, angle: float) -> void:
	var bone: int = _bone[bone_name]
	_skeleton.set_bone_pose_rotation(bone, _skeleton.get_bone_pose_rotation(bone) * Quaternion(axis, angle))
