class_name DartMatch
extends TableMatch
## Darts an der Scheibe in der Bar (Spielkonzept 6.10): 301 mit einfachem Aus gegen einen Gast – oder allein üben.
##
## Man steht an der Linie und zielt mit der Maus; der Blick schwankt leicht (Atmen). Linksklick halten macht ihn enger
## und ruhiger (nach STEADY_TIME am ruhigsten, ab TIRE_AFTER zittert der Arm), Loslassen wirft – mit Streuung, mehr bei
## hastigem Wurf oder bewegter Maus. Rausch, Kaffeezittern, Schock und Müdigkeit (Player.weakness) machen es schwerer.
## Der Gast wirft nach seiner Treffsicherheit (profile["darts"]["skill"]) und sucht sich am Ende das passende Feld.
## Schummeln: über die Linie treten – näher dran trifft man besser, aber der Gast steht daneben (dice.perception).
## Lärm macht jeder Pfeil (dart, dart_wall); Einsätze, Beziehung und Revanche wie bei Schach.

const PLAYER_FLIGHT := Color(0.75, 0.08, 0.06)
const GUEST_FLIGHT := Color(0.1, 0.25, 0.7)
## Zielen: Blickwinkel an der Linie und beim ruhigen Zielen (Anteil von Settings.fov)
const ZOOM_IDLE := 0.5
const ZOOM_AIM := 0.27
## Schwanken des Blicks (rad), beim Halten bis auf STEADY_MIN davon nach STEADY_TIME s; ab TIRE_AFTER s wieder mehr
const SWAY := 0.01
const STEADY_MIN := 0.35
const STEADY_TIME := 0.9
const TIRE_AFTER := 2.6
const TIRE_RATE := 0.6
## Zittern (rad): zu viel Kaffee, Schock (× shock)
const TREMOR_JITTER := 0.0025
const TREMOR_SHOCK := 0.005
## Streuung beim Loslassen (rad, Standardabweichung); hastig (kürzer als QUICK s gehalten) mal QUICK_FACTOR; je
## 1000 px/s Mausbewegung MOUSE_SPREAD dazu
const SPREAD := 0.0065
const QUICK := 0.25
const QUICK_FACTOR := 1.7
const MOUSE_SPREAD := 0.008
## Gast: Streuung in m von schwach bis sicher
const GUEST_SIGMA := Vector2(0.065, 0.017)
const GUEST_GAP := 1.1          ## Pause zwischen zwei Pfeilen des Gastes
const PULL_TIME := 1.6          ## Pfeile ziehen nach einer Aufnahme
const HAND := Vector3(0.11, -0.085, -0.26)   ## Pfeil in der Hand vor der Kamera
const DEFAULT_PROFILE := {"likes": false, "skill": 0.4, "pride": 0.5}
## Sätze für Gäste ohne eigene (feste Profile und GuestGenerator haben sie)
const LINES := {
	"darts_yes": ["Darts? Na gut, ein Spiel."],
	"darts_no": ["Nein, jetzt nicht."],
	"darts_win": ["Gewonnen!"],
	"darts_lose": ["Gut geworfen."],
	"darts_challenge": ["Lust auf eine Runde Darts an der Bar?"],
	"darts_caught": ["He! Du stehst ja fast an der Scheibe! So nicht."],
}
const GOOD_VISIT_LINES := ["Na also!", "So wird das gemacht.", "Hast du das gesehen?", "Ha!"]
const PLAYER_VISIT_LINES := ["Nicht schlecht …", "Oha.", "Glückstreffer.", "Hm. Gut geworfen."]

var board: DartBoard

var _practice := false
var _rest := [Darts.START, Darts.START]   ## 0 = Spieler, 1 = Gast
var _visits := [0, 0]
var _turn := 0
var _visit_start := Darts.START
var _visit_darts: Array[String] = []
var _flying := false
var _wait := 0.0
var _then := Callable()
var _over_line := false
var _cheat_visit := false       ## in dieser Aufnahme über der Linie geworfen
var _off_board := 0             ## nüchtern neben die Scheibe geworfen – absichtlich verlieren?
var _hold := -1.0               ## ≥ 0: Linksklick gehalten seit so vielen s
var _sway_time := 0.0
var _sway := Vector2.ZERO       ## schon auf den Blick gelegt
var _hand_dart: Node3D
var _score_label: Label
var _visit_label: Label


