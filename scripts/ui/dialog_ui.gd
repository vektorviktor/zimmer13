class_name DialogUI
extends CanvasLayer
## Gespräch mit einem Gast (Spielkonzept 6.2–6.5, 6.9): Plaudern, über das Monster
## reden, Handeln, Schenken, um Deko bitten, beruhigen, zur Feier einladen,
## beleidigen, entschuldigen, mitkommen lassen (6.3). Auswahl per Maus oder Zifferntasten 1–9 und 0, Esc schließt.
## Ausbau 6.9 (2026-10-24, Logik in Talk): oben bis zu zwei Anlässe je nach Lage, dann in fester Ordnung Plaudern,
## „Ich muss dir was erzählen …“ (Erlebnisse und Lügen), „Sag mal …“ (Fragen), „Könntest du …“ (Bitten), Handeln …,
## zuletzt Tschüss; zu Beginn stellt der Gast manchmal selbst eine Frage. Zu lange Listen scrollen.

const CHAT_COOLDOWN := 40.0
const GIFT_COOLDOWN := 150.0
## Nicht zu verschenken: Schlüssel und was dem Hotel gehört (Schachbrett, Würfelbecher – Wunsch 2026-10-21)
const NO_GIFT := [Item.Kind.KEY, Item.Kind.CHESS_BOARD, Item.Kind.DICE_CUP, Item.Kind.DARTS]
## Gebratener Kürbis als Geschenk (Spielkonzept 3.8): so viel weniger Angst
const ROAST_CALM := 20.0
## Plaudern zählt am Tag nur so oft voll (6.3), danach kaum noch
const CHATS_PER_DAY := 2
## Entschuldigen kostet je nach Stufe (verfeindet / stark verfeindet)
const APOLOGY_PRICE := {Social.Tier.ENEMY: 5, Social.Tier.STRONG_ENEMY: 15}
## Anlässe (6.9): höchstens so viele oben im Menü; „Was hältst du von …?“ für Gäste bis so weit weg
const MAX_OCCASIONS := 2
const NEIGHBOR_RANGE := 4.0

var guest: Guest

var _name: Label
var _text: Label
var _options: GridContainer
var _buttons: Array[Button] = []
var _game := "dice"     ## Spiel, um dessen Einsatz gerade verhandelt wird ("dice", "chess" oder "darts")
var _door: Door = null  ## Gespräch an der Tür (Spielkonzept 6.19): die Zimmertür, durch deren Spalt geredet wird
var _woken := false
var _scroll: ScrollContainer
var _question := {}     ## Frage des Gastes, auf die du gerade antwortest (Talk.pick_question)
var _done := {}         ## "gast|anlass" → Spieltag: Anlass schon genutzt (nicht gespeichert)


func _ready() -> void:
	layer = 15
	visible = false
	var box := UiKit.dark_panel(self, Color(0.05, 0.03, 0.03, 0.92), Color(0.45, 0.3, 0.15), Vector4(0.08, 0.5, 0.92, 0.98))
	_name = UiKit.plain_label(10, Color(0.95, 0.75, 0.4))
	box.add_child(_name)
	_text = UiKit.plain_label(10, Color(0.9, 0.88, 0.85))
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_text)
	# Lange Listen scrollen (6.9) – Leiste im Ton des Kastens
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_scroll)
	var bar := _scroll.get_v_scroll_bar()
	var grab := StyleBoxFlat.new()
	grab.bg_color = Color(0.45, 0.3, 0.15, 0.8)
	grab.content_margin_left = 2
	grab.content_margin_right = 2
	for style_name in ["grabber", "grabber_highlight", "grabber_pressed"]:
		bar.add_theme_stylebox_override(style_name, grab)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(1, 1, 1, 0.05)
	track.content_margin_left = 2
	track.content_margin_right = 2
	bar.add_theme_stylebox_override("scroll", track)
	_options = UiKit.option_grid(_scroll)
	_options.size_flags_horizontal = Control.SIZE_EXPAND_FILL


