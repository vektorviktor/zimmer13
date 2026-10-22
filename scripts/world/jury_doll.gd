class_name JuryDoll
extends StaticBody3D
## Die Puppe – „Halloween-Jury“ (Spielkonzept 5.5): das sichtbare Urteil des Abkommens. Kurz vor einem echten Angriff
## legt der MonsterDirector fest, vor welcher bewohnten Tür sie liegt (judge) – dort endet der Angriff, und wer drin
## ist, stirbt. Sie springt nur um, wenn der Spieler weder ihren alten noch ihren neuen Platz sieht. Niemand kann sie
## bewegen, außer Kindern zwischen den Angriffen: Sie nehmen sie zum Spielen mit und legen sie meist vor die Tür der
## eigenen Familie. Findet ein Gast sie vor seiner Tür, bekommt er Angst. Keine Bedrohung (4.1).
## Erreichbar über Game.doll; gespeichert unter „doll“ (save_state/load_state).

## Lage vor der Tür: so weit vom Flurpunkt door_front (0,9 m vor der Tür) zur Tür hin, mit dem Gesicht zur Tür
const DOOR_GAP := 0.4
## Umspringen: so oft wird geprüft, ob der Spieler gerade wegsieht
const MOVE_SCAN := 0.3
## Kinder: so oft schauen sie sich nach ihr um, so nah, mit dieser Chance holt eins sie; danach so lange Ruhe (s)
const KID_SCAN := 3.0
const KID_RANGE := 9.0
const KID_CHANCE := 0.2
const KID_REST := Vector2(90.0, 200.0)
## Gäste vor ihrer Tür: so nah bemerken sie sie, so viel Angst macht das
const NOTICE_RANGE := 5.0
const NOTICE_FEAR := 25.0
const NOTICE_LINES := ["Da sitzt diese Puppe vor meiner Tür …", "Wer hat mir die Puppe vor die Tür gesetzt?!",
	"Diese Puppe … sie guckt meine Tür an.", "Bei mir sitzt die Puppe. Das gefällt mir nicht."]
const KID_LINES := ["Die Puppe hat mich angeguckt!", "Komm, Puppe, wir gehen zu Mama!", "Psst, die Puppe schläft."]
const SKIN := Color(0.9, 0.84, 0.76)
const DRESS := Color(0.85, 0.42, 0.08)
## Größe gegenüber dem gebauten Modell (~0,5 m sitzend) – gut sichtbar im dunklen Flur
const SIZE := 1.35

## Zimmer, vor dessen Tür sie gerade urteilt ("" = kein Urteil, Kinder dürfen sie nehmen)
var verdict := ""
## Zimmer, vor dessen Tür sie liegt ("" = woanders, z. B. in der Lobby)
var at_room := ""
var carrier: Guest            ## Kind, das sie gerade trägt
var _fetcher: Guest           ## Kind auf dem Weg zu ihr
var _goal_room := ""          ## dorthin trägt das Kind sie (Tür der Familie)
var _pending := ""            ## Urteil steht, aber sie ist noch nicht umgesprungen
var _scan := 0.0
var _kid_scan := KID_SCAN
var _kid_rest := 60.0
var _noticed := {}            ## Gast-ID → true: hat sie bei diesem Urteil schon vor seiner Tür gesehen
var _builder: LevelBuilder


func setup(builder: LevelBuilder) -> JuryDoll:
	_builder = builder
	return self


func _ready() -> void:
	collision_layer = Item.LAYER   # nur für den Blick des Spielers – blockiert niemanden
	collision_mask = 0
	set_meta("interactable", self)
	add_to_group("jury_doll")
	_build()


## Startplatz: auf einem Sofa in der Lobby.
func place_at_start() -> void:
	var seats := _builder.cat_perches.filter(func(p: Dictionary) -> bool: return _builder.lobby_seats.has(p["floor"]))
	if seats.is_empty():
		global_position = _builder.lobby_center
		return
	var seat: Dictionary = seats[0]
	global_position = seat["top"]
	var out: Vector3 = (seat["floor"] as Vector3) - (seat["top"] as Vector3)
	rotation.y = atan2(out.x, out.z)


func get_prompt(_player: Player) -> String:
	return "Eine alte Puppe [E]"


func interact(_player: Player) -> void:
	Game.say("Sie lässt sich nicht hochheben – als wäre sie festgewachsen.", 3.0)


func is_judging() -> bool:
	return verdict != ""


