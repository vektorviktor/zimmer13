class_name GuestBody
extends Node3D
## Gastmodell aus einem Grundkörper (Spielkonzept 6.0, „Gastmodelle“): Meshy-Figur mit Mixamo-Skelett,
## gebaut von tools/build_guest.py. Je Gast verschieden: Größe, Schulterbreite, Körperbau
## (Formschlüssel „build“) und die Farben von Oberteil, Hose und Haaren (psx_guest.gdshader).
##
## Bewegung: Gehen, Rennen und die Tänze (Mixamo, umgerechnet von tools/build_guest.py) kommen aus
## der GLB, alles andere aus den Arm-Pivots des Gastes – die Posen in Guest (Tragen, Panik, Sitzen)
## drehen weiter nur _arm_l/_arm_r, hier zielen die Oberarmknochen in dieselbe Richtung.

## Grundkörper. Werte gibt tools/build_guest.py aus (Höhe und Schulterbreite in m, Laufweite der
## Animationen in m/s, mittlere Helligkeit der Färbebereiche).
const BODIES := {
	"man": {
		"path": "res://assets/models/guest_man.glb", "sex": "m",
		"height": 1.700, "width": 0.433, "walk": 1.40, "run": 2.44, "ref": Vector3(0.383, 0.125, 0.200),
	},
}
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

var body_id := ""
var _skeleton: Skeleton3D
var _player: AnimationPlayer
var _mesh: MeshInstance3D
var _bone := {}
var _info: Dictionary
var _scale := 1.0
var _width := 1.0
var _breath := 0.0
var dance := ""   ## Name aus DANCES, solange der Gast tanzt (setzt Guest._dance_pose)


## Grundkörper für einen Gast – "" = keiner passt (dann bleibt die Klötzchenfigur). Feste Gäste
## bekommen später eigene Modelle. Verteilt wird reihum nach der Gastnummer, nicht zufällig, damit
## sich kein Körper häuft.
static func pick(profile: Dictionary, guest_id: String) -> String:
	if not profile.get("generated", false):
		return ""
	var fits: Array = []
	for key in BODIES:
		if BODIES[key]["sex"] == profile.get("sex", ""):
			fits.append(key)
	if fits.is_empty():
		return ""
	fits.sort()
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
	_mesh.material_override = _material_for(path, _mesh)
	_mesh.set_instance_shader_parameter("tint_top", (profile["coat"] as Color).srgb_to_linear())
	_mesh.set_instance_shader_parameter("tint_bottom", (profile["pants"] as Color).srgb_to_linear())
	_mesh.set_instance_shader_parameter("tint_hair", (profile["hair"] as Color).srgb_to_linear())
	var shape := _mesh.find_blend_shape_by_name("build")
	if shape >= 0:
		_mesh.set_blend_shape_value(shape, float(profile.get("build", 0.0)))
	_scale = float(profile.get("height_cm", _info["height"] * 100.0)) / 100.0 / float(_info["height"])
	_width = clampf(float(profile.get("width_cm", _info["width"] * 100.0)) / 100.0 / (float(_info["width"]) * _scale),
		WIDTH_LIMIT.x, WIDTH_LIMIT.y)
	scale = Vector3(_scale * _width, _scale, _scale)
	_breath = randf() * TAU


static func _material_for(path: String, mesh: MeshInstance3D) -> ShaderMaterial:
	if not _material.has(path):
		var info: Dictionary
		for key in BODIES:
			if BODIES[key]["path"] == path:
				info = BODIES[key]
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/psx_guest.gdshader")
		m.set_shader_parameter("albedo_tex", (mesh.get_active_material(0) as BaseMaterial3D).albedo_texture)
		m.set_shader_parameter("ref_lum", info["ref"])
		_material[path] = m
	return _material[path]


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
	# Der Kopf bleibt schmal, wenn der Körper breiter wird
	_skeleton.set_bone_pose_scale(_bone["Head"], Vector3(1.0 / _width, 1.0, 1.0))
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
	if cur.dot(want) > 0.9999 or cur.dot(want) < -0.9999:
		return
	var turned := Basis(Quaternion(cur, want)) * pose.basis
	var parent := _skeleton.get_bone_parent(bone)
	var parent_basis := _skeleton.get_bone_global_pose(parent).basis if parent >= 0 else Basis()
	_skeleton.set_bone_pose_rotation(bone, (parent_basis.inverse() * turned).get_rotation_quaternion())


func _turn(bone_name: String, axis: Vector3, angle: float) -> void:
	var bone: int = _bone[bone_name]
	_skeleton.set_bone_pose_rotation(bone, _skeleton.get_bone_pose_rotation(bone) * Quaternion(axis, angle))
