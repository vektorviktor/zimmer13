class_name PumpkinMan
extends NavWalker
## Der Kürbismann (Spielkonzept 4.19): früher Rezeptionist des Hotels. Zwei Kinder klopften zu Süßes oder Saures,
## er gab nichts – sie holten seine Axt, köpften ihn und setzten ihm als Streich einen Kürbis auf. Jetzt jagt er
## alle, die Spaß haben: Feiernde und Spieler an den Spieltischen, den Spieler auch. Kinder auf Süßes-oder-Saures-
## Runde zählen mit und locken ihn, aber ihnen tut er nie etwas (6.13) – sie schützen auch niemanden. Wer ihm im
## Weg steht, den erschlägt er, auch ohne Spaß.
## Steigt der Spaßwert des Hotels (fun, siehe FUN_START) über FUN_THRESHOLD, erscheint er mit hoher Chance – je mehr
## Spaß, desto sicherer; war er bis Tag 15 nicht zweimal da, kommt er an Tag 15 und 16 sicher. Er klettert an der Straßenfassade neben dem Haupteingang aufs Lobbydach, geht hinüber,
## springt vor einer Glastür der Lobby in den Mittelgarten und sucht zuerst die Lobby ab (entschieden 2026-10-21).
## Danach nimmt er sich immer den Nächsten vor: zu jemandem mit Spaß sprintet er, sonst folgt er dem nächsten
## erwachsenen Gast; den Spieler jagt er, wenn er ihn in der Nähe sieht oder der Spaß hat (oder im Weg steht). Sieht er sein Opfer, rennt er hin und schlägt mit dem Beil zu. Wer sich versteckt oder ihm lange
## genug aus den Augen ist, entkommt. Nach HUNT_TIME (2–3 min) hat er keine Lust mehr und verlässt das Hotel durch den
## Haupteingang – eine Opfergrenze gibt es nicht. Opfer bleiben als Leiche liegen.
## Modell von tools/build_pumpkin.py (walk, run, spin_jump von Meshy, Tänze wie bei den Gästen; das Beil ist ein
## eigenes Netz am Knochen RightHand). Der Schlag ist Mixamos „Standing Melee Attack Downward“ (ATTACK_ANIM); fehlt
## er in der GLB, bleibt er kurz stehen und holt aus. Klettern (CLIMB_ANIM) und Landen (LAND_ANIM) nimmt er, sobald
## es sie in der GLB gibt – bis dahin klettert er mit Gehbewegungen und bleibt nach dem Aufprall kurz stehen.
## Debug: --pumpkin[=anim] stellt eine Testfigur vor dich, --pumpkin=jagd[,gast] jagt (kommt auch übers Dach),
## F9 bzw. --pumpkin=dach lässt ihn übers Lobbydach kommen, --pumpkin=garten gleich an den Kürbisbeeten erscheinen.

enum State { INACTIVE, TEST, STALK, CHASE, SEARCH, STRIKE, ROAM, LEAVE, CLIMB, ROOF, LEAP, LAND, LOBBY }

const MODEL := "res://assets/models/pumpkin_man.glb"
## Beim Schlag (Dragon Studio, „sword slice“ – Datei dragon-studio-sword-slice-393847)
const HIT_SOUND := "res://assets/sound/axe_hit.mp3"
const HIT_SOUND_UNIT := 5.0          ## so nah ungedämpft …
const HIT_SOUND_RANGE := 35.0        ## … ab hier stumm
## Testfigur: so weit vor dem Spieler (m)
const DISTANCE := 2.5

# --- Tuning -------------------------------------------------------------------
## Spaßwert (Spielkonzept 4.19, 2026-10-22, ersetzt „15 Gäste mit Spaß, dann 30 %“): unsichtbar, 0 bis FUN_MAX, Start
## FUN_START. Er fällt ständig (je Sekunde FUN_DECAY des Werts – ohne Spaß von 60 in gut drei Minuten unter 10); jeder
## Gast mit Spaß hebt ihn je Sekunde nach seiner Beschäftigung (FUN_GAIN – am Spieltisch und auf Feiern stark), der
## Spieler wie ein Gast. Deko platzieren (Spieler) gibt kurz FUN_DECO je Stück, das in FUN_DECO_TIME verfliegt. Über
## FUN_THRESHOLD wird alle FUN_ROLL_EVERY s gewürfelt: FUN_CHANCE.x an der Schwelle bis FUN_CHANCE.y bei FUN_MAX.
## Solange er im Hotel ist, steigt nichts; danach fängt der Wert bei 0 an.
const FUN_START := 30.0
const FUN_MAX := 100.0
const FUN_DECAY := 1.0 / 90.0
const FUN_GAIN := {"game": 0.12, "party": 0.06, "decorate": 0.04, "eat": 0.04, "trick": 0.03}
const FUN_DECO := 3.0
const FUN_DECO_TIME := 60.0
const FUN_THRESHOLD := 60.0
## Trägt der Spieler die Kürbismann-Maske (Spielkonzept 5.19), liegt die Schwelle so tief – schon der Grundspaß des
## Hotels (FUN_START) reicht, und gewürfelt wird mit mehr Chance (threshold)
const MASK_THRESHOLD := 10.0
const FUN_ROLL_EVERY := 30.0
const FUN_CHANCE := Vector2(0.4, 0.9)
## Garantie: War er bis GUARANTEE_DAY noch keine GUARANTEE_VISITS Mal da, kommt er an diesem und am nächsten Tag
## sicher – zu einer zufälligen Tageszeit (Anteil des Tages in GUARANTEE_TIME), auch wenn keiner Spaß hat.
const GUARANTEE_DAY := 15
const GUARANTEE_VISITS := 2
const GUARANTEE_TIME := Vector2(0.25, 0.75)
const CHECK_EVERY := 1.0
## Ankündigung (Spielkonzept 4.19, 2026-10-22): Fällt der Wurf (oder die Garantie), kommt er erst nach ANNOUNCE_TIME –
## dann aber sicher. So lange werden alle Lampen rot und flackern ab und zu (FlickerLight.red, in RED_FADE s), der
## Plattenspieler leiert überall eine schrille Melodie (SynthAudio.creepy) und alle Kinder bleiben stehen und singen
## (Guest.singing, SynthAudio.chorus nach Nähe bis CHORUS_RANGE, Zeilen aus SONG als Untertitel). Rot und Melodie bleiben,
## bis er wieder weg ist; die Kinder hören auf, sobald er landet. In seiner Nähe leuchten die Lampen greller
## (FlickerLight.hot_spot).
const ANNOUNCE_TIME := Vector2(180.0, 240.0)
const RED_FADE := 4.0
const CREEPY_VOLUME := 0.55
const CHORUS_RANGE := 25.0
const CHORUS_FAR := 0.12      ## so leise hört man die Kinder überall
const SONG_LINE_TIME := 2.72  ## eine Zeile = acht Töne der Melodie (SynthAudio.CREEPY_BEAT)
const SONG := ["Kürbiskopf, Kürbiskopf, wo ist dein Gesicht?", "Süßes gabst du keines – Saures gab's für dich.",
	"Die Axt lag am Empfang, die Kerze ging aus,", "Kürbiskopf, Kürbiskopf, kommt heut in jedes Haus."]
