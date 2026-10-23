class_name GrandStair
## Lobbytreppe und Galeriegeländer (Spielkonzept 7.5, Lobbytreppe 2026-10-21): gerade Wangentreppe aus dem Plan,
## unten offen – zwei Wangen tragen Tritt- und Setzstufen, darunter eine schräge Untersicht. Beidseitig ein Geländer
## mit gedrechselten Stäben (zwei je Stufe), profiliertem Handlauf und Pfosten mit Kappe und Knauf; die oberen
## Pfosten hängen mit einem Zapfen unter die Galeriekante. Läufer mit Messingstangen in der Mitte.
## Gelaufen wird wie bei LevelBuilder._flight auf einer glatten Rampe (Ebene 1, Meta „stair_ramp“), die Trittflächen
## sind eigene Körper auf LevelBuilder.LAYER_TREAD (nur für Spuren). Alles wird im Code gebaut, ein Mesh je Material.

## Ziel-Steigung; die Zahl der Stufen ergibt sich aus der Höhe, der Auftritt aus der Lauflänge im Plan
const RISER := 0.17
## Trittstufe: Dicke und Überstand über die Setzstufe darunter; Setzstufe: Dicke
const TREAD_T := 0.04
const NOSING := 0.03
const RISER_T := 0.02
## Wange: Dicke, Oberkante über und Unterkante unter der Linie der Stufenvorderkanten (senkrecht gemessen)
const STRINGER_T := 0.07
const STRINGER_UP := 0.07
const STRINGER_DOWN := 0.4
## Untersicht so weit über der Unterkante der Wangen (die Wangen stehen unten etwas vor)
const SOFFIT_UP := 0.05
## Handlauf: Oberkante über den Stufenvorderkanten bzw. über dem Galerieboden; Querschnitt (quer, hoch) als
## geschlossener Umriss, Unterseite auf der Achse
const RAIL_H := 0.9
const GALLERY_RAIL_H := 1.0
const RAIL_PROFILE := [Vector2(-0.025, 0.0), Vector2(0.025, 0.0), Vector2(0.025, 0.015), Vector2(0.0375, 0.025),
	Vector2(0.0375, 0.045), Vector2(0.025, 0.061), Vector2(0.0, 0.066), Vector2(-0.025, 0.061), Vector2(-0.0375, 0.045),
	Vector2(-0.0375, 0.025), Vector2(-0.025, 0.015)]
const RAIL_PROFILE_H := 0.066
## Stäbe: so viele je Stufe; am Galeriegeländer höchstens dieser Abstand. Vierkant unten und oben (Kantenlänge,
## Höhen), dazwischen gedrechselt mit diesem Umriss (Radius, Anteil der Länge), BALUSTER_SIDES Ecken
const BALUSTERS_PER_TREAD := 2
const BALUSTER_GAP := 0.14
const BALUSTER_BLOCK := 0.045
const BALUSTER_LOW := 0.09
const BALUSTER_HIGH := 0.11
const BALUSTER_TURN := [Vector2(0.02, 0.0), Vector2(0.023, 0.03), Vector2(0.023, 0.06), Vector2(0.016, 0.09),
	Vector2(0.016, 0.14), Vector2(0.022, 0.2), Vector2(0.028, 0.32), Vector2(0.026, 0.42), Vector2(0.018, 0.52),
	Vector2(0.012, 0.62), Vector2(0.012, 0.8), Vector2(0.016, 0.88), Vector2(0.02, 0.93), Vector2(0.02, 0.97),
	Vector2(0.016, 1.0)]
const BALUSTER_SIDES := 8
## Bodenholm des Galeriegeländers (die Stäbe der Treppe stehen auf der Wange): Breite, Höhe
const SILL := Vector2(0.07, 0.06)
## Pfosten: Kantenlänge, Höhe der Kappe über dem Fuß (unten) bzw. über dem Galerieboden; Fußblock; Knauf und Zapfen
## als Drehkörper (Radius, Höhe), von unten nach oben
const NEWEL := 0.14
const NEWEL_TOP := 1.2
const NEWEL_BASE := Vector3(0.17, 0.22, 0.17)
const NEWEL_CAP := Vector3(0.19, 0.045, 0.19)
const FINIAL := [Vector2(0.03, 0.0), Vector2(0.025, 0.025), Vector2(0.04, 0.04), Vector2(0.055, 0.075),
	Vector2(0.04, 0.11), Vector2(0.0, 0.13)]
