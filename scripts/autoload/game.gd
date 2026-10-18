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
	"cry": "[Eine Katze jammert]", "meow": "[Miau]",
}

var player: Player
var director: MonsterDirector
var monster: Monster
var ghost: SheetGhost
var hud: Hud
var audio: SynthAudio
var social: Social
var dialog: DialogUI
var dice: DiceMatch
var menus: Menus
var traces: Traces
var phones: PhoneCalls
var game_over := false
## Debug: letzte Lärmereignisse (F3) und Ausgabe in die Konsole (--trace)
var noise_log: Array[String] = []
var noise_trace := false
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
	phones = null
	noise_log.clear()


func say(text: String, duration: float = 3.5) -> void:
	message_posted.emit(text, duration)


func play_sound(kind: String, volume: float = 1.0) -> void:
	if audio:
		audio.play_shot(kind, volume)
	if volume >= 0.3 and SOUND_CAPTIONS.has(kind):
		caption(SOUND_CAPTIONS[kind])


## Lärm (Spielkonzept 4.15): Geräusch und Lärm in einem. `kind` ist eine Art aus
## `Senses.NOISE`; der Spieler hört es je nach Entfernung und Wänden, Monster und Gäste
## reagieren in ihrer Hörweite. `source` (wer es macht) hört sich selbst nicht.
## Gibt die Lautstärke zurück, mit der der Spieler es hört (0 = gar nicht).
func noise(kind: String, pos: Vector3, source: Node = null) -> float:
	var data: Dictionary = Senses.NOISE.get(kind, {})
	if data.is_empty():
		push_warning("Unbekannte Lärm-Art: " + kind)
		return 0.0
	var loudness: float = data["range"]
	var volume := 0.0
	if player and String(data["sound"]) != "":
		volume = float(data["volume"])
		if source != player:
			# Der Spieler hört fremde Geräusche bis zur doppelten (gedämpften) Hörweite
			var ear := player.camera.global_position
			var d := ear.distance_to(pos)
			var reach := 0.0
			if d < maxf(2.0 * loudness, Senses.PLAYER_MIN_REACH):
				var audible := Senses.audible_range(player.get_world_3d(), pos, ear, loudness)
				reach = maxf(2.0 * audible, Senses.PLAYER_MIN_REACH * audible / loudness)
			volume *= clampf(1.0 - d / reach, 0.0, 1.0) if reach > 0.0 else 0.0
		if volume > 0.02:
			play_sound(data["sound"], volume)
	var heard: Array[String] = []
	if director:
		var r := director.on_noise(pos, loudness, source)
		if r != "":
			heard.append(r)
	if social and data.get("alarm", false):
		heard.append_array(social.on_alarm(kind, pos, loudness, source))
	var line := "[%ds] Lärm %s %.0f m @ (%.1f, %.1f, %.1f)%s" % [int(director.elapsed) if director else 0,
		kind, loudness, pos.x, pos.y, pos.z, "" if heard.is_empty() else " → " + ", ".join(heard)]
	noise_log.append(line)
	if noise_log.size() > 5:
		noise_log.pop_front()
	if noise_trace:
		print(line)
	return volume


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
	_bind_keys("map", [KEY_TAB])        # Kartenblätter ansehen (halten)
	_bind_keys("compass", [KEY_F])      # Kompass ansehen (halten)
	_bind_keys("light_mode", [KEY_R])   # Taschenlampe: normales Licht ↔ UV
	_bind_mouse("use_item", MOUSE_BUTTON_LEFT)   # Taschenlampe an/aus
	_bind_keys("debug_overlay", [KEY_F3])
	_bind_keys("debug_manifest", [KEY_F5])
	_bind_keys("debug_teleport", [KEY_F6])
	_bind_keys("debug_console", [KEY_QUOTELEFT, KEY_F1])   # [^] auf deutscher Tastatur
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
