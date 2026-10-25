class_name ShowerScare
extends Node3D
## Der Lakengeist in der Dusche (Spielkonzept 4.24): ein einmaliger, fest gesetzter Moment im Bad von Zimmer 13 – eigene
## Inszenierung, nicht Teil der Regeln des Lakengeists (keine Würfel, keine Zeugen, zählt nicht für seine Stufen).
## Beginnt die erste Nachtruhe, die mindestens einen Spieltag nach der ersten Begegnung mit ihm liegt
## (SheetGhost.first_seen, Social.start_sleep → on_night_rest), läuft im Bad die Dusche (RUNNING): Wasserrauschen
## (SynthAudio.shower – nur für den Spieler, kein Lärm), dichter weißer Nebel in der Duschecke hinter beschlagenem Glas,
## Flocken und leiser Geisterklang; die Badlampe wird langsam dunkler und pulsiert (FlickerLight.hold – kein Flackern, der
## Schalter klickt nur). Wer schläft, wacht auf; Schlafen geht nicht mehr (HideSpot.interact). Das bleibt, bis man hingeht.
## Kommt der Spieler der Duschtür auf CATCH_RANGE nahe und ist keine andere Bedrohung im Haus, fängt die Kamera ihn
## (CAUGHT): Der Blick wird auf den Nebel gerissen (abgeschwächter Blickzug, Settings.look_pull < 1: nur sanft gelenkt),
## man steht fest, der Geist taucht darin auf und würgt wie sonst (SheetGhost.shower_visit). Losgerissen (on_escaped):
## Das Wasser hört auf, der Nebel verzieht sich, die Scheibe klart auf, auf der Glastür bleiben blutige Handabdrücke
## (Traces) – erlebt (DONE), es passiert nie wieder. Erwürgt: Beim Laden läuft die Dusche wieder (gespeichert ist RUNNING).
## Debug: --dusche[=fang|los|nacht].

enum Stage { WAITING, RUNNING, CAUGHT, CLEARING, DONE }

const STAGE_NAMES := ["waiting", "running", "running", "done", "done"]   ## so gespeichert (gefangen zählt als laufend)
const AMBIENCE := "res://assets/sound/ghost_ambience.mp3"

# --- Tuning -------------------------------------------------------------------
const CATCH_RANGE := 1.5        ## so nah an der Duschtür (waagerecht) fängt die Kamera den Spieler
const GHOST_DELAY := 0.9        ## nach dem Fang taucht er so viel später im Nebel auf
const SNAP_SPEED := 14.0        ## Blick zum Nebel: gerissen (1 − e^(−k·t) je Bild) …
const GENTLE_SPEED := Vector2(0.8, 2.5)   ## … abgeschwächt: sanft gelenkt, je nach Settings.look_pull (0,2 … unter 1)
const FADE_IN := 4.0            ## Nebel und Rauschen ziehen so lange auf
const DIM_TIME := 8.0           ## so lange wird die Badlampe dunkler, bis sie nur noch pulsiert
const PULSE := Vector2(0.1, 0.22)   ## Helligkeit der Lampe: so viel plus so viel im Puls …
const PULSE_PERIOD := 2.8       ## … alle so viele Sekunden
const WATER_RANGE := 9.0        ## Hörweite des Wassers (m, gedämpft durch Wände und Türen wie Lärm)
const WATER_VOLUME := 0.55
const WATER_STOP := 1.2         ## so schnell hört das Wasser auf
const CLEAR_TIME := 20.0        ## so lange verzieht sich der Nebel und klart die Scheibe auf
const FOG_DENSITY := 1.6        ## in der Duschecke …
const SPILL_DENSITY := 0.35     ## … und was über die Glaswand quillt
const FOG_GLOW := Color(0.45, 0.46, 0.48)   ## Eigenleuchten: weißer Dampf auch im dunklen Bad (sonst stünde dort ein dunkler Block)
const FOG_GLASS := Color(0.86, 0.88, 0.9, 0.5)    ## beschlagene Scheibe …
const FOG_GLASS_GLOW := Color(0.16, 0.165, 0.17)  ## … milchig hell vom Dampf dahinter
const AMBIENCE_DB := -6.0       ## leiser Geisterklang, bis er selbst da ist
const AMBIENCE_RANGE := 7.0
## Dampf: Anzahl, Lebenszeit, Größe, Farbe (Deckkraft); Flocken wie am Lakengeist
const STEAM := 36
const STEAM_LIFE := 5.0
const STEAM_SIZE := 0.55
const STEAM_COLOR := Color(0.9, 0.91, 0.93, 0.3)
const FLAKES := 20
const FLAKE_SIZE := 0.04

