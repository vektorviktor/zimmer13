class_name SheetGhost
extends Node3D
## Der Lakengeist am Fenster (Spielkonzept 4.18). Er kommt, wenn man einen Raum mit Außenfenster betritt,
## in dem das Licht aus und der Vorhang offen ist – und wird mit jedem Mal dreister. Fenstertüren nach draußen
## haben keinen Vorhang: Dort kommt er bei Licht aus noch wahrscheinlicher, ab dem 3. Mal öffnet er sie.
##   1. schwebt kurz heran · 2. fasst die Scheibe an (blutige Handabdrücke) und hypnotisiert mit kreisenden
##   Händen · 3. kommt herein und würgt · ab dem 4. Mal kommt er immer herein, auch durch den Vorhang.
## Wer gewürgt wird, reißt sich nur mit wildem Hin und Her los – der Griff zieht ständig zurück, Losreißen
## ist die seltene Ausnahme. Gäste als Zeugen vertreiben ihn. Verschwinden: in 0,5 s ausgeblendet.
## Wer sich vor ihm im Schrank versteckt, den wartet er ab: Er schwebt vor den Türen, packt zu, wer
## herauskommt, und fliegt am Ende vielleicht hinein (Luft anhalten hilft ein wenig).
## Ab dem 6. Mal taucht er auch im Flur auf, wenn alle Gäste schlafen (Nachtruhe, Social) – dann gibt es
## keine Zeugen. Er sucht die Schwachen (Player/Guest.weakness(): Schlafmangel, Rausch, Angst, Trauer): je
## schwächer, desto häufiger; ab WEAK_HALL auch früher im Flur, ganz schwach sicher, sobald man dort allein ist.
## Gäste behandelt er wie den Spieler (Spielkonzept 6.12): Wer wach im Dunkeln bei offenem Vorhang steht,
## bekommt Besuch – mit eigenem Zähler (Guest.ghost_visits). Ein erwürgter Gast bleibt als Leiche liegen.
## Wer ihn sieht, erschrickt (Guest.shock) und erzählt später davon.
## Kinder (Spielkonzept 6.13) sucht er wegen ihrer Schwäche öfter auf, würgt sie aber nie: Statt zuzupacken
## erschreckt er sie und verschwindet. Als Zeugen zählen sie nicht.
## Solange er da ist, hört man ihn: ein geloopter Klangteppich am Geist, der mit ihm ein- und ausblendet.
## Vom Saum rieseln weiße Flocken, die hinter ihm zurückbleiben und mit ihm verschwinden.
## Vor der Tür (Spielkonzept 4.18, 5.6): Hängen an einer Zimmertür Lakengespenster und ist jemand drinnen, zieht
## es ihn manchmal dorthin. Er steht lautlos vor der geschlossenen Tür und kreist mit den Händen, die Gespenster
## kreisen mit; drinnen dreht sich der Blick ganz langsam zur Tür (durch die Wand), ein Gast starrt hin und geht
## irgendwann aufmachen – außer jemand ist bei ihm. Wer die Tür öffnet, den packt er. Nach DOOR_TIME ist er weg.
## Geisterstunde (Spielkonzept 4.18, 2026-10-23): Nach der Mitternachtsglocke (Weather) bis 1 Uhr zieht er kaum
## sichtbar durch die Flure des Obergeschosses (PATROL) – nur Flocken und leiser Klang. Sieht er den Spieler im Flur
## (Senses.can_see), schwebt er auf ihn zu: Die ersten HOUR_WARNINGS Begegnungen verschwindet er kurz vor ihm, danach
## würgt er (eigener Zähler hour_meetings, seine Stufe bleibt). Greift eine der Flur-Regeln (Schwäche, ab dem 6. Mal,
## Garantie) oder kommt man ihm ans dunkle Fenster, wird ein gewöhnlicher Besuch daraus; schwache Gäste im Flur ebenso.
## In der Dusche (Spielkonzept 4.24, ShowerScare): einmal taucht er im Nebel der Duschecke von Zimmer 13 auf und würgt –
## eigene Inszenierung (shower_visit): zählt nicht für die Stufe, kein Zeuge vertreibt ihn. Der Blickzug folgt der
## Einstellung Settings.look_pull.

enum State { IDLE, APPROACH, HOVER, ENTER, STRANGLE, FADE, LURK, FLY_IN, DOOR, PATROL }

const MODEL := "res://assets/models/ghost.glb"
const AMBIENCE := "res://assets/sound/ghost_ambience.mp3"

# --- Tuning -------------------------------------------------------------------
const FROM_DAY := 2                   ## spukt ab diesem Tag (oder schon nach dem ersten Angriff)
const SPAWN_CHANCE := 0.7             ## beim Betreten eines dunklen Raums mit offenem Vorhang
const STAY_CHANCE := 0.25             ## … und alle STAY_EVERY Sekunden, solange man darin bleibt
const STAY_EVERY := 6.0
const FRENCH_DOOR_CHANCE := 0.9       ## an einer Fenstertür statt SPAWN_CHANCE …
const FRENCH_DOOR_STAY := 0.4         ## … und STAY_CHANCE
const COOLDOWN := 45.0                ## frühestens wieder nach so vielen Sekunden
const CHECK_EVERY := 0.5
const WINDOW_RANGE := 7.0             ## so nah am Fenster (und mit freier Sicht darauf) muss man sein
const START_DISTANCE := 7.0           ## so weit draußen taucht er auf
const STOP_OUTSIDE := 1.4             ## 1. Mal: bleibt so weit vor der Scheibe
const STOP_AT_GLASS := 0.32           ## ab dem 2. Mal: Hände an der Scheibe
const FLOAT_SPEED := 1.6
const INSIDE_SPEED := 1.1
const HOVER_TIME := [1.5, 4.5, 1.2]   ## 1. Mal, 2. Mal, ab 3. Mal (dann kommt er herein)
const APPEAR_TIME := 0.8
const FADE_TIME := 0.5
const HYPNOSIS_FROM := 2
const ENTER_FROM := 3
const THROUGH_CURTAIN_FROM := 4
const TRANCE_GAIN := 0.35             ## Hypnose je Sekunde, solange man ihn ansieht
const TRANCE_DECAY := 0.25
const PULL := 0.9                     ## Blickzug (rad/s) bei voller Hypnose
const GRIP_RANGE := 0.7
## Losreißen: Jeder Richtungswechsel füllt den Balken, der Griff zieht ihn ständig zurück. Erst ab etwa
## 6,5 Wechseln je Sekunde über die ganze Zeit reicht es – ab dem 4. Mal greift er noch fester zu.
const ESCAPE_TIME := 3.0
const ESCAPE_GAIN := 0.16             ## je Richtungswechsel
const ESCAPE_GRIP := 0.72             ## so viel zieht der Griff je Sekunde zurück
const ESCAPE_GRIP_STAGE := 0.06       ## ab dem 4. Mal je Mal fester (höchstens +0,3)
## Gäste reißen sich nur selten los: so viel + Mut × so viel
const GUEST_ESCAPE := Vector2(0.3, 0.2)   ## 2026-10-21: im Mittel etwa 4 von 10 (Spielkonzept 6.17), vorher 0,05 + 0,2 × Mut
## Schrank: so lange wartet er vor den Türen, dann fliegt er mit dieser Chance hinein (sonst gibt er auf)
const LURK_TIME := Vector2(20.0, 35.0)
const FLY_IN_CHANCE := 0.4
const FLY_IN_CHANCE_LATE := 0.75      ## ab dem 6. Mal
const FLY_IN_WEAK := 0.3              ## bei voller Schwäche so viel mehr
const BREATH_SAVES := 0.5             ## Luft anhalten senkt die Chance um bis zu diesen Anteil …
const BREATH_FULL := 12.0             ## … bei so vielen Sekunden angehaltener Luft während des Wartens
const PANT_CHANCE := 0.25             ## hat er dich beim Warten keuchen hören: so viel mehr Chance (Ausdauer, 3.1)
const FLY_IN_SPEED := 2.4
const RATTLE_EVERY := Vector2(3.0, 7.0)
const WITNESSES := 1                  ## so viele wache Gäste mit Blick auf ihn vertreiben ihn
const WITNESS_RANGE := 12.0
const LEAVE_RANGE := 14.0             ## so weit weg vom Fenster (bzw. von ihm) gibt er auf
## Flur: ab diesem Mal, Chance je Sekunde im dunklen Flur, wenn alle schlafen; Abstand beim Auftauchen
const HALL_FROM := 6
const HALL_CHANCE := 0.04
const HALL_DISTANCE := Vector2(8.0, 16.0)
const HALL_GIVE_UP := LEAVE_RANGE + 6.0   ## im Flur gibt er auf, wenn man so weit von ihm weg ist
## Debug (F6, --ghost=flur): höchstens so weit vor dem Spieler taucht er auf – knapp unter HALL_GIVE_UP
const DEBUG_HALL_DISTANCE := HALL_GIVE_UP - 1.0
## Schwäche des Opfers (0..1, Spielkonzept 4.18 – Player.weakness(), Guest.weakness()): bis zu so viel mehr
## Chance, Pause und Flur-Chance bis zu (1 + WEAK_FASTER)-mal kürzer bzw. häufiger; ab WEAK_HALL auch vor dem
## 6. Mal im Flur, ab WEAK_SURE sicher im Flur, sobald man dort allein ist (auch ohne Nachtruhe). Eine Nacht
## ohne Schlaf ist ein Drittel Schwäche – zwei Nächte reichen für den Flur, drei für sicher.
const WEAK_CHANCE := 0.3
const WEAK_FASTER := 3.0
const WEAK_HALL := 0.66
const WEAK_SURE := 1.0
## Modell: Handgelenke so hoch über dem Ursprung, Hände so weit vor der Mitte
const HANDS_Y := 1.12
const HANDS_AHEAD := 0.45
const NECK_BELOW_EYES := 0.22
const FINGERS := ["thumb", "index", "middle", "ring", "pinky"]
## Klang: Lautstärke bei voller Sichtbarkeit, in dieser Nähe ungedämpft, ab dieser Entfernung stumm
const AMBIENCE_DB := 0.0
const AMBIENCE_UNIT := 4.0
const AMBIENCE_RANGE := 30.0
## Flocken vom Saum: so viele gleichzeitig, Lebenszeit (s), Kantenlänge (m), Eigenleuchten
const FLAKES := 36
const FLAKE_LIFE := 3.0
const FLAKE_SIZE := 0.045
const FLAKE_GLOW := 0.7
const FLAKE_FROM := 0.2               ## Anteil der Modellhöhe über dem Saum, wo sie entstehen
## Vor der Tür (Lakengespenster als Deko, Spielkonzept 5.6)
const DOOR_CHANCE := 0.006           ## je Prüfung (CHECK_EVERY) und Lakengespenst an der Tür, × (1 + Schwäche)
const DOOR_TIME := Vector2(90.0, 150.0)
const DOOR_DECO_RANGE := 1.8         ## so nah an der Türmitte (waagerecht) müssen die Lakengespenster hängen
const DOOR_STAND := 0.75             ## so weit vor der Tür (Flurseite) steht er
const DOOR_PULL := 0.05              ## Blickzug durch die Wand (rad/s), bei voller Schwäche doppelt so stark
const DOOR_PULL_RANGE := 7.0
const DOOR_GRAB_RANGE := 1.6         ## kommt das Opfer im Flur so nah, packt er zu
const DOOR_WITNESS_RANGE := 6.0      ## vor der Tür vertreiben ihn Gäste erst aus dieser Nähe (sonst bliebe er im Flur nie)
## Garantien (Spielkonzept 4.18, 2026-10-22): War er bis GUARANTEE_DAY noch nie beim Spieler, kommt er ab dann sicher in
## den Flur, sobald der Spieler dort allein ist – als Warnung: er schwebt heran und verschwindet WARN_RANGE vor ihm.
## Ab CATCH_UP_DAY holt er auf, solange er noch keine CATCH_UP_VISITS Mal beim Spieler war (hat er am CATCH_UP_DAY
## damit angefangen, den ganzen Tag): Jeder dunkle Raum mit Fenster ruft ihn sicher, Pause nur CATCH_UP_COOLDOWN –
## er kommt mehrmals hintereinander, und jedes Mal zählt für seine Stufe.
const GUARANTEE_DAY := 10
const WARN_RANGE := 3.0
const CATCH_UP_DAY := 20
const CATCH_UP_VISITS := 3
const CATCH_UP_COOLDOWN := 8.0
## Geisterstunde: beginnt, wenn die Glocke ausgeschlagen hat, endet um HOUR_END Uhr; so viele Begegnungen nur Warnung
const HOUR_START := Weather.BELL_STRIKES * Weather.BELL_GAP / Calendar.HOUR
const HOUR_END := 1.0
const HOUR_WARNINGS := 3
const PATROL_SPEED := 0.8
const PATROL_FADE := 0.12             ## so deutlich ist er, solange er niemanden bemerkt hat (Raster, kaum zu sehen) …
const PATROL_SOUND := 0.45            ## … sein Klang so laut, die Flocken so deutlich (Anteil von ganz da)
const PATROL_FLAKES := 0.7
const PATROL_SIGHT := 7.0             ## Grundsichtweite nach Senses.can_see (Monster: 8 m) und Blickkegel
const PATROL_FOV := 0.3
const PATROL_LEG := Vector2(8.0, 30.0)   ## so weit liegt das nächste Ziel im Flur
const PATROL_AWAY := 15.0             ## so weit vom Spieler taucht er auf (wo der nicht hinsieht)
const HOUR_PAUSE := 8.0               ## nach einer Begegnung so lange, bis er wieder umgeht
const DEBUG_CALM := 120.0             ## Debug (--ghost=stunde): so lange ruht das Monster mindestens
## Dusche (4.24): so lange steht er im Nebel und kreist mit den Händen, dann kommt er so schnell durch die Glastür
const SHOWER_HOVER := 1.6
const SHOWER_SPEED := 1.8
const NEVER_SEEN := -1.0e9

