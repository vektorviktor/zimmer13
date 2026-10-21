class_name DiscoBall
extends Node3D
## Discokugel über der Tanzfläche im Partyraum (Spielkonzept 7.1): hängt an einer Schnur von der Decke über dem
## Luftraum, spiegelt die Lampen (shaders/psx_mirror.gdshader). Auf Feiern dreht sie sich, und Lichtpunkte ziehen
## über Wände, Boden und Tänzer – eine Punktlampe in der Kugel, die ein Punktemuster wirft (Projektor) und
## sich mitdreht. Die Kugel selbst bekommt von ihr kein Licht (eigene Ebene, LAYER).

## Modell aus tools/build_disco_ball.py: glatte Kugel, Plättchen als Normal Map, Ursprung in der Mitte
const MODEL := "res://assets/models/disco_ball.glb"
const RADIUS := 0.4
## Drehung auf Feiern (Bogenmaß/s) – eine Runde in gut 20 s
const SPIN := 0.3
## Sichtbarkeitsebene der Kugel, die ihre eigene Punktlampe auslässt
const LAYER := 1 << 10
## Lichtpunkte: Stärke, Reichweite, Ein- und Ausblenden (s)
const DOTS_ENERGY := 6.0
const DOTS_RANGE := 14.0
const DOTS_FADE := 1.5
const DOTS_COUNT := 900

var _ball: Node3D
var _dots: OmniLight3D
var _level := 0.0   ## Lichtpunkte 0..1


## top = Abstand von der Kugelmitte hinauf zur Decke, an der die Schnur hängt
func setup(top: float) -> DiscoBall:
	Geo.mesh(self, Geo.cylinder(0.01, top - RADIUS, 4), Mat.psx(Color(0.2, 0.18, 0.16)), Vector3(0, (top + RADIUS) / 2.0, 0)) \
		.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ball = (load(MODEL) as PackedScene).instantiate()
	add_child(_ball)
	for m: MeshInstance3D in _ball.find_children("*", "MeshInstance3D", true, false):
		m.material_override = _material(m.get_active_material(0) as BaseMaterial3D)
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.layers = LAYER
	_dots = OmniLight3D.new()
	_dots.light_projector = _dot_pattern()
	_dots.light_cull_mask = ~LAYER & 0xFFFFF
	_dots.shadow_enabled = true   # ohne Schatten kein Projektor
	_dots.omni_range = DOTS_RANGE
	_dots.omni_attenuation = 0.6
	_dots.light_specular = 0.0
	_dots.visible = false
	_ball.add_child(_dots)
	return self


func _process(delta: float) -> void:
	var party: bool = Game.social != null and Game.social.party_active
	if party:
		_ball.rotation.y = wrapf(_ball.rotation.y + SPIN * delta, 0.0, TAU)
	_level = move_toward(_level, 1.0 if party else 0.0, delta / DOTS_FADE)
	_dots.visible = _level > 0.0
	_dots.light_energy = DOTS_ENERGY * _level


## Material aus dem importierten: Farbe, Normal Map und Spiegelmaske (Blau der Metallic-Textur)
static func _material(src: BaseMaterial3D) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/psx_mirror.gdshader")
	m.set_shader_parameter("albedo_tex", _mipmapped(src.albedo_texture))
	m.set_shader_parameter("normal_tex", _mipmapped(src.normal_texture))
	m.set_shader_parameter("mirror_tex", _mipmapped(src.metallic_texture))
	return m


## Unkomprimiert eingebettete Texturen kommen ohne Mipmaps – aus der Ferne flimmerten die Fugen dann als Striche.
static func _mipmapped(tex: Texture2D) -> Texture2D:
	var img := tex.get_image()
	if img.has_mipmaps():
		return tex
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## Punktemuster für den Projektor: kleine helle Flecken auf Schwarz, ein paar farbig. Die Punktlampe bildet die
## obere und die untere Bildhälfte je auf eine Halbkugel ab – die Punkte liegen gleichmäßig über beide.
static func _dot_pattern() -> ImageTexture:
	const SIZE := 1024
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1313
	var tints := [Color(1, 1, 1), Color(1, 1, 1), Color(1, 1, 1), Color(1.0, 0.55, 0.8), Color(0.55, 0.8, 1.0), Color(1.0, 0.8, 0.45)]
	for i in DOTS_COUNT:
		var c := Vector2(rng.randf_range(0, SIZE), rng.randf_range(0, SIZE))
		var r := rng.randf_range(1.4, 2.4)
		var tint: Color = tints[rng.randi() % tints.size()]
		for y in range(int(c.y - r - 1), int(c.y + r + 2)):
			for x in range(int(c.x - r - 1), int(c.x + r + 2)):
				if x < 0 or y < 0 or x >= SIZE or y >= SIZE:
					continue
				var k := clampf(r + 0.5 - c.distance_to(Vector2(x + 0.5, y + 0.5)), 0.0, 1.0)
				if k > 0.0:
					img.set_pixel(x, y, img.get_pixel(x, y).lerp(tint, k))
	return ImageTexture.create_from_image(img)
