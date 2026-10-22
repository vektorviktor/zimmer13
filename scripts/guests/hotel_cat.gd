class_name HotelCat
extends CharacterBody3D
## Hotelkatze (Spielkonzept 6.11). Streift durchs Hotel, schläft auf Sofas und Betten, lässt sich
## von Spieler und Gästen streicheln und folgt ihrem Lieblingsgast. Vor geschlossenen Türen miaut sie.
## Das Monster tut ihr nichts (es mag Katzen), aber sie hat Angst vor ihm: Kommt es nah, rennt sie
## weg und weint – eine Frühwarnung. Im Vorbeigehen wirft sie manchmal Deko um; selten bringt sie
## dir etwas vor die Tür oder legt sich auf dein Bett.
## Tragen (Spielkonzept 6.11): Erst streicheln, dann nimmt [E] sie auf den Arm (scheue erst, wenn sie dich
## kennen). Auf dem Arm schnurrt sie und beruhigt; [G] setzt sie ab, nach einer Weile windet sie sich heraus.
## Naht das Monster, faucht sie, kratzt und springt weg.
## Modell: tools/build_cat.py (Laufen als Animation, Stehen/Sitzen/Liegen per Code wie beim Monster).

enum State { IDLE, WALK, SLEEP, FLEE, WAIT_DOOR, PET, FOLLOW, GIFT, FETCH, CARRIED }

const MODEL := "res://assets/models/cat.glb"
## Eigene Kollisionsebene (11): blockiert niemanden, nur der Spieler-Strahl trifft sie (Streicheln)
const LAYER := 1024
const WALK_SPEED := 0.6
const RUN_SPEED := 2.8
## Bei diesem Tempo läuft die Animation „walk“ in Originalgeschwindigkeit
const ANIM_SPEED := 0.55
## Monster näher als das (gleiches Stockwerk) → Flucht; erst ab SAFE_DISTANCE wieder ruhig
const FEAR_DISTANCE := 12.0
const SAFE_DISTANCE := 20.0
const CRY_INTERVAL := 2.6
## Geschenk höchstens einmal so oft (Spielzeit) – und auch dann nur selten
const GIFT_COOLDOWN := Calendar.DAY_SECONDS
const GIFT_KINDS := [Item.Kind.LEAVES, Item.Kind.COBWEB, Item.Kind.CANDLE]
## So oft holt sie stattdessen etwas, das einem Gast gehört (der vermisst es dann)
const GUEST_GIFT_CHANCE := 0.4
## Auf dem Arm: so lange bleibt sie (mehr, je öfter gestreichelt, weniger, je scheuer), so viel Schock je Sekunde weg
const CARRY_TIME := Vector2(15.0, 40.0)
const CARRY_CALM := 0.02
## Scheue Katzen lassen sich erst ab so oft Streicheln hochnehmen
const CARRY_TRUST := 3
## Zimmer-Arten ohne Liegeplätze für Katzen
const UNINHABITABLE := ["laundry", "abandoned", "derelict", "locked"]
## Persönlichkeit: schläfrig (Nickerchen), scheu (weicht beim Streicheln aus), neugierig (streift,
## bringt Geschenke), tollpatschig (wirft Deko um). Färbung über die Fell-Textur. home: wohnt im Katzenraum
## (Spielkonzept 7.7) – schläft und streift meist dort, folgt selten jemandem hinaus, bringt nichts.
const PROFILES := {
	"minka": {"name": "Minka", "tint": Color(1.0, 1.0, 1.0), "sleepy": 0.7, "shy": 0.05, "curious": 0.3, "clumsy": 0.12},
	"socke": {"name": "Socke", "tint": Color(0.5, 0.46, 0.44), "sleepy": 0.45, "shy": 0.5, "curious": 0.45, "clumsy": 0.2},
	"kasimir": {"name": "Kasimir", "tint": Color(1.0, 0.7, 0.42), "sleepy": 0.25, "shy": 0.0, "curious": 0.85, "clumsy": 0.35},
	"luna": {"name": "Luna", "tint": Color(0.3, 0.28, 0.3), "sleepy": 0.6, "shy": 0.2, "curious": 0.3, "clumsy": 0.1, "home": true},
	"fussel": {"name": "Fussel", "tint": Color(1.0, 0.95, 0.85), "sleepy": 0.5, "shy": 0.35, "curious": 0.25, "clumsy": 0.25, "home": true},
	"tiger": {"name": "Tiger", "tint": Color(0.95, 0.62, 0.32), "sleepy": 0.35, "shy": 0.0, "curious": 0.5, "clumsy": 0.3, "home": true},
	"mausi": {"name": "Mausi", "tint": Color(0.68, 0.66, 0.66), "sleepy": 0.8, "shy": 0.6, "curious": 0.15, "clumsy": 0.1, "home": true},
}
## So oft bleibt eine Katzenraum-Katze bei Nickerchen und Streifzügen dort
const HOME_STAY := 0.85
## Posen (Drehungen im Skelettraum: X = linke Seite, Y = oben, Z = Blickrichtung) und Absenkung
const POSES := {
	"stand": {"drop": 0.0, "turns": []},
	"sit": {"drop": 0.05, "turns": [["Hips", Vector3.RIGHT, -0.55], ["frontleg", Vector3.RIGHT, 0.5], ["R_frontleg", Vector3.RIGHT, 0.5],
		["backleg", Vector3.RIGHT, -0.9], ["R_backleg", Vector3.RIGHT, -0.9], ["backleg1", Vector3.RIGHT, 1.6], ["R_backleg1", Vector3.RIGHT, 1.6],
		["head", Vector3.RIGHT, 0.35]]},
	"lie": {"drop": 0.15, "turns": [["frontleg", Vector3.RIGHT, -1.2], ["R_frontleg", Vector3.RIGHT, -1.2],
		["frontleg1", Vector3.RIGHT, 0.6], ["R_frontleg1", Vector3.RIGHT, 0.6],
		["backleg", Vector3.RIGHT, -1.2], ["R_backleg", Vector3.RIGHT, -1.2], ["backleg1", Vector3.RIGHT, 1.4], ["R_backleg1", Vector3.RIGHT, 1.4],
		["head", Vector3.RIGHT, 0.25], ["tailstart", Vector3.UP, 0.9]]},
}

