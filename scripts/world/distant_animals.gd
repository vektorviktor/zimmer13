class_name DistantAnimals
extends Node
## Tiere in der Ferne (Spielkonzept 7.8, 4.25): Ein Waldkauz ruft nachts aus dem Wald, manchmal antwortet das Weibchen;
## Krähen krächzen fern hinter der Waldkante – morgens und abends am meisten, nachts kaum; Hunde bellen in der Ferne,
## oft antwortet ein zweiter. Nur Klang, kein Lärm (niemand reagiert): draußen lauter, drinnen gedämpft wie Glocke und
## heulender Hund (Weather.BELL_INSIDE), im Schlaf hört man nichts. Das Wetter dämpft: Im Regen schweigt der Kauz und
## die Krähen rufen seltener, im Gewitter gar nicht; nach lautem Donner schlagen manchmal die Hunde an und Krähen fliegen
## krächzend auf. Den heulenden Hund hinter der Waldkante (4.25) spielt Weather.howl.

## Abstand zwischen zwei Rufen in Sekunden Spielzeit (zufällig); ob gerufen wird, entscheidet dann die Tageszeit
const OWL_EVERY := Vector2(70.0, 220.0)
const CROW_EVERY := Vector2(90.0, 260.0)
const BARK_EVERY := Vector2(150.0, 420.0)
## Pegel draußen (drinnen × Weather.BELL_INSIDE); Untertitel nur ab CAPTION_FROM
const OWL_VOLUME := 0.45
const CROW_VOLUME := 0.28
const BARK_VOLUME := 0.4
const CAPTION_FROM := 0.25
## Waldkauz: ruft von OWL_HOURS.x bis OWL_HOURS.y Uhr (über Mitternacht); so oft antwortet das Weibchen
const OWL_HOURS := Vector2(19.0, 6.0)
const OWL_ANSWER := 0.4
## Krähen: so wahrscheinlich ist ein Ruf morgens (6–11), tagsüber, abends (bis 20 Uhr) und nachts; 2–4 Krächzer je Ruf
const CROW_ACTIVITY := {"morning": 1.0, "day": 0.5, "evening": 1.0, "night": 0.08}
const CROW_CAWS := Vector2i(2, 4)
## Hunde: so oft antwortet ein zweiter, so wahrscheinlich bellt einer nachts (sonst immer)
const BARK_ANSWER := 0.5
const BARK_NIGHT := 0.5
## Im Regen so viel seltener (Krähen, Hunde); ab dieser Regenstärke schweigt der Kauz, im Gewitter auch die Krähen
const RAIN_DAMP := 0.4
const RAIN_QUIET := 0.3
## Nach Donner ab dieser Stärke: so oft bellen die Hunde, so oft fliegen Krähen auf
const THUNDER_LOUD := 0.6
const THUNDER_DOGS := 0.35
const THUNDER_CROWS := 0.25

var builder: LevelBuilder
var _owl := 0.0
var _crow := 0.0
var _bark := 0.0


func _ready() -> void:
	add_to_group("time_skip")   # Zeitsprung im Schlaf (SleepSkip)
	_owl = randf_range(OWL_EVERY.x, OWL_EVERY.y)
	_crow = randf_range(CROW_EVERY.x, CROW_EVERY.y)
	_bark = randf_range(BARK_EVERY.x, BARK_EVERY.y)


## Zeitsprung im Schlaf (Spielkonzept 3.6): Im Schlaf hört man sie nicht – die Uhren laufen nur weiter.
func skip_time(dt: float) -> void:
	_owl = fposmod(_owl - dt, OWL_EVERY.y)
	_crow = fposmod(_crow - dt, CROW_EVERY.y)
	_bark = fposmod(_bark - dt, BARK_EVERY.y)


func _process(delta: float) -> void:
	if Game.director == null or Game.weather == null:
		return
	var hour := Calendar.hour_of(Game.director.elapsed)
	var w := Game.weather
	var rainy := w.kind != Weather.Kind.CLEAR and w.intensity > RAIN_QUIET
	var stormy := rainy and w.kind == Weather.Kind.STORM
	_owl -= delta
	if _owl <= 0.0:
		_owl = randf_range(OWL_EVERY.x, OWL_EVERY.y)
		if not rainy and (hour >= OWL_HOURS.x or hour < OWL_HOURS.y):
			owl(0.0)
	_crow -= delta
	if _crow <= 0.0:
		_crow = randf_range(CROW_EVERY.x, CROW_EVERY.y)
		if not stormy and randf() < _crow_activity(hour) * (RAIN_DAMP if rainy else 1.0):
			crows(0.0)
	_bark -= delta
	if _bark <= 0.0:
		_bark = randf_range(BARK_EVERY.x, BARK_EVERY.y)
		var night := Calendar.phase_at(hour) == Calendar.Phase.NIGHT
		if randf() < (BARK_NIGHT if night else 1.0) * (RAIN_DAMP if rainy else 1.0):
			dogs(0.0)


