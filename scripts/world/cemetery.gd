class_name Cemetery
extends Node3D
## Der Friedhof westlich des Kürbisfelds (Spielkonzept 5.15): Wer eine Leiche hinterlässt (Lakengeist, Kürbismann),
## wird beerdigt und bekommt einen zufälligen freien Grabplatz aus dem Plan – Erdhügel, am Kopfende ein Holzkreuz ohne
## Schrift mit Grablicht, am Morgen danach Blumen; der Name steht nur im Hinweis beim Ansehen.
## **Selbst beerdigen** ([E] an der Leiche): Abblenden, eine Spielstunde vergeht (Zeitsprung wie im Schlaf, mit allen
## Bedrohungen – kommt eine, ist das Grab trotzdem fertig), man steht vor dem Grab; beim Einblenden läutet die
## Totenglocke, die Freunde des Toten stehen schon darum. Bringt ihnen Beziehung (GAIN_BURY) und dem Spieler Gedenken.
## **Sonst begraben ihn die Gäste:** am ersten Vormittag, der mindestens MIN_LIE nach dem Tod liegt – um 9:30 läutet die
## Glocke, die Leiche ist fort, um 10 Uhr ist die Trauerfeier; wer dabei ist, bekommt GAIN_ATTEND.
## Die Trauernden (Familie zuerst, höchstens MAX_MOURNERS) stehen 1–2 Spielstunden am Grab (Guest.join_party mit Blick).
## Die Vermissten (Opfer des Monsters, keine Leiche) stehen auf der Gedenktafel der Gedenkstätte, vor ihr je eine
## Grabkerze. Die Grablichter gehen nie aus. Ab der ersten Beerdigung steckt eine Schaufel im nächsten freien Grab.
## Gespeichert: Gräber und wartende Leichen (save_state); Tafel und Kerzen ergeben sich aus den Toten.

const BURY_TIME := Calendar.HOUR            ## so lange dauert das Begraben (Zeitsprung)
const BURY_STEP := Calendar.HOUR / 30.0     ## Zeitsprung in Schritten je Bild (wie SleepSkip)
const FADE := 1.2                           ## Ab- und Aufblenden (Sekunden)
const BELL_HOUR := 9.5                      ## Totenglocke vor der Trauerfeier
const FUNERAL_HOUR := 10.0
const MIN_LIE := 6.0 * Calendar.HOUR        ## frühestens so lange nach dem Tod begraben die Gäste
const MOURN_TIME := Vector2(1.0, 2.0) * Calendar.HOUR
const MAX_MOURNERS := 6
const GAIN_BURY := 10.0                     ## Beziehung bei den Freunden des Toten
const GAIN_ATTEND := 3.0
const COMFORT := 0.15                       ## so viel weniger Schock beim Gedenken (einmal je Spieltag)
const ATTEND_RANGE := 9.0                   ## so nah am Grab gilt man als bei der Trauerfeier
const FLOWERS_AFTER := Calendar.DAY_SECONDS * 0.5
const SHOVEL_HINT := "Die Erde ist schon gelockert. Für den Nächsten."
const FLAME := Color(1.0, 0.6, 0.2)
const GLASS := Color(0.75, 0.05, 0.04)
const SOIL := Color(0.2, 0.13, 0.08)

var slots: Array[Dictionary] = []           ## aus dem Plan: {pos, head}
var spot: Dictionary = {}                   ## Gedenkstätte: {pos, front, size}
var graves := {}                            ## Platz → {id, name, died, at, by_player, flowers}
var pending := {}                           ## Gast-ID → Todeszeit (Leiche liegt noch)
var _funeral := {}                          ## laufende Trauerfeier: {at, end, ids, attended}
var _mourners: Array[Dictionary] = []       ## {guest, until}
var _grave_nodes := {}                      ## Platz → Node3D
var _tablet: Label3D
var _candle_root: Node3D
var _candle_light: FlickerLight
var _missing: Array[String] = []            ## Namen auf der Tafel
var _shovel: Node3D
var _comfort_day := 0
var _check := 0.0
var burying := false


