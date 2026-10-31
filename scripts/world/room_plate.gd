class_name RoomPlate
extends RefCounted
## Messingplakette mit der Zimmernummer an den Gästezimmertüren (Spielkonzept 7.5, Entscheidung 31.10.): gebürstete
## Platte mit 45°-Fase und dünner Kordel am Rand, links und rechts eine Schlitzschraube, darauf erhabene, polierte
## Ziffern mit runden Kanten.
## Plastisch ist nur die Platte; Ziffern und Schrauben sind Textur (Farbe, Normal Map, Rauheit aus einer Höhenkarte,
## gebacken von tools/room_plate.gd). Ein Satz für alle Türen: Die Vorderseite ist ein Streifen aus Zellen –
## Schraube, Füller, je Ziffer eine Zelle, Füller, Schraube –, jede zeigt auf ihren Ausschnitt im Satz. Die Füller
## sind glatt gebürstet und werden in der Breite gestreckt (Bürstung waagerecht, das sieht man nicht). So ist es ein
## Material und ein Draw Call je Tür, und jede Nummer geht ohne neue Bilder. Die Kordel liegt im Rahmen um den
## Streifen: vier auf Gehrung geschnittene Trapeze aus einem Band im Satz ("K"), unverzerrt.
## Fehlt eine führende Ziffer am Schild (013 → „13“, 7.5), zeigt ihre Zelle den Abdruck („g“ + Ziffer): heller, wo
## sie das Messing geschützt hat, mit Kleberand und zwei Stiftlöchern.
##
## Maße in mm (Mesh in Metern), Satz in mm von links oben.

## = LevelBuilder.SIGN_FONT (hier ohne LevelBuilder, damit tools/room_plate.gd das Skript ohne Spiel laden kann)
const FONT := "res://assets/fonts/cinzel_bold.ttf"
const ALBEDO := "res://assets/textures/room_plate.png"
const NORMAL := "res://assets/textures/room_plate_normal.png"
const ROUGH := "res://assets/textures/room_plate_rough.png"
## Platte: Größe, Stärke, Fase (45°) an der Vorderkante, Breite des Rahmens mit der Kordel
const PLATE := Vector2(140.0, 74.0)
const THICK := 3.0
const CHAMFER := 1.2
const ROPE_W := 3.4
## Ziffern: höchstens so hoch (Tinte), Rand links und rechts je Ziffer; passen drei breite nicht zwischen die
## Schraubenzellen, werden alle kleiner
const DIGIT_H := 46.0
const SPACING := 2.0
## Zellen: Schraube (Breite, Schraubenmitte vom Außenrand), Füller im Satz
const END_W := 13.0
const SCREW_X := 7.0
const FILL_W := 12.0
## Satz: Pixel je mm, Kantenlänge (= Mat.PHOTO_SIZE), Rand um jede Zelle (gegen Übersprechen der Mipmaps)
const PX_MM := 4.0
const SIZE := 1024
const PAD := 4.0
## Ziffern, die es im Satz gibt (Abdrücke nur für die abgefallene Null)
const DIGITS := "0123456789"
const GHOSTS := "0"

static var _layout: Dictionary


