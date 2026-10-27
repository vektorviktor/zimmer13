class_name AtticSpook
extends Node
## Spuk im Dachboden (Spielkonzept 4.21, 24.10.): Blitzt es, während der Spieler in einer der Kammern steht (nicht auf
## den offenen Böden), dreht ihn das Haus im hellsten Blitzbild um genau 90° nach links oder rechts – die Kinder von
## 1987 spielen ihm einen Streich, kurz danach kichert es leise. Ein grellweißer Bildblitz (Hud.flash_white) verdeckt
## den Augenblick, auch in Kammern ohne Fenster. Weather meldet jedes Blitzbild (on_flash). Mit CHANCE
## je Blitz, höchstens einmal je Gewitter, nie während eine Bedrohung hinter ihm her ist (Monster in der Nähe,
## Lakengeist bei ihm), nicht im Versteck oder im Sitzen. Bei abgeschwächtem Flackern (Einstellungen, Barrierefreiheit)
## nur das Kichern. Der Kompass zeigt den Dreh. Erzeugt vom LevelBuilder (_attic_haze), nicht gespeichert.
## Außerdem kennt er die Räume des Dachbodens und ihre Türen (für den Notausgang beim Urteil, Spielkonzept 4.33, 3a:
## das Monster erscheint ungesehen 1–2 Kammern neben der, die der Spieler zuletzt betreten hat) und lässt Staub aus
## einer Türöffnung rieseln.

const CHANCE := 0.5
const GIGGLE_DELAY := 1.2   ## Spielsekunden nach dem Dreh
const GIGGLE_VOLUME := 0.55
const WHITE := 0.9          ## Deckkraft des Blitzes übers Bild, in dem der Dreh passiert (Hud.flash_white)
## Notausgang (4.33): so weit hinter der Tür steht das Monster in seiner Kammer
const AMBUSH_BEHIND := 1.3
## Staub aus dem Türsturz: Körnchen, Lebenszeit, Größe, Farbe, so tief fällt er (m/s²)
const DUST := 70
const DUST_LIFE := 2.2
const DUST_SIZE := 0.02
const DUST_COLOR := Color(0.72, 0.7, 0.66, 0.8)
const DUST_FALL := 0.9

var forced := false   ## Debug --dachboden=blitz: beim nächsten Blitz sicher (ohne Zufall)
var _rects: Array[Rect2] = []
var _floor_y := 0.0
var _height := 0.0
var _done := false    ## in diesem Gewitter schon gespukt
var _rooms: Array = []           ## alle Räume des Dachbodens (Kammern und offene Böden), je ein Array[Rect2]
var _links: Array = []           ## je Raum: [{"to": Raum, "door": Door} …] (_link_rooms, beim ersten Gebrauch)
var _linked := false
var last_room := -1              ## Raum, den der Spieler zuletzt betreten hat (−1 = noch keiner)


## rects = Grundfläche der Kammern (x, z), rooms = alle Räume des Dachbodens (je ein Array[Rect2]), floor_y = Höhe
## des Bodens, height = bis zur Decke.
func setup(rects: Array[Rect2], rooms: Array, floor_y: float, height: float) -> AtticSpook:
	_rects = rects
	_rooms = rooms
	_floor_y = floor_y
	_height = height
	return self


func _process(_delta: float) -> void:
	if _done and Game.weather and Game.weather.kind != Weather.Kind.STORM:
		_done = false   # das Gewitter ist vorbei – im nächsten darf es wieder
	if Game.player:
		var i := room_at(Game.player.global_position)
		if i >= 0:
			last_room = i


## Ein Blitzbild (Weather): vielleicht den Spieler drehen.
func on_flash() -> void:
	var p := Game.player
	if _done or p == null or not in_chamber(p.global_position) or p.hiding or p.seat:
		return
	if not forced and (randf() >= CHANCE or _threatened(p.global_position)):
		return
	forced = false
	_done = true
	if Game.social and Game.social.talk:   # ein Erlebnis zum Erzählen (6.9)
		Game.social.talk.note("attic", p.global_position)
	var turn := Settings.flicker_intensity >= 1.0
	var dir := 1.0 if randf() < 0.5 else -1.0
	if turn:
		if Game.hud:
			Game.hud.flash_white(WHITE)   # auch in Kammern ohne Fenster: der Blitz blendet, dann steht man anders
		p.rotation.y = wrapf(p.rotation.y + dir * PI / 2.0, -PI, PI)
		Game.shot_event("attic_turn", 4)
	if Game.tracing:
		print("[Dachboden] Blitz – %s" % (("dreht dich um 90° nach " + ("links" if dir > 0.0 else "rechts")) if turn else "nur Kichern"))
	get_tree().create_timer(GIGGLE_DELAY, false).timeout.connect(func() -> void:
		Game.play_sound("giggle", GIGGLE_VOLUME)
		Game.caption("[leises Kichern]"))


