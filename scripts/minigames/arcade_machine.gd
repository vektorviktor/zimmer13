class_name ArcadeMachine
extends StaticBody3D
## Videospielautomat in der Bar (Spielkonzept 6.10, Entscheidungen 28.10. und 2.11.): ein aufrechtes Spielgerät mit
## Leuchtschild, gewölbter Bildröhre, Joystick und zwei Knöpfen. Zwei Spiele, beide eigene Entwürfe statt Tetris und
## Pac-Man:
## - „deadra“: Fünferformen aus Gespenstern, Kürbissen und Totenschädeln fallen in ein Feld 12 × 18, volle Reihen
##   verschwinden.
## - „ghost_hotel“: ein Männchen sammelt Kürbisse in Hotelfluren, Lakengespenster jagen es; mit einer Laterne
##   blinken sie rot, fliehen und lassen sich verbannen – ihre Augen wandern zurück in den Startraum.
## Eine Runde kostet PRICE Geld, Gewinn gibt es keinen. Man steht davor (Player.stand_at, konzentriert wie am
## Spieltisch: Vorwarnungen fallen weniger auf), die Bewegungstasten steuern, [Leertaste] dreht, [Esc] hört auf; die
## Maus schaut sich weiter um. Kommt etwas in die Nähe, lässt man den Joystick los. Jedes Gerät hat seine eigene
## Bestenliste (LIST_SIZE Plätze, gespeichert): darin stehen alte Einträge von früher, du als „DU“ und Gäste, die
## tagsüber selbst eine Münze einwerfen (Kinder und manche Erwachsene). Wer zusieht, wie du einen stolzen Gast
## überholst, ist gekränkt, andere freuen sich mit. Lärm mittel („arcade“ alle NOISE_EVERY s, „arcade_over“ beim
## Spielende). Ohne Spieler läuft die Vorführung (Attract-Modus) im Wechsel mit der Bestenliste. Der Bildschirm ist
## ein kleines Pixelbild (SCREEN_PX), das nur neu gemalt wird, wenn der Spieler in der Nähe ist. Ursprung am Boden,
## lokale +Z = Front.
## Modell: assets/models/arcade_machine.glb (tools/build_arcade.py, Sketchfab „Arcade Machine“ von Tomas_Tew, CC-BY);
## Gehäusebilder je Spiel aus tools/arcade_art.py (Farbe je Spiel, Normal Map und Rauheit gemeinsam).

enum Mode { ATTRACT, PLAY, GUEST }

const SIZE := Vector3(0.73, 1.82, 0.93)     ## Rumpf des Modells (tools/build_arcade.py)
const MODEL := "res://assets/models/arcade_machine.glb"
const TEX := "res://assets/textures/arcade_%s.png"          ## Farbe je Spiel, %s = game
const STICK_TEX := "res://assets/textures/arcade_%s_stick.png"
const NORMAL := "res://assets/textures/arcade_normal.png"
const ROUGH := "res://assets/textures/arcade_rough.png"       ## Rot = Leuchtmaske des Schilds, Grün = Rauheit
const SCREEN_PX := Vector2i(120, 160)      ## Hochformat wie bei alten Automaten
## Mittellinie der Bildröhre (unten, oben) aus tools/build_arcade.py – dort sitzt „Münze einwerfen“
const SCREEN_BOTTOM := Vector3(0.0, 1.058, -0.003)
const SCREEN_TOP := Vector3(0.0, 1.465, -0.094)
## Lage des Pixelbilds in den UVs der Röhre (links, unten, rechts, oben): volle Höhe, Seitenverhältnis 3 : 4 –
## die Röhre ist zu den Seiten stark gewölbt, in der Mitte sind 0,1 u etwa 8,6 cm breit
const PICTURE_RECT := Vector4(0.32, 0.222, 0.68, 0.799)
const MARQUEE_GLOW := 1.4                  ## so hell leuchtet das Schild in seinen eigenen Farben
const TICK := 0.18                         ## Sekunden je Bild der Vorführung
const AWAKE_RANGE := 14.0                  ## weiter weg steht das Bild still
const TITLES := {"deadra": "Deadra", "ghost_hotel": "Ghost Hotel"}
## Je Spiel: Farbe des Scheins vor dem Bildschirm und der beiden Knöpfe (Gehäuse und Schild stecken in der Textur)
const LOOKS := {
	"deadra": {"glow": Color(0.75, 0.95, 0.55), "buttons": [Color(0.45, 0.95, 0.25), Color(0.55, 0.15, 0.7)]},
	"ghost_hotel": {"glow": Color(1.0, 0.6, 0.2), "buttons": [Color(1.0, 0.5, 0.1), Color(0.92, 0.93, 0.97)]},
}

## Spielen (Entscheidung 2.11.): Preis je Runde, Standplatz vor dem Gerät, Blickwinkel dort (Anteil von Settings.fov)
const PRICE := 1
const PLAY_SPOT := 0.8
const ZOOM := 0.8
const NOISE_EVERY := 4.0                   ## so oft dudelt der Automat beim Spielen (Lärm „arcade“)
const REPEAT_DELAY := 0.2                  ## gehaltene Taste wiederholt nach so vielen Sekunden …
const REPEAT_RATE := 0.07                  ## … alle so viele
## Bestenliste: Plätze, so lange steht sie nach einem Spiel auf dem Schirm, Wechsel in der Vorführung (Bilder à TICK)
const LIST_SIZE := 8
const LIST_SHOW := 8.0
const ATTRACT_DEMO := 66
const ATTRACT_LIST := 33
## Einträge von früher – niemand im Hotel kennt die Kürzel
const OLD_SCORES := {
	"deadra": [["OTT", 3200], ["MKW", 2400], ["LIZ", 1800], ["JAN", 1100], ["BEN", 600]],
	"ghost_hotel": [["RAY", 4100], ["SUE", 3300], ["OTT", 2500], ["KAI", 1600], ["MEL", 900]],
}
## Gäste spielen selbst: so oft schaut ein Gerät nach einem freien Gast, mit dieser Chance, so lange spielt er, und so
## viele Punkte macht ein mittelguter (× 0,3 … 1,8 nach Geschick, das aus seiner ID folgt – kein Zufallsaufruf im
## GuestGenerator)
const GUEST_CHECK := 30.0
const GUEST_CHANCE := 0.25
const GUEST_LENGTH := Vector2(40.0, 80.0)
const GUEST_SCORE := {"deadra": 2500.0, "ghost_hotel": 3500.0}
const WATCH_RANGE := 8.0                   ## so nah muss man stehen, um einen Gast spielen zu sehen (und umgekehrt)

static var _textures := {}
## Für automatische Tests (--automaten=deadra|hotel --autoplay): spielt selbst mit zufälligen Eingaben
static var autoplay := false

