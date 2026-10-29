class_name SchockenMatch
extends BarMatch
## Schocken am Würfeltisch (Spielkonzept 6.10, Regeln in Schocken): eine Hälfte mit 13 Bierdeckeln in der Mitte.
## Wer anfängt, würfelt bis zu dreimal und legt damit fest, wie oft der andere darf. Der Verlierer der Runde bekommt
## die Deckel – erst aus der Mitte, dann vom Gewinner – und fängt die nächste Runde an. Ist die Mitte leer und hat
## einer keinen Deckel mehr, ist er raus und hat gewonnen; Schock aus beendet die Hälfte sofort.
## Gezinkte Würfel im Becher (GameTable.loaded, wie beim Mäxchen): einmal „gezinkt würfeln“ – riskant.

const MAX_THROWS := 3

var _middle := Schocken.DECKEL
var _deckel_player := 0
var _deckel_guest := 0
var _starter := ""                ## wer die Runde anfängt
var _limit := MAX_THROWS          ## so oft darf der Zweite
var _first: Array[int] = []       ## Wurf des Anfangenden
var _first_throws := 0
var _dice: Array[int] = []
var _throws := 0
var _cheat_used := false
var _dice_view: DiceView


func _init() -> void:
	super("schocken", "wuerfel", false)


func _build_view() -> void:
	_dice_view = DiceView.new()
	_dice_view.custom_minimum_size = Vector2(80, 24)
	_view_box.add_child(_dice_view)


func _reset() -> void:
	_middle = Schocken.DECKEL
	_deckel_player = 0
	_deckel_guest = 0
	_cheat_used = false
	if _dice_view:
		_dice_view.hide_dice()


func _score_text() -> String:
	return "Deckel: du %d · %s %d · Mitte %d" % [_deckel_player, guest.display_name, _deckel_guest, _middle]


func _on_seated() -> void:
	_start_round("guest" if randf() < 0.5 else "player")


# --- Runden ----------------------------------------------------------------------

func _start_round(starter: String) -> void:
	_starter = starter
	_limit = MAX_THROWS
	_first = []
	_update_title()
	if starter == "player":
		_player_turn("Neue Runde – du fängst an.")
	else:
		_guest_turn("Neue Runde – %s fängt an." % guest.display_name)


func _player_turn(intro: String) -> void:
	_throws = 0
	_dice = []
	_say(intro + (" Du darfst %d× würfeln." % _limit if _starter != "player" else ""))
	_player_throw(false)


func _player_throw(keep_ones: bool) -> void:
	_dice = Schocken.reroll(_dice, keep_ones) if not _dice.is_empty() else Schocken.roll(3)
	_throws += 1
	_rattle()
	_show_player_options()


func _show_player_options() -> void:
	_dice_view.show_dice(_dice)
	var text := "Wurf %d: %s." % [_throws, Schocken.label(_dice)]
	if _starter != "player":
		text += " Zu schlagen: %s (%d Würfe)." % [Schocken.label(_first), _first_throws]
	_say(text)
	_clear()
	_option("Stehen lassen", _player_stand)
	if _throws < _limit:
		if _dice.has(1) and _dice.count(1) < 3:
			_option("Einsen liegen lassen, nachwürfeln", _player_throw.bind(true))
		_option("Alle nachwürfeln", _player_throw.bind(false))
	if table.loaded and not _cheat_used and _throws < _limit:
		_option("Gezinkt würfeln (riskant)", _cheat)
	_option("Absichtlich verlieren", _throw_round)


func _player_stand() -> void:
	_clear()
	if _starter == "player":
		_first = _dice.duplicate()
		_first_throws = _throws
		_limit = _throws
		_guest_turn("Du lässt %s stehen (%d %s)." % [Schocken.label(_dice), _throws, "Wurf" if _throws == 1 else "Würfe"])
	else:
		_settle_round(_first, _first_throws, _dice, _throws, false)


