class_name Talk
extends Node
## Was im Gespräch gesagt wird (Spielkonzept 6.9, 2026-10-24): eigene Erlebnisse des Spielers, Erzählen und Lügen,
## Fragen der Gäste mit Antworten, das Gedächtnis der Gäste (Guest.claims) und die Haltungen daraus (Guest.stances),
## die ihr Verhalten steuern. Kind von Social, erreichbar über Game.social.talk. Die Knöpfe baut DialogUI.
##   · Erlebnisse (log): Monster, Lakengeist, Kürbismann gesehen, Leiche oder Blutlache gefunden, Lakengeist im Zimmer,
##     im Dachboden umgedreht – jedes frisch am Tag, an dem es geschah, jedem Gast einmal zu erzählen.
##   · Lügen fliegen auf: Gegenbeweis (der „Tote“ läuft vorbei), er war selbst dort, der Beschuldigte widerspricht,
##     zwei Freunde vergleichen, die Wahrheit kommt heraus (expose_at). Dann ist er sauer, sagt es, erzählt es Freunden
##     und glaubt dir einen Tag lang nichts.
##   · Haltungen verfallen nach STANCE_TIME; „vorsichtig“ und „sorglos“ wirken in Guest (Tagesablauf, Flackern, Hören),
##     „misstraut“ in GuestPals.are_pals.
##   · Weitererzählen: Wer eine Geschichte glaubt, erzählt sie Freunden, die er trifft – höchstens MAX_HOPS weit, die
##     Angst nach dem Tratsch des Erzählers und je Station halb so stark (Freundesnetz, 6.18, 1; GuestPals.net_strength).
## Gespeichert: log, Zähler, Verdacht nach Einbrüchen (social.talk); je Gast claims und stances.

## Beziehungsbudget (6.18, 5): so viele freundliche Gesten am Spieltag zählen voll (Plaudern, Beruhigen, Monster-Gespräch,
## Telefon, Anlässe zusammen), jede weitere nur noch zu diesem Anteil
const FULL_PER_DAY := 2
const OVER_BUDGET := 0.15
## Gesprächsbereitschaft (6.18, 5; entschieden 2026-11-03): so viele Gespräche am Spieltag (Gespräch und Telefon
## zusammen) – ab „nett“, bei Kindern und ab „verfeindet“ (nur Entschuldigen) ohne Grenze. Verärgerte brechen nach
## SHORT_TALK Antworten ab.
const TALKS_PER_DAY := {Social.Tier.ANGRY: 2, Social.Tier.ANNOYED: 2, Social.Tier.NEUTRAL: 4}
const SHORT_TALK := 3
const BUSY_LINES := ["Ich hab zu tun.", "Nicht schon wieder. Ich hab zu tun.", "Jetzt nicht. Ich hab zu tun."]

## Geschichten über Spuk (mit Ort) und über Funde – Spieler-Erlebnisse und Lügen
const SPOOK := ["monster", "ghost", "pumpkin"]
const STORIES := ["monster", "ghost", "pumpkin", "corpse", "blood", "ghost_visit", "attic"]
## Was ein Gast selbst erlebt haben muss, um „Du auch?!“ zu sagen (Guest.remembers)
const SAME_EXPERIENCE := {"monster": "monster", "ghost": "ghost", "ghost_visit": "ghost", "pumpkin": "pumpkin",
	"corpse": "corpse", "blood": "blood"}
## So viele eigene Erlebnisse merkt sich der Spieler, so viele Aussagen ein Gast
const MAX_LOG := 12
const MAX_CLAIMS := 12
## Dieselbe Sichtung zählt erst nach so vielen Sekunden als neues Erlebnis; so weit und so oft wird geschaut
const SIGHT_AGAIN := 120.0
const SIGHT_RANGE := 30.0
const FIND_RANGE := 7.0
const SCAN_EVERY := 0.4
## Haltungen gelten so lange (Spielzeit), „glaubt dir nichts“ nach einer aufgeflogenen Lüge ebenso
const STANCE_TIME := Calendar.DAY_SECONDS
## Geglaubte Geschichte: so viel Angst (× (1,2 − Mut)), Kinder × CHILD_FEAR
const STORY_FEAR := 18.0
const CHILD_FEAR := 1.3
## Aufgeflogen: so viel Beziehung (schwere Lügen – über Menschen und „da war nichts“ – mehr), weitererzählt an Freunde
const EXPOSED := -12.0
const EXPOSED_HEAVY := -20.0
const EXPOSED_PALS := -4.0
const SEEN_THROUGH := -5.0
## Wahrheit kommt raus („da war nichts“, aber jemand ist gestorben): nach so vielen Sekunden
const TRUTH_DELAY := Vector2(60.0, 180.0)
## Gegenbeweis: so nah muss der „Tote“ kommen; der Beschuldigte widerspricht aus dieser Nähe
const ALIVE_RANGE := 8.0
const DENY_RANGE := 3.0
## Weitererzählen (wie GuestPals): so nah, so oft geschaut, höchstens so viele Schritte vom Spieler weg
const TELL_RANGE := 3.2
const TELL_SCAN := 1.5
const MAX_HOPS := 2
## Fragen der Gäste: so oft fragt er zu Beginn eines Gesprächs (nach Stufe), Versprechen eines Kindes gilt so lange
const ASK_CHANCE := {Social.Tier.NEUTRAL: 0.25, Social.Tier.NICE: 0.35, Social.Tier.FRIENDLY: 0.45, Social.Tier.FRIEND: 0.55,
	Social.Tier.GOOD_FRIEND: 0.6}
const PROMISE_TIME := 6.0 * Calendar.HOUR
const PROMISE_KEPT := 6.0
const PROMISE_BROKEN := -10.0
## Heimbringen (er hält dich für mutig): ab dieser Angst fragt er
const ESCORT_FEAR := 35.0

## Ein Ding als Akkusativ/Nominativ (für Gerüchte und Antworten)
const THING := {"monster": "das Monster", "ghost": "das Gespenst", "pumpkin": "den Kürbismann", "ghost_visit": "etwas in Zimmer 13",
	"attic": "etwas auf dem Dachboden", "blood": "Blut", "corpse": "eine Leiche"}
## Was der Spieler erzählt (Knopf): {zone}, {who}
const TELL_LABEL := {
	"monster": "Ich hab das Monster gesehen – bei {zone}!",
	"ghost": "Hast du das Gespenst gesehen? Bei {zone}!",
	"pumpkin": "Da war ein Mann mit Kürbiskopf – bei {zone}!",
	"corpse": "Ich hab {who} gefunden … tot. Bei {zone}.",
	"blood": "Bei {zone} ist überall Blut!",
	"ghost_visit": "Heute Nacht war etwas bei mir im Zimmer.",
	"attic": "Auf dem Dachboden hat mich etwas herumgedreht.",
	"thief": "{who} hat geklaut. Ich hab's gesehen.",
}
## Lügen: was man erfinden kann (danach wer bzw. wo)
const LIE_LABEL := {"ghost": "… ich hab das Gespenst gesehen", "monster": "… ich hab das Monster gesehen",
	"pumpkin": "… ich hab den Kürbismann gesehen", "corpse": "… ich hab eine Leiche gefunden", "thief": "… jemand hat geklaut"}
