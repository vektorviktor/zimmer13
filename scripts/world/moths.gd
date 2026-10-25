class_name Moths
extends Node3D
## Motten (Spielkonzept 4.25). Um brennende Lampen in der Nähe des Spielers taumeln ein paar Motten – reine
## Stimmung, auf einem MultiMesh (shaders/psx_bird.gdshader, matt).

const AMBIENT := 8                    ## Motten insgesamt
const PER_LAMP := 3
const LAMP_RANGE := 14.0              ## brennende Lampen so nah beim Spieler bekommen Motten
const LAMP_CHECK := 1.5
const ORBIT := Vector2(0.18, 0.5)     ## so weit um die Lampe
const SPEED := 1.6
const JITTER := 2.5
const FLAP_RATE := 24.0

var _builder: LevelBuilder
var _mm: MultiMesh
var _pos := PackedVector3Array()
var _vel := PackedVector3Array()
var _anchor: Array[Node3D] = []       ## Lampe, um die die Motte kreist (null = unterwegs zur nächsten)
var _flap := PackedFloat32Array()
var _lamp_t := 0.0


func setup(builder: LevelBuilder) -> void:
	_builder = builder
	_build_ambient()


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



func _physics_process(delta: float) -> void:
	_lamp_t -= delta
	if _lamp_t <= 0.0:
		_lamp_t = LAMP_CHECK
		_assign_lamps()
	for i in AMBIENT:
		_step(i, delta)


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