## Ein Grab zum Ansehen: Name und Todestag im Hinweis, [E] gedenkt.
class GraveTouch extends StaticBody3D:
	var cemetery: Cemetery
	var slot := -1

	func get_prompt(_player: Player) -> String:
		var g: Dictionary = cemetery.graves.get(slot, {})
		if g.is_empty():
			return ""
		return "%s · † %s – gedenken [E]" % [g["name"], Calendar.date_text(float(g["died"])).split(" – ")[0]]

	func interact(player: Player) -> void:
		cemetery.remember(player, [String(cemetery.graves.get(slot, {}).get("name", ""))])


## Die Gedenktafel: die Vermissten, [E] gedenkt.
class TabletTouch extends StaticBody3D:
	var cemetery: Cemetery

	func get_prompt(_player: Player) -> String:
		if cemetery._missing.is_empty():
			return "Gedenktafel – noch leer"
		return "Vermisst: %s – gedenken [E]" % ", ".join(cemetery._missing)

	func interact(player: Player) -> void:
		if not cemetery._missing.is_empty():
			cemetery.remember(player, cemetery._missing)


## Die Schaufel im nächsten freien Grab – benutzen geht nicht.
class ShovelTouch extends StaticBody3D:
	func get_prompt(_player: Player) -> String:
		return Cemetery.SHOVEL_HINT

	func interact(_player: Player) -> void:
		pass


func setup(grave_slots: Array[Dictionary], memorial: Dictionary) -> void:
	slots = grave_slots
	spot = memorial
	add_to_group("time_skip")
	if not spot.is_empty():
		_build_memorial()


func has_place() -> bool:
	return not slots.is_empty()


# --- Tod und Beerdigung -----------------------------------------------------------------------------

## Social.on_guest_died: Wer liegen bleibt, wartet aufs Grab; die anderen kommen auf die Tafel.
func on_guest_died(guest: Guest) -> void:
	if guest.corpse:
		pending[guest.id] = Game.director.elapsed if Game.director else 0.0
	_refresh_missing()


## Kann der Spieler diese Leiche beerdigen?
func can_bury(guest: Guest) -> bool:
	return has_place() and guest.dead and guest.corpse and pending.has(guest.id) and _free_slot(guest) >= 0 \
		and not burying


## [E] an der Leiche: abblenden, eine Stunde vergeht, vor dem fertigen Grab mit der Totenglocke wieder einblenden.
func bury_by_player(guest: Guest) -> void:
	var player := Game.player
	var director := Game.director
	if not can_bury(guest) or player == null or director == null:
		if Game.tracing:
			print("[Friedhof] %s lässt sich nicht beerdigen (Leiche %s, wartet %s, frei %d, gerade %s)" % [guest.display_name,
				guest.corpse, pending.has(guest.id), _free_slot(guest), burying])
		return
	if threat():
		Game.say("Nicht jetzt.", 2.0)
		return
	burying = true
	player.spellbound = true
	await _fade(true)
	var slot := _bury(guest, true)
	var left := BURY_TIME
	var woke := ""
	director.skipping = true
	while left > 0.0:
		var dt := minf(BURY_STEP, left)
		woke = director.skip(dt)
		get_tree().call_group(&"time_skip", &"skip_time", dt)
		left -= dt
		if woke != "" or threat() or player.dead:
			break
		await get_tree().process_frame
	director.skipping = false
	var s: Dictionary = slots[slot]
	var head: Vector3 = s["head"]
	var stand: Vector3 = s["pos"] - head * 1.9
	TeleportUI.place_player(stand, s["pos"] - stand)
	_gather(guest, slot, true)
	if Game.tracing:
		print("[Friedhof] %s selbst beerdigt (Platz %d) um %s, %d Trauernde%s" % [guest.display_name, slot,
			Calendar.time_text(director.elapsed), _mourners.size(), " – unterbrochen: " + woke if woke != "" else ""])
	await _fade(false)
	player.spellbound = false
	burying = false
	Game.play_sound("bell")
	_thank(guest, GAIN_BURY)
	remember(player, [], false)
	if woke != "":
		Game.say(woke, 3.0)
	else:
		Game.say("Die Totenglocke läutet für %s." % guest.display_name, 4.0, "dead")


## Nicht beerdigen, solange das Monster unterwegs ist oder der Kürbismann kommt (der Garten ist sein Revier); der
## Lakengeist bleibt an den Fenstern und hält nicht auf.
func threat() -> bool:
	if Game.nightmare and Game.nightmare.active():
		return true
	if Game.monster and Game.monster.is_active():
		return true
	return Game.pumpkin != null and (Game.pumpkin.in_house() or Game.pumpkin.announcing())


