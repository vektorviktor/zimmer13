class_name SlotMachine
extends StaticBody3D
## Spielautomat in der Bar (Spielkonzept 6.10, Entscheidung 28.10.): ein alter einarmiger Bandit. Für PRICE Geld
## drehen sich drei Walzen; drei Gleiche zahlen aus (PAYOUT), zwei Gleiche geben den Einsatz zurück – auf Dauer
## schluckt er mehr, als er gibt. Er rattert laut (Lärm „slot“), Gewinne klimpern noch lauter. Drei Augen zahlen
## nichts – sie starren dich nur an. Ab und zu läuft er nachts von selbst an, wenn niemand davorsteht (Spuk, lockt).
## Kein gespeicherter Zustand. Lokale +Z = Front.

const PRICE := 1
const SIZE := Vector3(0.6, 1.65, 0.5)
## Walzenbilder: Name, Farbe, Gewicht (wie oft es auf der Walze steht)
const SYMBOLS := [["7", Color(0.95, 0.15, 0.1), 1], ["KÜRBIS", Color(1.0, 0.55, 0.1), 2], ["GLOCKE", Color(0.95, 0.8, 0.2), 3],
	["KERZE", Color(0.95, 0.92, 0.8), 3], ["EULE", Color(0.6, 0.45, 0.3), 3], ["AUGE", Color(0.75, 0.2, 0.6), 1]]
const PAYOUT := {"7": 20, "KÜRBIS": 10, "GLOCKE": 5, "KERZE": 5, "EULE": 5, "AUGE": 0}
const SPIN_TIME := 1.6
const GHOST_EVERY := Vector2(240.0, 600.0)   ## Spielsekunden bis zum nächsten Selbstanlauf (Spuk)

var _reels: Array[Label3D] = []
var _spinning := 0.0
var _result: Array[int] = []
var _ghost_timer := 0.0
var _by_player := false


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	set_meta("interactable", self)
	add_to_group("time_skip")
	_ghost_timer = randf_range(GHOST_EVERY.x, GHOST_EVERY.y)
	var body := Mat.psx(Color(0.45, 0.06, 0.08))
	var chrome := Mat.metal()
	var dark := Mat.psx(Color(0.05, 0.05, 0.06))
	var glow := Mat.psx(Color(0.12, 0.1, 0.08), "", 1.0, Color(1.0, 0.85, 0.6), 0.8)
	Geo.box_part(self, Vector3(SIZE.x, 0.9, SIZE.z), Vector3(0, 0.45, 0), body)   # Sockel
	Geo.box_part(self, Vector3(SIZE.x, SIZE.y - 0.9, SIZE.z * 0.8), Vector3(0, 0.9 + (SIZE.y - 0.9) / 2.0, -SIZE.z * 0.1), body)
	var front := SIZE.z * 0.3 + 0.005
	Geo.mesh(self, Geo.box(Vector3(0.46, 0.2, 0.01)), glow, Vector3(0, 1.22, front))   # Walzenfenster
	Geo.mesh(self, Geo.box(Vector3(0.5, 0.05, 0.02)), chrome, Vector3(0, 1.1, front))
	Geo.mesh(self, Geo.box(Vector3(0.5, 0.05, 0.02)), chrome, Vector3(0, 1.345, front))
	Geo.mesh(self, Geo.box(Vector3(0.4, 0.06, 0.12)), dark, Vector3(0, 0.88, SIZE.z / 2.0 - 0.02))   # Münzschale
	Geo.mesh(self, Geo.box(Vector3(0.03, 0.07, 0.012)), Mat.psx(Color(0.8, 0.7, 0.3)), Vector3(0.18, 1.0, front + 0.006))   # Münzschlitz
	var arm := Geo.mesh(self, Geo.cylinder(0.015, 0.4, 6), chrome, Vector3(SIZE.x / 2.0 + 0.04, 1.25, 0.05))   # Hebel
	Geo.mesh(arm, Geo.sphere(0.04, 0.08, 8, 4), Mat.psx(Color(0.8, 0.1, 0.1)), Vector3(0, 0.22, 0))
	for i in 3:
		var reel := Label3D.new()
		reel.font_size = 32
		reel.pixel_size = 0.0011
		reel.outline_size = 6
		reel.outline_modulate = Color(0, 0, 0)
		reel.position = Vector3(-0.15 + i * 0.15, 1.22, front + 0.008)
		add_child(reel)
		_reels.append(reel)
		_show(i, randi() % SYMBOLS.size())
	var sign := Label3D.new()
	sign.text = "JACKPOT"
	sign.font_size = 40
	sign.pixel_size = 0.0025
	sign.modulate = Color(1.0, 0.85, 0.3)
	sign.outline_size = 8
	sign.outline_modulate = Color(0, 0, 0)
	sign.position = Vector3(0, 1.52, front + 0.01)
	add_child(sign)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.8, 0.55)
	light.light_energy = 0.3
	light.omni_range = 2.2
	light.position = Vector3(0, 1.3, front + 0.4)
	light.add_to_group("light_source")
	add_child(light)