## Reaktionen nach Charakter (Talk.temper): glaubt es, glaubt es nicht
const BELIEVE := {
	"ängstlich": ["Nein … nein! Ich geh heute nicht mehr raus.", "Ich wusste es. Ich wusste, dass hier etwas ist."],
	"Plaudertasche": ["Echt jetzt?! Das muss ich sofort den anderen erzählen!", "Bei {zone}? Wahnsinn. Wer weiß das noch?"],
	"Bastler": ["Gruselig … ich bleib heute lieber in der Nähe meiner Tür.", "Das glaub ich dir. Hier stimmt was nicht."],
	"geschäftstüchtig": ["Hm. Dann pass ich auf meine Sachen auf.", "Gut zu wissen. Die Gegend meide ich."],
	"Griesgram": ["Na wunderbar. Noch ein Grund, im Zimmer zu bleiben.", "Hab ich doch gesagt. Dieses Hotel."],
	"Skeptiker": ["Wenn du das sagst … ich seh mir das an. Vorsichtig.", "Hm. Dafür gibt es sicher eine Erklärung. Aber gut."],
	"Kind": ["Echt?! Ich hab Angst … ich will zu {eltern}!", "Wirklich? Ein echtes? Uuuh …"],
}
const DOUBT := {
	"Skeptiker": ["Du hast zu viel Punsch getrunken.", "Ein Vorhang im Wind. Mehr nicht."],
	"Griesgram": ["Erzähl das jemand anderem.", "Hmpf. Märchen."],
	"geschäftstüchtig": ["Und was willst du dafür? Nein, danke."],
	"": ["Ich weiß nicht … das klingt ziemlich weit hergeholt.", "Bist du sicher? Im Dunkeln sieht man viel."],
}
const SHARED := ["Du auch?! Ich dachte schon, ich werd verrückt.", "Dann hab ich es mir nicht eingebildet …",
	"Ich hab es auch gesehen! Gott sei Dank, ich dachte, keiner glaubt mir."]
const NOT_AGAIN := "Nicht schon wieder so eine Geschichte."
const NO_TRUST := "Du hast mich schon mal angelogen. Warum sollte ich dir jetzt glauben?"
const SEEN_THROUGH_LINES := ["Das glaub ich dir nicht. Warum erzählst du so was?", "Lüg mich nicht an."]
const WAS_THERE := "Bei {zone}? Da bin ich doch gerade! Da ist nichts."
const CONTRADICTION := "Du hast doch gesagt, du glaubst nicht an Geister! "
const CORPSE_BELIEVE := ["{who}?! Nein … das kann nicht sein …", "{who} … tot? *wird blass*"]
const CORPSE_PAL := ["*weint* {who} … wir haben doch erst gestern zusammen gelacht.", "{who}? Nein! Nicht {who} …"]
const THIEF_BELIEVE := ["{who}? Das hätte ich nicht gedacht. Ich pass auf.", "{who} also. Na warte."]
const THIEF_DOUBT := ["{who}? Niemals. {who} ist mein Freund.", "Das glaub ich nicht. Nicht {who}."]
## Aufgeflogen – was er sagt (dort, wo es passiert) und womit er dich beim nächsten Gespräch empfängt
const EXPOSED_LINES := {
	"alive": "{who} lebt! Ich hab {who} gerade gesehen. Warum erzählst du so was?!",
	"denied": "{who} sagt, das stimmt nicht. Und ich glaube {who}.",
	"compare": "Du hast {other} was ganz anderes erzählt als mir. Was soll das?",
	"truth": "„Da war nichts“, hast du gesagt. Und jetzt ist jemand tot.",
	"there": WAS_THERE,
}
const CONFRONT := ["Du hast mich angelogen. Ich red nicht gern mit Lügnern.", "Ach, du. Erzählst du mir wieder Märchen?",
	"Weißt du, was ich nicht mag? Wenn man mich anlügt."]
const RUMOR := {
	"spook": ["Hast du's gehört? Zimmer 13 hat bei {zone} {thing} gesehen!", "Zimmer 13 hat {thing} gesehen. Bei {zone}. Ehrlich!"],
	"corpse": ["{who} soll tot sein … bei {zone}.", "Hast du's gehört? {who} … *flüstert*"],
	"thief": ["Pass auf deine Sachen auf. {who} soll geklaut haben.", "Weißt du, was man über {who} sagt?"],
	"other": ["Hast du's gehört? Zimmer 13 hat was erlebt …", "Es geht was um im Haus. Zimmer 13 hat's erzählt."],
}
const RUMOR_REPLY := ["Was?! Echt?", "Oh nein …", "Hör auf, mir Angst zu machen.", "Das glaub ich erst, wenn ich's sehe."]

## Eigene Erlebnisse des Spielers: {id, kind, zone, who (Gast-ID bei Leichen), at}
var log: Array[Dictionary] = []
## Zimmer → true: dort wurde (ungesehen) eingebrochen – die Bewohner fragen nach (Frage „room“)
var suspects := {}
## Zeitpunkte von Todesfällen (für „Hast du letzte Nacht was gehört?“)
var deaths: Array[float] = []
var _next_id := 1
var _seen_finds := {}      ## sight_key → true: Funde, die schon im Log stehen (nicht gespeichert, einmal je Fund)
var _scan := SCAN_EVERY
var _expose_scan := 1.0
var _tell_scan := TELL_SCAN
var _queue: Array[Dictionary] = []   ## {guest, amount, delay} – Freunde erfahren von einer Lüge
var _doubted := {}         ## Gast-ID → Tag, an dem er zuletzt eine Geschichte nicht geglaubt hat
var debug_answer := -1     ## --gespraech=frage,…,n: diese Antwort gleich wählen


func _now() -> float:
	return Game.director.elapsed if Game.director else 0.0


## Charakter für Reaktionen: Archetyp (erzeugte Gäste), „Kind“, sonst aus den Werten der festen Gäste.
static func temper(g: Guest) -> String:
	if g.is_child():
		return "Kind"
	var arche := String(g.profile.get("archetype", ""))
	if arche != "":
		return arche
	if float(g.profile["brave"]) < 0.35:
		return "ängstlich"
	if float(g.profile["gossip"]) >= 0.8:
		return "Plaudertasche"
	if float(g.profile.get("reliable", 0.7)) >= 0.85:
		return "Skeptiker"
	if float(g.profile["greed"]) >= 0.7:
		return "geschäftstüchtig"
	return "Bastler"


func _fill(text: String, g: Guest, extra: Dictionary = {}) -> String:
	var keys := extra.duplicate()
	if g.is_child() and not keys.has("eltern"):
		keys["eltern"] = "Mama" if GuestProfiles.get_profile(String(g.profile.get("parent", ""))).get("sex", "m") == "f" else "Papa"
	return text.format(keys)


# --- Erlebnisse des Spielers ------------------------------------------------------------------

## Ein Erlebnis des Spielers merken (Spielkonzept 6.9). who: Gast-ID (Leiche).
func note(kind: String, pos: Vector3, who: String = "") -> void:
	var now := _now()
	for i in range(log.size() - 1, -1, -1):
		var e := log[i]
		if e["kind"] == kind and e["who"] == who and now - float(e["at"]) < SIGHT_AGAIN:
			return
	var zone := Game.director.zone_name_at(pos) if Game.director else ""
	log.append({"id": _next_id, "kind": kind, "zone": zone, "who": who, "at": now})
	_next_id += 1
	if log.size() > MAX_LOG:
		log.pop_front()
	if Game.tracing:
		print("[Gespräch] Erlebnis: %s bei %s" % [kind, zone])


