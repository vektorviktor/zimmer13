class_name DoorContest
extends Node
## Der Anfang: Türschmuck-Wettbewerb (Spielkonzept 2.5). Gibt dem friedlichen Anfang (2.1) ein Ziel mit Frist – die
## Siegerehrung am 2. Oktober um 20 Uhr in der Lobby ist der erste Angriff.
##   · Willkommensbrief auf dem Schreibtisch in Zimmer 13 (statt eines Einführungstexts) und ein kurzer Gedanke dazu
##   · Aushangbrett in der Lobby (NoticeBoard): Wettbewerb und Hausordnung, nach dem Angriff der veränderte Aushang
##   · Durchsagen der Direktion zu festen Uhrzeiten (Gong und Einblendung)
##   · Siegerehrung: Die Gäste versammeln sich um die Puppe (Jury) und warten auf den Spieler, spätestens bis 22 Uhr.
##     Sein Blick wird zur Puppe gezogen (die Steuerung ist gesperrt), sie steigt auf, schwebt und löst sich in Rauch
##     auf – das einzige Mal, dass sie sich vor seinen Augen bewegt (5.5). Dann geht das Licht aus, das Monster steht in
##     der dunklen Ecke der Lobby (MonsterDirector.first_attack_in_lobby)
##   · Die Regel danach: Warnungszettel von 1999 am Morgen danach unter der Tür von Zimmer 13, Gäste reden am Brett,
##     beim ersten Urteil der Puppe ein Satz im Tagebuch
##   · Notizbuch (3.10): steckt im Umschlag des Briefs, erste Aufgabe ist die eigene Tür (bei der Siegerehrung
##     durchgestrichen bzw. „zu spät“); Durchsagen und Aushänge kommen als Notiz hinein, Ankunft, Siegerehrung und
##     erstes Urteil als Meilensteine ins Tagebuch
## Erreichbar über Game.contest; gespeichert unter „contest“ (save_state/load_state).

enum Stage { CONTEST, GATHERING, SCENE, DONE }

