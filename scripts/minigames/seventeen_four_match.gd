class_name SeventeenFourMatch
extends BarMatch
## 17 und 4 mit dem Kartenspiel aus dem Spieleschrank (Spielkonzept 6.10): Skatblatt mit 32 Karten – Sieben bis
## Zehn zählen ihre Augen, Bube 2, Dame 3, König 4, Ass 11. Du ziehst zuerst, so viele Karten du willst; über 21
## hast du verloren, zwei Asse („Feuer“) zählen als 21. Dann zieht der Gast, bis er dich schlägt oder es ihm zu
## heiß wird. Wer näher an 21 ist, gewinnt die Runde, Gleichstand zählt nicht; zwei Runden gewinnen.
## Schummeln: einmal eine Karte aus dem Ärmel ziehen.

const WIN_ROUNDS := 2
const SUITS := ["Kreuz", "Pik", "Herz", "Karo"]
const RANKS := {"7": 7, "8": 8, "9": 9, "10": 10, "Bube": 2, "Dame": 3, "König": 4, "Ass": 11}

var _deck: Array[String] = []
var _hand_player: Array[String] = []
var _hand_guest: Array[String] = []
var _score_player := 0
var _score_guest := 0
var _sleeve_used := false


func _init() -> void:
	super("siebzehn", "karten", false)


func _reset() -> void:
	_score_player = 0
	_score_guest = 0
	_sleeve_used = false


func _score_text() -> String:
	return "Du %d : %d %s" % [_score_player, _score_guest, guest.display_name]


static func card_value(card: String) -> int:
	return int(RANKS[card.split(" ")[1]])


## Wert einer Hand: Summe, zwei Asse allein sind „Feuer“ (21).
static func hand_value(hand: Array[String]) -> int:
	if hand.size() == 2 and card_value(hand[0]) == 11 and card_value(hand[1]) == 11:
		return 21
	var total := 0
	for card in hand:
		total += card_value(card)
	return total


func _on_seated() -> void:
	_start_round()


func _start_round() -> void:
	_deck.clear()
	for suit in SUITS:
		for rank in RANKS:
			_deck.append("%s %s" % [suit, rank])
	_deck.shuffle()
	_hand_player = [_deck.pop_back(), _deck.pop_back()]
	_hand_guest = []
	_update_title()
	_shuffle_sound()
	_player_options("%s mischt und gibt." % guest.display_name)


func _player_options(intro: String) -> void:
	var value := hand_value(_hand_player)
	_say("%s Deine Karten: %s – zusammen %d." % [intro, ", ".join(_hand_player), value])
	_clear()
	_option("Noch eine Karte", _draw)
	_option("Genug", _guest_draws)
	if not _sleeve_used:
		_option("Karte aus dem Ärmel (schummeln)", _sleeve)
	_option("Absichtlich überziehen", _bust_on_purpose)


func _draw() -> void:
	_hand_player.append(_deck.pop_back())
	_shuffle_sound()
	if hand_value(_hand_player) > 21:
		_round_over("guest", "Du ziehst %s – %d, überzogen!" % [_hand_player.back(), hand_value(_hand_player)])
		return
	_player_options("Du ziehst %s." % _hand_player.back())


func _sleeve() -> void:
	_sleeve_used = true
	var need := 21 - hand_value(_hand_player)
	var best := ""
	for rank in RANKS:   # die Karte, die am nächsten an 21 bringt, ohne zu überziehen
		if int(RANKS[rank]) <= need and (best == "" or int(RANKS[rank]) > card_value(best)):
			best = "Herz %s" % rank
	if best == "":
		_player_options("Im Ärmel steckt nichts, was jetzt hilft.")
		return
	_hand_player.append(best)
	if randf() < float(guest.profile["dice"]["perception"]) * 0.6:
		_caught_cheating("Die Karte kam aus deinem Ärmel! Ich hab's gesehen!")
		return
	_player_options("Du schiebst %s aus dem Ärmel in deine Hand." % best)


func _bust_on_purpose() -> void:
	_threw_game = true
	while hand_value(_hand_player) <= 21:
		_hand_player.append(_deck.pop_back())
	_round_over("guest", "Du ziehst und ziehst – %d, überzogen." % hand_value(_hand_player))


func _guest_draws() -> void:
	_clear()
	var target := hand_value(_hand_player)
	_say("Du bleibst bei %d. %s zieht …" % [target, guest.display_name])
	var skill := float(profile_of(guest, id)["skill"])
	var nerve := int(lerpf(14.0, 17.0, skill)) - int(guest_shake(guest) * 3.0)   # so weit zieht er auch ohne Not
	while true:
		_hand_guest.append(_deck.pop_back())
		_shuffle_sound()
		await get_tree().create_timer(1.0, false).timeout
		if not _still_playing():
			return
		var value := hand_value(_hand_guest)
		_say("%s hat %s – %d." % [guest.display_name, ", ".join(_hand_guest), value])
		if value > 21 or value > target or (value >= nerve and value == target):
			break
	await get_tree().create_timer(0.8, false).timeout
	if not _still_playing():
		return
	var guest_value := hand_value(_hand_guest)
	if guest_value > 21:
		_round_over("player", "%s überzieht mit %d." % [guest.display_name, guest_value])
	elif guest_value > target:
		_round_over("guest", "%s hat %d, du %d." % [guest.display_name, guest_value, target])
	else:
		_round_over("", "Gleichstand bei %d – die Runde zählt nicht." % target)


func _round_over(winner: String, text: String) -> void:
	if winner == "player":
		_score_player += 1
	elif winner == "guest":
		_score_guest += 1
	_update_title()
	_say(text + (" Runde für dich." if winner == "player" else (" Runde für %s." % guest.display_name if winner == "guest" else "")))
	_clear()
	if _score_player >= WIN_ROUNDS or _score_guest >= WIN_ROUNDS:
		_option("Weiter", func() -> void: _finish(1 if _score_player > _score_guest else -1, _score_player == 1))
	else:
		_option("Neu geben", _start_round)


func _shuffle_sound() -> void:
	Game.play_sound("rustle", 0.25)