func _guest_turn(intro: String) -> void:
	_clear()
	_dice_view.hide_dice()
	_say("%s %s würfelt …" % [intro, guest.display_name])
	var dice: Array[int] = []
	var throws := 0
	var skill := float(profile_of(guest, id)["skill"]) * (1.0 - 0.4 * guest.drunk)
	while throws < _limit:
		dice = Schocken.reroll(dice, true) if not dice.is_empty() else Schocken.roll(3)
		throws += 1
		_rattle()
		await get_tree().create_timer(1.0, false).timeout
		if not _still_playing():
			return
		_dice_view.show_dice(dice)
		if _guest_stands(dice, throws, skill):
			break
	var text := "%s lässt %s stehen (%d %s)." % [guest.display_name, Schocken.label(dice), throws, "Wurf" if throws == 1 else "Würfe"]
	if _starter == "guest":
		_first = dice
		_first_throws = throws
		_limit = throws
		await get_tree().create_timer(1.0, false).timeout
		if _still_playing():
			_player_turn(text)
	else:
		_say(text)
		await get_tree().create_timer(1.2, false).timeout
		if _still_playing():
			_settle_round(_first, _first_throws, dice, throws, true)


## Bleibt der Gast stehen? Als Zweiter, sobald er vorn liegt; als Erster bei einem guten Wurf – wer gut spielt,
## wagt bei einer mittleren Hausnummer noch einen Wurf.
func _guest_stands(dice: Array[int], throws: int, skill: float) -> bool:
	if _starter == "player":
		return Schocken.beats(dice, throws, _first, _first_throws, false)
	var score := Schocken.score(dice)
	var target := int(lerpf(540.0, 1004.0, skill))
	return score >= target or (score >= 2000)


## first: Wurf des Anfangenden, second: Wurf des Zweiten. guest_second: der Gast hat als Zweiter gewürfelt.
func _settle_round(first: Array[int], first_throws: int, second: Array[int], second_throws: int, guest_second: bool) -> void:
	var second_wins := Schocken.beats(second, second_throws, first, first_throws, false)
	var winner_dice := second if second_wins else first
	var guest_won := second_wins == guest_second
	var loser := "player" if guest_won else "guest"
	var count := Schocken.deckel(winner_dice)
	var text := "%s gewinnt mit %s. " % [guest.display_name if guest_won else "Du", Schocken.label(winner_dice)]
	if count >= Schocken.DECKEL:
		_give(loser, Schocken.DECKEL, true)
		text += "Schock aus – alle Deckel für %s!" % ("dich" if loser == "player" else guest.display_name)
	else:
		var moved := _give(loser, count, false)
		text += "%d Deckel für %s." % [moved, "dich" if loser == "player" else guest.display_name]
	_update_title()
	_say(text)
	_clear()
	var done := (_middle == 0 and (_deckel_player == 0 or _deckel_guest == 0)) or _deckel_player >= Schocken.DECKEL \
		or _deckel_guest >= Schocken.DECKEL
	if done:
		_option("Weiter", _end_half)
	else:
		_option("Nächste Runde", _start_round.bind(loser))


## Deckel an den Verlierer: aus der Mitte, ist sie leer, vom Gewinner. Gibt zurück, wie viele es waren.
func _give(loser: String, count: int, all: bool) -> int:
	if all:
		_middle = 0
		_deckel_player = Schocken.DECKEL if loser == "player" else 0
		_deckel_guest = Schocken.DECKEL if loser == "guest" else 0
		return Schocken.DECKEL
	var moved := 0
	if _middle > 0:
		moved = mini(count, _middle)
		_middle -= moved
	else:
		moved = mini(count, _deckel_guest if loser == "player" else _deckel_player)
		if loser == "player":
			_deckel_guest -= moved
		else:
			_deckel_player -= moved
	if loser == "player":
		_deckel_player += moved
	else:
		_deckel_guest += moved
	return moved


func _end_half() -> void:
	var player_won := _deckel_guest > _deckel_player
	_finish(1 if player_won else -1, not player_won and _deckel_player < Schocken.DECKEL)


# --- Schummeln & absichtlich verlieren ----------------------------------------------

func _cheat() -> void:
	_cheat_used = true
	_throws += 1
	_dice = [1, 1, 1]
	if randf() < 0.5:
		_dice[2] = 6
	_rattle()
	if randf() < float(guest.profile["dice"]["perception"]) * 0.7:
		table.loaded = false   # die gezinkten Würfel sind aufgeflogen
		_caught_cheating(guest.line("caught_cheat"))
		return
	_show_player_options()


func _throw_round() -> void:
	_threw_game = true
	_dice = [2, 2, 1]
	_say("Du lässt absichtlich eine kleine Hausnummer stehen.")
	_player_stand()


func _rattle() -> void:
	Game.noise("dice", table.global_position, Game.player)   # Würfeln ist laut (4.15)
	Game.play_sound("blip", 0.2)
