class_name GuestDeaths
extends Node
## Jeder Tod hat eine Ursache (Spielkonzept 6.18, 2; 6.8; entschieden 2026-11-03, ZIM-160).
## - **Ursache:** Was der Spieler einem Gast antut, merkt sich `note` je Gast: ignoriertes Klopfen an Zimmer 13 (Social),
##   sein Telefon klingeln lassen (PhoneCalls), als Begleiter mitgenommen (Guest.start_follow), Licht in seinem Zimmer
##   ausgemacht (LightSwitch), Deko oder Birne geklaut (Social.on_player_took), dazu „sorglos“ aus einem Gespräch (Talk).
##   Stirbt er, sucht `on_guest_died` die frischeste Ursache, die noch gilt – daraus folgt die **Schuld** des Spielers.
## - **Wie lange:** Diebstahl, solange die Deko fehlt (ein Gegenstand mit Meta „taken_from“ liegt nicht wieder vor seiner
##   Tür); Klopfen, Telefon, Licht und Begleiten bis zum Ende derselben Nacht (6 Uhr); „sorglos“, solange die Haltung hält.
##   Stirbt er durch das Urteil der Puppe vor seiner Tür (5.5), ist das die Ursache – ohne Schuld (die Puppe legt nicht der
##   Spieler).
## - **Ein Wert:** Schock und Trauer sind eins (Player.shock): jeder Tod gibt SHOCK_BASE, ein Freund mehr (nach Beziehung),
##   Schuld SHOCK_GUILT dazu. Offene Schuld lässt den Schock langsamer verfliegen (GUILT_RECOVERY, Social._update_memorials),
##   bis eine Kerze vor seiner Tür brennt oder GUILT_DAYS Spieltage um sind.
## - **Halluzinationen** (Telefon, falsches Klopfen, Spiegel) tragen den Namen des zuletzt Gestorbenen (last_dead).
## - **Freunde erfahren es:** Wer die Ursache kennt – Zeugen der Tat (`note`) und der eigene Haushalt des Toten –, mag den
##   Spieler weniger, ein Freund des Toten stark (WITNESS_RELATION). Der gesprächigste von ihnen erzählt es übers
##   Freundesnetz (6.18, 1; GuestPals.spread_with_affected): seinen Freunden wie Klagen (NET_RELATION) und den Freunden des
##   Toten, auch wenn sie nicht seine sind (FRIEND_RELATION).
## - **Gedenken:** Brennt ein Licht des Spielers vor der Tür des Toten (honor), sinkt der Schock um HONOR_SHOCK, die Schuld
##   ist gesühnt und seine Freunde mögen den Spieler mehr (HONOR_RELATION) – je Toter einmal.
## Kind von Social, erreichbar über Game.social.deaths. Gespeichert: die Toten (records) und die offenen Ursachen (causes).

## Schock je Tod: Grundwert, bei Freunden dazu SHOCK_BOND × Beziehung/100 (0,5 … 1), bei Schuld SHOCK_GUILT
const SHOCK_BASE := 0.2
const SHOCK_BOND := 0.8
const SHOCK_GUILT := 0.35
## Offene Schuld: Schock verfliegt so viel langsamer; nach so vielen Spieltagen ohne Kerze verblasst sie
const GUILT_RECOVERY := 0.5
const GUILT_DAYS := 3
## Ende der Nacht (Uhr): bis dahin zählen Klopfen, Telefon, Licht und Begleiten
const NIGHT_END := 6.0
## Wer die Ursache kennt: Zeuge, der Freund des Toten war (bzw. sein Haushalt) · sonst ein Zeuge
const WITNESS_RELATION := -30.0
const KNOWER_RELATION := -10.0
## Übers Netz: an die Freunde des Erzählers (× Tratsch, je Station halb) · an die Freunde des Toten
const NET_RELATION := -10.0
const FRIEND_RELATION := -25.0
## Gedenken: ein Licht des Spielers so nah vor der Tür; so viel Schock weniger, so viel Beziehung für seine Freunde
const HONOR_RANGE := 2.5
const HONOR_SHOCK := 0.25
const HONOR_RELATION := 10.0
## Ursachen mit Schuld (Notizbuch, Tagebuch, Debug)
const CAUSE_TEXT := {"knock": "nicht aufgemacht, als er an Zimmer 13 klopfte", "phone": "sein Telefon klingeln lassen",
	"escort": "ihn mitgenommen", "light": "bei ihm das Licht ausgemacht", "theft": "ihm etwas weggenommen",
	"careless": "ihm gesagt, da sei nichts"}
