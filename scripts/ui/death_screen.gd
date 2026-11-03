class_name DeathScreen
extends CanvasLayer
## Sterbebildschirm nach dem Jumpscare: verrauschtes Standbild. Danach den letzten
## Spielstand laden, einen anderen wählen oder zurück ins Hauptmenü (Spielkonzept 8.7). Im Albtraum-Modus (8.9) nur
## noch das Hauptmenü – der Slot ist mit dem Tod gelöscht.
## Oben das Porträt dessen, der einen geholt hat (Player.killed_by, IconArt.THREATS – sonst der Totenkopf), neben
## der Überschrift je ein kleiner Totenkopf.

## Wer einen geholt hat: Satz unter der Überschrift
const KILLED_LINES := {
	"monster": "Das Monster hat dich geholt.",
	"ghost": "Der Lakengeist hat dir die Luft genommen.",
	"pumpkin": "Der Kürbismann hat dich erwischt.",
}
const TITLE_SKULL := 32

const NOISE_SHADER := """
shader_type canvas_item;
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	float n = hash(FRAGCOORD.xy + fract(TIME * 13.0) * 97.0);
	float line = step(0.5, fract(SCREEN_UV.y * 90.0 + TIME * 2.0));
	COLOR = vec4(n * 0.25 + line * 0.03, n * 0.04, n * 0.04, 0.6);
}
"""

var _root: Control
var _box: VBoxContainer


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.0, 0.0, 1.0)
	root.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var noise := ColorRect.new()
	var shader := Shader.new()
	shader.code = NOISE_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	noise.material = material
	noise.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(noise)
	noise.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_root = root
	var box := VBoxContainer.new()
	_box = box
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	root.add_child(box)
	var killer := Game.player.killed_by if Game.player else ""
	var portrait := TextureRect.new()
	portrait.texture = IconArt.threat(killer) if IconArt.THREATS.has(killer) else IconArt.texture("dead")
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED   # 1 : 1 – Pixel für Pixel
	portrait.custom_minimum_size = Vector2(IconArt.SIZE, IconArt.SIZE)
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(portrait)
	var title := HBoxContainer.new()
	title.alignment = BoxContainer.ALIGNMENT_CENTER
	title.add_theme_constant_override("separation", 6)
	title.add_child(_skull())
	title.add_child(_label("DU BIST GESTORBEN", 24, Color(0.8, 0.1, 0.08)))
	title.add_child(_skull())
	box.add_child(title)
	box.add_child(_label(KILLED_LINES.get(killer, "Das Hotel lässt niemanden gehen …"), 10, Color(0.7, 0.65, 0.6)))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	box.add_child(spacer)
	if Game.nightmare_mode:   # Albtraum-Modus (8.9): der Slot ist schon fort, kein Zurückladen
		box.add_child(_label("Der Albtraum ist vorbei. Dein Spielstand ist fort.", 10, Color(0.7, 0.65, 0.6)))
	elif SaveManager.has_any_save():
		box.add_child(_button("Letzten Spielstand laden", _on_load_newest))
		box.add_child(_button("Spielstand wählen", _on_choose))
	else:
		box.add_child(_button("Neu beginnen", _on_restart))
	box.add_child(_button("Hauptmenü", _on_title))
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH

	root.modulate.a = 0.0
	create_tween().tween_property(root, "modulate:a", 1.0, 0.8)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := UiKit.plain_label(font_size, color, 2)
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func _skull() -> TextureRect:
	var skull := TextureRect.new()
	skull.texture = IconArt.texture("dead", TITLE_SKULL)
	skull.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	skull.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return skull


func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 12)
	button.pressed.connect(callback)
	return button


func _on_restart() -> void:
	Game.start_new_game(0)


func _on_load_newest() -> void:
	SaveManager.load_newest()


func _on_choose() -> void:
	_box.visible = false
	var sheet := UiKit.sheet(_root, "Spielstand wählen", Vector2(330, 0))
	var list := SlotList.new().setup(SlotList.Mode.LOAD, Game.current_slot)
	list.picked.connect(func(slot: int) -> void: SaveManager.load_slot(slot))
	sheet.add_child(list)
	sheet.add_child(UiKit.button("Zurück", func() -> void:
		sheet.get_parent().queue_free()
		_box.visible = true))


func _on_title() -> void:
	Game.go_to_title()
