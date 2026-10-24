class_name PocketMap
extends Node3D
## Die eingesteckten Kartenblätter in der linken Hand (Tab halten, Spielkonzept 3.2): das
## oberste Blatt ist zu sehen, dahinter stehen die Kanten der übrigen hervor, oben links eine
## Büroklammer. Das letzte Blatt listet den Schlüsselbund. Steht senkrecht, Bildseite +Z
## (zur Kamera), Norden oben (+Y).
## Mit dem Notizbuch (3.10) liegen die Blätter darin: Einband dahinter, rechts Reiter für die Lesezeichen Karte,
## Aufgaben, Notizen und – sobald man eine Bedrohung gesehen hat – Gesehen (NotebookPage). Mausrad/Linksklick blättern durch das ganze Buch, next_bookmark (Rechtsklick)
## springt zum nächsten Lesezeichen auf die Seite, auf der man dort zuletzt war. Kommt etwas Neues dazu, steht das
## Lesezeichen auf der letzten Seite. Seiten des Notizbuchs werden erst beim Ansehen gerendert (je eine Textur).

const KEYS := "keys"   ## Seiten-ID des Schlüsselblatts
const MAX_EDGES := 3
const BOOKMARK_ORDER := ["map", "tasks", "notes", "threats"]
const COVER := Color(0.24, 0.12, 0.08)

## Seiten in Blätter-Reihenfolge: Kartenblätter (HotelMap.PAGES), ggf. KEYS, dann "tasks:0" …, "notes:0" … und
## "threats:0"
var pages: Array[String] = []
var index := 0

var _height := 0.0
var _sheet: MeshInstance3D
var _edges: Array[MeshInstance3D] = []
var _clip: Array[MeshInstance3D] = []
var _cover: MeshInstance3D
var _tabs := {}               ## Lesezeichen → Reiter (MeshInstance3D)
var _counter: Label3D
var _keys_title: Label3D
var _keys_list: Label3D
var _note_material: Material
var _map_pages: Array[String] = []   ## ohne Notizbuch: nur diese (Karte und Schlüssel)
## Notizbuch: gesetzte Seiten je Lesezeichen (NotebookPage.paginate), gesehener Stand, zuletzt gewählte Seite
var _layout := {"tasks": [[]], "notes": [[]], "threats": [[]]}
var _revision := {"tasks": -1, "notes": -1, "threats": -1}
var _remember := {"map": "", "tasks": "", "notes": "", "threats": ""}
var _owned := false
var _textures := {}           ## Seiten-ID → Texture2D
var _materials := {}          ## Seiten-ID → StandardMaterial3D
var _rendering := {}          ## Seiten-ID → true, solange sie gerendert wird


func _ready() -> void:
	var w := Item.MAP_WIDTH
	_height = w * HotelMap.PAGE_SIZE.y / HotelMap.PAGE_SIZE.x
	var quad := QuadMesh.new()
	quad.size = Vector2(w, _height)
	_sheet = Geo.mesh(self, quad, null, Vector3.ZERO)
	_note_material = HotelMap.paper_material(HotelMap.NOTE_PAPER)
	# Kanten der Blätter dahinter: je etwas versetzt und dunkler
	for k in MAX_EDGES:
		var edge := Geo.mesh(self, quad, Mat.psx(HotelMap.PAPER.darkened(0.12 + 0.08 * k)),
			Vector3(0.004 * (k + 1), -0.003 * (k + 1), -0.0008 * (k + 1)))
		edge.rotation.z = 0.012 * (k + 1) * (1.0 if k % 2 == 0 else -1.0)
		_edges.append(edge)
	# Büroklammer oben links
	var wire := Mat.psx(Color(0.6, 0.62, 0.65))
	_clip.append(Geo.mesh(self, Geo.box(Vector3(0.0012, 0.016, 0.0008)), wire, Vector3(-w / 2.0 + 0.008, _height / 2.0 - 0.002, 0.0008)))
	_clip.append(Geo.mesh(self, Geo.box(Vector3(0.0012, 0.012, 0.0008)), wire, Vector3(-w / 2.0 + 0.0125, _height / 2.0, 0.0008)))
	_clip.append(Geo.mesh(self, Geo.box(Vector3(0.0057, 0.0012, 0.0008)), wire, Vector3(-w / 2.0 + 0.01025, _height / 2.0 + 0.006, 0.0008)))
	# Notizbuch: Einband dahinter und drei Reiter am rechten Rand (im sichtbaren Ausschnitt, NotebookPage)
	_cover = Geo.mesh(self, Geo.box(Vector3(w + 0.018, _height + 0.014, 0.006)), Mat.psx(COVER), Vector3(0.002, -0.002, -0.0065))
	for i in BOOKMARK_ORDER.size():
		var id: String = BOOKMARK_ORDER[i]
		var tab := Geo.mesh(self, Geo.box(Vector3(0.024, 0.028, 0.0003)), Mat.psx(NotebookPage.BOOKMARKS[id]["color"]),
			Vector3(w / 2.0, 0.062 - 0.036 * i, -0.0004))   # zwischen Blatt und den Kanten dahinter
		_tabs[id] = tab
	_counter = _label(18, HotelMap.INK, Vector3(w / 2.0 - 0.03, -_height / 2.0 + 0.008, 0.0006))
	_keys_title = _label(30, HotelMap.INK, Vector3(-w / 2.0 + 0.02, _height / 2.0 - 0.02, 0.0006))
	_keys_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_keys_title.text = "Schlüsselbund"
	_keys_list = _label(22, HotelMap.INK, Vector3(-w / 2.0 + 0.03, _height / 2.0 - 0.035, 0.0006))
	_keys_list.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_keys_list.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_refresh()


