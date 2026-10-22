class_name PoolWater
extends MeshInstance3D
## Wasser im Hallenbad (Spielkonzept 7.5): halbtransparent mit rein optischen Wellen im Shader
## (shaders/psx_water.gdshader), ohne Physik und Auftrieb. Wer durchs Becken geht, zieht Wellenringe
## hinter sich her, die Wände werfen sie zurück, und alles addiert sich; wer hineinfällt, platscht – ein hoher Ring, der als Schaum bricht (oben auf dem Kamm
## und am Beckenrand), dazu Spritzer.
## Das Wasser spürt das Monster (wie das Rauschen nach Entfernung, Spielkonzept 4.13 – gemessen zum Wasser,
## nicht zum Spieler): erst wird es spiegelglatt, näher zittern feine Ringe von seiner Seite her übers
## Becken, ist es in der Halle, schwappt das Becken unruhig wie eine Badewanne und schäumt an den Rändern.

const SHADER := "res://shaders/psx_water.gdshader"
## Muss zu MAX_RIPPLES im Shader passen
const MAX_RIPPLES := 32
## so lange läuft ein Ring, dann ist er abgeklungen (genug für den Rückweg von der Wand); RIPPLE_DECAY geht
## als ripple_decay an den Shader, danach wählt ripple() den schwächsten Platz, wenn keiner frei ist
const RIPPLE_LIFE := 9.0
const RIPPLE_DECAY := 0.35
## Gitterweite der Wasserfläche – fein genug für die Ringe (Abstand der Kämme ~1,1 m)
const GRID := 0.25
## Gehen im Wasser: alle so viele Meter ein Ring, Stärke gehend bzw. schneller als Gehen
const WAKE_EVERY := 0.6
const WAKE_WALK := 0.4
const WAKE_RUN := 0.7
## Stillstehen im Wasser: schwacher Ring alle so viele Sekunden
const IDLE_EVERY := 1.6
const IDLE_STRENGTH := 0.15
## Eintauchen: ab dieser Fallgeschwindigkeit (m/s) platscht es, sonst nur ein Ring
const SPLASH_SPEED := 2.5
## Monster: ab hier legen sich die Grundwellen, hier sind sie ganz glatt (Meter bis zum Wasser)
const STILL_FROM := 32.0
const STILL_FULL := 20.0
## Zittern ab Beginn des Rauschens, am stärksten, wo es am lautesten ist
const TREMOR_FROM := MonsterDirector.NOISE_START
const TREMOR_FULL := MonsterDirector.NOISE_FULL
## In der Halle: Grundwellen so viel höher, Schwappen der Länge nach (Meter, Dauer einer Hin- und
## Herbewegung; die Querwelle ist schneller)
const SLOSH_WAVES := 2.0
const SLOSH_HEIGHT := 0.15
const SLOSH_PERIOD := 9.0
## Übergänge je Sekunde (Glätten, Zittern, Schwappen an- und abschwellen)
const CALM_RATE := 0.25
const TREMOR_RATE := 0.5
const SLOSH_UP := 0.25
const SLOSH_DOWN := 0.08

var surface_y := 0.0
var inner := Rect2()   ## Innenkante des Beckens in x/z
var hall := Rect2()    ## Hallenbad samt Umgang in x/z
var debug_stage := ""  ## --pool=still|tremor|slosh: Stufe fest, ohne Übergang

var _ripples := PackedVector4Array()   ## x, z, Alter, Stärke (0 = frei)
var _walkers := {}                    ## Node3D → {wet, at, dist, idle}
var _time := 0.0
var _calm := 0.0
var _tremor := 0.0
var _slosh := 0.0
var _slosh_phase := Vector2.ZERO
var _spray_side := 0                  ## an welchem Ende zuletzt Gischt aufspritzte
var _mat: ShaderMaterial
var _drop_mat: Material
var _drop_mesh: BoxMesh


## area = Wasserfläche laut Plan (unter den Beckenrändern), wall = Dicke der Beckenränder,
## p_hall = Halle samt Umgang (dort schwappt das Becken, wenn das Monster darin ist).
func _init(area: Rect2, y: float, wall: float, p_hall: Rect2) -> void:
	surface_y = y
	inner = area.grow(-wall)
	hall = p_hall
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
	_mat.set_shader_parameter("ripple_decay", RIPPLE_DECAY)
	material_override = _mat
	_ripples.resize(MAX_RIPPLES)
	_drop_mat = Mat.psx(Color(0.8, 0.9, 0.95), "", 1.0, Color(0.4, 0.5, 0.55), 0.4)
	_drop_mesh = Geo.box(Vector3(0.03, 0.03, 0.03))
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
	_update_unrest(delta)
	_mat.set_shader_parameter("wave_time", _time)
	_mat.set_shader_parameter("ripples", _ripples)