## force_question: diese Frage stellt er sicher (Debug --gespraech=frage).
func open(p_guest: Guest, force_question: String = "") -> void:
	guest = p_guest
	_question = {}
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
	var greeting_only := false   # nur ein Gruß des Verletzten – danach passt „X hat mir von dir erzählt“ noch
	var witness := _wound_visit()
	# Was er sich über dich gemerkt hat (6.9) – aufgeflogene Lüge, Versprechen –, sonst vielleicht eine Frage
	var talk := Game.social.talk
	var requests := Game.social.requests
	var remembered := ""
	var thanks := ""   # Dank für eine ausgerichtete Nachricht (6.14)
	var offer := {}    # eine Bitte, die er von sich aus stellt (6.14)
	if experience.is_empty() and guest.wound == "" and guest.wound_note == "" and guest.fear < 60.0:
		remembered = talk.greeting(guest)
		if remembered == "":
			thanks = requests.thanks_on_greet(guest)
		if remembered == "" and thanks == "" and force_question == "":
			offer = requests.offer_for(guest)
		if remembered == "" and thanks == "" and offer.is_empty():
			_question = talk.pick_question(guest, force_question)
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
		greeting_only = true
	elif not experience.is_empty():
		experience["told"] = true
		_say(Game.social.experience_line(guest, experience))
		Game.social.on_monster_talk(guest)
	elif remembered != "":
		_say(remembered)
	elif thanks != "":
		_say(thanks)
	elif not offer.is_empty():
		_say(String(offer["ask"]))
	elif not _question.is_empty():
		_say(String(_question["text"]))
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
	# Ein Freund hat ihm Gutes über dich erzählt (Spielkonzept 6.16) – nach einem Erlebnis oder einem Detail des
	# Verletzten (6.17) erst in einem späteren Gespräch, darum nur abholen, wenn der Satz auch kommt
	if (experience.is_empty() or greeting_only) and guest.fear < 60.0 and _question.is_empty():
		var heard := Game.social.pals.take_heard_line(guest)
		if heard != "":
			_text.text += " " + heard
		var nudge := requests.reminder(guest) if offer.is_empty() and thanks == "" else ""
		if nudge != "":
			_text.text += " „%s“" % nudge
	if guest.drunk >= BarTap.TIPSY:
		_text.text = "*hicks* " + _text.text
	if Game.player.disguised:   # unter dem Laken (5.9)
		_text.text = "„Wer steckt denn da drunter? … Ach, du bist's!“ " + _text.text
	if not _question.is_empty():
		_show_question()
	elif not offer.is_empty():
		_show_offer(offer)
	else:
		_show_main()
	if talk.debug_answer >= 0:   # --gespraech: gleich antworten bzw. den ersten Anlass wählen
		var pick := talk.debug_answer
		talk.debug_answer = -1
		get_tree().create_timer(1.5, false).timeout.connect(func() -> void:
			if visible and pick < _buttons.size():
				print("[Gespräch] wähle: %s" % _buttons[pick].text)
				_buttons[pick].pressed.emit()
				print("[Gespräch] %s: %s" % [_name.text, _text.text]))


## Gespräch an der Tür eines Gästezimmers (Spielkonzept 6.19, RoomAccess): der Bewohner im Türspalt, vier Wege hinein.
func open_door(p_guest: Guest, door: Door, woken: bool) -> void:
	guest = p_guest
	_door = door
	_woken = woken
	visible = true
	Game.player.in_dialog = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if Game.hud:
		Game.hud.set_prompt("")
	guest.begin_talk()
	var to := door.center() - Game.player.global_position
	Game.player.rotation.y = atan2(-to.x, -to.z)
	_clear()
	_name.text = "%s – an der Tür" % guest.display_name
	var tier := Social.tier(guest)
	if guest.is_child():
		_say("Wer ist da?" if not Game.social.access.knows_player(guest) else "Ach, du bist's!")
	elif woken:
		_say("Weißt du, wie spät es ist? Was willst du?")
	elif tier <= Social.Tier.ANGRY:
		_say("Du? Verschwinde.")
		_option("Gehen", _door_close)
		return
	elif tier >= Social.Tier.FRIEND:
		_say("Ach, du bist's! Was gibt's?")
	elif tier <= Social.Tier.ANNOYED:
		_say("Was willst du?")
	else:
		_say("Ja, bitte?")
	_option("Darf ich reinkommen?", _door_try.bind("honest"))
	_option("Lügen: „Die Rezeption schickt mich – wegen deiner Lampe.“", _door_try.bind("lie_lamp"))
	_option("Lügen: „Ich hab was für dich.“", _door_try.bind("lie_gift"))
	_option("Panik machen: „Es ist hinter mir! Lass mich rein!“", _door_try.bind("panic"))
	_option("Bestechen (%d Geld)" % RoomAccess.BRIBE_MONEY, _door_try.bind("bribe"), Game.money < RoomAccess.BRIBE_MONEY)
	_option("Schon gut.", _door_close)


