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
##   · Gäste rufen sich gegenseitig an: Freunde erzählen sich Geschichten über jede Entfernung (Gerüchte
##     verbreiten sich schneller), ängstliche Gäste rufen in Panik herum – auch dich. Jedes Klingeln ist Lärm.

# --- Tuning -------------------------------------------------------------------
const RING_INTERVAL := 3.0
const INCOMING_RINGS := 6                  ## so oft klingelt es, bevor der Anrufer aufgibt
const OUTGOING_RINGS := 5
const CALL_COOLDOWN := Vector2(110.0, 240.0)
const AMBIENT_COOLDOWN := Vector2(90.0, 200.0)
const PRANK_TIME := 2.0                    ## wer so schnell wieder auflegt, macht Telefonstreiche
const QUICK_DIAL_MAX := 10                 ## Einträge der Zimmerliste an der Rezeption
const CREEPY_PICKUP := 0.12                ## in einem leeren Zimmer nimmt doch jemand ab
## Gäste rufen sich an: so lange reden sie, nach so vielen Klingeln nimmt der Angerufene frühestens ab. Ein ängstlicher
## Gast (Mut unter PANIC_BRAVE) ab PANIC_FROM Angst ruft in Panik herum – auch nachts, mit kürzerer Pause
## (PANIC_COOLDOWN); der Angerufene bekommt PANIC_FEAR Angst (× (1,2 − Mut)) ab, der Anrufer wird PANIC_CALM ruhiger.
const GUEST_CALL_TIME := Vector2(10.0, 20.0)
const GUEST_ANSWER_RINGS := 2
const PANIC_FROM := 60.0
const PANIC_BRAVE := 0.4
const PANIC_FEAR := 15.0
const PANIC_CALM := 8.0
const PANIC_COOLDOWN := Vector2(20.0, 45.0)

## Sätze am Telefon ({name}, {room}, {where}). Feste Gäste können eigene haben: "phone_<key>"
## in ihren lines (nicht in GuestGenerator.COMMON – das verschöbe die Zufallsfolge).
const LINES := {
	"warn": ["Ich bin's, {name}. Es ist {where}. Bleib, wo du bist.", "{name} hier, Zimmer {room}. Ich hab es gerade gesehen – {where}. Pass auf dich auf."],
	"warn_near": ["{name} hier … es ist bei mir im Flur. {where}. Komm nicht her!", "Es ist direkt vor meiner Tür – {where}! Ich … ich lege jetzt auf."],
	"lie": ["Alles ruhig hier. Ich glaube, es schläft. Komm doch in die Lobby.", "Die Luft ist rein, ich hab extra nachgesehen. Du kannst ruhig rausgehen.", "Hier ist {name}. Am Flurende liegt Deko, die keinem gehört. Beeil dich!"],
	"chat": ["Hallo? Hier ist {name} aus Zimmer {room}. Ich wollte nur mal eine Stimme hören.", "{name} hier. Mir ist langweilig. Erzähl mir was."],
	"party": ["{name} hier! Im Partyraum läuft Musik – kommst du rüber?"],
	"answer": ["Ja? Zimmer {room}.", "Hallo? Wer ist da?"],
	"answer_friend": ["Oh, du bist's! Schön, dass du anrufst.", "Hallo, du! Alles in Ordnung bei dir?"],
	"answer_enemy": ["Was willst du?", "Ach, du. Mach's kurz."],
	"answer_panic": ["Nicht jetzt! Es ist irgendwo hier!", "Pssst! Ruf nicht an, es hört das!"],
	"no_news": ["Ich habe nichts gesehen. Zum Glück.", "Nein. Und ich will auch nichts sehen."],
	"prank": ["Hallo? … Hallo?! Sehr witzig.", "Wer ist da? … Idiot."],
	"prank_again": ["Hör auf, hier anzurufen! Ich weiß, dass du das bist!", "Noch einmal, und alle erfahren, was du hier treibst!"],
	"dead": ["Ich bin's … {name}. Warum bist du nicht gekommen? Zimmer {room}. Ich warte.", "Hallo? … Hier ist {name}. Es ist so dunkel hier. Komm mich holen."],
	"reception": ["Rezeption.", "Rezeption, guten Abend."],
	"panic": ["{name} hier … Es ist irgendwo da draußen, ich hör es! Was soll ich denn tun?", "Bitte, du musst mir helfen – ich hab solche Angst! Ist es bei dir auch?"],
	"guest_call": ["*am Telefon* Ich bin's. Na, wie geht's dir?", "*am Telefon* Hallo, du! Hast du kurz Zeit?"],
	"guest_answer": ["*nimmt ab* Ja? … Ach, du bist's!", "*nimmt ab* Hallo? Schön, dass du anrufst."],
	"panic_call": ["*am Telefon* Hast du das gehört?! Es ist hier irgendwo! Schließ deine Tür ab!", "*am Telefon* Ich halt das nicht aus … Ist es bei dir auch? Sag doch was!"],
	"panic_answer": ["Was? Wo?! … Ich mach die Tür zu.", "Hör auf, du machst mir Angst!"],
}