## Grab anlegen und die Leiche wegnehmen. Gibt den Platz zurück.
func _bury(guest: Guest, by_player: bool) -> int:
	var slot := _free_slot(guest)
	var died := float(pending.get(guest.id, Game.director.elapsed))
	pending.erase(guest.id)
	graves[slot] = {"id": guest.id, "name": guest.display_name, "died": died, "at": Game.director.elapsed,
		"by_player": by_player, "flowers": false}
	guest.bury()
	_build_grave(slot)
	_place_shovel()
	return slot


## Zufälliger freier Platz – fest je Gast (gleicher Gast, gleicher Stand: gleicher Platz).
func _free_slot(guest: Guest) -> int:
	var free: Array[int] = []
	for i in slots.size():
		if not graves.has(i):
			free.append(i)
	if free.is_empty():
		return -1
	return free[absi(hash(guest.id)) % free.size()]


## Die Freunde des Toten stehen am Grab: sofort dort (selbst beerdigt, hinter der Schwarzblende) oder hingehen.
func _gather(dead: Guest, slot: int, at_once: bool) -> void:
	var s: Dictionary = slots[slot]
	var head: Vector3 = s["head"]
	var side := head.cross(Vector3.UP).normalized()
	var center: Vector3 = s["pos"]
	var spots: Array[Vector3] = []   # zu beiden Seiten des Grabs und am Fußende neben dem Spieler (er steht mittig dort)
	for k: float in [-0.78, 0.78]:
		spots.append(center - head * 0.3 + side * k)
	for k: float in [-0.78, 0.78]:
		spots.append(center + head * 0.35 + side * k)
	for k: float in [-0.55, 0.55]:
		spots.append(center - head * 1.45 + side * k)
	var until: float = Game.director.elapsed + randf_range(MOURN_TIME.x, MOURN_TIME.y)
	var i := 0
	for g in mourners_of(dead):
		if i >= spots.size():
			break
		g.fear = minf(g.fear, 50.0)   # zur Beerdigung fasst man sich (join_party nimmt keine Verängstigten)
		if at_once:
			g.global_position = spots[i]
			g.velocity = Vector3.ZERO
		g.join_party(spots[i], center)
		_mourners.append({"guest": g, "until": until})
		i += 1


## Familie zuerst, dann Freunde (6.16), höchstens MAX_MOURNERS; keiner, der versteckt ist oder gerade spricht.
func mourners_of(dead: Guest) -> Array[Guest]:
	var family: Array[Guest] = []
	var friends: Array[Guest] = []
	if Game.social == null or Game.social.pals == null:
		return family
	for other in Game.social.living_guests():
		var g: Guest = other
		if g.hiding or g.state == Guest.State.TALKING or _mourners.any(func(e: Dictionary) -> bool: return e["guest"] == g):
			continue
		var kin := g.housemate_of(dead) or String(g.profile.get("parent", "")) == dead.id 			or String(dead.profile.get("parent", "")) == g.id
		if kin:
			family.append(g)
		elif Game.social.pals.are_pals(dead, g):
			friends.append(g)
	family.append_array(friends)
	return family.slice(0, MAX_MOURNERS)


## Beziehung bei den Freunden des Toten (sie erzählen es weiter: GuestPals.praise über die Beziehung).
func _thank(dead: Guest, amount: float) -> void:
	if Game.social == null:
		return
	var all: Array[Guest] = mourners_of(dead)
	for e in _mourners:
		all.append(e["guest"])
	for g in all:
		if g.has_meta("cemetery_thanked_" + dead.id):
			continue
		g.set_meta("cemetery_thanked_" + dead.id, true)
		Game.social.change_relation(g, amount)


## Gedenken (Grab, Tafel, Trauerfeier): einmal je Spieltag spürbar weniger Schock.
func remember(player: Player, names: Array, say := true) -> void:
	var today := Calendar.day_of(Game.director.elapsed)
	if today != _comfort_day:
		_comfort_day = today
		player.shock = maxf(0.0, player.shock - COMFORT)
	if say and not names.is_empty():
		Game.say("Du stehst eine Weile still. %s." % ", ".join(names), 4.0)


