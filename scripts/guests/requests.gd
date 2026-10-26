class_name GuestRequests
extends Node
## Bitten der Gäste (Spielkonzept 6.14, entschieden 2026-10-26): Jeder Gast hat eine Bitte, die zu ihm passt.
##   · Herzensbitte: je Gast eine im ganzen Spiel, ab „freundlich“ (HEART_TIER), aus dem Charakter (Talk.temper) –
##     Kernfiguren mit eigener (CORE). Ohne Frist, außerhalb des Beziehungsbudgets (6.18, 5), weil es sie nur einmal gibt.
##   · Kleine Bitten: selten (SMALL_PER_DAY im ganzen Hotel), höchstens MAX_SMALL zugleich, nach Lage – kahle Tür →
##     Lieblingskürbis (5.8, geschnitzt nur bei schnitzbaren Sorten; er stellt ihn vor seine Tür), abends eine Kerze,
##     morgens Kaffee, Kinder Süßes, sonst etwas, das er mag. Frist: bis zum Ende des Spieltags, zählen zum Budget.
## Arten: item (bringen – erfüllt beim Schenken, DialogUI._gift), escort (zur Bar begleiten), message (einem Freund
## etwas ausrichten – Anlass im Gespräch mit ihm), game (eine Partie – erfüllt am Ende eines Spiels).
## Der Gast fragt von sich aus (offer_for, Chance OFFER_CHANCE) oder auf „Kann ich dir irgendwie helfen?“. Angenommen →
## Notizbuch (3.10); abgelehnt kostet nichts, bei Freunden ein wenig. Kind von Social, erreichbar über
## Game.social.requests. Gespeichert unter social.requests.

## Herzensbitte ab dieser Stufe; so viel Beziehung, wenn sie erfüllt ist (dazu Lob bei seinen Freunden)
const HEART_TIER := Social.Tier.FRIENDLY
const HEART_REWARD := 12.0
const HEART_PRAISE := 3.0
## Kleine Bitten: höchstens so viele am Spieltag im ganzen Hotel, so viele zugleich offen, ab dieser Stufe
const SMALL_PER_DAY := 1
const MAX_SMALL := 3
const SMALL_TIER := Social.Tier.NEUTRAL
const SMALL_REWARD := 6.0
const SMALL_PRAISE := 1.5
## Verpasst (Ende des Spieltags) bzw. abgelehnt als Freund
const MISSED := -2.0
const DECLINED_FRIEND := -1.0
## So oft fragt er von sich aus zu Beginn eines Gesprächs (Herzensbitte, kleine Bitte)
const OFFER_CHANCE := {"heart": 0.6, "small": 0.35}
## Ein Begleiter für die Bitte „zur Bar“ kommt so lange mit (s)
const ESCORT_TIME := 300.0