var ui: PhoneUI
var home_phone: HotelPhone                 ## das Telefon in Zimmer 13

var _phones := {}                          ## Raum-ID (Zimmernummer, "0" = Rezeption) → HotelPhone
var _incoming: Dictionary = {}             ## {kind, guest, room, variant, rings, next}
var _outgoing: Dictionary = {}             ## {phone, guest, rings, next, answer_at, creepy}
var _ambient: Dictionary = {}              ## Gast ruft Gast an: {phone, caller, target, panic, rings, max, next}
var _talk: Dictionary = {}                 ## {guest, since, chose}
var _pranks := {}                          ## Gast-ID → Anzahl Telefonstreiche
var _active_phone: HotelPhone              ## Hörer in der Hand des Spielers
var _call_id := 0                          ## verhindert, dass alte Zeitgeber in ein neues Gespräch funken
var _call_cooldown := 90.0
var _ambient_cooldown := 60.0
var _time := 0.0


func _ready() -> void:
	add_to_group("time_skip")   # Zeitsprung im Schlaf (SleepSkip)


## Zeitsprung im Schlaf (SleepSkip, Spielkonzept 3.6): Pausen zwischen Anrufen laufen ab.
func skip_time(dt: float) -> void:
	_call_cooldown -= dt
	_ambient_cooldown -= dt


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
	var panicked: Array = []
	for guest in Game.social.living_guests():
		var g: Guest = guest
		if g.hiding or g.state in [Guest.State.KNOCK, Guest.State.SHELTER, Guest.State.TALKING, Guest.State.MINIGAME]:
			continue
		if _panicky(g) and _at_home(g) and Social.tier(g) >= Social.Tier.NEUTRAL:
			panicked.append(g)   # ruft in Panik herum – auch dich
		elif out and Social.tier(g) >= Social.Tier.FRIENDLY:
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
	if not panicked.is_empty():
		choices.append([2.0, "panic", panicked])
	if director.first_attack_done:
		choices.append([0.6 + (2.0 if _grieving() else 0.0), "creepy", []])
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
	if not dead.is_empty() and (_grieving() or randf() < 0.3):
		var ghost: Guest = dead[randi() % dead.size()]
		return {"kind": "creepy", "variant": "dead", "guest": ghost, "room": ghost.home["no"]}
	return {"kind": "creepy", "variant": "breath", "room": _empty_room()}


## Trauer oder Halluzinationen: Dann ruft öfter … etwas anderes an.
func _grieving() -> bool:
	return Game.director.grief > 0.0 or Game.director.is_hallucinating()


