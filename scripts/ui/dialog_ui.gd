class_name DialogUI
extends CanvasLayer
## Gespräch mit einem Gast (Spielkonzept 6.2–6.5, 6.9): Plaudern, über das Monster
## reden, Handeln, Schenken, um Deko bitten, beruhigen, zur Feier einladen,
## beleidigen, entschuldigen, mitkommen lassen (6.3). Auswahl per Maus oder Zifferntasten 1–9 und 0, Esc schließt.

const CHAT_COOLDOWN := 40.0
const GIFT_COOLDOWN := 150.0
## Plaudern zählt am Tag nur so oft voll (6.3), danach kaum noch
const CHATS_PER_DAY := 2
## Entschuldigen kostet je nach Stufe (verfeindet / stark verfeindet)
const APOLOGY_PRICE := {Social.Tier.ENEMY: 5, Social.Tier.STRONG_ENEMY: 15}

var guest: Guest

var _name: Label
var _text: Label
var _options: GridContainer
var _buttons: Array[Button] = []
var _game := "dice"     ## Spiel, um dessen Einsatz gerade verhandelt wird ("dice" oder "chess")


func _ready() -> void:
	layer = 15
	visible = false
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.03, 0.03, 0.92)
	style.border_color = Color(0.45, 0.3, 0.15)
	style.set_border_width_all(1)
	style.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	panel.anchor_left = 0.08
	panel.anchor_right = 0.92
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.98
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	_name = _label(10, Color(0.95, 0.75, 0.4))
	box.add_child(_name)
	_text = _label(10, Color(0.9, 0.88, 0.85))
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_text)
	_options = GridContainer.new()
	_options.columns = 2
	_options.add_theme_constant_override("h_separation", 8)
	_options.add_theme_constant_override("v_separation", 0)
	box.add_child(_options)


func open(p_guest: Guest) -> void:
	guest = p_guest
	visible = true
	Game.player.in_dialog = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if Game.hud:
		Game.hud.set_prompt("")
	guest.begin_talk()
	var to := guest.global_position - Game.player.global_position
	Game.player.rotation.y = atan2(-to.x, -to.z)
	Game.player.head.rotation.x = -0.05
	# Wer etwas Schlimmes erlebt hat, erzählt zuerst davon (Spielkonzept 6.12) – das Monster hört mit (4.7)
	var experience := guest.untold_experience()
	if not experience.is_empty():
		experience["told"] = true
		_say(Game.social.experience_line(guest, experience))
		Game.social.on_monster_talk(guest)
	elif guest.fear >= 60.0:
		_say(guest.line("panic"))
	elif Social.tier(guest) == Social.Tier.STRONG_ENEMY:
		_say("Du traust dich was. Sprich schnell – bevor ich es mir anders überlege.")
	elif Social.tier(guest) <= Social.Tier.ENEMY:
		_say(guest.line("greet_enemy"))
	elif Social.tier(guest) >= Social.Tier.FRIEND:
		_say(guest.line("greet_friend"))
	else:
		_say(guest.line("greet"))
	_show_main()


func close() -> void:
	visible = false
	if guest:
		guest.end_talk()
	guest = null
	Game.player.in_dialog = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		var key := (event as InputEventKey).keycode
		var index: int = 9 if key == KEY_0 else key - KEY_1
		if index >= 0 and index < _buttons.size() and not _buttons[index].disabled:
			_buttons[index].pressed.emit()
			get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if visible and (guest == null or guest.dead or Game.game_over):
		close()


# --- Seiten -------------------------------------------------------------------------