## Inhalt setzen: eingesteckte Kartenblätter und Schlüssel
func set_content(map_pages: Array[String], keys: Array[String]) -> void:
	_map_pages.clear()
	for page in HotelMap.PAGES:
		if page["id"] in map_pages:
			_map_pages.append(page["id"])
	if not keys.is_empty():
		_map_pages.append(KEYS)
		var lines: PackedStringArray = []
		for id in keys:
			lines.append("–  " + Item.key_label(id))
		_keys_list.text = "\n".join(lines)
	_rebuild()


## Hat das Notizbuch etwas Neues (oder kam es gerade dazu)? Dann die Seiten neu setzen.
func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		return
	var book := Game.notebook
	var owned := book != null and book.owned
	if owned != _owned or (owned and (book.tasks_revision != _revision["tasks"] or book.notes_revision != _revision["notes"]
			or book.seen_revision != _revision["threats"])):
		_rebuild()


func _rebuild() -> void:
	var current := pages[index] if index < pages.size() else ""
	var book := Game.notebook
	_owned = book != null and book.owned
	pages.assign(_map_pages)
	if _owned:
		for kind in ["tasks", "notes"]:
			var revision: int = book.tasks_revision if kind == "tasks" else book.notes_revision
			if revision != _revision[kind]:
				_revision[kind] = revision
				_layout[kind] = NotebookPage.paginate(kind, book.tasks if kind == "tasks" else book.notes)
				_remember[kind] = "%s:%d" % [kind, _layout[kind].size() - 1]   # Neues steht hinten
				_drop_textures(kind)
			for i in (_layout[kind] as Array).size():
				pages.append("%s:%d" % [kind, i])
		# Gesehen: eine Seite mit den Bildern (NotebookPage), erst nach der ersten Bedrohung
		if book.seen_revision != _revision["threats"]:
			_revision["threats"] = book.seen_revision
			var rows: Array = []
			for id in IconArt.THREAT_ORDER:
				if book.seen.has(id):
					rows.append({"id": id, "at": float(book.seen[id])})
			_layout["threats"] = [rows]
			_remember["threats"] = "threats:0"
			_drop_textures("threats")
		if not book.seen.is_empty():
			pages.append("threats:0")
	index = maxi(0, pages.find(current))
	_refresh()


## Beim Hervorholen: das Blatt der Ebene, auf der man steht, liegt oben (falls vorhanden) – ohne Karte die Aufgaben.
func open_at(page_id: String) -> void:
	_rebuild()
	var i := pages.find(page_id)
	if i < 0 and not _map_pages.is_empty():
		i = 0
	if i < 0:
		i = pages.find(_remember["tasks"])
	index = maxi(0, i)
	_refresh()


## Debug (--show=aufgaben|notizen) und Rechtsklick: Lesezeichen aufschlagen, auf seiner zuletzt gewählten Seite.
func open_bookmark(id: String) -> void:
	_rebuild()
	var target: String = _remember.get(id, "")
	if id == "map" and target == "" and not _map_pages.is_empty():
		target = _map_pages[0]
	var i := pages.find(target)
	if i >= 0:
		index = i
		_refresh()