## Läuft gerade ein Gespräch an der Tür? (Debug --klopfen)
func at_door() -> bool:
	return _door != null


func answer_door(way: String) -> void:
	_door_try(way)


func _door_try(way: String) -> void:
	var result: Dictionary = Game.social.access.try_enter(guest, _door, way, _woken)
	_clear()
	_say(String(result["line"]))
	_door = null   # die Tür regelt jetzt RoomAccess (offen oder wieder zu)
	_option("Weiter", close)


func _door_close() -> void:
	if _door and is_instance_valid(guest):
		_door.set_open(false, false, true, guest)
	_door = null
	close()


func close() -> void:
	if _door and is_instance_valid(guest):   # Esc im Türgespräch: der Spalt geht wieder zu
		_door.set_open(false, false, true, guest)
	_door = null
	visible = false
	if is_instance_valid(guest):
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
	elif UiKit.press_number(event, _buttons):
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if visible and (not is_instance_valid(guest) or guest.dead or Game.game_over):
		close()


# --- Seiten -------------------------------------------------------------------------

## Hauptmenü in fester Ordnung (Spielkonzept 6.9): Anlässe, Angebote des Gastes, Plaudern, die drei Gruppen, Handeln,
## Schenken, Spielen, Monster, Beruhigen, Feier, Beleidigen, Tschüss.
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
	for occasion in _occasions().slice(0, MAX_OCCASIONS):
		_option(String(occasion["label"]), _occasion.bind(String(occasion["key"]), occasion["call"]))
	if guest.challenge_time > 0.0:
		_option("Herausforderung annehmen (%s)" % {"chess": "Schach", "darts": "Darts"}.get(guest.challenge_game, "Mäxchen"),
			_show_stakes.bind(guest.challenge_game))
	if Game.social.search.has_offer(guest):
		_option("Klar, ich such mit!", _search)   # er hat gefragt, ob du mitkommst (5.9)
	if guest.sleepless and Game.social.sleep_active:
		_option("Ab ins Bett mit dir", _to_bed)
	var own: Dictionary = Game.social.requests.request_of(guest)
	if own.get("kind", "") == "escort" and not guest.is_following():
		_option("Komm, ich bring dich zur Bar", _escort)   # seine Bitte (6.14)
	_option("Plaudern", _chat)
	_option("Ich muss dir was erzählen …", _show_tell)
	_option("Sag mal …", _show_ask)
	_option("Könntest du …", _show_please)
	_option("Handeln", _show_trade)
	if Game.social.builder.in_area(player.global_position, "bar"):
		if guest.is_child():
			_option("Einen Kakao ausgeben (%d Geld)" % BarTap.PRICE, _cocoa, Game.money < BarTap.PRICE)
		else:
			_option("Eine Runde ausgeben (%d Geld)" % (BarTap.PRICE * 2), _round, Game.money < BarTap.PRICE * 2)
	if player.held and not player.held.kind in NO_GIFT:
		_option("%s schenken" % player.held.display_name, _gift.bind(player.held))
	if not _bag_items(true).is_empty():
		_option("Aus der Tasche schenken …", _show_bag.bind(true))
	if Game.dice and Game.dice.table.has_cup(player) and not Game.dice.table.busy:
		_option("Mäxchen an der Bar spielen", _show_stakes.bind("dice"))
	if Game.chess and Game.chess.table.has_board(player) and not Game.chess.table.busy:
		_option("Schach in der Lobby spielen", _show_stakes.bind("chess"))
	if Game.darts and Game.darts.board and Game.darts.board.has_darts(player) and not Game.darts.board.busy 			and not guest.is_child():
		_option("Darts in der Bar spielen", _show_stakes.bind("darts"))
	if Game.director.first_attack_done:
		_option("Über das Monster reden", _talk_monster)
	else:
		_option("Ist dir hier etwas aufgefallen?", _talk_odd)
	if guest.fear >= 30.0:
		_option("Beruhigen", _calm)
	if Game.social.party_active:
		if guest.state != Guest.State.PARTY:
			_option("Komm mit zur Feier!", _join_party)
	elif not guest.invited:
		_option("Zur Feier in den Partyraum einladen", _invite)
	_option("Beleidigen", _insult)
	_option("Tschüss", close)