const NIGHT_CAUSES := ["knock", "phone", "escort", "light"]

## Gast-ID → {Ursache → {at (Director.elapsed), until (-1: Diebstahl, solange die Deko fehlt), knowers (Gast-IDs)}}
var causes := {}
## Die Toten in der Reihenfolge ihres Todes: {id, name, day, at, cause ("" = keine), guilt, honored}
var records: Array[Dictionary] = []


## Der Spieler tut `victim` etwas an, das ihn das Leben kosten kann (Ursache, siehe CAUSE_TEXT). Wer ihn dabei sieht
## (und erkennt, 5.9), kennt die Ursache.
func note(victim: Guest, kind: String) -> void:
	if victim == null or victim.dead:
		return
	var now := _now()
	var knowers: Array = []
	var p := Game.player
	if p:
		for other in Game.social.living_guests():
			var g: Guest = other
			if g != victim and g.can_see_actor(p) and p.recognized_by(g):
				knowers.append(g.id)
	var list: Dictionary = causes.get(victim.id, {})
	list[kind] = {"at": now, "until": -1.0 if kind == "theft" else night_end(now), "knowers": knowers}
	causes[victim.id] = list
	if Game.tracing:
		print("[Ursache] %s: %s (bis %s)" % [victim.display_name, kind, "die Deko zurück ist" if kind == "theft"
			else Calendar.time_text(night_end(now))])


## Alle Bewohner von Zimmer `no` (Licht aus, Telefon).
func note_room(no: String, kind: String) -> void:
	if no == "" or no == LevelBuilder.PLAYER_ROOM:
		return
	for other in Game.social.living_guests():
		var g: Guest = other
		if String(g.home["no"]) == no:
			note(g, kind)


## Spielzeit, zu der die Nacht nach `at` endet (das nächste NIGHT_END Uhr).
static func night_end(at: float) -> float:
	var day := Calendar.raw_day_of(at)
	return Calendar.at(day if Calendar.hour_of(at) < NIGHT_END else day + 1, NIGHT_END)


## Fehlt ihm noch Deko, die der Spieler genommen hat (Meta „taken_from“, nicht wieder vor seiner Tür)?
func deco_missing(g: Guest) -> bool:
	var door_front: Vector3 = g.home["door_front"]
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if String(item.get_meta("taken_from", "")) == g.id and (item.is_held
				or item.global_position.distance_to(door_front) > HONOR_RANGE):
			return true
	return false


## Die Ursache, die bei seinem Tod noch gilt (die frischeste): {kind, knowers} – leer, wenn keine.
func cause_of(g: Guest) -> Dictionary:
	var now := _now()
	var best := {}
	var best_at := -INF
	var list: Dictionary = causes.get(g.id, {})
	for kind in list:
		var c: Dictionary = list[kind]
		var valid := deco_missing(g) if kind == "theft" else now <= float(c["until"])
		if valid and float(c["at"]) > best_at:
			best_at = float(c["at"])
			best = {"kind": kind, "knowers": c["knowers"]}
	if g.has_stance("careless") and best.is_empty():   # „da war nichts“ (6.9) – gilt, solange er es glaubt
		best = {"kind": "careless", "knowers": []}
	return best