var stage := Stage.WAITING
var debug_struggle := false     ## Debug (--dusche=los): wild hin und her, bis er loslässt

var _builder: LevelBuilder
var _shower: Node3D             ## Duschecke im Bad von Zimmer 13 (LevelBuilder, Gruppe „showers“), lokal +Z = Tür
var _bath_id := ""
var _door := Vector3.ZERO       ## Mitte der Glastür am Boden
var _center := Vector3.ZERO     ## Mitte der Duschecke am Boden
var _door_z := 0.0              ## Außenfläche der Glastür (lokal z)
var _lamps: Array[Lamp] = []
var _glass: Array = []          ## [MeshInstance3D, Fläche] mit dem Glas der Duschecke
var _fogged: StandardMaterial3D
var _fog_mat: ShaderMaterial
var _spill_mat: ShaderMaterial
var _steam: CPUParticles3D
var _flakes: CPUParticles3D
var _flake_mat: ShaderMaterial
var _ambience: AudioStreamPlayer3D
var _level := 0.0               ## Nebel, Dampf, beschlagene Scheibe (0..1)
var _water := 0.0               ## Wasser (0..1)
var _dim := 0.0                 ## Badlampe: 0 = wie geschaltet, 1 = nur noch Puls
var _t := 0.0
var _catch_t := 0.0
var _ghost_called := false
var _sound_timer := 0.0
var _heard := 0.0
var _struggle_t := 0.0
var _struggle_left := true


func setup(builder: LevelBuilder) -> ShowerScare:
	_builder = builder
	return self


func _ready() -> void:
	for node in get_tree().get_nodes_in_group("showers"):
		var shower := node as Node3D
		if _builder.home_room_at(shower.global_position) == LevelBuilder.PLAYER_ROOM:
			_shower = shower
	if _shower == null:
		push_warning("Dusche (4.24): Zimmer 13 hat keine Duschecke")
		return
	_bath_id = _builder.room_at(_shower.global_position)
	_center = _shower.global_position
	_door_z = LevelBuilder.SHOWER_SIZE / 2.0 - LevelBuilder.SHOWER_GLASS_INSET
	_find_glass()
	_door = _shower.to_global(Vector3(0, 0, _door_z))
	for node in get_tree().get_nodes_in_group("lamp_fixtures"):
		var lamp := node as Lamp
		var p := lamp.global_position
		if p.y > _center.y - 0.5 and p.y < _center.y + LevelBuilder.H + 0.5 and _builder.room_at(Vector3(p.x, _center.y, p.z)) == _bath_id:
			_lamps.append(lamp)
	_build()
	_show(false)


## Glas der Duschecke (Mat.glass, LevelBuilder._fixture_materials) – beschlägt; daran die Außenfläche der Tür.
func _find_glass() -> void:
	for m: MeshInstance3D in _shower.find_children("*", "MeshInstance3D", true, false):
		for s in m.mesh.get_surface_count():
			if m.get_surface_override_material(s) != Mat.glass():
				continue
			_glass.append([m, s])
			var verts: PackedVector3Array = m.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]
			var to_body := _shower.global_transform.affine_inverse() * m.global_transform
			var front := -INF
			for v in verts:
				front = maxf(front, (to_body * v).z)
			if front > 0.0:
				_door_z = front
	_fogged = Mat.glass().duplicate() as StandardMaterial3D
	_fogged.emission_enabled = true


