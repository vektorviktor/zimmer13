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
## Fototexturen (PBR-Sets in assets/textures/<set>/): Kantenlänge des Farbbilds mit PS1-Look (Texel für Texel,
## grob wie die Tapete) und ohne (weich gefiltert, mit Mipmaps – aus der Nähe scharf, in der Ferne ruhig)
const PHOTO_SIZE_PSX := 256
const PHOTO_SIZE_SMOOTH := 1024

static var _shader: Shader
static var _shader_two_sided: Shader
static var _wall_shader: Shader
static var _particle_shader: Shader
static var _leaves_shader: Shader
static var _decal_shader: Shader
static var _wall_albedo := {}
static var _wall_surface: ImageTexture
static var _cache := {}
static var _photos: Array[ShaderMaterial] = []
static var _photo_shader: Shader
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


## Material aus einem Foto (PBR-Set, z. B. Beton) mit shaders/psx_photo.gdshader, in Weltkoordinaten über meters
## Meter gespannt. Das Farbbild liegt in zwei Stufen vor (PHOTO_SIZE_PSX ohne, PHOTO_SIZE_SMOOTH mit Mipmaps), die
## Normal Map (normal_path, OpenGL-Format) nur in der großen und nur ohne PS1-Look – Settings.apply schaltet über
## set_photo_detail um. Glanz (specular > 0, z. B. 0,5) mit der Rauheit aus roughness_path wirkt in beiden Looks
## (wie die Tapete). Die übrigen Karten des Sets löscht tools/photo_set.gd, siehe TECHNIK.md.
static func photo(path: String, meters: float, normal_path: String = "", roughness_path: String = "",
		specular: float = 0.0, color: Color = Color(1, 1, 1)) -> ShaderMaterial:
	var key := "photo|%s|%s|%s|%.2f|%.2f|%s" % [path, normal_path, roughness_path, meters, specular, color.to_html()]
	if not _cache.has(key):
		if _photo_shader == null:
			_photo_shader = load("res://shaders/psx_photo.gdshader")
		var img := _photo_image(path)
		var small := img.duplicate() as Image
		small.resize(PHOTO_SIZE_PSX, PHOTO_SIZE_PSX, Image.INTERPOLATE_LANCZOS)
		img.generate_mipmaps()
		var m := ShaderMaterial.new()
		m.shader = _photo_shader
		m.set_shader_parameter("albedo", color)
		m.set_shader_parameter("tex_scale", 1.0 / meters)
		m.set_shader_parameter("specular", specular)
		m.set_meta("photo_psx", ImageTexture.create_from_image(small))
		m.set_meta("photo_smooth", ImageTexture.create_from_image(img))
		if normal_path != "":
			var normal := _photo_image(normal_path)
			normal.generate_mipmaps(true)   # gemittelte Normalen wieder auf Länge 1
			m.set_shader_parameter("normal_tex", ImageTexture.create_from_image(normal))
		if roughness_path != "":
			var rough := _photo_image(roughness_path)
			rough.generate_mipmaps()
			m.set_shader_parameter("roughness_tex", ImageTexture.create_from_image(rough))
			m.set_shader_parameter("use_roughness", true)
		_photos.append(m)
		_cache[key] = m
		_set_photo_detail(m, Settings.psx_look)
	return _cache[key]


## Alle Fotomaterialien auf die Stufe für den PS1-Look (psx = true) bzw. ohne ihn umstellen.
static func set_photo_detail(psx: bool) -> void:
	for m in _photos:
		_set_photo_detail(m, psx)


static func _set_photo_detail(m: ShaderMaterial, psx: bool) -> void:
	m.set_shader_parameter("albedo_tex", m.get_meta("photo_psx" if psx else "photo_smooth"))
	m.set_shader_parameter("use_normal", not psx and m.get_shader_parameter("normal_tex") != null)


## Bild einer Fototextur als RGB8, höchstens PHOTO_SIZE_SMOOTH (tools/photo_set.gd schneidet es schon zu;
## kleinere Karten wie die Rauheit bleiben, wie sie sind).
static func _photo_image(path: String) -> Image:
	var img := (load(path) as Texture2D).get_image()
	img.decompress()
	img.convert(Image.FORMAT_RGB8)
	if img.get_width() > PHOTO_SIZE_SMOOTH or img.get_height() > PHOTO_SIZE_SMOOTH:
		img.resize(PHOTO_SIZE_SMOOTH, PHOTO_SIZE_SMOOTH, Image.INTERPOLATE_LANCZOS)
	return img


## Blattkarten (Hecken) mit shaders/psx_leaves.gdshader: Textur tex_id aus TexGen mit Alpha (ausgestanzt),
## beidseitig, abgedunkelt mit den Eckfarben.
static func leaves(tex_id: String) -> ShaderMaterial:
	var key := "leaves|" + tex_id
	if not _cache.has(key):
		if _leaves_shader == null:
			_leaves_shader = load("res://shaders/psx_leaves.gdshader")
		var m := ShaderMaterial.new()
		m.shader = _leaves_shader
		m.set_shader_parameter("albedo_tex", TexGen.get_tex(tex_id))
		_cache[key] = m
	return _cache[key]


## Flache Auflage mit Umriss aus dem Alpha einer Bilddatei (shaders/psx_decal.gdshader, Kürbismatsch) – eigenes
## Material je Aufruf, damit jede für sich verblassen kann (Parameter `fade`).
static func decal(path: String) -> ShaderMaterial:
	if _decal_shader == null:
		_decal_shader = load("res://shaders/psx_decal.gdshader")
	var m := ShaderMaterial.new()
	m.shader = _decal_shader
	m.set_shader_parameter("albedo_tex", load(path))
	return m


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


## Auflage wie `layer`, aber mit den UVs des Meshs statt Weltkoordinaten (Läufer: die Bordüre folgt dem Band).
static func layer_uv(tex_id: String, pull: float = 0.01) -> ShaderMaterial:
	var key := "layer_uv|%s|%.4f" % [tex_id, pull]
	if not _cache.has(key):
		var m := psx(Color(1, 1, 1), "", 1.0, Color.BLACK, 0.0, false)
		m.set_shader_parameter("albedo_tex", TexGen.get_tex(tex_id))
		m.set_shader_parameter("layer_pull", pull)
		_cache[key] = m
	return _cache[key]


## Partikel (shaders/psx_particle.gdshader): eigenes Material je Emitter, weitere Parameter (rainbow,
## sway, spin …) setzt der Aufrufer. frames = so viele Bilder nebeneinander in tex.
static func particle(tex: Texture2D = null, glow: float = 0.0, frames: int = 1) -> ShaderMaterial:
	if _particle_shader == null:
		_particle_shader = load("res://shaders/psx_particle.gdshader")
	var m := ShaderMaterial.new()
	m.shader = _particle_shader
	if tex:
		m.set_shader_parameter("albedo_tex", tex)
	m.set_shader_parameter("glow", glow)
	m.set_shader_parameter("frames", frames)
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


## Poliertes Metall (shaders/psx_metal.gdshader): spiegelt einen gedachten Raum, so hell wie die Lampen ihn
## beleuchten, mit Glanzpunkt – Edelstahl mit der Standardfarbe, Chrom heller. Je Farbe ein gemeinsames Material.
static func metal(tint: Color = Color(0.78, 0.8, 0.84)) -> ShaderMaterial:
	var key := "metal|%s" % tint.to_html()
	if not _cache.has(key):
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/psx_metal.gdshader")
		m.set_shader_parameter("tint", tint)
		_cache[key] = m
	return _cache[key]


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