## Frische Erlebnisse (heute), die dieser Gast noch nicht von dir gehört hat – das jüngste zuerst.
func untold(g: Guest) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var today := Calendar.today()
	for i in range(log.size() - 1, -1, -1):
		var e := log[i]
		if Calendar.day_of(float(e["at"])) != today or not _claim_of(g, int(e["id"])).is_empty():
			continue
		if e["kind"] == "corpse" and String(e["who"]) == g.id:
			continue
		result.append(e)
	return result


## Knopftext für ein Erlebnis (oder eine erfundene Geschichte).
func tell_label(story: Dictionary) -> String:
	var who := Game.social.guest_name(String(story.get("who", "")))
	var zone := String(story.get("zone", ""))
	var text := String(TELL_LABEL.get(story["kind"], "Mir ist was passiert …")).format({"zone": zone if zone != "" else "hier", "who": who})
	return Game.leviathan_name.name_for(text, Game.leviathan_name.player_knows) if Game.leviathan_name else text


func _scan_sights() -> void:
	var p := Game.player
	if p == null or p.dead or p.sleeping or Game.director == null:
		return
	if Game.monster and Game.monster.is_active():
		_check_sight("monster", Game.monster, 1.6)
	if Game.ghost and Game.ghost.is_active():
		_check_sight("ghost", Game.ghost, 1.0)
		if Game.ghost.with_player():
			note("ghost_visit", p.global_position)
	if Game.pumpkin and Game.pumpkin.in_house():
		_check_sight("pumpkin", Game.pumpkin, 1.5)
	for node in get_tree().get_nodes_in_group("shock_sights"):
		var sight := node as Node3D
		if sight == null or not sight.has_meta("sight_key"):
			continue
		var key := String(sight.get_meta("sight_key"))
		if _seen_finds.has(key) or sight.global_position.distance_to(p.global_position) > FIND_RANGE:
			continue
		if not Game.director.player_can_see(sight.global_position + Vector3.UP * 0.3):
			continue
		_seen_finds[key] = true
		var kind := String(sight.get_meta("sight_kind", "blood"))
		note(kind, sight.global_position, (sight as Guest).id if sight is Guest else "")


func _check_sight(kind: String, threat: Node3D, height: float) -> void:
	if not threat.is_visible_in_tree():
		return
	var at := threat.global_position + Vector3.UP * height
	if at.distance_to(Game.player.camera.global_position) <= SIGHT_RANGE and Game.director.player_can_see(at):
		note(kind, threat.global_position)


# --- Gedächtnis -------------------------------------------------------------------------------

func _claim(topic: String, extra: Dictionary = {}) -> Dictionary:
	var c := {"topic": topic, "zone": "", "who": "", "lie": false, "at": _now(), "from": "player", "hops": 0, "src": 0,
		"spread": [], "exposed": false, "believed": true, "stance": "", "value": ""}
	c.merge(extra, true)
	return c


func _remember(g: Guest, claim: Dictionary) -> void:
	g.claims.append(claim)
	if g.claims.size() > MAX_CLAIMS:
		g.claims.pop_front()


## Die Aussage zu einem Erlebnis bzw. einer erfundenen Geschichte (src), sonst {}.
func _claim_of(g: Guest, src: int) -> Dictionary:
	for c: Dictionary in g.claims:
		if int(c["src"]) == src:
			return c
	return {}


## Letzte Aussage des Spielers zu einem Thema (Antworten: „ghost_belief“, „brave“ …), sonst {}.
func said(g: Guest, topic: String) -> Dictionary:
	for i in range(g.claims.size() - 1, -1, -1):
		var c: Dictionary = g.claims[i]
		if c["topic"] == topic and c["from"] == "player":
			return c
	return {}


## Freundliche Geste (Beziehungsbudget, 6.18, 5): zählt am Spieltag nur FULL_PER_DAY-mal voll – Plaudern, Beruhigen,
## Monster-Gespräch, Telefon und Anlässe zusammen; danach bringt sie kaum noch etwas. Am Morgen ist es wieder voll.
func friendly(g: Guest, amount: float) -> void:
	var today := Calendar.today()
	if g.chat_day != today:
		g.chat_day = today
		g.chats_today = 0
	g.chats_today += 1
	Game.social.change_relation(g, amount if g.chats_today <= FULL_PER_DAY else amount * OVER_BUDGET)


## Gesprächsbereitschaft (6.18, 5): so viele Gespräche hat er heute noch (-1 = ohne Grenze).
func talks_left(g: Guest) -> int:
	var limit := -1 if g.is_child() else int(TALKS_PER_DAY.get(Social.tier(g), -1))
	if limit < 0:
		return -1
	return maxi(0, limit - (g.talks_today if g.talk_day == Calendar.today() else 0))


## Ein Gespräch beginnt (von Angesicht oder am Telefon): false, wenn er heute schon genug mit dir geredet hat.
func start_talk(g: Guest) -> bool:
	if talks_left(g) == 0:
		return false
	var today := Calendar.today()
	if g.talk_day != today:
		g.talk_day = today
		g.talks_today = 0
	g.talks_today += 1
	return true


## Verärgerte (genervt, wütend) brechen nach SHORT_TALK Antworten ab („Ich hab zu tun.“, 6.18, 5).
static func cuts_short(g: Guest, steps: int) -> bool:
	return steps >= SHORT_TALK and not g.is_child() and Social.tier(g) in [Social.Tier.ANNOYED, Social.Tier.ANGRY]


# --- Erzählen und Lügen -----------------------------------------------------------------------

## Der Spieler erzählt ein Erlebnis (lie = false) oder erfindet eins. story: {kind, zone, who[, id]}. Gibt die Antwort.
func tell(g: Guest, story: Dictionary, lie: bool) -> String:
	var kind := String(story["kind"])
	var zone := String(story.get("zone", ""))
	var who_id := String(story.get("who", ""))
	var src := int(story.get("id", 0))
	if src == 0:
		src = _next_id
		_next_id += 1
	var keys := {"zone": zone if zone != "" else "hier", "who": Game.social.guest_name(who_id)}
	var claim := _claim(kind, {"zone": zone, "who": who_id, "lie": lie, "src": src})
	_remember(g, claim)
	if Game.tracing:
		print("[Gespräch] %s %s: %s bei %s" % ["Lüge an" if lie else "erzählt", g.display_name, kind, zone])
	# Er war selbst dort – und da war nichts (fliegt sofort auf)
	if lie and kind in SPOOK and zone != "" and Game.director.zone_name_at(g.global_position) == zone \
			and not g.remembers(String(SAME_EXPERIENCE.get(kind, kind))):
		claim["believed"] = false
		return expose(g, claim, "there", false)
	if g.has_stance("no_trust"):
		claim["believed"] = false
		return NO_TRUST
	if lie and randf() < _see_through(g, kind):
		claim["believed"] = false
		claim["exposed"] = true
		Game.social.change_relation(g, SEEN_THROUGH)
		g.set_stance("no_trust", STANCE_TIME * 0.5)
		if Game.tracing:
			print("[Gespräch] %s durchschaut die Lüge" % g.display_name)
		return SEEN_THROUGH_LINES.pick_random()
	var prefix := ""
	var belief := said(g, "ghost_belief")
	if kind in ["ghost", "ghost_visit"] and not belief.is_empty() and belief["value"] == "no":
		prefix = CONTRADICTION
	if not _believes(g, kind, who_id, prefix != ""):
		claim["believed"] = false
		var doubted_today := int(_doubted.get(g.id, 0)) == Calendar.today()
		_doubted[g.id] = Calendar.today()
		Game.social.change_relation(g, -3.0 if doubted_today else -1.0)
		if kind == "thief":
			return prefix + _fill(THIEF_DOUBT.pick_random(), g, keys)
		return prefix + (NOT_AGAIN if doubted_today else _fill((DOUBT.get(temper(g), DOUBT[""]) as Array).pick_random(), g, keys))
	return prefix + _believed(g, claim, keys)


