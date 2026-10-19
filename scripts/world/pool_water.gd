class_name PoolWater
extends MeshInstance3D
## Wasser im Hallenbad (Spielkonzept 7.5): halbtransparent mit rein optischen Wellen im Shader
## (shaders/psx_water.gdshader), ohne Physik und Auftrieb. Wer durchs Becken geht, zieht Wellenringe
## hinter sich her; wer hineinfällt, platscht – ein hoher Ring, der als Schaum bricht (oben auf dem Kamm
## und am Beckenrand), dazu Spritzer.

const SHADER := "res://shaders/psx_water.gdshader"
## Muss zu MAX_RIPPLES im Shader passen
const MAX_RIPPLES := 24
## so lange läuft ein Ring, dann ist er abgeklungen
const RIPPLE_LIFE := 6.0
## Gitterweite der Wasserfläche – fein genug für die Ringe (Abstand der Kämme ~1,1 m)
const GRID := 0.25
## Gehen im Wasser: alle so viele Meter ein Ring, Stärke gehend bzw. schneller als Gehen
const WAKE_EVERY := 0.45
const WAKE_WALK := 0.4
const WAKE_RUN := 0.7
## Stillstehen im Wasser: schwacher Ring alle so viele Sekunden
const IDLE_EVERY := 1.6
const IDLE_STRENGTH := 0.15
## Eintauchen: ab dieser Fallgeschwindigkeit (m/s) platscht es, sonst nur ein Ring
const SPLASH_SPEED := 2.5

var surface_y := 0.0
var inner := Rect2()   ## Innenkante des Beckens in x/z

var _ripples := PackedVector4Array()   ## x, z, Alter, Stärke (0 = frei)
var _next := 0
var _walkers := {}                    ## Node3D → {wet, at, dist, idle}
var _time := 0.0
var _mat: ShaderMaterial
var _drop_mat: Material


## area = Wasserfläche laut Plan (unter den Beckenrändern), wall = Dicke der Beckenränder.
func _init(area: Rect2, y: float, wall: float) -> void:
	surface_y = y
	inner = area.grow(-wall)
	var plane := PlaneMesh.new()
	plane.size = area.size
	plane.subdivide_width = ceili(area.size.x / GRID) - 1
	plane.subdivide_depth = ceili(area.size.y / GRID) - 1
	mesh = plane
	position = Vector3(area.get_center().x, y, area.get_center().y)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mat = ShaderMaterial.new()
	_mat.shader = load(SHADER)
	_mat.set_shader_parameter("pool_rect", Vector4(inner.position.x, inner.position.y, inner.end.x, inner.end.y))
	material_override = _mat
	_ripples.resize(MAX_RIPPLES)
	_drop_mat = Mat.psx(Color(0.8, 0.9, 0.95), "", 1.0, Color(0.4, 0.5, 0.55), 0.4)
	add_to_group("pool_water")


func _process(delta: float) -> void:
	_time += delta
	for i in MAX_RIPPLES:
		var r := _ripples[i]
		if r.w > 0.0:
			r.z += delta
			if r.z > RIPPLE_LIFE:
				r.w = 0.0
			_ripples[i] = r
	for n: Node3D in [Game.player, Game.monster]:
		if is_instance_valid(n) and n.visible:
			_track(n, delta)
	_mat.set_shader_parameter("wave_time", _time)
	_mat.set_shader_parameter("ripples", _ripples)


## Wellenring an dieser Stelle (strength 1 ≈ 14 cm hoch).
func ripple(at: Vector2, strength: float) -> void:
	_ripples[_next] = Vector4(at.x, at.y, 0.0, strength)
	_next = (_next + 1) % MAX_RIPPLES


## Hineinfallen: hoher Ring mit einem Nachschwapper und Spritzer (strength ~1).
func splash(at: Vector2, strength: float) -> void:
	ripple(at, strength * 1.5)
	ripple(at + Vector2(0.25, -0.15), strength * 0.6)
	var drops := CPUParticles3D.new()
	drops.one_shot = true
	drops.amount = roundi(30 + 30 * strength)
	drops.lifetime = 1.1
	drops.explosiveness = 0.9
	drops.mesh = Geo.box(Vector3(0.03, 0.03, 0.03))
	drops.material_override = _drop_mat
	drops.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING   # rund um die Eintauchstelle, nicht ins Gesicht
	drops.emission_ring_axis = Vector3.UP
	drops.emission_ring_radius = 0.8
	drops.emission_ring_inner_radius = 0.45
	drops.emission_ring_height = 0.0
	drops.direction = Vector3.UP
	drops.spread = 25.0
	drops.initial_velocity_min = 2.0 * strength
	drops.initial_velocity_max = 3.5 * strength
	drops.scale_amount_min = 0.6
	drops.scale_amount_max = 1.4
	drops.position = Vector3(at.x, surface_y, at.y) - position
	add_child(drops)
	drops.emitting = true
	drops.finished.connect(drops.queue_free)


func _track(n: Node3D, delta: float) -> void:
	var feet := n.global_position
	var at := Vector2(feet.x, feet.z)
	var wet := inner.has_point(at) and feet.y < surface_y - 0.05 and feet.y > surface_y - 2.0
	var s: Dictionary = _walkers.get(n, {"wet": false, "at": at, "dist": 0.0, "idle": 0.0})
	if wet and not s["wet"]:
		var fall := -(n as CharacterBody3D).velocity.y if n is CharacterBody3D else 0.0
		if fall > SPLASH_SPEED:
			splash(at, clampf(fall / 5.0, 0.8, 1.4))
		else:
			ripple(at, WAKE_WALK)
		s["dist"] = 0.0
	elif wet:
		var moved := at.distance_to(s["at"])
		s["dist"] += moved
		if s["dist"] >= WAKE_EVERY:
			s["dist"] = 0.0
			s["idle"] = 0.0
			ripple(at, WAKE_RUN if moved / maxf(delta, 0.001) > Player.WALK_SPEED + 0.3 else WAKE_WALK)
		elif moved < 0.01:
			s["idle"] += delta
			if s["idle"] >= IDLE_EVERY:
				s["idle"] = 0.0
				ripple(at, IDLE_STRENGTH)
	s["wet"] = wet
	s["at"] = at
	_walkers[n] = s