func _build() -> void:
	var shader: Shader = load("res://shaders/shower_steam.gdshader")
	var inner := LevelBuilder.SHOWER_SIZE - 0.08
	var top := LevelBuilder.SHOWER_GLASS_H
	_fog_mat = ShaderMaterial.new()
	_fog_mat.shader = shader
	_spill_mat = ShaderMaterial.new()
	_spill_mat.shader = shader
	_spill_mat.set_shader_parameter("edge", Vector3(0.3, 0.4, 0.3))
	var fog := FogVolume.new()   # die Duschecke bis über die Glaswand
	fog.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	fog.size = Vector3(inner, top, inner)
	fog.position = Vector3(0, LevelBuilder.SHOWER_TRAY + top / 2.0, 0)
	fog.material = _fog_mat
	_shower.add_child(fog)
	var spill := FogVolume.new()   # quillt oben über das Glas und ein Stück vor die Tür
	spill.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX
	spill.size = Vector3(inner + 0.4, 0.9, inner + 0.9)
	spill.position = Vector3(0, top + 0.1, 0.35)
	spill.material = _spill_mat
	_shower.add_child(spill)
	# Dampfschwaden: weiche Ballen, die in der Duschecke aufsteigen
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in 32:
		for x in 32:
			var d := Vector2(x - 15.5, y - 15.5).length() / 16.0
			img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d, 0.0, 1.0) ** 2.0))
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = ImageTexture.create_from_image(img)
	_steam = Geo.particles(STEAM, STEAM_LIFE, STEAM_SIZE, mat, 0.3, 0.4)
	_steam.color = STEAM_COLOR
	_steam.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_steam.emission_box_extents = Vector3(inner * 0.4, 0.5, inner * 0.4)
	_steam.position = Vector3(0, 0.9, 0)
	_steam.direction = Vector3.UP
	_steam.spread = 25.0
	_steam.initial_velocity_min = 0.12
	_steam.initial_velocity_max = 0.3
	_steam.gravity = Vector3.ZERO
	_steam.damping_min = 0.02
	_steam.damping_max = 0.05
	_steam.scale_amount_min = 0.7
	_steam.scale_amount_max = 1.6
	_shower.add_child(_steam)
	# Flocken im Nebel – das Zeichen des Lakengeists (4.20)
	_flake_mat = Mat.particle(null, 0.7)
	_flake_mat.set_shader_parameter("spin", 1.5)
	_flake_mat.set_shader_parameter("sway", 0.04)
	_flakes = Geo.particles(FLAKES, 3.5, FLAKE_SIZE, _flake_mat, 0.15, 0.4)
	_flakes.color = Color(0.9, 0.9, 0.95)
	_flakes.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_flakes.emission_box_extents = Vector3(inner * 0.4, 0.4, inner * 0.4)
	_flakes.position = Vector3(0, 1.6, 0)
	_flakes.direction = Vector3.DOWN
	_flakes.spread = 40.0
	_flakes.initial_velocity_min = 0.03
	_flakes.initial_velocity_max = 0.1
	_flakes.gravity = Vector3(0, -0.08, 0)
	_shower.add_child(_flakes)
	_ambience = AudioStreamPlayer3D.new()
	var stream := load(AMBIENCE) as AudioStreamMP3
	stream.loop = true
	_ambience.stream = stream
	_ambience.attenuation_model = AudioStreamPlayer3D.ATTENUATION_DISABLED   # gedämpft über Game.hearing, nur die Richtung
	_ambience.position = Vector3(0, 1.5, 0)
	_shower.add_child(_ambience)


# --- Ablauf -----------------------------------------------------------------------------------

## Läuft das Wasser (bis man den Moment erlebt hat)?
func running() -> bool:
	return stage == Stage.RUNNING or stage == Stage.CAUGHT


## Kamera gefangen bzw. er würgt – Speichern gesperrt.
func busy() -> bool:
	return stage == Stage.CAUGHT


## Schlafen geht nicht, solange die Dusche läuft (HideSpot.interact).
func blocks_sleep() -> bool:
	return running()


## Solange die Dusche läuft, kommt der Lakengeist in Zimmer 13 nicht zum Spieler – der Moment wartet auf ihn
## (SheetGhost._player_free).
func reserves(player: Player) -> bool:
	return running() and _builder.home_room_at(player.global_position) == LevelBuilder.PLAYER_ROOM