## Er glaubt es: Angst, Haltung, Lauschen (4.7), Beziehung. Gibt seine Antwort.
func _believed(g: Guest, claim: Dictionary, keys: Dictionary) -> String:
	var kind := String(claim["topic"])
	var who := Game.social.guest_by_id(String(claim["who"]))
	if kind == "thief":
		if who:
			claim["stance"] = "distrusts:" + who.id
			g.set_stance(claim["stance"], STANCE_TIME)
		return _fill(THIEF_BELIEVE.pick_random(), g, keys)
	var shared := g.remembers(String(SAME_EXPERIENCE.get(kind, "-")))
	g.fear = minf(100.0, g.fear + STORY_FEAR * (1.2 - float(g.profile["brave"])) * (CHILD_FEAR if g.is_child() else 1.0))
	g.scared_by_player()
	claim["stance"] = "wary"
	g.clear_stance("careless")
	g.set_stance("wary", STANCE_TIME)
	if kind in ["monster", "ghost", "pumpkin", "ghost_visit"]:
		Game.social.on_monster_talk(g)   # das Monster hört mit (4.7)
	friendly(g, 5.0 if shared else 2.0)
	if g.is_child():
		var parent := g.parent_guest()
		if parent:   # Mama oder Papa finden das gar nicht gut
			_queue.append({"guest": parent, "amount": -3.0, "delay": randf_range(15.0, 40.0)})
	if shared:
		return SHARED.pick_random()
	if kind == "corpse" and who:
		if Game.social.pals.are_pals(g, who):
			g.fear = minf(100.0, g.fear + 20.0)
			return _fill(CORPSE_PAL.pick_random(), g, keys)
		return _fill(CORPSE_BELIEVE.pick_random(), g, keys)
	return _fill((BELIEVE[temper(g)] as Array).pick_random(), g, keys)


## Glaubt er die Geschichte? Kinder alles, Skeptiker nur Handfestes oder was sie selbst erlebt haben.
func _believes(g: Guest, kind: String, who_id: String, contradicted: bool) -> bool:
	if kind == "thief":
		var who := Game.social.guest_by_id(who_id)
		return who == null or not Game.social.pals.are_pals(g, who)
	if g.is_child():
		return true
	if g.remembers(String(SAME_EXPERIENCE.get(kind, "-"))):
		return true
	var chance: float = {"Skeptiker": 0.0, "Griesgram": 0.5, "geschäftstüchtig": 0.75}.get(temper(g), 0.9)
	if temper(g) == "Skeptiker" and kind in ["corpse", "blood"]:
		chance = 0.6
	if contradicted:
		chance *= 0.5
	return randf() < chance


## So oft durchschaut er eine Lüge sofort: Menschenkenntnis (perception beim Würfeln), Skeptiker mehr.
func _see_through(g: Guest, kind: String) -> float:
	var perception := float((g.profile.get("dice", {}) as Dictionary).get("perception", 0.3))
	var chance := perception * 0.5 + (0.2 if temper(g) == "Skeptiker" else 0.0)
	if kind == "thief":
		chance += 0.1
	return clampf(chance, 0.0, 0.6)


## Eine Lüge fliegt auf (how: alive, denied, compare, truth, there). Er ist sauer, sagt es (in Hörweite), erzählt es
## seinen Freunden und glaubt dir einen Tag lang nichts. speak = false: nur die Zeile zurückgeben (im Gespräch).
func expose(g: Guest, claim: Dictionary, how: String, speak: bool = true, other: Guest = null) -> String:
	if claim["exposed"]:
		return ""
	claim["exposed"] = true
	var heavy: bool = claim["topic"] in ["thief", "night", "room"]
	var amount := (EXPOSED_HEAVY if heavy else EXPOSED) * (1.0 if claim["from"] == "player" else 0.5)
	Game.social.change_relation(g, amount)
	if claim["stance"] != "":
		g.clear_stance(String(claim["stance"]))
	g.set_stance("no_trust", STANCE_TIME)
	g.set_stance("confront", STANCE_TIME * 2.0)
	var line := _fill(String(EXPOSED_LINES.get(how, SEEN_THROUGH_LINES[0])), g, {"zone": claim["zone"],
		"who": Game.social.guest_name(String(claim["who"])), "other": other.display_name if other else "jemand"})
	if speak:
		g.say(line)
	Game.social.pals.spread([g], EXPOSED_PALS)   # übers Freundesnetz (6.18, 1)
	if Game.tracing:
		print("[Gespräch] Lüge aufgeflogen (%s): %s – %s, Beziehung %.0f" % [how, g.display_name, claim["topic"], g.relation])
	return line


# --- Fragen der Gäste -------------------------------------------------------------------------

## Fragt er zu Beginn des Gesprächs etwas? {id, text, answers: [[key, Text], …]} oder {}. force: diese Frage (Debug).
func pick_question(g: Guest, force: String = "") -> Dictionary:
	var tier := Social.tier(g)
	if force == "":
		if g.fear >= 60.0 or tier < Social.Tier.NEUTRAL or g.wound != "":
			return {}
		if g.has_stance("brave_thinks") and g.fear >= ESCORT_FEAR and not g.is_following():
			return _question(g, "escort")
		if randf() >= float(ASK_CHANCE.get(tier, 0.25)):
			return {}
	var options: Array[String] = []
	if force != "":
		options.append(force)
	else:
		if said(g, "ghost_belief").is_empty():
			options.append("ghosts")
		if Game.director.first_attack_done and Calendar.phase() in [Calendar.Phase.MORNING, Calendar.Phase.DAY] \
				and not _asked_today(g, "night") and not g.is_child():
			options.append("night")
		if Game.contest and Game.contest.stage == DoorContest.Stage.CONTEST and said(g, "contest").is_empty() and not g.is_child():
			options.append("contest")
		if suspects.has(String(g.home["no"])) and not _asked_today(g, "room") and not g.is_child():
			options.append("room")
		if said(g, "brave").is_empty() and not g.is_child() and (g.fear >= 20.0 or Game.director.first_attack_done):
			options.append("brave")
		if g.is_child() and not _asked_today(g, "play") and not g.has_stance("promise"):
			options.append("play")
	if options.is_empty():
		return {}
	return _question(g, options.pick_random())


func _asked_today(g: Guest, topic: String) -> bool:
	var c := said(g, topic)
	return not c.is_empty() and Calendar.day_of(float(c["at"])) == Calendar.today()


