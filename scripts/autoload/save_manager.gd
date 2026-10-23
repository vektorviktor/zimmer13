extends Node
## Speichern & Laden (Autoload „SaveManager“, Spielkonzept 8).
##   Slot 1–3: manuell am Tagebuch in Zimmer 13 · Slot 0: Autosave bei wichtigen Ereignissen.
## Weil es kein Inventar gibt, ist die Welt der Spielstand: jeder Gegenstand mit Ort und
## Zustand, alle Gäste, die versteckten Werte des Monsters, Lampen, Türen, Vorhänge …
## Dateien: user://saves/slot_N.json (+ .png Vorschaubild), sicher geschrieben über .tmp.
## Laden = Hauptszene neu aufbauen und dann aus dem Spielstand befüllen.
## Feste Welt-Objekte werden über ihre Reihenfolge in der Gruppe zugeordnet. Ein Spielstand passt deshalb nur
## zu genau dem Hotel, in dem er entstand: Der Fingerabdruck der Welt (world_fingerprint) steht im Spielstand,
## ändert sich das Hotel, wird der Stand mit Hinweis abgelehnt statt falsch befüllt.

signal autosaved

## Headless (Testläufe, tests/smoke.sh) und mit --bg (Screenshot-Läufe nebenher) ein eigener Ordner – sonst
## überschreibt ein Testlauf den echten Autosave
var DIR := "user://saves_headless/" if DisplayServer.get_name() == "headless" or "--bg" in OS.get_cmdline_user_args() \
	else "user://saves/"
