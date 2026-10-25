class_name PowerCut
extends Node
## Stromausfall im Gewitter (Spielkonzept 4.28). Selten schlägt ein Blitz so nah ein, dass die Hauptsicherung fliegt:
## Erst zucken alle Lampen ein paar Sekunden unruhig (Vorwarnung, FlickerLight.brownout), dann ein Knall, das Netz
## brummt ab (Klang „power_down“) – und alles Elektrische ist aus (FlickerLight.power_off): Wandlampen, Deckenlampen,
## Lichterketten, die Halogenröhren im Keller. Nur Kerzen, Kürbisse und das Kesselfeuer brennen noch. Weil Licht schützt
## (4.4), ist das hart – darum höchstens einmal am Spieltag, nur nach dem ersten Angriff und nur mit Gewitter.
## Gäste erschrecken und rufen nach Kerzen. **Wieder Strom:** am Sicherungskasten (FuseBox) im Untergeschoss die
## Sicherung einlegen ([E], Lärm „fuse“) – mitten durchs dunkle Haus und hinunter. Sonst kommt er nach RESTORE Stunden
## von selbst wieder; wer das tut, weiß niemand (Personal sieht man nie, 2.5).
## Gespeichert unter „omens“: ob der Strom aus ist, bis wann, und der Tag des letzten Ausfalls.

const CUT_CHANCE := 0.08              ## je Blitz (nach dem ersten Angriff, im Gewitter)
const WARN_TIME := 3.0                ## so lange zucken die Lampen vorher
const RESTORE := Vector2(2.0, 3.5)    ## Spielstunden bis der Strom von selbst wiederkommt
const GUEST_FEAR := 20.0
const LINES := ["Der Strom! Hat jemand Kerzen?", "Nicht bewegen … wo ist der Lichtschalter?", "Das war der Blitz. Ganz ruhig.",
	"Ich sehe nichts mehr!", "Kerzen! Wir brauchen Kerzen!"]
const FUSE_FALLBACK := Vector3(36.0, LevelBuilder.CELLAR_Y + 1.45, -49.78)   ## Nordwand des Maschinenraums, Blick nach +Z

var off := false
var _until := 0.0                     ## Spielzeit, zu der der Strom von selbst wiederkommt
var _last_day := 0
var _warn := 0.0
var _builder: LevelBuilder
var fuse_box: FuseBox


func setup(builder: LevelBuilder) -> PowerCut:
	_builder = builder
	return self


func _ready() -> void:
	FlickerLight.power_off = false
	FlickerLight.brownout = 0.0
	fuse_box = FuseBox.new()
	fuse_box.position = FUSE_FALLBACK
	add_child(fuse_box)


func _exit_tree() -> void:
	FlickerLight.power_off = false
	FlickerLight.brownout = 0.0


func save_state() -> Dictionary:
	return {"off": off, "until": _until, "last_day": _last_day}


func load_state(d: Dictionary) -> void:
	_last_day = int(d.get("last_day", 0))
	_until = float(d.get("until", 0.0))
	_set_off(bool(d.get("off", false)), false)


## Ein Blitz (Weather._update_flash): selten fliegt die Sicherung.
func on_flash() -> void:
	var d := Game.director
	if off or _warn > 0.0 or d == null or not d.first_attack_done or Game.weather.kind != Weather.Kind.STORM \
			or Calendar.day_of(d.elapsed) == _last_day or randf() >= CUT_CHANCE:
		return
	begin()


func begin() -> void:
	_warn = WARN_TIME
	FlickerLight.brownout = 0.5
	if Game.tracing:
		print("[Stromausfall] die Lampen zucken")


func _process(delta: float) -> void:
	if _warn > 0.0:
		_warn -= delta
		FlickerLight.brownout = 0.4 + 0.5 * (1.0 - _warn / WARN_TIME)
		if _warn <= 0.0:
			FlickerLight.brownout = 0.0
			_cut()
		return
	if off and Game.director and Game.director.elapsed >= _until:
		restore(false)


