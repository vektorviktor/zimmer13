extends Node
## Speichern & Laden (Autoload „SaveManager“, Spielkonzept 8).
##   Slot 1–3: manuell am Tagebuch in Zimmer 13 · Slot 0: Autosave bei wichtigen Ereignissen.
## Weil es kein Inventar gibt, ist die Welt der Spielstand: jeder Gegenstand mit Ort und
## Zustand, alle Gäste, die versteckten Werte des Monsters, Lampen, Türen, Vorhänge …
## Dateien: user://saves/slot_N.json (+ .png Vorschaubild), sicher geschrieben über .tmp.
## Laden = Hauptszene neu aufbauen und dann aus dem Spielstand befüllen.

signal autosaved

const DIR := "user://saves/"
## 2: größeres Hotel (Kreuzungen, 30 Zimmer, Kellertreppe) – ältere Stände passen nicht mehr
## 3: zufällig erzeugte Gäste (Seed + Zimmer im Spielstand)
## 4: Obergeschoss, dritte Kreuzung, Spuren und Zettel der Gäste
const VERSION := 4
const MIN_VERSION := 4
const SLOTS := 3
const AUTOSAVE := 0
## Mindestabstand zum Monster für den Autosave (Tuning)
const AUTOSAVE_MONSTER_DISTANCE := 25.0
## Bereiche, deren erster Besuch einen Autosave auslöst
const NEW_AREAS := ["Lobby", "Küche", "Bar", "Garten", "Südflügel", "Nordflügel", "Ostflügel Süd", "Ostflügel Nord", "Treppenhaus", "OG Flur West", "Keller", "Zimmer 16", "Zimmer 17", "Zimmer 18"]

## Zeitpunkt (Ticks in ms) des letzten Speicherns oder Ladens in dieser Sitzung
var last_save_msec := -1
var visited: Array = []

var _pending_autosave := ""
var _check_timer := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	DirAccess.make_dir_recursive_absolute(DIR)


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


## Kopfdaten für die Slot-Übersicht ({} = leer oder unlesbar).
func slot_info(slot: int) -> Dictionary:
	var data := _read(slot)
	if data.is_empty():
		return {}
	return {
		"text": data.get("text", ""), "saved_at": data.get("saved_at", 0),
		"playtime": data.get("playtime", 0.0), "alive": data.get("alive", []),
	}


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
		if not info.is_empty() and int(info["saved_at"]) > best_time:
			best_time = int(info["saved_at"])
			best = slot
	return best


func has_any_save() -> bool:
	return newest_slot() >= 0


# --- Speichern ---------------------------------------------------------------------

## Am Tagebuch: gesperrt, solange das Monster in der Nähe ist (Rauschen) oder jagt (8.5, 4.13).
func can_save() -> bool:
	if Game.director == null or Game.game_over or Game.player == null:
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
	if Game.dice and Game.dice.active:
		return false
	if Game.menus and Game.menus.is_open():
		return false
	if not can_save():
		return false
	if Game.monster.is_active() and Game.monster.global_position.distance_to(p.global_position) < AUTOSAVE_MONSTER_DISTANCE:
		return false
	return true


func autosave(_reason: String) -> void:
	var thumb := get_viewport().get_texture().get_image()
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
	if data.is_empty():
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
			if g.relation <= -50.0:
				parts.append("%s redet nicht mehr mit mir." % g.display_name)
			elif g.relation >= 50.0:
				parts.append("%s und ich sind Freunde geworden." % g.display_name)
	var lit := 0
	var deco := 0
	if Game.director:
		for node in get_tree().get_nodes_in_group("items"):
			var item := node as Item
			if item.is_held or item.deco_strength <= 0.0:
				continue
			if item.global_position.distance_to(Game.director.player_door_front) < 2.5:
				deco += 1
				if item.lit and item.kind == Item.Kind.CARVED_PUMPKIN:
					lit += 1
	if lit > 0:
		parts.append("Vor meiner Tür brennen %s." % ("ein Kürbis" if lit == 1 else "%d Kürbisse" % lit))
	elif deco == 0:
		parts.append("Vor meiner Tür steht nichts. Gar nichts.")
	if Game.player and Game.player.shock > 0.3:
		parts.append("Ich kann nicht aufhören zu zittern.")
	if Game.director and Game.director.strange_diary:
		# Zimmer 13 bleibt nicht unberührt (4.13): eine Zeile, die man nicht geschrieben hat
		return (Calendar.date_text(Game.director.elapsed) + ". " if Game.director else "") \
			+ " ".join(parts.slice(0, 2)) + " – Darunter, in fremder Schrift: »Ich sehe dir beim Schreiben zu.«"
	if parts.is_empty():
		parts.append("Noch ein Abend in diesem Hotel. Es ist still. Zu still.")
	var date := Calendar.date_text(Game.director.elapsed) + ". " if Game.director else ""
	return date + " ".join(parts.slice(0, 3))


# --- Zustand einsammeln ------------------------------------------------------------------