## Kleine Schrift 3 × 5 für Punkte und Bestenliste (Umlaute werden zu Grundbuchstaben, _text)
const FONT := {
	"0": ["###", "#.#", "#.#", "#.#", "###"], "1": [".#.", "##.", ".#.", ".#.", "###"],
	"2": ["###", "..#", "###", "#..", "###"], "3": ["###", "..#", "###", "..#", "###"],
	"4": ["#.#", "#.#", "###", "..#", "..#"], "5": ["###", "#..", "###", "..#", "###"],
	"6": ["###", "#..", "###", "#.#", "###"], "7": ["###", "..#", "..#", ".#.", ".#."],
	"8": ["###", "#.#", "###", "#.#", "###"], "9": ["###", "#.#", "###", "..#", "###"],
	"A": ["###", "#.#", "###", "#.#", "#.#"], "B": ["##.", "#.#", "##.", "#.#", "##."],
	"C": ["###", "#..", "#..", "#..", "###"], "D": ["##.", "#.#", "#.#", "#.#", "##."],
	"E": ["###", "#..", "##.", "#..", "###"], "F": ["###", "#..", "##.", "#..", "#.."],
	"G": ["###", "#..", "#.#", "#.#", "###"], "H": ["#.#", "#.#", "###", "#.#", "#.#"],
	"I": ["###", ".#.", ".#.", ".#.", "###"], "J": ["..#", "..#", "..#", "#.#", "###"],
	"K": ["#.#", "#.#", "##.", "#.#", "#.#"], "L": ["#..", "#..", "#..", "#..", "###"],
	"M": ["#.#", "###", "###", "#.#", "#.#"], "N": ["##.", "#.#", "#.#", "#.#", "#.#"],
	"O": ["###", "#.#", "#.#", "#.#", "###"], "P": ["###", "#.#", "###", "#..", "#.."],
	"Q": ["###", "#.#", "#.#", "###", "..#"], "R": ["##.", "#.#", "##.", "#.#", "#.#"],
	"S": ["###", "#..", "###", "..#", "###"], "T": ["###", ".#.", ".#.", ".#.", ".#."],
	"U": ["#.#", "#.#", "#.#", "#.#", "###"], "V": ["#.#", "#.#", "#.#", "#.#", ".#."],
	"W": ["#.#", "#.#", "###", "###", "#.#"], "X": ["#.#", "#.#", ".#.", "#.#", "#.#"],
	"Y": ["#.#", "#.#", ".#.", ".#.", ".#."], "Z": ["###", "..#", ".#.", "#..", "###"],
	".": ["...", "...", "...", "...", ".#."], ":": ["...", ".#.", "...", ".#.", "..."],
	"-": ["...", "...", "###", "...", "..."], "!": [".#.", ".#.", ".#.", "...", ".#."],
}
const TEXT_COLOR := Color(1.0, 0.95, 0.6)

## Deadra: Feld, Kästchengröße in Pixeln, die zwölf Fünferformen (Spielkonzept 6.10)
const FIELD := Vector2i(12, 18)
const CELL := 6
const FIELD_AT := Vector2i(6, 36)
const PENTOMINOES := [
	[Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2)],   # F
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4)],   # I
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(1, 3)],   # L
	[Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(0, 3)],   # N
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 2)],   # P
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(1, 2)],   # T
	[Vector2i(0, 0), Vector2i(2, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1)],   # U
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)],   # V
	[Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)],   # W
	[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(1, 2)],   # X
	[Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, 2), Vector2i(1, 3)],   # Y
	[Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(1, 2), Vector2i(2, 2)],   # Z
]
## Punkte für 1 … 5 Reihen auf einmal (× Stufe); alle LINES_PER_LEVEL Reihen eine Stufe höher und schneller
const LINE_POINTS: Array[int] = [0, 100, 300, 500, 800, 1200]
const LINES_PER_LEVEL := 8
const FALL_TIME := 0.7                     ## Sekunden je Reihe auf Stufe 1, je Stufe × FALL_SPEEDUP
const FALL_SPEEDUP := 0.85
const SOFT_DROP := 0.05                    ## mit [S] fällt es so schnell
## Kästchenbilder 6 × 6 (# = Grundfarbe, o = dunkel, g = Stiel)
const TILES := {
	"ghost": [".####.", "#o##o#", "######", "######", "######", "#.##.#"],
	"pumpkin": ["..g...", ".####.", "#o##o#", "######", "#oooo#", ".####."],
	"skull": [".####.", "######", "#oo#oo", "######", ".#o#o.", ".####."],
}
const TILE_COLORS := {"ghost": Color(0.92, 0.94, 1.0), "pumpkin": Color(1.0, 0.5, 0.08), "skull": Color(0.86, 0.82, 0.68)}
const TILE_KINDS: Array[String] = ["ghost", "pumpkin", "skull"]

## Ghost Hotel: Hotelflure (# Wand, . Kürbis, L Laterne, S Startraum der Gespenster), 8 Pixel je Feld
const MAZE := [
	"###############",
	"#.....#.#.....#",
	"#.###.#.#.###.#",
	"#L...........L#",
	"#.###.#.#.###.#",
	"#.#...#.#...#.#",
	"#.#.###.###.#.#",
	"#.....#S#.....#",
	"#.#.#.###.#.#.#",
	"#...#.....#...#",
	"#.###.###.###.#",
	"#.............#",
	"#.###.#.#.###.#",
	"#.....#.#.....#",
	"#.###.#.#.###.#",
	"#L...........L#",
	"#.###.#.#.###.#",
	"#.....#.#.....#",
	"###############",
]
const MAZE_CELL := 8
const MAZE_AT := Vector2i(0, 8)
const MAN := ["...##...", "...##...", "..####..", ".#.##.#.", "...##...", "..#..#..", "..#..#.."]
const SHEET := ["..####..", ".######.", "##o##o##", "########", "########", "########", "#.##.##.", "........"]
const EYES := ["........", "........", ".##..##.", ".#o..#o.", "........", "........", "........", "........"]
const SCARED_TICKS := 24                   ## Vorführung: so lange blinken die Gespenster nach einer Laterne rot
const GHOST_GAPS: Array[int] = [5, 9, 13]  ## Vorführung: so viele Felder laufen die Gespenster hinter dem Männchen
## Spielen: Startfelder, Sekunden je Feld (je Stufe × HOTEL_SPEEDUP), so lange blinken die Gespenster rot (je Stufe
## kürzer, nie unter SCARED_MIN), Wartezeit der drei Gespenster im Startraum, Leben, Punkte
const MAN_START := Vector2i(7, 11)
const HOME := Vector2i(7, 7)
const MAN_STEP := 0.17
const GHOST_STEP := 0.21
const SCARED_STEP := 0.34
const EYES_STEP := 0.08
const HOTEL_SPEEDUP := 0.93
const SCARED_TIME := 7.0
const SCARED_MIN := 3.0
const GHOST_RELEASE: Array[float] = [0.5, 4.0, 8.0]
const LIVES := 3
const PUMPKIN_POINTS := 10
const LANTERN_POINTS := 50
const GHOST_POINTS := 200                  ## verdoppelt sich je Gespenst derselben Laterne
const DIRS: Array[Vector2i] = [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]
const DIR_KEYS: Array[String] = ["move_forward", "move_left", "move_back", "move_right"]

var game := "deadra"

