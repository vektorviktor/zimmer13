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
## Dazu (alles 7.8): Regen an den Scheiben (rain_wet, window_rain.gdshader – nass im Regen, trocknet danach langsam),
## ebenso nass und glänzend die Böden draußen (Rasen, Kies, Terrassen; wet_ground.gdshaderinc, Mat.wettable);
## Wind (`wind`, Grundbrise, im Regen und Gewitter stärker, in Böen) – Gras, Blätter, fallendes Laub, Regen, Klang;
## Nebel draußen (ground_fog.gdshader), mit jedem Tag dichter, der Himmel wolkiger; der Mond nimmt ab und zu – Neumond
## Mitte Oktober, Vollmond an Halloween – und so hell scheint er (auch für die Sicht des Monsters, moonlight()).
## Bei manchem Blitz steht kurz eine Gestalt zwischen den Bäumen (LightningFigure). Eule, Krähen und Hunde rufen in der
## Ferne, je nach Uhrzeit und Wetter (DistantAnimals).
## Blutregen (Seltenwetter): einmal je Spiel fällt ein Schauer rot – ab dem 20. Oktober, nur wenn der Spieler wach ist
## und ihn sieht (draußen oder am Außenfenster), spätestens ab dem 28. sicher beim nächsten solchen Schauer. Gäste in der
## Nähe fürchten sich, der mutigste erklärt ihn nüchtern (Saharastaub) – Omen oder Natur bleibt offen. Solange er
## fällt, ist der Himmel rotbraun, Blitze leuchten rot und der nasse Boden glänzt rot; er trocknet wie sonst ab. Danach
## bleiben rote Flecken auf den Scheiben und rötliche Pfützen draußen, bis normaler Regen sie abwäscht; kein Blut für
## die Spuren.
## Nicht gespeichert: Nach dem Laden ist es klar; Mond und Nebel folgen dem Kalender. Gespeichert (bei den Omen): ob es
## schon Blut geregnet hat und wie viel davon noch zu sehen ist.

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
## Donnerlautstärke (0,4–1,0) ab der die Aufnahme „nah“ bzw. „mittel“ spielt, darunter „fern“
const THUNDER_CLOSE := 0.8
const THUNDER_MID := 0.55
## Regen: so viele Tropfen bei voller Stärke im Kasten (± HALF_EXTENT um den Spieler), so hoch beginnen sie
const DROPS := 24000
const HALF_EXTENT := 20.0
const TOP := 16.0
## Tropfen als Striche: so lang und breit (m), nie schmaler als so viele Bildpunkte (dafür blasser)
const STREAK := Vector2(0.5, 0.0015)
const STREAK_PIXELS := 1.5
const STREAK_COLOR := Color(0.72, 0.77, 0.88, 0.3)
## Fallgeschwindigkeit samt Wind (m/s)
const FALL := Vector3(0.8, -11.0, 0.3)
## Dach-Höhenkarte: Zellgröße, Rand um den Plan (Aufbau über die ersten Bilder verteilt)
const CELL := 0.5
const MARGIN := 12.0
const ROOF_BUDGET_USEC := 1500   ## Strahltests je Bild höchstens so lange (µs), mindestens eine Zeile (ZIM-124)
## Klang: Regenrauschen draußen und drinnen; Donner übertönt so lange (s) und so stark (Hörweite × 1 − MASK)
const RAIN_OUT := 0.45
const RAIN_IN := 0.16
const MASK_TIME := 3.5
const MASK := 0.6
## Blitz: Mondlicht so viel heller, so schnell klingt eine Zuckung ab (je s); Bedeckung bei Regen (Shader: kleiner = mehr Wolken)
const FLASH_ENERGY := 6.0
const FLASH_DECAY := 6.0
const FLASH_FOG := 0.5            ## so viel davon kommt im Nebel an
const CLOUDS_RAIN := 0.12
## Kirchturmglocke um Mitternacht (Spielkonzept 7.8): so viele Schläge, so weit auseinander (s), Pegel, drinnen so viel
## davon, Tonhöhe (tiefer als die Totenglocke – eine große Glocke weit weg)
const BELL := "res://assets/sound/church_bell.wav"
const BELL_STRIKES := 12
const BELL_GAP := 1.3
const BELL_DB := -9.0
const BELL_INSIDE := 0.5
const BELL_PITCH := 0.6
## Hund hinter der Waldkante (4.25): so laut (draußen), drinnen × BELL_INSIDE
const HOWL_VOLUME := 0.55
## Abstand zwischen zwei Heulern in Sekunden Spielzeit, zufällig (Tuning)
const HOWL_EVERY := Vector2(240.0, 720.0)
## Regen an den Scheiben: so schnell werden sie bei vollem Regen nass (je s), so lange trocknen sie danach (s)
const WET_RATE := 1.0 / 30.0
const DRY_TIME := 300.0
## Wind (0 … 1): Grundbrise am 1. Oktober … an Halloween, so viel mehr bei Regen und bei Gewitter, Böen bis so viel
## dazu, eine Böe dauert so lange (s); Klang draußen und drinnen
const WIND_CALM := Vector2(0.15, 0.3)
const WIND_RAIN := 0.3
const WIND_STORM := 0.55
const GUST := 0.3
const GUST_TIME := Vector2(2.0, 7.0)
const WIND_OUT := 0.4
const WIND_IN := 0.18
## Fallendes Laub im Wind: so viel schneller (× 1 + wind × das), so schräg
const LEAF_RUSH := 1.5
const LEAF_SLANT := 1.4
## Nebel draußen: Dichte am 1. Oktober … an Halloween, Höhe der Schicht (m, halbiert sie etwa), Kasten bis so hoch (m)
const FOG_DENSITY := Vector2(0.006, 0.16)
const FOG_HEIGHT := Vector2(1.2, 3.0)
const FOG_TOP := 14.0
## Wolken: Bedeckung bei klarem Himmel am 1. Oktober … an Halloween (Shader: kleiner = mehr Wolken)
const CLOUDS_LATE := 0.3
## Mond: Umlauf (Tage), Vollmond um Mitternacht nach Halloween (Calendar.day_float), Mondlicht bei Neumond (Anteil)
const SYNODIC := 29.53
const FULL_MOON := 32.0
const MOON_DARK := 0.15
## Blutregen: frühestens ab diesem Tag, ab diesem sicher; Chance je passendem Schauer dazwischen (steigt bis 1); der
## Spieler sieht ihn draußen oder bis so weit (m) von einem Außenfenster mit offenem Vorhang
const BLOOD_FROM := 20
const BLOOD_SURE := 28
const BLOOD_CHANCE := 0.25
const BLOOD_WINDOW := 8.0
## so lange wäscht normaler Regen voller Stärke die roten Reste ab (s); Farbe der Tropfen
const BLOOD_WASH := 90.0
const BLOOD_STREAK := Color(0.62, 0.1, 0.08, 0.38)
## so lange (s) blendet Blutregen in Himmel, Boden und Tropfen ein bzw. aus; Farbe des Blitzlichts dabei
const BLOOD_FADE := 20.0
const BLOOD_FLASH := Color("ff1111")
## Gäste: so nah (m) am Spieler reagieren sie, so viel Angst (× 1,2 − Mut), so viele sagen etwas (dazu der Mutigste)
const BLOOD_GUESTS := 25.0
const BLOOD_FEAR := 25.0
const BLOOD_VOICES := 2
const BLOOD_LINES: Array[String] = ["Der Regen … der ist ja rot!", "Das ist Blut. Das ist doch Blut!",
	"Ein Zeichen. Ich hab's euch gesagt – ein Zeichen.", "Fasst das nicht an!"]
