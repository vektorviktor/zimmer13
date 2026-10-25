class_name Player
extends CharacterBody3D
## Ego-Perspektive-Spieler. Kapsel so hoch wie die Figur (1,45–2,00 m, Standard 1,80 m) × 0,45 m (Spielkonzept 3.1, 3.9);
## Augenhöhe und Hocken wachsen mit. Den eigenen Körper (PlayerBody) sieht man nur im Spiegel und als Schatten.
## Ein Gegenstand in der Hand, Kleines dazu in der Tasche (BAG_SLOTS Fächer, Spielkonzept 3.2): [Q] halten zeigt die
## Fächer über dem verschwommenen Spiel (es läuft weiter), Maus / Mausrad / [1]–[6] wählen, Loslassen nimmt den
## Gegenstand in die Hand – was die Hand hielt, fällt zu Boden; ein leeres Fach steckt Kleines aus der Hand ein.
## Am Körper: Kompass, Kartenblätter und Schlüsselbund – Karte (Tab) und Kompass (F) holt die linke Hand hervor.
## Getränkedose, Tasse Kaffee oder Tee in der Hand: [Linksklick] trinkt.
## Kann sich in Schränken und unter Betten verstecken (3.4) und auf Sitzmöbel setzen (Seat, 3.1).
## Taschenlampe in der Hand: [Linksklick] an/aus, [R] normales Licht ↔ UV (4.16).

const HEIGHT := 1.8
## Gebratenen Kürbis essen (Spielkonzept 3.8): so viel Schock weniger
const EAT_CALM := 0.2
const RADIUS := 0.225
const CROUCH_HEIGHT := 1.15
const EYE_HEIGHT := 1.68
const CROUCH_EYE_HEIGHT := 1.02
const WALK_SPEED := 2.6
const RUN_SPEED := 4.8
const CROUCH_SPEED := 1.3
const JUMP_VELOCITY := 3.6
const REACH := 2.2
## Tasche für Kleines (Spielkonzept 3.2): so viele Fächer, je ein Gegenstand (Item.POCKET_KINDS)
const BAG_SLOTS := 6
## Getränkedose trinken: so viel Schock weniger (die Ausdauer ist danach voll)
const CAN_CALM := 0.05
## Tasche offen: so viele Pixel Mausweg je Fach; so nah an der Mitte ist nichts gewählt (in Fächern)
const BAG_MOUSE_STEP := 60.0
const BAG_DEAD_ZONE := 0.35
const MOUSE_SENSITIVITY := 0.0022
const HIDE_COMFORT_TIME := 22.0   ## ab hier wird es im Versteck unangenehm
const HIDE_MAX_TIME := 38.0       ## dann muss man raus (wie in „Doors“)
const BREATH_MAX := 6.0
## Schlafen im eigenen Bett, jederzeit (Spielkonzept 3.6, 4.18): die Zeit läuft so viel schneller; man wählt 1–8
## Stunden (SLEEP_HOURS, voreingestellt die erste); so viele Spielsekunden (= Spielminuten, 2.4) sind eine ganze
## Mütze Schlaf (SLEEP_FULL, darunter anteilig), so viele im Rausch geben Kater (SLEEP_MIN); ab dieser Nähe des
## Monsters wacht man auf
const SLEEP_SPEED := 5.0
const SLEEP_HOURS := Vector2i(1, 8)
const SLEEP_FULL := 360.0
const SLEEP_MIN := 120.0
const SLEEP_WAKE_THREAT := 0.3
## Hand mit dem Gegenstand: unten rechts
const HAND_REST := Vector3(0.22, -0.22, -0.45)
## Linke Hand: Karte bildfüllend vors Gesicht, Kompass vor die Brust (Zifferblatt zum Gesicht
## gekippt); beim Hervorholen kommt sie von unten
const MAP_VIEW := Vector3(0.0, -0.005, -0.12)
const COMPASS_VIEW := Vector3(-0.03, -0.12, -0.3)
const COMPASS_TILT := 1.05
const LEFT_DOWN := Vector3(0.0, -0.3, 0.05)
const INSPECT_SPEED := 0.5        ## Laufen beim Draufschauen: halbe Geschwindigkeit
const TRANCE_SLOW := 0.65         ## volle Hypnose des Lakengeists: so viel langsamer
const STEP_LENGTH := 0.75         ## alle so viele Meter ein Schritt (Lärm auf Holz/Fliesen, 4.15)
const RUN_STEP_LENGTH := 1.3      ## beim Rennen: nur zu hören (Footsteps), Lärm macht der Lauf-Takt
const LAND_SPEED := 2.5           ## ab dieser Fallgeschwindigkeit ist Landen zu hören
const SOFT_FLOORS := ["carpet", "grass"]   ## Teppich und Rasen schlucken Schritte
## Schlagen und Rammen (Spielkonzept 6.3): Reichweite eines Schlags, Mindesttempo zum Rammen,
## Verletzung heilt in so vielen Sekunden ganz, macht bis zu so viel langsamer
const PUNCH_REACH := 1.4
const PUNCH_CONFIRM_TIME := 1.5
const RAM_SPEED := 3.5
const RAM_REACH := 0.75
const INJURY_HEAL_TIME := 240.0
const INJURY_SLOW := 0.4
const BLEED_TIME := 40.0
## Ausdauer (Spielkonzept 3.1): Rennen leert sie in so vielen Sekunden, im Stehen ist sie in so vielen
## Sekunden wieder voll (beim Gehen halb so schnell). Leer → außer Atem: Rennen geht erst ab STAMINA_CALM
## wieder. Unter STAMINA_HINT hört man den Atem schon beim Rennen.
const STAMINA_RUN_TIME := 15.0
const STAMINA_REST_TIME := 12.0
const STAMINA_WALK_SLOW := 0.5
const STAMINA_CALM := 0.6
const STAMINA_HINT := 0.3
## Außer Atem hält man die Luft bis zu so viel schneller nicht mehr aus (voll erschöpft: dreimal so schnell).
## Ab PANT_NOISE_FROM ist das Keuchen Lärm (alle PANT_EVERY s) und verrät einen im Versteck.
const WINDED_BREATH_DRAIN := 2.0
const PANT_NOISE_FROM := 0.3
const PANT_EVERY := 1.5
## Rausch (Spielkonzept 3.7, Stufen in BarTap): Angetrunken schwankt der Blick, die Maus zieht nach (so schnell
## folgt die Sicht – nüchtern sofort, voll betrunken träge) und man stolpert (je Sekunde Gehen so oft, voll
## betrunken). Wer im Rausch schläft, hat danach so lange Kater: Rennen leert die Ausdauer schneller.
const LOOK_LAG := Vector2(30.0, 7.0)
const STUMBLE_RATE := 0.25
const HANGOVER_TIME := 240.0
const HANGOVER_DRAIN := 1.4
## Schwäche (Spielkonzept 4.18): so viele Nächte ohne Schlaf machen ganz schwach, betrunken (BarTap.DRUNK, ab dem
## 3. Glas) ebenso; so viel zählen Schock, Trauer (frisch) und Kater
const WEAK_NIGHTS := 3.0
## Unter dem Bettlaken (Spielkonzept 5.9) erkennen Gäste den Spieler nur aus dieser Nähe
const RECOGNIZE_RANGE := 1.5
const WEAK_DRUNK := 1.0 / BarTap.DRUNK
const WEAK_SHOCK := 0.5
const WEAK_GRIEF := 0.3
const WEAK_HANGOVER := 0.2
## Kaffee (Spielkonzept 3.11): eine Tasse wirkt so viele Spielsekunden (= Spielminuten) und überdeckt so viele Nächte
## ohne Schlaf; danach kommt das Tief so lange mit so viel mehr Müdigkeit. Solange er wirkt, zählt Schlaf nur so viel.
## Jede Tasse hebt den Koffeinspiegel um 1, er sinkt um 1 je COFFEE_FADE s – ab COFFEE_JITTER zittert man
## (dritte Tasse kurz hintereinander), das Herz klopft so laut (0..1, SynthAudio.heart)
const COFFEE_TIME := 180.0
const COFFEE_MASK := 1.0
const COFFEE_LOW_TIME := 60.0
const COFFEE_LOW := 0.5
const COFFEE_SLEEP := 0.5
const COFFEE_FADE := 120.0
const COFFEE_JITTER := 2.5
const COFFEE_HEART := 0.4
## Kräutertee (Spielkonzept 3.12): nimmt so viel Schock; so viele Spielsekunden danach schläft man besser – Schlaf zählt
## TEA_SLEEP-fach (30 % mehr) und der Kaffee stört dabei nicht mehr
const TEA_CALM := 0.1
const TEA_TIME := 120.0
const TEA_SLEEP := 1.3
## Zittern der Hand vor Koffein: so weit (m) und so schnell (Hz)
const TREMOR := 0.006
const TREMOR_RATE := 23.0
## Verschwommene Sicht (Spielkonzept 3.6/3.7): so unscharf nach WEAK_NIGHTS Nächten ohne Schlaf (in Schüben
## schwächer), ab diesem Rausch (1. Glas noch klar), bei Kater; so schnell (je Sekunde) folgt die Sicht dem Zustand
const SIGHT_TIRED := 0.7
const SIGHT_DRUNK_FROM := 0.25
const SIGHT_HANGOVER := 0.12
const SIGHT_FADE := 0.5
## Im Sitzen (Spielkonzept 3.1): so weit dreht sich der Blick höchstens zur Seite – 180° nach vorn
const SIT_TURN := PI / 2.0

