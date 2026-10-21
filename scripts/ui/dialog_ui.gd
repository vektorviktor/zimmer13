class_name DialogUI
extends CanvasLayer
## Gespräch mit einem Gast (Spielkonzept 6.2–6.5, 6.9): Plaudern, über das Monster
## reden, Handeln, Schenken, um Deko bitten, beruhigen, zur Feier einladen,
## beleidigen, entschuldigen, mitkommen lassen (6.3). Auswahl per Maus oder Zifferntasten 1–9 und 0, Esc schließt.
## Prototyp: „Etwas fragen …“ – Freitext über das lokale Sprachmodell (GuestChat, Spielkonzept 6.15).

const CHAT_COOLDOWN := 40.0
const GIFT_COOLDOWN := 150.0
## Nicht zu verschenken: Schlüssel und was dem Hotel gehört (Schachbrett, Würfelbecher – Wunsch 2026-10-21)
const NO_GIFT := [Item.Kind.KEY, Item.Kind.CHESS_BOARD, Item.Kind.DICE_CUP]
## Gebratener Kürbis als Geschenk (Spielkonzept 3.8): so viel weniger Angst
const ROAST_CALM := 20.0
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
var _page := ""         ## "main", "ask" oder eine andere Seite (nur main und ask werden neu aufgebaut)
var _question: LineEdit ## Eingabe für „Etwas fragen …“ (nur auf der Seite ask sichtbar)
## Debug --ask=gast,frage|frage: diese Fragen nacheinander stellen, sobald das Modell bereit ist
var debug_questions: Array[String] = []


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
	_question = LineEdit.new()
	_question.placeholder_text = "Frag etwas … (Enter)"
	_question.max_length = GuestChat.MAX_INPUT
	_question.add_theme_font_size_override("font_size", 9)
	_question.visible = false
	_question.text_submitted.connect(_submit_question)
	box.add_child(_question)
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
	if GuestChat.can_ask(guest):
		LlmClient.ensure()   # lädt das Modell beim ersten Gespräch (Prototyp)
	var to := guest.global_position - Game.player.global_position
	Game.player.rotation.y = atan2(-to.x, -to.z)
	Game.player.head.rotation.x = -0.05
	# Wer etwas Schlimmes erlebt hat, erzählt zuerst davon (Spielkonzept 6.12) – das Monster hört mit (4.7)
	var experience := guest.untold_experience()
	var witness := _wound_visit()
	if witness != "":
		_say(witness)   # Überlebender (6.17): bei jedem Gespräch ein neues Detail, alles stimmt
		Game.social.on_monster_talk(guest)
		experience = {"told": true}
	elif guest.wound_note != "":
		_say(Wounds.NEGLECT_LINE if guest.wound_note == "neglect" else Wounds.HEALED_LINE)
		guest.wound_note = ""
		experience = {"told": true}
	elif guest.wound != "":
		_say(Wounds.GREET[guest.wound].pick_random())
		experience = {"told": true}
	elif not experience.is_empty():
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
	# Ein Freund hat ihm Gutes über dich erzählt (Spielkonzept 6.16)
	var heard := Game.social.pals.take_heard_line(guest)
	if heard != "" and experience.is_empty() and guest.fear < 60.0:
		_text.text += " " + heard
	if guest.drunk >= BarTap.TIPSY:
		_text.text = "*hicks* " + _text.text
	if Game.player.disguised:   # unter dem Laken (5.9)
		_text.text = "„Wer steckt denn da drunter? … Ach, du bist's!“ " + _text.text
	_show_main()


func close() -> void:
	visible = false
	_question.visible = false
	_question.release_focus()
	debug_questions.clear()
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
		return
	if not visible or Game.llm == null or not GuestChat.can_ask(guest):
		return
	# Modell ist inzwischen geladen: „Etwas fragen …“ freischalten bzw. die Debug-Fragen stellen
	if Game.llm.is_ready() and _page == "main" and _buttons.any(func(b: Button) -> bool: return b.disabled and b.text.ends_with("(lädt …)")):
		_show_main()
	if Game.llm.is_ready() and not debug_questions.is_empty() and not Game.llm.busy() and _question.editable:
		if _page != "ask":
			_show_ask()
		_submit_question(debug_questions.pop_front())


# --- Seiten -------------------------------------------------------------------------