const BLOOD_CHILD := "Es regnet Blut! Es regnet Blut!"
const BLOOD_CALM := "Saharastaub. Der Wind trägt ihn bis zu uns herauf, das kommt alle paar Jahre vor."
## Rötliche Pfützen: so viele, so groß (m), Farbe, fester Zufall für die Stellen
const PUDDLES := 90
const PUDDLE_SIZE := Vector2(0.7, 2.2)
const PUDDLE_COLOR := Color("a80808")
const PUDDLE_SEED := 2610

var _howl_timer := 0.0           ## bis zum nächsten Heulen (4.25)
var animals: DistantAnimals       ## Eule, Krähen und Hunde in der Ferne (7.8)
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
var _roofs: Image
var _origin := Vector2.ZERO
var _rows_done := 0
var _bell: AudioStreamPlayer
var _bell_left := 0               ## so viele Schläge stehen noch aus
var _bell_timer := 0.0
var _last_hour := -1.0
var wet := 0.0                    ## 0 … 1: so nass sind die Scheiben
var wind := 0.25                  ## 0 … 1: Windstärke gerade
var _gust := 0.0
var _gust_target := 0.0
var _gust_timer := 0.0
var _time := 0.0                  ## Spielzeit für die Shader (weather_time)
var _leaf_timer := 0.0
var _moon_light := 1.0            ## Mondphase × Bewölkung: so viel vom vollen Mondlicht kommt an
var _fog: FogVolume
var _fog_mat: ShaderMaterial
var _figure: LightningFigure
var _flickers := 0                ## Zuckungen des laufenden Blitzes bisher
var _drops_on := false            ## Tropfen an den Scheiben gerade sichtbar
var _stormy := false              ## der letzte Schauer war ein Gewitter (Wind auch beim Abklingen)
var _fog_drift := Vector2.ZERO    ## so weit ist der Nebel getrieben (m)
var _figure_seen := false         ## in diesem Gewitter stand schon eine Gestalt im Blitz
var blood_done := false           ## es hat in diesem Spiel schon Blut geregnet
var stain := 0.0                  ## 0 … 1: so viel Rot ist noch auf Scheiben und in Pfützen
var _blood := false               ## der laufende (oder letzte) Schauer ist Blutregen
var _blood_reacted := false
var _blood_tinted := false        ## Regentropfen gerade rot gefärbt
var _blood_amount := 0.0          ## 0 … 1: Blutregen weich ein- und ausgeblendet (rain_blood, Himmel)
var _roof_img: Image              ## Dach-Höhenkarte (für die Pfützen)
var _puddles: Array[Decal] = []