var head: Node3D
var camera: Camera3D
var held: Item
## Tasche für Kleines (Spielkonzept 3.2): Fach 1 zuerst, höchstens BAG_SLOTS
var bag: Array[Item] = []
## [Q] gehalten: Fächer sind eingeblendet, die Maus wählt statt sich umzusehen
var bag_open := false
## gewähltes Fach (−1 = keins: Loslassen bricht ab)
var bag_sel := -1
var _bag_cursor := 0.0   ## Mausweg seit dem Öffnen in Fächern, 0 = Mitte
var debug_bag_menu := false   ## --bag-menu: als würde [Q] gehalten
var carried_cat: HotelCat   ## Katze auf dem Arm (Spielkonzept 6.11) – solange keine Hand frei für Gegenstände
var crouching := false
var running := false
var dead := false
var killed_by := ""    ## wer ihn geholt hat: „monster“, „ghost“, „pumpkin“ (IconArt.THREATS, Sterbebildschirm)
var hiding: HideSpot
var hide_time := 0.0
var hide_stress := 0.0
var breath := BREATH_MAX
var holding_breath := false
## Schock nach dem Tod eines Freundes (0..1, klingt ab) – Spielkonzept 6.8
var shock := 0.0
var shock_recovery := 1.0   ## schneller durch Gedenken oder Feiern (Social)
var in_dialog := false
## Gebannt (Siegerehrung, Spielkonzept 2.5): keine Steuerung, DoorContest führt den Blick
var spellbound := false
var focused := false   ## sitzt konzentriert am Spieltisch → Vorwarnungen fallen weniger auf
var inspecting := false  ## schaut auf Karte oder Kompass in der linken Hand
var trance := 0.0      ## Hypnose des Lakengeists (0..1) – macht langsamer (Spielkonzept 4.18)
var gripped := false   ## wird gewürgt: steht fest, nur move_input zählt (Losreißen)
var move_input := Vector2.ZERO   ## Bewegungstasten dieses Frames
var sleeping := false  ## schläft im eigenen Bett (liegt dabei als Versteck darin)
## Nachtruhen ohne Schlaf seit dem ersten Angriff – lockt den Lakengeist (Spielkonzept 4.18). Anteilig: Wenig Schlaf
## zählt als Bruchteil einer Nacht, Schlaf baut die Schuld anteilig ab (3.6)
var nights_awake := 0.0
var sleep_hours := SLEEP_HOURS.x   ## so lange will man schlafen – am eigenen Bett mit dem Mausrad (3.6)
var _slept := 0.0      ## seit dem Ende der letzten Nachtruhe geschlafen (Spielsekunden)
var _sleep_now := 0.0  ## in diesem Schlaf geschlafen (Spielsekunden)
var _sleep_lost := 0.0 ## davon nicht erholsam – Kaffee wirkte noch (3.11); negativ: nach Tee erholsamer (3.12)
## Am Körper (Spielkonzept 3.2): Kompass, Kartenblätter (HotelMap.PAGES-IDs), Schlüssel-IDs
var has_compass := false
var map_pages: Array[String] = []
var keyring: Array[String] = []
var debug_show := ""   ## --show=map|keys|compass|aufgaben|notizen|gesehen: als würde die Taste gehalten (keys: Schlüsselblatt oben)
var injury := 0.0      ## von Gästen geschlagen (0..1): langsamer, blutet – heilt mit der Zeit (6.3)
var stamina := 1.0     ## Ausdauer (0..1), nicht sichtbar – nur Herzschlag und Atem verraten sie (3.1)
var winded := false    ## außer Atem: kein Rennen, bis man sich beruhigt hat
var debug_sprint := false   ## --sprint: rennt vorwärts wie mit W + Shift, bis er außer Atem ist
var disguised := false   ## Bettlaken übergeworfen – Gäste erkennen ihn nur aus der Nähe (5.9)
var disguise_count := 0  ## wie oft schon übergeworfen – jeder Gast staunt einmal je Mal (Guest._notice_disguise)
var drunk := 0.0       ## Rausch (0..1) von der Bar – Stufen in BarTap (3.7)
var hangover := 0.0    ## Sekunden Kater nach dem Schlaf im Rausch
var coffee := 0.0      ## so viele Spielsekunden wirkt der Kaffee noch – überdeckt die Müdigkeit (3.11)
var coffee_low := 0.0  ## so viele Spielsekunden noch das Tief danach
var caffeine := 0.0    ## Koffeinspiegel in Tassen – ab COFFEE_JITTER zittert man
var tea := 0.0         ## so viele Spielsekunden schläft man nach einem Tee noch besser (3.12)
var sight_blur := 0.0   ## verschwommene Sicht (0..1) aus Müdigkeit und Rausch – Post-Shader `blur` (3.6/3.7)
var sight_warp := 0.0   ## Wabern und Doppelbild im Rausch (0..1) – Post-Shader `warp`
var seat: Seat          ## sitzt auf diesem Möbel (3.1) – Platz in _seat_spot
## Größe der Figur (Spielkonzept 3.9) – Kapsel, Augenhöhe und Hocken im Verhältnis zu HEIGHT
var body_height := HEIGHT
var eye_height := EYE_HEIGHT
var crouch_height := CROUCH_HEIGHT
var crouch_eye := CROUCH_EYE_HEIGHT
var body: PlayerBody
## zusätzlich verschwommen (0..1) – Erwachen am Waschbecken (CharacterCreation)
var intro_blur := 0.0

var _hand: Node3D
var _left_hand: Node3D
var _pocket_map: PocketMap
var _compass_holder: Node3D
var _compass: Item
var _left_shown := ""   ## "map", "compass" oder ""
var _left_raise := 0.0
var _shape: CapsuleShape3D
var _collider: CollisionShape3D
var _ray: RayCast3D
var _focus = null
var _hang_hint := false   ## Hinweis aufs Aufhängen schon gezeigt
var _bag_hint := false    ## Hinweis auf die Tasche schon gezeigt
var _bag_node: Node3D     ## hier hängen die Gegenstände in der Tasche (unsichtbar)
var _noise_timer := 0.0
var _flame_timer := 1.0   ## bis zum nächsten Wurf, ob die Flamme in der Hand ausgeht (_update_flame_wind)
var _pant_timer := 0.0
var _step_dist := 0.0
var _steps: Footsteps
var _was_on_floor := true
var _bob := 0.0
var _hide_yaw := 0.0
var _hide_pitch := 0.0
var _breath_locked := false
var _crouch_toggled := false
var _dread_time := 0.0
var _shock_drop_timer := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _shove := Vector3.ZERO      ## Stoß von außen (angerempelt, geschlagen), klingt ab
var _kick := 0.0                ## Kamera-Ruck nach Schlag oder Stoß
var _bleed := 0.0
var _blood_dist := 0.0
var _punch_cooldown := 0.0
var _ram_cooldown := 0.0
var _confirm_guest: Guest       ## „Wirklich zuschlagen?“ – zweiter Klick auf denselben Gast
var _confirm_time := 0.0
var _look_lag := Vector2.ZERO   ## im Rausch: Mausbewegung, der die Sicht noch nachzieht
var _drunk_time := 0.0
var _sleep_drunk := 0.0         ## höchster Rausch in diesem Schlaf → Kater
var _seat_spot: Marker3D
var _sit_turn := 0.0            ## Blick gegenüber der Sitzrichtung, höchstens ±SIT_TURN


func _ready() -> void:
	add_to_group("time_skip")   # Zeitsprung im Schlaf (SleepSkip)
	add_to_group("player")
	collision_layer = 8
	# Ebene 4 (Gegenstände, Pflanzen, Schalter) blockiert nicht – lose Dinge werden weggeschoben
	collision_mask = 1 | 2 | 16 | 64 | 128 | 256
	_shape = CapsuleShape3D.new()
	_shape.radius = RADIUS
	_shape.height = body_height
	_collider = CollisionShape3D.new()
	_collider.shape = _shape
	_collider.position.y = body_height / 2.0
	add_child(_collider)
	head = Node3D.new()
	head.position.y = eye_height
	add_child(head)
	_steps = Footsteps.new()
	add_child(_steps)
	camera = Camera3D.new()
	camera.fov = Settings.fov
	Settings.changed.connect(func() -> void: camera.fov = Settings.fov)
	camera.near = 0.03
	camera.far = 70.0   # knapp hinter dem Nebelende (main.gd) – weiter sieht man nichts, auch das Monster nicht
	head.add_child(camera)
	camera.make_current()
	camera.cull_mask = 0xFFFFF & ~PlayerBody.LAYER   # den eigenen Körper nur im Spiegel und als Schatten
	body = PlayerBody.new()
	add_child(body)
	_hand = Node3D.new()
	_hand.position = HAND_REST
	camera.add_child(_hand)
	_left_hand = Node3D.new()
	_left_hand.visible = false
	camera.add_child(_left_hand)
	_pocket_map = PocketMap.new()
	_left_hand.add_child(_pocket_map)
	_compass_holder = Node3D.new()
	_compass_holder.rotation.x = COMPASS_TILT
	_left_hand.add_child(_compass_holder)
	_bag_node = Node3D.new()
	_bag_node.visible = false
	add_child(_bag_node)
	_ray = RayCast3D.new()
	_ray.target_position = Vector3(0, 0, -REACH)
	_ray.collision_mask = 1 | 2 | 4 | 64 | 128 | 256 | HotelWindow.LAYER_BLOCK | HotelCat.LAYER
	_ray.add_exception(self)
	camera.add_child(_ray)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	# Charaktererstellung: man kann sich nicht bewegen (3.9) – Mausbewegung beim Laden drehte sonst den Blick weg
	if dead or in_dialog or spellbound or Game.creating:
		return
	if bag_open:
		_bag_input(event)
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var rel: Vector2 = (event as InputEventMouseMotion).screen_relative * MOUSE_SENSITIVITY * Settings.mouse_sensitivity
		if Settings.invert_y:
			rel.y = -rel.y
		if hiding:
			_hide_yaw = clampf(_hide_yaw - rel.x, -0.45, 0.45)
			_hide_pitch = clampf(_hide_pitch - rel.y, -0.3, 0.3)
			_apply_hide_view()
		elif drunk >= BarTap.TIPSY:
			_look_lag += rel   # die Sicht zieht nach (_process)
		else:
			_look(rel)
	elif event is InputEventMouseButton and event.pressed and _left_shown == "map" and inspecting:
		# Blättern: Linksklick / Mausrad runter = nächstes Blatt, Mausrad hoch = voriges; Rechtsklick = nächstes
		# Lesezeichen des Notizbuchs (3.10) – im Versteck hält Rechtsklick die Luft an, dort reicht das Mausrad
		var button := (event as InputEventMouseButton).button_index
		if button == MOUSE_BUTTON_LEFT or button == MOUSE_BUTTON_WHEEL_DOWN:
			_pocket_map.flip(1)
		elif button == MOUSE_BUTTON_WHEEL_UP:
			_pocket_map.flip(-1)
		elif button == MOUSE_BUTTON_RIGHT and hiding == null:
			_pocket_map.next_bookmark()
	elif event.is_action_pressed("map") or event.is_action_pressed("compass"):
		_explain_left_hand("map" if event.is_action_pressed("map") else "compass")
	elif event is InputEventMouseButton and event.pressed and _wheel_step(event) != 0 and _focus is HideSpot 			and hiding == null and (_focus as HideSpot).can_sleep(self):
		# am eigenen Bett: Mausrad hoch = länger schlafen, runter = kürzer (3.6)
		sleep_hours = clampi(sleep_hours + _wheel_step(event), SLEEP_HOURS.x, SLEEP_HOURS.y)
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("bag") and not gripped:
		open_bag()
	elif _bag_slot_pressed(event) >= 0 and not gripped:
		take_from_bag(_bag_slot_pressed(event))
	elif event.is_action_pressed("interact") and not gripped:
		if hiding:
			exit_hide()
		elif _focus != null and is_instance_valid(_focus):
			_focus.interact(self)
	elif event.is_action_pressed("drop") and not hiding:
		if held == null and disguised:
			take_off_sheet()
		else:
			drop_held()
	elif event.is_action_pressed("use_item") and _punch_target() != null:
		_try_punch(_punch_target())
	elif (event.is_action_pressed("use_item") or event.is_action_pressed("light_mode")) and held and held.has_wick() and not hiding:
		_use_flame()
	elif event.is_action_pressed("light_mode") and _snuff_target() != null:
		_snuff_target().snuff()
	elif event.is_action_pressed("use_item") and held and held.kind == Item.Kind.BED_SHEET and not hiding:
		put_on_sheet()
	elif event.is_action_pressed("use_item") and held and held.kind == Item.Kind.ROAST_PUMPKIN and not hiding:
		eat_held()
	elif event.is_action_pressed("use_item") and held and held.kind == Item.Kind.SODA_CAN and not hiding:
		drink_can()
	elif event.is_action_pressed("use_item") and held and held.kind == Item.Kind.COFFEE and not hiding:
		drink_coffee()
	elif event.is_action_pressed("use_item") and held and held.kind == Item.Kind.TEA and not hiding:
		drink_tea()
	elif event.is_action_pressed("use_item") or event.is_action_pressed("light_mode"):
		_use_flashlight(event.is_action_pressed("light_mode"))


