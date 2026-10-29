class_name Bathtub
extends StaticBody3D
## Eingeflieste Badewanne (Spielkonzept 7.10, Skizzen 23.10.): gefliester Block in Plangröße – Schürze und Rand um
## die Wanne –, darauf die Keramikwanne TUB_LENGTH lang, ihr Rand RAISE hoch aufgesetzt und außen abgerundet; innen
## Rückenschräge am Kopfende (−X), Abfluss und Überlauf am Fußende. Messingarmatur aus Zylindern an der Wand dahinter:
## zwei Anschlüsse mit Rosetten, Rohr mit Drehgriffen an den Enden, schräger Auslauf über die Wanne.
## Das Becken ist hohl (man kann hineinsteigen). Lokale +Z = Vorderseite (zum Raum), −Z = Wand; Ursprung am Boden
## in der Mitte. size vor dem Einhängen setzen.

## Länge der Wanne (Entscheidung 23.10.); der Block nimmt die Nische ein (Plan: 2,8 m) und ist 60 cm hoch
## (LevelBuilder.BOX_HEIGHTS): Wanne 50 cm tief auf 10 cm Sockel
const TUB_LENGTH := 2.2
## Fliesenrand an den Längsseiten (bis zum Wannenrand), Keramikrand der Wanne und wie weit er auf den Fliesen aufsitzt
const RIM := 0.1
const LIP := 0.05
const RAISE := 0.01
## Fliesenausschnitt größer als die Öffnung (höchstens so, dass die runden Außenecken des Rands ihn noch decken)
const CUT := 0.015
## Beckenboden (= Sockel); Radius der Ecken: Öffnung, Außenkante des Rands, am Boden
const FLOOR_Y := 0.1
const CORNER_TOP := 0.07
const CORNER_OUTER := 0.06
const CORNER_BOTTOM := 0.085
## Ausrundung zwischen Wand und Boden: beginnt so hoch über dem Boden an der Wand und endet so weit innen auf dem
## Boden; Zwischenringe
const FILLET_UP := 0.07
const FILLET_IN := 0.07
const FILLET_STEPS := 4
const CORNER_SEGMENTS := 5
## Wie weit die Wände bis zum Boden einrücken: Kopfende (Rückenschräge), Fußende, Seiten
const HEAD_SLOPE := 0.4
const FOOT_SLOPE := 0.08
const SIDE_SLOPE := 0.06
## Senkrechtes Stück unter dem Keramikrand, bevor die Wand schräg wird
const LIP_DROP := 0.03
## Armatur: Höhe der Rohrachse über den Fliesen (10 cm, bleibt unter der Schürze der Fensterbank, LevelBuilder.WINDOW_SILL),
## Abstand der Wandanschlüsse von der Mitte, Rohrachse vor der Wand, Radien von Rohr und Drehgriffen, Länge eines
## Drehgriffs mit Rille; Auslauf: Länge nach vorn, Gefälle, Radius; Kanten rings um jeden Zylinder
const MIXER_RISE := 0.1
const MIXER_SPREAD := 0.075
const MIXER_OUT := 0.065
const PIPE_R := 0.03
const KNOB_R := 0.034
const KNOB_LENGTH := 0.05
const GROOVE := 0.006
const SPOUT_LENGTH := 0.18
const SPOUT_DROP := 0.03
const SPOUT_R := 0.02
const MIXER_SIDES := 24
const CERAMIC := Color(0.88, 0.88, 0.86)

## Block: Länge (x), Höhe = Oberkante der Fliesen (y), Tiefe (z)
var size := Vector3(2.8, 0.6, 0.9)
## Fliesen des Bads (LevelBuilder._bath_tiles, in Weltkoordinaten – die Fugen laufen von Boden und Wand durch)
var tiles: Material