## Donner (Weather._thunder): Laut genug, schlagen manchmal die Hunde an und Krähen fliegen auf (nicht mitten in der
## Nacht, da schlafen sie).
func on_thunder(loud: float) -> void:
	if loud < THUNDER_LOUD:
		return
	if randf() < THUNDER_DOGS:
		dogs(randf_range(0.5, 1.5))
	var hour := Calendar.hour_of(Game.director.elapsed) if Game.director else 12.0
	if randf() < THUNDER_CROWS and _crow_activity(hour) > 0.1:
		crows(randf_range(0.3, 1.0), true)


## Der Waldkauz ruft nach `delay` s – manchmal antwortet das Weibchen („ke-wick“).
func owl(delay: float) -> void:
	_later(delay, func() -> void:
		_call("owl", OWL_VOLUME, "[Eine Eule ruft]")
		if randf() < OWL_ANSWER:
			_later(randf_range(5.0, 7.0), _call.bind("owl_kewick", OWL_VOLUME, "")))
	_trace(delay, "Eine Eule ruft")


## Krähen krächzen fern nach `delay` s, 2–4-mal; startled: aufgescheucht vom Donner, mehr und schneller.
func crows(delay: float, startled: bool = false) -> void:
	var caws := randi_range(CROW_CAWS.x, CROW_CAWS.y) + (2 if startled else 0)
	var at := delay
	for i in caws:
		_later(at, _call.bind("caw", CROW_VOLUME, "[Krähen in der Ferne]" if i == 0 else ""))
		at += randf_range(0.25, 0.5) if startled else randf_range(0.45, 1.0)
	_trace(delay, "Krähen krächzen in der Ferne")


## Ein Hund bellt fern nach `delay` s, oft antwortet ein zweiter (der andere Hund).
func dogs(delay: float) -> void:
	var first := "bark" if randf() < 0.5 else "bark_deep"
	_later(delay, _call.bind(first, BARK_VOLUME, "[Hunde bellen in der Ferne]"))
	if randf() < BARK_ANSWER:
		var second := "bark_deep" if first == "bark" else "bark"
		_later(delay + randf_range(1.8, 3.5), _call.bind(second, BARK_VOLUME * 0.8, ""))
	_trace(delay, "Hunde bellen in der Ferne")


## Debug (--tiere=eule|kraehen|hunde, ohne Wert alle nacheinander): nach 1 s, unabhängig von Uhrzeit und Wetter.
func debug(which: String) -> void:
	match which:
		"eule":
			owl(1.0)
		"kraehen":
			crows(1.0)
		"hunde":
			dogs(1.0)
		_:
			owl(1.0)
			crows(7.0)
			dogs(11.0)


func _crow_activity(hour: float) -> float:
	match Calendar.phase_at(hour):
		Calendar.Phase.MORNING:
			return CROW_ACTIVITY["morning"]
		Calendar.Phase.DAY:
			return CROW_ACTIVITY["day"]
		Calendar.Phase.EVENING:
			return CROW_ACTIVITY["evening"] if hour < 20.0 else CROW_ACTIVITY["night"]
	return CROW_ACTIVITY["night"]


## Spielt einen Ruf, so laut wie draußen bzw. gedämpft drinnen; nicht, solange der Spieler schläft oder tot ist.
func _call(kind: String, volume: float, caption_text: String) -> void:
	var p := Game.player
	if p == null or p.dead or p.sleeping or builder == null:
		return
	var v := volume * (Weather.BELL_INSIDE if not builder.is_outdoor(p.global_position) else 1.0)
	Game.play_sound(kind, v, Vector3.INF, null, caption_text if v >= CAPTION_FROM else "")


func _later(delay: float, f: Callable) -> void:
	if delay <= 0.0:
		f.call()
	else:
		get_tree().create_timer(delay, false).timeout.connect(f)


func _trace(delay: float, text: String) -> void:
	if Game.tracing:
		_later(delay, func() -> void: print("[Wetter] Tiere: " + text))