var visits := 0          ## so oft ist er schon beim Spieler erschienen (Stufe)
var hour_meetings := 0   ## so oft hat er den Spieler in der Geisterstunde bemerkt (gespeichert)
var state := State.IDLE
var debug_ignore_player := false   ## Debug (--shock=id,ghost): Spieler zählt bei Gästen nicht als Zeuge
var catch_up_day := false   ## am CATCH_UP_DAY hat er aufgeholt – der ganze Tag zählt (gespeichert)
## Spielzeit (MonsterDirector.elapsed) seiner ersten Begegnung mit dem Spieler – Fenster, Flur, Warnung, Geisterstunde;
## NEVER_SEEN = noch nie (gespeichert; danach richtet sich die Dusche, 4.24 – Debug setzt auch Zeiten vor dem Spielbeginn)
var first_seen := NEVER_SEEN

var _victim: Node3D      ## Player oder Guest, zu dem er gerade kommt
var _warn_only := false  ## garantierter erster Auftritt im Flur: nur heranschweben, dann weg
var _stage := 0          ## das wievielte Mal bei diesem Opfer
var _victim_saw := false ## Gast hat ihn schon gesehen (Schreck)
var _escape_at := -1.0   ## Gast: reißt sich nach so vielen Sekunden los (< 0: schafft es nicht)
var _guest_windows := {} ## Gast-ID → Fenster bzw. Fenstertür, an dem er zuletzt stand (wie _last_window beim Spieler)
var _force_guest: Guest

var _window: Node3D      ## HotelWindow oder Fenstertür (Door), durch die er gerade kommt
var _last_window: Node3D
var _cooldown := 0.0
var _check := 0.0
var _stay := 0.0         ## bis zum nächsten Wurf, solange der Spieler im dunklen Raum bleibt
var _timer := 0.0
var _time := 0.0
var _fade := 0.0
var _target := Vector3.ZERO
var _swings := 0
var _last_sign := 0
var _escape := 0.0       ## Losreißen: Balken 0..1
var _lurk_spot: HideSpot ## Schrank, vor dem er wartet bzw. in den er hineinfliegt
var _rattle := 0.0
var _held_breath := 0.0  ## so lange hat der Spieler beim Warten die Luft angehalten
var _heard_pant := false ## beim Warten hat der Spieler gekeucht
var _material: ShaderMaterial
var _skeleton: Skeleton3D
var _bone := {}
var _rest := {}
var _ambience: AudioStreamPlayer3D
var _flakes: CPUParticles3D
var _flake_mat: ShaderMaterial
var _door_room: Dictionary = {}   ## Zimmer, vor dessen Tür er steht (LevelBuilder.rooms)
var _door_deco: Array[Item] = []  ## die Lakengespenster dort – sie kreisen mit
var _windows: Array[Node] = []    ## Fenstertüren und Fenster, je Prüfung (_check_spawn) einmal gelesen – _window_near läuft für jeden Gast …
var _dark := {}                   ## … ebenso Raum-ID → dunkel?
var _hour_meeting := false        ## der laufende Auftritt ist eine Begegnung in der Geisterstunde
var _hour_pause := 0.0            ## so lange, bis er in der Geisterstunde wieder umgeht (eigene Pause, nicht _cooldown)
var _eyes: Area3D                 ## Beobachter für Senses.can_see (ohne Form, stört keinen Strahl)
var _patrol_points := {}          ## Boden (gerundet) → Flurpunkte dieses Stockwerks (beim ersten Umgehen gesammelt)
var _floor_y := 0.0               ## Boden des Stockwerks, auf dem er umgeht
var _path := PackedVector3Array()
var _path_i := 0
var _patrol_check := 0.0
var _debug_hour_near := false     ## Debug (--ghost=stunde): taucht im Flur des Spielers auf
var _scripted := false            ## der Auftritt in der Dusche (4.24): keine Zeugen, nicht gezählt


## Zeitsprung im Schlaf (SleepSkip, Spielkonzept 3.6): Pausen laufen ab (zu Schlafenden kommt er nicht – das Bett
## ist ein Versteck).
func skip_time(dt: float) -> void:
	_cooldown = maxf(0.0, _cooldown - dt)
	_hour_pause = maxf(0.0, _hour_pause - dt)


func _ready() -> void:
	add_to_group("time_skip")   # Zeitsprung im Schlaf (SleepSkip)
	var visual: Node3D = (load(MODEL) as PackedScene).instantiate()
	add_child(visual)
	_skeleton = visual.find_children("*", "Skeleton3D", true, false)[0]
	for i in _skeleton.get_bone_count():
		_bone[_skeleton.get_bone_name(i)] = i
		_rest[i] = _skeleton.get_bone_rest(i).basis.get_rotation_quaternion()
	var mesh: MeshInstance3D = visual.find_children("*", "MeshInstance3D", true, false)[0]
	_material = ShaderMaterial.new()
	_material.shader = load("res://shaders/psx_ghost.gdshader")
	_material.set_shader_parameter("albedo", Color(0.85, 0.85, 0.9))
	_material.set_shader_parameter("albedo_tex", (mesh.get_active_material(0) as BaseMaterial3D).albedo_texture)
	mesh.material_override = _material
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ambience = AudioStreamPlayer3D.new()
	var stream := load(AMBIENCE) as AudioStreamMP3
	stream.loop = true
	_ambience.stream = stream
	_ambience.unit_size = AMBIENCE_UNIT
	_ambience.max_distance = AMBIENCE_RANGE
	_ambience.position.y = HANDS_Y
	add_child(_ambience)
	_build_flakes(mesh)
	_eyes = Area3D.new()
	_eyes.collision_layer = 0
	_eyes.collision_mask = 0
	_eyes.monitoring = false
	_eyes.monitorable = false
	add_child(_eyes)
	_hide()


## Weiße Flocken rund um den unteren Rand des Lakens, sinken langsam und trudeln.
func _build_flakes(mesh: MeshInstance3D) -> void:
	var box := (global_transform.affine_inverse() * mesh.global_transform) * mesh.get_aabb()
	_flake_mat = Mat.particle(null, FLAKE_GLOW)
	_flake_mat.set_shader_parameter("spin", 1.5)
	_flake_mat.set_shader_parameter("sway", 0.04)
	_flake_mat.set_shader_parameter("sway_cycles", 1.2)
	_flakes = Geo.particles(FLAKES, FLAKE_LIFE, FLAKE_SIZE, _flake_mat, 0.15, 0.4)
	_flakes.color = Color(0.9, 0.9, 0.95)
	# Ring knapp außerhalb des Lakens (Breite ohne die vorgestreckten Arme), etwas über dem Saum –
	# weiter innen verdeckte sie das Laken, weiter unten am Fenster die Brüstung
	_flakes.position = Vector3(box.get_center().x, box.position.y + box.size.y * FLAKE_FROM, box.get_center().z)
	_flakes.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
	_flakes.emission_ring_axis = Vector3.UP
	_flakes.emission_ring_radius = box.size.x * 0.45
	_flakes.emission_ring_inner_radius = box.size.x * 0.32
	_flakes.emission_ring_height = box.size.y * 0.15
	_flakes.direction = Vector3.DOWN
	_flakes.spread = 40.0
	_flakes.initial_velocity_min = 0.03
	_flakes.initial_velocity_max = 0.12
	_flakes.gravity = Vector3(0, -0.08, 0)
	_flakes.damping_min = 0.05
	_flakes.damping_max = 0.1
	_flakes.scale_amount_min = 0.6
	_flakes.scale_amount_max = 1.3
	add_child(_flakes)