## Herzensbitten nach Charakter. ask: was er sagt, task: Zeile im Notizbuch, thanks: wenn erfüllt.
## item = Item.Kind, game = "dice"/"chess"/"darts"/"" (egal), money: Lohn in Geld.
const HEART := {
	"Bastler": {"kind": "item", "item": Item.Kind.BULB, "task": "Eine Glühbirne für die Nachttischlampe",
		"ask": "Meine Nachttischlampe ist hinüber, und ich hab keine Ersatzbirne dabei. Wenn du irgendwo eine findest – ich wär dir echt dankbar.",
		"thanks": "Eine Birne! Jetzt kann ich abends wieder basteln. Danke, wirklich."},
	"ängstlich": {"kind": "escort", "task": "Zur Bar begleiten – traut sich nicht allein durch den Flur",
		"ask": "Kannst du mich zur Bar bringen? Allein trau ich mich nicht mehr durch den Flur.",
		"thanks": "Geschafft … Danke, dass du mitgekommen bist. Allein hätte ich umgedreht."},
	"geschäftstüchtig": {"kind": "item", "item": Item.Kind.SKULL, "money": 15, "task": "Einen Totenkopf besorgen – zahlt 15",
		"ask": "Ich such einen Totenkopf. Echte Ware, kein Plastik. Besorg mir einen, und ich zahl dir 15 – Ehrenwort.",
		"thanks": "Na also, das ist Qualität. Hier, 15, wie abgemacht."},
	"Plaudertasche": {"kind": "message", "task": "{target} ausrichten: heute Abend an der Bar, Neuigkeiten",
		"ask": "Tust du mir einen Gefallen? Sag {target}, dass ich heute Abend an der Bar bin – ich hab Neuigkeiten! Aber verrat noch nichts.",
		"say": "{giver} lässt ausrichten: heute Abend an der Bar, Neuigkeiten.",
		"reply": "Neuigkeiten? Von {giver}? Dann komm ich hin – danke!",
		"thanks": "Du hast es ausgerichtet? Prima! Du bist ein Schatz."},
	"Skeptiker": {"kind": "item", "item": Item.Kind.COBWEB, "task": "Spinnweben aus dem Keller – als Beweis",
		"ask": "Angeblich hängen unten im Keller Spinnweben so dick wie Vorhänge. Bring mir welche, dann glaub ich's.",
		"thanks": "Hm. Tatsächlich. Na gut – ich nehm alles zurück. Danke."},
	"Griesgram": {"kind": "item", "item": Item.Kind.TEA, "task": "Einen Tee bringen – Kräuter, nicht zu heiß",
		"ask": "Die Kinder lärmen den ganzen Tag. Bring mir einen Tee, ja? Kräuter. Und nicht zu heiß.",
		"thanks": "… Danke. Der ist gut. Sag's keinem."},
	"Kind": {"kind": "game", "game": "", "task": "Mit {name} spielen – Würfeln, Schach oder Darts",
		"ask": "Spielst du mit mir? Bitte! Die Großen haben nie Zeit.",
		"thanks": "Das war toll! Spielen wir morgen wieder?"},
}
## Herzensbitten der Kernfiguren (6.0) – eigene Sätze; ihr Bezug zum Geheimnis (2.3) ist noch offen.
const CORE := {
	"edna": {"kind": "item", "item": Item.Kind.CANDLE, "task": "Eine Kerze für Ednas Fenster",
		"ask": "Ach, Liebes … würdest du mir eine Kerze bringen? Für mein Fenster. Damit draußen jemand sieht, dass hier noch Licht ist.",
		"thanks": "Danke. Mein Mann hat früher immer eine ins Fenster gestellt. Jetzt fühlt es sich wieder an wie zu Hause."},
	"bruno": {"kind": "item", "item": Item.Kind.CARVED_PUMPKIN, "favorite": true, "task": "Bruno einen geschnitzten {fav} bringen",
		"ask": "Schnitz mir einen {fav}. Einen richtigen, mit Zähnen. Meine sehen alle aus wie Kartoffeln.",
		"thanks": "Na, sieh mal einer an. Das ist ein Kürbis. Den stell ich vor die Tür."},
	"mila": {"kind": "game", "game": "chess", "task": "Mit Mila eine Partie Schach spielen",
		"ask": "Spielst du mal eine Partie Schach mit mir? Hier kann's keiner, und ich roste ein.",
		"thanks": "Danke für die Partie! Endlich mal jemand, der nicht nach drei Zügen aufgibt."},
}
## Kleine Bitten nach Lage (item: Item.Kind)
const SMALL := {
	"pumpkin": {"task": "Einen {fav}{carved} vor {name}s Tür",
		"ask": "Vor meiner Tür ist es so kahl … Ich hätte so gern einen {fav}{carved_ask}. Wenn du einen findest?",
		"thanks": "Ein {fav_nom}! Der kommt gleich vor die Tür. Danke!"},
	"candle": {"item": Item.Kind.CANDLE, "task": "Eine Kerze bringen",
		"ask": "Ich hab kein Licht mehr für heute Nacht. Hättest du eine Kerze für mich?",
		"thanks": "Eine Kerze … dann ist es heute Nacht nicht ganz dunkel. Danke."},
	"coffee": {"item": Item.Kind.COFFEE, "task": "Einen Kaffee bringen",
		"ask": "Ich krieg die Augen kaum auf. Bringst du mir einen Kaffee mit, wenn du an der Maschine vorbeikommst?",
		"thanks": "Kaffee! Du rettest mir den Morgen."},
	"sweets": {"item": Item.Kind.SWEETS, "task": "Süßigkeiten für {name}",
		"ask": "Hast du Süßigkeiten? Mama sagt, ich darf nur eins. Eins!",
		"thanks": "Jaaa! Danke!"},
	"likes": {"task": "{thing} für {name}",
		"ask": "Weißt du, was mir fehlt? {thing}. Wenn dir mal was über den Weg läuft …",
		"thanks": "Genau so was! Danke, dass du an mich gedacht hast."},
}
## Was er mag – als Satzteil (kleine Bitte „likes“)
const THINGS := {Item.Kind.CANDLE: "Eine Kerze", Item.Kind.LEAVES: "Ein bisschen Herbstlaub", Item.Kind.COBWEB: "Spinnweben",
	Item.Kind.BAT_GARLAND: "Eine Fledermausgirlande", Item.Kind.SPIDER: "Eine Deko-Spinne", Item.Kind.SKULL: "Ein Totenkopf",
	Item.Kind.LIGHT_STRING: "Eine Lichterkette", Item.Kind.SHEET_GHOST: "Ein Lakengespenst", Item.Kind.MINI_PUMPKIN: "Ein Zierkürbis",
	Item.Kind.SWEETS: "Süßigkeiten", Item.Kind.TEA: "Ein Tee", Item.Kind.COFFEE: "Ein Kaffee", Item.Kind.SODA_CAN: "Eine Limo",
	Item.Kind.BROOM: "Ein Hexenbesen", Item.Kind.APPLE: "Ein Apfel"}
