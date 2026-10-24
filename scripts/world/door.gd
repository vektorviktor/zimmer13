class_name Door
extends Node3D
## Drehtür, einfach oder doppelt. Lokale +X = Türbreite, Scharnier im Ursprung (hinge_end: bei x = width),
## Boden auf y = 0. Sie geht nach lokal +Z auf. Türen liegen auf Kollisionsebene 2 und gehen nicht ins NavMesh ein,
## damit das Monster durch Türöffnungen planen kann (es öffnet sie dann selbst).

## Kollisionstiefe des Türblatts (= Wandstärke, siehe LevelBuilder.T)
const COLLISION_DEPTH := 0.2

## Aussehen des Blatts: im Code gebaut (Betriebs- und Glastüren) oder eines der gemalten Modelle aus
## tools/build_doors.py – Zimmertür bzw. Kniestocktür zum Dachboden (Spielkonzept 4.21)
enum Look { PLAIN, HOTEL, ATTIC }
const HOTEL_MODEL := "res://assets/models/door_hotel.glb"
const ATTIC_MODEL := "res://assets/models/door_attic.glb"
## Blattgröße der Modelle (Meter, wie im Skript) – gestreckt auf die Tür, Klinke und Bänder bleiben, wie sie sind
const HOTEL_LEAF := Vector2(1.18, 2.08)
const ATTIC_LEAF := Vector2(0.78, 1.55)
## Klinke: Abstand der Drückerachse von der Schlosskante und Höhe über dem Boden
const HANDLE_INSET := 0.1
const HANDLE_HEIGHT := 1.04
## Bänder der Zimmertür als Anteil der Blatthöhe (wie gemalt)
const HINGE_AT: Array[float] = [0.12, 0.62, 0.88]

var width := 1.2
var height := 2.1
var open_angle := deg_to_rad(-100.0)
var double := false
var locked := false
var key_id := ""
var locked_text := "Abgeschlossen."
var monster_can_open := true
var glass := false          ## Glastür: man sieht hindurch (Ebene 7 statt 2)
var look := Look.PLAIN      ## vor dem Einhängen setzen (nicht bei Glastüren)
var hinge_end := false      ## einfache Tür: Scharnier bei x = width statt im Ursprung (Türanschlag im Plan)
## Fenstertür nach draußen (Terrasse, Garten, Balkon; Gruppe „french_doors“): Raum dahinter und Richtung nach
## draußen – dort erscheint auch der Lakengeist (Spielkonzept 4.18)
var room_id := ""
var outward := Vector3.ZERO
var is_open := false
## Zuletzt vom Monster aufgerissen (nicht vom Spieler oder einem Gast)
var opened_by_monster := false
## Zimmertür (Spielkonzept 6.19): Nummer des Zimmers dahinter (LevelBuilder._room). Ein Gästezimmer gehört seinem
## Haushalt, ein unbewohntes dem Hotel (vacant) – beide sind abgeschlossen, Hineinkommen nur mit Einlass,
## Schlüssel oder Gewalt
var room_no := ""
var vacant := false
## Wer dahinter wohnt (Haushalt, 6.20) – steht beim Hinsehen vor dem Hinweis
var resident_name := ""
## Aufgebrochen (vom Spieler oder vom Monster, 5.5): steht offen und schließt nicht mehr, bis jemand sie repariert
var broken := false
var broken_by_player := false
var broken_day := 0          ## Tag des Aufbrechens – der Besitzer repariert frühestens am nächsten Morgen
var _working := false
## Werkzeug an der Tür (6.19): Aufbrechen und Reparieren dauern so lange (s), so nah muss man dabeibleiben (m)
const FORCE_TIME := 4.0
const REPAIR_TIME := 6.0
const WORK_RANGE := 2.0

var _pivots: Array[Node3D] = []
var _bodies: Array[Node3D] = []
var _dirs: Array[float] = []   ## je Flügel: +1 = Blatt nach +X vom Scharnier, −1 = nach −X
var _tween: Tween

