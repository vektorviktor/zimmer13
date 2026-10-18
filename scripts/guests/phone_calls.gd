class_name PhoneCalls
extends Node
## Zimmertelefone (Spielkonzept 4.14): verbindet das Klopfen (4.13), das Ablenken des Monsters
## (4.11) und die Beziehungen zu den Gästen (6.2).
##   · Anrufe bekommen (nur Zimmer 13): Freunde warnen, Feinde lügen, Bekannte plaudern oder
##     laden ein – und manchmal atmet nur jemand. Danach liegt irgendwo ein Hörer daneben.
##   · Selbst anrufen: Zimmernummer wählen (0 = Rezeption). Klingeln ist Lärm im Zielzimmer.
##     Wer anruft und sofort auflegt, macht Telefonstreiche – das spricht sich herum.
##   · Der Preis: Auch das eigene Telefon klingelt laut. Hörer daneben legen macht still,
##     aber dann erreicht einen auch keine Warnung.
##   · Ab und zu klingelt irgendwo im Hotel ein Telefon (Gäste rufen sich an).

# --- Tuning -------------------------------------------------------------------
const RING_INTERVAL := 3.0
const INCOMING_RINGS := 6                  ## so oft klingelt es, bevor der Anrufer aufgibt
const OUTGOING_RINGS := 5
const CALL_COOLDOWN := Vector2(110.0, 240.0)
const AMBIENT_COOLDOWN := Vector2(90.0, 200.0)
const PRANK_TIME := 2.0                    ## wer so schnell wieder auflegt, macht Telefonstreiche
const QUICK_DIAL_MAX := 10                 ## Einträge der Zimmerliste an der Rezeption
const CREEPY_PICKUP := 0.12                ## in einem leeren Zimmer nimmt doch jemand ab

## Sätze am Telefon ({name}, {room}, {where}). Feste Gäste können eigene haben: "phone_<key>"
## in ihren lines (nicht in GuestGenerator.COMMON – das verschöbe die Zufallsfolge).
const LINES := {
	"warn": ["Ich bin's, {name}. Es ist {where}. Bleib, wo du bist.", "{name} hier, Zimmer {room}. Ich hab es gerade gesehen – {where}. Pass auf dich auf."],
	"warn_near": ["{name} hier … es ist bei mir im Flur. {where}. Komm nicht her!", "Es ist direkt vor meiner Tür – {where}! Ich … ich lege jetzt auf."],
	"lie": ["Alles ruhig hier. Ich glaube, es schläft. Komm doch in die Lobby.", "Die Luft ist rein, ich hab extra nachgesehen. Du kannst ruhig rausgehen.", "Hier ist {name}. Am Flurende liegt Deko, die keinem gehört. Beeil dich!"],
	"chat": ["Hallo? Hier ist {name} aus Zimmer {room}. Ich wollte nur mal eine Stimme hören.", "{name} hier. Mir ist langweilig. Erzähl mir was."],
	"party": ["{name} hier! In der Lobby läuft Musik – kommst du rüber?"],
	"answer": ["Ja? Zimmer {room}.", "Hallo? Wer ist da?"],
	"answer_friend": ["Oh, du bist's! Schön, dass du anrufst.", "Hallo, du! Alles in Ordnung bei dir?"],
	"answer_enemy": ["Was willst du?", "Ach, du. Mach's kurz."],
	"answer_panic": ["Nicht jetzt! Es ist irgendwo hier!", "Pssst! Ruf nicht an, es hört das!"],
	"no_news": ["Ich habe nichts gesehen. Zum Glück.", "Nein. Und ich will auch nichts sehen."],
	"prank": ["Hallo? … Hallo?! Sehr witzig.", "Wer ist da? … Idiot."],
	"prank_again": ["Hör auf, hier anzurufen! Ich weiß, dass du das bist!", "Noch einmal, und alle erfahren, was du hier treibst!"],
	"dead": ["Ich bin's … {name}. Warum bist du nicht gekommen? Zimmer {room}. Ich warte.", "Hallo? … Hier ist {name}. Es ist so dunkel hier. Komm mich holen."],
	"reception": ["Rezeption.", "Rezeption, guten Abend."],
}

var ui: PhoneUI
var home_phone: HotelPhone                 ## das Telefon in Zimmer 13

