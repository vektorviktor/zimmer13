extends SceneTree
## Fototextur-Set (PBR) für Mat.photo zuschneiden (TECHNIK.md, „Fototexturen“). Die Dateien im Ordner werden
## überschrieben bzw. gelöscht – nur auf Kopien anwenden.
##
##   godot --headless --path . -s tools/photo_set.gd -- assets/textures/<set>
##       nur prüfen: Größe und Wertebereich jeder Karte (einfarbige Karten sind leer), Format jeder Normal Map
##       (OpenGL/DirectX, aus der Höhenkarte geschätzt)
##   godot --headless --path . -s tools/photo_set.gd -- assets/textures/<set> basecolor normalogl roughness:512 [--dx]
##       behält die Karten, deren Name eines der Stichwörter enthält, verkleinert sie auf SIZE bzw. die Größe hinter
##       dem Doppelpunkt (JPEG), dreht mit --dx Grün der Normal Map um (DirectX → OpenGL, das Format von psx_photo)
##       und löscht alle übrigen Bilder samt .import
##   … basecolor normalogl --ao[=stärke]
##       backt vorher die Ambient-Occlusion-Karte ins Farbbild (Farbe × mix(1, AO, stärke), Standard 1) – für Sets,
##       deren Muster (Fugen, Relief) fast nur in AO/Normal/Height steckt: psx_photo hat keinen AO-Eingang, und im
##       PS1-Look fehlt auch die Normal Map

## = Mat.PHOTO_SIZE_SMOOTH (die große Stufe; die kleine rechnet Mat.photo beim Laden daraus)
const SIZE := 1024
const JPG_QUALITY := 0.92
const IMAGE_EXT := ["jpg", "jpeg", "png", "webp", "tga", "exr"]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("Ordner fehlt")
		quit(1)
		return
	var dir := ProjectSettings.globalize_path("res://" + args[0].trim_prefix("res://")).trim_suffix("/") + "/"
	var keep := {}   # Stichwort → Kantenlänge
	var flip := false
	var ao_strength := 0.0
	for a in args.slice(1):
		if a == "--dx":
			flip = true
		elif a.begins_with("--ao"):
			ao_strength = a.get_slice("=", 1).to_float() if a.contains("=") else 1.0
		else:
			var parts := a.to_lower().split(":")
			keep[parts[0]] = parts[1].to_int() if parts.size() > 1 else SIZE
	var files: Array[String] = []
	for f in DirAccess.get_files_at(dir):
		if f.get_extension().to_lower() in IMAGE_EXT:
			files.append(f)
	_report(dir, files)
	if keep.is_empty():
		quit()
		return
	var ao: Image
	if ao_strength > 0.0:
		for f in files:
			if _is_ao(f):
				ao = Image.load_from_file(dir + f)
				ao.convert(Image.FORMAT_RGB8)
		if ao == null:
			push_error("--ao: keine AO-Karte im Ordner")
			quit(1)
			return
	for f in files:
		var size := 0
		for k: String in keep:
			if f.to_lower().contains(k):
				size = keep[k]
		if size == 0:
			DirAccess.remove_absolute(dir + f)
			DirAccess.remove_absolute(dir + f + ".import")
			print("gelöscht  ", f)
			continue
		var img := Image.load_from_file(dir + f)
		img.convert(Image.FORMAT_RGB8)
		if img.get_width() > size or img.get_height() > size:
			img.resize(size, size, Image.INTERPOLATE_LANCZOS)
		var baked := ao != null and _is_color(f)
		if baked:
			var a := ao.duplicate() as Image
			a.resize(img.get_width(), img.get_height(), Image.INTERPOLATE_LANCZOS)
			for y in img.get_height():
				for x in img.get_width():
					img.set_pixel(x, y, img.get_pixel(x, y) * lerpf(1.0, a.get_pixel(x, y).r, ao_strength))
		var normal := _is_normal(f)
		if flip and normal:
			for y in img.get_height():
				for x in img.get_width():
					var c := img.get_pixel(x, y)
					img.set_pixel(x, y, Color(c.r, 1.0 - c.g, c.b))
		var out := dir + f.get_basename() + ".jpg"
		if out != dir + f:
			DirAccess.remove_absolute(dir + f)
		DirAccess.remove_absolute(dir + f + ".import")   # neu importieren mit Standardwerten
		img.save_jpg(out, JPG_QUALITY)
		print("behalten  ", out.get_file(), "  %d²%s%s" % [img.get_width(), "  Grün gedreht" if flip and normal else "",
			"  AO × %.2f eingebacken" % ao_strength if baked else ""])
	quit()


func _is_ao(f: String) -> bool:
	var l := f.to_lower()
	return l.contains("ambientocclusion") or l.contains("ambient_occlusion") or l.contains("_ao")


func _is_color(f: String) -> bool:
	var l := f.to_lower()
	return l.contains("basecolor") or l.contains("base_color") or l.contains("albedo") or l.contains("diffuse")


func _is_normal(f: String) -> bool:
	var l := f.to_lower()
	return l.contains("normal") or l.contains("_nor")


## Größen und Wertebereiche ausgeben und das Format jeder Normal Map schätzen: Wo die Höhe nach oben im Bild
## zunimmt, zeigt die Fläche nach unten – im OpenGL-Format ist Grün dort klein, im DirectX-Format groß.
func _report(dir: String, files: Array[String]) -> void:
	var normals := {}
	var height: Image
	for f in files:
		var img := Image.load_from_file(dir + f)
		var small := img.duplicate() as Image
		small.resize(256, 256)
		var lo := 1.0
		var hi := 0.0
		var sum := 0.0
		for y in 256:
			for x in 256:
				var v := small.get_pixel(x, y).r
				lo = minf(lo, v)
				hi = maxf(hi, v)
				sum += v
		print("%-45s %d × %d   Rot %.2f … %.2f, Mittel %.2f%s" % [f, img.get_width(), img.get_height(), lo, hi,
			sum / 65536.0, "  – einfarbig" if hi - lo < 0.02 else ""])
		var l := f.to_lower()
		if _is_normal(f):
			normals[f] = img
		elif l.contains("height") or l.contains("displacement") or l.contains("_disp"):
			height = img
	if height == null:
		return
	for f: String in normals:
		var normal: Image = normals[f]
		var h := height.duplicate() as Image
		if h.get_size() != normal.get_size():
			h.resize(normal.get_width(), normal.get_height())
		var sum := 0.0
		var step := maxi(1, normal.get_width() / 512)
		for y in range(step, normal.get_height() - step, step):
			for x in range(0, normal.get_width(), step):
				var rise_up := h.get_pixel(x, y - 1).r - h.get_pixel(x, y + 1).r   # > 0: steigt nach oben an
				sum += rise_up * (normal.get_pixel(x, y).g - 0.5)
		print("%s: %s (Maß %.1f)" % [f, "DirectX – mit --dx drehen" if sum > 0.0 else "OpenGL", sum])