## Urteil (MonsterDirector): Sie gehört vor die Tür von Zimmer `no` und springt dorthin, sobald niemand hinsieht.
## Ein Kind, das sie gerade trägt oder holen will, lässt sie fallen bzw. los.
func judge(no: String) -> void:
	if no == verdict:
		return
	verdict = no
	_noticed.clear()
	_drop_from_kid()
	_pending = no if no != at_room else ""
	if Game.tracing:
		print("[Puppe] Urteil: Zimmer %s%s" % [no, "" if _pending == "" else " – springt, sobald keiner hinsieht"])


## Der Angriff ist vorbei: Sie bleibt liegen, wo sie ist – Kinder dürfen sie wieder nehmen.
func release() -> void:
	verdict = ""
	_pending = ""
	_noticed.clear()


func _process(delta: float) -> void:
	if carrier:
		_carried_step()
	_scan -= delta
	if _scan > 0.0:
		return
	_scan = MOVE_SCAN
	if _pending != "":
		_try_jump()
	if verdict != "":
		_notice_residents()
	_kid_rest -= MOVE_SCAN
	_kid_scan -= MOVE_SCAN
	if _kid_scan <= 0.0:
		_kid_scan = KID_SCAN
		_update_kids()


## Springt vor die Tür des Urteils, wenn der Spieler weder hier noch dort hinsieht.
func _try_jump() -> void:
	var info: Dictionary = _builder.rooms.get(_pending, {})
	if info.is_empty():
		_pending = ""
		return
	var spot := _door_spot(info)
	if _seen(global_position) or _seen(spot["pos"]):
		return
	_place(spot, _pending)
	_pending = ""
	if Game.tracing:
		print("[Puppe] liegt jetzt vor Zimmer %s bei %s" % [at_room, global_position])


## Platz vor der Tür: zwischen Flur und Tür, mit dem Gesicht zur Tür.
func _door_spot(info: Dictionary) -> Dictionary:
	var into: Vector3 = info["into"]
	var p: Vector3 = (info["door_front"] as Vector3) + into * DOOR_GAP
	return {"pos": Vector3(p.x, (info["door_front"] as Vector3).y, p.z), "yaw": atan2(into.x, into.z)}


func _place(spot: Dictionary, room: String) -> void:
	global_position = spot["pos"]
	rotation = Vector3(0, float(spot["yaw"]), 0)
	at_room = room


func _seen(p: Vector3) -> bool:
	var player := Game.player
	if player == null or player.dead or Game.director == null:
		return false
	return Game.director.player_can_see(p + Vector3.UP * 0.3)


## Gäste, die sie vor der eigenen Tür sehen: Angst, und sie sagen es laut (einmal je Urteil).
func _notice_residents() -> void:
	if at_room != verdict or Game.social == null:
		return
	for guest in Game.social.living_guests():
		var g: Guest = guest
		if g.is_child() or _noticed.has(g.id) or String(g.home["no"]) != verdict or g.hiding != null:
			continue
		if g.global_position.distance_to(global_position) > NOTICE_RANGE or not _in_view(g):
			continue
		_noticed[g.id] = true
		g.fear = minf(100.0, g.fear + NOTICE_FEAR)
		g.say(NOTICE_LINES.pick_random())
		if Game.tracing:
			print("[Puppe] %s findet sie vor der eigenen Tür" % g.display_name)


## Sieht der Gast sie (Blickrichtung, freie Sicht)?
func _in_view(g: Guest) -> bool:
	var eye := g.global_position + Vector3.UP * g.eye_height()
	var to := global_position + Vector3.UP * 0.3 - eye
	return (-g.global_transform.basis.z).dot(to.normalized()) > 0.2 and Senses.clear_line(get_world_3d(), eye, eye + to, self)


# --- Kinder ---------------------------------------------------------------------------------

## Zwischen den Angriffen holt sich ab und zu ein Kind in der Nähe die Puppe (es muss sie sehen).
func _update_kids() -> void:
	if verdict != "" or carrier or Game.social == null:
		return
	if _fetcher:
		if not _fetcher_ok(_fetcher):
			_fetcher = null
		return
	if _kid_rest > 0.0 or Game.social.sleep_active:
		return
	for guest in Game.social.living_guests():
		var g: Guest = guest
		if not g.is_child() or not _kid_free(g) or g.global_position.distance_to(global_position) > KID_RANGE:
			continue
		if not Senses.clear_line(get_world_3d(), g.global_position + Vector3.UP * g.eye_height(), global_position + Vector3.UP * 0.3, self):
			continue
		if randf() >= KID_CHANCE:
			return
		_fetcher = g
		g._walk_to(global_position, Guest.State.WALK)
		return


