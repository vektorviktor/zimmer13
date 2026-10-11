class_name Mat
## Materialien im PS1-Stil (Vertex-Snapping, Nearest-Filter, kein Glanz).

static var _shader: Shader
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


## Für flache Auflagen auf einer anderen Fläche (Teppich auf Fliesen, Kassetten auf dem Türblatt):
## wird leicht zur Kamera gezogen, damit die Unterlage beim Vertex-Snapping nicht durchflimmert.
static func layer(color: Color, tex_id: String = "", tex_scale: float = 1.0) -> ShaderMaterial:
	var key := "layer|%s|%s|%.3f" % [color.to_html(), tex_id, tex_scale]
	if _cache.has(key):
		return _cache[key]
	var m := psx(color, tex_id, tex_scale, Color.BLACK, 0.0, false)
	m.set_shader_parameter("layer_pull", 0.01)
	_cache[key] = m
	return m


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
