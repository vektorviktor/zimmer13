class_name GuestRequests
extends Node
## Bitten der Gäste (Spielkonzept 6.14, entschieden 2026-10-26): Jeder Gast hat eine Bitte, die zu ihm passt.
##   · Herzensbitte: je Gast eine im ganzen Spiel, ab „freundlich“ (HEART_TIER), aus dem Charakter (Talk.temper) –
##     Kernfiguren mit eigener (CORE). Ohne Frist, außerhalb des Beziehungsbudgets (6.18, 5), weil es sie nur einmal gibt.
##   · Kleine Bitten: selten (SMALL_PER_DAY im ganzen Hotel), höchstens MAX_SMALL zugleich, nach Lage – kahle Tür →
##     Lieblingskürbis (5.8, geschnitzt nur bei schnitzbaren Sorten; er stellt ihn vor seine Tür), abends eine Kerze,
##     morgens Kaffee, Kinder Süßes, abends manchmal ein Glas von der Bar in seiner Sorte (Rotwein für Weinfreunde,
##     BarTap.favorite_of; ZIM-35), sonst etwas, das er mag. Frist: bis zum Ende des Spieltags, zählen zum Budget.
## Arten: item (bringen – erfüllt beim Schenken, DialogUI._gift), escort (zur Bar begleiten), message (einem Freund
## etwas ausrichten – Anlass im Gespräch mit ihm), game (eine Partie – erfüllt am Ende eines Spiels), reconcile (Streit
## unter Gästen, 6.16: die Entschuldigung an den anderen überbringen – wie message, aber vom Spieler angestoßen, ohne Frist
## und außerhalb der kleinen Bitten; GuestQuarrels), memorial (Trauerwunsch, 6.12, 6.18 Punkt 3: eine Kerze für den Toten
## vor seine Tür – solange er trauert, außerhalb der kleinen Bitten; erfüllt durch GuestDeaths.honor, Dank beim nächsten
## Gespräch; endet die Trauer vorher, verfällt der Wunsch still und wird im Notizbuch gestrichen).
## Wünsche aus schweren Momenten (6.18 Punkt 3, ZIM-161, Tender): je Zustand fest – Deko für die Tür (door_deco, nach der
## Puppe), eine Katze zum Trösten (cat, nach dem Lakengeist und für Waisen), etwas Warmes ans Bett (soup, verletzt), die
## verschleppte Deko zurück (deco_back); Kernfiguren eigene (Tender.CORE, Art item). Feld „state“: Endet der Zustand,
## verfällt der Wunsch still und wird im Notizbuch gestrichen. Wie memorial außerhalb der kleinen Bitten, ohne Frist;
## je Zustand einmal (granted). Erfüllt: Beziehung ↑ (TENDER_REWARD, im schweren Moment doppelt), er erzählt es weiter.
## Seltene Bitten (6.14 „Wiederfinden“): ring – Gerda Wagner (Haushalt RING_HOUSEHOLD) hat ihren Ehering draußen auf
## einem Tisch liegen lassen, eine Krähe hat ihn ins Nest vor einem Dachfenster getragen (4.25, RoofNest; ZIM-50). Sie
## fragt ab RING_DAY, einmal im Spiel (rare), ohne Frist; erfüllt beim Schenken – auch wenn man ihn vorher gefunden hat.
## Lohn: Freundschaft (mindestens „befreundet“) und ein kleines Geschenk.
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
## Bitten außerhalb der kleinen (ohne Frist, nicht in SMALL_PER_DAY/MAX_SMALL)
const OUTSIDE_SMALL := ["reconcile", "memorial", "door_deco", "cat", "soup", "deco_back", "ring"]
## Verpasst (Ende des Spieltags) bzw. abgelehnt als Freund
const MISSED := -2.0
const DECLINED_FRIEND := -1.0
## So oft fragt er von sich aus zu Beginn eines Gesprächs (Herzensbitte, kleine Bitte)
const OFFER_CHANCE := {"heart": 0.6, "small": 0.35, "memorial": 0.7, "tender": 0.7, "ring": 0.5}
## Ehering (seltene Bitte „Wiederfinden“, ZIM-50): wessen, ab welchem Spieltag sie fragt, Beziehung danach mindestens so
## viel (befreundet), dazu so viel Lob bei ihren Freunden
const RING_HOUSEHOLD := "H10"
const RING_DAY := 3
const RING_FRIEND := 55.0
const RING := {"kind": "ring", "item": Item.Kind.RING,
	"task": "Den Ehering von {name} wiederfinden – draußen am Tisch saßen Krähen",
	"ask": "Ach, gut, dass ich dich sehe … Mein Ehering ist weg. Fünfzig Jahre hab ich ihn nicht abgenommen, und dann leg ich ihn einmal draußen auf den Tisch, nur kurz. Als ich wiederkam, saßen lauter Krähen drum herum. Otto darf das nicht erfahren. Hältst du die Augen offen?",
	"thanks": "Mein Ring! Bei den Krähen war er? Ach, du … Hier, nimm das – und wenn du je etwas brauchst, klopf bei uns. Bei Otto und mir bist du jetzt immer willkommen."}