func is_active() -> bool:
	return state != State.IDLE


## Ist er gerade beim Spieler (Erscheinen, Hypnose, Würgen, Lauern vor dem Schrank, vor der Tür)? Dann ist das
## Tagebuch gesperrt und der Autosave wartet (Spielkonzept 8.5, 8.6).
func with_player() -> bool:
	return is_active() and _victim != null and _victim == Game.player


func _physics_process(delta: float) -> void:
	var player := Game.player
	if player == null:
		return
	_time += delta
	_cooldown = maxf(0.0, _cooldown - delta)
	_hour_pause = maxf(0.0, _hour_pause - delta)
	if state == State.IDLE:
		player.trance = maxf(0.0, player.trance - TRANCE_DECAY * delta)
		_check -= delta
		if _check <= 0.0:
			_check = CHECK_EVERY
			_check_spawn()
		return
	if Game.game_over:
		if state != State.FADE:   # das Monster war schneller – ihn selbst hört man nicht mehr
			_ambience.stop()
		return
	if state not in [State.FADE, State.PATROL] and not _scripted:   # beim Umgehen sieht ihn kaum einer; in der Dusche zählt kein Zeuge
		var seen_by := _witness_guests(global_position + Vector3.UP * HANDS_Y, _victim, DOOR_WITNESS_RANGE if state == State.DOOR else WITNESS_RANGE)
		if seen_by.size() + _player_witness(global_position + Vector3.UP * HANDS_Y) >= WITNESSES:
			for guest in seen_by:
				guest.shock("ghost", global_position)
			if Game.tracing:
				var names := seen_by.map(func(g: Guest) -> String: return g.display_name)
				print("[Lakengeist] vertrieben von %s%s" % [", ".join(names) if not names.is_empty() else "dir",
					" (vor der Tür, %.0f s vor Schluss)" % _timer if state == State.DOOR else ""])
			_vanish()
		elif _lost_victim():
			_vanish()
	if _victim is Guest and not _victim_saw and state in [State.APPROACH, State.HOVER, State.ENTER] and _fade > 0.5:
		_guest_sees_me(_victim as Guest)
	match state:
		State.APPROACH:
			if _float_to(_target, FLOAT_SPEED, delta):
				if _stage >= HYPNOSIS_FROM and _window:
					_touch_glass()
				state = State.HOVER
				_timer = HOVER_TIME[mini(_stage, 3) - 1]
		State.HOVER:
			_timer -= delta
			if _timer <= 0.0:
				if _stage < ENTER_FROM:
					_vanish()
				elif not _salt_repels():
					_open_french_door()
					state = State.ENTER
		State.ENTER:
			if _salt_repels():   # durchs Fenster hinter dem Vorhang, vor der geöffneten Tür (5.13)
				return
			var neck := _eye_of(_victim) - Vector3(0, NECK_BELOW_EYES, 0)
			var flat := Vector3(neck.x - global_position.x, 0, neck.z - global_position.z)
			if _warn_only and flat.length() < WARN_RANGE:
				if Game.tracing:
					print("[Lakengeist] Warnung im Flur – verschwunden")
				_vanish()
				return
			if _float_to(_grip_spot(), SHOWER_SPEED if _scripted else INSIDE_SPEED, delta) or flat.length() < HANDS_AHEAD + GRIP_RANGE:
				_grab()
			elif _victim.global_position.distance_to(_window_center(_window) if _window else global_position) > (LEAVE_RANGE if _window else HALL_GIVE_UP):
				_vanish()
		State.STRANGLE:
			_struggle(delta)
		State.LURK:
			_lurk(delta)
		State.FLY_IN:
			if _float_to(_grip_spot(), FLY_IN_SPEED, delta):
				_grab()
		State.DOOR:
			if ghost_hour():   # die Glocke hat ausgeschlagen – er geht um
				_vanish()
			else:
				_door_watch(delta)
		State.PATROL:
			_patrol(delta)
		State.FADE:
			_fade = maxf(0.0, _fade - delta / FADE_TIME)
			if _fade <= 0.0:
				_hide()
				return
	if state in [State.APPROACH, State.HOVER, State.ENTER, State.LURK, State.FLY_IN, State.DOOR] and _fade < 1.0:
		_fade = minf(1.0, _fade + delta / APPEAR_TIME)
	elif state == State.PATROL:
		_fade = move_toward(_fade, PATROL_FADE, delta / APPEAR_TIME)
	_material.set_shader_parameter("fade", _fade)
	_flake_mat.set_shader_parameter("fade", _fade / PATROL_FADE * PATROL_FLAKES if state == State.PATROL else _fade)
	_flakes.emitting = state != State.FADE
	_update_ambience()
	_update_trance(delta)
	_pose()


# --- Erscheinen ---------------------------------------------------------------------------

## Betritt der Spieler einen dunklen Raum mit Außenfenster (Vorhang offen – ab dem 4. Mal egal) oder Fenstertür,
## würfelt es (SPAWN_CHANCE bzw. FRENCH_DOOR_CHANCE); bleibt er darin, alle STAY_EVERY Sekunden erneut
## (STAY_CHANCE bzw. FRENCH_DOOR_STAY).
## Ab Tag FROM_DAY oder nach dem ersten Angriff des Monsters (der Anfang bleibt friedlich, 2.1).
func _check_spawn() -> void:
	var player := Game.player
	var director := Game.director
	if director == null or Game.game_over or director.other_threat_active(self):
		return   # nur eine Bedrohung im Haus
	_refresh_windows()
	var hour := ghost_hour()
	if not hour and _haunting() and _cooldown <= 0.0 and director.player_threat <= 0.0 and _check_doors():
		return
	if _player_free(player) and _haunting():
		if _check_guarantee_hall(player) or _check_hall(player) or _check_player_window(player):
			return
	if hour:   # Geisterstunde: er geht um – zu Türen und Gästen an Fenstern kommt er solange nicht
		if _hour_pause <= 0.0 and director.player_threat <= 0.0:
			_start_patrol()
		return
	if _haunting() or _force_guest != null:
		_check_guests()


## Fenster und Fenstertüren neu lesen, Dunkelheit der Räume vergessen (je Prüfung einmal).
func _refresh_windows() -> void:
	_windows = get_tree().get_nodes_in_group("french_doors")   # zuerst: Dort kommt er am liebsten
	_windows.append_array(get_tree().get_nodes_in_group("windows"))
	_dark.clear()


## Kann er zum Spieler kommen? Nicht zu Toten, Versteckten, im Gespräch und im Katzenraum (Spielkonzept 7.7) – und nicht
## in Zimmer 13, solange dort die Dusche läuft: Der Moment im Bad wartet auf ihn (4.24).
func _player_free(player: Player) -> bool:
	if Game.shower_scare and Game.shower_scare.reserves(player):
		return false
	return not (player.dead or player.hiding != null or player.in_dialog or Game.social.builder.is_safe(player.global_position))


## Dunkles Fenster in der Nähe des Spielers: beim Betreten würfeln, beim Bleiben alle STAY_EVERY Sekunden.
func _check_player_window(player: Player) -> bool:
	var eye := player.camera.global_position
	var window := _window_near(eye, visits + 1)
	var chance := 0.0
	if window != _last_window:
		_last_window = window
		_stay = STAY_EVERY
		chance = _spawn_chance(player, window)
	elif window != null:
		_stay -= CHECK_EVERY
		if _stay <= 0.0:
			_stay = STAY_EVERY
			chance = 1.0 if catching_up() else minf(1.0, (FRENCH_DOOR_STAY if window is Door else STAY_CHANCE) + WEAK_CHANCE * player.weakness())
	# in Gesellschaft kommt er nicht
	if window != null and _cooldown <= 0.0 and Game.director.player_threat <= 0.0 \
			and _witness_guests(eye, player).size() < WITNESSES and randf() < chance:
		_appear(window, player)
		return true
	return false


## Spukt er schon? Ab Tag FROM_DAY oder nach dem ersten Angriff, je nachdem, was früher kommt.
func _haunting() -> bool:
	return Game.director.first_attack_done or Calendar.today() >= FROM_DAY


## Gäste behandelt er wie den Spieler (Spielkonzept 6.12): Steht ein wacher Gast in einem dunklen Raum mit
## offenem Vorhang (meist: er ruht im eigenen Zimmer), würfelt es einmal – gleiche Chance, gleiche Stufen.
func _check_guests() -> void:
	if Game.social == null:
		return
	for guest in Game.social.guests:
		var g: Guest = guest
		if _force_guest != null and g != _force_guest:
			continue   # Debug: nur zu diesem Gast
		if g.dead or g.hiding != null or g.state in [Guest.State.TALKING, Guest.State.MINIGAME, Guest.State.SLEEP, Guest.State.KNOCK, Guest.State.SHELTER] \
				or Game.social.builder.is_safe(g.global_position):
			_guest_windows.erase(g.id)
			continue
		var eye := _eye_of(g)
		var window := _window_near(eye, g.ghost_visits + 1)
		if window == _guest_windows.get(g.id):
			continue
		_guest_windows[g.id] = window
		if window == null:
			continue
		var forced := _force_guest == g
		if not forced and (_cooldown > 0.0 or Game.director.player_threat > 0.0 \
				or _witness_guests(eye, g).size() + _player_witness(eye) >= WITNESSES or randf() >= _spawn_chance(g, window)):
			continue
		_force_guest = null
		_appear(window, g)
		return


