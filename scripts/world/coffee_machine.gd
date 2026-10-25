class_name CoffeeMachine
extends StaticBody3D
## Kaffeemaschine in der Küche (Spielkonzept 3.11), links auf der Küchenzeile: [E] mit leeren Händen – sie mahlt und
## gurgelt brew_time Sekunden (Lärm noise_kind), dann steht eine Tasse (drink_kind) unter dem Auslauf. Umsonst. In
## guest_phase (Kaffee: morgens 6–11 Uhr) geht alle GUEST_GAP Sekunden ein freier Gast aus der Nähe hin (Zustand EAT wie
## am Herd, Guest._arrive fragt expects), kocht sich eine Tasse und trinkt sie dort – wer innerhalb von TOGETHER Sekunden
## hier trank, wird miteinander vertrauter (6.16). Kinder nur, wenn children (Kaffee nie, 6.13).
## Der Wasserkocher (TeaKettle, 3.12) ist dasselbe mit Tee, abends und eigener Optik (_build).
## Was gerade läuft, wird nicht gespeichert (die fertige Tasse schon, sie ist ein Gegenstand).
## Erreichbar über Game.coffee bzw. Game.kettle. Ursprung = Unterseite auf der Arbeitsplatte, lokale +Z = Vorderseite.

const BREW_TIME := 20.0
## Während sie läuft: alle so viele Sekunden Lärm (Mahlen, Gurgeln)
const NOISE_EVERY := 5.0
## Gäste: so lange Pause zwischen zwei Versuchen (s), so weit (gleiches Stockwerk) kommt einer her, so lange steht er
## nach dem Brühen noch da und trinkt
const GUEST_GAP := Vector2(40.0, 90.0)
const GUEST_RANGE := 16.0
const GUEST_STAY := 16.0
const TOGETHER := 90.0
const LINES := ["Erst mal einen Kaffee.", "Ohne Kaffee bin ich kein Mensch.", "Ah, frisch gebrüht.", "Die Nacht war kurz …"]
## Wo die Tasse steht (lokal, auf der Arbeitsplatte unter dem Auslauf)
const CUP_SPOT := Vector3(0, 0.0, 0.07)

var front := Vector3(0, 0, 1)
var brewing := false
## Was hier gekocht wird – der Wasserkocher setzt das in _init anders
var drink_kind := Item.Kind.COFFEE
var brew_time := BREW_TIME
var noise_kind := "coffee"
var guest_phase := Calendar.Phase.MORNING
var children := false
var lines: Array = LINES
var cup_spot := CUP_SPOT
## Texte: Name des Geräts, läuft, mit leeren Händen, kochen, Gedanke beim Start, fertig, Trace-Kürzel
var texts := {"name": "Kaffeemaschine", "brewing": "Der Kaffee läuft durch", "make": "Kaffee kochen",
	"start": "Die Maschine mahlt und gurgelt. Hoffentlich hört das niemand.", "done": "Der Kaffee ist fertig.",
	"trace": "Kaffee", "drinks": "trinkt Kaffee an der Maschine", "to": "zur Kaffeemaschine"}

var _timer := 0.0
var _noise_timer := 0.0
var _brew_for: Guest          ## brüht für diesen Gast (null = für den Spieler)
var _guest: Guest             ## Gast auf dem Weg hierher oder davor
var _guest_timer := randf_range(GUEST_GAP.x, GUEST_GAP.y)
var _drinkers: Array[Dictionary] = []   ## {guest, at} – wer zuletzt hier trank (MonsterDirector.elapsed)
var _cup: Item                ## die letzte Tasse, solange sie an ihrem Platz steht
var _lamp: MeshInstance3D
var _lamp_on: Material
var _lamp_off: Material
var _steam: CPUParticles3D


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	set_meta("interactable", self)
	_register()
	_build()
	_steam = CPUParticles3D.new()
	_steam.emitting = false
	_steam.amount = 10
	_steam.lifetime = 1.6
	_steam.local_coords = false
	_steam.direction = Vector3.UP
	_steam.spread = 10.0
	_steam.gravity = Vector3(0, 0.12, 0)
	_steam.initial_velocity_min = 0.08
	_steam.initial_velocity_max = 0.16
	_steam.scale_amount_min = 0.6
	_steam.scale_amount_max = 1.6
	var puff := QuadMesh.new()
	puff.size = Vector2(0.03, 0.03)
	var puff_mat := StandardMaterial3D.new()
	puff_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	puff_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puff_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	puff_mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	puff_mat.albedo_color = Color(0.92, 0.92, 0.9, 0.2)
	puff.material = puff_mat
	_steam.mesh = puff
	_steam.position = _steam_spot()
	add_child(_steam)


func _register() -> void:
	Game.coffee = self


