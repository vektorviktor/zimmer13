class_name DoorCasing
extends MeshInstance3D
## Rahmen der Holztüren mit dem Zimmertür-Modell (Door.Look.HOTEL) nach der Vorlage des Nutzers (29.10.): Zarge in
## der Laibung mit Anschlag auf der Seite gegenüber der Aufgehseite (−Z), auf beiden Wandseiten eine gestufte
## Bekleidung, oben auf Gehrung. Statt OpeningFrame (Craftsman-Rahmen der übrigen Öffnungen). Im Code aus einem Profil
## gebaut, damit er auf jede Türgröße passt; Holz wie Türblatt und Vertäfelung (Mat.hotel_wood, Faser entlang der
## Teile). Wo vor der Wand eine Haut liegt (Fliesen, Beton …), sitzt die Bekleidung davor (lift).
## Reine Optik: keine Kollision, nicht im Spielstand.
##
## Lokale Lage wie Door: Öffnung von x = 0 bis width, Boden y = 0, Wandmitte z = 0, Wandstärke depth.

## Bekleidung: Profil als (Abstand von der Innenkante nach außen, Höhe über der Wand) – schmaler Absatz an der
## Laibung, flaches Brett, zwei Stufen, Nut, erhabener Außenrand mit Fase (Vorlage)
const PROFILE: Array[Vector2] = [Vector2(0.0, -0.002), Vector2(0.0, 0.016), Vector2(0.004, 0.02), Vector2(0.03, 0.02),
	Vector2(0.03, 0.024), Vector2(0.05, 0.024), Vector2(0.05, 0.028), Vector2(0.066, 0.028), Vector2(0.068, 0.025),
	Vector2(0.072, 0.025), Vector2(0.074, 0.031), Vector2(0.09, 0.031), Vector2(0.095, 0.026), Vector2(0.1, 0.02),
	Vector2(0.1, -0.002)]
## Zarge: so weit ragt sie in die Öffnung (das Blatt hat 1 cm Luft); die Bekleidung sitzt so weit dahinter
const JAMB := 0.008
const REVEAL := 0.004
## Anschlag: so weit vor der Zarge, Lage in z (hinter dem geschlossenen Blatt, außerhalb seines Schwenkkreises)
const STOP_W := 0.012
const STOP_Z := Vector2(-0.046, -0.034)

static var _cache := {}   # gleiche Türen teilen sich ein Mesh

var width := 1.2
var height := 2.1
var depth := 0.2
var lift := Vector2.ZERO   ## Wandhaut auf −Z bzw. +Z (Door.casing_lift)
var _v := PackedVector3Array()
var _n := PackedVector3Array()
var _uv := PackedVector2Array()
var _i := PackedInt32Array()


func setup(p_width: float, p_height: float, p_depth: float, p_lift := Vector2.ZERO) -> DoorCasing:
	width = p_width
	height = p_height
	depth = p_depth
	lift = p_lift
	return self


func _ready() -> void:
	material_override = Mat.hotel_wood()
	var key := "%.3f|%.3f|%.3f|%.3f|%.3f" % [width, height, depth, lift.x, lift.y]
	if not _cache.has(key):
		_build()
		_cache[key] = Geo.add_surface(ArrayMesh.new(), _v, _n, _i, _uv)
		_v = PackedVector3Array()
		_n = PackedVector3Array()
		_uv = PackedVector2Array()
		_i = PackedInt32Array()
	mesh = _cache[key]


func _build() -> void:
	# Zarge bis vor die Wandhaut (sonst sähe man deren Schnittkante in der Laibung)
	var d0 := -depth / 2.0 - lift.x
	var d1 := depth / 2.0 + lift.y
	var top := height - JAMB
	# Zarge: Innenflächen der drei Bretter, Faser entlang
	_quad(Vector3(JAMB, 0, d0), Vector3(JAMB, top, d0), Vector3(JAMB, top, d1), Vector3(JAMB, 0, d1), Vector3.RIGHT, true)
	_quad(Vector3(width - JAMB, 0, d0), Vector3(width - JAMB, top, d0), Vector3(width - JAMB, top, d1),
		Vector3(width - JAMB, 0, d1), Vector3.LEFT, true)
	_quad(Vector3(JAMB, top, d0), Vector3(width - JAMB, top, d0), Vector3(width - JAMB, top, d1), Vector3(JAMB, top, d1),
		Vector3.DOWN, false)
	# Stirnseiten der Zarge zwischen ihrer Fläche und der Bekleidung (Schattenfuge)
	for s in [-1.0, 1.0]:
		var z: float = d0 if s < 0.0 else d1
		var n := Vector3(0, 0, s)
		var a := JAMB - REVEAL
		_quad(Vector3(a, 0, z), Vector3(JAMB, 0, z), Vector3(JAMB, top, z), Vector3(a, top, z), n, true)
		_quad(Vector3(width - JAMB, 0, z), Vector3(width - a, 0, z), Vector3(width - a, top, z), Vector3(width - JAMB, top, z), n, true)
		_quad(Vector3(a, top, z), Vector3(width - a, top, z), Vector3(width - a, height - a, z), Vector3(a, height - a, z), n, false)
	_stop(top)
	for s in [-1.0, 1.0]:
		_casing(s)