const SPAWN_DISTANCE := Vector2(18.0, 28.0)   ## ohne Kürbisbeet: so weit von seinem ersten Opfer taucht er auf
const BED_REACH := 2.5               ## so nah an einer Kürbispflanze muss der NavMesh-Punkt liegen
const WALK_SPEED := 1.74             ## wie Meshys Gehen (Laufweite aus build_pumpkin.py, bei 2 m Größe)
const CHASE_SPEED := 3.6             ## schneller als rennende Gäste (3,3), langsamer als der rennende Spieler (4,8)
const RUN_ANIM_SPEED := 3.01         ## Laufweite von Meshys Rennen – schneller gespielt, wenn er schneller rennt
const SIGHT_RANGE := 18.0            ## so weit sieht er sein Opfer (freie Sicht)
const LOSE_SIGHT := 6.0              ## so lange ohne Sicht, dann sucht er dort, wo er es zuletzt sah
const SEARCH_TIME := 4.0             ## so lange steht er dort und sieht sich um
const GIVE_UP_RANGE := 45.0          ## weiter weg verfolgt er niemanden
const PLAYER_NOTICE := 14.0          ## sieht er den Spieler so nah, verfolgt er ihn – auch ohne Spaß
const STRIKE_RANGE := 1.4            ## so nah holt er aus …
const HIT_RANGE := 2.0               ## … und trifft, wer beim Schlag noch so nah ist
const BLOCK_RANGE := 1.2             ## so nah vor ihm steht jemand im Weg (erschlägt er, auch ohne Spaß) …
const BLOCK_DOT := 0.6               ## … und so genau vor ihm (Kosinus zur Blickrichtung)
const WINDUP := 0.45                 ## Ausholen ohne Schlaganimation (s) – der Spieler kann noch wegrennen
const STRIKE_TIME := 1.1             ## so lange steht er nach dem Schlag
const HIT_AT := 0.4                  ## mit Schlaganimation: Treffer bei diesem Anteil (das Beil saust nach unten)
const ATTACK_SPEED := 1.3            ## Schlaganimation schneller (Mixamo: 2,3 s, Treffer erst nach 0,9 s)
const ATTACK_ANIM := "attack"
const HUNT_TIME := Vector2(120.0, 180.0)   ## so lange ist er im Hotel (zufällig), dann geht er – egal wie viele er geholt hat
const ROAM_RANGE := 25.0             ## hat gerade keiner Spaß, streift er in diesem Umkreis umher …
const RECHECK := 3.0                 ## … und sieht so oft nach, ob wieder jemand Spaß hat
const EXIT := Vector3(0.0, 0.0, -1.5)   ## innen vor dem Haupteingang (Ursprung = Mitte des Eingangs)
const SCARE_RANGE := 14.0            ## Gäste mit freier Sicht auf ihn erschrecken
const LEAVE_TIME := 120.0            ## spätestens dann ist er weg (sonst am Ausgang, sobald ihn keiner sieht)
const HEAD_HEIGHT := 1.85

# --- Ankunft übers Lobbydach (Spielkonzept 4.19) ----------------------------------
## Er klettert an der Straßenseite gegenüber einer Gartentür der Lobby hoch (Südwand z = 0, außen – der Haupteingang
## ist verriegelt, der Luftraum oben geschlossen), geht übers Dach und springt vor dieser Glastür in den Garten.
const FACADE_Z := 0.45               ## so weit vor der Südwand klettert er (Wand 0,2 m stark, Kapsel 0,3 m)
const CLIMB_SPEED := 1.5             ## m/s die Fassade hinauf
const LEDGE_TIME := 0.7              ## so lange zieht er sich über die Dachkante
const ROOF_SPEED := 2.2              ## übers Dach (schneller als Gehen, langsamer als die Jagd)
const EDGE_WAIT := 1.6               ## so lange steht er an der Dachkante und sieht in den Garten hinunter
const LEAP_SPEED := 2.2              ## so schnell trägt ihn der Schritt über die Kante nach vorn (m/s)
const LAND_TIME := 0.9               ## ohne Landeanimation: so lange bleibt er nach dem Aufprall stehen
const CLIMB_ANIM := "climb"          ## Mixamo-Klettern (assets/source/anim/pumpkin/climb.fbx) – fehlt es: Gehen
const LAND_ANIM := "land"            ## Mixamo-Landung (…/land.fbx) – fehlt sie: stehen bleiben
## Wo er die Lobby absucht, nach dem Halt hinter der Glastür (x zur Seite seiner Tür gespiegelt): Seitengang neben
## der Treppe, hinter der Rezeption (sein alter Platz), vor dem Haupteingang
const LOBBY_STOPS: Array[Vector3] = [Vector3(6.3, 0, -15.0), Vector3(0.0, 0, -9.0), Vector3(1.5, 0, -3.5)]
const LOBBY_LOOK := 2.5              ## so lange sieht er sich an jedem Halt um
const LOOK_EVERY := 0.4              ## so oft sieht er beim Absuchen nach, ob jemand da ist

var state := State.INACTIVE

var _player: AnimationPlayer
var _collider: CollisionShape3D
var _hit_sound: AudioStreamPlayer3D
var _test := false
var fun := FUN_START          ## Spaßwert ohne den Deko-Anteil (gespeichert)
var visits := 0               ## so oft war er schon im Hotel (gespeichert, für die Garantie)
## Garantie: Spielzeit (Director.elapsed), zu der er sicher kommt – je Tag einer; geprüft am GUARANTEE_DAY (gespeichert)
var guarantee_at: Array = []
var guarantee_checked := false
var _fun_deco := 0.0          ## kurzer Anteil vom Deko-Platzieren
var _announce := 0.0          ## Ankündigung: noch so viele Sekunden, dann kommt er
var _announce_wait := 0.0     ## Ankündigung vorbei, aber kein Platz zum Erscheinen: so lange schon
var _song := 0.0
var _song_line := 0
var _roll := FUN_ROLL_EVERY
var _check := 0.0
var _scan := 0.0
var _timer := 0.0
var _hunt_left := 0.0
var _kills := 0
var _forced: Node3D           ## Debug (--pumpkin=jagd,…): dieses Opfer zuerst, egal wer näher ist
var _victim: Node3D
var _last_seen := Vector3.ZERO
var _unseen_time := 0.0
var _hit_done := false
var _strike_target: Node3D    ## wen der Schlag trifft – sein Opfer oder wer im Weg steht
var _strike_len := 0.0        ## Dauer des Schlags (s) …
var _hit_time := 0.0          ## … und wann er trifft
var _scared := {}             ## Gast-ID → schon erschrocken (je Auftritt einmal)
var _door := Vector3.ZERO     ## Ankunft: Mitte der Glastür am Boden, vor der er landet …
var _roof_y := 0.0            ## … Höhe der Dachkante über der Straßenfassade …
var _edge_y := 0.0            ## … und der Kante über der Glastür (dazwischen folgt er dem Dach, _surface_y)
var _ground_y := 0.0          ## … und des Gartens davor
var _at_edge := false         ## steht an der Dachkante
var _lobby_left: Array[Vector3] = []   ## Halte in der Lobby, die er noch absuchen will
var _look := 0.0


## Testfigur vor den Spieler stellen, Blick zu ihm – ersetzt eine schon stehende. Ohne Verhalten.
static func spawn_in_front_of(p: Player, anim: String) -> PumpkinMan:
	var tree := p.get_tree()
	for old in tree.get_nodes_in_group("pumpkin_men"):
		old.queue_free()
	var man := PumpkinMan.new()
	man._test = true
	man.add_to_group("pumpkin_men")
	tree.current_scene.add_child(man)
	var forward := -p.global_transform.basis.z
	forward.y = 0.0
	man.global_position = p.global_position + forward.normalized() * DISTANCE
	man.rotation.y = p.rotation.y + PI
	man.play(anim)
	return man