## 2: größeres Hotel (Kreuzungen, 30 Zimmer, Kellertreppe) – ältere Stände passen nicht mehr
## 3: zufällig erzeugte Gäste (Seed + Zimmer im Spielstand)
## 4: Obergeschoss, dritte Kreuzung, Spuren und Zettel der Gäste
## 5: Zimmertelefone (Gruppe phones) – Stände mit Version 4 laden weiter, alle Hörer liegen auf
## 6: am Körper (player.compass/map_pages/keyring), Kartenblätter – ältere Stände laden weiter,
##    Kompass, Karte und Schlüssel liegen dort noch in der Welt
## 7: Kommoden im Flur (Gruppe dressers) – ältere Stände laden weiter, alle Schubladen sind zu und unberührt
## 8: Hotelkatzen (Gruppe cats) – ältere Stände laden weiter, die Katzen beginnen an ihren Startplätzen
## 9: Milchglas zwischen Flur und Zimmern entfernt (Gruppe windows kleiner, Spuren hängen an Fenster-Indizes)
## 10: Deckenlampen entfernt, dafür Wandleuchten, zwei je Zimmer (Gruppe lamp_fixtures anders)
## 11: Schreck & Erlebnisse der Gäste, Leichen, Lakengeist bei Gästen (corpse, ghost_visits, seen, experiences)
##     – Stände mit Version 10 laden weiter, die Gäste haben dann noch nichts erlebt
## 12: Nächte ohne Schlaf (player.nights_awake) – ältere Stände laden weiter, der Spieler gilt als ausgeschlafen
## 13: Schachbrett (Item.Kind.CHESS_BOARD) – in älteren Ständen bleibt das Brett vom Start auf dem Schachtisch
## 14: Freundschaftsstufen (Gast: deeds, chat_day, chats_today; Spieler: injury) – ältere Stände laden weiter,
##     es gab dann noch keine Taten (die Extreme müssen neu verdient werden)
## 15: neuer Grundriss aus dem Gebäudeplan (Spielkonzept 7.5) – alle Gruppen neu, ältere Stände passen nicht mehr
## 16: Einrichtung aus den Objektebenen des Plans – Lampen, Schalter, Verstecke, Kommoden, Telefone … in neuer
##     Reihenfolge, ältere Stände passen nicht mehr
## 17: vier Deckenleuchten in der Lobby (Spielkonzept 7.3) – mehr Lampen, ältere Stände passen nicht mehr
## 18: Deckenleuchten in Bar, Partyraum und Lobby – mehr Lampen, ältere Stände passen nicht mehr
## 19: Deckenleuchten über den zehn Flurkübeln – mehr Lampen, ältere Stände passen nicht mehr
## 20: Fingerabdruck der Welt („world“) – Umbauten am Hotel brauchen keine neue Version mehr, nur noch
##     Änderungen am Aufbau des Spielstands selbst
## 21: Rausch und Kater (player.drunk/hangover, Gast drunk) – Stände mit Version 20 laden weiter, alle nüchtern
## 22: Kinder (Spielkonzept 6.13) – „parent“ in der Gästeliste (roster); ältere Stände laden weiter, ohne Kinder
## 23: aufgehängte Deko (Spielkonzept 5.6) – „hung“ an Gegenständen, neue Arten Lakengespenst, Lichterkette,
##     Zierkürbis; ältere Stände laden weiter, dort hängt noch nichts
## 24: übergeworfenes Bettlaken (player.disguised, Item.Kind.BED_SHEET) – ältere Stände laden weiter, unverkleidet
## 25: Freundschaften unter Gästen (Spielkonzept 6.16) – „pals“ unter „social“; ältere Stände laden weiter, dort
##     sind nur Familie und Zimmernachbarn befreundet
## 26: Überlebende & Verletzungen (Spielkonzept 6.17) – je Gast wound, wound_left, wound_bed, wound_facts, wound_told,
##     wound_visited; ältere Stände laden weiter, alle unverletzt
## 27: Verdacht wegen Katzendiebstahl (social.cat_blame), ohne Delle der Dreistigkeit (director.boldness_dip entfällt) –
##     ältere Stände laden weiter, dort verdächtigt keiner den Spieler, eine gespeicherte Delle wird übergangen
## 28: Tasche für Kleines (player.bag, Spielkonzept 3.2) und Getränkedosen (Item.Kind.SODA_CAN) – ältere Stände
##     laden weiter, die Tasche ist dann leer
## 29: Puppe (Spielkonzept 5.5: „doll“, im Director Frist, Urteil und Weg), Feindschaften unter Gästen (social.pals mit
##     counts und feuds), Spaßwert und Garantie des Kürbismanns („pumpkin“), Aufholen des Lakengeists (ghost.catch_up_day)
##     – ältere Stände laden weiter, die Puppe sitzt dann in der Lobby
## 30: Aufzug (Spielkonzept 7.4, Gruppe elevators: Höhe der Kabine, gewählte Halte, Tür offen) – ältere Stände passen
##     ohnehin nicht mehr (Aufzugtüren und Kabinenleuchte ändern den Fingerabdruck)
## 31: Tagesuhr (Spielkonzept 2.4) – ein Tag dauert 1440 statt 300 s, die Nachtruhe folgt der Uhr (social.night_seed statt
##     sleep_timer); ältere Stände laden nicht mehr (ihre Spielzeit ergäbe einen ganz anderen Tag)
## 32: Knappheit (Spielkonzept 5.10) – Faulzeit der Kürbisse im Zusatz der Gegenstände („r=…“), Tag der letzten
##     Entnahme eines Gastes je Kiste (resources.guest_day); ältere Stände laden nicht (Kisten wären wieder voll)
const VERSION := 32
const MIN_VERSION := 32
const SLOTS := 3
const AUTOSAVE := 0
## Mindestabstand zum Monster für den Autosave (Tuning)
const AUTOSAVE_MONSTER_DISTANCE := 25.0
## Gruppen fester Welt-Objekte, die nach Reihenfolge gespeichert werden; bei COUNT_ONLY zählt nur die Anzahl
## (Katzen beginnen nicht immer am selben Platz)
const WORLD_GROUPS := ["doors", "chests", "pumpkin_plants", "resource_spots", "lamp_fixtures", "light_switches",
	"windows", "hide_spots", "phones", "dressers", "cats", "elevators"]
const COUNT_ONLY := ["cats"]
## Fingerabdruck des zuletzt gebauten Hotels – für die Slot-Übersicht, bevor ein Hotel steht
var WORLD_FILE := DIR + "world.txt"
## Bereiche, deren erster Besuch einen Autosave auslöst
const NEW_AREAS := ["Lobby", "Galerie", "Küche", "Speisesaal", "Bar", "Partyraum", "Pool", "Garten", "Innenhof Nordost", "Innenhof Südost",
	"Ostflügel, Nordflur", "Westflügel, Südflur", "Treppenhaus", "Keller", "Zimmer 0116", "Zimmer 0117", "Zimmer 0118"]

## Zeitpunkt (Ticks in ms) des letzten Speicherns oder Ladens in dieser Sitzung
var last_save_msec := -1
var visited: Array = []

