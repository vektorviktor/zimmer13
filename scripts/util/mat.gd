class_name Mat
## Materialien (Spielkonzept 9.2, realistischer Look). Mat.psx heißt nur noch so.

# --- Tuning
## Tapeten (Spielkonzept 7.2): Farbvariante → [Muster, Kachelgröße in Metern]. Farbe wallpaper_<variante>.png, Normal
## Map (OpenGL) und Rauheit je Muster wallpaper_<muster>_normal.png / _rough.png – nahtlose, hochaufgelöste Kacheln
## mit Mipmaps. Breite der Kachel = Bahnbreite (psx_wall strip_width 0,53 m), damit Muster und Bahnen
## zusammenpassen. Die Rautentapeten zeichnet tools/build_wallpaper.py; eigene Tapeten im selben Format hier eintragen.
const WALLPAPERS := {
	"teal": ["harlequin", Vector2(0.53, 0.53)],
	"red": ["harlequin", Vector2(0.53, 0.53)],
	"beige": ["harlequin", Vector2(0.53, 0.53)],
	"brown": ["harlequin", Vector2(0.53, 0.53)],
}
const WALLPAPER_PATH := "res://assets/textures/wallpaper_%s.png"
const WALLPAPER_NORMAL_PATH := "res://assets/textures/wallpaper_%s_normal.png"
const WALLPAPER_ROUGH_PATH := "res://assets/textures/wallpaper_%s_rough.png"
## Holz (Leiste unter der Decke, gemalte Vertäfelung): Bild je Variante (oak …) mit eigener Höhenkarte, im Spiel auf
## diese Breite verkleinert (Höhe im selben Verhältnis) und über so viele Meter Wand gespannt
const WAINSCOT_PATH := "res://assets/textures/wainscot_%s.png"
const WAINSCOT_BUMP_PATH := "res://assets/textures/wainscot_bump.png"
const WALLPAPER_SRC_SIZE := 512
const WALLPAPER_SIZE := 256
const WALLPAPER_METERS := 3.5
## Bänder im Holzbild als Pixelzeilen [von, bis): Leiste, Vertäfelung
const WALLPAPER_FRIEZE := Vector2(0, 12)
const WALLPAPER_BASE := Vector2(20, 128)
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
## Fototexturen (PBR-Sets in assets/textures/<set>/): höchste Kantenlänge des Farbbilds (weich gefiltert, mit
## Mipmaps – aus der Nähe scharf, in der Ferne ruhig)
const PHOTO_SIZE := 1024
## Holz für Mat.wood (Balkenbett): helle Eiche, AO × 0,6 eingebacken
const WOOD_TEX := "res://assets/textures/Wood_02/Wood02_basecolor.jpg"
const WOOD_NORMAL := "res://assets/textures/Wood_02/Wood02_normalOgl.jpg"
## Holz der Vertäfelung (Spielkonzept 7.2), der Zimmertüren und ihrer Rahmen (Mat.hotel_wood – überall dieselbe Optik,
## Wunsch des Nutzers 30.10.): Wood067 (ambientCG, CC0, dunkle Nuss, Faser waagerecht) über die Mesh-UVs, so viele
## Meter je Kachel (nicht im Verhältnis zu Wainscot.MODULE, sonst glichen sich die Felder), dunkel getönt wie der
## Türrahmen, der dem Nutzer am besten gefiel, seidenmatt; das Farbbild ohne die großen Wolken
## (tools/wainscot_wood.py), dazu je Teil eine gebackene Verschattung (tools/build_wainscot.py, build_room_door.py)
const WAINSCOT_TEX := "res://assets/textures/wainscot_wood.png"
const WAINSCOT_NORMAL := "res://assets/textures/Wood067/Wood067_2K-JPG_NormalGL.jpg"
const WAINSCOT_ROUGH := "res://assets/textures/Wood067/Wood067_2K-JPG_Roughness.jpg"
const WAINSCOT_AO := "res://assets/textures/wainscot_ao.png"
const DOOR_AO := "res://assets/textures/door_room_ao.png"
const WAINSCOT_METERS := 0.7
const WAINSCOT_TINT := Color(0.74, 0.72, 0.71)
const WAINSCOT_GLOSS := 0.35
## Bohlen (Mat.planks): eine Kachel über so viele Meter, so viele Bretter darin, Fugenbreite in Texeln, Abdunklung
const PLANK_METERS := 2.0
const PLANK_ROWS := 8
const PLANK_GAP := 4
const PLANK_DARKEN := 0.45
## Bowlingbahn (Mat.lane_boards): eine Kachel über so viele Meter, so viele schmale Riemen quer darin (≈ 2,5 cm wie
## auf echten Bahnen), Abdunklung je Riemen, Fuge in Texeln
const LANE_METERS := 0.8
const LANE_BOARDS := 32
const LANE_DARKEN := 0.18
const LANE_GAP := 1
## Milchglas (Mat.frosted_glass, ZIM-143): satinierte Oberfläche aus tools/frosted_glass.gd (Normal Map, Rauheit),
## eine Kachel über so viele Meter; Farbe mit Deckkraft, Licht von hinten (die Seite gegenüber leuchtet durch)
const FROSTED_TEX := "res://assets/textures/frosted_glass"
const FROSTED_METERS := 0.12
const FROSTED_COLOR := Color(0.8, 0.83, 0.81, 0.8)
const FROSTED_BACKLIGHT := Color(0.35, 0.35, 0.33)