## Ein Zimmer, in dem niemand wohnt – am liebsten das abgeschlossene Zimmer 018.
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
		"panic":
			if Game.tracing:
				print("[Telefon] Panikanruf von %s" % guest.display_name)
			ui.show_page("%s – %s" % [title, guest.display_name], "„%s“" % _line(guest, "panic"), [
				["Beruhig dich. Schließ ab und bleib, wo du bist.", func() -> void:
					guest.fear = maxf(0.0, guest.fear - 25.0)
					if not guest.stoked_recently():   # selbst geschürt: keine Beziehung (6.18, 5)
						Game.social.talk.friendly(guest, 1.5)   # am Telefon halb so viel wie Trösten (6.9)
					hang_up()],
				["Auflegen", hang_up],
			])
		"lie":
			ui.show_page("%s – %s" % [title, guest.display_name], "„%s“" % _line(guest, "lie"), [
				["Danke.", hang_up],
				["Auflegen", hang_up],
			])
		"chat":
			var key := "party" if Game.social.party_active else "chat"
			_talk = {"guest": guest, "since": _time, "chose": true}
			_show_talk(guest, "„%s“" % _line(guest, key))
			if key == "party" and Game.notebook:   # ein Termin (Notizbuch, 3.10)
				Game.notebook.add_note("", "Feier im Partyraum – ich soll rüberkommen.", _caller(guest))
		"creepy":
			_take_creepy(call, title)
		"kid_prank":
			ui.show_page(title, "*Kichern* … „Saures!“ … *klick*", [["Auflegen", hang_up]])
		"decorate":
			ui.show_page("%s – %s" % [title, guest.display_name],
				"„%s hier! Wir schmücken gerade %s – bring Deko mit und komm dazu!“" % [guest.display_name, call["where"]], [
				["Ich komme!", func() -> void:
					Game.social.decorating.on_accepted()
					if Game.notebook:
						Game.notebook.add_note("", "Sie schmücken gerade %s – ich soll mit Deko kommen." % call["where"], _caller(guest))
					hang_up()],
				["Keine Zeit.", hang_up],
			])


## Wo es ist – laut einem Gast. Nicht jeder erinnert sich richtig (4.13).
func _monster_where(guest: Guest) -> String:
	var zone := Game.director.zone_name_at(Game.monster.global_position)
	if zone == "" or randf() > float(guest.profile.get("reliable", 0.7)):
		zone = Game.social.random_zone_name()
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
				ui.set_text("„%s“" % _line(ghost, "dead"))
				if Game.notebook:
					Game.notebook.add_note("", "Anruf aus Zimmer %s. Es war %s. Aber %s ist tot." % [room, ghost.display_name,
						ghost.display_name], "Telefon"))
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


## Quelle einer Notiz aus einem Anruf: „Edna, Zi. 021 am Telefon“.
func _caller(guest: Guest) -> String:
	return "%s, Zi. %s am Telefon" % [guest.display_name, String(guest.home["sign"])]


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
	_end_call()
	if _active_phone:
		_show_dial(_active_phone)


## Wer nimmt in diesem Zimmer ab? Ein Gast, der zu Hause ist und nicht im Schrank sitzt – lieber ein Erwachsener
## als ein Kind (Haushalte, Spielkonzept 6.20).
func _guest_at(phone: HotelPhone) -> Guest:
	var kid: Guest = null
	for guest in Game.social.living_guests():
		var g: Guest = guest
		if g.home["no"] != phone.room_id or g.hiding:
			continue
		if g.state in [Guest.State.KNOCK, Guest.State.SHELTER, Guest.State.PARTY, Guest.State.MINIGAME, Guest.State.TALKING]:
			continue
		var center: Vector3 = g.home["center"]
		if g.global_position.distance_to(center) < 3.5:
			if not g.is_child():
				return g
			kid = g
	return kid


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
	_talk = {"guest": guest, "since": _time, "chose": false, "steps": 0}
	if key == "answer_panic":
		# keine Zeit zum Reden – er legt selbst auf
		ui.show_page(_talk_title(guest), "„%s“" % _line(guest, key), [["Auflegen", hang_up]])
		_talk["chose"] = true
		return
	if not Game.social.talk.start_talk(guest):   # Gesprächsbereitschaft (6.18, 5): heute schon genug geredet
		ui.show_page(_talk_title(guest), "„%s“ *legt auf*" % Talk.BUSY_LINES.pick_random(), [["Auflegen", hang_up]])
		_talk["chose"] = true
		return
	_show_talk(guest, "„%s“" % _line(guest, key))


func _talk_title(guest: Guest) -> String:
	return "Zimmer %s – %s (%s)" % [guest.home["no"], guest.display_name, Social.relation_word(guest.relation)]