## Ab dem 6. Mal: Schlafen alle Gäste und steht der Spieler im Flur, taucht er dort mit kleiner Chance
## je Sekunde auf – irgendwo vor oder hinter ihm, wo er gerade nicht hinsieht. Schwäche: je schwächer,
## desto öfter, ab WEAK_HALL auch vor dem 6. Mal, ab WEAK_SURE sicher, sobald man allein im Flur ist.
func _check_hall(player: Player) -> bool:
	if not _hall_rule(player):
		return false
	var spot := _hall_spot(player)
	if spot == Vector3.INF:
		return false
	_appear_in_hall(spot)
	return true


## Greift gerade eine Flur-Regel für den Spieler (ab dem 6. Mal bei Nachtruhe, Schwäche)? Würfelt dabei.
func _hall_rule(player: Player) -> bool:
	var weak := player.weakness()
	if Game.social == null or not _in_hall(player.global_position):
		return false
	if weak >= WEAK_SURE:
		return not (_cooldown > 0.0 or Game.director.player_threat > 0.0 \
				or _witness_guests(player.camera.global_position, player).size() >= WITNESSES)
	if (visits + 1 < HALL_FROM and weak < WEAK_HALL) or not Game.social.all_asleep():
		return false
	return not (_cooldown > 0.0 or Game.director.player_threat > 0.0 \
			or randf() >= HALL_CHANCE * (1.0 + WEAK_FASTER * weak) * CHECK_EVERY)


## Wo er im Flur auftaucht: ein Wegpunkt HALL_DISTANCE vom Spieler auf seiner Höhe, im Flur, wo der Spieler gerade
## nicht hinsieht und kein wacher Gast ihn sähe (ganz Schwache auch ohne Nachtruhe). INF = keiner.
func _hall_spot(player: Player) -> Vector3:
	var spots: Array[Vector3] = []
	for entry in Game.director.patrol:
		var p: Vector3 = entry["pos"]
		var d := p.distance_to(player.global_position)
		if absf(p.y - player.global_position.y) < 1.5 and d >= HALL_DISTANCE.x and d <= HALL_DISTANCE.y \
				and _in_hall(p) and not Game.director.player_can_see(p + Vector3.UP * 1.2) \
				and _witness_guests(p + Vector3.UP * HANDS_Y, player).size() < WITNESSES:
			spots.append(p)
	return Vector3.INF if spots.is_empty() else spots[randi() % spots.size()]


## Garantie (GUARANTEE_DAY): War er noch nie beim Spieler, kommt er sicher, sobald der allein im Flur ist – als Warnung.
func _check_guarantee_hall(player: Player) -> bool:
	if not _guarantee_rule(player):
		return false
	var spot := _hall_spot(player)
	if spot == Vector3.INF:
		return false
	_appear_in_hall(spot)
	_warn_only = true
	if Game.tracing:
		print("[Lakengeist] Garantie an Tag %d: Warnung im Flur" % Calendar.today())
	return true


func _guarantee_rule(player: Player) -> bool:
	return not (visits > 0 or Calendar.today() < GUARANTEE_DAY or Game.social == null or not _in_hall(player.global_position) \
			or _cooldown > 0.0 or Game.director.player_threat > 0.0 \
			or _witness_guests(player.camera.global_position, player).size() >= WITNESSES)


## Holt er gerade auf (CATCH_UP_DAY)? Solange er noch keine CATCH_UP_VISITS Mal beim Spieler war – und hat er am
## CATCH_UP_DAY damit angefangen, den ganzen Tag.
func catching_up() -> bool:
	var day := Calendar.today()
	if day < CATCH_UP_DAY:
		return false
	if visits < CATCH_UP_VISITS:
		if day == CATCH_UP_DAY:
			catch_up_day = true
		return true
	return catch_up_day and day == CATCH_UP_DAY


## Lakengespenster an einer geschlossenen Zimmertür, jemand Waches drinnen: Mit DOOR_CHANCE je Gespenst
## (mehr bei Schwachen) stellt er sich davor – nur wo ihn gerade niemand sieht.
func _check_doors() -> bool:
	if Game.social == null:
		return false
	var builder := Game.social.builder
	var by_room := {}
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.kind != Item.Kind.SHEET_GHOST or not item.hung:
			continue
		for room: Dictionary in builder.rooms.values():
			var door: Door = room.get("door")
			if door == null:
				continue
			var c := door.center()
			if Vector2(item.global_position.x - c.x, item.global_position.z - c.z).length() < DOOR_DECO_RANGE \
					and absf(item.global_position.y - c.y) < 2.0:
				by_room.get_or_add(room["no"], []).append(item)
				break
	for no: String in by_room:
		var room: Dictionary = builder.rooms[no]
		var door: Door = room["door"]
		var victim := _door_victim(room)
		if door.is_open or victim == null:
			continue
		if randf() >= DOOR_CHANCE * (by_room[no] as Array).size() * (1.0 + _weakness(victim)):
			continue
		var salt := SaltLine.guarding(no)
		if salt:   # Salz an der Tür oder am Fenster (5.13): er kommt nicht
			salt.repel()
			continue
		var stand := _door_stand(room)
		if _witness_guests(stand + Vector3.UP * HANDS_Y, victim).size() >= WITNESSES \
				or Game.director.player_can_see(stand + Vector3.UP * 1.2):
			continue
		var deco: Array[Item] = []
		deco.assign(by_room[no])
		_appear_at_door(room, victim, deco)
		return true
	return false


## Wer im Zimmer ist und wach: der Spieler, sonst ein Gast, der dort wohnt (oder null).
func _door_victim(room: Dictionary) -> Node3D:
	var builder := Game.social.builder
	var no := String(room["no"])
	var player := Game.player
	if not (player.dead or player.hiding != null or player.in_dialog) and builder.room_at(player.global_position) == no:
		return player
	for guest in Game.social.guests:
		var g: Guest = guest
		if g.home["no"] != no or g.dead or g.hiding != null or builder.room_at(g.global_position) != no \
				or g.state in [Guest.State.TALKING, Guest.State.MINIGAME, Guest.State.SLEEP, Guest.State.KNOCK, Guest.State.SHELTER, Guest.State.GHOSTED]:
			continue
		return g
	return null


## Wo er vor der Tür schwebt: im Flur, DOOR_STAND vor der Wand, Hände auf Halshöhe eines Erwachsenen.
func _door_stand(room: Dictionary) -> Vector3:
	var front: Vector3 = room["door_front"]   # 0,9 m vor der Wandmitte
	var into: Vector3 = room["into"]
	var stand := front + into * (0.9 - DOOR_STAND)
	return Vector3(stand.x, front.y + Player.EYE_HEIGHT - NECK_BELOW_EYES - HANDS_Y, stand.z)


func _appear_at_door(room: Dictionary, victim: Node3D, deco: Array[Item]) -> void:
	_start_visit(victim, null)
	_victim_saw = true   # sieht ihn erst, wenn die Tür aufgeht
	_last_window = null
	_door_room = room
	_door_deco = deco
	for item in deco:
		item.circling_with = self
	global_position = _door_stand(room)
	_face(room["into"])
	_timer = randf_range(DOOR_TIME.x, DOOR_TIME.y)
	state = State.DOOR
	var door: Door = room["door"]
	if victim is Guest:
		(victim as Guest).door_trance(door.center())
	if Game.tracing:
		print("[Lakengeist] %d. Mal – vor der Tür von %s (%d Lakengespenster), bei %s" % [_stage, room["no"], deco.size(),
			(victim as Guest).display_name if victim is Guest else "dir (Schwäche %.2f)" % Game.player.weakness()])


## Vor der Tür: lautlos, bis die Zeit um ist. Geht die Tür auf – oder kommt das Opfer im Flur zu nah –,
## packt er zu (wie beim Hereinkommen; Zeugen vertreiben ihn wie sonst auch).
func _door_watch(delta: float) -> void:
	var door: Door = _door_room["door"]
	var near := Vector2(_victim.global_position.x - global_position.x, _victim.global_position.z - global_position.z).length() < DOOR_GRAB_RANGE
	if door.is_open or near:
		_end_door()
		_stage = maxi(_stage, ENTER_FROM)
		state = State.ENTER
		if Game.tracing:
			print("[Lakengeist] Tür auf – er packt zu")
		return
	_timer -= delta
	if _timer <= 0.0:
		if Game.tracing:
			print("[Lakengeist] vor der Tür verschwunden")
		_vanish()


## Hände kreisen im Takt (für die Lakengespenster vor der Tür, Item.circling_with).
func hand_phase() -> float:
	return _time * 2.2


func _end_door() -> void:
	for item in _door_deco:
		if is_instance_valid(item):
			item.circling_with = null
	_door_deco.clear()
	_door_room = {}


## Flur eines Stockwerks (nicht die Lobby) – nach dem Grundriss, nicht nach dem Zonennamen.
func _in_hall(p: Vector3) -> bool:
	return Game.social.builder.in_corridor(p)


func _appear_in_hall(floor_point: Vector3) -> void:
	_start_visit(Game.player, null)
	_last_window = null
	var neck := Game.player.camera.global_position.y - NECK_BELOW_EYES
	global_position = Vector3(floor_point.x, neck - HANDS_Y, floor_point.z)
	_face(Game.player.global_position - global_position)
	state = State.ENTER
	Game.caption("[Kälte im Flur]")
	if Game.tracing:
		var weak := Game.player.weakness()
		print("[Lakengeist] %d. Mal – im Flur, %.0f m entfernt (Schwäche %.2f%s)" % [visits,
			floor_point.distance_to(Game.player.global_position), weak, ", sicher" if weak >= WEAK_SURE else ""])


## Dunkle Fenstertür oder dunkles Außenfenster in der Nähe dieses Augenpunkts, durch das er zum `stage`. Mal
## käme (nur aus _check_spawn).
func _window_near(eye: Vector3, stage: int) -> Node3D:
	var world := get_world_3d()
	for window: Node3D in _windows:
		var room_id := ""
		var inside := Vector3.ZERO
		if window is Door:
			var door := window as Door
			if door.locked:
				continue
			room_id = door.room_id
			inside = door.center() - door.outward * 0.4
		else:
			var win := window as HotelWindow
			if not win.has_curtains() or (win.closed and stage < THROUGH_CURTAIN_FROM):
				continue
			room_id = win.room_id
			inside = win.inside_point()
		if inside.distance_to(eye) > WINDOW_RANGE or absf(inside.y - eye.y) > 2.0 or not _room_dark(room_id):
			continue
		if Senses.clear_line(world, inside, eye, null, Senses.SIGHT_MASK & ~HotelWindow.LAYER_BLOCK):
			return window
	return null


