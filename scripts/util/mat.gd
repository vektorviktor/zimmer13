class_name Mat
## Materialien im PS1-Stil (Vertex-Snapping, Nearest-Filter, kein Glanz – außer auf der Tapete).

# --- Tuning
## Tapete: Farbbild je Variante (%s = teal, red …) und eine gemeinsame Höhenkarte (gleich groß,
## pixelgenau übereinander), im Spiel auf diese Kantenlänge verkleinert (PS1-Look) und über so
## viele Meter Wand gespannt
const WALLPAPER_PATH := "res://assets/textures/wallpaper_%s.png"
const WALLPAPER_BUMP_PATH := "res://assets/textures/wallpaper_bump.png"
const WALLPAPER_SRC_SIZE := 512
const WALLPAPER_SIZE := 256
const WALLPAPER_METERS := 3.5
## Bänder im Quellbild als Pixelzeilen [von, bis): Leiste, eine Wiederholung der Rauten, Vertäfelung
const WALLPAPER_FRIEZE := Vector2(0, 12)
const WALLPAPER_FIELD := Vector2(20, 148)
const WALLPAPER_BASE := Vector2(404, 512)
## Glanz je Graustufe der Höhenkarte (0 = stumpf, 1 = Lack); fremde Stufen nehmen die nächste
const WALLPAPER_GLOSS := {
	0: 0.0,      # Fugen zwischen den Rauten
	103: 0.1,    # dunkle Rauten – Velours, stumpf
	109: 0.65,   # helle Rauten – Satin
	114: 0.4,    # vertiefte Kassettenrahmen
	137: 0.6,    # Stufe unter dem Handlauf
	149: 0.7,    # Vertäfelung, Grund
	196: 0.9,    # Handlauf, Kassettenfüllung, Deckenleiste – Lack
}

static var _shader: Shader
static var _shader_two_sided: Shader
static var _wall_shader: Shader
static var _wall_albedo := {}
static var _wall_surface: ImageTexture
static var _cache := {}
static var _cobweb: StandardMaterial3D
static var _glass: StandardMaterial3D
static var _frosted: StandardMaterial3D


## Gemeinsam genutztes Material. Mit shared = false entsteht ein eigenes Material,
## dessen Parameter man zur Laufzeit ändern kann (z. B. leuchtende Lampen).
static func psx(color: Color, tex_id: String = "", tex_scale: float = 1.0, emission: Color = Color.BLACK, emission_energy: float = 0.0, shared: bool = true) -> ShaderMaterial:
	var key := "%s|%s|%.3f|%s|%.2f" % [color.to_html(), tex_id, tex_scale, emission.to_html(), emission_energy]
	if shared and _cache.has(key):
		return _cache[key]
	if _shader == null:
		_shader = load("res://shaders/psx_surface.gdshader")
	var m := ShaderMaterial.new()
	m.shader = _shader
	m.set_shader_parameter("albedo", color)
	if tex_id != "":
		m.set_shader_parameter("albedo_tex", TexGen.get_tex(tex_id))
		m.set_shader_parameter("use_world_uv", true)
		m.set_shader_parameter("tex_scale", tex_scale)
	m.set_shader_parameter("emission", emission)
	m.set_shader_parameter("emission_energy", emission_energy)
	if shared:
		_cache[key] = m
	return m


## PSX-Material mit der Farbtextur aus einer importierten GLB – eins pro Textur der Modelldatei
## (surface = Fläche des Meshs, deren Material die Textur liefert). two_sided zeichnet auch die
## Rückseiten – für einseitige Flächen wie Meshys Blätter.
static func model(path: String, src: MeshInstance3D, surface: int = 0, two_sided: bool = false) -> ShaderMaterial:
	var tex := (src.get_active_material(surface) as BaseMaterial3D).albedo_texture
	var key := "model|%s|%d" % [path, tex.get_instance_id() if tex else 0]
	if not _cache.has(key):
		var m := psx(Color(0.8, 0.8, 0.8), "", 1.0, Color.BLACK, 0.0, false)
		m.set_shader_parameter("albedo_tex", tex)
		if two_sided:
			if _shader_two_sided == null:
				_shader_two_sided = Shader.new()
				_shader_two_sided.code = m.shader.code.replace("cull_back", "cull_disabled")
			m.shader = _shader_two_sided
		_cache[key] = m
	return _cache[key]


## Für flache Auflagen auf einer anderen Fläche (Teppich auf Fliesen, Kassetten auf dem Türblatt):
## wird leicht zur Kamera gezogen, damit die Unterlage beim Vertex-Snapping nicht durchflimmert.
## pull = Anteil der Kameraentfernung (Rahmen nehmen weniger, sonst überdecken sie Vorhänge und Türblätter).
static func layer(color: Color, tex_id: String = "", tex_scale: float = 1.0, pull: float = 0.01) -> ShaderMaterial:
	var key := "layer|%s|%s|%.3f|%.4f" % [color.to_html(), tex_id, tex_scale, pull]
	if _cache.has(key):
		return _cache[key]
	var m := psx(color, tex_id, tex_scale, Color.BLACK, 0.0, false)
	m.set_shader_parameter("layer_pull", pull)
	_cache[key] = m
	return m