func _kid_free(g: Guest) -> bool:
	return not g.dead and g.state in [Guest.State.IDLE, Guest.State.WALK] and g.fear < 40.0 and not g.is_following() \
		and g.held == null and String(g.get_meta("visit", "")) == ""


func _fetcher_ok(g: Guest) -> bool:
	return is_instance_valid(g) and not g.dead and g.state in [Guest.State.IDLE, Guest.State.WALK] and g.fear < 60.0


## Unterwegs: Ist das Kind da, nimmt es sie hoch und trägt sie vor die Tür der Familie.
func _physics_process(_delta: float) -> void:
	if _fetcher == null:
		return
	if not _fetcher_ok(_fetcher) or verdict != "":
		_fetcher = null
		return
	var flat := Vector2(_fetcher.global_position.x - global_position.x, _fetcher.global_position.z - global_position.z)
	if flat.length() > 1.0:
		if _fetcher.state == Guest.State.IDLE:
			_fetcher = null   # anders entschieden
		return
	carrier = _fetcher
	_fetcher = null
	var home := carrier.parent_guest()
	_goal_room = String((home if home and not home.dead else carrier).home["no"])
	at_room = ""
	carrier._walk_to(_builder.rooms[_goal_room]["door_front"], Guest.State.WALK)
	carrier.say(KID_LINES.pick_random())
	if Game.tracing:
		print("[Puppe] %s nimmt sie mit (zu Zimmer %s)" % [carrier.display_name, _goal_room])


## In den Armen des Kindes; ist es angekommen (oder macht etwas anderes), legt es sie ab – vor der Tür der Familie,
## wenn es dort ist.
func _carried_step() -> void:
	if not is_instance_valid(carrier) or carrier.dead:
		carrier = null
		return
	var hand: Node3D = carrier._hand
	global_position = hand.global_position + Vector3.DOWN * 0.15
	rotation = Vector3(0, carrier.rotation.y + PI, 0)
	if carrier.state == Guest.State.WALK:
		return
	var info: Dictionary = _builder.rooms.get(_goal_room, {})
	if not info.is_empty() and carrier.global_position.distance_to(info["door_front"]) < 2.5:
		_place(_door_spot(info), _goal_room)
	else:
		_put_down_here()
	if Game.tracing:
		print("[Puppe] %s legt sie ab%s" % [carrier.display_name, " vor Zimmer " + at_room if at_room != "" else ""])
	carrier = null
	_kid_rest = randf_range(KID_REST.x, KID_REST.y)


## Wo das Kind gerade steht, auf den Boden.
func _put_down_here() -> void:
	var p := global_position
	var hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.3, p + Vector3.DOWN * 2.0, 1))
	if not hit.is_empty():
		p = hit["position"]
	global_position = p
	rotation = Vector3(0, rotation.y, 0)
	at_room = ""


## Urteil: Ein Kind, das sie trägt oder holen will, lässt los – sie liegt dann, wo es steht.
func _drop_from_kid() -> void:
	_fetcher = null
	if carrier:
		carrier = null
		_put_down_here()


# --- Spielstand -----------------------------------------------------------------------------

func save_state() -> Dictionary:
	return {"pos": [global_position.x, global_position.y, global_position.z], "yaw": rotation.y, "verdict": verdict,
		"at_room": at_room, "pending": _pending}


func load_state(d: Dictionary) -> void:
	_fetcher = null
	carrier = null
	_noticed.clear()
	if d.is_empty():
		return
	var p: Array = d.get("pos", [0, 0, 0])
	global_position = Vector3(float(p[0]), float(p[1]), float(p[2]))
	rotation = Vector3(0, float(d.get("yaw", 0.0)), 0)
	verdict = String(d.get("verdict", ""))
	at_room = String(d.get("at_room", ""))
	_pending = String(d.get("pending", ""))


# --- Aussehen -------------------------------------------------------------------------------

