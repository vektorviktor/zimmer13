class_name Mirror
extends MeshInstance3D
## Spiegel mit echtem Spiegelbild (Aufzug, Waschbecken – Spielkonzept 7.10, 3.9): Eine zweite Kamera steht am
## Spiegelpunkt der Spielerkamera und schaut mit schiefem Frustum genau durch die Spiegelfläche (`set_frustum`,
## near = Abstand zur Ebene – was hinter dem Spiegel liegt, fällt weg); ihr Bild malt sie in ein SubViewport,
## shaders/mirror_view.gdshader zeigt es auf der Fläche. Gerendert wird nur, wenn der Spiegel im Bild, nah genug,
## auf dem Stockwerk und nicht hinter einer Wand ist und „Spiegelungen“ an sind – sonst ist er matt. Kamera und
## SubViewport entstehen erst beim ersten Hinsehen (es gibt einen Spiegel über jedem Waschbecken).
## Die Fläche liegt auf LAYER, den die Spiegelkamera nicht sieht; die Spielerfigur (PlayerBody.LAYER) sieht nur sie.

const LAYER := 1 << 19   ## Sichtebene der Spiegelfläche – die Spiegelkamera sieht sie nicht
const PX := 320          ## Breite des Spiegelbilds in Pixeln (PS1-grob)
const TINT := Color(0.86, 0.9, 0.88)
const DULL := Color(0.62, 0.7, 0.74)
const FLOOR_SPAN := 2.5  ## höchstens so weit über oder unter der Kamera (sonst anderes Stockwerk)

static var _dull: Material
## Charaktererstellung (CharacterCreation): Spiegelbild auch ohne „Spiegelungen“ in den Einstellungen
static var force := false

## false = bleibt matt (der tote Aufzug)
var active := true
## so nah muss die Kamera sein
var reach := 12.0
var size := Vector2.ONE
var _vp: SubViewport
var _cam: Camera3D
var _live_mat: ShaderMaterial


## Spiegelfläche (size in m) an parent, Mitte bei pos, Blick (Vorderseite) nach normal (waagerecht).
static func make(parent: Node3D, mirror_size: Vector2, pos: Vector3, normal: Vector3, range_m: float = 12.0) -> Mirror:
	var m := Mirror.new()
	m.size = mirror_size
	m.reach = range_m
	var quad := QuadMesh.new()
	quad.size = mirror_size
	m.mesh = quad
	if _dull == null:
		_dull = Mat.psx(DULL)
	m.material_override = _dull
	m.layers = LAYER
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	m.position = pos
	m.process_mode = Node.PROCESS_MODE_ALWAYS   # auch in der (pausierten) Charaktererstellung
	m.rotation.y = atan2(normal.x, normal.z)   # QuadMesh zeigt nach +Z
	parent.add_child(m)
	return m


func _setup_camera() -> void:
	_vp = SubViewport.new()
	_vp.size = Vector2i(PX, roundi(PX * size.y / size.x))
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_vp)
	_cam = Camera3D.new()
	_cam.cull_mask = 0xFFFFF & ~LAYER
	_cam.projection = Camera3D.PROJECTION_FRUSTUM
	_vp.add_child(_cam)
	_cam.current = true
	_live_mat = ShaderMaterial.new()
	_live_mat.shader = load("res://shaders/mirror_view.gdshader")
	_live_mat.set_shader_parameter("view", _vp.get_texture())
	_live_mat.set_shader_parameter("tint", TINT)
	_env()
	Settings.changed.connect(_env)


## Umgebung der Spiegelkamera: die der Welt ohne Tonemapping (das kommt im Hauptbild ein zweites Mal), ohne
## Bildschirmspiegelung und Lichtnebel (zu teuer für ein Bild im Bild).
func _env() -> void:
	var env := get_world_3d().environment if is_inside_tree() else null
	if env:
		var own := env.duplicate() as Environment
		own.tonemap_mode = Environment.TONE_MAPPER_LINEAR
		own.ssr_enabled = false
		own.volumetric_fog_enabled = false
		own.glow_enabled = false
		_cam.environment = own


## Ist der Spiegel für diese Kamera zu sehen? Mitte oder eine Ecke im Bild, davor, nah, kein Wand dazwischen.
func _visible_to(cam: Camera3D) -> bool:
	if not active or not (Settings.reflections or force) or cam == null or not is_visible_in_tree():
		return false
	var t := global_transform
	var n := t.basis.z.normalized()
	var c := t.origin
	if (cam.global_position - c).dot(n) <= 0.05 or cam.global_position.distance_to(c) > reach \
			or absf(cam.global_position.y - c.y) > FLOOR_SPAN:
		return false
	var seen := false
	for corner: Vector2 in [Vector2.ZERO, Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var q: Vector2 = corner * size / 2.0
		seen = seen or cam.is_position_in_frustum(t * Vector3(q.x, q.y, 0.01))
	if not seen:
		return false
	if get_tree().paused:   # Physik steht – nur die Charaktererstellung pausiert und will ihn sehen
		return force
	# Wände (Ebene 1) zwischen Auge und Spiegel: dann ist er nicht zu sehen
	var query := PhysicsRayQueryParameters3D.create(cam.global_position, c + n * 0.08, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_3d()
	var live := _visible_to(cam)
	if live and _vp == null:
		_setup_camera()
	if _vp:
		_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if live else SubViewport.UPDATE_DISABLED
	material_override = _live_mat if live else _dull
	if not live:
		return
	var t := global_transform
	var n := t.basis.z.normalized()
	var c := t.origin
	var dist := (cam.global_position - c).dot(n)
	var p := cam.global_position - n * dist * 2.0
	var x_axis := -t.basis.x.normalized()
	var y_axis := t.basis.y.normalized()
	_cam.global_transform = Transform3D(Basis(x_axis, y_axis, -n), p)
	var rel := c - p
	_cam.set_frustum(size.y, Vector2(rel.dot(x_axis), rel.dot(y_axis)), dist, cam.far)