const THOUGHT := "Da liegt ein Brief auf dem Schreibtisch."
const LETTER_TITLE := "Hotel – Mitteilung der Direktion"
const LETTER_TEXT := "Verehrter Gast,\nherzlich willkommen in Zimmer 13. Wir wünschen Ihnen einen schaurig-schönen Oktober.\n\nWie jedes Jahr lädt die Direktion zum Türschmuck-Wettbewerb: Die Jury kürt am 2. Oktober um 20 Uhr in der Lobby die schönste Tür. Alles Weitere finden Sie am Brett in der Lobby.\n\nDie Direktion"
## Erster Tagebucheintrag – Satz des Startstands und am 1. Oktober, sobald der Brief gelesen ist
const ARRIVAL_ENTRY := "Angekommen. Zimmer 13 ist hübsch, wenn auch etwas altmodisch. Morgen Abend kürt eine Jury die schönste Tür – ich brauche Deko."
## Meilensteine im Tagebuch (3.10): Siegerehrung mit bzw. ohne den Spieler, erster Angriff auf anderem Weg (Debug)
const CEREMONY_ENTRY := "Die Siegerehrung. Die Puppe ist aufgestanden, über uns geschwebt und in einer Rauchwolke verschwunden. Dann ging das Licht aus, und in der Ecke der Lobby stand etwas. Einen Sieger gab es nicht."
const CEREMONY_MISSED_ENTRY := "Die Siegerehrung habe ich verpasst. Unten erzählen sie, die Puppe sei aufgestanden und in Rauch aufgegangen – und als das Licht ausging, habe in der Ecke etwas gestanden."
const FIRST_SIGHT_ENTRY := "Heute habe ich es zum ersten Mal gesehen. Ich weiß nicht, was es ist. Ich weiß nur, dass es mich auch gesehen hat."
## Erste Aufgabe im Notizbuch (3.10)
const TASK_ID := "contest"
const TASK_TEXT := "Meine Tür schmücken"
const TASK_DUE := "bis 2. Okt., 20 Uhr"
const POSTER_TITLE := "Aushang der Direktion"
const POSTER_HEAD := "HALLOWEEN\nIM HOTEL"
const POSTER_BEFORE := "Großer Türschmuck-Wettbewerb\n\nVerehrte Gäste, schmücken Sie Ihre Zimmertür!\nDie Jury kürt am 2. Oktober um 20 Uhr in der Lobby die schönste Tür.\nDie Jury sieht nur, was im Licht hängt.\n\nDie Direktion"
const POSTER_AFTER := "Die Jury hat entschieden.\nVon nun an besucht sie die Tür, die am wenigsten zu bieten hat.\nDie Jury sieht nur, was im Licht hängt.\n\nDie Direktion"
const RULES_TITLE := "Hausordnung"
const RULES_TEXT := "Nachtruhe von 23 bis 6 Uhr.\nDie Bar schließt um Mitternacht.\nZu Ihrer Sicherheit bleibt der Haupteingang nachts verschlossen.\n\nDie Direktion"
## Was die Figur sich vom Brett notiert (3.10): vorher, nachher, Hausordnung
const POSTER_BEFORE_JOT := "Türschmuck-Wettbewerb: Die Jury kürt am 2. Okt. um 20 Uhr die schönste Tür. Sie sieht nur, was im Licht hängt."
const POSTER_AFTER_JOT := "Der Aushang ist ein anderer: Die Jury besucht jetzt die Tür, die am wenigsten zu bieten hat. Sie sieht nur, was im Licht hängt."
const RULES_JOT := "Hausordnung: Nachtruhe 23–6 Uhr, die Bar schließt um Mitternacht, der Haupteingang bleibt nachts zu."
## Durchsagen: Tag, Uhrzeit, Text, Notiz im Notizbuch – verpasste (Uhr vorgestellt, Schlaf) holt das Spiel höchstens
## eine Spielstunde später nach
const ANNOUNCEMENTS := [
	[1, 15.5, "Verehrte Gäste, herzlich willkommen. Die Direktion lädt zum Türschmuck-Wettbewerb. Die Jury kürt morgen um 20 Uhr in der Lobby die schönste Tür.",
		"Willkommen. Türschmuck-Wettbewerb: Die Jury kürt morgen um 20 Uhr in der Lobby die schönste Tür."],
	[2, 12.0, "Verehrte Gäste, noch acht Stunden bis zur Siegerehrung. Die Jury freut sich auf Ihre Türen.",
		"Noch acht Stunden bis zur Siegerehrung."],
	[2, 19.75, "Verehrte Gäste, die Jury bittet in einer Viertelstunde in die Lobby.",
		"Die Jury bittet in einer Viertelstunde in die Lobby."],
	[2, 20.0, "Die Siegerehrung beginnt, sobald alle Gäste versammelt sind.",
		"Die Siegerehrung beginnt, sobald alle versammelt sind."],
]
const ANNOUNCE_LATE := 60.0
## Siegerehrung: Tag und Stunde, spätestens dann ohne den Spieler
const CEREMONY_DAY := 2
const CEREMONY_HOUR := 20.0
const CEREMONY_LATEST := 22.0
## Der Spieler steht so lange in der Lobby, dann geht es los – sobald so viele Versammelte an ihrem Platz stehen, sonst
## nach WAIT_FOR_GUESTS Sekunden
const START_DELAY := 4.0
const ARRIVED_SHARE := 0.7
const WAIT_FOR_GUESTS := 25.0
## Plätze um die Puppe: Raster, Abstand zu ihr (davor bleibt ein Halbkreis frei, damit man sie sieht), nur vor dem Sofa
const SPOT_GRID := 0.9
const SPOT_MIN := 2.6
const GATHER_LINES := ["Wo bleibt denn die Jury?", "Wer wohl gewinnt?", "Meine Tür ist die schönste, ganz klar.",
	"Die Puppe ist die Jury? Wie putzig.", "Wann geht's denn los?", "Hast du die Türen im Ostflügel gesehen? Wunderschön."]
const GATHER_TALK := Vector2(6.0, 12.0)
## Ablauf der Szene (s): Blick zur Puppe, sie steht auf und steigt, schwebt, Rauch, Licht aus
const T_TURN := 1.6
const T_RISE := 3.8
const T_VANISH := 6.0
const T_DARK := 7.5
const RISE_HEIGHT := 1.5   ## über die Köpfe der Versammelten
const GAZE_SPEED := 3.0
## Warnungszettel (WarningNote „1999“): ab dieser Stunde am Morgen nach dem Angriff, so weit hinter der Tür
const NOTE_HOUR := 6.0
const NOTE_INSIDE := 0.7
## Gerede am Brett am Tag nach dem Angriff: so viele Gäste zugleich, so oft kommt einer dazu, höchstens so oft am Tag
const READERS := 3
const READ_EVERY := 40.0
const READS_PER_DAY := 8
const BOARD_LINES := ["Hast du gelesen, was am Brett steht?", "„Die Jury hat entschieden“ … was soll das heißen?",
	"Wer hat den Zettel am Brett ausgetauscht?", "„Die Tür, die am wenigsten zu bieten hat“ … mir ist ganz kalt."]

var stage := Stage.CONTEST
var letter_read := false
var announced := 0            ## so viele Durchsagen sind vorbei
var note_delivered := false
var attack_day := 0           ## Tag der Siegerehrung (0 = noch nicht)
## Erstes Urteil der Puppe nach der Siegerehrung (Tagebuch): Zimmer, Satz, Tag
var verdict_room := ""
var verdict_text := ""
var verdict_day := 0
var board: NoticeBoard

