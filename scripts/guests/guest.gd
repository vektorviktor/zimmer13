class_name Guest
extends CharacterBody3D
## Hotelgast mit eigenem Tagesablauf (Spielkonzept 6). Nutzt dieselben Dinge wie der
## Spieler: trägt Gegenstände in der Hand, öffnet Türen, versteckt sich in Schränken.
## Stellt Deko vor die eigene Tür, erntet und schnitzt Kürbisse, klaut, wenn er dich
## nicht mag (oder in Panik ist), feiert in der Lobby – und kann vom Monster geholt werden.
## Der Koffer („stock“) ist abstrakt; was er in der Hand hat, ist echt.
## Licht & Vorhänge (7.3): schaltet sein Zimmerlicht, zieht Vorhänge zu, wenn er Angst hat,
## ersetzt fehlende Glühbirnen – und klaut selbst welche.
## Schreck (6.12): Sieht er eine Blutlache, eine Leiche oder den Lakengeist, bleibt er geschockt stehen –
## je nach Charakter mit erhobenen Händen und Flucht, starr oder weinend – und erzählt später davon.
## Freundschaft & Feindschaft (6.3): folgt dir als Freund, besucht dich in Zimmer 13, rempelt dich an,
## wenn er wütend ist, stolpert, wenn du ihn rammst, und schlägt zurück oder flieht, wenn du zuschlägst.

enum State { IDLE, WALK, CARRY_HOME, PLACE_DECO, HARVEST, STEAL, HIDE_GO, HIDING, PARTY, TALKING, MINIGAME, DEAD, KNOCK, SHELTER, SLEEP, SHOCKED, GHOSTED,
	FOLLOW, VISIT, ATTACK, STAGGER }

const WALK_SPEED := 1.4
const RUN_SPEED := 3.3
## Hört das Monster (Rauschen) ab dieser Entfernung – vorsichtige Gäste verstecken sich
const HEAR_DISTANCE := 15.0
## Erschreckendes Geräusch (4.15): Angst-Zuwachs (× (1,2 − Mut)) und Pause bis zur nächsten Reaktion
const ALARM_FEAR := 25.0
const ALARM_COOLDOWN := 20.0
const ALARM_LINES := ["Was war das?!", "Hast du das gehört?", "Da war doch was …", "Hallo? Ist da jemand?"]
## Erst wieder aus dem Versteck, wenn das Monster so weit weg ist
const SAFE_DISTANCE := 22.0
## Spuren: so viele schlammige Schritte nach dem Garten, so lange blutet ein Gast nach einem Angriff
## Schlafen im Bett (Nachtruhe): Füße so weit vom Bettmittelpunkt zum Fußende, so hoch liegt die Matratze
const BED_FEET := 0.9
const BED_TOP := 0.53
const MUD_STEPS := 14
const BLEED_TIME := 45.0
## Tänze bei Feiern (`_dance_pose`) für die Klötzchenfigur – Gastmodelle tanzen GuestBody.DANCES
const DANCES := ["hüpfen", "wiegen", "drehen", "arme hoch", "twist", "schunkeln"]
## Schreck (Spielkonzept 6.12): so weit sieht er Blut und Leichen, so oft schaut er sich um;
## Reaktion je Charakter (feste Gäste: profile["shock"])
const SHOCK_RANGE := 7.0
const SHOCK_SCAN := 0.5
const SHOCK_STYLES := {
	"ängstlich": "flee", "geschäftstüchtig": "flee", "Plaudertasche": "cry", "Bastler": "cry",
	"Skeptiker": "freeze", "Griesgram": "freeze",
}
const SHOCK_CRIES := {
	"flee": ["Oh Gott! Nein, nein, nein!", "Hilfe! HILFE!", "Weg hier, nur weg!"],
	"freeze": ["…", "Was zum …", "Das … das ist nicht wahr."],
	"cry": ["Nein … *schluchzt*", "Oh nein, oh nein … *weint*", "Warum … *schluchzt*"],
}
## So viele Erlebnisse merkt er sich (die ältesten fallen heraus)
const MAX_EXPERIENCES := 5
## Freundschaft & Feindschaft (6.3): Abstand beim Folgen, Reichweite eines Schlags, so lange humpelt er
## nach einem Schlag (langsamer), so stark trifft er dich
const FOLLOW_GAP := 1.8
const PUNCH_REACH := 1.1
const HURT_TIME := 90.0
const HURT_SLOW := 0.7
const PUNCH_INJURY := 0.35
const RUDE_LINES := ["Aus dem Weg!", "Pass doch auf!", "Geh mir aus den Augen.", "Na, wieder unterwegs?"]
const RAMMED_LINES := ["Hey! Spinnst du?", "Au! Pass doch auf!", "Was soll das denn?!"]
const HIT_BACK_LINES := ["Na warte!", "Das wirst du bereuen!", "Jetzt reicht's mir!"]
const HIT_FLEE_LINES := ["Hilfe! Der ist verrückt!", "Lass mich in Ruhe!", "Au! Hör auf!"]
const DECO_KINDS := [Item.Kind.CARVED_PUMPKIN, Item.Kind.CANDLE, Item.Kind.COBWEB, Item.Kind.LEAVES, Item.Kind.PUMPKIN]

var id := ""
var profile: Dictionary
var display_name := ""
var relation := 0.0          ## −100 (Feind) … +100 (Freund)
var fear := 0.0              ## 0 … 100, ab 60 Panik
var stock := {}              ## Item.Kind → Anzahl
var home: Dictionary         ## Zimmer-Info vom LevelBuilder
var dead := false
var hiding: HideSpot
var crouching := false
var running := false
var holding_breath := false
var held: Item
var invited := false
var chat_cooldown := 0.0
var gift_cooldown := 0.0
var monster_line := 0
var expected_deco := 0      ## so viel eigene Deko sollte vor der Tür stehen
var money := 0
var seated := false          ## sitzt am Spieltisch
var challenge_time := 0.0    ## > 0: hat dich gerade herausgefordert (Sekunden bis es verfällt)
var challenge_cooldown := 0.0
var challenge_game := "dice"  ## wozu er herausfordert: "dice" (Mäxchen) oder "chess" (Spielkonzept 6.10)
var state := State.IDLE
var gen_seed := -1           ## ≥ 0: zufällig erzeugter Gast (GuestGenerator)
var corpse := false          ## tot, liegt aber noch da (Lakengeist, Spielkonzept 6.12)
var ghost_visits := 0        ## so oft kam der Lakengeist schon zu ihm (Stufe, wie beim Spieler)
var seen_sights: Array = []  ## Blutlachen und Leichen, die er schon gesehen hat (sight_key)
## Eigene Erlebnisse: {kind (blood/corpse/ghost/ghost_attack), zone, who, at (Director.elapsed), told}
var experiences: Array = []
## Taten zwischen ihm und dem Spieler (6.3): games, gifts_to, gifts_from, hostile, revenge
var deeds := {}
var chat_day := 0            ## Tag des letzten Plauderns
var chats_today := 0         ## nur die ersten zwei Plaudereien am Tag zählen voll
var attack_cooldown := 0.0
var threatened := false      ## hat dir schon gedroht – beim nächsten Mal schlägt er zu