## Anschlag auf der Zarge: Vorderfläche und beide Seiten, oben auf Gehrung (Seitenflächen stoßen stumpf)
func _stop(top: float) -> void:
	var x0 := JAMB
	var x1 := JAMB + STOP_W
	var y1 := top - STOP_W
	var z0 := STOP_Z.x
	var z1 := STOP_Z.y
	_quad(Vector3(x1, 0, z0), Vector3(x1, y1, z0), Vector3(x1, y1, z1), Vector3(x1, 0, z1), Vector3.RIGHT, true)
	_quad(Vector3(width - x1, 0, z0), Vector3(width - x1, y1, z0), Vector3(width - x1, y1, z1), Vector3(width - x1, 0, z1),
		Vector3.LEFT, true)
	_quad(Vector3(x1, y1, z0), Vector3(width - x1, y1, z0), Vector3(width - x1, y1, z1), Vector3(x1, y1, z1),
		Vector3.DOWN, false)
	for z in [z0, z1]:
		var n := Vector3(0, 0, -1.0 if z == z0 else 1.0)
		_quad(Vector3(x0, 0, z), Vector3(x1, 0, z), Vector3(x1, top, z), Vector3(x0, top, z), n, true)
		_quad(Vector3(width - x1, 0, z), Vector3(width - x0, 0, z), Vector3(width - x0, top, z), Vector3(width - x1, top, z), n, true)
		_quad(Vector3(x1, y1, z), Vector3(width - x1, y1, z), Vector3(width - x1, top, z), Vector3(x1, top, z), n, false)


## Bekleidung auf der Wandseite s (±Z): jede Profilstufe als Band links hoch, oben quer, rechts hinab – die Ecken
## treffen sich auf der Diagonale (Gehrung von selbst)
func _casing(s: float) -> void:
	var face := s * (depth / 2.0 + (lift.x if s < 0.0 else lift.y))
	var xl := JAMB - REVEAL
	var xr := width - JAMB + REVEAL
	var yh := height - JAMB + REVEAL
	for k in PROFILE.size() - 1:
		var p0: Vector2 = PROFILE[k]
		var p1: Vector2 = PROFILE[k + 1]
		var t := (p1 - p0).normalized()
		var pn := Vector2(-t.y, t.x)   # Profil von innen nach außen: Außenseite links der Laufrichtung
		var z0 := face + s * p0.y
		var z1 := face + s * p1.y
		# links (u nach −X)
		_quad(Vector3(xl - p0.x, 0, z0), Vector3(xl - p1.x, 0, z1), Vector3(xl - p1.x, yh + p1.x, z1),
			Vector3(xl - p0.x, yh + p0.x, z0), Vector3(-pn.x, 0, s * pn.y).normalized(), true)
		# oben (u nach +Y)
		_quad(Vector3(xl - p0.x, yh + p0.x, z0), Vector3(xl - p1.x, yh + p1.x, z1), Vector3(xr + p1.x, yh + p1.x, z1),
			Vector3(xr + p0.x, yh + p0.x, z0), Vector3(0, pn.x, s * pn.y).normalized(), false)
		# rechts (u nach +X)
		_quad(Vector3(xr + p0.x, 0, z0), Vector3(xr + p1.x, 0, z1), Vector3(xr + p1.x, yh + p1.x, z1),
			Vector3(xr + p0.x, yh + p0.x, z0), Vector3(pn.x, 0, s * pn.y).normalized(), true)


## Viereck a–d mit Normale n, im Uhrzeigersinn von vorn (Godot); UV in Metern, Faser senkrecht (u = y) oder
## waagerecht (u = x), v quer dazu aus den übrigen Achsen
func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, vertical: bool) -> void:
	var base := _v.size()
	for p in [a, b, c, d]:
		_v.append(p)
		_n.append(n)
		_uv.append(Vector2(p.y, p.x + p.z) if vertical else Vector2(p.x, p.y + p.z))
	if (b - a).cross(c - a).dot(n) < 0.0:
		_i.append_array([base, base + 1, base + 2, base, base + 2, base + 3])
	else:
		_i.append_array([base, base + 2, base + 1, base, base + 3, base + 2])