static var _shader: Shader
static var _shader_two_sided: Shader
static var _shader_wet: Shader
static var _wall_shader: Shader
static var _particle_shader: Shader
static var _leaves_shader: Shader
static var _decal_shader: Shader
static var _wall_albedo := {}
static var _papers := {}   # Tapete → Texturen (_paper)
static var _wood_surface: ImageTexture
static var _cache := {}
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


## Boden draußen, der im Regen nass wird (Weather, shaders/wet_ground.gdshaderinc): gloss = so glatt, wenn ganz nass.
## psx_surface rechnet sonst keinen Glanz – solche Flächen bekommen eine Abwandlung mit Glanz.
static func wettable(m: ShaderMaterial, gloss: float) -> void:
	if m.shader == _shader:
		if _shader_wet == null:
			_shader_wet = Shader.new()
			_shader_wet.code = _shader.code.replace("specular_disabled", "specular_schlick_ggx")
		m.shader = _shader_wet
	m.set_shader_parameter("wettable", true)
	m.set_shader_parameter("wet_gloss", gloss)


## PSX-Material mit der Farbtextur aus einer importierten GLB – eins pro Textur der Modelldatei
## (surface = Fläche des Meshs, deren Material die Textur liefert). two_sided zeichnet auch die
## Rückseiten – für einseitige Flächen wie Meshys Blätter. cutout stanzt nach dem Alpha der Textur aus
## (Blattkarten der Bäume, shaders/psx_leaves.gdshader) und ist immer beidseitig.
static func model(path: String, src: MeshInstance3D, surface: int = 0, two_sided: bool = false, cutout: bool = false) -> ShaderMaterial:
	var tex := (src.get_active_material(surface) as BaseMaterial3D).albedo_texture
	var key := "model|%s|%d|%s" % [path, tex.get_instance_id() if tex else 0, cutout]
	if not _cache.has(key):
		var m := psx(Color(0.8, 0.8, 0.8), "", 1.0, Color.BLACK, 0.0, false)
		m.set_shader_parameter("albedo_tex", tex)
		if cutout:
			if _leaves_shader == null:
				_leaves_shader = load("res://shaders/psx_leaves.gdshader")
			m.shader = _leaves_shader
			m.set_shader_parameter("albedo", Color(0.8, 0.8, 0.8))
			m.set_shader_parameter("albedo_tex", tex)
		elif two_sided:
			if _shader_two_sided == null:
				_shader_two_sided = Shader.new()
				_shader_two_sided.code = m.shader.code.replace("cull_back", "cull_disabled")
			m.shader = _shader_two_sided
		_cache[key] = m
	return _cache[key]