var agent: NavigationAgent3D
var _collider: CollisionShape3D
var _visual: Node3D
var _hand: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _body: GuestBody         ## Gastmodell; null = Klötzchenfigur (noch kein passender Grundkörper)
var _arms_free := true       ## Gastmodell: Arme schwingen mit der Laufanimation
var _label: Label3D
var _target := Vector3.ZERO
var _timer := 0.0
var _steal_item: Item
var _steal_lamp: Lamp
var _resting := false        ## ruht im Zimmer bei ausgeschaltetem Licht
var _plant: PumpkinPlant
var _hide_spot: HideSpot
var _deco_timer := 0.0
var _steal_timer := 0.0
var _monster_cooldown := 0.0
var _panic_quiet := 0.0      ## Panik-Satz nicht ständig wiederholen
var _alarm_cooldown := 0.0
var _run_noise := 0.0
var _warned := false
var _to_bed := false       ## Nachtruhe: auf dem Weg ins eigene Bett
var _flicker_fear := 0.0   ## nach langem Flackern so lange im Versteck bleiben (Sekunden)
var _anim := 0.0
var _dance := -1   ## Index in DANCES bzw. GuestBody.DANCES, -1 = tanzt gerade nicht
var _dance_timer := 0.0
var _game_look := Vector3.ZERO
var _stuck_time := 0.0
var _last_pos := Vector3.ZERO
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _door_timer := 0.0
var _mud := 0
var _bleeding := 0.0
var _step_dist := 0.0
var _foot_side := 1.0
var _trace_pos := Vector3.ZERO
var _shock_scan := 0.0
var _shock_look := Vector3.ZERO
var _shock_style := ""
var _entranced := false    ## vom Lakengeist hypnotisiert – bleibt stehen, bis er weg ist
var _gripped := false      ## wird vom Lakengeist gewürgt
var _hurt_time := 0.0      ## geschlagen: humpelt so lange langsamer
var _bump_cooldown := 0.0
var _push := Vector3.ZERO  ## Rückstoß beim Stolpern
var _hit_back := false     ## nach dem Stolpern: zurückschlagen statt fliehen
var _resume_follow := 0.0  ## Begleiter im Gespräch: so lange kommt er danach noch mit


func setup(p_id: String, p_home: Dictionary) -> Guest:
	id = p_id
	profile = GuestProfiles.get_profile(p_id)
	display_name = profile["name"]
	stock = (profile["stock"] as Dictionary).duplicate()
	money = int(profile.get("money", 5))
	home = p_home
	return self


func _ready() -> void:
	collision_layer = 128
	collision_mask = 1 | 16
	set_meta("interactable", self)
	add_to_group("guests")
	_collider = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.25
	capsule.height = 1.7
	_collider.shape = capsule
	_collider.position.y = 0.85
	add_child(_collider)
	agent = NavigationAgent3D.new()
	agent.radius = 0.3
	agent.height = 1.6
	agent.path_desired_distance = 0.3
	agent.target_desired_distance = 0.4
	agent.path_height_offset = 0.2   # NavMesh liegt ~0,2 m über dem Boden
	add_child(agent)
	_build_visual()
	_deco_timer = randf_range(30.0, 70.0)
	_steal_timer = randf_range(30.0, 60.0)
	_timer = randf_range(2.0, 6.0)


# --- Für Dialog & Social ------------------------------------------------------

func get_prompt(_player: Player) -> String:
	if dead or hiding or state == State.GHOSTED:
		return ""
	return "Mit %s sprechen [E]  (%s)" % [display_name, Social.relation_word(relation)]


func interact(_player: Player) -> void:
	if not dead and not hiding and state != State.GHOSTED and Game.dialog:
		Game.dialog.open(self)


func begin_talk() -> void:
	_resume_follow = _timer if state == State.FOLLOW else 0.0
	state = State.TALKING


func end_talk() -> void:
	if state != State.TALKING:
		return
	if _resume_follow > 0.0:
		_timer = _resume_follow   # ein Begleiter kommt nach dem Gespräch weiter mit
		_resume_follow = 0.0
		state = State.FOLLOW
	else:
		_set_idle(randf_range(2.0, 5.0))


func say(text: String) -> void:
	if Game.player and Game.player.global_position.distance_to(global_position) < 14.0:
		Game.say("%s: „%s“" % [display_name, text], 4.0)


## Panik-Satz – höchstens alle 45 s, sonst klingt er wie eine Schallplatte mit Sprung.
func say_panic() -> void:
	if _panic_quiet > 0.0:
		return
	_panic_quiet = 45.0
	say(line("panic"))


func line(key: String) -> String:
	return GuestProfiles.line(profile, key)


## An Zimmer 13 klopfen (Spielkonzept 4.13). Die Tür ist zu – ist der Gast weit weg,
## steht er einfach schon davor.
func start_knock(door_front: Vector3) -> void:
	if hiding:
		_leave_hide()
	_drop_held()
	if global_position.distance_to(door_front) > 6.0:
		global_position = door_front + Vector3(randf_range(-0.3, 0.3), 0.05, -0.15)
	_target = door_front
	fear = maxf(fear, 70.0)
	state = State.KNOCK


## Der Spieler hat aufgemacht: hinein ins Zimmer 13, dort eine Weile bleiben.
func enter_shelter(room_center: Vector3) -> void:
	_target = room_center + _jitter(0.8)
	_timer = randf_range(25.0, 45.0)
	fear = maxf(0.0, fear - 30.0)
	state = State.SHELTER


## Harmloser Angriff: zu Tode erschrocken, aber nicht geholt – rennt davon.
func scared_by_monster() -> void:
	if dead:
		return
	if hiding:
		_leave_hide()
	fear = 100.0
	say_panic()
	if randf() < 0.6:
		_bleeding = BLEED_TIME   # verletzt – hinterlässt Blutstropfen
	if randf() < 0.35:
		_lose_coins()
	_monster_cooldown = 10.0
	_go_hide()


func join_party(spot: Vector3) -> void:
	if dead or hiding or fear >= 60.0:
		return
	_drop_held()
	_target = spot
	state = State.PARTY


## Zum Spieltisch gehen und hinsetzen (Minispiel).
func sit_for_game(seat: Vector3, look: Vector3) -> void:
	_drop_held()
	_target = seat
	_game_look = look
	seated = false
	state = State.MINIGAME


func end_game() -> void:
	seated = false
	if state == State.MINIGAME:
		_set_idle(randf_range(3.0, 8.0))


func leave_party() -> void:
	if state == State.PARTY:
		_set_idle(randf_range(2.0, 6.0))
	invited = false


## Sieht dieser Gast den Akteur? 5 m × Auffälligkeit, 180°, abgelenkt ×0,6 (Spielkonzept 4.15).
## Für Zeugen beim Diebstahl.
func can_see_actor(actor) -> bool:
	if dead or hiding or actor == null or actor.dead or actor.hiding != null:
		return false
	var base := Senses.GUEST_SIGHT * (Senses.DISTRACTED if is_distracted() else 1.0)
	return Senses.can_see(self, global_position + Vector3.UP * 1.6, -global_transform.basis.z,
		base, Senses.GUEST_FOV_DOT, actor)


## Abgelenkt: im Gespräch, beim Würfeln, auf der Feier, in Panik.
func is_distracted() -> bool:
	return state in [State.TALKING, State.MINIGAME, State.PARTY] or fear >= 60.0


## Ein erschreckendes Geräusch gehört (Spielkonzept 4.15). Ängstliche geraten in Panik,
## Mutige sehen nach, die anderen erzählen davon. Gibt die Reaktion zurück (Debug), sonst "".
func hear_alarm(pos: Vector3) -> String:
	if dead or hiding or _alarm_cooldown > 0.0 or state in [State.TALKING, State.MINIGAME, State.KNOCK, State.SHELTER, State.HIDE_GO, State.SHOCKED, State.GHOSTED, State.STAGGER, State.ATTACK]:
		return ""
	_alarm_cooldown = ALARM_COOLDOWN
	var brave := float(profile["brave"])
	fear = minf(100.0, fear + ALARM_FEAR * (1.2 - brave))
	if fear >= 60.0:
		say_panic()
		_go_hide()
		return "Panik"
	if state == State.PARTY:
		return "erschrickt"
	say(ALARM_LINES[randi() % ALARM_LINES.size()])
	if randf() < brave:
		_drop_held()
		_walk_to(pos, State.WALK)
		return "sieht nach"
	return "erzählt davon"


## Streichelt eine Hotelkatze im Vorbeigehen (Spielkonzept 6.11) – das beruhigt.
func pet_cat(cat: HotelCat) -> void:
	fear = maxf(0.0, fear - 15.0)
	_set_idle(randf_range(2.5, 4.0))
	var to := cat.global_position - global_position
	rotation.y = atan2(-to.x, -to.z)
	if randf() < 0.4:
		say(["Na, %s?", "Na du, %s.", "Hallo %s, meine Schöne.", "%s! Komm her."].pick_random() % cat.display_name)


func own_deco_near_door() -> Array[Item]:
	var result: Array[Item] = []
	var door_front: Vector3 = home["door_front"]
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.owner_id == id and not item.is_held and item.global_position.distance_to(door_front) < 2.5:
			result.append(item)
	return result