func _show_main() -> void:
	_clear()
	_page = "main"
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
	if Game.social.search.has_offer(guest):
		_option("Klar, ich such mit!", _search)   # er hat gefragt, ob du mitkommst (5.9)
	_option("Plaudern", _chat)
	if GuestChat.can_ask(guest) and Game.llm and Game.llm.state in ["starting", "warming", "ready"]:
		var loading: bool = not Game.llm.is_ready()
		_option("Etwas fragen …" + (" (lädt …)" if loading else ""), _show_ask, loading)
	if Game.director.first_attack_done:
		_option("Über das Monster reden", _talk_monster)
	else:
		_option("Ist dir hier etwas aufgefallen?", _talk_odd)
	_option("Handeln", _show_trade)
	if Game.social.builder.in_area(player.global_position, "bar"):
		if guest.is_child():
			_option("Einen Kakao ausgeben (%d Geld)" % BarTap.PRICE, _cocoa, Game.money < BarTap.PRICE)
		else:
			_option("Eine Runde ausgeben (%d Geld)" % (BarTap.PRICE * 2), _round, Game.money < BarTap.PRICE * 2)
	if Game.dice and Game.dice.table.has_cup(player) and not Game.dice.table.busy:
		_option("Mäxchen an der Bar spielen", _show_stakes.bind("dice"))
	if Game.chess and Game.chess.table.has_board(player) and not Game.chess.table.busy:
		_option("Schach in der Lobby spielen", _show_stakes.bind("chess"))
	if player.held and not player.held.kind in NO_GIFT:
		_option("%s schenken" % player.held.display_name, _gift)
	_option("Hast du Deko für mich?", _ask_deco)
	if tier >= Social.Tier.NICE and not Game.social.party_active:
		_option("Wollen wir zusammen …", _show_together)
	if guest.is_following():
		_option("Du kannst gehen", _dismiss)
	elif tier >= Social.Tier.FRIEND:
		_option("Komm mit", _follow)
	if guest.sleepless and Game.social.sleep_active:
		_option("Ab ins Bett mit dir", _to_bed)
	if guest.fear >= 30.0:
		_option("Beruhigen", _calm)
	if Game.social.party_active:
		if guest.state != Guest.State.PARTY:
			_option("Komm mit zur Feier!", _join_party)
	elif not guest.invited:
		_option("Zur Feier in die Lobby einladen", _invite)
	_option("Beleidigen", _insult)
	_option("Tschüss", close)


## Besuch bei einem Verletzten (Spielkonzept 6.17): zählt als Besuch, einmal am Spieltag heilt es etwas schneller; das
## nächste Detail, das er als Zeuge erzählt ("" = keins mehr). Erlebnisse vom Angriff gelten damit als erzählt.
func _wound_visit() -> String:
	if guest.wound == "":
		return ""
	guest.wound_visited = true
	if int(guest.wound_facts.get("visit_day", 0)) != Calendar.today():
		guest.wound_facts["visit_day"] = Calendar.today()
		guest.speed_healing(Wounds.VISIT_HEAL)
	var line := guest.witness_line()
	if line != "" and guest.is_hoarse():
		line = "*heiser* " + line   # Würgemale
	if line != "":
		for e in guest.experiences:
			if e["kind"] in ["monster", "ghost", "ghost_attack", "pumpkin"]:
				e["told"] = true
	return line


## Gemeinsam etwas machen (Spielkonzept 5.9, 2026-10-21): schmücken, wo du stehst, groß schmücken, Deko suchen.
func _show_together() -> void:
	_clear()
	_say("Woran denkst du?")
	if not guest.is_child():
		_option("… hier schmücken?", _decorate_here.bind(false))
		if Game.social.decorating.can_call_big():
			_option("… ein großes Schmücken ausrufen?", _decorate_here.bind(true))
	_option("… Deko suchen gehen?", _search)
	_option("Zurück", _show_main)


func _decorate_here(big: bool) -> void:
	var partner := guest   # close() setzt guest auf null
	var why: String = Game.social.decorating.call_here(partner, big)
	if why != "":
		_say(why)
		_show_main()
		return
	close()
	if not big:   # beim großen Schmücken ruft er selbst alle zusammen
		partner.say(Decorating.PLAYER_CALL_LINES.pick_random())


func _search() -> void:
	var partner := guest
	var why: String = Game.social.search.ask(partner)
	if why != "":
		_say(why)
		_show_main()
		return
	close()
	Game.social.search.lead_off(partner)


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
	_say(guest.line("only_fun") if guest.is_child() else "Um was spielen wir?")
	if game == "chess" and Game.social.has_watched_chess(guest):
		_name.text = "%s – %s (du hast zugesehen)" % [guest.display_name, ChessMatch.strength_text(guest)]
	_option("Nur zum Spaß", _play.bind(0, false))
	if guest.is_child():   # Kinder spielen nie um Einsätze (6.13)
		_option("Doch nicht", _show_main)
		return
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


## Freitext (Prototyp, 6.15): Eingabezeile, Enter schickt die Frage ans Sprachmodell (GuestChat).
func _show_ask() -> void:
	_clear()
	_page = "ask"
	_question.visible = true
	_question.editable = true
	_question.grab_focus.call_deferred()
	_option("Zurück", _show_main)