func _show_main() -> void:
	_clear()
	_name.text = "%s – %s" % [guest.display_name, Social.relation_word(guest.relation)]
	var player := Game.player
	if guest.fear >= 60.0:
		_option("Beruhigen", _calm)
		_option("Tschüss", close)
		return
	var tier := Social.tier(guest)
	if tier <= Social.Tier.ENEMY:
		var price: int = APOLOGY_PRICE[tier]
		_option("Entschuldigen (%d Geld)" % price, _apologize.bind(price), Game.money < price)
		_option("Tschüss", close)
		return
	if guest.challenge_time > 0.0:
		_option("Herausforderung annehmen (%s)" % ("Schach" if guest.challenge_game == "chess" else "Mäxchen"),
			_show_stakes.bind(guest.challenge_game))
	_option("Plaudern", _chat)
	if Game.director.first_attack_done:
		_option("Über das Monster reden", _talk_monster)
	else:
		_option("Ist dir hier etwas aufgefallen?", _talk_odd)
	_option("Handeln", _show_trade)
	if Game.dice and Game.dice.table.has_cup(player) and not Game.dice.table.busy:
		_option("Mäxchen an der Bar spielen", _show_stakes.bind("dice"))
	if Game.chess and Game.chess.table.has_board(player) and not Game.chess.table.busy:
		_option("Schach in der Lobby spielen", _show_stakes.bind("chess"))
	if player.held and player.held.kind != Item.Kind.KEY:
		_option("%s schenken" % player.held.display_name, _gift)
	_option("Hast du Deko für mich?", _ask_deco)
	if guest.is_following():
		_option("Du kannst gehen", _dismiss)
	elif tier >= Social.Tier.FRIEND:
		_option("Komm mit", _follow)
	if guest.fear >= 30.0:
		_option("Beruhigen", _calm)
	if Game.social.party_active:
		if guest.state != Guest.State.PARTY:
			_option("Komm mit zur Feier!", _join_party)
	elif not guest.invited:
		_option("Zur Feier in die Lobby einladen", _invite)
	_option("Beleidigen", _insult)
	_option("Tschüss", close)


func _show_trade() -> void:
	_clear()
	_say("Was darf's sein?" if Social.tier(guest) >= Social.Tier.NEUTRAL else "Mach schnell.")
	var player := Game.player
	for kind in guest.stock:
		var count := int(guest.stock[kind])
		if count <= 0:
			continue
		var price := _sell_price(kind)
		var label := "%s kaufen – %d Geld (%d da)" % [_kind_name(kind), price, count]
		_option(label, _buy.bind(kind), Game.money < price or player.held != null)
	if player.held and player.held.kind != Item.Kind.KEY:
		_option("%s verkaufen – %d Geld" % [player.held.display_name, _buy_price(player.held)], _sell)
	_option("Zurück", _show_main)


## Einsatz aushandeln (Spielkonzept 6.10). game: "dice" (Mäxchen) oder "chess" (Schach)
func _show_stakes(game: String) -> void:
	_game = game
	var match_ui: Node = Game.chess if game == "chess" else Game.dice
	var reason: String = match_ui.why_not(guest)
	if reason != "":
		_say(reason)
		_show_main()
		return
	_clear()
	_say("Um was spielen wir?")
	if game == "chess" and Game.social.has_watched_chess(guest):
		_name.text = "%s – %s (du hast zugesehen)" % [guest.display_name, ChessMatch.strength_text(guest)]
	_option("Nur zum Spaß", _play.bind(0, false))
	for amount in [3, 8]:
		_option("Um %d Geld" % amount, _play.bind(amount, false), Game.money < amount)
	if match_ui.can_stake_item(guest):
		_option("Um %s (deine Hand)" % Game.player.held.display_name, _play.bind(0, true))
	_option("Doch nicht", _show_main)


func _play(money: int, with_item: bool) -> void:
	var chess := _game == "chess"
	var prefix := "chess_" if chess else "dice_"
	var likes := bool((ChessMatch.chess_profile(guest) if chess else guest.profile["dice"])["likes"])
	var challenged := guest.challenge_time > 0.0 and guest.challenge_game == _game
	if Social.tier(guest) <= Social.Tier.ANGRY and not challenged:
		_say(guest.line(prefix + "no"))
		_show_main()
		return
	if money > guest.money:
		_say("So viel Geld hab ich nicht.")
		_show_stakes(_game)
		return
	if money == 0 and not with_item and float(guest.profile["greed"]) > 0.8:
		_say("Ohne Einsatz? Langweilig.")
		_show_stakes(_game)
		return
	if not likes and Social.tier(guest) <= Social.Tier.ANNOYED and not challenged:
		_say(guest.line(prefix + "no"))
		_show_main()
		return
	guest.challenge_time = 0.0
	var opponent := guest
	opponent.say(opponent.line(prefix + "yes"))
	close()
	if chess:
		Game.chess.start(opponent, {"money": money, "item": with_item})
	else:
		Game.dice.start(opponent, {"money": money, "item": with_item})


# --- Aktionen ---------------------------------------------------------------------