## Gespräch am Telefon: weniger als von Angesicht zu Angesicht (Beziehung halb so stark),
## aber dafür muss niemand in den dunklen Flur.
func _show_talk(guest: Guest, text: String) -> void:
	if Talk.cuts_short(guest, int(_talk.get("steps", 0))):   # Verärgerte brechen früh ab (6.18, 5)
		ui.show_page(_talk_title(guest), "%s „%s“ *legt auf*" % [text, Talk.BUSY_LINES.pick_random()], [["Auflegen", hang_up]])
		return
	_talk["steps"] = int(_talk.get("steps", 0)) + 1
	var options: Array = [["Plaudern", _phone_chat.bind(guest)]]
	if Game.director.first_attack_done:
		options.append(["Hast du es gesehen?", _phone_ask.bind(guest)])
	if Game.social.party_active:
		if guest.state != Guest.State.PARTY:
			options.append(["Komm zur Feier in den Partyraum!", _phone_party.bind(guest)])
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
	Game.social.talk.friendly(guest, 3.0)   # mit dem Plaudern von Angesicht in einem Budget (6.18, 5)
	_show_talk(guest, "„%s“" % guest.line("smalltalk"))


func _phone_ask(guest: Guest) -> void:
	_talk["chose"] = true
	var report := Game.social.report_line(guest)
	Game.social.on_monster_talk(guest)
	_show_talk(guest, "„%s“" % (report if report != "" else _line(guest, "no_news")))


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
		guest.join_party(Game.social.free_party_spot(guest))
		ui.show_page(_talk_title(guest), "„%s“" % guest.line("party_yes"), [["Auflegen", hang_up]])
	else:
		_show_talk(guest, "„%s“" % guest.line("party_no"))


## Leeres Zimmer – und doch nimmt jemand ab.
func _creepy_pickup(target: HotelPhone) -> void:
	var id := _call_id
	var text := "„%s“" % (LINES["reception"] as Array).pick_random() if target.is_main() else "[Jemand nimmt ab.]"
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
	_end_call()
	if _active_phone:
		Game.noise("handset", _active_phone.global_position, Game.player)
	_active_phone = null
	ui.close()


## Gespräch bzw. Klingeln beim Angerufenen beenden; alte Zeitgeber (_after) feuern danach nicht mehr.
func _end_call() -> void:
	if not _outgoing.is_empty():
		(_outgoing["phone"] as HotelPhone).ringing = false
	_outgoing = {}
	_talk = {}
	_call_id += 1


## Den Hörer neben den Apparat legen: still – aber auch keine Warnungen mehr.
func leave_off_hook() -> void:
	var phone := _active_phone
	_end_call()
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
	Game.say("Du hörst noch, wie %s schimpft: „%s“" % [guest.display_name, _line(guest, "prank_again" if count >= 2 else "prank")], 4.0)


# --- Gäste rufen sich an -------------------------------------------------------------------

## Irgendwo im Hotel klingelt es – ein Gast ruft einen anderen an (4.14). Auch das hört das Monster.
func _update_ambient(delta: float) -> void:
	if not _ambient.is_empty():
		_guest_call_step(delta)
		return
	_ambient_cooldown -= delta
	if _ambient_cooldown > 0.0:
		return
	var call := _pick_guest_call()
	var panic: bool = call.get("panic", false)
	_ambient_cooldown = randf_range(PANIC_COOLDOWN.x, PANIC_COOLDOWN.y) if panic else randf_range(AMBIENT_COOLDOWN.x, AMBIENT_COOLDOWN.y)
	if not call.is_empty():
		_start_guest_call(call["caller"], call["target"], panic)


## Wer ruft wen an? Lieber ein ängstlicher Gast in Panik, sonst (nicht in der Nachtruhe) irgendein Erwachsener, der
## daheim ist – angerufen wird ein Freund (6.16), in Panik zur Not ein Nachbar. {} = gerade keiner.
func _pick_guest_call() -> Dictionary:
	var panicked: Array[Guest] = []
	var callers: Array[Guest] = []
	for g: Guest in Game.social.living_guests():
		if g.is_child() or g.hiding or g.is_asleep() or not g.state in [Guest.State.IDLE, Guest.State.WALK] or not _at_home(g):
			continue
		var phone: HotelPhone = _phones.get(String(g.home["no"]))
		if phone == null or phone == home_phone or phone.off_hook:
			continue
		if _panicky(g):
			panicked.append(g)
		elif not Game.social.sleep_active:
			callers.append(g)
	panicked.shuffle()
	callers.shuffle()
	for caller in panicked:
		var target := _call_target(caller, true)
		if target:
			return {"caller": caller, "target": target, "panic": true}
	for caller in callers:
		var target := _call_target(caller, false)
		if target:
			return {"caller": caller, "target": target, "panic": false}
	return {}


