class_name DiningTable
extends StaticBody3D
## Tafel im Speisesaal (ZIM-157, Skizze des Nutzers 2.11.), Planfarbe „Möbel: Tafel“, im Look der Bücherregale:
## Beine LEG im Quadrat mit je drei Furchen auf jeder Seite, Zargen APRON_SET hinter der Außenfläche der Beine mit
## stehenden Mulden wie im Fries der Regale, die Platte steht ringsum OVERHANG über. So groß wie im Plan, auch lange
## Tafeln nur mit vier Eckbeinen (Wunsch des Nutzers 2.11.). Darauf ein Läufer aus Damast entlang der Länge, der an
## beiden Enden RUNNER_DROP herabhängt (Spielkonzept 7.15). Ursprung mittig auf dem Boden, lokal x = Länge.
##
## Beine und Zargen aus tools/build_dining_table.py (gebackene Verschattung und Normale), gesetzt als MultiMesh je Teil;
## eine Zarge sind aneinandergereihte Stücke von je einer Mulde (PITCH), leicht gestreckt, bis die Länge zwischen zwei
## Beinen aufgeht – die Holz-UV läuft über INSTANCE_CUSTOM durch (psx_photo, instance_shift wie Bookshelf). Platte und
## Läufer baut das Skript selbst, Läufer-Texturen aus tools/build_runner.py. Maße = Bauskript.

const MODEL := "res://assets/models/dining_table.glb"
const AO := "res://assets/textures/dining_table_ao.png"
const NORMAL := "res://assets/textures/dining_table_normal.png"
const RUNNER_TEX := "res://assets/textures/TableRunner/table_runner_basecolor.png"
const RUNNER_NORMAL := "res://assets/textures/TableRunner/table_runner_normal.png"
const RUNNER_ROUGH := "res://assets/textures/TableRunner/table_runner_roughness.png"
## eine Kachel des Damasts; Glanz der Atlasbindung
const RUNNER_METERS := 0.5
const RUNNER_SPECULAR := 0.35

## Oberkante der Platte, Stärke der Platte
const HEIGHT := 0.85
const TOP_T := 0.04
const LEG := 0.15
const OVERHANG := 0.04
const APRON_SET := 0.01
const APRON_T := 0.025
const APRON_H := 0.10
const PITCH := 0.031
## Kante der Platte: oben gerundet (EDGE_R), senkrecht, unten eine Fase (EDGE_CHAMFER)
const EDGE_R := 0.008
const EDGE_CHAMFER := 0.008
const EDGE_STEPS := 4
## Läufer: Breite (höchstens RUNNER_SHARE der Plattenbreite), Stärke, so weit hängt er an den Enden herab
const RUNNER_W := 0.40
const RUNNER_SHARE := 0.45
const RUNNER_T := 0.003
const RUNNER_DROP := 0.30
## kleinste Platte – kleinere Rechtecke baut LevelBuilder als Kasten
const MIN_SIZE := Vector2(0.6, 0.5)

static var _parts := {}
static var _wood: ShaderMaterial
static var _top_wood: ShaderMaterial
static var _cloth: ShaderMaterial

## Platte: Länge (lokal x) und Breite (lokal z)
var size := Vector2(2.0, 1.0)
## Versatz der Maserung (u, v) für die ganze Tafel
var grain := Vector2.ZERO


static func make(p_size: Vector2) -> DiningTable:
	var table := DiningTable.new()
	table.size = p_size
	return table