func _question(g: Guest, id: String) -> Dictionary:
	match id:
		"ghosts":
			return {"id": id, "text": "Glaubst du an Gespenster?" if g.is_child() else "Sag mal … glaubst du an Geister?",
				"answers": [["yes", "Ja. Hier im Haus sowieso."], ["no", "Nein. Das sind Geschichten."], ["unsure", "Ich weiß es nicht."]]}
		"night":
			return {"id": id, "text": "Hast du letzte Nacht was gehört?",
				"answers": [["bad", "Ja – es war unheimlich. Pass auf dich auf."], ["nothing", "Ach, da war nichts."],
					["slept", "Ich hab geschlafen."]]}
		"contest":
			var rival := _random_other(g)
			return {"id": id, "text": "Was meinst du – wer gewinnt den Türschmuck?", "rival": rival.id if rival else "",
				"answers": [["you", "Du natürlich!"], ["me", "Ich!"]] + ([["rival", "%s." % rival.display_name]] if rival else [])}
		"room":
			return {"id": id, "text": "Jemand war in meinem Zimmer. Die Tür ist kaputt. Warst du das?",
				"answers": [["confess", "Ja … tut mir leid."], ["deny", "Nein, wirklich nicht."], ["excuse", "Die Tür war schon offen."]]}
		"brave":
			return {"id": id, "text": "Hast du eigentlich keine Angst hier?",
				"answers": [["fearless", "Nein. Ich hab keine Angst."], ["afraid", "Doch. Ganz schön."]]}
		"play":
			return {"id": id, "text": "Spielst du mit mir?",
				"answers": [["later", "Später, versprochen!"], ["no", "Heute nicht."]]}
		"escort":
			return {"id": id, "text": "Bringst du mich zu meinem Zimmer? Du hast ja keine Angst …",
				"answers": [["yes", "Klar, komm mit."], ["no", "Gerade nicht."]]}
	return {}


func _random_other(g: Guest) -> Guest:
	var others := Game.social.pals.pals_of(g).filter(func(o: Guest) -> bool: return not o.is_child())
	if others.is_empty():
		others = Game.social.living_guests().filter(func(o: Guest) -> bool: return o != g and not o.is_child())
	return others.pick_random() if not others.is_empty() else null


## Antwort auf seine Frage: merkt sie sich, setzt Haltungen, gibt seine Reaktion. after: "follow" – er kommt mit
## (DialogUI schließt dann), sonst "".
func answer(g: Guest, question: Dictionary, key: String) -> Dictionary:
	var id := String(question["id"])
	var t := temper(g)
	var claim := _claim(id, {"value": key})
	_remember(g, claim)
	var line := ""
	var after := ""
	match id:
		"ghosts":
			var believer := t in ["ängstlich", "Plaudertasche", "Bastler", "Kind"] or g.remembers("ghost")
			var same := (key == "yes" and believer) or (key == "no" and not believer)
			if key == "unsure":
				line = "Ehrlich. Das gefällt mir." if t != "Kind" else "Ich auch nicht …"
				friendly(g, 1.0)
			elif same:
				line = ("Endlich jemand, der mir glaubt!" if believer else "Eben. Ein vernünftiger Mensch.")
				friendly(g, 4.0)
			else:
				line = ("Wie kannst du das sagen – nach allem, was hier passiert?" if believer else "Ach komm. Geister. Wirklich?")
				Game.social.change_relation(g, -1.0)
		"night":
			var happened := _night_had_events()
			if key == "bad":
				claim["lie"] = not happened
				claim["stance"] = "wary"
				g.clear_stance("careless")
				g.set_stance("wary", STANCE_TIME)
				g.fear = minf(100.0, g.fear + 10.0 * (1.2 - float(g.profile["brave"])))
				g.scared_by_player()
				line = "Ich wusste es. Ich bleib heute in der Nähe meines Zimmers." if t != "Skeptiker" else "Hm. Gut zu wissen."
				friendly(g, 2.0)
			elif key == "nothing":
				claim["lie"] = happened
				claim["stance"] = "careless"
				g.clear_stance("wary")
				g.set_stance("careless", STANCE_TIME)
				g.fear = maxf(0.0, g.fear - 10.0)
				line = "Gut. Dann hab ich mir das nur eingebildet."
				if happened:   # jemand ist gestorben – das spricht sich herum
					claim["expose_at"] = _now() + randf_range(TRUTH_DELAY.x, TRUTH_DELAY.y)
			else:
				line = "Schön für dich. Ich hab kaum ein Auge zugemacht."
		"contest":
			var proud := float((g.profile.get("dice", {}) as Dictionary).get("pride", 0.5))
			var sharp := float((g.profile.get("dice", {}) as Dictionary).get("perception", 0.3))
			if key == "you":
				if sharp > 0.45 and proud < 0.6:
					line = "Schmeichler. Aber danke."
				else:
					line = "Ach, findest du? *strahlt*"
					friendly(g, 3.0 + 3.0 * proud)
			elif key == "me":
				line = "Na, wir werden sehen." if proud < 0.6 else "Du? Mit der Tür? Träum weiter."
				Game.social.change_relation(g, -1.0 if proud < 0.6 else -3.0)
			else:
				var rival := Game.social.guest_by_id(String(question.get("rival", "")))
				claim["who"] = rival.id if rival else ""
				if rival and Game.social.pals.are_pals(g, rival):
					line = "%s? Ja, das gönn ich %s." % [rival.display_name, rival.display_name]
					friendly(g, 2.0)
				elif rival and Game.social.pals.are_feuding(g, rival):
					line = "%s? Bloß nicht." % rival.display_name
					Game.social.change_relation(g, -3.0)
				else:
					line = "%s? Hm. Kann sein." % (rival.display_name if rival else "Der")
		"room":
			if key == "confess":
				suspects.erase(String(g.home["no"]))
				Game.social.change_relation(g, -4.0)
				line = "… Immerhin bist du ehrlich. Mach das nie wieder."
			else:
				claim["lie"] = true
				suspects.erase(String(g.home["no"]))   # einmal gefragt – geglaubt oder nicht
				var chance := _see_through(g, "room") + (0.15 if key == "excuse" else 0.0)
				if randf() < chance:
					expose(g, claim, "seen", false)
					line = SEEN_THROUGH_LINES.pick_random()
				else:
					line = "Hm. Dann war es wohl jemand anderes." if key == "deny" else "Offen? Ich hab sie abgeschlossen … komisch."
		"brave":
			if key == "fearless":
				claim["stance"] = "brave_thinks"
				g.set_stance("brave_thinks", STANCE_TIME * 2.0)
				line = "Wirklich? Dann weiß ich ja, an wen ich mich halte."
				friendly(g, 1.0)
			else:
				line = "Gut, dass ich nicht allein bin." if t in ["ängstlich", "Kind"] else "Ehrlich. Das mag ich."
				friendly(g, 4.0 if t == "ängstlich" else 2.0)
		"play":
			if key == "later":
				claim["stance"] = "promise"
				g.set_stance("promise", PROMISE_TIME, {"games": Game.social.deed(g, "games")})
				line = "Versprochen? Juhu! Ich warte auf dich."
				friendly(g, 2.0)
			else:
				Game.social.change_relation(g, -3.0)
				line = "Menno."
		"escort":
			g.clear_stance("brave_thinks")
			if key == "yes":
				friendly(g, 4.0)
				line = "Danke … ich bleib dicht hinter dir."
				after = "follow"
			else:
				Game.social.change_relation(g, -6.0)
				line = "Ich dachte, du hast keine Angst."
	if Game.tracing:
		print("[Gespräch] %s fragt „%s“ – Antwort %s%s" % [g.display_name, id, key, " (gelogen)" if claim["lie"] else ""])
	return {"line": line, "after": after}


