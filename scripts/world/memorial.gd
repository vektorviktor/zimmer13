class_name Memorial
extends StaticBody3D
## Die Gedenkecke in der Lobby (Spielkonzept 5.15): ein schmales Wandtischchen, auf dem für jeden Toten ein rotes
## Grablicht brennt, davor ein Kärtchen mit seinem Namen. Am Tag danach liegen Blumen dabei. Die Trauer (6.8) hat einen
## Ort: Vor den brennenden Lichtern gedenken ([E]) senkt den Schock – einmal je Spieltag spürbar.
## **Das Warnsignal:** Kommt das Monster durch die Lobby, gehen alle Grablichter zugleich aus. Wieder anzünden kann man
## sie mit Streichhölzern oder einer Flamme in der Hand (Item.light_prompt); am Morgen zünden die Gäste sie wieder an.
## Die Lichter zählen als Licht (eine gemeinsame FlickerLight-Lampe, wie Kerzen `soft`).
## Ort: Ausstattung „Gedenktisch“ im Plan, bis dahin SPOT (Ostwand der Lobby). Aus den Toten abgeleitet – nicht
## gespeichert, nach dem Laden brennen sie.

const SPOT := Vector3(7.4, 0.0, -24.4)   ## Ostwand der Lobby, Tisch mit Blick nach −X
const TABLE := Vector3(1.5, 0.82, 0.42)
const PER_ROW := 6
const OUT_RANGE := 9.0                   ## Monster so nah (gleiches Stockwerk): alle aus
const LIGHT_ENERGY := 0.5                ## für die ersten Lichter, mehr Lichter etwas heller
const GLASS := Color(0.75, 0.05, 0.04)
const FLAME := Color(1.0, 0.6, 0.2)
const FLOWERS_AFTER := Calendar.DAY_SECONDS * 0.5
const COMFORT := 0.15                    ## so viel weniger Schock beim Gedenken
const NOTE := "In der Lobby brennen Grablichter für die Toten. Als es vorbeikam, gingen sie alle zugleich aus."

var lit := true
var _dead: Array[Dictionary] = []        ## je Toter: {id, name, at (Spielzeit), node}
var _light: FlickerLight
var _flames: Array[MeshInstance3D] = []
var _comfort_day := 0
var _check := 0.0
var _noted := false


func _ready() -> void:
	collision_layer = 1 | 4
	collision_mask = 0
	set_meta("interactable", self)
	position = SPOT
	rotation.y = -PI / 2.0   # +Z in die Lobby (nach −X)
	var wood := Mat.wood(false, Color(0.45, 0.32, 0.25))
	Geo.mesh(self, Geo.box(Vector3(TABLE.x, 0.04, TABLE.z)), wood, Vector3(0, TABLE.y - 0.02, TABLE.z / 2.0))
	for x in [-1.0, 1.0]:
		for z in [0.05, TABLE.z - 0.05]:
			Geo.mesh(self, Geo.box(Vector3(0.04, TABLE.y - 0.04, 0.04)), wood, Vector3(x * (TABLE.x / 2.0 - 0.05), (TABLE.y - 0.04) / 2.0, z))
	Geo.mesh(self, Geo.box(Vector3(TABLE.x, 0.004, TABLE.z * 0.8)), Mat.psx(Color(0.08, 0.07, 0.07)), Vector3(0, TABLE.y + 0.002, TABLE.z / 2.0))   # schwarzes Tuch
	Geo.add_box_shape(self, TABLE, Vector3(0, TABLE.y / 2.0, TABLE.z / 2.0))
	_light = FlickerLight.new()
	_light.soft = true
	_light.light_color = Color(1.0, 0.35, 0.2)
	_light.omni_range = 3.0   # kurz: ohne Schatten (nicht in „lamps“) schiene sie sonst durch die Wand
	_light.base_energy = 0.0
	_light.position = Vector3(0, TABLE.y + 0.2, TABLE.z / 2.0)
	add_child(_light)


func get_prompt(player: Player) -> String:
	if _dead.is_empty():
		return ""
	var flame := Item.light_prompt(self, player)
	if flame != "":
		return flame
	return "Gedenken [E]" if lit else "Die Grablichter sind aus"


func interact(player: Player) -> void:
	if Item.light_by(self, player):
		return
	if not lit or _dead.is_empty():
		return
	var today := Calendar.day_of(Game.director.elapsed)
	var names: Array = _dead.map(func(e: Dictionary) -> String: return e["name"])
	if today != _comfort_day:
		_comfort_day = today
		player.shock = maxf(0.0, player.shock - COMFORT)
	Game.say("Du stehst eine Weile vor den Lichtern. %s." % ", ".join(names), 4.0)


# Für Item.light_prompt / light_by (wie eine Kerze)
func can_light() -> bool:
	return not lit and not _dead.is_empty()


func light_up() -> void:
	lit = true
	_show()


func flame_name() -> String:
	return "Grablichter"


## Social.on_guest_died: ein neues Grablicht.
func on_guest_died(guest: Guest) -> void:
	_add(guest, Game.director.elapsed if Game.director else 0.0)