## Zeitsprung im Schlaf (SleepSkip, Spielkonzept 3.6): der Spaßwert fällt weiter (nachts hat keiner Spaß).
func skip_time(dt: float) -> void:
	if state == State.INACTIVE and not announcing():
		fun = fun * exp(-FUN_DECAY * dt)


func _ready() -> void:
	add_to_group("time_skip")   # Zeitsprung im Schlaf (SleepSkip)
	var model: Node3D = (load(MODEL) as PackedScene).instantiate()
	add_child(model)
	var body: MeshInstance3D = model.find_child("pumpkin_man", true, false)
	body.material_override = Mat.model(MODEL, body, 0, true)   # Jackenfetzen sind einseitig
	# Das Beil in der rechten Hand (Ursprung = Griffpunkt, Stiel entlang +Y, Schneide −X)
	var axe: MeshInstance3D = model.find_child("axe", true, false)
	axe.material_override = Mat.model(MODEL, axe)
	_player = model.find_children("*", "AnimationPlayer", true, false)[0]
	for anim in ["walk", "run"]:
		_player.get_animation(anim).loop_mode = Animation.LOOP_LINEAR
	if _test:
		state = State.TEST
		return
	FlickerLight.red = 0.0   # statisch – vom letzten Spiel nichts übrig lassen
	FlickerLight.hot_spot = Vector3.INF
	collision_layer = 32   # wie das Monster: Gäste und Spieler laufen nicht durch ihn hindurch
	collision_mask = 1
	_collider = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.9   # 2 m groß, passt unter den Türen (2,1 m) durch
	_collider.shape = capsule
	_collider.position.y = 0.95
	add_child(_collider)
	agent = NavigationAgent3D.new()
	agent.radius = 0.3
	agent.height = 1.6
	agent.path_desired_distance = PATH_DISTANCE
	agent.target_desired_distance = 0.5
	agent.path_height_offset = 0.2   # NavMesh liegt ~0,2 m über dem Boden
	agent.path_search_max_polygons = 0   # wie das Monster: sonst endet ein langer Weg (Flügel, Stockwerke) auf halber Strecke
	add_child(agent)
	_hit_sound = AudioStreamPlayer3D.new()
	_hit_sound.stream = load(HIT_SOUND)
	_hit_sound.unit_size = HIT_SOUND_UNIT
	_hit_sound.max_distance = HIT_SOUND_RANGE
	_hit_sound.position.y = 1.2
	add_child(_hit_sound)
	_deactivate()
	fun = FUN_START


## Animation in Schleife – „chicken“ reicht für „dance_chicken“. false = gibt es nicht.
## spin_jump steht auf der Stelle; Meshys Sprung trägt ihn 3,1 m nach vorn (tools/build_pumpkin.py).
func play(anim: String) -> bool:
	if not _player.has_animation(anim):
		anim = "dance_" + anim
	if not _player.has_animation(anim):
		Game.say("Kürbismann: keine Animation „%s“ (%s)" % [anim, ", ".join(_player.get_animation_list())], 3.0)
		return false
	_player.get_animation(anim).loop_mode = Animation.LOOP_LINEAR
	_player.play(anim)
	return true


## Jagt er gerade (dann ist es nirgends ruhig, wo er ist – MonsterDirector.is_quiet)?
func is_hunting() -> bool:
	return state in [State.STALK, State.CHASE, State.SEARCH, State.STRIKE, State.ROAM, State.LAND, State.LOBBY]


## Ist er noch draußen auf dem Weg übers Dach (klettert, geht, springt)? Dann läuft seine Zeit im Hotel noch nicht.
func arriving() -> bool:
	return state in [State.CLIMB, State.ROOF, State.LEAP]


## Ist er im Hotel (jagt oder geht gerade)? Testfiguren zählen nicht.
func in_house() -> bool:
	return state != State.INACTIVE and not _test


func _physics_process(delta: float) -> void:
	if _test:
		return
	if Input.is_action_just_pressed("debug_pumpkin") and not Game.game_over:
		Game.achievements.cheated()   # Erfolge nur noch für diese Sitzung (8.11)
		debug_roof()
	_update_omens(delta)
	if state == State.INACTIVE:
		if announcing():
			_announce_step(delta)
			return
		_check -= delta
		if _check <= 0.0:
			_check = CHECK_EVERY
			_check_spawn()
		return
	if Game.player == null or Game.game_over:
		return
	if not arriving():
		_hunt_left -= delta
	_timer -= delta
	if _hunt_left <= 0.0 and state != State.LEAVE and state != State.STRIKE:
		_start_leave()   # keine Lust mehr
	_open_doors()
	_scan -= delta
	if _scan <= 0.0:
		_scan = 0.5
		_scare_onlookers()
	match state:
		State.STALK:
			_stalk(delta)
		State.CHASE:
			_chase(delta)
		State.SEARCH:
			_search(delta)
		State.STRIKE:
			_strike(delta)
		State.ROAM:
			_roam(delta)
		State.LEAVE:
			_leave(delta)
		State.CLIMB:
			_climb(delta)
		State.ROOF:
			_roof(delta)
		State.LEAP:
			_leap(delta)
		State.LAND:
			_land(delta)
		State.LOBBY:
			_lobby(delta)


# --- Erscheinen ---------------------------------------------------------------

## Spaßwert nachführen (CHECK_EVERY) und über FUN_THRESHOLD alle FUN_ROLL_EVERY s würfeln; dazu die Garantie
## (GUARANTEE_DAY). Nicht vor dem ersten Angriff des Monsters – der friedliche Anfang (Spielkonzept 2.1) bleibt.
func _check_spawn() -> void:
	var social := Game.social
	if social == null or Game.director == null or Game.player == null or Game.player.dead \
			or NavigationServer3D.map_get_iteration_id(get_world_3d().navigation_map) == 0:
		return   # ohne fertiges NavMesh findet er keinen Platz zum Erscheinen
	_update_fun(CHECK_EVERY)
	if not Game.director.first_attack_done or Game.director.other_threat_active(self):
		return   # nur eine Bedrohung im Haus – der Wurf wartet, bis die andere weg ist
	if _guarantee_due():
		if Game.tracing:
			print("[Kürbismann] Garantie an Tag %d (erst %d Mal da)" % [Calendar.today(), visits])
		guarantee_at.pop_front()
		_begin_announce()
		return
	var value := fun_value()
	var limit := threshold()
	if value < limit:
		_roll = FUN_ROLL_EVERY * 0.5   # gleich über der Schwelle wird bald gewürfelt
		return
	_roll -= CHECK_EVERY
	if _roll > 0.0:
		return
	_roll = FUN_ROLL_EVERY
	var chance := lerpf(FUN_CHANCE.x, FUN_CHANCE.y, clampf((value - limit) / (FUN_MAX - limit), 0.0, 1.0))
	var roll := randf()
	if Game.tracing:
		print("[Kürbismann] Spaßwert %.0f – Wurf %.2f gegen %.2f" % [value, roll, chance])
	if roll < chance:
		_begin_announce()


# --- Ankündigung ------------------------------------------------------------------------------

## Kündigt er sich gerade an (rote Lampen, Melodie, Kinder singen – er ist noch nicht da)?
func announcing() -> bool:
	return _announce > 0.0 or _announce_wait > 0.0


