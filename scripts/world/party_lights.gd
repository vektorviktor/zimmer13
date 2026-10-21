class_name PartyLights
extends Node3D
## Bunte Partylampen (Spielkonzept 7.6, entschieden 2026-10-21): farbige Strahler unter der Decke des Partyraums,
## auf die Tanzfläche gerichtet. Läuft eine Feier (Social.party_active), blenden sie ein und wechseln langsam die
## Farben – jeder versetzt, ab und zu alle gemeinsam im Takt; sonst sind sie aus. Ohne Schatten, nicht in der Gruppe
## „lamps“ (ShadowBudget und Flackern lassen sie in Ruhe). Nicht gespeichert.

## Farben, durch die die Strahler wandern (rot, orange, grün, blau, lila)
const COLORS: Array[Color] = [Color(1.0, 0.15, 0.2), Color(1.0, 0.55, 0.1), Color(0.25, 1.0, 0.3), Color(0.2, 0.4, 1.0),
	Color(0.75, 0.25, 1.0)]
## So lange bleibt eine Farbe, so lange dauert der Übergang
const HOLD := 2.2
const BLEND := 0.8
## Gemeinsamer Wechsel: so oft, so lange alle dieselbe Farbe
const SYNC_GAP := Vector2(9.0, 16.0)
const SYNC_TIME := 3.0
const ENERGY := 24.0
const FADE := 1.5
const ANGLE := 21.0

var _spots: Array[SpotLight3D] = []
var _lenses: Array[StandardMaterial3D] = []
var _level := 0.0
var _time := 0.0
var _sync_timer := 10.0
var _sync_left := 0.0
var _sync_color := 0


## room: Grundfläche des Partyraums, mount: Höhe der Strahler, center: Mitte der Tanzfläche (Boden).
func setup(room: Rect2, mount: float, center: Vector3) -> PartyLights:
	var inner := room.grow(-0.35)
	var points: Array[Vector2] = [inner.position, Vector2(inner.end.x, inner.position.y), inner.end, Vector2(inner.position.x, inner.end.y)]
	if room.size.x >= room.size.y:
		points.append(Vector2(inner.get_center().x, inner.position.y))
		points.append(Vector2(inner.get_center().x, inner.end.y))
	else:
		points.append(Vector2(inner.position.x, inner.get_center().y))
		points.append(Vector2(inner.end.x, inner.get_center().y))
	var housing := Mat.psx(Color(0.08, 0.08, 0.09))
	for i in points.size():
		var p := Vector3(points[i].x, mount, points[i].y)
		var holder := Node3D.new()
		add_child(holder)
		var target := center + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5))
		holder.transform = Transform3D(Basis.looking_at(target - p, Vector3.UP), p)   # -Z zeigt auf die Tanzfläche
		Geo.mesh(holder, Geo.box(Vector3(0.18, 0.18, 0.24)), housing, Vector3(0, 0, 0.02))
		var lens := StandardMaterial3D.new()
		lens.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		lens.albedo_color = Color(0.1, 0.1, 0.1)
		Geo.mesh(holder, Geo.cylinder(0.07, 0.02, 8), lens, Vector3(0, 0, -0.105)).rotation.x = PI / 2.0
		_lenses.append(lens)
		var spot := SpotLight3D.new()
		spot.position = Vector3(0, 0, -0.12)
		spot.spot_angle = ANGLE
		spot.spot_angle_attenuation = 0.8
		spot.spot_attenuation = 0.4   # weit weg von der Tanzfläche – kaum Abfall mit der Entfernung
		spot.spot_range = p.distance_to(target) * 1.6
		spot.light_energy = 0.0
		spot.shadow_enabled = false
		spot.visible = false
		holder.add_child(spot)
		_spots.append(spot)
	return self


func _process(delta: float) -> void:
	var on := Game.social != null and Game.social.party_active and not Game.game_over
	_level = move_toward(_level, 1.0 if on else 0.0, delta / FADE)
	if _level <= 0.0 and not _spots[0].visible:
		return
	_time += delta
	if on:
		_sync_timer -= delta
		if _sync_timer <= 0.0:
			_sync_timer = randf_range(SYNC_GAP.x, SYNC_GAP.y)
			_sync_left = SYNC_TIME
			_sync_color = randi() % COLORS.size()
	_sync_left = maxf(0.0, _sync_left - delta)
	for i in _spots.size():
		var color := _color_at(_time / (HOLD + BLEND) + i * 1.37)
		if _sync_left > 0.0:
			color = color.lerp(COLORS[_sync_color], clampf(_sync_left * 3.0, 0.0, 1.0))
		var spot := _spots[i]
		spot.visible = _level > 0.0
		spot.light_color = color
		spot.light_energy = ENERGY * _level
		_lenses[i].albedo_color = Color(0.1, 0.1, 0.1).lerp(color, _level)


## Farbe nach Phase (ganze Zahl = eine Farbe ganz, Rest: halten, dann überblenden).
func _color_at(phase: float) -> Color:
	var n := COLORS.size()
	var i := int(floor(phase)) % n
	var f := clampf((fposmod(phase, 1.0) * (HOLD + BLEND) - HOLD) / BLEND, 0.0, 1.0)
	return COLORS[i].lerp(COLORS[(i + 1) % n], f)