## Zellen im Satz: Name → Rect2 (mm, ohne Rand) – "L"/"R" Schraube, "F" Füller, Ziffer, "g" + Ziffer Abdruck,
## "K" Kordelband (so lang wie die Platte oben, außen bei y = 0) –, "face" der Zellenstreifen, "rim" die Platte oben
## ohne Fase und "glyphs": Ziffer → Dreiecke der Tinte in mm, Ursprung links oben in der Zelle (y nach unten)
static func layout() -> Dictionary:
	if not _layout.is_empty():
		return _layout
	var rim := PLATE - Vector2.ONE * CHAMFER * 2.0
	var face := rim - Vector2.ONE * ROPE_W * 2.0
	# Größe aus der breitesten Ziffer und der höchsten Tinte bei Probegröße 1
	var probe := {}
	var widest := 0.0
	var top := INF
	var bottom := -INF
	for d in DIGITS:
		var tris := _glyph(d)
		probe[d] = tris
		var box := _bounds(tris)
		widest = maxf(widest, box.size.x)
		top = minf(top, box.position.y)
		bottom = maxf(bottom, box.end.y)
	var scale := minf(DIGIT_H / (bottom - top), (face.x - 2.0 * END_W - 6.0 * SPACING) / (3.0 * widest))
	var cells := {"L": END_W, "R": END_W, "F": FILL_W}
	var glyphs := {}
	var mid := (top + bottom) / 2.0 * scale
	for d in DIGITS:
		var tris: PackedVector2Array = probe[d]
		var box := _bounds(tris)
		var out := PackedVector2Array()
		for p in tris:   # Tinte SPACING vom linken Zellrand, Ziffernmitte auf halber Höhe
			out.append(Vector2((p.x - box.position.x) * scale + SPACING, p.y * scale - mid + face.y / 2.0))
		glyphs[d] = out
		cells[d] = box.size.x * scale + 2.0 * SPACING
	for d in GHOSTS:
		cells["g" + d] = cells[d]
	cells["K"] = rim.x
	# Reihen von links nach rechts füllen
	var rects := {}
	var row := SIZE / PX_MM
	var at := Vector2.ZERO
	var order := ["L", "R", "F"]
	for d in DIGITS:
		order.append(d)
	for d in GHOSTS:
		order.append("g" + d)
	order.append("K")
	for key: String in order:
		var w: float = cells[key] + 2.0 * PAD
		if at.x + w > row:
			at = Vector2(0.0, at.y + face.y + 2.0 * PAD)
		rects[key] = Rect2(at + Vector2.ONE * PAD, Vector2(cells[key], ROPE_W if key == "K" else face.y))
		at.x += w
	assert(at.y + face.y + 2.0 * PAD <= row, "RoomPlate: Satz passt nicht in %d px" % SIZE)
	_layout = {"cells": rects, "glyphs": glyphs, "face": face, "rim": rim}
	return _layout


