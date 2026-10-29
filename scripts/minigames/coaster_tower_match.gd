class_name CoasterTowerMatch
extends BarMatch
## Bierdeckel-Turm am Würfeltisch (Spielkonzept 6.10): Ihr legt abwechselnd je einen Deckel auf den Turm. Deine Hand
## wackelt (Nadel) – leg auf, wenn sie in der grünen Mitte ist. Jeder schiefe Deckel bringt den Turm in Schräglage,
## gerade Deckel richten ihn wieder etwas auf. Wer ihn umwirft, verliert; steht er bei MAX_HEIGHT, ist es
## unentschieden. Rausch, Schock, Müdigkeit und zu viel Kaffee lassen die Hand zittern (player_shake).
## Spielgerät: der Bierdeckel-Stapel aus dem Spieleschrank.

const MAX_HEIGHT := 24
const LEAN_KEEP := 0.88           ## so viel Schräglage bleibt je Deckel
const LEAN_ADD := 0.5             ## so viel bringt ein Deckel mit voll ausgeschlagener Nadel
const FALL := 0.75                ## ab dieser Schräglage stürzt der Turm
const GUEST_SIGMA := Vector2(0.55, 0.12)   ## Streuung des Gastes, unsicher … sicher

var _height := 0
var _lean := 0.0
var _turn := ""
var _t := 0.0
var _gauge: BarGauge


func _init() -> void:
	super("bierdeckel", "deckel", false)


func _build_view() -> void:
	_gauge = BarGauge.new()
	_gauge.zone = 0.25
	_view_box.add_child(_gauge)


func _reset() -> void:
	_height = 0
	_lean = 0.0


func _score_text() -> String:
	return "Turm: %d Deckel%s" % [_height, " – er wackelt!" if absf(_lean) > FALL * 0.6 else ""]


func _on_seated() -> void:
	_player_turn("Du fängst an.")


func _player_turn(intro: String) -> void:
	_turn = "player"
	_update_title()
	_say("%s Leg einen Deckel auf, wenn deine Hand ruhig ist (grüne Mitte)." % intro)
	_clear()
	_option("Auflegen", _player_place)
	_option("Absichtlich anstoßen", _knock)


## Die Nadel schwingt umso weiter und schneller, je höher der Turm und je zittriger die Hand.
func _update_game(delta: float) -> void:
	if _turn != "player" or _over:
		return
	_t += delta
	var shake := player_shake()
	var amp := 0.35 + shake * 0.55 + _height * 0.015
	var speed := 1.7 + _height * 0.06 + shake * 1.4
	_gauge.set_value(sin(_t * speed) * amp + sin(_t * 13.0) * shake * 0.15 + _lean * 0.2)


func _player_place() -> void:
	if _turn != "player":
		return
	_turn = ""
	_place(_gauge.value, "player")


func _place(off: float, who: String) -> void:
	_height += 1
	_lean = _lean * LEAN_KEEP + off * LEAN_ADD
	_update_title()
	if absf(_lean) >= FALL:
		_collapse(who)
		return
	if _height >= MAX_HEIGHT:
		_say("%d Deckel – der Turm steht! Keiner will mehr ran." % _height)
		_clear()
		_option("Weiter", _finish.bind(0))
		return
	if who == "player":
		_guest_turn()
	else:
		_player_turn("%s legt einen Deckel auf%s." % [guest.display_name, " – der Turm schwankt bedenklich" if absf(_lean) > FALL * 0.6 else ""])


func _guest_turn() -> void:
	_clear()
	_say("%s legt vorsichtig einen Deckel auf …" % guest.display_name)
	await get_tree().create_timer(1.6, false).timeout
	if not _still_playing():
		return
	var skill := float(profile_of(guest, id)["skill"])
	var sigma := lerpf(GUEST_SIGMA.x, GUEST_SIGMA.y, skill) * (1.0 + guest_shake(guest) * 1.5) * (1.0 + _height * 0.05)
	_place(clampf(randfn(0.0, sigma) + _lean * 0.2, -1.0, 1.0), "guest")


func _collapse(who: String) -> void:
	Game.noise("coasters", table.global_position, Game.player)
	_say("Der Turm kippt – %d Deckel prasseln über den Tisch! %s" % [_height,
		"Du hast ihn umgeworfen." if who == "player" else "%s hat ihn umgeworfen." % guest.display_name])
	_clear()
	_option("Weiter", _finish.bind(-1 if who == "player" else 1, who == "player" and _height > 10))


func _knock() -> void:
	_threw_game = true
	_turn = ""
	_height += 1
	_collapse("player")


## Für automatische Tests: beim Auflegen auf eine ruhige Stelle warten (sonst zufällig wie alle Barspiele).
func debug_press_random() -> String:
	if _turn == "player" and absf(_gauge.value) > _gauge.zone and randf() < 0.7:
		return ""
	return super()