## Ein Freund mit Telefon in einem anderen Zimmer – lieber einer, der daheim und wach ist; in Panik (panic) zur Not der
## nächste Nachbar auf demselben Stockwerk, der abnimmt. null = keiner.
func _call_target(caller: Guest, panic: bool) -> Guest:
	var best: Guest = null
	var fallback: Guest = null
	var pals := Game.social.pals.pals_of(caller)
	for g: Guest in Game.social.living_guests():
		if g == caller or g.home["no"] == caller.home["no"]:
			continue
		var phone: HotelPhone = _phones.get(String(g.home["no"]))
		if phone == null or phone == home_phone or phone.off_hook or phone.ringing:
			continue
		if not g in pals:
			if panic and absf(g.global_position.y - caller.global_position.y) < 2.5 and _answers(g) and (fallback == null \
					or g.global_position.distance_to(caller.global_position) < fallback.global_position.distance_to(caller.global_position)):
				fallback = g
			continue
		if best == null or (_answers(g) and not _answers(best)):
			best = g
	return best if best else fallback


func _start_guest_call(caller: Guest, target: Guest, panic: bool) -> void:
	var rings := randi_range(3, 5)
	_ambient = {"phone": _phones[String(target.home["no"])], "caller": caller, "target": target, "panic": panic,
		"rings": 0, "max": rings, "next": randf_range(0.5, 1.5)}
	caller.wait_awake(RING_INTERVAL * (rings + 1))   # wählt und wartet am Hörer


func _guest_call_step(delta: float) -> void:
	var phone: HotelPhone = _ambient["phone"]
	_ambient["next"] = float(_ambient["next"]) - delta
	if float(_ambient["next"]) > 0.0:
		return
	var caller = _ambient["caller"]   # untypisiert: nach dem Laden kann der Gast neu erzeugt worden sein
	var target = _ambient["target"]
	var panic: bool = _ambient["panic"]
	if not is_instance_valid(caller) or caller.dead or caller.hiding or phone.off_hook \
			or int(_ambient["rings"]) >= int(_ambient["max"]):
		phone.ringing = false
		_ambient = {}
		return
	if int(_ambient["rings"]) >= GUEST_ANSWER_RINGS and is_instance_valid(target) and _answers(target):
		phone.ringing = false
		_ambient = {}
		_guest_call(caller, target, panic)
		return
	_ambient["rings"] = int(_ambient["rings"]) + 1
	_ambient["next"] = RING_INTERVAL
	_ring(phone)


## Das Gespräch: Beide bleiben am Hörer stehen. Freunde erzählen sich eine Geschichte weiter (Talk.phone_spread),
## in Panik steckt die Angst den anderen an.
func _guest_call(caller: Guest, target: Guest, panic: bool) -> void:
	var time := randf_range(GUEST_CALL_TIME.x, GUEST_CALL_TIME.y)
	caller.wait_awake(time)
	target.wait_awake(time)
	target.say(_line(target, "guest_answer"))
	if panic:
		target.fear = minf(100.0, target.fear + PANIC_FEAR * (1.2 - float(target.profile["brave"])))
		caller.fear = maxf(0.0, caller.fear - PANIC_CALM)
	var told := Game.social.talk.phone_spread(caller, target)
	if not told:
		caller.say(_line(caller, "panic_call" if panic else "guest_call"))
	if panic:
		get_tree().create_timer(3.0, false).timeout.connect(func() -> void:
			if is_instance_valid(target) and not target.dead:
				target.say(_line(target, "panic_answer")))
	if Game.tracing:
		print("[Telefon] %s ruft %s an%s%s" % [caller.display_name, target.display_name, " (Panik)" if panic else "",
			", erzählt weiter" if told else ""])


## Nimmt er ab? Daheim, wach, nicht versteckt und nicht beschäftigt.
func _answers(g: Guest) -> bool:
	return not g.dead and g.hiding == null and not g.is_asleep() and _at_home(g) \
		and g.state in [Guest.State.IDLE, Guest.State.WALK, Guest.State.PARTY]


## In seinem Zimmer (mit Bad), wo das Telefon steht.
func _at_home(g: Guest) -> bool:
	return Game.social.builder.home_room_at(g.global_position) == String(g.home["no"])


