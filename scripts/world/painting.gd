class_name Painting
extends StaticBody3D
## Gemälde oder Druck im Rahmen (Planfarbe „Ausstattung: Bild“, ZIM-151): echte gemeinfreie Werke, thematisch wie
## Dorés Leviathan-Druck (Spielkonzept 4.32), ausgewählt nach der Flächenart, in der das Bild hängt. Ölbilder
## auf Leinwand (Struktur als Detail-Normal-Map) im profilierten Goldrahmen, Drucke mit Passepartout in schmalem
## Holzrahmen hinter Glas. [E] zeigt das Werk aus der Nähe. Bilder aus tools/build_paintings.gd.
## Ursprung auf der Wand, Bildseite nach +Z.

const DIR := "res://assets/textures/paintings/"
const CANVAS := DIR + "canvas_normal.png"
## Meter je Kachel der Leinwandstruktur (32 Fäden → 1,6 mm je Faden)
const CANVAS_TILE := 0.05
## lange Seite der Bildfläche je Flächenart (Meter); Drucke immer PRINT_LONG
const LONG_SIDE := {"lobby": 1.5, "bar": 1.0, "party": 1.0, "office": 1.7}
const LONG_DEFAULT := 0.75
const PRINT_LONG := 0.48
## Passepartout um den Druck (unten etwas breiter, wie üblich)
const MAT_SIDE := 0.07
const MAT_BOTTOM := 0.085
const PRINT_FRAME := 0.03
const PRINT_DEPTH := 0.03
## Flächenart → Gruppe in WORKS; alles andere hängt wie im Flur. Im Büro der Direktion nur sein Porträt.
const GROUPS := {"lobby": "lobby", "bar": "bar", "party": "bar", "corridor": "corridor", "library": "study",
	"office": "director", "secretariat": "study", "room": "room"}