func _room_dark(room_id: String) -> bool:
	if not _dark.has(room_id):
		_dark[room_id] = true
		for node in get_tree().get_nodes_in_group("lamp_fixtures"):
			var lamp := node as Lamp
			if lamp.room_id == room_id and lamp.is_lit():
				_dark[room_id] = false
				break
	return _dark[room_id]


func _appear(window: Node3D, victim: Node3D) -> void:
	_start_visit(victim, window)
	var outward := window.global_transform.basis.z.normalized() * -1.0
	var base := window.global_position - Vector3(0, HANDS_Y, 0)
	var door := window as Door
	if door:   # Fenstertür: über dem Boden davor, Hände auf Halshöhe eines Erwachsenen
		outward = door.outward
		var c := door.center()
		base = Vector3(c.x, door.global_position.y + Player.EYE_HEIGHT - NECK_BELOW_EYES - HANDS_Y, c.z)
	_swings = 0
	_last_sign = 0
	_face(-outward)
	if door == null and (window as HotelWindow).closed:   # ab dem 4. Mal: hinter dem Vorhang, gleich herein
		global_position = base + outward * STOP_AT_GLASS
		state = State.ENTER
	else:
		global_position = base + outward * START_DISTANCE
		_target = base + outward * (STOP_OUTSIDE if _stage < HYPNOSIS_FROM else STOP_AT_GLASS)
		state = State.APPROACH
	if victim is Player:
		Game.caption("[Etwas schwebt vor der Fenstertür]" if door else "[Etwas schwebt vor dem Fenster]")
	if Game.tracing:
		print("[Lakengeist] %d. Mal %s (%s) – bei %s" % [_stage, "an der Fenstertür" if door else "am Fenster",
			door.room_id if door else (window as HotelWindow).room_id, (victim as Guest).display_name if victim is Guest \
			else "dir (Schwäche %.2f)" % Game.player.weakness()])


## Beginn eines Auftritts (Fenster, Flur, Tür): Besuch beim Opfer zählen – Stufe = das wievielte Mal bei ihm –,
## sichtbar machen, eingeblendet wird er danach in _physics_process.
func _start_visit(victim: Node3D, window: Node3D) -> void:
	_victim = victim
	_warn_only = false
	_hour_meeting = false
	_victim_saw = false
	if victim is Guest:
		var guest := victim as Guest
		guest.ghost_visits += 1
		_stage = guest.ghost_visits
	else:
		visits += 1
		_stage = visits
		if not met() and Game.director:
			first_seen = Game.director.elapsed
	_window = window
	_lurk_spot = null
	visible = true
	_fade = 0.0


## Ab dem 2. Mal: blutige Handabdrücke außen auf der Scheibe (an einer offenen Fenstertür keine).
func _touch_glass() -> void:
	var door := _window as Door
	if door and door.is_open:
		return
	Game.play_sound("thud", 0.4)
	if Game.traces == null:
		return
	if door:
		Game.traces.add_french_door_handprints(door)
	else:
		Game.traces.add_window_handprints(_window as HotelWindow)


## Ab dem 3. Mal kommt er herein – eine geschlossene Fenstertür schwingt dabei lautlos auf.
func _open_french_door() -> void:
	var door := _window as Door
	if door == null or door.is_open or door.locked:
		return
	door.set_open(true, false, true, self)
	if Game.tracing:
		print("[Lakengeist] öffnet die Fenstertür (%s)" % door.room_id)
	if _victim is Player:
		Game.caption("[Die Fenstertür schwingt auf]")


## Salz (Spielkonzept 5.13): Ist das Opfer in einem Zimmer, das eine heile Salzlinie schützt, und er selbst draußen,
## kommt er nicht hinein – die Linie zählt die Abweisung, er verschwindet. In der Dusche (4.24) hilft kein Salz.
func _salt_repels() -> bool:
	if _scripted or _victim == null or Game.social == null:
		return false
	var builder := Game.social.builder
	var room := builder.home_room_at(_victim.global_position)
	if room == "" or builder.home_room_at(global_position) == room:
		return false
	var line := SaltLine.guarding(room)
	if line == null:
		return false
	line.repel()
	if _victim is Player:
		Game.caption("[Er kommt nicht über das Salz]")
	if Game.tracing:
		print("[Lakengeist] %d. Mal – das Salz hält ihn aus %s fern (bei %s)" % [_stage, room,
			(_victim as Guest).display_name if _victim is Guest else "dir"])
	_vanish()
	return true


## Mitte des Fensters bzw. der Fenstertür (für den Abstand, ab dem er aufgibt).
func _window_center(window: Node3D) -> Vector3:
	return (window as Door).center() if window is Door else window.global_position


# --- Geisterstunde ---------------------------------------------------------------------------

## Läuft die Geisterstunde? Nach der Mitternachtsglocke bis HOUR_END Uhr – erst nach dem ersten Angriff (4.20).
func ghost_hour() -> bool:
	if Game.director == null or not Game.director.first_attack_done:
		return false
	var hour := Calendar.hour_of(Game.director.elapsed)
	return hour >= HOUR_START and hour < HOUR_END


## Er taucht im Flur des Obergeschosses auf, weit weg vom Spieler und wo der nicht hinsieht, und geht um.
func _start_patrol() -> bool:
	var player := Game.player
	var near := _debug_hour_near and _in_hall(player.global_position)
	var points := _corridor_points(player.global_position.y if near else _hour_floor())
	var options: Array[Vector3] = []
	for p in points:
		var d := p.distance_to(player.global_position)
		if near:
			if d >= HALL_DISTANCE.x and d <= HALL_DISTANCE.y:
				options.append(p)
		elif d >= PATROL_AWAY and not Game.director.player_can_see(p + Vector3.UP * 1.2):
			options.append(p)
	if options.is_empty():
		return false
	var at: Vector3 = options.pick_random()
	_victim = null
	_window = null
	_lurk_spot = null
	_warn_only = false
	_hour_meeting = false
	visible = true
	_fade = 0.0
	_floor_y = at.y
	global_position = _hover(at)
	_path = PackedVector3Array()
	_path_i = 0
	_patrol_check = CHECK_EVERY
	state = State.PATROL
	_debug_hour_near = false
	if near:   # Debug: er kommt auf dich zu, du siehst hin
		_face(player.global_position - global_position)
		_path = PackedVector3Array([player.global_position])
		_debug_look_at(at + Vector3.UP * 1.4)
	if Game.tracing:
		print("[Lakengeist] Geisterstunde: geht um, %.0f m von dir" % at.distance_to(player.global_position))
	return true


## Boden des Stockwerks, auf dem er umgeht: Obergeschoss (dort ist er zu Hause, 4.20), ohne Flure dort das Erdgeschoss.
func _hour_floor() -> float:
	return LevelBuilder.UP_Y if not _corridor_points(LevelBuilder.UP_Y).is_empty() else 0.0


## Flurpunkte (Wegpunkte im Flur, nicht Lobby oder Galerie) auf dem Stockwerk mit diesem Boden – je Stockwerk einmal
## gesammelt.
func _corridor_points(floor_y: float) -> Array[Vector3]:
	var key := roundi(floor_y)
	if not _patrol_points.has(key):
		var builder := Game.social.builder
		var list: Array[Vector3] = []
		for p in builder.wander_points:
			if absf(p.y - floor_y) < 1.0 and builder.in_corridor(p):
				list.append(p)
		_patrol_points[key] = list
	return _patrol_points[key]


## Höhe, in der er über diesem Bodenpunkt schwebt: Hände auf Halshöhe eines Erwachsenen.
func _hover(floor_point: Vector3) -> Vector3:
	return Vector3(floor_point.x, _floor_y + Player.EYE_HEIGHT - NECK_BELOW_EYES - HANDS_Y, floor_point.z)


## Umgehen: von Flurpunkt zu Flurpunkt über das NavMesh; zweimal je Sekunde sieht er sich um.
func _patrol(delta: float) -> void:
	if not ghost_hour():
		if Game.tracing:
			print("[Lakengeist] Geisterstunde vorbei")
		_vanish()
		return
	if _path_i >= _path.size():
		_next_leg()
	else:
		var to := _hover(_path[_path_i])
		_face(to - global_position)
		if _float_to(to, PATROL_SPEED, delta):
			_path_i += 1
	_patrol_check -= delta
	if _patrol_check <= 0.0:
		_patrol_check = CHECK_EVERY
		_patrol_look()


## Nächstes Ziel: ein Flurpunkt PATROL_LEG entfernt, Weg über das NavMesh (sonst geradeaus).
func _next_leg() -> void:
	var here := Vector3(global_position.x, _floor_y, global_position.z)
	var options: Array[Vector3] = []
	var points := _corridor_points(_floor_y)
	for p in points:
		var d := p.distance_to(here)
		if d >= PATROL_LEG.x and d <= PATROL_LEG.y:
			options.append(p)
	if options.is_empty():
		options = points
	var goal: Vector3 = options.pick_random()
	_path = NavigationServer3D.map_get_path(get_world_3d().navigation_map, here, goal, true)
	if _path.is_empty():
		_path = PackedVector3Array([goal])
	_path_i = 0


## Beim Umgehen: Greift eine Flur-Regel oder ruft ihn ein dunkles Fenster, wird ein gewöhnlicher Besuch daraus.
## Sonst: Sieht er den Spieler im Flur, eine Begegnung der Geisterstunde; einen schwachen Gast, einen Besuch.
func _patrol_look() -> void:
	var player := Game.player
	if _player_free(player):
		_refresh_windows()
		var near := absf(player.global_position.y - _floor_y) < 1.5 and player.global_position.distance_to(global_position) < HALL_GIVE_UP
		var warn := near and _guarantee_rule(player)
		if warn or (near and _hall_rule(player)):
			_turn_to(player, warn)
			return
		if _check_player_window(player):
			return
		if _in_hall(player.global_position) and _sees(player):
			_meet_in_hour(player)
			return
	for guest in Game.social.guests:
		var g: Guest = guest
		if g.dead or g.hiding != null or g.state in [Guest.State.SLEEP, Guest.State.TALKING, Guest.State.MINIGAME] \
				or g.weakness() < WEAK_HALL or not _in_hall(g.global_position) or not _sees(g):
			continue
		_turn_to(g, false)
		return


## Sieht er diesen Akteur (Licht, Ducken und Laufen zählen wie beim Monster, 4.15)?
func _sees(actor) -> bool:
	return Senses.can_see(_eyes, global_position + Vector3.UP * (HANDS_Y + 0.5), -global_transform.basis.z,
		PATROL_SIGHT, PATROL_FOV, actor)