## Fingerabdruck des aktuellen Hotels ("" = noch keins gebaut, dann aus WORLD_FILE)
var world := ""
var _pending_autosave := ""
var _check_timer := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	DirAccess.make_dir_recursive_absolute(DIR)
	if FileAccess.file_exists(WORLD_FILE):
		world = FileAccess.get_file_as_string(WORLD_FILE).strip_edges()


func _process(delta: float) -> void:
	if Game.player == null or Game.game_over:
		return
	_check_timer -= delta
	if _check_timer > 0.0:
		return
	_check_timer = 1.0
	_check_new_area()
	if _pending_autosave != "" and is_safe_for_autosave():
		var reason := _pending_autosave
		_pending_autosave = ""
		autosave(reason)


# --- Slots -------------------------------------------------------------------------

func slot_path(slot: int, ext: String = "json") -> String:
	return DIR + ("autosave" if slot == AUTOSAVE else "slot_%d" % slot) + "." + ext


func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


## Kopfdaten für die Slot-Übersicht ({} = leer oder unlesbar). "fits" = false: stammt aus einem anderen
## Hotel oder einer anderen Spielstand-Version und lässt sich nicht laden.
func slot_info(slot: int) -> Dictionary:
	var data := _read(slot)
	if data.is_empty():
		return {}
	return {
		"text": data.get("text", ""), "saved_at": data.get("saved_at", 0),
		"playtime": data.get("playtime", 0.0), "alive": data.get("alive", []), "fits": fits(data),
	}


## Passt der Spielstand zu diesem Spiel? Ist das Hotel noch nicht gebaut und auch kein Fingerabdruck
## gemerkt, gilt er vorerst als passend – main.gd prüft nach dem Aufbau noch einmal.
func fits(data: Dictionary) -> bool:
	var version := int(data.get("version", 0))
	if version > VERSION or version < MIN_VERSION:
		return false
	return world == "" or String(data.get("world", "")) == world


## Fingerabdruck aus Anzahl und Lage der festen Welt-Objekte – nach dem Aufbau des Hotels aufrufen,
## bevor sich etwas bewegt. Merkt ihn sich auch für die Slot-Übersicht im Titelbildschirm.
func note_world() -> void:
	var parts: PackedStringArray = []
	for group in WORLD_GROUPS:
		var nodes := get_tree().get_nodes_in_group(group)
		parts.append("%s:%d" % [group, nodes.size()])
		if group in COUNT_ONLY:
			continue
		for node in nodes:
			var p: Vector3 = (node as Node3D).global_position.snapped(Vector3.ONE * 0.1)
			parts.append("%.1f,%.1f,%.1f" % [p.x, p.y, p.z])
	var fingerprint := ";".join(parts).md5_text()
	if fingerprint != world:
		world = fingerprint
		var file := FileAccess.open(WORLD_FILE, FileAccess.WRITE)
		if file:
			file.store_string(world)


func thumbnail(slot: int) -> Texture2D:
	var path := slot_path(slot, "png")
	if not FileAccess.file_exists(path):
		return null
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	return ImageTexture.create_from_image(img) if img else null


## Neuester Spielstand (Slots und Autosave), −1 = keiner.
func newest_slot() -> int:
	var best := -1
	var best_time := -1
	for slot in range(0, SLOTS + 1):
		var info := slot_info(slot)
		if not info.is_empty() and info["fits"] and int(info["saved_at"]) > best_time:
			best_time = int(info["saved_at"])
			best = slot
	return best


func has_any_save() -> bool:
	return newest_slot() >= 0


# --- Speichern ---------------------------------------------------------------------

## Am Tagebuch: gesperrt, solange das Monster in der Nähe ist (Rauschen) oder jagt (8.5, 4.13),
## solange die Flackerwelle läuft (4.17), der Kürbismann im Hotel ist (4.19) und der Lakengeist beim
## Spieler ist (4.18). Der Kürbismann wird nicht gespeichert – sonst wäre man ihn durch Laden los.
func can_save() -> bool:
	if Game.director == null or Game.game_over or Game.player == null or Game.director.is_signalling():
		return false
	if (Game.pumpkin and (Game.pumpkin.in_house() or Game.pumpkin.announcing())) or (Game.ghost and Game.ghost.with_player()):
		return false
	var monster := Game.monster
	if not monster.is_active():
		return true
	return monster.state != Monster.State.CHASE \
		and monster.global_position.distance_to(Game.player.global_position) >= MonsterDirector.NOISE_START