const GAME_NAMES := {"dice": "Mäxchen", "chess": "Schach", "darts": "Darts"}
const REMIND := ["Denkst du noch an meine Bitte?", "Und – hast du an mich gedacht? Kein Stress.",
	"Du weißt noch, worum ich dich gebeten hab?"]

## Offene Bitten: {id, guest, heart, kind, item, variety, carved, game, target, money, task, thanks, say, reply,
## day, told} – told: ausgerichtet (message), wartet auf den Dank
var active: Array[Dictionary] = []
## Gast-ID → "done" (erfüllt) bzw. "open" (angenommen) – jeder bekommt seine Herzensbitte nur einmal
var hearts := {}
var _small_day := -1
var _small_today := 0
var _next_id := 1
var _offered := {}    ## Gast-ID → Spieltag: heute schon gefragt (nicht gespeichert)
var _reminded := {}   ## Gast-ID → Spieltag: heute schon erinnert (nicht gespeichert)
var _day := -1
var _forced := ""     ## --bitte: diese Bitte stellt der nächste Gast sicher (herz, kerze, kuerbis …)


func _process(_delta: float) -> void:
	if Game.social == null or Game.director == null:
		return
	var today := Calendar.today()
	if _day != today:
		if _day >= 0:
			_end_of_day()
		_day = today
	for req in active.duplicate():
		if req["kind"] == "escort":
			_check_escort(req)


# --- Fragen, Annehmen, Ablehnen ----------------------------------------------------------------

## Bitte, die er zu Beginn des Gesprächs von sich aus stellt ({} = keine). asked: der Spieler hat gefragt
## („Kann ich dir irgendwie helfen?“) – dann ohne Zufall.
func offer_for(g: Guest, asked: bool = false) -> Dictionary:
	if g.dead or Grinch.is_grinch(g) or own_request(g) or (not asked and _forced == "" and int(_offered.get(g.id, -1)) == Calendar.today()):
		return {}
	var req := {}
	if _forced != "":
		req = _forced_request(g, _forced)
		_forced = ""
		return req
	if _heart_open_to(g) and (asked or randf() < float(OFFER_CHANCE["heart"])):
		req = make_heart(g)
	elif _small_allowed(g) and (asked or randf() < float(OFFER_CHANCE["small"])):
		req = _make_small(g)
	if not asked and not req.is_empty():
		_offered[g.id] = Calendar.today()
	return req


## Angenommen: ins Notizbuch, er merkt es sich. Gibt seinen Satz zurück.
func accept(g: Guest, req: Dictionary) -> String:
	req["id"] = "bitte:%d" % _next_id
	_next_id += 1
	req["day"] = Calendar.today()
	active.append(req)
	if req["heart"]:
		hearts[g.id] = "open"
	else:
		if _small_day != Calendar.today():
			_small_day = Calendar.today()
			_small_today = 0
		_small_today += 1
	if Game.notebook:
		Game.notebook.add_task(req["id"], req["task"], "", g, "" if req["heart"] else "heute")
	if Game.tracing:
		print("[Bitte] %s: %s angenommen (%s)" % [g.display_name, req["task"], req["kind"]])
	if req["kind"] == "escort":
		return "Danke! Ich bleib dicht hinter dir."
	return "Danke! Ich wusste, auf dich ist Verlass." if not g.is_child() else "Versprochen? Juhu!"