var _image: Image
var _texture: ImageTexture
var _coin_label: Label3D
var _tick := 0.0
var _frame := 0
var _rng := RandomNumberGenerator.new()
var _mode := Mode.ATTRACT
var _dirty := false
## Bestenliste: [{"name", "score", "who"}] absteigend; who = Gast-ID, „player“ oder "" (von früher)
var _scores: Array[Dictionary] = []
var _list_left := 0.0                      ## so lange steht die Bestenliste noch nach einem Spiel
var _highlight := -1                       ## dieser Platz blinkt darin
var _score := 0
var _level := 1
var _noise_left := 0.0
var _held := {}                            ## gehaltene Taste → Sekunden bis zur nächsten Wiederholung
var _bot := {}                             ## autoplay: Tasten dieses Bilds
var _bot_plan := {}                        ## autoplay Deadra: {"turns", "x"} für das fallende Teil
## Gast am Gerät
var _guest: Guest
var _guest_timer := GUEST_CHECK
var _guest_time := 0.0
var _guest_length := 0.0
## Deadra: liegende Kästchen (Vector2i → Art), fallendes Teil (gedrehte Kästchen), Reihen, Fallzeit
var _stack := {}
var _cells: Array = []
var _piece_kind := 0
var _piece_at := Vector2i.ZERO
var _next_piece := 0
var _lines := 0
var _fall := 0.0
## Ghost Hotel: übrige Kürbisse und Laternen (Feld → true); Vorführung: Rundweg, Stelle darauf, Angst-Zähler
var _dots := {}
var _loop: Array[Vector2i] = []
var _step := 0
var _scared := 0
## Ghost Hotel spielen: Männchen, Richtung, gewünschte Richtung, Zeit bis zum nächsten Feld, Leben, Pause nach Tod
## oder geschaffter Runde, Kette gefangener Gespenster einer Laterne, Gespenster
## [{"cell", "dir", "state": home|out|eyes, "wait", "timer", "scared"}]
var _man := MAN_START
var _dir := Vector2i.LEFT
var _want := Vector2i.LEFT
var _man_timer := 0.0
var _lives := LIVES
var _pause := 0.0
var _dying := false
var _combo := 0
var _ghosts: Array[Dictionary] = []


func setup(which: String) -> ArcadeMachine:
	game = which if LOOKS.has(which) else "deadra"
	return self


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	add_to_group("arcades")
	set_meta("interactable", self)
	_rng.seed = hash(game)
	var look: Dictionary = LOOKS[game]
	# Kollision: hinten der hohe Rumpf, vorn der Unterbau bis unter das Bedienfeld
	Geo.add_box_shape(self, Vector3(SIZE.x, SIZE.y, 0.566), Vector3(0, SIZE.y / 2.0, -0.183))
	Geo.add_box_shape(self, Vector3(SIZE.x, 0.96, 0.366), Vector3(0, 0.48, 0.283))
	var model := (load(MODEL) as PackedScene).instantiate()
	add_child(model)
	var cabinet := ShaderMaterial.new()
	cabinet.shader = load("res://shaders/psx_model.gdshader")
	cabinet.set_shader_parameter("albedo_tex", _tex(TEX % game))
	cabinet.set_shader_parameter("normal_tex", _tex(NORMAL, true))
	cabinet.set_shader_parameter("use_normal", true)
	cabinet.set_shader_parameter("roughness_tex", _tex(ROUGH))
	cabinet.set_shader_parameter("glow_tex", _tex(ROUGH))
	cabinet.set_shader_parameter("emission", Color.WHITE)
	cabinet.set_shader_parameter("emission_energy", MARQUEE_GLOW)
	cabinet.set_shader_parameter("glow_albedo", true)
	(model.find_child("cabinet") as MeshInstance3D).material_override = cabinet
	var ball := StandardMaterial3D.new()
	ball.albedo_texture = _tex(STICK_TEX % game)
	ball.roughness = 0.25
	var ring := StandardMaterial3D.new()
	ring.albedo_color = Color(0.05, 0.05, 0.055)
	ring.roughness = 0.6
	var stick := model.find_child("stick") as MeshInstance3D
	stick.set_surface_override_material(0, ball)
	stick.set_surface_override_material(1, ring)
	for i in 2:
		var button := StandardMaterial3D.new()
		button.albedo_color = look["buttons"][i]
		button.roughness = 0.3
		(model.find_child("button_" + "ab"[i]) as MeshInstance3D).material_override = button
	# Bildröhre: das Pixelbild über shaders/arcade_screen.gdshader
	_image = Image.create(SCREEN_PX.x, SCREEN_PX.y, false, Image.FORMAT_RGBA8)
	_texture = ImageTexture.create_from_image(_image)
	var glass := ShaderMaterial.new()
	glass.shader = load("res://shaders/arcade_screen.gdshader")
	glass.set_shader_parameter("picture", _texture)
	glass.set_shader_parameter("picture_rect", PICTURE_RECT)
	glass.set_shader_parameter("picture_px", Vector2(SCREEN_PX))
	var tube := model.find_child("screen") as MeshInstance3D
	tube.material_override = glass
	tube.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var up := (SCREEN_TOP - SCREEN_BOTTOM).normalized()
	_coin_label = Label3D.new()
	_coin_label.text = "MÜNZE EINWERFEN"
	_coin_label.font_size = 32
	_coin_label.pixel_size = 0.0007
	_coin_label.outline_size = 8
	_coin_label.outline_modulate = Color(0, 0, 0)
	_coin_label.modulate = Color(1.0, 0.95, 0.6)
	_coin_label.position = SCREEN_BOTTOM + up * 0.045 + Vector3(0, -up.z, up.y) * 0.004
	_coin_label.rotation.x = atan2(up.z, up.y)
	add_child(_coin_label)
	var light := OmniLight3D.new()
	light.light_color = look["glow"]
	light.light_energy = 0.25
	light.light_specular = 0.0                 # Schein der Röhre – kein Glanzpunkt auf ihrem eigenen Glas
	light.omni_range = 2.0
	light.position = Vector3(0, 1.3, 0.45)
	light.add_to_group("light_source")
	add_child(light)
	for entry: Array in OLD_SCORES[game]:
		_scores.append({"name": entry[0], "score": entry[1], "who": ""})
	_attract_start()
	_draw()


## Debug --automaten: vor die Automaten der Bar, Blick auf beide (bzw. alle) zugleich; side: schräg von der
## Seite (Seitenbilder).
static func debug_show(tree: SceneTree, side := false) -> void:
	var all := tree.get_nodes_in_group("arcades")
	if all.is_empty():
		push_warning("--automaten: kein Videoautomat im Plan")
		return
	var mid := Vector3.ZERO
	for a: ArcadeMachine in all:
		mid += a.global_position
	mid /= all.size()
	var out := (all[0] as ArcadeMachine).global_basis.z
	var at := mid + out * 1.9
	if side:
		at = mid + out * 1.3 + (all[0] as ArcadeMachine).global_basis.x * 1.8
	TeleportUI.place_player(at, Vector3(mid.x - at.x, 0, mid.z - at.z).normalized())


