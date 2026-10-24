class_name LightRooms
extends RefCounted
## Bereiche fürs Licht: Der Grundriss jedes Stockwerks zerfällt an den Wänden des Plans in Bereiche (Raster wie
## LevelBuilder.GRID). Türen verbinden zwei Bereiche, solange sie Licht durchlassen (Door.lets_light), Fenster,
## Glastüren und Aufzugtüren nur einen Schritt weit; Treppen, Lufträume und freier Himmel verbinden Stockwerke
## dauerhaft. reach() sagt, welche Bereiche die Kamera erreichen kann – Lichter anderswo schaltet ShadowBudget für die
## Darstellung ab (ohne Platz im Schattenatlas schienen sie durch Wände). An/Aus, Energie und
## MonsterDirector.light_at bleiben unberührt. Nichts wird von Hand gepflegt: LevelBuilder meldet beim Bau jede Wand,
## Tür, Fenster und Öffnung des Plans (begin_floor … finish).

const CELL := 0.25
## Seiten einer Tür bzw. eines Fensters: so weit quer zur Wand von ihrer Mitte
const SIDE := 0.45
## Liegt ein Punkt in einer Wandzelle: so viele Zellen weit nach der nächsten freien suchen
const SEARCH := 2
## Wände mindestens so dick rastern (plus Rand), damit jede wenigstens eine Zelle schließt und Ecken dicht sind
const MIN_WALL := 0.25
## Abstand der Stichproben in Treppen und Lufträumen bzw. unter freiem Himmel (m)
const SAMPLE := 1.0
const SKY_SAMPLE := 2.0
## Lose Lichter (Gegenstände) und die Kamera gehören zum höchsten Stockwerk, dessen Boden höchstens ABOVE über ihnen
## liegt – liegt dort keine Fläche des Plans, aber im Stockwerk darüber (bis BELOW), zu dem (ins Becken gefallen)
const ABOVE := 0.5
const BELOW := 2.0
## Flächenarten draußen, wenn der Plan es nicht sagt (Terrassen- und Balkonkanten, Kies)
const OUTDOOR_KINDS := ["garden", "terrace", "balcony", "gravel"]

enum Link { DOOR, GLASS, WINDOW }

var region_count := 0

## Je Stockwerk: {level, base_y, origin, size, places (Fläche je Zelle wie LevelBuilder._grid), outdoor (je Fläche),
## walls (beim Bau: je Zeile Paare [von, bis]), runs (je Zeile PackedInt32Array [von, bis, Lauf, …])}
var _floors: Array[Dictionary] = []
var _roots := {}                         ## Wurzelknoten eines Stockwerks → Index in _floors
var _parent := PackedInt32Array()        ## Union-Find über die freien Läufe aller Stockwerke
var _run_region := PackedInt32Array()    ## Lauf → Bereich (nach finish)
var _pending: Array = []                 ## Türen und Fenster bis finish: [Stockwerk, Seite a, Seite b, Link, Door]
var _openings: Array = []                ## Treppen und Lufträume bis finish: [Stockwerk, Rect2, hinauf, hinab]
var _links_a := PackedInt32Array()
var _links_b := PackedInt32Array()
var _links_kind := PackedInt32Array()
var _links_door: Array[Door] = []
var _adjacent: Array = []                ## je Bereich die Indizes seiner Verbindungen


## Neues Stockwerk (LevelBuilder._begin_floor): Raster und Flächen wie dessen Nachschlagetabelle.
func begin_floor(level: int, base_y: float, root: Node3D, origin: Vector2, size: Vector2i, places: PackedInt32Array,
		place_info: Array[Dictionary]) -> void:
	var outdoor := PackedByteArray()
	for p in place_info:
		var region: Dictionary = p["region"]
		outdoor.append(1 if bool(region.get("outdoor", String(p["kind"]) in OUTDOOR_KINDS)) else 0)
	var walls := []
	walls.resize(size.y)
	for y in size.y:
		walls[y] = []
	_floors.append({"level": level, "base_y": base_y, "origin": origin, "size": size, "places": places,
		"outdoor": outdoor, "walls": walls, "runs": []})
	_roots[root] = _floors.size() - 1