# --- Anlässe, Erzählen, Fragen, Bitten (Spielkonzept 6.9) ----------------------------------------

## Was die Lage gerade hergibt, nach Vorrang: Warnen, ein frisches Erlebnis, Trauer, was er gerade tut, Gewitter,
## wer daneben steht. Jeder Anlass einmal je Gast und Spieltag.
func _occasions() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var talk := Game.social.talk
	var day := Calendar.today()
	var add := func(key: String, label: String, call: Callable) -> void:
		if int(_done.get(guest.id + "|" + key, -1)) != day:
			list.append({"key": key, "label": label, "call": call})
	if Game.monster and Game.monster.is_active() and guest.hiding == null:
		add.call("warn:%d" % Game.director.attacks, "Versteck dich! Es ist unterwegs!", _warn)
	var message := Game.social.requests.message_for(guest)   # etwas ausrichten (6.14)
	if not message.is_empty():
		add.call("msg:" + String(message["id"]), String(message["say"]), _deliver.bind(message))
	var fresh := talk.untold(guest)
	if not fresh.is_empty():
		add.call("tell:%d" % int(fresh[0]["id"]), talk.tell_label(fresh[0]), _tell_story.bind(fresh[0]))
	if guest.has_stance("grieving"):
		add.call("grief", "%s fehlt mir auch." % String(guest.stances["grieving"].get("who", "")), _comfort)
	if guest.talk_prev in [Guest.State.DECORATE, Guest.State.PLACE_DECO]:
		add.call("deco", "Schön geworden!", _praise_deco)
	elif guest.talk_prev == Guest.State.EAT:
		add.call("eat", "Lass es dir schmecken.", _enjoy_meal)
	if Game.weather and Game.weather.kind == Weather.Kind.STORM:
		add.call("storm", "Hast du auch Angst vor dem Gewitter?", _storm_talk)
	var near: Guest = null
	var near_d := NEIGHBOR_RANGE
	for other in Game.social.living_guests():
		var g: Guest = other
		var d := g.global_position.distance_to(guest.global_position)
		if g != guest and d < near_d:
			near = g
			near_d = d
	if near:
		add.call("opinion:" + near.id, "Was hältst du von %s?" % near.display_name, _opinion.bind(near))
	return list


func _occasion(key: String, call: Callable) -> void:
	_done[guest.id + "|" + key] = Calendar.today()
	call.call()


## Warnen (6.18): Er bringt sich in Sicherheit – es ist ja wirklich etwas unterwegs.
func _warn() -> void:
	Game.social.talk.friendly(guest, 6.0)
	var partner := guest
	close()
	partner.say("Danke! Ich bin weg!" if not partner.is_child() else "Ich hab Angst! Ich lauf heim!")
	partner.take_cover()


func _comfort() -> void:
	guest.fear = maxf(0.0, guest.fear - 20.0)
	Game.social.talk.friendly(guest, 4.0)
	_say("*schnieft* Danke." if guest.is_child() else "Danke … das tut gut, das zu hören.")
	_show_main()


