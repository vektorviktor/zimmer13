class_name Boiler
extends StaticBody3D
## Alter Kohlekessel im Heizkeller (Spielkonzept 7.4, 7.9; Modell `assets/models/boiler.glb` aus tools/build_boiler.py).
## Die Feuerklappe steht offen (DOOR_OPEN), im Feuerraum glüht die Glut auf dem Rost, darüber lodern Flammen, ab und zu
## fliegt ein Funke heraus, und es knistert (SynthAudio.fire, gedämpft durch Wände wie Lärm). Licht: ein orangeroter
## Lichtkegel aus der Klappe nach vorn auf den Boden (SpotLight3D im Feuerraum – der Kessel selbst wirft den Schatten,
## so hat der Kegel die Form der Öffnung) und ein schwacher Schein davor (FlickerLight in `lamps`: flackert wie eine
## Kerze, zählt für MonsterDirector.light_at, Schatten über ShadowBudget). Der Kegel folgt dem Schein, auch wenn
## ShadowBudget ihn abschaltet. Das Feuer brennt immer – Anheizen, Kohle und Ausgehen sind eingefroren (7.4).
## Oben auf dem Kessel sitzt der Rohrstutzen (PIPE_TOP), dort setzt LevelBuilder._boiler_pipes an. Nicht gespeichert.
## Ursprung mittig unten, lokale +Z = Feuerklappe.

const MODEL := "res://assets/models/boiler.glb"
const RADIUS := 0.43
const HEIGHT := 2.0
## Oberseite mit dem Rohrstutzen (lokal)
const PIPE_TOP := Vector3(0, 2.0, 0)
## Feuerklappe: so weit aufgeschwenkt (Bogenmaß, 100°), Scharnier rechts
const DOOR_OPEN := 1.745
## Feuerraum (lokal): Rost bei y 0,6, Öffnung x ±0,21, y 0,52..0,88, vorn bei z 0,4
const GRATE := Vector3(0, 0.6, 0.27)
const OPENING := Vector3(0, 0.7, 0.42)
const FIRE_COLOR := Color(1.0, 0.36, 0.1)
## Schein vor der Klappe: Stärke und Reichweite (wie eine helle Kerze, etwas weiter)
const GLOW_ENERGY := 0.7
const GLOW_RANGE := 5.5
## Lichtkegel aus der Klappe: Stärke, Reichweite, halber Öffnungswinkel (°), Neigung nach unten (°)
const CONE_ENERGY := 10.0
const CONE_RANGE := 10.0
const CONE_ANGLE := 55.0
const CONE_TILT := 20.0
## Knistern: so weit (m) hört man es ohne Wände dazwischen; so laut höchstens (SynthAudio.fire)
const CRACKLE_RANGE := 8.0
const CRACKLE_VOLUME := 0.55

var _glow: FlickerLight
var _cone: SpotLight3D
var _embers: ShaderMaterial
var _sound_timer := 0.0
var _sound_target := 0.0


func _ready() -> void:
	collision_mask = 0
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = RADIUS
	shape.height = HEIGHT
	cs.shape = shape
	cs.position = Vector3(0, HEIGHT / 2.0, 0)
	add_child(cs)
	_build_model()
	_build_fire()


func _build_model() -> void:
	if not ResourceLoader.exists(MODEL):
		Geo.mesh(self, Geo.cylinder(0.4, HEIGHT, 12), Mat.psx(Color(0.2, 0.17, 0.15)), Vector3(0, HEIGHT / 2.0, 0))
		return
	var model: Node3D = (load(MODEL) as PackedScene).instantiate()
	add_child(model)
	for m: MeshInstance3D in model.find_children("*", "MeshInstance3D", true, false):
		for s in m.mesh.get_surface_count():
			var src := m.mesh.surface_get_material(s) as BaseMaterial3D
			if src and src.albedo_texture:
				m.set_surface_override_material(s, Mat.model(MODEL, m, s))
			else:
				m.set_surface_override_material(s, Mat.psx(src.albedo_color if src else Color(0.04, 0.035, 0.03)))
	var door := model.find_child("fire_door", true, false) as Node3D
	if door:
		door.rotation.y = DOOR_OPEN
		# Die offene Klappe steht nach vorn ab – eigener Kasten, damit man nicht hindurchläuft
		var arm := Vector3(-0.25, 0, 0).rotated(Vector3.UP, DOOR_OPEN)
		var box := Geo.add_box_shape(self, Vector3(0.5, 0.42, 0.06), door.position + arm)
		box.rotation.y = DOOR_OPEN


