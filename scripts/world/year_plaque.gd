class_name YearPlaque
extends RefCounted
## Goldene Plakette mit der Jahreszahl auf der unteren Leiste der Fotorahmen (ZIM-134, Spielkonzept 5.14): dünnes,
## poliertes Blech mit Fase, die Ziffern eingraviert und dunkel ausgelegt.
## Wie RoomPlate: Plastisch ist nur das Blech, die Gravur ist Textur (Farbe, Normal Map, Rauheit aus einer Höhenkarte,
## gebacken von tools/year_plaque.gd). Die Vorderseite ist ein Streifen aus Zellen – Füller, je Ziffer eine Zelle,
## Füller –, jede zeigt auf ihren Ausschnitt im Satz; die Füller werden in der Breite gestreckt. So geht jedes Jahr
## ohne neue Bilder, alle Plaketten teilen ein Material.
##
## Maße in mm (Mesh in Metern), Satz in mm von links oben.

const ALBEDO := "res://assets/textures/year_plaque.png"
const NORMAL := "res://assets/textures/year_plaque_normal.png"
const ROUGH := "res://assets/textures/year_plaque_rough.png"
## Blech: Größe, Stärke, Fase (45°) an der Vorderkante
const PLATE := Vector2(40.0, 12.0)
const THICK := 0.8
const CHAMFER := 0.35
## Ziffern: Höhe der Tinte, Rand links und rechts je Ziffer
const DIGIT_H := 6.5
const SPACING := 0.45
## Füller im Satz (wird gestreckt)
const FILL_W := 8.0
## Satz: Pixel je mm, Kantenlänge, Rand um jede Zelle (gegen Übersprechen der Mipmaps)
const PX_MM := 16.0
const SIZE := 1024
const PAD := 2.0
const DIGITS := "0123456789"
## Glanz des Golds (wie PLATE_METALLIC an den Türen)
const METALLIC := 0.6

static var _layout: Dictionary


## Zellen im Satz: Name → Rect2 (mm, ohne Rand) – "F" Füller, Ziffer –, "face" die Vorderseite ohne Fase und
## "glyphs": Ziffer → Dreiecke der Tinte in mm, Ursprung links oben in der Zelle (y nach unten)
static func layout() -> Dictionary:
	if not _layout.is_empty():
		return _layout
	var face := PLATE - Vector2.ONE * CHAMFER * 2.0
	var probe := {}
	var top := INF
	var bottom := -INF
	for d in DIGITS:
		var tris := RoomPlate._glyph(d)
		probe[d] = tris
		var box := RoomPlate._bounds(tris)
		top = minf(top, box.position.y)
		bottom = maxf(bottom, box.end.y)
	var scale := DIGIT_H / (bottom - top)
	var mid := (top + bottom) / 2.0 * scale
	var cells := {"F": FILL_W}
	var glyphs := {}
	for d in DIGITS:
		var tris: PackedVector2Array = probe[d]
		var box := RoomPlate._bounds(tris)
		var out := PackedVector2Array()
		for p in tris:   # Tinte SPACING vom linken Zellrand, Ziffernmitte auf halber Höhe
			out.append(Vector2((p.x - box.position.x) * scale + SPACING, p.y * scale - mid + face.y / 2.0))
		glyphs[d] = out
		cells[d] = box.size.x * scale + 2.0 * SPACING
	var rects := {}
	var row := SIZE / PX_MM
	var at := Vector2.ZERO
	var order := ["F"]
	for d in DIGITS:
		order.append(d)
	for key: String in order:
		var w: float = cells[key] + 2.0 * PAD
		if at.x + w > row:
			at = Vector2(0.0, at.y + face.y + 2.0 * PAD)
		rects[key] = Rect2(at + Vector2.ONE * PAD, Vector2(cells[key], face.y))
		at.x += w
	assert(at.y + face.y + 2.0 * PAD <= row, "YearPlaque: Satz passt nicht in %d px" % SIZE)
	_layout = {"cells": rects, "glyphs": glyphs, "face": face}
	return _layout


## Plakette mit der Aufschrift text (Ziffern): Rückseite bei z = 0, Vorderseite nach +Z, Mitte im Ursprung, oben = +Y.
## UVs in den Satz (1 = SIZE Pixel).
static func mesh(text: String) -> ArrayMesh:
	var lay := layout()
	var cells: Dictionary = lay["cells"]
	var face: Vector2 = lay["face"]
	var keys := []
	var used := 0.0
	for c in text:
		if cells.has(c):
			keys.append(c)
			used += (cells[c] as Rect2).size.x
	var fill := maxf(0.0, (face.x - used) / 2.0)
	var strip: Array = [["F", fill]]
	for k: String in keys:
		strip.append([k, (cells[k] as Rect2).size.x])
	strip.append(["F", fill])
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
		RoomPlate._quad(verts, normals, uvs, indices,
			[Vector3(x, face.y / 2.0, THICK), Vector3(x + w, face.y / 2.0, THICK),
				Vector3(x + w, -face.y / 2.0, THICK), Vector3(x, -face.y / 2.0, THICK)],
			[r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
		x += w
	# Fase und Kanten aus einem Band des Füllers, Politur längs der Kante
	var f: Rect2 = cells["F"]
	var band := Vector2(f.position.x, f.position.y + 1.0)
	var uv_band := [band, band + Vector2(f.size.x, 0), band + Vector2(f.size.x, 1.0), band + Vector2(0, 1.0)]
	var top := RoomPlate._corners(face)
	var outer := RoomPlate._corners(PLATE)
	for k in 4:
		var a: Vector2 = top[k]
		var b: Vector2 = top[(k + 1) % 4]
		var oa: Vector2 = outer[k]
		var ob: Vector2 = outer[(k + 1) % 4]
		RoomPlate._quad(verts, normals, uvs, indices, [Vector3(a.x, a.y, THICK), Vector3(b.x, b.y, THICK),
			Vector3(ob.x, ob.y, THICK - CHAMFER), Vector3(oa.x, oa.y, THICK - CHAMFER)], uv_band)
		RoomPlate._quad(verts, normals, uvs, indices, [Vector3(oa.x, oa.y, THICK - CHAMFER),
			Vector3(ob.x, ob.y, THICK - CHAMFER), Vector3(ob.x, ob.y, -0.3), Vector3(oa.x, oa.y, -0.3)], uv_band)
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

