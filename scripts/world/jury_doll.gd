class_name JuryDoll
extends StaticBody3D
## Die Puppe – „Halloween-Jury“ (Spielkonzept 5.5): das sichtbare Urteil des Abkommens. Kurz vor einem echten Angriff
## legt der MonsterDirector fest, vor welcher bewohnten Tür sie liegt (judge) – dort endet der Angriff, und wer drin
## ist, stirbt. Sie springt nur um, wenn der Spieler weder ihren alten noch ihren neuen Platz sieht. Niemand kann sie
## bewegen, außer Kindern zwischen den Angriffen: Sie nehmen sie zum Spielen mit und legen sie meist vor die Tür der
## eigenen Familie. Findet ein Gast sie vor seiner Tür, bekommt er Angst. Keine Bedrohung (4.1).
## Bis zum ersten Angriff ist sie die Jury des Türschmuck-Wettbewerbs (2.5): ein Schildchen „Jury“ vor ihr, kein Kind
## nimmt sie mit. Bei der Siegerehrung steht sie auf, schwebt (stand_pose, DoorContest bewegt sie) und löst sich in
## Rauch auf (vanish) – bis zum nächsten Urteil ist sie fort und taucht dann vor der Tür auf.
## Erreichbar über Game.doll; gespeichert unter „doll“ (save_state/load_state).

## Lage vor der Tür: so weit vom Flurpunkt door_front (0,9 m vor der Tür) zur Tür hin, mit dem Gesicht zur Tür
const DOOR_GAP := 0.25
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
## Meshy-Puppe (tools/build_doll.py): 1,7 m in A-Pose, Blick nach +Z, Mixamo-Knochen
const MODEL := "res://assets/models/doll.glb"
## Größe gegenüber dem Modell: sitzend ~0,65 m, stehend 1,1 m – gut sichtbar im dunklen Flur
const SIZE := 0.65
## Sitzfläche unter dem Ursprung des Modells (m, Modellmaß): Hüftgelenk ~0,76 m minus halber Oberschenkel
const SEAT := 0.68
## Kopfmitte über dem Boden, sitzend (m) – dorthin schauen Gäste und Spieler bei der Siegerehrung (DoorContest)
const HEAD_HEIGHT := (1.45 - SEAT) * SIZE
## Sitzen: Arme aus der A-Pose (45°) so weit zum Körper (rad), Kopf leicht geneigt (Modellachsen)
const ARM_DOWN := 0.4
const HEAD_TILT := Vector3(0.12, 0, 0.16)

## Zimmer, vor dessen Tür sie gerade urteilt ("" = kein Urteil, Kinder dürfen sie nehmen)
var verdict := ""
## Zimmer, vor dessen Tür sie liegt ("" = woanders, z. B. in der Lobby)
var at_room := ""
## Seit der Siegerehrung fort (2.5): unsichtbar, bis sie vor der Tür des nächsten Urteils auftaucht
var gone := false
var carrier: Guest            ## Kind, das sie gerade trägt
var _fetcher: Guest           ## Kind auf dem Weg zu ihr
var _goal_room := ""          ## dorthin trägt das Kind sie (Tür der Familie)
var _pending := ""            ## Urteil steht, aber sie ist noch nicht umgesprungen
var _scan := 0.0
var _kid_scan := KID_SCAN
var _kid_rest := 60.0
var _noticed := {}            ## Gast-ID → true: hat sie bei diesem Urteil schon vor seiner Tür gesehen
var _builder: LevelBuilder
var _skeleton: Skeleton3D
var _bones := {}              ## Knochenname → Index (Beine, Arme, Kopf: Sitzen und Aufstehen)
var _body: MeshInstance3D
var _skirt := -1              ## Formschlüssel „sit“: Rock liegt auf den Beinen (tools/build_doll.py)
var _card: Node3D             ## Schildchen „Jury“ (Wettbewerb, 2.5)


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
	return "Die Jury [E]" if _card and _card.visible else "Eine alte Puppe [E]"


func interact(_player: Player) -> void:
	if Game.achievements:
		Game.achievements.unlock("jury_doll")   # Spielkonzept 8.11
	if _card and _card.visible:
		Game.say("Ein Schildchen vor ihr: „Jury“. Sie lässt sich nicht hochheben – als wäre sie festgewachsen.", 3.5)
	else:
		Game.say("Sie lässt sich nicht hochheben – als wäre sie festgewachsen.", 3.0)


## Schildchen „Jury“ zeigen (bis zur Siegerehrung, DoorContest).
func show_card(value: bool) -> void:
	if _card:
		_card.visible = value