var id := ""
var profile: Dictionary
var display_name := ""
var favourite := ""           ## Gast-ID des Lieblingsgasts
var affection := 0            ## wie oft der Spieler sie gestreichelt hat
var state := State.IDLE

var _builder: LevelBuilder
var _visual: Node3D
var _skeleton: Skeleton3D
var _player: AnimationPlayer
var _bone := {}
var _rest: Array[Quaternion] = []
var _rot: Array[Quaternion] = []
var _mouth: Node3D
var _carried: Item
var _fetch_item: Item
var _perch_cache: Array[Dictionary] = []
var agent: NavigationAgent3D
var _target := Vector3.ZERO
var _timer := 0.0
var _perch := -1              ## Index in perches() oder −1 (auf dem Boden)
var _perch_goal := -1         ## dorthin unterwegs
var _hopping := false
var _cry_timer := 0.0
var _meow_timer := 0.0
var _pet_effect := 0.0        ## Abklingzeit der beruhigenden Wirkung auf den Spieler
var _guest_pet := 0.0
var _gift_timer := 0.0
var _check_timer := 0.0
var _bumped := {}             ## Item-ID → Spielzeit, damit nicht dieselbe Deko immer wieder fällt
var _wait_door: Door
var _cowering := false        ## Flucht endet an einer geschlossenen Tür: geduckt weiterweinen
var _after_door := State.IDLE
var _anim := 0.0
var _stuck_time := 0.0
var _last_pos := Vector3.ZERO
var _carried_by: Player
var _carry_time := 0.0
var _purr_timer := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func setup(p_id: String, builder: LevelBuilder) -> HotelCat:
	id = p_id
	profile = PROFILES[p_id]
	display_name = profile["name"]
	_builder = builder
	_gift_timer = randf_range(0.3, 1.0) * GIFT_COOLDOWN
	return self


func _ready() -> void:
	collision_layer = LAYER
	collision_mask = 1 | 16   # Türen wie bei Gästen nicht: geschlossene erkennt _door_ahead()
	set_meta("interactable", self)
	add_to_group("cats")
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.16, 0.26, 0.42)
	shape.shape = box
	shape.position.y = 0.14
	add_child(shape)
	agent = NavigationAgent3D.new()
	agent.radius = 0.15
	agent.height = 0.3
	agent.path_desired_distance = 0.3
	agent.target_desired_distance = 0.3
	agent.path_height_offset = 0.2
	add_child(agent)
	_build_visual()
	_timer = randf_range(1.0, 5.0)
	if favourite == "" and Game.social:
		var guests: Array = Game.social.living_guests()
		if not guests.is_empty():
			favourite = guests[absi(hash(id)) % guests.size()].id


# --- Für Spieler, Gäste und Speichern ------------------------------------------------------

func get_prompt(p: Player) -> String:
	if _hopping or state == State.CARRIED:
		return ""
	if state == State.PET and p.held == null and p.carried_cat == null:
		return "%s hochnehmen [E]" % display_name
	if state == State.SLEEP:
		return "%s streicheln [E]  (schläft)" % display_name
	return "%s streicheln [E]" % display_name


func interact(p: Player) -> void:
	if state == State.PET and p.held == null and p.carried_cat == null:
		pick_up(p)
		return
	if state == State.FLEE:
		Game.say("%s ist viel zu verängstigt." % display_name, 2.0)
		return
	if state != State.SLEEP and randf() < float(profile["shy"]) * 0.6:
		Game.say("%s weicht dir aus." % display_name, 2.0)
		_wander()
		return
	Game.noise("cat_purr", global_position, self)
	affection += 1
	if _pet_effect <= 0.0:
		_pet_effect = 12.0
		p.shock = maxf(0.0, p.shock - 0.12)   # beruhigt (Schock 6.8)
	Game.say("%s schnurrt." % display_name, 2.0)
	if state != State.SLEEP:
		_drop_carried()
		state = State.PET
		_timer = 4.0
		_target = p.global_position