## Mausrad hoch +1, runter −1, sonst 0.
func _wheel_step(event: InputEvent) -> int:
	match (event as InputEventMouseButton).button_index:
		MOUSE_BUTTON_WHEEL_UP: return 1
		MOUSE_BUTTON_WHEEL_DOWN: return -1
	return 0


func _look(rel: Vector2) -> void:
	if seat:
		_sit_turn = clampf(_sit_turn - rel.x, -SIT_TURN, SIT_TURN)
		rotation.y = _seat_spot.global_rotation.y + _sit_turn
	else:
		rotate_y(-rel.x)
	head.rotation.x = clampf(head.rotation.x - rel.y, -1.45, 1.45)


## Im Rausch folgt die Sicht der Maus träge (Spielkonzept 3.7).
func _process(delta: float) -> void:
	if bag_open and (dead or in_dialog or gripped):
		close_bag(false)
	elif bag_open and not Input.is_action_pressed("bag") and not debug_bag_menu:
		close_bag(true)   # [Q] losgelassen
	if _look_lag == Vector2.ZERO:
		return
	if dead or in_dialog or hiding or spellbound:
		_look_lag = Vector2.ZERO
		return
	var step := _look_lag * minf(1.0, delta * lerpf(LOOK_LAG.x, LOOK_LAG.y, BarTap.sway(drunk)))
	_look_lag -= step
	_look(step)
	if _look_lag.length() < 0.0001:
		_look_lag = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if dead:
		if sleeping:
			_stop_sleep()   # im Schlaf geholt
		return
	_update_drunk(delta)
	_update_coffee(delta)
	_update_shock(delta)
	_update_dread(delta)
	_update_hand(delta)
	_update_injury(delta)
	_update_stamina(delta)
	if in_dialog or spellbound or Game.creating:
		velocity = Vector3.ZERO
		running = false
		return
	if hiding:
		running = false
		# Würgen im Schrank: nur die Bewegungstasten zählen (Losreißen)
		move_input = Input.get_vector("move_left", "move_right", "move_forward", "move_back") if gripped else Vector2.ZERO
		_update_hiding(delta)
		return
	if seat:
		running = false
		_update_seated()
		return
	_update_crouch()
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif Input.is_action_just_pressed("jump") and not crouching:
		velocity.y = JUMP_VELOCITY
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if debug_sprint:
		debug_sprint = not winded
		input = Vector2(0, -1) if debug_sprint else Vector2.ZERO
	move_input = input
	if gripped:
		velocity = Vector3.ZERO
		running = false
		return
	var dir := (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	running = (Input.is_action_pressed("run") or debug_sprint) and not crouching and not winded and input.length() > 0.1
	var speed := CROUCH_SPEED if crouching else (RUN_SPEED if running else WALK_SPEED)
	if held:
		speed *= held.carry_speed()   # Großes 0,8, Riesenkürbis langsamer (Item.carry_speed)
	if inspecting:
		speed *= INSPECT_SPEED
	speed *= 1.0 - TRANCE_SLOW * trance
	speed *= 1.0 - INJURY_SLOW * injury
	velocity.x = dir.x * speed + _shove.x
	velocity.z = dir.z * speed + _shove.z
	_shove = _shove.move_toward(Vector3.ZERO, 9.0 * delta)
	var fall_speed := -velocity.y
	move_and_slide()
	if is_on_floor() and not _was_on_floor and fall_speed > LAND_SPEED and Game.director:
		Game.noise("land", global_position, self)
	_was_on_floor = is_on_floor()
	_push_items(dir, speed)
	if running and speed >= RAM_SPEED:
		_check_ram(dir)

	var moving := is_on_floor() and input.length() > 0.1
	if moving:
		_bob += delta * speed * 2.4
	_update_flame_wind(delta, moving)
	_drunk_walk(moving, delta)
	var eye := crouch_eye if crouching else eye_height
	var bob := sin(_bob) * 0.03 if moving else 0.0
	head.position.y = lerpf(head.position.y, eye + bob, minf(1.0, 12.0 * delta))

	# Rennen macht Lärm, Gehen nur auf Holz und Fliesen, geduckt ist man still (4.15)
	if running and moving:
		_noise_timer -= delta
		if _noise_timer <= 0.0:
			_noise_timer = 0.6
			if Game.director:
				Game.noise("run", global_position, self)
	# Schritte: auf Teppich zu hören (Footsteps), Lärm nur beim Gehen auf hartem Boden (4.15)
	if moving and (running or not crouching):
		_step_dist += speed * delta
		if _step_dist >= (RUN_STEP_LENGTH if running else STEP_LENGTH):
			_step_dist = 0.0
			var ground := Footsteps.floor_under(self)
			_steps.step(ground, running)
			if not running and Game.director and ground != "air" and not ground in SOFT_FLOORS:
				Game.noise("step", global_position, self)
	_update_focus()


## Linke Hand: Karte bzw. Notizbuch (Tab, 3.10) oder Kompass (F) halten hebt sie vor die Augen. Mit einem großen
## Gegenstand sind beide Hände voll; im Gespräch geht es nicht. Das Spiel läuft dabei weiter.
func _update_hand(delta: float) -> void:
	var want := ""
	if not in_dialog:
		if (Input.is_action_pressed("map") or debug_show in ["map", "keys", "aufgaben", "notizen", "gesehen"]) and _can_show("map"):
			want = "map"
		elif (Input.is_action_pressed("compass") or debug_show == "compass") and _can_show("compass"):
			want = "compass"
	if want != "" and want != _left_shown:
		_left_shown = want
		_left_raise = 0.0
		if want == "map":
			_pocket_map.open_at(PocketMap.KEYS if debug_show == "keys" else HotelMap.page_at(global_position.y))
			if debug_show in ["aufgaben", "notizen", "gesehen"]:
				_pocket_map.open_bookmark({"aufgaben": "tasks", "notizen": "notes", "gesehen": "threats"}[debug_show])
			Game.noise("map", global_position, self)
	inspecting = want != ""
	_left_raise = move_toward(_left_raise, 1.0 if inspecting else 0.0, delta * 5.0)
	if _left_raise <= 0.0:
		_left_shown = ""
	var view := MAP_VIEW if _left_shown == "map" else COMPASS_VIEW
	var t := ease(_left_raise, -2.0)
	_left_hand.position = (view + LEFT_DOWN).lerp(view, t)
	_left_hand.rotation.x = -0.9 * (1.0 - t)
	_left_hand.visible = _left_shown != ""
	_pocket_map.visible = _left_shown == "map"
	_compass_holder.visible = _left_shown == "compass"
	_hand.position = _hand.position.lerp(HAND_REST, minf(1.0, 10.0 * delta))
	if jittery():   # zu viel Kaffee (3.11): die Hand bebt
		var shake := _drunk_time * TREMOR_RATE
		_hand.position += Vector3(sin(shake * 1.3), sin(shake * 1.7 + 1.0), 0.0) * TREMOR


func _can_show(what: String) -> bool:
	if hands_blocked():
		return false
	if what == "map":
		return not map_pages.is_empty() or not keyring.is_empty() or (Game.notebook != null and Game.notebook.owned)
	return has_compass


## Taste gedrückt, aber nichts zu sehen: kurz sagen, warum
func _explain_left_hand(what: String) -> void:
	if in_dialog or _can_show(what):
		return
	if hands_blocked():
		Game.say("Die Hände sind voll.")
	elif what == "map":
		Game.say("Du hast keine Karte.")
	else:
		Game.say("Du hast keinen Kompass.")


## Kerze (Kürbis, Totenkopf mit Kerze) in der Hand, Linksklick oder R (Spielkonzept 5.12): brennt sie, auspusten;
## sonst mit der Streichholzschachtel aus der Tasche anzünden.
func _use_flame() -> void:
	if held.lit:
		held.snuff()
	elif has_matches():
		held.light_up()
		Game.say("Du zündest sie mit einem Streichholz an.", 2.0)
	else:
		Game.say("Du hast nichts, um sie anzuzünden.", 2.0)
	if Game.hud:
		Game.hud.set_held(held.display_name)


## Streichholzschachtel dabei – in der Tasche oder in der Hand?
func has_matches() -> bool:
	if held and held.kind == Item.Kind.MATCHBOX:
		return true
	return bag.any(func(item: Item) -> bool: return item.kind == Item.Kind.MATCHBOX)


## Flamme in der Welt, auf die man blickt und die [R] auspusten kann (Item oder FixedCandle) – nicht mit der
## Taschenlampe in der Hand (R schaltet dort UV).
func _snuff_target() -> Object:
	if hiding or (held and held.flashlight) or not is_instance_valid(_focus):
		return null
	if (_focus is Item and not (_focus as Item).is_held and (_focus as Item).lit) or (_focus is FixedCandle and (_focus as FixedCandle).lit):
		return _focus
	return null


## Brennendes in der Hand geht in der Bewegung manchmal aus (Spielkonzept 5.12): je Sekunde gewürfelt, beim Rennen im
## Haus und draußen; Regen draußen macht es wahrscheinlicher, Kürbis und Totenkopf schützen die Flamme.
func _update_flame_wind(delta: float, moving: bool) -> void:
	if held == null or not held.lit or not moving:
		return
	_flame_timer -= delta
	if _flame_timer > 0.0:
		return
	_flame_timer = 1.0
	var outside := RainVeil.is_outdoor(global_position)
	var chance := 0.0
	if outside:
		chance = Item.FLAME_OUT_OUTSIDE_RUN if running else Item.FLAME_OUT_OUTSIDE
		if Game.weather:
			chance *= 1.0 + Item.FLAME_WEATHER * Game.weather.intensity
	elif running:
		chance = Item.FLAME_OUT_RUN
	if held.kind in Item.CANDLE_HOLDERS:
		chance *= Item.FLAME_SHELTER
	if randf() < chance:
		if Game.tracing:
			print("[Kerze] geht in der Hand aus (%s, %s)" % ["draußen" if outside else "drinnen", "rennt" if running else "geht"])
		held._extinguish()
		Game.say("Der Luftzug löscht die Flamme." if not outside else "Der Wind bläst die Flamme aus.", 2.0)
		if Game.hud:
			Game.hud.set_held(held.display_name)


## Taschenlampe in der Hand bedienen. Im Versteck bleibt sie aus – das Licht würde einen verraten.
func _use_flashlight(mode: bool) -> void:
	if held == null or held.flashlight == null:
		return
	if hiding:
		Game.say("Nicht hier drin – das Licht würde dich verraten.")
		return
	if mode:
		held.flashlight.switch_mode()
	else:
		held.flashlight.toggle()


# --- Am Körper: Kompass, Kartenblätter, Schlüsselbund (Spielkonzept 3.2) ------------------

## Gegenstand aus der Welt an den Körper nehmen – er verschwindet aus der Welt.
func _pocket(item: Item) -> void:
	match item.kind:
		Item.Kind.COMPASS:
			give_compass()
			Game.say("Ein alter Kompass – eingesteckt. [F] halten, um draufzuschauen.", 3.5)
			Game.play_sound("blip", 0.5)
		Item.Kind.MAP:
			var first := map_pages.is_empty()
			add_map_page(item.page_id)
			if first:
				Game.say("%s – eingesteckt. [Tab] halten zum Ansehen, [Linksklick] blättert." % item.display_name, 4.0)
			elif Game.notebook and Game.notebook.owned:
				Game.say("%s – ins Notizbuch gelegt." % item.display_name, 3.0)
			else:
				Game.say("%s – zu den anderen Blättern gesteckt." % item.display_name, 3.0)
			Game.noise("map", global_position, self)
		Item.Kind.KEY:
			add_key(item.key_id)
			Game.say("%s – an den Schlüsselbund." % item.display_name, 3.0)
			Game.noise("keys", global_position, self)
	item.queue_free()


func give_compass() -> void:
	has_compass = true
	if _compass:
		return
	_compass = Item.create(Item.Kind.COMPASS)
	_compass_holder.add_child(_compass)
	_compass.make_pocketed()
	_compass.rotation = Vector3(0, PI, 0)


func add_map_page(id: String) -> void:
	if not id in map_pages:
		map_pages.append(id)
	_pocket_map.set_content(map_pages, keyring)


func add_key(id: String) -> void:
	if not id in keyring:
		keyring.append(id)
	_pocket_map.set_content(map_pages, keyring)


## Spielstand: alles am Körper neu setzen
func set_pockets(compass: bool, pages: Array, keys: Array) -> void:
	has_compass = false
	if _compass:
		_compass.queue_free()
		_compass = null
	if compass:
		give_compass()
	map_pages.assign(pages)
	keyring.assign(keys)
	_pocket_map.set_content(map_pages, keyring)


## Passt ein Schlüssel – am Bund oder (Ausgangsschlüssel) in der Hand?
func has_key(id: String) -> bool:
	return id != "" and (id in keyring or held_key_id() == id)


# --- Am Spieltisch sitzen -------------------------------------------------------

func sit_at(at: Vector3, look: Vector3) -> void:
	if hiding:
		exit_hide()
	leave_seat(true)
	in_dialog = true
	focused = true
	_collider.disabled = true
	velocity = Vector3.ZERO
	global_position = at
	var to := look - at
	rotation = Vector3(0, atan2(-to.x, -to.z), 0)
	head.position.y = 1.2
	head.rotation.x = -0.55
	if Game.hud:
		Game.hud.set_prompt("")


func stand_up() -> void:
	in_dialog = false
	focused = false
	global_position += transform.basis.z * 0.5
	_collider.disabled = false
	head.position.y = eye_height
	head.rotation.x = 0.0


# --- Auf Sitzmöbel setzen (Spielkonzept 3.1) -----------------------------------------

## Auf einen festen Platz setzen: Blick in Sitzrichtung, höchstens SIT_TURN zur Seite. Großes stellt man ab.
func sit_down(s: Seat, spot: Marker3D) -> void:
	if hiding:
		exit_hide()
	leave_seat(true)
	if held and held.is_large:
		Game.say("Du stellst %s ab." % held.display_name, 2.0)
		drop_held()
	set_crouching(false)
	seat = s
	_seat_spot = spot
	_collider.disabled = true
	velocity = Vector3.ZERO
	_shove = Vector3.ZERO
	global_position = spot.global_position
	_sit_turn = 0.0
	rotation = Vector3(0, spot.global_rotation.y, 0)
	head.position.y = s.top + Seat.EYE_ABOVE
	head.rotation.x = 0.0
	if Game.tracing:
		print("[Sitzen] %s, Platz %d bei %s, Blick %s" % [s.kind, s.spots.find(spot), spot.global_position.snapped(Vector3.ONE * 0.1),
			(-spot.global_basis.z).snapped(Vector3.ONE * 0.1)])


## Im Sitzen: Leertaste oder eine Bewegungstaste steht auf, Würgen reißt hoch. [E] bleibt für Dinge in Reichweite.
func _update_seated() -> void:
	velocity = Vector3.ZERO
	move_input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if gripped or Input.is_action_just_pressed("jump") or move_input.length() > 0.1:
		leave_seat(gripped)
		return
	_update_focus()


## Aufstehen: vor den Platz, sonst daneben oder dahinter. Ist nirgends Platz, bleibt man sitzen (false) – außer
## mit `force` (Stoß, Würgen, Versetzen), dann steht man vor dem Platz.
func leave_seat(force: bool = false) -> bool:
	if seat == null:
		return true
	var at := stand_position()
	if at == Vector3.INF:
		if not force:
			Game.say("Hier ist kein Platz zum Aufstehen.", 2.0)
			return false
		at = _seat_spot.global_position - _seat_spot.global_basis.z * seat.stand_out
	seat = null
	_seat_spot = null
	global_position = at
	_collider.disabled = false
	head.position.y = eye_height
	return true


## Wo man beim Aufstehen stünde (INF = kein Platz); stehend die eigene Lage – so speichert der Spielstand.
## Sucht vor dem Platz, dann schräg, seitlich und dahinter, jeweils etwas weiter weg – nie durch eine Wand.
func stand_position() -> Vector3:
	if seat == null:
		return global_position
	var base := _seat_spot.global_position
	var fwd := -_seat_spot.global_basis.z
	var space := get_world_3d().direct_space_state
	for step in 3:
		var dist := seat.stand_out + 0.3 * step
		for turn: float in [0.0, 0.25, -0.25, 0.5, -0.5, 0.75, -0.75, 1.0]:
			var at := base + fwd.rotated(Vector3.UP, turn * PI) * dist
			if not _can_stand(at):
				continue
			var look := PhysicsRayQueryParameters3D.create(base + Vector3.UP * 1.4, at + Vector3.UP * 1.4, 1, [get_rid()])
			if space.intersect_ray(look).is_empty():
				return at
	return Vector3.INF


## Ziel des Blicks (Strahl in Reichweite), sonst die eigene Lage – Sitzmöbel wählen den nächsten Platz dazu.
func aim_point() -> Vector3:
	return _ray.get_collision_point() if _ray.is_colliding() else global_position


# --- Angst: engerer Blick, schwerer Atem (Spielkonzept 4.13) ---------------------------

func _update_dread(delta: float) -> void:
	var threat := Game.director.player_threat if Game.director else 0.0
	camera.fov = lerpf(camera.fov, Settings.fov - 10.0 * threat, minf(1.0, 2.0 * delta))
	_dread_time += delta * (1.5 + threat * 1.5)
	camera.position.y = sin(_dread_time) * 0.012 * threat


# --- Schock (Spielkonzept 6.8) -------------------------------------------------

func add_shock(amount: float, guilt: bool) -> void:
	shock = clampf(shock + amount, 0.0, 1.0)
	_shock_drop_timer = 8.0
	if guilt:
		Game.say("Das war deine Schuld …", 4.0)


func _update_shock(delta: float) -> void:
	if shock <= 0.0:
		camera.rotation = Vector3.ZERO
		return
	shock = maxf(0.0, shock - delta / 180.0 * shock_recovery)
	# Zittern
	camera.rotation = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * shock * 0.008
	# Zittrige Hände: ab und zu fällt etwas herunter
	_shock_drop_timer -= delta
	if _shock_drop_timer <= 0.0:
		_shock_drop_timer = 12.0
		if held and not hiding and randf() < shock * 0.35:
			Game.say("Deine Hände zittern – %s fällt dir herunter." % held.display_name)
			drop_held(true)


# --- Schlagen, Rammen, Verletzungen (Spielkonzept 6.3) ------------------------------

## Ein Gast in Armlänge vor dir – und keine Taschenlampe in der Hand (die schaltet der Linksklick).
func _punch_target() -> Guest:
	if hiding or gripped or sleeping or (held and held.flashlight) or _punch_cooldown > 0.0:
		return null
	if not is_instance_valid(_focus):   # vor dem Cast – einen freigegebenen Gast kann man nicht casten
		return null
	var guest := _focus as Guest
	if guest == null or guest.dead or guest.hiding \
			or guest.state == Guest.State.GHOSTED or guest.global_position.distance_to(global_position) > PUNCH_REACH:
		return null
	return guest


## Erster Klick fragt nach (außer bei Gästen, mit denen du ohnehin im Streit liegst), der zweite schlägt.
func _try_punch(guest: Guest) -> void:
	if guest.is_child():
		Game.say("Ein Kind schlägt man nicht.", 2.5)   # Spielkonzept 6.13
		_punch_cooldown = 0.7
		return
	var fighting := Social.tier(guest) <= Social.Tier.ANGRY
	if not fighting and (_confirm_guest != guest or _confirm_time <= 0.0):
		_confirm_guest = guest
		_confirm_time = PUNCH_CONFIRM_TIME
		Game.say("Wirklich %s schlagen? [Linksklick]" % guest.display_name, PUNCH_CONFIRM_TIME)
		return
	_confirm_guest = null
	_punch_cooldown = 0.7
	_hand.position = HAND_REST + Vector3(-0.08, 0.08, -0.35)   # Faust nach vorn, federt zurück
	_kick = 0.04
	Game.play_sound("thud", 0.9)
	var dir := guest.global_position - global_position
	dir.y = 0.0
	Game.social.on_player_punched(guest, dir.normalized())


## Für --punch: wie ein Linksklick auf den Gast.
func debug_punch(guest: Guest) -> void:
	_punch_cooldown = 0.0
	_try_punch(guest)


## Im Rennen in einen Gast: Er stolpert, du wirst gebremst.
func _check_ram(dir: Vector3) -> void:
	if _ram_cooldown > 0.0 or Game.social == null:
		return
	for guest in Game.social.living_guests():
		var g: Guest = guest
		if g.hiding or g.state in [Guest.State.STAGGER, Guest.State.SLEEP, Guest.State.GHOSTED]:
			continue
		var to := g.global_position - global_position
		if absf(to.y) > 1.0:
			continue
		to.y = 0.0
		if to.length() < RAM_REACH and to.normalized().dot(dir) > 0.5:
			_ram_cooldown = 1.5
			_shove = -dir * 1.5
			_kick = 0.03
			Game.play_sound("thud", 0.7)
			Game.social.on_player_rammed(g, dir)
			return


## Von außen gestoßen (angerempelt, geschlagen).
func shove(push: Vector3) -> void:
	leave_seat(true)   # reißt einen vom Sitz hoch
	_shove = Vector3(push.x, 0.0, push.z)
	_kick = maxf(_kick, 0.03)


## Ein Gast schlägt dich: roter Blitz, Rückstoß, du blutest und wirst langsamer. Töten kann er dich nicht.
func hurt(amount: float, from: Vector3) -> void:
	if dead:
		return
	injury = minf(1.0, injury + amount)
	_bleed = BLEED_TIME
	var away := global_position - from
	away.y = 0.0
	shove(away.normalized() * 4.0)
	_kick = 0.07
	Game.play_sound("thud", 1.0)
	if Game.hud:
		Game.hud.flash_hurt(amount)


# --- Verkleiden (Spielkonzept 5.9) ---------------------------------------------------

## Bettlaken aus der Hand überwerfen: Man sieht nur noch durch die Augenlöcher, Gäste erkennen einen nur aus
## der Nähe (recognized_by) – als Zeugen beim Klauen, beim Rempeln, beim Anschließen.
func put_on_sheet() -> void:
	consume_held()
	set_disguised(true)
	Game.say("Du wirfst dir das Laken über. Wer bist du jetzt? ([G] mit leeren Händen: abnehmen)", 4.0)


## Abnehmen: Das Laken kommt zurück in die Hand.
func take_off_sheet() -> void:
	set_disguised(false)
	receive_item(Item.create(Item.Kind.BED_SHEET))


func set_disguised(value: bool) -> void:
	if value and not disguised:
		disguise_count += 1
	disguised = value
	if Game.hud:
		Game.hud.set_disguised(value)


## Aussehen aus der Charaktererstellung (Spielkonzept 3.9): Figur neu bauen, Kapsel und Augenhöhe auf die Größe.
func set_look(look: Dictionary) -> void:
	body.apply(look)
	var k := float(body.look["height"]) / HEIGHT
	body_height = HEIGHT * k
	eye_height = EYE_HEIGHT * k
	crouch_height = CROUCH_HEIGHT * k
	crouch_eye = CROUCH_EYE_HEIGHT * k
	_set_crouch(crouching)
	if hiding == null and seat == null:
		head.position.y = crouch_eye if crouching else eye_height


## Erkennt dieser Gast den Spieler? Verkleidet nur aus RECOGNIZE_RANGE.
func recognized_by(guest: Node3D) -> bool:
	return not disguised or guest.global_position.distance_to(global_position) < RECOGNIZE_RANGE


# --- Rausch & Schwäche (Spielkonzept 3.7, 4.18) ---------------------------------------

## Ein Glas an der Bar: nimmt Schock, macht betrunken. quiet: ohne Gedanken (im Gespräch, Runde ausgeben).
func drink(quiet: bool = false) -> void:
	drunk = minf(1.0, drunk + BarTap.DRINK)
	shock = maxf(0.0, shock - BarTap.CALM)
	if not quiet:
		if drunk >= BarTap.DRUNK:
			Game.say("Noch eins … Warum dreht sich die Bar?", 3.0)
		elif drunk >= BarTap.TIPSY:
			Game.say("Die Theke schwankt ein bisschen.", 3.0)
		else:
			Game.say("Das wärmt.", 2.5)
	if Game.tracing:
		print("[Bar] Glas getrunken – Rausch %.2f, Schwäche %.2f" % [drunk, weakness()])


## Wie angreifbar der Spieler gerade ist (0..1) – danach sucht sich der Lakengeist seine Opfer (4.18):
## Schlafmangel (wie er sich anfühlt, tiredness), Rausch, Schock, frische Trauer und Kater zählen zusammen.
func weakness() -> float:
	var grief := 0.0
	if Game.director:
		grief = clampf(Game.director.grief / MonsterDirector.GRIEF_TIME, 0.0, 1.0)
	return clampf(tiredness() / WEAK_NIGHTS + drunk * WEAK_DRUNK + shock * WEAK_SHOCK + grief * WEAK_GRIEF
		+ (WEAK_HANGOVER if hangover > 0.0 else 0.0), 0.0, 1.0)


func _update_drunk(delta: float) -> void:
	drunk = maxf(0.0, drunk - delta / BarTap.SOBER_TIME)
	hangover = maxf(0.0, hangover - delta)
	if sleeping:
		_sleep_drunk = maxf(_sleep_drunk, drunk)
	_drunk_time += delta
	_update_sight(delta)


## Nächte ohne Schlaf, wie sie sich gerade anfühlen (Spielkonzept 3.11) – für Schwäche und Sicht: Kaffee überdeckt
## COFFEE_MASK davon, das Tief danach legt COFFEE_LOW drauf. Die Schuld selbst (nights_awake) bleibt.
func tiredness() -> float:
	if coffee > 0.0:
		return maxf(0.0, nights_awake - COFFEE_MASK)
	return nights_awake + (COFFEE_LOW if coffee_low > 0.0 else 0.0)


## Zu viel Kaffee (3.11): die Hand zittert, das Herz klopft, beim Bluffen verrät es einen.
func jittery() -> bool:
	return caffeine >= COFFEE_JITTER


## Kaffee baut sich ab; lässt er wach nach, kommt das Tief (wer schläft, verschläft es).
func _update_coffee(delta: float) -> void:
	caffeine = maxf(0.0, caffeine - delta / COFFEE_FADE)
	coffee_low = maxf(0.0, coffee_low - delta)
	tea = maxf(0.0, tea - delta)
	if coffee <= 0.0:
		return
	coffee = maxf(0.0, coffee - delta)
	if coffee > 0.0 or sleeping:
		return
	coffee_low = COFFEE_LOW_TIME
	Game.say("Der Kaffee lässt nach. Die Müdigkeit kommt zurück – schwerer als vorher.", 3.5)
	if Game.tracing:
		print("[Kaffee] Wirkung vorbei – Tief, Müdigkeit %.2f" % tiredness())


## Tasse Kaffee trinken (Spielkonzept 3.11): überdeckt die Müdigkeit COFFEE_TIME lang (jede weitere Tasse verlängert
## nur) und beendet ein Tief; ab der dritten kurz hintereinander zittert man.
func drink_coffee() -> void:
	consume_held()
	var tired := nights_awake >= 0.5 or coffee_low > 0.0
	coffee = COFFEE_TIME
	coffee_low = 0.0
	caffeine += 1.0
	if jittery():
		Game.say("Das Herz rast, die Hände zittern. Das war eine Tasse zu viel.", 3.5)
	elif tired:
		Game.say("Heiß und bitter. Die Augen gehen wieder auf.", 3.0)
	else:
		Game.say("Heiß und bitter. Schmeckt nach Hotel.", 3.0)
	if Game.tracing:
		print("[Kaffee] getrunken – Koffein %.1f, Müdigkeit fühlt sich an wie %.2f statt %.2f Nächte" % [caffeine, tiredness(), nights_awake])


## Tasse Kräutertee trinken (Spielkonzept 3.12): etwas weniger Schock, und TEA_TIME lang schläft man besser.
func drink_tea() -> void:
	consume_held()
	shock = maxf(0.0, shock - TEA_CALM)
	tea = TEA_TIME
	if coffee > 0.0:
		Game.say("Kräutertee nach dem Kaffee. Vielleicht kann ich jetzt trotzdem schlafen.", 3.0)
	else:
		Game.say("Warmer Kräutertee. Die Schultern werden locker.", 3.0)
	if Game.tracing:
		print("[Tee] getrunken – Schock %.2f, schläft %.0f s lang besser" % [shock, tea])


## So viel von dt Schlaf erholt: nach einem Tee TEA_SLEEP (3.12, auch mit Kaffee), sonst solange der Kaffee wirkt nur
## COFFEE_SLEEP (3.11) – vor dem Abbau von Tee und Kaffee rechnen.
func _sleep_credit(dt: float) -> float:
	var calm := minf(dt, tea)
	var rest := dt - calm
	var awake := minf(rest, maxf(0.0, coffee - calm))
	return calm * TEA_SLEEP + awake * COFFEE_SLEEP + (rest - awake)


## Verschwommene Sicht (Spielkonzept 3.6/3.7): je Nacht ohne Schlaf unschärfer, in Schüben, als fielen die Augen
## zu; im Rausch angetrunken leicht, betrunken deutlich, pulsierend, dazu Wabern und Doppelbild; Kater ein Hauch.
func _update_sight(delta: float) -> void:
	var t := _drunk_time
	var tired := clampf(tiredness() / WEAK_NIGHTS, 0.0, 1.0) * SIGHT_TIRED
	tired *= 0.55 + 0.45 * pow(0.5 + 0.5 * sin(t * 0.45), 4.0) + 0.05 * sin(t * 1.7)
	var tipsy := pow(clampf((drunk - SIGHT_DRUNK_FROM) / (BarTap.ENOUGH - SIGHT_DRUNK_FROM), 0.0, 1.0), 1.5)
	tipsy *= 0.75 + 0.25 * sin(t * 0.9)
	var sore := (SIGHT_HANGOVER * (0.7 + 0.3 * sin(t * 0.6))) if hangover > 0.0 else 0.0
	sight_blur = move_toward(sight_blur, clampf(tired + tipsy + sore, 0.0, 1.0), delta * SIGHT_FADE)
	sight_warp = move_toward(sight_warp, BarTap.sway(drunk), delta * SIGHT_FADE)


## Im Rausch: der Blick schwankt und driftet, beim Gehen stolpert man manchmal – das hört man (4.15).
func _drunk_walk(moving: bool, delta: float) -> void:
	var sway := BarTap.sway(drunk)
	if sway <= 0.0:
		return
	rotate_y(sin(_drunk_time * 0.7) * 0.25 * sway * delta)
	if moving and randf() < delta * STUMBLE_RATE * sway:
		var side := transform.basis.x * (1.0 if randf() < 0.5 else -1.0)
		shove(side * randf_range(1.5, 2.5))
		_kick = maxf(_kick, 0.05)
		Game.caption("[Du stolperst]")
		if Game.director:
			Game.noise("stumble", global_position, self)


## Seitliches Schwanken des Kopfes im Rausch (nicht im Versteck oder Gespräch).
func _drunk_roll() -> float:
	if hiding or in_dialog:
		return 0.0
	return sin(_drunk_time * 1.1) * 0.05 * BarTap.sway(drunk)


func _update_injury(delta: float) -> void:
	_punch_cooldown -= delta
	_ram_cooldown -= delta
	_confirm_time -= delta
	injury = maxf(0.0, injury - delta / INJURY_HEAL_TIME)
	_kick = move_toward(_kick, 0.0, delta * 0.25)
	head.rotation.z = sin(_drunk_time * 30.0) * _kick + _drunk_roll()   # Spielzeit, nicht Systemzeit
	# Blutstropfen beim Gehen – eine Spur, der man folgen kann (4.13)
	_bleed = maxf(0.0, _bleed - delta)
	if _bleed > 0.0 and is_on_floor() and Game.traces:
		_blood_dist += Vector2(velocity.x, velocity.z).length() * delta
		if _blood_dist > 1.2:
			_blood_dist = 0.0
			Game.traces.add_guest_drop("drops", global_position + Vector3(randf_range(-0.15, 0.15), 0, randf_range(-0.15, 0.15)))


# --- Ausdauer (Spielkonzept 3.1) ---------------------------------------------------

## Rennen (aus dem letzten Frame) leert die Ausdauer, sonst kommt sie wieder – im Stehen, Sitzen und
## Versteck schneller als beim Gehen. Leer → außer Atem, bis sie wieder bei STAMINA_CALM ist.
func _update_stamina(delta: float) -> void:
	# Lautes Keuchen ist Lärm – auch im Versteck, außer man hält die Luft an
	_pant_timer -= delta
	if is_panting() and _pant_timer <= 0.0:
		_pant_timer = PANT_EVERY
		Game.noise("pant", global_position, self)
	if running:
		stamina = maxf(0.0, stamina - delta / STAMINA_RUN_TIME * (HANGOVER_DRAIN if hangover > 0.0 else 1.0))
		if stamina <= 0.0 and not winded:
			winded = true
			Game.caption("[Du keuchst]")
			if Game.tracing:
				print("[Ausdauer] außer Atem")
		return
	var moving := Vector2(velocity.x, velocity.z).length() > 0.5
	stamina = minf(1.0, stamina + delta / STAMINA_REST_TIME * (STAMINA_WALK_SLOW if moving else 1.0))
	if winded and stamina >= STAMINA_CALM:
		winded = false
		if Game.tracing:
			print("[Ausdauer] beruhigt – Rennen geht wieder")


## Wie laut Herz und Atem sind (0..1): außer Atem voll, klingt bis zum Beruhigen ab; beim Rennen mit
## wenig Ausdauer schon leise – die einzige Warnung, denn eine Anzeige gibt es nicht.
func exertion() -> float:
	if winded:
		return 1.0 - stamina / STAMINA_CALM
	return 0.4 * clampf(1.0 - stamina / STAMINA_HINT, 0.0, 1.0)


## Keucht er hörbar – für Monster und Lakengeist? (Luft anhalten bringt es zum Schweigen)
func is_panting() -> bool:
	return exertion() >= PANT_NOISE_FROM and not holding_breath and not sleeping


# --- Gegenstände -----------------------------------------------------------

func try_pick_up(item: Item) -> void:
	if item.kind == Item.Kind.COINS:
		Game.money += item.coin_value
		Game.say("+%d Geld" % item.coin_value, 2.0)
		Game.play_sound("blip")
		item.queue_free()
		return
	var into_bag := (held != null or carried_cat != null) and bag_takes(item)
	if held and not item.goes_to_pocket() and not into_bag:
		if item.fits_pocket() and not hands_blocked() and bag.size() >= BAG_SLOTS:
			Game.say("Hand und Tasche sind voll.")
		else:
			Game.say("Du hast schon etwas in der Hand. Erst ablegen [G].")
		return
	if carried_cat and not item.goes_to_pocket():
		Game.say("Erst %s absetzen [G]." % carried_cat.display_name)
		return
	if item.owner_id != "" and item.owner_id != "player" and Game.social:
		Game.social.on_player_took(item)
	if item.goes_to_pocket():
		_pocket(item)
		return
	if into_bag:
		bag_add(item)
		Game.say("%s – eingesteckt." % item.display_name, 2.0)
		Game.noise("bag", global_position, self)
		return
	item.owner_id = "player"
	_hold(item)
	Game.play_sound("blip", 0.5)
	if item.fits_pocket() and not _bag_hint:
		_bag_hint = true
		Game.say("%s – passt in die Tasche: [Q] halten und ein leeres Fach wählen steckt es ein" % item.display_name, 4.0)
	elif item.flashlight:
		Game.say("%s – [Linksklick] an/aus%s" % [item.display_name, ", [R] UV" if item.flashlight.has_uv else ""], 3.0)
	elif item.can_hang() and not _hang_hint:
		_hang_hint = true
		Game.say("%s – auf eine Wand sehen und [G] zum Aufhängen" % item.display_name, 3.5)


## In die rechte Hand nehmen (aufgehoben oder aus der Tasche).
func _hold(item: Item) -> void:
	held = item
	item.set_held(true)
	item.reparent(_hand, false)
	item.position = item.hold_offset()
	item.rotation = Vector3(0, PI, 0)
	if Game.hud:
		Game.hud.set_held(item.display_name)


## `shocked`: vor Schreck fallen gelassen – lauter (6.8, 4.15). `hang`: Deko vor einer Wand hängt man auf.
func drop_held(shocked: bool = false, hang: bool = true) -> void:
	if held == null and carried_cat:
		carried_cat.put_down()
		return
	if held == null:
		return
	var item := held
	var spot := {} if shocked or not hang else _hang_spot()
	if not spot.is_empty():
		# An die Wand hängen statt ablegen (Spielkonzept 5.6)
		held = null
		item.reparent(get_parent(), false)
		item.hang(spot["point"], spot["out"], float(spot.get("length", 0.0)))
		Game.noise("drop", item.global_position, self)
		if Game.pumpkin:
			Game.pumpkin.on_deco_placed()   # Deko platzieren macht kurz Spaß (4.19)
		if Game.hud:
			Game.hud.set_held("")
		return
	held = null
	var place := _drop_position()
	item.reparent(get_parent(), false)
	item.global_position = place
	item.rotation = Vector3(0, rotation.y, 0)
	item.set_held(false)
	item.linear_velocity = Vector3.ZERO
	var heavy := item.is_large or item.kind in [Item.Kind.PUMPKIN, Item.Kind.CARVED_PUMPKIN]
	Game.noise("shock_drop" if shocked else ("drop_heavy" if heavy else "drop"), place, self)
	if not shocked and item.deco_strength > 0.0 and Game.pumpkin:
		Game.pumpkin.on_deco_placed()   # Deko platzieren macht kurz Spaß (4.19)
	if Game.hud:
		Game.hud.set_held("")


## Neuer Gegenstand direkt in die Hand (Ernte, Vorrat, Kauf, Geschenk).
func receive_item(item: Item) -> bool:
	if item == null:
		return false
	get_parent().add_child(item)
	item.global_position = global_position + Vector3.UP
	if (held or carried_cat) and not item.goes_to_pocket() and not bag_takes(item):
		Game.say("Die Hände sind voll – %s liegt jetzt vor dir." % item.display_name)
		item.global_position = _drop_position()
		return false
	try_pick_up(item)
	return true


## Gebratenen Kürbis essen (Spielkonzept 3.8): Schock sinkt.
func eat_held() -> void:
	shock = maxf(0.0, shock - EAT_CALM)
	consume_held()
	Game.say("Warm, süß und ein bisschen rauchig. Das tut gut.", 3.0)


## Getränkedose trinken (Spielkonzept 3.1, 3.2): wieder ganz bei Atem und etwas ruhiger – das Zischen hört man.
func drink_can() -> void:
	var cola := held.flavor == "cola"
	consume_held()
	stamina = 1.0
	winded = false
	shock = maxf(0.0, shock - CAN_CALM)
	Game.noise("can", global_position, self)
	Game.say("Zisch. Eiskalte Cola – der Atem geht wieder ruhig." if cola else "Zisch. Süße, kalte Limo – der Atem geht wieder ruhig.", 3.0)


## Gegenstand aus der Hand geben (Geschenk, das der Gast selbst trägt – Spielkonzept 6.17). null = leere Hände.
func hand_over() -> Item:
	var item := held
	held = null
	if Game.hud:
		Game.hud.set_held("")
	return item


## Gegenstand in der Hand wird verbraucht (z. B. Kerze in den Kürbis).
func consume_held() -> void:
	if held == null:
		return
	held.queue_free()
	held = null
	if Game.hud:
		Game.hud.set_held("")


# --- Tasche für Kleines (Spielkonzept 3.2) ----------------------------------------------

## Passt dieser Gegenstand noch in die Tasche? Mit einem großen Ding oder einer Katze im Arm kommt man nicht heran.
func bag_takes(item: Item) -> bool:
	return item.fits_pocket() and carried_cat == null and not hands_blocked() and bag.size() < BAG_SLOTS


## Kann er einen neuen Gegenstand dieser Art annehmen – in die freie Hand oder in die Tasche? (Neue Kerzen brennen nicht
## und passen deshalb auch in die Tasche, Spielkonzept 5.12.)
func can_take(kind: int) -> bool:
	if carried_cat:
		return false
	return held == null or (kind in Item.POCKET_KINDS and not hands_blocked() and bag.size() < BAG_SLOTS)


## [Q] gedrückt: Fächer einblenden. Das Spiel läuft weiter, man kann weiterlaufen – nur die Maus wählt.
func open_bag() -> void:
	bag_open = true
	bag_sel = -1
	_bag_cursor = 0.0
	_show_bag_menu()


## [Q] losgelassen (choose) oder abgebrochen (Rechtsklick, Gespräch, Würgen …).
func close_bag(choose: bool) -> void:
	bag_open = false
	if Game.hud:
		Game.hud.show_bag_menu(false)
	if choose and bag_sel >= 0:
		if bag_sel < bag.size():
			take_from_bag(bag_sel)
		elif held:
			stow_held()   # leeres Fach: Kleines aus der Hand hinein


## Eingabe bei offener Tasche: Maus nach links/rechts, Mausrad oder [1]–[6] wählen, Rechtsklick bricht ab.
func _bag_input(event: InputEvent) -> void:
	var half := BAG_SLOTS / 2.0
	if event is InputEventMouseMotion:
		var dx := (event as InputEventMouseMotion).screen_relative.x * Settings.mouse_sensitivity / BAG_MOUSE_STEP
		_bag_cursor = clampf(_bag_cursor + dx, -half, half)
		bag_sel = -1 if absf(_bag_cursor) < BAG_DEAD_ZONE else clampi(floori(_bag_cursor + half), 0, BAG_SLOTS - 1)
	elif event is InputEventMouseButton and event.pressed:
		match (event as InputEventMouseButton).button_index:
			MOUSE_BUTTON_WHEEL_DOWN:
				_select_bag_slot((bag_sel + 1) % BAG_SLOTS)
			MOUSE_BUTTON_WHEEL_UP:
				_select_bag_slot((bag_sel - 1 + BAG_SLOTS) % BAG_SLOTS if bag_sel >= 0 else BAG_SLOTS - 1)
			MOUSE_BUTTON_RIGHT:
				close_bag(false)
				return
	elif _bag_slot_pressed(event) >= 0:
		_select_bag_slot(_bag_slot_pressed(event))
	else:
		return
	_show_bag_menu()


## --bag-menu=n: Tasche offen halten, Fach `slot` gewählt (−1 = keins)
func debug_open_bag(slot: int) -> void:
	debug_bag_menu = true
	open_bag()
	if slot >= 0:
		_select_bag_slot(mini(slot, BAG_SLOTS - 1))
	_show_bag_menu()


func _select_bag_slot(slot: int) -> void:
	bag_sel = slot
	_bag_cursor = slot - BAG_SLOTS / 2.0 + 0.5   # die Maus macht von dort aus weiter


func _show_bag_menu() -> void:
	if Game.hud:
		Game.hud.show_bag_menu(true, bag, BAG_SLOTS, bag_sel, held)


## Kleines aus der Hand in die Tasche (Tasche offen, leeres Fach gewählt).
func stow_held() -> void:
	if held == null:
		return
	if not held.fits_pocket():
		Game.say("Eine brennende Kerze steckt man nicht ein." if held.kind == Item.Kind.CANDLE else "%s passt nicht in die Tasche." % held.display_name)
		return
	if bag.size() >= BAG_SLOTS:
		Game.say("Die Tasche ist voll.")
		return
	var item := held
	held = null
	if Game.hud:
		Game.hud.set_held("")
	bag_add(item)
	Game.noise("bag", global_position, self)


## Fach `slot` in die Hand (Loslassen von [Q], ohne Tasche direkt mit [1]–[6]). Was die Hand hielt – groß oder klein –
## fällt zu Boden (es wird nicht aufgehängt); im Versteck ist dafür kein Platz.
func take_from_bag(slot: int) -> void:
	if slot >= bag.size():
		return
	if carried_cat:
		Game.say("Erst %s absetzen [G]." % carried_cat.display_name)
		return
	if held and hiding:
		Game.say("Hier drin kannst du %s nicht ablegen." % held.display_name)
		return
	if held:
		drop_held(false, false)
	var item: Item = bag[slot]
	bag.remove_at(slot)
	item.take_from_bag()
	_hold(item)
	_show_bag()
	Game.noise("bag", global_position, self)


## Fach-Taste dieses Ereignisses (0 = [1]) oder −1
func _bag_slot_pressed(event: InputEvent) -> int:
	for i in BAG_SLOTS:
		if event.is_action_pressed("bag_%d" % (i + 1)):
			return i
	return -1


## In die Tasche, an Platz `at` (sonst ans Ende). Der Gegenstand muss hineinpassen (bag_takes).
func bag_add(item: Item, at: int = -1) -> void:
	if item.get_parent():
		item.reparent(_bag_node, false)
	else:
		_bag_node.add_child(item)
	item.owner_id = "player"
	item.put_in_bag()
	item.position = Vector3.ZERO
	bag.insert(clampi(at, 0, bag.size()) if at >= 0 else bag.size(), item)
	_show_bag()


## Aus der Tasche nehmen, um es wegzugeben oder zu verbrauchen – der Gegenstand gehört dann dem Aufrufer.
func bag_remove(item: Item) -> Item:
	bag.erase(item)
	item.take_from_bag()
	_show_bag()
	return item


## Hat er so etwas – in der Hand oder in der Tasche?
func has_kind(kind: int) -> bool:
	return held_kind() == kind or bag.any(func(item: Item) -> bool: return item.kind == kind)


## Einen Gegenstand dieser Art verbrauchen – aus der Hand, sonst aus der Tasche. false = keiner da.
func consume_kind(kind: int) -> bool:
	if held_kind() == kind:
		consume_held()
		return true
	for item in bag:
		if item.kind == kind:
			bag_remove(item).queue_free()
			return true
	return false


## Weggeben (Geschenk) – aus der Hand oder aus der Tasche.
func give_away(item: Item) -> Item:
	return hand_over() if item == held else bag_remove(item)


## Verkauft oder verbraucht – aus der Hand oder aus der Tasche.
func consume_item(item: Item) -> void:
	if item == held:
		consume_held()
	else:
		bag_remove(item).queue_free()


## Spielstand: Tasche neu füllen
func set_bag(items: Array[Item]) -> void:
	for item in bag:
		item.queue_free()
	bag.clear()
	for item in items:
		bag_add(item)
	_show_bag()


## HUD: kleine Fächer unten rechts, bei offener Tasche auch die große Anzeige
func _show_bag() -> void:
	if Game.hud:
		Game.hud.set_bag(bag, BAG_SLOTS)
	if bag_open:
		_show_bag_menu()


func held_kind() -> int:
	return held.kind if held else -1


func held_key_id() -> String:
	if held and held.kind == Item.Kind.KEY:
		return held.key_id
	return ""


## Große Gegenstände (Kürbis …) brauchen beide Hände → keine Türen/Truhen öffnen.
func hands_blocked() -> bool:
	return held != null and held.is_large


func _drop_position() -> Vector3:
	var space := get_world_3d().direct_space_state
	var from := camera.global_position
	var forward := -camera.global_transform.basis.z
	var query := PhysicsRayQueryParameters3D.create(from, from + forward * 1.6, 1 | 2 | 4 | 64)
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	var point: Vector3
	if not hit.is_empty():
		var normal: Vector3 = hit["normal"]
		var pos: Vector3 = hit["position"]
		if normal.y > 0.6:
			return pos + Vector3.UP * 0.01
		point = pos - forward * 0.3
	else:
		point = from + forward * 1.2
	var down := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.1, point + Vector3.DOWN * 3.0, 1 | 4)
	down.exclude = [get_rid()]
	var floor_hit := space.intersect_ray(down)
	if floor_hit.is_empty():
		return point
	var floor_pos: Vector3 = floor_hit["position"]
	return floor_pos + Vector3.UP * 0.01