# --- Ablauf ---------------------------------------------------------------------------------------

func _process(delta: float) -> void:
	_check -= delta
	if _check > 0.0 or burying:
		return
	_check = 0.5
	var d := Game.director
	if d == null or not has_place():
		return
	_update_funeral(d.elapsed)
	for i in range(_mourners.size() - 1, -1, -1):
		var e: Dictionary = _mourners[i]
		if not is_instance_valid(e["guest"]):
			_mourners.remove_at(i)
			continue
		var g: Guest = e["guest"]
		if g.dead or d.elapsed >= float(e["until"]) or g.state != Guest.State.PARTY:
			if not g.dead and g.state == Guest.State.PARTY:
				g.leave_party()
			_mourners.remove_at(i)
	for slot in graves:
		var g: Dictionary = graves[slot]
		if not g["flowers"] and d.elapsed - float(g["at"]) > FLOWERS_AFTER and _grave_nodes.has(slot) \
				and not d.player_can_see((_grave_nodes[slot] as Node3D).global_position + Vector3.UP * 0.3):
			g["flowers"] = true
			_flowers(_grave_nodes[slot])


## Gäste begraben, wer zu lange liegt: Glocke um 9:30, Trauerfeier um 10 Uhr.
func _update_funeral(now: float) -> void:
	var due: Array[String] = []
	var at := 0.0
	for id in pending:
		var t := funeral_time(float(pending[id]))
		if now >= t - (FUNERAL_HOUR - BELL_HOUR) * Calendar.HOUR:
			due.append(id)
			at = t
	if not due.is_empty() and Game.social:
		var ids: Array[String] = []
		for id in due:
			var g := Game.social.guest_by_id(id)
			if g == null or _free_slot(g) < 0:
				pending.erase(id)
				continue
			var slot := _bury(g, false)
			_gather(g, slot, false)
			ids.append(id)
		_funeral = {"at": at, "end": at + MOURN_TIME.y, "ids": ids, "attended": false}
		if not (Game.player and Game.player.sleeping):
			Game.play_sound("bell")
			Game.say("Die Totenglocke läutet. Um 10 Uhr ist die Trauerfeier auf dem Friedhof.", 4.0, "dead")
		if Game.tracing:
			print("[Friedhof] Glocke um %s – Trauerfeier für %s" % [Calendar.time_text(now), ", ".join(ids)])
	if _funeral.is_empty():
		return
	if now >= float(_funeral["end"]):
		_funeral = {}
		return
	var p := Game.player
	if not _funeral["attended"] and now >= float(_funeral["at"]) and p and not p.sleeping and _near_graves(p.global_position):
		_funeral["attended"] = true
		var names: Array = []
		for id in _funeral["ids"]:
			var g := Game.social.guest_by_id(id)
			if g:
				_thank(g, GAIN_ATTEND)
				names.append(g.display_name)
		remember(p, names, false)
		Game.say("Du stehst bei der Trauerfeier. %s." % ", ".join(names), 4.0)
		if Game.tracing:
			print("[Friedhof] Spieler bei der Trauerfeier")


## Erste 10 Uhr, die mindestens MIN_LIE nach dem Tod liegt.
func funeral_time(died: float) -> float:
	var day := Calendar.raw_day_of(died)
	var t := Calendar.at(day, FUNERAL_HOUR)
	while t - died < MIN_LIE:
		day += 1
		t = Calendar.at(day, FUNERAL_HOUR)
	return t


func _near_graves(p: Vector3) -> bool:
	for slot in _funeral.get("ids", []).map(func(id: String) -> int: return _slot_of(id)):
		if slot >= 0 and (slots[slot]["pos"] as Vector3).distance_to(p) < ATTEND_RANGE:
			return true
	return false


func _slot_of(id: String) -> int:
	for slot in graves:
		if graves[slot]["id"] == id:
			return slot
	return -1


## Zeitsprung im Schlaf: nichts zu tun – _process rechnet nach der Uhr.
func skip_time(_dt: float) -> void:
	pass


# --- Bild ------------------------------------------------------------------------------------------

func _fade(black: bool) -> void:
	if Game.hud:
		Game.hud.fade_black(black, FADE)
	await get_tree().create_timer(FADE, false).timeout