func collect() -> Dictionary:
	var tree := get_tree()
	var p := Game.player
	var data := {
		"version": VERSION,
		"saved_at": int(Time.get_unix_time_from_system()),
		"playtime": Game.director.elapsed,
		"money": Game.money,
		"current_slot": Game.current_slot,
		"visited": visited.duplicate(),
		"player": {
			"pos": _v(p.global_position), "yaw": p.rotation.y, "pitch": p.head.rotation.x,
			"crouch": p.crouching, "shock": p.shock,
			"held": _item_data(p.held) if p.held else null,
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
		"thefts_ago": thefts, "memorials": memorials, "watched": social._watched.keys(),
		"party_cooldown": social._party_cooldown, "roster": social.roster_state(),
		"arrival_timer": social._arrival_timer,
	}
	var director := Game.director
	var curiosity: Array = []
	for zone in director.zones:
		curiosity.append(float(zone["curiosity"]))
	data["director"] = {
		"boldness": director.boldness, "boldness_dip": director.boldness_dip,
		"satiation": director.satiation, "elapsed": director.elapsed,
		"curiosity": curiosity, "state": director.save_state(),
	}
	data["traces"] = Game.traces.save_state() if Game.traces else []
	data["hide_spots"] = _collect_group("hide_spots", func(n: Node) -> Dictionary: return n.save_state())
	data["doors"] = _collect_group("doors", func(n: Node) -> Dictionary:
		return {"open": n.is_open, "locked": n.locked})
	data["chests"] = _collect_group("chests", func(n: Node) -> Dictionary:
		return {"open": n.is_open})
	data["plants"] = _collect_group("pumpkin_plants", func(n: Node) -> Dictionary:
		return {"stage": n.stage, "timer": n._timer})
	data["resources"] = _collect_group("resource_spots", func(n: Node) -> Dictionary:
		return {"uses": n.uses, "timer": n._timer})
	data["lamps"] = _collect_group("lamp_fixtures", func(n: Node) -> Dictionary: return n.save_state())
	data["switches"] = _collect_group("light_switches", func(n: Node) -> Dictionary: return n.save_state())
	data["windows"] = _collect_group("windows", func(n: Node) -> Dictionary: return n.save_state())
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
		"rot": _v(e), "owner": item.owner_id, "lit": item.lit, "burn": item.burn_time,
	}


# --- Zustand wiederherstellen ------------------------------------------------------------

## Wird von main.gd aufgerufen, nachdem das Hotel frisch aufgebaut ist.
func apply(data: Dictionary) -> void:
	var tree := get_tree()
	var world := Game.player.get_parent()
	visited = (data.get("visited", []) as Array).duplicate()
	Game.money = int(data.get("money", 5))
	Game.current_slot = int(data.get("current_slot", Game.current_slot))
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
		n._update_visual())
	_apply_group("light_switches", data.get("switches", []), func(n: Node, d: Dictionary) -> void: n.load_state(d))
	_apply_group("lamp_fixtures", data.get("lamps", []), func(n: Node, d: Dictionary) -> void: n.load_state(d))
	_apply_group("windows", data.get("windows", []), func(n: Node, d: Dictionary) -> void: n.load_state(d))
	_apply_group("hide_spots", data.get("hide_spots", []), func(n: Node, d: Dictionary) -> void: n.load_state(d))
	if Game.traces:
		Game.traces.load_state(data.get("traces", []))
	if Game.dice and Game.dice.table:
		Game.dice.table.loaded = bool(data.get("table_loaded", false))

	# Monster-Werte
	var director := Game.director
	var dd: Dictionary = data.get("director", {})
	director.boldness = float(dd.get("boldness", director.boldness))
	director.boldness_dip = float(dd.get("boldness_dip", 0.0))
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
		g.stock = {}
		var stock: Dictionary = d["stock"]
		for key in stock:
			g.stock[int(key)] = int(stock[key])
		g._set_idle(randf_range(1.0, 4.0))
		if bool(d["dead"]):
			g.die()

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
		world.add_child(item)
		item.global_position = _vec(entry["pos"])
		item.global_rotation = _vec(entry["rot"])
	for guest in Game.social.guests:
		var g: Guest = guest
		var held = gd.get(g.id, {}).get("held")
		if held != null and not g.dead:
			g._take_into_hand(_make_item(held))

	# Spieler
	var pd: Dictionary = data["player"]
	var p := Game.player
	p.global_position = _vec(pd["pos"])
	p.rotation.y = float(pd["yaw"])
	p.head.rotation.x = float(pd["pitch"])
	p.shock = float(pd.get("shock", 0.0))
	if pd.get("held") != null:
		var held_item := _make_item(pd["held"])
		held_item.owner_id = "player"
		world.add_child(held_item)
		p.try_pick_up(held_item)

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
	social._party_cooldown = float(sd.get("party_cooldown", 150.0))
	social._arrival_timer = float(sd.get("arrival_timer", -1.0))
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
	var data: Dictionary = parsed
	var version := int(data.get("version", 0))
	if version > VERSION or version < MIN_VERSION:
		return {}
	return data


func _v(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


func _vec(a) -> Vector3:
	return Vector3(float(a[0]), float(a[1]), float(a[2]))