## Auf den Arm nehmen (nach dem Streicheln). Scheue Katzen wollen erst ein paar Mal gestreichelt sein.
func pick_up(p: Player) -> void:
	if float(profile["shy"]) > 0.3 and affection < CARRY_TRUST:
		Game.say("%s will nicht hochgenommen werden – noch nicht." % display_name, 2.5)
		_wander()
		return
	_drop_carried()
	_perch = -1
	_perch_goal = -1
	state = State.CARRIED
	_carried_by = p
	p.carried_cat = self
	collision_layer = 0
	velocity = Vector3.ZERO
	_carry_time = randf_range(CARRY_TIME.x, CARRY_TIME.y) * (1.0 + minf(affection, 10) * 0.1) * (1.0 - float(profile["shy"]) * 0.5)
	_purr_timer = 0.0
	Game.say("Du nimmst %s auf den Arm. [G] zum Absetzen." % display_name, 2.5)
	if Game.hud:
		Game.hud.set_held(display_name)


## Absetzen ([G] oder von selbst): vor dem Spieler auf den Boden – vor einer Wand dichter heran.
func put_down() -> void:
	var p := _carried_by
	_carried_by = null
	state = State.IDLE
	_timer = randf_range(3.0, 8.0)
	collision_layer = LAYER
	if p == null or not is_instance_valid(p):
		return
	p.carried_cat = null
	if Game.hud:
		Game.hud.set_held("")
	var forward := -p.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var from := p.global_position + Vector3.UP * 0.5
	var ray := PhysicsRayQueryParameters3D.create(from, from + forward * 0.8, 1 | 2)
	ray.exclude = [p.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	var reach := 0.6 if hit.is_empty() else maxf(0.1, from.distance_to(hit["position"]) - 0.3)
	global_position = p.global_position + forward * reach + Vector3.UP * 0.05
	rotation.y = p.rotation.y + PI
	_last_pos = global_position


func _carried_step(delta: float) -> void:
	var p := _carried_by
	if p == null or not is_instance_valid(p) or p.dead or p.hiding != null or p.sleeping or p.gripped:
		put_down()
		return
	if _monster_near(FEAR_DISTANCE):
		# Angst: faucht, kratzt und ist weg
		Game.say("%s faucht, kratzt dich und springt weg!" % display_name, 2.5)
		p.add_shock(0.1, false)
		put_down()
		_start_flee()
		return
	var forward := -p.global_basis.z
	global_position = p.global_position + Vector3.UP * 0.95 + forward * 0.42 + p.global_basis.x * 0.04
	rotation.y = p.rotation.y + PI / 2.0   # quer im Arm
	velocity = Vector3.ZERO
	p.shock = maxf(0.0, p.shock - CARRY_CALM * delta)
	_purr_timer -= delta
	if _purr_timer <= 0.0:
		_purr_timer = randf_range(5.0, 9.0)
		Game.noise("cat_purr", global_position, self)
	_carry_time -= delta
	if _carry_time <= 0.0:
		Game.say("%s windet sich und springt herunter." % display_name, 2.0)
		put_down()


## Startplätze: Minka schläft auf dem Sofa, Socke in der Küche, Kasimir im Flur vor Zimmer 13.
func place_at_start() -> void:
	if _home_cat():
		var spots := _home_perches()
		if not spots.is_empty():
			_perch = spots[PROFILES.keys().find(id) % spots.size()]
			global_position = perches()[_perch]["top"]
			state = State.SLEEP
			_timer = randf_range(30.0, 120.0)
			_last_pos = global_position
			return
	match id:
		"minka":
			_perch = 0
			global_position = perches()[0]["top"]
			state = State.SLEEP
			_timer = randf_range(60.0, 120.0)
		"socke":
			global_position = _builder.kitchen_spot + Vector3(0.6, 0.05, -0.4)
		_:
			global_position = _builder.player_door_front + (_builder.rooms[LevelBuilder.PLAYER_ROOM]["along"] as Vector3) * 2.0 + Vector3(0, 0.05, 0)
	_last_pos = global_position


## Debug (--cat=id): sitzt vor dem Spieler.
func place_in_front_of(p: Player) -> void:
	if state == State.CARRIED:
		put_down()
	_perch = -1
	global_position = p.global_position - p.global_transform.basis.z * 1.1 + Vector3.UP * 0.05
	rotation.y = p.rotation.y + PI
	state = State.IDLE
	_timer = 20.0


## Ein Gast streichelt sie im Vorbeigehen.
func petted_by_guest() -> void:
	Game.noise("cat_purr", global_position, self)
	if state != State.SLEEP and state != State.CARRIED:
		state = State.PET
		_timer = 3.0


func save_state() -> Dictionary:
	var pos := global_position
	if state == State.CARRIED and _carried_by:
		pos = _carried_by.global_position + Vector3.UP * 0.05   # auf dem Arm: nach dem Laden zu deinen Füßen
	return {"pos": [pos.x, pos.y, pos.z], "rot": rotation.y,
		"favourite": favourite, "affection": affection, "gift": _gift_timer, "perch": _perch,
		"sleep": state == State.SLEEP, "timer": _timer,
		"carried": SaveManager._item_data(_carried) if _carried else null}


func load_state(d: Dictionary) -> void:
	var p: Array = d.get("pos", [])
	if p.size() == 3:
		global_position = Vector3(float(p[0]), float(p[1]), float(p[2]))
	rotation.y = float(d.get("rot", 0.0))
	favourite = String(d.get("favourite", favourite))
	affection = int(d.get("affection", 0))
	_gift_timer = float(d.get("gift", _gift_timer))
	_perch = int(d.get("perch", -1))
	if _perch >= perches().size():
		_perch = -1
	state = State.SLEEP if bool(d.get("sleep", false)) else State.IDLE
	_timer = float(d.get("timer", 5.0))
	# Beute im Maul liegt nach dem Laden vor ihren Pfoten
	var carried = d.get("carried")
	if carried is Dictionary:
		var item := SaveManager._make_item(carried)
		_builder.world.add_child(item)
		item.global_position = global_position - global_transform.basis.z * 0.3 + Vector3.UP * 0.02


## Alle Liegeplätze: Sofas und Rezeption in der Lobby, Betten und Fensterbänke aller bewohnbaren Zimmer und
## der Lobby. Reihenfolge fest – unabhängig davon, wer gerade wo wohnt (der Index wird gespeichert).
## `yaw`: so liegt sie oben. Ausgewählt werden nur Plätze in der Lobby und in bewohnten Zimmern.
func perches() -> Array[Dictionary]:
	if not _perch_cache.is_empty():
		return _perch_cache
	var list: Array[Dictionary] = _builder.cat_perches.duplicate()
	for no in _builder.rooms:
		var room: Dictionary = _builder.rooms[no]
		if room["kind"] in UNINHABITABLE:
			continue
		for spot in room["spots"]:
			if spot is HideSpot and spot.type == HideSpot.Type.BED:
				list.append({"floor": spot.exit_point.global_position, "top": spot.global_transform * Vector3(0.3, 0.57, 0.0), "room": no})
	for node in get_tree().get_nodes_in_group("windows"):
		var win := node as HotelWindow
		if not win.exterior or not win.has_curtains():
			continue
		var room: Dictionary = _builder.rooms.get(win.room_id, {})
		if win.room_id != "lobby" and (room.is_empty() or room["kind"] in UNINHABITABLE):
			continue
		# Fensterbank: 2 cm über der Laibung, vor der Scheibe (lokale +Z = in den Raum)
		var top := win.global_transform * Vector3(0.0, -win.height / 2.0 + 0.03, 0.09)
		var front := win.global_transform * Vector3(0.0, 0.0, 0.7)
		list.append({"floor": Vector3(front.x, top.y - LevelBuilder.WINDOW_SILL - 0.02, front.z), "top": top,
			"yaw": win.global_rotation.y + PI / 2.0, "room": win.room_id})
	_perch_cache = list
	return list


# --- Ablauf ----------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_anim += delta
	_pet_effect -= delta
	_guest_pet -= delta
	_gift_timer -= delta
	_check_timer -= delta
	if _hopping:
		_animate(delta)
		return
	if state == State.CARRIED:
		_carried_step(delta)
		_animate(delta)
		return
	if _monster_near(FEAR_DISTANCE) and state != State.FLEE:
		_start_flee()
	match state:
		State.IDLE:
			_stop(delta)
			_timer -= delta
			if _timer <= 0.0:
				_next_activity()
		State.SLEEP:
			_stop(delta)
			_timer -= delta
			if _timer <= 0.0:
				_wake()
		State.PET:
			_stop(delta)
			_face(_target, delta)
			_timer -= delta
			if _timer <= 0.0:
				state = State.IDLE
				_timer = randf_range(2.0, 6.0)
		State.WAIT_DOOR:
			_wait_at_door(delta)
		State.FLEE:
			_flee_step(delta)
		State.FOLLOW:
			_follow_step(delta)
		_:
			if _move_to(_target, WALK_SPEED, delta):
				_arrive()
	if _check_timer <= 0.0:
		_check_timer = 0.4
		_check_surroundings()
	_animate(delta)


func _next_activity() -> void:
	var sleepy := float(profile["sleepy"])
	var curious := float(profile["curious"])
	var weights := {"nap": 1.0 + sleepy * 3.0, "wander": 0.5 + curious * 2.0, "sit": 1.0,
		"follow": 0.8, "bed": 0.06 + minf(affection, 10) * 0.03}
	if _gift_timer <= 0.0 and not _home_cat():
		weights["gift"] = 0.15 * curious
	if _home_cat():
		weights["follow"] = 0.1
		weights["bed"] = 0.0
	match _weighted_choice(weights):
		"nap":
			var spots := _usable_perches()
			var home := _home_pick()
			if home >= 0:
				_go_perch(home)
			elif randf() < 0.65 and not spots.is_empty():
				_go_perch(spots.pick_random())
			else:
				_walk_to(_floor_spot())
		"wander":
			_wander()
		"sit":
			state = State.IDLE
			_timer = randf_range(6.0, 15.0)
		"follow":
			if _favourite_guest() != null:
				state = State.FOLLOW
				_timer = randf_range(20.0, 45.0)
			else:
				_wander()
		"bed":
			var spots := perches()
			for i in spots.size():
				if spots[i].get("room", "") == LevelBuilder.PLAYER_ROOM:
					_go_perch(i)
					return
			_wander()
		"gift":
			_start_gift()


## Indizes der Liegeplätze, die gerade in Frage kommen: Lobby und bewohnte Zimmer (Zimmer 13, Gäste).
func _usable_perches() -> Array[int]:
	var occupied := {LevelBuilder.PLAYER_ROOM: true}
	if Game.social:
		for g in Game.social.living_guests():
			occupied[String(g.home["no"])] = true
	var result: Array[int] = []
	var list := perches()
	for i in list.size():
		var room := String(list[i].get("room", ""))
		if room == "" or room == "lobby" or occupied.has(room):
			result.append(i)
	return result


## Wohnt sie im Katzenraum?
func _home_cat() -> bool:
	return bool(profile.get("home", false))


## Liegeplätze im Katzenraum (Kratzbäume).
func _home_perches() -> Array[int]:
	var result: Array[int] = []
	var list := perches()
	for i in list.size():
		if list[i].get("cat_room", false):
			result.append(i)
	return result


## Bleibt eine Katzenraum-Katze daheim (HOME_STAY)? Dann ein zufälliger Liegeplatz dort, sonst −1.
func _home_pick() -> int:
	if not _home_cat() or randf() >= HOME_STAY:
		return -1
	var spots := _home_perches()
	return spots.pick_random() if not spots.is_empty() else -1


func _wander() -> void:
	var home := _home_pick()
	if home >= 0:
		_walk_to((perches()[home]["floor"] as Vector3) + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5)))
		return
	var points: Array[Vector3] = _builder.wander_points
	var near: Array[Vector3] = []
	for p in points:
		if absf(p.y - global_position.y) < 1.5 and p.distance_to(global_position) < 25.0:
			near.append(p)
	var choice := near if not near.is_empty() else points
	_walk_to(choice[randi() % choice.size()] + Vector3(randf_range(-0.8, 0.8), 0, randf_range(-0.6, 0.6)))