func next_bookmark() -> void:
	if pages.is_empty():
		return
	var here := _bookmark_of(pages[index])
	var order: Array = BOOKMARK_ORDER.filter(func(b: String) -> bool: return _has_bookmark(b))
	if order.size() < 2:
		return
	open_bookmark(order[(order.find(here) + 1) % order.size()])
	if Game.player:
		Game.noise("map", Game.player.global_position, Game.player)


func flip(step: int) -> void:
	if pages.size() < 2:
		return
	index = posmod(index + step, pages.size())
	_refresh()
	if Game.player:
		Game.noise("map", Game.player.global_position, Game.player)


## Lesezeichen der Seite, die gerade oben liegt ("map", "tasks", "notes").
func bookmark() -> String:
	return _bookmark_of(pages[index]) if index < pages.size() else "map"


func _bookmark_of(page_id: String) -> String:
	return page_id.get_slice(":", 0) if ":" in page_id else "map"


func _has_bookmark(id: String) -> bool:
	if id == "threats":
		return _owned and not Game.notebook.seen.is_empty()
	return not _map_pages.is_empty() if id == "map" else _owned


func _refresh() -> void:
	if _sheet == null:
		return
	_cover.visible = _owned
	for id in _tabs:
		var tab: MeshInstance3D = _tabs[id]
		tab.visible = _owned and _has_bookmark(id)
	for part in _clip:
		part.visible = not _owned
	if pages.is_empty():
		return
	var id := pages[index]
	var mark := _bookmark_of(id)
	_remember[mark] = id
	for b in _tabs:   # der aufgeschlagene Reiter steht weiter heraus
		(_tabs[b] as MeshInstance3D).position.x = Item.MAP_WIDTH / 2.0 + (0.008 if b == mark else 0.0)
	var keys := id == KEYS
	if mark == "map":
		_sheet.material_override = _note_material if keys else HotelMap.material(id)
	else:
		_sheet.material_override = _book_material(id)
	_keys_title.visible = keys
	_keys_list.visible = keys
	for k in _edges.size():
		_edges[k].visible = k < pages.size() - 1
	var map_count := _map_pages.size()
	_counter.text = "Blatt %d/%d" % [index + 1, map_count] if mark == "map" and map_count > 1 else ""


# --- Seiten des Notizbuchs ------------------------------------------------------------------

## Material einer Notizbuchseite – leer (Papier), bis ihre Textur fertig gerendert ist. Ungeschattet: beleuchtet
## verschwamm die Schrift unter dem Filmic-Tonemapping zu Grau auf Grau, und lesen soll man auch im Dunkeln (3.10).
func _book_material(id: String) -> StandardMaterial3D:
	if not _materials.has(id):
		var paper := StandardMaterial3D.new()
		paper.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		paper.albedo_color = HotelMap.NOTE_PAPER
		paper.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		_materials[id] = paper
	var m: StandardMaterial3D = _materials[id]
	if _textures.has(id):
		m.albedo_color = Color.WHITE
		m.albedo_texture = _textures[id]
	elif not _rendering.has(id):
		_render(id)
	return m


func _render(id: String) -> void:
	_rendering[id] = true
	var kind := id.get_slice(":", 0)
	var page := id.get_slice(":", 1).to_int()
	var layout: Array = _layout[kind]
	var vp := SubViewport.new()
	vp.size = NotebookPage.SIZE
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.add_child(NotebookPage.new().setup(kind, layout[page] if page < layout.size() else [], page, layout.size()))
	get_tree().root.add_child(vp)
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	vp.queue_free()
	if not _rendering.has(id):
		return   # inzwischen neu gesetzt – die nächste Ansicht rendert neu
	_rendering.erase(id)
	if img == null:   # ohne Grafik (--headless)
		return
	img.generate_mipmaps()
	_textures[id] = ImageTexture.create_from_image(img)
	if index < pages.size() and pages[index] == id:
		_refresh()


func _drop_textures(kind: String) -> void:
	for dict: Dictionary in [_textures, _materials, _rendering]:
		for id in dict.keys():
			if String(id).begins_with(kind + ":"):
				dict.erase(id)


func _label(font_size: int, color: Color, pos: Vector3) -> Label3D:
	var label := Label3D.new()
	label.font_size = font_size
	label.pixel_size = 0.0004
	label.modulate = color
	label.outline_size = 0
	label.position = pos
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(label)
	return label
