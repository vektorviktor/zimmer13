class_name FixedCandle
extends StaticBody3D
## Feste Deko-Kerze auf dem Teller (Kommoden, Tische, Theke – Spielkonzept 7.3). Brennt von Spielbeginn an und unbegrenzt,
## bis das Monster sie im Vorbeigehen ausbläst (4.13) oder der Spieler sie auspustet [R]; wieder an mit einer Flamme
## oder der Streichholzschachtel in der Hand (Item.light_prompt, 5.12). Gespeichert über die Gruppe „fixed_candles“.

var lit := true
var light: FlickerLight
var energy := 1.0

var _flame: Node3D


func setup(p_energy: float) -> FixedCandle:
	energy = p_energy
	return self


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	add_to_group("fixed_candles")
	set_meta("interactable", self)
	var wick := CandleModel.build(self, false, true)   # auf dem Teller
	_flame = CandleModel.flame(self, Vector3(0, wick, 0))
	light = FlickerLight.new()
	light.position = Vector3(0, wick + 0.045, 0)
	light.light_color = Color(1.0, 0.68, 0.32)
	light.base_energy = energy
	light.omni_range = 4.5
	light.soft = true
	light.shadow_enabled = false
	light.distance_fade_enabled = true
	light.distance_fade_begin = 20.0
	light.distance_fade_length = 5.0
	light.add_to_group("lamps")
	add_child(light)
	Geo.add_box_shape(self, Vector3(0.12, wick + 0.04, 0.12), Vector3(0, (wick + 0.04) / 2.0, 0))
	_show()


func can_light() -> bool:
	return not lit


func flame_name() -> String:
	return "Kerze"


func light_up(_with_sound: bool = true) -> void:
	lit = true
	_show()
	Game.play_sound("blip", 0.4)


## Das Monster geht vorbei (Spur, Spielkonzept 4.13).
func blow_out() -> void:
	if not lit:
		return
	lit = false
	_show()
	if Game.player and Game.player.global_position.distance_to(global_position) < 6.0:
		Game.caption("[Eine Kerze erlischt]")


## Der Spieler pustet sie aus.
func snuff() -> void:
	if not lit:
		return
	lit = false
	_show()
	Game.play_sound("blip", 0.2)


func get_prompt(player: Player) -> String:
	var lighting := Item.light_prompt(self, player)
	if lighting != "":
		return lighting
	if lit:
		return "Kerze auspusten [R]" if not (player.held and player.held.flashlight) else ""
	return "Kerze (aus)"


func interact(player: Player) -> void:
	if not Item.light_by(self, player) and lit:
		snuff()   # [E] pustet sie ebenso aus – mehr kann man mit ihr nicht tun


func save_state() -> Dictionary:
	return {"lit": lit}


func load_state(d: Dictionary) -> void:
	lit = bool(d.get("lit", true))
	_show()


func _show() -> void:
	if light:
		light.burn_out = not lit
	if _flame:
		_flame.visible = lit