var _phones := {}                          ## Raum-ID (Zimmernummer, "0" = Rezeption) → HotelPhone
var _incoming: Dictionary = {}             ## {kind, guest, room, variant, rings, next}
var _outgoing: Dictionary = {}             ## {phone, guest, rings, next, answer_at, creepy}
var _ambient: Dictionary = {}              ## {phone, rings, max, next}
var _talk: Dictionary = {}                 ## {guest, since, chose}
var _pranks := {}                          ## Gast-ID → Anzahl Telefonstreiche
var _active_phone: HotelPhone              ## Hörer in der Hand des Spielers
var _call_id := 0                          ## verhindert, dass alte Zeitgeber in ein neues Gespräch funken
var _call_cooldown := 90.0
var _ambient_cooldown := 60.0
var _time := 0.0


func setup() -> void:
	for node in get_tree().get_nodes_in_group("phones"):
		var phone := node as HotelPhone
		_phones["0" if phone.is_main() else phone.room_id] = phone
	home_phone = _phones.get(LevelBuilder.PLAYER_ROOM)
	ui = PhoneUI.new()
	ui.name = "PhoneUI"
	add_child(ui)


func is_busy() -> bool:
	return ui != null and ui.visible


func _process(delta: float) -> void:
	_time += delta
	if Game.game_over:
		return
	_update_incoming(delta)
	_update_outgoing(delta)
	_update_ambient(delta)


# --- Klingeln ---------------------------------------------------------------------------

## Ein Klingeln: laut, wenn man in der Nähe ist – und Lärm im ganzen Umkreis (4.14, 4.15).
func _ring(phone: HotelPhone) -> void:
	phone.ringing = true
	var volume := Game.noise("phone", phone.global_position)
	if volume >= 0.15:
		Game.caption("[Dein Telefon klingelt]" if phone == home_phone else "[Ein Telefon klingelt]")
	# Wer sich im Zimmer versteckt, zuckt zusammen
	for guest in Game.social.living_guests():
		var g: Guest = guest
		if g.hiding and g.home["no"] == phone.room_id:
			g.fear = minf(100.0, g.fear + 8.0)


# --- Anrufe für Zimmer 13 -----------------------------------------------------------------

func _update_incoming(delta: float) -> void:
	if not _incoming.is_empty():
		_incoming_step(delta)
		return
	_call_cooldown -= delta
	if _call_cooldown > 0.0:
		return
	_call_cooldown = 10.0   # später noch einmal versuchen
	var p := Game.player
	if p == null or p.dead or home_phone == null or home_phone.off_hook or is_busy():
		return
	if p.global_position.distance_to(home_phone.global_position) > Senses.range_of("phone") \
			or absf(p.global_position.y - home_phone.global_position.y) > 2.5:
		return
	if Game.social.is_knocking():
		return
	var call := _pick_incoming()
	if call.is_empty():
		return
	_call_cooldown = randf_range(CALL_COOLDOWN.x, CALL_COOLDOWN.y)
	start_incoming(call)


func start_incoming(call: Dictionary) -> void:
	_incoming = call
	_incoming["rings"] = 0
	_incoming["next"] = 0.0


## Wer ruft an? Freunde warnen, Feinde lügen (beides nur, wenn es unterwegs ist), Bekannte
## plaudern in ruhigen Zeiten. Nach dem ersten Angriff ruft manchmal … etwas anderes an.
func _pick_incoming() -> Dictionary:
	var director := Game.director
	var out := Game.monster.is_active()
	var warners: Array = []
	var liars: Array = []
	var chatters: Array = []
	for guest in Game.social.living_guests():
		var g: Guest = guest
		if g.hiding or g.state in [Guest.State.KNOCK, Guest.State.SHELTER, Guest.State.TALKING, Guest.State.MINIGAME]:
			continue
		if out and Social.tier(g) >= Social.Tier.FRIENDLY:
			warners.append(g)
		elif out and Social.tier(g) <= Social.Tier.ANGRY:
			liars.append(g)
		elif not out and Social.tier(g) >= Social.Tier.NICE:
			chatters.append(g)
	var choices: Array = []   # [Gewicht, Art, Kandidaten]
	if not warners.is_empty():
		choices.append([3.0, "warn", warners])
	if not liars.is_empty():
		choices.append([1.0, "lie", liars])
	if not chatters.is_empty():
		choices.append([1.5, "chat", chatters])
	if director.first_attack_done:
		var grieving := director.grief > 0.0 or director.is_hallucinating()
		choices.append([0.6 + (2.0 if grieving else 0.0), "creepy", []])
	if choices.is_empty():
		return {}
	var total := 0.0
	for c in choices:
		total += float(c[0])
	var roll := randf() * total
	for c in choices:
		roll -= float(c[0])
		if roll <= 0.0:
			if c[1] == "creepy":
				return _creepy_call()
			var list: Array = c[2]
			var guest: Guest = list[randi() % list.size()]
			return {"kind": c[1], "guest": guest, "room": guest.home["no"]}
	return {}