## Aussehen und Kollision: Gehäuse mit Kopf und Auslauf, Abtropfgitter, Wassertank, Lämpchen.
func _build() -> void:
	var shell := Mat.psx(Color(0.13, 0.13, 0.14))
	var steel := Mat.psx(Color(0.55, 0.55, 0.57))
	Geo.mesh(self, Geo.box(Vector3(0.24, 0.34, 0.16)), shell, Vector3(0, 0.17, -0.06))          # Gehäuse
	Geo.mesh(self, Geo.box(Vector3(0.24, 0.06, 0.12)), shell, Vector3(0, 0.31, 0.07))           # Kopf mit Auslauf
	Geo.mesh(self, Geo.cylinder(0.012, 0.03, 6), steel, Vector3(0, 0.265, 0.07))                # Auslauf
	Geo.mesh(self, Geo.box(Vector3(0.2, 0.012, 0.12)), steel, Vector3(0, 0.006, 0.07))          # Abtropfgitter
	Geo.mesh(self, Geo.box(Vector3(0.07, 0.2, 0.07)), Mat.psx(Color(0.45, 0.5, 0.55)), Vector3(0.09, 0.2, -0.13))   # Wassertank
	_lamp_off = Mat.psx(Color(0.2, 0.05, 0.04))
	_lamp_on = Mat.psx(Color(1.0, 0.25, 0.1), "", 1.0, Color(1.0, 0.25, 0.1), 1.5)
	_lamp = Geo.mesh(self, Geo.box(Vector3(0.018, 0.018, 0.005)), _lamp_off, Vector3(-0.08, 0.31, 0.131))
	# Nur das Gehäuse ist fest – unter dem Auslauf steht die Tasse auf der Arbeitsplatte
	Geo.add_box_shape(self, Vector3(0.24, 0.34, 0.16), Vector3(0, 0.17, -0.06))
	Geo.add_box_shape(self, Vector3(0.24, 0.06, 0.12), Vector3(0, 0.31, 0.07))


## Wo es dampft, solange es läuft.
func _steam_spot() -> Vector3:
	return cup_spot + Vector3(0, 0.12, 0)


## Beim Laden eines Spielstands (SaveManager.apply): aus, niemand wartet (nicht gespeichert).
func reset() -> void:
	brewing = false
	_brew_for = null
	_guest = null
	_drinkers.clear()
	_cup = null
	_show()


## Steht noch eine Tasse an ihrem Platz? Dann kocht es keine zweite.
func _cup_waiting() -> bool:
	return is_instance_valid(_cup) and not _cup.is_held and not _cup.in_bag \
		and _cup.global_position.distance_to(to_global(cup_spot)) < 0.15


func get_prompt(player: Player) -> String:
	if brewing:
		return "%s – noch %d s" % [texts["brewing"], ceili(_timer)]
	if _cup_waiting():
		return _cup.get_prompt(player)   # die Tasse ist klein – wer aufs Gerät schaut, nimmt sie
	if player.held or player.carried_cat:
		return "%s – mit leeren Händen %s" % [texts["name"], texts["make"]]
	return "%s [E]" % texts["make"]


func get_icon(_player: Player) -> String:
	return IconArt.drink_icon(drink_kind)


func interact(player: Player) -> void:
	if _cup_waiting() and not brewing:
		_cup.interact(player)
		return
	if brewing or player.held or player.carried_cat:
		return
	_start_brew(null, player)
	Game.say(texts["start"], 3.0)


func _start_brew(for_guest: Guest, source: Node) -> void:
	brewing = true
	_brew_for = for_guest
	_timer = brew_time
	_noise_timer = 0.0
	_show()
	Game.noise(noise_kind, global_position, source)


func _process(delta: float) -> void:
	if Game.game_over:
		return
	if brewing:
		_timer -= delta
		_noise_timer += delta
		if _noise_timer >= NOISE_EVERY:
			_noise_timer = 0.0
			Game.noise(noise_kind, global_position, _brew_for if _brew_for else self)
		if _timer <= 0.0:
			_done()
	_update_guest(delta)


func _show() -> void:
	if _lamp:
		_lamp.material_override = _lamp_on if brewing else _lamp_off
	if _steam:
		_steam.emitting = brewing


