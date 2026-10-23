class_name Calendar
extends StaticBody3D
## Ingame-Kalender und Tagesuhr (Spielkonzept 2.1, 2.4): vom 1. Oktober bis Halloween, draußen immer Nacht.
## 24 Stunden = 24 Minuten Echtzeit (eine Spielminute = eine Sekunde). Das Spiel beginnt am 1. Oktober um 15 Uhr;
## das Kalenderblatt wechselt um Mitternacht. Die Zeit kommt aus der Spielzeit des MonsterDirectors (pausiert mit
## dem Spiel und wird gespeichert). Als Knoten: Abreißkalender an der Wand von Zimmer 13 (lokale +Z in den Raum).

## Tageslänge in Sekunden Echtzeit – zentraler Tuning-Wert (24 min → 31 Tage ≈ 12½ h).
const DAY_SECONDS := 1440.0
const HOUR := DAY_SECONDS / 24.0
## Anreise am 1. Oktober um 15 Uhr (Spielzeit 0)
const START_HOUR := 15.0
const FIRST_DAY := 1
const HALLOWEEN := 31
const MONTH := "Oktober"
## Tagesablauf der Gäste (2.4): Morgen 6–11, Tag 11–18, Abend 18–23, Nacht 23–6 (Nachtruhe mit Streuung, Social)
enum Phase { MORNING, DAY, EVENING, NIGHT }
const PHASE_START := [6.0, 11.0, 18.0, 23.0]
const PHASE_NAMES := ["Morgen", "Tag", "Abend", "Nacht"]

var _number: Label3D
var _shown_day := -1


## Stunden seit dem 1. Oktober, 0 Uhr.
static func clock_of(elapsed: float) -> float:
	return START_HOUR + elapsed / HOUR


## Tag im Oktober ohne Obergrenze (nach Halloween 32, 33 …) – für Zeitpunkte, die über den 31. hinausreichen.
static func raw_day_of(elapsed: float) -> int:
	return FIRST_DAY + floori(clock_of(elapsed) / 24.0)


## Aktueller Tag im Oktober (1 … 31; nach Halloween bleibt es vorerst beim 31.).
static func day_of(elapsed: float) -> int:
	return mini(raw_day_of(elapsed), HALLOWEEN)


## Tag mit Bruchteil (1,0 = 1. Oktober, 0 Uhr) – zum gleitenden Steigern über den Monat.
static func day_float(elapsed: float) -> float:
	return FIRST_DAY + clock_of(elapsed) / 24.0


## Uhrzeit in Stunden (0 … 24, Bruchteile = Minuten).
static func hour_of(elapsed: float) -> float:
	return fposmod(clock_of(elapsed), 24.0)


## Spielzeit (Director.elapsed) am Tag day um hour Uhr; vor der Anreise negativ.
static func at(day: int, hour: float) -> float:
	return ((day - FIRST_DAY) * 24.0 + hour - START_HOUR) * HOUR


## Phase des Tagesablaufs zur Uhrzeit (die Nachtruhe selbst streut, siehe Social).
static func phase_at(hour: float) -> Phase:
	for i in range(PHASE_START.size() - 1, -1, -1):
		if hour >= PHASE_START[i]:
			return i as Phase
	return Phase.NIGHT   # vor 6 Uhr


static func phase() -> Phase:
	return phase_at(hour_of(_elapsed()))


static func date_text(elapsed: float) -> String:
	var day := day_of(elapsed)
	return "%d. %s%s" % [day, MONTH, " – Halloween" if day == HALLOWEEN else ""]


## „15:42 Uhr“
static func time_text(elapsed: float) -> String:
	var minutes := int(hour_of(elapsed) * 60.0)
	return "%d:%02d Uhr" % [minutes / 60, minutes % 60]


static func today() -> int:
	return day_of(_elapsed())


## Spielzeit des Directors (0, solange es keinen gibt – Titelbildschirm, Szenenwechsel).
static func _elapsed() -> float:
	return Game.director.elapsed if Game.director else 0.0


# --- Abreißkalender --------------------------------------------------------------

func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	set_meta("interactable", self)
	Geo.mesh(self, Geo.box(Vector3(0.3, 0.4, 0.02)), Mat.psx(Color(0.9, 0.87, 0.78)), Vector3(0, 0, 0.01))
	Geo.mesh(self, Geo.box(Vector3(0.3, 0.09, 0.025)), Mat.psx(Color(0.6, 0.1, 0.07)), Vector3(0, 0.155, 0.012))
	var month := _label(MONTH.to_upper(), 16, Color(0.95, 0.9, 0.8))
	month.position = Vector3(0, 0.155, 0.027)
	_number = _label("1", 30, Color(0.15, 0.1, 0.08))
	_number.position = Vector3(0, -0.04, 0.022)
	Geo.add_box_shape(self, Vector3(0.32, 0.42, 0.06), Vector3(0, 0, 0.03))


func _process(_delta: float) -> void:
	var day := today()
	if day != _shown_day:
		_shown_day = day
		_number.text = str(day)
		_number.modulate = Color(0.6, 0.08, 0.05) if day == HALLOWEEN else Color(0.15, 0.1, 0.08)


func get_prompt(_player: Player) -> String:
	return "Kalender: %s · %s" % [date_text(_elapsed()), time_text(_elapsed())]


func interact(_player: Player) -> void:
	var left := HALLOWEEN - today()
	if left <= 0:
		Game.say("Halloween, %s. Heute ist es so weit." % time_text(_elapsed()), 3.0)
	else:
		Game.say("%s, %s – noch %d %s bis Halloween." % [date_text(_elapsed()), time_text(_elapsed()), left,
			"Tag" if left == 1 else "Tage"], 3.0)


func _label(text: String, size: int, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = size
	label.pixel_size = 0.004
	label.modulate = color
	label.outline_size = 0
	label.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	add_child(label)
	return label