func _ready() -> void:
	var panel := _build_panel(Color(0.04, 0.05, 0.06, 0.82), 5, Vector4(0.02, 0.03, 0.4, 0.42))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	panel.add_child(box)
	_title = UiKit.plain_label(9, Color(0.95, 0.75, 0.4))
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_title)
	_score_label = UiKit.plain_label(11, Color(0.95, 0.93, 0.88))
	box.add_child(_score_label)
	_visit_label = UiKit.plain_label(9, Color(0.75, 0.8, 0.7))
	box.add_child(_visit_label)
	_log = UiKit.plain_label(8, Color(0.9, 0.88, 0.85))
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log.custom_minimum_size = Vector2(0, 30)
	box.add_child(_log)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 0)
	box.add_child(list)
	_options = list


func _table() -> GameTable:
	return board


func _gear() -> Item.Kind:
	return Item.Kind.DARTS


# --- Treffsicherheit der Gäste ---------------------------------------------------------

static func darts_profile(p_guest: Guest) -> Dictionary:
	return p_guest.profile.get("darts", DEFAULT_PROFILE)


static func line_of(p_guest: Guest, key: String) -> String:
	var lines: Dictionary = p_guest.profile["lines"]
	return p_guest.line(key) if lines.has(key) else String(LINES[key][randi() % LINES[key].size()])


## Streuung in m: je sicherer, desto enger; Angst und Rausch machen sie größer.
static func sigma_of(p_guest: Guest) -> float:
	var skill := float(darts_profile(p_guest)["skill"])
	return lerpf(GUEST_SIGMA.x, GUEST_SIGMA.y, skill) * (1.0 + p_guest.fear / 120.0 + p_guest.drunk * 1.5)


## Für Menüs und Zuschauer: „wirft sicher“ …
static func strength_text(p_guest: Guest) -> String:
	var skill := float(darts_profile(p_guest)["skill"])
	return "wirft unsicher" if skill < 0.35 else ("wirft ordentlich" if skill < 0.7 else "wirft sicher")


# --- Start ----------------------------------------------------------------------------

## Kann jetzt mit diesem Gast gespielt werden? Gibt einen Grund zurück oder "".
func why_not(p_guest: Guest) -> String:
	if active or board == null or Game.table_game_active():
		return "Gerade nicht."
	if board.busy:
		return "An der Dartscheibe wird schon gespielt."
	if not board.has_darts(Game.player):
		return "Die Dartpfeile fehlen."
	if p_guest.is_child():
		return "Pfeile sind nichts für Kinder."
	return _guest_unwilling(p_guest)


## stake: {"money": int, "item": bool}
func start(p_guest: Guest, stake: Dictionary) -> void:
	_practice = false
	_reset()
	_begin(p_guest, stake, Vector3(0.12, 0.01, -0.05))   # Pfeile auf den Stehtisch, falls du sie in der Hand hast
	_update_board()
	_say("%s kommt an die Linie …" % guest.display_name)
	_clear()
	_option("Doch nicht spielen", _abort.bind("Du legst die Pfeile wieder hin."))
	if Game.tracing:
		print("[Darts] gegen %s (Streuung %.1f cm)" % [guest.display_name, sigma_of(guest) * 100.0])


## Allein werfen: 301 ohne Gegner und ohne Ende – zum Üben.
func practice() -> void:
	if active or board == null or Game.table_game_active():
		return
	_practice = true
	_reset()
	guest = null
	active = true
	_over = false
	_abort_timer = -1.0
	board.busy = true
	var player := Game.player
	if player.held_kind() == Item.Kind.DARTS:
		var gear := player.held
		player.drop_held()
		gear.global_position = board.top_center() + Vector3(0, 0.01, 0)
	_take_places()
	visible = true
	_waiting_for_seat = true
	_update_board()
	if Game.tracing:
		print("[Darts] allein")


func _reset() -> void:
	_rest = [Darts.START, Darts.START]
	_visits = [0, 0]
	_turn = 0
	_visit_start = Darts.START
	_visit_darts.clear()
	_flying = false
	_wait = 0.0
	_then = Callable()
	_over_line = false
	_cheat_visit = false
	_off_board = 0
	_hold = -1.0
	_sway = Vector2.ZERO


func _take_places() -> void:
	var player := Game.player
	if player.held:   # beide Hände frei – was du hältst, legst du auf den Stehtisch
		var item := player.held
		player.drop_held(false, false)
		item.global_position = board.stake_spot(-1) + Vector3(-0.08, 0, -0.12)
	player.stand_at(board.throw_spot(false), board.bull())
	player.fov_zoom = ZOOM_IDLE
	if guest:
		guest.stand_for_game(board.guest_seat.global_position, board.bull())
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_hand_dart = DartModel.build(PLAYER_FLIGHT)
	player.camera.add_child(_hand_dart)
	_hand_dart.position = HAND
	_hand_dart.basis = Basis.looking_at(Vector3(-0.15, 0.1, -1.0))
	_hand_dart.visible = false