## Beginn der Nachtruhe (Social.start_sleep): die erste mindestens einen Spieltag nach der ersten Begegnung.
func on_night_rest() -> void:
	var ghost := Game.ghost
	if stage != Stage.WAITING or _shower == null or ghost == null or not ghost.met():
		return
	if Game.director.elapsed - ghost.first_seen < Calendar.DAY_SECONDS:
		return
	start()


## Die Dusche läuft (auch Debug).
func start() -> void:
	if _shower == null or running():
		return
	stage = Stage.RUNNING
	_show(true)
	var player := Game.player
	if player and player.sleeping:
		player.wake_up("Du wachst auf. Im Bad rauscht Wasser …")
	if Game.tracing:
		print("[Dusche] läuft – %s, %s (Badlampen: %d)" % [Calendar.date_text(Game.director.elapsed),
			Calendar.time_text(Game.director.elapsed), _lamps.size()])


## Losgerissen (SheetGhost._struggle): Wasser aus, Nebel verzieht sich, Handabdrücke auf der Glastür.
func on_escaped() -> void:
	if stage != Stage.CAUGHT:
		return
	stage = Stage.CLEARING
	Game.player.spellbound = false
	_release_lamps()
	if debug_struggle:
		debug_struggle = false
		Input.action_release("move_left")
		Input.action_release("move_right")
	if Game.traces:
		Game.traces.add_shower_handprints(_shower, _door_z)
	get_tree().create_timer(2.5, false).timeout.connect(Game.say.bind("Das Wasser hat aufgehört.", 3.0))
	if Game.tracing:
		print("[Dusche] erlebt – das Wasser hört auf, Handabdrücke auf der Glastür")


func _process(delta: float) -> void:
	if _shower == null:
		return
	_t += delta
	match stage:
		Stage.RUNNING:
			_level = minf(1.0, _level + delta / FADE_IN)
			_water = _level
			_dim = minf(1.0, _dim + delta / DIM_TIME)
			_check_catch()
		Stage.CAUGHT:
			_caught(delta)
		Stage.CLEARING:
			_water = maxf(0.0, _water - delta / WATER_STOP)
			_level = maxf(0.0, _level - delta / CLEAR_TIME)
			if _level <= 0.0:
				stage = Stage.DONE
				_show(false)
	if stage == Stage.WAITING or stage == Stage.DONE:
		return
	_update_lamps()
	_update_look()
	_update_sound(delta)


## Kommt er der Duschtür nahe und ist keine andere Bedrohung im Haus: Kamera fangen. Sonst wartet der Moment.
func _check_catch() -> void:
	var player := Game.player
	if player == null or player.dead or Game.game_over or Game.creating or player.hiding != null or player.in_dialog \
			or player.spellbound or _threat():
		return
	var p := player.global_position
	if absf(p.y - _door.y) > 1.0 or Vector2(p.x - _door.x, p.z - _door.z).length() > CATCH_RANGE \
			or _builder.room_at(p) != _bath_id:
		return
	stage = Stage.CAUGHT
	_catch_t = 0.0
	_ghost_called = false
	if player.seat:
		player.leave_seat(true)
	if player.bag_open:
		player.close_bag(false)
	player.spellbound = true
	Game.play_sound("sting", 0.7)
	if Game.tracing:
		print("[Dusche] Kamera gefangen (%.1f m vor der Tür, Blickzug %.2f)" % [Vector2(p.x - _door.x, p.z - _door.z).length(), Settings.look_pull])


## Monster unterwegs oder angekündigt, Lakengeist woanders, Geisterstunde, Kürbismann im Haus oder angekündigt.
func _threat() -> bool:
	var director := Game.director
	return director == null or director.other_threat_active(null) or director.is_signalling() \
		or (Game.ghost != null and Game.ghost.ghost_hour())


func _caught(delta: float) -> void:
	_catch_t += delta
	var player := Game.player
	if player.dead or Game.game_over:
		return
	if player.gripped:   # er hat zugepackt – jetzt zählen die Bewegungstasten (Losreißen)
		player.spellbound = false
		if debug_struggle:
			_debug_struggle(delta)
	else:
		_pull_gaze(delta)
	if not _ghost_called and _catch_t >= GHOST_DELAY:
		_ghost_called = true
		Game.ghost.shower_visit(_center)
	elif _ghost_called and not Game.ghost.is_active() and not player.gripped:
		# er ist ohne Griff verschwunden (sollte nicht vorkommen) – der Moment wartet weiter
		player.spellbound = false
		stage = Stage.RUNNING


