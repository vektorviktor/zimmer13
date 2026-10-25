class_name HideSpot
extends StaticBody3D
## Versteck (Kleiderschrank oder Bett), Mechanik angelehnt an Roblox „Doors“.
## Lokale +Z-Achse zeigt aus dem Versteck heraus. Spieler und (später) Gäste
## nutzen dieselbe Schnittstelle; „occupant“ reserviert den Platz.

enum Type { WARDROBE, BED }
## Ab dieser Breite (m) ist ein Bett ein Doppelbett für zwei (Haushalte, 6.20) – im Plan 1,50 m Einzel-, 2,20 m Doppelbett
const DOUBLE_WIDTH := 1.8

var type := Type.WARDROBE
var occupant: Node = null
## Doppelbett: der zweite Schläfer eines Haushalts (Spielkonzept 6.20) – occupant und partner liegen nebeneinander
var partner: Node = null
## Das Monster hat gesehen, wie jemand hineingegangen ist → es holt ihn.
var seen_entering := false
## Vom Monster geprüft (Spur): Schranktür steht offen / Bett ist zerwühlt.
var checked := false
var view_point: Marker3D
var exit_point: Marker3D
var check_point: Marker3D
## Das Bett in Zimmer 13: Darin schläft der Spieler während der Nachtruhe (Spielkonzept 4.18).
var own_bed := false
## Bett: Länge (lokal x) und Breite (lokal z) = Außenmaß des Balkenbetts (BedModel) aus dem Plan; vor dem Einfügen setzen
var bed_size := Vector2(2.1, 1.5)
## Bett: Seite des Kopfendes auf der lokalen x-Achse (−1 oder +1); heraus geht es immer nach +Z
var head_x := -1.0
## Bett: Plätze auf der Bettkante (Spielkonzept 3.1) – stehend [E] setzt sich, geduckt geht es darunter
var seat: Seat

var _visual: Node3D
var _leaves: Array[Node3D] = []
var _blanket: Node3D
var _blanket_rest: Vector3


## Ein Doppelbett (breit genug für zwei), in dem schon jemand liegt, und der zweite Platz ist frei.
func takes_partner() -> bool:
	return type == Type.BED and bed_size.y >= DOUBLE_WIDTH and occupant != null and occupant is Guest and partner == null


## Seitlicher Versatz eines Schläfers (lokal z): im Doppelbett links und rechts, sonst mittig.
func sleep_offset(second: bool) -> float:
	if bed_size.y < DOUBLE_WIDTH:
		return 0.0
	return bed_size.y * (0.25 if second else -0.25)


## Platz freigeben, den who belegt (occupant oder partner).
func release(who: Node) -> void:
	if partner == who:
		partner = null
	elif occupant == who:
		occupant = partner
		partner = null


func setup(p_type: Type) -> HideSpot:
	type = p_type
	return self


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	set_meta("interactable", self)
	add_to_group("hide_spots")
	_visual = Node3D.new()
	add_child(_visual)
	view_point = _marker()
	exit_point = _marker()
	check_point = _marker()
	if type == Type.WARDROBE:
		_build_wardrobe()
	else:
		_build_bed()


func get_prompt(player: Player) -> String:
	if seat and player.seat == seat:
		return ""
	if can_sleep(player):
		if occupant != null:
			return "Besetzt"
		return "Schlafen: %s [E]    (Mausrad: Dauer · geduckt: unters Bett)" % Player.hours_text(player.sleep_hours)
	if _sits(player):
		return seat.get_prompt(player)
	if occupant != null and occupant != player:
		return "Besetzt"
	if checked and type == HideSpot.Type.BED:
		return "Das Bett ist zerwühlt … Unters Bett kriechen [E]"
	return "Im Schrank verstecken [E]" if type == Type.WARDROBE else "Unters Bett kriechen [E]"


## Aktions-Symbol über dem Hinweis (IconArt): Schlafen im eigenen Bett, sonst Verstecken – nicht beim Hinsetzen.
func get_icon(player: Player) -> String:
	if can_sleep(player):
		return "sleep" if occupant == null else ""
	if (seat and player.seat == seat) or _sits(player) or (occupant != null and occupant != player):
		return ""
	return "closet_enter"


func interact(player: Player) -> void:
	if seat and player.seat == seat:
		return
	if can_sleep(player):
		if Game.shower_scare and Game.shower_scare.blocks_sleep():
			Game.say("Ich kann nicht schlafen, solange da Wasser läuft.", 3.0)   # Spielkonzept 4.24
		elif occupant == null:
			player.start_sleep(self)
	elif _sits(player):
		seat.interact(player)
	elif occupant == null:
		player.enter_hide(self)


## Im eigenen Bett (Zimmer 13) schläft man, wann man will (Spielkonzept 3.6) – geduckt kriecht man darunter.
func can_sleep(player: Player) -> bool:
	return own_bed and not player.crouching


## Stehend auf ein Bett: auf die Kante setzen (auch wenn jemand darunter liegt).
func _sits(player: Player) -> bool:
	return seat != null and not player.crouching


## `actor`: wer hineingeht – die Schranktür ist Lärm (4.15).
func on_enter(actor: Node = null) -> void:
	set_checked(false)
	_set_leaves(deg_to_rad(7.0))
	Game.noise("hide", global_position, actor)


func on_exit() -> void:
	_set_leaves(0.0)
	seen_entering = false


## Spur „geprüftes Versteck“: Schranktüren bleiben halb offen, das Bett zerwühlt.
func set_checked(value: bool) -> void:
	checked = value
	if type == Type.WARDROBE:
		_set_leaves(deg_to_rad(38.0) if value else 0.0)
	elif _blanket:
		_blanket.position = _blanket_rest + (Vector3(head_x * 0.2, 0.03, 0.12) if value else Vector3.ZERO)
		_blanket.rotation = Vector3(0.06, 0.3, 0.04) if value else Vector3.ZERO