## Wo der Gegenstand in der Hand an der Wand hängen würde (Spielkonzept 5.6): {point, out[, length]} oder
## leer. point liegt auf der Wandfläche: beim Lakengespenst in Höhe des Hakens, bei der Lichterkette in der
## Mitte der Aufhängelinie – sie reicht nach beiden Seiten bis zur nächsten Wand oder Tür, höchstens 1,5 m.
func _hang_spot() -> Dictionary:
	if held == null or not held.can_hang():
		return {}
	var space := get_world_3d().direct_space_state
	var from := camera.global_position
	var query := PhysicsRayQueryParameters3D.create(from, from - camera.global_transform.basis.z * REACH, 1)
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return {}
	var normal: Vector3 = hit["normal"]
	if absf(normal.y) > 0.3:
		return {}
	var out := Vector3(normal.x, 0, normal.z).normalized()
	var point: Vector3 = hit["position"]
	var floor_y := global_position.y
	match held.kind:
		Item.Kind.SHEET_GHOST:
			point.y = clampf(point.y + 0.3, floor_y + 1.6, floor_y + 2.5)
		Item.Kind.COBWEB:
			point.y = clampf(point.y, floor_y + 0.5, floor_y + 2.7)
		Item.Kind.BAT_GARLAND:
			point.y = clampf(point.y + 0.2, floor_y + 1.7, floor_y + 2.5)
		Item.Kind.SPIDER:
			point.y = clampf(point.y + 0.3, floor_y + 1.8, floor_y + 2.6)
		Item.Kind.BROOM:
			point.y = floor_y   # lehnt unten an der Wand
		Item.Kind.LIGHT_STRING:
			point.y = clampf(point.y + 0.15, floor_y + 1.7, floor_y + 2.5)
			var along := Vector3.UP.cross(out)
			var reach: Array[float] = [1.5, 1.5]
			for i in 2:
				var start := point + out * 0.06
				var ray := PhysicsRayQueryParameters3D.create(start, start + along * (1.0 if i == 0 else -1.0) * 1.5, 1 | 2)
				var block := space.intersect_ray(ray)
				if not block.is_empty():
					reach[i] = start.distance_to(block["position"]) - 0.05
			if reach[0] + reach[1] < 0.8:
				return {}
			return {"point": point + along * (reach[0] - reach[1]) / 2.0, "out": out, "length": reach[0] + reach[1]}
	return {"point": point, "out": out}