func _praise_deco() -> void:
	Game.social.talk.friendly(guest, 3.0)
	_say("Findest du? Danke! Ich bin noch nicht fertig.")
	_show_main()


func _enjoy_meal() -> void:
	Game.social.talk.friendly(guest, 2.0)
	_say("Danke! Willst du was abhaben? … War nur ein Witz.")
	_show_main()


func _storm_talk() -> void:
	if Talk.temper(guest) in ["ängstlich", "Kind"]:
		guest.fear = maxf(0.0, guest.fear - 10.0)
		Game.social.talk.friendly(guest, 4.0)
		_say("Ja! Gut, dass ich nicht allein bin.")
	else:
		Game.social.talk.friendly(guest, 1.0)
		_say("Ach was. Aber gemütlich ist es nicht.")
	_show_main()


func _opinion(other: Guest) -> void:
	_say(Game.social.talk.opinion(guest, other) if is_instance_valid(other) else "Wen meinst du?")
	_show_main()


## „Ich muss dir was erzählen …“: frische Erlebnisse, die er noch nicht kennt – und das Erfinden.
func _show_tell() -> void:
	_clear()
	_say("Ja? Was denn?")
	var talk := Game.social.talk
	for e in talk.untold(guest).slice(0, 4):
		_option(talk.tell_label(e), _tell_story.bind(e))
	_option("Mir ist was passiert …", _show_lie)
	_option("Zurück", _show_main)


func _tell_story(e: Dictionary) -> void:
	_say(Game.social.talk.tell(guest, e, false))
	_show_main()


## Lügen (6.9): erst was, dann wer bzw. wo.
func _show_lie() -> void:
	_clear()
	_say("Was ist passiert?")
	for kind in Talk.LIE_LABEL:
		var k: String = kind
		if k == "corpse" or k == "thief":
			_option(String(Talk.LIE_LABEL[k]), _show_lie_who.bind(k))
		else:
			_option(String(Talk.LIE_LABEL[k]), _show_lie_where.bind(k, ""))
	_option("Ach, nichts.", _show_main)


func _show_lie_who(kind: String) -> void:
	_clear()
	_say("Wer?")
	for other in Game.social.talk.opinion_names(guest, 6):
		_option(other.display_name, _show_lie_where.bind(kind, other.id) if kind == "corpse" else _lie.bind(kind, other.id, ""))
	_option("Ach, nichts.", _show_main)


## Vier Orte zur Auswahl – einer davon ist, wo er gerade selbst steht (das fliegt sofort auf).
func _show_lie_where(kind: String, who: String) -> void:
	_clear()
	_say("Wo?")
	var zones: Array[String] = []
	var here := Game.director.zone_name_at(guest.global_position)
	if here != "":
		zones.append(here)
	for i in 12:
		var z := Game.social.random_zone_name()
		if z != "" and not z in zones:
			zones.append(z)
		if zones.size() >= 4:
			break
	zones.shuffle()
	for z in zones:
		_option("… bei %s" % z, _lie.bind(kind, who, z))
	_option("Ach, nichts.", _show_main)


func _lie(kind: String, who: String, zone: String) -> void:
	_say(Game.social.talk.tell(guest, {"kind": kind, "zone": zone, "who": who}, true))
	_show_main()


## „Sag mal …“: Fragen an ihn.
func _show_ask() -> void:
	_clear()
	_say("Hm?")
	_option("Was hältst du von …?", _show_opinions)
	_option("Was hast du heute noch vor?", func() -> void:
		_say(Game.social.talk.plans(guest))
		_show_ask())
	_option("Was weißt du über Zimmer 13?", func() -> void:
		_say(Game.social.talk.room13(guest))
		_show_ask())
	if Game.contest and Game.contest.stage == DoorContest.Stage.CONTEST:
		_option("Wie gefällt dir meine Tür?", func() -> void:
			_say(Game.social.talk.door_verdict(guest))
			_show_ask())
	_option("Kann ich dir irgendwie helfen?", _offer_help)
	_option("Zurück", _show_main)


