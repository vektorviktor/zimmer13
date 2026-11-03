class_name BarMatch
extends TableMatch
## Grundlage der Barspiele am Würfeltisch (Spielkonzept 6.10, Entscheidung 28.10.): Schocken, Armdrücken,
## Bierdeckel-Turm, Trinkduell, 17 und 4, Kneipenquiz, Wahrheit oder Pflicht. Wie Mäxchen: Spieler gegen einen Gast,
## Einsätze auf dem Tisch, Abbruch bei einer Vorwarnung (TableMatch). Das Spielgerät ist der Würfelbecher oder ein
## Spiel aus dem Spieleschrank (Item.Kind.BAR_GAME, Sorte gear_flavor) – ohne es am Tisch kein Spiel.
##
## Lust, Können und Stolz je Gast und Spiel: aus profile[id], sonst fest aus der Gast-ID gewürfelt (profile_of) –
## so kommen keine Zufallsaufrufe in GuestGenerator.make() dazu.

## Spiele in der Reihenfolge des Dialogs: id → Titel
const GAMES := {"schocken": "Schocken", "armdruecken": "Armdrücken", "bierdeckel": "Bierdeckel-Turm",
	"trinkduell": "Trinkduell", "siebzehn": "17 und 4", "quiz": "Kneipenquiz", "wahrheit": "Wahrheit oder Pflicht"}
## Wie gern Gäste ein Spiel mögen (Anteil), wenn ihr Profil nichts sagt
const LIKES := {"schocken": 0.55, "armdruecken": 0.4, "bierdeckel": 0.45, "trinkduell": 0.35, "siebzehn": 0.5,
	"quiz": 0.5, "wahrheit": 0.45}
## Sätze, wenn der Gast keine eigenen hat (profile.lines „<id>_yes“ …); %s = Titel des Spiels
const LINES := {
	"yes": ["Na gut, eine Runde %s.", "%s? Klar, setz dich.", "%s! Gern."],
	"no": ["Nein, jetzt nicht.", "Keine Lust auf %s.", "Vielleicht später."],
	"win": ["Gewonnen!", "Ha! Das war meins.", "Tja. Übung macht den Meister."],
	"lose": ["Gut gespielt.", "Na schön, du hast gewonnen.", "Revanche, irgendwann."],
	"challenge": ["Na, Lust auf %s? Ich fordere dich heraus.", "Eine Runde %s am Würfeltisch? Komm schon.",
		"%s – du gegen mich. Traust du dich?"],
}
## Diese Barspiele spielen Gäste auch untereinander (Entscheidung 3.11.) – die übrigen nur mit dem Spieler
const GUEST_GAMES := ["schocken", "armdruecken"]
## Ab diesem Stolz will ein Gast nach einer Niederlage Revanche und fordert dich von sich aus heraus (wie Mäxchen)
const PROUD := 0.5

var table: GameTable
var id := ""
var title := ""
var gear_flavor := ""      ## Sorte des Spiels aus dem Schrank, "wuerfel" = Würfelbecher, "" = nichts nötig
var adults_only := false   ## Kinder spielen nicht mit (6.13)

var _view_box: Container   ## links neben dem Text – das Spiel legt dort sein Bild ab


func _init(p_id: String, p_gear: String, p_adults_only: bool) -> void:
	id = p_id
	title = GAMES[p_id]
	gear_flavor = p_gear
	adults_only = p_adults_only
	name = "Bar_" + p_id


