class_name MusicBox
extends Node
## Marions Spieluhr (Spielkonzept 5.17): ein Holzkästchen mit Messingkurbel, im Deckel ein eingebranntes „M.“. Josef
## Ahrend hat sie 1987 für seine Tochter gekauft; sie lag seitdem im Heizkeller oben auf dem alten Regal
## (LevelBuilder._boiler_room, neben der Batterie).
## Aufziehen (Linksklick in der Hand): Das Wiegenlied läuft gut eine Viertelminute und wird am Ende langsamer. Das ist
## **Lärm** (alle NOISE_EVERY s) – das Monster hört es und kommt. Ist es aber nah (LISTEN_RANGE), bleibt es stehen und
## horcht LISTEN_TIME Sekunden, auch mitten in der Jagd (Monster.listen_to): Er kennt die Melodie. Das wirkt einmal je
## Aufbruch (Aktivphase), danach lockt sie nur noch.
## Marion erkennt sie, wenn sie dabei ist. Später gehört sie zu seinen Sachen fürs Ritual (2.8).
## Läuft nur, solange gespielt wird (nicht gespeichert); die Spieluhr selbst ist ein Gegenstand (Item.Kind.MUSIC_BOX).

const PLAY_TIME := 16.5                ## so lange spielt sie (SynthAudio.DURATIONS „music_box“)
const NOISE_EVERY := 3.0
const LISTEN_RANGE := 11.0
const LISTEN_TIME := 6.0
const MARION_RANGE := 5.0
const MARION_LINE := "Das … das ist mein Lied. Wo hast du die Spieluhr her? Die wollte er mir schenken."
const NOTE := "Als die Spieluhr spielte, blieb es stehen und horchte. Nur einmal – danach kam es dem Klang nach."

static var _listened_attack := -1     ## bei diesem Aufbruch hat es schon gehorcht

var item: Item
var _left := PLAY_TIME
var _noise_t := 0.0


## Aussehen: Kästchen, Deckel mit Messingrand und „M.“, Kurbel an der Seite.
static func build(parent: Item, size: Vector3) -> void:
	var wood := Mat.psx(Color(0.3, 0.17, 0.09))
	var brass := Mat.metal(Color(0.8, 0.65, 0.35))
	Geo.mesh(parent, Geo.box(Vector3(size.x, size.y - 0.012, size.z)), wood, Vector3(0, (size.y - 0.012) / 2.0, 0))
	Geo.mesh(parent, Geo.box(Vector3(size.x + 0.004, 0.012, size.z + 0.004)), Mat.psx(Color(0.36, 0.2, 0.11)), Vector3(0, size.y - 0.006, 0))
	Geo.mesh(parent, Geo.box(Vector3(size.x * 0.6, 0.002, size.z * 0.6)), brass, Vector3(0, size.y + 0.001, 0))
	var mark := Label3D.new()
	mark.text = "M."
	mark.font_size = 40
	mark.pixel_size = 0.0006
	mark.modulate = Color(0.25, 0.14, 0.06)
	mark.outline_size = 0
	mark.rotation.x = -PI / 2.0
	mark.position = Vector3(0, size.y + 0.003, 0)
	parent.add_child(mark)
	var crank := Node3D.new()
	crank.name = "Kurbel"
	crank.position = Vector3(size.x / 2.0 + 0.004, size.y * 0.45, 0)
	parent.add_child(crank)
	var shaft := Geo.mesh(crank, Geo.cylinder(0.003, 0.012, 6), brass, Vector3(0.006, 0, 0))
	shaft.rotation.z = PI / 2.0
	Geo.mesh(crank, Geo.box(Vector3(0.003, 0.022, 0.004)), brass, Vector3(0.012, 0.009, 0))
	Geo.mesh(crank, Geo.cylinder(0.004, 0.01, 6), wood, Vector3(0.016, 0.02, 0))


static func playing(box: Item) -> bool:
	return box != null and box.has_node("Spielwerk")


## Aufziehen und spielen lassen (aus Player, Linksklick).
static func wind(box: Item, player: Player) -> void:
	if playing(box):
		return
	var works := MusicBox.new()
	works.name = "Spielwerk"
	works.item = box
	box.add_child(works)
	Game.play_sound("music_box", 0.9)
	Game.say("Du ziehst die Spieluhr auf. Ein Wiegenlied, dünn und hell.", 3.0)
	if Game.social:
		for g in Game.social.living_guests():
			var guest := g as Guest
			if guest.display_name.begins_with("Marion") and guest.global_position.distance_to(player.global_position) < MARION_RANGE:
				guest.say(MARION_LINE)
				break


func _process(delta: float) -> void:
	if item == null or not is_instance_valid(item):
		queue_free()
		return
	_left -= delta
	_noise_t -= delta
	var crank := item.get_node_or_null("Kurbel") as Node3D
	if crank:
		crank.rotation.x += delta * 2.5 * (0.4 + 0.6 * clampf(_left / PLAY_TIME, 0.0, 1.0))
	if _noise_t <= 0.0:
		_noise_t = NOISE_EVERY
		Game.noise("music_box", item.global_position, item)
	_charm_monster()
	if _left <= 0.0:
		queue_free()


## Ist das Monster nah und hat bei diesem Aufbruch noch nicht gehorcht: Es bleibt stehen und horcht.
func _charm_monster() -> void:
	var m := Game.monster
	var d := Game.director
	if m == null or d == null or not m.is_active() or _listened_attack == d.attacks:
		return
	if m.global_position.distance_to(item.global_position) > LISTEN_RANGE or absf(m.global_position.y - item.global_position.y) > 2.5:
		return
	_listened_attack = d.attacks
	m.listen_to(item.global_position, LISTEN_TIME)
	if Game.notebook and Game.player and d.player_can_see(m.global_position + Vector3.UP * 1.2):
		Game.notebook.add_note("music_box", NOTE, "Spieluhr")