## cause "monster": er verschwindet, zurück bleiben Kratzer und ein Schuh. "ghost": vom Lakengeist
## erwürgt – er bleibt liegen (Spielkonzept 6.12).
func die(cause: String = "monster") -> void:
	if dead:
		return
	dead = true
	if hiding:
		hiding.occupant = null
		hiding = null
	_drop_held()
	state = State.DEAD
	_collider.disabled = true
	collision_layer = 0
	_label.visible = false
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.owner_id == id:
			item.owner_id = ""
	if cause == "ghost":
		_lie_down()
		return
	visible = false
	# Spuren statt Gore: Kratzer am Boden und ein einzelner Schuh
	var traces := Node3D.new()
	get_parent().add_child(traces)
	traces.global_position = global_position
	for i in 3:
		var scratch := Geo.mesh(traces, Geo.box(Vector3(1.1, 0.01, 0.05)), Mat.psx(Color(0.12, 0.02, 0.02)), Vector3(0, 0.012, -0.12 + i * 0.12))
		scratch.rotation.y = 0.3
	Geo.mesh(traces, Geo.box(Vector3(0.12, 0.08, 0.26)), Mat.psx(profile["pants"]), Vector3(0.5, 0.04, 0.3))


## Leiche: auf den Rücken gekippt, Arme zur Seite. Andere Gäste erschrecken davor (Gruppe shock_sights).
func _lie_down() -> void:
	corpse = true
	visible = true
	velocity = Vector3.ZERO
	_arm_l.rotation = Vector3(0, 0, -0.5)
	_arm_r.rotation = Vector3(0, 0, 0.4)
	if _body:
		_body.animate(0.0, 0.0, false, [_arm_l, _arm_r], false, false)
	_visual.position = Vector3(0, 0.13, 0)
	_visual.rotation = Vector3(PI / 2.0, 0, 0.08)
	set_meta("sight_key", "corpse:" + id)
	set_meta("sight_kind", "corpse")
	add_to_group("shock_sights")


# --- Ablauf ---------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if dead:
		return
	_animate(delta)
	_update_label()
	_leave_traces(delta)
	fear = maxf(0.0, fear - delta * 0.4)
	chat_cooldown = maxf(0.0, chat_cooldown - delta)
	challenge_cooldown = maxf(0.0, challenge_cooldown - delta)
	if challenge_time > 0.0:
		challenge_time -= delta
		if challenge_time <= 0.0:
			Game.social.on_challenge_ignored(self)
	gift_cooldown = maxf(0.0, gift_cooldown - delta)
	_monster_cooldown -= delta
	_panic_quiet -= delta
	_alarm_cooldown -= delta
	_hurt_time = maxf(0.0, _hurt_time - delta)
	_bump_cooldown -= delta
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	match state:
		State.TALKING:
			_stop(delta)
			if Game.player:
				_face(Game.player.global_position, delta)
			return
		State.HIDING:
			_hiding_step(delta)
			return
		State.SLEEP:
			# schläft – bemerkt nichts (kein Rauschen, kein Monster) bis zum Ende der Nachtruhe
			if not Game.social.sleep_active:
				wake_up()
			return
		State.KNOCK:
			# klopft an Zimmer 13 und wartet, dass jemand aufmacht
			_stop(delta)
			_face(_target + Vector3(0, 0, 1.0), delta)
			return
		State.SHELTER:
			# Schutz in Zimmer 13 gefunden – eine Weile bleiben
			if _move_to(_target, WALK_SPEED, delta):
				_timer -= delta
				if _timer <= 0.0:
					_set_idle(randf_range(2.0, 5.0))
			_open_doors()
			return
		State.GHOSTED:
			# Der Lakengeist hält ihn am Hals (SheetGhost) – bis er sich losreißt oder stirbt
			_stop(delta)
			return
		State.STAGGER:
			# gerammt oder geschlagen: taumelt zurück, dann flieht er oder schlägt zurück
			velocity = Vector3(_push.x, 0.0 if is_on_floor() else velocity.y - _gravity * delta, _push.z)
			_push = _push.move_toward(Vector3.ZERO, 8.0 * delta)
			move_and_slide()
			_timer -= delta
			if _timer <= 0.0:
				_after_stagger()
			return
	_watch_monster()
	_scan_for_shock(delta)
	running = state == State.HIDE_GO
	if running:
		# Wer in Panik rennt, macht Lärm (6.5, 4.15)
		_run_noise -= delta
		if _run_noise <= 0.0:
			_run_noise = 0.6
			Game.noise("run", global_position, self)
	var speed := (RUN_SPEED if running else WALK_SPEED) * _speed_factor()
	match state:
		State.IDLE:
			_stop(delta)
			_timer -= delta
			_steal_timer -= delta
			if _steal_timer <= 0.0:
				_steal_timer = randf_range(30.0, 60.0)
				if _try_steal():
					return
			if _timer <= 0.0:
				_next_activity()
		State.PARTY:
			if _move_to(_target, WALK_SPEED, delta):
				_face(Game.social.party_center(), delta)
		State.MINIGAME:
			if seated:
				_stop(delta)
				_face(_game_look, delta)
			elif _move_to(_target, WALK_SPEED, delta):
				global_position = Vector3(_target.x, global_position.y, _target.z)
				seated = true
		State.SHOCKED:
			_stop(delta)
			_face(_shock_look, delta)
			_timer -= delta
			if _timer <= 0.0 and not _entranced:
				_after_shock()
		State.FOLLOW:
			_follow_step(delta)
		State.ATTACK:
			_attack_step(delta)
		_:
			# Wütende Gäste halten im Vorbeigehen auf dich zu, um dich anzurempeln (6.3)
			var goal := _target
			if _wants_to_bump():
				goal = Game.player.global_position
			if _move_to(goal, speed, delta) and goal == _target:
				_arrive()
			_check_bump()
	_open_doors()


# --- Freundschaft & Feindschaft (Spielkonzept 6.3) ------------------------------------

func is_following() -> bool:
	return state == State.FOLLOW or (state == State.TALKING and _resume_follow > 0.0)


## Mitkommen: bleibt etwa FOLLOW_GAP hinter dir, rennt, wenn du davonläufst.
func start_follow(duration: float = 120.0) -> void:
	if dead or hiding:
		return
	if state == State.PARTY:
		leave_party()
	_timer = duration
	state = State.FOLLOW


func stop_follow(text: String = "") -> void:
	if not is_following():
		return
	_resume_follow = 0.0
	if text != "":
		say(text)
	if state == State.FOLLOW:
		_set_idle(randf_range(2.0, 5.0))


func _follow_step(delta: float) -> void:
	var p := Game.player
	_timer -= delta
	if p == null or p.dead or _timer <= 0.0:
		stop_follow("Ich geh dann mal wieder.")
		return
	if p.hiding:
		stop_follow("Ich such mir selbst ein Versteck …")
		return
	if p.sleeping:
		stop_follow("Schlaf gut.")
		return
	var d := global_position.distance_to(p.global_position)
	if d > 25.0:
		stop_follow("Wo bist du denn hin?")
		return
	if d > FOLLOW_GAP:
		_move_to(p.global_position, (RUN_SPEED if d > 5.0 else WALK_SPEED * 1.4) * _speed_factor(), delta)
	else:
		_stop(delta)
		_face(p.global_position, delta)


## Besuch in Zimmer 13: hingehen, dann klopft er (Social.on_visit_arrived).
func start_visit(door_front: Vector3) -> void:
	if dead or hiding:
		return
	_walk_to(door_front, State.VISIT)


## Steht vor Zimmer 13 und klopft höflich (kein Panik-Klopfen).
func knock_politely() -> void:
	_drop_held()
	state = State.KNOCK


func end_visit() -> void:
	if state == State.KNOCK:
		_set_idle(randf_range(2.0, 5.0))


## Auf den Spieler losgehen und zuschlagen (Erzfeind oder Vergeltung). Läufst du weg, gibt er auf.
func start_attack(duration: float = 12.0) -> void:
	if dead or hiding:
		return
	if state == State.PARTY:
		leave_party()
	_drop_held()
	_timer = duration
	state = State.ATTACK


