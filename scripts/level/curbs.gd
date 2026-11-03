class_name Curbs
## Randsteine an den Kieswegen (ZIM-173, Spielkonzept 7.10): überall, wo Kies an Rasen stößt, eine Reihe einzelner
## Granitsteine auf der Rasenseite (der Weg bleibt so breit wie im Plan). Jeder Stein etwas anders lang, mit Fuge,
## leicht verkippt und verschieden hoch, einzelne abgesackt – alt, nicht frisch verlegt. An Außenecken läuft der
## Stein entlang x durch, an Innenecken endet der entlang z an ihm. Ohne Kollision (so niedrig, dass man darüber
## hinwegsteigt), nicht im NavMesh; je Kachel ein Mesh.

const WIDTH := 0.12                   ## Breite (m)
const RISE := 0.07                    ## so weit über den Kies
const DEPTH := 0.1                    ## so tief darunter (verdeckt Lücken beim Verkippen)
const LENGTH := Vector2(0.5, 1.0)     ## Länge eines Steins von … bis
const JOINT := 0.008                  ## Fuge
const JITTER_RISE := 0.012            ## Höhe ± (m)
const JITTER_TILT := 1.5              ## Neigung ± (Grad, quer und längs)
const JITTER_YAW := 0.6               ## Drehung ± (Grad)
const SUNK_CHANCE := 0.07             ## Anteil abgesackter Steine
const SUNK_DROP := Vector2(0.025, 0.05)
const SUNK_TILT := 4.0
const SAMPLE := 0.1                   ## Schritt entlang der Kieskante (= Auflösung des Plans)
const CHUNK := 16.0
const SEED := 1730

static var count := 0                 ## gebaute Steine (für --trace)


## Steine an allen Kanten Kies ↔ Rasen bauen.
static func build(builder: LevelBuilder, parent: Node3D, gravel: Array[Rect2], mat: Material) -> void:
	var along_x: Array[Dictionary] = []   # {a, b (x), line (z der Kieskante), out (±1 Richtung Rasen)}
	var along_z: Array[Dictionary] = []
	for r in gravel:
		for side in 4:
			var horizontal := side < 2
			var out := -1.0 if side % 2 == 0 else 1.0
			var line: float
			var from: float
			var to: float
			if horizontal:
				line = r.position.y if out < 0.0 else r.end.y
				from = r.position.x
				to = r.end.x
			else:
				line = r.position.x if out < 0.0 else r.end.x
				from = r.position.y
				to = r.end.y
			var run_start := NAN
			var t := from
			while t < to - 0.001:
				var mid := t + SAMPLE / 2.0
				var q := Vector2(mid, line + out * 0.05) if horizontal else Vector2(line + out * 0.05, mid)
				var lawn := builder.is_lawn(q)
				if lawn and is_nan(run_start):
					run_start = t
				elif not lawn and not is_nan(run_start):
					(along_x if horizontal else along_z).append({"a": run_start, "b": t, "line": line, "out": out})
					run_start = NAN
				t += SAMPLE
			if not is_nan(run_start):
				(along_x if horizontal else along_z).append({"a": run_start, "b": to, "line": line, "out": out})
	# Außenecken: Stein entlang x bis über die Ecke, wenn dort ein Stein entlang z anschließt
	for h in along_x:
		for v in along_z:
			var band := Vector2(v["line"], v["line"] + v["out"] * WIDTH)
			var touches_z: bool = absf(float(v["a"]) - h["line"]) < 0.01 or absf(float(v["b"]) - h["line"]) < 0.01
			if not touches_z:
				continue
			if absf(float(h["b"]) - band.x) < 0.01 and band.y > band.x:
				h["b"] = band.y
			elif absf(float(h["a"]) - band.x) < 0.01 and band.y < band.x:
				h["a"] = band.y
	# Innenecken und Kreuzungen: Steine entlang z enden an denen entlang x
	var cut_z: Array[Dictionary] = []
	for v in along_z:
		var pieces: Array[Vector2] = [Vector2(v["a"], v["b"])]
		var x_band := Vector2(minf(v["line"], v["line"] + v["out"] * WIDTH), maxf(v["line"], v["line"] + v["out"] * WIDTH))
		for h in along_x:
			if float(h["b"]) <= x_band.x + 0.001 or float(h["a"]) >= x_band.y - 0.001:
				continue
			var z_band := Vector2(minf(h["line"], h["line"] + h["out"] * WIDTH), maxf(h["line"], h["line"] + h["out"] * WIDTH))
			var next: Array[Vector2] = []
			for piece in pieces:
				if z_band.y <= piece.x or z_band.x >= piece.y:
					next.append(piece)
					continue
				if z_band.x > piece.x:
					next.append(Vector2(piece.x, z_band.x))
				if z_band.y < piece.y:
					next.append(Vector2(z_band.y, piece.y))
			pieces = next
		for piece in pieces:
			if piece.y - piece.x > 0.05:
				cut_z.append({"a": piece.x, "b": piece.y, "line": v["line"], "out": v["out"]})
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var tools := {}   # Vector2i → SurfaceTool
	var box := BoxMesh.new()
	for h in along_x:
		_row(tools, box, rng, h, true)
	for v in cut_z:
		_row(tools, box, rng, v, false)
	var holder := Node3D.new()
	holder.name = "Randsteine"
	parent.add_child(holder)
	for key: Vector2i in tools:
		var st: SurfaceTool = tools[key]
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		mi.material_override = mat
		holder.add_child(mi)
	if Game.tracing:
		print("[Randsteine] %d Steine an %d Kanten" % [count, along_x.size() + cut_z.size()])


