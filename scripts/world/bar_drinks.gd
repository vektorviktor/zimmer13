class_name BarDrinks
extends RefCounted
## Flaschen und Gläser der Bar (Spielkonzept 3.7, ZIM-35): Rotwein, Bier und Schnaps (Korn) – im Code gedreht
## (Geo.lathe, glatte Normalen), Ursprung mittig unten, Etikett nach +Z. Glas ohne Textur: glatt, fast klar bzw. grün
## und braun getönt, durchsichtig von beiden Seiten; der Inhalt (Wein, Bier mit Schaum, Korn) liegt darin und wird vor
## dem Glas gezeichnet (render_priority). Etiketten aus dem Atlas von tools/bar_labels.gd (Mat.pbr_model: Papier,
## Druck, geprägte Goldfolie mit Normal-/Rauheitskarte), Kapsel, Kronkorken und Schraubverschluss aus Metall.
## Meshes und Materialien geteilt (ein Satz je Sorte).

const LABELS := "res://assets/textures/bar_labels"
## Etikett: Breite ringsum / Höhe (= tools/bar_labels.gd LABEL_MM), Zeilen im Atlas
const LABEL_ASPECT := 140.0 / 88.0
const LABEL_ROWS := {"wein": 0, "bier": 1, "schnaps": 2}
const SIDES := 32

## Flaschen: Außenprofil (Radius, Höhe in m) von unten nach oben, Glasfarbe (Alpha = Deckung), Etikett (Unterkante,
## Höhe, Radius), Verschluss (von, bis, Radius), Farbe und Metall des Verschlusses
const BOTTLES := {
	"wein": {"profile": [Vector2(0.0, 0.006), Vector2(0.03, 0.0), Vector2(0.0365, 0.003), Vector2(0.0372, 0.012),
			Vector2(0.0372, 0.205), Vector2(0.034, 0.222), Vector2(0.024, 0.238), Vector2(0.0165, 0.25),
			Vector2(0.0148, 0.262), Vector2(0.0148, 0.292), Vector2(0.0162, 0.295), Vector2(0.0162, 0.3), Vector2(0.0, 0.3)],
		"glass": Color(0.05, 0.16, 0.07, 0.9), "label": Vector3(0.062, 0.085, 0.0372),
		"cap": Vector3(0.255, 0.301, 0.0168), "cap_color": Color(0.32, 0.04, 0.07), "cap_metal": 0.65},
	"bier": {"profile": [Vector2(0.0, 0.004), Vector2(0.026, 0.0), Vector2(0.0305, 0.003), Vector2(0.031, 0.01),
			Vector2(0.031, 0.135), Vector2(0.028, 0.152), Vector2(0.018, 0.172), Vector2(0.0135, 0.186),
			Vector2(0.0128, 0.232), Vector2(0.0142, 0.236), Vector2(0.0142, 0.243), Vector2(0.0, 0.243)],
		"glass": Color(0.22, 0.09, 0.02, 0.88), "label": Vector3(0.034, 0.072, 0.031),
		"cap": Vector3(0.237, 0.249, 0.0152), "cap_color": Color(0.78, 0.62, 0.3), "cap_metal": 1.0},
	"schnaps": {"profile": [Vector2(0.0, 0.008), Vector2(0.03, 0.0), Vector2(0.0345, 0.004), Vector2(0.035, 0.014),
			Vector2(0.035, 0.18), Vector2(0.031, 0.198), Vector2(0.019, 0.214), Vector2(0.0135, 0.226),
			Vector2(0.0128, 0.258), Vector2(0.0, 0.258)],
		"glass": Color(0.82, 0.9, 0.88, 0.16), "label": Vector3(0.05, 0.072, 0.035),
		"cap": Vector3(0.246, 0.272, 0.0142), "cap_color": Color(0.74, 0.75, 0.77), "cap_metal": 1.0,
		"liquid": 0.2},
}
## Gläser: Außenprofil, Innenraum (wo der Inhalt sitzt, von unten nach oben), Füllhöhe, Schaumkrone (Bier), Farbe des
## Inhalts (Alpha = Deckung), Größe als Gegenstand
const GLASSES := {
	"wein": {"profile": [Vector2(0.0, 0.0), Vector2(0.034, 0.0), Vector2(0.036, 0.002), Vector2(0.03, 0.004),
			Vector2(0.006, 0.008), Vector2(0.0042, 0.016), Vector2(0.0042, 0.07), Vector2(0.009, 0.08),
			Vector2(0.026, 0.092), Vector2(0.037, 0.11), Vector2(0.04, 0.13), Vector2(0.038, 0.155),
			Vector2(0.033, 0.18), Vector2(0.031, 0.192)],
		"cavity": [Vector2(0.0, 0.084), Vector2(0.024, 0.095), Vector2(0.0355, 0.112), Vector2(0.0385, 0.13)],
		"level": 0.122, "liquid": Color(0.3, 0.02, 0.05, 0.93), "size": Vector3(0.08, 0.19, 0.08)},
	"bier": {"profile": [Vector2(0.0, 0.0), Vector2(0.028, 0.0), Vector2(0.03, 0.003), Vector2(0.0315, 0.02),
			Vector2(0.036, 0.1), Vector2(0.037, 0.118), Vector2(0.034, 0.142), Vector2(0.0345, 0.152), Vector2(0.036, 0.16)],
		"cavity": [Vector2(0.0, 0.01), Vector2(0.0285, 0.01), Vector2(0.03, 0.02), Vector2(0.0345, 0.1),
			Vector2(0.0355, 0.118), Vector2(0.0325, 0.142)],
		"level": 0.132, "foam": 0.018, "liquid": Color(0.78, 0.48, 0.08, 0.82), "size": Vector3(0.075, 0.16, 0.075)},
	"schnaps": {"profile": [Vector2(0.0, 0.0), Vector2(0.018, 0.0), Vector2(0.0195, 0.002), Vector2(0.02, 0.012),
			Vector2(0.0225, 0.058), Vector2(0.0222, 0.06)],
		"cavity": [Vector2(0.0, 0.012), Vector2(0.0175, 0.012), Vector2(0.02, 0.058)],
		"level": 0.048, "liquid": Color(0.95, 0.93, 0.82, 0.2), "size": Vector3(0.045, 0.06, 0.045)},
}
const FOAM := Color(0.96, 0.93, 0.84)

