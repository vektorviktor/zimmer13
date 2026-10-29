class_name PubQuizMatch
extends BarMatch
## Kneipenquiz mit den Quizkarten aus dem Spieleschrank (Spielkonzept 6.10): sechs Fragen, jeder antwortet auf jede.
## Ein Teil der Fragen ist Allgemeinwissen rund um Halloween und die Bar, der andere fragt das Hotel ab – wer wo
## wohnt, was ein Gast mag, wie viele Gäste da sind. Wer viel herumkommt und zuhört, weiß das; über sich selbst
## weiß der Gast immer Bescheid. Mehr richtige Antworten gewinnen.

const QUESTIONS := 6
const HOTEL_QUESTIONS := 3   ## davon höchstens so viele übers Hotel
## Allgemeinwissen: [Frage, richtig, falsch, falsch]
const TRIVIA := [
	["Aus welchem Land kommt der Brauch, Laternen aus Rüben und Kürbissen zu schnitzen?", "Irland", "Mexiko", "Schweden"],
	["Aus welchem keltischen Fest ist Halloween hervorgegangen?", "Samhain", "Beltane", "Jul"],
	["Wovon ist „Halloween“ die Kurzform?", "Abend vor Allerheiligen", "Heilige Nacht", "Hallo, Abend"],
	["Wann ist Allerheiligen?", "1. November", "31. Oktober", "2. November"],
	["Wie viele Augen hat ein Würfel zusammen?", "21", "18", "24"],
	["Wie viele Karten hat ein Skatblatt?", "32", "52", "36"],
	["Was ist beim Mäxchen der höchste Wurf?", "Eine Zwei und eine Eins", "Zwei Sechsen", "Eine Sechs und eine Fünf"],
	["Was ist beim Schocken „Schock aus“?", "Drei Einsen", "Drei Sechsen", "Eine Straße"],
	["Wie viele Punkte bringt das Bull's Eye beim Darts?", "50", "25", "60"],
	["Wie viele Felder hat ein Schachbrett?", "64", "81", "49"],
	["Wer schrieb „Dracula“?", "Bram Stoker", "Mary Shelley", "Edgar Allan Poe"],
	["Wer schrieb „Frankenstein“?", "Mary Shelley", "Bram Stoker", "Theodor Storm"],
	["Wie heißt der Mann mit der Laterne aus der irischen Sage?", "Jack", "Paddy", "Finn"],
	["Was streut man im Volksglauben vor die Schwelle gegen Geister?", "Salz", "Zucker", "Mehl"],
	["Welches Tier bringt im Aberglauben Unglück, wenn es von links den Weg kreuzt?", "Eine schwarze Katze", "Ein Rabe", "Eine Kröte"],
	["Was wirft man beim Darts von der Linie?", "Pfeile", "Bolzen", "Nadeln"],
]

var _questions: Array[Dictionary] = []   ## {"q", "right", "options", "guest_knows"}
var _index := 0
var _points_player := 0
var _points_guest := 0
var _peeked := false


func _init() -> void:
	super("quiz", "quiz", false)


func _reset() -> void:
	_index = 0
	_points_player = 0
	_points_guest = 0
	_peeked = false


func _score_text() -> String:
	return "Frage %d/%d · Du %d : %d %s" % [mini(_index + 1, QUESTIONS), QUESTIONS, _points_player, _points_guest, guest.display_name]


func _on_seated() -> void:
	_questions = _pick_questions()
	_ask()


## Halb Allgemeinwissen, halb Hotel – je nachdem, was es gerade an Gästen gibt.
func _pick_questions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var skill := float(profile_of(guest, id)["skill"])
	var hotel := _hotel_questions(skill)
	hotel.shuffle()
	for q in hotel.slice(0, HOTEL_QUESTIONS):
		result.append(q)
	var trivia := TRIVIA.duplicate()
	trivia.shuffle()
	for t in trivia:
		if result.size() >= QUESTIONS:
			break
		result.append({"q": t[0], "right": t[1], "options": [t[1], t[2], t[3]], "guest_knows": 0.25 + skill * 0.45})
	result.shuffle()
	return result


