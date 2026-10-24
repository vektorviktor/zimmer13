class_name Weather
extends Node3D
## Wetter draußen (Spielkonzept 7.8): Meist ist es klar, manchmal regnet es, manchmal gewittert es – gegen Monatsende
## öfter und häufiger als Gewitter. Regen fällt als Partikel in einem Kasten um den Spieler (shaders/rain.gdshader),
## jeder Tropfen nur bis zur obersten Fläche unter sich – drinnen regnet es also nie, durch die Fenster sieht man ihn.
## Dazu Rauschen (SynthAudio.rain, drinnen dumpfer) und mehr Wolken. Bei Gewitter: Blitze (Mondlicht und Himmel
## blitzen kurz auf, das Licht fällt durch die Fenster) und Donner einige Sekunden später – Lärm ohne Quelle: Er lockt
## niemanden, übertönt aber kurz alles, das Monster hört schlechter (masking, MonsterDirector.on_noise).
## Um Mitternacht schlägt hinter der Waldkante eine Kirchturmglocke zwölfmal, tief und fern, drinnen leiser – kein
## Lärm. Danach beginnt die Geisterstunde (SheetGhost, Spielkonzept 4.18).
## Nicht gespeichert: Nach dem Laden ist es klar.

enum Kind { CLEAR, RAIN, STORM }

## Pause ohne Regen am 1. Oktober … an Halloween; so lange dauert ein Schauer; so oft ist er ein Gewitter
const CLEAR_EARLY := Vector2(500.0, 1000.0)
const CLEAR_LATE := Vector2(200.0, 420.0)
const FIRST_CLEAR := Vector2(150.0, 400.0)
const SHOWER_TIME := Vector2(120.0, 260.0)
const STORM_CHANCE := Vector2(0.3, 0.75)
const FADE := 20.0                ## so lange setzt Regen ein bzw. hört auf (s)
const LIGHTNING_GAP := Vector2(10.0, 30.0)
const THUNDER_DELAY := Vector2(0.4, 3.5)   ## nah: gleich, fern: später und leiser
## Regen: so viele Tropfen bei voller Stärke im Kasten (± HALF_EXTENT um den Spieler), so hoch beginnen sie
const DROPS := 9000
const HALF_EXTENT := 20.0
const TOP := 16.0
const DROP_SIZE := Vector3(0.008, 0.4, 0.008)
const DROP_COLOR := Color(0.6, 0.66, 0.78, 0.2)
## Ohne PS1-Look: so viele Tropfen, Striche so lang und breit (m), nie schmaler als so viele Bildpunkte (dafür blasser)
const DROPS_FINE := 24000
const STREAK := Vector2(0.5, 0.0015)
const STREAK_PIXELS := 1.5
const STREAK_COLOR := Color(0.72, 0.77, 0.88, 0.3)
## Fallgeschwindigkeit samt Wind (m/s)
const FALL := Vector3(0.8, -11.0, 0.3)
## Dach-Höhenkarte: Zellgröße, Rand um den Plan, so viele Zeilen je Physikbild (Aufbau verteilt)
const CELL := 0.5
const MARGIN := 12.0
const ROWS_PER_FRAME := 24
## Klang: Regenrauschen draußen und drinnen; Donner übertönt so lange (s) und so stark (Hörweite × 1 − MASK)
const RAIN_OUT := 0.45
const RAIN_IN := 0.16
const MASK_TIME := 3.5
const MASK := 0.6
## Blitz: Mondlicht so viel heller, so schnell klingt eine Zuckung ab (je s); Bedeckung bei Regen (Shader: kleiner = mehr Wolken)
const FLASH_ENERGY := 6.0
const FLASH_DECAY := 6.0
const CLOUDS_RAIN := 0.12
## Kirchturmglocke um Mitternacht (Spielkonzept 7.8): so viele Schläge, so weit auseinander (s), Pegel, drinnen so viel
## davon, Tonhöhe (tiefer als die Totenglocke – eine große Glocke weit weg)
const BELL := "res://assets/sound/church_bell.wav"
const BELL_STRIKES := 12
const BELL_GAP := 1.3
const BELL_DB := -9.0
const BELL_INSIDE := 0.5
const BELL_PITCH := 0.6

var kind := Kind.CLEAR
var intensity := 0.0              ## 0 … 1, folgt dem Wetter weich