## Material aus einem Foto (PBR-Set, z. B. Beton) mit shaders/psx_photo.gdshader, in Weltkoordinaten über meters
## Meter gespannt, Normal Map (normal_path) im OpenGL-Format. Glanz (specular > 0, z. B. 0,5) mit der Rauheit aus
## roughness_path wie die Tapete. Die übrigen Karten des Sets löscht tools/photo_set.gd, siehe TECHNIK.md. object_uv: Textur in
## Modellkoordinaten statt in Weltkoordinaten (Bewegtes wie die Aufzugskabine). mesh_uv: über die UVs des Meshs (in
## Metern) – Holz mit Faserrichtung (Geo.grain_box).
static func photo(path: String, meters: float, normal_path: String = "", roughness_path: String = "",
		specular: float = 0.0, color: Color = Color(1, 1, 1), object_uv: bool = false, mesh_uv: bool = false) -> ShaderMaterial:
	var key := "photo|%s|%s|%s|%.2f|%.2f|%s|%s|%s" % [path, normal_path, roughness_path, meters, specular, color.to_html(), object_uv, mesh_uv]
	if not _cache.has(key):
		_cache[key] = _photo_from(_photo_image(path), _photo_image(normal_path) if normal_path != "" else null,
			roughness_path, meters, specular, color, object_uv, mesh_uv)
	return _cache[key]


## Fotomaterial aus fertigen Bildern (Farbe RGB8 höchstens PHOTO_SIZE, Normal Map oder null) – für Mat.photo und
## zusammengesetzte Bilder wie die Bohlen (Mat.planks).
static func _photo_from(img: Image, normal: Image, roughness_path: String, meters: float, specular: float, color: Color,
		object_uv: bool, mesh_uv: bool) -> ShaderMaterial:
	if _photo_shader == null:
		_photo_shader = load("res://shaders/psx_photo.gdshader")
	img.generate_mipmaps()
	var m := ShaderMaterial.new()
	m.shader = _photo_shader
	m.set_shader_parameter("albedo", color)
	m.set_shader_parameter("tex_scale", 1.0 / meters)
	m.set_shader_parameter("specular", specular)
	m.set_shader_parameter("object_uv", object_uv)
	m.set_shader_parameter("mesh_uv", mesh_uv)
	m.set_shader_parameter("albedo_tex", ImageTexture.create_from_image(img))
	if normal:
		normal.generate_mipmaps(true)   # gemittelte Normalen wieder auf Länge 1
		m.set_shader_parameter("normal_tex", ImageTexture.create_from_image(normal))
		m.set_shader_parameter("use_normal", true)
	if roughness_path != "":
		var rough := _photo_image(roughness_path)
		rough.generate_mipmaps()
		m.set_shader_parameter("roughness_tex", ImageTexture.create_from_image(rough))
		m.set_shader_parameter("use_roughness", true)
	return m


## Bild einer Fototextur als RGB8, höchstens PHOTO_SIZE (tools/photo_set.gd schneidet es schon zu;
## kleinere Karten wie die Rauheit bleiben, wie sie sind).
static func _photo_image(path: String) -> Image:
	var img := (load(path) as Texture2D).get_image()
	img.decompress()
	img.convert(Image.FORMAT_RGB8)
	if img.get_width() > PHOTO_SIZE or img.get_height() > PHOTO_SIZE:
		img.resize(PHOTO_SIZE, PHOTO_SIZE, Image.INTERPOLATE_LANCZOS)
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


## Flache Auflage mit Umriss aus dem Alpha einer Bilddatei (shaders/psx_decal.gdshader, Blut, Wachs, Kürbismatsch) –
## eigenes Material je Aufruf, damit jede für sich verblassen kann (Parameter `fade`). Liegen daneben <name>_n.png und
## <name>_d.png (tools/splat_maps.gd), kommen Normal Map und Detailkarte dazu; den Look stellt TraceMark.splat_look ein.
static func decal(path: String) -> ShaderMaterial:
	if _decal_shader == null:
		_decal_shader = load("res://shaders/psx_decal.gdshader")
	var m := ShaderMaterial.new()
	m.shader = _decal_shader
	m.set_shader_parameter("albedo_tex", load(path))
	var base := path.get_basename()
	if ResourceLoader.exists(base + "_n.png"):
		m.set_shader_parameter("normal_tex", load(base + "_n.png"))
		m.set_shader_parameter("use_normal", true)
	if ResourceLoader.exists(base + "_d.png"):
		m.set_shader_parameter("detail_tex", load(base + "_d.png"))
		m.set_shader_parameter("use_detail", true)
	return m