## Gemeinfrei (Urheber > 70 Jahre tot), Quelle Wikimedia Commons – Dateinamen in TECHNIK.md („Gemälde“); nur das
## Porträt des alten Herrn ist eigens erstellt (ohne Maler: artist leer)
const WORKS := {
	"boecklin_toteninsel": {"group": "lobby", "artist": "Arnold Böcklin", "title": "Die Toteninsel", "year": "1880",
		"text": "Öl auf Leinwand. Ein Ruderboot gleitet über schwarzes Wasser auf eine Felseninsel zu, in deren Mitte Zypressen stehen. Vorn im Boot eine verhüllte weiße Gestalt, daneben ein Sarg. Niemand im Hotel weiß, wer das Bild hier aufgehängt hat."},
	"aivazovsky_neunte_woge": {"group": "lobby", "artist": "Iwan Aiwasowski", "title": "Die neunte Woge", "year": "1850",
		"text": "Öl auf Leinwand. Schiffbrüchige klammern sich an einen Mast, die Sonne bricht durch den Sturm. Die nächste Welle türmt sich schon. Seeleute sagen, die neunte sei immer die schwerste."},
	"maclise_snap_apple": {"group": "bar", "artist": "Daniel Maclise", "title": "Snap-Apple Night", "year": "1833",
		"text": "Öl auf Leinwand. Halloween in einer irischen Scheune: Man schnappt nach Äpfeln an Schnüren, wirft Nüsse ins Feuer und liest daraus die Zukunft. Mitten im Trubel sitzen ein paar, die nicht mitlachen."},
	"hokusai_geistergeschichten": {"group": "bar", "print": true, "artist": "Katsushika Hokusai",
		"title": "Hundert Geistergeschichten in einem Spukhaus", "year": "um 1790",
		"text": "Farbholzschnitt. Ein Haus voller Gäste, und überall sitzen Geister: auf dem Dach, am Fenster, zwischen den Leuten. Beim Spiel der hundert Geschichten löscht man nach jeder eine Kerze – bei der letzten soll einer erscheinen."},
	"friedrich_abtei": {"group": "corridor", "artist": "Caspar David Friedrich", "title": "Abtei im Eichwald",
		"year": "1810", "text": "Öl auf Leinwand. Mönche tragen einen Sarg durch einen kahlen Eichenwald zur Ruine einer Kirche. Über allem dämmert ein fahler Himmel. Ein Grab liegt offen im Schnee."},
	"dore_rabe": {"group": "corridor", "print": true, "artist": "Gustave Doré", "title": "Zu Poes „Der Rabe“",
		"year": "1884", "text": "Holzstich, letztes Blatt des Buchs. Ein Mann in einem Sessel, auf der Büste über der Tür sitzt der Rabe, und sein Schatten fällt über den ganzen Boden. Doré starb, bevor das Buch erschien."},
	"haeckel_discomedusae": {"group": "corridor", "print": true, "artist": "Ernst Haeckel",
		"title": "Discomedusae (Kunstformen der Natur, Tafel 8)", "year": "1904",
		"text": "Farblithografie. Quallen, die Fangfäden wie Haar nach unten. Haeckel hat sie nach Präparaten gezeichnet, aus Tiefen, in die kein Licht reicht."},
	"haeckel_siphonophorae": {"group": "corridor", "print": true, "artist": "Ernst Haeckel",
		"title": "Siphonophorae (Kunstformen der Natur, Tafel 7)", "year": "1904",
		"text": "Farblithografie. Staatsquallen: Jede ist eigentlich ein Schwarm, viele Tiere, die zusammen eines bilden. Eine lange Kette treibt quer über das Blatt."},
	"blake_leviathan": {"group": "study", "print": true, "artist": "William Blake", "title": "Behemoth und Leviathan",
		"year": "1825", "text": "Kupferstich aus den Illustrationen zum Buch Hiob. Oben Gott in einer Wolke, darunter auf dem Land der Behemoth, und unten in der Tiefe, in einer Kugel aus Wellen, windet sich der Leviathan. Am Rand steht: »Er ist König über alle Stolzen.«"},
	"ruisdael_friedhof": {"group": "study", "artist": "Jacob van Ruisdael", "title": "Der Judenfriedhof",
		"year": "um 1655", "text": "Öl auf Leinwand. Grabsteine unter einem Gewitterhimmel, eine Kirchenruine, ein abgestorbener Baum, ein Bach, der sich durch die Gräber zieht. Ganz hinten ein Regenbogen."},
	"portraet_frau": {"group": "study", "artist": "Umkreis des Harmen de Bye", "title": "Bildnis einer Dame",
		"year": "um 1675", "text": "Öl auf Leinwand. Eine Dame in heller Seide vor rotem Vorhang, eine Blume in der Hand. Ihr Blick folgt einem, wohin man auch geht – das sagt man von vielen alten Bildern."},
	"portraet_mann": {"group": "study", "artist": "Unbekannter Maler", "title": "Bildnis eines Herrn", "year": "um 1600",
		"text": "Öl auf Leinwand. Ein Herr in Schwarz mit weißem Kragen. Wer er war, weiß niemand mehr, auch nicht, wie er ins Hotel kam."},
	"portraet_alter_herr": {"group": "director", "artist": "", "title": "Der alte Herr", "year": "unsigniert, um 1985",
		"text": "Öl auf Leinwand. Ein alter Herr thront im roten Ledersessel – demselben, der unten vor dem Schreibtisch steht. Die Hände ruhen auf einem Stock mit silbernem Schlangenkopf, neben ihm liegt ein Vertrag mit rotem Siegel. Er lächelt, als wüsste er etwas über einen. Das Gesicht kommt einem bekannt vor."},
	"fuessli_nachtmahr": {"group": "room", "artist": "Johann Heinrich Füssli", "title": "Der Nachtmahr", "year": "1781",
		"text": "Öl auf Leinwand. Eine Schlafende liegt hingestreckt auf dem Bett, auf ihrer Brust hockt ein Dämon, aus dem Vorhang schiebt sich der Kopf eines Pferdes. Ausgerechnet über einem Hotelbett."},
	"friedrich_mond": {"group": "room", "artist": "Caspar David Friedrich", "title": "Zwei Männer in Betrachtung des Mondes",
		"year": "1819", "text": "Öl auf Leinwand. Zwei Männer stehen im Abend an einem entwurzelten Baum und schauen auf die Mondsichel. Man sieht ihre Gesichter nicht."},
	"grimshaw_roundhay": {"group": "room", "artist": "John Atkinson Grimshaw",
		"title": "Mondlicht am See, Roundhay Park", "year": "um 1870",
		"text": "Öl auf Leinwand. Ein Weg an einem See im Mondlicht, kahle Bäume, ein nasser Zaun. Niemand ist unterwegs."},
}

var key := ""
static var _textures := {}
static var _canvas: Texture2D
static var _gold_mat: StandardMaterial3D


## Gruppe für eine Flächenart (GROUPS)
static func group_for(area: String) -> String:
	return GROUPS.get(area, "corridor")


## n-tes Werk der Gruppe (reihum), nur solche, deren Bild vorhanden ist; "" wenn keins
static func pick(group: String, n: int) -> String:
	var keys := WORKS.keys().filter(func(k: String) -> bool:
		return WORKS[k]["group"] == group and ResourceLoader.exists(DIR + k + ".jpg"))
	return "" if keys.is_empty() else String(keys[n % keys.size()])


static func texture(work: String) -> Texture2D:
	if not _textures.has(work):
		_textures[work] = _mipmapped(DIR + work + ".jpg", false)
	return _textures[work]