var _timer := 0.0
var _lightning := 0.0
var _flash := 0.0                 ## 0 … 1 (Abklingen)
var _flash_queue: Array[float] = []   ## Zeitpunkte (s ab jetzt) der Zuckungen eines Blitzes
var _mask := 0.0
var _builder: LevelBuilder
var _moon: DirectionalLight3D
var _moon_energy := 0.32
var _sky: ShaderMaterial
var _clouds := 0.4
var _rain: GPUParticles3D
var _rain_mat: ShaderMaterial
var _rain_psx := true             ## Aussehen der Tropfen, wie es gerade gebaut ist (Settings.psx_look)
var _roofs: Image
var _origin := Vector2.ZERO
var _rows_done := 0
var _bell: AudioStreamPlayer
var _bell_left := 0               ## so viele Schläge stehen noch aus
var _bell_timer := 0.0
var _last_hour := -1.0


func _ready() -> void:
	add_to_group("time_skip")   # Zeitsprung im Schlaf (SleepSkip)


## Zeitsprung im Schlaf (SleepSkip, Spielkonzept 3.6): bis zum nächsten Wetterwechsel um dt näher.
func skip_time(dt: float) -> void:
	_timer = maxf(0.001, _timer - dt)


func setup(builder: LevelBuilder, moon: DirectionalLight3D, sky: ShaderMaterial) -> void:
	_builder = builder
	_moon = moon
	_moon_energy = moon.light_energy
	_sky = sky
	var cover = sky.get_shader_parameter("cloud_cover")   # null, solange der Standardwert gilt
	_clouds = float(cover) if cover != null else 0.4
	_timer = randf_range(FIRST_CLEAR.x, FIRST_CLEAR.y)
	_prepare_roofs()
	_build_rain()
	_bell = AudioStreamPlayer.new()
	_bell.stream = load(BELL)
	_bell.pitch_scale = BELL_PITCH
	_bell.max_polyphony = 3   # jeder Schlag klingt aus, während der nächste kommt
	add_child(_bell)


func _process(delta: float) -> void:
	if _builder == null:
		return
	_build_roof_rows()
	_timer -= delta
	if _timer <= 0.0:
		if kind == Kind.CLEAR:
			var storm := randf() < lerpf(STORM_CHANCE.x, STORM_CHANCE.y, _progress())
			set_weather(Kind.STORM if storm else Kind.RAIN)
		else:
			set_weather(Kind.CLEAR)
	intensity = move_toward(intensity, 0.0 if kind == Kind.CLEAR else 1.0, delta / FADE)
	if kind == Kind.STORM and intensity > 0.5:
		_lightning -= delta
		if _lightning <= 0.0:
			lightning()
	_update_flash(delta)
	_mask = maxf(0.0, _mask - delta)
	_update_rain()
	_update_bell(delta)


## Wechselt die Uhr über Mitternacht, schlägt die Glocke BELL_STRIKES-mal – das weckt (Spielkonzept 3.6).
func _update_bell(delta: float) -> void:
	if Game.director == null:
		return
	var hour := Calendar.hour_of(Game.director.elapsed)
	if _last_hour >= 23.0 and hour < 1.0:
		_bell_left = BELL_STRIKES
		_bell_timer = 0.0
		Game.caption("[Eine Kirchturmglocke schlägt Mitternacht]")
		if Game.player and Game.player.sleeping:
			Game.player.wake_up("Die Kirchturmglocke weckt dich.")   # Termine wecken (Spielkonzept 3.6)
		if Game.tracing:
			print("[Wetter] Kirchturmglocke: Mitternacht am %d." % Calendar.today())
	_last_hour = hour
	if _bell_left <= 0:
		return
	_bell_timer -= delta
	if _bell_timer > 0.0:
		return
	_bell_timer = BELL_GAP
	_bell_left -= 1
	var p := Game.player
	var inside := p != null and not _builder.is_outdoor(p.global_position)
	var gain := Settings.effects_volume * (BELL_INSIDE if inside else 1.0)
	if gain > 0.0:
		_bell.volume_db = BELL_DB + linear_to_db(gain)
		_bell.play()