const DROP := [Vector2(0.0, 0.0), Vector2(0.035, 0.04), Vector2(0.03, 0.07), Vector2(0.045, 0.1), Vector2(0.06, 0.12)]
## Galeriegeländer: höchstens so weit zwischen zwei Pfosten
const BAY := 3.0
## Blende vor der Galeriekante (lackiert wie die Pfosten): Tiefe vor der Kante – die Pfostenfüße (NEWEL_BASE) ragen
## 8,5 cm vor –, Überstand unter die Decke; Abdeckleiste oben und Leiste unten: Tiefe, Höhe
const FASCIA_DEPTH := 0.1
const FASCIA_BELOW := 0.04
const FASCIA_LIP := Vector2(0.125, 0.035)
## Läufer (TexGen „runner“): Breite, Abstand über den Stufen; Messingstangen: Radius, Überstand je Seite
const RUNNER_W := 2.4
const RUNNER_LIFT := 0.003
const ROD_R := 0.012
const ROD_OVER := 0.04
## Rampe: Dicke (senkrecht zur Schräge) – reicht unten bis knapp unter die Untersicht, sonst steckte der Kopf
## darin, bevor man anstößt
const RAMP_T := 0.32
## Farben: Lack (Setzstufen, Wangen, Stäbe, Pfosten, Untersicht), gebeizt (Trittstufen, Handlauf, Kappen), Messing
const PAINT := Color(0.78, 0.74, 0.64)
const STAIN := Color(0.3, 0.15, 0.08)
const BRASS := Color(0.86, 0.66, 0.3)

static var _balusters := {}


## Treppe im Rechteck rect (Plan, x/z), oberes Ende up („north“, „south“, „east“, „west“), von y = 0 bis rise über
## dem Boden von parent.
static func build(parent: Node3D, rect: Rect2, up: String, rise: float) -> void:
	var holder := Node3D.new()
	holder.name = "GrandStair"
	var along_x := up == "east" or up == "west"
	var width := rect.size.y if along_x else rect.size.x
	var run := rect.size.x if along_x else rect.size.y
	var c := rect.get_center()
	match up:
		"north":
			holder.position = Vector3(c.x, 0, rect.end.y)
		"south":
			holder.position = Vector3(c.x, 0, rect.position.y)
			holder.rotation.y = PI
		"east":
			holder.position = Vector3(rect.position.x, 0, c.y)
			holder.rotation.y = -PI / 2.0
		_:
			holder.position = Vector3(rect.end.x, 0, c.y)
			holder.rotation.y = PI / 2.0
	parent.add_child(holder)
	# Lokal: x quer, −z bergauf (u = −z ab der ersten Setzstufe), y hoch
	var n := maxi(2, roundi(rise / RISER))
	var h := rise / n
	var g := run / (n - 1)
	var slope := h / g
	var nose := func(u: float) -> float: return h + u * slope   # Linie der Stufenvorderkanten
	var x_side := width / 2.0 - NEWEL / 2.0   # Mitte von Wange, Stäben, Handlauf und Pfosten
	var inner := x_side - STRINGER_T / 2.0
	var paint := Shape.new()
	var stain := Shape.new()
	var brass := Shape.new()
	var runner := Shape.new()
	for k in range(1, n):
		var u0 := (k - 1) * g - NOSING
		stain.box(Vector3(0, k * h - TREAD_T / 2.0, -(u0 + k * g) / 2.0), Vector3(2.0 * inner + 0.02, TREAD_T, g + NOSING))
	for k in range(1, n + 1):
		var y0 := (k - 1) * h
		var y1 := k * h - (TREAD_T if k < n else 0.0)
		var u0 := (k - 1) * g if k < n else run - RISER_T   # die oberste vor der Galeriekante, nicht in ihr
		paint.box(Vector3(0, (y0 + y1) / 2.0, -(u0 + RISER_T / 2.0)), Vector3(2.0 * inner + 0.02, y1 - y0, RISER_T))
	for s: float in [-1.0, 1.0]:
		_stringer(paint, s * x_side, run, nose)
	_soffit(paint, inner, run, nose, slope)
	_runner(runner, brass, n, h, g, run)
	var rail_drop := RAIL_PROFILE_H / cos(atan(slope))   # senkrechte Höhe des schrägen Querschnitts
	var y_rail := func(u: float) -> float: return nose.call(u) + RAIL_H - rail_drop
	for s: float in [-1.0, 1.0]:
		var x := s * x_side
		stain.sweep(RAIL_PROFILE, Vector3(x, y_rail.call(0.0), 0.0), Vector3(x, y_rail.call(run), -run))
		_newel(paint, stain, Vector3(x, 0, 0), NEWEL_TOP, false)
		_newel(paint, stain, Vector3(x, rise - STRINGER_DOWN - 0.05, -run), rise + NEWEL_TOP, true)
		var spots: Array[Transform3D] = []
		for k in range(1, n):
			for j in BALUSTERS_PER_TREAD:
				var u := (k - 1) * g + g * (j + 0.5) / BALUSTERS_PER_TREAD
				if u < NEWEL / 2.0 + 0.03 or u > run - NEWEL / 2.0 - 0.03:
					continue
				spots.append(Transform3D(Basis(), Vector3(x, nose.call(u) + STRINGER_UP - 0.03, -u)))
		_baluster_row(holder, RAIL_H - rail_drop + 0.01 - STRINGER_UP + 0.03, spots)
	Geo.mesh(holder, paint.commit(), Mat.psx(PAINT), Vector3.ZERO)
	Geo.mesh(holder, stain.commit(), Mat.psx(STAIN), Vector3.ZERO)
	Geo.mesh(holder, brass.commit(), Mat.metal(BRASS), Vector3.ZERO)
	var ramp := _collision(holder, width, run, rise, n, h, g, x_side, nose)
	# Der Läufer hängt an der Rampe: Footsteps.floor_under liest den Boden aus den Meshes des getroffenen Körpers –
	# Teppichschritte, Gehen ist leise (Player.SOFT_FLOORS)
	var carpet := Mat.layer_uv("runner").duplicate() as ShaderMaterial
	carpet.set_meta("floor", "carpet")
	Geo.mesh(ramp, runner.commit(), carpet, Vector3.ZERO).transform = ramp.transform.affine_inverse()