static func _mipmapped(path: String, normal: bool) -> ImageTexture:
	var img := (load(path) as Texture2D).get_image()
	img.decompress()
	img.generate_mipmaps(normal)
	return ImageTexture.create_from_image(img)


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	add_to_group("paintings")
	set_meta("interactable", self)


## Baut das Bild; area = Flächenart (bestimmt die Größe der Ölbilder)
func setup(work: String, area: String) -> Painting:
	key = work
	var tex := texture(work)
	var aspect := float(tex.get_width()) / tex.get_height()
	var is_print: bool = WORKS[work].get("print", false)
	var long: float = PRINT_LONG if is_print else LONG_SIDE.get(area, LONG_DEFAULT)
	var size := Vector2(long, long / aspect) if aspect >= 1.0 else Vector2(long * aspect, long)
	if is_print:
		_build_print(tex, size)
	else:
		_build_oil(tex, size)
	return self


## Leinwand im Goldrahmen: drei Stufen, die nach innen zur Leinwand hin abfallen
func _build_oil(tex: Texture2D, size: Vector2) -> void:
	var fw := clampf(maxf(size.x, size.y) * 0.09, 0.06, 0.13)
	var depth := 0.065
	var gold := _gold()
	var steps: Array[Vector3] = [Vector3(0.0, 0.45, 1.0), Vector3(0.45, 0.8, 0.78), Vector3(0.8, 1.0, 0.55)]   # von außen: Anteil von fw (von, bis), Höhe
	for s in steps:
		var outer := size + Vector2.ONE * fw * (1.0 - s.x) * 2.0
		var inner := size + Vector2.ONE * fw * (1.0 - s.y) * 2.0
		_ring(outer, inner, depth * s.z, gold)
	var canvas := _canvas_material(tex, size, 0.55, 1.0)
	Geo.mesh(self, _quad(size, size / CANVAS_TILE), canvas, Vector3(0, 0, 0.022))
	var back := size + Vector2.ONE * fw * 2.0
	Geo.add_box_shape(self, Vector3(back.x, back.y, depth), Vector3(0, 0, depth / 2.0))


## Druck: Papier auf Passepartout, schmaler dunkler Holzrahmen, Glas davor
func _build_print(tex: Texture2D, size: Vector2) -> void:
	var board := size + Vector2(MAT_SIDE * 2.0, MAT_SIDE + MAT_BOTTOM)
	var mid := Vector3(0, (MAT_BOTTOM - MAT_SIDE) / 2.0, 0)   # Bild sitzt etwas über der Mitte des Passepartouts
	var outer := board + Vector2.ONE * PRINT_FRAME * 2.0
	_ring(outer, board, PRINT_DEPTH, Mat.hotel_wood(), -mid)
	var cream := StandardMaterial3D.new()
	cream.albedo_color = Color(0.86, 0.83, 0.76)
	cream.roughness = 0.95
	Geo.mesh(self, Geo.box(Vector3(board.x, board.y, 0.004)), cream, Vector3(0, 0, 0.012) - mid)
	Geo.mesh(self, _quad(size, size / CANVAS_TILE), _canvas_material(tex, size, 0.9, 0.12), Vector3(0, 0, 0.0145))
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(1, 1, 1, 0.06)
	glass.roughness = 0.04
	glass.metallic_specular = 0.6
	Geo.mesh(self, _quad(board, Vector2.ONE), glass, Vector3(0, 0, 0.022) - mid)
	Geo.add_box_shape(self, Vector3(outer.x, outer.y, PRINT_DEPTH), Vector3(0, 0, PRINT_DEPTH / 2.0) - mid)


## Rahmenleisten zwischen zwei Rechtecken (oben/unten über die volle Breite, Seiten dazwischen)
func _ring(outer: Vector2, inner: Vector2, depth: float, mat: Material, at := Vector3.ZERO) -> void:
	var w := (outer - inner) / 2.0
	for side in [-1.0, 1.0]:
		Geo.mesh(self, Geo.box(Vector3(outer.x, w.y, depth)), mat, at + Vector3(0, side * (inner.y + w.y) / 2.0, depth / 2.0))
		Geo.mesh(self, Geo.box(Vector3(w.x, inner.y, depth)), mat, at + Vector3(side * (inner.x + w.x) / 2.0, 0, depth / 2.0))


## Bild auf UV, Leinwand- bzw. Papierstruktur als Detail-Normal-Map auf UV2 (gekachelt)
func _canvas_material(tex: Texture2D, size: Vector2, roughness: float, weave: float) -> StandardMaterial3D:
	if _canvas == null:
		_canvas = _mipmapped(CANVAS, true)
	var m := StandardMaterial3D.new()
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT
	m.albedo_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.roughness = roughness
	m.detail_enabled = true
	m.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
	m.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL   # ohne Detailbild weiß → Farbe bleibt
	m.detail_normal = _canvas
	m.normal_enabled = true
	m.normal_scale = weave
	return m