## Platte zur Nummer no (dreistellig) mit der Aufschrift label (fehlen vorn Ziffern, zeigen sie den Abdruck):
## Rückseite bei z = 0, Vorderseite nach +Z, Mitte im Ursprung, oben = +Y. UVs in den Satz (1 = SIZE Pixel).
static func mesh(no: String, label: String) -> ArrayMesh:
	var lay := layout()
	var cells: Dictionary = lay["cells"]
	var face: Vector2 = lay["face"]
	var keys := []
	var lost := no.length() - label.length() if no.ends_with(label) else 0
	var text := no if lost > 0 else label
	for i in text.length():
		var key := ("g" + text[i]) if i < lost else text[i]
		if cells.has(key):
			keys.append(key)
	var used := 0.0
	for k: String in keys:
		used += (cells[k] as Rect2).size.x
	var fill := maxf(0.0, (face.x - 2.0 * END_W - used) / 2.0)
	var strip: Array = [["L", END_W], ["F", fill]]
	for k: String in keys:
		strip.append([k, (cells[k] as Rect2).size.x])
	strip.append_array([["F", fill], ["R", END_W]])
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var x := -face.x / 2.0
	for part: Array in strip:
		var w: float = part[1]
		if w <= 0.0:
			continue
		var r: Rect2 = cells[part[0]]
		_quad(verts, normals, uvs, indices,
			[Vector3(x, face.y / 2.0, THICK), Vector3(x + w, face.y / 2.0, THICK),
				Vector3(x + w, -face.y / 2.0, THICK), Vector3(x, -face.y / 2.0, THICK)],
			[r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
		x += w
	# Rahmen mit der Kordel (Trapeze im Uhrzeigersinn, außen v = 0), dann Fase und Kanten aus dem gebürsteten Feld
	# des Füllers, Riefen längs der Kante
	var rope: Rect2 = cells["K"]
	var f: Rect2 = cells["F"]
	var inner := _corners(face)
	var top := _corners(lay["rim"])
	var outer := _corners(PLATE)
	for k in 4:
		var a: Vector2 = inner[k]
		var b: Vector2 = inner[(k + 1) % 4]
		var ta: Vector2 = top[k]
		var tb: Vector2 = top[(k + 1) % 4]
		var length := ta.distance_to(tb)
		var o := rope.position
		_quad(verts, normals, uvs, indices, [Vector3(ta.x, ta.y, THICK), Vector3(tb.x, tb.y, THICK),
			Vector3(b.x, b.y, THICK), Vector3(a.x, a.y, THICK)],
			[o, o + Vector2(length, 0), o + Vector2(length - ROPE_W, ROPE_W), o + Vector2(ROPE_W, ROPE_W)])
		a = ta
		b = tb
		var oa: Vector2 = outer[k]
		var ob: Vector2 = outer[(k + 1) % 4]
		var band := Vector2(f.position.x, f.position.y + 2.0)
		var uv_band := [band, band + Vector2(f.size.x, 0), band + Vector2(f.size.x, 3.0), band + Vector2(0, 3.0)]
		_quad(verts, normals, uvs, indices, [Vector3(a.x, a.y, THICK), Vector3(b.x, b.y, THICK),
			Vector3(ob.x, ob.y, THICK - CHAMFER), Vector3(oa.x, oa.y, THICK - CHAMFER)], uv_band)
		_quad(verts, normals, uvs, indices, [Vector3(oa.x, oa.y, THICK - CHAMFER), Vector3(ob.x, ob.y, THICK - CHAMFER),
			Vector3(ob.x, ob.y, -0.5), Vector3(oa.x, oa.y, -0.5)], uv_band)
	for i in verts.size():
		verts[i] *= 0.001
		uvs[i] /= SIZE / PX_MM
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m


## Ecken eines Rechtecks der Größe size um den Ursprung im Uhrzeigersinn von links oben
static func _corners(size: Vector2) -> Array:
	return [Vector2(-size.x, size.y) / 2.0, size / 2.0, Vector2(size.x, -size.y) / 2.0, -size / 2.0]


## Viereck p (rundum, uv je Ecke in mm) mit flacher Normale, Vorderseite von der Plattenmitte weg
static func _quad(verts: PackedVector3Array, normals: PackedVector3Array, uvs: PackedVector2Array,
		indices: PackedInt32Array, p: Array, uv: Array) -> void:
	var n: Vector3 = (p[2] - p[0]).cross(p[1] - p[0]).normalized()
	var center: Vector3 = (p[0] + p[2]) / 2.0
	var first := verts.size()
	for i in 4:
		verts.append(p[i])
		normals.append(n if n.dot(center) >= 0.0 else -n)
		uvs.append(uv[i])
	if n.dot(center) >= 0.0:   # Normale zeigt von der Plattenmitte weg: Reihenfolge stimmt
		indices.append_array([first, first + 1, first + 2, first, first + 2, first + 3])
	else:
		indices.append_array([first, first + 2, first + 1, first, first + 3, first + 2])


## Vorderseite der Ziffer d als Dreiecke (Probegröße, y nach unten)
static func _glyph(d: String) -> PackedVector2Array:
	var tm := TextMesh.new()
	tm.text = d
	tm.font = load(FONT)
	tm.font_size = 64
	tm.pixel_size = 1.0 / 64.0
	tm.curve_step = 0.5
	tm.depth = 0.05
	var arrays := tm.get_mesh_arrays()
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
	if idx.is_empty():
		idx = PackedInt32Array(range(v.size()))
	var out := PackedVector2Array()
	for t in roundi(idx.size() / 3.0):
		if n[idx[t * 3]].z < 0.5:   # nur die Vorderseite
			continue
		for k in 3:
			var p := v[idx[t * 3 + k]]
			out.append(Vector2(p.x, -p.y))
	return out


static func _bounds(tris: PackedVector2Array) -> Rect2:
	var box := Rect2(tris[0], Vector2.ZERO)
	for p in tris:
		box = box.expand(p)
	return box
