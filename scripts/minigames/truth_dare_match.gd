class_name TruthDareMatch
extends BarMatch
## Wahrheit oder Pflicht mit der leeren Flasche aus dem Spieleschrank (Spielkonzept 6.10): Die Flasche dreht sich
## SPINS Mal und zeigt auf dich oder den Gast. Zeigt sie auf den Gast, fragst du – bei „Wahrheit“ erzählt er, was er
## gesehen hat oder was ihn umtreibt, bei „Pflicht“ suchst du ihm eine Aufgabe aus. Zeigt sie auf dich, fragt er.
## Kein Gewinner, keine Einsätze: Es geht ums Kennenlernen. Singen ist laut (Lärm „singing“) – das hört auch das
## Monster. Kinder spielen mit, trinken aber nicht.

const SPINS := 6
## Fragen an dich: [Frage, ehrliche Antwort, Lüge]
const TRUTHS := [
	["Hast du hier im Hotel schon mal etwas mitgehen lassen?", "„Ja … ein bisschen.“", "„Nie im Leben!“"],
	["Hast du Angst vor dem, was hier nachts umgeht?", "„Ja. Große.“", "„Ich? Angst? Nein.“"],
	["Magst du mich eigentlich?", "„Ja, wirklich.“", "„Klar doch.“"],
	["Warum bist du wirklich hier?", "„Ich weiß es selbst nicht genau.“", "„Urlaub. Einfach Urlaub.“"],
	["Was war das Peinlichste, das dir passiert ist?", "Du erzählst die ganze Geschichte.", "Du erfindest etwas Harmloses."],
	["Hast du schon mal beim Spielen geschummelt?", "„Ertappt. Ja.“", "„Ich? Niemals.“"],
]
## Pflichten: Schlüssel → Text (für dich und für den Gast)
const DARES := {
	"sing": "Sing ein Lied – laut!",
	"drink": "Trink ein Glas auf ex!",
	"coin": "Gib eine Münze in die Runde!",
	"joke": "Erzähl einen Witz!",
}

var _spin := 0
var _opened := 0           ## so oft hat der Gast etwas von sich erzählt
var _bond := 0.0           ## Beziehung, die am Ende dazukommt


func _init() -> void:
	super("wahrheit", "flasche", false)


func _reset() -> void:
	_spin = 0
	_opened = 0
	_bond = 0.0


func _score_text() -> String:
	return "Dreh %d/%d" % [mini(_spin + 1, SPINS), SPINS]


func can_stake_item(_guest: Guest) -> bool:
	return false


func _on_seated() -> void:
	_offer_spin("Die Flasche liegt in der Mitte.")


func _offer_spin(text: String) -> void:
	_update_title()
	_say(text)
	_clear()
	if _spin >= SPINS:
		_option("Aufhören", _done)
		return
	_option("Flasche drehen", _do_spin)
	_option("Aufhören", _done)


func _do_spin() -> void:
	_spin += 1
	_clear()
	_say("Die Flasche dreht sich … und dreht sich …")
	Game.play_sound("rustle", 0.2)
	await get_tree().create_timer(1.4, false).timeout
	if not _still_playing():
		return
	if randf() < 0.5:
		_say("Sie zeigt auf %s. Du fragst: „Wahrheit oder Pflicht?“" % guest.display_name)
		await get_tree().create_timer(1.0, false).timeout
		if not _still_playing():
			return
		if randf() < 0.3 + float(guest.profile["brave"]) * 0.5:
			_guest_dare()
		else:
			_guest_truth()
	else:
		_say("Sie zeigt auf dich. %s grinst: „Wahrheit oder Pflicht?“" % guest.display_name)
		_clear()
		_option("Wahrheit", _player_truth)
		_option("Pflicht", _player_dare)


# --- Der Gast ist dran -------------------------------------------------------------

func _guest_truth() -> void:
	_opened += 1
	_bond += 3.0
	var report := Game.social.report_line(guest) if Game.director.first_attack_done else ""
	var text := report if report != "" else guest.line("monster" if Game.director.first_attack_done else "odd")
	if randf() < 0.4:
		text = guest.line("smalltalk")
	_offer_spin("%s: „Wahrheit.“ … und erzählt: „%s“" % [guest.display_name, text])