## Blattgold: warmes Metall, leicht fleckige Rauheit und Riefen aus Rauschen (mit Mipmaps)
func _gold() -> StandardMaterial3D:
	if _gold_mat == null:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.62, 0.46, 0.22)
		m.metallic = 0.85
		m.roughness = 1.0
		var rough := NoiseTexture2D.new()
		rough.width = 512
		rough.height = 512
		rough.seamless = true
		rough.generate_mipmaps = true
		rough.noise = FastNoiseLite.new()
		rough.noise.frequency = 0.03
		rough.color_ramp = Gradient.new()
		rough.color_ramp.set_color(0, Color(0.25, 0.25, 0.25))
		rough.color_ramp.set_color(1, Color(0.6, 0.6, 0.6))
		m.roughness_texture = rough
		var bump := NoiseTexture2D.new()
		bump.width = 512
		bump.height = 512
		bump.seamless = true
		bump.as_normal_map = true
		bump.bump_strength = 4.0
		bump.generate_mipmaps = true
		bump.noise = FastNoiseLite.new()
		bump.noise.frequency = 0.08
		m.normal_enabled = true
		m.normal_texture = bump
		m.normal_scale = 0.3
		m.uv1_triplanar = true
		m.uv1_scale = Vector3.ONE * 6.0
		_gold_mat = m
	return _gold_mat


## Rechteck in der XY-Ebene nach +Z, UV über das ganze Bild, UV2 = uv2_tiles Kacheln
func _quad(size: Vector2, uv2_tiles: Vector2) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := size / 2.0
	var corners := [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]
	var verts := []
	for c in corners:
		verts.append([Vector3(c.x * h.x, c.y * h.y, 0), Vector2((c.x + 1) / 2.0, (1 - c.y) / 2.0)])
	for i in [0, 2, 1, 0, 3, 2]:   # im Uhrzeigersinn von vorn
		st.set_normal(Vector3.BACK)
		st.set_uv(verts[i][1])
		st.set_uv2(verts[i][1] * uv2_tiles)
		st.add_vertex(verts[i][0])
	st.generate_tangents()
	return st.commit()


## --bilder[=gruppe]: vor das erste Bild aus dem Plan; hängt keins (oder mit Gruppe lobby, bar, corridor, study,
## room, director bzw. alle), kommen die Werke als Reihe frei in die Lobby, du stehst davor.
static func debug_show(tree: SceneTree, group: String) -> void:
	var hung := tree.get_nodes_in_group("paintings")
	if group == "" and not hung.is_empty():
		var first: Painting = hung[0]
		var forward := first.global_basis.z
		TeleportUI.place_player(first.global_position + forward * 2.2 + Vector3.DOWN * 1.6, -forward)
		return
	var works := WORKS.keys().filter(func(k: String) -> bool:
		return (group in ["", "alle"] or WORKS[k]["group"] == group) and ResourceLoader.exists(DIR + k + ".jpg"))
	if works.is_empty():
		push_warning("--bilder: keine Werke in Gruppe „%s“" % group)
		return
	var area: String = {"lobby": "lobby", "bar": "bar", "director": "office"}.get(group, "")
	var row: Array[Painting] = []
	var width := 0.0
	for k in works:
		var p := Painting.new().setup(k, area)
		tree.current_scene.add_child(p)
		row.append(p)
		width += _width(p) + 0.4
	var center: Vector3 = Game.social.builder.lobby_center
	var x := -width / 2.0
	for p in row:
		var w := _width(p)
		p.global_position = center + Vector3(x + w / 2.0 + 0.2, 1.7, 0)
		x += w + 0.4
	TeleportUI.place_player(center + Vector3(0, 0, minf(width * 0.45, 7.0) + 2.0), Vector3.FORWARD)


static func _width(p: Painting) -> float:
	var w := 0.0
	for c in p.get_children():
		if c is CollisionShape3D:
			w = maxf(w, ((c as CollisionShape3D).shape as BoxShape3D).size.x)
	return w


func get_prompt(_player: Player) -> String:
	if Game.sealed_rooms and Game.sealed_rooms.frame_ready(self):   # hat man den Brief aus 038 gelesen (6.19 (7))
		return "Hinter dem Rahmen tasten [E]"
	return "Bild ansehen [E] – %s" % WORKS[key]["title"]


func interact(player: Player) -> void:
	if Game.sealed_rooms and Game.sealed_rooms.frame_ready(self):
		Game.sealed_rooms.take_frame_key(player)
		return
	var w: Dictionary = WORKS[key]
	if Game.menus:
		var title: String = w["title"] if w["artist"] == "" else "%s: %s" % [w["artist"], w["title"]]
		Game.menus.open_photo(title, texture(key), "%s, %s" % [w["year"], w["text"]])
