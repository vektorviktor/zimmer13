class_name DrinkDuelMatch
extends BarMatch
## Trinkduell am Würfeltisch (Spielkonzept 6.10, 3.7): Runde um Runde trinkt jeder ein Glas (je BarTap.PRICE Geld,
## jeder zahlt seins) – der Rausch ist echt und bleibt. Nach jedem Glas die Standprobe: Halte dich gerade, wenn die
## Nadel in der Mitte ist; die Mitte wird mit jedem Glas schmaler. Wer schwankt oder nicht mehr kann, verliert;
## können beide nicht mehr (BarTap.ENOUGH), ist es unentschieden. Nichts für Kinder.

const TOLERANCE := Vector2(0.35, 0.95)   ## ab diesem Rausch kommt der Gast ins Schwanken, verträgt wenig … viel

var _round := 0
var _turn := ""
var _t := 0.0
var _gauge: BarGauge


func _init() -> void:
	super("trinkduell", "", true)


func _build_view() -> void:
	_gauge = BarGauge.new()
	_view_box.add_child(_gauge)


func _reset() -> void:
	_round = 0
	_turn = ""


func _score_text() -> String:
	return "Gläser: %d" % _round


func why_not(p_guest: Guest) -> String:
	var reason := super(p_guest)
	if reason == "" and Game.money < BarTap.PRICE:
		return "Ohne Geld kein Trinkduell."
	return reason


func _on_seated() -> void:
	_offer_round("Zwei Gläser stehen bereit.")


func _offer_round(text: String) -> void:
	_turn = ""
	_update_title()
	_say(text)
	_clear()
	_option("Prost! (%d Geld)" % BarTap.PRICE, _drink, Game.money < BarTap.PRICE)
	_option("Aufgeben", _give_up)


func _drink() -> void:
	var player := Game.player
	var guest_done := guest.drunk >= BarTap.ENOUGH or guest.money < BarTap.PRICE
	var player_done := player.drunk >= BarTap.ENOUGH or Game.money < BarTap.PRICE
	if player_done and guest_done:
		_say("Keiner von euch kriegt noch ein Glas runter.")
		_clear()
		_option("Weiter", _finish.bind(0))
		return
	if player_done:
		_say("Du hast genug – das Glas bleibt stehen.")
		_clear()
		_option("Weiter", _finish.bind(-1, true))
		return
	if guest_done:
		_say("%s schiebt das Glas weg: „Ich … nein. Du hast gewonnen.“" % guest.display_name)
		_clear()
		_option("Weiter", _finish.bind(1))
		return
	_round += 1
	Game.money -= BarTap.PRICE
	guest.money -= BarTap.PRICE
	player.drink(true)
	guest.drink()
	Game.play_sound("blip", 0.25)
	_update_title()
	_turn = "player"
	_t = 0.0
	_gauge.zone = clampf(0.45 - BarTap.sway(player.drunk) * 0.3, 0.1, 0.45)
	_say("Ihr kippt das %d. Glas. Jetzt gerade halten – wenn die Nadel in der Mitte ist." % _round)
	_clear()
	_option("Gerade stehen", _stand)


## Die Nadel schwankt mit dem Rausch – erst sanft, dann weit und unruhig.
func _update_game(delta: float) -> void:
	if _turn != "player" or _over:
		return
	_t += delta
	var sway := BarTap.sway(Game.player.drunk)
	var shake := player_shake()
	_gauge.set_value(sin(_t * (1.4 + sway * 1.6)) * (0.3 + sway * 0.6) + sin(_t * 7.3) * shake * 0.2)


func _stand() -> void:
	if _turn != "player":
		return
	_turn = ""
	var player_ok := absf(_gauge.value) <= _gauge.zone
	var tolerance := lerpf(TOLERANCE.x, TOLERANCE.y, float(profile_of(guest, id)["skill"]))
	var guest_ok := randf() >= clampf((guest.drunk - tolerance) * 2.5 + guest.fear / 300.0, 0.0, 0.95)
	var text := "Du stehst kerzengerade." if player_ok else "Du schwankst – fast wärst du vom Hocker gekippt."
	text += " " + ("%s hält sich wacker." % guest.display_name if guest_ok else "%s schwankt bedenklich." % guest.display_name)
	_clear()
	if player_ok and guest_ok:
		_offer_round(text + " Noch eins?")
	elif player_ok:
		_say(text)
		_option("Weiter", _finish.bind(1))
	elif guest_ok:
		_say(text)
		_option("Weiter", _finish.bind(-1, _round >= 2))
	else:
		_say(text + " Unentschieden!")
		_option("Weiter", _finish.bind(0))


func _give_up() -> void:
	_finish(-1, _round >= 2, "Du schiebst das Glas weg.")


func debug_press_random() -> String:
	if _turn == "player" and absf(_gauge.value) > _gauge.zone and randf() < 0.7:
		return ""
	return super()