## Debug --automaten=deadra|hotel: Münze einwerfen und spielen (mit --autoplay spielt er selbst);
## --automaten=gast[,id]: der Gast (Standard das erste Kind) spielt Ghost Hotel, du siehst zu.
static func debug_play(tree: SceneTree, which: String, guest_id := "") -> void:
	var wanted := "ghost_hotel" if which in ["hotel", "gast"] else "deadra"
	var machine: ArcadeMachine = null
	for a: ArcadeMachine in tree.get_nodes_in_group("arcades"):
		if a.game == wanted:
			machine = a
			break
	if machine == null:
		push_warning("--automaten: kein Automat mit %s im Plan" % TITLES[wanted])
		return
	var front := machine.global_transform * Vector3(0, 0, PLAY_SPOT)
	if which != "gast":
		Game.money = maxi(Game.money, PRICE)
		TeleportUI.place_player(front, -machine.global_basis.z)
		machine.interact(Game.player)
		return
	var guest: Guest = Game.social.find_guest(guest_id) if guest_id != "" else null
	if guest == null:
		for g: Guest in Game.social.living_guests():
			if g.is_child():
				guest = g
				break
	if guest == null:
		push_warning("--automaten=gast: kein Gast")
		return
	guest.global_position = machine.global_transform * Vector3(0.9, 0.05, 1.6)
	guest._set_idle(1.0)
	TeleportUI.place_player(machine.global_transform * Vector3(-1.2, 0, 2.0), -machine.global_basis.z)
	machine._guest_begin(guest)
	machine._guest_length = 20.0


## Textur mit Mipmaps (normal: gemittelte Normalen wieder auf Länge 1), einmal geladen für alle Automaten
static func _tex(path: String, normal := false) -> ImageTexture:
	if not _textures.has(path):
		var img := (load(path) as Texture2D).get_image()
		img.decompress()
		img.generate_mipmaps(normal)
		_textures[path] = ImageTexture.create_from_image(img)
	return _textures[path]


# --- Spielen und Bestenliste ---------------------------------------------------------------------------------

func get_prompt(_player: Player) -> String:
	var title: String = TITLES[game]
	if _mode == Mode.PLAY:
		return ""
	if _mode == Mode.GUEST and is_instance_valid(_guest):
		return "%s – %s spielt gerade" % [title, _guest.display_name]
	if Game.money < PRICE:
		return "%s – %d Geld, so viel hast du nicht" % [title, PRICE]
	return "%s spielen – %d Geld [E]" % [title, PRICE]


func interact(player: Player) -> void:
	if _mode != Mode.ATTRACT or Game.money < PRICE:
		return
	Game.money -= PRICE
	Game.noise("arcade_coin", global_transform * SCREEN_BOTTOM, player)
	player.stand_at(global_transform * Vector3(0, 0, PLAY_SPOT), global_transform * ((SCREEN_BOTTOM + SCREEN_TOP) / 2.0))
	player.fov_zoom = ZOOM
	_mode = Mode.PLAY
	_list_left = 0.0
	_score = 0
	_level = 1
	_noise_left = 0.0
	_held.clear()
	_coin_label.visible = false
	var stop := Keys.tag("pause")
	if game == "deadra":
		_deadra_new()
		Game.say("%s %s schieben · %s oder %s drehen · %s schneller · %s aufhören" % [Keys.tag("move_left"),
			Keys.tag("move_right"), Keys.tag("move_forward"), Keys.tag("jump"), Keys.tag("move_back"), stop], 5.0)
	else:
		_hotel_new()
		Game.say("%s %s %s %s laufen · Laternen machen die Gespenster harmlos · %s aufhören" % [Keys.tag("move_forward"),
			Keys.tag("move_left"), Keys.tag("move_back"), Keys.tag("move_right"), stop], 5.0)
	_draw()
	if Game.tracing:
		print("[Automat] %s: Münze eingeworfen (Geld %d)" % [TITLES[game], Game.money])


## [Esc] beim Spielen hört auf (statt des Pausenmenüs) – vor _unhandled_input der Menüs.
func _input(event: InputEvent) -> void:
	if _mode == Mode.PLAY and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_game_over("Du lässt den Joystick los.")


func _process(delta: float) -> void:
	if _mode == Mode.PLAY:
		_update_play(delta)
		return
	_update_guest(delta)
	_list_left = maxf(0.0, _list_left - delta)
	_tick += delta
	if _tick < TICK:
		return
	_tick = 0.0
	if Game.player and Game.player.global_position.distance_to(global_position) > AWAKE_RANGE:
		return
	_frame += 1
	_coin_label.visible = _mode == Mode.ATTRACT and _frame % 6 < 4
	if game == "deadra":
		_deadra_step()
	else:
		_hotel_step()
	_draw()


func _update_play(delta: float) -> void:
	var player := Game.player
	if player == null or player.dead or not player.at_oche or player.hiding or player.gripped:
		_game_over("")
		return
	if _danger():
		_game_over("Du lässt den Joystick los – irgendetwas stimmt hier nicht.")
		return
	_noise_left -= delta
	if _noise_left <= 0.0:
		_noise_left = NOISE_EVERY
		Game.noise("arcade", global_transform * SCREEN_TOP, player)
	if autoplay:
		_bot_input()
	if game == "deadra":
		_deadra_play(delta)
	else:
		_hotel_play(delta)
	_frame = Engine.get_process_frames() / 8
	if _dirty and _mode == Mode.PLAY:
		_dirty = false
		_draw()


## Vorwarnung in der Nähe (wie beim Darts allein)?
func _danger() -> bool:
	return not Game.director.is_quiet(global_position, 20.0) or Game.director.long_signal_near(global_position)


## Taste gerade gedrückt – mit repeat auch wiederholt, solange man sie hält.
func _press(action: String, delta: float, repeat := true) -> bool:
	if autoplay:
		return _bot.get(action, false)
	if not Input.is_action_pressed(action):
		_held.erase(action)
		return false
	if not _held.has(action):
		_held[action] = REPEAT_DELAY
		return true
	_held[action] = float(_held[action]) - delta
	if repeat and float(_held[action]) <= 0.0:
		_held[action] = float(_held[action]) + REPEAT_RATE
		return true
	return false


func _down(action: String) -> bool:
	return _bot.get(action, false) if autoplay else Input.is_action_pressed(action)


## autoplay: Deadra sucht für jedes Teil Drehung und Spalte (_bot_best), dreht, schiebt und lässt fallen;
## Ghost Hotel biegt zufällig ab.
func _bot_input() -> void:
	_bot.clear()
	if game == "deadra":
		if int(_bot_plan.get("turns", 0)) > 0:
			_bot["jump"] = true
			_bot_plan["turns"] = int(_bot_plan["turns"]) - 1
		elif _piece_at.x < int(_bot_plan.get("x", _piece_at.x)):
			_bot["move_right"] = true
		elif _piece_at.x > int(_bot_plan.get("x", _piece_at.x)):
			_bot["move_left"] = true
		else:
			_bot["move_back"] = true
	elif _rng.randf() < 0.06:
		_bot[DIR_KEYS[_rng.randi() % DIR_KEYS.size()]] = true