func save_state() -> Dictionary:
	return {"checked": checked}


func load_state(data: Dictionary) -> void:
	if bool(data.get("checked", false)) != checked:
		set_checked(bool(data.get("checked", false)))


## Das Monster reißt das Versteck auf.
func rip_open() -> void:
	Game.noise("hide_burst", global_position, Game.monster)
	_fling_open()


## Der Lakengeist (Spielkonzept 4.18): Die Schranktüren fliegen auf – leiser als beim Monster.
func burst_open(source: Node) -> void:
	Game.noise("rattle", global_position, source)
	_fling_open()


## Der Lakengeist wartet davor und rüttelt an den Türen.
func rattle() -> void:
	Game.play_sound("thud", 0.35)
	for i in _leaves.size():
		var tw := create_tween()
		tw.tween_property(_leaves[i], "rotation:y", _leaf_side(i) * deg_to_rad(14.0), 0.08)
		tw.tween_property(_leaves[i], "rotation:y", _leaf_side(i) * deg_to_rad(7.0), 0.12)


func _fling_open() -> void:
	var tw := create_tween().set_parallel(true)
	if type == Type.WARDROBE:
		for i in _leaves.size():
			tw.tween_property(_leaves[i], "rotation:y", _leaf_side(i) * deg_to_rad(115.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		# Das Bett fliegt hoch und fällt wieder zurück (blieb sonst bis zum nächsten Laden schweben)
		tw.set_parallel(false)
		tw.tween_property(_visual, "position", Vector3(0, 0.3, 0.35), 0.15).set_trans(Tween.TRANS_BACK)
		tw.tween_property(_visual, "position", Vector3.ZERO, 0.25).set_delay(0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _set_leaves(angle: float) -> void:
	for i in _leaves.size():
		create_tween().tween_property(_leaves[i], "rotation:y", _leaf_side(i) * angle, 0.2)


## Drehsinn der Schranktüren (0 = links, 1 = rechts), damit beide nach vorn aufgehen.
func _leaf_side(i: int) -> float:
	return -1.0 if i == 0 else 1.0


func _marker() -> Marker3D:
	var m := Marker3D.new()
	m.rotation.y = PI   # Blickrichtung (−Z) zeigt nach lokal +Z, also aus dem Versteck heraus
	add_child(m)
	return m


func _build_wardrobe() -> void:
	var wood := Mat.psx(Color(0.32, 0.2, 0.12))
	var door_wood := Mat.psx(Color(0.36, 0.23, 0.13))
	var dark := Mat.psx(Color(0.06, 0.04, 0.03))
	var brass := Mat.psx(Color(0.8, 0.65, 0.25))
	Geo.mesh(_visual, Geo.box(Vector3(1.1, 2.1, 0.56)), wood, Vector3(0, 1.05, -0.02))
	Geo.mesh(_visual, Geo.box(Vector3(1.18, 0.08, 0.64)), wood, Vector3(0, 2.14, 0))
	for side in [-1.0, 1.0]:
		var pivot := Node3D.new()
		pivot.position = Vector3(side * 0.55, 0.05, 0.28)
		_visual.add_child(pivot)
		var x: float = -side * 0.26
		Geo.mesh(pivot, Geo.box(Vector3(0.52, 2.0, 0.03)), door_wood, Vector3(x, 1.0, 0))
		for i in 7:
			Geo.mesh(pivot, Geo.box(Vector3(0.36, 0.022, 0.036)), dark, Vector3(x, 1.25 + i * 0.075, 0.003))
		Geo.mesh(pivot, Geo.box(Vector3(0.025, 0.12, 0.05)), brass, Vector3(-side * 0.48, 1.05, 0.02))
		_leaves.append(pivot)
	Geo.add_box_shape(self, Vector3(1.1, 2.1, 0.6), Vector3(0, 1.05, 0))
	view_point.position = Vector3(0, 1.6, 0.05)
	exit_point.position = Vector3(0, 0, 0.85)
	check_point.position = Vector3(0, 0, 1.05)


func _build_bed() -> void:
	var length := bed_size.x
	var width := bed_size.y
	_blanket = BedModel.build(_visual, bed_size, head_x)
	_blanket_rest = _blanket.position
	Geo.add_box_shape(self, Vector3(length, BedModel.TOP, width), Vector3(0, BedModel.TOP / 2.0, 0))
	# Kopfteil: ein Kasten über dem Kopfbalken, wie die Bretter geneigt
	var lean := deg_to_rad(BedModel.HEAD_TILT)
	var rise := 0.6
	var shape := Geo.add_box_shape(self, Vector3(0.1, rise, width),
			Vector3(head_x * (length / 2.0 - BedModel.POST / 2.0 + sin(lean) * rise / 2.0), BedModel.TOP + cos(lean) * rise / 2.0 - 0.1, 0))
	shape.rotation.z = -head_x * lean
	view_point.position = Vector3(-head_x * 0.2, 0.17, 0.15)
	exit_point.position = Vector3(0, 0, width / 2.0 + 0.525)
	check_point.position = Vector3(0, 0, width / 2.0 + 0.625)
	# Bettkante zum Hinsetzen (stehend [E]), zur Ausstiegsseite: auf der Matratze, ohne das Kopfkissen
	var room := BedModel.inner(bed_size)
	seat = Seat.attach(self, "bett", BedModel.TOP - 0.03, Vector3(-head_x * 0.25, 0, room.y / 2.0 - 0.15), Vector3.BACK, room.x - 0.5, 0.65)
	seat.prompt = "Auf die Bettkante setzen [E]    (geduckt: unters Bett)"