## Der Wurf ist gefallen: in ANNOUNCE_TIME kommt er. Rot, Melodie und Gesang beginnen; Ängstliche bekommen Angst
## (wer genug hat, geht heim), die meisten feiern weiter, Betrunkene erst recht.
func _begin_announce(seconds: float = -1.0) -> void:
	_announce = seconds if seconds > 0.0 else randf_range(ANNOUNCE_TIME.x, ANNOUNCE_TIME.y)
	_announce_wait = 0.0
	_song = 0.0
	_song_line = 0
	Game.caption("[Alle Lichter werden rot]")
	Game.caption("[Eine schrille, verzerrte Melodie – überall im Hotel]")
	for guest in Game.social.living_guests():
		var g: Guest = guest
		if g.is_child():
			g.singing = true
		elif g.drunk < BarTap.DRUNK:
			g.fear = minf(100.0, g.fear + (1.0 - float(g.profile["brave"])) * 45.0)
	if Game.tracing:
		print("[Kürbismann] kündigt sich an – kommt in %.0f s (Spaßwert %.0f)" % [_announce, fun_value()])


## Während der Ankündigung (statt _check_spawn): Liedzeilen als Untertitel; ist die Zeit um, kommt er sicher – findet
## er keinen Platz, versucht er es jede Sekunde wieder, höchstens 60 s lang.
func _announce_step(delta: float) -> void:
	_song -= delta
	if _song <= 0.0:
		_song = SONG_LINE_TIME
		var near := _nearest_singer()
		if near < CHORUS_RANGE:
			Game.caption("[Die Kinder singen: „%s“]" % SONG[_song_line % SONG.size()])
		elif _song_line % SONG.size() == 0:
			Game.caption("[Irgendwo singen Kinder]")
		_song_line += 1
	if _announce > 0.0:
		_announce -= delta
		if _announce > 0.0:
			return
		_announce_wait = 0.001
	_announce_wait += delta
	if _start_any() or _announce_wait > 60.0:
		_announce_wait = 0.0
		_announce = 0.0
		_stop_singing()


## Rot und Melodie, solange er sich ankündigt oder im Hotel ist; grelle Lampen um ihn herum; Kinderchor nach Nähe.
func _update_omens(delta: float) -> void:
	var on := announcing() or in_house()
	FlickerLight.red = move_toward(FlickerLight.red, 1.0 if on else 0.0, delta / RED_FADE)
	FlickerLight.hot_spot = global_position + Vector3.UP * 1.5 if in_house() and not arriving() else Vector3.INF
	if Game.audio:
		Game.audio.creepy = move_toward(Game.audio.creepy, CREEPY_VOLUME * Settings.music_volume if on else 0.0, delta * 0.3)
		var chorus := 0.0
		if announcing():
			chorus = maxf(CHORUS_FAR, clampf(1.0 - _nearest_singer() / CHORUS_RANGE, 0.0, 1.0))
		Game.audio.chorus = move_toward(Game.audio.chorus, chorus, delta * 0.5)


## Abstand des Spielers zum nächsten singenden Kind (INF = keins).
func _nearest_singer() -> float:
	var best := INF
	if Game.player and Game.social:
		for guest in Game.social.guests:
			var g: Guest = guest
			if g.singing and not g.dead:
				best = minf(best, g.global_position.distance_to(Game.player.global_position))
	return best


func _stop_singing() -> void:
	if Game.social:
		for guest in Game.social.guests:
			(guest as Guest).singing = false


## Liedzeile für ein Kind, das man anspricht, während es singt (Guest.interact).
func song_line() -> String:
	_song_line += 1
	return SONG[_song_line % SONG.size()]


## Debug (--pumpkin=ankündigung[,s]): Er kündigt sich an und kommt in s Sekunden (Standard 20).
func debug_announce(seconds: float) -> void:
	Game.director.first_attack_done = true
	if state == State.INACTIVE and not announcing():
		_begin_announce(seconds)


## Debug (--despawn): Er ist sofort fort, auch eine laufende Ankündigung bricht ab; der Spaßwert fängt von vorn an.
## false = er war weder da noch angekündigt.
func debug_despawn() -> bool:
	var was := state != State.INACTIVE or announcing()
	_announce = 0.0
	_announce_wait = 0.0
	_stop_singing()
	if state != State.INACTIVE:
		_deactivate()
	return was


## Ab diesem Spaßwert wird gewürfelt: FUN_THRESHOLD, mit der Kürbismann-Maske auf dem Kopf MASK_THRESHOLD (5.19).
func threshold() -> float:
	return MASK_THRESHOLD if Game.player and Game.player.mask == "pumpkin" else FUN_THRESHOLD


## Spaßwert mit dem kurzen Deko-Anteil (0..FUN_MAX).
func fun_value() -> float:
	return minf(FUN_MAX, fun + _fun_deco)


## Fällt ständig, steigt mit jedem, der Spaß hat (Social.fun_kind; der Spieler wie ein Gast) – nicht, solange er im
## Hotel ist.
func _update_fun(delta: float) -> void:
	_fun_deco = maxf(0.0, _fun_deco - delta * FUN_DECO / FUN_DECO_TIME)
	var gain := 0.0
	if not in_house():
		for guest in Game.social.guests:
			gain += float(FUN_GAIN.get(Game.social.fun_kind(guest), 0.0))
		if Game.table_game_active():
			gain += float(FUN_GAIN["game"])
		elif Game.social.player_has_fun():
			gain += float(FUN_GAIN["party"])
	fun = clampf(fun + (gain - fun * FUN_DECAY) * delta, 0.0, FUN_MAX)


## Der Spieler hat Deko platziert (Player): kurz mehr Spaß.
func on_deco_placed() -> void:
	if not in_house():
		_fun_deco = minf(FUN_MAX, _fun_deco + FUN_DECO)


## Garantie: Am GUARANTEE_DAY einmal prüfen – war er noch keine GUARANTEE_VISITS Mal da, je eine zufällige Zeit an diesem
## und am nächsten Tag. Fällig, sobald die nächste erreicht ist; kam er an dem Tag schon von selbst, fällt sie weg.
func _guarantee_due() -> bool:
	var now := Game.director.elapsed
	var day := Calendar.today()
	if not guarantee_checked and day >= GUARANTEE_DAY:
		guarantee_checked = true
		if visits < GUARANTEE_VISITS:
			for d: int in [GUARANTEE_DAY, GUARANTEE_DAY + 1]:
				var start: float = Calendar.at(d, 0.0)
				guarantee_at.append(maxf(now, start + Calendar.DAY_SECONDS * randf_range(GUARANTEE_TIME.x, GUARANTEE_TIME.y)))
			if Game.tracing:
				print("[Kürbismann] Garantie: erst %d Mal da – kommt sicher bei %s" % [visits, ", ".join(guarantee_at.map(func(t) -> String: return Calendar.date_text(float(t)) + " (%.0f s)" % float(t)))])
	return not guarantee_at.is_empty() and now >= float(guarantee_at[0])


## Er kommt – zu denen, die Spaß haben, sonst zu allen Erwachsenen und dem Spieler (Garantie). false = kein Platz.
func _start_any() -> bool:
	var actors := Game.social.fun_actors()
	if actors.is_empty():
		for guest in Game.social.living_guests():
			actors.append(guest)
		actors.append(Game.player)
	return start_hunt(actors)