## Türen nach Feldern im Grundriss (Kantenlänge CELL), für Gäste, die laufend die Türen in ihrer Nähe
## abfragen (near). Türen bewegen sich nicht; das Raster entsteht beim ersten Abfragen nach dem Bau neu.
const CELL := 4.0
static var _all: Array[Door] = []
static var _cells := {}
static var _dirty := true
## Teile der Modelle (Pfad → {Name: [Mesh, Material]}), einmal geladen für alle Türen
static var _models := {}


func setup(p_width: float, p_height: float, p_open_angle_deg: float, p_double: bool = false, p_glass: bool = false,
		p_hinge_end: bool = false) -> Door:
	width = p_width
	height = p_height
	open_angle = deg_to_rad(p_open_angle_deg)
	double = p_double
	glass = p_glass
	hinge_end = p_hinge_end and not p_double
	return self


func _ready() -> void:
	add_to_group("doors")
	add_child(OpeningFrame.new().setup(0.0, 0.0, width, height, COLLISION_DEPTH))   # Zarge und Bekleidung
	if double:
		_pivots.append(_make_leaf(Vector3.ZERO, width / 2.0, 1.0))
		_pivots.append(_make_leaf(Vector3(width, 0, 0), width / 2.0, -1.0))
	elif hinge_end:
		_pivots.append(_make_leaf(Vector3(width, 0, 0), width, -1.0))
	else:
		_pivots.append(_make_leaf(Vector3.ZERO, width, 1.0))
	ShadowBudget.structure(self)   # Zarge und Blatt halten das Licht aller Lampen auf
	_all.append(self)
	_dirty = true


func _exit_tree() -> void:
	_all.erase(self)
	_dirty = true


func center() -> Vector3:
	return global_transform * Vector3(width / 2.0, height / 2.0, 0.0)


## Hält der Spieler dieses Werkzeug in der Hand?
func _holding(player: Player, kind: Item.Kind) -> bool:
	return player.held != null and player.held.kind == kind


## Zimmertür eines Gäste- oder unbewohnten Zimmers – die lässt sich aufbrechen (nicht Zimmer 18, Ausgang, Gesperrtes).
func _forcible() -> bool:
	return room_no != "" and monster_can_open and key_id == "zimmer_%s" % room_no


## Der Generalschlüssel passt – außer, jemand aus dem Zimmer ist drin und hat den Riegel vorgeschoben (6.19).
func _general_fits(player: Player) -> bool:
	if not _forcible() or not player.has_key(KeyCabinet.KEY_ID):
		return false
	return Game.social == null or Game.social.access.residents_home(room_no).is_empty()


## Arbeit mit einem Werkzeug an der Tür (Aufbrechen, Reparieren): dauert duration s, der Spieler muss mit dem Werkzeug
## in der Hand dabeibleiben.
func _work(player: Player, tool: Item.Kind, duration: float, text: String, done: Callable) -> void:
	if _working:
		return
	_working = true
	Game.say(text, duration)
	if tool == Item.Kind.CROWBAR:
		Game.noise("rattle", center(), player)
	get_tree().create_timer(duration, false).timeout.connect(func() -> void:
		_working = false
		if not _holding(player, tool) or player.global_position.distance_to(center()) > WORK_RANGE:
			Game.say("Abgebrochen.")
			return
		done.call(player))


## Aufgebrochen (6.19): laut, steht offen, schließt nicht mehr – Zeugen und Besitzer erfahren davon (RoomAccess).
func _forced(player: Player) -> void:
	locked = false
	broken = true
	broken_by_player = true
	broken_day = Calendar.today()
	set_open(true, true, true, player)
	Game.noise("door_force", center(), player)
	if Game.social and Game.social.access:
		Game.social.access.on_forced(self, true)


func _repaired(player: Player) -> void:
	var own := broken_by_player
	broken = false
	broken_by_player = false
	if _forcible() and Game.social and Game.social.builder.room_at(player.global_position) != room_no:
		locked = true   # das Schloss hält wieder – wer draußen steht, sperrt niemanden ein
	Game.noise("repair", center(), player)
	Game.say("Die Tür schließt wieder.")
	if Game.social and Game.social.access:
		Game.social.access.on_repaired(self, own)


