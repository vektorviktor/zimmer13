class_name GardenFurniture
extends StaticBody3D
## Gartenmöbel (ZIM-51, Fotos des Nutzers 31.10.): Gestelle aus anthrazit pulverbeschichtetem Vierkantrohr. Der Tisch
## quadratisch 80 × 80 cm, 75 cm hoch, oben eine Zarge und Holzlatten mit schmalen Fugen. Der Stuhl 50 cm breit,
## Armlehnen mit Holzauflage, Sitz und Lehne aus grauem Textilgewebe, das zwischen den Rohren leicht durchhängt; die
## Lehne gerade und nach hinten geneigt (die Krümmung des Vorbilds braucht es nicht). Holz: Wood_02 (Mat.wood) getönt
## wie Teak; Lack und Gewebe aus tools/garden_furniture.gd. Ursprung am Boden in der Mitte, Sitzseite des Stuhls nach
## +Z. Jedes Möbel ist ein Mesh mit vier Flächen (Lack, Längsholz, Hirnholz, Gewebe), alle Tische bzw. Stühle teilen es.

## Tisch: Kantenlänge, Höhe, Beine, Zarge (Höhe, Stärke), Latten (Anzahl, Fuge, Stärke)
const TABLE_SIDE := 0.8
const TABLE_H := 0.75
const LEG := 0.04
const APRON_H := 0.06
const APRON_T := 0.025
const SLATS := 10
const SLAT_GAP := 0.006
const SLAT_T := 0.02
## Stuhl: Breite, Tiefe (mit der geneigten Lehne), Rohr des Gestells und der Lehne, Sitzhöhe vorn und hinten, Höhe der
## Armlehne (Oberkante Holz), Lehne (Oberkante, Neigung), Durchhang des Gewebes
const CHAIR_W := 0.5
const CHAIR_D := 0.6
const TUBE := 0.035
const BACK_TUBE := 0.025
const SEAT_FRONT := 0.45
const SEAT_BACK := 0.41
const ARM_TOP := 0.65
const ARM_WOOD := Vector3(0.045, 0.02, 0.3)
const BACK_TOP := 0.9
const BACK_TILT := 10.0
const SAG := 0.015
## Rundung der Rohrkanten
const EDGE := 0.004
## Texturen (tools/garden_furniture.gd): Kachelgröße in Metern; Holz wie Teak getönt
const COAT_TEX := "res://assets/textures/garden_coat"
const FABRIC_TEX := "res://assets/textures/garden_fabric"
const COAT_METERS := 0.25
const FABRIC_METERS := 0.1
const WOOD_TINT := Color(1.25, 0.95, 0.7)
const SEED := 5152

static var _table: ArrayMesh
static var _chair: ArrayMesh

var is_chair := false


static func table() -> GardenFurniture:
	var f := GardenFurniture.new()
	if _table == null:
		_table = _build_table()
	Geo.mesh(f, _table, null, Vector3.ZERO)
	Geo.add_box_shape(f, Vector3(TABLE_SIDE, TABLE_H, TABLE_SIDE), Vector3(0, TABLE_H / 2.0, 0))
	f.collision_mask = 0
	return f


## Stuhl mit Sitzplatz (Seat) zur Vorderseite +Z
static func chair() -> GardenFurniture:
	var f := GardenFurniture.new()
	f.is_chair = true
	if _chair == null:
		_chair = _build_chair()
	Geo.mesh(f, _chair, null, Vector3.ZERO)
	var back_z := -CHAIR_D / 2.0 + 0.04
	Geo.add_box_shape(f, Vector3(CHAIR_W, SEAT_FRONT, CHAIR_D - 0.08), Vector3(0, SEAT_FRONT / 2.0, 0.04))
	Geo.add_box_shape(f, Vector3(CHAIR_W, BACK_TOP - SEAT_FRONT, 0.08), Vector3(0, (BACK_TOP + SEAT_FRONT) / 2.0, back_z))
	f.collision_mask = 0
	Seat.attach(f, "stuhl", SEAT_FRONT, Vector3(0, 0, 0.02), Vector3(0, 0, 1), CHAIR_W, CHAIR_D / 2.0 + 0.3)
	return f


static func _photo(base: String, meters: float, mesh_uv: bool) -> ShaderMaterial:
	return Mat.photo(base + ".png", meters, base + "_normal.png", base + "_rough.png", 0.5, Color(1, 1, 1), false, mesh_uv)