## Erdhügel, Holzkreuz am Kopfende, Grablicht davor, ein Kasten zum Ansehen.
func _build_grave(slot: int) -> void:
	if _grave_nodes.has(slot):
		return
	var s: Dictionary = slots[slot]
	var head: Vector3 = s["head"]
	var node := Node3D.new()
	add_child(node)
	node.global_position = s["pos"]
	node.basis = Basis.looking_at(head)   # −Z zum Kopfende, +Z zum Fußende
	var mound := Geo.mesh(node, Geo.sphere(0.5, 1.0, 12, 6), Mat.psx(SOIL, "", 1.0), Vector3(0, 0.0, 0.05))
	mound.scale = Vector3(0.8, 0.32, 1.8)
	var wood := Mat.wood(false, Color(0.5, 0.38, 0.28))
	Geo.mesh(node, Geo.box(Vector3(0.07, 1.0, 0.06)), wood, Vector3(0, 0.5, -0.92))     # Kreuz am Kopfende
	Geo.mesh(node, Geo.box(Vector3(0.5, 0.07, 0.06)), wood, Vector3(0, 0.72, -0.92))
	_grave_light(node, Vector3(0.18, 0.0, -0.78))
	var touch := GraveTouch.new()
	touch.cemetery = self
	touch.slot = slot
	touch.collision_layer = 4
	touch.collision_mask = 0
	touch.set_meta("interactable", touch)
	Geo.add_box_shape(touch, Vector3(0.8, 0.5, 2.0), Vector3(0, 0.25, 0))
	Geo.add_box_shape(touch, Vector3(0.5, 1.0, 0.1), Vector3(0, 0.5, -0.92))
	node.add_child(touch)
	_grave_nodes[slot] = node
	if graves.get(slot, {}).get("flowers", false):
		_flowers(node)


## Rotes Grablicht mit Flamme – geht nie aus (5.15).
func _grave_light(parent: Node3D, pos: Vector3, with_lamp := true) -> void:
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(GLASS, 0.8)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.emission_enabled = true
	glass.emission = GLASS
	glass.emission_energy_multiplier = 0.6
	glass.roughness = 0.15
	Geo.mesh(parent, Geo.cylinder(0.032, 0.1, 10), glass, pos + Vector3(0, 0.05, 0))
	Geo.mesh(parent, Geo.cylinder(0.034, 0.012, 10), Mat.metal(Color(0.7, 0.62, 0.4)), pos + Vector3(0, 0.103, 0))
	Geo.mesh(parent, Geo.sphere(0.009, 0.03, 6, 3), Mat.psx(FLAME, "", 1.0, FLAME, 3.0), pos + Vector3(0, 0.075, 0))
	if with_lamp:
		var light := FlickerLight.new()
		light.soft = true
		light.light_color = Color(1.0, 0.35, 0.2)
		light.omni_range = 1.6
		light.base_energy = 0.35
		light.position = pos + Vector3(0, 0.2, 0)
		parent.add_child(light)


## Ein kleiner Strauß am Kreuz.
func _flowers(node: Node3D) -> void:
	var colors := [Color(0.85, 0.82, 0.75), Color(0.75, 0.15, 0.2), Color(0.95, 0.75, 0.2)]
	for k in 5:
		var a := k * 1.3
		var p := Vector3(-0.15 + cos(a) * 0.05, 0.12, -0.6 + sin(a) * 0.05)
		var stem := Geo.mesh(node, Geo.cylinder(0.003, 0.16, 3), Mat.psx(Color(0.2, 0.35, 0.15)), p)
		stem.rotation.x = 1.2
		Geo.mesh(node, Geo.sphere(0.014, 0.024, 6, 3), Mat.psx(colors[k % colors.size()]), p + Vector3(0, 0.03, -0.07))