## Steht der Spieler im Zimmer hinter dieser Tür (oder in dessen Bad)? Von innen geht eine abgeschlossene Zimmertür
## einfach auf – das Schloss hält nur draußen fest, niemand wird eingesperrt.
func _inside(player: Player) -> bool:
	return room_no != "" and Game.social != null and Game.social.builder.home_room_at(player.global_position) == room_no


## Bewohntes Gästezimmer: Wer davorsteht, kann klopfen (Spielkonzept 6.19).
func _knockable() -> bool:
	return room_no != "" and not vacant and room_no != LevelBuilder.PLAYER_ROOM and Game.social != null \
		and Game.social.access != null


## Einen Spalt weit öffnen (Gespräch an der Tür, 6.19) – zählt nicht als offen, man kommt nicht hindurch.
func set_ajar(degrees: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	for i in _pivots.size():
		_tween.tween_property(_pivots[i], "rotation:y", deg_to_rad(degrees) * signf(open_angle) * _dirs[i], 0.4) \
			.set_trans(Tween.TRANS_SINE)
	ShadowBudget.wake = true


## Lässt die Tür Licht durch (LightRooms)? Offen – und beim Zufallen, bis das Blatt wirklich zu ist (Rütteln bleibt
## darunter).
func lets_light() -> bool:
	if is_open:
		return true
	for pivot in _pivots:
		if absf(pivot.rotation.y) > 0.03:
			return true
	return false


## Türen, deren Mitte höchstens CELL (im Grundriss) von pos entfernt sein kann – also eine Vorauswahl.
static func near(pos: Vector3) -> Array:
	if _dirty:
		_cells.clear()
		for door in _all:
			var c := door.center()
			var key := Vector2i(floori(c.x / CELL), floori(c.z / CELL))
			if not _cells.has(key):
				_cells[key] = []
			(_cells[key] as Array).append(door)
		_dirty = false
	var found := []
	var cx := floori(pos.x / CELL)
	var cz := floori(pos.z / CELL)
	for x in range(cx - 1, cx + 2):
		for z in range(cz - 1, cz + 2):
			found.append_array(_cells.get(Vector2i(x, z), []))
	return found


func get_prompt(player: Player) -> String:
	var text := _prompt(player)
	if resident_name == "" or text == "" or _inside(player):   # das Namensschild hängt draußen
		return text
	return "%s · %s" % [resident_name, text]


## Aktions-Symbol über dem Hinweis (IconArt).
func get_icon(_player: Player) -> String:
	return "door"


func _prompt(player: Player) -> String:
	if broken:
		return "Reparieren [E]" if _holding(player, Item.Kind.TOOLBOX) else "Aufgebrochen"
	if locked and not _inside(player):
		if player.has_key(key_id) or _general_fits(player):
			return "Hände voll" if player.hands_blocked() else "Aufschließen [E]"
		if _forcible() and _holding(player, Item.Kind.CROWBAR):
			return "Aufbrechen [E]"
		if _knockable():
			return "Klopfen [E]"
		return "Verschlossen"
	if player.hands_blocked():
		return "Hände voll"
	return "Tür schließen [E]" if is_open else "Tür öffnen [E]"


func interact(player: Player) -> void:
	if broken:
		if _holding(player, Item.Kind.TOOLBOX):
			_work(player, Item.Kind.TOOLBOX, REPAIR_TIME, "Du richtest Schloss und Zarge …", _repaired)
		else:
			Game.say("Die Tür ist aufgebrochen und schließt nicht mehr. Mit Werkzeug ließe sie sich reparieren.")
		return
	if locked and _inside(player):
		locked = false   # von innen: Klinke drücken, die Tür geht auf (abschließen tut der Besitzer wieder)
	if locked:
		var general := not player.has_key(key_id) and _general_fits(player)
		if (player.has_key(key_id) or general) and player.hands_blocked():
			Game.say("Mit vollen Händen kommst du nicht an den Schlüssel.")
		elif player.has_key(key_id) or general:
			locked = false
			Game.say("Aufgeschlossen.")
			Game.noise("unlock", center(), player)
			set_open(true, false, false, player)
			if general and Game.social and Game.social.access:
				Game.social.access.on_forced(self, false)   # mit dem Generalschlüssel in ein fremdes Zimmer (6.19)
			SaveManager.request_autosave("Tür aufgeschlossen")
		elif _forcible() and _holding(player, Item.Kind.CROWBAR):
			_work(player, Item.Kind.CROWBAR, FORCE_TIME, "Du setzt das Brecheisen an …", _forced)
		elif _knockable():
			Game.social.access.knock(self)   # Gästezimmer: klopfen (Spielkonzept 6.19)
		else:
			Game.say(locked_text)
			Game.noise("rattle", center(), player)
			_rattle()
		return
	if player.hands_blocked():
		Game.say("Mit vollen Händen geht das nicht.")
		return
	set_open(not is_open, false, false, player)


## `source`: wer die Tür bewegt (hört das eigene Knarren nicht als Lärm, 4.15).
func set_open(open: bool, fast: bool = false, quiet: bool = false, source: Node = null) -> void:
	if broken and not open:
		return   # aufgebrochen: schließt nicht mehr (6.19)
	is_open = open
	ShadowBudget.wake = true   # Lichter dahinter sofort ein- bzw. nach dem Zufallen ausschalten
	opened_by_monster = false
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	for i in _pivots.size():
		var target := open_angle * _dirs[i] if open else 0.0
		_tween.tween_property(_pivots[i], "rotation:y", target, 0.25 if fast else 0.6).set_trans(Tween.TRANS_SINE)
	if not quiet:
		Game.noise("door", center(), source)


## Das Monster reißt die Tür auf (auch abgeschlossene – außer der Lobbytür).
func monster_open() -> void:
	if is_open or not monster_can_open:
		return
	if locked and room_no != "":   # „Die Tür fällt, auch abgeschlossene“ (5.5): danach ist sie kaputt (6.19)
		broken = true
		broken_by_player = false
		broken_day = Calendar.today()
	locked = false
	set_open(true, true, true)
	opened_by_monster = true
	Game.noise("door_burst", center(), Game.monster)


## Spur auf dem (ersten) Türflügel anbringen; side = Seite der Tür (lokale ±Z).
## `at`: Lage auf dem Blatt (x als Anteil der Blattbreite, y in Metern) – Kratzer mittig, Handabdrücke höher.
func attach_mark(mark: TraceMark, side: float, at := Vector2(0.45, 1.35)) -> void:
	var leaf_width := width / 2.0 if double else width
	mark.solid = false
	mark.set_meta("door_side", side)
	mark.set_meta("door_at", at)
	_bodies[0].add_child(mark)
	mark.position = Vector3(_dirs[0] * leaf_width * at.x, at.y, side * 0.04)
	mark.rotation.y = 0.0 if side > 0.0 else PI


func _rattle() -> void:
	if is_open:
		return
	for pivot in _pivots:
		var tw := create_tween()
		for offset in [0.025, -0.025, 0.02, 0.0]:
			tw.tween_property(pivot, "rotation:y", offset, 0.05)


func _make_leaf(origin: Vector3, leaf_width: float, dir: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.position = origin
	add_child(pivot)
	var body := AnimatableBody3D.new()
	body.collision_layer = 64 if glass else 2
	body.collision_mask = 0
	body.sync_to_physics = false
	body.set_meta("interactable", self)
	pivot.add_child(body)
	_bodies.append(body)
	_dirs.append(dir)
	var leaf_size := Vector3(leaf_width - 0.02, height - 0.02, 0.06)
	var cx := dir * leaf_width / 2.0
	if glass:
		var frame := Mat.psx(Color(0.85, 0.85, 0.8))
		Geo.mesh(body, Geo.box(Vector3(leaf_width - 0.2, height - 0.2, 0.02)), Mat.glass(), Vector3(cx, height / 2.0, 0))
		Geo.mesh(body, Geo.box(Vector3(leaf_width - 0.02, 0.1, 0.06)), frame, Vector3(cx, 0.05, 0))
		Geo.mesh(body, Geo.box(Vector3(leaf_width - 0.02, 0.1, 0.06)), frame, Vector3(cx, height - 0.05, 0))
		Geo.mesh(body, Geo.box(Vector3(0.1, height - 0.02, 0.06)), frame, Vector3(dir * 0.05, height / 2.0, 0))
		Geo.mesh(body, Geo.box(Vector3(0.1, height - 0.02, 0.06)), frame, Vector3(dir * (leaf_width - 0.06), height / 2.0, 0))
		Geo.mesh(body, Geo.box(Vector3(leaf_width - 0.02, 0.05, 0.05)), frame, Vector3(cx, height * 0.55, 0))
	elif look == Look.PLAIN:
		Geo.mesh(body, Geo.box(leaf_size), Mat.psx(Color(0.3, 0.17, 0.1)), Vector3(cx, height / 2.0, 0))
		# Kassetten als Relief
		var panel := Mat.layer(Color(0.24, 0.13, 0.08))
		for y in [0.6, 1.5]:
			Geo.mesh(body, Geo.box(Vector3(leaf_width * 0.6, 0.55, 0.075)), panel, Vector3(cx, y * height / 2.1, 0))
	else:
		_add_model_leaf(body, leaf_size, dir)
	# Kollision so tief wie die Wand: Ein dünnes Türblatt bildet eine Nische, in der die
	# Spielerkapsel beim schrägen Entlanglaufen an der Wand hängenbleibt.
	Geo.add_box_shape(body, Vector3(leaf_size.x, leaf_size.y, COLLISION_DEPTH), Vector3(cx, height / 2.0, 0))
	if glass or look == Look.PLAIN:
		var brass := Mat.psx(Color(0.8, 0.65, 0.25))
		for z in [0.05, -0.05]:
			Geo.mesh(body, Geo.sphere(0.035, 0.07, 6, 3), brass, Vector3(dir * (leaf_width - 0.1), 1.0, z))
	return pivot


## Gemaltes Blatt (Look.HOTEL/ATTIC): auf die Blattgröße gestreckt, bei dir = −1 gespiegelt (Scharnier rechts).
## Klinke und Bänder der Zimmertür ungestreckt – sie sehen an schmalen Badtüren aus wie an breiten Zimmertüren.
func _add_model_leaf(body: Node3D, leaf_size: Vector3, dir: float) -> void:
	var hotel := look == Look.HOTEL
	var parts := _model_parts(HOTEL_MODEL if hotel else ATTIC_MODEL)
	var ref := HOTEL_LEAF if hotel else ATTIC_LEAF
	var leaf := Geo.mesh(body, parts["leaf"][0], parts["leaf"][1], Vector3(dir * 0.01, 0.01, 0))
	leaf.scale = Vector3(dir * leaf_size.x / ref.x, leaf_size.y / ref.y, 1.0)
	if not hotel:
		return
	var handle := Geo.mesh(body, parts["handle"][0], parts["handle"][1],
		Vector3(dir * (leaf_size.x + 0.01 - HANDLE_INSET), HANDLE_HEIGHT, 0))
	handle.scale.x = dir   # Drücker zeigt zum Scharnier
	for at in HINGE_AT:
		var hinge := Geo.mesh(body, parts["hinge"][0], parts["hinge"][1], Vector3(dir * 0.008, 0.01 + at * leaf_size.y, 0))
		hinge.scale.x = dir


static func _model_parts(path: String) -> Dictionary:
	if not _models.has(path):
		var parts := {}
		var scene: Node = (load(path) as PackedScene).instantiate()
		for mi: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
			parts[String(mi.name)] = [mi.mesh, Mat.model(path, mi)]
		scene.free()
		_models[path] = parts
	return _models[path]