func _chat() -> void:
	if guest.chat_cooldown > 0.0:
		_say("Lass uns später weiterreden.")
	else:
		guest.chat_cooldown = CHAT_COOLDOWN
		var today := Calendar.today()
		if guest.chat_day != today:
			guest.chat_day = today
			guest.chats_today = 0
		guest.chats_today += 1
		Game.social.change_relation(guest, 6.0 if guest.chats_today <= CHATS_PER_DAY else 1.0)
		var cat_talk := Game.social.cat_line(guest) if randf() < 0.3 or Game.social.cat_thefts.has(guest.id) else ""
		_say(cat_talk if cat_talk != "" else guest.line("smalltalk"))
	_show_main()


## Vor dem ersten Angriff: alles wirkt harmlos (Spielkonzept 2.1).
func _talk_odd() -> void:
	_say(guest.line("odd"))
	Game.social.change_relation(guest, 1.0)
	_show_main()


func _talk_monster() -> void:
	# Manchmal erzählt der Gast von Spuren – nicht immer zuverlässig (4.13)
	var report := Game.social.report_line(guest)
	var cat_tip := Game.social.cat_monster_line()
	var experience := guest.recent_experience()   # eigenes Erlebnis vom selben Tag (6.12)
	if not experience.is_empty() and randf() < 0.5:
		_say(Game.social.experience_line(guest, experience, true))
	elif report != "" and randf() < 0.5:
		_say(report)
	elif cat_tip != "" and randf() < 0.3:
		_say(cat_tip)
	else:
		var lines: Array = guest.profile["lines"]["monster"]
		_say(lines[guest.monster_line % lines.size()])
		guest.monster_line += 1
	Game.social.change_relation(guest, 3.0)
	guest.fear = minf(100.0, guest.fear + 12.0 * (1.2 - float(guest.profile["brave"])))
	Game.social.on_monster_talk(guest)
	_show_main()


func _gift() -> void:
	var item := Game.player.held
	var liked := item.kind in (guest.profile["likes"] as Array)
	var bonus := item.price() * 2.0 + (10.0 if liked else 0.0) + 3.0
	Game.social.change_relation(guest, bonus)
	Game.social.add_deed(guest, "gifts_to")
	if item.deco_strength > 0.0:
		guest.stock[item.kind] = int(guest.stock.get(item.kind, 0)) + 1
	Game.player.consume_held()
	_say(guest.line("thanks_like" if liked else "thanks"))
	_show_main()


func _ask_deco() -> void:
	if Social.tier(guest) < Social.Tier.FRIEND:
		_say(guest.line("refuse_deco"))
	elif guest.gift_cooldown > 0.0:
		_say("Ich hab dir doch gerade erst was gegeben.")
	elif Game.player.held:
		_say("Mach erst mal die Hände frei.")
	else:
		var kind := _best_deco()
		if kind < 0:
			_say("Ich hab gerade selbst nichts übrig.")
		else:
			guest.stock[kind] = int(guest.stock[kind]) - 1
			guest.gift_cooldown = GIFT_COOLDOWN
			Game.player.receive_item(Item.create(kind))
			Game.social.add_deed(guest, "gifts_from")
			_say(guest.line("give_deco"))
	_show_main()


func _calm() -> void:
	guest.fear = maxf(0.0, guest.fear - 40.0)
	Game.social.change_relation(guest, 4.0)
	_say(guest.line("calm"))
	_show_main()


func _invite() -> void:
	if Social.tier(guest) >= Social.Tier.NEUTRAL:
		guest.invited = true
		_say(guest.line("party_yes") + " Sag Bescheid – der Plattenspieler steht in der Lobby.")
	else:
		Game.social.change_relation(guest, -2.0)
		_say(guest.line("party_no"))
	_show_main()


func _join_party() -> void:
	if Social.tier(guest) >= Social.Tier.ANNOYED:
		guest.invited = true
		_say(guest.line("party_yes"))
		var spot: Vector3 = Game.social.free_party_spot()
		var partner := guest   # close() setzt guest auf null
		close()
		partner.join_party(spot)
		return
	_say(guest.line("party_no"))
	_show_main()


func _insult() -> void:
	Game.social.change_relation(guest, -15.0)
	Game.social.on_insult(guest)
	_say(guest.line("insult"))
	_show_main()