func _update_focus() -> void:
	_focus = null
	if _ray.is_colliding():
		var collider := _ray.get_collider()
		if collider and collider.has_meta("interactable"):
			_focus = collider.get_meta("interactable")
	if Game.hud:
		var text := ""
		var icon := ""   # Aktions-Symbol über dem Hinweis (IconArt) – vom Objekt, falls es get_icon hat
		if _focus != null and is_instance_valid(_focus):
			text = _focus.get_prompt(self)
			if text != "" and _focus.has_method("get_icon"):
				icon = _focus.get_icon(self)
		if text == "" and seat:
			text = "Aufstehen [Leertaste]"
		if text == "" and carried_cat:
			text = "%s absetzen [G]" % carried_cat.display_name
		if text == "" and held:
			if held.can_hang() and not _hang_spot().is_empty():
				text = "%s aufhängen [G]" % held.display_name
				icon = "decorate"
			elif held.kind == Item.Kind.LEAVES:
				text = "Herbstlaub verstreuen [G]"
				icon = "decorate"
		Game.hud.set_prompt(text, icon)


# --- Ducken ---------------------------------------------------------------

## Lose Gegenstände vor den Füßen beiseiteschieben, statt an ihnen hängenzubleiben.
func _push_items(dir: Vector3, speed: float) -> void:
	if dir.length() < 0.1:
		return
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.is_held or item.freeze or item.kind == Item.Kind.PUMPKIN_MUSH:
			continue   # Kürbismatsch klebt am Boden
		var to := item.global_position - global_position
		if to.y > 0.8 or to.y < -0.3:
			continue   # liegt auf einem Tisch oder tiefer
		var flat := Vector3(to.x, 0, to.z)
		if flat.length() > RADIUS + 0.3 or flat.dot(dir) <= 0.0:
			continue
		var away := flat.normalized() if flat.length() > 0.01 else dir
		item.sleeping = false
		item.linear_velocity = (dir + away).normalized() * speed * 0.9 + Vector3.UP * 0.4