## Wunsch aus einem schweren Moment erfüllt: so viel Beziehung (im Zustand doppelt), so viel Lob bei seinen Freunden
const TENDER_REWARD := 8.0
const TENDER_PRAISE := 2.5
## So oft wird geprüft, ob ein Zustand vorbei ist (Spielsekunden)
const STATE_SCAN := 1.0
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
		"money": 1, "thanks": "… Danke. Der ist gut. Hier, für den Tee. Sag's keinem."},
	"Kind": {"kind": "game", "game": "", "task": "Mit {name} spielen – Würfeln, Schach oder ein Barspiel",
		"ask": "Spielst du mit mir? Bitte! Die Großen haben nie Zeit.",
		"thanks": "Das war toll! Spielen wir morgen wieder?"},
}
## Herzensbitten der Kernfiguren (6.0) – eigene Sätze; ihr Bezug zum Geheimnis (2.3) ist noch offen.
const CORE := {
	"edna": {"kind": "item", "item": Item.Kind.CANDLE, "task": "Eine Kerze für Ednas Fenster",
		"ask": "Ach, Liebes … würdest du mir eine Kerze bringen? Für mein Fenster. Damit draußen jemand sieht, dass hier noch Licht ist.",
		"thanks": "Danke. Heinrich hat früher immer eine ins Fenster gestellt. Jetzt fühlt es sich wieder an wie zu Hause."},
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
	"coffee": {"item": Item.Kind.COFFEE, "money": 1, "task": "Einen Kaffee bringen",
		"ask": "Ich krieg die Augen kaum auf. Bringst du mir einen Kaffee mit, wenn du an der Maschine vorbeikommst?",
		"thanks": "Kaffee! Du rettest mir den Morgen. Hier, für den Becher."},
	"glass": {"item": Item.Kind.GLASS, "task": "{name} ein {drink} von der Bar bringen",
		"ask": "Weißt du, worauf ich jetzt Lust hätte? Auf ein {drink}. Bringst du mir eins von der Bar mit?",
		"thanks": "Ah, ein {drink}! Genau richtig. Prost – und danke!"},
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
## Vermitteln im Streit (6.16, GuestQuarrels): Zeile im Notizbuch, was du ausrichtest, Antwort, Dank
const RECONCILE := {"kind": "reconcile", "task": "{target} ausrichten: {name} will sich wieder vertragen",
	"say": "{giver} lässt ausrichten: Lass uns den Streit begraben.",
	"reply": "Das sagt {giver}? … Na gut. Schwamm drüber.",
	"thanks": "Ihr habt das geklärt? Danke. Der Streit lag mir schwer im Magen."}
## Trauerwunsch (6.12, GuestMourning): {target} ist der Tote
const MEMORIAL := {"kind": "memorial", "task": "Eine Kerze für {target} vor seine Tür stellen ({name} trauert)",
	"ask": "Ich krieg das nicht hin … Würdest du eine Kerze für {target} vor die Tür stellen? Nur ein kleines Licht.",
	"thanks": "Du hast ein Licht für {target} aufgestellt. Danke … das bedeutet mir viel."}
## Kinder trauern auch – ihr Wunsch
const MEMORIAL_CHILD_ASK := "Stellst du eine Kerze für {target} hin? Damit es nicht so dunkel ist."
const REMIND := ["Denkst du noch an meine Bitte?", "Und – hast du an mich gedacht? Kein Stress.",
	"Du weißt noch, worum ich dich gebeten hab?"]

## Offene Bitten: {id, guest, heart, kind, item, variety, carved, game, target, money, task, thanks, say, reply,
## day, told} – told: ausgerichtet (message), wartet auf den Dank
var active: Array[Dictionary] = []
## Gast-ID → "done" (erfüllt) bzw. "open" (angenommen) – jeder bekommt seine Herzensbitte nur einmal
var hearts := {}
## Gast-ID → {Zustand: Tender.instance} – diesen Wunsch hat er in diesem Zustand schon erfüllt bekommen
var granted := {}
## Erfüllte seltene Bitten (Schlüssel, etwa „ring“) – jede gibt es nur einmal im Spiel
var rare: Array = []
var _small_day := -1
var _small_today := 0
var _next_id := 1
var _offered := {}    ## Gast-ID → Spieltag: heute schon gefragt (nicht gespeichert)
var _reminded := {}   ## Gast-ID → Spieltag: heute schon erinnert (nicht gespeichert)
var _day := -1
var _forced := ""     ## --bitte: diese Bitte stellt der nächste Gast sicher (herz, kerze, kuerbis …)
var _state_scan := 0.0


func _process(delta: float) -> void:
	if Game.social == null or Game.director == null:
		return
	var today := Calendar.today()
	if _day != today:
		if _day >= 0:
			_end_of_day()
		_day = today
	_state_scan -= delta
	var scan := _state_scan <= 0.0
	if scan:
		_state_scan = STATE_SCAN
	for req in active.duplicate():
		if req["kind"] == "escort":
			_check_escort(req)
		elif req["kind"] == "memorial" and not req["told"]:
			_check_memorial(req)
		elif scan and req["state"] != "" and not _check_state(req):
			continue
		elif req["kind"] == "cat":
			_check_cat(req)


# --- Fragen, Annehmen, Ablehnen ----------------------------------------------------------------

## Bitte, die er zu Beginn des Gesprächs von sich aus stellt ({} = keine). asked: der Spieler hat gefragt
## („Kann ich dir irgendwie helfen?“) – dann ohne Zufall. tender_only: nur ein Wunsch aus dem schweren Moment (verletzt).
func offer_for(g: Guest, asked: bool = false, tender_only: bool = false) -> Dictionary:
	if g.dead or Grinch.is_grinch(g) or own_request(g) or (not asked and _forced == "" and int(_offered.get(g.id, -1)) == Calendar.today()):
		return {}
	var req := {}
	if _forced != "":
		req = _forced_request(g, _forced)
		_forced = ""
		return req
	var dead := _memorial_for(g)
	var state := tender_state(g)
	if dead and (asked or randf() < float(OFFER_CHANCE["memorial"])):   # Trauer geht vor (6.18, 3)
		req = make_memorial(g, dead)
	elif state != "" and (asked or randf() < float(OFFER_CHANCE["tender"])):   # dann die übrigen schweren Momente
		req = make_tender(g, state)
	elif tender_only:
		pass
	elif _ring_open_to(g) and (asked or randf() < float(OFFER_CHANCE["ring"])):   # seltene Bitte (ZIM-50)
		req = make_ring(g)
	elif _heart_open_to(g) and (asked or randf() < float(OFFER_CHANCE["heart"])):
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
	elif not _outside_small(req):
		if _small_day != Calendar.today():
			_small_day = Calendar.today()
			_small_today = 0
		_small_today += 1
	if Game.notebook:
		Game.notebook.add_task(req["id"], req["task"], "", g, "" if req["heart"] or _outside_small(req) else "heute")
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
	if is_her_ring(g, item) and not rare.has("ring") and (req.is_empty() or req["kind"] != "ring"):
		_ring_reward(g)   # gefunden, bevor sie gefragt hat: Dank und Lohn wie erbeten
		return _fill(String(RING["thanks"]), g, null)
	if req.is_empty():
		return ""
	match String(req["kind"]):
		"ring":
			if not is_her_ring(g, item):
				return ""
		"item":
			if not _fits(req, item):
				return ""
			if int(req["item"]) in [Item.Kind.PUMPKIN, Item.Kind.CARVED_PUMPKIN]:
				g.gift_to_door = true
		"door_deco":   # nach der Puppe: irgendeine Deko – sie kommt gleich vor seine Tür
			if item.deco_strength <= 0.0 or item.kind in Guest.FOOD_GIFTS:
				return ""
			g.gift_to_door = true
		"soup":   # verletzt: etwas Warmes aus der Küche
			if not item.kind in Tender.WARM_FOOD:
				return ""
		"deco_back":   # genau das Stück, das die Katze verschleppt hat
			if String(item.get_meta("cat_took", "")) != g.id:
				return ""
			item.remove_meta("cat_took")
		_:
			return ""
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
		if req["kind"] in ["message", "reconcile"] and req["target"] == target.id and not req["told"]:
			return req
	return {}


## Ausgerichtet – der Empfänger antwortet; der Auftraggeber dankt beim nächsten Gespräch.
func deliver(target: Guest, req: Dictionary) -> String:
	req["told"] = true
	Game.social.change_relation(target, 2.0)
	var giver := Game.social.guest_by_id(String(req["guest"]))
	if giver and req["kind"] == "reconcile":
		Game.social.quarrels.reconcile(giver, target)
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
		if Game.achievements:
			Game.achievements.unlock("heart_request")   # Spielkonzept 8.11
		Game.social.change_relation(g, HEART_REWARD)   # einmalig, außerhalb des Tagesbudgets (6.18, 5)
		Game.social.pals.praise(g, HEART_PRAISE)
	elif req["kind"] == "ring":
		_ring_reward(g)
	elif req["state"] != "":   # Wunsch aus einem schweren Moment (6.18, 3): zählt im Zustand doppelt, er erzählt es weiter
		_grant(g, String(req["state"]))
		Game.social.talk.friendly(g, TENDER_REWARD)
		Game.social.pals.praise(g, TENDER_PRAISE)
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
	return req["variety"] == "" or (item.flavor if item.kind == Item.Kind.GLASS else item.variety) == req["variety"]


# --- Tagesende, Tod -----------------------------------------------------------------------------

## Kleine Bitten gelten nur bis zum Ende des Spieltags: „zu spät“, er ist ein wenig enttäuscht.
func _end_of_day() -> void:
	for req in active.duplicate():
		if req["heart"] or req["told"] or _outside_small(req):
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
	return today_count < SMALL_PER_DAY and active.filter(func(r: Dictionary) -> bool:
		return not r["heart"] and not _outside_small(r)).size() < MAX_SMALL


## Gerda Wagner (Haushalt RING_HOUSEHOLD, die Frau): ihr gehört der Ehering aus dem Dachnest (ZIM-50).
static func is_ring_owner(g: Guest) -> bool:
	return g != null and not g.is_child() and String(g.profile.get("household", "")) == RING_HOUSEHOLD \
		and String(g.profile.get("sex", "")) == "f"


static func is_her_ring(g: Guest, item: Item) -> bool:
	return item != null and item.kind == Item.Kind.RING and is_ring_owner(g)


## Seltene Bitte „Wiederfinden“: nur Gerda, ab RING_DAY, ab „neutral“, einmal im Spiel.
func _ring_open_to(g: Guest) -> bool:
	return is_ring_owner(g) and not rare.has("ring") and Calendar.today() >= RING_DAY and Social.tier(g) >= SMALL_TIER


func make_ring(g: Guest) -> Dictionary:
	var req := _base(g, RING, false)
	_fill_texts(g, req)
	return req


## Ehering zurück: Freundschaft (mindestens RING_FRIEND – der Zuwachs wird so bemessen, dass er nach der Abflachung in
## Social.change_relation reicht), Lob bei ihren Freunden, und gleich darauf ein kleines Geschenk aus ihrem Vorrat (eine
## Kerze, sonst Bonbons aus der Handtasche).
func _ring_reward(g: Guest) -> void:
	rare.append("ring")
	var damp := 1.0 - clampf(g.relation, 0.0, 100.0) / 110.0
	Game.social.change_relation(g, maxf(HEART_REWARD, (RING_FRIEND - g.relation) / damp + 0.5))
	Game.social.pals.praise(g, HEART_PRAISE)
	Game.social.add_deed(g, "gifts_from")
	var kind := Item.Kind.SWEETS
	if int(g.stock.get(Item.Kind.CANDLE, 0)) > 0:
		g.stock[Item.Kind.CANDLE] = int(g.stock[Item.Kind.CANDLE]) - 1
		kind = Item.Kind.CANDLE
	get_tree().create_timer(1.0, false).timeout.connect(func() -> void:   # erst, wenn der Ring aus der Hand ist
		if Game.player and not Game.player.dead:
			Game.player.receive_item(Item.create(kind)))
	if Game.notebook:
		Game.notebook.add_note("ring_back", "%s hat ihren Ehering wieder. Fünfzig Jahre – und Otto weiß von nichts." % g.display_name,
			"Zimmer %s" % String(g.home["no"]))
	if Game.tracing:
		print("[Ring] %s hat ihren Ehering wieder: Beziehung %.0f (%s), Geschenk %s" % [g.display_name, g.relation,
			Social.relation_word(g.relation), Item.Kind.keys()[kind]])


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


## Vermitteln (6.16): g will sich mit other vertragen – du richtest es other aus ({} = er hat schon eine offene Bitte).
func make_reconcile(g: Guest, other: Guest) -> Dictionary:
	if own_request(g):
		return {}
	var req := _base(g, RECONCILE, false)
	req["target"] = other.id
	_fill_texts(g, req)
	return req


## Trauerwunsch (6.12): eine Kerze für den Toten vor seine Tür.
func make_memorial(g: Guest, dead: Guest) -> Dictionary:
	var req := _base(g, MEMORIAL, false)
	if g.is_child():
		req["ask"] = MEMORIAL_CHILD_ASK
	req["target"] = dead.id
	_fill_texts(g, req)
	return req


## Um wen trauert er, für den noch kein Licht des Spielers brannte? null = keinen.
func _memorial_for(g: Guest) -> Guest:
	var id := GuestMourning.mourns(g)
	if id == "" or Game.social.deaths.honored(id):
		return null
	return Game.social.guest_by_id(id)


## Ein Licht des Spielers vor der Tür des Toten (GuestDeaths.honor): Wer es sich gewünscht hat, dankt beim nächsten
## Gespräch (wie beim Ausrichten).
func on_memorial(dead: Guest) -> void:
	for req in active:
		if req["kind"] == "memorial" and req["target"] == dead.id:
			req["told"] = true


## Trauer vorbei, ohne dass ein Licht brannte: Der Wunsch verfällt still (im Notizbuch gestrichen, ohne Malus).
func _check_memorial(req: Dictionary) -> void:
	var g := Game.social.guest_by_id(String(req["guest"]))
	if g and not g.dead and GuestMourning.mourns(g) == String(req["target"]):
		return
	active.erase(req)
	if Game.notebook:
		Game.notebook.miss_task(String(req["id"]))


# --- Wünsche aus schweren Momenten (6.18 Punkt 3, Tender) --------------------------------------

## Zählt nicht zu den kleinen Bitten (ohne Frist, nicht in SMALL_PER_DAY/MAX_SMALL)?
func _outside_small(req: Dictionary) -> bool:
	return req["kind"] in OUTSIDE_SMALL or req["state"] != ""


## Der schwere Moment, aus dem er sich gerade etwas wünscht ("" = keiner): der erste nach Tender.ORDER, dessen Wunsch
## er in diesem Zustand noch nicht erfüllt bekommen hat und der sich erfüllen lässt (Katzen da, Stück noch da).
func tender_state(g: Guest) -> String:
	for state: String in Tender.ORDER:
		if not Tender.has_state(g, state) or _granted(g, state):
			continue
		if state == "doll" and g.is_child():
			continue
		var core := Tender.CORE.has(g.id) and state in Tender.CORE_STATES
		if not core and state in ["ghost", "orphan"] and get_tree().get_nodes_in_group("cats").is_empty():
			continue
		if state == "cat_took" and _cat_loot(g) == null:
			continue
		return state
	return ""


## Sein Wunsch in diesem Zustand: Kernfiguren eigene, sonst nach Tender.WISHES (Kinder mit eigenen Sätzen).
func make_tender(g: Guest, state: String) -> Dictionary:
	var core := Tender.CORE.has(g.id) and state in Tender.CORE_STATES
	var src: Dictionary = (Tender.CORE[g.id] if core else Tender.WISHES[state] as Dictionary).duplicate()
	if not core and g.is_child() and Tender.WISHES.has(state + "_child"):
		src.merge(Tender.WISHES[state + "_child"], true)
	var req := _base(g, src, false)
	req["state"] = state
	if state == "cat_took":
		var s: Dictionary = g.stances["cat_took"]
		var kind := int(s.get("kind", -1))
		req["item"] = kind
		for key in ["task", "ask", "thanks"]:
			req[key] = String(req[key]).replace("{cat}", String(s.get("cat", "Die Katze"))) \
				.replace("{thing}", String(Tender.THINGS.get(kind, "meine Deko"))) \
				.replace("{what}", String(Tender.THINGS_TASK.get(kind, "die Deko")))
	_fill_texts(g, req)
	return req


## Das Stück, das ihm eine Katze verschleppt hat und das es noch gibt (null = keins).
func _cat_loot(g: Guest) -> Item:
	for node in get_tree().get_nodes_in_group("items"):
		if String((node as Item).get_meta("cat_took", "")) == g.id:
			return node
	return null


func _granted(g: Guest, state: String) -> bool:
	var states: Dictionary = granted.get(g.id, {})
	return states.has(state) and String(states[state]) == Tender.instance(g, state)


func _grant(g: Guest, state: String) -> void:
	if not granted.has(g.id):
		granted[g.id] = {}
	granted[g.id][state] = Tender.instance(g, state)


## Neue Verletzung (Guest.wound_by): Der Wunsch der alten ist vergessen.
func forget_granted(g: Guest, state: String) -> void:
	if granted.has(g.id):
		(granted[g.id] as Dictionary).erase(state)


## Katze zum Trösten: Trägst du eine Katze auf dem Arm nah genug heran, ist der Wunsch erfüllt – er krault sie.
func _check_cat(req: Dictionary) -> void:
	var p := Game.player
	if p == null or p.carried_cat == null or p.in_dialog:
		return
	var g := Game.social.guest_by_id(String(req["guest"]))
	if g == null or g.dead or g.global_position.distance_to(p.global_position) > Tender.CAT_RANGE:
		return
	var cat: HotelCat = p.carried_cat
	Game.noise("cat_purr", cat.global_position, cat)
	g.fear = maxf(0.0, g.fear - Tender.CAT_CALM)
	g.say(_complete(g, req))


## Gilt sein Zustand noch? Sonst verfällt der Wunsch still und wird im Notizbuch gestrichen, ohne Malus – die Kränkung
## kommt, wenn überhaupt, über die Besuche (Tender.on_grief_ended, Wounds.NEGLECT). false = verfallen.
func _check_state(req: Dictionary) -> bool:
	var g := Game.social.guest_by_id(String(req["guest"]))
	if g and not g.dead and Tender.has_state(g, String(req["state"])):
		return true
	active.erase(req)
	if Game.notebook:
		Game.notebook.miss_task(String(req["id"]))
	if Game.tracing and g:
		print("[Wunsch] %s: „%s“ verfällt – der Zustand ist vorbei" % [g.display_name, req["task"]])
	return false


## Kleine Bitte nach Lage ({} = gerade keine)
func _make_small(g: Guest) -> Dictionary:
	var key := ""
	var phase := Calendar.phase()
	if g.is_child():
		key = "sweets"
	elif g.is_household_lead() and g.own_deco_near_door().size() < 2:
		key = "pumpkin"
	elif phase == Calendar.Phase.EVENING and absi(hash(g.id + str(Calendar.today()))) % 2 == 0:
		key = "glass"   # Feierabend: ein Glas von der Bar (ZIM-35)
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
	elif key == "glass":
		req["variety"] = BarTap.favorite_of(g)   # Sorte des Glases (Item.flavor)
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
		"reply": String(src.get("reply", "")), "day": -1, "told": false, "state": ""}