## Sitzende Stoffpuppe (~0,5 m × SIZE): Porzellangesicht mit schwarzen Knopfaugen, orange-schwarzes Kleid, spitzer Hexenhut.
## Ursprung am Boden, Gesicht nach +Z.
func _build() -> void:
	var look := Node3D.new()   # alles in einem Knoten, damit sie sich als Ganzes vergrößern lässt
	look.scale = Vector3.ONE * SIZE
	add_child(look)
	var skin := Mat.psx(SKIN)
	var dress := Mat.psx(DRESS)
	var black := Mat.psx(Color(0.05, 0.04, 0.05))
	var stripes := Mat.psx(Color(0.92, 0.9, 0.85))
	# Beine nach vorn ausgestreckt, gestreifte Strümpfe, schwarze Schuhe
	for side: float in [-1.0, 1.0]:
		Geo.mesh(look, Geo.box(Vector3(0.05, 0.05, 0.2)), stripes, Vector3(side * 0.045, 0.03, 0.1))
		for i in 3:
			Geo.mesh(look, Geo.box(Vector3(0.054, 0.054, 0.02)), black, Vector3(side * 0.045, 0.03, 0.04 + i * 0.06))
		Geo.mesh(look, Geo.box(Vector3(0.06, 0.07, 0.08)), black, Vector3(side * 0.045, 0.045, 0.22))
	# Rock und Oberkörper
	Geo.mesh(look, Geo.cylinder(0.12, 0.12, 8), dress, Vector3(0, 0.07, 0))
	Geo.mesh(look, Geo.box(Vector3(0.15, 0.17, 0.1)), dress, Vector3(0, 0.2, 0))
	Geo.mesh(look, Geo.box(Vector3(0.16, 0.025, 0.11)), black, Vector3(0, 0.13, 0))   # Gürtel
	Geo.mesh(look, Geo.box(Vector3(0.12, 0.03, 0.11)), stripes, Vector3(0, 0.29, 0))  # Kragen
	# Arme hängen schlaff herunter
	for side: float in [-1.0, 1.0]:
		var arm := Geo.mesh(look, Geo.box(Vector3(0.04, 0.16, 0.045)), dress, Vector3(side * 0.1, 0.19, 0.01))
		arm.rotation.z = side * 0.18
		Geo.mesh(look, Geo.sphere(0.024, 0.04, 6, 3), skin, Vector3(side * 0.115, 0.1, 0.02))
	# Kopf, leicht geneigt
	var head := Node3D.new()
	head.position = Vector3(0, 0.37, 0)
	head.rotation = Vector3(0.12, 0, 0.16)
	look.add_child(head)
	Geo.mesh(head, Geo.sphere(0.075, 0.15, 10, 6), skin, Vector3.ZERO)
	Geo.mesh(head, Geo.sphere(0.08, 0.1, 10, 4), Mat.psx(Color(0.18, 0.08, 0.04)), Vector3(0, 0.03, -0.012))   # Haar
	for side: float in [-1.0, 1.0]:
		Geo.mesh(head, Geo.sphere(0.017, 0.022, 6, 3), black, Vector3(side * 0.028, 0.01, 0.066))   # Knopfaugen
		Geo.mesh(head, Geo.sphere(0.004, 0.006, 4, 2), stripes, Vector3(side * 0.028 + 0.005, 0.016, 0.079))
		Geo.mesh(head, Geo.sphere(0.012, 0.008, 6, 2), Mat.psx(Color(0.8, 0.45, 0.45)), Vector3(side * 0.045, -0.02, 0.058))
	Geo.mesh(head, Geo.box(Vector3(0.03, 0.006, 0.006)), Mat.psx(Color(0.45, 0.05, 0.05)), Vector3(0, -0.036, 0.07))   # Mund
	# Hexenhut: Krempe und schiefer Kegel
	Geo.mesh(head, Geo.cylinder(0.1, 0.01, 10), black, Vector3(0, 0.07, -0.005))
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.055
	cone.height = 0.13
	cone.radial_segments = 8
	var tip := Geo.mesh(head, cone, black, Vector3(0, 0.135, -0.01))
	tip.rotation.x = -0.25
	Geo.mesh(head, Geo.cylinder(0.057, 0.018, 10), dress, Vector3(0, 0.083, -0.005))   # Hutband
	Geo.add_box_shape(self, Vector3(0.28, 0.5, 0.32) * SIZE, Vector3(0, 0.25, 0.04) * SIZE)


## Debug (--doll=kind): Das erste Kind mit Eltern steht 3 m neben ihr und holt sie gleich (trägt sie vor die Tür der
## Familie). false = kein Kind oder sie urteilt gerade.
func debug_fetch() -> bool:
	var kids := Game.social.living_guests().filter(func(g: Guest) -> bool: return g.is_child() and g.parent_guest() != null)
	if kids.is_empty() or verdict != "":
		return false
	var kid: Guest = kids[0]
	var p := global_position + Vector3(3.0, 0.0, 0.0)
	var floor_hit := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3.UP, p + Vector3.DOWN * 2.0, 1))
	kid.global_position = (floor_hit["position"] as Vector3) + Vector3.UP * 0.05 if not floor_hit.is_empty() else p
	_kid_rest = 0.0
	_fetcher = kid
	kid._walk_to(global_position, Guest.State.WALK)
	return true
