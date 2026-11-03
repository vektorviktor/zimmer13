extends Node
## Einstellungen (Autoload „Settings“, Spielkonzept 8.4). Gelten für alle Spielstände und
## liegen getrennt davon in user://settings.cfg.

signal changed

const PATH := "user://settings.cfg"
## Auf diese Größe ist die Bedienoberfläche ausgelegt (hochskaliert); 3D in Fensterauflösung
const UI_SIZE := Vector2i(480, 270)
## Stufen für Schrift und Menüs (ui_scale, Spielkonzept 8.4): Anteil der vollen Hochskalierung auf UI_SIZE.
## 1,0 ist die größte Stufe – darunter hat die Oberfläche mehr Platz und alles wirkt kleiner.
const UI_SCALES := [1.0, 0.9, 0.8, 0.7, 0.6]

# Bild
var gamma := 1.0                 ## Helligkeit (0,6 … 1,8)
var fullscreen := false          ## wird nicht gespeichert – das Spiel startet immer im Fenster
var vsync := true
var fov := 90.0                  ## Sichtfeld senkrecht in Grad (60 … 120)
var reflections := true          ## Spiegelungen auf glatten Flächen (SSR: Lobbymarmor, Pool, Tapetenlack) – kostet Leistung
var graphics := 2                ## Grafikstufe: Index in GRAPHICS (0 Niedrig, 1 Mittel, 2 Hoch) – set_graphics
var ui_scale := 0.8              ## Schrift und Menüs: eine der UI_SCALES (Window.content_scale_factor)
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
var bite_pulse := 1.0            ## Pulsieren des Bildes nach dem Fledermausbiss (0,2 … 1; Spielkonzept 4.22) – dunkel bleibt es
var subtitles := false
var spider_blobs := false        ## Arachnophobie: Spinnen als schlichte Kugeln ohne Beine (Spielkonzept 4.23)
var warning_shown := false       ## Hinweis zur Lichtempfindlichkeit schon gezeigt
var age_notice_shown := false    ## Hinweis mit Altersempfehlung schon gezeigt

const KEYS := ["gamma", "vsync", "fov", "reflections", "graphics", "ui_scale",
	"master_volume", "music_volume", "effects_volume", "mouse_sensitivity", "invert_y",
	"crouch_toggle", "key_bindings", "flicker_intensity", "look_pull", "bite_pulse", "subtitles", "spider_blobs", "warning_shown", "age_notice_shown"]