## Aufstehen bei der Siegerehrung (0 = sitzt, 1 = steht): die Beine schwingen nach unten, der Kopf richtet sich auf,
## der Rock löst sich vom Schoß und hängt wieder als Glocke.
## Der Ursprung bleibt auf der Sitzfläche – stehend hängen die Beine darunter (sie schwebt dann ohnehin).
func stand_pose(k: float) -> void:
	var sit := 1.0 - k
	for side: float in [1.0, -1.0]:
		var prefix := "Left" if side > 0.0 else "Right"   # ihre Linke liegt bei +X
		_turn(prefix + "UpLeg", Vector3.RIGHT, -PI / 2.0 * sit)   # Beine nach vorn ausgestreckt
		_turn(prefix + "Arm", Vector3.BACK, -side * ARM_DOWN)
	_turn("Head", HEAD_TILT.normalized(), HEAD_TILT.length() * sit)
	_body.set_blend_shape_value(_skirt, sit)


## Dreht einen Knochen aus der Ruhepose um eine Achse im Modellraum (die Eltern stehen in Ruhepose).
func _turn(bone: String, axis: Vector3, angle: float) -> void:
	var i: int = _bones[bone]
	var parent := _skeleton.get_bone_global_rest(_skeleton.get_bone_parent(i)).basis
	var local := parent.inverse() * Basis(axis, angle) * parent * _skeleton.get_bone_rest(i).basis
	_skeleton.set_bone_pose_rotation(i, local.get_rotation_quaternion())


## In Rauch aufgelöst (Siegerehrung): fort, bis sie vor der Tür des nächsten Urteils liegt.
func vanish() -> void:
	gone = true
	visible = false
	collision_layer = 0
	at_room = ""
	stand_pose(0.0)
	show_card(false)


func _reappear() -> void:
	gone = false
	visible = true
	collision_layer = Item.LAYER


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
	if (not gone and _seen(global_position)) or _seen(spot["pos"]):
		return
	if gone:
		_reappear()
	_place(spot, _pending)
	_pending = ""
	if Game.contest:
		Game.contest.on_doll_placed(at_room)   # das erste Urteil kommt ins Tagebuch (2.5)
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
	if verdict != "" or carrier or gone or Game.social == null or Game.director == null or not Game.director.first_attack_done:
		return   # vor dem ersten Angriff ist sie die Jury in der Lobby (2.5)
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
		"at_room": at_room, "pending": _pending, "gone": gone}


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
	if bool(d.get("gone", false)):
		vanish()
		_pending = String(d.get("pending", ""))
	else:
		_reappear()


# --- Aussehen -------------------------------------------------------------------------------

## Sitzende Porzellanpuppe (Meshy): blonde Locken, rosa Blümchenkleid mit blauer Schleife, Beine nach vorn gestreckt.
## Ursprung auf der Sitzfläche, Gesicht nach +Z.
func _build() -> void:
	var look: Node3D = (load(MODEL) as PackedScene).instantiate()
	look.scale = Vector3.ONE * SIZE
	look.position.y = -SEAT * SIZE
	add_child(look)
	_body = look.find_child("doll", true, false)
	_body.material_override = Mat.model(MODEL, _body, 0, true)   # Kleidsaum und Haar sind einseitig
	_skirt = _body.find_blend_shape_by_name("sit")
	_skeleton = look.find_children("*", "Skeleton3D", true, false)[0]
	for side in ["Left", "Right"]:
		for bone in ["UpLeg", "Arm"]:
			_bones[side + bone] = _skeleton.find_bone(side + bone)
	_bones["Head"] = _skeleton.find_bone("Head")
	assert(not _bones.values().has(-1) and _skirt >= 0, "Puppe: Knochen oder Formschlüssel fehlen")
	stand_pose(0.0)
	Geo.add_box_shape(self, Vector3(0.45, 0.66, 0.65), Vector3(0, 0.33, 0.2))
	_build_card()


## Schildchen „Jury“: gefaltetes Kärtchen neben ihr auf dem Sofa, Schrift zum Betrachter.
func _build_card() -> void:
	_card = Node3D.new()
	_card.position = Vector3(0.34, 0, 0.12)
	_card.rotation.y = -0.25
	add_child(_card)
	var paper := Mat.psx(Color(0.93, 0.9, 0.82))
	for side: float in [-1.0, 1.0]:
		var leaf := Geo.mesh(_card, Geo.box(Vector3(0.16, 0.075, 0.003)), paper, Vector3(0, 0.035, side * 0.014))
		leaf.rotation.x = side * 0.38
	var label := NoticeBoard._label("Jury", 60, load(LevelBuilder.SIGN_FONT))
	label.position = Vector3(0, 0.036, 0.03)
	label.rotation.x = -0.38
	label.modulate = Color(0.45, 0.06, 0.04)
	_card.add_child(label)


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