## Social.on_guest_died: Ursache, Schuld, Schock und Trauer (ein Wert), und wer es weiß, erzählt es.
func on_guest_died(g: Guest) -> void:
	var cause := cause_of(g)
	var kind := String(cause.get("kind", ""))
	if kind == "" and Game.director and Game.director.doom_room == String(g.home["no"]):
		kind = "doll"   # das Urteil der Puppe (5.5) – ohne Schuld
	var guilt := CAUSE_TEXT.has(kind)
	causes.erase(g.id)
	records.append({"id": g.id, "name": g.display_name, "day": Calendar.today(), "at": _now(), "cause": kind,
		"guilt": guilt, "honored": false})
	var amount := SHOCK_BASE
	if Social.tier(g) >= Social.Tier.FRIEND:
		amount += SHOCK_BOND * clampf(g.relation / 100.0, 0.5, 1.0)
	if guilt:
		amount += SHOCK_GUILT
	if Game.player:
		Game.player.add_shock(amount, guilt)
	if Game.tracing:
		print("[Ursache] %s ist tot – Ursache %s, %s, Schock +%.2f" % [g.display_name, kind if kind != "" else "keine",
			"Schuld" if guilt else "keine Schuld", amount])
	if guilt:
		_tell(g, cause.get("knowers", []))


## Wer die Ursache kennt, mag den Spieler weniger; der Gesprächigste erzählt es übers Freundesnetz (6.18, 1).
func _tell(dead: Guest, witnesses: Array) -> void:
	var social := Game.social
	var knowers: Array[Guest] = []
	for id in witnesses:
		var w := social.guest_by_id(String(id))
		if w and not w.dead and not w in knowers:
			knowers.append(w)
	for other in social.living_guests():
		var g: Guest = other
		if g.housemate_of(dead) and not g in knowers:
			knowers.append(g)
	if knowers.is_empty():
		return
	var teller: Guest = knowers[0]
	for k in knowers:
		social.change_relation(k, WITNESS_RELATION if social.pals.are_pals(dead, k) else KNOWER_RELATION)
		if float(k.profile["gossip"]) > float(teller.profile["gossip"]):
			teller = k
	var friends: Array = []
	for other in social.living_guests():
		if social.pals.are_pals(dead, other) and not other in knowers:
			friends.append(other)
	social.pals.spread_with_affected(teller, NET_RELATION, friends, FRIEND_RELATION)
	if Game.tracing:
		print("[Ursache] Es wissen: %s – %s erzählt es weiter (%d Freunde des Toten)" % [
			", ".join(knowers.map(func(k: Guest) -> String: return k.display_name)), teller.display_name, friends.size()])


## Der zuletzt Gestorbene (Halluzinationen, 6.18, 2) – null, wenn noch keiner tot ist. Tote aus Ständen vor Version 71
## stehen nicht in records: dann irgendein Toter.
func last_dead() -> Guest:
	for i in range(records.size() - 1, -1, -1):
		var g := Game.social.guest_by_id(String(records[i]["id"]))
		if g:
			return g
	for i in range(Game.social.guests.size() - 1, -1, -1):
		if Game.social.guests[i].dead:
			return Game.social.guests[i]
	return null


## Brannte schon ein Licht des Spielers vor seiner Tür?
func honored(id: String) -> bool:
	for r in records:
		if r["id"] == id:
			return bool(r["honored"])
	return false


## Offene Schuld: ein Toter mit Schuld, für den noch kein Licht brannte, jünger als GUILT_DAYS Spieltage.
func open_guilt() -> bool:
	var today := Calendar.today()
	for r in records:
		if r["guilt"] and not r["honored"] and today - int(r["day"]) < GUILT_DAYS:
			return true
	return false


## Social._update_memorials (alle 2 s): Brennt ein Licht des Spielers vor der Tür eines Toten, ist er geehrt.
func update_honor() -> void:
	for r in records:
		if r["honored"]:
			continue
		var g := Game.social.guest_by_id(String(r["id"]))
		if g and _player_light_at(g.home["door_front"]):
			honor(r, g)


