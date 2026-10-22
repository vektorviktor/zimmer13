class_name Calendar
extends StaticBody3D
## Ingame-Kalender (Spielkonzept 2.1): vom 1. Oktober bis Halloween, draußen immer Nacht.
## Die Zeit kommt aus der Spielzeit des MonsterDirectors (pausiert mit dem Spiel und wird
## gespeichert). Als Knoten: Abreißkalender an der Wand von Zimmer 13 (lokale +Z in den Raum).

## Tageslänge in Sekunden Echtzeit – zentraler Tuning-Wert (5 min → 31 Tage ≈ 2,5 h).
const DAY_SECONDS := 300.0
const FIRST_DAY := 1
const HALLOWEEN := 31
const MONTH := "Oktober"

var _number: Label3D
var _shown_day := -1


## Aktueller Tag im Oktober (1 … 31; nach Halloween bleibt es vorerst beim 31.).
static func day_of(elapsed: float) -> int:
	return mini(FIRST_DAY + int(elapsed / DAY_SECONDS), HALLOWEEN)


static func date_text(elapsed: float) -> String:
	var day := day_of(elapsed)
	return "%d. %s%s" % [day, MONTH, " – Halloween" if day == HALLOWEEN else ""]


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
	return "Kalender: %s" % date_text(_elapsed())


func interact(_player: Player) -> void:
	var left := HALLOWEEN - today()
	if left <= 0:
		Game.say("Halloween. Heute ist es so weit.", 3.0)
	else:
		Game.say("%s – noch %d %s bis Halloween." % [date_text(_elapsed()), left, "Tag" if left == 1 else "Tage"], 3.0)


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
