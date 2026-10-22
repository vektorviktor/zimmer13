class_name Stove
extends StaticBody3D
## Herd in der Küche (Spielkonzept 3.8): Kürbis in der Hand → in den Topf (große Sorten, Suppe) bzw. in die Pfanne
## (kleine, braten); mit dem Messer klein schneiden, dann kocht es nach Spielzeit. Die Suppe reicht für PORTIONS
## Schalen – freie Gäste in der Nähe kommen und essen mit (Angst ↓, mögen dich mehr, werden miteinander vertrauter,
## 6.16), du selbst isst am Topf (Schock ↓); nach COLD_TIME ist sie kalt. Der gebratene Kürbis liegt danach als Teller
## (Item.Kind.ROAST_PUMPKIN) auf dem Herd. Was auf dem Herd steht, wird nicht gespeichert. Erreichbar über Game.kitchen.

const SOUP_TIME := 40.0
const ROAST_TIME := 25.0
const PORTIONS := 8
## So viele Gäste kommen höchstens zum Essen – die nächsten freien auf demselben Stockwerk (die Küche liegt abseits im
## Westflügel, darum ein weiter Umkreis); so lange isst jeder
const EATERS := 6
const EAT_RANGE := 130.0
const EAT_TIME := Vector2(8.0, 12.0)
const COLD_TIME := 180.0
## Wirkung einer Schale: Angst der Gäste, Beziehung (hat der Spieler gekocht), Schock des Spielers
const FEAR_RELIEF := 30.0
const RELATION := 6.0
const SHOCK_RELIEF := 0.3
## Große Sorten kommen in den Topf (Suppe), kleine in die Pfanne (braten); den Riesen kocht keiner
const SOUP_VARIETIES := ["halloween", "casper", "muskat"]
const ROAST_VARIETIES := ["hokkaido", "butternut", "turban"]
const EAT_LINES := ["Mmh, lecker!", "Genau das Richtige bei dem Wetter.", "Hast du die gekocht? Wunderbar!", "Noch ganz heiß …"]
const KID_EAT_LINES := ["Lecker!", "Darf ich noch eine?", "Das schmeckt besser als zu Hause!"]
const LATE_LINES := ["Schon alle? Schade.", "Oh – nichts mehr übrig."]

## empty · raw (Kürbis im Topf bzw. in der Pfanne, noch nicht geschnitten) · cooking · soup (fertig, Schalen übrig)
var phase := "empty"
var dish := ""                ## "soup" oder "roast"
var variety := ""
var portions := 0
## Wohin der Herd zeigt (Vorderseite, waagrecht) – dort stehen die Gäste beim Essen
var front := Vector3(0, 0, 1)