## Galeriegeländer von a nach b (Kollision 1 m hoch wie LevelBuilder._railing): Bodenholm, Stäbe, Handlauf und
## Pfosten an den Enden (post_a/post_b) und alle höchstens BAY Meter. Ein Pfosten, den es an dieser Stelle schon
## gibt (Ecke zweier Kanten), entsteht nicht doppelt.
static func railing(parent: Node3D, a: Vector3, b: Vector3, post_a: bool = true, post_b: bool = true) -> void:
	var length := a.distance_to(b)
	if length < 0.1:
		return
	var holder := Node3D.new()
	holder.position = (a + b) / 2.0
	holder.rotation.y = atan2(b.x - a.x, b.z - a.z) - PI / 2.0
	parent.add_child(holder)
	Geo.collider(holder, Vector3(length, GALLERY_RAIL_H, 0.1), Vector3(0, GALLERY_RAIL_H / 2.0, 0))
	var paint := Shape.new()
	var stain := Shape.new()
	paint.box(Vector3(0, SILL.y / 2.0, 0), Vector3(length, SILL.y, SILL.x))
	var rail_y := GALLERY_RAIL_H - RAIL_PROFILE_H
	stain.sweep(RAIL_PROFILE, Vector3(-length / 2.0, rail_y, 0), Vector3(length / 2.0, rail_y, 0))
	var placed: Dictionary = parent.get_meta("gallery_posts", {})
	parent.set_meta("gallery_posts", placed)
	var bays := ceili(length / BAY - 0.01)
	var spots: Array[Transform3D] = []
	for i in bays + 1:
		var x := -length / 2.0 + length * i / bays
		var has_post := (i > 0 or post_a) and (i < bays or post_b)
		var world := holder.position + Basis(Vector3.UP, holder.rotation.y) * Vector3(x, 0, 0)
		var key := Vector3i(roundi(world.x * 50.0), roundi(world.y * 50.0), roundi(world.z * 50.0))
		if has_post and not placed.has(key):
			placed[key] = true
			_newel(paint, stain, Vector3(x, 0, 0), NEWEL_TOP, false)
		if i == bays:
			break
		# Stäbe im Feld bis zum nächsten Pfosten (wo keiner steht, bis ans Ende)
		var from := x + (NEWEL / 2.0 if i > 0 or post_a else 0.0)
		var to := -length / 2.0 + length * (i + 1) / bays - (NEWEL / 2.0 if i + 1 < bays or post_b else 0.0)
		var m := maxi(1, roundi((to - from) / BALUSTER_GAP))
		for j in m:
			spots.append(Transform3D(Basis(), Vector3(lerpf(from, to, (j + 0.5) / m), SILL.y - 0.01, 0)))
	_baluster_row(holder, rail_y + 0.01 - SILL.y + 0.01, spots)
	Geo.mesh(holder, paint.commit(), Mat.psx(PAINT), Vector3.ZERO)
	Geo.mesh(holder, stain.commit(), Mat.psx(STAIN), Vector3.ZERO)