func _update_crouch() -> void:
	var want := Input.is_action_pressed("crouch")
	if Settings.crouch_toggle:
		if Input.is_action_just_pressed("crouch"):
			_crouch_toggled = not crouching
		want = _crouch_toggled
	if want and not crouching:
		_set_crouch(true)
	elif not want and crouching and _can_stand():
		_set_crouch(false)


## Spielstand: geduckt laden – wo der Platz zum Aufstehen fehlt (unter Treppen, Tischen), bleibt er geduckt;
## sonst steht er im nächsten Frame auf (beim Umschalten bleibt das Ducken an).
func set_crouching(value: bool) -> void:
	_set_crouch(value)
	_crouch_toggled = value


func _set_crouch(value: bool) -> void:
	crouching = value
	_shape.height = crouch_height if value else body_height
	_collider.position.y = _shape.height / 2.0


func _can_stand(at: Vector3 = global_position) -> bool:
	var probe := CapsuleShape3D.new()
	probe.radius = RADIUS - 0.02
	probe.height = body_height
	var params := PhysicsShapeQueryParameters3D.new()
	params.shape = probe
	params.transform = Transform3D(Basis(), at + Vector3(0, body_height / 2.0 + 0.02, 0))
	params.collision_mask = collision_mask
	params.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_shape(params, 1).is_empty()