## Blick auf den Nebel, dann auf ihn: gerissen, mit abgeschwächtem Blickzug sanft gelenkt.
func _pull_gaze(delta: float) -> void:
	var player := Game.player
	var target := Vector3(_center.x, player.camera.global_position.y - 0.05, _center.z)
	if _ghost_called and Game.ghost.is_active():
		target = Game.ghost.global_position + Vector3.UP * (SheetGhost.HANDS_Y + 0.4)
	var to := target - player.camera.global_position
	var speed := SNAP_SPEED if Settings.look_pull >= 1.0 else lerpf(GENTLE_SPEED.x, GENTLE_SPEED.y, (Settings.look_pull - 0.2) / 0.8)
	var k := 1.0 - exp(-speed * delta)
	player.rotation.y = lerp_angle(player.rotation.y, atan2(-to.x, -to.z), k)
	player.head.rotation.x = lerpf(player.head.rotation.x, clampf(atan2(to.y, Vector2(to.x, to.z).length()), -1.4, 1.4), k)


## Debug (--dusche=los): zehn Richtungswechsel je Sekunde – genug gegen den Griff, auch mit grober Schrittweite.
func _debug_struggle(delta: float) -> void:
	_struggle_t -= delta
	if _struggle_t > 0.0:
		return
	_struggle_t = 1.0 / 10.0
	Input.action_release("move_left" if _struggle_left else "move_right")
	_struggle_left = not _struggle_left
	Input.action_press("move_left" if _struggle_left else "move_right")


# --- Licht, Bild, Klang --------------------------------------------------------------------------

## Badlampe: aus dem, was der Schalter sagt, langsam in den Puls – mit Birne; ohne Birne bleibt sie dunkel.
func _update_lamps() -> void:
	if stage == Stage.CLEARING:
		return
	var pulse := PULSE.x + PULSE.y * (0.5 + 0.5 * sin(TAU * _t / PULSE_PERIOD))
	for lamp in _lamps:
		if lamp.light == null:
			continue
		if not lamp.has_bulb or lamp.bulb_broken:
			lamp.light.hold = -1.0
			continue
		lamp.light.hold = lerpf(1.0 if lamp.is_lit() else 0.0, pulse, _dim)


func _release_lamps() -> void:
	for lamp in _lamps:
		if lamp.light:
			lamp.light.hold = -1.0
	_dim = 0.0


func _update_look() -> void:
	var t := _t
	_fog_mat.set_shader_parameter("t", t)
	_fog_mat.set_shader_parameter("density", FOG_DENSITY * _level)
	_fog_mat.set_shader_parameter("emission", FOG_GLOW * _level)
	_spill_mat.set_shader_parameter("t", t)
	_spill_mat.set_shader_parameter("density", SPILL_DENSITY * _level)
	_spill_mat.set_shader_parameter("emission", FOG_GLOW * _level)
	_fogged.albedo_color = Mat.glass().albedo_color.lerp(FOG_GLASS, _level)
	_fogged.roughness = lerpf(Mat.glass().roughness, 0.8, _level)
	_fogged.emission = FOG_GLASS_GLOW * _level
	var steaming := running()
	if _steam.emitting != steaming:
		_steam.emitting = steaming
	var flaking := running() and not (_ghost_called and Game.ghost.is_active())   # ist er da, rieseln seine eigenen
	if _flakes.emitting != flaking:
		_flakes.emitting = flaking


