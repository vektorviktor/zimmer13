class_name DeathScreen
extends CanvasLayer
## Sterbebildschirm nach dem Jumpscare: verrauschtes Standbild, Neustart / Beenden.

const NOISE_SHADER := """
shader_type canvas_item;
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	float n = hash(FRAGCOORD.xy + fract(TIME * 13.0) * 97.0);
	float line = step(0.5, fract(SCREEN_UV.y * 90.0 + TIME * 2.0));
	COLOR = vec4(n * 0.25 + line * 0.03, n * 0.04, n * 0.04, 0.6);
}
"""


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

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 6)
	root.add_child(box)
	box.add_child(_label("DU BIST GESTORBEN", 24, Color(0.8, 0.1, 0.08)))
	box.add_child(_label("Das Hotel lässt niemanden gehen …", 10, Color(0.7, 0.65, 0.6)))
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	box.add_child(spacer)
	box.add_child(_button("Neu starten", _on_restart))
	box.add_child(_button("Beenden", _on_quit))
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH

	root.modulate.a = 0.0
	create_tween().tween_property(root, "modulate:a", 1.0, 0.8)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var settings := LabelSettings.new()
	settings.font_size = font_size
	settings.font_color = color
	settings.outline_size = 2
	settings.outline_color = Color.BLACK
	label.label_settings = settings
	return label


func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 12)
	button.pressed.connect(callback)
	return button


func _on_restart() -> void:
	get_tree().reload_current_scene()


func _on_quit() -> void:
	get_tree().quit()