## Grafikstufen (Spielkonzept 8.4, ZIM-94). Hoch ist der Stand vom 3.11.2026 (RTX 4060 Laptop, 1080p mit 30 FPS),
## Niedrig zielt auf neuere Onboard-Grafik (30 FPS). Fenster und RenderingServer stellt apply() ein, Umgebung, Mond und
## Schattenlampen main._apply_settings, die Sichtweite der Spielerkamera Player.
## scale/fsr: Auflösung der 3D-Ansicht (Anteil der Fensterauflösung; mit FSR 1 hochgerechnet, sonst bilinear) –
## shadow_atlas: Kantenlänge des Schattenatlas der Lampen (die 88 Plätze bleiben, sonst schienen Lampen durch Wände) –
## sun_atlas/moon_distance: Mondschatten (Atlas, Reichweite in m) – soft: Godots Filterstufe weicher Schatten
## (RenderingServer.ShadowQuality) – full: so viele Lampen um die Kamera werfen Schatten von allem (ShadowBudget.full) –
## ssr/ssr_steps: Spiegelungen beim Wählen der Stufe und Schritte je Strahl (unter 128 finden Strahlen über den Boden
## die Wände dahinter öfter nicht) – ssao/sdfgi: Umgebungsverdeckung und globale Beleuchtung; das Hotel nutzt beide
## bisher in keiner Stufe (Umgebungslicht ist eine feste Farbe), die Spalten machen sie je Stufe schaltbar –
## fog_volume: Rasterweite des Lichtnebels (Godot: 64) – view: Sichtweite in m (Nebelende, Kamera VIEW_MARGIN dahinter).
const GRAPHICS := [
	{"name": "Niedrig", "scale": 0.67, "fsr": true, "shadow_atlas": 2048, "sun_atlas": 2048, "moon_distance": 25.0,
		"soft": 1, "full": 5, "ssr": false, "ssr_steps": 64, "ssao": false, "sdfgi": false, "fog_volume": 48, "view": 40.0},
	{"name": "Mittel", "scale": 0.85, "fsr": true, "shadow_atlas": 4096, "sun_atlas": 4096, "moon_distance": 40.0,
		"soft": 2, "full": 8, "ssr": true, "ssr_steps": 96, "ssao": false, "sdfgi": false, "fog_volume": 64, "view": 52.0},
	{"name": "Hoch", "scale": 1.0, "fsr": false, "shadow_atlas": 4096, "sun_atlas": 4096, "moon_distance": 40.0,
		"soft": 2, "full": 12, "ssr": true, "ssr_steps": 128, "ssao": false, "sdfgi": false, "fog_volume": 64, "view": 66.0},
]
## So weit hinter dem Nebelende (view) endet die Kamera – dahinter sieht man ohnehin nichts, auch das Monster nicht
const VIEW_MARGIN := 4.0
## Zuletzt in apply() eingestellte Stufe (Eintrag aus GRAPHICS)
var _applied_graphics := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	for arg in OS.get_cmdline_user_args():   # schon für den Titelbildschirm
		set_ui_scale_arg(arg)
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
	window.content_scale_factor = clampf(float(ui_scale), UI_SCALES[-1], UI_SCALES[0])
	RenderingServer.global_shader_parameter_set("reflections", 1.0 if reflections else 0.0)   # Spiegelanteil (psx_photo)
	var g := graphics_level()
	if g != _applied_graphics:   # nur beim Wechsel – apply() läuft bei jedem Reglerzug
		_applied_graphics = g
		window.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if g["fsr"] else Viewport.SCALING_3D_MODE_BILINEAR
		window.scaling_3d_scale = g["scale"]
		window.positional_shadow_atlas_size = g["shadow_atlas"]
		RenderingServer.directional_shadow_atlas_set_size(g["sun_atlas"], true)
		RenderingServer.positional_soft_shadow_filter_set_quality(g["soft"])
		RenderingServer.directional_soft_shadow_filter_set_quality(g["soft"])
		RenderingServer.environment_set_volumetric_fog_volume_size(g["fog_volume"], g["fog_volume"])
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(master_volume, 0.0001)))
	changed.emit()


## Werte der eingestellten Grafikstufe (GRAPHICS)
func graphics_level() -> Dictionary:
	return GRAPHICS[clampi(int(graphics), 0, GRAPHICS.size() - 1)]


## Grafikstufe wählen: setzt auch die Spiegelungen auf den Wert der Stufe – der Haken lässt sich danach wieder
## umstellen und gilt dann. store false: nur für die Sitzung (Debug --grafik).
func set_graphics(level: int, store := true) -> void:
	graphics = clampi(level, 0, GRAPHICS.size() - 1)
	reflections = graphics_level()["ssr"]
	apply()
	if store:
		save_settings()


## Debug --schrift=n: Schrift & Menüs auf n % (60 … 100) nur für die Sitzung. false, wenn arg nicht passt.
func set_ui_scale_arg(arg: String) -> bool:
	if not arg.begins_with("--schrift=") or not arg.substr(10).is_valid_float():
		return false
	ui_scale = clampf(arg.substr(10).to_float() / 100.0, UI_SCALES[-1], UI_SCALES[0])
	return true


## Geänderte Tastenbelegung (InputMap) ins Profil übernehmen und speichern.
func store_key_bindings() -> void:
	key_bindings = Keys.changed()
	save_settings()


## Für das Kalibrierbild: so hell erscheint ein Farbwert mit der aktuellen Helligkeit.
func preview(c: Color) -> Color:
	var g := 1.0 / gamma
	return Color(pow(c.r, g), pow(c.g, g), pow(c.b, g), c.a)
