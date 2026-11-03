class_name DirectorOffice
extends Node
## Büro der Direktion und Sekretariat: Schlösser und Wege hinein (Spielkonzept 2.8, 2.10, 6.19; ZIM-6). Beide Türen
## sind abgeschlossen (LevelBuilder._opening): die zum Sekretariat mit SECRETARIAT_KEY, die vom Sekretariat ins Büro
## mit OFFICE_KEY. Das Büro ist Sperrbereich (SaveManager.NEW_AREAS), das Sekretariat nicht.
##   · Sekretariat: Der Schlüssel hing im Spind des Hausmeisters, Bruno behält ihn (HANDLUNG K3). Spind und Brunos Wege
##     fehlen noch (ZIM-4) – bis dahin hängt er ab SECRETARIAT_DAY neben dem Sicherungskasten im Maschinenraum
##     (Zwischenort, Spielkonzept 2.10).
##   · Büro: Josefs Schlüsselbund (JOSEF_KEYS) öffnet Sekretariat und Büro (JOSEF_OPENS, Player.has_key). Er gehört an den
##     alten Kessel in U2 – bis es U2 gibt, hängt er ab JOSEF_DAY seitlich am Kessel im Heizkeller (Zwischenort, 2.8).
##     Den Hinweis gibt Marion ab JOSEF_DAY einmal im Gespräch (Talk.greeting → marion_hint). Der Bund des
##     Rezeptionisten aus der Jeansjacke des Kürbismanns (4.21) ist noch nicht gebaut.
##   · Generalschlüssel (6.19): im Schreibtisch des Sekretariats in der Schublade mit Zahlenschloss (Desk.code_drawer),
##     Code CODE – ein Jahr des Abkommens, die erste Ernte (Vorschlag). Milas Ziffer aus der Nachtpartie fehlt (ZIM-8).
##   · Außerdem legt place_due den Schlüssel zu Zimmer 18 erst nach der Siegerehrung (Gustavs Tod) auf die Kiste im
##     Heizkeller (LevelBuilder.room18_key_at; 7.4: „nach Gustavs Tod“, sein Ort an der Leviathanmauer kommt mit ZIM-16)
##     – sonst ließe sich die Hauptgeschichte am ersten Tag abkürzen (befunde/BEFUNDE.md Q-02).
##   · Das Foto von 2005 (2.10, ZIM-117): mit gesprungenem Glas in der Mittelschublade (PHOTO_DRAWER), nicht abgeschlossen
##     (PhotoWall.found_photo, Desk).
## Nicht gespeichert: Ob ein Schlüssel schon hängt, steht in den Gegenständen bzw. am Bund (place_due sieht nach).
## Erreichbar über Game.director_office.

const SECRETARIAT_KEY := "sekretariat"
const OFFICE_KEY := "buero"
const JOSEF_KEYS := "josefs_bund"
const ROOM18_KEY := "zimmer_18"
## Was Josefs Bund aufschließt – das Hotel hat seit 1987 kein Schloss getauscht (2.8); Weiteres (Lager?) ist offen
const JOSEF_OPENS := [SECRETARIAT_KEY, OFFICE_KEY]
## Zahlenschloss im Sekretariat: Code (Spielkonzept 2.10, Vorschlag) und Schublade des Schreibtischs, von oben gezählt
## (0 Mittelschublade, 1 die obere im Unterschrank – die zweite)
const CODE := "1990"
const CODE_DRAWER := 1
## Darin liegt das Foto von 2005 (die Mittelschublade, ohne Schloss)
const PHOTO_DRAWER := 0
## Ab diesem Tag hängen die Schlüssel an ihren Zwischenorten (Sekretariat um den 6.–10., Josefs Bund ab der Mitte)
const SECRETARIAT_DAY := 6
const JOSEF_DAY := 14
## Zwischenorte: neben dem Sicherungskasten links (lokal zum Kasten, +Z = Raum) und seitlich am Kessel (lokal zum
## Kessel, +Z = Feuerklappe)
const SECRETARIAT_SPOT := Vector3(-0.34, 0.12, 0.02)
const JOSEF_SPOT := Vector3(Boiler.RADIUS + 0.03, 1.35, 0.0)
## Marions Hinweis (Text Vorschlag, 2.8); so steht er danach im Notizbuch
const MARION_HOUSEHOLD := "H22"
const MARION_LINE := "Vater hatte das ganze Haus am Gürtel. Jeden Schlüssel. Man hat ihn nie gefunden – den Bund auch nicht."
const MARION_NOTE := "Marion: Josef hatte 1987 alle Schlüssel des Hauses am Gürtel. Wo der Bund wohl geblieben ist?"
const CHECK_EVERY := 5.0
const LOCK_TITLE := "Zahlenschloss"
const LOCK_HINT := "Vier Messingräder an der Schublade, die Ziffern abgegriffen. [Enter] probieren · [Esc] lassen"

