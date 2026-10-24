class_name SleepSkip
extends Node
## Zeitsprung im Schlaf (Spielkonzept 3.6, entschieden 2026-10-24): Schläft der Spieler in der Nachtruhe, springt die
## Uhr – etwa HOUR_REAL Sekunden Echtzeit je Spielstunde – statt fünfmal so schnell zu laufen (ein 60-facher Zeitraffer
## ginge nicht: Godot rechnet weiter 60 Physikschritte je Sekunde, Gäste und Monster sprängen meterweise).
## Je Bild rückt die Zeit ein Stück vor: MonsterDirector.skip (Uhr, versteckte Werte, Spuk, Zeitplan – ein Aufbruch
## läuft abstrakt, mit Opfern, die man erst morgens findet), dann alle Knoten der Gruppe „time_skip“ mit
## skip_time(dt) (was sonst je Bild mit delta weiterzählt: Rausch, Angst, Nachwachsen, Kerzen, Spuren …).
## Ende: die gewählten Stunden sind um (aufstehen), die Nachtruhe ist vorbei (weiter im Zeitraffer), man wird geweckt
## (Lärm, Mitternachtsglocke) – oder das Monster kommt: Dann ist es wirklich unterwegs, LEAD Sekunden vor dem Ziel, und
## man schreckt hoch. Mit Wache (6.18: ein wacher Erwachsener in Zimmer 13) GUARD_LEAD-mal früher.
## Läuft nur, wenn die Welt ruhig ist (kein Monster, Lakengeist oder Kürbismann unterwegs) – sonst bleibt es beim
## Zeitraffer, bis es wieder ruhig ist (etwa nach der Geisterstunde); das Spielmenü hält ihn an.

const HOUR_REAL := 0.5          ## so viele Sekunden Echtzeit je übersprungene Spielstunde
const LEAD := 5.0               ## Vorlauf: so viele Sekunden, bevor das Monster ankommt, wacht man auf
const GUARD_LEAD := 2.0         ## mit Wache so viel mal mehr Vorlauf
const MIN_SKIP := 60.0          ## kürzere Reste (Spielsekunden) schläft man im Zeitraffer

var active := false
var _until := 0.0               ## bis zu dieser Spielzeit (Director.elapsed) springt es
var _retry := 0.0               ## im Zeitraffer: wann es wieder zu springen versucht


## Schläft der Spieler gerade ein (Player.start_sleep): springen, wenn Nachtruhe ist und nichts im Haus umgeht.
## false = es bleibt beim Zeitraffer.
func try_begin() -> bool:
	var player := Game.player
	var director := Game.director
	if active or player == null or not player.sleeping or director == null or Game.social == null \
			or not Game.social.sleep_active or director.other_threat_active(null) or Game.game_over:
		return false
	_until = minf(director.elapsed + player.sleep_left(), Game.social.night_ends_at())
	if _until - director.elapsed < MIN_SKIP:
		return false
	active = true
	director.skipping = true
	Engine.time_scale = 1.0
	_show_clock()
	if Game.tracing:
		print("[Zeitsprung] von %s bis %s" % [Calendar.time_text(director.elapsed), Calendar.time_text(_until)])
	return true


## Vorlauf in Sekunden: mit Wache länger.
func lead() -> float:
	return LEAD * (GUARD_LEAD if guarded() else 1.0)


## Hält jemand Wache (Spielkonzept 6.18)? Ein wacher Erwachsener in Zimmer 13 – die Wache selbst gibt es noch nicht,
## dies ist die Stelle, an der sie andockt.
func guarded() -> bool:
	if Game.social == null:
		return false
	for guest in Game.social.living_guests():
		var g: Guest = guest
		if not g.is_child() and not g.is_asleep() and Game.social.builder.room_at(g.global_position) == LevelBuilder.PLAYER_ROOM:
			return true
	return false


func _process(delta: float) -> void:
	var player := Game.player
	var director := Game.director
	if not active:
		_retry -= delta
		if _retry <= 0.0 and player and player.sleeping:
			_retry = 1.0
			try_begin()
		return
	if player == null or player.dead or not player.sleeping or Game.game_over:
		_end("")   # geweckt (Lärm, Glocke) oder aufgestanden
		return
	if director.other_threat_active(null):   # Kürbismann kündigt sich an, Lakengeist geht um
		_end("Du schreckst hoch – irgendetwas stimmt nicht.")
		return
	var dt := minf(delta / HOUR_REAL * Calendar.HOUR, _until - director.elapsed)
	if dt > 0.0:
		var wake := director.skip(dt)
		get_tree().call_group(&"time_skip", &"skip_time", dt)
		_show_clock()
		if wake != "":
			_end(wake)
			return
	if director.elapsed >= _until - 0.001:
		_end("")


## Sprung vorbei: geweckt mit Grund (das Monster kommt) – sonst schläft man im Zeitraffer weiter, falls noch Stunden
## übrig sind (Player._update_sleep steht auf, sobald sie um sind).
func _end(wake: String) -> void:
	active = false
	if Game.director:
		Game.director.skipping = false
	if Game.hud:
		Game.hud.set_sleep_clock("")
	var player := Game.player
	if Game.tracing and Game.director:
		print("[Zeitsprung] Ende um %s%s" % [Calendar.time_text(Game.director.elapsed), " – " + wake if wake != "" else ""])
	if player == null or not player.sleeping:
		return
	if wake != "":
		player.wake_up(wake)
	else:
		Engine.time_scale = Player.SLEEP_SPEED


func _show_clock() -> void:
	if Game.hud and Game.director:
		Game.hud.set_sleep_clock(Calendar.time_text(Game.director.elapsed))