## Er hat den Spieler in der Geisterstunde bemerkt: Die ersten HOUR_WARNINGS Male nur heranschweben und kurz vor
## ihm verschwinden, danach würgt er. Zählt nicht für seine Stufe am Fenster.
func _meet_in_hour(player: Player) -> void:
	hour_meetings += 1
	_victim = player
	_warn_only = hour_meetings <= HOUR_WARNINGS
	_victim_saw = false
	_stage = maxi(visits, 1)
	_hour_meeting = true
	_last_window = null
	state = State.ENTER
	Game.caption("[Kälte im Flur]")
	if Game.tracing:
		print("[Lakengeist] Geisterstunde: %d. Begegnung – %s" % [hour_meetings, "Warnung" if _warn_only else "er würgt"])


## Aus dem Umgehen wird ein gewöhnlicher Besuch bei `victim` (zählt für die Stufe), von dort, wo er gerade ist.
func _turn_to(victim: Node3D, warn: bool) -> void:
	var fade := _fade
	_start_visit(victim, null)
	_fade = fade
	_warn_only = warn
	if victim is Player:
		_last_window = null
		Game.caption("[Kälte im Flur]")
	state = State.ENTER
	if Game.tracing:
		print("[Lakengeist] Geisterstunde: dreht sich zu %s um (%d. Mal%s)" % [(victim as Guest).display_name if victim is Guest \
			else "dir", _stage, ", Warnung" if warn else ""])


# --- Würgen -----------------------------------------------------------------------------

func _grab() -> void:
	if _victim is Guest and (_victim as Guest).is_child():
		_frighten_child(_victim as Guest)
		return
	state = State.STRANGLE
	_timer = ESCAPE_TIME
	_swings = 0
	_last_sign = 0
	_escape = 0.0
	if _victim is Guest:
		# Mutige reißen sich eher los (ein Gast zappelt nicht nach Anleitung)
		var guest := _victim as Guest
		guest.ghost_grab(global_position + Vector3.UP * HANDS_Y)
		_escape_at = ESCAPE_TIME * randf_range(0.3, 0.9) if randf() < GUEST_ESCAPE.x + GUEST_ESCAPE.y * float(guest.profile["brave"]) else -1.0
		if Game.player.global_position.distance_to(guest.global_position) < 12.0:
			Game.play_sound("gasp", 0.6)
		Game.shot_event("strangle", 20)
		return
	Game.player.gripped = true
	Game.play_sound("gasp", 0.8)
	Game.caption("[Kalte Hände um deinen Hals – reiß dich los!]")
	Game.say("Beweg dich! Schnell hin und her!", ESCAPE_TIME)
	if Game.hud:
		Game.hud.set_struggle(0.0)
	Game.shot_event("strangle", 20)


## Losreißen: Jeder Richtungswechsel füllt den Balken um ESCAPE_GAIN, der Griff zieht ihn ständig zurück.
## Voll, bevor die Zeit um ist → los (aus dem Schrank stürzt man dabei heraus).
func _struggle(delta: float) -> void:
	if _victim is Guest:
		_timer -= delta
		if _escape_at >= 0.0 and ESCAPE_TIME - _timer >= _escape_at:
			if Game.tracing:
				print("[Lakengeist] %s hat sich losgerissen" % (_victim as Guest).display_name)
			(_victim as Guest).wound_by("choke")   # Würgemale: heiser, atmet schwer (6.17)
			_vanish()
		elif _timer <= 0.0:
			_kill_guest(_victim as Guest)
		return
	var player := Game.player
	var input: Vector2 = player.move_input
	var axis := input.x if absf(input.x) >= absf(input.y) else input.y
	var dir := 0 if absf(axis) < 0.5 else (1 if axis > 0.0 else -1)
	if dir != 0 and dir != _last_sign:
		if _last_sign != 0:
			_swings += 1
			_escape += ESCAPE_GAIN
		_last_sign = dir
	var grip := ESCAPE_GRIP + minf(0.3, ESCAPE_GRIP_STAGE * maxi(0, _stage - ENTER_FROM))
	_escape = maxf(0.0, _escape - grip * delta)
	if Game.hud:
		Game.hud.set_struggle(_escape)
	var held := ESCAPE_TIME - _timer
	if _escape >= 1.0:
		if Game.tracing:
			print("[Lakengeist] losgerissen nach %.1f s (%d Wechsel, %.1f je s)" % [held, _swings, _swings / maxf(0.1, held)])
		player.add_shock(0.25, false)
		Game.say("Losgerissen!", 1.5)
		if player.hiding:
			player.exit_hide()   # aus dem Schrank gestürzt
		if _scripted and Game.shower_scare:
			Game.shower_scare.on_escaped()
		_vanish()
		return
	_timer -= delta
	if _timer <= 0.0:
		if Game.tracing:
			print("[Lakengeist] Balken bei %.0f %% (%d Wechsel in %.1f s)" % [_escape * 100.0, _swings, ESCAPE_TIME])
		_kill()


func _kill() -> void:
	var player := Game.player
	if Game.tracing:
		print("[Lakengeist] erwürgt")
	state = State.FADE   # bleibt sichtbar, bis der Sterbebildschirm kommt
	_fade = 1.0
	player.gripped = false
	if Game.hud:
		Game.hud.set_struggle(-1.0)
	await Game.director.player_slain("ghost")
	_ambience.stop()   # erst mit dem Sterbebildschirm verstummt er


## Ein Kind würgt er nie (6.13): Er greift nach ihm, es schreit – und er ist weg.
func _frighten_child(child: Guest) -> void:
	if Game.tracing:
		print("[Lakengeist] %s erschreckt" % child.display_name)
	child.shock("ghost_attack", global_position + Vector3.UP * HANDS_Y)
	_vanish()


## Ein Gast stirbt – er bleibt liegen (Spielkonzept 6.12), das Hotel erfährt es wie beim Monster.
func _kill_guest(guest: Guest) -> void:
	if Game.tracing:
		print("[Lakengeist] %s erwürgt" % guest.display_name)
	Game.director.guest_slain(guest, "ghost")   # das Röcheln bricht ab – kein Schrei
	_vanish()


# --- Verschwinden & Zeugen ------------------------------------------------------------------

func _vanish() -> void:
	if Game.player:
		Game.player.gripped = false
	if Game.hud:
		Game.hud.set_struggle(-1.0)
	if _victim is Guest:
		(_victim as Guest).ghost_gone()
	state = State.FADE
	_lurk_spot = null
	_end_door()
	if _hour_meeting or _victim == null:   # Geisterstunde: bald geht er wieder um
		_hour_pause = HOUR_PAUSE
		if _victim == null:
			return   # nur umgegangen – kein Besuch, keine Abklingzeit
	# Je schwächer das Opfer, desto schneller kommt er wieder – beim Aufholen fast sofort
	_cooldown = COOLDOWN / (1.0 + WEAK_FASTER * _weakness(_victim))
	if _victim is Player and catching_up():
		_cooldown = CATCH_UP_COOLDOWN


func _hide() -> void:
	state = State.IDLE
	_scripted = false
	visible = false
	_fade = 0.0
	_window = null
	_victim = null
	_lurk_spot = null
	_hour_meeting = false
	_end_door()
	global_position = Vector3(0, -60, 0)
	if _ambience:
		_ambience.stop()
	if _material:
		_material.set_shader_parameter("fade", 0.0)
	if _flakes:
		_flakes.restart()   # alte Flocken weg, sonst stünden sie beim nächsten Auftritt noch am alten Ort
		_flakes.emitting = false


## Wache Gäste (außer dem Opfer) mit freier Sicht auf diesen Punkt, höchstens `reach` entfernt.
func _witness_guests(point: Vector3, victim: Node3D, reach: float = WITNESS_RANGE) -> Array[Guest]:
	var result: Array[Guest] = []
	if Game.social == null:
		return result
	var world := get_world_3d()
	for guest in Game.social.guests:
		if guest == victim or guest.dead or guest.hiding != null or guest.is_child() or guest.global_position.distance_to(point) > reach:
			continue
		if Senses.clear_line(world, _eye_of(guest), point):
			result.append(guest)
	return result


## Kommt er zu einem Gast, ist der Spieler ein Zeuge wie jeder andere (1 oder 0).
func _player_witness(point: Vector3) -> int:
	var player := Game.player
	if not _victim is Guest or debug_ignore_player or player == null or player.dead or player.hiding != null:
		return 0
	var eye := player.camera.global_position
	return 1 if eye.distance_to(point) <= WITNESS_RANGE and Senses.clear_line(get_world_3d(), eye, point) else 0


## Der Gast, zu dem er kommt, sieht ihn (Sicht durchs Glas): Schreck – ab der Hypnose-Stufe bleibt er
## gebannt stehen, statt wegzulaufen.
func _guest_sees_me(guest: Guest) -> void:
	var eye := _eye_of(guest)
	var head := global_position + Vector3.UP * (HANDS_Y + 0.5)
	if eye.distance_to(head) > LEAVE_RANGE \
			or not Senses.clear_line(get_world_3d(), eye, head, guest, Senses.SIGHT_MASK & ~HotelWindow.LAYER_BLOCK):
		return
	_victim_saw = true
	guest.shock("ghost", head, "", _stage >= HYPNOSIS_FROM)


## Opfer versteckt (Gast: auch im Bett) oder tot – dann verschwindet er.
func _victim_gone() -> bool:
	if _victim is Guest:
		var guest := _victim as Guest
		return guest.hiding != null or guest.dead
	var player := _victim as Player
	return player.hiding != null or player.dead


## Opfer verloren? Versteckt sich der Spieler vor ihm im Schrank, wartet er davor, statt zu verschwinden.
func _lost_victim() -> bool:
	if not _victim_gone():
		return false
	var player := _victim as Player
	if player == null or player.dead:
		return true
	if _lurk_spot != null and player.hiding == _lurk_spot:
		return false   # wartet davor, fliegt hinein oder würgt schon im Schrank
	return not _start_lurk(player.hiding)