## Die unheimliche Variante: Atmen aus einem leeren Zimmer, die Stimme eines Verschwundenen –
## oder es steht gerade vor deiner Tür.
func _creepy_call() -> Dictionary:
	var door_front: Vector3 = Game.director.player_door_front
	if Game.monster.is_active() and Game.monster.global_position.distance_to(door_front) < 6.0:
		return {"kind": "creepy", "variant": "door", "room": LevelBuilder.PLAYER_ROOM}
	var dead: Array = Game.social.guests.filter(func(g: Guest) -> bool: return g.dead)
	var grieving := Game.director.grief > 0.0 or Game.director.is_hallucinating()
	if not dead.is_empty() and (grieving or randf() < 0.3):
		var ghost: Guest = dead[randi() % dead.size()]
		return {"kind": "creepy", "variant": "dead", "guest": ghost, "room": ghost.home["no"]}
	return {"kind": "creepy", "variant": "breath", "room": _empty_room()}


## Ein Zimmer, in dem niemand wohnt – am liebsten das abgeschlossene Zimmer 0118.
func _empty_room() -> String:
	if randf() < 0.35 and _phones.has(LevelBuilder.LOCKED_ROOM):
		return LevelBuilder.LOCKED_ROOM
	var rooms: Array = []
	for no in Game.social.builder.rooms:
		var kind: String = Game.social.builder.rooms[no]["kind"]
		if kind in ["vacant", "abandoned", "derelict", "locked"] and _phones.has(no):
			rooms.append(no)
	return rooms[randi() % rooms.size()] if not rooms.is_empty() else LevelBuilder.LOCKED_ROOM


func _incoming_step(delta: float) -> void:
	var guest: Guest = _incoming.get("guest")
	if home_phone.off_hook or (guest and guest.dead and _incoming["kind"] != "creepy"):
		_end_incoming()
		return
	_incoming["next"] = float(_incoming["next"]) - delta
	if float(_incoming["next"]) > 0.0:
		return
	if int(_incoming["rings"]) >= INCOMING_RINGS:
		# Niemand nimmt ab. Bei der unheimlichen Variante liegt danach trotzdem ein Hörer daneben.
		if _incoming["kind"] == "creepy":
			_leave_receiver(String(_incoming["room"]))
		_end_incoming()
		return
	_incoming["rings"] = int(_incoming["rings"]) + 1
	_incoming["next"] = RING_INTERVAL
	_ring(home_phone)


func _end_incoming() -> void:
	_incoming = {}
	if home_phone:
		home_phone.ringing = false


## Der Spieler nimmt ein klingelndes Telefon ab.
func answer(phone: HotelPhone) -> void:
	phone.ringing = false
	if phone == home_phone and not _incoming.is_empty():
		var call := _incoming
		_incoming = {}
		_take_line(phone)
		_take_incoming(call)
	elif not _ambient.is_empty() and phone == _ambient["phone"]:
		_ambient = {}
		Game.say("Du nimmst ab. Ein Klicken – jemand hat aufgelegt.", 3.0)
	else:
		Game.say("Stille in der Leitung.", 2.5)


func _take_line(phone: HotelPhone) -> void:
	_active_phone = phone
	_call_id += 1
	if _active_phone:
		Game.noise("handset", _active_phone.global_position, Game.player)