## Abgelehnt: kostet nichts, bei Freunden ein wenig. Die Herzensbitte stellt er an einem anderen Tag wieder.
func decline(g: Guest, req: Dictionary) -> String:
	_offered[g.id] = Calendar.today()
	if Social.tier(g) >= Social.Tier.FRIEND:
		Game.social.change_relation(g, DECLINED_FRIEND)
	if req["heart"]:
		return "Schon gut. Vielleicht ein andermal."
	return "Na gut. Frag ich jemand anderen."


## Seine offene Bitte ({} = keine)
func request_of(g: Guest) -> Dictionary:
	for req in active:
		if req["guest"] == g.id:
			return req
	return {}


func own_request(g: Guest) -> bool:
	return not request_of(g).is_empty()


## Erinnerung beim Gespräch – einmal am Spieltag ("" = keine)
func reminder(g: Guest) -> String:
	var req := request_of(g)
	if req.is_empty() or req["told"] or int(_reminded.get(g.id, -1)) == Calendar.today():
		return ""
	_reminded[g.id] = Calendar.today()
	return String(REMIND.pick_random())


## Ausgerichtet: Dank beim nächsten Gespräch mit dem Auftraggeber ("" = nichts zu danken)
func thanks_on_greet(g: Guest) -> String:
	var req := request_of(g)
	if req.is_empty() or not req["told"]:
		return ""
	return _complete(g, req)


# --- Erfüllen ----------------------------------------------------------------------------------

## Geschenk aus DialogUI._gift: erfüllt es seine Bitte? Gibt seinen Dank zurück ("" = nein). Lieblingskürbis: er
## stellt ihn vor seine Tür (Guest.gift_to_door).
func on_gift(g: Guest, item: Item) -> String:
	var req := request_of(g)
	if req.is_empty() or req["kind"] != "item" or not _fits(req, item):
		return ""
	if int(req["item"]) in [Item.Kind.PUMPKIN, Item.Kind.CARVED_PUMPKIN]:
		g.gift_to_door = true
	return _complete(g, req)


## Ende einer Partie mit dem Spieler (DiceMatch, ChessMatch, DartMatch): game = "dice", "chess" oder "darts".
func on_game_played(g: Guest, game: String) -> void:
	var req := request_of(g)
	if req.is_empty() or req["kind"] != "game" or (req["game"] != "" and req["game"] != game):
		return
	var line := _complete(g, req)
	get_tree().create_timer(2.5, false).timeout.connect(func() -> void:
		if is_instance_valid(g) and not g.dead:
			g.say(line))


## Ausrichten: Anlass im Gespräch mit dem Empfänger – die Bitte, deren Nachricht an ihn geht ({} = keine)
func message_for(target: Guest) -> Dictionary:
	for req in active:
		if req["kind"] == "message" and req["target"] == target.id and not req["told"]:
			return req
	return {}


## Ausgerichtet – der Empfänger antwortet; der Auftraggeber dankt beim nächsten Gespräch.
func deliver(target: Guest, req: Dictionary) -> String:
	req["told"] = true
	Game.social.change_relation(target, 2.0)
	var giver := Game.social.guest_by_id(String(req["guest"]))
	if giver and Game.social.pals:
		Game.social.pals.note(giver, target)
	return _fill(String(req["reply"]), giver, target)


## Begleiten: Der Gast kommt mit; erfüllt, sobald er mit dir an der Bar ist.
func start_escort(g: Guest) -> void:
	g.start_follow(ESCORT_TIME)


func _check_escort(req: Dictionary) -> void:
	var g := Game.social.guest_by_id(String(req["guest"]))
	if g == null or g.dead or not g.is_following():
		return
	if Game.social.builder.in_area(g.global_position, "bar"):
		var line := _complete(g, req)
		g.stop_follow(line)


func _complete(g: Guest, req: Dictionary) -> String:
	active.erase(req)
	if Game.notebook:
		Game.notebook.finish_task(String(req["id"]))
	if req["heart"]:
		hearts[g.id] = "done"
		Game.social.change_relation(g, HEART_REWARD)   # einmalig, außerhalb des Tagesbudgets (6.18, 5)
		Game.social.pals.praise(g, HEART_PRAISE)
	else:
		Game.social.talk.friendly(g, SMALL_REWARD)
		Game.social.pals.praise(g, SMALL_PRAISE)
	if int(req["money"]) > 0:
		var paid := mini(int(req["money"]), g.money)
		g.money -= paid
		Game.money += paid
	if Game.tracing:
		print("[Bitte] %s: %s erfüllt" % [g.display_name, req["task"]])
	return String(req["thanks"])