## Auf dem Boden irgendwohin (kein Liegeplatz als Ziel).
func _walk_to(point: Vector3) -> void:
	_target = point
	_perch_goal = -1
	state = State.WALK


func _floor_spot() -> Vector3:
	var spots: Array[Vector3] = [_builder.kitchen_spot, _builder.lobby_center]
	spots.append_array(_builder.wander_points.slice(0, 4))
	return spots[randi() % spots.size()] + Vector3(randf_range(-0.5, 0.5), 0, randf_range(-0.5, 0.5))


func _go_perch(index: int) -> void:
	_perch_goal = index
	_target = perches()[index]["floor"]
	state = State.WALK


func _arrive() -> void:
	match state:
		State.FETCH:
			var item := _fetch_item
			_fetch_item = null
			if is_instance_valid(item) and not item.is_held and item.global_position.distance_to(global_position) < 0.8:
				if Game.social:
					Game.social.cat_thefts[item.owner_id] = display_name
				_carry(item)
				_head_home()
			else:
				state = State.IDLE   # jemand war schneller
				_timer = randf_range(2.0, 5.0)
		State.GIFT:
			_drop_carried()
			Game.noise("cat_meow", global_position, self)
			if Game.player and Game.player.global_position.distance_to(global_position) < 10.0:
				Game.say("%s hat dir etwas gebracht." % display_name, 2.5)
			_gift_timer = GIFT_COOLDOWN
			state = State.IDLE
			_timer = randf_range(3.0, 8.0)
		_:
			if _perch_goal >= 0:
				_hop_up(_perch_goal)
			else:
				_fall_asleep(randf_range(20.0, 60.0) if randf() < float(profile["sleepy"]) else 0.0)