## Für flache Auflagen auf einer anderen Fläche (Teppich auf Fliesen, Kassetten auf dem Türblatt):
## wird leicht zur Kamera gezogen, damit die Unterlage nicht durchflimmert.
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
	return layer_tex(TexGen.get_tex(tex_id), pull)


## Wie `layer_uv`, aber mit fertiger Textur (Teppiche: TexGen.rug je Größe).
static func layer_tex(tex: Texture2D, pull: float = 0.01) -> ShaderMaterial:
	var key := "layer_uv|%d|%.4f" % [tex.get_instance_id(), pull]
	if not _cache.has(key):
		var m := psx(Color(1, 1, 1), "", 1.0, Color.BLACK, 0.0, false)
		m.set_shader_parameter("albedo_tex", tex)
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
## storey = Stockwerkshöhe, ab deren Vielfachen die Vertäfelung neu beginnt; variant = Tapete (WALLPAPERS), wood = Holz.
static func wallpaper(wall_top: float, storey: float, variant: String = "teal", wood: String = "oak") -> ShaderMaterial:
	var key := "wallpaper|%s|%s|%.2f|%.2f" % [variant, wood, wall_top, storey]
	if _cache.has(key):
		return _cache[key]
	if _wall_shader == null:
		_wall_shader = load("res://shaders/psx_wall.gdshader")
		_wood_surface = _wall_surface_from(WAINSCOT_BUMP_PATH)
	if not _wall_albedo.has("wood:" + wood):
		_wall_albedo["wood:" + wood] = _load_wall_albedo(WAINSCOT_PATH % wood)
	var paper := _paper(variant)
	var m := ShaderMaterial.new()
	m.shader = _wall_shader
	m.set_shader_parameter("paper_tex", paper["color"])
	m.set_shader_parameter("paper_normal", paper["normal"])
	m.set_shader_parameter("paper_rough", paper["rough"])
	m.set_shader_parameter("paper_tile", paper["tile"])
	m.set_shader_parameter("wood_tex", _wall_albedo["wood:" + wood])
	m.set_shader_parameter("wood_surface_tex", _wood_surface)
	m.set_shader_parameter("texels_per_m", WALLPAPER_SIZE / WALLPAPER_METERS)
	var s := WALLPAPER_SIZE / float(WALLPAPER_SRC_SIZE)
	m.set_shader_parameter("frieze_rows", WALLPAPER_FRIEZE * s)
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
		for param in ["paper_tex", "paper_normal", "paper_rough", "paper_tile", "wood_tex"]:
			m.set_shader_parameter(param + "_b", b.get_shader_parameter(param))
		m.set_shader_parameter("wall_top_b", b.get_shader_parameter("wall_top"))
		m.set_shader_parameter("storey_b", b.get_shader_parameter("storey"))
		_cache[key] = m
	return _cache[key]


## Texturen einer Tapete aus WALLPAPERS: Farbe, Normal Map und Rauheit in voller Größe mit Mipmaps (color, normal,
## rough); tile = Kachel in Metern.
static func _paper(variant: String) -> Dictionary:
	if not _papers.has(variant):
		var pattern: String = WALLPAPERS[variant][0]
		var tile: Vector2 = WALLPAPERS[variant][1]
		var color := _photo_image(WALLPAPER_PATH % variant)
		var normal := _photo_image(WALLPAPER_NORMAL_PATH % pattern)
		var rough := _photo_image(WALLPAPER_ROUGH_PATH % pattern)
		color.generate_mipmaps()
		normal.generate_mipmaps(true)   # gemittelte Normalen wieder auf Länge 1
		rough.generate_mipmaps()
		_papers[variant] = {"tile": tile, "color": ImageTexture.create_from_image(color),
			"normal": ImageTexture.create_from_image(normal), "rough": ImageTexture.create_from_image(rough)}
	return _papers[variant]


## Farbbild des Holzes, verkleinert.
static func _load_wall_albedo(path: String) -> ImageTexture:
	var img := (load(path) as Texture2D).get_image()
	img.decompress()
	img.convert(Image.FORMAT_RGB8)
	var s := WALLPAPER_SIZE / float(WALLPAPER_SRC_SIZE)
	img.resize(WALLPAPER_SIZE, roundi(img.get_height() * s), Image.INTERPOLATE_BILINEAR)
	return ImageTexture.create_from_image(img)