func _attack_step(delta: float) -> void:
	var p := Game.player
	_timer -= delta
	if p == null or p.dead or p.hiding or p.in_dialog or _timer <= 0.0:
		_set_idle(randf_range(3.0, 6.0))
		return
	if global_position.distance_to(p.global_position) > PUNCH_REACH:
		_move_to(p.global_position, RUN_SPEED * 0.95 * _speed_factor(), delta)
		return
	_stop(delta)
	_face(p.global_position, delta)
	p.hurt(PUNCH_INJURY, global_position)
	Game.social.on_guest_hit_player(self)
	_bump_cooldown = 60.0
	_walk_to(_room_point(), State.WALK)


## Gerammt (hit = false) oder geschlagen (hit = true): taumelt zurück. Danach – je nach Mut, Stolz
## und Beziehung – weiter, weg oder zurückschlagen.
func stagger(push: Vector3, hit: bool) -> void:
	if dead or hiding or state in [State.GHOSTED, State.SLEEP]:
		return
	if state == State.PARTY:
		leave_party()
	_drop_held()
	_push = push
	_timer = 0.9 if hit else 0.6
	_hit_back = false
	state = State.STAGGER
	if not hit:
		say(RAMMED_LINES[randi() % RAMMED_LINES.size()])
		return
	_hurt_time = HURT_TIME
	var brave := float(profile["brave"])
	var pride := float((profile["dice"] as Dictionary).get("pride", 0.5))
	fear = minf(100.0, fear + 35.0 * (1.2 - brave))
	_hit_back = brave >= 0.55 or pride >= 0.65 or Social.tier(self) <= Social.Tier.ENEMY
	say((HIT_BACK_LINES if _hit_back else HIT_FLEE_LINES).pick_random())


func _after_stagger() -> void:
	if _hit_back:
		_hit_back = false
		start_attack(8.0)
	elif _hurt_time > 0.0:
		fear = maxf(fear, 70.0)
		_go_hide()
	else:
		_set_idle(randf_range(1.0, 3.0))


func _speed_factor() -> float:
	return HURT_SLOW if _hurt_time > 0.0 else 1.0


## Wütend oder schlimmer, der Spieler nah und sichtbar: hält auf ihn zu.
func _wants_to_bump() -> bool:
	if state != State.WALK or _bump_cooldown > 0.0 or Social.tier(self) > Social.Tier.ANGRY:
		return false
	var p := Game.player
	if p == null or p.dead or p.hiding or p.in_dialog:
		return false
	return p.global_position.distance_to(global_position) < 3.5 and can_see_actor(p)


func _check_bump() -> void:
	if not _wants_to_bump():
		return
	var p := Game.player
	var to := p.global_position - global_position
	to.y = 0.0
	if to.length() > 0.9:
		return
	_bump_cooldown = 45.0
	p.shove(to.normalized() * 3.0)
	say(RUDE_LINES[randi() % RUDE_LINES.size()])
	Game.social.on_guest_rammed_player(self)


# --- Nachtruhe --------------------------------------------------------------------------

## Nachtruhe beginnt (Social): ins Zimmer, Licht aus, ins Bett. Wer gerade redet, spielt, klopft oder
## sich versteckt, geht später (über _next_activity).
## instant (Debug): sofort im eigenen Bett.
func bedtime(instant: bool = false) -> void:
	if instant and not dead and state != State.SLEEP:
		if hiding:
			_leave_hide()
		global_position = _room_point()
		_fall_asleep()
		return
	if dead or state in [State.TALKING, State.MINIGAME, State.KNOCK, State.SHELTER, State.HIDING, State.HIDE_GO, State.SLEEP, State.SHOCKED, State.GHOSTED, State.STAGGER, State.ATTACK]:
		return
	if state == State.PARTY:
		leave_party()
	_go_to_bed()


func _go_to_bed() -> void:
	_to_bed = true
	_walk_to(_room_point(), State.WALK)


## Licht aus, ins eigene Bett (still – kein Versteck-Geräusch): Er liegt sichtbar auf dem Rücken, den Kopf
## am Kissen (lokal −X des Betts; Pose in _pose). Ist das Bett belegt, schläft er im Stehen.
func _fall_asleep() -> void:
	_to_bed = false
	_set_room_light(false)
	state = State.SLEEP
	for spot in home["spots"]:
		var bed := spot as HideSpot
		if bed.type == HideSpot.Type.BED and bed.occupant == null:
			hiding = bed
			bed.occupant = self
			bed.set_checked(false)
			_collider.disabled = true
			velocity = Vector3.ZERO
			var along := bed.global_transform.basis.x.normalized()
			global_position = bed.global_position + along * BED_FEET + Vector3.UP * BED_TOP
			rotation.y = atan2(-along.x, -along.z)   # lokale +Z (Kopf beim Liegen) zum Kissen
			return


func is_asleep() -> bool:
	return state == State.SLEEP


## Nachtruhe vorbei: aus dem Bett, Licht an.
func wake_up() -> void:
	_to_bed = false
	if state != State.SLEEP:
		return
	if hiding:
		_leave_hide()
	_set_room_light(true)
	_set_idle(randf_range(2.0, 8.0))


func _set_idle(duration: float) -> void:
	state = State.IDLE
	_timer = duration


func _next_activity() -> void:
	if _resting:
		_resting = false
		_set_room_light(true)
	if Game.social.sleep_active:
		_go_to_bed()
		return
	if Game.social.party_active and invited:
		join_party(Game.social.free_party_spot())
		return
	if fear >= 60.0:
		_walk_to(_room_point(), State.WALK)
		return
	# Gute Freunde schließen sich manchmal von selbst an (6.3)
	var p := Game.player
	if Social.tier(self) == Social.Tier.GOOD_FRIEND and p and not p.dead and p.hiding == null and randf() < 0.25 \
			and p.global_position.distance_to(global_position) < 6.0 and can_see_actor(p):
		say("Ich komm ein Stück mit.")
		start_follow(60.0)
		return
	var choice := _weighted_choice(profile["activities"])
	match choice:
		"room":
			_walk_to(_room_point(), State.WALK)
		"lobby":
			var seats: Array[Vector3] = Game.social.builder.lobby_seats
			_walk_to(seats[randi() % seats.size()] + _jitter(0.3), State.WALK)
		"kitchen":
			_walk_to(Game.social.builder.kitchen_spot + _jitter(1.2), State.WALK)
		"bar":
			var bar_spots: Array[Vector3] = Game.social.builder.bar_spots
			_walk_to(bar_spots[randi() % bar_spots.size()] + _jitter(0.3), State.WALK)
		"garden":
			_plant = _ripe_plant() if profile["harvester"] else null
			if _plant:
				_walk_to(_plant.global_position + Vector3(0, 0, 0.7), State.HARVEST)
			else:
				var spots: Array[Vector3] = Game.social.builder.garden_spots
				_walk_to(spots[randi() % spots.size()] + _jitter(1.5), State.WALK)
		_:
			var corridor: Array[Vector3] = Game.social.builder.wander_points
			_walk_to(corridor[randi() % corridor.size()] + _jitter(0.5), State.WALK)


func _walk_to(point: Vector3, new_state: State) -> void:
	_target = point
	state = new_state


func _arrive() -> void:
	match state:
		State.WALK:
			if _to_bed and _is_home():
				_fall_asleep()
				return
			_set_idle(randf_range(15.0, 40.0))
			if _is_home():
				_at_home()
				if fear < 30.0 and float(profile["brave"]) >= 0.4 and not remembers("ghost") and randf() < 0.3:
					_resting = true
					_set_room_light(false)
		State.CARRY_HOME:
			if held:
				var kind := held.kind
				held.queue_free()
				held = null
				stock[kind] = int(stock.get(kind, 0)) + 1
			_set_idle(randf_range(8.0, 20.0))
			_at_home()
		State.HARVEST:
			if _plant and _plant.is_ripe() and held == null:
				_take_into_hand(_plant.harvest())
				Game.noise("harvest", global_position, self)
				_walk_to(_room_point(), State.CARRY_HOME)
			else:
				_set_idle(randf_range(5.0, 10.0))
		State.PLACE_DECO:
			_drop_held()
			expected_deco += 1
			_set_idle(randf_range(5.0, 12.0))
		State.STEAL:
			_finish_steal()
		State.VISIT:
			Game.social.on_visit_arrived(self)
		State.HIDE_GO:
			if _hide_spot and _hide_spot.occupant == null:
				_enter_hide(_hide_spot)
			else:
				_go_hide()