func _leave_places() -> void:
	Game.player.leave_oche()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if is_instance_valid(_hand_dart):
		_hand_dart.queue_free()
	board.clear_darts()


func _on_seated() -> void:
	if _practice:
		_say("Linksklick halten: ruhig zielen · loslassen: werfen.")
	else:
		_say("Du fängst an. Linksklick halten: ruhig zielen · loslassen: werfen.")
	_player_turn()


func _stop() -> void:
	_hold = -1.0
	_then = Callable()
	if is_instance_valid(_hand_dart):
		_hand_dart.visible = false
	Game.player.fov_zoom = ZOOM_IDLE


func _update_game(delta: float) -> void:
	if _practice and not _over and _danger():
		_abort("Du lässt die Pfeile sinken – irgendetwas stimmt hier nicht.")
		return
	if _wait > 0.0:
		_wait -= delta
		if _wait <= 0.0 and _then.is_valid():
			var next := _then
			_then = Callable()
			next.call()
		return
	if _still_playing() and _turn == 0 and not _flying and not _waiting_for_seat:
		_aim(delta)


## Allein an der Scheibe: Vorwarnung in der Nähe?
func _danger() -> bool:
	return not Game.director.is_quiet(board.global_position, 20.0) or Game.director.long_signal_near(board.global_position)


func _after(seconds: float, next: Callable) -> void:
	_wait = seconds
	_then = next


# --- Zielen und werfen (Spieler) ------------------------------------------------------------

func _player_turn() -> void:
	_turn = 0
	_hand_dart.visible = true
	_hold = -1.0
	_update_board()
	_clear()
	if _practice:
		_option("Von vorn", _restart_practice)
		_option("Aufhören", _end)
	else:
		_option("Wieder hinter die Linie" if _over_line else "Über die Linie treten", _step_line)
		_option("Aufgeben", _resign)


func _aim(delta: float) -> void:
	var player := Game.player
	_sway_time += delta
	var holding := Input.is_action_pressed("use_item")
	if holding:
		_hold = maxf(_hold, 0.0) + delta
	var steady := clampf(_hold / STEADY_TIME, 0.0, 1.0) if _hold >= 0.0 else 0.0
	var amount := SWAY * (1.0 + 1.5 * player.weakness()) * (1.0 + 2.5 * BarTap.sway(player.drunk))
	amount *= lerpf(1.0, STEADY_MIN, steady) + maxf(0.0, _hold - TIRE_AFTER) * TIRE_RATE
	var t := _sway_time
	var sway := Vector2(sin(t * 0.83 * TAU) + 0.5 * sin(t * 1.9 * TAU + 1.3),
		sin(t * 0.61 * TAU + 0.7) + 0.5 * sin(t * 1.37 * TAU)) * amount / 1.5
	var tremor := (TREMOR_JITTER if player.jittery() else 0.0) + player.shock * TREMOR_SHOCK
	sway += Vector2(sin(t * 71.0) + sin(t * 113.0), sin(t * 89.0) + sin(t * 61.0)) * tremor * 0.5
	var step := sway - _sway
	_sway = sway
	player.rotation.y -= step.x
	player.head.rotation.x = clampf(player.head.rotation.x + step.y, -1.45, 1.45)
	player.fov_zoom = lerpf(ZOOM_IDLE, ZOOM_AIM, steady)
	_hand_dart.position = HAND + Vector3(0, 0.015, 0.05) * steady
	if not holding and _hold >= 0.0:
		_player_throw()


## Loslassen: Strahl aus der Mitte des Blicks mit Streuung auf die Scheibe.
func _player_throw() -> void:
	var player := Game.player
	var cam := player.camera
	var spread := SPREAD * (1.0 + 1.2 * player.weakness())
	if _hold < QUICK:
		spread *= QUICK_FACTOR
	spread += Input.get_last_mouse_screen_velocity().length() / 1000.0 * MOUSE_SPREAD
	var dir := -cam.global_basis.z
	dir = dir.rotated(cam.global_basis.y, randfn(0.0, spread)).rotated(cam.global_basis.x, randfn(0.0, spread))
	var hit: Variant = board.ray_to_board(cam.global_position, dir)
	_throw_at(hit if hit != null else Vector2(9, 9))


