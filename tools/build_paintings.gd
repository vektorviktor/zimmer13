extends SceneTree
## Gemälde und Drucke für die Bilderrahmen (Painting, ZIM-151): verkleinert die Originale von Wikimedia Commons auf
## höchstens SIZE an der langen Seite und legt sie als JPEG nach assets/textures/paintings/<name>.jpg. Dazu die
## Leinwandstruktur canvas_normal.png (kachelbar, Köperbindung) für die Ölbilder.
##
##   godot --headless --path . -s tools/build_paintings.gd -- <ordner mit den Originalen>
##       jede Datei <name>.jpg/.png im Ordner wird übernommen, der Name bleibt (Schlüssel in Painting.WORKS)
##   godot --headless --path . -s tools/build_paintings.gd -- --canvas
##       nur die Leinwandstruktur neu

const OUT := "res://assets/textures/paintings/"
const SIZE := 2048
const JPG_QUALITY := 0.9
## Leinwand: Kachel in Pixeln und Fäden je Kachel (Painting.CANVAS_TILE Meter je Kachel)
const CANVAS_PX := 512
const CANVAS_THREADS := 32
## Museumsscans mit Rahmenkante oder schwarzem Rand: so viel (Anteil je Seite) wird rundum abgeschnitten
const CROP := {"boecklin_toteninsel": 0.016, "fuessli_nachtmahr": 0.012, "portraet_frau": 0.016,
	"portraet_mann": 0.016}


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	if args.is_empty() or args[0] == "--canvas":
		_canvas()
		quit()
		return
	var src := args[0].trim_suffix("/") + "/"
	for file in DirAccess.get_files_at(src):
		if file.get_extension().to_lower() not in ["jpg", "jpeg", "png"]:
			continue
		var img := Image.load_from_file(src + file)
		if img == null:
			push_error("nicht lesbar: " + file)
			continue
		img.convert(Image.FORMAT_RGB8)
		var cut: float = CROP.get(file.get_basename(), 0.0)
		if cut > 0.0:
			var m := Vector2i(Vector2(img.get_size()) * cut)
			img = img.get_region(Rect2i(m, img.get_size() - m * 2))
		var long := maxi(img.get_width(), img.get_height())
		if long > SIZE:
			var f := float(SIZE) / long
			img.resize(roundi(img.get_width() * f), roundi(img.get_height() * f), Image.INTERPOLATE_LANCZOS)
		var out := OUT + file.get_basename() + ".jpg"
		img.save_jpg(ProjectSettings.globalize_path(out), JPG_QUALITY)
		print("%s  %d×%d" % [out, img.get_width(), img.get_height()])
	_canvas()
	quit()


## Höhe der Leinwand: Köper aus Kett- und Schussfäden, jeder Faden rund gewölbt, leicht unregelmäßig dick;
## daraus die Normal Map (OpenGL, Grün nach oben).
func _canvas() -> void:
	var n := CANVAS_PX
	var cell := float(n) / CANVAS_THREADS
	var noise := FastNoiseLite.new()
	noise.seed = 13
	noise.frequency = 0.02
	var h := PackedFloat32Array()
	h.resize(n * n)
	for y in n:
		for x in n:
			var cx := int(x / cell)
			var cy := int(y / cell)
			var u := fposmod(x / cell, 1.0)
			var v := fposmod(y / cell, 1.0)
			# oben liegt im Wechsel Kette oder Schuss (Leinwandbindung)
			var warp_up := (cx + cy) % 2 == 0
			var warp := sin(u * PI)          # Kettfaden quer gewölbt
			var weft := sin(v * PI)          # Schussfaden
			var t := warp * (0.6 + 0.4 * sin(v * PI)) if warp_up else weft * (0.6 + 0.4 * sin(u * PI))
			h[y * n + x] = t + 0.15 * noise.get_noise_2d(x, y)
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	var strength := 2.5
	for y in n:
		for x in n:
			var dx := h[y * n + (x + 1) % n] - h[y * n + (x - 1 + n) % n]
			var dy := h[((y + 1) % n) * n + x] - h[((y - 1 + n) % n) * n + x]
			var nv := Vector3(-dx * strength, dy * strength, 1.0).normalized()
			img.set_pixel(x, y, Color(nv.x * 0.5 + 0.5, nv.y * 0.5 + 0.5, nv.z * 0.5 + 0.5))
	img.save_png(ProjectSettings.globalize_path(OUT + "canvas_normal.png"))
	print(OUT + "canvas_normal.png")