var _timer := 0.0
var _player_ate := false
var _eaters := {}             ## Gast-ID → {guest, phase (go/eat), time, spot}
var _ate: Array[Guest] = []   ## wer von diesem Topf gegessen hat
var _pot: Node3D
var _pan: Node3D
var _soup: MeshInstance3D
var _slices: Node3D
var _steam: CPUParticles3D
var _bob := 0.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	set_meta("interactable", self)
	Game.kitchen = self
	var metal := Mat.psx(Color(0.32, 0.32, 0.34))
	_pot = Node3D.new()
	_pot.position = Vector3(-0.17, 0, 0)
	add_child(_pot)
	Geo.mesh(_pot, Geo.cylinder(0.16, 0.2, 10), metal, Vector3(0, 0.1, 0))
	Geo.mesh(_pot, Geo.cylinder(0.17, 0.02, 10), Mat.psx(Color(0.22, 0.22, 0.24)), Vector3(0, 0.2, 0))
	_soup = Geo.mesh(_pot, Geo.cylinder(0.145, 0.01, 10), Mat.psx(Color(0.95, 0.5, 0.1)), Vector3(0, 0.18, 0))
	_soup.visible = false
	_pan = Node3D.new()
	_pan.position = Vector3(0.2, 0, 0.02)
	add_child(_pan)
	Geo.mesh(_pan, Geo.cylinder(0.14, 0.04, 10), Mat.psx(Color(0.15, 0.15, 0.16)), Vector3(0, 0.02, 0))
	var handle := Geo.mesh(_pan, Geo.box(Vector3(0.2, 0.02, 0.03)), Mat.psx(Color(0.12, 0.08, 0.05)), Vector3(0.22, 0.035, 0))
	handle.rotation.z = 0.1
	_slices = Node3D.new()
	_pan.add_child(_slices)
	for i in 5:
		var a := i * TAU / 5.0
		var slice := Geo.mesh(_slices, Geo.box(Vector3(0.09, 0.025, 0.04)), Mat.psx(Color(0.9, 0.48, 0.12)), Vector3(cos(a) * 0.07, 0.05, sin(a) * 0.07))
		slice.rotation.y = -a
	_slices.visible = false
	_steam = CPUParticles3D.new()
	_steam.emitting = false
	_steam.amount = 22
	_steam.lifetime = 2.2
	_steam.local_coords = false
	_steam.direction = Vector3.UP
	_steam.spread = 12.0
	_steam.gravity = Vector3(0, 0.15, 0)
	_steam.initial_velocity_min = 0.15
	_steam.initial_velocity_max = 0.3
	_steam.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	_steam.emission_sphere_radius = 0.08
	_steam.scale_amount_min = 0.6
	_steam.scale_amount_max = 2.2
	var puff := QuadMesh.new()
	puff.size = Vector2(0.045, 0.045)
	var puff_mat := StandardMaterial3D.new()
	puff_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puff_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	puff_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	puff_mat.albedo_color = Color(0.92, 0.92, 0.9, 0.22)
	puff_mat.vertex_color_use_as_albedo = true   # Ein- und Ausblenden über color_ramp
	puff.material = puff_mat
	_steam.mesh = puff
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0.0))
	fade.add_point(0.2, Color(1, 1, 1, 1.0))
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0.0))
	_steam.color_ramp = fade
	add_child(_steam)
	Geo.add_box_shape(self, Vector3(0.7, 0.24, 0.45), Vector3(0, 0.12, 0))


## Beim Laden eines Spielstands (SaveManager.apply): Herd leer, niemand isst (nicht gespeichert).
func reset() -> void:
	_eaters.clear()
	_ate.clear()
	phase = "empty"
	portions = 0
	_show()


## Ein Kürbis in der Hand: kommt er in den Topf (Suppe) oder in die Pfanne (braten)? "" = gar nicht.
static func dish_for(item: Item) -> String:
	if item == null:
		return ""
	if item.kind == Item.Kind.MINI_PUMPKIN:
		return "roast"
	if item.kind != Item.Kind.PUMPKIN:
		return ""
	if item.variety in SOUP_VARIETIES:
		return "soup"
	return "roast" if item.variety in ROAST_VARIETIES else ""


func get_prompt(player: Player) -> String:
	match phase:
		"empty":
			var d := dish_for(player.held)
			if d == "soup":
				return "%s in den Topf geben [E]" % player.held.display_name
			if d == "roast":
				return "%s in die Pfanne legen [E]" % player.held.display_name
			if player.held and player.held.kind == Item.Kind.CARVED_PUMPKIN:
				return "Herd – einen geschnitzten Kürbis kocht man nicht"
			return "Herd – mit einem Kürbis in der Hand kochen"
		"raw":
			if player.held_kind() == Item.Kind.KNIFE:
				return "Kürbis klein schneiden und %s [E]" % ("kochen" if dish == "soup" else "braten")
			if player.held == null:
				return "Kürbis wieder herausnehmen [E]  – zum Kochen ein Messer in die Hand"
			return "Kürbis %s – zum Schneiden ein Messer in die Hand" % ("im Topf" if dish == "soup" else "in der Pfanne")
		"cooking":
			return "%s – noch %d s" % ["Die Suppe kocht" if dish == "soup" else "Der Kürbis brutzelt", ceili(_timer)]
		"soup":
			if _player_ate:
				return "Kürbissuppe – du bist satt (%d Schalen übrig)" % portions
			return "Kürbissuppe essen [E] (%d Schalen übrig)" % portions
	return ""