## Platzhalter: {name} (Auftraggeber), {target}, {giver}, {fav}/{fav_nom} (Sorte im Akkusativ/Nominativ),
## {carved}/{carved_ask}, {thing}, {drink} (Glas von der Bar in seiner Sorte)
func _fill_texts(g: Guest, req: Dictionary) -> void:
	var target := Game.social.guest_by_id(String(req["target"])) if req["target"] != "" else null
	var fav := String(PumpkinKinds.data(req["variety"] if req["variety"] != "" else g.favorite_pumpkin())["name"])
	# „Weißer Kürbis“ ist schon gebeugt: „einen weißen Kürbis“, „ein weißer Kürbis“
	var extra := {"{fav_nom}": fav.replace("Weißer", "weißer"), "{fav}": fav.replace("Weißer Kürbis", "weißen Kürbis"),"{carved}": " (geschnitzt)" if req["carved"] else "",
		"{carved_ask}": ", geschnitzt" if req["carved"] else (", ganz, nicht angeschnitten" if req["item"] == Item.Kind.PUMPKIN else ""),
		"{thing}": String(THINGS.get(int(req["item"]), "Etwas")),
		"{drink}": String(BarTap.SORTS.get(String(req["variety"]), BarTap.SORTS["wein"])["glass"])}
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
		"small_today": _small_today, "next_id": _next_id, "granted": granted.duplicate(true), "rare": rare.duplicate()}


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
	granted = {}
	var gr: Dictionary = d.get("granted", {})
	for id in gr:
		var states := {}
		for state in (gr[id] as Dictionary):
			states[String(state)] = String(gr[id][state])
		granted[String(id)] = states
	rare = (d.get("rare", []) as Array).map(func(k) -> String: return String(k))
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
		"day": int(r.get("day", -1)), "told": bool(r.get("told", false)), "state": String(r.get("state", ""))}