# --- Verstecken -------------------------------------------------------------

func enter_hide(spot: HideSpot) -> void:
	leave_seat(true)
	if held and held.is_large:
		Game.say("Du stellst %s ab." % held.display_name, 2.0)
		drop_held()
	_set_crouch(false)
	if held and held.flashlight and held.flashlight.on:
		held.flashlight.toggle()
	hiding = spot
	spot.occupant = self
	hide_time = 0.0
	hide_stress = 0.0
	breath = BREATH_MAX
	_breath_locked = false
	_collider.disabled = true
	velocity = Vector3.ZERO
	_hide_yaw = 0.0
	_hide_pitch = 0.0
	head.position.y = eye_height
	spot.on_enter(self)
	_apply_hide_view()
	if Game.hud:
		Game.hud.set_hide_mode(1 if spot.type == HideSpot.Type.WARDROBE else 2)
	if Game.director:
		Game.director.on_actor_hid(spot, self)


func exit_hide() -> void:
	if hiding == null:
		return
	if sleeping:
		_stop_sleep()
	var spot := hiding
	hiding = null
	spot.occupant = null
	spot.on_exit()
	global_position = spot.exit_point.global_position
	rotation = Vector3(0, spot.exit_point.global_rotation.y, 0)
	head.rotation.x = 0.0
	_collider.disabled = false
	holding_breath = false
	hide_stress = 0.0
	if Game.hud:
		Game.hud.set_hide_mode(0)
		Game.hud.set_hide_state(0.0, 1.0, false)