## Hoteltapete mit Vertäfelung und Glanz (Spielkonzept 7.2). wall_top = Wandhöhe (Leiste darunter),
## storey = Stockwerkshöhe, ab deren Vielfachen die Vertäfelung neu beginnt; variant = Farbbild.
static func wallpaper(wall_top: float, storey: float, variant: String = "teal") -> ShaderMaterial:
	var key := "wallpaper|%s|%.2f|%.2f" % [variant, wall_top, storey]
	if _cache.has(key):
		return _cache[key]
	if _wall_shader == null:
		_wall_shader = load("res://shaders/psx_wall.gdshader")
		_build_wall_surface()
	if not _wall_albedo.has(variant):
		_wall_albedo[variant] = _load_wall_albedo(variant)
	var m := ShaderMaterial.new()
	m.shader = _wall_shader
	m.set_shader_parameter("albedo_tex", _wall_albedo[variant])
	m.set_shader_parameter("surface_tex", _wall_surface)
	m.set_shader_parameter("texels_per_m", WALLPAPER_SIZE / WALLPAPER_METERS)
	var s := WALLPAPER_SIZE / float(WALLPAPER_SRC_SIZE)
	m.set_shader_parameter("frieze_rows", WALLPAPER_FRIEZE * s)
	m.set_shader_parameter("field_rows", WALLPAPER_FIELD * s)
	m.set_shader_parameter("base_rows", WALLPAPER_BASE * s)
	m.set_shader_parameter("wall_top", wall_top)
	m.set_shader_parameter("storey", storey)
	_cache[key] = m
	return m


## Wand zwischen zwei Räumen: Seite a wie wallpaper(...), Flächen mit Normale b_normal wie Seite b.
static func wallpaper_split(a: ShaderMaterial, b: ShaderMaterial, b_normal: Vector3) -> ShaderMaterial:
	var key := "wallsplit|%d|%d|%s" % [a.get_instance_id(), b.get_instance_id(), b_normal]
	if not _cache.has(key):
		var m := a.duplicate() as ShaderMaterial
		m.set_shader_parameter("side_b_normal", b_normal)
		m.set_shader_parameter("albedo_tex_b", b.get_shader_parameter("albedo_tex"))
		m.set_shader_parameter("wall_top_b", b.get_shader_parameter("wall_top"))
		m.set_shader_parameter("storey_b", b.get_shader_parameter("storey"))
		_cache[key] = m
	return _cache[key]


## Farbbild der Variante, verkleinert.
static func _load_wall_albedo(variant: String) -> ImageTexture:
	var img := (load(WALLPAPER_PATH % variant) as Texture2D).get_image()
	img.decompress()
	img.convert(Image.FORMAT_RGB8)
	img.resize(WALLPAPER_SIZE, WALLPAPER_SIZE, Image.INTERPOLATE_BILINEAR)
	return ImageTexture.create_from_image(img)


## Oberfläche aus der Höhenkarte: R = Höhe, G = Glanz der Stufe.
static func _build_wall_surface() -> void:
	var bump := (load(WALLPAPER_BUMP_PATH) as Texture2D).get_image()
	bump.decompress()
	bump.convert(Image.FORMAT_L8)
	bump.resize(WALLPAPER_SIZE, WALLPAPER_SIZE, Image.INTERPOLATE_NEAREST)
	var surf := Image.create(WALLPAPER_SIZE, WALLPAPER_SIZE, false, Image.FORMAT_RG8)
	for y in WALLPAPER_SIZE:
		for x in WALLPAPER_SIZE:
			var level := bump.get_pixel(x, y).r8
			surf.set_pixel(x, y, Color(level / 255.0, _gloss_for(level), 0.0))
	_wall_surface = ImageTexture.create_from_image(surf)


## Glanz der nächstgelegenen Stufe aus WALLPAPER_GLOSS.
static func _gloss_for(level: int) -> float:
	var best := 0
	for l: int in WALLPAPER_GLOSS:
		if absi(l - level) < absi(best - level):
			best = l
	return WALLPAPER_GLOSS[best]


static func cobweb() -> StandardMaterial3D:
	if _cobweb == null:
		_cobweb = StandardMaterial3D.new()
		_cobweb.albedo_texture = TexGen.get_tex("cobweb")
		_cobweb.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		_cobweb.alpha_scissor_threshold = 0.5
		_cobweb.cull_mode = BaseMaterial3D.CULL_DISABLED
		_cobweb.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_cobweb.roughness = 1.0
	return _cobweb


static func glass() -> StandardMaterial3D:
	if _glass == null:
		_glass = StandardMaterial3D.new()
		_glass.albedo_color = Color(0.55, 0.7, 0.8, 0.2)
		_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_glass.roughness = 0.1
		_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _glass


## Milchglas: lässt Licht und Umrisse durch, aber keinen klaren Blick.
static func frosted_glass() -> StandardMaterial3D:
	if _frosted == null:
		_frosted = StandardMaterial3D.new()
		_frosted.albedo_color = Color(0.82, 0.84, 0.8, 0.86)
		_frosted.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_frosted.roughness = 1.0
		_frosted.cull_mode = BaseMaterial3D.CULL_DISABLED
		_frosted.emission_enabled = true
		_frosted.emission = Color(0.05, 0.05, 0.045)
	return _frosted