## Zu Hause: Licht, Vorhänge und Glühbirnen prüfen, Deko kontrollieren, Kürbisse
## schnitzen, Deko vor die Tür stellen.
func _at_home() -> void:
	_check_lights()
	var placed := own_deco_near_door()
	for item in placed:
		if item.is_toppled():
			item.stand_up()   # von einer Katze umgeworfen (6.11)
	if placed.size() < expected_deco:
		Game.social.on_guest_noticed_missing(self, expected_deco - placed.size())
	expected_deco = placed.size()
	if profile["carver"] and int(stock.get(Item.Kind.PUMPKIN, 0)) > 0:
		stock[Item.Kind.PUMPKIN] = int(stock[Item.Kind.PUMPKIN]) - 1
		stock[Item.Kind.CARVED_PUMPKIN] = int(stock.get(Item.Kind.CARVED_PUMPKIN, 0)) + 1
	if placed.size() < 2 and held == null:
		for kind in DECO_KINDS:
			if int(stock.get(kind, 0)) > 0:
				stock[kind] = int(stock[kind]) - 1
				_take_into_hand(Item.create(kind))
				_walk_to(deco_place_point(), State.PLACE_DECO)
				return


func _home_lamps() -> Array[Lamp]:
	var result: Array[Lamp] = []
	for node in get_tree().get_nodes_in_group("lamp_fixtures"):
		var lamp := node as Lamp
		if lamp.room_id == home["no"]:
			result.append(lamp)
	return result


func _set_room_light(on: bool) -> void:
	var sw := LightSwitch.find(get_tree(), home["no"])
	if sw:
		sw.set_on(on)


func _check_lights() -> void:
	# Ängstlich (oder den Lakengeist erlebt) → Vorhänge zu (nicht gesehen werden – macht das Zimmer aber dunkler)
	for node in get_tree().get_nodes_in_group("windows"):
		var win := node as HotelWindow
		if win.room_id == home["no"] and win.has_curtains():
			win.set_closed(fear >= 30.0 or remembers("ghost"))
	_set_room_light(true)
	for lamp in _home_lamps():
		if lamp.has_bulb and not lamp.bulb_broken:
			continue
		if lamp.has_bulb and lamp.bulb_broken and lamp.sparking:
			continue   # alter Wackelkontakt – daran hat er sich gewöhnt
		if int(stock.get(Item.Kind.BULB, 0)) > 0:
			stock[Item.Kind.BULB] = int(stock[Item.Kind.BULB]) - 1
			if lamp.has_bulb:
				lamp.take_bulb()
			lamp.insert_bulb(Item.create(Item.Kind.BULB))
		elif not lamp.has_bulb:
			Game.social.on_guest_noticed_missing_bulb(self)
		else:
			say("Meine Lampe ist durchgebrannt … jetzt sitze ich im Dunkeln.")


## Platz neben der eigenen Tür (im Flur), an dem Deko steht.
func deco_place_point() -> Vector3:
	var door_front: Vector3 = home["door_front"]
	var along: Vector3 = home["along"]
	var into: Vector3 = home["into"]
	var p := door_front + into * 0.45 + along * (1.0 if randf() < 0.5 else -1.0) * randf_range(0.9, 1.3)
	return Vector3(p.x, door_front.y, p.z)


# --- Klauen -------------------------------------------------------------------------

## Mag uns nicht (und ist gierig) → klaut Deko des Spielers. In Panik ohne eigene Deko
## → klaut irgendeine Deko, um sich zu schützen.
func _try_steal() -> bool:
	if held:
		return false
	var hostile := Social.tier(self) <= Social.Tier.ANGRY and randf() < float(profile["greed"])
	var desperate := fear >= 60.0 and own_deco_near_door().is_empty()
	if not hostile and not desperate:
		return false
	var best: Item = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.is_held or item.deco_strength <= 0.0 or item.owner_id == id:
			continue
		if hostile and item.owner_id != "player":
			continue
		if Game.player and Game.player.global_position.distance_to(item.global_position) < 8.0:
			continue
		if Game.social.is_in_closed_chest(item):
			continue
		var d := global_position.distance_to(item.global_position)
		if d < best_dist:
			best_dist = d
			best = item
	if best == null or randf() < 0.35:
		var lamp := _bulb_to_steal(hostile)
		if lamp:
			_steal_lamp = lamp
			_steal_item = null
			_walk_to(_floor_below(lamp.global_position) + _toward_room(lamp), State.STEAL)
			return true
	if best == null:
		return false
	_steal_item = best
	_walk_to(best.global_position, State.STEAL)
	return true


## Eine Lampe, deren Birne er klauen würde: feindlich → aus dem Zimmer des Spielers,
## in Panik → irgendeine (nicht die eigene), um das eigene Zimmer hell zu halten.
func _bulb_to_steal(hostile: bool) -> Lamp:
	var best: Lamp = null
	var best_dist := INF
	for node in get_tree().get_nodes_in_group("lamp_fixtures"):
		var lamp := node as Lamp
		if not lamp.has_bulb or lamp.bulb_broken or lamp.room_id == home["no"]:
			continue
		if lamp.room_id == "lobby":
			continue   # Lobbydecke – zu hoch
		if hostile and lamp.room_id != "13":
			continue
		if Game.player and Game.player.global_position.distance_to(lamp.global_position) < 8.0:
			continue
		var d := global_position.distance_to(lamp.global_position)
		if d < best_dist:
			best_dist = d
			best = lamp
	return best


## Kleiner Schritt von der Wand weg, damit der Gast unter der Wandleuchte stehen kann.
func _toward_room(lamp: Lamp) -> Vector3:
	if lamp.style == Lamp.Style.WALL:
		var out := lamp.global_transform.basis.z
		return Vector3(out.x, 0, out.z).normalized() * 0.6
	return Vector3.ZERO


func _finish_steal() -> void:
	if _steal_lamp != null:
		var lamp := _steal_lamp
		_steal_lamp = null
		if not is_instance_valid(lamp) or not lamp.has_bulb or held:
			_set_idle(randf_range(3.0, 6.0))
			return
		var victim := lamp.room_id
		var bulb := lamp.take_bulb()
		_take_into_hand(bulb)
		Game.social.on_guest_stole_bulb(self, lamp, victim)
		_walk_to(_room_point(), State.CARRY_HOME)
		return
	var item := _steal_item
	_steal_item = null
	if item == null or not is_instance_valid(item) or item.is_held:
		_set_idle(randf_range(3.0, 6.0))
		return
	var victim := item.owner_id
	_take_into_hand(item)
	Game.social.on_guest_stole(self, item, victim)
	_walk_to(deco_place_point(), State.PLACE_DECO)


# --- Schreck & Erlebnisse (Spielkonzept 6.12) ---------------------------------------------------

## Reaktion auf Schreckliches, fest je Charakter: "flee" (Hände hoch, weglaufen), "freeze" (starr), "cry" (weinen).
func shock_style() -> String:
	if profile.has("shock"):
		return profile["shock"]
	return SHOCK_STYLES.get(profile.get("archetype", ""), "freeze")


## Augenhöhe über den Füßen (Sichtlinien, Hals für den Lakengeist).
func eye_height() -> float:
	if _body:
		return float(profile.get("height_cm", 170.0)) / 100.0 - 0.1
	return 1.6 * float(profile.get("height", 1.0))


## Schaut sich alle 0,5 s nach Blutlachen und Leichen um, die er noch nicht kennt (Gruppe shock_sights,
## Schlüssel in Meta „sight_key“). Jeder Fund erschreckt ihn nur einmal.
func _scan_for_shock(delta: float) -> void:
	_shock_scan -= delta
	if _shock_scan > 0.0:
		return
	_shock_scan = SHOCK_SCAN
	if state in [State.HIDE_GO, State.SHOCKED]:
		return
	var eye := global_position + Vector3.UP * eye_height()
	var forward := -global_transform.basis.z
	var space := get_world_3d().direct_space_state
	for node in get_tree().get_nodes_in_group("shock_sights"):
		var sight := node as Node3D
		if sight == self or not sight.has_meta("sight_key"):
			continue
		var key := String(sight.get_meta("sight_key"))
		if key in seen_sights:
			continue
		var at := sight.global_position + Vector3.UP * 0.15
		if eye.distance_to(at) > SHOCK_RANGE or absf(at.y - global_position.y) > 1.5:
			continue
		if forward.dot((at - eye).normalized()) < Senses.GUEST_FOV_DOT:
			continue
		var query := PhysicsRayQueryParameters3D.create(eye, at, Senses.SIGHT_MASK)
		query.exclude = [get_rid()]
		if not space.intersect_ray(query).is_empty():
			continue
		seen_sights.append(key)
		shock(String(sight.get_meta("sight_kind", "blood")), sight.global_position, (sight as Guest).display_name if sight is Guest else "")
		return


