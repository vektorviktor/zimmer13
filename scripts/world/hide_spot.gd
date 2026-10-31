class_name HideSpot
extends StaticBody3D
## Versteck (Kleiderschrank oder Bett), Mechanik angelehnt an Roblox „Doors“.
## Lokale +Z-Achse zeigt aus dem Versteck heraus. Spieler und (später) Gäste
## nutzen dieselbe Schnittstelle; „occupant“ reserviert den Platz.

enum Type { WARDROBE, BED }
## Ab dieser Breite (m) ist ein Bett ein Doppelbett für zwei (Haushalte, 6.20) – im Plan 1,50 m Einzel-, 2,20 m Doppelbett
const DOUBLE_WIDTH := 1.8
## Kleiderschrank (tools/build_wardrobe.py): Modell, gebackene Verschattung und Normale, Höhe (= TOP im Bauskript)
const WARDROBE_MODEL := "res://assets/models/wardrobe.glb"
const WARDROBE_AO := "res://assets/textures/wardrobe_ao.png"
const WARDROBE_NORMAL := "res://assets/textures/wardrobe_normal.png"
const WARDROBE_TOP := 2.18
static var _wardrobe := {}

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
## Zimmer des Betts (LevelBuilder.rooms, "" = keins) – auch in fremden Betten schläft man (Spielkonzept 3.6)
var room_no := ""
## Bett: Länge (lokal x) und Breite (lokal z) = Außenmaß des Balkenbetts (BedModel) aus dem Plan; vor dem Einfügen setzen
var bed_size := Vector2(2.1, 1.5)
## Bett: Seite des Kopfendes auf der lokalen x-Achse (−1 oder +1); heraus geht es immer nach +Z
var head_x := -1.0
## Bett: Plätze auf der Bettkante (Spielkonzept 3.1) – stehend [E] setzt sich, geduckt geht es darunter
var seat: Seat

var _visual: Node3D
var _leaves: Array[Node3D] = []
var _louvres: Array[MeshInstance3D] = []   # gemalte Lamellenfüllung je Tür
var _slats: Array[MeshInstance3D] = []     # echte Lamellen je Tür (Innensicht, show_inside)
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
	if _key_here(player):
		return "Zimmerschlüssel vom Nachttisch nehmen [E]"   # ein Gast schläft hier (Spielkonzept 6.19)
	var sleeper := _sleeper()
	if sleeper:
		return "%s wecken [E]" % sleeper.display_name
	if can_sleep(player):
		if occupant != null:
			return "Besetzt"
		if not own_bed:
			return "Im fremden Bett schlafen: %s [E]    (Mausrad: Dauer, ganz runter: hinsetzen)" % Player.hours_text(player.bed_hours)
		return "Schlafen: %s [E]    (Mausrad: Dauer · geduckt: unters Bett)" % Player.hours_text(player.sleep_hours)
	if _sits(player):
		var text := seat.get_prompt(player)
		return text + ("    (Mausrad: schlafen)" if sleepable(player) and text != "Besetzt" and player.seat == null else "")
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
	if _key_here(player):
		Game.social.access.steal_key(self)
		return
	var sleeper := _sleeper()
	if sleeper and Game.social:
		Game.social.wake_guest(sleeper)   # Spielkonzept 3.6
	elif can_sleep(player):
		if Game.shower_scare and Game.shower_scare.blocks_sleep():
			Game.say("Ich kann nicht schlafen, solange da Wasser läuft.", 3.0)   # Spielkonzept 4.24
		elif occupant == null:
			player.start_sleep(self)
	elif _sits(player):
		seat.interact(player)
	elif occupant == null:
		player.enter_hide(self)


## Ein Gast, der hier schläft (nicht verletzt im Krankenbett) – den kann man wecken (Spielkonzept 3.6).
func _sleeper() -> Guest:
	for node in [occupant, partner]:
		var g := node as Guest
		if g and not g.dead and g.is_asleep() and not g.in_sickbed():
			return g
	return null


## Schläft hier ein Gast in seinem Zimmer, dessen Schlüssel man nehmen kann (RoomAccess, Spielkonzept 6.19)?
func _key_here(player: Player) -> bool:
	return type == Type.BED and Game.social != null and Game.social.access != null \
		and Game.social.access.can_steal_key(self, player)


## Im eigenen Bett (Zimmer 13) schläft man, wann man will (Spielkonzept 3.6), im fremden, sobald man mit dem Mausrad
## Stunden gewählt hat (sonst setzt man sich auf die Kante) – geduckt kriecht man darunter.
func can_sleep(player: Player) -> bool:
	return sleepable(player) and (own_bed or player.bed_hours > 0)


## Hier kann man überhaupt schlafen: in jedem Bett eines Zimmers, stehend.
func sleepable(player: Player) -> bool:
	return type == Type.BED and (own_bed or room_no != "") and not player.crouching


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


## Kleiderschrank aus tools/build_wardrobe.py (ZIM-130): Korpus und Türen im Holz der Vertäfelung mit gebackener
## Verschattung und Normale (Furchen der Pfosten, Lamellen gemalt), Knöpfe, Bänder und Kleiderstange aus Messing wie
## im glTF. Je Tür ein Drehpunkt (Lage aus dem Modell) mit Rahmen, gemalter Füllung, echten Lamellen (Innensicht) und
## Knopf.
func _build_wardrobe() -> void:
	var parts := _wardrobe_parts()
	var wood := Mat.hotel_wood(WARDROBE_AO, WARDROBE_NORMAL)
	_wardrobe_part(_visual, parts["carcass"], wood)
	_wardrobe_part(_visual, parts["brass"], null)
	for s in ["l", "r"]:
		var pivot := Node3D.new()
		pivot.position = (parts["door_" + s][1] as Vector3)
		_visual.add_child(pivot)
		_wardrobe_part(pivot, parts["door_" + s], wood)
		_wardrobe_part(pivot, parts["knob_" + s], null)
		_louvres.append(_wardrobe_part(pivot, parts["louvre_" + s], wood))
		var slats := _wardrobe_part(pivot, parts["slats_" + s], Mat.hotel_wood())
		slats.visible = false
		_slats.append(slats)
		_leaves.append(pivot)
	Geo.add_box_shape(self, Vector3(1.12, WARDROBE_TOP, 0.6), Vector3(0, WARDROBE_TOP / 2.0, 0.01))
	view_point.position = Vector3(0, 1.6, 0.05)
	exit_point.position = Vector3(0, 0, 0.85)
	check_point.position = Vector3(0, 0, 1.05)


## Innensicht: Steckt der Spieler im Schrank, zeigen die Türen echte Lamellen statt der gemalten Füllung – durch die
## Schlitze sieht man hinaus (ZIM-130).
func show_inside(on: bool) -> void:
	for i in _louvres.size():
		_louvres[i].visible = not on
		_slats[i].visible = on


## Teile des Schrankmodells: Name → [Mesh, Lage des Knotens] (Material wie im glTF für die Messingteile)
static func _wardrobe_parts() -> Dictionary:
	if _wardrobe.is_empty():
		var scene: Node = (load(WARDROBE_MODEL) as PackedScene).instantiate()
		for mi: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
			_wardrobe[String(mi.name)] = [mi.mesh, mi.position]
		scene.free()
	return _wardrobe


## Teil unter parent: Mesh im Ursprung (Türteile liegen schon relativ zum Drehpunkt), mat = null → Material des Meshs
func _wardrobe_part(parent: Node3D, part: Array, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = part[0]
	mi.material_override = mat
	parent.add_child(mi)
	return mi


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
