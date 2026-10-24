class_name AtticSpook
extends Node
## Spuk im Dachboden (Spielkonzept 4.21, 24.10.): Blitzt es, während der Spieler in einer der Kammern steht (nicht auf
## den offenen Böden), dreht ihn das Haus im hellsten Blitzbild um genau 90° nach links oder rechts – die Kinder von
## 1987 spielen ihm einen Streich, kurz danach kichert es leise. Ein grellweißer Bildblitz (Hud.flash_white) verdeckt
## den Augenblick, auch in Kammern ohne Fenster. Weather meldet jedes Blitzbild (on_flash). Mit CHANCE
## je Blitz, höchstens einmal je Gewitter, nie während eine Bedrohung hinter ihm her ist (Monster in der Nähe,
## Lakengeist bei ihm), nicht im Versteck oder im Sitzen. Bei abgeschwächtem Flackern (Einstellungen, Barrierefreiheit)
## nur das Kichern. Der Kompass zeigt den Dreh. Erzeugt vom LevelBuilder (_attic_haze), nicht gespeichert.

const CHANCE := 0.5
const GIGGLE_DELAY := 1.2   ## Spielsekunden nach dem Dreh
const GIGGLE_VOLUME := 0.55
const WHITE := 0.9          ## Deckkraft des Blitzes übers Bild, in dem der Dreh passiert (Hud.flash_white)

var forced := false   ## Debug --dachboden=blitz: beim nächsten Blitz sicher (ohne Zufall)
var _rects: Array[Rect2] = []
var _floor_y := 0.0
var _height := 0.0
var _done := false    ## in diesem Gewitter schon gespukt


## rects = Grundfläche der Kammern (x, z), floor_y = Höhe des Bodens, height = bis zur Decke.
func setup(rects: Array[Rect2], floor_y: float, height: float) -> AtticSpook:
	_rects = rects
	_floor_y = floor_y
	_height = height
	return self


func _process(_delta: float) -> void:
	if _done and Game.weather and Game.weather.kind != Weather.Kind.STORM:
		_done = false   # das Gewitter ist vorbei – im nächsten darf es wieder


## Ein Blitzbild (Weather): vielleicht den Spieler drehen.
func on_flash() -> void:
	var p := Game.player
	if _done or p == null or not in_chamber(p.global_position) or p.hiding or p.seat:
		return
	if not forced and (randf() >= CHANCE or _threatened(p.global_position)):
		return
	forced = false
	_done = true
	var turn := Settings.flicker_intensity >= 1.0
	var dir := 1.0 if randf() < 0.5 else -1.0
	if turn:
		if Game.hud:
			Game.hud.flash_white(WHITE)   # auch in Kammern ohne Fenster: der Blitz blendet, dann steht man anders
		p.rotation.y = wrapf(p.rotation.y + dir * PI / 2.0, -PI, PI)
		Game.shot_event("attic_turn", 4)
	if Game.tracing:
		print("[Dachboden] Blitz – %s" % (("dreht dich um 90° nach " + ("links" if dir > 0.0 else "rechts")) if turn else "nur Kichern"))
	get_tree().create_timer(GIGGLE_DELAY, false).timeout.connect(func() -> void:
		Game.play_sound("giggle", GIGGLE_VOLUME)
		Game.caption("[leises Kichern]"))


## Steht p in einer Kammer des Dachbodens?
func in_chamber(p: Vector3) -> bool:
	if p.y < _floor_y - 0.3 or p.y > _floor_y + _height:
		return false
	for r in _rects:
		if r.has_point(Vector2(p.x, p.z)):
			return true
	return false


## Ist gerade etwas hinter ihm her? Monster in der Nähe (wirkt durch Wände) oder der Lakengeist bei ihm.
func _threatened(p: Vector3) -> bool:
	return (Game.director and Game.director.threat_at(p) > 0.0) or (Game.ghost and Game.ghost.with_player())