## Rechteck im Plan groß genug für eine Tafel (in beiden Lagen)
static func fits(rect_size: Vector2) -> bool:
	return maxf(rect_size.x, rect_size.y) >= MIN_SIZE.x and minf(rect_size.x, rect_size.y) >= MIN_SIZE.y


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("dining_tables")
	var hx := size.x / 2.0 - OVERHANG - LEG / 2.0   # Mitte der Beine
	var hz := size.y / 2.0 - OVERHANG - LEG / 2.0
	var xs: Array[float] = [-hx, hx]
	var put := {}   # Teil → [[Transform3D, Streckung, Versatz], …]
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([grain, size])
	# Ecken: das Bein ist mit Zargen nach +x und −z gebacken (vorn links), die übrigen gedreht
	for corner in [[-1, 1, 0.0], [1, 1, PI / 2.0], [1, -1, PI], [-1, -1, -PI / 2.0]]:
		_add(put, "leg_corner", Transform3D(Basis(Vector3.UP, corner[2]), Vector3(corner[0] * hx, 0, corner[1] * hz)),
			1.0, Vector2(rng.randf() * 5.0, rng.randf() * 5.0))
	# Zargen je Seite: Außenfläche nach o, Stücke laufen nach d = up × o, zwischen den Beinen dieser Seite
	var zs: Array[float] = [-hz, hz]
	for o: Vector3 in [Vector3.BACK, Vector3.FORWARD, Vector3.LEFT, Vector3.RIGHT]:
		var d := Vector3.UP.cross(o)
		var along_x := absf(d.x) > 0.5
		var legs: Array[float] = []
		for t in (xs if along_x else zs):
			legs.append(t * (d.x if along_x else d.z))
		legs.sort()
		var out := (hz if along_x else hx) + LEG / 2.0 - APRON_SET
		var u := rng.randf() * 7.0
		for k in legs.size() - 1:
			_apron(put, o, d, out, legs[k] + LEG / 2.0, legs[k + 1] - LEG / 2.0, Vector2(u, rng.randf() * 7.0))
	for part: String in put:
		var list: Array = put[part]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = _model()[part]
		mm.instance_count = list.size()
		for i in list.size():
			var shift: Vector2 = list[i][2] + grain
			mm.set_instance_transform(i, list[i][0])
			mm.set_instance_custom_data(i, Color(shift.x, shift.y, list[i][1], 0.0))
		var mmi := MultiMeshInstance3D.new()
		mmi.name = part
		mmi.multimesh = mm
		mmi.material_override = _wood_material()
		add_child(mmi)
	var top := MeshInstance3D.new()
	top.name = "top"
	top.mesh = _top_mesh()
	top.material_override = _top_material()
	add_child(top)
	var runner := MeshInstance3D.new()
	runner.name = "runner"
	runner.mesh = _runner_mesh()
	runner.material_override = _cloth_material()
	add_child(runner)
	_collision(xs, hx, hz)


## Zarge von t0 bis t1 entlang d (Außenfläche bei out entlang o): Stücke von PITCH, gestreckt, bis es aufgeht; das
## erste und letzte stoßen ans Bein
func _apron(put: Dictionary, o: Vector3, d: Vector3, out: float, t0: float, t1: float, shift: Vector2) -> void:
	var length := t1 - t0
	if length <= 0.0:
		return
	var n := maxi(1, roundi(length / PITCH))
	var stretch := length / (n * PITCH)
	for i in n:
		var part := "apron"
		if n > 1 and i == 0:
			part = "apron_l"
		elif n > 1 and i == n - 1:
			part = "apron_r"
		var t := t0 + i * PITCH * stretch
		_add(put, part, Transform3D(Basis(d * stretch, Vector3.UP, o), o * out + d * t), stretch,
			shift + Vector2(t - t0, 0))


func _add(put: Dictionary, part: String, xf: Transform3D, stretch: float, shift: Vector2) -> void:
	if not put.has(part):
		put[part] = []
	put[part].append([xf, stretch, shift])


## Platte, Beine und Zargen als Kästen; unter der Tafel bleibt es frei
func _collision(xs: Array[float], hx: float, hz: float) -> void:
	Geo.add_box_shape(self, Vector3(size.x, TOP_T, size.y), Vector3(0, HEIGHT - TOP_T / 2.0, 0))
	var leg_h := HEIGHT - TOP_T
	for x in xs:
		for s in [-1.0, 1.0]:
			Geo.add_box_shape(self, Vector3(LEG, leg_h, LEG), Vector3(x, leg_h / 2.0, s * hz))
	var y := leg_h - APRON_H / 2.0
	for s in [-1.0, 1.0]:
		Geo.add_box_shape(self, Vector3(2.0 * hx, APRON_H, APRON_T),
			Vector3(0, y, s * (hz + LEG / 2.0 - APRON_SET - APRON_T / 2.0)))
		Geo.add_box_shape(self, Vector3(APRON_T, APRON_H, 2.0 * hz),
			Vector3(s * (hx + LEG / 2.0 - APRON_SET - APRON_T / 2.0), y, 0))


# --- Platte --------------------------------------------------------------------------------------------------------
## Kante als (Abstand von der Plattenkante nach außen, Höhe, Normale in (außen, oben)): Rundung oben, senkrecht, Fase
static func _edge() -> Array:
	var pts := []
	for i in EDGE_STEPS + 1:
		var a := PI / 2.0 * (1.0 - float(i) / EDGE_STEPS)
		pts.append([-EDGE_R + EDGE_R * cos(a), HEIGHT - EDGE_R + EDGE_R * sin(a), Vector2(cos(a), sin(a))])
	var low := HEIGHT - TOP_T + EDGE_CHAMFER
	pts.append([0.0, low, Vector2(1, 0)])
	var q := Vector2(1, -1).normalized()
	pts.append([0.0, low, q])   # Knick zur Fase: eigene Normale
	pts.append([-EDGE_CHAMFER, HEIGHT - TOP_T, q])
	return pts