func save_to(slot: int, text: String, thumb: Image) -> bool:
	var data := collect()
	data["text"] = text
	data["slot"] = slot
	var ok := _write(slot, data)
	if ok and thumb:
		thumb.save_png(slot_path(slot, "png"))
	if ok:
		last_save_msec = Time.get_ticks_msec()
	return ok


func request_autosave(reason: String) -> void:
	_pending_autosave = reason


## Nur in sicheren Momenten (8.6) – sonst wird der Autosave aufgeschoben.
func is_safe_for_autosave() -> bool:
	var p := Game.player
	if p == null or p.dead or p.hiding != null or p.in_dialog or Game.game_over:
		return false
	if not p.is_on_floor():   # nicht im Sprung oder Fall – sonst lädt man womöglich mitten in der Luft oder im Leeren
		return false
	if (Game.dice and Game.dice.active) or (Game.chess and Game.chess.active):
		return false
	if Game.menus and Game.menus.is_open():
		return false
	if not can_save():
		return false
	if Game.monster.is_active() and Game.monster.global_position.distance_to(p.global_position) < AUTOSAVE_MONSTER_DISTANCE:
		return false
	return true


func autosave(_reason: String) -> void:
	# Headless (Testläufe) gibt es kein Bild – dann ohne Vorschau
	var thumb: Image = null if DisplayServer.get_name() == "headless" else get_viewport().get_texture().get_image()
	if save_to(AUTOSAVE, diary_sentence(), thumb):
		autosaved.emit()


func _check_new_area() -> void:
	var zone := Game.director._zone_at(Game.player.global_position)
	if zone.is_empty():
		return
	var zone_name: String = zone["name"]
	if zone_name in NEW_AREAS and not zone_name in visited:
		visited.append(zone_name)
		request_autosave("Neuer Bereich: " + zone_name)


# --- Laden -------------------------------------------------------------------------

func load_slot(slot: int) -> bool:
	var data := _read(slot)
	if data.is_empty() or not fits(data):
		return false
	Game.pending_load = data
	Game.new_game_slot = 0
	if slot != AUTOSAVE:
		Game.current_slot = slot
	get_tree().paused = false
	get_tree().change_scene_to_file(Game.MAIN_SCENE)
	return true


func load_newest() -> bool:
	var slot := newest_slot()
	return slot >= 0 and load_slot(slot)


# --- Tagebuchsatz ---------------------------------------------------------------------

## Ein kurzer Tagebuchsatz aus dem aktuellen Stand – erscheint in der Slot-Übersicht.
func diary_sentence() -> String:
	var parts: Array[String] = []
	if Game.social:
		for guest in Game.social.guests:
			if guest.dead:
				parts.append("%s ist fort." % guest.display_name)
		for guest in Game.social.living_guests():
			var g: Guest = guest
			match Social.tier(g):
				Social.Tier.STRONG_ENEMY:
					parts.append("%s hasst mich. Ich gehe ihm aus dem Weg." % g.display_name)
				Social.Tier.ENEMY:
					parts.append("%s redet nicht mehr mit mir." % g.display_name)
				Social.Tier.FRIEND:
					parts.append("%s und ich sind Freunde geworden." % g.display_name)
				Social.Tier.GOOD_FRIEND:
					parts.append("Auf %s kann ich mich verlassen." % g.display_name)
	var lit := 0
	var deco := 0
	if Game.director:
		var door: Vector3 = Game.director.player_door_front
		for node in get_tree().get_nodes_in_group("items"):
			var item := node as Item
			if item.is_held or item.deco_strength <= 0.0:
				continue
			if Vector2(item.global_position.x - door.x, item.global_position.z - door.z).length() < 2.5 and absf(item.global_position.y - door.y) < 3.0:
				deco += 1
				if item.lit and item.kind == Item.Kind.CARVED_PUMPKIN:
					lit += 1
	if lit > 0:
		parts.append("Vor meiner Tür brennen %s." % ("ein Kürbis" if lit == 1 else "%d Kürbisse" % lit))
	elif deco == 0:
		parts.append("Vor meiner Tür steht nichts. Gar nichts.")
	if Game.player and Game.player.shock > 0.3:
		parts.append("Ich kann nicht aufhören zu zittern.")
	var date := Calendar.date_text(Game.director.elapsed) + ". " if Game.director else ""
	if Game.director and Game.director.strange_diary:
		# Zimmer 13 bleibt nicht unberührt (4.13): eine Zeile, die man nicht geschrieben hat
		return date + " ".join(parts.slice(0, 2)) + " – Darunter, in fremder Schrift: »Ich sehe dir beim Schreiben zu.«"
	if parts.is_empty():
		parts.append("Noch ein Abend in diesem Hotel. Es ist still. Zu still.")
	return date + " ".join(parts.slice(0, 3))