## Befreundete Gäste kommen ein Stück mit (6.3) – bis du sie wegschickst, dich versteckst oder es zu gefährlich wird.
func _follow() -> void:
	if guest.fear >= 40.0:
		_say("Jetzt? Ich trau mich gerade nirgendwohin.")
		_show_main()
		return
	_say("Klar, ich komm mit.")
	var friend := guest   # close() setzt guest auf null
	close()
	friend.start_follow()


func _dismiss() -> void:
	_say("Na gut. Pass auf dich auf.")
	var friend := guest
	close()
	friend.stop_follow()


func _apologize(price: int) -> void:
	Game.money -= price
	guest.threatened = false
	Game.social.change_relation(guest, 12.0)
	_say("… Na gut. Fürs Erste.")
	_show_main()


func _buy(kind: int) -> void:
	var price := _sell_price(kind)
	if Game.money < price or Game.player.held:
		return
	Game.money -= price
	guest.money += price
	guest.stock[kind] = int(guest.stock[kind]) - 1
	Game.social.change_relation(guest, 1.0)
	Game.social.add_deed(guest, "gifts_from")
	Game.player.receive_item(Item.create(kind))
	_say("Gute Wahl.")
	_show_trade()


func _sell() -> void:
	var item := Game.player.held
	var price := _buy_price(item)
	if guest.money < price:
		_say("So viel Geld hab ich gerade nicht.")
		_show_trade()
		return
	guest.money -= price
	Game.money += price
	if item.deco_strength > 0.0:
		guest.stock[item.kind] = int(guest.stock.get(item.kind, 0)) + 1
	Game.player.consume_held()
	Game.social.change_relation(guest, 1.0)
	_say("Abgemacht.")
	_show_trade()


# --- Hilfen -----------------------------------------------------------------------

func _sell_price(kind: int) -> int:
	var base: float = Item.PRICES.get(kind, 1)
	var discount := _tier_factor(1.0, 0.95, 0.9, 0.8, 0.7)
	return maxi(1, roundi(base * float(guest.profile["sell"]) * discount))


func _buy_price(item: Item) -> int:
	var bonus := _tier_factor(1.0, 1.0, 1.05, 1.15, 1.25)
	return maxi(1, roundi(item.price() * float(guest.profile["buy"]) * bonus))


## Preisfaktor je Stufe: bis neutral, nett, freundlich, befreundet, guter Freund
func _tier_factor(neutral: float, nice: float, friendly: float, friend: float, good: float) -> float:
	match Social.tier(guest):
		Social.Tier.NICE:
			return nice
		Social.Tier.FRIENDLY:
			return friendly
		Social.Tier.FRIEND:
			return friend
		Social.Tier.GOOD_FRIEND:
			return good
	return neutral


func _best_deco() -> int:
	for kind in Guest.DECO_KINDS:
		if int(guest.stock.get(kind, 0)) > 0:
			return kind
	return -1


func _kind_name(kind: int) -> String:
	match kind:
		Item.Kind.PUMPKIN:
			return "Kürbis"
		Item.Kind.CARVED_PUMPKIN:
			return "Geschnitzter Kürbis"
		Item.Kind.CANDLE:
			return "Kerze"
		Item.Kind.COBWEB:
			return "Spinnenweben"
		Item.Kind.LEAVES:
			return "Herbstlaub"
		Item.Kind.KNIFE:
			return "Messer"
		Item.Kind.DICE_CUP:
			return "Würfelbecher"
		Item.Kind.LOADED_DICE:
			return "Gezinkte Würfel"
		Item.Kind.CHESS_BOARD:
			return "Schachbrett"
	return "Etwas"


func _say(text: String) -> void:
	_text.text = "„%s“" % text


func _clear() -> void:
	for button in _buttons:
		button.queue_free()
	_buttons.clear()


func _option(text: String, callback: Callable, disabled: bool = false) -> void:
	var button := Button.new()
	button.text = "%d. %s" % [_buttons.size() + 1, text]
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.disabled = disabled
	button.flat = true
	button.add_theme_font_size_override("font_size", 9)
	button.custom_minimum_size = Vector2(190, 0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tight := StyleBoxEmpty.new()
	tight.content_margin_top = 1
	tight.content_margin_bottom = 1
	for style_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(style_name, tight)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(callback)
	_options.add_child(button)
	_buttons.append(button)


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	var settings := LabelSettings.new()
	settings.font_size = font_size
	settings.font_color = color
	label.label_settings = settings
	return label
