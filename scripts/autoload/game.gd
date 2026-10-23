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
	"scream": "[Ein Schrei]", "death_scream": "[Ein Schrei – jäh abgerissen]", "grunt": "[Ein Ächzen]",
	"shriek": "[Ein Kreischen]", "growl": "[Knurren]", "bang": "[Ein Knall]", "sting": "[Schriller Ton]",
	"cry": "[Eine Katze kreischt]", "meow": "[Miau]", "bell": "[Eine Totenglocke läutet]",
	"ding": "[Ding – der Aufzug]", "motor": "[Ein Motor brummt im Schacht]", "alarm": "[Eine Alarmglocke schrillt]",
	"chime": "[Gong – eine Durchsage]", "poof": "[Ein Fauchen]",
}

var player: Player
var director: MonsterDirector
var monster: Monster
var ghost: SheetGhost
var pumpkin: PumpkinMan
var hud: Hud
var audio: SynthAudio
var social: Social
var dialog: DialogUI
var dice: DiceMatch
var chess: ChessMatch
var menus: Menus
var traces: Traces
var phones: PhoneCalls
var weather: Weather
var kitchen: Stove                ## Herd in der Küche (Spielkonzept 3.8), setzt sich selbst
var confetti: Confetti            ## Konfetti auf Feiern (Spielkonzept 7.6)
var doll: JuryDoll                 ## die Puppe – „Halloween-Jury“ (Spielkonzept 5.5)
var contest: DoorContest           ## Türschmuck-Wettbewerb, Brief, Brett, Siegerehrung (Spielkonzept 2.5)
var game_over := false
## Charaktererstellung am Waschbecken läuft (Spielkonzept 3.9) – kein Spielmenü, das Spiel ist pausiert
var creating := false
## Debug: letzte Lärmereignisse (F3)
var noise_log: Array[String] = []
## Debug: --trace (auch aus der Konsole) – Lärm und Zustandswechsel in die Konsole schreiben
var tracing := false
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


## Headless (tests/smoke.sh): Endmarke beim Abbau – stürzt Godot danach ab oder hängt, liegt es am Beenden, nicht am
## Spiel (offenes Problem, TECHNIK.md 10).
func _exit_tree() -> void:
	if DisplayServer.get_name() == "headless":
		print("[Ende] Szenenbaum abgebaut")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	# Entwicklungsläufe starten ohne Fokus (project.godot, no_focus.editor_runtime) – ohne --bg gleich nachholen
	if OS.has_feature("editor_runtime") and not "--bg" in OS.get_cmdline_user_args():
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, false)
		DisplayServer.window_move_to_foreground()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			_shot_path = arg.substr(7)
		elif arg.begins_with("--frames="):
			_shot_at = arg.substr(9).to_int()
		elif arg.begins_with("--shot-on="):
			_shot_on = arg.substr(10)
			_shot_at = -1   # erst beim Ereignis
		elif arg == "--bg":
			_to_background()
		elif arg == "--trace":
			tracing = true   # schon hier, damit es beim Aufbau der Welt gilt (main.gd setzt es sonst erst danach)


## Debug: --bg – Fenster nimmt keinen Fokus und liegt außerhalb des Bildschirms, damit Testläufe
## (Screenshots) nicht stören. Nicht minimieren: dann zeichnet Godot nicht mehr.
func _to_background() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	DisplayServer.window_set_position(Vector2i(-4000, 0))


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
	creating = false
	money = 5
	player = null
	director = null
	monster = null
	ghost = null
	pumpkin = null
	hud = null
	audio = null
	social = null
	dialog = null
	dice = null
	chess = null
	menus = null
	traces = null
	phones = null
	weather = null
	kitchen = null
	confetti = null
	doll = null
	contest = null
	noise_log.clear()
	Senses.clear_cache()


func say(text: String, duration: float = 3.5) -> void:
	message_posted.emit(text, duration)


## `pos`/`who`: Ort und Stimme für menschliche Laute (SynthAudio.VOICES) – die klingen aus ihrer Richtung.
func play_sound(kind: String, volume: float = 1.0, pos := Vector3.INF, who: Node = null) -> void:
	if audio and not audio.play_shot(kind, volume, pos, who):
		return
	if volume >= 0.3 and SOUND_CAPTIONS.has(kind):
		caption(SOUND_CAPTIONS[kind])


## Nur der Klang, ohne Lärm (niemand sonst reagiert): so laut, wie der Spieler ihn bei `loudness` m Hörweite
## hört – bis zur doppelten Hörweite, gedämpft durch Wände wie bei `noise`. Gibt die Lautstärke zurück.
func sound_at(sound: String, pos: Vector3, loudness: float, source: Node = null, volume: float = 1.0) -> float:
	if player == null:
		return 0.0
	if source != player:
		var ear := player.camera.global_position
		var d := ear.distance_to(pos)
		var reach := 0.0
		if d < maxf(2.0 * loudness, Senses.PLAYER_MIN_REACH):
			var audible := Senses.audible_range(player.get_world_3d(), pos, ear, loudness)
			reach = maxf(2.0 * audible, Senses.PLAYER_MIN_REACH * audible / loudness)
		volume *= clampf(1.0 - d / reach, 0.0, 1.0) if reach > 0.0 else 0.0
	if volume > 0.02:
		play_sound(sound, volume, pos, source)
	return volume


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
		volume = sound_at(data["sound"], pos, loudness, source, float(data["volume"]))
		if player.sleeping and source != player and volume >= 0.3:
			player.wake_up("Ein Geräusch weckt dich.")
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
	if tracing:
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
	_bind_keys("drop", [KEY_G])
	_bind_keys("map", [KEY_TAB])        # Kartenblätter ansehen (halten)
	_bind_keys("compass", [KEY_F])      # Kompass ansehen (halten)
	_bind_keys("light_mode", [KEY_R])   # Taschenlampe: normales Licht ↔ UV
	_bind_mouse("use_item", MOUSE_BUTTON_LEFT)   # Taschenlampe an/aus
	_bind_keys("bag", [KEY_Q])          # Tasche (halten): Fächer zeigen, loslassen nimmt in die Hand (Spielkonzept 3.2)
	for i in Player.BAG_SLOTS:          # Fach 1–6 der Tasche wählen bzw. gleich in die Hand
		_bind_keys("bag_%d" % (i + 1), [KEY_1 + i])
	_bind_keys("debug_overlay", [KEY_F3])
	_bind_keys("debug_manifest", [KEY_F5])
	_bind_keys("debug_teleport", [KEY_F6])
	_bind_keys("debug_lure", [KEY_F7])
	_bind_keys("debug_pumpkin", [KEY_F9])   # Kürbismann im Garten (F8 stoppt im Godot-Editor das Spiel)
	_bind_keys("debug_fps", [KEY_F10])      # Bilder pro Sekunde (Hud)
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