func _take_incoming(call: Dictionary) -> void:
	var guest: Guest = call.get("guest")
	var room := String(call.get("room", ""))
	var title := "Zimmer %s" % room if room != "" else "Unbekannt"
	match String(call["kind"]):
		"warn":
			var where := _monster_where(guest)
			var near: bool = Game.monster.global_position.distance_to(guest.home["center"]) < 12.0
			var text := _line(guest, "warn_near" if near else "warn", {"where": where})
			Game.social.on_monster_talk(guest)   # auch am Telefon hört es mit (4.7)
			ui.show_page("%s – %s" % [title, guest.display_name], "„%s“" % text, [
				["Danke!", func() -> void:
					Game.social.change_relation(guest, 3.0)
					hang_up()],
				["Auflegen", hang_up],
			])
		"lie":
			ui.show_page("%s – %s" % [title, guest.display_name], "„%s“" % _line(guest, "lie", {}), [
				["Danke.", hang_up],
				["Auflegen", hang_up],
			])
		"chat":
			var key := "party" if Game.social.party_active else "chat"
			_talk = {"guest": guest, "since": _time, "chose": true}
			_show_talk(guest, "„%s“" % _line(guest, key, {}))
		"creepy":
			_take_creepy(call, title)


## Wo es ist – laut einem Gast. Nicht jeder erinnert sich richtig (4.13).
func _monster_where(guest: Guest) -> String:
	var zone := Game.director.zone_name_at(Game.monster.global_position)
	if zone == "" or randf() > float(guest.profile.get("reliable", 0.7)):
		var names: Array = Game.director.zones.map(func(z: Dictionary) -> String: return z["name"])
		zone = names[randi() % names.size()]
	return where_text(zone)


## „in der Lobby“, „im Nordflügel“, „in Zimmer 13“.
static func where_text(zone: String) -> String:
	if zone.begins_with("Zimmer"):
		return "in " + zone
	if zone == "Kellertreppe":
		return "auf der Kellertreppe"
	if zone in ["Lobby", "Küche", "Bar"]:
		return "in der " + zone
	return "im " + zone


func _take_creepy(call: Dictionary, title: String) -> void:
	var id := _call_id
	var room := String(call["room"])
	match String(call["variant"]):
		"door":
			ui.show_page("Unbekannt", "[Atmen. Ganz nah.]", [["Auflegen", hang_up]])
			_after(id, 3.5, func() -> void:
				ui.set_text("[Atmen. Ganz nah.]\n[Es kommt nicht nur aus dem Hörer.]")
				Game.play_sound("growl", 0.35)
				Game.director.add_curiosity(Game.director.player_door_front, 20.0))
		"dead":
			var ghost: Guest = call["guest"]
			ui.show_page(title, "[Rauschen] …", [["Auflegen", hang_up]])
			_after(id, 2.0, func() -> void:
				ui.set_text("„%s“" % _line(ghost, "dead", {})))
			_after(id, 7.0, func() -> void:
				ui.set_text("[Die Leitung ist tot.]")
				Game.play_sound("sting", 0.4)
				_leave_receiver(room))
		_:
			ui.show_page("Unbekannt", "Hallo? …", [["Auflegen", hang_up]])
			Game.play_sound("gasp", 0.25)
			_after(id, 2.0, func() -> void: ui.set_text("[Atmen]"))
			_after(id, 6.0, func() -> void:
				ui.set_text("[Atmen]\n[Die Leitung ist tot.]")
				_leave_receiver(room))


## Spur der unheimlichen Anrufe: In diesem Zimmer liegt jetzt ein Hörer neben dem Apparat.
func _leave_receiver(room: String) -> void:
	var phone: HotelPhone = _phones.get(room)
	if phone and phone != home_phone:
		phone.set_off_hook(true)


# --- Selbst anrufen -----------------------------------------------------------------------

func open_dial(phone: HotelPhone) -> void:
	if is_busy():
		return
	_take_line(phone)
	_show_dial(phone)


func _show_dial(phone: HotelPhone) -> void:
	var quick: Array = []
	var hint := "Zimmernummer wählen (Zifferntasten) · 0 = Rezeption"
	if phone.is_main():
		hint = "Zimmernummer wählen (Zifferntasten) · Gästeverzeichnis:"
		quick = _directory()
	ui.show_dial("Telefon – %s" % ("Rezeption" if phone.is_main() else "Zimmer " + phone.room_id), hint, quick)