## Schreck: bleibt 2–5 s stehen (je mutiger, desto kürzer) und starrt hin – danach je nach Charakter
## weglaufen und verstecken, weitermachen oder weinend heim. Wird zum Erlebnis, von dem er erzählt.
## entranced: vom Lakengeist hypnotisiert – bleibt stehen, bis der weg ist.
func shock(kind: String, pos: Vector3, who: String = "", entranced: bool = false) -> void:
	if dead:
		return
	remember(kind, pos, who)
	if hiding or state in [State.TALKING, State.MINIGAME, State.KNOCK, State.SHELTER, State.SLEEP, State.GHOSTED]:
		return
	if state == State.PARTY:
		leave_party()
	_drop_held()
	var brave := float(profile["brave"])
	_shock_style = shock_style()
	_shock_look = pos
	_entranced = entranced
	state = State.SHOCKED
	_timer = lerpf(5.0, 2.0, brave)
	fear = minf(100.0, fear + (50.0 if kind == "corpse" else 30.0) * (1.2 - brave))
	var cries: Array = SHOCK_CRIES[_shock_style]
	say(cries[randi() % cries.size()])
	if Game.player and Game.player.global_position.distance_to(global_position) < 10.0:
		Game.play_sound("gasp", 0.5)
	Game.shot_event("shock", 40)


func _after_shock() -> void:
	match _shock_style:
		"flee":
			fear = maxf(fear, 70.0)
			_go_hide()
		"cry":
			_walk_to(_room_point(), State.WALK)
		_:
			_set_idle(randf_range(2.0, 4.0))


## Der Lakengeist hat ihn am Hals (SheetGhost) – er zappelt, bis er sich losreißt oder stirbt.
func ghost_grab(ghost_pos: Vector3) -> void:
	if state == State.PARTY:
		leave_party()
	_drop_held()
	_entranced = false
	_shock_look = ghost_pos
	state = State.GHOSTED
	say("*röchelt*")


## Der Lakengeist ist weg. Wer gewürgt wurde und sich losgerissen hat, rennt in Panik davon.
func ghost_gone() -> void:
	_entranced = false
	if dead or state != State.GHOSTED:
		return
	remember("ghost_attack", _shock_look)
	fear = 100.0
	say_panic()
	_go_hide()


## Ein Erlebnis merken (für Gespräche). Dasselbe kurz hintereinander zählt einmal; wird man nach dem
## Anblick des Lakengeists noch gewürgt, wird daraus ein Angriff.
func remember(kind: String, pos: Vector3, who: String = "") -> void:
	var now := Game.director.elapsed if Game.director else 0.0
	if not experiences.is_empty():
		var last: Dictionary = experiences.back()
		var same: bool = last["kind"] == kind or (last["kind"] == "ghost" and kind == "ghost_attack")
		if same and last["who"] == who and now - float(last["at"]) < 60.0:
			if last["kind"] != kind:
				last["kind"] = kind
				last["told"] = false
			return
	var zone := Game.director.zone_name_at(pos) if Game.director else ""
	experiences.append({"kind": kind, "zone": zone, "who": who, "at": now, "told": false})
	if experiences.size() > MAX_EXPERIENCES:
		experiences.pop_front()


## Jüngstes Erlebnis dieser Art („ghost“ passt auch auf „ghost_attack“, "" auf alles) aus dem
## letzten Spieltag, sonst {}.
func recent_experience(kind: String = "") -> Dictionary:
	var now := Game.director.elapsed if Game.director else 0.0
	for i in range(experiences.size() - 1, -1, -1):
		var e: Dictionary = experiences[i]
		if String(e["kind"]).begins_with(kind) and now - float(e["at"]) < Calendar.DAY_SECONDS:
			return e
	return {}


func remembers(kind: String) -> bool:
	return not recent_experience(kind).is_empty()


## Das älteste Erlebnis, von dem er dem Spieler noch nicht erzählt hat, sonst {}.
func untold_experience() -> Dictionary:
	for e in experiences:
		if not e["told"]:
			return e
	return {}


# --- Monster & Verstecken -------------------------------------------------------------

func _watch_monster() -> void:
	var monster := Game.monster
	if not monster.is_active():
		_warned = false
		return
	var d := global_position.distance_to(monster.global_position)
	if d > SAFE_DISTANCE:
		_warned = false
	elif d < HEAR_DISTANCE and not _warned and state != State.HIDE_GO:
		_warned = true
		# Sie hören es (Rauschen, Flackern) – vorsichtige Gäste verstecken sich sofort
		if randf() > float(profile["brave"]) and state != State.PARTY:
			fear = minf(100.0, fear + 15.0)
			_go_hide()
			return
	if _monster_cooldown > 0.0 or state == State.HIDE_GO:
		return
	var eye := global_position + Vector3.UP * 1.6
	var monster_head := monster.global_position + Vector3.UP * 1.7
	if eye.distance_to(monster_head) > 15.0:
		return
	var query := PhysicsRayQueryParameters3D.create(eye, monster_head, Monster.SIGHT_MASK)
	if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
		return
	_monster_cooldown = 10.0
	fear = minf(100.0, fear + 45.0 * (1.2 - float(profile["brave"])))
	Game.social.on_guest_saw_monster(self)
	if randf() < 0.1:
		_lose_coins()
	_go_hide()


## Flackerwelle beim Aufbruch des Monsters (Spielkonzept 4.17), erreicht den Gast nach `delay` s.
## level 0 = kurzes Zucken, 1 = Flackern, 2 = langes Flackern.
func on_flicker_signal(level: int, delay: float) -> void:
	get_tree().create_timer(delay, false).timeout.connect(_react_to_flicker.bind(level))


## Langes Flackern: Ängstliche verstecken sich sofort und bleiben eine Weile drin. Beim kurzen
## Zucken bleiben fast alle, wo sie sind.
func _react_to_flicker(level: int) -> void:
	if dead or hiding != null or state in [State.HIDE_GO, State.PARTY, State.TALKING, State.MINIGAME, State.DEAD, State.GHOSTED]:
		return
	var brave := float(profile["brave"])
	fear = minf(100.0, fear + [2.0, 8.0, 20.0][level])
	var threshold: float = [1.0, brave + 0.5, brave][level]
	if randf() > threshold:
		_flicker_fear = 15.0 * level * level
		_go_hide()


func _go_hide() -> void:
	_drop_held()
	if state == State.PARTY:
		state = State.IDLE
	_hide_spot = Game.social.find_hide_spot(self)
	if _hide_spot:
		_walk_to(_hide_spot.exit_point.global_position, State.HIDE_GO)
	else:
		_walk_to(_room_point(), State.WALK)


func _enter_hide(spot: HideSpot) -> void:
	Game.director.on_actor_hid(spot, self)
	Game.social.release_hide_spot(spot)
	hiding = spot
	spot.occupant = self
	spot.on_enter(self)
	visible = false
	_collider.disabled = true
	velocity = Vector3.ZERO
	global_position = spot.global_position
	state = State.HIDING
	_timer = 0.0


func _hiding_step(delta: float) -> void:
	_timer += delta
	var monster := Game.monster
	_flicker_fear = maxf(0.0, _flicker_fear - delta)
	var calm := (not monster.is_active() or monster.global_position.distance_to(global_position) > SAFE_DISTANCE) and _flicker_fear <= 0.0
	if not calm:
		_timer = minf(_timer, 0.0)
	if calm and _timer > 8.0:
		_leave_hide()
		_set_idle(randf_range(2.0, 5.0))


