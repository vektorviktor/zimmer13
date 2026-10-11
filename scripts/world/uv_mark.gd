class_name UvMark
extends Node3D
## Etwas, das nur unter UV-Licht zu sehen ist (Spielkonzept 4.16): Schrift an der Wand oder
## der Nachglanz einer Fußspur des Monsters. Die Taschenlampe ruft `shine()` auf, solange der
## UV-Kegel darauf fällt; danach verblasst es in Sekundenbruchteilen. Lokale +Z zeigt zum
## Betrachter (wie bei TraceMark). Nicht gespeichert – Schriften baut der LevelBuilder,
## Fußspuren gehören zu Traces.

const FADE_IN := 4.0
const FADE_OUT := 2.5
const HOLD := 0.15              ## so lange bleibt es nach dem letzten Treffer voll sichtbar
const COLOR := Color(0.78, 0.62, 1.0)

var _glow := 0.0
var _hold := 0.0
var _label: Label3D
var _meshes: Array[MeshInstance3D] = []
var _mat: StandardMaterial3D


## Leuchtschrift (Großbuchstaben, Zeilen mit \n).
func setup_text(text: String, pixel_size: float = 0.0035) -> UvMark:
	_label = Label3D.new()
	_label.text = text
	_label.pixel_size = pixel_size
	_label.font_size = 48
	_label.outline_size = 0
	_label.modulate = Color(COLOR, 0.0)
	_label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_label.double_sided = false
	_label.position.z = 0.004
	add_child(_label)
	return self


## Nachglanz aus eigenen Kästen (z. B. die Form einer Fußspur), alle mit einem Material.
func add_box(size: Vector3, pos: Vector3, yaw: float = 0.0) -> MeshInstance3D:
	if _mat == null:
		_mat = StandardMaterial3D.new()
		_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat.albedo_color = Color(COLOR, 0.0)
	var mi := Geo.mesh(self, Geo.box(size), _mat, pos)
	mi.rotation.y = yaw
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.visible = false
	_meshes.append(mi)
	return mi


func _ready() -> void:
	add_to_group("uv_marks")
	set_process(false)


## Der UV-Kegel trifft diese Stelle.
func shine() -> void:
	_hold = HOLD
	set_process(true)


func _process(delta: float) -> void:
	_hold -= delta
	_glow = move_toward(_glow, 1.0 if _hold > 0.0 else 0.0, delta * (FADE_IN if _hold > 0.0 else FADE_OUT))
	_apply()
	if _glow <= 0.0 and _hold <= 0.0:
		set_process(false)


func _apply() -> void:
	# Leichtes Zittern der Helligkeit – das UV-Licht ist nie ganz ruhig
	var a := _glow * randf_range(0.85, 1.0)
	if _label:
		_label.modulate = Color(COLOR, a)
	if _mat:
		_mat.albedo_color = Color(COLOR, a * 0.8)
	for mi in _meshes:
		mi.visible = a > 0.02