## Blende vor der Galeriekante von a nach b (achsparallel, Galerieboden auf a.y), out zeigt in den Luftraum: deckt
## die Stirn der Decke und des Bodens darüber (drop = Abstand Galerieboden – Deckenunterseite) und die vorstehenden
## Pfostenfüße ab. ext_a/ext_b verlängern um die Leistentiefe, damit sich zwei Blenden an einer Ecke treffen.
static func fascia(parent: Node3D, a: Vector3, b: Vector3, out: Vector3, drop: float, ext_a: bool = true,
		ext_b: bool = true) -> void:
	var along := (b - a).normalized()
	a -= along * (FASCIA_LIP.x if ext_a else 0.0)
	b += along * (FASCIA_LIP.x if ext_b else 0.0)
	var sh := Shape.new()
	var part := func(depth: float, y0: float, y1: float) -> void:
		var c := (a + b) / 2.0 + out * (depth / 2.0) + Vector3.UP * (y0 + y1) / 2.0
		var size := (b - a).abs() + out.abs() * depth + Vector3.UP * (y1 - y0)
		sh.box(c, size)
	var bottom := -drop - FASCIA_BELOW
	part.call(FASCIA_DEPTH, bottom + FASCIA_LIP.y, 0.0)
	part.call(FASCIA_LIP.x, 0.0, FASCIA_LIP.y)   # Abdeckleiste, vor dem Bodenholm
	part.call(FASCIA_LIP.x, bottom, bottom + FASCIA_LIP.y)
	Geo.mesh(parent, sh.commit(), Mat.psx(PAINT), Vector3.ZERO)


## Wange auf Höhe x: Oberkante STRINGER_UP über, Unterkante STRINGER_DOWN unter den Stufenvorderkanten; vorn senkrecht
## in der Mitte des unteren Pfostens, unten auf dem Boden, oben senkrecht in der Mitte des oberen Pfostens.
static func _stringer(sh: Shape, x: float, run: float, nose: Callable) -> void:
	var u_floor := (STRINGER_DOWN - float(nose.call(0.0))) / ((float(nose.call(1.0)) - float(nose.call(0.0))))
	var us: Array[float] = [0.0, u_floor]
	var steps := ceili(run / Geo.MAX_FACE)
	for i in range(1, steps + 1):
		var u := run * i / steps
		if absf(u - u_floor) > 0.05:
			us.append(u)
	us.sort()
	var top := func(u: float) -> float: return float(nose.call(u)) + STRINGER_UP
	var bottom := func(u: float) -> float: return maxf(0.0, float(nose.call(u)) - STRINGER_DOWN)
	for i in us.size() - 1:
		var u0 := us[i]
		var u1 := us[i + 1]
		var a := Vector2(-u0, bottom.call(u0))
		var b := Vector2(-u0, top.call(u0))
		var c := Vector2(-u1, top.call(u1))
		var d := Vector2(-u1, bottom.call(u1))
		for side: float in [-1.0, 1.0]:
			var xs := x + side * STRINGER_T / 2.0
			sh.quad(Vector3(xs, a.y, a.x), Vector3(xs, b.y, b.x), Vector3(xs, c.y, c.x), Vector3(xs, d.y, d.x), Vector3(side, 0, 0))
		var up_n := Vector3(0, c.x - b.x, -(c.y - b.y)).normalized()
		if up_n.y < 0.0:
			up_n = -up_n
		sh.quad(Vector3(x - STRINGER_T / 2.0, b.y, b.x), Vector3(x + STRINGER_T / 2.0, b.y, b.x),
			Vector3(x + STRINGER_T / 2.0, c.y, c.x), Vector3(x - STRINGER_T / 2.0, c.y, c.x), up_n)
		if a.y > 0.0 or d.y > 0.0:
			var down_n := Vector3(0, d.x - a.x, -(d.y - a.y)).normalized()
			if down_n.y > 0.0:
				down_n = -down_n
			sh.quad(Vector3(x - STRINGER_T / 2.0, a.y, a.x), Vector3(x + STRINGER_T / 2.0, a.y, a.x),
				Vector3(x + STRINGER_T / 2.0, d.y, d.x), Vector3(x - STRINGER_T / 2.0, d.y, d.x), down_n)