## Wand des Plans von a nach b (achsparallel) – samt ihren Öffnungen; die verbinden door/window.
func wall(a: Vector2, b: Vector2, thickness: float) -> void:
	var f: Dictionary = _floors[-1]
	var half := thickness / 2.0 + maxf(0.04, (MIN_WALL - thickness) / 2.0 + 0.01)
	var lo := Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2(half, half)
	var hi := Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2(half, half)
	var o: Vector2 = f["origin"]
	var size: Vector2i = f["size"]
	var c0 := Vector2i(maxi(0, ceili((lo.x - o.x) / CELL - 0.5)), maxi(0, ceili((lo.y - o.y) / CELL - 0.5)))
	var c1 := Vector2i(mini(size.x - 1, floori((hi.x - o.x) / CELL - 0.5)), mini(size.y - 1, floori((hi.y - o.y) / CELL - 0.5)))
	var walls: Array = f["walls"]
	for y in range(c0.y, c1.y + 1):
		(walls[y] as Array).append_array([c0.x, c1.x])


## Tür mit Mitte c in einer Wand quer zu side (Einheitsvektor).
func door(c: Vector2, side: Vector2, d: Door) -> void:
	_pending.append([_floors.size() - 1, c - side * SIDE, c + side * SIDE, Link.GLASS if d.glass else Link.DOOR, d])


## Fenster, Aufzugtür oder ein Meter Glaswand: lässt Licht einen Schritt weit durch.
func window(c: Vector2, side: Vector2) -> void:
	_pending.append([_floors.size() - 1, c - side * SIDE, c + side * SIDE, Link.WINDOW, null])


## Treppe bzw. Luftraum: verbindet dauerhaft mit dem Stockwerk darüber (up) bzw. darunter (down).
func opening(r: Rect2, up: bool, down: bool) -> void:
	_openings.append([_floors.size() - 1, r, up, down])


## Nach dem Bau aller Stockwerke: Läufe zu Bereichen, Stockwerke verbinden, Türen und Fenster einhängen.
func finish() -> void:
	for f in _floors:
		_build_runs(f)
	for o in _openings:
		var fi: int = o[0]
		var r: Rect2 = o[1]
		for step: int in [1, -1]:
			var other := _floor_of_level(int(_floors[fi]["level"]) + step)
			if other < 0 or not (o[2] if step > 0 else o[3]):
				continue
			for p in _samples(r):
				var a := _run_near(fi, p)
				var b := _run_near(other, p)
				if a >= 0 and b >= 0:
					_union(a, b)
	_join_sky()
	_run_region.resize(_parent.size())
	var ids := {}
	for i in _parent.size():
		var root := _find(i)
		if not ids.has(root):
			ids[root] = ids.size()
		_run_region[i] = ids[root]
	region_count = ids.size()
	_adjacent.resize(region_count)
	for i in region_count:
		_adjacent[i] = []
	for l in _pending:
		var a := _region_near(l[0], l[1])
		var b := _region_near(l[0], l[2])
		if a < 0 or b < 0 or a == b:
			continue
		(_adjacent[a] as Array).append(_links_a.size())
		(_adjacent[b] as Array).append(_links_a.size())
		_links_a.append(a)
		_links_b.append(b)
		_links_kind.append(l[3])
		_links_door.append(l[4])
	_pending.clear()
	_openings.clear()
	for f in _floors:
		f.erase("walls")


## Bereich eines Punkts (−1 = keiner: in der Wand). node: Licht im Baum – sein Stockwerk ist das seines
## Wurzelknotens (Unterwasserlampen liegen tiefer als ihr Boden, Halogenröhren im UG fast so hoch wie der nächste),
## ohne einen (lose Gegenstände, die Kamera) nach der Höhe.
func region_at(pos: Vector3, node: Node = null) -> int:
	if _run_region.is_empty():
		return -1
	return _region_near(_floor_at(pos, node), Vector2(pos.x, pos.z))