func _ready() -> void:
	add_to_group("time_skip")   # Zeitsprung im Schlaf (SleepSkip)


## Zeitsprung im Schlaf (SleepSkip, Spielkonzept 3.6): bis zum nächsten Wetterwechsel um dt näher.
func skip_time(dt: float) -> void:
	_timer = maxf(0.001, _timer - dt)
	_howl_timer = fposmod(_howl_timer - dt, HOWL_EVERY.y)   # im Schlaf hört man ihn nicht
	if kind == Kind.CLEAR:
		wet = move_toward(wet, 0.0, dt / DRY_TIME)


func setup(builder: LevelBuilder, moon: DirectionalLight3D, sky: ShaderMaterial) -> void:
	_builder = builder
	_moon = moon
	_moon_energy = moon.light_energy
	_sky = sky
	var cover = sky.get_shader_parameter("cloud_cover")   # null, solange der Standardwert gilt
	_clouds = float(cover) if cover != null else 0.4
	_timer = randf_range(FIRST_CLEAR.x, FIRST_CLEAR.y)
	_howl_timer = randf_range(HOWL_EVERY.x, HOWL_EVERY.y)
	_prepare_roofs()
	_build_rain()
	_build_fog()
	_figure = LightningFigure.new()
	_figure.builder = builder
	add_child(_figure)
	animals = DistantAnimals.new()
	animals.builder = builder
	add_child(animals)
	_bell = AudioStreamPlayer.new()
	_bell.stream = load(BELL)
	_bell.pitch_scale = BELL_PITCH
	_bell.max_polyphony = 3   # jeder Schlag klingt aus, während der nächste kommt
	add_child(_bell)


func _process(delta: float) -> void:
	if _builder == null:
		return
	_build_roof_rows()
	_howl_timer -= delta
	if _howl_timer <= 0.0:
		_howl_timer = randf_range(HOWL_EVERY.x, HOWL_EVERY.y)
		howl(0.0)
	_timer -= delta
	if _timer <= 0.0:
		if kind == Kind.CLEAR:
			var storm := randf() < lerpf(STORM_CHANCE.x, STORM_CHANCE.y, _progress())
			set_weather(Kind.STORM if storm else Kind.RAIN, false, _blood_due())
		else:
			set_weather(Kind.CLEAR)
	intensity = move_toward(intensity, 0.0 if kind == Kind.CLEAR else 1.0, delta / FADE)
	if kind == Kind.STORM and intensity > 0.5:
		_lightning -= delta
		if _lightning <= 0.0:
			lightning()
	_time += delta
	RenderingServer.global_shader_parameter_set("weather_time", fposmod(_time, 3600.0))
	_update_moon()
	_update_flash(delta)
	_mask = maxf(0.0, _mask - delta)
	_update_rain()
	_update_wet(delta)
	_update_wind(delta)
	_update_fog()
	_update_blood(delta)
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