var _builder: LevelBuilder
var _gathered: Array[Guest] = []
var _spot_of := {}            ## Gast-ID → Platz
var _spots: Array[Vector3] = []
var _next_spot := 0          ## nächster freier Platz in _spots
var _gather_check := 0.0
var _talk := 4.0
var _in_lobby := 0.0
var _scene_t := 0.0
var _with_player := false
var _vanished := false
var _doll_base := Vector3.ZERO
var _readers := {}            ## Gast-ID → Platz am Brett
var _read_timer := 20.0
var _reads_today := 0
var _read_day := 0
var _tick := 0.0
var _after_shown := false


func setup(builder: LevelBuilder) -> DoorContest:
	_builder = builder
	board = builder.notice_board
	_pin_board()
	if builder.diary:
		var letter := Letter.new()
		letter.contest = self
		builder.diary.get_parent().add_child(letter)
		letter.global_transform = builder.diary.global_transform * Transform3D(Basis.IDENTITY, Vector3(-0.3, 0.0, 0.0))
		_place_letter.call_deferred(letter)
	return self


## Brief neben das Tagebuch: der erste freie Platz auf dem Schreibtisch (Tischplatte darunter, nichts im Weg) – erst
## nach zwei Physikbildern, wenn alle Körper im Raum stehen.
func _place_letter(letter: Node3D) -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	var diary := _builder.diary
	var space := diary.get_world_3d().direct_space_state
	var box := BoxShape3D.new()
	box.size = Vector3(0.28, 0.06, 0.28)   # mit etwas Luft zu Telefon und Kerze
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = box
	query.collision_mask = 0xFFFF
	query.collide_with_areas = false
	query.exclude = [letter.get_rid()]
	for r: float in [0.3, 0.38]:
		for i in 12:
			var a := TAU * i / 12.0 + PI
			var at := diary.global_transform * Vector3(cos(a) * r, 0, sin(a) * r)
			query.transform = Transform3D(diary.global_basis, at + Vector3.UP * 0.045)
			if not space.intersect_shape(query, 1).is_empty():
				continue   # Telefon, Kerze, Gegenstand oder das Tagebuch selbst
			var on_desk := true
			for corner: Vector3 in [Vector3(-0.09, 0, -0.09), Vector3(0.09, 0, -0.09), Vector3(-0.09, 0, 0.09), Vector3(0.09, 0, 0.09)]:
				var p := at + diary.global_basis * corner
				var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.1, p + Vector3.DOWN * 0.1, 1))
				on_desk = on_desk and not hit.is_empty() and absf((hit["position"] as Vector3).y - diary.global_position.y) < 0.03
			if on_desk:
				letter.global_transform = Transform3D(diary.global_basis.rotated(Vector3.UP, a * 0.15), at)
				return


## Neues Spiel: nach dem Erwachen am Waschbecken (bzw. gleich beim Start) der Gedanke an den Brief.
func welcome() -> void:
	Game.say(THOUGHT, 3.5)


func on_letter_read() -> void:
	if not letter_read and Game.notebook:   # im Umschlag: das Notizbuch, darin gleich die erste Aufgabe (3.10)
		Game.notebook.give()
		if stage == Stage.CONTEST:
			Game.notebook.add_task(TASK_ID, TASK_TEXT, "Direktion", null, TASK_DUE)
	letter_read = true
	if Game.diary and stage == Stage.CONTEST:
		Game.diary.note("arrival", ARRIVAL_ENTRY)


## Tagebuchsatz (SaveManager.diary_sentence): nach dem ersten Urteil der Puppe dieser Satz (bis zum Tag danach), am
## 1. Oktober nach dem Brief die Ankunft – sonst "".
func diary_line() -> String:
	if verdict_text != "" and Calendar.today() <= verdict_day + 1:
		return verdict_text
	if letter_read and stage == Stage.CONTEST and Calendar.today() == 1:
		return ARRIVAL_ENTRY
	return ""


## Keine Feiern am Abend der Siegerehrung, bis sie vorbei ist (Social).
func holds_parties() -> bool:
	return stage in [Stage.GATHERING, Stage.SCENE] or (stage == Stage.CONTEST and Calendar.today() == CEREMONY_DAY)


## Die Gäste versammeln sich gerade (kein Besuch, kein Süßes oder Saures – Social).
func is_gathering() -> bool:
	return stage in [Stage.GATHERING, Stage.SCENE]


func in_scene() -> bool:
	return stage == Stage.SCENE