func _leave_hide() -> void:
	var spot := hiding
	if spot == null:
		return
	hiding = null
	spot.occupant = null
	spot.on_exit()
	visible = true
	_collider.disabled = false
	global_position = spot.exit_point.global_position
	state = State.IDLE


# --- Hände ------------------------------------------------------------------------

func _take_into_hand(item: Item) -> void:
	if item == null:
		return
	if not item.is_inside_tree():
		get_parent().add_child(item)
	item.owner_id = id
	item.set_held(true)
	item.reparent(_hand, false)
	item.position = Vector3(0, -0.15, 0) if item.is_large else Vector3.ZERO
	item.rotation = Vector3(0, PI, 0)
	held = item


func _drop_held() -> void:
	if held == null:
		return
	var item := held
	held = null
	item.reparent(get_parent(), true)
	var pos := Vector3(item.global_position.x, global_position.y + 0.02, item.global_position.z)
	if state == State.PLACE_DECO:
		pos = Vector3(_target.x, _target.y + 0.02, _target.z)
	item.global_position = pos
	item.rotation = Vector3(0, rotation.y + PI, 0)
	item.set_held(false)
	item.linear_velocity = Vector3.ZERO


# --- Hilfen ------------------------------------------------------------------------

func _room_point() -> Vector3:
	var c: Vector3 = home["center"]
	return c + _jitter(1.0)


func _is_home() -> bool:
	var c: Vector3 = home["center"]
	return global_position.distance_to(c) < 2.5


func _ripe_plant() -> PumpkinPlant:
	for node in get_tree().get_nodes_in_group("pumpkin_plants"):
		var plant := node as PumpkinPlant
		if plant.is_ripe():
			return plant
	return null


# --- Spuren der Gäste ------------------------------------------------------------------

## Schlammige Schuhabdrücke nach dem Garten, Wachs von etwas Brennendem in der Hand,
## Blutstropfen nach einem Angriff.
func _leave_traces(delta: float) -> void:
	_bleeding = maxf(0.0, _bleeding - delta)
	var in_garden := global_position.x < 0.0 and global_position.z < -7.2 and global_position.y < 1.0
	if in_garden:
		_mud = MUD_STEPS
	var moved := Vector2(global_position.x - _trace_pos.x, global_position.z - _trace_pos.z).length()
	_trace_pos = global_position
	if moved > 1.0 or moved < 0.001 or hiding:
		return   # versetzt (Versteck, Laden) oder steht still
	_step_dist += moved
	if _step_dist < 0.8:
		return
	_step_dist = 0.0
	var traces := Game.traces
	if traces == null:
		return
	if _mud > 0 and not in_garden:
		_mud -= 1
		_foot_side = -_foot_side
		traces.add_shoeprint(global_position + global_transform.basis.x * 0.1 * _foot_side, rotation.y)
	if (_bleeding > 0.0 or _hurt_time > HURT_TIME - 20.0) and randf() < 0.5:
		traces.add_guest_drop("drops", global_position + _jitter(0.15))
	if held and held.lit and randf() < 0.15:
		traces.add_guest_drop("wax", global_position + _jitter(0.2))


## In Panik fallen ein paar Münzen aus der Tasche – wer sie findet, darf sie behalten.
func _lose_coins() -> void:
	if money < 2:
		return
	var n := randi_range(1, mini(4, money))
	money -= n
	var coins := Item.create(Item.Kind.COINS, str(n))
	get_parent().add_child(coins)
	coins.global_position = global_position + _jitter(0.4) + Vector3.UP * 0.05


## Boden unter einem Punkt (z. B. unter einer Lampe) – auf jedem Stockwerk.
func _floor_below(p: Vector3) -> Vector3:
	var query := PhysicsRayQueryParameters3D.create(p + Vector3.DOWN * 0.3, p + Vector3.DOWN * 4.0, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return Vector3(p.x, global_position.y if hit.is_empty() else (hit["position"] as Vector3).y, p.z)


func _jitter(r: float) -> Vector3:
	return Vector3(randf_range(-r, r), 0, randf_range(-r, r))


func _weighted_choice(weights: Dictionary) -> String:
	var total := 0.0
	for key in weights:
		total += float(weights[key])
	var r := randf() * total
	for key in weights:
		r -= float(weights[key])
		if r <= 0.0:
			return key
	return weights.keys()[0]


func _open_doors() -> void:
	# Bei vielen Gästen und Türen nicht jeden Frame alle Türen prüfen
	_door_timer -= get_physics_process_delta_time()
	if _door_timer > 0.0:
		return
	_door_timer = 0.15
	for node in get_tree().get_nodes_in_group("doors"):
		var door := node as Door
		if door.is_open or door.locked:
			continue
		if door.center().distance_to(global_position + Vector3.UP) < 1.2:
			door.set_open(true, false, false, self)


func _move_to(point: Vector3, speed: float, delta: float) -> bool:
	if agent.target_position.distance_to(point) > 0.25:
		agent.target_position = point
	# Nur angekommen, wenn auch das Stockwerk stimmt (Zimmer liegen übereinander)
	var near := Vector2(point.x - global_position.x, point.z - global_position.z).length() < 0.6 		and absf(point.y - global_position.y) < 1.5
	if near or agent.is_navigation_finished():
		_stop(delta)
		return true
	var next := agent.get_next_path_position()
	var dir := next - global_position
	dir.y = 0.0
	if dir.length() > 0.01:
		dir = dir.normalized()
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), minf(1.0, 8.0 * delta))
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	velocity.y = 0.0 if is_on_floor() else velocity.y - _gravity * delta
	move_and_slide()
	# Festgefahren? Weg neu berechnen und kurz seitlich ausweichen.
	if global_position.distance_to(_last_pos) < speed * delta * 0.2:
		_stuck_time += delta
		if _stuck_time > 1.0:
			_stuck_time = 0.0
			var side := Vector3(-dir.z, 0, dir.x) * (1.0 if randf() < 0.5 else -1.0)
			global_position += side * 0.15
			agent.target_position = point + Vector3(0.01, 0, 0)
	else:
		_stuck_time = 0.0
	_last_pos = global_position
	return false


func _stop(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	velocity.y = 0.0 if is_on_floor() else velocity.y - _gravity * delta
	move_and_slide()


func _face(pos: Vector3, delta: float) -> void:
	var to := pos - global_position
	if Vector2(to.x, to.z).length() < 0.01:
		return
	rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), minf(1.0, 6.0 * delta))


# --- Aussehen -------------------------------------------------------------------------

func _build_visual() -> void:
	_visual = Node3D.new()
	add_child(_visual)
	var body_id := GuestBody.pick(profile, id)
	if body_id != "":
		_body = GuestBody.new()
		_body.setup(body_id, profile)
		_visual.add_child(_body)
		# Unsichtbare Pivots: die Posen drehen sie, das Modell zielt mit den Oberarmen danach
		_arm_l = Node3D.new()
		_arm_r = Node3D.new()
		_visual.add_child(_arm_l)
		_visual.add_child(_arm_r)
	else:
		_build_blocks()
	_hand = Node3D.new()
	_hand.position = Vector3(0, 1.0, -0.35)
	_visual.add_child(_hand)
	_label = Label3D.new()
	_label.text = display_name
	_label.font_size = 28
	_label.pixel_size = 0.005
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_label.modulate = Color(0.9, 0.85, 0.7)
	_label.position = Vector3(0, 2.0, 0)
	_label.visible = false
	add_child(_label)


## Klötzchenfigur für Gäste ohne Grundkörper
func _build_blocks() -> void:
	_visual.scale = Vector3.ONE * float(profile.get("height", 1.0))
	var coat := Mat.psx(profile["coat"])
	var pants := Mat.psx(profile["pants"])
	var skin := Mat.psx(Color(0.82, 0.66, 0.55))
	var hair := Mat.psx(profile["hair"])
	for side in [-1.0, 1.0]:
		Geo.mesh(_visual, Geo.box(Vector3(0.13, 0.85, 0.15)), pants, Vector3(side * 0.09, 0.425, 0))
	Geo.mesh(_visual, Geo.box(Vector3(0.4, 0.62, 0.24)), coat, Vector3(0, 1.15, 0))
	_arm_l = _make_arm(-1.0, coat, skin)
	_arm_r = _make_arm(1.0, coat, skin)
	Geo.mesh(_visual, Geo.sphere(0.13, 0.28, 7, 4), skin, Vector3(0, 1.6, 0))
	Geo.mesh(_visual, Geo.box(Vector3(0.28, 0.1, 0.28)), hair, Vector3(0, 1.72, 0.01))
	Geo.mesh(_visual, Geo.box(Vector3(0.28, 0.2, 0.08)), hair, Vector3(0, 1.62, 0.12))
	for side in [-1.0, 1.0]:
		Geo.mesh(_visual, Geo.box(Vector3(0.03, 0.03, 0.02)), Mat.psx(Color(0.05, 0.05, 0.05)), Vector3(side * 0.05, 1.62, -0.12))