## Fertig: die Tasse steht da – ein wartender Gast nimmt sie und trinkt (Guest.receive_gift, FOOD_GIFTS).
func _done() -> void:
	brewing = false
	_show()
	_finished()
	var cup := Item.create(drink_kind)
	get_parent().add_child(cup)
	cup.global_position = to_global(cup_spot) + Vector3.UP * 0.005
	cup.rotation.y = rotation.y
	_cup = cup
	var g := _brew_for
	_brew_for = null
	if g and g == _guest and not g.dead and g.state in [Guest.State.EAT, Guest.State.IDLE] and g.held == null:
		cup.owner_id = g.id
		g.receive_gift(cup)   # trinkt nach ein paar Sekunden aus (Guest._gift_step)
		g._set_idle(GUEST_STAY)
		_note_drinker(g)
		if Game.tracing:
			print("[%s] %s %s" % [texts["trace"], g.display_name, texts["drinks"]])
		_guest = null
		return
	cup.owner_id = "player" if g == null else ""
	if Game.tracing:
		print("[%s] Tasse fertig bei %s" % [texts["trace"], cup.global_position.snapped(Vector3.ONE * 0.01)])
	if g == null and _player_near(12.0):
		Game.say(texts["done"], 2.5)


## Gleich nach dem Kochen, bevor die Tasse dasteht (Wasserkocher: er pfeift).
func _finished() -> void:
	pass


## Wer kurz nacheinander hier trinkt, wird miteinander vertrauter (6.16).
func _note_drinker(g: Guest) -> void:
	var now := Game.director.elapsed if Game.director else 0.0
	_drinkers = _drinkers.filter(func(d: Dictionary) -> bool:
		return now - float(d["at"]) <= TOGETHER and is_instance_valid(d["guest"]) and not (d["guest"] as Guest).dead)
	for d in _drinkers:
		if d["guest"] != g:
			Game.social.pals.note(g, d["guest"])
	_drinkers.append({"guest": g, "at": now})


func _player_near(range_m: float) -> bool:
	var p := Game.player
	return p != null and not p.dead and p.global_position.distance_to(global_position) < range_m


# --- Gäste ---------------------------------------------------------------------------------

## Kommt dieser Gast gerade hierher? (Guest._arrive im Zustand EAT – sonst ist es der Herd.)
func expects(g: Guest) -> bool:
	return g == _guest


## In guest_phase alle GUEST_GAP s ein Gast; wer unterwegs abbricht (Schreck, Gespräch …), gibt das Gerät frei.
func _update_guest(delta: float) -> void:
	if _guest:
		if _guest.dead or not _guest.state in [Guest.State.EAT, Guest.State.IDLE, Guest.State.TALKING]:
			_guest = null
		return
	_guest_timer -= delta
	if _guest_timer > 0.0:
		return
	_guest_timer = randf_range(GUEST_GAP.x, GUEST_GAP.y)
	start_guest(null)


## Ein Gast holt sich eine Tasse (Debug: dieser, zu jeder Uhrzeit). false = keiner frei oder das Gerät ist belegt.
func start_guest(forced: Guest) -> bool:
	var social := Game.social
	if social == null or brewing or _guest != null or _cup_waiting():
		return false
	if forced == null and (Calendar.phase() != guest_phase or social.party_active or social.sleep_active \
			or not Game.director.is_quiet(global_position)):
		return false
	var pos := global_position
	var g := forced
	if g == null:
		var candidates := social.living_guests().filter(func(c: Guest) -> bool:
			return (children or not c.is_child()) and c.held == null and c.hiding == null \
				and c.state in [Guest.State.IDLE, Guest.State.WALK] and not c.is_following() and c.fear < 50.0 \
				and absf(c.global_position.y - pos.y) < 2.5 and c.global_position.distance_to(pos) < GUEST_RANGE \
				and not social.decorating.is_crew(c) and not social.search.is_busy(c) and not _taken(c))
		if candidates.is_empty():
			return false
		g = candidates.pick_random()
	_guest = g
	g._walk_to(guest_spot(), Guest.State.EAT)
	if Game.tracing:
		print("[%s] %s geht %s" % [texts["trace"], g.display_name, texts["to"]])
	return true


## Ist er schon an einem anderen Gerät unterwegs (Kaffeemaschine und Wasserkocher stehen nebeneinander)?
func _taken(g: Guest) -> bool:
	for other: CoffeeMachine in [Game.coffee, Game.kettle]:
		if other and other != self and other.expects(g):
			return true
	return false


## Wo der Gast steht: vor dem Gerät, aufs NavMesh gezogen.
func guest_spot() -> Vector3:
	return NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map, global_position + front * 0.7)


## Guest._arrive im Zustand EAT: hier – kochen und warten.
func on_arrived(g: Guest) -> void:
	if g != _guest or brewing or _cup_waiting():
		_guest = null if g == _guest else _guest
		g._set_idle(randf_range(2.0, 5.0))
		return
	var to := global_position - g.global_position
	g.rotation.y = atan2(-to.x, -to.z)
	g._set_idle(brew_time + 3.0)   # wartet davor
	_start_brew(g, g)
	if randf() < 0.6:
		g.say(lines.pick_random())