func get_prompt(_player: Player) -> String:
	if _spinning > 0.0:
		return "Die Walzen drehen sich …"
	if Game.money < PRICE:
		return "Spielautomat – %d Geld, so viel hast du nicht" % PRICE
	return "Spielautomat: Hebel ziehen – %d Geld [E]" % PRICE


func interact(_player: Player) -> void:
	if _spinning > 0.0 or Game.money < PRICE:
		return
	Game.money -= PRICE
	_spin(true)


func _spin(by_player: bool) -> void:
	_by_player = by_player
	_spinning = SPIN_TIME
	_result = [roll(), roll(), roll()]
	Game.noise("slot", global_position + Vector3.UP, Game.player if by_player else self)


## Ein Walzenbild nach Gewicht.
static func roll() -> int:
	var total := 0
	for s in SYMBOLS:
		total += int(s[2])
	var r := randi() % total
	for i in SYMBOLS.size():
		r -= int(SYMBOLS[i][2])
		if r < 0:
			return i
	return 0


## Was drei Walzen auszahlen (ohne den Einsatz abzuziehen).
static func payout(result: Array[int]) -> int:
	if result[0] == result[1] and result[1] == result[2]:
		return int(PAYOUT[SYMBOLS[result[0]][0]])
	if result[0] == result[1] or result[1] == result[2] or result[0] == result[2]:
		return PRICE
	return 0


func _process(delta: float) -> void:
	if _spinning > 0.0:
		_spinning -= delta
		for i in 3:   # die Walzen bleiben nacheinander stehen
			if _spinning > SPIN_TIME * (0.6 - i * 0.3):
				_show(i, randi() % SYMBOLS.size())
			else:
				_show(i, _result[i])
		if _spinning <= 0.0:
			_settle()
		return
	_ghost_timer -= delta
	if _ghost_timer <= 0.0:
		_ghost_timer = randf_range(GHOST_EVERY.x, GHOST_EVERY.y)
		if Game.player and Game.player.global_position.distance_to(global_position) > 6.0:
			_spin(false)   # niemand hat den Hebel gezogen …


## Zeitsprung im Schlaf (TECHNIK.md 3): kein Nachholen, nur der Spuk-Zähler läuft weiter.
func skip_time(dt: float) -> void:
	_ghost_timer = maxf(5.0, _ghost_timer - dt)


func _settle() -> void:
	var names: Array[String] = []
	for i in _result:
		names.append(String(SYMBOLS[i][0]))
	var win := payout(_result)
	if not _by_player:
		if Game.tracing:
			print("[Spielautomat] läuft von selbst an: %s" % " – ".join(names))
		if win > 0:
			_drop_coins(win)   # da liegt Geld in der Schale – für wen auch immer
		return
	if names[0] == "AUGE" and names[1] == "AUGE" and names[2] == "AUGE":
		Game.say("Drei Augen starren dich an. Hinter dir knackt etwas im Holz.", 4.0)
		Game.player.shock = minf(1.0, Game.player.shock + 0.05)
		return
	if win <= 0:
		Game.say("%s. Nichts." % " – ".join(names), 2.5)
		return
	if win == PRICE:
		Game.say("%s. Dein Einsatz kommt zurück." % " – ".join(names), 2.5)
	else:
		Game.say("%s! %d Geld klimpern in die Schale!" % [" – ".join(names), win], 3.5)
		Game.noise("slot_win", global_position + Vector3.UP, Game.player)
	Game.money += win
	if Game.tracing:
		print("[Spielautomat] %s → %d Geld" % [" – ".join(names), win])


## Gewinn ohne Spieler: Münzen in der Schale.
func _drop_coins(value: int) -> void:
	var coins := Item.create(Item.Kind.COINS, str(value))
	get_parent().add_child(coins)
	coins.global_position = global_transform * Vector3(0, 0.93, SIZE.z / 2.0 - 0.02)
	Game.noise("slot_win", global_position + Vector3.UP, self)


func _show(i: int, symbol: int) -> void:
	_reels[i].text = SYMBOLS[symbol][0]
	_reels[i].modulate = SYMBOLS[symbol][1]
