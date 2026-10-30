extends Node
## Einstellungen (Autoload „Settings“, Spielkonzept 8.4). Gelten für alle Spielstände und
## liegen getrennt davon in user://settings.cfg.

signal changed

const PATH := "user://settings.cfg"
## Auf diese Größe ist die Bedienoberfläche ausgelegt (hochskaliert); 3D in Fensterauflösung
const UI_SIZE := Vector2i(480, 270)

# Bild
var gamma := 1.0                 ## Helligkeit (0,6 … 1,8)
var fullscreen := false          ## wird nicht gespeichert – das Spiel startet immer im Fenster
var vsync := true
var fov := 90.0                  ## Sichtfeld senkrecht in Grad (60 … 120)
var reflections := true          ## Spiegelungen auf glatten Flächen (SSR: Lobbymarmor, Pool, Tapetenlack) – kostet Leistung
# Ton
var master_volume := 1.0
var music_volume := 1.0
var effects_volume := 1.0
# Steuerung
var mouse_sensitivity := 1.0     ## Faktor
var invert_y := false
var crouch_toggle := false
var key_bindings := {}           ## Tastenbelegung: nur Abweichungen vom Standard, Aktion → Tasten (Keys, Spielkonzept 8.4)
# Barrierefreiheit
var flicker_intensity := 1.0     ## Flackern und Bildrauschen (0,2 … 1)
var look_pull := 1.0             ## Blickzug des Lakengeists (0,2 … 1; Spielkonzept 4.18, 4.24) – unter 1 nur sanft gelenkt
var subtitles := false
var spider_blobs := false        ## Arachnophobie: Spinnen als schlichte Kugeln ohne Beine (Spielkonzept 4.23)
var warning_shown := false       ## Hinweis zur Lichtempfindlichkeit schon gezeigt
var age_notice_shown := false    ## Hinweis mit Altersempfehlung schon gezeigt

const KEYS := ["gamma", "vsync", "fov", "reflections",
	"master_volume", "music_volume", "effects_volume", "mouse_sensitivity", "invert_y",
	"crouch_toggle", "key_bindings", "flicker_intensity", "look_pull", "subtitles", "spider_blobs", "warning_shown", "age_notice_shown"]


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
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_size = UI_SIZE
	window.content_scale_factor = 1.0
	RenderingServer.global_shader_parameter_set("reflections", 1.0 if reflections else 0.0)   # Spiegelanteil (psx_photo)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.0001)))
	changed.emit()


## Geänderte Tastenbelegung (InputMap) ins Profil übernehmen und speichern.
func store_key_bindings() -> void:
	key_bindings = Keys.changed()
	save_settings()


## Für das Kalibrierbild: so hell erscheint ein Farbwert mit der aktuellen Helligkeit.
func preview(c: Color) -> Color:
	var g := 1.0 / gamma
	return Color(pow(c.r, g), pow(c.g, g), pow(c.b, g), c.a)
