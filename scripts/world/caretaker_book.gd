class_name CaretakerBook
extends StaticBody3D
## Das Notizbuch des Hausmeisters in Zimmer 18 (Spielkonzept 7.4, HANDLUNG M8): eine Kladde auf dem Tisch, fest, nicht
## tragbar. [E] liest sie vor Ort (Menus.open_pages): die drei Mängel am Aufzug, Notizen des Hausmeisters und dahinter
## in Bleistift die des Gastes von 2003, der das Buch an sich genommen hat. Gelesen: Die Figur schreibt die drei Mängel
## als drei Zeilen unter „Aufgaben“ ins eigene Notizbuch (3.10) – gespeichert ist das nur dort, ein zweites Lesen
## schreibt nichts doppelt. Durchgestrichen wird je Mangel mit fixed(), sobald die Reparatur gebaut ist (7.4, offen).
## furnish() legt das Buch, den Schaltschlüssel (Item.Kind.KEY „aufzug“) und den UV-Aufsatz (4.16) auf den Tisch des
## Zimmers. Zimmer 18 bleibt zu, bis man den Schlüssel von der Leviathanmauer hat. Texte: Vorschlag (7.4).

## Schlüssel-ID des Schaltschlüssels (am Bund, Item.key_label)
const KEY_ID := "aufzug"
const TITLE := "Notizbuch des Hausmeisters"
const PAGES := [
	"AUFZUG 1 – steht. Die Direktion sagt: nicht im Oktober.

Drei Sachen, dann fährt er wieder:

1. Schaltschlüssel. Ohne den rührt sich das Bedienfeld in der Kabine nicht. Bleibt bei mir.

2. Hauptsicherung raus – Anweisung der Direktion, wie jedes Mal. Liegt bei mir im Spind. Ohne die fährt nichts. Sicherungskasten im Untergeschoss.",
	"3. Bremse festgefressen. Maschinenraum im Untergeschoss, neben dem Heizraum. Mit der Kurbel lösen – dauert, und quietscht durch den ganzen Keller. Nicht nachts.

Heizraum: Der neue Kessel ist nicht angeschlossen. Trotzdem ist es da unten heiß. Die Rohre gehen nach unten, nicht nach oben. Nicht meine Sache, sagt die Direktion.",
	"Im Oktober keine Arbeiten im Keller. Anweisung.

Die schwarze Katze war wieder im Heizraum. Sieht aus wie seine. Kann nicht sein.",
	"(Darunter in einer anderen Schrift, mit Bleistift:)

Oktober 2003. Das Buch hat mir der Hausmeister gegeben, den Schaltschlüssel auch. Gesagt hat er nichts. Hier steht mehr über dieses Haus als in jedem Prospekt.

Nicht darüber reden. Es hört zu. 13 hat es zuerst gemerkt.

Das violette Licht erträgt es nicht. Nicht lange, aber es geht.

Falls wir es nicht schaffen: Wir hinterlassen Zeichen, die man nur in diesem Licht sieht. Wer das liest – such sie.",
]
## Aufgaben im Notizbuch (3.10) je Mangel: ID und Zeile
const TASKS := {
	"key": ["lift_key", "Aufzug: Schaltschlüssel ins Bedienfeld der Kabine"],
	"fuse": ["lift_fuse", "Aufzug: Hauptsicherung aus dem Spind des Hausmeisters in den Sicherungskasten im Untergeschoss"],
	"brake": ["lift_brake", "Aufzug: Bremse im Maschinenraum mit der Kurbel lösen (laut)"],
}
const TASK_ORDER := ["key", "fuse", "brake"]
const TASK_BY := "Notizbuch des Hausmeisters"
## Auf dem Tisch: so weit entlang der langen Seite (Anteil der halben Länge) liegen Buch und Fundstücke vom Telefon in
## der Mitte weg, so weit quer (m) liegen Schlüssel und Aufsatz auseinander
const BOOK_ALONG := -0.62
const FIND_ALONG := 0.6
const FIND_ACROSS := 0.09

var _room_center := Vector3.ZERO   ## Boden in der Mitte von Zimmer 18 (Debug: von dort auf den Tisch sehen)