## Schräge Untersicht zwischen den Wangen, vom Boden bis zur Galeriekante.
static func _soffit(sh: Shape, inner: float, run: float, nose: Callable, slope: float) -> void:
	var drop := STRINGER_DOWN - SOFFIT_UP
	var u0 := (drop - float(nose.call(0.0))) / slope
	var n := Vector3(0, -1, -slope).normalized()
	sh.grid(Vector3(-inner, 0.0, -u0), Vector3(inner, 0.0, -u0),
		Vector3(inner, float(nose.call(run)) - drop, -run), Vector3(-inner, float(nose.call(run)) - drop, -run), n)


## Läufer im Wasserfall-Stil: von jeder Stufenvorderkante senkrecht hinab auf die Stufe darunter, über die Stufe
## bis zur nächsten Vorderkante; oben die letzte Setzstufe hinauf. Die Musterkachel wiederholt sich entlang des
## Wegs (an den Kachelgrenzen geteilt, die UVs springen), in jeder Falte eine Messingstange.
static func _runner(sh: Shape, brass: Shape, n: int, h: float, g: float, run: float) -> void:
	var px := RUNNER_W / TexGen.RUNNER_WIDTH
	var tile := TexGen.RUNNER_TILE_ROWS * px
	var cap_v := float(TexGen.RUNNER_CAP_ROWS) / (TexGen.RUNNER_CAP_ROWS + TexGen.RUNNER_TILE_ROWS)
	var path: Array[Vector2] = []   # (u, y)
	for k in range(1, n):
		var u := (k - 1) * g - NOSING - RUNNER_LIFT
		path.append(Vector2(u, (k - 1) * h + (RUNNER_LIFT if k > 1 else 0.0)))
		path.append(Vector2(u, k * h + RUNNER_LIFT))
		if k > 1:
			_rod(brass, Vector3(0, (k - 1) * h + ROD_R + RUNNER_LIFT, -(u - ROD_R)))
	path.append(Vector2(run - RISER_T - RUNNER_LIFT, (n - 1) * h + RUNNER_LIFT))
	_rod(brass, Vector3(0, (n - 1) * h + ROD_R + RUNNER_LIFT, -(run - RISER_T - RUNNER_LIFT - ROD_R)))
	path.append(Vector2(run - RISER_T - RUNNER_LIFT, n * h))
	var s := 0.0
	for i in path.size() - 1:
		var p0 := path[i]
		var p1 := path[i + 1]
		var length := p0.distance_to(p1)
		var normal := Vector3(0, 1, 0) if absf(p1.y - p0.y) < 0.001 else Vector3(0, 0, 1)
		var cuts: Array[float] = [0.0]
		var next := (floorf(s / tile) + 1.0) * tile
		while next < s + length - 0.001:
			cuts.append(next - s)
			next += tile
		cuts.append(length)
		for j in cuts.size() - 1:
			var t0 := cuts[j] / length
			var t1 := cuts[j + 1] / length
			var a := p0.lerp(p1, t0)
			var b := p0.lerp(p1, t1)
			var phase := fposmod((s + cuts[j]) / tile, 1.0)
			var v0 := cap_v + phase * (1.0 - cap_v)
			var v1 := v0 + (cuts[j + 1] - cuts[j]) / tile * (1.0 - cap_v)
			var w := RUNNER_W / 2.0
			sh.quad(Vector3(-w, a.y, -a.x), Vector3(w, a.y, -a.x), Vector3(w, b.y, -b.x), Vector3(-w, b.y, -b.x), normal,
				[Vector2(0, v0), Vector2(1, v0), Vector2(1, v1), Vector2(0, v1)])
		s += length