## Bereiche, die die Kamera bei pos erreichen kann (Index = Bereich, ≠ 0 = erreichbar): über Türen, die Licht
## durchlassen, beliebig weit, dazu ein Schritt durch Fenster, geschlossene Glastüren und Aufzugtüren. Leer, wenn die
## Kamera in keinem Bereich liegt – dann gilt alles als erreichbar.
func reach(pos: Vector3) -> PackedByteArray:
	var start := region_at(pos)
	if start < 0:
		return PackedByteArray()
	var seen := PackedByteArray()
	seen.resize(region_count)
	seen.fill(0)
	seen[start] = 1
	var list := PackedInt32Array([start])
	var k := 0
	while k < list.size():
		var r := list[k]
		k += 1
		for li: int in _adjacent[r]:
			if _links_kind[li] == Link.WINDOW or not _passes(li):
				continue
			var other := _links_b[li] if _links_a[li] == r else _links_a[li]
			if seen[other] == 0:
				seen[other] = 1
				list.append(other)
	for r in list:
		for li: int in _adjacent[r]:
			if _links_kind[li] == Link.DOOR or (_links_kind[li] == Link.GLASS and _passes(li)):
				continue
			var other := _links_b[li] if _links_a[li] == r else _links_a[li]
			if seen[other] == 0:
				seen[other] = 2
	return seen


func _passes(li: int) -> bool:
	var d := _links_door[li]
	return is_instance_valid(d) and d.lets_light()


## Freie Läufe je Rasterzeile zwischen den Wänden; Läufe, die einen der Zeile darüber überlappen, gehören zusammen.
func _build_runs(f: Dictionary) -> void:
	var size: Vector2i = f["size"]
	var walls: Array = f["walls"]
	var runs: Array = f["runs"]
	var prev := PackedInt32Array()
	for y in size.y:
		var iv: Array = walls[y]
		var pairs: Array[Vector2i] = []
		for i in range(0, iv.size(), 2):
			pairs.append(Vector2i(iv[i], iv[i + 1]))
		pairs.sort()
		var row := PackedInt32Array()
		var x := 0
		for pr in pairs:
			if pr.x > x:
				row.append_array([x, pr.x - 1, _parent.size()])
				_parent.append(_parent.size())
			x = maxi(x, pr.y + 1)
		if x < size.x:
			row.append_array([x, size.x - 1, _parent.size()])
			_parent.append(_parent.size())
		var i := 0
		var j := 0
		while i < row.size() and j < prev.size():
			if row[i + 1] < prev[j]:
				i += 3
			elif prev[j + 1] < row[i]:
				j += 3
			else:
				_union(row[i + 2], prev[j + 2])
				if row[i + 1] < prev[j + 1]:
					i += 3
				else:
					j += 3
		runs.append(row)
		prev = row


## Freier Himmel: Wo auf zwei Stockwerken übereinander beide Stellen draußen liegen (keine Fläche des Plans oder eine
## draußen), gehören die Bereiche zusammen – vom Hof sieht man die Fenster oben. Nicht ins Untergeschoss.
func _join_sky() -> void:
	var step := roundi(SKY_SAMPLE / CELL)
	for fi in _floors.size():
		var f: Dictionary = _floors[fi]
		var up := _floor_of_level(int(f["level"]) + 1)
		if int(f["level"]) < 0 or up < 0:
			continue
		var size: Vector2i = f["size"]
		var o: Vector2 = f["origin"]
		for cy in range(0, size.y, step):
			for cx in range(0, size.x, step):
				var p := o + (Vector2(cx, cy) + Vector2(0.5, 0.5)) * CELL
				if not _outdoor(fi, p) or not _outdoor(up, p):
					continue
				var a := _run_at(fi, _cell(fi, p))
				var b := _run_at(up, _cell(up, p))
				if a >= 0 and b >= 0:
					_union(a, b)


func _outdoor(fi: int, p: Vector2) -> bool:
	var f: Dictionary = _floors[fi]
	var place := _place(fi, p)
	return place == 0 or (f["outdoor"] as PackedByteArray)[place - 1] == 1