## Ein Hund heult hinter der Waldkante (Spielkonzept 4.25) – verstreut und zufällig als Stimmung (HOWL_EVERY), nach
## `delay` Sekunden. Nur Klang, weit weg: draußen lauter, drinnen gedämpft; im Schlaf hört man ihn nicht.
func howl(delay: float) -> void:
	get_tree().create_timer(delay, false).timeout.connect(func() -> void:
		var p := Game.player
		if p == null or p.dead or p.sleeping:
			return
		var inside := not _builder.is_outdoor(p.global_position)
		Game.play_sound("howl", HOWL_VOLUME * (BELL_INSIDE if inside else 1.0))
		if Game.tracing:
			print("[Wetter] Ein Hund heult in der Ferne"))


## Debug (--weather=…) und Zeitplan: Wetter wechseln. instant: sofort volle Stärke. blood: der Schauer ist Blutregen.
func set_weather(new_kind: Kind, instant: bool = false, blood: bool = false) -> void:
	kind = new_kind
	if kind != Kind.CLEAR:
		_stormy = kind == Kind.STORM
		_figure_seen = false
		_blood = blood
		_blood_reacted = false
		if blood:
			blood_done = true
			if instant:
				stain = 1.0
				_blood_amount = 1.0
			if Game.tracing:
				print("[Wetter] Blutregen")
	if kind == Kind.CLEAR:
		_timer = _gap(CLEAR_EARLY, CLEAR_LATE)
	else:
		_timer = randf_range(SHOWER_TIME.x, SHOWER_TIME.y)
		_lightning = randf_range(3.0, 8.0) if instant else randf_range(LIGHTNING_GAP.x, LIGHTNING_GAP.y)
	if instant:
		intensity = 0.0 if kind == Kind.CLEAR else 1.0
		wet = intensity   # die Scheiben gleich mit
	if Game.tracing:
		print("[Wetter] %s für %d s" % [["klar", "Regen", "Gewitter"][kind], int(_timer)])


## Ein Blitz: zwei, drei Zuckungen, dann (je nach Entfernung) der Donner. Manchmal steht im ersten Aufzucken eine
## Gestalt zwischen den Bäumen (LightningFigure) – dann folgt die zweite Zuckung später, und sie ist fort.
## figure: Gestalt sicher (Debug --weather=gestalt).
func lightning(figure: bool = false) -> void:
	_lightning = randf_range(LIGHTNING_GAP.x, LIGHTNING_GAP.y)
	_flash_queue = [0.0, randf_range(0.08, 0.14)]
	_flickers = 0
	if (figure or (not _figure_seen and randf() < LightningFigure.CHANCE)) and _figure.place(figure):
		_figure_seen = true   # höchstens einmal je Gewitter
		_flash_queue = [0.0, randf_range(LightningFigure.GONE.x, LightningFigure.GONE.y)]
	elif randf() < 0.5:
		_flash_queue.append(randf_range(0.25, 0.4))
	var delay := randf_range(THUNDER_DELAY.x, THUNDER_DELAY.y)
	var loud := clampf(1.3 - delay / THUNDER_DELAY.y, 0.4, 1.0)
	get_tree().create_timer(delay, false).timeout.connect(_thunder.bind(loud))
	if Game.tracing:
		print("[Wetter] Blitz, Donner nach %.1f s" % delay)


func _thunder(loud: float) -> void:
	var p := Game.player
	var inside := p != null and not _builder.is_outdoor(p.global_position)
	var kind := "thunder_close" if loud >= THUNDER_CLOSE else ("thunder_short" if loud >= THUNDER_MID else "thunder_far")
	Game.play_sound(kind, loud * (0.7 if inside else 1.0))
	Game.caption("[Donner]")
	_mask = MASK_TIME * loud
	animals.on_thunder(loud)   # Hunde schlagen an, Krähen fliegen auf


## Donner übertönt gerade alles: Hörweite × diesen Wert (MonsterDirector.on_noise).
func masking() -> float:
	return 1.0 - MASK * clampf(_mask / MASK_TIME, 0.0, 1.0)


