extends Node
## Globaler Spielzustand (Autoload „Game“): Referenzen, Geld, Meldungen, Tastenbelegung.

signal money_changed(amount: int)
signal message_posted(text: String, duration: float)
signal player_died
signal caption_posted(text: String)

const MAIN_SCENE := "res://scenes/main.tscn"
const TITLE_SCENE := "res://scenes/title.tscn"
## Untertitel für wichtige Geräusche (Einstellungen → Barrierefreiheit)
const SOUND_CAPTIONS := {
	"scream": "[Ein Schrei]", "growl": "[Knurren]", "bang": "[Ein Knall]", "sting": "[Schriller Ton]",
}

var player: Player
var director: MonsterDirector
var monster: Monster
var hud: Hud
var audio: SynthAudio
var social: Social
var dialog: DialogUI
var dice: DiceMatch
var menus: Menus
var traces: Traces
var game_over := false
## Spielstand, der beim nächsten Start der Hauptszene geladen wird (siehe SaveManager)
var pending_load: Dictionary = {}
## Neues Spiel: in diesen Slot gleich den Startzustand schreiben (0 = keiner)
var new_game_slot := 0
## Bevorzugter Slot für das Tagebuch (1–3)
var current_slot := 1
## Geld ist der einzige abstrakte Besitz – alles andere wird in den Händen getragen.
var money := 0:
	set(value):
		money = value
		money_changed.emit(money)


## Debug: --shot=pfad.png speichert nach --frames=n Frames einen Screenshot und beendet
## das Spiel – auch im Titelbildschirm und bei offenem (pausierendem) Menü.
## Mit --shot-on=ereignis stattdessen kurz nach einem Ereignis (siehe shot_event).
var _shot_path := ""
var _shot_at := 120
var _shot_frames := 0
var _shot_on := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_shot_path = arg.substr(7)
		elif arg.begins_with("--frames="):
			_shot_at = arg.substr(9).to_int()
		elif arg.begins_with("--shot-on="):
			_shot_on = arg.substr(10)
			_shot_at = -1   # erst beim Ereignis


func _process(_delta: float) -> void:
	if _shot_path == "":
		return
	_shot_frames += 1
	if _shot_frames == _shot_at:
		get_viewport().get_texture().get_image().save_png(_shot_path)
		get_tree().quit()


## Debug: Ein Ereignis für --shot-on ist eingetreten (z. B. "reveal") – Screenshot
## nach `frames` Frames, sobald es zu --shot-on passt.
func shot_event(event: String, frames: int = 25) -> void:
	if _shot_path != "" and event == _shot_on:
		_shot_at = _shot_frames + frames


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
	menus = null
	traces = null


func say(text: String, duration: float = 3.5) -> void:
	message_posted.emit(text, duration)


func play_sound(kind: String, volume: float = 1.0) -> void:
	if audio:
		audio.play_shot(kind, volume)
	if volume >= 0.3 and SOUND_CAPTIONS.has(kind):
		caption(SOUND_CAPTIONS[kind])


## Untertitel für ein Geräusch – nur, wenn in den Einstellungen eingeschaltet.
func caption(text: String) -> void:
	if Settings.subtitles:
		caption_posted.emit(text)


## Neues Spiel starten; slot > 0 → Startzustand gleich dorthin speichern.
func start_new_game(slot: int) -> void:
	pending_load = {}
	new_game_slot = slot
	if slot > 0:
		current_slot = slot
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_SCENE)


func go_to_title() -> void:
	pending_load = {}
	new_game_slot = 0
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE)


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