static func _rod(sh: Shape, center: Vector3) -> void:
	var half := RUNNER_W / 2.0 + ROD_OVER
	sh.sweep([Vector2(-ROD_R, 0), Vector2(-ROD_R / 2.0, -ROD_R * 0.87), Vector2(ROD_R / 2.0, -ROD_R * 0.87),
		Vector2(ROD_R, 0), Vector2(ROD_R / 2.0, ROD_R * 0.87), Vector2(-ROD_R / 2.0, ROD_R * 0.87)],
		center + Vector3(-half, 0, 0), center + Vector3(half, 0, 0))


## Pfosten mit Fuß bei foot, Kappe bis top (Höhe im selben Raum): Fußblock (oder unten ein gedrechselter Zapfen,
## wenn er unter einer Kante hängt), Schaft, Kragen, gebeizte Kappe mit Knauf.
static func _newel(paint: Shape, stain: Shape, foot: Vector3, top: float, hanging: bool) -> void:
	var base_top := foot.y + (0.0 if hanging else NEWEL_BASE.y)
	if hanging:
		paint.lathe(DROP, foot - Vector3(0, DROP[-1].y, 0), BALUSTER_SIDES)
	else:
		paint.box(foot + Vector3(0, NEWEL_BASE.y / 2.0, 0), NEWEL_BASE)
	var cap_y := top - NEWEL_CAP.y
	var collar := 0.03
	paint.box(Vector3(foot.x, (base_top + cap_y - collar) / 2.0, foot.z), Vector3(NEWEL, cap_y - collar - base_top, NEWEL))
	paint.box(Vector3(foot.x, cap_y - collar / 2.0, foot.z), Vector3(NEWEL + 0.02, collar, NEWEL + 0.02))
	stain.box(Vector3(foot.x, cap_y + NEWEL_CAP.y / 2.0, foot.z), NEWEL_CAP)
	stain.lathe(FINIAL, Vector3(foot.x, top, foot.z), BALUSTER_SIDES)