# --- Ablauf ---------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if Game.director == null or Game.game_over:
		return
	_update_announcements()
	if stage != Stage.DONE and stage != Stage.SCENE and Game.director.first_attack_done:
		_skip_to_done()   # der erste Angriff kam anders (Debug, alter Spielstand)
	match stage:
		Stage.CONTEST:
			if Game.director.elapsed >= Calendar.at(CEREMONY_DAY, CEREMONY_HOUR):
				_begin_gathering()
		Stage.GATHERING:
			_gathering_step(delta)
		Stage.SCENE:
			_scene_step(delta)
		Stage.DONE:
			_tick -= delta
			if _tick <= 0.0:
				_tick = 1.0
				_after_step()
	if board and _after_shown != Game.director.first_attack_done:
		_after_shown = Game.director.first_attack_done
		_pin_board()


func _pin_board() -> void:
	if board == null:
		return
	var after := Game.director != null and Game.director.first_attack_done
	board.pin("poster", Vector2(-0.22, 0.03), Vector2(0.46, 0.66), POSTER_HEAD, POSTER_AFTER if after else POSTER_BEFORE,
		POSTER_TITLE, POSTER_HEAD.replace("\n", " ") + "\n\n" + (POSTER_AFTER if after else POSTER_BEFORE),
		"board_after" if after else "board_before", POSTER_AFTER_JOT if after else POSTER_BEFORE_JOT)
	board.pin("rules", Vector2(0.33, 0.12), Vector2(0.34, 0.42), RULES_TITLE.to_upper(), RULES_TEXT, RULES_TITLE, RULES_TEXT,
		"board_rules", RULES_JOT)


func _update_announcements() -> void:
	var now := Game.director.elapsed
	while announced < ANNOUNCEMENTS.size():
		var a: Array = ANNOUNCEMENTS[announced]
		var at := Calendar.at(int(a[0]), float(a[1]))
		if now < at:
			return
		announced += 1
		if now - at < ANNOUNCE_LATE and stage != Stage.DONE:
			announce(String(a[2]), String(a[3]))


## Durchsage der Direktion (Spielkonzept 5.9): Gong, dann der Text – kurz gefasst ins Notizbuch (jot, 3.10).
func announce(text: String, jot: String = "") -> void:
	Game.play_sound("chime", 0.7)
	Game.say("Durchsage: „%s“" % text, 7.0)
	if Game.notebook:
		Game.notebook.add_note("", jot if jot != "" else text, "Durchsage")


func _skip_to_done() -> void:
	_release_guests(false)
	_settle_task()
	if Game.diary:
		Game.diary.note("first_attack", FIRST_SIGHT_ENTRY)
	stage = Stage.DONE
	attack_day = Calendar.today()
	if Game.doll:
		Game.doll.show_card(false)


# --- Siegerehrung -------------------------------------------------------------------------------

## loaded: aus einem Spielstand – die Gäste kommen erst beim nächsten Rundgang (sonst ließen sie gleich nach dem Laden
## fallen, was sie gespeichert in der Hand hielten).
func _begin_gathering(loaded: bool = false) -> void:
	stage = Stage.GATHERING
	_in_lobby = 0.0
	_gather_check = 5.0 if loaded else 0.0
	_spots = _gather_spots()
	_gathered.clear()
	_spot_of.clear()
	_next_spot = 0
	if loaded:
		return
	if Game.social.party_active:
		Game.social.end_party("Die Musik verstummt – alle gehen zur Siegerehrung in die Lobby.")
	_gather_guests()
	if Game.tracing:
		print("[Wettbewerb] Siegerehrung: %d Gäste kommen in die Lobby, %d Plätze" % [_gathered.size(), _spots.size()])


## Plätze vor der Puppe: Raster über die Lobby, auf dem NavMesh, nicht hinter dem Sofa – die nächsten zuerst.
func _gather_spots() -> Array[Vector3]:
	var result: Array[Vector3] = []
	var doll := Game.doll
	var forward := doll.global_basis.z
	forward = Vector3(forward.x, 0, forward.z).normalized()
	var front := Vector3(doll.global_position.x, 0, doll.global_position.z) + forward * 0.8
	var map := doll.get_world_3d().navigation_map
	var rect := _builder.lobby_rect.grow(-0.6)
	var x := rect.position.x
	while x <= rect.end.x:
		var z := rect.position.y
		while z <= rect.end.y:
			var p := Vector3(x, 0, z)
			var d := p - front
			z += SPOT_GRID
			if d.length() < SPOT_MIN or d.normalized().dot(forward) < -0.2:
				continue
			var snap := NavigationServer3D.map_get_closest_point(map, p)
			if Vector2(snap.x - p.x, snap.z - p.z).length() < 0.12 and absf(snap.y) < 0.3:
				result.append(snap)
		x += SPOT_GRID
	result.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.distance_to(front) < b.distance_to(front))
	return result