## Ein Licht des Spielers (angezündet, nicht in der Hand) vor dieser Tür?
func _player_light_at(door_front: Vector3) -> bool:
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.lit and not item.is_held and item.owner_id == "player" and item.global_position.distance_to(door_front) < HONOR_RANGE:
			return true
	return false


func honor(r: Dictionary, dead: Guest) -> void:
	r["honored"] = true
	var p := Game.player
	if p:
		p.shock = maxf(0.0, p.shock - HONOR_SHOCK)
	var social := Game.social
	for other in social.living_guests():
		if social.pals.are_pals(dead, other):
			social.change_relation(other, HONOR_RELATION)
	social.requests.on_memorial(dead)   # Trauerwunsch erfüllt (6.12)
	Game.say("Ein Licht für %s." % String(r["name"]), 3.0)
	if Game.tracing:
		print("[Gedenken] Licht vor der Tür von %s%s" % [r["name"], " – Schuld gesühnt" if r["guilt"] else ""])


func _now() -> float:
	return Game.director.elapsed if Game.director else 0.0


func save_state() -> Dictionary:
	return {"causes": causes.duplicate(true), "records": records.duplicate(true)}


## Ältere Stände (vor Version 71): keine Ursachen, keine Toten verzeichnet – die schon Toten haben keine Schuld.
func load_state(d: Dictionary) -> void:
	causes = {}
	var saved: Dictionary = d.get("causes", {})
	for id in saved:
		var list := {}
		for kind in saved[id]:
			var c: Dictionary = saved[id][kind]
			list[String(kind)] = {"at": float(c.get("at", 0.0)), "until": float(c.get("until", 0.0)),
				"knowers": (c.get("knowers", []) as Array).map(func(k) -> String: return String(k))}
		causes[String(id)] = list
	records.clear()
	for r: Dictionary in d.get("records", []):
		records.append({"id": String(r.get("id", "")), "name": String(r.get("name", "")), "day": int(r.get("day", 1)),
			"at": float(r.get("at", 0.0)), "cause": String(r.get("cause", "")), "guilt": bool(r.get("guilt", false)),
			"honored": bool(r.get("honored", false))})


# --- Debug (--schuld) ----------------------------------------------------------------------------

const DEBUG_CAUSES := {"klopfen": "knock", "telefon": "phone", "licht": "light", "begleiten": "escort",
	"diebstahl": "theft", "sorglos": "careless", "keine": "", "abgelaufen": "", "zurueck": "", "gedenken": "light",
	"halten": "light"}