## Sammelt die Teile je Material und legt sie als Flächen eines Meshs an
class Parts:
	var coat := SurfaceTool.new()
	var wood := SurfaceTool.new()
	var end := SurfaceTool.new()
	var fabric := GrandStair.Shape.new()
	var rng := RandomNumberGenerator.new()
	var has_fabric := false

	func _init() -> void:
		for st: SurfaceTool in [coat, wood, end]:
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
		rng.seed = SEED

	## Vierkantrohr von a nach b, Querschnitt cross (Breite quer, Höhe), Kanten gerundet
	func tube(a: Vector3, b: Vector3, cross: Vector2) -> void:
		var dir := (b - a).normalized()
		var up := Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.99 else Vector3.BACK
		var basis := Basis.looking_at(dir, up)
		var m := Geo.rounded_box(Vector3(cross.x, cross.y, a.distance_to(b)), EDGE, 1)
		coat.append_from(m, 0, Transform3D(basis, (a + b) / 2.0))

	## Holzleiste um center, Faser entlang der längsten Achse, je Leiste ein anderer Ausschnitt der Maserung
	func board(center: Vector3, size: Vector3) -> void:
		var grain := 0 if size.x >= size.y and size.x >= size.z else (2 if size.z >= size.y else 1)
		var m := Geo.grain_box(size, grain, Vector2(1.0, 0.25), 0.1, Vector2(rng.randf(), rng.randf()))
		wood.append_from(m, 0, Transform3D(Basis(), center))
		end.append_from(m, 1, Transform3D(Basis(), center))

	## Gewebe als dünne Bahn über die Ecken a (links vorn), b (rechts vorn), c (rechts hinten), d (links hinten), in der
	## Mitte quer um sag nach -up durchhängend (stärker als längs). Oben- und Unterseite, UVs in Metern.
	func sheet(a: Vector3, b: Vector3, c: Vector3, d: Vector3, sag: float) -> void:
		has_fabric = true
		const NU := 8
		const NV := 8
		var n := (b - a).cross(d - a).normalized()
		if n.y < 0.0 or (absf(n.y) < 0.3 and n.z < 0.0):
			n = -n
		var at := func(u: float, v: float) -> Vector3:
			var p: Vector3 = a.lerp(b, u).lerp(d.lerp(c, u), v)
			return p - n * sag * sin(PI * u) * (0.6 + 0.4 * sin(PI * v))
		var width := a.distance_to(b)
		var length := a.distance_to(d)
		for side in [1.0, -1.0]:
			var off: Vector3 = n * (0.0015 * side)
			for i in NU:
				for j in NV:
					var q := [Vector2(i, j), Vector2(i + 1, j), Vector2(i + 1, j + 1), Vector2(i, j + 1)]
					var p := []
					var nn := []
					var uv := []
					for k: Vector2 in q:
						var u := k.x / NU
						var v := k.y / NV
						var pt: Vector3 = at.call(u, v)
						var du: Vector3 = at.call(minf(u + 0.01, 1.0), v) - at.call(maxf(u - 0.01, 0.0), v)
						var dv: Vector3 = at.call(u, minf(v + 0.01, 1.0)) - at.call(u, maxf(v - 0.01, 0.0))
						var normal := du.cross(dv).normalized()
						if normal.dot(n) < 0.0:
							normal = -normal
						p.append(pt + off)
						nn.append(normal * side)
						uv.append(Vector2(u * width, v * length))
					fabric.tri(p[0], p[1], p[2], nn[0], nn[1], nn[2], uv[0], uv[1], uv[2])
					fabric.tri(p[0], p[2], p[3], nn[0], nn[2], nn[3], uv[0], uv[2], uv[3])

	func commit() -> ArrayMesh:
		var m := ArrayMesh.new()
		var pairs := [[coat, GardenFurniture._photo(COAT_TEX, COAT_METERS, false)], [wood, Mat.wood(false, WOOD_TINT)],
			[end, Mat.wood(true, WOOD_TINT)]]
		if has_fabric:
			pairs.append([fabric.st, GardenFurniture._photo(FABRIC_TEX, FABRIC_METERS, true)])
		for pair: Array in pairs:
			(pair[0] as SurfaceTool).commit(m)
			m.surface_set_material(m.get_surface_count() - 1, pair[1])
		return m