## Fertige Meshes (Fliesen, Keramik, Messing) je Blockgröße – gleich große Wannen teilen sie (Mesh-Cache, Geo)
static var _meshes := {}


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var length := minf(TUB_LENGTH, size.x - 0.2)
	var h := size.y
	var hx := length / 2.0
	var hz := size.z / 2.0 - RIM
	# Öffnung der Wanne; der Ausschnitt in den Fliesen ist CUT größer (sonst flimmern seine Kanten in der Beckenwand),
	# seine Ecken deckt der Keramikrand noch
	var ox := hx - LIP
	var oz := hz - LIP
	var cx := ox + CUT
	var cz := oz + CUT
	var tiled := GrandStair.Shape.new()
	var ceramic := GrandStair.Shape.new()
	var brass := GrandStair.Shape.new()
	# Gefliester Block um den Ausschnitt; dieselben Quader sind die Kollision
	var side := size.z / 2.0 - cz
	var end := size.x / 2.0 - cx
	var parts := [
		[Vector3(size.x, h, side), Vector3(0, h / 2.0, size.z / 2.0 - side / 2.0)],
		[Vector3(size.x, h, side), Vector3(0, h / 2.0, -size.z / 2.0 + side / 2.0)],
		[Vector3(end, h, cz * 2.0), Vector3(-size.x / 2.0 + end / 2.0, h / 2.0, 0)],
		[Vector3(end, h, cz * 2.0), Vector3(size.x / 2.0 - end / 2.0, h / 2.0, 0)],
	]
	for p in parts:
		tiled.box(p[1], p[0])
		Geo.add_box_shape(self, p[0], p[1])
	Geo.add_box_shape(self, Vector3(cx * 2.0, FLOOR_Y, cz * 2.0), Vector3(0, FLOOR_Y / 2.0, 0))
	# Keramik: aufgesetzter Rand (Außenkante, Oberseite), Wände in drei Ringen, Boden
	var rim_top := h + RAISE
	var outer_low := _loop(-hx, hx, hz, CORNER_OUTER, h)
	var outer := _loop(-hx, hx, hz, CORNER_OUTER, rim_top)
	var top := _loop(-ox, ox, oz, CORNER_TOP, rim_top)
	var drop_y := rim_top - LIP_DROP
	var drop := _loop(-ox, ox, oz, CORNER_TOP, drop_y)
	# Wand von drop bis zum Boden, unten über eine Bézierkurve (Wand → Knick → Boden) ausgerundet; die Ringe sind
	# (x0, x1, hz, Eckradius) und eine Höhe
	var wall_top := Vector4(-ox, ox, oz, CORNER_TOP)
	var knee := Vector4(-ox + HEAD_SLOPE, ox - FOOT_SLOPE, oz - SIDE_SLOPE, CORNER_BOTTOM)
	var start := wall_top.lerp(knee, 1.0 - FILLET_UP / (drop_y - FLOOR_Y))
	var floor_edge := knee + Vector4(FILLET_IN, -FILLET_IN, -FILLET_IN, -FILLET_IN * 0.8)
	var rings: Array[PackedVector3Array] = [top, drop]
	for step in FILLET_STEPS + 1:
		var t := float(step) / FILLET_STEPS
		var q := start * (1.0 - t) * (1.0 - t) + knee * 2.0 * t * (1.0 - t) + floor_edge * t * t
		var y := (FLOOR_Y + FILLET_UP) * (1.0 - t) * (1.0 - t) + FLOOR_Y * (2.0 * t * (1.0 - t) + t * t)
		rings.append(_loop(q.x, q.y, q.z, q.w, y))
	var bottom := rings[-1]
	var n := top.size()
	for i in n:
		var j := (i + 1) % n
		ceramic.quad(outer[i], outer[j], top[j], top[i], Vector3.UP)
		var ni := _outward(outer, i)
		var nj := _outward(outer, j)
		ceramic.tri(outer_low[i], outer_low[j], outer[j], ni, nj, nj)
		ceramic.tri(outer_low[i], outer[j], outer[i], ni, nj, ni)
	var last := rings.size() - 1
	var normals: Array[PackedVector3Array] = []
	for k in rings.size():
		var ns := PackedVector3Array()
		for i in n:
			var along := rings[k][(i + 1) % n] - rings[k][(i - 1 + n) % n]
			var down := rings[mini(k + 1, last)][i] - rings[maxi(k - 1, 0)][i]
			var normal := along.cross(down).normalized()
			if normal.y < -0.01 or (absf(normal.y) <= 0.01 and normal.dot(Vector3(-rings[k][i].x, 0, -rings[k][i].z)) < 0.0):
				normal = -normal   # nach innen bzw. oben
			ns.append(normal)
		normals.append(ns)
	for k in last:
		for i in n:
			var j := (i + 1) % n
			var a := rings[k]
			var b := rings[k + 1]
			ceramic.tri(a[i], a[j], b[j], normals[k][i], normals[k][j], normals[k + 1][j])
			ceramic.tri(a[i], b[j], b[i], normals[k][i], normals[k + 1][j], normals[k + 1][i])
	var mid := Vector3((bottom[0].x + bottom[n / 2].x) / 2.0, FLOOR_Y, 0)
	for i in n:
		ceramic.tri(mid, bottom[i], bottom[(i + 1) % n], Vector3.UP, Vector3.UP, Vector3.UP)
	# Abfluss am Fußende, Überlauf in der Fußwand
	brass.lathe([Vector2(0.035, FLOOR_Y), Vector2(0.035, FLOOR_Y + 0.004)], Vector3(bottom[0].x - 0.07, 0, 0), MIXER_SIDES)
	var over_y := h - 0.13
	var wall_x := lerpf(drop[0].x, knee.y, (drop_y - over_y) / (drop_y - FLOOR_Y))
	_tube(brass, Vector3(wall_x - 0.008, over_y, 0), Vector3(wall_x + 0.03, over_y, 0), 0.035)
	_mixer(brass, h + MIXER_RISE, -size.z / 2.0)
	var key := "%.4f,%.4f,%.4f" % [size.x, size.y, size.z]
	if not _meshes.has(key):
		_meshes[key] = [tiled.commit(), ceramic.commit(), brass.commit()]
	var m: Array = _meshes[key]
	Geo.mesh(self, m[0], tiles if tiles else Mat.psx(Color(0.82, 0.88, 0.9), "tiles", 4.0), Vector3.ZERO)
	Geo.mesh(self, m[1], Mat.psx(CERAMIC), Vector3.ZERO)
	Geo.mesh(self, m[2], Mat.metal(GrandStair.BRASS), Vector3.ZERO)