## Er kommt übers Lobbydach (_start_arrival, an der Gartentür, die einem der Feiernden am nächsten liegt) und sucht
## zuerst die Lobby ab; mit `at` erscheint er gleich dort (Debug). Ohne Glastür von der Lobby in den Garten erscheint
## er außer Sicht am Kürbisbeet, das einem der Feiernden am nächsten liegt (ohne freies Beet SPAWN_DISTANCE von ihm).
## Wen er dann jagt, sucht er sich laufend selbst aus (_pick).
func start_hunt(actors: Array[Node3D], at: Vector3 = Vector3.INF) -> bool:
	var huntable: Array[Node3D] = []
	for actor in actors:
		if _can_hunt(actor):
			huntable.append(actor)
	if huntable.is_empty():
		return false
	var first: Node3D = huntable.pick_random()
	var door := _garden_door(first.global_position) if at == Vector3.INF else Vector3.INF
	var spot := at
	if spot == Vector3.INF and door == Vector3.INF:
		spot = _bed_point(first.global_position)
		if spot == Vector3.INF:
			spot = _spawn_point(first.global_position)
		if spot == Vector3.INF:
			if Game.tracing:
				print("[Kürbismann] kein Platz zum Erscheinen bei %s" % _name_of(first))
			return false
	visits += 1
	var today := Calendar.today()
	guarantee_at = guarantee_at.filter(func(t) -> bool: return Calendar.day_of(float(t)) != today)   # heute schon da
	_kills = 0
	_scared.clear()
	_hunt_left = randf_range(HUNT_TIME.x, HUNT_TIME.y)
	visible = true
	velocity = Vector3.ZERO
	_victim = null
	_lobby_left.clear()
	if door != Vector3.INF:
		_start_arrival(door)
		return true
	_collider.disabled = false
	global_position = spot
	_last_pos = spot
	if Game.tracing:
		print("[Kürbismann] erscheint bei %s" % Game.director.zone_name_at(spot))
	_next_victim()
	return true


## Er kommt aus den Kürbisbeeten (Spielkonzept 4.19): NavMesh-Punkt neben der Pflanze, die `near` am nächsten liegt
## und die der Spieler nicht sieht. `seen_ok` (Debug): auch eine, die er sieht. Kein Beet → Vector3.INF.
func _bed_point(near: Vector3, seen_ok: bool = false) -> Vector3:
	var map := get_world_3d().navigation_map
	var plants := get_tree().get_nodes_in_group("pumpkin_plants")
	plants.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return a.global_position.distance_to(near) < b.global_position.distance_to(near))
	for node in plants:
		var plant := node as Node3D
		var p := NavigationServer3D.map_get_closest_point(map, plant.global_position)
		if p.distance_to(plant.global_position) > BED_REACH:
			continue
		if seen_ok or not Game.director.player_can_see(p + Vector3.UP * HEAD_HEIGHT):
			return p
	return Vector3.INF


## NavMesh-Punkt im passenden Abstand auf demselben Stockwerk, den der Spieler nicht sieht.
func _spawn_point(near: Vector3) -> Vector3:
	var map := get_world_3d().navigation_map
	var start := randf() * TAU
	for i in 16:
		var dir := Vector3.FORWARD.rotated(Vector3.UP, start + TAU * i / 16.0)
		var dist := randf_range(SPAWN_DISTANCE.x, SPAWN_DISTANCE.y)
		var p := NavigationServer3D.map_get_closest_point(map, near + dir * dist)
		var flat := Vector2(p.x - near.x, p.z - near.z).length()
		if absf(p.y - near.y) < 1.5 and flat > SPAWN_DISTANCE.x * 0.6 \
				and not Game.director.player_can_see(p + Vector3.UP * HEAD_HEIGHT):
			return p
	return Vector3.INF


# --- Ankunft übers Lobbydach -------------------------------------------------------

## Die Glastür von der Lobby in den Mittelgarten, die `near` am nächsten liegt (Mitte am Boden) – ohne: Vector3.INF.
func _garden_door(near: Vector3) -> Vector3:
	if Game.social == null:
		return Vector3.INF
	var builder := Game.social.builder
	var best := Vector3.INF
	for node in get_tree().get_nodes_in_group("doors"):
		var door := node as Door
		if not door.glass:
			continue
		var c := door.center()
		c.y = 0.0
		if builder.in_lobby(c + Vector3(0, 0, 0.8)) and builder.is_outdoor(c + Vector3(0, 0, -0.8)) \
				and (best == Vector3.INF or c.distance_to(near) < best.distance_to(near)):
			best = c
	return best


## Höhe der obersten Fläche bei (x, z) unterhalb von `below` – Dach (Decke, Ebene 5) bzw. Garten.
func _surface_y(x: float, z: float, below: float = 50.0) -> float:
	var query := PhysicsRayQueryParameters3D.create(Vector3(x, below, z), Vector3(x, -1.0, z), 1 | LevelBuilder.LAYER_CEILING)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return (hit["position"] as Vector3).y if not hit.is_empty() else 0.0


## Unten an der Straßenfassade, genau gegenüber der Glastür – von dort klettert er hinauf. Übers Dach geht er ohne
## Physik und NavMesh (Kapsel aus), auf festem Weg; erst im Garten ist er wieder ein Körper.
func _start_arrival(door: Vector3) -> void:
	_door = door
	_roof_y = _surface_y(door.x, -0.4)   # wo er über die Kante steigt (siehe _climb)
	_edge_y = _surface_y(door.x, door.z + 0.05)
	_ground_y = _surface_y(door.x, door.z - 2.5, minf(_roof_y, _edge_y) - 1.0)
	_at_edge = false
	_collider.disabled = true
	global_position = Vector3(door.x, 0.0, FACADE_Z)
	rotation.y = 0.0   # Blick nach −Z, zur Wand
	state = State.CLIMB
	if _player.has_animation(CLIMB_ANIM):
		_player.get_animation(CLIMB_ANIM).loop_mode = Animation.LOOP_LINEAR
	if Game.tracing:
		print("[Kürbismann] klettert aufs Lobbydach (%.1f m), will zur Gartentür bei x %.1f" % [_roof_y, door.x])


## Die Fassade hinauf, dann über die Kante aufs Dach.
func _climb(delta: float) -> void:
	if _player.has_animation(CLIMB_ANIM):
		if _player.current_animation != CLIMB_ANIM:
			_player.play(CLIMB_ANIM, 0.2)
		_player.speed_scale = 1.0
	else:
		_animate("walk", CLIMB_SPEED)
	if global_position.y < _roof_y:
		global_position.y = minf(_roof_y, global_position.y + CLIMB_SPEED * delta)
		_timer = LEDGE_TIME
		return
	global_position.z = move_toward(global_position.z, -0.4, (FACADE_Z + 0.4) / LEDGE_TIME * delta)
	if _timer <= 0.0:
		state = State.ROOF
		Game.shot_event("pumpkin_roof", 30)


## Übers Dach bis an die Kante über der Glastür, dort kurz stehen und hinuntersehen – dann ein Schritt ins Leere.
func _roof(delta: float) -> void:
	var edge := Vector3(_door.x, _edge_y, _door.z)
	if not _at_edge:
		_animate("walk", ROOF_SPEED)
		_face(edge, delta)
		# waagerecht zur Kante, die Höhe folgt dem Dach (Dachgeschoss: Schrägen, flaches Dach dazwischen)
		var flat := Vector2(global_position.x, global_position.z).move_toward(Vector2(edge.x, edge.z), ROOF_SPEED * delta)
		global_position = Vector3(flat.x, _surface_y(flat.x, flat.y, global_position.y + 1.5), flat.y)
		if Vector2(global_position.x - edge.x, global_position.z - edge.z).length() < 0.05:
			_at_edge = true
			_timer = EDGE_WAIT
			Game.shot_event("pumpkin_edge", 30)
		return
	_animate("walk", 0.0)
	_face(edge + Vector3(0, 0, -5.0), delta)
	if _timer <= 0.0:
		state = State.LEAP
		velocity = Vector3(0, 0.5, -LEAP_SPEED)
		Game.shot_event("pumpkin_leap", 30)
		if Game.tracing:
			print("[Kürbismann] springt vom Dach")


