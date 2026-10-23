extends SceneTree
## Karten für Flecken am Boden (Blut, Wachs, Kürbismatsch – shaders/psx_decal.gdshader, TECHNIK.md „Spuren auf dem
## Boden“) aus dem Umriss einer Grafik: Neben <name>.png entstehen
##   <name>_n.png  Normal Map (OpenGL, Y nach oben) aus einer Höhe: Dicke + leichtes Rauschen
##   <name>_d.png  Detailkarte: R = Rauheit, G = Dicke (0 am Rand, 1 ab `edge` Pixeln nach innen), B = Rauschen
## Die Dicke ist der Abstand zum nächsten durchsichtigen Pixel – flüssig: steiler Rand, flache Mitte.
##
##   godot --headless --path . -s tools/splat_maps.gd -- assets/textures/blood_pool.png [schlüssel=wert …]
##       edge=8          so viele Pixel vom Rand bis zur vollen Dicke
##       rough=0.1,0.45  Rauheit in der Mitte, am Rand (nass glänzt, der Rand trocknet zuerst)
##       bump=1.0        Stärke der Normal Map (Rand und Rauschen)
##       noise=0.2       Anteil des Rauschens an Höhe und Rauheit
##       grain=6         Größe der feinsten Rauschstufe in Pixeln (dazu ×2 und ×4)
##       seed=1          Rauschen festlegen (gleiche Werte → gleiche Karten)

const DEFAULTS := {"edge": 8.0, "rough": "0.1,0.45", "bump": 1.0, "noise": 0.2, "grain": 6.0, "seed": 1}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Grafik fehlt")
		quit(1)
		return
	var opt := DEFAULTS.duplicate()
	for a in args.slice(1):
		var kv := a.split("=")
		opt[kv[0]] = kv[1] if kv.size() > 1 else ""
	var path := ProjectSettings.globalize_path("res://" + args[0].trim_prefix("res://"))
	var img := Image.load_from_file(path)
	if img == null:
		push_error("nicht lesbar: " + path)
		quit(1)
		return
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var edge := float(opt["edge"])
	var rough := String(opt["rough"]).split(",")
	var rough_mid := rough[0].to_float()
	var rough_rim := rough[1].to_float() if rough.size() > 1 else rough_mid
	var noise_k := float(opt["noise"])
	var bump := float(opt["bump"])
	var dist := _distance(img)
	var noise := _noise(w, h, float(opt["grain"]), int(opt["seed"]))
	# Höhe: Dicke (weich ansteigend) und Rauschen nur, wo Fleck ist
	var thick := PackedFloat32Array()
	var height := PackedFloat32Array()
	thick.resize(w * h)
	height.resize(w * h)
	for i in w * h:
		var t := smoothstep(0.0, 1.0, minf(1.0, dist[i] / edge))
		thick[i] = t
		height[i] = t + (noise[i] - 0.5) * noise_k * t if dist[i] > 0.0 else 0.0
	var normal := Image.create(w, h, false, Image.FORMAT_RGB8)
	var detail := Image.create(w, h, false, Image.FORMAT_RGB8)
	for y in h:
		for x in w:
			var i := y * w + x
			# Gefälle über die Nachbarn; Höhe nach unten im Bild steigt → Normale zeigt nach oben im Bild (+Y)
			var dx := height[y * w + mini(x + 1, w - 1)] - height[y * w + maxi(x - 1, 0)]
			var dy := height[mini(y + 1, h - 1) * w + x] - height[maxi(y - 1, 0) * w + x]
			var n := Vector3(-dx * bump, dy * bump, 1.0).normalized()
			normal.set_pixel(x, y, Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5))
			var r := clampf(lerpf(rough_rim, rough_mid, thick[i]) + (noise[i] - 0.5) * noise_k, 0.0, 1.0)
			detail.set_pixel(x, y, Color(r, thick[i], noise[i]))
	var base := path.get_basename()
	normal.save_png(base + "_n.png")
	detail.save_png(base + "_d.png")
	print("%s: %d × %d, Rand %.0f px, Rauheit %.2f…%.2f → _n.png, _d.png" % [args[0], w, h, edge, rough_mid, rough_rim])
	quit()


## Abstand jedes Pixels (in Pixeln) zum nächsten durchsichtigen (Alpha < 0,5) – zwei Durchläufe mit 1 und √2
## (Chamfer); durchsichtige Pixel 0, der Bildrand zählt als durchsichtig.
func _distance(img: Image) -> PackedFloat32Array:
	var w := img.get_width()
	var h := img.get_height()
	var d := PackedFloat32Array()
	d.resize(w * h)
	for y in h:
		for x in w:
			d[y * w + x] = 1e6 if img.get_pixel(x, y).a >= 0.5 else 0.0
	var steps := [[-1, 0, 1.0], [0, -1, 1.0], [-1, -1, 1.4142], [1, -1, 1.4142]]
	for pass_i in 2:
		var dir := 1 if pass_i == 0 else -1
		var ys := range(h) if dir == 1 else range(h - 1, -1, -1)
		var xs := range(w) if dir == 1 else range(w - 1, -1, -1)
		for y in ys:
			for x in xs:
				var i: int = y * w + x
				if d[i] == 0.0:
					continue
				var best := d[i]
				for s in steps:
					var nx: int = x + int(s[0]) * dir
					var ny: int = y + int(s[1]) * dir
					var nd := 0.0 if nx < 0 or ny < 0 or nx >= w or ny >= h else d[ny * w + nx]
					best = minf(best, nd + float(s[2]))
				d[i] = best
	return d


## Leichtes Rauschen 0…1: Wertrauschen in drei Stufen (grain, ×2, ×4 Pixel), weich interpoliert.
func _noise(w: int, h: int, grain: float, seed_value: int) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out := PackedFloat32Array()
	out.resize(w * h)
	var total := 0.0
	for octave in 3:
		var cell := grain * pow(2.0, octave)
		var weight := 1.0 / (octave + 1)
		total += weight
		var gw := int(ceil(w / cell)) + 2
		var gh := int(ceil(h / cell)) + 2
		var grid := PackedFloat32Array()
		grid.resize(gw * gh)
		for i in gw * gh:
			grid[i] = rng.randf()
		for y in h:
			for x in w:
				var fx := x / cell
				var fy := y / cell
				var ix := int(fx)
				var iy := int(fy)
				var tx := smoothstep(0.0, 1.0, fx - ix)
				var ty := smoothstep(0.0, 1.0, fy - iy)
				var top := lerpf(grid[iy * gw + ix], grid[iy * gw + ix + 1], tx)
				var bottom := lerpf(grid[(iy + 1) * gw + ix], grid[(iy + 1) * gw + ix + 1], tx)
				out[y * w + x] += lerpf(top, bottom, ty) * weight
	for i in w * h:
		out[i] /= total
	return out