func _gather_guests() -> void:
	var look := _doll_look()
	for guest in Game.social.living_guests():
		var g: Guest = guest
		if g in _gathered or not _can_gather(g):
			continue
		if not _spot_of.has(g.id):   # wer zurückkommt, nimmt seinen alten Platz
			if _next_spot >= _spots.size():
				continue
			_spot_of[g.id] = _spots[_next_spot]
			_next_spot += 1
		g.join_party(_spot_of[g.id], look)
		if g.state == Guest.State.PARTY:
			_gathered.append(g)


func _can_gather(g: Guest) -> bool:
	return not g.dead and g.hiding == null and g.fear < 60.0 and g.wound_bed <= 0.0 and g.state in [Guest.State.IDLE,
		Guest.State.WALK, Guest.State.CARRY_HOME, Guest.State.PLACE_DECO, Guest.State.HARVEST]


func _doll_look() -> Vector3:
	return Game.doll.global_position + Vector3.UP * 0.35 * JuryDoll.SIZE


func _gathering_step(delta: float) -> void:
	_gather_check -= delta
	if _gather_check <= 0.0:
		_gather_check = 5.0
		_gathered = _gathered.filter(func(g: Guest) -> bool: return is_instance_valid(g) and not g.dead and g.state == Guest.State.PARTY)
		_gather_guests()
	_talk -= delta
	if _talk <= 0.0:
		_talk = randf_range(GATHER_TALK.x, GATHER_TALK.y)
		var near := _gathered.filter(func(g: Guest) -> bool: return g.global_position.distance_to(_spot_of[g.id]) < 2.0)
		if not near.is_empty():
			(near.pick_random() as Guest).say(GATHER_LINES.pick_random())
	var p := Game.player
	var here := p != null and not p.dead and _builder.in_lobby(p.global_position) and p.hiding == null \
		and not p.sleeping and not p.in_dialog and not (Game.menus and Game.menus.is_open())
	_in_lobby = _in_lobby + delta if here else 0.0
	if Game.director.other_threat_active(Game.monster):
		return   # Lakengeist oder Kürbismann im Haus – die Siegerehrung wartet
	if _in_lobby >= START_DELAY and (_arrived_share() >= ARRIVED_SHARE or _in_lobby >= WAIT_FOR_GUESTS):
		_begin_scene(true)
	elif Game.director.elapsed >= Calendar.at(CEREMONY_DAY, CEREMONY_LATEST):
		_begin_scene(false)


func _arrived_share() -> float:
	if _gathered.is_empty():
		return 1.0
	var there := _gathered.filter(func(g: Guest) -> bool: return g.global_position.distance_to(_spot_of[g.id]) < 1.5).size()
	return float(there) / _gathered.size()


func _begin_scene(with_player: bool) -> void:
	stage = Stage.SCENE
	_scene_t = 0.0
	_vanished = false
	_with_player = with_player
	_doll_base = Game.doll.global_position
	Game.doll.show_card(false)
	for g in _gathered:
		if g.is_child():
			g._laugh = T_DARK + 5.0   # auch die Kinder sind still
	_talk = T_DARK + 5.0
	if with_player:
		var p := Game.player
		p.leave_seat(true)
		if p.bag_open:
			p.close_bag(false)
		p.spellbound = true
		Game.say("Es wird still in der Lobby.", 2.5)
	if Game.tracing:
		print("[Wettbewerb] Die Puppe steht auf – %s" % ("vor dem Spieler" if with_player else "ohne den Spieler (22 Uhr)"))


func _scene_step(delta: float) -> void:
	_scene_t += delta
	var doll := Game.doll
	if _with_player:
		_pull_gaze(delta)
	if not _vanished:
		var k := smoothstep(T_TURN, T_RISE, _scene_t)
		doll.stand_pose(k)
		var hover := sin(maxf(0.0, _scene_t - T_RISE) * 2.4) * 0.04
		doll.global_position = _doll_base + Vector3.UP * (RISE_HEIGHT * k + hover)
		if _with_player and _scene_t > T_RISE:   # sie dreht sich zum Spieler
			var to := Game.player.global_position - doll.global_position
			doll.rotation.y = lerp_angle(doll.rotation.y, atan2(to.x, to.z), minf(1.0, delta * 1.5))
		if _scene_t >= T_VANISH:
			_vanished = true
			_puff(doll.global_position + Vector3.UP * 0.3 * JuryDoll.SIZE)
			Game.play_sound("poof", 0.8)
			doll.vanish()
	if _scene_t >= T_DARK:
		_end_scene()


## Kopf und Blick des Spielers sanft zur Puppe (kein Kameraschnitt, Spielkonzept 2.5).
func _pull_gaze(delta: float) -> void:
	var p := Game.player
	var target := Game.doll.global_position + Vector3.UP * 0.4 * JuryDoll.SIZE
	var to := target - p.camera.global_position
	var k := 1.0 - exp(-GAZE_SPEED * delta)
	p.rotation.y = lerp_angle(p.rotation.y, atan2(-to.x, -to.z), k)
	p.head.rotation.x = lerpf(p.head.rotation.x, clampf(atan2(to.y, Vector2(to.x, to.z).length()), -1.4, 1.4), k)