## Freier Fall in den Garten; der Aufprall ist Lärm (pumpkin_land) – Gäste in der Nähe erschrecken.
func _leap(delta: float) -> void:
	velocity.y -= _gravity * delta
	global_position += velocity * delta
	if global_position.y > _ground_y:
		return
	global_position.y = _ground_y
	velocity = Vector3.ZERO
	_collider.disabled = false
	_last_pos = global_position
	state = State.LAND
	Game.noise("pumpkin_land", global_position, self)
	Game.shot_event("pumpkin_land", 20)
	if _player.has_animation(LAND_ANIM):
		_player.play(LAND_ANIM, 0.05)
		_player.speed_scale = 1.0
		_timer = _player.get_animation(LAND_ANIM).length
	else:
		_animate("walk", 0.0)
		_timer = LAND_TIME
	if Game.tracing:
		print("[Kürbismann] landet bei %s (%.1f, %.2f, %.1f)" % [Game.director.zone_name_at(global_position),
			global_position.x, global_position.y, global_position.z])


func _land(delta: float) -> void:
	_stop(delta)
	if _timer <= 0.0:
		_start_lobby()


## Zuerst sucht er die Lobby ab: durch die Glastür hinein, an jedem Halt (LOBBY_STOPS) sieht er sich um. Wen er dabei
## sieht, den jagt er – jeden Erwachsenen und den Spieler, ob mit Spaß oder ohne; danach wie sonst (_next_victim).
func _start_lobby() -> void:
	state = State.LOBBY
	_timer = -1.0
	_look = 0.0
	_lobby_left.clear()
	var side := -1.0 if _door.x < 0.0 else 1.0
	var map := get_world_3d().navigation_map
	_lobby_left.append(NavigationServer3D.map_get_closest_point(map, _door + Vector3(0, 0, 2.5)))
	for stop in LOBBY_STOPS:
		_lobby_left.append(NavigationServer3D.map_get_closest_point(map, Vector3(stop.x * side, stop.y, stop.z)))
	if Game.tracing:
		print("[Kürbismann] sucht die Lobby ab")


func _lobby(delta: float) -> void:
	_look -= delta
	if _look <= 0.0:
		_look = LOOK_EVERY
		var found := _spot_someone()
		if found:
			_lobby_left.clear()
			_victim = found
			_last_seen = found.global_position
			_timer = RECHECK
			_start_chase()
			return
	if _strike_blocker():
		return
	if _timer < 0.0:
		if _lobby_left.is_empty():
			_next_victim()
			return
		_animate("walk", WALK_SPEED)
		if _move_to(_lobby_left[0], WALK_SPEED, delta):
			_lobby_left.pop_front()
			_timer = LOBBY_LOOK
			Game.shot_event("pumpkin_lobby", 60)
			if Game.tracing:
				print("[Kürbismann] sieht sich in der Lobby um (%.1f, %.1f)" % [global_position.x, global_position.z])
		return
	_stop(delta)
	_animate("walk", 0.0)
	rotation.y += delta * 0.9   # sieht sich um
	if _timer <= 0.0:
		_timer = -1.0


## Wen er beim Absuchen sieht: den Nächsten, Kinder nicht. Mit `--pumpkin=jagd,…` nur das erzwungene Opfer.
func _spot_someone() -> Node3D:
	if Game.social == null:
		return null
	var actors: Array[Node3D] = [_forced]
	if not _can_hunt(_forced):
		actors = _everyone()
	var seen: Array[Node3D] = []
	for actor in actors:
		if _can_hunt(actor) and _sees(actor):
			seen.append(actor)
	return _nearest(seen)


# --- Jagd -------------------------------------------------------------------------

## Nächstes Opfer (_pick) – gibt es keinen erwachsenen Gast mehr, streift er umher, bis er keine Lust mehr hat.
func _next_victim() -> void:
	_lobby_left.clear()
	_victim = _pick()
	if _victim == null:
		_start_roam()
		return
	_last_seen = _victim.global_position
	_unseen_time = 0.0
	_timer = RECHECK
	state = State.STALK
	if Game.tracing:
		print("[Kürbismann] %s zu %s%s" % ["sprintet" if _has_fun(_victim) else "geht", _name_of(_victim),
			" (im Partyraum)" if _in_party_room(_victim) else ""])


## Wen er sich vornimmt (Spielkonzept 4.19): zuerst den Nächsten, den er im Partyraum sieht (jeden, auch den Spieler),
## dann den Spieler, wenn er ihn in der Nähe sieht (PLAYER_NOTICE), dann den Nächsten, der gerade Spaß hat (Gast oder
## Spieler) – sonst den nächsten erwachsenen Gast.
func _pick() -> Node3D:
	if _can_hunt(_forced):
		return _forced
	if Game.player.mask == "pumpkin" and _can_hunt(Game.player):
		return Game.player   # wer seine Maske trägt, ist sein Ziel, sobald er im Haus ist (5.19)
	if Game.social == null:
		return null
	var party := _nearest(_seen_in_party_room())
	if party:
		return party
	if _player_near():
		return Game.player
	var fun := _nearest(Game.social.fun_actors())
	if fun:
		return fun
	var guests: Array[Node3D] = []
	guests.assign(Game.social.guests)
	return _nearest(guests)


## Sieht er den Spieler in der Nähe? Dann verfolgt er ihn, ob er Spaß hat oder nicht.
func _player_near() -> bool:
	var p := Game.player
	return _can_hunt(p) and p.global_position.distance_to(global_position) < PLAYER_NOTICE and _sees(p)


func _has_fun(actor: Node3D) -> bool:
	if Game.social == null:
		return false
	if _in_party_room(actor):
		return true   # im Partyraum sprintet er auf jeden zu – ob er noch feiert oder schon erstarrt ist
	return Game.social.has_fun(actor as Guest) if actor is Guest else Game.social.player_has_fun()


## Alle im Partyraum, die er sieht – Gäste wie der Spieler, mit oder ohne Spaß (Spielkonzept 4.19). Kinder nicht (_can_hunt).
func _seen_in_party_room() -> Array[Node3D]:
	var result: Array[Node3D] = []
	for actor in _everyone():
		if _can_hunt(actor) and _in_party_room(actor) and _sees(actor):
			result.append(actor)
	return result


## Spieler und alle Gäste (auch Kinder und Tote – _can_hunt sortiert aus).
func _everyone() -> Array[Node3D]:
	var actors: Array[Node3D] = [Game.player]
	for guest in Game.social.guests:
		actors.append(guest)
	return actors


func _in_party_room(actor: Node3D) -> bool:
	return Game.social != null and is_instance_valid(actor) and Game.social.builder.in_area(actor.global_position, "partyraum")


func _nearest(actors: Array[Node3D]) -> Node3D:
	var best: Node3D = null
	for actor in actors:
		if _can_hunt(actor) and (best == null \
				or actor.global_position.distance_to(global_position) < best.global_position.distance_to(global_position)):
			best = actor
	return best