## Passt der Gegenstand? Kürbis: Sorte, geschnitzt bzw. ungeschnitzt.
func _fits(req: Dictionary, item: Item) -> bool:
	if item.kind != int(req["item"]):
		return false
	return req["variety"] == "" or item.variety == req["variety"]


# --- Tagesende, Tod -----------------------------------------------------------------------------

## Kleine Bitten gelten nur bis zum Ende des Spieltags: „zu spät“, er ist ein wenig enttäuscht.
func _end_of_day() -> void:
	for req in active.duplicate():
		if req["heart"] or req["told"]:
			continue
		active.erase(req)
		if Game.notebook:
			Game.notebook.miss_task(String(req["id"]))
		var g := Game.social.guest_by_id(String(req["guest"]))
		if g and not g.dead:
			Game.social.change_relation(g, MISSED)


## Stirbt der Gast, bleibt die Aufgabe im Notizbuch offen (Kreuz, 3.10) – hier fällt sie weg.
func on_guest_died(g: Guest) -> void:
	for req in active.duplicate():
		if req["guest"] == g.id:
			active.erase(req)


# --- Bitten bauen -------------------------------------------------------------------------------

func _heart_open_to(g: Guest) -> bool:
	return not hearts.has(g.id) and Social.tier(g) >= HEART_TIER


func _small_allowed(g: Guest) -> bool:
	if Social.tier(g) < SMALL_TIER:
		return false
	var today_count := _small_today if _small_day == Calendar.today() else 0
	return today_count < SMALL_PER_DAY and active.filter(func(r: Dictionary) -> bool: return not r["heart"]).size() < MAX_SMALL


## Seine Herzensbitte: Kernfigur eigene, sonst nach Charakter. Kein Zufall – aus Charakter und ID (Spielstände).
func make_heart(g: Guest) -> Dictionary:
	var src: Dictionary = CORE.get(g.id, HEART.get(Talk.temper(g), HEART["Bastler"]))
	var req := _base(g, src, true)
	if src.get("favorite", false):   # Bruno: geschnitzt in seiner Sorte – lässt sie sich nicht schnitzen, Halloween
		var fav := g.favorite_pumpkin()
		req["variety"] = fav if bool(PumpkinKinds.data(fav)["carve"]) else PumpkinKinds.DEFAULT
	if req["kind"] == "message":
		var target := _message_target(g)
		if target == null:   # niemand da, dem er etwas ausrichten könnte: dann wie ein Bastler
			return _base(g, HEART["Bastler"], true)
		req["target"] = target.id
	_fill_texts(g, req)
	return req


## Kleine Bitte nach Lage ({} = gerade keine)
func _make_small(g: Guest) -> Dictionary:
	var key := ""
	var phase := Calendar.phase()
	if g.is_child():
		key = "sweets"
	elif g.is_household_lead() and g.own_deco_near_door().size() < 2:
		key = "pumpkin"
	elif phase == Calendar.Phase.EVENING or phase == Calendar.Phase.NIGHT:
		key = "candle"
	elif phase == Calendar.Phase.MORNING:
		key = "coffee"
	else:
		key = "likes"
	return _small_of(g, key)


func _small_of(g: Guest, key: String) -> Dictionary:
	var src: Dictionary = SMALL[key].duplicate()
	src["kind"] = "item"
	var req := _base(g, src, false)
	if key == "pumpkin":
		var fav := g.favorite_pumpkin()
		var carve: bool = bool(PumpkinKinds.data(fav)["carve"]) and abs(hash(g.id + str(Calendar.today()))) % 2 == 0
		req["item"] = Item.Kind.CARVED_PUMPKIN if carve else Item.Kind.PUMPKIN
		req["variety"] = fav
		req["carved"] = carve
	elif key == "likes":
		var likes: Array = (g.profile.get("likes", []) as Array).filter(func(k: int) -> bool: return THINGS.has(k))
		if likes.is_empty():
			return {}
		req["item"] = int(likes[abs(hash(g.id + str(Calendar.today()))) % likes.size()])
	_fill_texts(g, req)
	return req


