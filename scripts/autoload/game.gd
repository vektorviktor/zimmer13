extends Node
## Globaler Spielzustand (Autoload „Game“): Referenzen, Geld, Meldungen, Tastenbelegung.

signal money_changed(amount: int)
signal message_posted(text: String, duration: float, icon: String)
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
	"chime": "[Gong – eine Durchsage]", "poof": "[Ein Fauchen]", "flutter": "[Flügelschlagen]",
	"howl": "[Ein Hund heult in der Ferne]", "caw": "[Eine Krähe krächzt]", "squeak": "[Ratten quieken]",
	"music_box": "[Eine Spieluhr spielt]", "fuse": "[Klack – eine Sicherung]",
	"power_down": "[Der Strom fällt aus]",
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
var darts: DartMatch               ## Darts an der Bar (Spielkonzept 6.10)
var bowling: BowlingMatch           ## Bowling allein an der Bahn in der Bar (Spielkonzept 6.10)
var bar_games := {}                ## Barspiele am Würfeltisch: id → BarMatch (Spielkonzept 6.10, 28.10.)
var menus: Menus
var traces: Traces
var phones: PhoneCalls
var weather: Weather
var bats: Bats                     ## Fledermäuse draußen (Spielkonzept 4.22)
var spiders: Spiders               ## Spinnen am Boden und in Schubladen (Spielkonzept 4.23)
var sleep_skip: SleepSkip          ## Zeitsprung im Schlaf (Spielkonzept 3.6)
var shower_scare: ShowerScare      ## Lakengeist in der Dusche von Zimmer 13 (Spielkonzept 4.24)
var crows: Crows                   ## Krähen im Garten, merken sich Gesichter (Spielkonzept 4.25)
var rats: Rats                     ## Ratten im Untergeschoss, rennen vor dem Monster (Spielkonzept 4.25)
var moths: Moths                   ## Motten an den Lampen (Spielkonzept 4.25)
var boiler_cat: BoilerCat          ## die schwarze Kesselkatze Josefs, des früheren Hausmeisters (Spielkonzept 4.26)
var mirror_omens: MirrorOmens      ## Gestalt im Spiegel, verhängte Spiegel (Spielkonzept 4.27)
var power_cut: PowerCut            ## Stromausfall im Gewitter (Spielkonzept 4.28)
var nightmare: Nightmare           ## der Albtraum von 1987 (Spielkonzept 4.29)
var scarecrow: Scarecrow           ## die Vogelscheuche, die näher kommt (Spielkonzept 4.30)
var extra_child: ExtraChild        ## das Kind zu viel beim Süßes oder Saures (Spielkonzept 4.31)
var photo_wall: PhotoWall          ## Gruppenfotos der Ernten 1987–2026 in der Lobby (Spielkonzept 5.14)
var cemetery: Cemetery             ## Friedhof mit Gräbern und Gedenkstätte (Spielkonzept 5.15)
var register: HotelRegister        ## Hotelregister auf der Rezeption, Kreuze neben den Toten (Spielkonzept 2.3)
var leviathan_name: LeviathanName  ## erste bestätigte Sichtung, Hugos Druck, der Name Leviathan (Spielkonzept 4.32)
var doll_house: DollHouse          ## Puppenhaus in der Bibliothek (Spielkonzept 5.16)
var pumpkin_faces: PumpkinFaces    ## Kürbisgesichter, die sich verändern (Spielkonzept 5.18)
var apple_tub: AppleTub            ## Apfeltauchen im Partyraum (Spielkonzept 6.21)
var kitchen: Stove                ## Herd in der Küche (Spielkonzept 3.8), setzt sich selbst
var coffee: CoffeeMachine         ## Kaffeemaschine in der Küche (Spielkonzept 3.11), setzt sich selbst
var kettle: TeaKettle             ## Wasserkocher in der Küche (Spielkonzept 3.12), setzt sich selbst
var confetti: Confetti            ## Konfetti auf Feiern (Spielkonzept 7.6)
var doll: JuryDoll                 ## die Puppe – „Halloween-Jury“ (Spielkonzept 5.5)
var contest: DoorContest           ## Türschmuck-Wettbewerb, Brief, Brett, Siegerehrung (Spielkonzept 2.5)
var notebook: Notebook             ## Notizbuch am Körper: Aufgaben und Notizen (Spielkonzept 3.10)
var diary: Diary                   ## Tagebuch in Zimmer 13: Speichern und Meilensteine (Spielkonzept 3.10, 8.5)
var achievements: Achievements     ## Erfolge in Bronze, Silber, Gold, im Profil gespeichert (Spielkonzept 8.11)
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
## Wechsel in die Hauptszene läuft (enter_game) – „Lädt …“ steht, weitere Klicks zählen nicht
var entering := false
## Bevorzugter Slot für das Tagebuch (1–3); im Albtraum-Modus der einzige Slot des Spiels
var current_slot := 1
## Albtraum-Modus (Spielkonzept 8.9): beim neuen Spiel gewählt, steht im Spielstand. Ein einziger Slot (current_slot) –
## Tagebuch und Autosave schreiben nur dorthin, der Tod löscht ihn (SaveManager.on_death). Nicht zu verwechseln mit
## `nightmare`, dem Albtraum von 1987 (4.29).
var nightmare_mode := false
## Geld ist der einzige abstrakte Besitz – alles andere wird in den Händen getragen.
var money := 0:
	set(value):
		money = value
		money_changed.emit(money)