func _update_flash(delta: float) -> void:
	for i in range(_flash_queue.size() - 1, -1, -1):
		_flash_queue[i] -= delta
		if _flash_queue[i] <= 0.0:
			_flash_queue.remove_at(i)
			_flash = randf_range(0.7, 1.0)
			_flickers += 1
			if _figure.placed:   # nur im ersten Aufzucken, beim zweiten ist sie fort
				_figure.set_shown(_flickers == 1)
			Game.shot_event("lightning", 4)   # im Hintergrundfenster hinkt das Bild nach
			if _builder and _builder.attic_spook:   # Spuk im Dachboden: dreht den Spieler im Blitzbild
				_builder.attic_spook.on_flash()
			if Game.power_cut:   # Stromausfall im Gewitter (Spielkonzept 4.28)
				Game.power_cut.on_flash()
	_flash = maxf(0.0, _flash - delta * FLASH_DECAY)
	if _figure.placed and _flash_queue.is_empty() and _flash < 0.05:
		_figure.set_shown(false)
	var overcast := intensity * (1.0 if kind != Kind.CLEAR else 0.6)
	_moon_light = _moon_phase_light() * (1.0 - 0.6 * overcast)
	if _moon:
		_moon.light_energy = _moon_energy * _moon_light + _flash * FLASH_ENERGY
		# im Nebel nur schwach aufleuchten – sonst wird er im Blitz eine weiße Wand
		_moon.light_volumetric_fog_energy = (_moon_energy * _moon_light + _flash * FLASH_FOG) / _moon.light_energy
		var flash_color := Color(0.85, 0.9, 1.0).lerp(BLOOD_FLASH, _blood_amount * intensity)
		_moon.light_color = Color(0.55, 0.65, 1.0).lerp(flash_color, clampf(_flash, 0.0, 1.0))
	if _sky:
		_sky.set_shader_parameter("flash", _flash)
		_sky.set_shader_parameter("blood", _blood_amount * intensity)
		var clear_sky := lerpf(_clouds, CLOUDS_LATE, _season())   # bis Halloween wolkiger
		_sky.set_shader_parameter("cloud_cover", lerpf(clear_sky, CLOUDS_RAIN, overcast))


## So viel vom vollen Mondlicht kommt gerade an (Phase und Wolken, ohne Blitz) – auch für das Mondlicht durch die
## Fenster, das das Monster sehen lässt (MonsterDirector.light_at).
func moonlight() -> float:
	return _moon_light


# --- Mond, Wind, Nebel, nasse Scheiben (7.8) -----------------------------------------------------

## Mondalter als Winkel: 0 Vollmond, ±PI Neumond, negativ zunehmend.
func moon_phase() -> float:
	var day := Calendar.day_float(Game.director.elapsed) if Game.director else float(Calendar.FIRST_DAY)
	return wrapf(TAU * (day - FULL_MOON) / SYNODIC, -PI, PI)


func _moon_phase_light() -> float:
	return lerpf(MOON_DARK, 1.0, 0.5 + 0.5 * cos(moon_phase()))


func _update_moon() -> void:
	if _sky:
		_sky.set_shader_parameter("moon_phase", moon_phase())


## 0 am 1. Oktober … 1 an Halloween, gleitend über den Tag.
func _season() -> float:
	var day := Calendar.day_float(Game.director.elapsed) if Game.director else float(Calendar.FIRST_DAY)
	return clampf((day - Calendar.FIRST_DAY) / float(Calendar.HALLOWEEN - Calendar.FIRST_DAY), 0.0, 1.0)


## Sind auf den Scheiben gerade Tropfen oder rote Flecken zu sehen?
func panes_wet() -> bool:
	return wet > 0.002 or stain > 0.01


func _update_wet(delta: float) -> void:
	if intensity > 0.05:
		wet = move_toward(wet, intensity, delta * WET_RATE)
	else:
		wet = move_toward(wet, 0.0, delta / DRY_TIME)
	RenderingServer.global_shader_parameter_set("rain_wet", wet)
	if panes_wet() != _drops_on:
		_drops_on = panes_wet()
		get_tree().set_group("rain_panes", "visible", _drops_on)


## Wie stark die Böe gerade ist (0 … 1): der Böenanteil am Wind, bei Regen und Sturm stärker. Starke Böen blasen
## offene Kerzen draußen aus (Item.gust_out_chance, Entscheidung 3.11.).
func gust() -> float:
	return clampf(_gust * (0.5 + intensity), 0.0, 1.0)


## Debug (--weather=boe): gleich eine heftige Böe, ein paar Sekunden lang.
func force_gust() -> void:
	_gust_target = 1.0
	_gust_timer = GUST_TIME.y