# --- Zustand einsammeln ------------------------------------------------------------------

func collect() -> Dictionary:
	var tree := get_tree()
	var p := Game.player
	var stand := p.stand_position()   # im Sitzen: wo er aufstünde (geladen wird stehend)
	var data := {
		"version": VERSION,
		"world": world,
		"saved_at": int(Time.get_unix_time_from_system()),
		"playtime": Game.director.elapsed,
		"money": Game.money,
		"current_slot": Game.current_slot,
		"visited": visited.duplicate(),
		"player": {
			"pos": _v(stand if stand != Vector3.INF else p.global_position), "yaw": p.rotation.y, "pitch": p.head.rotation.x,
			"crouch": p.crouching, "shock": p.shock, "nights_awake": p.nights_awake, "injury": p.injury,
			"drunk": p.drunk, "hangover": p.hangover, "disguised": p.disguised,
			"held": _item_data(p.held) if p.held else null,
			"bag": p.bag.map(_bag_data),
			"compass": p.has_compass, "map_pages": p.map_pages.duplicate(), "keyring": p.keyring.duplicate(),
		},
		"items": [],
		"guests": {},
		"social": {},
		"director": {},
	}
	for node in tree.get_nodes_in_group("items"):
		var item := node as Item
		if item.is_held or item.is_queued_for_deletion():
			continue
		data["items"].append(_item_data(item))
	var alive: Array = []
	for guest in Game.social.guests:
		var g: Guest = guest
		var pos := g.global_position
		var yaw := g.rotation.y
		if g.hiding:
			pos = g.hiding.exit_point.global_position
			yaw = g.hiding.exit_point.global_rotation.y
		if not g.dead:
			alive.append(g.display_name)
		var stock := {}
		for kind in g.stock:
			stock[str(int(kind))] = int(g.stock[kind])
		data["guests"][g.id] = {
			"pos": _v(pos), "yaw": yaw, "dead": g.dead, "relation": g.relation, "fear": g.fear,
			"money": g.money, "stock": stock, "expected_deco": g.expected_deco,
			"chat_cooldown": g.chat_cooldown, "gift_cooldown": g.gift_cooldown,
			"challenge_cooldown": g.challenge_cooldown, "monster_line": g.monster_line,
			"held": _item_data(g.held) if g.held else null,
			"corpse": g.corpse, "ghost_visits": g.ghost_visits, "seen": g.seen_sights, "experiences": g.experiences,
			"drunk": g.drunk,
			"deeds": g.deeds, "chat_day": g.chat_day, "chats_today": g.chats_today,
			"wound": g.wound, "wound_left": g.wound_left, "wound_bed": g.wound_bed, "wound_facts": g.wound_facts,
			"wound_told": g.wound_told, "wound_visited": g.wound_visited,
		}
	data["alive"] = alive
	var social := Game.social
	var thefts := {}
	for id in social._thefts:
		thefts[id] = social._time - float(social._thefts[id])   # vor wie vielen Sekunden
	var memorials: Array = []
	for door_front in social._memorial_doors:
		memorials.append(_v(door_front))
	data["social"] = {
		"thefts_ago": thefts, "memorials": memorials, "watched": social._watched.keys(), "chess_watched": social._chess_watched.keys(),
		"party_cooldown": social._party_cooldown, "roster": social.roster_state(),
		"arrival_timer": social._arrival_timer,
		"cat_thefts": social.cat_thefts, "cat_blame": social.cat_blame, "cats_have_cried": social.cats_have_cried,
		"sleep_active": social.sleep_active, "night_seed": social.night_seed,
		"pals": social.pals.save_state(),
	}
	var director := Game.director
	var curiosity: Array = []
	for zone in director.zones:
		curiosity.append(float(zone["curiosity"]))
	data["director"] = {
		"boldness": director.boldness,
		"satiation": director.satiation, "elapsed": director.elapsed,
		"curiosity": curiosity, "state": director.save_state(),
	}
	data["traces"] = Game.traces.save_state() if Game.traces else []
	data["ghost"] = Game.ghost.save_state() if Game.ghost else {}
	data["doll"] = Game.doll.save_state() if Game.doll else {}
	data["pumpkin"] = Game.pumpkin.save_state() if Game.pumpkin else {}
	data["hide_spots"] = _collect_group("hide_spots", func(n: Node) -> Dictionary: return n.save_state())
	data["doors"] = _collect_group("doors", func(n: Node) -> Dictionary:
		return {"open": n.is_open, "locked": n.locked})
	data["chests"] = _collect_group("chests", func(n: Node) -> Dictionary:
		return {"open": n.is_open})
	data["plants"] = _collect_group("pumpkin_plants", func(n: Node) -> Dictionary:
		return {"stage": n.stage, "timer": n._timer})
	data["resources"] = _collect_group("resource_spots", func(n: Node) -> Dictionary:
		return {"uses": n.uses, "timer": n._timer, "guest_day": n.guest_day})
	data["lamps"] = _collect_group("lamp_fixtures", func(n: Node) -> Dictionary: return n.save_state())
	data["switches"] = _collect_group("light_switches", func(n: Node) -> Dictionary: return n.save_state())
	data["windows"] = _collect_group("windows", func(n: Node) -> Dictionary: return n.save_state())
	data["phones"] = _collect_group("phones", func(n: Node) -> Dictionary: return n.save_state())
	data["dressers"] = _collect_group("dressers", func(n: Node) -> Dictionary: return n.save_state())
	data["cats"] = _collect_group("cats", func(n: Node) -> Dictionary: return n.save_state())
	data["elevators"] = _collect_group("elevators", func(n: Node) -> Dictionary: return n.save_state())
	data["table_loaded"] = Game.dice.table.loaded if Game.dice and Game.dice.table else false
	return data