func _show_opinions() -> void:
	_clear()
	_say("Von wem?")
	for other in Game.social.talk.opinion_names(guest, 8):
		var o: Guest = other
		_option(o.display_name, func() -> void:
			_say(Game.social.talk.opinion(guest, o))
			_show_opinions())
	_option("Zurück", _show_ask)


## Seine Bitte (Spielkonzept 6.14): annehmen oder ablehnen.
func _show_offer(req: Dictionary) -> void:
	_clear()
	_option("Mach ich.", _accept.bind(req))
	_option("Tut mir leid, gerade nicht.", func() -> void:
		_say(Game.social.requests.decline(guest, req))
		_show_main())


func _accept(req: Dictionary) -> void:
	_say(Game.social.requests.accept(guest, req))
	if req["kind"] == "escort":
		_escort()
		return
	_show_main()


## „Kann ich dir irgendwie helfen?“ – seine Bitte ohne Zufall, wenn er eine hat.
func _offer_help() -> void:
	var requests := Game.social.requests
	if requests.own_request(guest):
		_say("Du hilfst mir doch schon. Eins nach dem anderen.")
		_show_ask()
		return
	var req := requests.offer_for(guest, true)
	if req.is_empty():
		_say("Gerade nicht. Lieb von dir, dass du fragst." if not guest.is_child() else "Nö. Aber danke!")
		_show_ask()
		return
	_say(String(req["ask"]))
	_show_offer(req)


## Zur Bar begleiten (6.14): er kommt mit, bis ihr dort seid.
func _escort() -> void:
	var partner := guest   # close() setzt guest auf null
	close()
	Game.social.requests.start_escort(partner)


## Etwas ausrichten (6.14): der Empfänger antwortet, der Auftraggeber dankt beim nächsten Gespräch.
func _deliver(req: Dictionary) -> void:
	_say(Game.social.requests.deliver(guest, req))
	_show_main()


## „Könntest du …“: Bitten.
func _show_please() -> void:
	_clear()
	_say("Kommt drauf an.")
	var tier := Social.tier(guest)
	_option("… mir Deko geben?", _ask_deco)
	if Game.social.access.can_lend(guest) and Game.player.held == null:   # Konrads Werkzeug (Spielkonzept 6.19)
		_option("… mir dein Werkzeug leihen?", func() -> void:
			_say(Game.social.access.lend(guest))
			_show_please())
	if tier >= Social.Tier.NICE and not Game.social.party_active:
		_option("Wollen wir zusammen …", _show_together)
	if guest.is_following():
		_option("Du kannst gehen", _dismiss)
	elif tier >= Social.Tier.FRIEND:
		_option("… mitkommen?", _follow)
	if Game.director.first_attack_done and not guest.is_child():
		_option("… heute in deinem Zimmer bleiben?", _stay_in)
	_option("Zurück", _show_main)


## Bitte (6.9): Er bleibt einen halben Tag vorsichtig und geht gleich heim – Skeptiker nur, wenn sie dich mögen.
func _stay_in() -> void:
	if Talk.temper(guest) == "Skeptiker" and Social.tier(guest) < Social.Tier.FRIEND and guest.fear < 30.0:
		_say("Warum? Weil du Angst hast? Nein, danke.")
		_show_please()
		return
	if Social.tier(guest) < Social.Tier.NICE and guest.fear < 30.0:
		_say("Ich geh, wohin ich will.")
		_show_please()
		return
	guest.clear_stance("careless")
	guest.set_stance("wary", Talk.STANCE_TIME * 0.5)
	Game.social.talk.friendly(guest, 2.0)
	_say("Na gut. Ich geh heim und schließ ab.")
	var partner := guest   # geht los, sobald das Gespräch vorbei ist
	get_tree().create_timer(1.0, false).timeout.connect(func() -> void:
		if is_instance_valid(partner) and partner.state != Guest.State.TALKING:
			partner.go_home())
	_show_main()