## Rauchwolke, in der sie verschwindet: graue Ballen, die aufquellen und verwehen.
func _puff(at: Vector3) -> void:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in 16:
		for x in 16:
			var d := Vector2(x - 7.5, y - 7.5).length() / 8.0
			img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d * d, 0.0, 1.0)))
	var mat := Mat.particle(ImageTexture.create_from_image(img))
	mat.set_shader_parameter("spin", 0.4)
	var smoke := Geo.particles(70, 1.8, 0.22, mat, 0.05, 0.7)
	smoke.color = Color(0.32, 0.31, 0.31)
	smoke.one_shot = true
	smoke.explosiveness = 0.9
	smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	smoke.emission_sphere_radius = 0.3
	smoke.direction = Vector3.UP
	smoke.spread = 180.0
	smoke.initial_velocity_min = 0.5
	smoke.initial_velocity_max = 1.4
	smoke.gravity = Vector3(0, 0.35, 0)
	smoke.damping_min = 1.0
	smoke.damping_max = 1.8
	smoke.scale_amount_min = 0.6
	smoke.scale_amount_max = 2.2
	get_parent().add_child(smoke)
	smoke.global_position = at
	smoke.emitting = true
	get_tree().create_timer(4.0, false).timeout.connect(smoke.queue_free)


## Licht aus, das Monster in der dunklen Ecke – der erste Angriff (harmlos, 2.1). Die Gäste fliehen heim.
func _end_scene() -> void:
	stage = Stage.DONE
	attack_day = Calendar.today()
	var sw := LightSwitch.find(get_tree(), "lobby")
	if sw:
		sw.set_on(false)
	Game.play_sound("bang", 0.6)
	if _with_player:
		Game.say("Das Licht geht aus.", 3.0)
		Game.player.spellbound = false
	Game.director.first_attack_in_lobby(_monster_corner(), _doll_base)
	_release_guests(true)
	_settle_task()
	if Game.diary:
		Game.diary.note("first_attack", CEREMONY_ENTRY if _with_player else CEREMONY_MISSED_ENTRY)
	if Game.tracing:
		print("[Wettbewerb] Licht aus – erster Angriff in der Lobby")


## Ecke der Lobby, die am weitesten vom Spieler (bzw. von der Puppe) weg ist – auf dem NavMesh.
func _monster_corner() -> Vector3:
	var rect := _builder.lobby_rect.grow(-1.0)
	var from := Game.player.global_position if _with_player else _doll_base
	var map := Game.doll.get_world_3d().navigation_map
	var best := Vector3.ZERO
	var best_d := -1.0
	for c: Vector2 in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]:
		var p := NavigationServer3D.map_get_closest_point(map, Vector3(c.x, 0, c.y))
		var d := Vector2(p.x - from.x, p.z - from.z).length()
		if d > best_d:
			best_d = d
			best = p
	return best


func _release_guests(scared: bool) -> void:
	var screams := 3
	for g in _gathered:
		if not is_instance_valid(g) or g.dead:
			continue
		g.leave_party()
		if scared:
			g.fear = maxf(g.fear, 75.0)
			g.take_cover()
			if screams > 0 and randf() < 0.3:
				screams -= 1
				Game.play_sound("scream", 0.8, g.global_position, g)
	_gathered.clear()
	_spot_of.clear()


# --- Danach ---------------------------------------------------------------------------------------

func _after_step() -> void:
	if not note_delivered and Game.director.elapsed >= Calendar.at(attack_day + 1, NOTE_HOUR):
		_deliver_note(true)
	_board_readers()


## Warnungszettel von 1999 hinter der Tür von Zimmer 13 – erst, wenn der Spieler die Stelle nicht sieht.
func _deliver_note(fresh: bool) -> void:
	var spot := _note_spot()
	if fresh and Game.player and Game.director.player_can_see(spot + Vector3.UP * 0.05):
		return
	note_delivered = true
	var note := WarningNote.new().setup("1999")
	get_parent().add_child(note)
	note.global_position = spot
	if fresh:
		Game.sound_at("rustle", spot, 6.0)
		if Game.tracing:
			print("[Wettbewerb] Zettel unter der Tür von Zimmer 13")


func _note_spot() -> Vector3:
	var room: Dictionary = _builder.rooms[LevelBuilder.PLAYER_ROOM]
	var door: Door = room["door"]
	var into: Vector3 = room["into"]
	var c := door.center()
	return Vector3(c.x, (room["door_front"] as Vector3).y, c.z) + into * NOTE_INSIDE