func _fall_asleep(duration: float) -> void:
	if duration <= 0.0:
		state = State.IDLE
		_timer = randf_range(4.0, 12.0)
		return
	state = State.SLEEP
	_timer = duration


func _wake() -> void:
	if _perch >= 0:
		_hop_down()
	state = State.IDLE
	_timer = randf_range(1.0, 4.0)


# --- Möbel: hoch- und herunterspringen ----------------------------------------------------

func _hop_up(index: int) -> void:
	_perch_goal = -1
	var perch: Dictionary = perches()[index]
	_perch = index
	_hop(perch["top"], func() -> void:
		if perch.has("yaw"):
			rotation.y = float(perch["yaw"])
		_fall_asleep(randf_range(40.0, 120.0) * (0.6 + float(profile["sleepy"]))))


func _hop_down() -> void:
	var floor_pos: Vector3 = perches()[_perch]["floor"]
	_perch = -1
	_hop(floor_pos, Callable())


func _hop(to: Vector3, done: Callable) -> void:
	_hopping = true
	velocity = Vector3.ZERO
	var from := global_position
	var flat := to - from
	if Vector2(flat.x, flat.z).length() > 0.05:
		rotation.y = atan2(-flat.x, -flat.z)
	var tween := create_tween()
	tween.tween_method(func(t: float) -> void:
		global_position = from.lerp(to, t) + Vector3.UP * sin(PI * t) * 0.35, 0.0, 1.0, 0.45)
	tween.tween_callback(func() -> void:
		_hopping = false
		_last_pos = global_position
		if done.is_valid():
			done.call())