## Das Gästeverzeichnis an der Rezeption: feste Gäste und Bekannte, nach Zimmern sortiert.
func _directory() -> Array:
	var known: Array = Game.social.living_guests().filter(func(g: Guest) -> bool:
		return g.gen_seed < 0 or absf(g.relation) >= 5.0)
	known.sort_custom(func(a: Guest, b: Guest) -> bool: return int(a.home["no"]) < int(b.home["no"]))
	var list: Array = []
	for guest in known.slice(0, QUICK_DIAL_MAX):
		var g: Guest = guest
		list.append(["%s – %s" % [g.home["no"], g.display_name], g.home["no"]])
	return list


func dial(number: String) -> void:
	if _active_phone == null or number == "":
		return
	var own := "0" if _active_phone.is_main() else _active_phone.room_id
	var target: HotelPhone = _phones.get(number)
	var title := "Rezeption" if number == "0" else "Zimmer %s" % number
	if number == own:
		ui.show_page(title, "Besetzt. Natürlich – das ist dein eigener Anschluss.", _retry_options())
	elif target == null:
		ui.show_page(title, "„Kein Anschluss unter dieser Nummer.“", _retry_options())
	elif target.off_hook or target.ringing:
		ui.show_page(title, "Tuut … tuut … tuut. Besetzt.", _retry_options())
	else:
		var guest := _guest_at(target)
		var creepy := guest == null and Game.director.first_attack_done and randf() < CREEPY_PICKUP
		_outgoing = {"phone": target, "guest": guest, "rings": 0, "next": 0.8,
			"answer_at": randi_range(1, 3), "creepy": creepy}
		ui.show_page(title, "Es klingelt …", [["Auflegen", hang_up]])


func _retry_options() -> Array:
	return [["Neu wählen", _dial_again], ["Auflegen", hang_up]]


func _dial_again() -> void:
	_outgoing = {}
	_talk = {}
	_call_id += 1
	if _active_phone:
		_show_dial(_active_phone)


## Wer nimmt in diesem Zimmer ab? Ein Gast, der zu Hause ist und nicht im Schrank sitzt.
func _guest_at(phone: HotelPhone) -> Guest:
	for guest in Game.social.living_guests():
		var g: Guest = guest
		if g.home["no"] != phone.room_id or g.hiding:
			continue
		if g.state in [Guest.State.KNOCK, Guest.State.SHELTER, Guest.State.PARTY, Guest.State.MINIGAME, Guest.State.TALKING]:
			continue
		var center: Vector3 = g.home["center"]
		if g.global_position.distance_to(center) < 3.5:
			return g
	return null


func _update_outgoing(delta: float) -> void:
	if _outgoing.is_empty():
		return
	var target: HotelPhone = _outgoing["phone"]
	_outgoing["next"] = float(_outgoing["next"]) - delta
	if float(_outgoing["next"]) > 0.0:
		return
	var rings := int(_outgoing["rings"])
	var guest: Guest = _outgoing["guest"]
	if guest and (guest.dead or guest.hiding or guest.state == Guest.State.TALKING):
		guest = null
		_outgoing["guest"] = null
	if guest and rings >= int(_outgoing["answer_at"]):
		target.ringing = false
		_outgoing = {}
		_guest_answers(guest)
		return
	if bool(_outgoing["creepy"]) and rings >= 2:
		target.ringing = false
		_outgoing = {}
		_creepy_pickup(target)
		return
	if rings >= OUTGOING_RINGS:
		target.ringing = false
		_outgoing = {}
		ui.show_page(ui.title(), "Niemand nimmt ab.", _retry_options())
		return
	_outgoing["rings"] = rings + 1
	_outgoing["next"] = RING_INTERVAL
	_ring(target)
	ui.set_text("Es klingelt …" + " tuuut".repeat(rings + 1))


func _guest_answers(guest: Guest) -> void:
	var key := "answer"
	if guest.fear >= 60.0:
		key = "answer_panic"
	elif Social.tier(guest) <= Social.Tier.ENEMY:
		key = "answer_enemy"
	elif Social.tier(guest) >= Social.Tier.FRIEND:
		key = "answer_friend"
	_talk = {"guest": guest, "since": _time, "chose": false}
	if key == "answer_panic":
		# keine Zeit zum Reden – er legt selbst auf
		ui.show_page(_talk_title(guest), "„%s“" % _line(guest, key, {}), [["Auflegen", hang_up]])
		_talk["chose"] = true
		return
	_show_talk(guest, "„%s“" % _line(guest, key, {}))