func _add(guest: Guest, at: float) -> void:
	for e in _dead:
		if e["id"] == guest.id:
			return
	var i := _dead.size()
	var node := Node3D.new()
	var row := i / PER_ROW
	var col := i % PER_ROW
	node.position = Vector3(-TABLE.x / 2.0 + 0.14 + col * (TABLE.x - 0.28) / (PER_ROW - 1), TABLE.y, 0.12 + row * 0.16)
	add_child(node)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(GLASS, 0.8)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.emission_enabled = true
	glass.emission = GLASS
	glass.emission_energy_multiplier = 0.6
	glass.roughness = 0.15
	Geo.mesh(node, Geo.cylinder(0.032, 0.1, 10), glass, Vector3(0, 0.05, 0))
	Geo.mesh(node, Geo.cylinder(0.034, 0.012, 10), Mat.metal(Color(0.7, 0.62, 0.4)), Vector3(0, 0.103, 0))   # Deckel
	var flame := Geo.mesh(node, Geo.sphere(0.009, 0.03, 6, 3), Mat.psx(FLAME, "", 1.0, FLAME, 3.0), Vector3(0, 0.075, 0))
	_flames.append(flame)
	var card := Label3D.new()   # Name auf einem Kärtchen davor
	card.text = guest.display_name
	card.font_size = 22
	card.pixel_size = 0.0009
	card.modulate = Color(0.12, 0.1, 0.08)
	card.outline_size = 0
	card.position = Vector3(0, 0.015, 0.07)
	card.rotation.x = -1.2
	node.add_child(card)
	Geo.mesh(node, Geo.box(Vector3(0.09, 0.002, 0.04)), Mat.psx(Color(0.9, 0.87, 0.8)), Vector3(0, 0.003, 0.07))
	_dead.append({"id": guest.id, "name": guest.display_name, "at": at, "node": node, "flowers": false})
	_show()


func _show() -> void:
	for f in _flames:
		f.visible = lit
	_light.base_energy = (LIGHT_ENERGY + 0.08 * minf(_dead.size(), 8)) if lit and not _dead.is_empty() else 0.0
	_light.burn_out = not lit or _dead.is_empty()


func _process(delta: float) -> void:
	_check -= delta
	if _check > 0.0:
		return
	_check = 0.5
	var d := Game.director
	if d == null:
		return
	if _dead.is_empty() and Game.social:   # nach dem Laden: aus den Toten
		for g in Game.social.guests:
			if (g as Guest).dead and not (g as Guest).is_child():
				_add(g, d.elapsed - Calendar.DAY_SECONDS)
	var m := Game.monster
	if lit and not _dead.is_empty() and m and m.is_active() and absf(m.global_position.y - global_position.y) < 2.0 \
			and m.global_position.distance_to(global_position) < OUT_RANGE:
		lit = false
		_show()
		if Game.tracing:
			print("[Gedenken] alle Grablichter gehen aus")
		if not _noted and Game.notebook and d.player_can_see(global_position + Vector3.UP):
			_noted = true
			Game.notebook.add_note("memorial_out", NOTE, "Lobby")
	if not lit and Calendar.phase() == Calendar.Phase.MORNING and not (m and m.is_active()) \
			and not d.player_can_see(global_position + Vector3.UP):
		lit = true   # morgens zünden die Gäste sie wieder an
		_show()
	for e in _dead:
		if not e["flowers"] and d.elapsed - float(e["at"]) > FLOWERS_AFTER and not d.player_can_see(global_position + Vector3.UP):
			e["flowers"] = true
			_flowers(e["node"])


## Ein kleiner Strauß neben dem Licht: Stiele und Blüten.
func _flowers(node: Node3D) -> void:
	var colors := [Color(0.85, 0.82, 0.75), Color(0.75, 0.15, 0.2), Color(0.95, 0.75, 0.2)]
	for k in 4:
		var a := k * 1.7
		var stem := Geo.mesh(node, Geo.cylinder(0.003, 0.12, 3), Mat.psx(Color(0.2, 0.35, 0.15)),
			Vector3(0.045 + cos(a) * 0.01, 0.04, sin(a) * 0.01))
		stem.rotation.z = -1.3
		Geo.mesh(node, Geo.sphere(0.012, 0.02, 6, 3), Mat.psx(colors[k % colors.size()]), Vector3(0.1 + cos(a) * 0.012, 0.03, sin(a) * 0.015))


## Debug (--gedenken[=aus]): drei Gäste sind tot, ihre Grablichter brennen, du stehst davor · aus: gleich kommt das
## Monster durch die Lobby (die Lichter gehen aus).
func debug_show(what: String) -> void:
	Game.director.first_attack_done = true
	if Game.social:
		var n := 0
		for g in Game.social.living_guests():
			if n >= 3:
				break
			if not g.is_child():
				_add(g, Game.director.elapsed - Calendar.DAY_SECONDS)
				n += 1
	var front := global_position + global_transform.basis.z * 1.8
	front.y = 0.05
	TeleportUI.place_player(front, global_position + Vector3.UP * 0.6 - front)
	if what == "aus":
		get_tree().create_timer(3.0, false).timeout.connect(func() -> void:
			Game.monster.spawn_at(global_position + global_transform.basis.z * 3.0 + Vector3(0, 0.05, 2.0)))