# --- Angst vor dem Monster ------------------------------------------------------------------

func _monster_near(distance: float) -> bool:
	var m := Game.monster
	if m == null or not m.is_active():
		return false
	return absf(m.global_position.y - global_position.y) < 2.5 and m.global_position.distance_to(global_position) < distance


func _start_flee() -> void:
	_drop_carried()
	if _perch >= 0:
		global_position = perches()[_perch]["floor"]   # erschrocken herunter
		_perch = -1
	_perch_goal = -1
	state = State.FLEE
	_cowering = false
	if Game.social:
		Game.social.cats_have_cried = true
	_cry_timer = 0.0
	_target = _flee_point()
	_timer = 0.0


func _flee_point() -> Vector3:
	var m := Game.monster.global_position
	var best := global_position
	var best_d := -1.0
	var candidates: Array[Vector3] = _builder.wander_points.duplicate()
	candidates.append_array([_builder.lobby_center, _builder.kitchen_spot])
	for p in candidates:
		if absf(p.y - global_position.y) > 1.5 or p.distance_to(global_position) > 30.0:
			continue
		var d := p.distance_to(m)
		if d > best_d:
			best_d = d
			best = p
	return best


func _flee_step(delta: float) -> void:
	_cry_timer -= delta
	if _cry_timer <= 0.0:
		_cry_timer = CRY_INTERVAL * randf_range(0.8, 1.3)
		Game.noise("cat_cry", global_position, self)
	var safe := not _monster_near(SAFE_DISTANCE)
	if _cowering or _move_to(_target, RUN_SPEED, delta):
		if safe:
			_timer += delta
			if _timer > 6.0:   # noch ein wenig weinen, dann ist es vorbei
				state = State.IDLE
				_cowering = false
				_timer = randf_range(8.0, 15.0)
		elif not _cowering:
			_target = _flee_point()


# --- Lieblingsgast, Geschenke, Türen ---------------------------------------------------------

func _favourite_guest() -> Guest:
	if favourite == "" or Game.social == null:
		return null
	var g: Guest = Game.social.guest_by_id(favourite)
	return g if g != null and not g.dead and g.hiding == null else null


func _follow_step(delta: float) -> void:
	var g := _favourite_guest()
	_timer -= delta
	if g == null or _timer <= 0.0:
		state = State.IDLE
		_timer = randf_range(3.0, 8.0)
		return
	var to := g.global_position + g.global_transform.basis.z * 0.8
	if global_position.distance_to(g.global_position) < 1.3:
		_stop(delta)
		_face(g.global_position, delta)
	else:
		_move_to(to, WALK_SPEED * 1.6, delta)


func _start_gift() -> void:
	var loot := _guest_item_nearby() if randf() < GUEST_GIFT_CHANCE else null
	if loot != null:
		_fetch_item = loot
		_target = loot.global_position
		_perch_goal = -1
		state = State.FETCH
		return
	var kind: Item.Kind = GIFT_KINDS[randi() % GIFT_KINDS.size()]
	var item := Item.create(kind)
	if item.lit:
		item._extinguish()
	_carry(item)
	_head_home()


## Mit der Beute im Maul zu Zimmer 13.
func _head_home() -> void:
	var home: Dictionary = _builder.rooms[LevelBuilder.PLAYER_ROOM]
	var door: Door = home["door"]
	_target = home["door_inside"] if door != null and door.is_open else home["door_front"]
	_target += Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3))
	_perch_goal = -1
	state = State.GIFT