func interact(player: Player) -> void:
	match phase:
		"empty":
			var d := dish_for(player.held)
			if d == "":
				return
			variety = PumpkinKinds.DEFAULT if player.held.kind == Item.Kind.MINI_PUMPKIN else player.held.variety
			dish = d
			player.consume_held()
			phase = "raw"
			_show()
			Game.noise("drop", global_position, player)
		"raw":
			if player.held_kind() == Item.Kind.KNIFE:
				phase = "cooking"
				_timer = SOUP_TIME if dish == "soup" else ROAST_TIME
				_show()
				Game.say("Du schneidest den Kürbis klein. Jetzt heißt es warten.", 3.0)
			elif player.held == null:
				var item := Item.create(Item.Kind.MINI_PUMPKIN) if variety == PumpkinKinds.DEFAULT and dish == "roast" \
					else Item.create(Item.Kind.PUMPKIN, variety)
				item.owner_id = "player"
				phase = "empty"
				_show()
				player.receive_item(item)
		"soup":
			if not _player_ate and portions > 0:
				_player_ate = true
				portions -= 1
				player.shock = maxf(0.0, player.shock - SHOCK_RELIEF)
				Game.say("Heiße Kürbissuppe. Für einen Moment ist alles gut.", 3.0)
				if portions == 0:
					_end_soup("")


func _process(delta: float) -> void:
	if Game.game_over:
		return
	_bob += delta
	match phase:
		"cooking":
			_timer -= delta
			_soup.position.y = 0.18 + sin(_bob * 9.0) * 0.004   # blubbert
			_slices.position.y = sin(_bob * 14.0) * 0.003       # brutzelt
			if _timer <= 0.0:
				_done()
		"soup":
			_timer -= delta
			_update_eaters(delta)
			if _timer <= 0.0:
				_end_soup("Die Kürbissuppe ist kalt geworden.")


func _done() -> void:
	if dish == "roast":
		var plate := Item.create(Item.Kind.ROAST_PUMPKIN, variety)
		plate.owner_id = "player"
		get_parent().add_child(plate)
		plate.global_position = _pan.global_position + Vector3(0, 0.06, 0)
		phase = "empty"
		_show()
		if _player_near(10.0):
			Game.say("%s ist fertig." % plate.display_name, 3.0)
		return
	phase = "soup"
	portions = PORTIONS
	_timer = COLD_TIME
	_player_ate = false
	_ate.clear()
	_show()
	Game.say("Es gibt Kürbissuppe in der Küche!", 4.0)
	_call_eaters()


func _end_soup(message: String) -> void:
	Game.social.pals.note_group(_ate)   # zusammen gegessen (6.16)
	if Game.tracing:
		print("[Kochen] Suppe aus: %d gegessen, %d Schalen übrig" % [_ate.size(), portions])
	for id in _eaters.keys():
		var g: Guest = _eaters[id]["guest"]
		if not g.dead and g.state in [Guest.State.EAT, Guest.State.IDLE]:
			g._set_idle(randf_range(2.0, 5.0))
	_eaters.clear()
	_ate.clear()
	phase = "empty"
	portions = 0
	_show()
	if message != "" and _player_near(15.0):
		Game.say(message, 3.0)


func _show() -> void:
	_soup.visible = (phase in ["raw", "cooking", "soup"]) and dish == "soup"
	_soup.material_override = Mat.psx(Color(0.95, 0.55, 0.15) if phase == "raw" else Color(0.95, 0.45, 0.08))
	_slices.visible = phase in ["raw", "cooking"] and dish == "roast"
	_steam.position = (_pot.position if dish == "soup" else _pan.position) + Vector3(0, 0.22, 0)
	_steam.emitting = phase == "cooking" or phase == "soup"


func _player_near(range_m: float) -> bool:
	var p := Game.player
	return p != null and not p.dead and p.global_position.distance_to(global_position) < range_m


# --- Gemeinsam essen --------------------------------------------------------------------

