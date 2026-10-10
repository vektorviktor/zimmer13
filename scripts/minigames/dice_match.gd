class_name DiceMatch
extends CanvasLayer
## Mäxchen am Würfeltisch – Spieler gegen einen Gast (Spielkonzept 6.10).
##
## Ablauf einer Runde: Wer dran ist, würfelt verdeckt und sagt einen Wert an, der die
## vorige Ansage überbieten muss – wahr oder geblufft. Der andere glaubt (und muss
## selbst überbieten) oder deckt auf. Wer lügt bzw. zu Unrecht misstraut, verliert
## die Runde. Wer zuerst 2 Runden gewinnt, gewinnt die Partie.
##
## Einsätze liegen echt auf dem Tisch (Münzen, Gegenstände). Bei einer Vorwarnung
## springt der Gast auf – die Einsätze bleiben liegen, für wen auch immer.

const WIN_ROUNDS := 2

var active := false
var guest: Guest
var table: GameTable

var _score_player := 0
var _score_guest := 0
var _claim := -1               ## aktuelle Ansage
var _claim_by := ""            ## "player" / "guest"
var _actual := -1              ## wirklicher Wurf des Ansagenden
var _player_dice: Array[int] = []
var _player_bluffs := 0        ## macht den Gast misstrauischer
var _cheat_used := false
var _threw_game := false
var _pot: Item
var _player_item: Item
var _guest_item: Item
var _pot_value := 0
var _waiting_for_seat := false
var _abort_timer := -1.0
var _over := false

var _title: Label
var _log: Label
var _dice: DiceView
var _options: GridContainer
var _buttons: Array[Button] = []