## Steht p in einer Kammer des Dachbodens?
func in_chamber(p: Vector3) -> bool:
	if p.y < _floor_y - 0.3 or p.y > _floor_y + _height:
		return false
	for r in _rects:
		if r.has_point(Vector2(p.x, p.z)):
			return true
	return false


## Ist gerade etwas hinter ihm her? Monster in der Nähe (wirkt durch Wände) oder der Lakengeist bei ihm.
func _threatened(p: Vector3) -> bool:
	return (Game.director and Game.director.threat_at(p) > 0.0) or (Game.ghost and Game.ghost.with_player())


# --- Notausgang beim Urteil (Spielkonzept 4.33, 3a) ---------------------------------------------------------------

## Raum des Dachbodens, in dem p steht (−1 = keiner, auch nicht auf der Höhe des Dachbodens).
func room_at(p: Vector3) -> int:
	if p.y < _floor_y - 0.3 or p.y > _floor_y + _height:
		return -1
	for i in _rooms.size():
		for r: Rect2 in _rooms[i]:
			if r.has_point(Vector2(p.x, p.z)):
				return i
	return -1


## Türen zwischen den Räumen: Vor und hinter jeder niedrigen Tür auf dieser Höhe liegt je ein Raum.
func _link_rooms() -> void:
	_linked = true
	_links.clear()
	for i in _rooms.size():
		_links.append([])
	for node in get_tree().get_nodes_in_group("doors"):
		var door := node as Door
		if door.look != Door.Look.ATTIC:
			continue
		var c := door.center()
		var n := door.global_basis.z
		var a := room_at(Vector3(c.x, _floor_y, c.z) + n * 0.6)
		var b := room_at(Vector3(c.x, _floor_y, c.z) - n * 0.6)
		if a >= 0 and b >= 0 and a != b:
			(_links[a] as Array).append({"to": b, "door": door})
			(_links[b] as Array).append({"to": a, "door": door})


## Wo das Monster beim Notausgang erscheint: in einem Raum, eine oder zwei Türen von dem entfernt, in dem der Spieler
## steht (sonst dem, den er zuletzt betreten hat), hinter der Tür, die zu ihm führt – nur, wo er gerade nicht hinsieht;
## schaut er auf diese Tür, nimmt es eine andere. {"pos", "door"} – leer, wenn es keinen solchen Raum gibt.
func ambush_spot(player: Player) -> Dictionary:
	if not _linked:
		_link_rooms()
	var start := room_at(player.global_position)
	if start < 0:
		start = last_room
	if start < 0:
		return {}
	# Breitensuche: Tiefe und die Tür zum Raum davor (Richtung Spieler)
	var depth := {start: 0}
	var via := {}
	var queue: Array[int] = [start]
	while not queue.is_empty():
		var i: int = queue.pop_front()
		if int(depth[i]) >= 2:
			continue
		for link: Dictionary in _links[i]:
			var to: int = link["to"]
			if not depth.has(to):
				depth[to] = int(depth[i]) + 1
				via[to] = link["door"]
				queue.append(to)
	var spots: Array[Dictionary] = []
	for i in via:
		var door: Door = via[i]
		var c := door.center()
		var n := door.global_basis.z
		var into := n if room_at(Vector3(c.x, _floor_y, c.z) + n * 0.6) == i else -n
		var pos := Vector3(c.x, _floor_y, c.z) + into * AMBUSH_BEHIND
		if room_at(pos) == i and not Game.director.player_can_see(pos + Vector3.UP * 1.2):
			spots.append({"pos": pos, "door": door, "watched": Game.director.player_can_see(c)})
	spots.shuffle()
	spots.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return not a["watched"] and b["watched"])
	return spots[0] if not spots.is_empty() else {}


## Staub rieselt aus dem Sturz der Tür (Notausgang: etwas Schweres stößt dagegen).
func dust(door: Door) -> void:
	var mat := Mat.particle(null, 0.05)
	var p := Geo.particles(DUST, DUST_LIFE, DUST_SIZE, mat, 0.05, 0.4)
	p.color = DUST_COLOR
	p.one_shot = true
	p.explosiveness = 0.6
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(door.width * 0.45, 0.02, 0.08)
	p.direction = Vector3.DOWN
	p.spread = 25.0
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.3
	p.gravity = Vector3(0, -DUST_FALL, 0)
	p.damping_min = 0.2
	p.damping_max = 0.6
	add_child(p)
	p.global_transform = Transform3D(door.global_basis, door.global_transform * Vector3(door.width / 2.0, door.height - 0.03, 0))
	p.emitting = true
	get_tree().create_timer(DUST_LIFE + 0.5, false).timeout.connect(p.queue_free)