## Frage des Gastes (6.9): eine Antwort wählen, er reagiert, dann das Menü.
func _show_question() -> void:
	_clear()
	for a in _question["answers"]:
		_option(String(a[1]), _answer.bind(String(a[0])))


func _answer(key: String) -> void:
	var result: Dictionary = Game.social.talk.answer(guest, _question, key)
	_question = {}
	_say(String(result["line"]))
	if result["after"] == "follow":   # Heimbringen: er kommt mit
		var partner := guest
		close()
		partner.start_follow(120.0)
		return
	_show_main()


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
	_option("Zurück", _show_please)


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
		_option(label, _buy.bind(kind), Game.money < price or not player.can_take(kind))
	if player.held and player.held.kind != Item.Kind.KEY:
		_option("%s verkaufen – %d Geld" % [player.held.display_name, _buy_price(player.held)], _sell.bind(player.held))
	if not _bag_items(false).is_empty():
		_option("Aus der Tasche verkaufen …", _show_bag.bind(false))
	_option("Zurück", _show_main)


## Tasche des Spielers (Spielkonzept 3.2): ein Fach zum Schenken (gift) oder Verkaufen auswählen.
func _show_bag(gift: bool) -> void:
	_clear()
	_say("Was hast du denn da?")
	for item in _bag_items(gift):
		if gift:
			_option("%s schenken" % item.display_name, _gift.bind(item))
		else:
			_option("%s verkaufen – %d Geld" % [item.display_name, _buy_price(item)], _sell.bind(item))
	_option("Zurück", _show_main if gift else _show_trade)


## Was in der Tasche zum Schenken bzw. Verkaufen taugt
func _bag_items(gift: bool) -> Array[Item]:
	var items: Array[Item] = []
	for item in Game.player.bag:
		if not (gift and item.kind in NO_GIFT):
			items.append(item)
	return items


## Einsatz aushandeln (Spielkonzept 6.10). game: "dice" (Mäxchen), "chess" (Schach) oder "darts"
func _show_stakes(game: String) -> void:
	_game = game
	var match_ui: Node = _match_of(game)
	var reason: String = match_ui.why_not(guest)
	if reason != "":
		_say(reason)
		_show_main()
		return
	_clear()
	_say(guest.line("only_fun") if guest.is_child() else "Um was spielen wir?")
	if game == "chess" and Game.social.has_watched_chess(guest):
		_name.text = "%s – %s (du hast zugesehen)" % [guest.display_name, ChessMatch.strength_text(guest)]
	elif game == "darts" and Game.social.has_watched_darts(guest):
		_name.text = "%s – %s (du hast zugesehen)" % [guest.display_name, DartMatch.strength_text(guest)]
	_option("Nur zum Spaß", _play.bind(0, false))
	if guest.is_child():   # Kinder spielen nie um Einsätze (6.13)
		_option("Doch nicht", _show_main)
		return
	for amount in [3, 8]:
		_option("Um %d Geld" % amount, _play.bind(amount, false), Game.money < amount)
	if match_ui.can_stake_item(guest):
		_option("Um %s (deine Hand)" % Game.player.held.display_name, _play.bind(0, true))
	_option("Doch nicht", _show_main)


func _match_of(game: String) -> Node:
	return {"chess": Game.chess, "darts": Game.darts}.get(game, Game.dice)


## Satz des Gastes zum Spiel: „dice_yes“, „chess_no“ … – Darts mit Rückfall auf DartMatch.LINES.
func _game_line(game: String, key: String) -> String:
	if game == "darts":
		return DartMatch.line_of(guest, "darts_" + key)
	return guest.line(("chess_" if game == "chess" else "dice_") + key)


func _play(money: int, with_item: bool) -> void:
	var profile: Dictionary = {"chess": ChessMatch.chess_profile(guest), "darts": DartMatch.darts_profile(guest)}.get(_game,
		guest.profile["dice"])
	var likes := bool(profile["likes"])
	var challenged := guest.challenge_time > 0.0 and guest.challenge_game == _game
	if Social.tier(guest) <= Social.Tier.ANGRY and not challenged:
		_say(_game_line(_game, "no"))
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
		_say(_game_line(_game, "no"))
		_show_main()
		return
	guest.challenge_time = 0.0
	var opponent := guest
	opponent.say(_game_line(_game, "yes"))
	close()
	_match_of(_game).start(opponent, {"money": money, "item": with_item})


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


