extends Node
## Einstellungen (Autoload „Settings“, Spielkonzept 8.4). Gelten für alle Spielstände und
## liegen getrennt davon in user://settings.cfg.

signal changed

const PATH := "user://settings.cfg"
## Interne Auflösung (PS1-Look): Breite × Höhe
const RESOLUTIONS: Array[Vector2i] = [Vector2i(480, 270), Vector2i(640, 360), Vector2i(960, 540)]
## Shader mit Nearest-Filter – ohne PS1-Look werden ihre Texturen weich gefiltert
const PSX_SHADERS := ["res://shaders/psx_surface.gdshader", "res://shaders/psx_guest.gdshader",
	"res://shaders/psx_ghost.gdshader", "res://shaders/psx_particle.gdshader", "res://shaders/psx_photo.gdshader",
	"res://shaders/psx_leaves.gdshader"]

# Bild
var gamma := 1.0                 ## Helligkeit (0,6 … 1,8)
var fullscreen := false          ## wird nicht gespeichert – das Spiel startet immer im Fenster
var vsync := true
var fov := 72.0
var reflections := true          ## Spiegelungen auf glatten Flächen (SSR: Lobbymarmor, Pool, Tapetenlack) – kostet Leistung
# PS1-Look
var psx_look := true             ## Hauptschalter: aus = volle Auflösung, glatte Texturen, kein Wackeln/Dithering
var resolution := 0              ## Index in RESOLUTIONS
var vertex_wobble := true
var dithering := true
# Ton
var master_volume := 1.0
var music_volume := 1.0
var effects_volume := 1.0
# Steuerung
var mouse_sensitivity := 1.0     ## Faktor
var invert_y := false
var crouch_toggle := false
# Barrierefreiheit
var flicker_intensity := 1.0     ## Flackern und Bildrauschen (0,2 … 1)
var subtitles := false
var warning_shown := false       ## Hinweis zur Lichtempfindlichkeit schon gezeigt
var age_notice_shown := false    ## Hinweis mit Altersempfehlung schon gezeigt

## Hält die PSX_SHADERS geladen, damit jedes load() dieselbe (umgeschaltete) Instanz liefert
var _shaders: Array[Shader] = []

const KEYS := ["gamma", "vsync", "fov", "reflections", "psx_look", "resolution", "vertex_wobble", "dithering",
	"master_volume", "music_volume", "effects_volume", "mouse_sensitivity", "invert_y",
	"crouch_toggle", "flicker_intensity", "subtitles", "warning_shown", "age_notice_shown"]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	apply()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	for key in KEYS:
		if cfg.has_section_key("settings", key):
			set(key, cfg.get_value("settings", key))


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for key in KEYS:
		cfg.set_value("settings", key, get(key))
	if cfg.save(PATH) != OK:
		push_warning("Einstellungen konnten nicht gespeichert werden: " + PATH)


## Einen Wert ändern, sofort anwenden und speichern.
func set_value(key: String, value) -> void:
	set(key, value)
	apply()
	save_settings()


func apply() -> void:
	var window := get_window()
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	if DisplayServer.window_get_mode() != mode and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(mode)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	if psx_look:
		# Höhere interne Auflösung: 3D schärfer, Bedienoberfläche gleich groß
		var res := RESOLUTIONS[clampi(resolution, 0, RESOLUTIONS.size() - 1)]
		window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		window.content_scale_size = res
		window.content_scale_factor = float(res.x) / 480.0
	else:
		# 3D in Fensterauflösung, Bedienoberfläche wie bisher auf 480 × 270 ausgelegt und hochskaliert
		window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		window.content_scale_size = RESOLUTIONS[0]
		window.content_scale_factor = 1.0
	RenderingServer.global_shader_parameter_set("psx_snap", 1.0 if psx_look and vertex_wobble else 0.0)
	RenderingServer.global_shader_parameter_set("psx_smooth", 0.0 if psx_look else 1.0)   # Tapete (psx_wall)
	RenderingServer.global_shader_parameter_set("reflections", 1.0 if reflections else 0.0)   # Spiegelanteil (psx_photo)
	_apply_texture_filter(psx_look)
	Mat.set_photo_detail(psx_look)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.0001)))
	changed.emit()


## Dithering im Nachbearbeitungs-Shader – nur mit PS1-Look
func dither_on() -> bool:
	return psx_look and dithering


## Filter-Hinweis lässt sich nicht per Uniform umschalten: Shader-Code der geteilten Shader-Ressourcen
## umschreiben, alle Materialien damit übernehmen ihn.
func _apply_texture_filter(nearest: bool) -> void:
	if _shaders.is_empty():
		for path in PSX_SHADERS:
			_shaders.append(load(path))
	var from := "filter_linear_mipmap" if nearest else "filter_nearest"
	var to := "filter_nearest" if nearest else "filter_linear_mipmap"
	for shader in _shaders:
		if shader.code.contains(from):
			shader.code = shader.code.replace(from, to)


## Für das Kalibrierbild: so hell erscheint ein Farbwert mit der aktuellen Helligkeit.
func preview(c: Color) -> Color:
	var g := 1.0 / gamma
	return Color(pow(c.r, g), pow(c.g, g), pow(c.b, g), c.a)
