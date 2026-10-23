class_name ItemIcons
extends Node
## Kleine Bilder der Gegenstände für die Tasche (Spielkonzept 3.2): Jede Art (mit ihrem Extra, z. B. Cola/Limo)
## wird einmal in einem eigenen SubViewport schräg von oben gerendert und danach wiederverwendet. Die Kopie dort ist
## kein Welt-Gegenstand (raus aus Gruppe „items“, eingefroren, ohne Verarbeitung). Gerendert wird RENDER_FRAMES lang,
## dann steht das Bild – beim ersten Mal sind die Shader im Spiel oft noch nicht übersetzt, dann bliebe es leer.

const SIZE := 40          ## Pixel (interne Auflösung)
const VIEW := Vector3(0.0, 0.75, 1.0)   ## Blickrichtung zur Kamera hin: schräg von vorn oben
const RENDER_FRAMES := 30

var _cache := {}
var _fresh := {}   ## SubViewport → noch so viele Bilder rendern


func _process(_delta: float) -> void:
	for vp: SubViewport in _fresh.keys():
		_fresh[vp] -= 1
		if _fresh[vp] <= 0:
			vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
			_fresh.erase(vp)


func icon(item: Item) -> Texture2D:
	# ohne Faulzeit („r=…“, Spielkonzept 5.10) – sonst bekäme jeder Kürbis ein eigenes Bild; die Stufe steht im Namen
	var extra := ",".join(Array(item.create_extra().split(",")).filter(func(part: String) -> bool: return not part.begins_with("r=")))
	var key := "%d|%s|%s" % [item.kind, extra, item.display_name]
	if not _cache.has(key):
		_cache[key] = _render(item)
	return _cache[key]


func _render(item: Item) -> Texture2D:
	var vp := SubViewport.new()
	vp.size = Vector2i(SIZE, SIZE)
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	_fresh[vp] = RENDER_FRAMES
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.7
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	vp.add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.rotation = Vector3(-0.9, 0.5, 0.0)
	sun.light_energy = 1.2
	vp.add_child(sun)
	var copy := Item.create(item.kind, item.create_extra())
	vp.add_child(copy)
	copy.remove_from_group("items")
	copy.remove_meta("interactable")
	copy.set_held(true)
	copy.process_mode = Node.PROCESS_MODE_DISABLED
	if not item.lit and copy.lit:
		copy._extinguish()   # Kerzenstummel
	var box := _bounds(copy)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = maxf(box.size.x, maxf(box.size.y, box.size.z)) * 1.35
	cam.near = 0.01
	cam.far = 10.0
	vp.add_child(cam)
	var center := box.get_center()
	cam.look_at_from_position(center + VIEW.normalized() * 2.0, center)
	cam.current = true
	return vp.get_texture()


## Umriss aller Netze des Gegenstands (lokal, Ursprung = Unterseite)
func _bounds(item: Item) -> AABB:
	var box := AABB()
	var first := true
	var inv := item.global_transform.affine_inverse()
	for node in item.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if not mi.is_visible_in_tree():
			continue
		var part := inv * mi.global_transform * mi.get_aabb()
		box = part if first else box.merge(part)
		first = false
	return box if not first else AABB(Vector3(-0.05, 0, -0.05), Vector3(0.1, 0.1, 0.1))