func _guest_dare() -> void:
	_say("%s: „Pflicht!“ Was soll %s tun?" % [guest.display_name, guest.display_name])
	_clear()
	for key in DARES:
		if key == "drink" and guest.is_child():
			continue
		_option(String(DARES[key]), _guest_does.bind(key))


func _guest_does(key: String) -> void:
	var refuses := randf() < float(profile_of(guest, id)["pride"]) * 0.3 + guest.fear / 200.0
	if refuses:
		_bond -= 2.0
		_offer_spin("%s verschränkt die Arme: „Das mach ich nicht.“" % guest.display_name)
		return
	_bond += 2.0
	match key:
		"sing":
			Game.noise("singing", table.global_position, guest)
			_offer_spin("%s singt aus vollem Hals – schief und laut. Die Gläser klirren." % guest.display_name)
		"drink":
			guest.drink()
			_offer_spin("%s kippt ein Glas auf ex und schüttelt sich." % guest.display_name)
		"coin":
			if guest.money > 0:
				guest.money -= 1
				Game.money += 1
				_offer_spin("%s schnippt dir eine Münze zu." % guest.display_name)
			else:
				_offer_spin("%s zeigt die leeren Taschen. Alle lachen." % guest.display_name)
		"joke":
			_offer_spin("%s erzählt einen Witz: „%s“" % [guest.display_name, guest.line("smalltalk")])


# --- Du bist dran ------------------------------------------------------------------

func _player_truth() -> void:
	var t: Array = TRUTHS[randi() % TRUTHS.size()]
	_say("%s fragt: „%s“" % [guest.display_name, t[0]])
	_clear()
	_option("Ehrlich: %s" % t[1], _player_answers.bind(true))
	_option("Lügen: %s" % t[2], _player_answers.bind(false))


func _player_answers(honest: bool) -> void:
	if honest:
		_bond += 4.0
		_offer_spin("%s nickt langsam. „Danke, dass du ehrlich bist.“" % guest.display_name)
	elif randf() < float(guest.profile["dice"]["perception"]) * 0.8:
		_bond -= 6.0
		_offer_spin("%s zieht eine Augenbraue hoch: „Das glaub ich dir nicht.“" % guest.display_name)
	else:
		_bond += 1.0
		_offer_spin("%s glaubt dir." % guest.display_name)


func _player_dare() -> void:
	var keys := DARES.keys().filter(func(k: String) -> bool: return not (k == "drink" and Game.money < BarTap.PRICE))
	var key: String = keys[randi() % keys.size()]
	_say("%s: „%s“" % [guest.display_name, DARES[key]])
	_clear()
	_option("Machen", _player_does.bind(key))
	_option("Kneifen", _player_chickens)


func _player_does(key: String) -> void:
	_bond += 3.0
	match key:
		"sing":
			Game.noise("singing", table.global_position, Game.player)
			_offer_spin("Du singst, so laut du kannst. %s lacht Tränen." % guest.display_name)
		"drink":
			Game.money -= BarTap.PRICE
			Game.player.drink(true)
			_offer_spin("Du kippst das Glas. Es brennt.")
		"coin":
			if Game.money > 0:
				Game.money -= 1
				guest.money += 1
				_offer_spin("Du schiebst %s eine Münze hin." % guest.display_name)
			else:
				_offer_spin("Du zeigst die leeren Taschen. %s lacht." % guest.display_name)
		"joke":
			_offer_spin("Du erzählst einen Witz. %s %s" % [guest.display_name,
				"prustet los." if randf() < 0.6 else "verzieht keine Miene."])


func _player_chickens() -> void:
	_bond -= 3.0
	_offer_spin("„Feigling!“, ruft %s." % guest.display_name)


# --- Ende ----------------------------------------------------------------------------

func _done() -> void:
	_over = true
	var prof := profile_of(guest, id)
	var change := 4.0 + (3.0 if prof["likes"] else 0.0) + _bond
	Game.social.add_deed(guest, "games")
	Game.social.requests.on_game_played(guest, id)
	Game.social.change_relation(guest, change)
	_stakes.split(guest)
	_say("%s: „%s“" % [guest.display_name, "Das war schön. Man lernt sich kennen." if change > 5.0 else "Na ja. War ganz lustig."])
	_clear()
	_option("Aufstehen", _end)
	if Game.tracing:
		print("[Barspiel] %s mit %s: %d Drehungen, Beziehung %+.0f, %d× erzählt" % [title, guest.display_name, _spin, change, _opened])
