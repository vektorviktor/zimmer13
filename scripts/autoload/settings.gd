extends Node
## Einstellungen (Autoload „Settings“, Spielkonzept 8.4). Gelten für alle Spielstände und
## liegen getrennt davon in user://settings.cfg.

signal changed

const PATH := "user://settings.cfg"
## Interne Auflösung (PS1-Look): Breite × Höhe
const RESOLUTIONS: Array[Vector2i] = [Vector2i(480, 270), Vector2i(640, 360), Vector2i(960, 540)]

# Bild
var gamma := 1.0                 ## Helligkeit (0,6 … 1,8)
var fullscreen := false          ## wird nicht gespeichert – das Spiel startet immer im Fenster
var vsync := true
var fov := 72.0
# PS1-Look
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

const KEYS := ["gamma", "vsync", "fov", "resolution", "vertex_wobble", "dithering",
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
	cfg.save(PATH)


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
	# Höhere interne Auflösung: 3D schärfer, Bedienoberfläche gleich groß
	var res := RESOLUTIONS[clampi(resolution, 0, RESOLUTIONS.size() - 1)]
	window.content_scale_size = res
	window.content_scale_factor = float(res.x) / 480.0
	RenderingServer.global_shader_parameter_set("psx_snap", 1.0 if vertex_wobble else 0.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.0001)))
	changed.emit()


## Für das Kalibrierbild: so hell erscheint ein Farbwert mit der aktuellen Helligkeit.
func preview(c: Color) -> Color:
	var g := 1.0 / gamma
	return Color(pow(c.r, g), pow(c.g, g), pow(c.b, g), c.a)