## Gedenkstätte: Holztafel auf zwei Pfosten, davor die Grabkerzen der Vermissten.
func _build_memorial() -> void:
	var root := Node3D.new()
	add_child(root)
	root.global_position = spot["pos"]
	var front: Vector3 = spot["front"]
	root.basis = Basis.looking_at(-front)   # +Z nach vorn
	var wood := Mat.wood(false, Color(0.45, 0.33, 0.24))
	for x in [-0.55, 0.55]:
		Geo.mesh(root, Geo.box(Vector3(0.09, 1.5, 0.09)), wood, Vector3(x, 0.75, -0.4))
	Geo.mesh(root, Geo.box(Vector3(1.3, 0.8, 0.05)), wood, Vector3(0, 1.05, -0.4))
	Geo.mesh(root, Geo.box(Vector3(1.4, 0.06, 0.12)), wood, Vector3(0, 1.48, -0.4))   # Dächlein
	_tablet = Label3D.new()
	_tablet.font_size = 40
	_tablet.pixel_size = 0.0016
	_tablet.modulate = Color(0.62, 0.58, 0.5)   # weiß ausgemalte Kerben, ungeschattet wie die Schilder im Hotel
	_tablet.outline_size = 0
	_tablet.width = 700.0
	_tablet.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tablet.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_tablet.position = Vector3(0, 1.38, -0.37)
	_tablet.shaded = false
	root.add_child(_tablet)
	_candle_root = Node3D.new()
	root.add_child(_candle_root)
	_candle_light = FlickerLight.new()
	_candle_light.soft = true
	_candle_light.light_color = Color(1.0, 0.35, 0.2)
	_candle_light.omni_range = 3.0
	_candle_light.base_energy = 0.0
	_candle_light.position = Vector3(0, 0.3, 0.1)
	root.add_child(_candle_light)
	var touch := TabletTouch.new()
	touch.cemetery = self
	touch.collision_layer = 4
	touch.collision_mask = 0
	touch.set_meta("interactable", touch)
	Geo.add_box_shape(touch, Vector3(1.3, 1.5, 0.3), Vector3(0, 0.75, -0.4))
	Geo.add_box_shape(touch, Vector3(1.3, 0.2, 0.6), Vector3(0, 0.1, 0.1))
	root.add_child(touch)
	_refresh_missing()


## Tafel und Kerzen aus den Toten: wer tot ist und weder liegt noch begraben ist, ist vermisst.
func _refresh_missing() -> void:
	if _tablet == null or Game.social == null:
		return
	var names: Array[String] = []
	for g in Game.social.guests:
		var guest: Guest = g
		if guest.dead and not guest.corpse and not guest.buried:
			names.append(guest.display_name)
	if names == _missing:
		return
	_missing = names
	_tablet.text = "Vermisst\n\n" + "\n".join(names) if not names.is_empty() else ""
	for c in _candle_root.get_children():
		c.queue_free()
	var per_row := 6
	for i in names.size():
		var row := i / per_row
		var col := i % per_row
		var n := mini(per_row, names.size() - row * per_row)
		var holder := Node3D.new()
		_candle_root.add_child(holder)
		_grave_light(holder, Vector3((col - (n - 1) / 2.0) * 0.16, 0.0, -0.2 + row * 0.16), false)
	_candle_light.base_energy = 0.0 if names.is_empty() else 0.45 + 0.06 * minf(names.size(), 8)


## Ab der ersten Beerdigung: die Schaufel im nächsten freien Grab (dem Platz, den der nächste Tote bekäme, ist der
## noch unbekannt – also der erste freie in Planreihenfolge).
func _place_shovel() -> void:
	if graves.is_empty():
		return
	var next := -1
	for i in slots.size():
		if not graves.has(i):
			next = i
			break
	if _shovel == null:
		_shovel = Node3D.new()
		add_child(_shovel)
		var wood := Mat.wood(false, Color(0.55, 0.42, 0.3))
		var metal := Mat.metal(Color(0.45, 0.43, 0.4))
		Geo.mesh(_shovel, Geo.cylinder(0.018, 1.0, 6), wood, Vector3(0, 0.55, 0))
		Geo.mesh(_shovel, Geo.box(Vector3(0.16, 0.03, 0.03)), wood, Vector3(0, 1.06, 0))
		Geo.mesh(_shovel, Geo.box(Vector3(0.2, 0.22, 0.012)), metal, Vector3(0, 0.03, 0))   # Blatt halb in der Erde
		Geo.mesh(_shovel, Geo.cylinder(0.2, 0.04, 8), Mat.psx(SOIL), Vector3(0, 0.0, 0)).scale = Vector3(1.0, 1.0, 0.6)
		var touch := ShovelTouch.new()
		touch.collision_layer = 4
		touch.collision_mask = 0
		touch.set_meta("interactable", touch)
		Geo.add_box_shape(touch, Vector3(0.25, 1.1, 0.15), Vector3(0, 0.55, 0))
		_shovel.add_child(touch)
	_shovel.visible = next >= 0
	if next >= 0:
		var s: Dictionary = slots[next]
		_shovel.global_position = (s["pos"] as Vector3) + (s["head"] as Vector3) * 0.3
		_shovel.rotation = Vector3(0.12, 0.6, 0.05)