## Am Tag nach der Siegerehrung stehen Gäste vor dem Brett und reden darüber.
func _board_readers() -> void:
	if board == null or attack_day == 0 or Calendar.today() != attack_day + 1 or Game.social.sleep_active:
		return
	if _read_day != Calendar.today():
		_read_day = Calendar.today()
		_reads_today = 0
	for id in _readers.keys():
		var g := Game.social.guest_by_id(id)
		if g == null or g.dead or not g.state in [Guest.State.WALK, Guest.State.IDLE]:
			_readers.erase(id)
			continue
		var spot: Vector3 = _readers[id]
		if g.state == Guest.State.IDLE and Vector2(g.global_position.x - spot.x, g.global_position.z - spot.z).length() < 1.2:
			var to := board.global_position - g.global_position
			g.rotation.y = atan2(-to.x, -to.z)
			g._set_idle(randf_range(6.0, 10.0))
			g.say(BOARD_LINES.pick_random())
			_readers.erase(id)
	_read_timer -= 1.0
	if _read_timer > 0.0 or _readers.size() >= READERS or _reads_today >= READS_PER_DAY:
		return
	_read_timer = READ_EVERY * randf_range(0.6, 1.4)
	var idle := Game.social.living_guests().filter(func(g: Guest) -> bool:
		return not g.is_child() and g.state == Guest.State.IDLE and g.fear < 50.0 and not _readers.has(g.id))
	if idle.is_empty():
		return
	var reader: Guest = idle.pick_random()
	var spot := board.reading_spot(randf_range(-0.7, 0.7))
	_readers[reader.id] = spot
	_reads_today += 1
	reader._walk_to(spot, Guest.State.WALK)


## Die Puppe liegt vor der Tür ihres Urteils (JuryDoll) – das erste Mal nach der Siegerehrung kommt ins Tagebuch.
func on_doll_placed(room: String) -> void:
	if verdict_room != "" or stage != Stage.DONE:
		return
	verdict_room = room
	verdict_day = Calendar.today()
	var info: Dictionary = _builder.rooms[room]
	var deco := Game.director.deco_strength_at(info["door_front"])
	var where := "vor meiner Tür" if room == LevelBuilder.PLAYER_ROOM else "vor Zimmer %s" % String(info["sign"])
	var how := "An der Tür hing fast nichts." if deco < 1.0 else ("An der Tür hing nicht viel." if deco < 3.0 else "Dabei hing dort einiges.")
	verdict_text = "Die Puppe saß %s. %s" % [where, how]
	if Game.diary:
		Game.diary.note("first_verdict", verdict_text)


## Die Frist der ersten Aufgabe ist um (Siegerehrung): durchgestrichen, wenn vor der Tür etwas hängt, sonst „zu spät“.
func _settle_task() -> void:
	if Game.notebook == null or Game.notebook.task_state(TASK_ID) != Notebook.TaskState.OPEN:
		return
	if Game.director.deco_strength_at(Game.director.player_door_front) > 0.0:
		Game.notebook.finish_task(TASK_ID)
	else:
		Game.notebook.miss_task(TASK_ID)


# --- Spielstand -----------------------------------------------------------------------------------

func save_state() -> Dictionary:
	return {"stage": int(Stage.GATHERING if stage == Stage.SCENE else stage), "letter_read": letter_read,
		"announced": announced, "note_delivered": note_delivered, "attack_day": attack_day, "verdict_room": verdict_room,
		"verdict_text": verdict_text, "verdict_day": verdict_day}


## Ältere Stände ohne „contest“: Ist der erste Angriff schon gewesen, ist alles vorbei (der Zettel liegt nicht).
func load_state(d: Dictionary) -> void:
	_release_guests(false)
	var done := Game.director.first_attack_done
	stage = Stage.DONE if done else clampi(int(d.get("stage", Stage.CONTEST)), Stage.CONTEST, Stage.GATHERING) as Stage
	letter_read = bool(d.get("letter_read", done))
	announced = int(d.get("announced", ANNOUNCEMENTS.size() if done else 0))
	note_delivered = bool(d.get("note_delivered", done))
	attack_day = int(d.get("attack_day", Calendar.today() if done else 0))
	verdict_room = String(d.get("verdict_room", ""))
	verdict_text = String(d.get("verdict_text", ""))
	verdict_day = int(d.get("verdict_day", 0))
	if stage == Stage.GATHERING:
		_begin_gathering(true)
	if Game.doll:
		Game.doll.show_card(stage != Stage.DONE)
	if note_delivered and d.has("note_delivered") and get_tree().get_nodes_in_group("warning_notes").all(
			func(n: Node) -> bool: return (n as WarningNote).note_id != "1999"):
		_deliver_note(false)
	_after_shown = not done   # Brett beim nächsten Bild passend neu anheften