## Wasser und Geisterklang: alle 0,25 s, wie laut der Spieler es hier hört (Wände, Türen), dazwischen weich nachgeführt.
func _update_sound(delta: float) -> void:
	_sound_timer -= delta
	if _sound_timer <= 0.0:
		_sound_timer = 0.25
		_heard = Game.hearing(_center + Vector3.UP * 1.2, WATER_RANGE) if Game.player else 0.0
		if Game.audio and Game.player:
			Game.audio.shower_muffle = 0.0 if _builder.room_at(Game.player.global_position) == _bath_id else 1.0
	if Game.audio:
		Game.audio.shower = move_toward(Game.audio.shower, _heard * _water * WATER_VOLUME, delta)
	var ghostly := _level if stage == Stage.RUNNING or (stage == Stage.CAUGHT and not _ghost_called) else 0.0
	var near := Game.hearing(_center + Vector3.UP * 1.2, AMBIENCE_RANGE) if Game.player else 0.0
	var level := ghostly * near * Settings.effects_volume
	if level <= 0.001:
		if _ambience.playing:
			_ambience.stop()
		return
	_ambience.volume_db = AMBIENCE_DB + linear_to_db(level)
	if not _ambience.playing:
		_ambience.play(randf() * _ambience.stream.get_length())


## Nebel, Dampf, Flocken und beschlagenes Glas an oder aus (aus: alles weg, Lampen wieder wie geschaltet).
func _show(on: bool) -> void:
	if _shower == null:
		return
	if on:
		for g in _glass:
			(g[0] as MeshInstance3D).set_surface_override_material(g[1], _fogged)
		_update_look()
		return
	_level = 0.0
	_water = 0.0
	_release_lamps()
	_steam.emitting = false
	_flakes.emitting = false
	_ambience.stop()
	_fog_mat.set_shader_parameter("density", 0.0)
	_spill_mat.set_shader_parameter("density", 0.0)
	for g in _glass:
		(g[0] as MeshInstance3D).set_surface_override_material(g[1], Mat.glass())
	if Game.audio:
		Game.audio.shower = 0.0


func _exit_tree() -> void:
	if Game.audio:
		Game.audio.shower = 0.0
	if debug_struggle:
		Input.action_release("move_left")
		Input.action_release("move_right")


# --- Debug & Speichern ---------------------------------------------------------------------------

## Debug (--dusche[=fang|los]): Der Lakengeist gilt als gesehen, die Dusche läuft sofort (Nebel ganz da). Ohne Angabe
## stehst du in der Badtür bzw. so weit von der Dusche, dass sie dich noch nicht fängt, Blick zu ihr; fang: knapp vor
## der Duschtür – sie fängt dich gleich; los: dazu reißt du dich los (wild hin und her).
func debug(what: String) -> void:
	if _shower == null:
		Game.say("Dusche: Zimmer 13 hat keine Duschecke.", 2.5)
		return
	if not Game.ghost.met():
		Game.ghost.first_seen = Game.director.elapsed
	start()
	_level = 1.0
	_water = 1.0
	_dim = 1.0
	debug_struggle = what == "los"
	var player := Game.player
	var front := _shower.global_transform.basis.z.normalized()
	var spot := Vector3.INF
	var distances := [1.2, 1.3] if what in ["fang", "los"] else [2.6, 2.3, 2.0]
	for dist: float in distances:
		for turn: float in [0.6, -0.6, 0.0, 1.0, -1.0, 1.3, -1.3]:
			var p := _door + front.rotated(Vector3.UP, turn) * dist
			if spot == Vector3.INF and _builder.room_at(p) == _bath_id:
				spot = p
	if spot == Vector3.INF:
		spot = _door + front * 1.2
	player.global_position = spot + Vector3.UP * 0.05
	var to := _center - spot
	player.rotation.y = atan2(-to.x, -to.z)
	player.head.rotation.x = 0.0


## Debug (--dusche=nacht): Die erste Begegnung mit dem Lakengeist liegt über einen Tag zurück, die Nachtruhe beginnt
## (läuft sie schon, gilt sie als gerade begonnen) – die Dusche läuft nach der Regel.
func debug_night() -> void:
	Game.ghost.first_seen = Game.director.elapsed - Calendar.DAY_SECONDS - 1.0
	if Game.social.sleep_active:
		on_night_rest()
	else:
		Game.social.debug_sleep()


func save_state() -> Dictionary:
	return {"stage": STAGE_NAMES[stage]}


func load_state(d: Dictionary) -> void:
	if _shower == null:
		return
	match String(d.get("stage", "waiting")):
		"running":
			stage = Stage.RUNNING
			_level = 1.0
			_water = 1.0
			_dim = 1.0
			_show(true)
		"done":
			stage = Stage.DONE
			_show(false)
		_:
			stage = Stage.WAITING
			_show(false)