## Kein Opfer mehr im Hotel: Er streift umher (wer ihm im Weg steht, stirbt trotzdem) und sieht alle RECHECK Sekunden
## nach, ob wieder jemand da ist.
func _start_roam() -> void:
	state = State.ROAM
	_timer = RECHECK
	var dir := Vector3.FORWARD.rotated(Vector3.UP, randf() * TAU)
	_last_seen = NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map,
		global_position + dir * randf_range(8.0, ROAM_RANGE))
	if Game.tracing:
		print("[Kürbismann] streift umher (noch %.0f s)" % _hunt_left)


func _roam(delta: float) -> void:
	if _timer <= 0.0:
		_timer = RECHECK
		if _pick() != null:
			_next_victim()
			return
	if _strike_blocker():
		return
	_animate("walk", WALK_SPEED)
	if _move_to(_last_seen, WALK_SPEED, delta):
		_start_roam()


## Kinder (Spielkonzept 6.13) holt er nie – sie haben Spaß und locken ihn, aber er geht an ihnen vorbei.
func _can_hunt(actor: Node3D) -> bool:
	if not is_instance_valid(actor):
		return false
	if actor is Guest:
		var guest := actor as Guest
		return not guest.dead and guest.hiding == null and not guest.is_child() and guest.wound != "axe"   # wen er verletzt hat, lässt er (6.17)
	var player := actor as Player
	return player != null and not player.dead and player.hiding == null and not player.sleeping


## Hin zum Opfer: Wer Spaß hat, zu dem sprintet er; einem Gast ohne Spaß folgt er gehend. Sieht er es, jagt er es.
## Alle RECHECK Sekunden sucht er neu aus – ist jetzt ein anderer näher (oder hat Spaß), nimmt er den.
func _stalk(delta: float) -> void:
	if not _can_hunt(_victim):
		_next_victim()
		return
	if _timer <= 0.0:
		_timer = RECHECK
		var better := _pick()
		if better != null and better != _victim:
			_next_victim()
			return
	_last_seen = _victim.global_position   # er weiß, wo gefeiert wird
	if _sees(_victim):
		_start_chase()
		return
	if _strike_blocker():
		return
	var sprint := _has_fun(_victim)
	_animate("run" if sprint else "walk", CHASE_SPEED if sprint else WALK_SPEED)
	_move_to(_last_seen, CHASE_SPEED if sprint else WALK_SPEED, delta)


func _start_chase() -> void:
	state = State.CHASE
	_unseen_time = 0.0
	if _victim is Guest:
		(_victim as Guest).see_pumpkin(global_position + Vector3.UP * HEAD_HEIGHT)
	elif _victim is Player:
		Game.play_sound("sting", 0.8)
		Game.caption("[Schwere Schritte – etwas rennt auf dich zu]")
	if Game.tracing:
		print("[Kürbismann] rennt auf %s los" % _name_of(_victim))


func _chase(delta: float) -> void:
	if not _can_hunt(_victim) or _victim.global_position.distance_to(global_position) > GIVE_UP_RANGE:
		_lost_victim()
		return
	if _sees(_victim):
		_last_seen = _victim.global_position
		_unseen_time = 0.0
	else:
		_unseen_time += delta
		if _unseen_time >= LOSE_SIGHT:
			_lost_victim()
			return
	if _timer <= 0.0:
		_timer = RECHECK
		if _victim != Game.player and not _can_hunt(_forced) and _player_near() and not _in_party_room(_victim):
			_victim = Game.player   # der Spieler in der Nähe geht vor
			_start_chase()
			return
	var to := _victim.global_position - global_position
	if Vector2(to.x, to.z).length() < STRIKE_RANGE and absf(to.y) < 1.0:
		_start_strike(_victim)
		return
	if _strike_blocker():
		return
	_animate("run", CHASE_SPEED)
	_move_to(_last_seen, CHASE_SPEED, delta)


## Opfer weg (versteckt, entkommen): Er geht hin, wo er es zuletzt sah, und sieht sich um.
func _lost_victim() -> void:
	if Game.tracing:
		print("[Kürbismann] verliert %s" % _name_of(_victim))
	state = State.SEARCH
	_timer = -1.0


func _search(delta: float) -> void:
	if _can_hunt(_victim) and _sees(_victim):
		_start_chase()
		return
	if _timer < 0.0:
		_animate("walk", WALK_SPEED)
		if _move_to(_last_seen, WALK_SPEED, delta):
			_timer = SEARCH_TIME
		return
	_stop(delta)
	_animate("walk", 0.0)
	rotation.y += delta * 0.8   # sieht sich um
	if _timer <= 0.0:
		if _victim == Game.player and Game.achievements:
			Game.achievements.unlock("pumpkin_escape")   # abgeschüttelt (Spielkonzept 8.11)
		_next_victim()


## Wer ihm im Weg steht – ein Erwachsener oder der Spieler, ob mit Spaß oder ohne –, den erschlägt er im Vorbeigehen.
## Kinder nicht (sie schützen aber auch niemanden). true = er holt aus.
func _strike_blocker() -> bool:
	if Game.social == null:
		return false
	var ahead := -global_transform.basis.z
	for actor in _everyone():
		if actor == _victim or not _can_hunt(actor):
			continue
		var to := actor.global_position - global_position
		var flat := Vector3(to.x, 0.0, to.z)
		if absf(to.y) < 1.0 and flat.length() < BLOCK_RANGE and flat.normalized().dot(ahead) > BLOCK_DOT:
			if Game.tracing:
				print("[Kürbismann] %s steht im Weg" % _name_of(actor))
			_start_strike(actor)
			return true
	return false


func _start_strike(target: Node3D) -> void:
	state = State.STRIKE
	_strike_target = target
	_hit_done = false
	_face(target.global_position, 1.0)
	if target is Guest:
		(target as Guest).cower(global_position + Vector3.UP * HEAD_HEIGHT)
	Game.shot_event("pumpkin", 30)
	if _player.has_animation(ATTACK_ANIM):
		_player.play(ATTACK_ANIM, 0.15)
		_player.speed_scale = ATTACK_SPEED
		_strike_len = _player.get_animation(ATTACK_ANIM).length / ATTACK_SPEED
		_hit_time = _strike_len * HIT_AT
	else:
		_animate("walk", 0.0)   # ohne Schlaganimation: er bleibt stehen und holt aus
		_strike_len = WINDUP + STRIKE_TIME
		_hit_time = WINDUP
	_timer = _strike_len


func _strike(delta: float) -> void:
	_stop(delta)
	if is_instance_valid(_strike_target):
		_face(_strike_target.global_position, delta)
	if not _hit_done and _strike_len - _timer >= _hit_time:
		_hit_done = true
		_hit()
	if _timer <= 0.0 and state == State.STRIKE:
		if _hunt_left <= 0.0:
			_start_leave()
		elif _can_hunt(_victim):
			if _sees(_victim):
				_start_chase()   # daneben oder jemand im Weg – weiter hinter dem Opfer her
			else:
				state = State.STALK
		elif not _lobby_left.is_empty():
			state = State.LOBBY   # wer im Weg stand, ist erledigt – weiter die Lobby absuchen
			_timer = -1.0
		else:
			_next_victim()