## Ängstlich und in Angst: ruft in Panik herum.
func _panicky(g: Guest) -> bool:
	return not g.is_child() and g.fear >= PANIC_FROM and float(g.profile["brave"]) < PANIC_BRAVE


# --- Hilfen -----------------------------------------------------------------------------

## Satz am Telefon: eigener Satz des Gastes ("phone_<key>") oder aus LINES.
func _line(guest: Guest, key: String, extra: Dictionary = {}) -> String:
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


## Klingelstreich eines Kindes (Süßes oder Saures, Spielkonzept 6.13): Zimmer 13 klingelt, am anderen Ende
## kichert es nur. false, wenn das Telefon gerade nicht klingeln kann.
func kid_prank(guest: Guest) -> bool:
	if home_phone == null or home_phone.off_hook or is_busy():
		return false
	start_incoming({"kind": "kid_prank", "guest": guest, "room": guest.home["no"]})
	return true


## Einladung zur Schmück-Aktion (Spielkonzept 5.9): where wie „den Südflur (Ostflügel)“. false, wenn das Telefon
## gerade nicht klingeln kann – dann kommt die Einladung als Meldung.
func decorate_call(guest: Guest, where: String) -> bool:
	if home_phone == null or home_phone.off_hook or is_busy() or not _incoming.is_empty():
		return false
	start_incoming({"kind": "decorate", "guest": guest, "room": guest.home["no"], "where": where})
	return true


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
			var guest := Game.social.find_guest(who.get_slice(",", 0))
			if guest == null:
				push_warning("--call: unbekannter Gast %s" % who)
				return
			var kind := "chat"
			if who.ends_with(",panik"):   # ruft in Panik an (Angst 80)
				guest.fear = 80.0
				kind = "panic"
			elif Game.monster.is_active():
				kind = "lie" if Social.tier(guest) <= Social.Tier.ANGRY else "warn"
			start_incoming({"kind": kind, "guest": guest, "room": guest.home["no"]})


## Debug (--gastanruf=id[,panik]): Dieser Gast steht daheim, kennt eine frische Geschichte (Geist gesehen) und ruft
## gleich einen Freund an (ohne Freund wird der nächste Gast mit Telefon einer), der auch daheim steht · panik: in Panik
## (Angst 80).
func debug_guest_call(args: PackedStringArray) -> void:
	var caller := Game.social.find_guest(args[0])
	if caller == null:
		push_warning("--gastanruf: unbekannter Gast %s" % args[0])
		return
	var panic := args.size() > 1 and args[1] == "panik"
	caller.global_position = caller.home["center"]
	caller.wait_awake(5.0)
	if panic:
		caller.fear = 80.0
	var target := _call_target(caller, panic)
	if target == null or not Game.social.pals.are_pals(caller, target):   # ohne Freund: der nächste Gast mit Telefon wird einer
		for g: Guest in Game.social.living_guests():
			if not g.is_child() and g.home["no"] != caller.home["no"] and _phones.has(String(g.home["no"])) and (target == null 					or g.home["center"].distance_to(caller.home["center"]) < target.home["center"].distance_to(caller.home["center"])):
				target = g
		if target:
			Game.social.pals.note(caller, target, GuestPals.PAL_DEEDS)
	if target == null:
		push_warning("--gastanruf: %s hat niemanden zum Anrufen" % caller.display_name)
		return
	target.global_position = target.home["center"]
	target.wait_awake(20.0)
	var talk := Game.social.talk
	talk._remember(caller, talk._claim("ghost", {"zone": Game.social.random_zone_name(), "from": caller.id, "src": -1 - randi() % 100000}))
	caller.profile = caller.profile.duplicate()
	caller.profile["gossip"] = 1.0   # erzählt es sicher weiter
	_ambient = {}
	_start_guest_call(caller, target, panic)
	if Game.tracing:
		print("[Telefon] Debug: %s ruft %s an (Zimmer %s → %s)" % [caller.display_name, target.display_name, caller.home["no"], target.home["no"]])


## Debug (--dial=n): vom Telefon in Zimmer 13 aus wählen. "lobby": Wählseite am Haupttelefon.
func debug_dial(number: String) -> void:
	if number == "lobby":
		open_dial(_phones["0"])
		return
	open_dial(home_phone)
	dial(number)