func _apply_hide_view() -> void:
	var view := hiding.view_point.global_transform
	global_position = view.origin - Vector3(0, eye_height, 0)
	rotation = Vector3(0, view.basis.get_euler().y + _hide_yaw, 0)
	head.rotation.x = _hide_pitch


func _update_hiding(delta: float) -> void:
	if sleeping:
		_update_sleep(delta)
		return
	hide_time += delta
	# Luft anhalten: senkt die Chance, dass das Monster dich findet – aber nicht zu lange.
	if not Input.is_action_pressed("hold_breath"):
		_breath_locked = false
	holding_breath = Input.is_action_pressed("hold_breath") and not _breath_locked and breath > 0.0
	if holding_breath:
		breath -= delta * (1.0 + WINDED_BREATH_DRAIN * exertion())   # außer Atem geht es kürzer
		if breath <= 0.0:
			breath = 0.0
			holding_breath = false
			_breath_locked = true
			Game.noise("gasp", global_position, self)
	else:
		breath = minf(BREATH_MAX, breath + delta * 0.8)
	# Unter Schock hält man es im Versteck kürzer aus
	var comfort := HIDE_COMFORT_TIME * (1.0 - 0.4 * shock)
	hide_stress = clampf((hide_time - comfort) / (HIDE_MAX_TIME - comfort), 0.0, 1.0)
	if Game.hud:
		Game.hud.set_hide_state(hide_stress, breath / BREATH_MAX, holding_breath)
		Game.hud.set_prompt("Verlassen [E]    Luft anhalten [Rechtsklick]", "closet_exit")
	if hide_stress >= 1.0 and not gripped:
		Game.say("Du hältst es hier drin nicht mehr aus!")
		Game.noise("gasp", global_position, self)
		exit_hide()


# --- Schlafen (Spielkonzept 3.6, 4.18) ----------------------------------------

## Im eigenen Bett, wann man will: Augen zu, die Zeit läuft schneller (in der Nachtruhe springt sie, SleepSkip), bis
## sleep_hours um sind (dann steht man auf).
## Man liegt dabei wie in einem Versteck im Bett – das Monster kann einen dort finden.
func start_sleep(bed: HideSpot) -> void:
	enter_hide(bed)
	sleeping = true
	_sleep_now = 0.0
	_sleep_lost = 0.0
	_sleep_drunk = drunk
	Engine.time_scale = SLEEP_SPEED
	if Game.hud:
		Game.hud.set_hide_mode(3)
		Game.hud.set_prompt("Aufstehen [E]", "sleep")
	Game.say("Du schläfst ein … (%s)" % hours_text(sleep_hours), 2.0)
	if Game.tracing:
		print("[Schlaf] eingeschlafen für %d h (%.2f Nächte ohne Schlaf)" % [sleep_hours, nights_awake])
	if Game.sleep_skip:
		Game.sleep_skip.try_begin()   # in der Nachtruhe springt die Zeit (3.6)


## „1 Stunde“, „3 Stunden“.
static func hours_text(hours: int) -> String:
	return "1 Stunde" if hours == 1 else "%d Stunden" % hours


## So viele Spielsekunden will man noch schlafen.
func sleep_left() -> float:
	return maxf(0.0, sleep_hours * Calendar.HOUR - _sleep_now)


## Zeitsprung im Schlaf (SleepSkip, Spielkonzept 3.6): was sonst je Bild abklingt oder sich
## erholt, um dt auf einmal; der Schlaf zählt mit.
func skip_time(dt: float) -> void:
	shock = maxf(0.0, shock - dt / 180.0 * shock_recovery)
	drunk = maxf(0.0, drunk - dt / BarTap.SOBER_TIME)
	hangover = maxf(0.0, hangover - dt)
	injury = maxf(0.0, injury - dt / INJURY_HEAL_TIME)
	stamina = minf(1.0, stamina + dt / STAMINA_REST_TIME)
	if sleeping:
		var credit := _sleep_credit(dt)
		_slept += credit
		_sleep_now += dt
		_sleep_lost += dt - credit
	caffeine = maxf(0.0, caffeine - dt / COFFEE_FADE)
	coffee_low = maxf(0.0, coffee_low - dt)
	coffee = maxf(0.0, coffee - dt)   # im Schlaf ohne Tief
	tea = maxf(0.0, tea - dt)


func _update_sleep(delta: float) -> void:
	var credit := _sleep_credit(delta)
	_slept += credit
	_sleep_now += delta
	_sleep_lost += delta - credit
	if Game.hud:
		Game.hud.set_prompt("Aufstehen [E]", "sleep")
	if Game.director and Game.director.player_threat > SLEEP_WAKE_THREAT:
		wake_up("Du schreckst hoch – etwas ist ganz nah!")
	elif sleep_left() <= 0.0:
		_wake_rested()


## Die gewählten Stunden sind um: aufwachen und aufstehen.
func _wake_rested() -> void:
	var hours := sleep_hours
	var hungover := _sleep_drunk >= BarTap.TIPSY and _sleep_now >= SLEEP_MIN
	exit_hide()   # → _stop_sleep: Erholung, Kater
	var text := "Du wachst auf. "
	if hungover:
		text += "Mir brummt der Schädel."
	elif nights_awake <= 0.0:
		text += "Endlich ausgeschlafen."
	elif nights_awake < 1.0:
		text += "Noch ein bisschen müde."
	else:
		text += "Das war zu kurz – ich bin immer noch hundemüde."
	Game.say(text, 3.5)
	if Game.tracing:
		print("[Schlaf] nach %d h aufgewacht (%.2f Nächte ohne Schlaf)" % [hours, nights_awake])


## Aufwachen, aber im Bett bleiben (darunter versteckt).
func wake_up(text: String) -> void:
	if not sleeping:
		return
	var slept := _sleep_now
	_stop_sleep()
	hide_time = 0.0
	if Game.hud:
		Game.hud.set_hide_mode(2)
	Game.say(text, 3.0)
	if Game.tracing:
		print("[Schlaf] geweckt nach %.0f s: %s (%.2f Nächte ohne Schlaf)" % [slept, text, nights_awake])


## Schlaf endet (gewählte Zeit um, geweckt, aufgestanden, tot): Er baut die Nächte ohne Schlaf anteilig ab – eine ganze
## Mütze (SLEEP_FULL) auf null, solange Kaffee wirkte nur halb (3.11) –, im Rausch ab SLEEP_MIN mit Kater (3.7). Die Wahl springt zurück auf eine Stunde.
func _stop_sleep() -> void:
	sleeping = false
	Engine.time_scale = 1.0
	if not dead:
		nights_awake *= 1.0 - minf(1.0, (_sleep_now - _sleep_lost) / SLEEP_FULL)
		if _sleep_drunk >= BarTap.TIPSY and _sleep_now >= SLEEP_MIN:
			hangover = HANGOVER_TIME
	_sleep_now = 0.0
	_sleep_lost = 0.0
	_sleep_drunk = 0.0
	sleep_hours = SLEEP_HOURS.x


## Ende der Nachtruhe (Social): Wer seit der letzten zu wenig geschlafen hat, hat anteilig eine Nacht mehr ohne Schlaf
## (gar nicht: eine ganze, SLEEP_FULL: keine). Wer gerade schläft, schläft weiter. Gezählt wird erst nach dem ersten
## Angriff (der friedliche Anfang soll niemanden bestrafen).
func on_night_over() -> void:
	var missed := 1.0 - minf(1.0, _slept / SLEEP_FULL)
	_slept = 0.0
	if not Game.director or not Game.director.first_attack_done or dead or missed <= 0.0:
		return
	nights_awake += missed
	if missed >= 1.0:
		var text := ""
		match roundi(nights_awake):
			1: text = "Wieder eine Nacht ohne Schlaf."
			2: text = "Zwei Nächte wach … Ich sollte mich in meinem Bett ausschlafen."
			_: text = "Mir fallen die Augen zu. Und draußen im Flur wartet etwas auf mich."
		# nach der Meldung, dass die Gäste aufwachen
		get_tree().create_timer(3.6, false).timeout.connect(Game.say.bind(text, 4.0))
	if Game.tracing:
		print("[Schlaf] Nachtruhe vorbei – %.2f Nacht verpasst, %.2f Nächte ohne Schlaf" % [missed, nights_awake])


func _exit_tree() -> void:
	Engine.time_scale = 1.0   # nicht schlafend ins Menü