## Debug: --shot=pfad.png speichert nach --frames=n Frames einen Screenshot und beendet
## das Spiel – auch im Titelbildschirm und bei offenem (pausierendem) Menü.
## Mit --shot-on=ereignis stattdessen kurz nach einem Ereignis (siehe shot_event).
## --shot-size=BxH: rahmenloses Fenster in dieser Größe, auch größer als der Bildschirm (Windows begrenzt
## Fenster mit Rahmen auf die Bildschirmfläche) – für hochaufgelöste Bilder wie den Hintergrund des Titelbildschirms.
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
		elif arg.begins_with("--shot-size="):
			var size := arg.substr(12).split("x")
			get_window().borderless = true
			get_window().size = Vector2i(size[0].to_int(), size[1].to_int())
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
	shower_scare = null
	pumpkin = null
	hud = null
	audio = null
	social = null
	dialog = null
	dice = null
	chess = null
	darts = null
	bar_games = {}
	menus = null
	traces = null
	phones = null
	weather = null
	kitchen = null
	coffee = null
	kettle = null
	confetti = null
	doll = null
	contest = null
	notebook = null
	diary = null
	achievements = null
	crows = null
	rats = null
	moths = null
	boiler_cat = null
	mirror_omens = null
	power_cut = null
	nightmare = null
	scarecrow = null
	extra_child = null
	photo_wall = null
	cemetery = null
	register = null
	leviathan_name = null
	doll_house = null
	pumpkin_faces = null
	apple_tub = null
	noise_log.clear()
	Senses.clear_cache()


## Läuft gerade ein Spiel mit dem Spieler – Mäxchen, Schach, Darts (auch allein), Bowling oder ein Barspiel?
func table_game_active() -> bool:
	if (dice != null and dice.active) or (chess != null and chess.active) or (darts != null and darts.active) \
			or (bowling != null and bowling.active):
		return true
	for game: BarMatch in bar_games.values():
		if game.active:
			return true
	return false


## Meldung oben im Bild; icon: Symbol darüber (IconArt-Name, z. B. „dead“).
func say(text: String, duration: float = 3.5, icon: String = "") -> void:
	message_posted.emit(text, duration, icon)


## `pos`/`who`: Ort und Stimme für menschliche Laute (SynthAudio.VOICES) – die klingen aus ihrer Richtung.
## `caption_text`: eigener Untertitel (Lärmtabelle, Spielkonzept 4.15) – kommt auch bei leisen Geräuschen.
func play_sound(kind: String, volume: float = 1.0, pos := Vector3.INF, who: Node = null, caption_text := "") -> void:
	if audio and not audio.play_shot(kind, volume, pos, who):
		return
	if caption_text != "":
		caption(caption_text)
	elif volume >= 0.3 and SOUND_CAPTIONS.has(kind):
		caption(SOUND_CAPTIONS[kind])


## Nur der Klang, ohne Lärm (niemand sonst reagiert): so laut, wie der Spieler ihn bei `loudness` m Hörweite
## hört – bis zur doppelten Hörweite, gedämpft durch Wände wie bei `noise`. Gibt die Lautstärke zurück.
func sound_at(sound: String, pos: Vector3, loudness: float, source: Node = null, volume: float = 1.0,
		caption_text := "") -> float:
	if player == null:
		return 0.0
	if source != player:
		volume *= _heard(pos, loudness)
	if volume > 0.02:
		play_sound(sound, volume, pos, source, caption_text)
	return volume