func _update_wind(delta: float) -> void:
	_gust_timer -= delta
	if _gust_timer <= 0.0:
		_gust_timer = randf_range(GUST_TIME.x, GUST_TIME.y)
		_gust_target = randf() * randf()   # meist schwach, selten heftig
	_gust = move_toward(_gust, _gust_target, delta / 1.5)
	var weather_wind := WIND_STORM if _stormy else WIND_RAIN
	wind = clampf(lerpf(WIND_CALM.x, WIND_CALM.y, _season()) + intensity * weather_wind + _gust * GUST * (0.5 + intensity), 0.0, 1.0)
	_fog_drift += Vector2(FALL.x, FALL.z).normalized() * (0.15 + 0.8 * wind) * delta
	RenderingServer.global_shader_parameter_set("wind_strength", wind)
	if _rain_mat:   # Regen fällt im Wind schräger
		var slant := Vector2(FALL.x, FALL.z) * (0.4 + 1.2 * wind)
		_rain_mat.set_shader_parameter("wind", slant)
		if _rain.draw_pass_1:
			(_rain.draw_pass_1.surface_get_material(0) as ShaderMaterial).set_shader_parameter("fall", Vector3(slant.x, FALL.y, slant.y))
	var p := Game.player
	if Game.audio:
		var outside := p != null and _builder.is_outdoor(p.global_position)
		Game.audio.wind = smoothstep(0.1, 1.0, wind) * (WIND_OUT if outside else WIND_IN)
		Game.audio.wind_gust = clampf(_gust + 0.4 * intensity, 0.0, 1.0)
	_leaf_timer -= delta
	if _leaf_timer <= 0.0:
		_leaf_timer = 0.25
		var slant := Vector3(FALL.x, 0.0, FALL.z).normalized() * wind * LEAF_SLANT
		for leaves in _builder.leaf_emitters:
			leaves.speed_scale = 1.0 + wind * LEAF_RUSH
			leaves.direction = (Vector3.DOWN + slant).normalized()


func _build_fog() -> void:
	_fog_mat = ShaderMaterial.new()
	_fog_mat.shader = load("res://shaders/ground_fog.gdshader")
	_fog_mat.set_shader_parameter("cell", CELL)
	_fog_mat.set_shader_parameter("map_origin", _origin)
	_fog = FogVolume.new()
	_fog.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	var bottom := LevelBuilder.CELLAR_Y - 1.0
	var size := Vector2(_roofs.get_width(), _roofs.get_height()) * CELL
	_fog.size = Vector3(size.x, FOG_TOP - bottom, size.y)
	_fog.position = Vector3(_origin.x + size.x / 2.0, (FOG_TOP + bottom) / 2.0, _origin.y + size.y / 2.0)
	_fog.material = _fog_mat
	_fog.visible = false   # erst mit fertiger Dachkarte
	add_child(_fog)


func _update_fog() -> void:
	if _roofs != null:
		return
	_fog.visible = true
	var s := _season()
	_fog_mat.set_shader_parameter("density", lerpf(FOG_DENSITY.x, FOG_DENSITY.y, s * s))
	_fog_mat.set_shader_parameter("height", lerpf(FOG_HEIGHT.x, FOG_HEIGHT.y, s))
	_fog_mat.set_shader_parameter("drift", Vector2(fposmod(_fog_drift.x, 1000.0), fposmod(_fog_drift.y, 1000.0)))


func _gap(early: Vector2, late: Vector2) -> float:
	var t := _progress()
	return randf_range(lerpf(early.x, late.x, t), lerpf(early.y, late.y, t))


func _progress() -> float:
	return clampf(float(Calendar.today() - Calendar.FIRST_DAY) / float(Calendar.HALLOWEEN - Calendar.FIRST_DAY), 0.0, 1.0)


# --- Blutregen (Seltenwetter, 7.8) ---------------------------------------------------------------

func save_state() -> Dictionary:
	return {"blood_done": blood_done, "stain": snappedf(stain, 0.001)}


func load_state(data: Dictionary) -> void:
	blood_done = bool(data.get("blood_done", false))
	stain = float(data.get("stain", 0.0))


## Soll der Schauer, der gerade beginnt, Blutregen sein? Einmal je Spiel, ab BLOOD_FROM mit steigender Chance, ab
## BLOOD_SURE sicher – aber nur, wenn der Spieler wach ist und ihn sieht.
func _blood_due() -> bool:
	var day := Calendar.today()
	if blood_done or day < BLOOD_FROM or not _player_sees_rain():
		return false
	return day >= BLOOD_SURE or randf() < lerpf(BLOOD_CHANCE, 1.0, float(day - BLOOD_FROM) / float(BLOOD_SURE - BLOOD_FROM))


