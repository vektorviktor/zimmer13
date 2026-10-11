class_name PocketMap
extends Node3D
## Die eingesteckten Kartenblätter in der linken Hand (Tab halten, Spielkonzept 3.2): das
## oberste Blatt ist zu sehen, dahinter stehen die Kanten der übrigen hervor, oben links eine
## Büroklammer. Das letzte Blatt listet den Schlüsselbund. Steht senkrecht, Bildseite +Z
## (zur Kamera), Norden oben (+Y).

const KEYS := "keys"   ## Seiten-ID des Schlüsselblatts
const MAX_EDGES := 3

## Seiten in Blätter-Reihenfolge: Kartenblätter (HotelMap.PAGES), zuletzt ggf. KEYS
var pages: Array[String] = []
var index := 0

var _height := 0.0
var _sheet: MeshInstance3D
var _edges: Array[MeshInstance3D] = []
var _counter: Label3D
var _keys_title: Label3D
var _keys_list: Label3D
var _note_material: Material


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
	Geo.mesh(self, Geo.box(Vector3(0.0012, 0.016, 0.0008)), wire, Vector3(-w / 2.0 + 0.008, _height / 2.0 - 0.002, 0.0008))
	Geo.mesh(self, Geo.box(Vector3(0.0012, 0.012, 0.0008)), wire, Vector3(-w / 2.0 + 0.0125, _height / 2.0, 0.0008))
	Geo.mesh(self, Geo.box(Vector3(0.0057, 0.0012, 0.0008)), wire, Vector3(-w / 2.0 + 0.01025, _height / 2.0 + 0.006, 0.0008))
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
	var current := pages[index] if index < pages.size() else ""
	pages.clear()
	for page in HotelMap.PAGES:
		if page["id"] in map_pages:
			pages.append(page["id"])
	if not keys.is_empty():
		pages.append(KEYS)
		var lines: PackedStringArray = []
		for id in keys:
			lines.append("–  " + Item.key_label(id))
		_keys_list.text = "\n".join(lines)
	index = maxi(0, pages.find(current))
	_refresh()


## Beim Hervorholen: das Blatt der Ebene, auf der man steht, liegt oben (falls vorhanden)
func open_at(page_id: String) -> void:
	var i := pages.find(page_id)
	if i >= 0:
		index = i
	_refresh()


func flip(step: int) -> void:
	if pages.size() < 2:
		return
	index = posmod(index + step, pages.size())
	_refresh()
	Game.play_sound("rustle", 0.5)


func _refresh() -> void:
	if _sheet == null or pages.is_empty():
		return
	var id := pages[index]
	var keys := id == KEYS
	_sheet.material_override = _note_material if keys else HotelMap.material(id)
	_keys_title.visible = keys
	_keys_list.visible = keys
	for k in _edges.size():
		_edges[k].visible = k < pages.size() - 1
	_counter.text = "Blatt %d/%d" % [index + 1, pages.size()] if pages.size() > 1 else ""


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