func reset() -> void:
	load_state({})


# --- Debug --------------------------------------------------------------------------------------

## --bitte=gast[,art[,annehmen|erfuellen]]: Der Gast kommt vor dich und stellt seine Bitte (art: herz – Standard –,
## kuerbis, kerze, kaffee, suess, mag; ring – die seltene Bitte, nur Gerda). Mit annehmen sagst du gleich zu, mit
## erfuellen erfüllst du sie auch (Gegenstand in die Hand und schenken, Partie zählt, Begleiter an der Bar, Nachricht
## ausgerichtet; ring: aus dem Dachnest holen und schenken, Prüfung „[Ring] … ok“ bzw. „FEHLER“) – Ausgabe [Bitte].
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
	if what == "ring":
		return make_ring(g) if is_ring_owner(g) else {}
	var key: String = {"kuerbis": "pumpkin", "kerze": "candle", "kaffee": "coffee", "suess": "sweets", "mag": "likes",
		"glas": "glass"}.get(what, "")
	return make_heart(g) if key == "" else _small_of(g, key)


## Ring-Bitte erfüllen wie im Spiel: unter das Dachfenster, [E] am Nest (RoofNest.interact), ihr schenken.
func _debug_ring(g: Guest) -> void:
	var report := func(what: String, ok: bool) -> void:
		print("[Ring] %s: %s" % [what, "ok" if ok else "FEHLER"])
	var nest: RoofNest = Game.crows.roof if Game.crows else null
	report.call("Dachnest gebaut", nest != null)
	if nest == null:
		return
	Game.dialog.close()
	Game.crows.debug_show("dachnest")
	report.call("Prompt am Fenster", nest.get_prompt(Game.player).ends_with("[E]"))
	nest.interact(Game.player)
	var ring := Game.player.held
	report.call("Ring in der Hand", ring != null and ring.kind == Item.Kind.RING and ring.display_name.begins_with("Goldener Ehering"))
	report.call("Dachnest leer", Game.crows.roof_nest.is_empty())
	if ring == null:
		return
	Game.dialog.open(g)
	Game.dialog.call("_gift", ring)
	print("[Bitte] %s sagt: %s" % [g.display_name, Game.dialog._text.text])
	Game.dialog.close()
	report.call("Bitte erfüllt", request_of(g).is_empty() and rare.has("ring"))
	report.call("befreundet", Social.tier(g) >= Social.Tier.FRIEND)
	get_tree().create_timer(2.0, false).timeout.connect(func() -> void:
		var gift := Game.player.held
		report.call("kleines Geschenk in der Hand", gift != null and gift.kind in [Item.Kind.CANDLE, Item.Kind.SWEETS]
			or Game.player.bag.any(func(i: Item) -> bool: return i.kind in [Item.Kind.CANDLE, Item.Kind.SWEETS])))
	get_tree().create_timer(20.0, false).timeout.connect(func() -> void:
		report.call("Ring angesteckt (weg)", not is_instance_valid(ring) or ring.is_queued_for_deletion()))