## Nur wenn er ohnehin hereingekommen wäre (ab dem 3. Mal, im Flur) – und nur vor Schränken. Eine Warnung
## (Garantie, erste Begegnungen der Geisterstunde) endet, wenn man sich versteckt.
func _start_lurk(spot: HideSpot) -> bool:
	if spot == null or spot.type != HideSpot.Type.WARDROBE or state == State.STRANGLE or _warn_only \
			or not (_stage >= ENTER_FROM or _window == null):
		return false
	var builder := Game.social.builder
	var room := builder.home_room_at(spot.global_position)
	if SaltLine.guarding(room) != null and builder.home_room_at(global_position) != room:
		return false   # das Zimmer mit dem Schrank ist gesalzen (5.13)
	_lurk_spot = spot
	state = State.LURK
	_timer = randf_range(LURK_TIME.x, LURK_TIME.y)
	_rattle = randf_range(RATTLE_EVERY.x, RATTLE_EVERY.y)
	_held_breath = 0.0
	_heard_pant = false
	if Game.tracing:
		print("[Lakengeist] wartet %.0f s vor dem Schrank" % _timer)
	return true


## Vor dem Schrank: schwebt vor die Türen und rüttelt ab und zu. Wer herauskommt, wird gepackt; wer nach
## Luft schnappt, verrät sich – dann fliegt er sofort hinein. Am Ende würfelt er: hinein oder aufgeben.
func _lurk(delta: float) -> void:
	var player := Game.player
	if player.hiding != _lurk_spot:   # herausgekommen (oder musste raus)
		_lurk_spot = null
		state = State.ENTER
		Game.caption("[Er hat gewartet]")
		return
	var front := _lurk_spot.check_point.global_position
	var hands := _lurk_spot.view_point.global_position.y - NECK_BELOW_EYES - HANDS_Y
	_float_to(Vector3(front.x, hands, front.z), INSIDE_SPEED, delta)
	_face(_lurk_spot.global_position - global_position)
	if player.holding_breath:
		_held_breath += delta
	elif player.is_panting():
		_heard_pant = true
	_rattle -= delta
	if _rattle <= 0.0:
		_rattle = randf_range(RATTLE_EVERY.x, RATTLE_EVERY.y)
		_lurk_spot.rattle()
		Game.caption("[Etwas rüttelt an der Schranktür]" if randf() < 0.6 else "[Flüstern vor dem Schrank]")
	if player.breath <= 0.0:
		if Game.tracing:
			print("[Lakengeist] hört dich keuchen – fliegt in den Schrank")
		_fly_in()
		return
	_timer -= delta
	if _timer > 0.0:
		return
	var chance := (FLY_IN_CHANCE_LATE if _stage >= HALL_FROM else FLY_IN_CHANCE) + FLY_IN_WEAK * player.weakness()
	if _heard_pant:
		chance += PANT_CHANCE
	chance *= 1.0 - BREATH_SAVES * clampf(_held_breath / BREATH_FULL, 0.0, 1.0)
	var flies := randf() < chance
	if Game.tracing:
		print("[Lakengeist] Schrank: Chance %.0f %% (Luft angehalten %.1f s%s) – %s" % [chance * 100.0, _held_breath,
			", gekeucht" if _heard_pant else "",
			"fliegt hinein" if flies else "gibt auf"])
	if flies:
		_fly_in()
	else:
		_vanish()


## Die Türen fliegen auf, er schwebt hinein und würgt im Schrank.
func _fly_in() -> void:
	state = State.FLY_IN
	_lurk_spot.burst_open(self)
	Game.caption("[Die Schranktüren fliegen auf]")


## Wohin er schwebt, um zuzupacken: Hände am Hals des Opfers. Dreht ihn zum Opfer.
func _grip_spot() -> Vector3:
	var neck := _eye_of(_victim) - Vector3(0, NECK_BELOW_EYES, 0)
	var flat := Vector3(neck.x - global_position.x, 0, neck.z - global_position.z)
	_face(flat)
	return Vector3(neck.x, neck.y - HANDS_Y, neck.z) - flat.normalized() * HANDS_AHEAD


## Erscheinen bei Spieler oder Gast – je schwächer das Opfer, desto wahrscheinlicher, an einer Fenstertür
## noch wahrscheinlicher (4.18).
func _spawn_chance(victim: Node3D, window: Node3D) -> float:
	if victim is Player and catching_up():
		return 1.0
	return minf(1.0, (FRENCH_DOOR_CHANCE if window is Door else SPAWN_CHANCE) + WEAK_CHANCE * _weakness(victim))


## Schwäche von Spieler oder Gast (0..1).
func _weakness(victim: Node3D) -> float:
	if victim is Player:
		return (victim as Player).weakness()
	if victim is Guest:
		return (victim as Guest).weakness()
	return 0.0


## Augenpunkt des Opfers (Spieler: Kamera).
func _eye_of(victim: Node3D) -> Vector3:
	if victim is Guest:
		return victim.global_position + Vector3.UP * (victim as Guest).eye_height()
	return (victim as Player).camera.global_position


# --- Hypnose ----------------------------------------------------------------------------

## Ab dem 2. Mal: Solange man ihn ansieht, während er die Hände kreisen lässt, wird man langsamer und
## der Blick wird zu ihm gezogen. Beim Würgen hält er den Blick fest.
## Sein Klang folgt der Sichtbarkeit (Erscheinen, Ausblenden) und der Effektlautstärke; jeder Auftritt
## beginnt an einer zufälligen Stelle der Schleife.
func _update_ambience() -> void:
	var level := 0.0 if state == State.DOOR else _fade * Settings.effects_volume   # vor der Tür: lautlos
	if state == State.PATROL:   # beim Umgehen leise
		level = _fade / PATROL_FADE * PATROL_SOUND * Settings.effects_volume
	if level <= 0.001:
		_ambience.stop()
		return
	_ambience.volume_db = AMBIENCE_DB + linear_to_db(level)
	if not _ambience.playing:
		_ambience.play(randf() * _ambience.stream.get_length())


func _update_trance(delta: float) -> void:
	var player := Game.player
	var head := global_position + Vector3.UP * (HANDS_Y + 0.5)
	var mine := _victim == player   # bei einem Gast hält er den Spieler nicht fest
	var hypnotizing := mine and _stage >= HYPNOSIS_FROM and state in [State.HOVER, State.ENTER] and _fade > 0.5
	if hypnotizing and Game.director.player_can_see(head):
		player.trance = minf(1.0, player.trance + TRANCE_GAIN * delta)
	else:
		player.trance = maxf(0.0, player.trance - TRANCE_DECAY * delta)
	var pull := PULL * player.trance * Settings.look_pull
	if state == State.STRANGLE and mine:
		pull = PULL * 2.0 * Settings.look_pull
	if player.hiding:   # im Versteck ist der Blick fest
		return
	if state == State.DOOR and mine and global_position.distance_to(player.global_position) < DOOR_PULL_RANGE:
		# Hypnose durch die Wand: nur der Blick dreht sich, ganz langsam, zur Tür
		var at := head - player.camera.global_position
		var door_pull := DOOR_PULL * (1.0 + player.weakness()) * Settings.look_pull
		player.rotation.y = rotate_toward(player.rotation.y, atan2(-at.x, -at.z), door_pull * delta)
	if pull <= 0.0:
		return
	var to := head - player.camera.global_position
	var want_yaw := atan2(-to.x, -to.z)
	player.rotation.y = rotate_toward(player.rotation.y, want_yaw, pull * delta)
	var want_pitch := atan2(to.y, Vector2(to.x, to.z).length())
	player.head.rotation.x = move_toward(player.head.rotation.x, want_pitch, pull * delta)


# --- Bewegung & Pose ----------------------------------------------------------------------

## Schwebt auf `to` zu; true, wenn angekommen.
func _float_to(to: Vector3, speed: float, delta: float) -> bool:
	var d := to - global_position
	if d.length() <= speed * delta:
		global_position = to
		return true
	global_position += d.normalized() * speed * delta
	return false


## Blick (Modell-Vorderseite −Z) in Richtung `dir`.
func _face(dir: Vector3) -> void:
	if Vector2(dir.x, dir.z).length() > 0.01:
		rotation.y = atan2(-dir.x, -dir.z)


## Schweben, wehender Saum, kreisende Hände (Hypnose), gekrallte Finger (Würgen).
func _pose() -> void:
	var bob := sin(_time * 1.7) * 0.04
	_visual_offset(bob)
	_rotate("hem", Vector3.RIGHT, sin(_time * 1.3) * 0.08)
	_rotate("head", Vector3.FORWARD, sin(_time * 0.7) * 0.12)
	var circling := state == State.DOOR or (_stage >= HYPNOSIS_FROM and state in [State.HOVER, State.ENTER, State.LURK])
	var gripping := state in [State.STRANGLE, State.FLY_IN]
	for side in [".L", ".R"]:
		var phase := hand_phase() + (0.0 if side == ".L" else PI)
		var lift := 0.25 if gripping else 0.0
		var swirl_x := sin(phase) * 0.22 if circling else 0.0
		var swirl_z := cos(phase) * 0.22 if circling else 0.0
		_rotate2("upper_arm" + side, Vector3.RIGHT, swirl_x + lift, Vector3.BACK, swirl_z)
		_rotate("forearm" + side, Vector3.RIGHT, swirl_x * 0.6 + lift * 0.5)
		var curl := 0.35 if gripping else (-0.08 if state == State.HOVER and _stage >= HYPNOSIS_FROM else 0.05 * sin(_time * 3.0 + phase))
		for finger in FINGERS:
			for g in [1, 2, 3]:
				_rotate("%s%d%s" % [finger, g, side], Vector3.RIGHT, curl * (0.6 if finger == "thumb" else 1.0))


func _visual_offset(y: float) -> void:
	_skeleton.get_parent_node_3d().position.y = y


func _rotate(bone_name: String, axis: Vector3, angle: float) -> void:
	var i: int = _bone.get(bone_name, -1)
	if i >= 0:
		_skeleton.set_bone_pose_rotation(i, _rest[i] * Quaternion(axis, angle))


func _rotate2(bone_name: String, axis_a: Vector3, a: float, axis_b: Vector3, b: float) -> void:
	var i: int = _bone.get(bone_name, -1)
	if i >= 0:
		_skeleton.set_bone_pose_rotation(i, _rest[i] * Quaternion(axis_a, a) * Quaternion(axis_b, b))


# --- Dusche (Spielkonzept 4.24) -------------------------------------------------------------

## Ist er dem Spieler schon begegnet (first_seen)?
func met() -> bool:
	return first_seen > NEVER_SEEN