static var _cache := {}


## Flasche der Sorte als Kind von parent (Ursprung mittig unten)
static func bottle(parent: Node3D, sort: String, pos := Vector3.ZERO) -> Node3D:
	var d: Dictionary = BOTTLES[sort]
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	var profile: Array = d["profile"]
	var label: Vector3 = d["label"]
	if d.has("liquid"):
		# Klarer Korn: der Inhalt füllt die Flasche bis knapp unter die Schulter
		var inner: Array = []
		for p: Vector2 in profile:
			if p.y <= float(d["liquid"]):
				inner.append(Vector2(maxf(0.0, p.x - 0.002), maxf(p.y, 0.008)))
		inner.append(Vector2(0.0, float(d["liquid"])))
		var liquid := Geo.mesh(root, _mesh("bl|" + sort, func() -> Mesh: return Geo.lathe(inner, SIDES)),
			_liquid(Color(0.95, 0.93, 0.82, 0.12)), Vector3.ZERO)
		liquid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var glass := Geo.mesh(root, _mesh("b|" + sort, func() -> Mesh: return Geo.lathe(profile, SIDES)),
		_glass(d["glass"]), Vector3.ZERO)
	if (d["glass"] as Color).a < 0.5:
		glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Geo.mesh(root, _mesh("lb|" + sort, func() -> Mesh: return _label_mesh(label.z + 0.0004, label.x, label.y, int(LABEL_ROWS[sort]))),
		Mat.pbr_model(LABELS), Vector3.ZERO)
	var cap: Vector3 = d["cap"]
	Geo.mesh(root, _mesh("c|" + sort, func() -> Mesh: return _cap_mesh(sort, cap)), _metal(d["cap_color"], float(d["cap_metal"])),
		Vector3.ZERO)
	return root


## Volles Glas der Sorte als Kind von parent (Ursprung mittig unten)
static func glass(parent: Node3D, sort: String, pos := Vector3.ZERO) -> Node3D:
	var d: Dictionary = GLASSES[sort]
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	var level := float(d["level"])
	var liquid := Geo.mesh(root, _mesh("gl|" + sort, func() -> Mesh: return Geo.lathe(_fill(d["cavity"], level), SIDES)),
		_liquid(d["liquid"]), Vector3.ZERO)
	liquid.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if d.has("foam"):
		# Schaumkrone: vom Bier bis über den Pegel, oben leicht gewölbt
		var top := level + float(d["foam"])
		var r0 := _radius_at(d["cavity"], level) - 0.0005
		var r1 := _radius_at(d["cavity"], top) - 0.0005
		var foam_profile := [Vector2(r0, level), Vector2(r1, top - 0.002), Vector2(r1 * 0.7, top), Vector2(0.0, top + 0.002)]
		Geo.mesh(root, _mesh("gf|" + sort, func() -> Mesh: return Geo.lathe(foam_profile, SIDES, 60.0)), _foam(), Vector3.ZERO)
	var shell := Geo.mesh(root, _mesh("g|" + sort, func() -> Mesh: return Geo.lathe(d["profile"], SIDES)),
		_glass(Color(0.85, 0.92, 0.92, 0.12)), Vector3.ZERO)
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return root


static func glass_size(sort: String) -> Vector3:
	return GLASSES[sort]["size"]