## Wach und draußen – oder nah an einem Außenfenster mit offenem Vorhang.
func _player_sees_rain() -> bool:
	var p := Game.player
	if p == null or p.dead or p.sleeping:
		return false
	if _builder.is_outdoor(p.global_position):
		return true
	for node in get_tree().get_nodes_in_group("windows"):
		var win := node as HotelWindow
		if win.lets_moonlight() and not win.frosted and win.global_position.distance_to(p.global_position) < BLOOD_WINDOW:
			return true
	return false


func _update_blood(delta: float) -> void:
	if _blood:
		stain = maxf(stain, wet)
	elif kind != Kind.CLEAR and intensity > 0.05:
		stain = move_toward(stain, 0.0, delta * intensity / BLOOD_WASH)   # normaler Regen wäscht es ab
	_blood_amount = move_toward(_blood_amount, 1.0 if _blood else 0.0, delta / BLOOD_FADE)
	RenderingServer.global_shader_parameter_set("rain_blood", _blood_amount)
	RenderingServer.global_shader_parameter_set("pane_stain", stain)
	if _blood != _blood_tinted:
		_tint_rain(_blood)
	if _blood and not _blood_reacted and intensity > 0.4:
		_blood_reacted = true
		_blood_reactions()
	_update_puddles()


## Regentropfen rot (Blutregen) oder wie sonst.
func _tint_rain(blood: bool) -> void:
	_blood_tinted = blood
	var mat := _rain.draw_pass_1.surface_get_material(0) if _rain.draw_pass_1 else null
	if mat is ShaderMaterial:
		(mat as ShaderMaterial).set_shader_parameter("color", BLOOD_STREAK if blood else STREAK_COLOR)


## Der Spieler merkt es, Gäste in der Nähe fürchten sich, zwei sagen etwas, zuletzt erklärt der Mutigste.
func _blood_reactions() -> void:
	Game.say("Der Regen … er ist rot.", 4.0)
	var p := Game.player
	var near: Array = []
	for g: Guest in Game.social.guests:
		if not g.dead and not g.is_asleep() and g.global_position.distance_to(p.global_position) < BLOOD_GUESTS:
			near.append(g)
	near.sort_custom(func(a: Guest, b: Guest) -> bool:
		return a.global_position.distance_squared_to(p.global_position) < b.global_position.distance_squared_to(p.global_position))
	var calm: Guest = null
	for g: Guest in near:
		var brave := float(g.profile["brave"])
		g.fear = minf(100.0, g.fear + BLOOD_FEAR * (1.2 - brave))
		if not g.is_child() and (calm == null or brave > float(calm.profile["brave"])):
			calm = g
	var lines := BLOOD_LINES.duplicate()
	lines.shuffle()
	var delay := 2.5
	var voices := 0
	for g: Guest in near:
		if g == calm or voices >= BLOOD_VOICES:
			continue
		var line: String = BLOOD_CHILD if g.is_child() else lines[voices]
		get_tree().create_timer(delay, false).timeout.connect(func() -> void:
			if is_instance_valid(g) and not g.dead:
				g.say(line))
		delay += 3.0
		voices += 1
	if calm:
		get_tree().create_timer(delay + 1.0, false).timeout.connect(func() -> void:
			if is_instance_valid(calm) and not calm.dead:
				calm.say(BLOOD_CALM))
	if Game.tracing:
		print("[Wetter] Blutregen: %d Gäste in der Nähe, erklärt: %s" % [near.size(), calm.display_name if calm else "-"])


## Rötliche Pfützen draußen (Decals auf ebenem Boden unter freiem Himmel, feste Stellen), so kräftig wie stain.
func _update_puddles() -> void:
	if stain < 0.01:
		if not _puddles.is_empty() and _puddles[0].visible:
			for d in _puddles:
				d.visible = false
		return
	if _puddles.is_empty():
		if _roof_img == null:
			return
		_build_puddles()
	for d in _puddles:
		d.visible = true
		d.modulate = Color(PUDDLE_COLOR, stain)