## Kleine Deko eines Gastes in der Nähe, die gerade niemand trägt (nicht schon vor Zimmer 13).
func _guest_item_nearby() -> Item:
	var door_13: Vector3 = _builder.rooms[LevelBuilder.PLAYER_ROOM]["door_front"]
	var best: Item = null
	var best_d := 25.0
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if not item.kind in GIFT_KINDS or item.is_held or item.hung or item.lit or item.owner_id in ["", "player"]:
			continue
		if absf(item.global_position.y - global_position.y) > 1.5 or item.global_position.distance_to(door_13) < 4.0:
			continue
		var d := item.global_position.distance_to(global_position)
		if d < best_d:
			best_d = d
			best = item
	return best


func _carry(item: Item) -> void:
	if not item.is_inside_tree():
		_builder.world.add_child(item)
	item.set_held(true)
	item.reparent(_mouth, false)
	item.position = Vector3.ZERO
	item.rotation = Vector3(0, 0, PI / 2.0) if item.kind == Item.Kind.CANDLE else Vector3.ZERO
	_carried = item


func _drop_carried() -> void:
	if _carried == null:
		return
	var item := _carried
	_carried = null
	item.reparent(_builder.world, true)
	item.global_position = Vector3(item.global_position.x, global_position.y + 0.02, item.global_position.z)
	item.rotation = Vector3(0, rotation.y, 0)
	item.set_held(false)


## Geschlossene Tür direkt voraus? (Das NavMesh kennt keine Türen.)
func _door_ahead(dir: Vector3) -> Door:
	var probe := global_position + dir * 0.45
	for door: Door in Door.near(probe):
		if door.is_open:
			continue
		var c := door.center()
		if absf(c.y - 1.05 - global_position.y) < 1.0 and Vector2(c.x - probe.x, c.z - probe.z).length() < 0.7:
			return door
	return null


func _wait_at_door(delta: float) -> void:
	_stop(delta)
	_face(_wait_door.center(), delta)
	_timer -= delta
	_meow_timer -= delta
	if _wait_door.is_open:
		state = _after_door
		return
	if _meow_timer <= 0.0:
		_meow_timer = randf_range(3.0, 5.0)
		Game.noise("cat_meow", global_position, self)
	if _timer <= 0.0:
		_drop_carried()   # ein Geschenk bleibt dann eben vor der Tür
		_fall_asleep(randf_range(30.0, 70.0))   # gibt auf, legt sich hin, versucht es später wieder


# --- Umgebung: Gäste streicheln, Deko umwerfen ----------------------------------------------

func _check_surroundings() -> void:
	if state in [State.IDLE, State.SLEEP, State.FOLLOW] and _guest_pet <= 0.0 and Game.social:
		for g in Game.social.living_guests():
			if g.state == Guest.State.IDLE and g.fear < 50.0 and g.hiding == null \
					and g.global_position.distance_to(global_position) < 1.4 and randf() < 0.5:
				g.pet_cat(self)
				petted_by_guest()
				_guest_pet = randf_range(40.0, 80.0)
				break
	if _perch >= 0 or not state in [State.WALK, State.FLEE, State.FOLLOW, State.GIFT, State.FETCH]:
		return
	var now := Game.director.elapsed if Game.director else 0.0
	if _bumped.size() > 100:   # Abgelaufenes vergessen – sonst wächst die Liste mit jeder Deko, an der sie vorbeikommt
		for key in _bumped.keys():
			if now - float(_bumped[key]) >= 60.0:
				_bumped.erase(key)
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if not item.kind in Item.TOPPLE_KINDS or item.is_held or item.is_toppled():
			continue
		var to := item.global_position - global_position
		if absf(to.y) > 0.5 or Vector2(to.x, to.z).length() > 0.32:
			continue
		var key := item.get_instance_id()
		if now - float(_bumped.get(key, -999.0)) < 60.0:
			continue
		_bumped[key] = now
		var chance := float(profile["clumsy"]) * (2.0 if state == State.FLEE else 1.0)
		if randf() < chance:
			item.knock_over(global_position)
			Game.noise("cat_knock", item.global_position, self)


# --- Bewegung (wie Gäste: NavigationAgent mit Festgefahren-Erkennung) -------------------------

func _move_to(point: Vector3, speed: float, delta: float) -> bool:
	if agent.target_position.distance_to(point) > 0.25:
		agent.target_position = point
	var near := Vector2(point.x - global_position.x, point.z - global_position.z).length() < 0.4 \
		and absf(point.y - global_position.y) < 1.5
	if near or agent.is_navigation_finished():
		_stop(delta)
		return true
	agent.path_desired_distance = maxf(0.3, speed * get_physics_process_delta_time() * 1.5)   # wie Guest._move_to
	var next := agent.get_next_path_position()
	var dir := next - global_position
	dir.y = 0.0
	if dir.length() > 0.01:
		dir = dir.normalized()
		var door := _door_ahead(dir)
		if door != null and state == State.FLEE:
			_cowering = true   # in Panik kommt sie nicht weiter
			_stop(delta)
			return true
		if door != null:
			_wait_door = door
			_after_door = state
			state = State.WAIT_DOOR
			_timer = randf_range(12.0, 20.0)
			_meow_timer = 0.5
			_stop(delta)
			return false
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), minf(1.0, 8.0 * delta))
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	velocity.y = 0.0 if is_on_floor() else velocity.y - _gravity * delta
	move_and_slide()
	if global_position.distance_to(_last_pos) < speed * delta * 0.2:
		_stuck_time += delta
		if _stuck_time > 1.0:
			_stuck_time = 0.0
			var side := Vector3(-dir.z, 0, dir.x) * (1.0 if randf() < 0.5 else -1.0)
			global_position += side * 0.1
			agent.target_position = point + Vector3(0.01, 0, 0)
	else:
		_stuck_time = 0.0
	_last_pos = global_position
	return false