## Beine, Zarge ringsum unter der Platte, eine Mittelstrebe unter den Latten; Latten entlang x über die ganze Tiefe
static func _build_table() -> ArrayMesh:
	var p := Parts.new()
	var h := TABLE_SIDE / 2.0
	var top := TABLE_H - SLAT_T
	var leg := h - LEG / 2.0
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			p.tube(Vector3(sx * leg, 0, sz * leg), Vector3(sx * leg, top, sz * leg), Vector2(LEG, LEG))
	var mid := top - APRON_H / 2.0
	var apron := h - APRON_T / 2.0
	for s in [-1.0, 1.0]:
		p.tube(Vector3(-leg, mid, s * apron), Vector3(leg, mid, s * apron), Vector2(APRON_T, APRON_H))
		p.tube(Vector3(s * apron, mid, -leg), Vector3(s * apron, mid, leg), Vector2(APRON_T, APRON_H))
	p.tube(Vector3(0, top - 0.015, -h + APRON_T), Vector3(0, top - 0.015, h - APRON_T), Vector2(0.03, 0.03))
	var width := (TABLE_SIDE - SLAT_GAP * (SLATS - 1)) / SLATS
	for i in SLATS:
		var z := -h + width / 2.0 + i * (width + SLAT_GAP)
		p.board(Vector3(0, top + SLAT_T / 2.0, z), Vector3(TABLE_SIDE, SLAT_T, width))
	return p.commit()


## Seitenteile (Vorderbein bis unter die Armlehne, Armlehne bis an die Lehne, Hinterbein schräg nach hinten,
## Sitzrohr), runde Sitzkante vorn, Querrohr hinten; Lehne aus zwei geneigten Holmen mit Querrohr oben. Das Gewebe
## spannt sich zwischen den Sitzrohren und zwischen den Holmen.
static func _build_chair() -> ArrayMesh:
	var p := Parts.new()
	var t := TUBE
	var x := CHAIR_W / 2.0 - t / 2.0
	var zf := CHAIR_D / 2.0 - t / 2.0 - 0.025   # Vorderbein
	var arm_y := ARM_TOP - ARM_WOOD.y - t / 2.0
	var tilt := tan(deg_to_rad(BACK_TILT))
	var back_x := x - t / 2.0 - BACK_TUBE / 2.0
	var back_top := Vector3(0, BACK_TOP - BACK_TUBE / 2.0, -CHAIR_D / 2.0 + BACK_TUBE / 2.0)
	var back_low := Vector3(0, SEAT_BACK - 0.02, back_top.z + (back_top.y - SEAT_BACK + 0.02) * tilt)
	var back_at := func(y: float) -> float: return back_low.z - (y - back_low.y) * tilt
	var zb := back_low.z + 0.01                                     # Sitz hinten
	for s in [-1.0, 1.0]:
		var sx: float = s * x
		p.tube(Vector3(sx, 0, zf), Vector3(sx, arm_y + t / 2.0, zf), Vector2(t, t))
		p.tube(Vector3(sx, arm_y, zf + t / 2.0), Vector3(sx, arm_y, back_at.call(arm_y)), Vector2(t, t))
		p.tube(Vector3(sx, 0, zb - 0.06), Vector3(sx, SEAT_BACK, zb), Vector2(t, t))
		p.tube(Vector3(sx, SEAT_FRONT - t / 2.0, zf), Vector3(sx, SEAT_BACK - t / 2.0, zb), Vector2(t, t * 0.8))
		p.tube(Vector3(s * back_x, back_low.y, back_low.z), Vector3(s * back_x, back_top.y, back_top.z),
			Vector2(BACK_TUBE, BACK_TUBE))
		p.board(Vector3(sx, ARM_TOP - ARM_WOOD.y / 2.0, zf + t / 2.0 + 0.012 - ARM_WOOD.z / 2.0), ARM_WOOD)
	var inner := x - t / 2.0
	p.tube(Vector3(-inner, SEAT_FRONT - 0.015, zf), Vector3(inner, SEAT_FRONT - 0.015, zf), Vector2(0.03, 0.03))
	p.tube(Vector3(-inner, SEAT_BACK - 0.015, zb), Vector3(inner, SEAT_BACK - 0.015, zb), Vector2(0.025, 0.025))
	p.tube(Vector3(-back_x, back_top.y, back_top.z), Vector3(back_x, back_top.y, back_top.z), Vector2(BACK_TUBE, BACK_TUBE))
	var fx := inner - 0.005
	p.sheet(Vector3(-fx, SEAT_FRONT, zf), Vector3(fx, SEAT_FRONT, zf), Vector3(fx, SEAT_BACK, zb), Vector3(-fx, SEAT_BACK, zb), SAG)
	var bx := back_x - BACK_TUBE / 2.0
	var y0 := SEAT_BACK + 0.01
	var y1 := back_top.y - BACK_TUBE / 2.0
	p.sheet(Vector3(-bx, y0, back_at.call(y0)), Vector3(bx, y0, back_at.call(y0)), Vector3(bx, y1, back_at.call(y1)),
		Vector3(-bx, y1, back_at.call(y1)), SAG)
	return p.commit()