func _ready() -> void:
	var panel := _build_panel(Color(0.05, 0.04, 0.03, 0.9), 6, Vector4(0.06, 0.5, 0.94, 0.98))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	_title = UiKit.plain_label(10, Color(0.95, 0.75, 0.4))
	box.add_child(_title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	_view_box = HBoxContainer.new()
	row.add_child(_view_box)
	_log = UiKit.plain_label(9, Color(0.9, 0.88, 0.85))
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log.custom_minimum_size = Vector2(300, 0)
	row.add_child(_log)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	box.add_child(grid)
	_options = grid
	_button_width = 190.0
	_build_view()


# --- Vom Spiel zu liefern ------------------------------------------------------------

## Spielbild in _view_box legen (Würfel, Wackelbalken …) – darf leer bleiben.
func _build_view() -> void:
	pass


## Eigene Werte zurücksetzen, bevor die Partie beginnt.
func _reset() -> void:
	pass


## Titelzeile: Spielstand („Du 2 : 1 Edna“) – ohne Einsatz, den hängt _update_title an.
func _score_text() -> String:
	return ""


# --- Profil und Sätze -------------------------------------------------------------------

## {"likes": bool, "skill": 0..1, "pride": 0..1} – aus dem Profil oder fest aus der Gast-ID.
static func profile_of(guest: Guest, game: String) -> Dictionary:
	if guest.profile.has(game):
		return guest.profile[game]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(guest.id + ":" + game)
	var skill := rng.randf()
	if game == "armdruecken":   # Kraft: kräftig gebaute Gäste drücken besser, Kinder kaum
		skill = lerpf(skill, clampf((float(guest.profile.get("build", 0.2)) + 0.6) / 1.6, 0.0, 1.0), 0.5)
	if game == "trinkduell":    # wer viel verträgt
		skill = lerpf(skill, 0.5 + float(guest.profile["dice"]["pride"]) * 0.4, 0.3)
	if guest.is_child():
		skill *= 0.4
	return {"likes": rng.randf() < float(LIKES.get(game, 0.4)), "skill": skill,
		"pride": float(guest.profile["dice"]["pride"])}


## Lieblings-Barspiel des Gastes (Spielkonzept 6.10, Entscheidung 3.11.): unter den Spielen, die er mag, das, was er
## am besten kann – fest aus profile_of, also aus Profil bzw. Gast-ID. "" = er mag keins. Kinder nichts nur für
## Erwachsene.
static func favorite_of(guest: Guest) -> String:
	var best := ""
	var best_skill := -1.0
	for game: String in GAMES:
		var match_ui: BarMatch = Game.bar_games.get(game)
		if match_ui and match_ui.adults_only and guest.is_child():
			continue
		var prof := profile_of(guest, game)
		if bool(prof["likes"]) and float(prof["skill"]) > best_skill:
			best = game
			best_skill = float(prof["skill"])
	return best


## Satz des Gastes zum Spiel: eigener („schocken_yes“) oder allgemeiner aus LINES.
static func line_of(guest: Guest, game: String, key: String) -> String:
	var lines: Dictionary = guest.profile["lines"]
	if lines.has(game + "_" + key):
		return guest.line(game + "_" + key)
	var options: Array = LINES.get(key, ["…"])
	var text := String(options[randi() % options.size()])
	return text % GAMES.get(game, game) if text.contains("%s") else text


## Wie sehr die Hand des Spielers zittert (0..1): Rausch, Schock, Müdigkeit und Trauer (Schwäche, 4.18), dazu
## zu viel Kaffee (3.11) – für die Geschick-Spiele.
static func player_shake() -> float:
	var p := Game.player
	return clampf(p.weakness() * 0.9 + (0.35 if p.jittery() else 0.0), 0.0, 1.0)


## Dasselbe beim Gast: Angst und Rausch.
static func guest_shake(guest: Guest) -> float:
	return clampf(guest.fear / 120.0 + guest.drunk * 0.8, 0.0, 1.0)


static func strength_text(guest: Guest, game: String) -> String:
	var skill := float(profile_of(guest, game)["skill"])
	return "spielt schwach" if skill < 0.35 else ("spielt ordentlich" if skill < 0.7 else "spielt stark")


# --- Start ----------------------------------------------------------------------------

func _table() -> GameTable:
	return table


func _gear() -> Item.Kind:
	if gear_flavor == "wuerfel":
		return Item.Kind.DICE_CUP
	return Item.Kind.BAR_GAME if gear_flavor != "" else Item.Kind.KEY   # KEY: nichts (wird nie gesetzt)


## Liegt das Spielgerät am Tisch oder hält der Spieler es? player darf null sein.
func has_gear(player: Player) -> bool:
	if gear_flavor == "":
		return true
	if gear_flavor == "wuerfel":
		return table.has_cup(player)
	if player != null and player.held and player.held.kind == Item.Kind.BAR_GAME and player.held.flavor == gear_flavor:
		return true
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.kind == Item.Kind.BAR_GAME and item.flavor == gear_flavor and not item.is_held \
				and item.global_position.distance_to(table.top_center()) < 0.8:
			return true
	return false


## Was fehlt, damit gespielt werden kann – "" = nichts.
func missing_gear_text() -> String:
	if has_gear(Game.player):
		return ""
	if gear_flavor == "wuerfel":
		return "Der Würfelbecher fehlt am Tisch."
	return "%s fehlt am Würfeltisch – im Spieleschrank nachsehen." % Item.BAR_GAMES[gear_flavor]


## Kann jetzt mit diesem Gast gespielt werden? Gibt einen Grund zurück oder "".
func why_not(p_guest: Guest) -> String:
	if active or table == null or Game.table_game_active():
		return "Gerade nicht."
	if table.busy:
		return "Am Würfeltisch wird schon gespielt."
	if adults_only and p_guest.is_child():
		return "Das ist nichts für Kinder."
	var missing := missing_gear_text()
	if missing != "":
		return missing
	return _guest_unwilling(p_guest)


## Darf der Gast dich gerade dazu herausfordern? Tisch frei, kein Spiel am Laufen, nichts nur für Erwachsene bei
## Kindern. Das Spielgerät darf fehlen – das holst du dann aus dem Spieleschrank (why_not sagt es beim Annehmen).
func can_challenge(p_guest: Guest) -> bool:
	return not active and table != null and not table.busy and not Game.table_game_active() \
		and not (adults_only and p_guest.is_child())


## stake: {"money": int, "item": bool}
func start(p_guest: Guest, stake: Dictionary) -> void:
	_reset()
	_begin(p_guest, stake, Vector3(-0.15, 0.01, 0.0))
	_update_title()
	_say("%s kommt an den Tisch …" % guest.display_name)
	_clear()
	_option("Doch nicht spielen", _abort.bind("Du stehst wieder auf."))


# --- Ende ----------------------------------------------------------------------------

## Partie vorbei: result 1 = du gewinnst, −1 = der Gast, 0 = unentschieden. close: knapp verloren (freut ihn).
func _finish(result: int, close := false, extra := "") -> void:
	_over = true
	var prof := profile_of(guest, id)
	var change := 5.0 + (3.0 if prof["likes"] else 0.0)    # gemeinsame Zeit
	var line := ""
	if result > 0:
		change -= float(prof["pride"]) * 8.0               # Stolz gekränkt
		line = line_of(guest, id, "lose")
		if float(prof["pride"]) > PROUD:                   # stolze Gäste wollen Revanche – in der Bar (Social)
			guest.challenge_cooldown = randf_range(90.0, 150.0)
			guest.challenge_game = id
			Game.social.queue_rematch(guest)
		_stakes.take_for_player()
	elif result < 0:
		line = line_of(guest, id, "win")
		if close:
			change += 4.0
		if _threw_game:
			if randf() < float(guest.profile["dice"]["perception"]) + 0.2:
				change -= 10.0
				line = guest.line("patronized")
			else:
				change += 6.0
		_stakes.give_to_guest(guest)
	else:
		line = "Unentschieden. Auch gut."
		change += 2.0
		_stakes.split(guest)
	Game.social.add_deed(guest, "games")                   # gemeinsame Partie zählt für „guter Freund“ (6.3)
	Game.social.requests.on_game_played(guest, id)         # seine Bitte um eine Partie (6.14)
	Game.social.change_relation(guest, change)
	var stakes_text := ""
	if result > 0 and _stakes.any_left():
		stakes_text = " Die Einsätze liegen auf dem Tisch – nimm sie dir."
	_say(("%s\n" % extra if extra != "" else "") + "%s: „%s“%s" % [guest.display_name, line, stakes_text])
	_clear()
	_option("Aufstehen", _end)
	if Game.tracing:
		print("[Barspiel] %s mit %s: %s" % [title, guest.display_name, {1: "gewonnen", -1: "verloren", 0: "unentschieden"}[result]])


## Erwischt beim Schummeln: Beziehung ↓↓, Gerücht, der Gast nimmt die Einsätze.
func _caught_cheating(text: String) -> void:
	_over = true
	guest.say(text)
	_say("%s: „%s“" % [guest.display_name, text])
	Game.social.change_relation(guest, -30.0)
	Game.social.on_cheat_caught(guest)
	_stakes.give_to_guest(guest)
	_clear()
	_option("Aufstehen", _end)


## Für automatische Tests: eine zufällige Option wählen. Gibt Titel + Text zurück.
func debug_press_random() -> String:
	var info := "%s | %s" % [_title.text, _log.text.replace("\n", " ")]
	var enabled: Array[Button] = []
	for button in _buttons:
		if not button.disabled and not button.text.contains("Doch nicht") and not button.text.contains("Absichtlich"):
			enabled.append(button)
	if not enabled.is_empty():
		var choice := enabled[randi() % enabled.size()]
		info += "  →  " + choice.text
		choice.pressed.emit()
	return info


func _update_title() -> void:
	if guest == null:
		return
	var stakes := _stakes.labels()
	var score := _score_text()
	_title.text = "%s mit %s%s   ·   Einsatz: %s" % [title, guest.display_name, "   ·   " + score if score != "" else "",
		"keiner" if stakes.is_empty() else ", ".join(stakes)]