func _stop(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	if _perch >= 0:
		velocity.y = 0.0   # liegt auf einem Möbel – keine Schwerkraft
		return
	velocity.y = 0.0 if is_on_floor() else velocity.y - _gravity * delta
	move_and_slide()


func _face(pos: Vector3, delta: float) -> void:
	var to := pos - global_position
	if Vector2(to.x, to.z).length() < 0.01:
		return
	rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), minf(1.0, 5.0 * delta))


func _weighted_choice(weights: Dictionary) -> String:
	var total := 0.0
	for w in weights.values():
		total += float(w)
	var r := randf() * total
	for key in weights:
		r -= float(weights[key])
		if r <= 0.0:
			return key
	return weights.keys()[0]


# --- Aussehen ---------------------------------------------------------------------------------

func _build_visual() -> void:
	_visual = (load(MODEL) as PackedScene).instantiate()
	add_child(_visual)
	_skeleton = _visual.find_children("*", "Skeleton3D", true, false)[0]
	_player = _visual.find_children("*", "AnimationPlayer", true, false)[0]
	_player.get_animation("walk").loop_mode = Animation.LOOP_LINEAR
	for i in _skeleton.get_bone_count():
		_bone[_skeleton.get_bone_name(i)] = i
		_rest.append(_skeleton.get_bone_rest(i).basis.get_rotation_quaternion())
	_rot = _rest.duplicate()
	var mesh: MeshInstance3D = _visual.find_children("*", "MeshInstance3D", true, false)[0]
	var fur := Mat.psx(profile["tint"], "", 1.0, Color.BLACK, 0.0, false)
	fur.set_shader_parameter("albedo_tex", (mesh.get_active_material(0) as BaseMaterial3D).albedo_texture)
	mesh.material_override = fur
	_mouth = Node3D.new()
	_mouth.position = Vector3(0, 0.2, -0.26)
	_visual.add_child(_mouth)


## Laufen = Animation aus der GLB; sonst Pose per Code (Stehen, Sitzen, Liegen) plus Schwanz und Kopf.
func _animate(delta: float) -> void:
	var speed := Vector2(velocity.x, velocity.z).length()
	if speed > 0.05 or _hopping:
		if _player.current_animation != "walk":
			_player.play("walk")
		_player.speed_scale = clampf(speed / ANIM_SPEED, 0.6, 4.0) if not _hopping else 2.0
		_visual.position.y = 0.0
		return
	if _player.is_playing():
		_player.stop()
	var pose: Dictionary = POSES[_pose_for_state()]
	_visual.position.y = lerpf(_visual.position.y, -float(pose["drop"]), minf(1.0, 6.0 * delta))
	_rot = _rest.duplicate()
	for t in pose["turns"]:
		_turn(t[0], t[1], t[2])
	# Schwanz pendelt (im Schlaf kaum), Kopf schaut sich um
	var calm := 0.2 if state == State.SLEEP else 1.0
	_turn("tail1", Vector3.UP, sin(_anim * 1.7) * 0.35 * calm)
	_turn("tail2", Vector3.UP, sin(_anim * 1.7 - 0.6) * 0.45 * calm)
	if state != State.SLEEP:
		_turn("head", Vector3.UP, sin(_anim * 0.45) * 0.4)
	for i in _rot.size():
		var current := _skeleton.get_bone_pose_rotation(i)
		_skeleton.set_bone_pose_rotation(i, current.slerp(_rot[i], minf(1.0, 8.0 * delta)))


func _pose_for_state() -> String:
	match state:
		State.SLEEP, State.CARRIED:
			return "lie"
		State.FLEE:
			return "lie" if _cowering else "sit"
		State.IDLE, State.PET, State.WAIT_DOOR:
			return "sit"
	return "stand"


## Dreht einen Knochen um eine Achse im Skelettraum (Eltern vor Kindern drehen).
func _turn(bone: String, axis: Vector3, angle: float) -> void:
	if not _bone.has(bone):
		return
	var i: int = _bone[bone]
	var parent_rot := Quaternion.IDENTITY
	var p := _skeleton.get_bone_parent(i)
	while p >= 0:
		parent_rot = _rot[p] * parent_rot
		p = _skeleton.get_bone_parent(p)
	_rot[i] = Quaternion((parent_rot.inverse() * axis).normalized(), angle) * _rot[i]