func _base(g: Guest, src: Dictionary, heart: bool) -> Dictionary:
	return {"id": "", "guest": g.id, "heart": heart, "kind": String(src.get("kind", "item")),
		"item": int(src.get("item", -1)), "variety": "", "carved": false, "game": String(src.get("game", "")),
		"target": "", "money": int(src.get("money", 0)), "task": String(src.get("task", "")),
		"ask": String(src.get("ask", "")), "thanks": String(src.get("thanks", "")), "say": String(src.get("say", "")),
		"reply": String(src.get("reply", "")), "day": -1, "told": false}


## Platzhalter: {name} (Auftraggeber), {target}, {giver}, {fav}/{fav_nom} (Sorte im Akkusativ/Nominativ),
## {carved}/{carved_ask}, {thing}
func _fill_texts(g: Guest, req: Dictionary) -> void:
	var target := Game.social.guest_by_id(String(req["target"])) if req["target"] != "" else null
	var fav := String(PumpkinKinds.data(req["variety"] if req["variety"] != "" else g.favorite_pumpkin())["name"])
	# „Weißer Kürbis“ ist schon gebeugt: „einen weißen Kürbis“, „ein weißer Kürbis“
	var extra := {"{fav_nom}": fav.replace("Weißer", "weißer"), "{fav}": fav.replace("Weißer Kürbis", "weißen Kürbis"),"{carved}": " (geschnitzt)" if req["carved"] else "",
		"{carved_ask}": ", geschnitzt" if req["carved"] else (", ganz, nicht angeschnitten" if req["item"] == Item.Kind.PUMPKIN else ""),
		"{thing}": String(THINGS.get(int(req["item"]), "Etwas"))}
	for key in ["task", "ask", "thanks", "say", "reply"]:
		var text := _fill(String(req[key]), g, target)
		for k in extra:
			text = text.replace(k, String(extra[k]))
		req[key] = text


func _fill(text: String, giver: Guest, target: Guest) -> String:
	text = text.replace("{name}", giver.display_name if giver else "")
	text = text.replace("{giver}", giver.display_name if giver else "")
	return text.replace("{target}", target.display_name if target else "")


## Wem eine Plaudertasche etwas ausrichten lässt: ein Freund außerhalb des Haushalts, sonst ein anderer Erwachsener
## (fest aus der ID, kein Zufall).
func _message_target(g: Guest) -> Guest:
	var candidates: Array[Guest] = []
	for other in Game.social.living_guests():
		var o: Guest = other
		if o != g and not o.is_child() and not g.housemate_of(o):
			candidates.append(o)
	if candidates.is_empty():
		return null
	var pals := candidates.filter(func(o: Guest) -> bool: return Game.social.pals.are_pals(g, o))
	var pool: Array = pals if not pals.is_empty() else candidates
	pool.sort_custom(func(a: Guest, b: Guest) -> bool: return a.id < b.id)
	return pool[abs(hash(g.id)) % pool.size()]


# --- Spielstand ---------------------------------------------------------------------------------

func save_state() -> Dictionary:
	return {"active": active.duplicate(true), "hearts": hearts.duplicate(), "small_day": _small_day,
		"small_today": _small_today, "next_id": _next_id}


## Ältere Stände ohne „requests“: keine Bitten
func load_state(d: Dictionary) -> void:
	active.clear()
	for r: Dictionary in d.get("active", []):
		var req := _base_from(r)
		if Game.social.guest_by_id(String(req["guest"])) != null:
			active.append(req)
	hearts = {}
	var h: Dictionary = d.get("hearts", {})
	for id in h:
		hearts[String(id)] = String(h[id])
	_small_day = int(d.get("small_day", -1))
	_small_today = int(d.get("small_today", 0))
	_next_id = int(d.get("next_id", 1))
	_offered.clear()
	_reminded.clear()
	_day = Calendar.today()


