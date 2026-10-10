extends Node
## Globaler Spielzustand (Autoload „Game“): Referenzen, Geld, Meldungen, Tastenbelegung.

signal money_changed(amount: int)
signal message_posted(text: String, duration: float)
signal player_died

var player: Player
var director: MonsterDirector
var monster: Monster
var hud: Hud
var audio: SynthAudio
var social: Social
var dialog: DialogUI
var dice: DiceMatch
var game_over := false
## Geld ist der einzige abstrakte Besitz – alles andere wird in den Händen getragen.
var money := 0:
	set(value):
		money = value
		money_changed.emit(money)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()


func reset() -> void:
	game_over = false
	money = 5
	player = null
	director = null
	monster = null
	hud = null
	audio = null
	social = null
	dialog = null
	dice = null


func say(text: String, duration: float = 3.5) -> void:
	message_posted.emit(text, duration)


func play_sound(kind: String, volume: float = 1.0) -> void:
	if audio:
		audio.play_shot(kind, volume)


func _setup_input() -> void:
	_bind_keys("move_forward", [KEY_W, KEY_UP])
	_bind_keys("move_back", [KEY_S, KEY_DOWN])
	_bind_keys("move_left", [KEY_A, KEY_LEFT])
	_bind_keys("move_right", [KEY_D, KEY_RIGHT])
	_bind_keys("run", [KEY_SHIFT])
	_bind_keys("jump", [KEY_SPACE])
	_bind_keys("crouch", [KEY_CTRL, KEY_C])
	_bind_keys("interact", [KEY_E])
	_bind_keys("drop", [KEY_G, KEY_Q])
	_bind_keys("debug_overlay", [KEY_F3])
	_bind_keys("debug_manifest", [KEY_F5])
	_bind_keys("pause", [KEY_ESCAPE])
	_bind_mouse("hold_breath", MOUSE_BUTTON_RIGHT)


func _ensure_action(action: StringName) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)


func _bind_keys(action: StringName, keys: Array) -> void:
	_ensure_action(action)
	for key in keys:
		var event := InputEventKey.new()
		event.physical_keycode = key
		InputMap.action_add_event(action, event)


func _bind_mouse(action: StringName, button: MouseButton) -> void:
	_ensure_action(action)
	var event := InputEventMouseButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)