## Spiel vorbei (auch abgebrochen): in die Bestenliste, Lärm, aufstehen; message "" = still (Spieler weg).
func _game_over(message: String) -> void:
	_mode = Mode.ATTRACT
	_held.clear()
	Game.noise("arcade_over", global_transform * SCREEN_TOP, Game.player)
	var rank := _add_score("DU", _score, "player")
	_highlight = rank
	_list_left = LIST_SHOW
	if Game.player and Game.player.at_oche:
		Game.player.leave_oche()
	if message != "":
		Game.say(message, 2.5)
	if rank >= 0:
		Game.say("Spiel vorbei – %d Punkte, Platz %d der Bestenliste." % [_score, rank + 1], 4.0)
		_overtaken(rank)
	else:
		Game.say("Spiel vorbei – %d Punkte." % _score, 3.0)
	if Game.tracing:
		print("[Automat] %s: Spiel vorbei mit %d Punkten (Stufe %d), %s" % [TITLES[game], _score, _level,
			"Platz %d" % (rank + 1) if rank >= 0 else "nicht in der Bestenliste"])
	_attract_start()
	_draw()


## In die Bestenliste eintragen; gibt den Platz zurück (0 = ganz oben) oder -1, wenn es nicht reicht.
func _add_score(entry_name: String, score: int, who: String) -> int:
	if score <= 0:
		return -1
	var rank := _scores.size()
	for i in _scores.size():
		if score > int(_scores[i]["score"]):
			rank = i
			break
	if rank >= LIST_SIZE:
		return -1
	_scores.insert(rank, {"name": entry_name, "score": score, "who": who})
	if _scores.size() > LIST_SIZE:
		_scores.resize(LIST_SIZE)
	return rank


## Du hast einen Gast überholt, der zusieht: stolze sind gekränkt, andere freuen sich mit (6.10). Einer reicht.
func _overtaken(rank: int) -> void:
	if Game.social == null:
		return
	for i in range(rank + 1, _scores.size()):
		var who := String(_scores[i]["who"])
		if who == "" or who == "player":
			continue
		var g := Game.social.guest_by_id(who)
		if g == null or g.dead or g.global_position.distance_to(global_position) > WATCH_RANGE:
			continue
		if float(g.profile.get("dice", {}).get("pride", 0.5)) > 0.6:
			Game.social.change_relation(g, -3.0)
			Game.say("%s schnaubt – der Platz in der Bestenliste ist weg." % g.display_name, 3.5)
		else:
			Game.social.change_relation(g, 3.0)
			Game.say("%s pfeift anerkennend." % g.display_name, 3.0)
		return


## Kürzel für die Bestenliste: die ersten drei Buchstaben des Namens.
static func initials(text: String) -> String:
	var out := ""
	for c in text.to_upper().replace("Ä", "A").replace("Ö", "O").replace("Ü", "U").replace("ß", "S"):
		if c >= "A" and c <= "Z":
			out += c
		if out.length() == 3:
			break
	return out


func save_state() -> Dictionary:
	return {"scores": _scores.map(func(e: Dictionary) -> Array: return [e["name"], e["score"], e["who"]])}


func load_state(d: Dictionary) -> void:
	if _mode == Mode.PLAY and Game.player and Game.player.at_oche:
		Game.player.leave_oche()
	_mode = Mode.ATTRACT
	_guest = null
	_scores.clear()
	for e: Array in d.get("scores", []):
		_scores.append({"name": String(e[0]), "score": int(e[1]), "who": String(e[2])})
	_attract_start()
	_draw()


# --- Gäste spielen selbst ------------------------------------------------------------------------------------

## Mag dieser Gast Videospiele? Kinder immer, sonst jeder dritte (fest aus der ID). Geschick ebenso fest.
static func likes(g: Guest) -> bool:
	return g.is_child() or absi(hash(g.id + "arcade")) % 3 == 0


func skill_of(g: Guest) -> float:
	return float(absi(hash(g.id + game)) % 1000) / 1000.0


func _update_guest(delta: float) -> void:
	if _guest == null:
		_guest_timer -= delta
		if _guest_timer > 0.0:
			return
		_guest_timer = GUEST_CHECK
		if Game.social == null or not Game.director.is_quiet(global_position, 25.0) or randf() > GUEST_CHANCE:
			return
		var free: Array = Game.social.living_guests().filter(func(g: Guest) -> bool:
			return g.state == Guest.State.IDLE and g.fear < 40.0 and not g.invited and likes(g))
		if not free.is_empty():
			_guest_begin(free[randi() % free.size()])
		return
	if not is_instance_valid(_guest) or _guest.dead or _guest.state != Guest.State.MINIGAME or not Game.director.is_quiet(global_position, 22.0):
		_guest_end(false)
		return
	if not _guest.seated:
		return
	_guest_time += delta
	_noise_left -= delta
	if _noise_left <= 0.0:
		_noise_left = NOISE_EVERY
		Game.noise("arcade", global_transform * SCREEN_TOP, _guest)
	if _guest_time >= _guest_length:
		_guest_end(true)


func _guest_begin(g: Guest) -> void:
	_guest = g
	_mode = Mode.GUEST
	_guest_time = 0.0
	_guest_length = randf_range(GUEST_LENGTH.x, GUEST_LENGTH.y)
	_noise_left = 0.0
	_list_left = 0.0
	_coin_label.visible = false
	g.stand_for_game(global_transform * Vector3(0, 0, PLAY_SPOT), global_transform * ((SCREEN_BOTTOM + SCREEN_TOP) / 2.0))
	if Game.tracing:
		print("[Automat] %s geht an %s" % [g.display_name, TITLES[game]])


func _guest_end(completed: bool) -> void:
	var g := _guest
	_guest = null
	_mode = Mode.ATTRACT
	if not is_instance_valid(g):
		_attract_start()
		return
	if completed:
		var score := int(GUEST_SCORE[game] * lerpf(0.3, 1.8, skill_of(g)) * randf_range(0.6, 1.3) * (1.0 - g.fear / 150.0))
		score = maxi(10, score / 10 * 10)
		var rank := _add_score(initials(g.display_name), score, g.id)
		_highlight = rank
		_list_left = LIST_SHOW
		var near := Game.player != null and Game.player.global_position.distance_to(global_position) < WATCH_RANGE
		if near and rank >= 0:
			Game.say("%s tippt die Buchstaben ein: Platz %d bei %s." % [g.display_name, rank + 1, TITLES[game]], 3.5)
		elif near:
			Game.say("%s haut auf den Automaten – Spiel vorbei." % g.display_name, 3.0)
		Game.noise("arcade_over", global_transform * SCREEN_TOP, g)
		if Game.tracing:
			print("[Automat] %s spielt %s: %d Punkte, %s" % [g.display_name, TITLES[game], score,
				"Platz %d" % (rank + 1) if rank >= 0 else "nicht in der Bestenliste"])
	if not g.dead:
		g.end_game()
	_attract_start()


# --- Bild ----------------------------------------------------------------------------------------------------

func _attract_start() -> void:
	if game == "deadra":
		_deadra_start()
	else:
		_hotel_start()


func _draw() -> void:
	_image.fill(Color(0.01, 0.01, 0.02))
	if _mode == Mode.ATTRACT and (_list_left > 0.0 or _frame % (ATTRACT_DEMO + ATTRACT_LIST) >= ATTRACT_DEMO):
		_list_draw()
	elif game == "deadra":
		_deadra_draw()
	else:
		_hotel_draw()
	_texture.update(_image)