## JSON macht aus Zahlen float – zurück in die richtige Form
func _base_from(r: Dictionary) -> Dictionary:
	return {"id": String(r.get("id", "")), "guest": String(r.get("guest", "")), "heart": bool(r.get("heart", false)),
		"kind": String(r.get("kind", "item")), "item": int(r.get("item", -1)), "variety": String(r.get("variety", "")),
		"carved": bool(r.get("carved", false)), "game": String(r.get("game", "")), "target": String(r.get("target", "")),
		"money": int(r.get("money", 0)), "task": String(r.get("task", "")), "ask": String(r.get("ask", "")),
		"thanks": String(r.get("thanks", "")), "say": String(r.get("say", "")), "reply": String(r.get("reply", "")),
		"day": int(r.get("day", -1)), "told": bool(r.get("told", false))}


func reset() -> void:
	load_state({})


# --- Debug --------------------------------------------------------------------------------------

## --bitte=gast[,art[,annehmen|erfuellen]]: Der Gast kommt vor dich und stellt seine Bitte (art: herz – Standard –,
## kuerbis, kerze, kaffee, suess, mag). Mit annehmen sagst du gleich zu, mit erfuellen erfüllst du sie auch
## (Gegenstand in die Hand und schenken, Partie zählt, Begleiter an der Bar, Nachricht ausgerichtet) – Ausgabe [Bitte].
func debug(parts: PackedStringArray) -> void:
	var g := Game.social.find_guest(parts[0] if parts.size() > 0 and parts[0] != "" else "edna")
	if g == null:
		Game.say("Gast unbekannt", 3.0)
		return
	_forced = parts[1] if parts.size() > 1 and parts[1] != "" else "herz"
	hearts.erase(g.id)
	for req in active.duplicate():
		if req["guest"] == g.id:
			active.erase(req)
	if _forced == "herz" and Social.tier(g) < HEART_TIER:
		g.relation = 40.0
	var fulfil := parts.size() > 2 and parts[2] == "erfuellen"
	if fulfil or (parts.size() > 2 and parts[2] == "annehmen"):
		Game.social.talk.debug_answer = 0   # „Mach ich.“
	get_tree().current_scene.call("_debug_talk", g, "")
	if fulfil:
		get_tree().create_timer(4.0, false).timeout.connect(_debug_fulfil.bind(g))


func _forced_request(g: Guest, what: String) -> Dictionary:
	var key: String = {"kuerbis": "pumpkin", "kerze": "candle", "kaffee": "coffee", "suess": "sweets", "mag": "likes"}.get(what, "")
	return make_heart(g) if key == "" else _small_of(g, key)


func _debug_fulfil(g: Guest) -> void:
	var req := request_of(g)
	if req.is_empty():
		print("[Bitte] %s: keine offene Bitte" % g.display_name)
		return
	match String(req["kind"]):
		"item":
			var extra := String(req["variety"])
			if int(req["item"]) == Item.Kind.CARVED_PUMPKIN:
				extra = (extra if extra != "" else PumpkinKinds.DEFAULT) + ",out"
			var item := Item.create(int(req["item"]), extra)
			Game.player.receive_item(item)
			if not Game.dialog.visible:
				Game.dialog.open(g)
			Game.dialog.call("_gift", item)
			print("[Bitte] %s sagt: %s" % [g.display_name, Game.dialog._text.text])
			Game.dialog.close()
			if item.kind in [Item.Kind.PUMPKIN, Item.Kind.CARVED_PUMPKIN]:   # steht er vor seiner Tür?
				get_tree().create_timer(90.0, false).timeout.connect(func() -> void:
					if is_instance_valid(item) and is_instance_valid(g):
						var front: Vector3 = g.home["door_front"]
						print("[Bitte] %s: %.1f m vor der Tür von %s, %s" % [item.display_name,
							Vector2(item.global_position.x - front.x, item.global_position.z - front.z).length(),
							g.display_name, "abgestellt" if not item.is_held else "noch in der Hand"]))
		"game":
			on_game_played(g, String(req["game"]) if req["game"] != "" else "dice")
		"escort":
			Game.dialog.close()
			start_escort(g)
			get_tree().create_timer(1.0, false).timeout.connect(func() -> void:
				var bar: Vector3 = Game.social.builder.bar_spots[0]
				Game.player.global_position = bar + Vector3(0.0, 0.1, 0.0)
				if is_instance_valid(g):
					g.global_position = bar + Vector3(0.8, 0.1, 0.0))
		"message":
			var target := Game.social.guest_by_id(String(req["target"]))
			print("[Bitte] %s antwortet: %s" % [target.display_name, deliver(target, req)])
			print("[Bitte] %s dankt: %s" % [g.display_name, thanks_on_greet(g)])