func _cut() -> void:
	var d := Game.director
	_last_day = Calendar.day_of(d.elapsed)
	_until = d.elapsed + randf_range(RESTORE.x, RESTORE.y) * Calendar.HOUR
	_set_off(true, true)
	Game.play_sound("bang", 0.8)
	Game.play_sound("power_down", 0.8)
	Game.say("Ein Knall, das Brummen in den Wänden erstirbt – der Strom ist weg.", 4.5)
	if Game.player and Game.player.sleeping:
		Game.player.wake_up("Ein Knall weckt dich. Es ist stockdunkel.")
	if Game.social:
		var near: Array = []
		for g in Game.social.living_guests():
			var guest := g as Guest
			if guest.state == Guest.State.SLEEP:
				continue
			guest.fear = minf(100.0, guest.fear + GUEST_FEAR * (1.3 - float(guest.profile.get("brave", 0.5))))
			if not guest.is_child() and Game.player and guest.global_position.distance_to(Game.player.global_position) < 15.0:
				near.append(guest)
		near.shuffle()
		for g in near.slice(0, 2):
			(g as Guest).say(LINES.pick_random())
	if Game.notebook:
		Game.notebook.add_note("power_cut", "Im Gewitter ist der Strom ausgefallen. Der Sicherungskasten ist unten im Maschinenraum.", "Gewitter")
	if Game.tracing:
		print("[Stromausfall] aus bis %s" % Calendar.time_text(_until))


## Strom wieder an – am Sicherungskasten (by_player) oder von selbst.
func restore(by_player: bool) -> void:
	if not off:
		return
	_set_off(false, true)
	if by_player:
		Game.say("Die Sicherung rastet ein. Über dir brummt es wieder.", 3.5)
	elif Game.player and not Game.player.sleeping:
		Game.say("Irgendwo klackt es. Die Lampen gehen wieder an – wer war das?", 4.0)
	if Game.tracing:
		print("[Stromausfall] Strom wieder da (%s)" % ("Sicherung" if by_player else "von selbst"))


func _set_off(value: bool, announce: bool) -> void:
	off = value
	FlickerLight.power_off = value
	if not value and announce:
		FlickerLight.brownout = 0.3   # beim Wiederkommen kurz unruhig
		get_tree().create_timer(1.2, false).timeout.connect(func() -> void: FlickerLight.brownout = 0.0)


## Debug (--strom[=kasten]): es gewittert, der erste Angriff gilt als geschehen, gleich fliegt die Sicherung · kasten: du
## stehst vor dem Sicherungskasten im Untergeschoss, der Strom ist schon aus.
func debug(what: String) -> void:
	Game.director.first_attack_done = true
	_last_day = 0
	if what == "kasten":
		_until = Game.director.elapsed + RESTORE.y * Calendar.HOUR
		_set_off(true, false)
		var front := fuse_box.global_position + fuse_box.global_transform.basis.z * 1.2
		front.y = LevelBuilder.CELLAR_Y + 0.05
		TeleportUI.place_player(front, fuse_box.global_position - front)
		return
	Game.weather.set_weather(Weather.Kind.STORM, true)
	get_tree().create_timer(1.0, false).timeout.connect(begin)


## Der Sicherungskasten im Untergeschoss: grauer Blechkasten mit Hebel. Ort: Ausstattung „Sicherungskasten“ im Plan, bis
## dahin PowerCut.FUSE_FALLBACK.
class FuseBox extends StaticBody3D:
	var _lever: Node3D

	func _ready() -> void:
		collision_layer = 4
		collision_mask = 0
		set_meta("interactable", self)
		var steel := Mat.psx(Color(0.42, 0.44, 0.43))
		Geo.mesh(self, Geo.box(Vector3(0.45, 0.6, 0.16)), steel, Vector3(0, 0, 0.08))
		Geo.mesh(self, Geo.box(Vector3(0.41, 0.56, 0.01)), Mat.psx(Color(0.36, 0.38, 0.37)), Vector3(0, 0, 0.165))
		Geo.mesh(self, Geo.box(Vector3(0.12, 0.08, 0.004)), Mat.psx(Color(0.85, 0.75, 0.1)), Vector3(0, 0.2, 0.172))   # Warnschild
		_lever = Node3D.new()
		_lever.position = Vector3(0.14, -0.05, 0.17)
		add_child(_lever)
		Geo.mesh(_lever, Geo.box(Vector3(0.03, 0.12, 0.03)), Mat.psx(Color(0.6, 0.1, 0.08)), Vector3(0, 0.05, 0.02))
		Geo.add_box_shape(self, Vector3(0.45, 0.6, 0.2), Vector3(0, 0, 0.1))

	func _process(_delta: float) -> void:
		var down := Game.power_cut != null and Game.power_cut.off
		_lever.rotation.x = 0.9 if down else -0.4

	func get_prompt(_player: Player) -> String:
		if Game.power_cut and Game.power_cut.off:
			return "Sicherung einlegen [E]"
		return "Sicherungskasten"

	func interact(player: Player) -> void:
		if Game.power_cut and Game.power_cut.off:
			Game.noise("fuse", global_position, player)
			Game.power_cut.restore(true)