func _list_draw() -> void:
	_text_center(8, "BESTENLISTE", TEXT_COLOR)
	_text_center(18, TITLES[game].to_upper(), LOOKS[game]["glow"])
	for i in _scores.size():
		var e := _scores[i]
		var color := TEXT_COLOR if e["who"] == "player" else Color(0.8, 0.8, 0.85)
		if i == _highlight and _list_left > 0.0 and _frame % 2 == 0:
			color = Color(1.0, 0.35, 0.2)
		var y := 34 + i * 12
		_text(Vector2i(14, y), "%d." % (i + 1), color)
		_text(Vector2i(30, y), String(e["name"]), color)
		var score := str(e["score"])
		_text(Vector2i(106 - score.length() * 4, y), score, color)
	_text_center(140, "%d GELD JE SPIEL" % PRICE, Color(0.6, 0.6, 0.65))


func _text(at: Vector2i, text: String, color: Color) -> void:
	var x := at.x
	for c in text.to_upper().replace("Ä", "A").replace("Ö", "O").replace("Ü", "U"):
		var rows: Array = FONT.get(c, [])
		for y in rows.size():
			var row: String = rows[y]
			for i in 3:
				if row[i] == "#" and x + i >= 0 and x + i < SCREEN_PX.x and at.y + y < SCREEN_PX.y:
					_image.set_pixel(x + i, at.y + y, color)
		x += 4


func _text_center(y: int, text: String, color: Color) -> void:
	_text(Vector2i((SCREEN_PX.x - text.length() * 4 + 1) / 2, y), text, color)


func _best() -> int:
	return int(_scores[0]["score"]) if not _scores.is_empty() else 0


# --- Deadra -------------------------------------------------------------------------------------------------

## Vorführung: unten liegt ein zerklüfteter Haufen, oben fällt ein Teil nach dem anderen hinein.
func _deadra_start() -> void:
	_stack.clear()
	for y in range(FIELD.y - 6, FIELD.y):
		for x in FIELD.x:
			if _rng.randf() < 0.35 + (y - (FIELD.y - 6)) * 0.1:
				_stack[Vector2i(x, y)] = _rng.randi() % TILE_KINDS.size()
	_next_piece = _rng.randi() % PENTOMINOES.size()
	_deadra_spawn()


## Spielen: leeres Feld, erstes Teil oben in der Mitte.
func _deadra_new() -> void:
	_stack.clear()
	_lines = 0
	_fall = FALL_TIME
	_next_piece = _rng.randi() % PENTOMINOES.size()
	_deadra_spawn()


## Nächstes Teil oben – ob es noch hinpasst, prüft _deadra_play.
func _deadra_spawn() -> void:
	_cells = PENTOMINOES[_next_piece].duplicate()
	_piece_kind = _rng.randi() % TILE_KINDS.size()
	_next_piece = _rng.randi() % PENTOMINOES.size()
	if _mode == Mode.PLAY:
		_piece_at = Vector2i(FIELD.x / 2 - 1, 0)
		if autoplay:
			_bot_plan = _bot_best()
	else:
		_piece_at = Vector2i(_rng.randi_range(0, FIELD.x - 3), 0)


func _deadra_fits(at: Vector2i, cells: Array) -> bool:
	for c: Vector2i in cells:
		var p := at + c
		if p.x < 0 or p.x >= FIELD.x or p.y >= FIELD.y or _stack.has(p):
			return false
	return true


## Vorführung: eine Reihe tiefer, sonst hinlegen; zu hoch gestapelt beginnt sie von vorn.
func _deadra_step() -> void:
	if _deadra_fits(_piece_at + Vector2i(0, 1), _cells):
		_piece_at.y += 1
		return
	_deadra_lock()
	var top := FIELD.y
	for p: Vector2i in _stack:
		top = mini(top, p.y)
	if top < 6:
		_deadra_start()
	else:
		_deadra_spawn()


## Teil hinlegen, volle Reihen versinken lassen; gibt die Zahl der Reihen zurück.
func _deadra_lock() -> int:
	for c: Vector2i in _cells:
		_stack[_piece_at + c] = _piece_kind
	var cleared := 0
	for y in FIELD.y:
		var full := true
		for x in FIELD.x:
			full = full and _stack.has(Vector2i(x, y))
		if full:
			cleared += 1
			var moved := {}
			for p: Vector2i in _stack:
				if p.y < y:
					moved[p + Vector2i(0, 1)] = _stack[p]
				elif p.y > y:
					moved[p] = _stack[p]
			_stack = moved
	return cleared


func _deadra_play(delta: float) -> void:
	if _press("move_left", delta):
		_deadra_shift(-1)
	if _press("move_right", delta):
		_deadra_shift(1)
	if _press("jump", delta, false) or _press("move_forward", delta, false):
		_deadra_rotate()
	_fall -= delta
	if _fall > 0.0:
		return
	_fall = SOFT_DROP if _down("move_back") else FALL_TIME * pow(FALL_SPEEDUP, _level - 1)
	_dirty = true
	if _deadra_fits(_piece_at + Vector2i(0, 1), _cells):
		_piece_at.y += 1
		return
	var cleared := _deadra_lock()
	if cleared > 0:
		_score += LINE_POINTS[mini(cleared, LINE_POINTS.size() - 1)] * _level
		_lines += cleared
		_level = 1 + _lines / LINES_PER_LEVEL
	_deadra_spawn()
	if not _deadra_fits(_piece_at, _cells):
		_game_over("")


func _deadra_shift(dx: int) -> void:
	if _deadra_fits(_piece_at + Vector2i(dx, 0), _cells):
		_piece_at.x += dx
		_dirty = true


## Drehen um 90°, an der Wand oder am Haufen notfalls ein, zwei Felder zur Seite.
func _deadra_rotate() -> void:
	var turned := _turned(_cells)
	for kick: int in [0, -1, 1, -2, 2]:
		if _deadra_fits(_piece_at + Vector2i(kick, 0), turned):
			_cells = turned
			_piece_at.x += kick
			_dirty = true
			return


## Kästchen um 90° gedreht, wieder an die obere linke Ecke gerückt
static func _turned(cells: Array) -> Array:
	var turned: Array = []
	var low := Vector2i(99, 99)
	for c: Vector2i in cells:
		var t := Vector2i(-c.y, c.x)
		turned.append(t)
		low = Vector2i(mini(low.x, t.x), mini(low.y, t.y))
	for i in turned.size():
		turned[i] = (turned[i] as Vector2i) - low
	return turned


## autoplay: beste Drehung und Spalte – volle Reihen gut, Höhe, Löcher und Unebenheit schlecht (übliche Gewichte)
func _bot_best() -> Dictionary:
	var best := -INF
	var plan := {"turns": 0, "x": _piece_at.x}
	var cells := _cells
	for turns in 4:
		for x in range(-2, FIELD.x):
			var at := Vector2i(x, _piece_at.y)
			if not _deadra_fits(at, cells):
				continue
			while _deadra_fits(at + Vector2i(0, 1), cells):
				at.y += 1
			var stack := _stack.duplicate()
			for c: Vector2i in cells:
				stack[at + c] = 0
			var full := 0
			var heights := 0
			var holes := 0
			var bumps := 0
			var last := -1
			for y in FIELD.y:
				var row := 0
				for col in FIELD.x:
					row += 1 if stack.has(Vector2i(col, y)) else 0
				full += 1 if row == FIELD.x else 0
			for col in FIELD.x:
				var top := FIELD.y
				for y in FIELD.y:
					if stack.has(Vector2i(col, y)):
						top = mini(top, y)
					elif top < y:
						holes += 1
				heights += FIELD.y - top
				if last >= 0:
					bumps += absi(top - last)
				last = top
			var value := full * 0.76 - heights * 0.51 - holes * 0.36 - bumps * 0.18
			if value > best:
				best = value
				plan = {"turns": turns, "x": x}
		cells = _turned(cells)
	return plan