## Wie laut der Spieler einen Lärm `kind` (Art aus `Senses.NOISE`) an `pos` hörte – ohne ihn zu machen (Zeitsprung,
## Spielkonzept 3.6: Hörte er es, endet der Sprung vorher). Ab 0,3 weckt Lärm einen Schlafenden (`noise`).
func heard_volume(kind: String, pos: Vector3) -> float:
	var data: Dictionary = Senses.NOISE.get(kind, {})
	if player == null or data.is_empty():
		return 0.0
	return float(data["volume"]) * _heard(pos, data["range"])


## Wie laut (0..1) der Spieler eine dauernde Klangquelle mit `loudness` m Hörweite an `pos` hört (Kesselfeuer).
func hearing(pos: Vector3, loudness: float) -> float:
	return _heard(pos, loudness) if player else 0.0


## Anteil (0..1), den der Spieler bei `loudness` m Hörweite von `pos` hört: bis zur doppelten Hörweite, gedämpft durch
## Wände.
func _heard(pos: Vector3, loudness: float) -> float:
	var ear := player.camera.global_position
	var d := ear.distance_to(pos)
	var reach := 0.0
	if d < maxf(2.0 * loudness, Senses.PLAYER_MIN_REACH):
		var audible := Senses.audible_range(player.get_world_3d(), pos, ear, loudness)
		reach = maxf(2.0 * audible, Senses.PLAYER_MIN_REACH * audible / loudness)
	return clampf(1.0 - d / reach, 0.0, 1.0) if reach > 0.0 else 0.0


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
		volume = sound_at(data["sound"], pos, loudness, source, float(data["volume"]), data.get("caption", ""))
		if player.sleeping and source != player and volume >= 0.3:
			player.wake_up("Ein Geräusch weckt dich.")
	var heard: Array[String] = []
	if director:
		var r := director.on_noise(pos, loudness, source)
		if r != "":
			heard.append(r)
	if social and data.get("alarm", false):
		heard.append_array(social.on_alarm(kind, pos, loudness, source))
	if social and player and source == player:
		heard.append_array(social.on_player_noise(kind, pos, loudness))
	if bats:
		bats.on_noise(pos, loudness, source)
	if crows:
		crows.on_noise(pos, loudness, source)
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


## Neues Spiel starten; slot > 0 → Startzustand gleich dorthin speichern. nightmare_run: Albtraum-Modus (8.9), nur
## mit Slot.
func start_new_game(slot: int, nightmare_run: bool = false) -> void:
	if entering:
		return
	pending_load = {}
	new_game_slot = slot
	nightmare_mode = nightmare_run and slot > 0
	if slot > 0:
		current_slot = slot
	SaveManager.drop_suspend()   # ein neues Spiel verwirft den Zwischenstand (8.10)
	enter_game()


## In die Hauptszene wechseln (Neues Spiel, Fortsetzen, Laden – Spielkonzept 8): Der Bau des Hotels hält das Bild
## sekundenlang an – ohne Rückmeldung glaubt man, daneben geklickt zu haben. Darum zuerst abdunkeln und „Lädt …“
## zeigen, zwei Bilder warten, bis es zu sehen ist, dann wechseln. Die Tafel hängt am Game-Knoten, übersteht den
## Wechsel und fängt bis zum ersten Bild der neuen Szene alle Klicks ab; weitere Aufrufe zählen solange nicht.
func enter_game() -> void:
	if entering:
		return
	entering = true
	var layer := CanvasLayer.new()
	layer.layer = 128
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.8)
	dim.theme = UiKit.menu_theme()
	layer.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var label := UiKit.label("Lädt …", 14, UiKit.PAPER, HORIZONTAL_ALIGNMENT_CENTER)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dim.add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_SCENE)
	await get_tree().scene_changed
	await get_tree().process_frame
	layer.queue_free()
	entering = false


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
	_bind_keys("debug_diag", [KEY_F2])      # Lichtdiagnose: aus → Position → Position und Licht (LightDiag)
	_bind_keys("debug_report", [KEY_F4])    # Lichtbericht nach user://berichte/ (LightDiag)
	_bind_keys("debug_atlas", [KEY_F11])    # nächste Aufteilung des Schattenatlas (LightDiag)
	_bind_keys("debug_console", [KEY_QUOTELEFT, KEY_F1])   # [^] auf deutscher Tastatur
	_bind_keys("pause", [KEY_ESCAPE])
	_bind_mouse("hold_breath", MOUSE_BUTTON_RIGHT)
	Keys.apply_saved(Settings.key_bindings)   # eigene Belegung aus dem Profil (Spielkonzept 8.4)


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