## Ist seit dem Ende der letzten Nachtruhe etwas Schlimmes geschehen (Todesfall, eigene Sichtung)?
func _night_had_events() -> bool:
	var since := _now() - 0.6 * Calendar.DAY_SECONDS
	for t in deaths:
		if t >= since:
			return true
	for e in log:
		if float(e["at"]) >= since:
			return true
	return false


## Gesprächsbeginn: Was er zuerst sagt, weil er sich an dich erinnert ("" = nichts) – aufgeflogene Lüge, Versprechen.
func greeting(g: Guest) -> String:
	if g.has_stance("confront"):
		g.clear_stance("confront")
		return CONFRONT.pick_random()
	if g.has_stance("promise"):
		return "Spielen wir jetzt? Du hast es versprochen!"
	if g.has_stance("promise_broken"):
		g.clear_stance("promise_broken")
		return "Du hast versprochen, mit mir zu spielen! Du hast es vergessen."
	if g.has_stance("saw_break_in"):   # Zeuge eines Einbruchs bei 13 (6.19, ZIM-54): er nennt den Namen
		var who := Game.social.guest_name(String(g.stances["saw_break_in"].get("who", "")))
		g.clear_stance("saw_break_in")
		if Game.notebook:
			Game.notebook.add_note("break_in:" + who, "%s ist in Zimmer 13 eingebrochen." % who, g.display_name)
		return "Ich hab gesehen, wer bei dir eingebrochen ist: %s! Mit dem bin ich fertig." % who
	if g.has_stance("lock_swapped"):   # Zweitschlüssel zurück (6.19, ZIM-54)
		var line := String(g.stances["lock_swapped"].get("line", ""))
		g.clear_stance("lock_swapped")
		return line
	if g.has_stance("envy"):
		g.clear_stance("envy")   # Neid auf Zimmer 13 (6.18, 5): der spitze Satz einmal am Tag
		return Social.ENVY_LINES.pick_random()
	return ""


# --- Sag mal … ---------------------------------------------------------------------------------

## „Was hältst du von …?“ – wen er nennen kann: seine Freunde und wer in der Nähe ist (höchstens limit).
func opinion_names(g: Guest, limit: int = 6) -> Array[Guest]:
	var result: Array[Guest] = []
	for o in Game.social.pals.pals_of(g):
		if result.size() < limit - 2:
			result.append(o)
	var near := Game.social.living_guests().filter(func(o: Guest) -> bool:
		return o != g and not o in result and o.global_position.distance_to(g.global_position) < 12.0)
	near.sort_custom(func(a: Guest, b: Guest) -> bool:
		return a.global_position.distance_squared_to(g.global_position) < b.global_position.distance_squared_to(g.global_position))
	for o: Guest in near:
		if result.size() >= limit:
			break
		result.append(o)
	return result


## Was er von other hält – und ein Hinweis, wie other tickt und wie other zu dir steht.
func opinion(g: Guest, other: Guest) -> String:
	var name := other.display_name
	var first := ""
	if g.has_stance("distrusts:" + other.id):
		first = "%s? Dem trau ich nicht mehr. Du weißt ja, warum." % name
	elif Game.social.quarrels.stole_from(other, g):   # Streit nach einem Diebstahl (6.16)
		first = "%s? Hat mir Deko von der Tür geklaut. Mit %s bin ich fertig." % [name, name]
	elif Game.social.pals.are_feuding(g, other):
		first = "%s? Sprich mir nicht von %s." % [name, name]
	elif other.parent_guest() == g or g.parent_guest() == other or g.housemate_of(other):
		first = "Wir wohnen zusammen. %s ist manchmal anstrengend, aber ich hab %s gern." % [name, name]
	elif Game.social.pals.are_pals(g, other):
		first = ["%s? Gute Seele. Wir verstehen uns.", "%s ist in Ordnung. Wir haben schon einiges zusammen gemacht."].pick_random() % name
	else:
		first = ["%s? Kenn ich kaum.", "%s? Hab nur mal Hallo gesagt."].pick_random() % name
	var hint: String = {
		"ängstlich": "Ich glaube, %s hat vor allem Angst.", "Skeptiker": "%s glaubt nur, was %s selbst sieht.",
		"Plaudertasche": "Erzähl %s nichts, was nicht alle wissen sollen.", "Griesgram": "%s ist immer schlecht gelaunt.",
		"geschäftstüchtig": "Bei %s hat alles seinen Preis.", "Bastler": "%s bastelt den ganzen Tag.",
		"Kind": "%s ist süß. Und erzählt alles weiter.",
	}.get(temper(other), "")
	var about_you := ""
	var tier := Social.tier(other)
	if tier >= Social.Tier.FRIEND:
		about_you = " %s redet gut über dich." % name
	elif tier <= Social.Tier.ANGRY:
		about_you = " %s ist nicht gut auf dich zu sprechen." % name
	var middle := (" " + (hint.replace("%s", name))) if hint != "" and randf() < 0.7 else ""
	return first + middle + about_you


## „Was hast du heute noch vor?“ – wo er nachher und heute Abend am ehesten ist, und welches Zimmer seins ist.
func plans(g: Guest) -> String:
	var place := {"room": "in meinem Zimmer", "lobby": "in der Lobby", "kitchen": "in der Küche", "bar": "an der Bar",
		"garden": "im Garten", "wander": "mal hier, mal da"}
	var room := "Mein Zimmer ist die %s." % String(g.home["sign"])
	if g.has_stance("wary"):
		return "Ich bleib heute in meinem Zimmer. Tür zu. " + room
	var phase := Calendar.phase()
	var now_top := _top(g.activity_weights(phase))
	if phase == Calendar.Phase.EVENING or phase == Calendar.Phase.NIGHT:
		return "Nachher bin ich wohl %s. Und dann ab ins Bett. %s" % [place.get(now_top, "irgendwo"), room]
	var evening := _top(g.activity_weights(Calendar.Phase.EVENING))
	if g.has_stance("careless"):
		return "Ein bisschen herumlaufen. Ist ja nichts los. Heute Abend %s. %s" % [place.get(evening, "irgendwo"), room]
	return "Nachher bin ich wohl %s. Heute Abend %s. %s" % [place.get(now_top, "irgendwo"), place.get(evening, "irgendwo"), room]


func _top(weights: Dictionary) -> String:
	var best := ""
	var best_w := -1.0
	for key in weights:
		if float(weights[key]) > best_w:
			best_w = float(weights[key])
			best = key
	return best


## „Was weißt du über Zimmer 13?“ (Schicht 1 des Geheimnisses, 2.3)
func room13(g: Guest) -> String:
	if g.id == "edna":
		return "Ich komme seit Jahren jeden Oktober her. Die 13 war nie belegt. Nie. Bis du kamst."
	return String({
		"ängstlich": "Zimmer 13? Ich geh da nicht mal vorbei. Früher war die Tür immer zu.",
		"Plaudertasche": "Man sagt, wer in der 13 wohnt, bleibt länger, als er wollte. Hat mir jemand erzählt!",
		"Skeptiker": "Eine Zahl. Abergläubische Hotels lassen sie aus. Dieses nicht. Interessant.",
		"Griesgram": "Die 13. Natürlich hat man dich da reingesteckt.",
		"Bastler": "Die Nummer an deiner Tür ist älter als die anderen. Messing, von Hand gegossen.",
		"geschäftstüchtig": "Die 13 ist das billigste Zimmer im Haus. Hat wohl einen Grund.",
		"Kind": "In der 13 wohnt ein Gespenst! Sagen die Großen. Wohnst du da?!",
	}.get(temper(g), "Keine Ahnung. Nur, dass sie nie jemand haben wollte."))