func _throw_at(p: Vector2) -> void:
	var cam := Game.player.camera
	_hold = -1.0
	_flying = true
	_hand_dart.visible = false
	if _over_line:
		_cheat_visit = true
	board.throw_dart(cam.to_global(HAND), p, PLAYER_FLIGHT, _landed.bind(0))


func _step_line() -> void:
	_over_line = not _over_line
	var look := Game.player.head.rotation.x
	var yaw := Game.player.rotation.y
	Game.player.stand_at(board.throw_spot(_over_line), board.bull())
	Game.player.head.rotation.x = look
	Game.player.rotation.y = yaw
	_say("Du stellst dich ein gutes Stück vor die Linie …" if _over_line else "Du trittst wieder hinter die Linie.")
	_player_turn()


func _resign() -> void:
	_say("Du legst die Pfeile hin und gibst auf.")
	_finish("guest")


func _restart_practice() -> void:
	board.clear_darts()
	_reset()
	_say("Neues Spiel: 301.")
	_player_turn()


# --- Ein Pfeil ist gelandet ---------------------------------------------------------------

func _landed(hit: Dictionary, who: int) -> void:
	_flying = false
	if not _still_playing():
		return
	if who == 0 and not hit["board"] and Game.player.weakness() < 0.3 and not Game.player.jittery():
		_off_board += 1
	var result := Darts.apply(_rest[who], int(hit["value"]), _visit_start)
	_visit_darts.append(String(hit["text"]))
	if result["bust"]:
		_rest[who] = _visit_start
		_say("%s – überworfen! Die Aufnahme zählt nicht." % hit["text"])
		_end_visit(who)
		return
	_rest[who] = int(result["rest"])
	if result["won"]:
		_update_board()
		if _practice:
			_say("%s – geschafft, in %d Aufnahmen!" % [hit["text"], _visits[0] + 1])
			_visits[0] += 1
			_after(PULL_TIME, _restart_practice)
		else:
			_say("%s – genau auf null!" % hit["text"])
			_finish("player" if who == 0 else "guest")
		return
	_update_board()
	if _visit_darts.size() >= Darts.DARTS_PER_VISIT:
		_end_visit(who)
	elif who == 0:
		_hand_dart.visible = true
	else:
		_after(GUEST_GAP, _guest_dart)


func _end_visit(who: int) -> void:
	var scored := _visit_start - int(_rest[who])
	if not _practice:
		var name := "Du" if who == 0 else guest.display_name
		_say("%s: %s = %d. Rest %d." % [name, " · ".join(_visit_darts), scored, _rest[who]])
		if who == 1 and scored >= 100 and randf() < 0.5:
			guest.say(GOOD_VISIT_LINES[randi() % GOOD_VISIT_LINES.size()])
		elif who == 0 and scored >= 100 and randf() < 0.4:
			guest.say(PLAYER_VISIT_LINES[randi() % PLAYER_VISIT_LINES.size()])
	_visits[who] += 1
	_update_board()
	_clear()
	if who == 0 and _cheat_visit and not _practice and _noticed_cheat():
		return
	_after(PULL_TIME, _next_visit.bind(who))


func _next_visit(last: int) -> void:
	board.clear_darts()
	_visit_darts.clear()
	_cheat_visit = false
	if not _practice and _visits[1] >= Darts.MAX_VISITS:
		var diff := int(_rest[0]) - int(_rest[1])
		_say("Zehn Aufnahmen vorbei – Rest %d gegen %d." % [_rest[0], _rest[1]])
		_finish("draw" if diff == 0 else ("player" if diff < 0 else "guest"))
		return
	_turn = 0 if _practice or last == 1 else 1
	_visit_start = _rest[_turn]
	if _turn == 0:
		_player_turn()
	else:
		_hand_dart.visible = false
		_update_board()
		_guest_dart()


# --- Der Gast wirft -----------------------------------------------------------------------

func _guest_dart() -> void:
	if not _still_playing():
		return
	var target := Darts.target_for(_rest[1], float(darts_profile(guest)["skill"]))
	_flying = true
	board.guest_throw(guest, Darts.aim_point(int(target["number"]), target["ring"]), sigma_of(guest), GUEST_FLIGHT,
		_landed.bind(1))


## Über die Linie getreten – sieht der Gast es? Er steht direkt daneben.
func _noticed_cheat() -> bool:
	var dice: Dictionary = guest.profile["dice"]
	if randf() >= float(dice["perception"]) * 0.9 + 0.15:
		return false
	_over = true
	_stop()
	var said := line_of(guest, "darts_caught")
	guest.say(said)
	_say("%s: „%s“ – die Partie ist geplatzt, %s nimmt die Einsätze." % [guest.display_name, said, guest.display_name])
	Game.social.change_relation(guest, -25.0)
	Game.social.on_cheat_caught(guest)
	_stakes.give_to_guest(guest)
	_clear()
	_option("Weggehen", _end)
	return true