## Platte: oben und unten eben, ringsum die Kante (_edge) mit Gehrung an den Ecken. Holz-UV in Metern, Faser entlang x.
func _top_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var ax := size.x / 2.0
	var az := size.y / 2.0
	var edge := _edge()
	_flat(st, ax - EDGE_R, az - EDGE_R, HEIGHT, 1.0)
	_flat(st, ax - EDGE_CHAMFER, az - EDGE_CHAMFER, HEIGHT - TOP_T, -1.0)
	# vier Seiten: Normale nach außen n, entlang e (von Ecke zu Ecke), halbe Länge l und Abstand w der Kante
	for side in [[Vector3.BACK, Vector3.RIGHT, ax, az], [Vector3.FORWARD, Vector3.LEFT, ax, az],
			[Vector3.RIGHT, Vector3.FORWARD, az, ax], [Vector3.LEFT, Vector3.BACK, az, ax]]:
		var n: Vector3 = side[0]
		var e: Vector3 = side[1]
		var l: float = side[2]
		var w: float = side[3]
		var v := 0.0
		for i in edge.size() - 1:
			var a: Array = edge[i]
			var b: Array = edge[i + 1]
			if is_equal_approx(a[0], b[0]) and is_equal_approx(a[1], b[1]):
				continue
			var na: Vector2 = a[2]
			var nb: Vector2 = b[2]
			var len := Vector2(b[0] - a[0], b[1] - a[1]).length()
			var quad := [
				[n * (w + a[0]) - e * (l + a[0]) + Vector3.UP * a[1], na, -(l + a[0]), v],
				[n * (w + a[0]) + e * (l + a[0]) + Vector3.UP * a[1], na, l + a[0], v],
				[n * (w + b[0]) + e * (l + b[0]) + Vector3.UP * b[1], nb, l + b[0], v + len],
				[n * (w + b[0]) - e * (l + b[0]) + Vector3.UP * b[1], nb, -(l + b[0]), v + len]]
			for k in _order(quad[0][0], quad[1][0], quad[2][0], n):
				var p: Array = quad[k]
				var pn: Vector2 = p[1]
				st.set_normal((n * pn.x + Vector3.UP * pn.y).normalized())
				st.set_uv(Vector2(p[2], p[3]) + grain)
				st.add_vertex(p[0])
			v += len
	return st.commit()


## Ebene Fläche ±hx × ±hz in Höhe y, Normale nach up (1 oben, −1 unten)
func _flat(st: SurfaceTool, hx: float, hz: float, y: float, up: float) -> void:
	var c := [Vector3(-hx, y, -hz), Vector3(hx, y, -hz), Vector3(hx, y, hz), Vector3(-hx, y, hz)]
	for k in _order(c[0], c[1], c[2], Vector3.UP * up):
		var p: Vector3 = c[k]
		st.set_normal(Vector3.UP * up)
		st.set_uv(Vector2(p.x, p.z) + grain)
		st.add_vertex(p)


# --- Läufer --------------------------------------------------------------------------------------------------------
## Mittellinie des Läufers im Schnitt (x, y) mit Normale: vom unteren Ende links herauf, über die Rundung der Kante,
## über die Platte, auf der anderen Seite wieder hinab
func _runner_path() -> Array:
	var ax := size.x / 2.0
	var h := RUNNER_T / 2.0
	var r := EDGE_R + h
	var half := []   # rechte Hälfte von der Kante oben bis unten
	for i in EDGE_STEPS + 1:
		var a := PI / 2.0 * (1.0 - float(i) / EDGE_STEPS)
		half.append([Vector2(ax - EDGE_R + r * cos(a), HEIGHT - EDGE_R + r * sin(a)), Vector2(cos(a), sin(a))])
	half.append([Vector2(ax + h, HEIGHT - RUNNER_DROP), Vector2(1, 0)])
	var path := []
	for i in range(half.size() - 1, -1, -1):
		var p: Vector2 = half[i][0]
		var n: Vector2 = half[i][1]
		path.append([Vector2(-p.x, p.y), Vector2(-n.x, n.y)])
	for item in half:
		path.append(item)
	return path