## Geschenk aus der Hand oder aus der Tasche
func _gift(item: Item) -> void:
	if guest.is_child() and item.kind == Item.Kind.COFFEE:
		_say("Kaffee? Den darf ich nicht trinken.")   # Kinder trinken nie Kaffee (6.13, 3.11)
		_show_main()
		return
	Game.social.access.on_gift(guest)   # ein versprochenes Geschenk (6.19)
	var wish := Game.social.requests.on_gift(guest, item)   # darum hat er dich gebeten (6.14) – sein Dank
	var kind := item.kind
	# Kürbis in seiner Lieblingssorte (Spielkonzept 5.8): freut ihn wie etwas, das er mag, und noch ein bisschen mehr
	var is_pumpkin := kind in [Item.Kind.PUMPKIN, Item.Kind.CARVED_PUMPKIN, Item.Kind.ROAST_PUMPKIN]
	var favorite := is_pumpkin and item.variety == guest.favorite_pumpkin()
	# Limo und Tee freuen jedes Kind (6.13, 3.12)
	var liked := kind in (guest.profile["likes"] as Array) or favorite or (guest.is_child() and kind in [Item.Kind.SODA_CAN, Item.Kind.TEA])
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
	if not guest.receive_gift(Game.player.give_away(item)):
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
	if wish != "":
		_say(wish)
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
	else:
		var kind := _best_deco()
		if kind < 0:
			_say("Ich hab gerade selbst nichts übrig.")
		elif not Game.player.can_take(kind):
			_say("Mach erst mal die Hände frei.")
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
	if Game.money < price or not Game.player.can_take(kind):
		return
	Game.money -= price
	guest.money += price
	guest.stock[kind] = int(guest.stock[kind]) - 1
	Game.social.change_relation(guest, 1.0)
	Game.social.add_deed(guest, "gifts_from")
	Game.player.receive_item(guest.stock_item(kind))
	_say("Gute Wahl.")
	_show_trade()


## Verkaufen aus der Hand oder aus der Tasche
func _sell(item: Item) -> void:
	var price := _buy_price(item)
	if guest.money < price:
		_say("So viel Geld hab ich gerade nicht.")
		_show_trade()
		return
	guest.money -= price
	Game.money += price
	if item.deco_strength > 0.0:
		guest.stock[item.kind] = int(guest.stock.get(item.kind, 0)) + 1
	Game.player.consume_item(item)
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
		Item.Kind.MATCHBOX:
			return "Streichholzschachtel"
		Item.Kind.SALT:
			return "Salz"
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
		Item.Kind.DARTS:
			return "Dartpfeile"
		Item.Kind.SWEETS:
			return "Süßigkeiten"
		Item.Kind.SODA_CAN:
			return "Getränkedose"
		Item.Kind.COFFEE:
			return "Tasse Kaffee"
		Item.Kind.TEA:
			return "Tasse Tee"
		Item.Kind.CROWBAR:
			return "Brecheisen"
		Item.Kind.TOOLBOX:
			return "Werkzeugkasten"
	return "Etwas"


func _say(text: String) -> void:
	_text.text = "„%s“" % text


func _clear() -> void:
	for button in _buttons:
		button.queue_free()
	_buttons.clear()
	if _scroll:
		_scroll.scroll_vertical = 0


## Zeilen über zehn (Taste 0) haben keine Ziffer – nur Maus und Mausrad (6.9).
func _option(text: String, callback: Callable, disabled: bool = false) -> void:
	var n := _buttons.size() + 1
	var button := UiKit.flat_option(("%d. %s" % [n % 10, text]) if n <= 10 else "    " + text, callback, disabled)
	_options.add_child(button)
	_buttons.append(button)