## Eine Reihe Steine von a bis b an der Kieskante line, zur Rasenseite out.
static func _row(tools: Dictionary, box: BoxMesh, rng: RandomNumberGenerator, run: Dictionary, horizontal: bool) -> void:
	var a: float = run["a"]
	var b: float = run["b"]
	var length := b - a
	var n := maxi(1, roundi(length / ((LENGTH.x + LENGTH.y) / 2.0)))
	var parts := PackedFloat32Array()
	var total := 0.0
	for i in n:
		parts.append(rng.randf_range(0.8, 1.2))
		total += parts[i]
	var cross: float = float(run["line"]) + float(run["out"]) * WIDTH / 2.0
	var t := a
	for i in n:
		var l := length * parts[i] / total
		var top := RISE + rng.randf_range(-JITTER_RISE, JITTER_RISE)
		var tilt_cross := rng.randf_range(-JITTER_TILT, JITTER_TILT)
		var tilt_along := rng.randf_range(-JITTER_TILT, JITTER_TILT) * 0.5
		if rng.randf() < SUNK_CHANCE:
			top -= rng.randf_range(SUNK_DROP.x, SUNK_DROP.y)
			tilt_cross += SUNK_TILT * (1.0 if rng.randf() < 0.5 else -1.0)
		var yaw := rng.randf_range(-JITTER_YAW, JITTER_YAW)
		var size := Vector3(maxf(0.05, l - JOINT), top + DEPTH, WIDTH)
		var mid := t + l / 2.0
		var center := Vector3(mid, top - size.y / 2.0, cross) if horizontal else Vector3(cross, top - size.y / 2.0, mid)
		var basis := Basis.from_euler(Vector3(deg_to_rad(tilt_cross), deg_to_rad(yaw), deg_to_rad(tilt_along)))
		if not horizontal:
			basis = Basis(Vector3.UP, PI / 2.0) * basis
		var key := Vector2i(floori(center.x / CHUNK), floori(center.z / CHUNK))
		if not tools.has(key):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			tools[key] = st
		box.size = size   # Maß in der Box, nicht in der Drehung – sonst stimmen die Normalen nicht
		(tools[key] as SurfaceTool).append_from(box, 0, Transform3D(basis, center))
		count += 1
		t += l