## Freie Gäste in der Nähe kommen zum Essen (bis EATERS), Kinder auch.
func _call_eaters() -> void:
	var pos := global_position
	var guests := Game.social.living_guests().filter(func(g: Guest) -> bool:
		return absf(g.global_position.y - pos.y) < 2.5 and g.global_position.distance_to(pos) < EAT_RANGE \
			and g.hiding == null and g.held == null and g.state in [Guest.State.IDLE, Guest.State.WALK] and not g.is_following() \
			and not Game.social.decorating.is_crew(g) and not Game.social.search.is_busy(g))
	guests.sort_custom(func(a: Guest, b: Guest) -> bool: return a.global_position.distance_to(pos) < b.global_position.distance_to(pos))
	var along := Vector3.UP.cross(front).normalized()
	var map := get_world_3d().navigation_map
	var i := 0
	for g: Guest in guests.slice(0, EATERS):
		var row := 1.1 + (i / 3) * 0.9
		var spot := pos + front * row + along * ((i % 3) - 1) * 0.9
		spot = NavigationServer3D.map_get_closest_point(map, Vector3(spot.x, g.global_position.y, spot.z))
		_eaters[g.id] = {"guest": g, "phase": "go", "time": 0.0, "spot": spot}
		g._walk_to(spot, Guest.State.EAT)
		i += 1
	if Game.tracing:
		print("[Kochen] Suppe fertig, es kommen: %s" % ", ".join(guests.slice(0, EATERS).map(func(g: Guest) -> String: return g.display_name)))


## Isst er gerade (oder ist auf dem Weg)? Gemeinsames Essen ist Spaß (Social.has_fun, Kürbismann 4.19).
func is_eating(g: Guest) -> bool:
	return _eaters.has(g.id) and _eaters[g.id]["phase"] == "eat"


## Der Spieler isst mit: am Topf, während Gäste essen.
func player_eats() -> bool:
	return phase == "soup" and _player_near(4.0) and _eaters.values().any(func(e: Dictionary) -> bool: return e["phase"] == "eat")


## Guest._arrive im Zustand EAT: eine Schale nehmen.
func on_arrived(g: Guest) -> void:
	if not _eaters.has(g.id):
		g._set_idle(randf_range(2.0, 5.0))
		return
	var entry: Dictionary = _eaters[g.id]
	if phase != "soup" or portions <= 0:
		_eaters.erase(g.id)
		g.say(LATE_LINES.pick_random())
		g._set_idle(randf_range(2.0, 5.0))
		return
	portions -= 1
	entry["phase"] = "eat"
	entry["time"] = randf_range(EAT_TIME.x, EAT_TIME.y)
	g._set_idle(30.0)
	var to := global_position - g.global_position
	g.rotation.y = atan2(-to.x, -to.z)
	if randf() < 0.6:
		g.say((KID_EAT_LINES if g.is_child() else EAT_LINES).pick_random())


func _update_eaters(delta: float) -> void:
	for id in _eaters.keys():
		var entry: Dictionary = _eaters[id]
		var g: Guest = entry["guest"]
		if g.dead or not g.state in [Guest.State.EAT, Guest.State.IDLE, Guest.State.TALKING]:
			_eaters.erase(id)   # erschreckt, versteckt …
			continue
		if g.state == Guest.State.TALKING:
			continue
		if entry["phase"] == "go":
			if g.state == Guest.State.IDLE:
				g._walk_to(entry["spot"], Guest.State.EAT)   # nach einem Gespräch weiter
			continue
		g._timer = 30.0
		entry["time"] = float(entry["time"]) - delta
		if float(entry["time"]) <= 0.0:
			g.fear = maxf(0.0, g.fear - FEAR_RELIEF)
			Game.social.change_relation(g, RELATION)
			_ate.append(g)
			if Game.tracing:
				print("[Kochen] %s hat gegessen (Beziehung %.0f)" % [g.display_name, g.relation])
			_eaters.erase(id)
			g._set_idle(randf_range(2.0, 5.0))
	if portions <= 0 and _eaters.is_empty():
		_end_soup("")