## Fläche des Plans an p (Index + 1, 0 = keine – auch außerhalb des Rasters).
func _place(fi: int, p: Vector2) -> int:
	var f: Dictionary = _floors[fi]
	var size: Vector2i = f["size"]
	var c := Vector2i(((p - (f["origin"] as Vector2)) / CELL).floor())
	if c.x < 0 or c.y < 0 or c.x >= size.x or c.y >= size.y:
		return 0
	return (f["places"] as PackedInt32Array)[c.y * size.x + c.x]


## Zelle zu p, aufs Raster beschränkt (außerhalb liegt der Rand, also draußen).
func _cell(fi: int, p: Vector2) -> Vector2i:
	var f: Dictionary = _floors[fi]
	var size: Vector2i = f["size"]
	var c := Vector2i(((p - (f["origin"] as Vector2)) / CELL).floor())
	return c.clamp(Vector2i.ZERO, size - Vector2i.ONE)


## Lauf der Zelle c (−1 = Wand).
func _run_at(fi: int, c: Vector2i) -> int:
	var row: PackedInt32Array = (_floors[fi]["runs"] as Array)[c.y]
	var lo := 0
	var hi := floori(row.size() / 3.0) - 1
	while lo <= hi:
		var mid := (lo + hi) >> 1
		if c.x < row[mid * 3]:
			hi = mid - 1
		elif c.x > row[mid * 3 + 1]:
			lo = mid + 1
		else:
			return row[mid * 3 + 2]
	return -1


## Lauf an p; liegt p in einer Wand, der der nächsten freien Zelle (bis SEARCH Zellen).
func _run_near(fi: int, p: Vector2) -> int:
	if fi < 0:
		return -1
	var c := _cell(fi, p)
	var run := _run_at(fi, c)
	if run >= 0:
		return run
	var f: Dictionary = _floors[fi]
	var size: Vector2i = f["size"]
	var local := (p - (f["origin"] as Vector2)) / CELL
	var best := INF
	for dy in range(-SEARCH, SEARCH + 1):
		for dx in range(-SEARCH, SEARCH + 1):
			var n := c + Vector2i(dx, dy)
			if n.x < 0 or n.y < 0 or n.x >= size.x or n.y >= size.y:
				continue
			var d := (Vector2(n) + Vector2(0.5, 0.5)).distance_squared_to(local)
			if d >= best:
				continue
			var r := _run_at(fi, n)
			if r >= 0:
				best = d
				run = r
	return run


func _region_near(fi: int, p: Vector2) -> int:
	var run := _run_near(fi, p)
	return _run_region[run] if run >= 0 else -1


func _floor_at(pos: Vector3, node: Node) -> int:
	var n := node
	while n != null:
		if _roots.has(n):
			return _roots[n]
		n = n.get_parent()
	var best := -1
	var lowest := -1
	for i in _floors.size():
		var y := float(_floors[i]["base_y"])
		if lowest < 0 or y < float(_floors[lowest]["base_y"]):
			lowest = i
		if y <= pos.y + ABOVE and (best < 0 or y > float(_floors[best]["base_y"])):
			best = i
	if best < 0:
		best = lowest
	if best < 0:
		return -1
	var p := Vector2(pos.x, pos.z)
	var above := _floor_of_level(int(_floors[best]["level"]) + 1)
	if above >= 0 and float(_floors[above]["base_y"]) <= pos.y + BELOW and _place(best, p) == 0 and _place(above, p) != 0:
		return above
	return best


func _floor_of_level(level: int) -> int:
	for i in _floors.size():
		if int(_floors[i]["level"]) == level:
			return i
	return -1


## Stichproben in r: alle SAMPLE Meter, mindestens die Mitte.
func _samples(r: Rect2) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var nx := maxi(1, floori(r.size.x / SAMPLE))
	var ny := maxi(1, floori(r.size.y / SAMPLE))
	for iy in ny:
		for ix in nx:
			points.append(r.position + r.size * Vector2((ix + 0.5) / nx, (iy + 0.5) / ny))
	return points


func _find(i: int) -> int:
	while _parent[i] != i:
		_parent[i] = _parent[_parent[i]]
		i = _parent[i]
	return i


func _union(a: int, b: int) -> void:
	a = _find(a)
	b = _find(b)
	if a != b:
		_parent[maxi(a, b)] = mini(a, b)