func _submit_question(text: String) -> void:
	if text.strip_edges() == "" or not _question.editable:
		return
	_question.editable = false
	_question.text = text
	var shown := _text.text
	_text.text = "*%s überlegt …*" % guest.display_name
	if not GuestChat.ask(guest, text, _on_answer.bind(guest)):
		_text.text = shown
		_question.editable = true


func _on_answer(intent: String, reply: String, _info: Dictionary, asked: Guest) -> void:
	if guest != asked or not visible:
		return   # Gespräch inzwischen beendet
	_question.editable = true
	_question.clear()
	if debug_questions.is_empty():
		Game.shot_event("answer")   # --shot-on=answer: nach der letzten Debug-Frage
	if _page == "ask":
		_question.grab_focus.call_deferred()
	match intent:
		"":
			_say("Hm? … Was hast du gesagt?")
		"monster":
			_say(reply)
			if Game.director.first_attack_done:
				_monster_talked()
			else:
				Game.social.change_relation(guest, 1.0)
		"einladen":   # entscheidet das Spiel, nicht das Modell
			_invite()
			_show_ask()
		"beleidigen":
			_insult()
		_:
			if intent == "plaudern":
				_count_chat()
			_say(reply)


# --- Aktionen ---------------------------------------------------------------------

func _chat() -> void:
	if not _count_chat():
		_say("Lass uns später weiterreden.")
	else:
		var cat_talk := Game.social.cat_line(guest) if randf() < 0.3 or Game.social.cat_thefts.has(guest.id) else ""
		_say(cat_talk if cat_talk != "" else guest.line("smalltalk"))
	_show_main()


## Plaudern zählt für die Beziehung (6.3) – false, solange die Pause seit dem letzten Plaudern läuft.
func _count_chat() -> bool:
	if guest.chat_cooldown > 0.0:
		return false
	guest.chat_cooldown = CHAT_COOLDOWN
	var today := Calendar.today()
	if guest.chat_day != today:
		guest.chat_day = today
		guest.chats_today = 0
	guest.chats_today += 1
	Game.social.change_relation(guest, 6.0 if guest.chats_today <= CHATS_PER_DAY else 1.0)
	return true


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
	elif report != "" and randf() < 0.5 + 0.4 * guest.drunk:   # betrunken erzählt er mehr (3.7)
		_say(report)
	elif cat_tip != "" and randf() < 0.3:
		_say(cat_tip)
	else:
		var lines: Array = guest.profile["lines"]["monster"]
		_say(lines[guest.monster_line % lines.size()])
		guest.monster_line += 1
	_monster_talked()
	_show_main()


## Über das Monster reden: Beziehung ↑, Angst ↑, und das Monster hört mit (4.7)
func _monster_talked() -> void:
	Game.social.change_relation(guest, 3.0)
	guest.fear = minf(100.0, guest.fear + 12.0 * (1.2 - float(guest.profile["brave"])))
	Game.social.on_monster_talk(guest)


func _gift() -> void:
	var item := Game.player.held
	var kind := item.kind
	# Kürbis in seiner Lieblingssorte (Spielkonzept 5.8): freut ihn wie etwas, das er mag, und noch ein bisschen mehr
	var is_pumpkin := kind in [Item.Kind.PUMPKIN, Item.Kind.CARVED_PUMPKIN, Item.Kind.ROAST_PUMPKIN]
	var favorite := is_pumpkin and item.variety == guest.favorite_pumpkin()
	var liked := kind in (guest.profile["likes"] as Array) or favorite
	var bonus := item.price() * 2.0 + (10.0 if liked else 0.0) + (8.0 if favorite else 0.0) + 3.0
	var fitting := false
	if guest.wound != "":
		# Verletzt (Spielkonzept 6.17): Geschenke dreifach (×2 in change_relation), passende noch mehr, zählen doppelt
		fitting = Wounds.fitting(guest.wound, item, guest.in_sickbed())
		bonus = bonus * Wounds.GIFT_FACTOR + (Wounds.FITTING if fitting else 0.0)
		guest.speed_healing(Wounds.GIFT_HEAL)
	Game.social.change_relation(guest, bonus)
	Game.social.add_deed(guest, "gifts_to", Wounds.GIFT_DEEDS if guest.wound != "" else 1)
	# Er nimmt es in die Hand und trägt es heim bzw. isst es (6.17); mit vollen Händen wandert es gleich in den Vorrat
	if not guest.receive_gift(Game.player.hand_over()):
		if item.deco_strength > 0.0:
			guest.stock[kind] = int(guest.stock.get(kind, 0)) + 1
		item.queue_free()
	var fav_name := String(PumpkinKinds.data(guest.favorite_pumpkin())["name"])
	if kind == Item.Kind.ROAST_PUMPKIN:
		# Gebratener Kürbis (Spielkonzept 3.8): er isst ihn gleich – das beruhigt
		guest.fear = maxf(0.0, guest.fear - ROAST_CALM)
		_say("Gebratener %s – mein Lieblingskürbis! Du bist ein Schatz." % fav_name if favorite
			else "Oh, noch warm! Danke – das tut gut.")
	elif fitting:
		_say("Genau das hab ich jetzt gebraucht. Danke – wirklich." if kind != Item.Kind.CANDLE
			else "Eine Kerze … dann ist es heute Nacht nicht ganz dunkel. Danke.")
	elif favorite:
		_say("Ein %s! Mein Lieblingskürbis – woher wusstest du das?" % fav_name)
	elif is_pumpkin and randf() < 0.6:
		_say("%s Mein Lieblingskürbis ist ja der %s." % [guest.line("thanks"), fav_name])   # ein Hinweis für das nächste Mal
	else:
		_say(guest.line("thanks_like" if liked else "thanks"))
	if guest.is_child() and kind == Item.Kind.KNIFE:
		# Ein Messer für ein Kind (6.13): Mama oder Papa erfahren es – und sind wütend
		_say(guest.line("knife"))
		var parent := guest.parent_guest()
		if parent:
			Game.social.change_relation(parent, -20.0)
			Game.social.add_deed(parent, "hostile")
	elif kind == Item.Kind.SWEETS:
		Game.social.on_sweets_given(guest)
	_show_main()