## Oberfläche des Holzes aus seiner Höhenkarte: R = Höhe, G = Glanz der Stufe.
static func _wall_surface_from(path: String) -> ImageTexture:
	var bump := (load(path) as Texture2D).get_image()
	bump.decompress()
	bump.convert(Image.FORMAT_L8)
	var s := WALLPAPER_SIZE / float(WALLPAPER_SRC_SIZE)
	bump.resize(WALLPAPER_SIZE, roundi(bump.get_height() * s), Image.INTERPOLATE_NEAREST)
	var surf := Image.create(bump.get_width(), bump.get_height(), false, Image.FORMAT_RG8)
	for y in bump.get_height():
		for x in bump.get_width():
			var level := bump.get_pixel(x, y).r8
			surf.set_pixel(x, y, Color(level / 255.0, _gloss_for(level), 0.0))
	return ImageTexture.create_from_image(surf)


## Glanz der nächstgelegenen Stufe aus WALLPAPER_GLOSS.
static func _gloss_for(level: int) -> float:
	var best := 0
	for l: int in WALLPAPER_GLOSS:
		if absi(l - level) < absi(best - level):
			best = l
	return WALLPAPER_GLOSS[best]


## Holz mit eigener Faserrichtung für Geo.grain_box (Balkenbett): Fläche 0 Längsholz als Foto (Wood_02, helle Eiche,
## Faser im Bild waagerecht, über die UVs in Metern), Fläche 1 Hirnholz (end = true, TexGen „wood_end“ – das Set hat
## keins). tint färbt beide.
static func wood(end: bool, tint: Color = Color(1, 1, 1)) -> ShaderMaterial:
	if not end:
		return photo(WOOD_TEX, 1.0, WOOD_NORMAL, "", 0.0, tint, false, true)
	var key := "wood_end|%s" % tint.to_html()
	if not _cache.has(key):
		var m := psx(tint, "", 1.0, Color.BLACK, 0.0, false)
		m.set_shader_parameter("albedo_tex", TexGen.get_tex("wood_end"))
		_cache[key] = m
	return _cache[key]


## Holz der Vertäfelung (LevelBuilder._wainscot): Wood067 über die UVs des Bausatzes, gebackene Verschattung über UV2.
static func wainscot() -> ShaderMaterial:
	if not _cache.has("wainscot"):
		var m := hotel_wood(WAINSCOT_AO).duplicate() as ShaderMaterial
		m.set_shader_parameter("instance_shift", true)
		_cache["wainscot"] = m
	return _cache["wainscot"]


## Holz der Vertäfelung, Zimmertüren und Türrahmen (WAINSCOT_*): ohne Verschattung (DoorCasing) bzw. mit einer
## gebackenen über UV2 (ao_path: Vertäfelung, Türblatt aus tools/build_room_door.py); Möbel (tools/furniture_kit.py)
## dazu mit gebackener Normale über UV2 (normal_path, Objektraum – Furchen und Lamellen des Schranks)
static func hotel_wood(ao_path: String = "", normal_path: String = "") -> ShaderMaterial:
	var key := "hotel_wood|" + ao_path + "|" + normal_path
	if not _cache.has(key):
		var m := photo(WAINSCOT_TEX, WAINSCOT_METERS, WAINSCOT_NORMAL, WAINSCOT_ROUGH, WAINSCOT_GLOSS, WAINSCOT_TINT,
			false, true)
		if ao_path != "" or normal_path != "":
			m = m.duplicate() as ShaderMaterial
		if ao_path != "":
			m.set_shader_parameter("ao_tex", load(ao_path))
			m.set_shader_parameter("use_ao", true)
		if normal_path != "":
			m.set_shader_parameter("detail_tex", load(normal_path))
			m.set_shader_parameter("use_detail", true)
		_cache[key] = m
	return _cache[key]