func _debug_fulfil(g: Guest) -> void:
	var req := request_of(g)
	if req.is_empty():
		print("[Bitte] %s: keine offene Bitte" % g.display_name)
		return
	match String(req["kind"]):
		"ring":
			_debug_ring(g)
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


# --- Debug (--zustand) -----------------------------------------------------------------------------

## --zustand=art[,gast[,erfuellen|verfallen|halten]]: Schwere Momente (6.18 Punkt 3, Tender). art: puppe (Puppe vor
## seiner Tür), geist (vom Lakengeist losgerissen), verletzt (Axtwunde), waise (seine Eltern sterben – ein Kind),
## katze (eine Katze verschleppt sein Laub). Prüft Zustand, doppelte Beziehung, passendes Geschenk, eigene Begrüßung und
## den Wunsch (Kernfiguren ihren eigenen); er wird angenommen und · erfuellen (Standard): du erfüllst ihn (Geschenk,
## Katze auf dem Arm heran, verschlepptes Laub aufheben – kein Diebstahl – und zurückgeben), er dankt, die Beziehung
## steigt, derselbe Wunsch kommt nicht wieder · verfallen: der Zustand endet, der Wunsch wird still gestrichen ·
## halten: der Wunsch bleibt offen (für --savetest). Meldet „[Wunsch] … ok“ bzw. „FEHLER“.
func debug_tender(parts: PackedStringArray) -> void:
	var social := Game.social
	var p := Game.player
	var art := parts[0] if parts.size() > 0 and parts[0] != "" else "puppe"
	var what := parts[2] if parts.size() > 2 and parts[2] != "" else "erfuellen"
	if not art in ["puppe", "geist", "verletzt", "waise", "katze"] or not what in ["erfuellen", "verfallen", "halten"]:
		print("[Wunsch] Debug: --zustand=puppe|geist|verletzt|waise|katze[,gast[,erfuellen|verfallen|halten]]")
		return
	var g: Guest = social.find_guest(parts[1]) if parts.size() > 1 and parts[1] != "" else null
	if g == null:   # ein passender Gast: Kind mit Eltern bzw. ein Erwachsener ohne Kernrolle
		for other in social.living_guests():
			var o: Guest = other
			if Grinch.is_grinch(o) or o.is_core() or (o.is_child() != (art == "waise")) or (art == "waise" and o.parent_guest() == null):
				continue
			g = o
			break
	if g == null or g.dead:
		print("[Wunsch] Debug: kein passender Gast")
		return
	var check := func(text: String, ok: bool) -> void:
		print("[Wunsch] %s: %s" % [text, "ok" if ok else "FEHLER"])
	if Game.notebook:
		Game.notebook.give(true)   # sonst trägt es nichts ein
	for req in active.duplicate():
		if req["guest"] == g.id:
			active.erase(req)
	g.relation = 20.0
	g.fear = 0.0
	g.global_position = p.global_position + (-p.global_transform.basis.z) * 1.6
	g._set_idle(30.0)
	var state: String = {"puppe": "doll", "geist": "ghost", "verletzt": "wound", "waise": "orphan", "katze": "cat_took"}[art]
	var loot: Item = null
	match art:
		"puppe":
			Tender.doll_door(g)
		"geist":
			g.wound_by("choke")
			g.wound_bed = 0.0   # er bleibt vor dir stehen
			Tender.after_ghost(g)
		"verletzt":
			g.wound_by("axe")
			g.wound_bed = 0.0   # er bleibt vor dir stehen
		"waise":
			var parent := g.parent_guest()
			for other in social.living_guests():   # der ganze Haushalt der Eltern
				if other != g and not (other as Guest).is_child() and (other as Guest).housemate_of(g):
					(other as Guest).die("monster")
					social.on_guest_died(other, "monster", true)
			if parent and not parent.dead:
				parent.die("monster")
				social.on_guest_died(parent, "monster", true)
			g.clear_stance("grieving")   # sonst geht der Trauerwunsch vor (eigener Test: --trauer)
			g.relation = 20.0
		"katze":
			loot = Item.create(Item.Kind.LEAVES)
			social.get_parent().add_child(loot)
			loot.owner_id = g.id
			loot.global_position = p.global_position + (-p.global_transform.basis.x) * 1.0 + Vector3(0, 0.05, 0)
			Tender.cat_took(g, loot, "Minka")
	print("[Wunsch] Debug: %s – %s (%s)" % [g.display_name, state, what])
	check.call("Zustand %s" % state, Tender.has_state(g, state))
	if art != "katze":
		check.call("empfindlich", Tender.is_tender(g))
		var before := g.relation
		social.change_relation(g, 2.0)
		check.call("zählt doppelt (+%.1f)" % (g.relation - before), g.relation - before > 2.0 * (1.0 - before / 110.0) * 1.5)
		if art != "verletzt":   # verletzt: Wounds.fitting wie bisher
			var sample := Item.create({"puppe": Item.Kind.SPIDER, "geist": Item.Kind.CANDLE, "waise": Item.Kind.SWEETS}[art])
			check.call("passendes Geschenk %s" % sample.display_name, Tender.fitting(g, sample))
			sample.free()
			check.call("eigene Begrüßung: „%s“" % Tender.greet(g), Tender.greet(g) != "")
	var core := Tender.CORE.has(g.id) and state in Tender.CORE_STATES
	var want: String = "item" if core else String((Tender.WISHES[state] as Dictionary)["kind"])
	var req := offer_for(g, true)
	check.call("Wunsch „%s“" % String(req.get("ask", "")), req.get("kind", "") == want and req.get("state", "") == state)
	if req.is_empty():
		return
	accept(g, req)
	check.call("im Notizbuch: „%s“" % String(req["task"]), Game.notebook == null or Game.notebook.task_state(String(req["id"])) == Notebook.TaskState.OPEN)
	check.call("zählt nicht zu den kleinen Bitten", _outside_small(req))
	if what == "halten":
		return
	if what == "verfallen":
		match state:
			"wound":
				g._heal()
			"orphan":
				print("[Wunsch] Debug: verwaist bleibt bis Halloween – nichts verfällt")
				return
			_:
				g.set_stance({"doll": "doll_door", "ghost": "after_ghost", "cat_took": "cat_took"}[state], 0.5)
		get_tree().create_timer(STATE_SCAN * 2.0 + 1.0, false).timeout.connect(func() -> void:
			check.call("verfällt mit dem Zustand", request_of(g).is_empty())
			check.call("im Notizbuch gestrichen", Game.notebook == null or Game.notebook.task_state(String(req["id"])) == Notebook.TaskState.LATE))
		return
	var rel := g.relation
	var done := func() -> void:
		check.call("erfüllt", request_of(g).is_empty() and (Game.notebook == null
			or Game.notebook.task_state(String(req["id"])) == Notebook.TaskState.DONE))
		check.call("Beziehung steigt (%.1f → %.1f)" % [rel, g.relation], g.relation > rel)
		check.call("kommt nicht wieder", tender_state(g) != state)
	if want == "cat":
		var cats := get_tree().get_nodes_in_group("cats")
		var cat: HotelCat = cats[0]
		cat.global_position = p.global_position + Vector3(0.3, 0.05, 0.3)
		cat.affection = HotelCat.CARRY_TRUST
		cat.pick_up(p)
		get_tree().create_timer(1.0, false).timeout.connect(func() -> void:
			print("[Wunsch] %s mit %s auf dem Arm" % [g.display_name, cat.display_name])
			done.call())
		return
	var gift: Item = loot
	if art == "katze":
		var hostile := social.deed(g, "hostile")
		p.try_pick_up(loot)
		check.call("Aufheben ist kein Diebstahl", social.deed(g, "hostile") == hostile and not loot.has_meta("taken_from"))
	else:
		gift = Item.create(int(req["item"]) if want == "item" else {"door_deco": Item.Kind.SPIDER, "soup": Item.Kind.ROAST_PUMPKIN}[want])
		p.receive_item(gift)
	if not Game.dialog.visible:
		Game.dialog.open(g)
	Game.dialog.call("_gift", gift)
	print("[Wunsch] %s sagt: %s" % [g.display_name, Game.dialog._text.text])
	Game.dialog.close()
	done.call()
	if want == "door_deco":   # steht sie vor seiner Tür?
		get_tree().create_timer(60.0, false).timeout.connect(func() -> void:
			var front: Vector3 = g.home["door_front"]
			check.call("Deko vor seiner Tür", is_instance_valid(gift) and not gift.is_held
				and Vector2(gift.global_position.x - front.x, gift.global_position.z - front.z).length() < 3.0))