# --- Debug ----------------------------------------------------------------------------------------

## --siegerehrung[=ohne]: Uhr auf 20 Uhr am 2. Oktober (falls früher), die Gäste stehen gleich an ihren Plätzen; der
## Spieler steht im freien Halbkreis vor der Puppe (ohne: er bleibt, wo er ist, und die Uhr springt auf 22 Uhr).
func debug_ceremony(without_player: bool) -> void:
	var at := Calendar.at(CEREMONY_DAY, CEREMONY_LATEST if without_player else CEREMONY_HOUR)
	Game.director.elapsed = maxf(Game.director.elapsed, at)
	announced = ANNOUNCEMENTS.size()
	if stage == Stage.CONTEST:
		_begin_gathering()
	for g in _gathered:
		g.global_position = _spot_of[g.id] + Vector3(0, 0.05, 0)
	if not without_player:
		var doll := Game.doll.global_position
		var forward := Game.doll.global_basis.z
		forward = Vector3(forward.x, 0, forward.z).normalized()
		var spot := NavigationServer3D.map_get_closest_point(Game.doll.get_world_3d().navigation_map,
			Vector3(doll.x, 0, doll.z) + forward * (SPOT_MIN + 0.6))
		TeleportUI.place_player(spot, -forward)


## --brett[=nachher]: Spieler vor das Aushangbrett (nachher: der erste Angriff gilt als geschehen).
func debug_board(after: bool) -> void:
	if after:
		Game.director.first_attack_done = true
	TeleportUI.place_player(board.reading_spot(0.0) + board.global_basis.z * 0.4, -board.global_basis.z)
	Game.player.head.rotation.x = deg_to_rad(4.0)


## --brief: Spieler am Schreibtisch in Zimmer 13, Blick auf den Brief.
func debug_letter() -> void:
	await get_tree().create_timer(0.3).timeout   # der Brief sucht sich erst seinen Platz (_place_letter)
	for node in get_tree().get_nodes_in_group("contest_letters"):
		var letter := node as Node3D
		var center: Vector3 = _builder.rooms[LevelBuilder.PLAYER_ROOM]["center"]
		var dir := Vector3(center.x - letter.global_position.x, 0, center.z - letter.global_position.z).normalized()
		var pos := letter.global_position + dir * 0.75
		TeleportUI.place_player(Vector3(pos.x, center.y, pos.z), -dir)
		Game.player.head.rotation.x = -0.8


## --zettel: erster Angriff gilt als geschehen, der Zettel liegt sofort, Spieler davor mit Blick hinunter.
func debug_note() -> void:
	Game.director.first_attack_done = true
	_skip_to_done()
	if not note_delivered:
		_deliver_note(false)
	var room: Dictionary = _builder.rooms[LevelBuilder.PLAYER_ROOM]
	var into: Vector3 = room["into"]
	var spot := _note_spot()
	TeleportUI.place_player(spot + into * 1.2, -into)
	Game.player.head.rotation.x = -0.9


## Der Willkommensbrief auf dem Schreibtisch in Zimmer 13: Umschlag mit Wachssiegel, darauf der aufgefaltete Brief.
class Letter:
	extends StaticBody3D

	var contest: DoorContest

	func _ready() -> void:
		collision_layer = 4
		collision_mask = 0
		set_meta("interactable", self)
		add_to_group("contest_letters")
		Geo.mesh(self, Geo.box(Vector3(0.17, 0.004, 0.12)), Mat.psx(Color(0.86, 0.8, 0.66)), Vector3(0, 0.002, 0))
		Geo.mesh(self, Geo.cylinder(0.014, 0.004, 8), Mat.psx(Color(0.55, 0.06, 0.05)), Vector3(0, 0.005, 0.0))   # Siegel
		var sheet := Geo.mesh(self, Geo.box(Vector3(0.15, 0.003, 0.2)), Mat.psx(Color(0.93, 0.9, 0.82)), Vector3(0.03, 0.006, -0.02))
		sheet.rotation.y = 0.25
		for i in 5:
			var line := Geo.mesh(self, Geo.box(Vector3(0.1 - (0.03 if i == 4 else 0.0), 0.004, 0.004)), Mat.psx(Color(0.2, 0.15, 0.12)),
				Vector3(0.03, 0.007, -0.08 + i * 0.03))
			line.rotation.y = 0.25
		Geo.add_box_shape(self, Vector3(0.24, 0.06, 0.24), Vector3(0, 0.03, 0))

	func get_prompt(_player: Player) -> String:
		return "Brief lesen [E]"

	func interact(_player: Player) -> void:
		if Game.menus:
			Game.menus.open_note(LETTER_TITLE, LETTER_TEXT)
		if contest:
			contest.on_letter_read()