## Debug (--weather=…) und Zeitplan: Wetter wechseln. instant: sofort volle Stärke.
func set_weather(new_kind: Kind, instant: bool = false) -> void:
	kind = new_kind
	if kind == Kind.CLEAR:
		_timer = _gap(CLEAR_EARLY, CLEAR_LATE)
	else:
		_timer = randf_range(SHOWER_TIME.x, SHOWER_TIME.y)
		_lightning = randf_range(3.0, 8.0) if instant else randf_range(LIGHTNING_GAP.x, LIGHTNING_GAP.y)
	if instant:
		intensity = 0.0 if kind == Kind.CLEAR else 1.0
	if Game.tracing:
		print("[Wetter] %s für %d s" % [["klar", "Regen", "Gewitter"][kind], int(_timer)])


## Ein Blitz: zwei, drei Zuckungen, dann (je nach Entfernung) der Donner.
func lightning() -> void:
	_lightning = randf_range(LIGHTNING_GAP.x, LIGHTNING_GAP.y)
	_flash_queue = [0.0, randf_range(0.08, 0.14)]
	if randf() < 0.5:
		_flash_queue.append(randf_range(0.25, 0.4))
	var delay := randf_range(THUNDER_DELAY.x, THUNDER_DELAY.y)
	var loud := clampf(1.3 - delay / THUNDER_DELAY.y, 0.4, 1.0)
	get_tree().create_timer(delay, false).timeout.connect(_thunder.bind(loud))
	if Game.tracing:
		print("[Wetter] Blitz, Donner nach %.1f s" % delay)


func _thunder(loud: float) -> void:
	var p := Game.player
	var inside := p != null and not _builder.is_outdoor(p.global_position)
	Game.play_sound("thunder", loud * (0.7 if inside else 1.0))
	Game.caption("[Donner]")
	_mask = MASK_TIME * loud


## Donner übertönt gerade alles: Hörweite × diesen Wert (MonsterDirector.on_noise).
func masking() -> float:
	return 1.0 - MASK * clampf(_mask / MASK_TIME, 0.0, 1.0)


func _update_flash(delta: float) -> void:
	for i in range(_flash_queue.size() - 1, -1, -1):
		_flash_queue[i] -= delta
		if _flash_queue[i] <= 0.0:
			_flash_queue.remove_at(i)
			_flash = randf_range(0.7, 1.0)
			Game.shot_event("lightning", 4)   # im Hintergrundfenster hinkt das Bild nach
			if _builder and _builder.attic_spook:   # Spuk im Dachboden: dreht den Spieler im Blitzbild
				_builder.attic_spook.on_flash()
	_flash = maxf(0.0, _flash - delta * FLASH_DECAY)
	var overcast := intensity * (1.0 if kind != Kind.CLEAR else 0.6)
	if _moon:
		_moon.light_energy = _moon_energy * (1.0 - 0.6 * overcast) + _flash * FLASH_ENERGY
		_moon.light_color = Color(0.55, 0.65, 1.0).lerp(Color(0.85, 0.9, 1.0), clampf(_flash, 0.0, 1.0))
	if _sky:
		_sky.set_shader_parameter("flash", _flash)
		_sky.set_shader_parameter("cloud_cover", lerpf(_clouds, CLOUDS_RAIN, overcast))


func _gap(early: Vector2, late: Vector2) -> float:
	var t := _progress()
	return randf_range(lerpf(early.x, late.x, t), lerpf(early.y, late.y, t))


func _progress() -> float:
	return clampf(float(Calendar.today() - Calendar.FIRST_DAY) / float(Calendar.HALLOWEEN - Calendar.FIRST_DAY), 0.0, 1.0)


# --- Regen ----------------------------------------------------------------------------------

func _update_rain() -> void:
	var p := Game.player
	var on := intensity > 0.01 and p != null and _roofs == null and _rows_done > 0   # erst mit fertiger Dachkarte
	if Settings.psx_look != _rain_psx:
		_set_drops(Settings.psx_look)
	_rain.emitting = on
	_rain.visible = on
	if on:
		_rain.amount_ratio = intensity
		_rain.global_position = Vector3(p.global_position.x, 0.0, p.global_position.z)
		_rain_mat.set_shader_parameter("center", p.global_position)
	if Game.audio:
		var outside := p != null and _builder.is_outdoor(p.global_position)
		Game.audio.rain = intensity * (RAIN_OUT if outside else RAIN_IN)
		Game.audio.rain_muffle = move_toward(Game.audio.rain_muffle, 0.0 if outside else 1.0, 0.05)