func _collect_group(group: String, fn: Callable) -> Array:
	var list: Array = []
	for node in get_tree().get_nodes_in_group(group):
		list.append(fn.call(node))
	return list


func _item_data(item: Item) -> Dictionary:
	var e := item.global_rotation
	return {
		"kind": int(item.kind), "extra": item.create_extra(), "pos": _v(item.global_position),
		"rot": _v(e), "owner": item.owner_id, "lit": item.lit, "burn": item.burn_time, "hung": item.hung,
	}


## Gegenstand in der Tasche: ohne Lage – er liegt beim Spieler
func _bag_data(item: Item) -> Dictionary:
	var d := _item_data(item)
	for key in ["pos", "rot", "hung"]:
		d.erase(key)
	return d


# --- Zustand wiederherstellen ------------------------------------------------------------

## Wird von main.gd aufgerufen, nachdem das Hotel frisch aufgebaut ist.
func apply(data: Dictionary) -> void:
	var tree := get_tree()
	var parent := Game.player.get_parent()   # dort liegen die Gegenstände (nicht `world`, das ist der Fingerabdruck)
	visited = (data.get("visited", []) as Array).duplicate()
	Game.money = int(data.get("money", 5))
	Game.current_slot = int(data.get("current_slot", Game.current_slot))
	# Laufendes Schmücken, Deko-Suche und Suppenessen werden nicht gespeichert – und die Gäste gleich neu gebaut
	Game.social.decorating.reset()
	Game.social.search.reset()
	Game.social.pranks.reset()
	Game.social.tidying.reset()
	if Game.kitchen:
		Game.kitchen.reset()
	# Zuerst die zufällig erzeugten Gäste – alles Weitere bezieht sich auf ihre IDs
	Game.social.restore_roster((data.get("social", {}) as Dictionary).get("roster", []))

	# Welt
	_apply_group("doors", data.get("doors", []), func(n: Node, d: Dictionary) -> void:
		n.locked = bool(d["locked"])
		if bool(d["open"]) != n.is_open:
			n.set_open(bool(d["open"]), true, true))
	_apply_group("chests", data.get("chests", []), func(n: Node, d: Dictionary) -> void:
		n.set_open(bool(d["open"]), true))
	_apply_group("pumpkin_plants", data.get("plants", []), func(n: Node, d: Dictionary) -> void:
		n.stage = int(d["stage"])
		n._timer = float(d["timer"])
		n._update_visual())
	_apply_group("resource_spots", data.get("resources", []), func(n: Node, d: Dictionary) -> void:
		n.uses = int(d["uses"])
		n._timer = float(d["timer"])
		n.guest_day = int(d.get("guest_day", 0))
		n._update_visual())
	_apply_group("light_switches", data.get("switches", []), func(n: Node, d: Dictionary) -> void: n.load_state(d))
	_apply_group("lamp_fixtures", data.get("lamps", []), func(n: Node, d: Dictionary) -> void: n.load_state(d))
	_apply_group("windows", data.get("windows", []), func(n: Node, d: Dictionary) -> void: n.load_state(d))
	_apply_group("hide_spots", data.get("hide_spots", []), func(n: Node, d: Dictionary) -> void: n.load_state(d))
	_apply_group("phones", data.get("phones", []), func(n: Node, d: Dictionary) -> void: n.load_state(d))
	_apply_group("dressers", data.get("dressers", []), func(n: Node, d: Dictionary) -> void: n.load_state(d))
	_apply_group("elevators", data.get("elevators", []), func(n: Node, d: Dictionary) -> void: n.load_state(d))
	if Game.traces:
		Game.traces.load_state(data.get("traces", []))
	if Game.ghost:
		Game.ghost.load_state(data.get("ghost", {}))
	if Game.dice and Game.dice.table:
		Game.dice.table.loaded = bool(data.get("table_loaded", false))

	# Monster-Werte
	var director := Game.director
	var dd: Dictionary = data.get("director", {})
	director.boldness = float(dd.get("boldness", director.boldness))
	director.satiation = float(dd.get("satiation", 0.0))
	director.elapsed = float(dd.get("elapsed", 0.0))
	director.phase = MonsterDirector.Phase.CALM
	var curiosity: Array = dd.get("curiosity", [])
	for i in mini(curiosity.size(), director.zones.size()):
		director.zones[i]["curiosity"] = float(curiosity[i])

	# Gäste (vor den Gegenständen: ein toter Gast gibt seine Sachen frei)
	var gd: Dictionary = data.get("guests", {})
	for guest in Game.social.guests:
		var g: Guest = guest
		if not gd.has(g.id):
			continue
		var d: Dictionary = gd[g.id]
		g.global_position = _vec(d["pos"])
		g.rotation.y = float(d["yaw"])
		g.relation = float(d["relation"])
		g.fear = float(d["fear"])
		g.money = int(d["money"])
		g.expected_deco = int(d["expected_deco"])
		g.chat_cooldown = float(d.get("chat_cooldown", 0.0))
		g.gift_cooldown = float(d.get("gift_cooldown", 0.0))
		g.challenge_cooldown = float(d.get("challenge_cooldown", 0.0))
		g.monster_line = int(d.get("monster_line", 0))
		g.ghost_visits = int(d.get("ghost_visits", 0))
		g.drunk = float(d.get("drunk", 0.0))
		g.seen_sights = (d.get("seen", []) as Array).duplicate()
		g.experiences = (d.get("experiences", []) as Array).duplicate(true)
		g.deeds = (d.get("deeds", {}) as Dictionary).duplicate()
		g.chat_day = int(d.get("chat_day", 0))
		g.chats_today = int(d.get("chats_today", 0))
		g.wound = String(d.get("wound", ""))
		g.wound_left = float(d.get("wound_left", 0.0))
		g.wound_bed = float(d.get("wound_bed", 0.0))
		g.wound_facts = (d.get("wound_facts", {}) as Dictionary).duplicate()
		g.wound_told = int(d.get("wound_told", 0))
		g.wound_visited = bool(d.get("wound_visited", false))
		g._update_wound_marks()
		g.stock = {}
		var stock: Dictionary = d["stock"]
		for key in stock:
			g.stock[int(key)] = int(stock[key])
		g._set_idle(randf_range(1.0, 4.0))
		if bool(d["dead"]):
			g.die("ghost" if bool(d.get("corpse", false)) else "monster")

	# Gegenstände: alle Start-Gegenstände weg, dann aus dem Spielstand neu erzeugen
	Game.player.held = null
	for guest in Game.social.guests:
		guest.held = null
	for node in tree.get_nodes_in_group("items"):
		var item := node as Item
		item.remove_from_group("items")
		item.queue_free()
	for entry in data.get("items", []):
		var item := _make_item(entry)
		parent.add_child(item)
		item.global_position = _vec(entry["pos"])
		item.global_rotation = _vec(entry["rot"])
		if bool(entry.get("hung", false)):
			item.restore_hung()
	for guest in Game.social.guests:
		var g: Guest = guest
		var held = gd.get(g.id, {}).get("held")
		if held != null and not g.dead:
			g._take_into_hand(_make_item(held))

	# Katzen (nach den Gästen: Lieblingsgast; nach den Gegenständen: ihre Beute im Maul)
	_apply_group("cats", data.get("cats", []), func(n: Node, d: Dictionary) -> void: n.load_state(d))

	# Spieler
	var pd: Dictionary = data["player"]
	var p := Game.player
	p.leave_seat(true)
	p.global_position = _vec(pd["pos"])
	p.rotation.y = float(pd["yaw"])
	p.head.rotation.x = float(pd["pitch"])
	p.set_crouching(bool(pd.get("crouch", false)))
	p.shock = float(pd.get("shock", 0.0))
	p.nights_awake = int(pd.get("nights_awake", 0))
	p.injury = float(pd.get("injury", 0.0))
	p.drunk = float(pd.get("drunk", 0.0))
	p.hangover = float(pd.get("hangover", 0.0))
	p.set_disguised(bool(pd.get("disguised", false)))
	p.set_pockets(bool(pd.get("compass", false)), pd.get("map_pages", []), pd.get("keyring", []))
	if pd.get("held") != null:
		var held_item := _make_item(pd["held"])
		held_item.owner_id = "player"
		parent.add_child(held_item)
		p.try_pick_up(held_item)
	var bag: Array[Item] = []
	for entry in pd.get("bag", []):
		bag.append(_make_item(entry))
	p.set_bag(bag)

	# Soziales
	var sd: Dictionary = data.get("social", {})
	var social := Game.social
	social._thefts = {}
	var thefts: Dictionary = sd.get("thefts_ago", {})
	for id in thefts:
		social._thefts[id] = social._time - float(thefts[id])
	social._memorial_doors.clear()
	for m in sd.get("memorials", []):
		social._memorial_doors.append(_vec(m))
	social._watched = {}
	for id in sd.get("watched", []):
		social._watched[id] = true
	social._chess_watched = {}
	for id in sd.get("chess_watched", []):
		social._chess_watched[id] = true
	social._party_cooldown = float(sd.get("party_cooldown", 150.0))
	social.cat_thefts = (sd.get("cat_thefts", {}) as Dictionary).duplicate()
	social.cat_blame = (sd.get("cat_blame", {}) as Dictionary).duplicate()
	social.cats_have_cried = bool(sd.get("cats_have_cried", false))
	social.sleep_active = bool(sd.get("sleep_active", false))
	social.night_seed = int(sd.get("night_seed", social.night_seed))
	social._arrival_timer = float(sd.get("arrival_timer", -1.0))
	social.pals.load_state(sd.get("pals", {}))
	if Game.doll:
		Game.doll.load_state(data.get("doll", {}))
	if Game.pumpkin:
		Game.pumpkin.load_state(data.get("pumpkin", {}))
	# Monster zuletzt: ggf. wieder unterwegs an seiner gespeicherten Stelle
	director.load_state(dd.get("state", {}))
	last_save_msec = Time.get_ticks_msec()