## Meist der Lieblingstanz des Gastes, ab und zu ein anderer (Spielkonzept 7.1).
func _dance_pose(delta: float) -> void:
	var dances: Array = GuestBody.DANCES if _body else DANCES
	_dance_timer -= delta
	if _dance < 0 or _dance_timer <= 0.0:
		var favourite := absi(hash(id)) % dances.size()
		_dance = favourite if randf() < 0.6 else randi() % dances.size()
		_dance_timer = randf_range(7.0, 15.0)
		_visual.rotation = Vector3.ZERO
	if _body:
		_body.dance = dances[_dance]
		_visual.position.y = 0.0
		return
	var t := _anim
	var beat := sin(t * 4.0)
	_arm_l.rotation.z = 0.0
	_arm_r.rotation.z = 0.0
	match DANCES[_dance]:
		"hüpfen":
			_visual.position.y = absf(beat) * 0.08
			_visual.rotation.y = sin(t * 2.0) * 0.4
			_arm_l.rotation.x = -1.2 + beat * 0.6
			_arm_r.rotation.x = -1.2 - beat * 0.6
		"wiegen":
			# Langsam von einer Seite zur anderen, Arme leicht ausgebreitet
			_visual.position.y = 0.0
			_visual.rotation.z = sin(t * 1.8) * 0.12
			_visual.rotation.y = sin(t * 0.9) * 0.25
			_arm_l.rotation.x = -0.3
			_arm_r.rotation.x = -0.3
			_arm_l.rotation.z = -0.6 + sin(t * 1.8) * 0.2
			_arm_r.rotation.z = 0.6 + sin(t * 1.8) * 0.2
		"drehen":
			# Pirouetten mit ausgestreckten Armen
			_visual.position.y = absf(sin(t * 3.0)) * 0.03
			_visual.rotation.y += delta * 3.2
			_arm_l.rotation.x = 0.0
			_arm_r.rotation.x = 0.0
			_arm_l.rotation.z = -1.4
			_arm_r.rotation.z = 1.4
		"arme hoch":
			# Arme über dem Kopf, im Takt winken
			_visual.position.y = absf(beat) * 0.05
			_visual.rotation.y = sin(t * 1.0) * 0.2
			_arm_l.rotation.x = -2.9 + beat * 0.15
			_arm_r.rotation.x = -2.9 - beat * 0.15
			_arm_l.rotation.z = -0.25 + beat * 0.2
			_arm_r.rotation.z = 0.25 + beat * 0.2
		"twist":
			# Schnelles Hin- und Herdrehen, in die Knie gehen
			_visual.position.y = -0.06 + sin(t * 3.0) * 0.05
			_visual.rotation.y = sin(t * 9.0) * 0.6
			_arm_l.rotation.x = -1.0 + sin(t * 9.0) * 0.3
			_arm_r.rotation.x = -1.0 - sin(t * 9.0) * 0.3
		"schunkeln":
			# Seitlich wippen, Arme angewinkelt vor dem Körper
			_visual.position.y = absf(sin(t * 2.5)) * 0.03
			_visual.rotation.z = sin(t * 2.5) * 0.2
			_visual.rotation.y = 0.0
			_arm_l.rotation.x = -1.5
			_arm_r.rotation.x = -1.5
			_arm_l.rotation.z = -0.3
			_arm_r.rotation.z = 0.3


## Schreckhaltung (6.12): Hände hoch und zittern (flee), Hand vor den Mund (freeze), zusammengesunken
## mit den Händen vorm Gesicht (cry). Hypnotisiert: Arme hängen, leises Schwanken. Gewürgt: Hände am
## Hals, zappeln.
func _shock_pose() -> void:
	var t := _anim
	if state == State.GHOSTED:
		_visual.rotation.y = sin(t * 11.0) * 0.12
		_visual.rotation.x = 0.12
		_arm_l.rotation = Vector3(-2.5 + sin(t * 13.0) * 0.15, 0, 0.55)
		_arm_r.rotation = Vector3(-2.5 - sin(t * 13.0) * 0.15, 0, -0.55)
		return
	if _entranced:
		_visual.rotation.z = sin(t * 0.9) * 0.04
		_arm_l.rotation.x = 0.0
		_arm_r.rotation.x = 0.0
		return
	match _shock_style:
		"flee":
			var shake := sin(t * 23.0) * 0.08
			_visual.rotation.x = 0.1   # weicht zurück
			_arm_l.rotation = Vector3(-2.8 + shake, 0, -0.35)
			_arm_r.rotation = Vector3(-2.8 - shake, 0, 0.35)
		"cry":
			_visual.rotation.x = -0.3
			_visual.position.y = -0.06 + absf(sin(t * 7.0)) * 0.015   # Schluchzen
			_arm_l.rotation = Vector3(-2.3, 0, 0.5)
			_arm_r.rotation = Vector3(-2.3, 0, -0.5)
		_:
			_arm_l.rotation = Vector3(-0.15, 0, 0)
			_arm_r.rotation = Vector3(-2.1, 0, -0.6)


func _make_arm(side: float, coat: Material, skin: Material) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = Vector3(side * 0.26, 1.42, 0)
	_visual.add_child(pivot)
	Geo.mesh(pivot, Geo.box(Vector3(0.1, 0.55, 0.11)), coat, Vector3(0, -0.27, 0))
	Geo.mesh(pivot, Geo.box(Vector3(0.08, 0.1, 0.09)), skin, Vector3(0, -0.6, 0))
	return pivot


func _update_label() -> void:
	var p := Game.player
	var d := p.global_position.distance_to(global_position) if p else INF
	_label.visible = hiding == null and d > 2.2 and d < 7.0 and state != State.TALKING


func _animate(delta: float) -> void:
	_anim += delta
	var speed := Vector2(velocity.x, velocity.z).length()
	_pose(delta, speed)
	if _body and visible:
		_body.animate(delta, speed, running, [_arm_l, _arm_r], _arms_free, state == State.MINIGAME and seated)


func _pose(delta: float, speed: float) -> void:
	_arms_free = false
	if state == State.PARTY and speed < 0.1:
		_dance_pose(delta)
		return
	_dance = -1
	if _body:
		_body.dance = ""
	_visual.position.y = 0.0
	_visual.rotation = Vector3.ZERO
	_arm_l.rotation.z = 0.0
	_arm_r.rotation.z = 0.0
	if state in [State.SHOCKED, State.GHOSTED]:
		_shock_pose()
		return
	if state == State.SLEEP and hiding:
		# schläft auf dem Rücken im Bett, Arme an der Seite, atmet ruhig
		_visual.position.y = 0.13 + sin(_anim * 1.6) * 0.006
		_visual.rotation.x = PI / 2.0
		_arm_l.rotation = Vector3(0, 0, -0.15)
		_arm_r.rotation = Vector3(0, 0, 0.15)
		return
	if state == State.MINIGAME and seated:
		_visual.position.y = -(_body.sit_drop() if _body else 0.35)   # sitzt
		_arm_l.rotation.x = -1.1 + sin(_anim * 3.0) * 0.05
		_arm_r.rotation.x = -1.1
		return
	if running:
		_arm_l.rotation.x = -2.6 + sin(_anim * 14.0) * 0.3   # Arme hoch – Panik
		_arm_r.rotation.x = -2.6 - sin(_anim * 14.0) * 0.3
	elif held:
		_arm_l.rotation.x = -1.2
		_arm_r.rotation.x = -1.2
	else:
		var swing := sin(_anim * 6.0) * clampf(speed * 0.35, 0.0, 0.6)
		_arm_l.rotation.x = swing
		_arm_r.rotation.x = -swing
		_arms_free = true