func _build_rain() -> void:
	_rain_mat = ShaderMaterial.new()
	_rain_mat.shader = load("res://shaders/rain.gdshader")
	_rain_mat.set_shader_parameter("half_extent", HALF_EXTENT)
	_rain_mat.set_shader_parameter("top", TOP)
	_rain_mat.set_shader_parameter("cell", CELL)
	_rain_mat.set_shader_parameter("map_origin", _origin)
	_rain_mat.set_shader_parameter("speed", -FALL.y)
	_rain_mat.set_shader_parameter("wind", Vector2(FALL.x, FALL.z))
	_rain = GPUParticles3D.new()
	_rain.lifetime = 600.0       # jeder Tropfen lebt im Shader immer weiter (fällt, beginnt oben neu)
	_rain.explosiveness = 1.0    # alle auf einmal, verteilt über die ganze Säule
	_rain.local_coords = false
	_rain.process_material = _rain_mat
	_rain.visibility_aabb = AABB(Vector3(-HALF_EXTENT - 2.0, -2.0, -HALF_EXTENT - 2.0), Vector3(HALF_EXTENT * 2.0 + 4.0, TOP + 4.0, HALF_EXTENT * 2.0 + 4.0))
	_rain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_set_drops(Settings.psx_look)
	_rain.emitting = false
	_rain.visible = false
	add_child(_rain)


## Tropfen im PS1-Look (Klötzchen) oder fein (Striche, mehr davon). Neue Anzahl startet die Partikel neu.
func _set_drops(psx: bool) -> void:
	_rain_psx = psx
	if psx:
		var mesh := BoxMesh.new()
		mesh.size = DROP_SIZE
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = DROP_COLOR
		mat.disable_fog = false
		mesh.material = mat
		_rain.amount = DROPS
		_rain.draw_pass_1 = mesh
	else:
		var mat := ShaderMaterial.new()
		mat.shader = load("res://shaders/rain_streak.gdshader")
		mat.set_shader_parameter("color", STREAK_COLOR)
		mat.set_shader_parameter("fall", FALL)
		mat.set_shader_parameter("streak_length", STREAK.x)
		mat.set_shader_parameter("streak_width", STREAK.y)
		mat.set_shader_parameter("min_pixels", STREAK_PIXELS)
		var quad := QuadMesh.new()   # 1 × 1, der Shader streckt ihn
		quad.material = mat
		_rain.amount = DROPS_FINE
		_rain.draw_pass_1 = quad


## Dach-Höhenkarte über dem ganzen Plan (+ Rand): je Zelle die Höhe der obersten Fläche (Strahl von oben, Ebenen 1 und
## Decke). Gebaut zeilenweise in den ersten Bildern (_build_roof_rows) – erst danach regnet es.
func _prepare_roofs() -> void:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for zone in _builder.zones:
		var c: Vector3 = zone["center"]
		var r := float(zone["radius"])
		lo = lo.min(Vector2(c.x - r, c.z - r))
		hi = hi.max(Vector2(c.x + r, c.z + r))
	lo -= Vector2.ONE * MARGIN
	hi += Vector2.ONE * MARGIN
	_origin = lo
	var size := Vector2i(ceili((hi.x - lo.x) / CELL), ceili((hi.y - lo.y) / CELL))
	_roofs = Image.create(size.x, size.y, false, Image.FORMAT_RF)
	_rows_done = -2   # zwei Bilder warten, bis die Physik alle Körper kennt


func _build_roof_rows() -> void:
	if _roofs == null or _rows_done >= _roofs.get_height():
		return
	if _rows_done < 0:
		_rows_done += 1
		return
	var space := get_world_3d().direct_space_state
	var last := mini(_rows_done + ROWS_PER_FRAME, _roofs.get_height())
	for y in range(_rows_done, last):
		for x in _roofs.get_width():
			var p := _origin + (Vector2(x, y) + Vector2.ONE * 0.5) * CELL
			var query := PhysicsRayQueryParameters3D.create(Vector3(p.x, TOP + 4.0, p.y), Vector3(p.x, -2.0, p.y),
				1 | LevelBuilder.LAYER_CEILING)
			var hit := space.intersect_ray(query)
			_roofs.set_pixel(x, y, Color((hit["position"] as Vector3).y if not hit.is_empty() else -2.0, 0, 0))
	_rows_done = last
	if _rows_done >= _roofs.get_height():
		_rain_mat.set_shader_parameter("roof_height", ImageTexture.create_from_image(_roofs))
		_rain_mat.set_shader_parameter("map_origin", _origin)
		_roofs = null   # die Textur hat jetzt die Daten
		_rows_done = 1 << 30
