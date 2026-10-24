class_name AtticHaze
extends Node3D
## Staubnebel im Dachgeschoss (Spielkonzept 4.21, 24.10.): blaugrauer Volumennebel über der Fläche des Dachbodens – je
## Rechteck ein FogVolume mit dem gemeinsamen Nebel-Shader shaders/attic_dust.gdshader (fleckig, treibt, flimmert leicht;
## die Zeit zählt hier mit delta, steht also in der Pause). Dazu feiner Staub (Partikel), der um die Kamera schwebt,
## solange sie im Dachboden ist. Das Licht durch die Dachfenster (Kegel des LevelBuilders) folgt dem Mond: so hell wie
## er gerade scheint (Wolken, Blitz – Weather), × SHAFT_ENERGY. Erzeugt vom LevelBuilder (_attic_haze), nicht gespeichert.

const SHADER := "res://shaders/attic_dust.gdshader"
const DENSITY := 0.09
const ALBEDO := Color(0.5, 0.56, 0.68)
const EMISSION := Color(0.035, 0.04, 0.055)   ## etwas Eigenleuchten: auch im Dunkeln steht er blaugrau im Raum
## Schwebender Staub: Anzahl, Lebenszeit, Größe, Kasten um die Kamera, Farbe (Deckkraft) und Eigenleuchten
const DUST := 140
const DUST_LIFE := 9.0
const DUST_SIZE := 0.012
const DUST_BOX := Vector3(3.5, 1.0, 3.5)
const DUST_COLOR := Color(0.78, 0.8, 0.86, 0.55)
const DUST_GLOW := 0.12
## Licht durch die Dachfenster je Einheit Mondlicht (der Mond hat sonst 0,32)
const SHAFT_ENERGY := 5.0

var _rects: Array[Rect2] = []
var _floor_y := 0.0
var _height := 0.0
var _material: ShaderMaterial
var _dust: CPUParticles3D
var _t := 0.0
var _shafts: Array[SpotLight3D] = []
var _moon: DirectionalLight3D


## rects = Grundfläche (x, z), floor_y = Höhe des Bodens, height = bis zur Decke.
## shafts = Licht der Dachfenster.
func setup(rects: Array[Rect2], floor_y: float, height: float, shafts: Array[SpotLight3D]) -> AtticHaze:
	_rects = rects
	_shafts = shafts
	_floor_y = floor_y
	_height = height
	return self


func _ready() -> void:
	_material = ShaderMaterial.new()
	_material.shader = load(SHADER)
	_material.set_shader_parameter("density", DENSITY)
	_material.set_shader_parameter("albedo", ALBEDO)
	_material.set_shader_parameter("emission", EMISSION)
	for r in _rects:
		var volume := FogVolume.new()
		volume.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
		volume.size = Vector3(r.size.x, _height, r.size.y)
		volume.position = Vector3(r.get_center().x, _floor_y + _height / 2.0, r.get_center().y)
		volume.material = _material
		add_child(volume)
	var mat := Mat.particle(null, DUST_GLOW)
	_dust = Geo.particles(DUST, DUST_LIFE, DUST_SIZE, mat, 0.25, 0.35)
	_dust.color = DUST_COLOR
	_dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_dust.emission_box_extents = DUST_BOX
	_dust.direction = Vector3.UP
	_dust.spread = 180.0
	_dust.gravity = Vector3(0, -0.004, 0)
	_dust.initial_velocity_min = 0.01
	_dust.initial_velocity_max = 0.05
	_dust.emitting = false
	add_child(_dust)


func _process(delta: float) -> void:
	_t += delta
	_material.set_shader_parameter("t", _t)
	if _moon == null:
		_moon = get_parent().get_node_or_null("Moon") as DirectionalLight3D
	var energy := (_moon.light_energy if _moon else 0.32) * SHAFT_ENERGY
	for shaft in _shafts:
		shaft.light_energy = energy
	var cam := get_viewport().get_camera_3d()
	var inside := cam != null and contains(cam.global_position)
	if inside:
		_dust.global_position = cam.global_position
	if _dust.emitting != inside:
		_dust.emitting = inside


## Liegt p im Dachboden (Grundfläche und Höhe des Nebels)?
func contains(p: Vector3) -> bool:
	if p.y < _floor_y - 0.2 or p.y > _floor_y + _height + 0.3:
		return false
	for r in _rects:
		if r.has_point(Vector2(p.x, p.z)):
			return true
	return false