# --- Speichern -------------------------------------------------------------------------------------

func save_state() -> Dictionary:
	var g := {}
	for slot in graves:
		g[str(slot)] = graves[slot]
	return {"graves": g, "pending": pending.duplicate()}


## Nach dem Laden der Gäste (SaveManager): Begrabene liegen nicht mehr da, Leichen ohne Eintrag warten ab jetzt.
func load_state(data: Dictionary) -> void:
	graves.clear()
	pending.clear()
	_mourners.clear()   # Gäste werden beim Laden neu gebaut – die alten sind freigegeben
	for n in _grave_nodes.values():
		(n as Node3D).queue_free()
	_grave_nodes.clear()
	var g: Dictionary = data.get("graves", {})
	for key in g:
		var slot := int(key)
		if slot < slots.size():
			graves[slot] = g[key]
			_build_grave(slot)
	var p: Dictionary = data.get("pending", {})
	for id in p:
		pending[String(id)] = float(p[id])
	if Game.social:
		for guest in Game.social.guests:
			var gg: Guest = guest
			if gg.dead and gg.corpse and not pending.has(gg.id):
				pending[gg.id] = Game.director.elapsed if Game.director else 0.0
	_place_shovel()
	_refresh_missing()


# --- Debug ------------------------------------------------------------------------------------------

## --beerdigen[=gast|jetzt]: ein Gast liegt erwürgt vor der Gedenkstätte – [E] beerdigt ihn · jetzt: nach 1,5 s von
## selbst (Rauchtest).
## --trauerfeier: zwei Gäste liegen seit gestern, einer ist vermisst (Tafel), es ist kurz vor halb zehn; du stehst vor
## der Gedenkstätte.
func debug_show(what: String) -> void:
	var d := Game.director
	d.first_attack_done = true
	if not has_place():
		push_warning("Friedhof: keine Grabplätze im Plan")
		return
	var victims: Array[Guest] = []
	if what.begins_with("beerdigen"):
		var id := what.get_slice(",", 1)
		var g := Game.social.guest_by_id(id) if id != "" and id != "jetzt" else null
		if g == null:
			for other in Game.social.living_guests():
				if not other.is_child() and not Game.social.pals.pals_of(other).is_empty():
					g = other
					break
		victims.append(g)
	else:
		for other in Game.social.living_guests():
			if victims.size() >= 2:
				break
			if not other.is_child() and not other.is_core():   # Kernfiguren sterben nie (4.33)
				victims.append(other)
	var stand: Vector3 = spot["pos"] + (spot["front"] as Vector3) * 2.5 if not spot.is_empty() else slots[0]["pos"]
	var front: Vector3 = spot["front"] if not spot.is_empty() else Vector3.RIGHT
	for i in victims.size():
		var g := victims[i]
		g.global_position = stand + front * 1.2 + front.cross(Vector3.UP) * (i * 1.2 - 0.6)
		d.guest_slain(g, "ghost")
	if what == "trauerfeier":
		for other in Game.social.living_guests():
			if not other.is_child() and not other.is_core() and not other in victims:
				other.die("monster")   # vermisst – kein Schrei, keine Meldung
				_refresh_missing()
				break
		d.elapsed = Calendar.at(Calendar.raw_day_of(d.elapsed) + 1, BELL_HOUR) - 20.0   # 20 s vor der Glocke
		for id in pending:
			pending[id] = d.elapsed - 12.0 * Calendar.HOUR   # gestern Abend gestorben
	TeleportUI.place_player(stand, front if what.begins_with("beerdigen") else -front)
	if what.ends_with(",jetzt"):
		get_tree().create_timer(1.5, false).timeout.connect(func() -> void: bury_by_player(victims[0]))