func _deadra_draw() -> void:
	var frame := Color(0.35, 0.3, 0.4)
	var green := Color(0.75, 0.95, 0.55)
	_image.fill_rect(Rect2i(FIELD_AT - Vector2i(2, 2), FIELD * CELL + Vector2i(4, 4)), frame)
	_image.fill_rect(Rect2i(FIELD_AT, FIELD * CELL), Color(0.04, 0.05, 0.04))
	for p: Vector2i in _stack:
		_tile(FIELD_AT + p * CELL, TILE_KINDS[_stack[p]])
	for c: Vector2i in _cells:
		_tile(FIELD_AT + (_piece_at + c) * CELL, TILE_KINDS[_piece_kind])
	# Vorschau rechts oben: das nächste Teil klein (3 Pixel je Kästchen)
	var preview := Vector2i(FIELD_AT.x + FIELD.x * CELL + 8, FIELD_AT.y)
	_image.fill_rect(Rect2i(preview - Vector2i(2, 2), Vector2i(22, 22)), frame)
	_image.fill_rect(Rect2i(preview, Vector2i(18, 18)), Color(0.04, 0.05, 0.04))
	for c: Vector2i in PENTOMINOES[_next_piece]:
		_image.fill_rect(Rect2i(preview + Vector2i(2, 2) + c * 3, Vector2i(3, 3)), green)
	if _mode != Mode.PLAY:
		# Vorführung: Punkte als Balken unter der Vorschau, damit es nach Spiel aussieht
		for i in 4:
			_image.fill_rect(Rect2i(preview.x, preview.y + 30 + i * 6, 6 + (i * 5 + _frame / 8) % 13, 3), Color(green, 0.8))
		_text_center(10, "DEADRA", green)
		return
	_text(Vector2i(6, 6), "PUNKTE", TEXT_COLOR)
	_text(Vector2i(34, 6), "%06d" % _score, TEXT_COLOR)
	_text(Vector2i(6, 16), "REKORD", Color(0.7, 0.7, 0.75))
	_text(Vector2i(34, 16), "%06d" % maxi(_best(), _score), Color(0.7, 0.7, 0.75))
	_text(Vector2i(preview.x - 2, preview.y + 28), "STUFE", green)
	_text(Vector2i(preview.x - 2, preview.y + 35), str(_level), TEXT_COLOR)
	_text(Vector2i(preview.x - 2, preview.y + 46), "REIHEN", green)
	_text(Vector2i(preview.x - 2, preview.y + 53), str(_lines), TEXT_COLOR)


func _tile(at: Vector2i, kind: String) -> void:
	var rows: Array = TILES[kind]
	var base: Color = TILE_COLORS[kind]
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			match row[x]:
				"#":
					_image.set_pixel(at.x + x, at.y + y, base)
				"o":
					_image.set_pixel(at.x + x, at.y + y, base.darkened(0.75))
				"g":
					_image.set_pixel(at.x + x, at.y + y, Color(0.2, 0.6, 0.15))


# --- Ghost Hotel ---------------------------------------------------------------------------------------------

## Vorführung: Das Männchen läuft die äußere Runde der Hotelflure ab, die Gespenster hinterher.
func _hotel_start() -> void:
	_loop.clear()
	var corners := [Vector2i(1, 3), Vector2i(13, 3), Vector2i(13, 15), Vector2i(1, 15)]
	for i in corners.size():
		var a: Vector2i = corners[i]
		var b: Vector2i = corners[(i + 1) % corners.size()]
		var d := (b - a).sign()
		var p := a
		while p != b:
			_loop.append(p)
			p += d
	_step = 0
	_scared = 0
	_hotel_fill()


## Überall wieder Kürbisse und Laternen
func _hotel_fill() -> void:
	_dots.clear()
	for y in MAZE.size():
		var row: String = MAZE[y]
		for x in row.length():
			if row[x] == "." or row[x] == "L":
				_dots[Vector2i(x, y)] = true


func _hotel_step() -> void:
	_step = (_step + 1) % _loop.size()
	var at := _loop[_step]
	if MAZE[at.y][at.x] == "L" and _dots.has(at):
		_scared = SCARED_TICKS
	_dots.erase(at)
	_scared = maxi(0, _scared - 1)
	if _step == 0:
		_hotel_fill()   # nach einer Runde liegen wieder überall Kürbisse


## Spielen: volle Flure, drei Leben.
func _hotel_new() -> void:
	_lives = LIVES
	_hotel_fill()
	_hotel_reset()


## Männchen und Gespenster auf ihre Startfelder (nach Tod oder geschaffter Runde)
func _hotel_reset() -> void:
	_man = MAN_START
	_dir = Vector2i.LEFT
	_want = Vector2i.LEFT
	_man_timer = MAN_STEP
	_dying = false
	_pause = 1.0
	_combo = 0
	_ghosts.clear()
	for i in GHOST_RELEASE.size():
		_ghosts.append({"cell": HOME, "dir": Vector2i.UP, "state": "home", "wait": GHOST_RELEASE[i], "timer": 0.0, "scared": 0.0})


## Begehbar? Den Startraum betreten nur Gespenster.
func _open(cell: Vector2i, ghost := false) -> bool:
	if cell.y < 0 or cell.y >= MAZE.size() or cell.x < 0 or cell.x >= String(MAZE[cell.y]).length():
		return false
	var c: String = MAZE[cell.y][cell.x]
	return c != "#" and (ghost or c != "S")


func _hotel_play(delta: float) -> void:
	for i in DIRS.size():
		if _press(DIR_KEYS[i], delta, false):
			_want = DIRS[i]
	if _pause > 0.0:
		_pause -= delta
		if _pause <= 0.0 and _dying:
			if _lives <= 0:
				_game_over("")
				return
			_hotel_reset()
		_dirty = true
		return
	var speed := pow(HOTEL_SPEEDUP, _level - 1)
	_man_timer -= delta
	if _man_timer <= 0.0:
		_man_timer += MAN_STEP * speed
		if _open(_man + _want):
			_dir = _want
		if _open(_man + _dir):
			_man += _dir
			_hotel_eat()
			_dirty = true
			if _hotel_caught() or _pause > 0.0:
				return
	for i in _ghosts.size():
		var g := _ghosts[i]
		g["scared"] = maxf(0.0, float(g["scared"]) - delta)
		if g["state"] == "home":
			g["wait"] = float(g["wait"]) - delta
			if float(g["wait"]) <= 0.0:
				g["state"] = "out"
				g["dir"] = Vector2i.UP
			continue
		g["timer"] = float(g["timer"]) - delta
		if float(g["timer"]) > 0.0:
			continue
		var step := EYES_STEP if g["state"] == "eyes" else (SCARED_STEP if float(g["scared"]) > 0.0 else GHOST_STEP * speed)
		g["timer"] = float(g["timer"]) + step
		_ghost_move(g, i)
		_dirty = true
		if g["state"] == "eyes" and g["cell"] == HOME:
			g["state"] = "home"
			g["wait"] = 2.0
			g["scared"] = 0.0
		if _hotel_caught():
			return