# --- Ende -------------------------------------------------------------------------------

## result: "player", "guest" oder "draw"
func _finish(result: String) -> void:
	_over = true
	_stop()
	_hand_dart.visible = false
	var darts := darts_profile(guest)
	var change := 5.0 + (3.0 if darts["likes"] else 0.0)     # gemeinsame Zeit
	var line := ""
	match result:
		"player":
			change -= float(darts["pride"]) * 8.0                # Stolz gekränkt
			line = line_of(guest, "darts_lose")
			if float(darts["pride"]) > 0.5:
				guest.challenge_cooldown = randf_range(90.0, 150.0)
				guest.challenge_game = "darts"
				Game.social.queue_rematch(guest)
			_stakes.take_for_player()
		"guest":
			line = line_of(guest, "darts_win")
			if int(_rest[0]) <= 30:
				change += 3.0                                     # knapp verloren freut ihn
			if _off_board >= 3:
				# Nüchtern dreimal neben die Scheibe? Ein guter Werfer merkt, dass du ihn gewinnen lässt.
				_threw_game = true
				if randf() < float(darts["skill"]) * 0.7 + 0.2:
					change -= 10.0
					line = guest.line("patronized")
				else:
					change += 6.0
			_stakes.give_to_guest(guest)
		_:
			change += 4.0                                         # Gleichstand freut beide
			line = "Unentschieden. Gutes Spiel."
			_stakes.split(guest)
	Game.social.add_deed(guest, "games")   # gemeinsame Partie zählt für „guter Freund“ (6.3)
	Game.social.requests.on_game_played(guest, "darts")   # seine Bitte um eine Partie (6.14)
	Game.social.change_relation(guest, change)
	var stakes_text := " Die Einsätze liegen auf dem Stehtisch – nimm sie dir." if result == "player" and _stakes.any_left() else ""
	_say("%s %s: „%s“%s" % [_log.text, guest.display_name, line, stakes_text])
	_update_board()
	if Game.tracing:
		print("[Darts] Ende nach %d Aufnahmen: %s (Rest %d : %d)" % [_visits[0], {"player": "du gewinnst",
			"guest": "%s gewinnt" % guest.display_name}.get(result, "unentschieden"), _rest[0], _rest[1]])
	_clear()
	_option("Weggehen", _end)


## Für automatische Tests (--autoplay): Der Spieler wirft selbst ein Feld mit mäßiger Streuung an, sonst die erste
## Option. Gibt aus, was passiert ist.
func debug_step() -> String:
	if not active:
		return ""
	if _still_playing() and _turn == 0 and not _flying and _wait <= 0.0 and not _waiting_for_seat:
		var target := Darts.target_for(_rest[0], 0.6)
		var p := Darts.scatter(Darts.aim_point(int(target["number"]), target["ring"]), 0.035)
		_throw_at(p)
		return "Du wirfst auf %s%d (Rest %d)" % [["", "", "D", "T", "", ""][target["ring"]], target["number"], _rest[0]]
	if _over and not _buttons.is_empty():
		var info := _log.text
		_buttons[0].pressed.emit()
		return info
	return ""


# --- Hilfen -----------------------------------------------------------------------------

func _update_board() -> void:
	var stakes := _stakes.labels()
	if _practice:
		_title.text = "Darts allein   ·   301, einfaches Aus"
		_score_label.text = "Rest %d   ·   Aufnahme %d" % [_rest[0], _visits[0] + 1]
	elif guest:
		_title.text = "Darts mit %s (%s)   ·   Einsatz: %s" % [guest.display_name, strength_text(guest),
			"keiner" if stakes.is_empty() else ", ".join(stakes)]
		_score_label.text = "Du %d   ·   %s %d   ·   Aufnahme %d/%d" % [_rest[0], guest.display_name, _rest[1],
			mini(_visits[_turn] + 1, Darts.MAX_VISITS), Darts.MAX_VISITS]
	var shown: Array[String] = _visit_darts.duplicate()
	while shown.size() < Darts.DARTS_PER_VISIT:
		shown.append("–")
	_visit_label.text = "%s: %s%s" % ["Du" if _turn == 0 else (guest.display_name if guest else "Du"), "  ".join(shown),
		"   (über der Linie)" if _over_line and _turn == 0 else ""]