func _build_fire() -> void:
	# Glut auf dem Rost
	_embers = Mat.psx(Color(0.7, 0.18, 0.04), "", 1.0, Color(1.0, 0.32, 0.06), 3.0, false)
	Geo.mesh(self, Geo.box(Vector3(0.38, 0.05, 0.22)), _embers, GRATE + Vector3(0, 0.02, 0))
	add_child(_flames())
	add_child(_sparks())
	_glow = FlickerLight.new()
	_glow.position = OPENING + Vector3(0, 0.05, 0.35)
	_glow.light_color = FIRE_COLOR
	_glow.base_energy = GLOW_ENERGY
	_glow.omni_range = GLOW_RANGE
	_glow.soft = true
	_glow.shadow_enabled = false
	_glow.distance_fade_enabled = true
	_glow.distance_fade_begin = 20.0
	_glow.distance_fade_length = 5.0
	_glow.add_to_group("lamps")
	add_child(_glow)
	_cone = SpotLight3D.new()
	_cone.position = GRATE + Vector3(0, 0.15, -0.05)
	_cone.basis = Basis.looking_at(Vector3(0, -tan(deg_to_rad(CONE_TILT)), 1).normalized())
	_cone.light_color = FIRE_COLOR
	_cone.light_energy = CONE_ENERGY
	_cone.spot_range = CONE_RANGE
	_cone.spot_angle = CONE_ANGLE
	_cone.spot_attenuation = 1.0
	_cone.spot_angle_attenuation = 0.6
	_cone.shadow_enabled = true   # der Kessel begrenzt den Kegel auf die Öffnung
	_cone.distance_fade_enabled = true
	_cone.distance_fade_begin = 20.0
	_cone.distance_fade_length = 5.0
	add_child(_cone)


## Flammen über der Glut: Billboards steigen auf und verblassen von Gelb über Orange zu Rot (wie DecoFire). Der
## Feuerraum verdeckt sie bis auf die Öffnung.
func _flames() -> CPUParticles3D:
	var flames := CPUParticles3D.new()
	flames.position = GRATE + Vector3(0, 0.03, 0.02)
	flames.amount = 30
	flames.lifetime = 0.5
	flames.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	flames.emission_box_extents = Vector3(0.16, 0.01, 0.09)
	flames.direction = Vector3.UP
	flames.spread = 12.0
	flames.initial_velocity_min = 0.15
	flames.initial_velocity_max = 0.35
	flames.gravity = Vector3(0, 0.5, 0)
	flames.scale_amount_min = 0.7
	flames.scale_amount_max = 1.4
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.85, 0.35))
	ramp.add_point(0.45, Color(1.0, 0.45, 0.08, 0.9))
	ramp.set_color(ramp.get_point_count() - 1, Color(0.8, 0.12, 0.02, 0.0))
	flames.color_ramp = ramp
	flames.mesh = _billboard(Vector2(0.09, 0.13))
	return flames


## Funken: selten einer, der aus der Klappe nach vorn oben fliegt und herabfällt.
func _sparks() -> CPUParticles3D:
	var sparks := CPUParticles3D.new()
	sparks.position = GRATE + Vector3(0, 0.08, 0.1)
	sparks.amount = 4
	sparks.lifetime = 1.3
	sparks.randomness = 1.0
	sparks.local_coords = false
	sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	sparks.emission_box_extents = Vector3(0.12, 0.02, 0.05)
	sparks.direction = Vector3(0, 0.7, 1)
	sparks.spread = 25.0
	sparks.initial_velocity_min = 0.5
	sparks.initial_velocity_max = 1.1
	sparks.gravity = Vector3(0, -1.6, 0)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.9, 0.5))
	ramp.set_color(1, Color(1.0, 0.25, 0.05, 0.0))
	sparks.color_ramp = ramp
	sparks.mesh = _billboard(Vector2(0.02, 0.02))
	return sparks


func _billboard(size: Vector2) -> QuadMesh:
	var quad := QuadMesh.new()
	quad.size = size
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.vertex_color_use_as_albedo = true
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	quad.material = mat
	return quad


func _process(delta: float) -> void:
	# Kegel und Glut flackern mit dem Schein; schaltet ShadowBudget den Schein ab (Kamera woanders), auch den Kegel
	var level := _glow.light_energy / GLOW_ENERGY
	_cone.visible = not _glow.has_meta("hidden_mask")
	_cone.light_energy = CONE_ENERGY * level
	_embers.set_shader_parameter("emission_energy", 2.0 + 1.5 * level)
	_update_sound(delta)


## Knistern: alle 0,25 s, wie laut der Spieler es hier hört (Entfernung, Wände), dazwischen weich nachgeführt.
func _update_sound(delta: float) -> void:
	if Game.audio == null:
		return
	_sound_timer -= delta
	if _sound_timer <= 0.0:
		_sound_timer = 0.25
		_sound_target = Game.hearing(to_global(OPENING + Vector3(0, 0, 0.3)), CRACKLE_RANGE) * CRACKLE_VOLUME
	Game.audio.fire = move_toward(Game.audio.fire, _sound_target, delta * 0.8)


func _exit_tree() -> void:
	if Game.audio:
		Game.audio.fire = 0.0