## Wellenring an dieser Stelle (strength 1 ≈ 14 cm hoch).
func ripple(at: Vector2, strength: float) -> void:
	var slot := 0
	var weakest := INF
	for i in MAX_RIPPLES:
		var r := _ripples[i]
		var left := r.w * exp(-r.z * RIPPLE_DECAY)
		if left < weakest:
			weakest = left
			slot = i
	_ripples[slot] = Vector4(at.x, at.y, 0.0, strength)


## Hineinfallen: hoher Ring mit einem Nachschwapper und Spritzer (strength ~1).
func splash(at: Vector2, strength: float) -> void:
	ripple(at, strength * 1.5)
	ripple(at + Vector2(0.25, -0.15), strength * 0.6)
	var drops := _drops(Vector3(at.x, surface_y, at.y), roundi(30 + 30 * strength), strength)
	drops.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING   # rund um die Eintauchstelle, nicht ins Gesicht
	drops.emission_ring_axis = Vector3.UP
	drops.emission_ring_radius = 0.8
	drops.emission_ring_inner_radius = 0.45
	drops.emission_ring_height = 0.0
	drops.emitting = true


## Tropfen, die einmal aufspritzen und wieder verschwinden (Form der Austrittsstelle setzt der Aufrufer).
func _drops(at: Vector3, amount: int, strength: float) -> CPUParticles3D:
	var drops := CPUParticles3D.new()
	drops.one_shot = true
	drops.amount = amount
	drops.lifetime = 1.1
	drops.explosiveness = 0.9
	drops.mesh = _drop_mesh
	drops.material_override = _drop_mat
	drops.direction = Vector3.UP
	drops.spread = 25.0
	drops.initial_velocity_min = 2.0 * strength
	drops.initial_velocity_max = 3.5 * strength
	drops.scale_amount_min = 0.6
	drops.scale_amount_max = 1.4
	drops.position = at - position
	add_child(drops)
	drops.finished.connect(drops.queue_free)
	return drops


## Unruhe durchs Monster: Zielwerte nach seinem Abstand zum Wasser, sanft angeglichen.
func _update_unrest(delta: float) -> void:
	var calm := 0.0
	var tremor := 0.0
	var slosh := 0.0
	var m := Game.monster
	if debug_stage != "":
		calm = 1.0
		tremor = 1.0 if debug_stage != "still" else 0.0
		slosh = 1.0 if debug_stage == "slosh" else 0.0
		_mat.set_shader_parameter("tremor_src", Vector2(inner.get_center().x, inner.end.y))
	elif is_instance_valid(m) and m.is_active() and m.visible:
		var at := m.global_position
		var near := Vector3(clampf(at.x, inner.position.x, inner.end.x), surface_y, clampf(at.z, inner.position.y, inner.end.y))
		var d := at.distance_to(near)
		calm = clampf((STILL_FROM - d) / (STILL_FROM - STILL_FULL), 0.0, 1.0)
		tremor = clampf((TREMOR_FROM - d) / (TREMOR_FROM - TREMOR_FULL), 0.0, 1.0)
		slosh = 1.0 if hall.has_point(Vector2(at.x, at.z)) and absf(at.y - surface_y) < 3.0 else 0.0
		_mat.set_shader_parameter("tremor_src", Vector2(near.x, near.z))
	if debug_stage != "":
		_calm = calm
		_tremor = tremor
		_slosh = slosh
	else:
		_calm = move_toward(_calm, calm, CALM_RATE * delta)
		_tremor = move_toward(_tremor, tremor, TREMOR_RATE * delta)
		_slosh = move_toward(_slosh, slosh, (SLOSH_UP if slosh > _slosh else SLOSH_DOWN) * delta)
	_slosh_phase += Vector2(TAU / SLOSH_PERIOD, TAU / (SLOSH_PERIOD * 0.45)) * delta
	_mat.set_shader_parameter("base_scale", lerpf(1.0 - _calm, SLOSH_WAVES, _slosh))
	_mat.set_shader_parameter("tremor", _tremor)
	_mat.set_shader_parameter("slosh", _slosh * SLOSH_HEIGHT)
	_mat.set_shader_parameter("slosh_phase", _slosh_phase)
	# Gischt am hohen Ende, wenn die Längswelle dort anschlägt (Westende hoch bei sin > 0)
	var up := sin(_slosh_phase.x)
	if _slosh > 0.3 and absf(up) > 0.97 and roundi(signf(up)) != _spray_side:
		_spray_side = roundi(signf(up))
		var x := inner.position.x if up > 0.0 else inner.end.x
		var drops := _drops(Vector3(x, surface_y + SLOSH_HEIGHT, inner.get_center().y), roundi(50 * _slosh), 0.7 * _slosh)
		drops.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		drops.emission_box_extents = Vector3(0.15, 0.0, inner.size.y / 2.0)
		drops.emitting = true


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