func _ready() -> void:
	layer = 15
	visible = false
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.04, 0.9)
	style.border_color = Color(0.5, 0.35, 0.15)
	style.set_border_width_all(1)
	style.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	panel.anchor_left = 0.06
	panel.anchor_right = 0.94
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.98
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	_title = _make_label(10, Color(0.95, 0.75, 0.4))
	box.add_child(_title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	_dice = DiceView.new()
	_dice.custom_minimum_size = Vector2(52, 24)
	row.add_child(_dice)
	_log = _make_label(9, Color(0.9, 0.88, 0.85))
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log.custom_minimum_size = Vector2(300, 0)
	row.add_child(_log)
	_options = GridContainer.new()
	_options.columns = 2
	_options.add_theme_constant_override("h_separation", 8)
	box.add_child(_options)


## Kann jetzt mit diesem Gast gespielt werden? Gibt einen Grund zurück oder "".
func why_not(p_guest: Guest) -> String:
	if active or table == null:
		return "Gerade nicht."
	if table.busy:
		return "Am Würfeltisch wird schon gespielt."
	if not table.has_cup(Game.player):
		return "Der Würfelbecher fehlt am Tisch."
	if p_guest.fear >= 60.0:
		return p_guest.line("panic")
	if Game.director.phase != MonsterDirector.Phase.CALM:
		return "Jetzt? Hörst du das nicht?"
	return ""


## stake: {"money": int, "item": bool}
func start(p_guest: Guest, stake: Dictionary) -> void:
	guest = p_guest
	active = true
	_over = false
	table.busy = true
	_score_player = 0
	_score_guest = 0
	_player_bluffs = 0
	_threw_game = false
	_abort_timer = -1.0
	_pot = null
	_player_item = null
	_guest_item = null
	_pot_value = 0
	var player := Game.player
	# Becher auf den Tisch, falls du ihn in der Hand hast
	if player.held_kind() == Item.Kind.DICE_CUP:
		var cup := player.held
		player.drop_held()
		cup.global_position = table.top_center() + Vector3(-0.15, 0.01, 0.0)
	_place_stakes(stake)
	player.sit_at(table.player_seat.global_position, table.top_center())
	guest.sit_for_game(table.guest_seat.global_position, table.top_center())
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_waiting_for_seat = true
	_update_title()
	_dice.hide_dice()
	_say("%s kommt an den Tisch …" % guest.display_name)
	_clear()
	_option("Doch nicht spielen", _abort.bind("Du stehst wieder auf."))


func _process(delta: float) -> void:
	if not active:
		return
	if _waiting_for_seat and guest.seated:
		_waiting_for_seat = false
		_start_round("guest" if randf() < 0.5 else "player")
	# Der Gast hat das Spiel verlassen (Panik, Monster gesehen, gestorben …)
	if not _over and (guest.dead or guest.state != Guest.State.MINIGAME):
		_abort("%s springt auf und rennt davon! Die Einsätze liegen noch auf dem Tisch …" % guest.display_name)
		return
	# Vorwarnung: je mutiger der Gast, desto später bemerkt er sie
	if not _over and Game.director.phase != MonsterDirector.Phase.CALM:
		if _abort_timer < 0.0:
			_abort_timer = 0.5 + float(guest.profile["brave"]) * 4.5
		_abort_timer -= delta
		if _abort_timer <= 0.0:
			guest.say(guest.line("panic"))
			guest.end_game()
			_abort("%s springt auf und rennt davon! Die Einsätze liegen noch auf dem Tisch …" % guest.display_name)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var index: int = (event as InputEventKey).keycode - KEY_1
		if index >= 0 and index < _buttons.size() and not _buttons[index].disabled:
			_buttons[index].pressed.emit()
			get_viewport().set_input_as_handled()


# --- Runden ----------------------------------------------------------------------

func _start_round(starter: String) -> void:
	_claim = -1
	_claim_by = ""
	_cheat_used = false
	_update_title()
	if starter == "player":
		_player_roll("Neue Runde – du fängst an.")
	else:
		_guest_roll("Neue Runde – %s fängt an." % guest.display_name)


## Du würfelst verdeckt und entscheidest, was du ansagst.
func _player_roll(intro: String) -> void:
	_player_dice = Maexchen.roll()
	_rattle()
	_dice.show_dice(_player_dice)
	var value := Maexchen.value_of(_player_dice)
	var text := "%s Du hast %s (nur du siehst es)." % [intro, Maexchen.label(value)]
	if _claim >= 0:
		text += " Zu überbieten: %s." % Maexchen.label(_claim)
	_say(text)
	_build_player_options()


func _build_player_options() -> void:
	_clear()
	var value := Maexchen.value_of(_player_dice)
	if _claim < 0 or Maexchen.beats(value, _claim):
		_option("Wahrheit: %s" % Maexchen.label(value), _player_announce.bind(value))
	# Bluffs: nur Werte über der Ansage UND über dem echten Wurf
	var floor_value := value if _claim < 0 or Maexchen.beats(value, _claim) else _claim
	var bluffs := Maexchen.higher_than(floor_value, 3)
	if not bluffs.has(21) and floor_value != 21:
		bluffs.append(21)
	for bluff in bluffs:
		_option("Bluffen: %s" % Maexchen.label(bluff), _player_announce.bind(bluff))
	if table.loaded and not _cheat_used:
		_option("Gezinkt nachwürfeln (riskant)", _cheat)
	_option("Absichtlich verlieren", _throw_round)


func _player_announce(value: int) -> void:
	_claim = value
	_claim_by = "player"
	_actual = Maexchen.value_of(_player_dice)
	if _actual != value:
		_player_bluffs += 1
	_dice.hide_dice()
	_say("Du schiebst den Becher rüber: „%s“" % Maexchen.label(value))
	_clear()
	_guest_respond.call_deferred()


func _guest_respond() -> void:
	await get_tree().create_timer(1.3).timeout
	if not _still_playing():
		return
	var dice: Dictionary = guest.profile["dice"]
	var plausible := Maexchen.chance_at_least(_claim)
	var suspicion := float(_player_bluffs) * 0.08 + float(dice["perception"]) * 0.2
	var doubt := clampf((1.0 - plausible) * 0.85 + suspicion - 0.15, 0.05, 0.95)
	if _claim == 21:
		doubt = 0.85
	if randf() < doubt:
		_say("%s: „Das glaub ich dir nicht!“ – und hebt den Becher …" % guest.display_name)
		_reveal()
	elif _claim == 21:
		_say("%s seufzt: „Gegen ein Mäxchen komm ich nicht an.“" % guest.display_name)
		_round_won_by("player")
	else:
		_guest_roll("%s glaubt dir." % guest.display_name)


## Der Gast würfelt verdeckt und sagt an – ehrlich oder geblufft, je nach Charakter.
func _guest_roll(intro: String) -> void:
	_clear()
	_dice.hide_dice()
	_say("%s %s würfelt …" % [intro, guest.display_name])
	_rattle()
	await get_tree().create_timer(1.4).timeout
	if not _still_playing():
		return
	var dice: Dictionary = guest.profile["dice"]
	var value := Maexchen.value_of(Maexchen.roll())
	var announce := value
	var can_truth := _claim < 0 or Maexchen.beats(value, _claim)
	if not can_truth or randf() > float(dice["honesty"]):
		var options := Maexchen.higher_than(_claim, int(dice["jump"]))
		announce = options[randi() % options.size()] if not options.is_empty() else 21
		if can_truth and Maexchen.beats(value, announce):
			announce = value
	_claim = announce
	_claim_by = "guest"
	_actual = value
	var text := "%s schaut unter den Becher und sagt: „%s“" % [guest.display_name, Maexchen.label(announce)]
	# Verräterische Gesten – nur wenn du den Gast vorher beim Spielen beobachtet hast
	if Game.social.has_watched(guest):
		var bluffing := announce != value
		if (bluffing and randf() < 0.6) or (not bluffing and randf() < 0.1):
			text += "\n" + String(dice["tell"])
	_say(text)
	_clear()
	if _claim == 21:
		_option("Aufdecken!", _player_doubt)
		_option("Glauben (= Runde verloren)", _player_believe)
	else:
		_option("Glauben – selbst würfeln", _player_believe)
		_option("Aufdecken!", _player_doubt)


func _player_believe() -> void:
	if _claim == 21:
		_say("Gegen ein Mäxchen kommst du nicht an.")
		_round_won_by("guest")
		return
	_player_roll("Du glaubst %s." % guest.display_name)


func _player_doubt() -> void:
	_say("Du hebst den Becher …")
	_reveal()


func _reveal() -> void:
	_clear()
	var honest := _actual == _claim or Maexchen.beats(_actual, _claim)
	var claimant := guest.display_name if _claim_by == "guest" else "Du"
	var text := "Unter dem Becher: %s (angesagt: %s). " % [Maexchen.label(_actual), Maexchen.label(_claim)]
	if honest:
		text += "%s hatte%s recht!" % [claimant, "" if _claim_by == "guest" else "st"]
		_round_won_by(_claim_by, text)
	else:
		text += "Gelogen!"
		_round_won_by("guest" if _claim_by == "player" else "player", text)


func _round_won_by(winner: String, text: String = "") -> void:
	if winner == "player":
		_score_player += 1
	else:
		_score_guest += 1
	_update_title()
	var message := text + (" Runde für dich." if winner == "player" else " Runde für %s." % guest.display_name)
	_say(message.strip_edges())
	_clear()
	if _score_player >= WIN_ROUNDS or _score_guest >= WIN_ROUNDS:
		_option("Weiter", _finish)
	else:
		var loser := "guest" if winner == "player" else "player"
		_option("Nächste Runde", _start_round.bind(loser))


# --- Schummeln & absichtlich verlieren ----------------------------------------------

func _cheat() -> void:
	_cheat_used = true
	var r := randf()
	if r < 0.6:
		_player_dice = [2, 1]
	elif r < 0.9:
		_player_dice = [6, 6]
	else:
		_player_dice = Maexchen.roll()
	_dice.show_dice(_player_dice)
	_rattle()
	var dice: Dictionary = guest.profile["dice"]
	if randf() < float(dice["perception"]) * 0.7:
		_caught_cheating()
		return
	_say("Du würfelst mit den gezinkten Würfeln nach: %s. %s hat nichts bemerkt." % [Maexchen.label(Maexchen.value_of(_player_dice)), guest.display_name])
	_build_player_options()


func _caught_cheating() -> void:
	_over = true
	guest.say(guest.line("caught_cheat"))
	_say("%s: „%s“" % [guest.display_name, guest.line("caught_cheat")])
	Game.social.change_relation(guest, -30.0)
	Game.social.on_cheat_caught(guest)
	table.loaded = false   # die gezinkten Würfel sind aufgeflogen
	_give_stakes_to_guest()
	_clear()
	_option("Aufstehen", _end)


func _throw_round() -> void:
	_threw_game = true
	_say("Du sagst absichtlich zu wenig an.")
	_round_won_by("guest")


# --- Ende ----------------------------------------------------------------------------

func _finish() -> void:
	_over = true
	var player_won := _score_player > _score_guest
	var dice: Dictionary = guest.profile["dice"]
	var change := 5.0 + (3.0 if dice["likes"] else 0.0)    # gemeinsame Zeit
	var line := ""
	if player_won:
		change -= float(dice["pride"]) * 8.0                # Stolz gekränkt
		line = guest.line("dice_lose")
		if float(dice["pride"]) > 0.5:
			guest.challenge_cooldown = randf_range(90.0, 150.0)
			Game.social.queue_rematch(guest)
		_take_stakes_for_player()
	else:
		line = guest.line("dice_win")
		if _score_player == 1:
			change += 4.0                                    # knapp verloren freut ihn
		if _threw_game:
			if randf() < float(dice["perception"]) + 0.2:
				change -= 10.0
				line = guest.line("patronized")
			else:
				change += 6.0
		_give_stakes_to_guest()
	Game.social.change_relation(guest, change)
	var stakes_text := ""
	if player_won and (is_instance_valid(_pot) or is_instance_valid(_guest_item) or is_instance_valid(_player_item)):
		stakes_text = " Die Einsätze liegen auf dem Tisch – nimm sie dir."
	_say("%s: „%s“%s" % [guest.display_name, line, stakes_text])
	_clear()
	_option("Aufstehen", _end)


func _abort(message: String) -> void:
	_over = true
	# Einsätze bleiben liegen – sie gehören jetzt niemandem
	for item in [_pot, _player_item, _guest_item]:
		if is_instance_valid(item):
			item.owner_id = ""
	_say(message)
	_clear()
	_option("Aufstehen", _end)


func _end() -> void:
	visible = false
	active = false
	table.busy = false
	_clear()
	if guest and not guest.dead:
		guest.end_game()
	Game.player.stand_up()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# --- Einsätze ------------------------------------------------------------------------

func _place_stakes(stake: Dictionary) -> void:
	var money := int(stake.get("money", 0))
	if money > 0:
		Game.money -= money
		guest.money -= money
		_pot_value = money * 2
		_pot = Item.create(Item.Kind.COINS, str(_pot_value))
		_pot.owner_id = "stake"
		get_parent().add_child(_pot)
		_pot.global_position = table.stake_spot(0)
	if stake.get("item", false) and Game.player.held:
		_player_item = Game.player.held
		Game.player.drop_held()
		_player_item.global_position = table.stake_spot(-1)
		_player_item.owner_id = "stake"
		var kind := _guest_counter_stake(_player_item.price())
		if kind >= 0:
			guest.stock[kind] = int(guest.stock[kind]) - 1
			_guest_item = Item.create(kind)
			_guest_item.owner_id = "stake"
			get_parent().add_child(_guest_item)
			_guest_item.global_position = table.stake_spot(1)


## Was legt der Gast gegen deinen Gegenstand? Etwas Gleichwertiges aus seinem Koffer.
func _guest_counter_stake(value: int) -> int:
	var best := -1
	var best_diff := 999
	for kind in guest.stock:
		if int(guest.stock[kind]) <= 0:
			continue
		var diff := absi(int(Item.PRICES.get(kind, 1)) - value)
		if diff < best_diff:
			best_diff = diff
			best = kind
	return best


func can_stake_item(p_guest: Guest) -> bool:
	var held := Game.player.held
	if held == null or held.kind == Item.Kind.KEY or held.kind == Item.Kind.DICE_CUP:
		return false
	for kind in p_guest.stock:
		if int(p_guest.stock[kind]) > 0:
			return true
	return false


func _take_stakes_for_player() -> void:
	for item in [_pot, _player_item, _guest_item]:
		if is_instance_valid(item):
			item.owner_id = "player"


func _give_stakes_to_guest() -> void:
	if is_instance_valid(_pot):
		guest.money += _pot_value
		_pot.queue_free()
	for item in [_player_item, _guest_item]:
		if is_instance_valid(item):
			guest.stock[item.kind] = int(guest.stock.get(item.kind, 0)) + 1
			item.queue_free()
	_pot = null
	_player_item = null
	_guest_item = null


## Für automatische Tests: eine zufällige Option wählen. Gibt Titel + Text zurück.
func debug_press_random() -> String:
	var info := "%s | %s" % [_title.text, _log.text.replace("
", " ")]
	var enabled: Array[Button] = []
	for button in _buttons:
		if not button.disabled and not button.text.contains("Doch nicht"):
			enabled.append(button)
	if not enabled.is_empty():
		var choice := enabled[randi() % enabled.size()]
		info += "  →  " + choice.text
		choice.pressed.emit()
	return info


# --- Hilfen --------------------------------------------------------------------------

func _still_playing() -> bool:
	return active and not _over


func _rattle() -> void:
	Game.play_sound("thud", 0.4)
	Game.play_sound("blip", 0.2)
	Game.director.on_noise(table.global_position, 0.7)   # Würfeln ist laut


func _update_title() -> void:
	if guest == null:
		return
	var stakes: Array[String] = []
	if _pot_value > 0:
		stakes.append("%d Geld" % _pot_value)
	if is_instance_valid(_player_item):
		stakes.append(_player_item.display_name)
	if is_instance_valid(_guest_item):
		stakes.append(_guest_item.display_name)
	_title.text = "Mäxchen mit %s   ·   Du %d : %d %s   ·   Einsatz: %s" % [guest.display_name,
		_score_player, _score_guest, guest.display_name, "keiner" if stakes.is_empty() else ", ".join(stakes)]


func _say(text: String) -> void:
	_log.text = text


func _clear() -> void:
	for button in _buttons:
		button.queue_free()
	_buttons.clear()


func _option(text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = "%d. %s" % [_buttons.size() + 1, text]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 9)
	button.custom_minimum_size = Vector2(190, 0)
	var tight := StyleBoxEmpty.new()
	tight.content_margin_top = 1
	tight.content_margin_bottom = 1
	for style_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(style_name, tight)
	button.pressed.connect(callback)
	_options.add_child(button)
	_buttons.append(button)


func _make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	var settings := LabelSettings.new()
	settings.font_size = font_size
	settings.font_color = color
	label.label_settings = settings
	return label