## „Wie gefällt dir meine Tür?“ (Türschmuck, 2.5): die Deko vor Zimmer 13 im Vergleich zu den bewohnten Zimmern.
func door_verdict(g: Guest) -> String:
	var director := Game.director
	var decos: Array = director._deco_items()
	var mine: float = director._deco_strength(director.player_door_front, decos)
	var total := 0.0
	var count := 0
	for no in director.inhabited_rooms():
		total += float(director._deco_strength(director.rooms[no]["door_front"], decos))
		count += 1
	var ratio := mine / maxf(0.5, total / maxf(1.0, count))
	if temper(g) == "Plaudertasche" and ratio >= 0.8:
		return "Deine Tür? Die schönste auf dem ganzen Flur! Das sag ich allen!"
	if ratio >= 1.3:
		return "Deine Tür? Die schönste auf dem Flur. Ehrlich."
	if ratio >= 0.8:
		return "Ganz nett. Da geht noch was."
	return "Ehrlich? Da hängt fast nichts. Pass auf, dass die Puppe nicht vor deiner Tür sitzt."


# --- Laufend ----------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if Game.game_over or Game.social == null or Game.director == null:
		return
	_scan -= delta
	if _scan <= 0.0:
		_scan = SCAN_EVERY
		_scan_sights()
	var i := _queue.size() - 1
	while i >= 0:
		var entry := _queue[i]
		entry["delay"] = float(entry["delay"]) - delta
		if float(entry["delay"]) <= 0.0:
			var g = entry["guest"]
			if is_instance_valid(g) and not g.dead:
				Game.social.change_relation(g, float(entry["amount"]))
			_queue.remove_at(i)
		i -= 1
	_expose_scan -= delta
	if _expose_scan <= 0.0:
		_expose_scan = 1.0
		_check_lies()
		_check_promises()
	_tell_scan -= delta
	if _tell_scan <= 0.0:
		_tell_scan = TELL_SCAN
		if not Game.social.sleep_active:
			_update_spread()


## Gegenbeweis, Widerspruch des Beschuldigten, die Wahrheit kommt raus.
func _check_lies() -> void:
	var now := _now()
	for node in Game.social.living_guests():
		var g: Guest = node
		for c: Dictionary in g.claims:
			if not c["lie"] or c["exposed"]:
				continue
			if c.has("expose_at") and now >= float(c["expose_at"]):
				expose(g, c, "truth")
				continue
			var who := Game.social.guest_by_id(String(c["who"]))
			if who == null or who.dead or g.is_asleep():
				continue
			var d := who.global_position.distance_to(g.global_position)
			if c["topic"] == "corpse" and d < ALIVE_RANGE and g.can_see_actor(who):
				expose(g, c, "alive")
			elif c["topic"] == "thief" and d < DENY_RANGE and not c.get("contested", false) and not who.is_asleep() \
					and who.state != Guest.State.TALKING:
				c["contested"] = true
				if Game.tracing:
					print("[Gespräch] %s trifft %s – widerspricht" % [g.display_name, who.display_name])
				if Game.social.pals.are_pals(g, who, true) or randf() < 0.5:
					who.say("Ich soll geklaut haben? Wer erzählt denn so was?")
					expose(g, c, "denied")


## Versprechen an ein Kind: gespielt (eine Partie mehr als beim Versprechen) oder die Zeit ist um.
func _check_promises() -> void:
	for node in Game.social.living_guests():
		var g: Guest = node
		g.prune_stances()
		if not g.stances.has("promise"):
			continue
		var s: Dictionary = g.stances["promise"]
		if Game.social.deed(g, "games") > int(s.get("games", 0)):
			g.clear_stance("promise")
			Game.social.change_relation(g, PROMISE_KEPT)
			g.say("Das war toll! Danke!")
		elif not g.has_stance("promise"):
			g.clear_stance("promise")
			Game.social.change_relation(g, PROMISE_BROKEN)
			g.set_stance("promise_broken", STANCE_TIME)
			var parent := g.parent_guest()
			if parent:
				Game.social.change_relation(parent, -3.0)
			if Game.tracing:
				print("[Gespräch] Versprechen an %s gebrochen" % g.display_name)


## Weitererzählen und Vergleichen unter Freunden (einer je Durchgang).
func _update_spread() -> void:
	var social := Game.social
	var now := _now()
	for node in social.living_guests():
		var a: Guest = node
		if not _free(a):
			continue
		for other in social.living_guests():
			var b: Guest = other
			if b == a or not _free(b) or b.global_position.distance_to(a.global_position) > TELL_RANGE:
				continue
			if not social.pals.are_pals(a, b):
				continue
			if _compare(a, b) or _try_pass(a, b, now):
				return


## a erzählt b eine Geschichte weiter, die b noch nicht kennt (eine, je nach Tratschfreude) – true, wenn erzählt.
func _try_pass(a: Guest, b: Guest, now: float) -> bool:
	for c: Dictionary in a.claims:
		if not c["believed"] or c["exposed"] or int(c["hops"]) >= MAX_HOPS or not (c["topic"] in STORIES or c["topic"] == "thief"):
			continue
		if now - float(c["at"]) > Calendar.DAY_SECONDS or b.id in c["spread"] or not _claim_of(b, int(c["src"])).is_empty():
			continue
		if c["topic"] == "thief" and c["who"] == b.id:
			continue
		if randf() > maxf(0.3, float(a.profile["gossip"])):
			c["spread"].append(b.id)   # behält es diesmal für sich
			continue
		c["spread"].append(b.id)
		_pass_on(a, b, c)
		return true
	return false


## Am Telefon (PhoneCalls, Spielkonzept 4.14): Freunde erzählen sich Geschichten über jede Entfernung – Gerüchte
## verbreiten sich so schneller als nur von Angesicht zu Angesicht. true, wenn a etwas weitererzählt hat.
func phone_spread(a: Guest, b: Guest) -> bool:
	return Game.social.pals.are_pals(a, b) and _try_pass(a, b, _now())


## Zwei Freunde merken, dass du ihnen dieselbe Sichtung an verschiedenen Orten erzählt hast.
func _compare(a: Guest, b: Guest) -> bool:
	for ca: Dictionary in a.claims:
		if ca["from"] != "player" or ca["exposed"] or not ca["topic"] in SPOOK:
			continue
		for cb: Dictionary in b.claims:
			if cb["from"] != "player" or cb["exposed"] or cb["topic"] != ca["topic"] or cb["zone"] == ca["zone"]:
				continue
			if not (ca["lie"] or cb["lie"]) or absf(float(ca["at"]) - float(cb["at"])) > Calendar.DAY_SECONDS:
				continue
			if ca["lie"]:
				expose(a, ca, "compare", true, b)
			if cb["lie"]:
				expose(b, cb, "compare", true, a)
			return true
	return false