## Wandarmatur (Skizze 23.10.), Wand bei z = wall, Rohrachse in Höhe y: zwei Anschlüsse mit Rosetten, waagerechtes
## Rohr, an beiden Enden ein Drehgriff mit Rille, aus der Mitte schräg nach vorn der Auslauf, das Mundstück unten
## ganz im Auslauf (es schaut vorn nicht heraus).
func _mixer(sh: GrandStair.Shape, y: float, wall: float) -> void:
	var z := wall + MIXER_OUT
	var half := MIXER_SPREAD + 0.03
	_tube(sh, Vector3(-half, y, z), Vector3(half, y, z), PIPE_R)
	for side in [-1.0, 1.0]:
		var x: float = side * MIXER_SPREAD
		_tube(sh, Vector3(x, y, wall), Vector3(x, y, wall + 0.01), 0.036)
		_tube(sh, Vector3(x, y, wall + 0.01), Vector3(x, y, z), 0.016)
		var a: float = side * half
		var g: float = side * (half + (KNOB_LENGTH - GROOVE) / 2.0)
		var b: float = g + side * GROOVE
		_tube(sh, Vector3(a, y, z), Vector3(g, y, z), KNOB_R)
		_tube(sh, Vector3(g, y, z), Vector3(b, y, z), KNOB_R - 0.005)
		_tube(sh, Vector3(b, y, z), Vector3(side * (half + KNOB_LENGTH), y, z), KNOB_R)
	var root := Vector3(0, y, z)
	var tip := Vector3(0, y - SPOUT_DROP, z + SPOUT_LENGTH)
	_tube(sh, root, tip, SPOUT_R)
	var outlet := tip - (tip - root).normalized() * (SPOUT_R + 0.004)
	sh.lathe([Vector2(0.016, outlet.y - SPOUT_R - 0.01), Vector2(0.016, outlet.y)], Vector3(0, 0, outlet.z), MIXER_SIDES)


## Glatter Zylinder von a nach b (MIXER_SIDES Kanten, ringsum weich schattiert), Enden geschlossen.
static func _tube(sh: GrandStair.Shape, a: Vector3, b: Vector3, r: float) -> void:
	var dir := (b - a).normalized()
	var side := dir.cross(Vector3.UP if absf(dir.y) < 0.9 else Vector3.RIGHT).normalized()
	var lift := side.cross(dir)
	var radial: Array[Vector3] = []
	for k in MIXER_SIDES + 1:
		var phi := TAU * k / MIXER_SIDES
		radial.append(side * cos(phi) + lift * sin(phi))
	for k in MIXER_SIDES:
		var n0 := radial[k]
		var n1 := radial[k + 1]
		sh.tri(a + n0 * r, a + n1 * r, b + n1 * r, n0, n1, n1)
		sh.tri(a + n0 * r, b + n1 * r, b + n0 * r, n0, n1, n0)
		sh.tri(a, a + n0 * r, a + n1 * r, -dir, -dir, -dir)
		sh.tri(b, b + n0 * r, b + n1 * r, dir, dir, dir)


## Abgerundetes Rechteck in der Höhe y (x von x0 bis x1, z von −hz bis hz, Eckradius r), immer gleich viele Punkte,
## so lassen sich zwei Ringe Punkt für Punkt verbinden.
static func _loop(x0: float, x1: float, hz: float, r: float, y: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	var centers := [Vector2(x1 - r, hz - r), Vector2(x0 + r, hz - r), Vector2(x0 + r, -hz + r), Vector2(x1 - r, -hz + r)]
	for c in 4:
		var center: Vector2 = centers[c]
		for s in CORNER_SEGMENTS + 1:
			var phi := PI / 2.0 * (c + float(s) / CORNER_SEGMENTS)
			out.append(Vector3(center.x + cos(phi) * r, y, center.y + sin(phi) * r))
	return out


## Waagerechte Normale eines Rings an Punkt i, nach außen.
static func _outward(ring: PackedVector3Array, i: int) -> Vector3:
	var n := ring.size()
	var normal := (ring[(i + 1) % n] - ring[(i - 1 + n) % n]).cross(Vector3.UP).normalized()
	return normal if normal.dot(Vector3(ring[i].x, 0, ring[i].z)) > 0.0 else -normal