## Buch, Schaltschlüssel und UV-Aufsatz auf den Tisch in Zimmer 18 (ohne Tisch in der Mitte des Zimmers auf den Boden).
static func furnish(builder: LevelBuilder) -> CaretakerBook:
	var no := LevelBuilder.LOCKED_ROOM
	if not builder.rooms.has(no):
		push_warning("Zimmer %s fehlt – kein Notizbuch des Hausmeisters" % no)
		return null
	var room: Dictionary = builder.rooms[no]
	var top: Vector3 = builder.room_tables.get(no, room["center"])
	var along: Vector3 = builder.room_table_axes.get(no, Vector3.RIGHT * 0.3)
	var across := along.normalized().cross(Vector3.UP)
	var book := CaretakerBook.new()
	book.name = "NotizbuchHausmeister"
	book._room_center = room["center"]
	builder.world.add_child(book)
	book.global_position = top + along * BOOK_ALONG + Vector3.UP * 0.005
	book.rotation.y = atan2(along.x, along.z) + 0.25
	for part: Array in [[Item.Kind.KEY, KEY_ID, -FIND_ACROSS], [Item.Kind.UV_FILTER, "", FIND_ACROSS]]:
		var item := Item.create(part[0], part[1])
		builder.world.add_child(item)
		item.global_position = top + along * FIND_ALONG + across * float(part[2]) + Vector3.UP * 0.03
	return book


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	set_meta("interactable", self)
	add_to_group("caretaker_books")
	var cover := Mat.psx(Color(0.2, 0.24, 0.2))
	var edge := Mat.psx(Color(0.8, 0.76, 0.64))
	var pencil := Mat.psx(Color(0.75, 0.6, 0.15))
	Geo.mesh(self, Geo.box(Vector3(0.15, 0.004, 0.21)), cover, Vector3(0, 0.002, 0))
	Geo.mesh(self, Geo.box(Vector3(0.144, 0.012, 0.204)), edge, Vector3(0.002, 0.01, 0))
	Geo.mesh(self, Geo.box(Vector3(0.15, 0.004, 0.21)), cover, Vector3(0, 0.018, 0))
	Geo.mesh(self, Geo.box(Vector3(0.1, 0.0015, 0.016)), Mat.psx(Color(0.85, 0.82, 0.7)), Vector3(0, 0.0205, -0.06))   # Etikett
	var p := Geo.mesh(self, Geo.cylinder(0.004, 0.16, 6), pencil, Vector3(0.09, 0.006, 0.01))
	p.rotation = Vector3(PI / 2.0, 0.15, 0)
	Geo.add_box_shape(self, Vector3(0.2, 0.05, 0.23), Vector3(0.02, 0.025, 0))


func get_prompt(_player: Player) -> String:
	return "%s lesen [E]" % TITLE


func interact(_player: Player) -> void:
	if Game.menus:
		Game.menus.open_pages(TITLE, PAGES)
	read()


## Gelesen: die drei Mängel als drei Zeilen ins Notizbuch (3.10) – ohne Notizbuch nichts, beim nächsten Lesen dann.
func read() -> void:
	if Game.notebook == null:
		return
	for part: String in TASK_ORDER:
		Game.notebook.add_task(TASKS[part][0], TASKS[part][1], TASK_BY)


## Ein Mangel ist behoben („key“, „fuse“, „brake“): in Notizbuch durchgestrichen. Für die Reparatur (7.4, noch nicht gebaut).
static func fixed(part: String) -> void:
	if Game.notebook and TASKS.has(part):
		Game.notebook.finish_task(TASKS[part][0])


## --zimmer18[=offen|gelesen]: in Zimmer 18 vor den Tisch, Blick aufs Notizbuch. offen: nach 1 s aufgeschlagen ·
## gelesen: gilt als gelesen, die drei Mängel stehen im Notizbuch (mit --show=aufgaben gleich aufgeschlagen).
func debug(mode: String) -> void:
	var center := _room_center
	var dir := Vector3(center.x - global_position.x, 0, center.z - global_position.z).normalized()
	TeleportUI.place_player(Vector3(global_position.x, center.y, global_position.z) + dir * 0.8, -dir)
	Game.player.head.rotation.x = deg_to_rad(-45.0)
	if Game.tracing:
		print("[Zimmer18] Notizbuch @ %s, Zimmermitte %s" % [global_position, center])
	if mode == "gelesen":
		Game.notebook.give(true)
		read()
	elif mode == "offen":
		get_tree().create_timer(1.0).timeout.connect(interact.bind(Game.player))