## Läufer als dünnes Band: Ober- und Unterseite, Längskanten, Säume an den Enden. UV in Metern: u quer, v entlang
## (das Muster steht längs zum Läufer)
func _runner_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w := minf(RUNNER_W, size.y * RUNNER_SHARE) / 2.0
	var h := RUNNER_T / 2.0
	var path := _runner_path()
	var s := [0.0]
	for i in range(1, path.size()):
		s.append(s[i - 1] + (path[i][0] as Vector2).distance_to(path[i - 1][0]))
	var at := func(i: int, side: float, z: float) -> Vector3:
		var p: Vector2 = path[i][0] + path[i][1] * side * h
		return Vector3(p.x, p.y, z)
	for i in path.size() - 1:
		var n0: Vector2 = path[i][1]
		var n1: Vector2 = path[i + 1][1]
		for side in [1.0, -1.0]:
			var quad := [[at.call(i, side, -w), n0, Vector2(-w, s[i])], [at.call(i, side, w), n0, Vector2(w, s[i])],
				[at.call(i + 1, side, w), n1, Vector2(w, s[i + 1])], [at.call(i + 1, side, -w), n1, Vector2(-w, s[i + 1])]]
			_quad(st, quad, func(nn: Vector2) -> Vector3: return Vector3(nn.x, nn.y, 0) * side)
		for z in [-w, w]:   # Längskanten
			var quad := [[at.call(i, -1.0, z), Vector2.ZERO, Vector2(s[i], 0)], [at.call(i, 1.0, z), Vector2.ZERO, Vector2(s[i], RUNNER_T)],
				[at.call(i + 1, 1.0, z), Vector2.ZERO, Vector2(s[i + 1], RUNNER_T)], [at.call(i + 1, -1.0, z), Vector2.ZERO, Vector2(s[i + 1], 0)]]
			_quad(st, quad, func(_nn: Vector2) -> Vector3: return Vector3(0, 0, signf(z)))
	for i in [0, path.size() - 1]:   # Säume
		var down := Vector3.DOWN
		var quad := [[at.call(i, -1.0, -w), Vector2.ZERO, Vector2(-w, 0)], [at.call(i, 1.0, -w), Vector2.ZERO, Vector2(-w, RUNNER_T)],
			[at.call(i, 1.0, w), Vector2.ZERO, Vector2(w, RUNNER_T)], [at.call(i, -1.0, w), Vector2.ZERO, Vector2(w, 0)]]
		_quad(st, quad, func(_nn: Vector2) -> Vector3: return down)
	return st.commit()


## Viereck aus vier [Punkt, Normale im Schnitt, UV], Normale je Ecke aus normal_of
func _quad(st: SurfaceTool, quad: Array, normal_of: Callable) -> void:
	var p0: Vector3 = quad[0][0]
	var p1: Vector3 = quad[1][0]
	var p2: Vector3 = quad[2][0]
	for k in _order(p0, p1, p2, normal_of.call(quad[0][1])):
		var q: Array = quad[k]
		st.set_normal(normal_of.call(q[1]))
		st.set_uv(q[2])
		st.add_vertex(q[0])


## Dreiecke eines Vierecks (Ecken 0–3) so, dass sie von der Seite n aus im Uhrzeigersinn umlaufen (wie Geo._quad)
static func _order(p0: Vector3, p1: Vector3, p2: Vector3, n: Vector3) -> Array:
	return [0, 2, 1, 0, 3, 2] if (p1 - p0).cross(p2 - p0).dot(n) > 0.0 else [0, 1, 2, 0, 2, 3]


# --- Modell und Material ---------------------------------------------------------------------------------------------
## Teile des Modells: Name → Mesh
static func _model() -> Dictionary:
	if _parts.is_empty():
		var scene: Node = (load(MODEL) as PackedScene).instantiate()
		for mi: MeshInstance3D in scene.find_children("*", "MeshInstance3D", true, false):
			_parts[String(mi.name)] = mi.mesh
		scene.free()
	return _parts


## Holz der Beine und Zargen (Mat.hotel_wood) mit gebackener Verschattung und Normale, Maserung je Instanz versetzt
static func _wood_material() -> ShaderMaterial:
	if _wood == null:
		_wood = Mat.hotel_wood(AO, NORMAL).duplicate() as ShaderMaterial
		_wood.set_shader_parameter("instance_shift", true)
	return _wood


static func _top_material() -> ShaderMaterial:
	if _top_wood == null:
		_top_wood = Mat.hotel_wood()
	return _top_wood


static func _cloth_material() -> ShaderMaterial:
	if _cloth == null:
		_cloth = Mat.photo(RUNNER_TEX, RUNNER_METERS, RUNNER_NORMAL, RUNNER_ROUGH, RUNNER_SPECULAR, Color(1, 1, 1),
			false, true)
	return _cloth