func _pass_on(a: Guest, b: Guest, c: Dictionary) -> void:
	var topic := String(c["topic"])
	var group := "spook" if topic in SPOOK else ("corpse" if topic == "corpse" else ("thief" if topic == "thief" else "other"))
	var thing := String(THING.get(topic, "etwas"))
	if Game.leviathan_name:   # wer den Namen kennt, sagt ihn (4.32)
		thing = Game.leviathan_name.name_for(thing, Game.leviathan_name.knows(a))
	a.say(_fill((RUMOR[group] as Array).pick_random(), a, {"thing": thing,
		"zone": c["zone"] if c["zone"] != "" else "hier", "who": Game.social.guest_name(String(c["who"]))}))
	var copy := c.duplicate(true)
	copy["from"] = a.id
	copy["hops"] = int(c["hops"]) + 1
	copy["spread"] = [a.id]
	copy["at"] = _now()
	copy["believed"] = not b.has_stance("no_trust") and _believes(b, topic, String(c["who"]), false)
	copy["stance"] = ""
	_remember(b, copy)
	if copy["believed"]:
		if topic == "thief":
			copy["stance"] = "distrusts:" + String(c["who"])
			b.set_stance(copy["stance"], STANCE_TIME)
		else:
			# Stärke nach dem Tratsch des Erzählers, je Station halb so stark (6.18, 1)
			b.fear = minf(100.0, b.fear + STORY_FEAR * GuestPals.net_strength(a, int(copy["hops"])) * (1.2 - float(b.profile["brave"])))
			copy["stance"] = "wary"
			b.clear_stance("careless")
			b.set_stance("wary", STANCE_TIME)
	get_tree().create_timer(2.5, false).timeout.connect(func() -> void:
		if is_instance_valid(b) and not b.dead:
			b.say(RUMOR_REPLY.pick_random()))
	if Game.tracing:
		print("[Gespräch] %s erzählt %s weiter: %s%s" % [a.display_name, b.display_name, topic, "" if copy["believed"] else " (glaubt es nicht)"])


func _free(g: Guest) -> bool:
	return not g.dead and g.hiding == null and g.fear < 60.0 and g.state in [Guest.State.IDLE, Guest.State.WALK, Guest.State.PARTY]


# --- Ereignisse -------------------------------------------------------------------------------

## Ein Gast ist gestorben: Hatte er „sorglos“ von dir (Schuld, 6.8 – Schock und Schock-Schuld rechnet GuestDeaths)?
## Seine Freunde trauern; Lügen über seinen Tod sind jetzt wahr; wer „da war nichts“ gehört hat, erfährt bald die Wahrheit.
func on_guest_died(dead: Guest) -> void:
	deaths.append(_now())
	if deaths.size() > 20:
		deaths.pop_front()
	if dead.has_stance("careless") and Game.player:
		if Game.diary:
			Game.diary.note("careless_death", "Ich habe %s gesagt, da sei nichts. Jetzt ist %s tot." % [dead.display_name, dead.display_name],
				dead.id)
		if Game.tracing:
			print("[Gespräch] %s ist sorglos gestorben – Schuld" % dead.display_name)
	for pal in Game.social.pals.pals_of(dead):
		pal.set_stance("grieving", STANCE_TIME, {"who": dead.display_name})
	for node in Game.social.living_guests():
		var g: Guest = node
		for c: Dictionary in g.claims:
			if c["topic"] == "corpse" and c["who"] == dead.id:
				c["lie"] = false
			elif c["topic"] == "night" and c["lie"] and not c["exposed"] and not c.has("expose_at"):
				c["expose_at"] = _now() + randf_range(TRUTH_DELAY.x, TRUTH_DELAY.y)


## Ungesehen eingebrochen (RoomAccess.on_forced): Die Bewohner fragen beim nächsten Gespräch nach.
func on_break_in(no: String) -> void:
	suspects[no] = true


# --- Spielstand -------------------------------------------------------------------------------

func save_state() -> Dictionary:
	return {"log": log.duplicate(true), "next_id": _next_id, "suspects": suspects.keys(), "deaths": deaths.duplicate()}


func load_state(d: Dictionary) -> void:
	log.clear()
	for e: Dictionary in d.get("log", []):
		log.append({"id": int(e.get("id", 0)), "kind": String(e.get("kind", "")), "zone": String(e.get("zone", "")),
			"who": String(e.get("who", "")), "at": float(e.get("at", 0.0))})
	_next_id = int(d.get("next_id", 1))
	suspects = {}
	for no in d.get("suspects", []):
		suspects[String(no)] = true
	deaths.clear()
	for t in d.get("deaths", []):
		deaths.append(float(t))
	_seen_finds.clear()


## Je Gast (SaveManager): Aussagen und Haltungen in speicherbarer Form – JSON macht aus Zahlen float.
static func load_claims(list: Array) -> Array:
	var result: Array = []
	for c in list:
		var claim: Dictionary = (c as Dictionary).duplicate(true)
		claim["src"] = int(claim.get("src", 0))
		claim["hops"] = int(claim.get("hops", 0))
		result.append(claim)
	return result


# --- Debug ------------------------------------------------------------------------------------

## --gespraech=frage,id,gast[,n] · erlebnis,art,gast[,erzaehlen] · luege,art,gast[,wer] (Spielkonzept 6.9)
func debug(parts: PackedStringArray) -> void:
	var what := parts[0] if parts.size() > 0 else "frage"
	var g := Game.social.guest_by_id(parts[2] if parts.size() > 2 else "edna")
	if g == null:
		Game.say("Gast unbekannt", 3.0)
		return
	var main := get_tree().current_scene
	match what:
		"frage":
			var qid := parts[1] if parts.size() > 1 and parts[1] != "" else "ghosts"
			if qid == "night":
				Game.director.first_attack_done = true
			if qid == "room":
				suspects[String(g.home["no"])] = true
			if qid == "escort":
				g.set_stance("brave_thinks", STANCE_TIME)
				g.fear = 50.0
			debug_answer = int(parts[3]) - 1 if parts.size() > 3 else -1
			main.call("_debug_talk", g, qid)
		"erlebnis":
			var kind := parts[1] if parts.size() > 1 and parts[1] != "" else "ghost"
			note(kind, Game.player.global_position, "")
			debug_answer = 0 if parts.size() > 3 and parts[3] == "erzaehlen" else -1
			main.call("_debug_talk", g, "")
		"luege":
			var kind := parts[1] if parts.size() > 1 and parts[1] != "" else "ghost"
			kind = {"leiche": "corpse", "dieb": "thief", "geist": "ghost", "monster": "monster", "kuerbis": "pumpkin"}.get(kind, kind)
			var who := Game.social.guest_by_id(parts[3]) if parts.size() > 3 else null
			var zone := Game.social.random_zone_name() if kind != "thief" else ""
			var reply := tell(g, {"kind": kind, "zone": zone, "who": who.id if who else ""}, true)
			print("[Gespräch] %s antwortet: %s" % [g.display_name, reply])
			if who and kind in ["corpse", "thief"]:   # der „Tote“ bzw. Beschuldigte kommt vorbei
				get_tree().create_timer(3.0, false).timeout.connect(func() -> void:
					if is_instance_valid(who) and is_instance_valid(g):
						var front := -g.global_transform.basis.z
						who.global_position = g.global_position + front * 1.5
						who._set_idle(8.0)
						g._set_idle(8.0))