## --schuld=id[,ursache]: Der Gast und ein Freund von ihm (Zeuge) stehen vor dir; du tust ihm die Ursache an (Standard
## licht), dann stirbt er. Prüft Ursache, Schuld, Schock, Namen der Halluzination und was sein Freund erfährt · keine:
## ohne Ursache · abgelaufen: Licht aus, die Nacht ist vorbei · zurueck: geklaute Deko liegt wieder vor seiner Tür ·
## gedenken: danach ein Licht vor seiner Tür · halten: dazu eine offene Ursache bei einem zweiten Gast (für --savetest).
## Meldet „[Schuld] … ok“ bzw. „FEHLER“.
func debug(parts: PackedStringArray) -> void:
	var social := Game.social
	var p := Game.player
	var victim := social.find_guest(parts[0] if parts.size() > 0 and parts[0] != "" else "edna")
	var what := parts[1] if parts.size() > 1 and parts[1] != "" else "licht"
	if victim == null or victim.dead or not DEBUG_CAUSES.has(what):
		print("[Schuld] Debug: --schuld=id[,%s]" % "|".join(DEBUG_CAUSES.keys()))
		return
	var kind: String = DEBUG_CAUSES[what]
	var check := func(text: String, ok: bool) -> void:
		print("[Schuld] %s: %s" % [text, "ok" if ok else "FEHLER"])
	var ahead := -p.global_transform.basis.z
	var side := p.global_transform.basis.x
	victim._set_idle(60.0)
	victim.global_position = p.global_position + ahead * 2.5 + side * 1.2
	var witness: Guest = null   # ein Freund des Opfers, der zusieht (nicht aus seinem Haushalt)
	for other in social.living_guests():
		var o: Guest = other
		if o != victim and not o.is_child() and not o.housemate_of(victim):
			witness = o
			break
	social.pals.note(witness, victim, GuestPals.PAL_DEEDS)
	witness._set_idle(60.0)
	witness.global_position = p.global_position + ahead * 2.5 - side * 1.2
	witness.look_at(p.global_position, Vector3.UP, false)
	witness.relation = 20.0
	print("[Schuld] Debug: %s, Ursache %s, Zeuge %s" % [victim.display_name, what, witness.display_name])
	var deco: Item = null
	match what:
		"licht", "gedenken", "halten", "abgelaufen":
			var sw: LightSwitch = null
			for node in get_tree().get_nodes_in_group("light_switches"):
				if (node as LightSwitch).room_id == String(victim.home["no"]):
					sw = node
					break
			if sw:
				sw.set_on(true, true)
				sw.interact(p)
			else:
				note_room(String(victim.home["no"]), "light")
			if what == "abgelaufen":
				causes[victim.id]["light"]["until"] = _now() - 1.0
		"klopfen":
			note(victim, "knock")
		"telefon":
			note_room(String(victim.home["no"]), "phone")
		"begleiten":
			victim.start_follow(30.0)
		"sorglos":
			victim.set_stance("careless", 600.0)
		"diebstahl", "zurueck":
			deco = Item.create(Item.Kind.CANDLE)
			social.get_parent().add_child(deco)
			deco.owner_id = victim.id
			deco.global_position = p.global_position + ahead * 0.8
			social.on_player_took(deco)
			deco.owner_id = "player"
			if what == "zurueck":
				deco.global_position = victim.home["door_front"]
			kind = "theft" if what == "diebstahl" else ""
	if what == "halten":   # eine offene Ursache, die gespeichert wird
		for other in social.living_guests():
			if other != victim and other != witness:
				note(other, "knock")
				break
	check.call("Ursache vermerkt", kind == "" or cause_of(victim).get("kind", "") == kind)
	var shock_before := p.shock
	var rel_before := witness.relation
	victim.die("monster")
	social.on_guest_died(victim, "monster", true)
	var r: Dictionary = records.back()
	var guilt := kind != ""
	check.call("Ursache „%s“ beim Tod" % r["cause"], r["cause"] == kind)
	check.call("Schuld %s" % ("ja" if guilt else "nein"), r["guilt"] == guilt)
	var amount := p.shock - shock_before
	check.call("Schock +%.2f" % amount, amount > SHOCK_BASE - 0.01 and (amount > SHOCK_BASE + SHOCK_GUILT - 0.01 or not guilt or p.shock >= 0.99))
	check.call("Halluzinationen tragen seinen Namen", last_dead() == victim)
	check.call("Schuld offen", open_guilt() == guilt)
	if guilt and what != "sorglos":
		check.call("Zeuge %s weiß es: %.0f → %.0f" % [witness.display_name, rel_before, witness.relation],
			witness.relation <= rel_before + WITNESS_RELATION * 0.8)
	else:   # sorglos: was du ihm gesagt hast, hat der Zeuge nicht gehört – nur sein Haushalt weiß es
		check.call("Zeuge unverändert", is_equal_approx(witness.relation, rel_before))
	if what == "gedenken":
		var candle := Item.create(Item.Kind.CANDLE)
		social.get_parent().add_child(candle)
		candle.owner_id = "player"
		candle.global_position = victim.home["door_front"]
		candle.light_up(false)
		var shock_lit := p.shock
		get_tree().create_timer(3.0, false).timeout.connect(func() -> void:
			check.call("Gedenken: geehrt", bool(r["honored"]))
			check.call("Gedenken: Schuld gesühnt", not open_guilt())
			check.call("Gedenken: Schock gesunken", p.shock < shock_lit - HONOR_SHOCK * 0.8))