## Kürbis oder Laterne unter dem Männchen; alles leer = nächste Runde, schneller.
func _hotel_eat() -> void:
	if not _dots.has(_man):
		return
	_dots.erase(_man)
	if MAZE[_man.y][_man.x] == "L":
		_score += LANTERN_POINTS
		_combo = 0
		var scared := maxf(SCARED_MIN, SCARED_TIME - (_level - 1) * 0.5)
		for g in _ghosts:
			if g["state"] == "out":
				g["scared"] = scared
				g["dir"] = -(g["dir"] as Vector2i)
	else:
		_score += PUMPKIN_POINTS
	if _dots.is_empty():
		_level += 1
		_hotel_fill()
		_hotel_reset()


## Gespenst auf dem Feld des Männchens: rot blinkend wird es verbannt, sonst ist ein Leben weg.
func _hotel_caught() -> bool:
	for g in _ghosts:
		if g["state"] != "out" or g["cell"] != _man:
			continue
		if float(g["scared"]) > 0.0:
			_score += GHOST_POINTS * (1 << mini(_combo, 3))
			_combo += 1
			g["state"] = "eyes"
			g["scared"] = 0.0
			continue
		_lives -= 1
		_dying = true
		_pause = 1.6
		_dirty = true
		return true
	return false


## An jeder Kreuzung neu wählen, nie umkehren (außer in der Sackgasse): verfolgen, rot blinkend zufällig fliehen,
## als Augen heim. Das erste jagt das Männchen direkt, das zweite zielt vier Felder vor es, das dritte irrt öfter.
func _ghost_move(g: Dictionary, index: int) -> void:
	var cell: Vector2i = g["cell"]
	var dir: Vector2i = g["dir"]
	var eyes: bool = g["state"] == "eyes"
	var options: Array[Vector2i] = []
	for d: Vector2i in DIRS:
		var next := cell + d
		if d != -dir and _open(next, true) and (eyes or next != HOME):
			options.append(d)
	if options.is_empty():
		options.append(-dir)
	var pick: Vector2i = options[_rng.randi() % options.size()]
	if eyes or (float(g["scared"]) <= 0.0 and not (index == 2 and _rng.randf() < 0.35)):
		var target := HOME if eyes else (_man + _dir * 4 if index == 1 else _man)
		var best := INF
		for d in options:
			var dist := float((cell + d - target).length_squared())
			if dist < best:
				best = dist
				pick = d
	g["dir"] = pick
	g["cell"] = cell + pick


func _hotel_draw() -> void:
	var wall := Color(0.36, 0.16, 0.1)        # dunkles Holz der Flurwände
	var carpet := Color(0.12, 0.03, 0.05)     # Flurteppich
	for y in MAZE.size():
		var row: String = MAZE[y]
		for x in row.length():
			var at := MAZE_AT + Vector2i(x, y) * MAZE_CELL
			var cell := Vector2i(x, y)
			match row[x]:
				"#":
					_image.fill_rect(Rect2i(at, Vector2i(MAZE_CELL, MAZE_CELL)), wall)
					_image.fill_rect(Rect2i(at + Vector2i(1, 1), Vector2i(MAZE_CELL - 2, MAZE_CELL - 2)), wall.darkened(0.35))
				"S":
					_image.fill_rect(Rect2i(at, Vector2i(MAZE_CELL, MAZE_CELL)), Color(0.15, 0.15, 0.3))
				_:
					_image.fill_rect(Rect2i(at, Vector2i(MAZE_CELL, MAZE_CELL)), carpet)
					if not _dots.has(cell):
						continue
					if row[x] == "L":   # Laterne
						_image.fill_rect(Rect2i(at + Vector2i(2, 1), Vector2i(4, 1)), Color(0.2, 0.2, 0.2))
						_image.fill_rect(Rect2i(at + Vector2i(2, 2), Vector2i(4, 4)), Color(1.0, 0.85, 0.3) if _frame % 2 == 0 else Color(1.0, 0.7, 0.2))
					else:   # kleiner Kürbis
						_image.fill_rect(Rect2i(at + Vector2i(3, 3), Vector2i(2, 2)), Color(1.0, 0.5, 0.08))
						_image.set_pixel(at.x + 4, at.y + 2, Color(0.2, 0.6, 0.15))
	if _mode == Mode.PLAY:
		_hotel_draw_play()
		return
	for gap in GHOST_GAPS:
		var cell := _loop[posmod(_step - gap, _loop.size())]
		var color := Color(0.92, 0.94, 1.0)
		if _scared > 0:
			color = Color(1.0, 0.15, 0.1) if _frame % 2 == 0 else Color(0.5, 0.05, 0.05)
		_sprite(MAZE_AT + cell * MAZE_CELL, SHEET, color)
	_sprite(MAZE_AT + _loop[_step] * MAZE_CELL, MAN, Color(0.4, 0.85, 0.35))
	# Kopfzeile: Kürbisse dieser Runde als Punkte
	for i in mini(_step, 28):
		_image.fill_rect(Rect2i(4 + i * 4, 2, 2, 2), Color(1.0, 0.5, 0.08))


func _hotel_draw_play() -> void:
	var blink := Engine.get_process_frames() / 6 % 2 == 0
	for g in _ghosts:
		var at := MAZE_AT + (g["cell"] as Vector2i) * MAZE_CELL
		if g["state"] == "eyes":
			_sprite(at, EYES, Color(0.92, 0.94, 1.0))
			continue
		var color := Color(0.92, 0.94, 1.0)
		var scared := float(g["scared"])
		if scared > 1.5:
			color = Color(1.0, 0.15, 0.1) if blink else Color(0.5, 0.05, 0.05)
		elif scared > 0.0:   # gleich vorbei: rot und weiß im Wechsel
			color = Color(1.0, 0.15, 0.1) if blink else Color(0.92, 0.94, 1.0)
		_sprite(at, SHEET, color)
	if not (_dying and blink):
		_sprite(MAZE_AT + _man * MAZE_CELL, MAN, Color(0.4, 0.85, 0.35))
	_text(Vector2i(2, 1), str(_score), TEXT_COLOR)
	_text(Vector2i(44, 1), "HI %d" % maxi(_best(), _score), Color(0.7, 0.7, 0.75))
	for i in maxi(_lives, 0):
		_image.fill_rect(Rect2i(114 - i * 6, 2, 4, 4), Color(0.4, 0.85, 0.35))
	if _dying and _lives <= 0:
		_text_center(84, "SPIEL VORBEI", Color(1.0, 0.35, 0.2))


func _sprite(at: Vector2i, rows: Array, color: Color) -> void:
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if row[x] == "#":
				_image.set_pixel(at.x + x, at.y + y, color)
			elif row[x] == "o":
				_image.set_pixel(at.x + x, at.y + y, Color(0.05, 0.05, 0.1))