func _build_puddles() -> void:
	var tex := ImageTexture.create_from_image(_puddle_image())
	var rng := RandomNumberGenerator.new()
	rng.seed = PUDDLE_SEED
	var size := Vector2i(_roof_img.get_width(), _roof_img.get_height())
	for i in PUDDLES * 60:
		if _puddles.size() >= PUDDLES:
			break
		var cell := Vector2i(rng.randi_range(0, size.x - 1), rng.randi_range(0, size.y - 1))
		var y := _roof_img.get_pixel(cell.x, cell.y).r
		var flat := _origin + (Vector2(cell) + Vector2.ONE * 0.5) * CELL
		var pos := Vector3(flat.x, y, flat.y)
		if absf(y) > 0.3 or not _builder.is_outdoor(pos + Vector3.UP * 0.3):
			continue
		var d := Decal.new()
		var s := rng.randf_range(PUDDLE_SIZE.x, PUDDLE_SIZE.y)
		d.size = Vector3(s, 0.6, s * rng.randf_range(0.5, 0.9))
		d.position = pos
		d.rotation.y = rng.randf() * TAU
		d.texture_albedo = tex
		d.modulate = Color(PUDDLE_COLOR, 0.0)
		d.upper_fade = 0.2
		d.lower_fade = 0.2
		add_child(d)
		_puddles.append(d)


## Weicher, unregelmäßiger Fleck (weiß, Deckkraft zum Rand hin weg) – die Farbe gibt modulate.
func _puddle_image() -> Image:
	var n := 64
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.seed = PUDDLE_SEED
	noise.frequency = 0.08
	for y in n:
		for x in n:
			var v := (Vector2(x, y) + Vector2.ONE * 0.5) / n * 2.0 - Vector2.ONE
			var edge := 0.75 + 0.25 * noise.get_noise_2d(x, y)
			var a := clampf((edge - v.length()) / 0.25, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * (0.75 + 0.25 * noise.get_noise_2d(x * 3.0, y * 3.0))))
	return img


# --- Regen ----------------------------------------------------------------------------------

func _update_rain() -> void:
	var p := Game.player
	var on := intensity > 0.01 and p != null and _roofs == null and _rows_done > 0   # erst mit fertiger Dachkarte
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
	_set_drops()
	_rain.emitting = false
	_rain.visible = false
	add_child(_rain)


## Tropfen als feine Striche (shaders/rain_streak.gdshader).
func _set_drops() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/rain_streak.gdshader")
	mat.set_shader_parameter("color", STREAK_COLOR)
	mat.set_shader_parameter("fall", FALL)
	mat.set_shader_parameter("streak_length", STREAK.x)
	mat.set_shader_parameter("streak_width", STREAK.y)
	mat.set_shader_parameter("min_pixels", STREAK_PIXELS)
	var quad := QuadMesh.new()   # 1 × 1, der Shader streckt ihn
	quad.material = mat
	_rain.amount = DROPS
	_rain.draw_pass_1 = quad
	if _blood_tinted:
		_tint_rain(true)


## Dach-Höhenkarte über dem ganzen Plan (+ Rand): je Zelle die Höhe der obersten Fläche (Strahl von oben, Ebenen 1 und
## Decke). Gebaut zeilenweise in den ersten Bildern (_build_roof_rows, je Bild nur ROOF_BUDGET_USEC, sonst ruckelt
## der Start) – erst danach regnet es und liegt Nebel.
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
	var start := Time.get_ticks_usec()
	var first := _rows_done
	while _rows_done < _roofs.get_height():
		if _rows_done > first and Time.get_ticks_usec() - start > ROOF_BUDGET_USEC:
			break
		var y := _rows_done
		_rows_done += 1
		for x in _roofs.get_width():
			var p := _origin + (Vector2(x, y) + Vector2.ONE * 0.5) * CELL
			var query := PhysicsRayQueryParameters3D.create(Vector3(p.x, TOP + 4.0, p.y), Vector3(p.x, -2.0, p.y),
				1 | LevelBuilder.LAYER_CEILING)
			var hit := space.intersect_ray(query)
			_roofs.set_pixel(x, y, Color((hit["position"] as Vector3).y if not hit.is_empty() else -2.0, 0, 0))
	if _rows_done >= _roofs.get_height():
		_roof_img = _roofs
		var tex := ImageTexture.create_from_image(_roofs)
		_rain_mat.set_shader_parameter("roof_height", tex)
		_rain_mat.set_shader_parameter("map_origin", _origin)
		_fog_mat.set_shader_parameter("roof_height", tex)   # Nebel nur unter freiem Himmel
		_roofs = null   # die Textur hat jetzt die Daten
		_rows_done = 1 << 30
