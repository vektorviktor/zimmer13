class_name OpeningFrame
extends MeshInstance3D
## Rahmen um eine Wandöffnung im Craftsman-Stil (Spielkonzept 7.2): Zarge in der Laibung, auf
## beiden Wandseiten Seitenbekleidung und Kopfpartie (Leiste, Friesbrett, Abdeckung mit Kehle).
## Fenster bekommen statt der Bekleidung bis zum Boden eine Fensterbank mit Schürze und einen
## Rahmen um die Scheibe. Die Teile stammen aus `assets/models/frames.glb` (`tools/build_frames.py`),
## werden nur in der Länge gestreckt und pro Öffnung zu einem einzigen Mesh zusammengefügt.
## Reine Optik: keine Kollision, nicht im Spielstand.
##
## Lokale Lage: Öffnung in der XY-Ebene von (x0, y0) bis (x0 + width, y0 + height),
## Wandmitte bei z = 0, Wandstärke depth.

const MODEL := "res://assets/models/frames.glb"
## Holzfarbe aller Rahmen
const COLOR := Color(0.42, 0.25, 0.13)
## Zarge: so weit ragt sie in die Öffnung und in die Wand (verdeckt die Schnittkante der Tapete)
const JAMB := 0.008
const JAMB_IN := 0.01
## Schattenfuge: die Bekleidung sitzt so weit hinter der Innenkante der Zarge
const REVEAL := 0.004
## Überlappung: so weit stecken Teile im Nachbarteil (Zarge in der Bekleidung, Bekleidung in der Leiste …).
## Beim Vertex-Snapping rastet jedes Teil für sich ein – Teile, die nur aneinanderstoßen, öffnen Fugen.
const TUCK := 0.012
## Seitlicher Überstand über die Außenkante der Bekleidung
const FILLET_OVERHANG := 0.012
const CAP_OVERHANG := 0.035
const STOOL_OVERHANG := 0.03
## Fensterrahmen um die Scheibe: Breite in der Ansicht, Tiefe
const SASH_W := 0.045
const SASH_D := 0.05
## Rahmen werden um diesen Anteil der Kameraentfernung nach vorn gezogen (Mat.layer), damit die Wand
## beim Vertex-Snapping nicht durch die Bekleidung sticht
const PULL := 0.005
## Längste Teilstrecke eines Teils – lange Flächen schwimmen beim Vertex-Snapping (siehe Geo.MAX_FACE)
const MAX_SEGMENT := 1.0

static var _parts := {}      # Name → Mesh-Arrays des Teils
static var _sizes := {}      # Name → Ausmaße (y = Profilbreite, z = Stärke)
static var _cache := {}      # gleiche Öffnungen teilen sich ein Mesh
static var _material: ShaderMaterial

var x0 := 0.0
var y0 := 0.0
var width := 1.2
var height := 2.1
var depth := 0.2
var window := false

var _verts := PackedVector3Array()
var _normals := PackedVector3Array()
var _indices := PackedInt32Array()


func setup(p_x0: float, p_y0: float, p_width: float, p_height: float, p_depth: float, p_window: bool = false) -> OpeningFrame:
	x0 = p_x0
	y0 = p_y0
	width = p_width
	height = p_height
	depth = p_depth
	window = p_window
	return self


func _ready() -> void:
	_load_kit()
	material_override = trim_material()
	var key := "%.3f|%.3f|%.3f|%.3f|%.3f|%s" % [x0, y0, width, height, depth, window]
	if not _cache.has(key):
		_build()
		_cache[key] = Geo.add_surface(ArrayMesh.new(), _verts, _normals, _indices)
		# Die Bauliste liegt jetzt im Mesh – nicht für die ganze Lebenszeit des Rahmens im Speicher halten
		_verts = PackedVector3Array()
		_normals = PackedVector3Array()
		_indices = PackedInt32Array()
	mesh = _cache[key]


