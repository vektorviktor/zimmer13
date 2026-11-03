class_name FixedCandle
extends StaticBody3D
## Feste Deko-Kerze auf dem Teller (Kommoden, Tische, Theke – Spielkonzept 7.3). Brennt von Spielbeginn an, bis das
## Monster sie im Vorbeigehen ausbläst (4.13) oder der Spieler sie auspustet [R]; wieder an mit einer Flamme oder der
## Streichholzschachtel in der Hand (Item.light_prompt, 5.12). Sie brennt ab wie jede Kerze (Item.BURN_TIME, Stummel
## ab Item.STUB); ganz abgebrannt bleibt der leere Teller – eine Kerze aus der Hand stellt man darauf [E], Gäste setzen
## im Vorbeigehen eine neue ein (CandleCare). Gespeichert über die Gruppe „fixed_candles“.

var lit := true
var light: FlickerLight
var energy := 1.0
## Übriges Wachs (1 = neu); 0 = der Teller ist leer. Beim Bau zufällig zwischen START_WAX, damit nicht alle zugleich
## ausgehen.
var wax := 1.0

const START_WAX := Vector2(0.5, 1.0)
const RANGE := 4.5

var _flame: Node3D
var _wick := 0.0
var _burn_acc := 0.0


func setup(p_energy: float) -> FixedCandle:
	energy = p_energy
	wax = randf_range(START_WAX.x, START_WAX.y)
	return self


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	add_to_group("fixed_candles")
	add_to_group("time_skip")   # Zeitsprung im Schlaf (SleepSkip): brennt weiter ab
	set_meta("interactable", self)
	_wick = CandleModel.build(self, false, true)   # auf dem Teller
	_flame = CandleModel.flame(self, Vector3(0, _wick, 0))
	light = FlickerLight.new()
	light.position = Vector3(0, _wick + 0.045, 0)
	light.light_color = Color(1.0, 0.68, 0.32)
	light.base_energy = energy
	light.omni_range = RANGE
	light.soft = true
	light.shadow_enabled = false
	light.distance_fade_enabled = true
	light.distance_fade_begin = 20.0
	light.distance_fade_length = 5.0
	light.add_to_group("lamps")
	add_child(light)
	Geo.add_box_shape(self, Vector3(0.12, _wick + 0.04, 0.12), Vector3(0, (_wick + 0.04) / 2.0, 0))
	_show()


func _process(delta: float) -> void:
	if not lit:
		return
	_burn_acc += delta
	if _burn_acc >= Item.BURN_STEP:
		burn(_burn_acc)
		if lit and randf() < Item.gust_out_chance(global_position, is_stub()) * _burn_acc:
			Item.gust_out(self)   # draußen bläst eine Böe sie aus (7.8)
		_burn_acc = 0.0


func skip_time(dt: float) -> void:
	burn(dt)


## Brennt dt Sekunden Spielzeit weiter; ganz abgebrannt bleibt der leere Teller.
func burn(dt: float) -> void:
	if not lit:
		return
	wax = maxf(0.0, wax - dt / Item.BURN_TIME)
	if wax <= 0.0:
		lit = false
		if Game.tracing:
			print("[Kerze] feste Kerze heruntergebrannt bei %s" % global_position.snapped(Vector3.ONE * 0.1))
	_show()


## Steht noch eine Kerze auf dem Teller?
func has_candle() -> bool:
	return wax > 0.0


func is_stub() -> bool:
	return has_candle() and wax < Item.STUB


## Eine neue Kerze (rest Wachs) auf den Teller – brennend oder nicht.
func renew(rest: float, burning: bool) -> void:
	wax = clampf(rest, 0.0, 1.0)
	lit = burning and has_candle()
	_show()


func can_light() -> bool:
	return not lit and has_candle()


func flame_name() -> String:
	return "Kerze"


func light_up(_with_sound: bool = true) -> void:
	if not has_candle():
		return
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
	if not has_candle():
		if player.held and player.held.kind == Item.Kind.CANDLE:
			return "Kerze auf den Teller stellen [E]"
		return "Leerer Kerzenteller"
	var lighting := Item.light_prompt(self, player)
	if lighting != "":
		return lighting
	var label := "Kerzenstummel" if is_stub() else "Kerze"
	if lit:
		return "%s auspusten [R]" % label if not (player.held and player.held.flashlight) else ""
	return "%s (aus)" % label


func interact(player: Player) -> void:
	if not has_candle():
		if player.held and player.held.kind == Item.Kind.CANDLE:
			renew(player.held.wax, player.held.lit)
			player.consume_held()
			Game.play_sound("blip", 0.3)
		return
	if not Item.light_by(self, player) and lit:
		snuff()   # [E] pustet sie ebenso aus – mehr kann man mit ihr nicht tun


func save_state() -> Dictionary:
	return {"lit": lit, "wax": snappedf(wax, 0.001)}


func load_state(d: Dictionary) -> void:
	lit = bool(d.get("lit", true))
	wax = float(d.get("wax", 1.0))
	_show()


func _show() -> void:
	var r := maxf(wax, 0.0)
	var tip := CandleModel.burn_down(self, _flame, _wick, r) if _wick > 0.0 else 0.0
	var wax_mesh: Node3D = get_meta("candle_wax", null)
	if is_instance_valid(wax_mesh):
		wax_mesh.visible = has_candle()
	if light:
		light.burn_out = not lit
		var k := Item.STUB_LIGHT if is_stub() else 1.0
		light.base_energy = energy * k
		light.omni_range = RANGE * sqrt(k)
		if _wick > 0.0:
			light.position.y = tip + 0.045
	if _flame:
		_flame.visible = lit