## Scherben eines zerbrochenen Glases (Item._shatter_glass)
static func shard_material() -> Material:
	return _glass(Color(0.85, 0.92, 0.92, 0.35))


## Innenraum bis zur Füllhöhe, oben flach geschlossen
static func _fill(cavity: Array, level: float) -> Array:
	var out: Array = []
	for p: Vector2 in cavity:
		if p.y < level:
			out.append(p)
	out.append(Vector2(_radius_at(cavity, level), level))
	out.append(Vector2(0.0, level))
	return out


## Radius des Innenraums auf Höhe y (linear zwischen den Punkten, darüber der letzte)
static func _radius_at(cavity: Array, y: float) -> float:
	for i in cavity.size() - 1:
		var a: Vector2 = cavity[i]
		var b: Vector2 = cavity[i + 1]
		if y >= a.y and y <= b.y and b.y > a.y:
			return lerpf(a.x, b.x, (y - a.y) / (b.y - a.y))
	return (cavity[-1] as Vector2).x


static func _mesh(key: String, make: Callable) -> Mesh:
	if not _cache.has(key):
		_cache[key] = make.call()
	return _cache[key]


## Etikett: Band um die Flasche (Radius r, Unterkante y0, Höhe h), mittig nach +Z; Breite ringsum nach LABEL_ASPECT.
## UVs in die Zeile row des Atlas, Tangenten für die Normal Map.
static func _label_mesh(r: float, y0: float, h: float, row: int) -> Mesh:
	var wrap := h * LABEL_ASPECT / r   # Winkel ringsum
	var segs := 24
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in segs + 1:
		var t := float(i) / segs
		var a := PI / 2.0 - wrap / 2.0 + wrap * (1.0 - t)   # links (u = 0) bis rechts, von vorn gesehen
		var n := Vector3(cos(a), 0.0, sin(a))
		for k in 2:
			st.set_normal(n)
			st.set_uv(Vector2(t, (row + (1.0 - k)) / float(LABEL_ROWS.size())))
			st.add_vertex(n * r + Vector3.UP * (y0 + h * k))
	for i in segs:
		var q := i * 2   # unten links, oben links, unten rechts, oben rechts – im Uhrzeigersinn ist vorn (Godot)
		st.add_index(q)
		st.add_index(q + 1)
		st.add_index(q + 2)
		st.add_index(q + 1)
		st.add_index(q + 3)
		st.add_index(q + 2)
	st.generate_tangents()
	return st.commit()


## Verschluss: Weinkapsel (Folie über Hals und Mündung), Kronkorken (gezackter Rand), Schraubverschluss (gerippt)
static func _cap_mesh(sort: String, cap: Vector3) -> Mesh:
	var r := cap.z
	match sort:
		"bier":
			return Geo.lathe([Vector2(r, cap.x), Vector2(r * 1.04, cap.x + 0.003), Vector2(r, cap.y - 0.002),
				Vector2(r * 0.9, cap.y), Vector2(0.0, cap.y)], 21, 50.0)
		"schnaps":
			return Geo.lathe([Vector2(r, cap.x), Vector2(r, cap.y - 0.0015), Vector2(r * 0.92, cap.y), Vector2(0.0, cap.y)], 24, 50.0)
	return Geo.lathe([Vector2(0.0158, cap.x), Vector2(0.0153, cap.x + 0.006), Vector2(0.0152, cap.y - 0.009),
		Vector2(r, cap.y - 0.006), Vector2(r, cap.y - 0.001), Vector2(r * 0.9, cap.y), Vector2(0.0, cap.y)], SIDES, 50.0)


static func _glass(tint: Color) -> StandardMaterial3D:
	var key := "glass|" + tint.to_html()
	if not _cache.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = tint
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.roughness = 0.04
		m.metallic_specular = 0.7
		m.rim_enabled = true   # Glas glänzt am Rand stärker (Fresnel)
		m.rim = 0.35
		m.rim_tint = 0.8
		_cache[key] = m
	return _cache[key]


static func _liquid(color: Color) -> StandardMaterial3D:
	var key := "liquid|" + color.to_html()
	if not _cache.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.08
		m.metallic_specular = 0.6
		m.render_priority = -1   # vor dem Glas zeichnen, das darum liegt
		_cache[key] = m
	return _cache[key]


static func _foam() -> StandardMaterial3D:
	if not _cache.has("foam"):
		var m := StandardMaterial3D.new()
		m.albedo_color = FOAM
		m.roughness = 0.85
		m.render_priority = -1
		_cache["foam"] = m
	return _cache["foam"]


static func _metal(color: Color, metal: float) -> StandardMaterial3D:
	var key := "metal|%s|%.2f" % [color.to_html(), metal]
	if not _cache.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.metallic = metal
		m.roughness = 0.32
		_cache[key] = m
	return _cache[key]
