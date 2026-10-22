extends Node
## Rechentests ohne Spielwelt: Rampe der Lobbytreppe (Spielkonzept 7.5), Kompassnadel, Türraster (Door.near).
## Läuft über tests/run.tscn (braucht die Autoloads).

var _ok := true


func run() -> bool:
	_stair_ramp()
	_compass_needle()
	_door_grid()
	print("Rechentests: alles richtig" if _ok else "Rechentests: FEHLER")
	return _ok


func _check(good: bool, text: String) -> void:
	print(("ok      " if good else "FALSCH  ") + text)
	_ok = _ok and good


## Die Lauframpe muss vorn auf dem Boden beginnen, oben bündig mit der Galerie enden (eine halbe Stufe Kante hielt
## Gäste fest) und überall zwischen Trittfläche und Stufenkante liegen.
func _stair_ramp() -> void:
	var rise := LevelBuilder.UP_Y
	var run := 6.9
	var n := maxi(2, roundi(rise / GrandStair.RISER))
	var h := rise / n
	var g := run / (n - 1)
	var nose := func(u: float) -> float: return h + u * h / g
	var holder := Node3D.new()
	var ramp := GrandStair._collision(holder, 3.8, run, rise, n, h, g, 1.83, nose)
	var up := ramp.transform.basis.y.normalized()
	var top := ramp.transform.origin + up * GrandStair.RAMP_T / 2.0   # ein Punkt auf der Lauffläche
	var height := func(u: float) -> float: return top.y - up.z * (-u - top.z) / up.y
	_check(absf(height.call(run) - rise) < 0.01, "Treppenrampe oben bündig mit der Galerie (%.3f m bei %.1f m)" % [height.call(run), rise])
	_check(absf(height.call(-g / 2.0)) < 0.01, "Treppenrampe beginnt vorn auf dem Boden (%.3f m)" % height.call(-g / 2.0))
	var lowest := INF
	var highest := -INF
	for k in range(1, n):
		var above: float = height.call((k - 0.5) * g) - k * h   # über der Mitte der k-ten Trittfläche
		lowest = minf(lowest, above)
		highest = maxf(highest, above)
	_check(lowest > -0.01 and highest <= h + 0.01,
		"Treppenrampe zwischen Trittflächen und Stufenkanten (%.3f … %.3f m über den Trittmitten)" % [lowest, highest])
	var shape := (ramp.get_child(0) as CollisionShape3D).shape as BoxShape3D
	var along := ramp.transform.basis.z.normalized() * shape.size.z / 2.0
	var ends := [top + along, top - along]   # Enden der Lauffläche
	var front := maxf(ends[0].z, ends[1].z)
	var back := minf(ends[0].z, ends[1].z)
	_check(front >= g / 2.0 - 0.02 and back <= -run + 0.02, "Treppenrampe reicht von z %.2f bis %.2f" % [front, back])
	holder.free()


## Die Federnadel muss bei jedem Frame endlich bleiben und bei normalen Frames auf ihr Ziel einschwingen.
func _compass_needle() -> void:
	for delta: float in [1.0 / 60.0, 0.1, 0.5, 2.0, 10.0]:
		var state := Vector2.ZERO
		for i in 50:
			state = Item.needle_step(state, PI * 0.9, delta)
		_check(state.is_finite(), "Kompassnadel endlich bei %.3f s je Frame (%.2f rad)" % [delta, state.x])
	var settle := Vector2.ZERO
	for i in 300:
		settle = Item.needle_step(settle, 1.0, 1.0 / 60.0)
	_check(absf(settle.x - 1.0) < 0.05, "Kompassnadel schwingt ein (%.3f rad nach 5 s, Ziel 1)" % settle.x)


## Door.near muss jede Tür liefern, deren Mitte im Grundriss näher als Door.CELL liegt – auch Türen, die erst nach
## dem Einhängen versetzt wurden – und freigegebene Türen vergessen.
func _door_grid() -> void:
	var world := Node3D.new()
	add_child(world)
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	for i in 60:
		var door := Door.new().setup(rng.randf_range(0.8, 1.6), 2.1, -100.0, i % 7 == 0)
		var pos := Vector3(rng.randf_range(-30.0, 30.0), [0.0, 4.0][i % 2], rng.randf_range(-30.0, 30.0))
		if i % 3 == 0:
			world.add_child(door)
			door.position = pos   # nach dem Einhängen versetzt: das Raster entsteht erst beim Abfragen
		else:
			door.position = pos
			world.add_child(door)
		door.rotation.y = rng.randf() * TAU
	var missing := 0
	for i in 300:
		var p := Vector3(rng.randf_range(-35.0, 35.0), 0.0, rng.randf_range(-35.0, 35.0))
		var near := Door.near(p)
		for door: Door in world.get_children():
			var c := door.center()
			if Vector2(c.x - p.x, c.z - p.z).length() < Door.CELL and not door in near:
				missing += 1
	_check(missing == 0, "Türraster findet alle Türen im Umkreis von %.0f m (%d fehlen)" % [Door.CELL, missing])
	var gone: Door = world.get_child(0)
	var spot := gone.center()
	gone.free()
	_check(not Door.near(spot).any(func(d: Variant) -> bool: return not is_instance_valid(d)),
		"Türraster vergisst freigegebene Türen")
	world.free()
