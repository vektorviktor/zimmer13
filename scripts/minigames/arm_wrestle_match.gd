class_name ArmWrestleMatch
extends BarMatch
## Armdrücken am Würfeltisch (Spielkonzept 6.10): Ellbogen auf den Tisch, auf „Los!“ drückt der Gast gleichmäßig
## mit seiner Kraft, du mit jedem Druck auf [1]. Wer schwach ist (Rausch, Schock, Müdigkeit – Schwäche 4.18),
## drückt weniger. Wer den anderen Arm auf den Tisch drückt, gewinnt die Runde; zwei Runden gewinnen die Partie.
## Schummeln: den Ellbogen anheben – mehr Hebel, aber der Gast sieht genau hin.

const WIN_ROUNDS := 2
const PUSH := 0.075               ## so weit bringt dich ein Druck (ohne Schwäche)
const GUEST_FORCE := Vector2(0.25, 0.75)   ## Kraft des Gastes je Sekunde, schwach … stark
const ROUND_TIME := 25.0          ## danach ist die Runde unentschieden und wird wiederholt
const COUNTDOWN := 1.2

var _score_player := 0
var _score_guest := 0
var _pos := 0.0
var _running := false
var _countdown := 0.0
var _time := 0.0
var _elbow := false
var _gauge: BarGauge


func _init() -> void:
	super("armdruecken", "", false)


func _build_view() -> void:
	_gauge = BarGauge.new()
	_gauge.tug = true
	_gauge.zone = 0.0
	_view_box.add_child(_gauge)


func _reset() -> void:
	_score_player = 0
	_score_guest = 0
	_running = false
	_pos = 0.0
	if _gauge:
		_gauge.set_value(0.0)


func _score_text() -> String:
	return "Du %d : %d %s" % [_score_player, _score_guest, guest.display_name]


func _on_seated() -> void:
	_start_round()


func _start_round() -> void:
	_pos = 0.0
	_time = 0.0
	_elbow = false
	_countdown = COUNTDOWN
	_running = true
	_gauge.set_value(0.0)
	_update_title()
	_say("Ihr fasst euch an den Händen … Drei, zwei, eins – los! (Taste 1 so schnell wie möglich)")
	_clear()
	_option("Drücken!", _push)
	_option("Ellbogen heben (schummeln)", _cheat)
	_option("Absichtlich nachgeben", _give_in)


func _push() -> void:
	if not _running or _countdown > 0.0:
		return
	var weak := Game.player.weakness()
	_pos += PUSH * (1.0 - 0.6 * weak) * (1.6 if _elbow else 1.0) * randf_range(0.8, 1.2)


func _update_game(delta: float) -> void:
	if not _running or _over:
		return
	if _countdown > 0.0:
		_countdown -= delta
		return
	_time += delta
	var skill := float(profile_of(guest, id)["skill"])
	var force := lerpf(GUEST_FORCE.x, GUEST_FORCE.y, skill) * (1.0 - 0.5 * guest.weakness())
	_pos -= force * delta * randf_range(0.6, 1.4)   # er drückt ungleichmäßig, mal mehr, mal weniger
	_gauge.set_value(_pos)
	if _elbow and randf() < float(guest.profile["dice"]["perception"]) * 0.6 * delta:
		_running = false
		_caught_cheating("Ellbogen bleibt auf dem Tisch! So nicht.")
		return
	if _pos >= 1.0:
		_round_over("player")
	elif _pos <= -1.0:
		_round_over("guest")
	elif _time >= ROUND_TIME:
		_running = false
		_say("Keiner gibt nach – die Arme zittern. Noch mal von vorn.")
		_clear()
		_option("Neu ansetzen", _start_round)


func _round_over(winner: String) -> void:
	_running = false
	Game.noise("arm_slam", table.global_position, Game.player)
	if winner == "player":
		_score_player += 1
	else:
		_score_guest += 1
	_update_title()
	_say("Rums! %s" % ("Sein Handrücken liegt auf dem Tisch – Runde für dich." if winner == "player"
		else "Dein Handrücken liegt auf dem Tisch – Runde für %s." % guest.display_name))
	_clear()
	if _score_player >= WIN_ROUNDS or _score_guest >= WIN_ROUNDS:
		_option("Weiter", func() -> void: _finish(1 if _score_player > _score_guest else -1, _score_player == 1))
	else:
		_option("Nächste Runde", _start_round)


func _cheat() -> void:
	if _elbow:
		return
	_elbow = true
	_say("Du hebst den Ellbogen ein Stück an – mehr Hebel …")


func _give_in() -> void:
	_threw_game = true
	_pos = -1.0


func _stop() -> void:
	_running = false