func _talk_title(guest: Guest) -> String:
	return "Zimmer %s – %s (%s)" % [guest.home["no"], guest.display_name, Social.relation_word(guest.relation)]


## Gespräch am Telefon: weniger als von Angesicht zu Angesicht (Beziehung halb so stark),
## aber dafür muss niemand in den dunklen Flur.
func _show_talk(guest: Guest, text: String) -> void:
	var options: Array = [["Plaudern", _phone_chat.bind(guest)]]
	if Game.director.first_attack_done:
		options.append(["Hast du es gesehen?", _phone_ask.bind(guest)])
	if Game.social.party_active:
		if guest.state != Guest.State.PARTY:
			options.append(["Komm zur Feier in die Lobby!", _phone_party.bind(guest)])
	elif not guest.invited:
		options.append(["Zur Feier einladen", _phone_invite.bind(guest)])
	options.append(["Auflegen", hang_up])
	ui.show_page(_talk_title(guest), text, options)


func _phone_chat(guest: Guest) -> void:
	_talk["chose"] = true
	if guest.chat_cooldown > 0.0:
		_show_talk(guest, "„Lass uns später weiterreden.“")
		return
	guest.chat_cooldown = DialogUI.CHAT_COOLDOWN
	Game.social.change_relation(guest, 3.0)
	_show_talk(guest, "„%s“" % guest.line("smalltalk"))


func _phone_ask(guest: Guest) -> void:
	_talk["chose"] = true
	var report := Game.social.report_line(guest)
	Game.social.on_monster_talk(guest)
	_show_talk(guest, "„%s“" % (report if report != "" else _line(guest, "no_news", {})))


func _phone_invite(guest: Guest) -> void:
	_talk["chose"] = true
	if Social.tier(guest) >= Social.Tier.NEUTRAL:
		guest.invited = true
		_show_talk(guest, "„%s“" % guest.line("party_yes"))
	else:
		Game.social.change_relation(guest, -2.0)
		_show_talk(guest, "„%s“" % guest.line("party_no"))


func _phone_party(guest: Guest) -> void:
	_talk["chose"] = true
	if Social.tier(guest) >= Social.Tier.ANNOYED:
		guest.invited = true
		guest.join_party(Game.social.free_party_spot())
		ui.show_page(_talk_title(guest), "„%s“" % guest.line("party_yes"), [["Auflegen", hang_up]])
	else:
		_show_talk(guest, "„%s“" % guest.line("party_no"))


## Leeres Zimmer – und doch nimmt jemand ab.
func _creepy_pickup(target: HotelPhone) -> void:
	var id := _call_id
	var text := "„%s“" % LINES["reception"][randi() % LINES["reception"].size()] if target.is_main() else "[Jemand nimmt ab.]"
	ui.show_page(ui.title(), text, [["Auflegen", hang_up]])
	_after(id, 2.5, func() -> void: ui.set_text(text + "\n[Atmen]"))
	_after(id, 6.0, func() -> void:
		ui.set_text(text + "\n[Atmen]\n[Die Leitung ist tot.]")
		target.set_off_hook(true))


# --- Auflegen ---------------------------------------------------------------------------

func hang_up() -> void:
	if not _talk.is_empty():
		var guest: Guest = _talk["guest"]
		if not bool(_talk["chose"]) and _time - float(_talk["since"]) < PRANK_TIME:
			_prank(guest)
	if not _outgoing.is_empty():
		(_outgoing["phone"] as HotelPhone).ringing = false
	_outgoing = {}
	_talk = {}
	_call_id += 1
	if _active_phone:
		Game.noise("handset", _active_phone.global_position, Game.player)
	_active_phone = null
	ui.close()


## Den Hörer neben den Apparat legen: still – aber auch keine Warnungen mehr.
func leave_off_hook() -> void:
	var phone := _active_phone
	_outgoing = {}
	_talk = {}
	_call_id += 1
	_active_phone = null
	ui.close()
	if phone:
		phone.set_off_hook(true)
		Game.say("Du legst den Hörer neben den Apparat. Jetzt klingelt hier nichts mehr – aber es erreicht dich auch niemand.", 4.5)