## Stäbe gleicher Länge als ein MultiMesh (ein Zeichenaufruf je Reihe), Fuß an den Stellen in spots.
static func _baluster_row(holder: Node3D, length: float, spots: Array[Transform3D]) -> void:
	if spots.is_empty():
		return
	var key := snappedf(length, 0.001)
	if not _balusters.has(key):
		var sh := Shape.new()
		var b := BALUSTER_BLOCK
		sh.box(Vector3(0, BALUSTER_LOW / 2.0, 0), Vector3(b, BALUSTER_LOW, b))
		sh.box(Vector3(0, length - BALUSTER_HIGH / 2.0, 0), Vector3(b, BALUSTER_HIGH, b))
		var turn := length - BALUSTER_LOW - BALUSTER_HIGH
		var profile := []
		for p: Vector2 in BALUSTER_TURN:
			profile.append(Vector2(p.x, p.y * turn))
		sh.lathe(profile, Vector3(0, BALUSTER_LOW, 0), BALUSTER_SIDES)
		_balusters[key] = sh.commit()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _balusters[key]
	mm.instance_count = spots.size()
	for i in spots.size():
		mm.set_instance_transform(i, spots[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = Mat.psx(PAINT)
	holder.add_child(mmi)


## Rampe zum Laufen (unten durch die Mitte der ersten Trittstufe bis auf den Boden, oben bündig mit der Galeriekante –
## lief sie dort auch durch die Trittmitten, blieb eine halbe Stufe Kante, an der Gäste hängen blieben), Trittflächen
## für Spuren, Geländer und Pfosten. Gibt die Rampe zurück.
static func _collision(holder: Node3D, width: float, run: float, rise: float, n: int, h: float, g: float,
		x_side: float, nose: Callable) -> StaticBody3D:
	var length := run + g / 2.0   # von u = −g/2 (Boden) bis u = run (Galerie)
	var angle := atan2(rise, length)
	var normal := Vector3(0, cos(angle), sin(angle))
	var ramp := StaticBody3D.new()
	ramp.collision_layer = 1
	ramp.collision_mask = 0
	ramp.set_meta("stair_ramp", true)
	ramp.transform = Transform3D(Basis(Vector3.RIGHT, normal, Vector3.RIGHT.cross(normal)),
		Vector3(0, rise / 2.0, -(run - g / 2.0) / 2.0) - normal * RAMP_T / 2.0)
	holder.add_child(ramp)
	Geo.add_box_shape(ramp, Vector3(width, RAMP_T, Vector2(length, rise).length()), Vector3.ZERO)
	var treads := StaticBody3D.new()
	treads.collision_layer = LevelBuilder.LAYER_TREAD
	treads.collision_mask = 0
	holder.add_child(treads)
	for k in range(1, n):
		Geo.add_box_shape(treads, Vector3(2.0 * x_side, 0.05, g), Vector3(0, k * h - 0.025, -(k - 0.5) * g))
	# Geländer: schräges Prisma von der Unterkante der Wange bis 1 m über die Stufen, vorn und oben senkrecht
	# abgeschnitten – ein gekippter Kasten ragte mit seiner Stirn auf Hüfthöhe 30 cm vor die Treppe, dort blieben
	# Gäste auf dem Weg ums Eck hängen
	for s: float in [-1.0, 1.0]:
		var body := StaticBody3D.new()
		body.collision_layer = 1
		body.collision_mask = 0
		holder.add_child(body)
		var points := PackedVector3Array()
		for u: float in [0.0, run]:
			for y: float in [float(nose.call(u)) - STRINGER_DOWN, float(nose.call(u)) + 1.0]:
				for dx: float in [-0.05, 0.05]:
					points.append(Vector3(s * x_side + dx, y, -u))
		var prism := ConvexPolygonShape3D.new()
		prism.points = points
		var col := CollisionShape3D.new()
		col.shape = prism
		body.add_child(col)
		Geo.collider(holder, Vector3(NEWEL_BASE.x, NEWEL_TOP, NEWEL_BASE.z), Vector3(s * x_side, NEWEL_TOP / 2.0, 0))
		Geo.collider(holder, Vector3(NEWEL, NEWEL_TOP, NEWEL), Vector3(s * x_side, rise + NEWEL_TOP / 2.0, -run))
	return ramp


## Sammelt Dreiecke für ein Mesh (ein Material). Godot zeichnet die Vorderseite im Uhrzeigersinn – jedes Dreieck
## wird so gedreht, dass sie zur angegebenen Normale zeigt. Große Flächen werden in Felder ≤ Geo.MAX_FACE geteilt.
class Shape:
	var st := SurfaceTool.new()

	func _init() -> void:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

	func tri(a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3,
			ua := Vector2.ZERO, ub := Vector2.ZERO, uc := Vector2.ZERO) -> void:
		if (b - a).cross(c - a).dot(na + nb + nc) > 0.0:
			var t := b
			b = c
			c = t
			var tn := nb
			nb = nc
			nc = tn
			var tu := ub
			ub = uc
			uc = tu
		for v in [[a, na, ua], [b, nb, ub], [c, nc, uc]]:
			st.set_normal(v[1])
			st.set_uv(v[2])
			st.add_vertex(v[0])

	## Viereck a-b-c-d (Umlaufrichtung egal) mit flacher Normale n, optional UVs je Ecke.
	func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, uv: Array = []) -> void:
		var u: Array = uv if uv.size() == 4 else [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
		tri(a, b, c, n, n, n, u[0], u[1], u[2])
		tri(a, c, d, n, n, n, u[0], u[2], u[3])

	## Viereck wie quad, in Felder ≤ Geo.MAX_FACE geteilt (bilinear zwischen den Ecken).
	func grid(a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3) -> void:
		var nu := maxi(1, ceili(maxf(a.distance_to(b), d.distance_to(c)) / Geo.MAX_FACE - 0.0001))
		var nv := maxi(1, ceili(maxf(a.distance_to(d), b.distance_to(c)) / Geo.MAX_FACE - 0.0001))
		var at := func(i: int, j: int) -> Vector3:
			var top: Vector3 = a.lerp(b, float(i) / nu)
			var bottom: Vector3 = d.lerp(c, float(i) / nu)
			return top.lerp(bottom, float(j) / nv)
		for i in nu:
			for j in nv:
				quad(at.call(i, j), at.call(i + 1, j), at.call(i + 1, j + 1), at.call(i, j + 1), n)

	## Quader (achsparallel) um center.
	func box(center: Vector3, size: Vector3) -> void:
		var hx := size.x / 2.0
		var hy := size.y / 2.0
		var hz := size.z / 2.0
		var p := func(x: float, y: float, z: float) -> Vector3: return center + Vector3(x * hx, y * hy, z * hz)
		grid(p.call(-1, 1, -1), p.call(1, 1, -1), p.call(1, 1, 1), p.call(-1, 1, 1), Vector3.UP)
		grid(p.call(-1, -1, -1), p.call(1, -1, -1), p.call(1, -1, 1), p.call(-1, -1, 1), Vector3.DOWN)
		grid(p.call(-1, -1, 1), p.call(1, -1, 1), p.call(1, 1, 1), p.call(-1, 1, 1), Vector3.BACK)
		grid(p.call(-1, -1, -1), p.call(1, -1, -1), p.call(1, 1, -1), p.call(-1, 1, -1), Vector3.FORWARD)
		grid(p.call(1, -1, -1), p.call(1, -1, 1), p.call(1, 1, 1), p.call(1, 1, -1), Vector3.RIGHT)
		grid(p.call(-1, -1, -1), p.call(-1, -1, 1), p.call(-1, 1, 1), p.call(-1, 1, -1), Vector3.LEFT)

	## Drehkörper um die senkrechte Achse durch base: profile = (Radius, Höhe) von unten nach oben, Höhe nie
	## fallend. Ringsum weich schattiert, zwischen den Profilabschnitten kantig; Deckel, wo der Radius endet.
	func lathe(profile: Array, base: Vector3, sides: int) -> void:
		var dirs: Array[Vector3] = []
		for j in sides + 1:
			var phi := TAU * j / sides + PI / sides
			dirs.append(Vector3(cos(phi), 0, sin(phi)))
		for i in profile.size() - 1:
			var p0: Vector2 = profile[i]
			var p1: Vector2 = profile[i + 1]
			var pn := Vector2(p1.y - p0.y, -(p1.x - p0.x)).normalized()
			for j in sides:
				var n0 := dirs[j] * pn.x + Vector3.UP * pn.y
				var n1 := dirs[j + 1] * pn.x + Vector3.UP * pn.y
				var a := base + dirs[j] * p0.x + Vector3.UP * p0.y
				var b := base + dirs[j + 1] * p0.x + Vector3.UP * p0.y
				var c := base + dirs[j + 1] * p1.x + Vector3.UP * p1.y
				var d := base + dirs[j] * p1.x + Vector3.UP * p1.y
				tri(a, b, c, n0, n1, n1)
				tri(a, c, d, n0, n1, n0)
		for end in [[profile[0], Vector3.DOWN], [profile[-1], Vector3.UP]]:
			var p: Vector2 = end[0]
			if p.x <= 0.0:
				continue
			var mid := base + Vector3.UP * p.y
			for j in sides:
				tri(mid, mid + dirs[j] * p.x, mid + dirs[j + 1] * p.x, end[1], end[1], end[1])

	## Gerader Strang von a nach b mit dem geschlossenen Querschnitt profile (quer waagerecht, hoch senkrecht zur
	## Richtung), entlang in Stücke ≤ Geo.MAX_FACE geteilt, Enden geschlossen.
	func sweep(profile: Array, a: Vector3, b: Vector3) -> void:
		var dir := (b - a).normalized()
		var side := dir.cross(Vector3.UP).normalized()
		var lift := side.cross(dir)
		var mid2 := Vector2.ZERO
		for p: Vector2 in profile:
			mid2 += p / profile.size()
		var at := func(p: Vector2, o: Vector3) -> Vector3: return o + side * p.x + lift * p.y
		var pieces := maxi(1, ceili(a.distance_to(b) / Geo.MAX_FACE - 0.0001))
		for k in pieces:
			var o0 := a.lerp(b, float(k) / pieces)
			var o1 := a.lerp(b, float(k + 1) / pieces)
			for i in profile.size():
				var p0: Vector2 = profile[i]
				var p1: Vector2 = profile[(i + 1) % profile.size()]
				var e := p1 - p0
				var n2 := Vector2(e.y, -e.x).normalized()
				if n2.dot((p0 + p1) / 2.0 - mid2) < 0.0:
					n2 = -n2
				quad(at.call(p0, o0), at.call(p1, o0), at.call(p1, o1), at.call(p0, o1), side * n2.x + lift * n2.y)
		for end in [[a, -dir], [b, dir]]:
			var o: Vector3 = end[0]
			for i in profile.size():
				var n: Vector3 = end[1]
				tri(at.call(mid2, o), at.call(profile[i], o), at.call(profile[(i + 1) % profile.size()], o), n, n, n)

	func commit() -> ArrayMesh:
		return st.commit()