func _ask_deco() -> void:
	# Kinder geben schon ab „nett“ etwas ab (6.13)
	if Social.tier(guest) < (Social.Tier.NICE if guest.is_child() else Social.Tier.FRIEND):
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
			Game.player.receive_item(guest.stock_item(kind))
			Game.social.add_deed(guest, "gifts_from")
			_say(guest.line("give_deco"))
	_show_main()


## An der Bar: zwei Gläser, eins für jeden (Spielkonzept 3.7) – die Beziehung steigt, beide werden betrunkener.
## Für ein Kind (6.13): Kakao statt Alkohol – nimmt Angst, freut es.
func _cocoa() -> void:
	Game.money -= BarTap.PRICE
	guest.fear = maxf(0.0, guest.fear - 25.0)
	Game.social.change_relation(guest, 5.0)
	_say(guest.line("cocoa"))
	_show_main()


func _round() -> void:
	if guest.is_child():
		_say(guest.line("no_drink"))   # Kinder trinken nie (6.13)
		_show_main()
		return
	if guest.drunk >= BarTap.ENOUGH:
		_say("Für mich nicht mehr, danke … *hicks*")
	elif Game.player.drunk >= BarTap.ENOUGH:
		_say("Du hast genug, glaub mir.")
	else:
		Game.money -= BarTap.PRICE * 2
		Game.player.drink(true)
		guest.drink()
		Game.social.change_relation(guest, 5.0)
		_say("Auf uns! Und darauf, dass wir diesen Monat überstehen." if guest.drunk < BarTap.DRUNK
			else "Du bist … *hicks* … ein echter Freund, weißt du das?")
	_show_main()


func _calm() -> void:
	guest.fear = maxf(0.0, guest.fear - 40.0)
	Game.social.change_relation(guest, 4.0)
	_say(guest.line("calm"))
	_show_main()


func _invite() -> void:
	if Social.tier(guest) >= Social.Tier.NEUTRAL or guest.is_child():   # Kinder kommen immer (6.13)
		guest.invited = true
		_say(guest.line("party_yes") + " Sag Bescheid – der Plattenspieler steht in der Lobby.")
	else:
		Game.social.change_relation(guest, -2.0)
		_say(guest.line("party_no"))
	_show_main()


func _join_party() -> void:
	if Social.tier(guest) >= Social.Tier.ANNOYED or guest.is_child():
		guest.invited = true
		_say(guest.line("party_yes"))
		var spot: Vector3 = Game.social.free_party_spot(guest)
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


## Schlafloses Kind in der Nachtruhe zurück ins Bett schicken (6.13) – Mama oder Papa sind dankbar.
func _to_bed() -> void:
	_say(guest.line("to_bed"))
	Game.social.change_relation(guest, 3.0)
	var parent := guest.parent_guest()
	if parent:
		Game.social.change_relation(parent, 8.0)
	var kid := guest   # close() setzt guest auf null
	close()
	kid.send_to_bed()


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
	Game.player.receive_item(guest.stock_item(kind))
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
		Item.Kind.SWEETS:
			return "Süßigkeiten"
	return "Etwas"


func _say(text: String) -> void:
	_text.text = "„%s“" % text


func _clear() -> void:
	_page = ""
	_question.visible = false
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