## Der Schlag: Wer noch in Reichweite ist, stirbt. Der Spieler kann im letzten Moment wegrennen.
func _hit() -> void:
	_hit_sound.play()
	Game.noise("axe_swing", global_position, self)   # nur Lärm (Gäste, Monster) – zu hören ist _hit_sound
	var target := _strike_target
	if not _can_hunt(target) or target.global_position.distance_to(global_position) > HIT_RANGE:
		if Game.tracing:
			print("[Kürbismann] schlägt daneben")
		return
	if target is Guest and Wounds.survives(target as Guest):
		# Der Hieb trifft nicht voll (Spielkonzept 6.17): Axtwunde, er blutet eine Spur und humpelt davon
		var survivor := target as Guest
		if Game.tracing:
			print("[Kürbismann] verletzt %s" % survivor.display_name)
		Game.sound_at("grunt", survivor.global_position, Senses.GRUNT_RANGE, survivor)
		survivor.wound_by("axe", self)   # weiter wie nach einem Treffer, sobald der Schlag vorbei ist (_strike)
		return
	_kills += 1
	if target is Guest:
		var guest := target as Guest
		if Game.tracing:
			print("[Kürbismann] erschlägt %s" % guest.display_name)
		# Der Schrei vom Ausholen (Guest.cower) bricht ab – dann noch ein Ächzen, dann ist es still
		if Game.audio:
			Game.audio.cut_voice(guest)
		Game.director.guest_slain(guest, "pumpkin")
	else:
		if Game.tracing:
			print("[Kürbismann] erschlägt den Spieler")
		Game.director.player_slain("pumpkin")


# --- Gehen ----------------------------------------------------------------------

## Keine Lust mehr: Er geht zum Haupteingang und verlässt das Hotel – unterwegs tut er niemandem mehr etwas.
func _start_leave() -> void:
	if Game.tracing:
		print("[Kürbismann] hat keine Lust mehr und geht (%d Opfer)" % _kills)
	state = State.LEAVE
	_victim = null
	_timer = LEAVE_TIME
	_last_seen = NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, EXIT)


## Am Ausgang ist er fort, sobald ihn keiner sieht (spätestens nach LEAVE_TIME).
func _leave(delta: float) -> void:
	var arrived := _move_to(_last_seen, WALK_SPEED, delta)
	_animate("walk", 0.0 if arrived else WALK_SPEED)
	var seen := Game.director.player_can_see(global_position + Vector3.UP * HEAD_HEIGHT) \
		and Game.player.global_position.distance_to(global_position) < SIGHT_RANGE * 2.0
	if _timer <= 0.0 or (arrived and not seen):
		if Game.tracing:
			print("[Kürbismann] hat das Hotel verlassen")
		_deactivate()


func _deactivate() -> void:
	state = State.INACTIVE
	fun = 0.0   # der Spaßwert fängt nach seinem Besuch von vorn an
	_fun_deco = 0.0
	_roll = FUN_ROLL_EVERY
	visible = false
	_victim = null
	_forced = null
	_lobby_left.clear()
	velocity = Vector3.ZERO
	if _collider:
		_collider.disabled = true
	global_position = Vector3(0, -55, 0)
	_player.stop()


# --- Sehen & Erschrecken ---------------------------------------------------------

## Freie Sicht von seinem Kopf auf das Opfer (durch Glas, nicht durch Wände und zugezogene Vorhänge).
func _sees(actor: Node3D) -> bool:
	var eye := global_position + Vector3.UP * HEAD_HEIGHT
	var target := actor.global_position + Vector3.UP * ((actor as Guest).eye_height() if actor is Guest else 1.4)
	return eye.distance_to(target) <= SIGHT_RANGE and Senses.clear_line(get_world_3d(), eye, target, self)


## Gäste, die ihn sehen, erschrecken – Spiel und Feier sind für sie vorbei (Guest.see_pumpkin). Auf dem Dach
## verdeckt ihn auch die oberste Decke (Ebene 5, sonst nicht im Sichtstrahl) – von drinnen sieht ihn dort keiner.
func _scare_onlookers() -> void:
	if Game.social == null or not visible:
		return
	var head := global_position + Vector3.UP * HEAD_HEIGHT
	var world := get_world_3d()
	var mask := Senses.SIGHT_MASK | (LevelBuilder.LAYER_CEILING if arriving() else 0)
	for guest in Game.social.guests:
		var g: Guest = guest
		if g.dead or g.hiding != null or _scared.has(g.id) or g.global_position.distance_to(head) > SCARE_RANGE:
			continue
		if Senses.clear_line(world, g.global_position + Vector3.UP * g.eye_height(), head, self, mask):
			_scared[g.id] = true
			g.see_pumpkin(head)


func _name_of(actor: Node3D) -> String:
	return (actor as Guest).display_name if actor is Guest else "Spieler"


# --- Bewegung & Animation ---------------------------------------------------------

## Läuft in Schleife; die Geschwindigkeit der Animation folgt seiner (0 = steht still in der Gehpose).
func _animate(anim: String, speed: float) -> void:
	if _player.current_animation != anim:
		_player.play(anim, 0.2)
	_player.speed_scale = speed / (RUN_ANIM_SPEED if anim == "run" else WALK_SPEED)


func _open_doors() -> void:
	for door: Door in Door.near(global_position):
		if not door.is_open and door.monster_can_open and door.center().distance_to(global_position + Vector3.UP) < 1.5:
			door.monster_open()


# --- Debug ------------------------------------------------------------------------

## F9 bzw. --pumpkin=dach: Er kommt übers Lobbydach und jagt wie sonst auch (auch ohne Feier und vor dem ersten Angriff).
func debug_roof() -> void:
	if state != State.INACTIVE:
		_deactivate()
	var actors: Array[Node3D] = [Game.player]   # nur, damit er erscheint – wen er jagt, sucht er selbst aus (_pick)
	if start_hunt(actors):
		Game.say("Kürbismann kommt übers Lobbydach", 2.0)


## --pumpkin=garten: Er erscheint gleich an den Kürbisbeeten im Garten (ohne den Weg übers Dach) und jagt.
func debug_garden() -> void:
	var garden: Array = Game.director.zones.filter(func(z: Dictionary) -> bool: return z["name"] == "Garten")
	if garden.is_empty():
		return
	if state != State.INACTIVE:
		_deactivate()
	var actors: Array[Node3D] = [Game.player]
	var spot := _bed_point(garden[0]["center"], true)
	if spot == Vector3.INF:
		spot = NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, garden[0]["center"])
	if start_hunt(actors, spot):
		Game.say("Kürbismann an den Kürbisbeeten", 2.0)


## --pumpkin=jagd[,gast]: Er kommt übers Dach und jagt den Spieler bzw. den Gast (auch ohne Spaß und vor dem
## ersten Angriff). false = kein Platz zum Erscheinen.
func debug_hunt(target: Node3D) -> bool:
	if in_house():
		_deactivate()
	_forced = target   # erst dieses Opfer, danach wie sonst
	var marked: Array[Node3D] = [target]
	return start_hunt(marked)


# --- Spielstand ------------------------------------------------------------------------------
## Gespeichert werden nur Spaßwert, Besuche und Garantie – er selbst nicht (im Hotel wird nicht gespeichert, 8.6).

func save_state() -> Dictionary:
	return {"fun": fun, "visits": visits, "guarantee_at": guarantee_at.duplicate(), "guarantee_checked": guarantee_checked}


func load_state(d: Dictionary) -> void:
	fun = float(d.get("fun", FUN_START))
	visits = int(d.get("visits", 0))
	guarantee_at = (d.get("guarantee_at", []) as Array).map(func(t) -> float: return float(t))
	guarantee_checked = bool(d.get("guarantee_checked", false))
	_fun_deco = 0.0
	_roll = FUN_ROLL_EVERY