func _apply_group(group: String, list: Array, fn: Callable) -> void:
	var nodes := get_tree().get_nodes_in_group(group)
	if nodes.size() != list.size():
		push_warning("Spielstand passt nicht zum Hotel (%s: %d statt %d) – wird übersprungen." % [group, list.size(), nodes.size()])
		return
	for i in nodes.size():
		fn.call(nodes[i], list[i])


func _make_item(entry: Dictionary) -> Item:
	var item := Item.create(int(entry["kind"]) as Item.Kind, String(entry.get("extra", "")))
	item.owner_id = String(entry.get("owner", ""))
	if item.kind == Item.Kind.CANDLE or item.kind == Item.Kind.CARVED_PUMPKIN:
		if bool(entry.get("lit", false)):
			item.burn_time = float(entry.get("burn", item.burn_time))
		elif item.lit:
			item._extinguish()
	return item


# --- Dateien -------------------------------------------------------------------------

func _write(slot: int, data: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(DIR)
	var path := slot_path(slot)
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		push_error("Spielstand konnte nicht geschrieben werden: %s" % tmp)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	var dir := DirAccess.open(DIR)
	if dir == null:
		push_error("Spielstand-Ordner nicht erreichbar: %s" % DIR)
		return false
	if dir.file_exists(path.get_file()):
		dir.remove(path.get_file())
	return dir.rename(tmp.get_file(), path.get_file()) == OK


func _read(slot: int) -> Dictionary:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _v(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


func _vec(a) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))