func _build() -> void:
	var l := x0
	var r := x0 + width
	var b := y0
	var t := y0 + height
	# Zarge: deckt die Laibung ab (oben, seitlich, bei Fenstern auch unten) und reicht bis in die Bekleidung
	var back := -depth / 2.0 - TUCK
	var jamb_d := depth + 2.0 * TUCK
	var jamb := JAMB + JAMB_IN
	var side_from := b + JAMB if window else b
	_put("board", Vector3(l - JAMB_IN, side_from, back), Vector3.UP, Vector3.BACK, Vector3.RIGHT, t - side_from, jamb_d, jamb)
	_put("board", Vector3(r + JAMB_IN, side_from, back), Vector3.UP, Vector3.BACK, Vector3.LEFT, t - side_from, jamb_d, jamb)
	_put("board", Vector3(l - JAMB_IN, t + JAMB_IN, back), Vector3.RIGHT, Vector3.BACK, Vector3.DOWN, width + 2.0 * JAMB_IN, jamb_d, jamb)
	if window:
		_put("board", Vector3(l - JAMB_IN, b - JAMB_IN, back), Vector3.RIGHT, Vector3.BACK, Vector3.UP, width + 2.0 * JAMB_IN, jamb_d, jamb)
		_sash(l, r, b, t)
	# Bekleidung auf beiden Wandseiten
	var casing_w: float = _sizes["casing"].y
	var inner_l := l + JAMB - REVEAL
	var inner_r := r - JAMB + REVEAL
	var outer_l := inner_l - casing_w
	var span := inner_r - inner_l + 2.0 * casing_w
	var head := t - JAMB + REVEAL
	var stool_h: float = _sizes["stool"].y
	var frieze_h: float = _sizes["frieze"].y
	# Fensterbank 2 mm über der unteren Zarge – gleich hohe Oberseiten flimmern gegeneinander
	var stool_top := b + JAMB + 0.002
	for s in [-1.0, 1.0]:
		var face := Vector3(0, 0, s * depth / 2.0)
		var out := Vector3(0, 0, s)
		var foot := stool_top - TUCK if window else b
		_put("casing", face + Vector3(inner_l, foot, 0), Vector3.UP, Vector3.LEFT, out, head + TUCK - foot)
		_put("casing", face + Vector3(inner_r, foot, 0), Vector3.UP, Vector3.RIGHT, out, head + TUCK - foot)
		var y := head
		_put("fillet", face + Vector3(outer_l - FILLET_OVERHANG, y, 0), Vector3.RIGHT, Vector3.UP, out, span + 2.0 * FILLET_OVERHANG)
		y += _sizes["fillet"].y
		# Friesbrett steckt unten in der Leiste und oben in der Abdeckung
		_put("frieze", face + Vector3(outer_l, y - TUCK, 0), Vector3.RIGHT, Vector3.UP, out, span, (frieze_h + 2.0 * TUCK) / frieze_h)
		y += frieze_h
		_put("cap", face + Vector3(outer_l - CAP_OVERHANG, y, 0), Vector3.RIGHT, Vector3.UP, out, span + 2.0 * CAP_OVERHANG)
		if window:
			# Fensterbank, darunter die Schürze (steckt oben in der Bank)
			var sill := stool_top - stool_h
			_put("stool", face + Vector3(outer_l - STOOL_OVERHANG, sill, 0), Vector3.RIGHT, Vector3.UP, out, span + 2.0 * STOOL_OVERHANG)
			_put("casing", face + Vector3(outer_l, sill + TUCK, 0), Vector3.RIGHT, Vector3.DOWN, out, span)


## Fensterrahmen in der Scheibenebene, innen an der Zarge.
func _sash(l: float, r: float, b: float, t: float) -> void:
	# steckt 6 mm in der Zarge, die Querstücke stecken in den senkrechten
	var z := -SASH_D / 2.0
	var tuck := 0.006
	var lo := b + JAMB - tuck
	var hi := t - JAMB + tuck
	var w := SASH_W + tuck
	_put("board", Vector3(l + JAMB - tuck, lo, z), Vector3.UP, Vector3.BACK, Vector3.RIGHT, hi - lo, SASH_D, w)
	_put("board", Vector3(r - JAMB + tuck, lo, z), Vector3.UP, Vector3.BACK, Vector3.LEFT, hi - lo, SASH_D, w)
	var from := l + JAMB + SASH_W - TUCK
	var inner := r - l - 2.0 * (JAMB + SASH_W - TUCK)
	_put("board", Vector3(from, hi, z), Vector3.RIGHT, Vector3.BACK, Vector3.DOWN, inner, SASH_D, w)
	_put("board", Vector3(from, lo, z), Vector3.RIGHT, Vector3.BACK, Vector3.UP, inner, SASH_D, w)


## Hängt ein Teil an: Länge entlang along, Profilbreite entlang across (× su), Stärke entlang out (× sv).
## Lange Teile werden in Stücke von höchstens MAX_SEGMENT geteilt.
func _put(part: String, origin: Vector3, along: Vector3, across: Vector3, out: Vector3, length: float, su: float = 1.0, sv: float = 1.0) -> void:
	if length <= 0.0:
		return
	var src: Array = _parts[part]
	var verts: PackedVector3Array = src[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = src[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = src[Mesh.ARRAY_INDEX]
	var n := maxi(1, ceili(length / MAX_SEGMENT - 0.001))
	var seg := length / n
	var basis := Basis(along * seg, across * su, out * sv)
	var normal_basis := basis.inverse().transposed()
	var mirrored := basis.determinant() < 0.0   # gespiegelt → Dreiecke umdrehen, sonst zeigen sie nach innen
	for k in n:
		var offset := origin + along * seg * k
		var base := _verts.size()
		for i in verts.size():
			_verts.append(offset + basis * verts[i])
			_normals.append((normal_basis * normals[i]).normalized())
		for i in range(0, indices.size(), 3):
			_indices.append(base + indices[i])
			if mirrored:
				_indices.append(base + indices[i + 2])
				_indices.append(base + indices[i + 1])
			else:
				_indices.append(base + indices[i + 1])
				_indices.append(base + indices[i + 2])


static func _load_kit() -> void:
	if not _parts.is_empty():
		return
	var scene: Node = (load(MODEL) as PackedScene).instantiate()
	for mi: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
		var arrays := mi.mesh.surface_get_arrays(0)
		if arrays[Mesh.ARRAY_INDEX] == null:
			var seq := PackedInt32Array()
			for i in (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size():
				seq.append(i)
			arrays[Mesh.ARRAY_INDEX] = seq
		_parts[String(mi.name)] = arrays
		_sizes[String(mi.name)] = mi.mesh.get_aabb().size
	scene.free()


## Material aller Rahmen – auch für die Laibungen der Wände (LevelBuilder._wall).
static func trim_material() -> ShaderMaterial:
	if _material == null:
		_material = Mat.layer(COLOR, "", 1.0, PULL)
	return _material