## Er taucht im Nebel der Duschecke auf (spot = Boden in ihrer Mitte), kreist kurz mit den Händen und kommt durch die
## Glastür, um zu würgen – Losreißen wie sonst (_struggle meldet es ShowerScare.on_escaped), sonst stirbt man. Zählt
## nicht für die Stufe; er greift so fest zu wie beim 3. Mal.
func shower_visit(spot: Vector3) -> void:
	if state != State.IDLE:
		_debug_reset()
	var player := Game.player
	_victim = player
	_warn_only = false
	_hour_meeting = false
	_victim_saw = false
	_stage = ENTER_FROM
	_window = null
	_last_window = null
	_lurk_spot = null
	_scripted = true
	_swings = 0
	_last_sign = 0
	visible = true
	_fade = 0.0
	var neck := player.camera.global_position.y - NECK_BELOW_EYES
	global_position = Vector3(spot.x, neck - HANDS_Y, spot.z)
	_face(player.global_position - global_position)
	state = State.HOVER
	_timer = SHOWER_HOVER
	Game.caption("[Etwas bewegt sich im Nebel]")
	if Game.tracing:
		print("[Lakengeist] in der Dusche – im Nebel aufgetaucht")


# --- Debug & Speichern ----------------------------------------------------------------------

## Debug (F6, --ghost=n): Er kommt sofort zum `stage`. Mal ans nächste Außenfenster bzw. an die nächste
## Fenstertür des Raums, in dem der Spieler steht – Licht dort aus, Vorhänge auf (ab dem 4. Mal zu), Blick
## dorthin. Ohne beides nur eine Meldung (false).
func debug_summon(stage: int) -> bool:
	var player := Game.player
	var room := Game.social.builder.room_at(player.global_position)
	var window: Node3D = null
	var best := INF
	for node in get_tree().get_nodes_in_group("windows") + get_tree().get_nodes_in_group("french_doors"):
		var door := node as Door
		var d := _window_center(node).distance_to(player.global_position)
		var usable := (door.room_id == room and not door.locked) if door \
			else ((node as HotelWindow).room_id == room and (node as HotelWindow).has_curtains())
		if room != "" and usable and d < best:
			window = node
			best = d
	if window == null:
		Game.say("Lakengeist: Hier ist kein Außenfenster und keine Fenstertür.", 2.5)
		return false
	_debug_reset()
	visits = maxi(0, stage - 1)
	var sw := LightSwitch.find(get_tree(), room)
	if sw:
		sw.set_on(false)
	for node in get_tree().get_nodes_in_group("windows"):
		var w := node as HotelWindow
		if w.room_id == room and w.has_curtains():
			w.set_closed(stage >= THROUGH_CURTAIN_FROM, true)
	if window is Door:
		(window as Door).set_open(false, true, true)
	_debug_look_at(_window_center(window))
	_last_window = window
	_appear(window, player)
	return true


## Debug (F6, --ghost=flur): Alle Gäste liegen sofort im Bett, er taucht in dem Flur auf, in dem der Spieler
## steht – Richtung des weitesten Wegpunkts dieses Flurabschnitts, höchstens DEBUG_HALL_DISTANCE entfernt –
## und kommt auf ihn zu (mindestens das 6. Mal). Außerhalb eines Flurs nur eine Meldung (false).
func debug_summon_hall() -> bool:
	var player := Game.player
	var builder := Game.social.builder
	if not builder.in_corridor(player.global_position):
		Game.say("Lakengeist: Du stehst in keinem Flur.", 2.5)
		return false
	var section := builder.room_at(player.global_position)
	var spot := Vector3.ZERO
	var far := 0.0
	for p: Vector3 in builder.wander_points:
		var d := p.distance_to(player.global_position)
		if builder.room_at(p) == section and d > far:
			spot = p
			far = d
	if far > DEBUG_HALL_DISTANCE:   # Flurabschnitte sind gerade: auf der Linie dorthin näher heran
		var from := Vector3(player.global_position.x, spot.y, player.global_position.z)
		spot = from + (spot - from).normalized() * DEBUG_HALL_DISTANCE
		far = DEBUG_HALL_DISTANCE
	if far < HALL_DISTANCE.x:
		Game.say("Lakengeist: Der Flur ist hier zu kurz.", 2.5)
		return false
	_debug_reset()
	visits = maxi(visits, HALL_FROM - 1)
	Game.social.debug_sleep(true)
	_debug_look_at(spot)
	_appear_in_hall(spot)
	return true


## Debug (--ghost=tür): Ein Lakengespenst hängt neben der Tür des Zimmers, in dem der Spieler steht (sonst
## Zimmer 13 – dorthin springt er), die Tür ist zu, und er steht sofort davor; Blick weg von der Tür.
## Mit Gast (--shock=id,tür): vor dessen Tür, der Spieler zählt nicht als Zeuge.
func debug_summon_door(guest: Guest = null) -> bool:
	var player := Game.player
	var builder := Game.social.builder
	var no := builder.room_at(player.global_position) if guest == null else String(guest.home["no"])
	if not builder.rooms.has(no):
		no = LevelBuilder.PLAYER_ROOM
		var home: Dictionary = builder.rooms[no]
		player.global_position = (home["center"] as Vector3) + Vector3(0, 0.05, 0)
	var room: Dictionary = builder.rooms[no]
	var door: Door = room["door"]
	door.set_open(false, true, true)
	var into: Vector3 = room["into"]
	var along: Vector3 = room["along"]
	var c := door.center()
	var face := Vector3(c.x, door.global_position.y, c.z) - into * (LevelBuilder.T / 2.0)
	var deco: Array[Item] = []
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.kind == Item.Kind.SHEET_GHOST and item.hung and item.global_position.distance_to(face) < DOOR_DECO_RANGE + 1.0:
			deco.append(item)
	if deco.is_empty():
		var ghost := Item.create(Item.Kind.SHEET_GHOST, "pumpkin")
		get_parent().add_child(ghost)
		ghost.hang(face + along * (door.width / 2.0 + 0.45) + Vector3.UP * 2.15, -into)
		deco.append(ghost)
	_debug_reset()
	if guest:
		debug_ignore_player = true
		_appear_at_door(room, guest, deco)
		return true
	_debug_look_at((room["center"] as Vector3) + into * 3.0)
	_appear_at_door(room, player, deco)
	return true


## Debug (--ghost=stunde[,n]): Die Uhr springt kurz vor Mitternacht (der erste Angriff gilt als geschehen), die Glocke
## schlägt, danach taucht er im Flur auf, in dem der Spieler steht, und kommt zum n. Mal (Standard 1, ab
## HOUR_WARNINGS + 1 würgt er). Das Monster ruht noch mindestens DEBUG_CALM Sekunden. Steht der Spieler in keinem Flur, geht er dort um, wo er sonst auch umginge.
func debug_ghost_hour(meeting: int) -> void:
	_debug_reset()
	var director := Game.director
	director.first_attack_done = true
	if director.phase != MonsterDirector.Phase.ACTIVE:   # das Monster bleibt im Keller, sonst wartete die Geisterstunde
		director._phase_left = maxf(director._phase_left, DEBUG_CALM)
	hour_meetings = maxi(0, meeting - 1)
	director.elapsed = Calendar.at(Calendar.day_of(director.elapsed), 24.0 - 3.0 / Calendar.HOUR)
	_debug_hour_near = true


## Debug (--ghost=tür --answer): Der Spieler macht die Tür auf, vor der er steht.
func debug_open_door() -> void:
	if state == State.DOOR:
		(_door_room["door"] as Door).set_open(true, false, false, Game.player)


## Debug: Läuft er schon, verschwindet er sofort (der Spieler kommt los); keine Pause.
func _debug_reset() -> void:
	if state != State.IDLE:
		Game.player.gripped = false
		if _victim is Guest:
			(_victim as Guest).ghost_gone()
		if Game.hud:
			Game.hud.set_struggle(-1.0)
		_hide()
	_cooldown = 0.0
	_hour_pause = 0.0


## Debug (--despawn): Er ist sofort fort, wer im Griff war, kommt los – danach die übliche Pause wie nach einem Besuch.
## false = er war gar nicht da.
func debug_despawn() -> bool:
	if state == State.IDLE:
		return false
	_debug_reset()
	_cooldown = COOLDOWN
	_hour_pause = HOUR_PAUSE
	return true


## Debug: Der Spieler bleibt stehen, nur sein Blick geht dorthin.
func _debug_look_at(point: Vector3) -> void:
	var to := point - Game.player.global_position
	Game.player.rotation.y = atan2(-to.x, -to.z)
	Game.player.head.rotation.x = 0.0


## Debug (--shock=id,ghostN): Licht im Zimmer des Gastes aus, Vorhänge auf (ab dem 4. Mal zu); er kommt
## sicher zum `stage`. Mal zu diesem Gast. Der Spieler zählt dabei nicht als Zeuge.
func debug_summon_guest(guest: Guest, stage: int) -> void:
	guest.ghost_visits = maxi(0, stage - 1)
	_cooldown = 0.0
	_guest_windows.erase(guest.id)
	_force_guest = guest
	debug_ignore_player = true
	var sw := LightSwitch.find(get_tree(), guest.home["no"])
	if sw:
		sw.set_on(false)
	var found := false
	for node in get_tree().get_nodes_in_group("windows"):
		var window := node as HotelWindow
		if window.room_id == guest.home["no"] and window.has_curtains():
			window.set_closed(stage >= THROUGH_CURTAIN_FROM, true)
			found = true
	for node in get_tree().get_nodes_in_group("french_doors"):
		found = found or ((node as Door).room_id == guest.home["no"] and not (node as Door).locked)
	if not found:
		print("[Lakengeist] Zimmer %s hat kein Außenfenster und keine Fenstertür – er kann nicht zu %s kommen" % [guest.home["no"], guest.display_name])


func save_state() -> Dictionary:
	return {"visits": visits, "cooldown": _cooldown, "catch_up_day": catch_up_day, "hour_meetings": hour_meetings,
		"first_seen": first_seen}


func load_state(d: Dictionary) -> void:
	visits = int(d.get("visits", 0))
	first_seen = float(d.get("first_seen", NEVER_SEEN if visits == 0 else 0.0))
	hour_meetings = int(d.get("hour_meetings", 0))
	catch_up_day = bool(d.get("catch_up_day", false))
	_cooldown = float(d.get("cooldown", 0.0))
	_guest_windows.clear()
	if Game.player:
		Game.player.gripped = false
	_hide()