## Anrufen und gleich wieder auflegen: Beim zweiten Mal spricht es sich herum.
func _prank(guest: Guest) -> void:
	var count := int(_pranks.get(guest.id, 0)) + 1
	_pranks[guest.id] = count
	Game.social.change_relation(guest, -4.0)
	if count >= 2:
		Game.social.on_insult(guest)
	Game.say("Du hörst noch, wie %s schimpft: „%s“" % [guest.display_name, _line(guest, "prank_again" if count >= 2 else "prank", {})], 4.0)


# --- Ferne Telefone ------------------------------------------------------------------------

## Irgendwo im Hotel klingelt es – Gäste rufen sich an. Auch das hört das Monster.
func _update_ambient(delta: float) -> void:
	if not _ambient.is_empty():
		var phone: HotelPhone = _ambient["phone"]
		_ambient["next"] = float(_ambient["next"]) - delta
		if float(_ambient["next"]) > 0.0:
			return
		if int(_ambient["rings"]) >= int(_ambient["max"]) or phone.off_hook:
			phone.ringing = false
			_ambient = {}
			return
		_ambient["rings"] = int(_ambient["rings"]) + 1
		_ambient["next"] = RING_INTERVAL
		_ring(phone)
		return
	_ambient_cooldown -= delta
	if _ambient_cooldown > 0.0:
		return
	_ambient_cooldown = randf_range(AMBIENT_COOLDOWN.x, AMBIENT_COOLDOWN.y)
	var candidates: Array = []
	for guest in Game.social.living_guests():
		var g: Guest = guest
		var phone: HotelPhone = _phones.get(String(g.home["no"]))
		if phone == null or phone == home_phone or phone.off_hook or phone.ringing:
			continue
		if Game.player and Game.player.global_position.distance_to(phone.global_position) < 8.0:
			continue
		candidates.append(phone)
	if not candidates.is_empty():
		_ambient = {"phone": candidates[randi() % candidates.size()], "rings": 0, "max": randi_range(2, 4), "next": 0.0}


# --- Hilfen -----------------------------------------------------------------------------

## Satz am Telefon: eigener Satz des Gastes ("phone_<key>") oder aus LINES.
func _line(guest: Guest, key: String, extra: Dictionary) -> String:
	var lines: Dictionary = guest.profile.get("lines", {}) if guest else {}
	var pool: Array = lines.get("phone_" + key, LINES.get(key, ["…"]))
	var values := {"name": guest.display_name if guest else "", "room": guest.home["no"] if guest else "", "where": ""}
	values.merge(extra, true)
	return String(pool[randi() % pool.size()]).format(values)


## Zeitgeber, der nur feuert, wenn noch dasselbe Gespräch läuft (pausiert mit dem Spiel).
func _after(id: int, seconds: float, fn: Callable) -> void:
	get_tree().create_timer(seconds, false).timeout.connect(func() -> void:
		if id == _call_id and is_busy():
			fn.call())


## Debug (--call=…): sofort einen Anruf für Zimmer 13 klingeln lassen.
func debug_call(who: String) -> void:
	_end_incoming()
	match who:
		"creepy", "breath":
			start_incoming({"kind": "creepy", "variant": "breath", "room": LevelBuilder.LOCKED_ROOM})
		"dead", "door":
			var call := _creepy_call()
			if who == "door":
				call = {"kind": "creepy", "variant": "door", "room": LevelBuilder.PLAYER_ROOM}
			start_incoming(call)
		_:
			var guest := Game.social.guest_by_id(who)
			if guest == null:
				push_warning("--call: unbekannter Gast %s" % who)
				return
			var kind := "chat"
			if Game.monster.is_active():
				kind = "lie" if Social.tier(guest) <= Social.Tier.ANGRY else "warn"
			start_incoming({"kind": kind, "guest": guest, "room": guest.home["no"]})


## Debug (--dial=n): vom Telefon in Zimmer 13 aus wählen. "lobby": Wählseite am Haupttelefon.
func debug_dial(number: String) -> void:
	if number == "lobby":
		open_dial(_phones["0"])
		return
	open_dial(home_phone)
	dial(number)