var lock_ui: CodeLockUI
var _timer := 0.0


func _ready() -> void:
	lock_ui = CodeLockUI.new()
	lock_ui.name = "Zahlenschloss"
	add_child(lock_ui)


func _process(delta: float) -> void:
	_timer -= delta
	if _timer > 0.0 or Game.player == null or Game.social == null:
		return
	_timer = CHECK_EVERY
	place_due(Calendar.today())


## Schlüssel, deren Tag gekommen ist, an ihre Zwischenorte hängen – sofern sie nicht schon irgendwo sind.
func place_due(day: int) -> void:
	if day >= SECRETARIAT_DAY and not _exists(SECRETARIAT_KEY) and Game.power_cut and Game.power_cut.fuse_box:
		_hang(SECRETARIAT_KEY, Game.power_cut.fuse_box.global_transform, SECRETARIAT_SPOT, 0.0)
	var boiler := get_tree().get_first_node_in_group("boilers") as Boiler
	if day >= JOSEF_DAY and not _exists(JOSEF_KEYS) and boiler:
		_hang(JOSEF_KEYS, boiler.global_transform, JOSEF_SPOT, PI / 2.0)
	var spot: Vector3 = Game.social.builder.room18_key_at
	if Game.director and Game.director.first_attack_done and spot != Vector3.INF and not _exists(ROOM18_KEY):
		var key := Item.create(Item.Kind.KEY, ROOM18_KEY)
		Game.social.builder.world.add_child(key)
		key.position = spot


## Der Schlüssel liegt schon in der Welt, am Bund, in der Hand – oder ein Gast hält ihn.
func _exists(id: String) -> bool:
	if id in Game.player.keyring or Game.player.held_key_id() == id:
		return true
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.kind == Item.Kind.KEY and item.key_id == id:
			return true
	for g in Game.social.guests:
		var held: Item = (g as Guest).held
		if held and is_instance_valid(held) and held.kind == Item.Kind.KEY and held.key_id == id:
			return true
	return false


## Schlüssel an einer Wand bzw. am Kessel aufhängen: at = Rahmen des Trägers, local = Punkt darin, yaw = Blickrichtung
## der Aufhängefläche um die Hochachse (0 = +Z des Trägers). Eingefroren, bis ihn jemand nimmt.
func _hang(id: String, at: Transform3D, local: Vector3, yaw: float) -> void:
	var item := Item.create(Item.Kind.KEY, id)
	Game.social.builder.world.add_child(item)
	# flach liegender Schlüssel → senkrecht an die Fläche, Bart nach unten
	var face := at.basis * Basis(Vector3.UP, yaw)
	item.global_transform = Transform3D(face * Basis(Vector3.RIGHT, PI / 2.0) * Basis(Vector3.UP, PI / 2.0), at * local)
	item.freeze = true


## Öffnet Josefs Bund diese Tür?
static func josef_opens(id: String) -> bool:
	return id in JOSEF_OPENS


## Zahlenschloss am Schreibtisch des Sekretariats: Fenster auf, bei richtigem Code springt die Schublade auf.
func open_lock(desk: Desk, drawer: int, player: Player) -> void:
	lock_ui.open(LOCK_TITLE, LOCK_HINT, func(code: String) -> bool: return try_code(desk, drawer, player, code))


## Code probieren (auch Debug). true = offen.
func try_code(desk: Desk, drawer: int, player: Player, code: String) -> bool:
	if code != CODE:
		Game.say("Das Schloss rührt sich nicht.", 2.0)
		Game.noise("rattle", desk.global_position, player)
		return false
	Game.say("Klick – das Schloss springt auf.", 2.5)
	Game.noise("unlock", desk.global_position, player)
	desk.unlock_code(drawer, player)
	return true


## Marions Hinweis auf Josefs Bund (Talk.greeting): einmal, ab JOSEF_DAY, solange der Spieler weder den Bund noch
## einen Weg ins Büro hat. "" = nichts. day < 0: heute (Debug gibt den Tag vor).
func marion_hint(g: Guest, day: int = -1) -> String:
	if day < 0:
		day = Calendar.today()
	if g.is_child() or String(g.profile.get("household", "")) != MARION_HOUSEHOLD or day < JOSEF_DAY:
		return ""
	if Game.notebook == null or Game.notebook.has_note(JOSEF_KEYS) or Game.player.has_key(OFFICE_KEY):
		return ""
	Game.notebook.add_note(JOSEF_KEYS, MARION_NOTE, g.display_name)
	return MARION_LINE