## Grobe Bohlen (Dachboden, Spielkonzept 4.21): aus dem Längsholz von Wood_02 zusammengesetzt, eine Kachel über
## PLANK_METERS – PLANK_ROWS Reihen, jede mit zwei Stößen an zufälliger Stelle, je Brett ein anderer Ausschnitt und
## eine andere Abdunklung (bis PLANK_DARKEN), dunkle Fugen (PLANK_GAP Texel) dazwischen. Die Faser liegt waagerecht
## wie im Foto, die Projektion von psx_photo legt die Bretter also an Wänden waagerecht, auf Böden und Decken
## entlang x. tint färbt alles (altes, graues Holz).
static func planks(tint: Color) -> ShaderMaterial:
	var key := "planks|%s" % tint.to_html()
	if _cache.has(key):
		return _cache[key]
	var src := _photo_image(WOOD_TEX)
	var src_normal := _photo_image(WOOD_NORMAL)
	var size := src.get_width()
	var row := size / PLANK_ROWS
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var normal := Image.create(size, size, false, Image.FORMAT_RGB8)
	src.convert(Image.FORMAT_RGBA8)
	var shade := Image.create(size, row, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4021
	var joints: Array[Vector2i] = []
	for r in PLANK_ROWS:
		var start := rng.randi_range(0, size - 1)
		var cut := rng.randi_range(size * 2 / 5, size * 3 / 5)
		for piece in 2:
			var x := start if piece == 0 else start + cut
			var length := cut if piece == 0 else size - cut
			var from := Vector2i(rng.randi_range(0, size - 1), rng.randi_range(0, size - row))
			_blit_wrapped(img, src, from, Vector2i(x, r * row), length, row)
			_blit_wrapped(normal, src_normal, from, Vector2i(x, r * row), length, row)
			shade.fill(Color(0.1, 0.08, 0.06, rng.randf_range(0.0, PLANK_DARKEN)))
			_blit_wrapped(img, shade, Vector2i.ZERO, Vector2i(x, r * row), length, row, true)
			joints.append(Vector2i(posmod(x, size), r * row))
	var gap := Color(0.05, 0.04, 0.03)
	var flat := Color(0.5, 0.5, 1.0)
	for r in PLANK_ROWS:
		img.fill_rect(Rect2i(0, r * row, size, PLANK_GAP), gap)
		normal.fill_rect(Rect2i(0, r * row, size, PLANK_GAP), flat)
	for j in joints:
		img.fill_rect(Rect2i(mini(j.x, size - PLANK_GAP), j.y, PLANK_GAP, row), gap)
		normal.fill_rect(Rect2i(mini(j.x, size - PLANK_GAP), j.y, PLANK_GAP, row), flat)
	img.convert(Image.FORMAT_RGB8)
	_cache[key] = _photo_from(img, normal, "", PLANK_METERS, 0.0, tint, false, false)
	return _cache[key]


## Versiegeltes Parkett der Bowlingbahn (Spielkonzept 6.10, 28.10.): schmale Riemen aus dem Längsholz von Wood_02, um
## 90° gedreht – die Faser läuft senkrecht im Bild, auf dem Boden also entlang z (die Bahn läuft von Süden nach Norden).
## Je Riemen ein anderer Ausschnitt, eine andere Abdunklung (bis LANE_DARKEN) und ein Stoß an zufälliger Stelle;
## feine Fugen (LANE_GAP). Ohne Normal Map: der Lack macht die Oberfläche glatt, den Glanz setzt der Aufrufer.
static func lane_boards(tint: Color) -> ShaderMaterial:
	var key := "lane|%s" % tint.to_html()
	if _cache.has(key):
		return _cache[key]
	var src := _photo_image(WOOD_TEX)
	src.rotate_90(CLOCKWISE)
	src.convert(Image.FORMAT_RGBA8)
	var size := src.get_width()
	var board := size / LANE_BOARDS
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var shade := Image.create(board, size, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 6100
	var gap := Color(0.12, 0.08, 0.05)
	for i in LANE_BOARDS:
		var x := i * board
		var from := Vector2i(rng.randi_range(0, size - board), rng.randi_range(0, size - 1))
		img.blit_rect(src, Rect2i(from.x, from.y, board, size - from.y), Vector2i(x, 0))   # senkrecht gekachelt
		if from.y > 0:
			img.blit_rect(src, Rect2i(from.x, 0, board, from.y), Vector2i(x, size - from.y))
		shade.fill(Color(0.1, 0.07, 0.04, rng.randf_range(0.0, LANE_DARKEN)))
		img.blend_rect(shade, Rect2i(0, 0, board, size), Vector2i(x, 0))
		img.fill_rect(Rect2i(x, 0, LANE_GAP, size), gap)
		img.fill_rect(Rect2i(x, rng.randi_range(0, size - 1), board, LANE_GAP), gap)   # Stoß
	img.convert(Image.FORMAT_RGB8)
	_cache[key] = _photo_from(img, null, "", LANE_METERS, 0.0, tint, false, false)
	return _cache[key]


## Streifen der Länge length (Zeilen h) aus src ab from nach dst ab to kopieren – beide Bilder kacheln waagerecht,
## über den Rand geht es vorn weiter. blend: mit Alpha darüberlegen statt ersetzen.
static func _blit_wrapped(dst: Image, src: Image, from: Vector2i, to: Vector2i, length: int, h: int, blend := false) -> void:
	var w := dst.get_width()
	var sw := src.get_width()
	var done := 0
	while done < length:
		var s := posmod(from.x + done, sw)
		var d := posmod(to.x + done, w)
		var n := mini(length - done, mini(sw - s, w - d))
		if blend:
			dst.blend_rect(src, Rect2i(s, from.y, n, h), Vector2i(d, to.y))
		else:
			dst.blit_rect(src, Rect2i(s, from.y, n, h), Vector2i(d, to.y))
		done += n


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


## Milchglas: lässt Licht und Umrisse durch, aber keinen klaren Blick. Satiniert (Normal Map und Rauheit in voller
## Größe mit Mipmaps), dreiseitig in Modellkoordinaten projiziert – die Körnung bleibt beim Öffnen auf der Scheibe.
static func frosted_glass() -> StandardMaterial3D:
	if _frosted == null:
		_frosted = StandardMaterial3D.new()
		_frosted.albedo_color = FROSTED_COLOR
		_frosted.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_frosted.cull_mode = BaseMaterial3D.CULL_DISABLED
		var normal := _photo_image(FROSTED_TEX + "_normal.png")
		normal.generate_mipmaps(true)   # gemittelte Normalen wieder auf Länge 1
		var rough := _photo_image(FROSTED_TEX + "_rough.png")
		rough.generate_mipmaps()
		_frosted.normal_enabled = true
		_frosted.normal_texture = ImageTexture.create_from_image(normal)
		_frosted.roughness = 1.0
		_frosted.roughness_texture = ImageTexture.create_from_image(rough)
		_frosted.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
		_frosted.uv1_triplanar = true
		_frosted.uv1_scale = Vector3.ONE / FROSTED_METERS
		_frosted.backlight_enabled = true
		_frosted.backlight = FROSTED_BACKLIGHT
		_frosted.emission_enabled = true
		_frosted.emission = Color(0.05, 0.05, 0.045)
	return _frosted


## Modell mit glTF-PBR-Set als Dateien neben der GLB (base + „_albedo.png“, „_normal.png“ OpenGL, „_orm.png“: Rot
## Verdeckung, Grün Rauheit, Blau Metall), jede Karte in voller Größe mit Mipmaps. metallic dämpft das Metall der Karte – voll
## metallisch spiegelt Messing fast nur die dunkle Umgebung (wie beim Mülleimer). Erstes Modell: Desk (ZIM-150).
static func pbr_model(base: String, metallic: float = 1.0) -> StandardMaterial3D:
	var key := "pbr|%s|%.2f" % [base, metallic]
	if not _cache.has(key):
		var m := StandardMaterial3D.new()
		m.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT
		m.albedo_texture = _mipmapped(base + "_albedo.png", false)
		m.normal_enabled = true
		m.normal_texture = _mipmapped(base + "_normal.png", true)
		var orm := _mipmapped(base + "_orm.png", false)
		m.roughness = 1.0
		m.roughness_texture = orm
		m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
		m.metallic = metallic
		m.metallic_texture = orm
		m.metallic_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_BLUE
		m.ao_enabled = true   # ohne gebackene Verdeckung steht Rot auf 1
		m.ao_texture = orm
		m.ao_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_RED
		_cache[key] = m
	return _cache[key]


## Textur mit Mipmaps (normal: gemittelte Normalen wieder auf Länge 1)
static func _mipmapped(path: String, normal: bool) -> ImageTexture:
	var img := (load(path) as Texture2D).get_image()
	img.decompress()
	img.generate_mipmaps(normal)
	return ImageTexture.create_from_image(img)