func _hotel_questions(skill: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var guests: Array = []
	for g: Guest in Game.social.living_guests():
		if not g.is_child() and String(g.profile.get("room", "")) != "":
			guests.append(g)
	guests.shuffle()
	for g: Guest in guests.slice(0, 3):
		var room := String(g.profile["room"])
		var wrong: Array[String] = []
		for other: Guest in guests:
			var r := String(other.profile["room"])
			if r != room and not r in wrong:
				wrong.append(r)
		while wrong.size() < 2:
			wrong.append("%03d" % randi_range(1, 49))
		var knows := 1.0 if g == guest else 0.25 + skill * 0.4 + (0.3 if Game.social.pals.are_pals(g, guest) else 0.0)
		result.append({"q": "In welchem Zimmer wohnt %s?" % g.display_name, "right": room,
			"options": [room, wrong[0], wrong[1]], "guest_knows": knows})
		var likes: Array = g.profile.get("likes", [])
		var right := Game.dialog._kind_name(int(likes[0])) if not likes.is_empty() and Game.dialog else "Etwas"
		if right != "Etwas":
			var others: Array = []
			for kind in [Item.Kind.CANDLE, Item.Kind.PUMPKIN, Item.Kind.SWEETS, Item.Kind.LEAVES, Item.Kind.COBWEB, Item.Kind.KNIFE, Item.Kind.SKULL]:
				var n := Game.dialog._kind_name(kind)
				if not kind in likes and n != right and n != "Etwas":
					others.append(n)
			others.shuffle()
			result.append({"q": "Was mag %s besonders gern?" % g.display_name, "right": right,
				"options": [right, others[0], others[1]], "guest_knows": 1.0 if g == guest else 0.2 + skill * 0.3})
	var count := Game.social.living_guests().size()
	result.append({"q": "Wie viele Gäste sind gerade im Hotel?", "right": str(count),
		"options": [str(count), str(count + randi_range(2, 5)), str(maxi(1, count - randi_range(2, 5)))], "guest_knows": 0.3 + skill * 0.4})
	return result


func _ask() -> void:
	_update_title()
	var q: Dictionary = _questions[_index]
	var options: Array = (q["options"] as Array).duplicate()
	options.shuffle()
	_say("„%s“" % q["q"])
	_clear()
	for o in options:
		_option(String(o), _answer.bind(String(o)))
	if not _peeked:
		_option("Auf die Rückseite schielen (schummeln)", _peek)


func _answer(choice: String) -> void:
	var q: Dictionary = _questions[_index]
	var right := String(q["right"])
	var player_right := choice == right
	var knows := float(q["guest_knows"]) * (1.0 - 0.5 * guest_shake(guest))
	var guest_right := randf() < knows or randf() < 1.0 / 3.0   # sonst rät er
	if player_right:
		_points_player += 1
	if guest_right:
		_points_guest += 1
	_say("Richtig ist: %s. %s, %s." % [right, "Du liegst richtig" if player_right else "Du liegst daneben",
		"%s auch" % guest.display_name if guest_right == player_right and guest_right else
		("%s weiß es" % guest.display_name if guest_right else "%s nicht" % guest.display_name)])
	_index += 1
	_update_title()
	_clear()
	if _index >= QUESTIONS:
		var result := signi(_points_player - _points_guest)
		_option("Auswerten", _finish.bind(result, _points_guest - _points_player == 1))
	else:
		_option("Nächste Frage", _ask)


func _peek() -> void:
	_peeked = true
	if randf() < float(guest.profile["dice"]["perception"]) * 0.6:
		_caught_cheating("Du schaust ja auf die Lösung! Pfui.")
		return
	var right := String(_questions[_index]["right"])
	_say("„%s“\nAuf der Rückseite steht klein: %s." % [_questions[_index]["q"], right])
	_clear()
	var options: Array = (_questions[_index]["options"] as Array).duplicate()
	options.shuffle()
	for o in options:
		_option(String(o), _answer.bind(String(o)))
