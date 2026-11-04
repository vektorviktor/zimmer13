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
## Die springende Type (2.11, ZIM-119): Alles, was die Maschine der Chefsekretärin getippt hat, liest sich über read_typed
## (Menus.open_typed, TypedPage) – Willkommensbrief, Aushänge der Direktion, Betriebsferien, Blatt in der Maschine,
## Dienstplan, Vertrag. Steht der Willkommensbrief gelesen und eins der Blätter von ihrer Maschine im Notizbuch
## (OLD_DOCS), notiert die Figur JUMP_JOT.
##   · Schreibmaschine (Typewriter) auf dem Sekretariatsschreibtisch, eingespannt ein frisches Blatt (MACHINE_TEXT).
##   · Dienstplan vom 31.10.1987 obenauf bei den Personalakten in der untersten Schublade (FILES_DRAWER, Desk).
##   · Vertrag von 1987 (Item.Kind.CONTRACT, ZIM-21) in der Mittelschublade des Direktionsschreibtischs
##     (CONTRACT_DRAWER, Desk) – ein Gegenstand, damit er ins Feuer kann (2.8, Ritual noch nicht gebaut).
##   · Aushang Betriebsferien (LEAVE_TEXT) im Personalflur neben der Tür des Hausmeisterraums – die Tür, die dem Spind
##     des Hausmeisters (_caretaker_locker) am nächsten liegt, auf der Seite gegenüber dem Spind.
##   Die Spuren des Hausmeisters (Tasse, nasser Mantel) fehlen: Der Plan zeigt den Hausmeisterraum, der Kartenbau
##   baut die Fläche noch nicht (ZIM-4).
## Nicht gespeichert: Ob ein Schlüssel schon hängt, steht in den Gegenständen bzw. am Bund (place_due sieht nach); was
## gelesen ist, steht im Notizbuch (ohne Notizbuch wird nichts notiert).
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
## Springende Type (2.11): Kennung je Getipptem; die von ihrer Maschine aus Sekretariat und Büro sind zugleich die
## Notiz-IDs (OLD_DOCS), JUMP_JOT kommt, sobald eins davon und der Willkommensbrief gelesen sind
const WELCOME_DOC := "willkommensbrief"
const MACHINE_DOC := "schreibmaschine"
const ROSTER_DOC := "dienstplan_1987"
const CONTRACT_DOC := "vertrag_1987"
const LEAVE_DOC := "betriebsferien"
const OLD_DOCS := [MACHINE_DOC, ROSTER_DOC, CONTRACT_DOC]
const JUMP_NOTE := "springende_type"
const JUMP_JOT := "Das ‚e‘ springt. Im Willkommensbrief auch."
## Schreibmaschine auf dem Sekretariatsschreibtisch (lokal zum Tisch, Platte; zwischen Postausgang links und Lampe
## rechts) und ihr Blatt (Text Vorschlag)
const MACHINE_SPOT := Vector3(-0.04, 0.0, 0.04)
const MACHINE_TITLE := "Schreibmaschine im Sekretariat"
const MACHINE_TEXT := "[note]Eine schwere Büromaschine, grün lackiert, die Tasten abgegriffen. Auf dem Wagen liegt Staub – auf dem eingespannten Blatt nicht. Briefkopf des Hotels, darunter zwei Zeilen:[/note]

Verehrter Gast,
herzlich willkommen in Zimmer"
const MACHINE_JOT := "In der Schreibmaschine im Sekretariat steckt ein frisches Blatt: der Anfang eines Willkommensbriefs. Die Maschine ist verstaubt."
## Personalakten mit dem Dienstplan: unterste Schublade des Sekretariatsschreibtischs (Hängeregistratur)
const FILES_DRAWER := 3
const FILES_LINE := "Hängeordner mit Personalakten, die Reiter vergilbt. Obenauf ein Dienstplan."
const ROSTER_TITLE := "Dienstplan, 31. Oktober 1987"
const ROSTER_TEXT := "[note]Obenauf in der Hängeregistratur, zwischen den Personalakten.[/note]

DIENSTPLAN – Samstag, 31. Oktober 1987 (Halloween)

Direktion – 19 Uhr Empfang im Speisesaal
Sekretariat – bis 21 Uhr, danach Durchsagen
Empfang – 18 bis 2 Uhr, Gästeliste
Küche – Festessen bis 22 Uhr, dann frei
Zimmermädchen – bis 20 Uhr, dann frei
Wäscherei – frei
Hausmeister J. Ahrend – ab 21 Uhr Kessel
Page – Gepäck bis 21 Uhr · 22 Uhr Heizkeller

Wer frei hat, verlässt das Haus bis 22 Uhr.
Die Direktion"
const ROSTER_JOT := "Dienstplan vom 31.10.1987: Josef ab 21 Uhr am Kessel. Der Page sollte um 22 Uhr in den Heizkeller."
## Vertrag von 1987 (2.3, 2.10; Text Vorschlag): Mittelschublade des Schreibtischs im Büro
const CONTRACT_DRAWER := 0
const CONTRACT_TITLE := "Abkommen, 1987"
const CONTRACT_TEXT := "[note]Drei Bogen schweres Papier, mit roter Kordel geheftet und gesiegelt.[/note]

ABKOMMEN

zwischen der Direktion des Grandhotels, vertreten durch ihren Gründer und Direktor, und dem, was unter dem Hause wohnt.

§ 1  Das Haus lädt [s]alljährlich[/s] [hand]alle drei Jahre[/hand] zur Halloween-Woche Gäste ein. Vom 1. Oktober an bleibt es geschlossen.

§ 2  Was unter dem Hause wohnt, nimmt sich aus den Gästen, wen es will. Die Gäste wissen von nichts.

§ 3  Dafür besteht das Haus fort, und die Familie des Direktors bleibt unversehrt.

§ 4  Besiegelt wird das Abkommen in der Nacht zu Allerheiligen 1987, im Heizkeller.

Grandhotel, den 31. Oktober 1987

[note]Darunter eine schwungvolle Unterschrift, nicht zu lesen, und rotes Siegelwachs. Am Rand neben § 1 zwei Kürzel: das erste in Tinte, das zweite ist keine Schrift – ein schwarzer, verkohlter Abdruck.[/note]"
const CONTRACT_JOT := "Der Vertrag von 1987 aus dem Büro: ein Abkommen mit dem, was unter dem Haus wohnt. „Alljährlich“ ist durchgestrichen, von Hand steht daneben „alle drei Jahre“. Besiegelt in der Nacht zu Allerheiligen 1987 im Heizkeller."
## Aushang im Personalflur (Wortlaut bestätigt 3.11.): Größe (quer), Mitte so hoch, so weit neben der Türkante
const LEAVE_TITLE := "Aushang im Personalflur"
const LEAVE_TEXT := "Oktober: Betriebsferien. Das Haus bleibt besetzt: Hausmeister."
const LEAVE_JOT := "Im Personalflur: Im Oktober hat das Personal Betriebsferien. Nur der Hausmeister ist im Haus."
const LEAVE_SIZE := Vector2(0.297, 0.21)
const LEAVE_HEIGHT := 1.5
const LEAVE_GAP := 0.35
## Abstand der Mitte zur Wandfläche: halbe Wandstärke (Plan 20 cm) und ein wenig
const LEAVE_OFF := 0.104
const CARETAKER_LOCKER := "Spind: Hausmeister"
## Erdgeschoss: Stahlspinde mit dem Fuß höchstens so weit (m) über bzw. unter null
const GROUND_SPAN := 1.0
## So weit (m, waagerecht) darf die Tür des Hausmeisterraums vom Spind entfernt sein
const LEAVE_RANGE := 8.0
const CHECK_EVERY := 5.0
const LOCK_TITLE := "Zahlenschloss"
const LOCK_HINT := "Vier Messingräder an der Schublade, die Ziffern abgegriffen. [Enter] probieren · [Esc] lassen"

var lock_ui: CodeLockUI
var typewriter: Typewriter
var leave_notice: NoticeBoard.Sheet
var leave_door: Door   ## Tür des Hausmeisterraums, neben der der Aushang hängt
var _timer := 0.0


func _ready() -> void:
	lock_ui = CodeLockUI.new()
	lock_ui.name = "Zahlenschloss"
	add_child(lock_ui)


## Schreibmaschine aufs Sekretariat, Aushang in den Personalflur. Nach dem Bau der Welt (Desk, Spinde, Türen stehen
## schon) und nach add_child. Dienstplan und Vertrag legt der Desk selbst hinein.
func setup(_builder: LevelBuilder) -> DirectorOffice:
	for node in get_tree().get_nodes_in_group("desks"):
		var desk := node as Desk
		if desk.variant == "sekretariat":
			typewriter = Typewriter.new()
			typewriter.name = "Schreibmaschine"
			typewriter.office = self
			desk.add_child(typewriter)
			typewriter.position = MACHINE_SPOT + Vector3.UP * Desk.dims(desk.variant).y
	if typewriter == null:
		push_warning("Kein Schreibtisch im Sekretariat – die Schreibmaschine fehlt")
	_pin_leave_notice()
	return self


## Aushang Betriebsferien neben die Tür des Hausmeisterraums, flurseitig (die Seite, auf der der Spind nicht steht),
## gegenüber dem Scharnier, damit das offene Blatt ihn nicht verdeckt.
func _pin_leave_notice() -> void:
	var locker := _caretaker_locker()
	if locker == null:
		push_warning("Gebäudeplan: kein „%s“ und nicht genau ein Stahlspind im EG – der Aushang Betriebsferien hat keinen Ort (Spielkonzept 2.11)" % CARETAKER_LOCKER)
		return
	var at := locker.global_position
	var door: Door = null
	var best := LEAVE_RANGE
	for node in get_tree().get_nodes_in_group("doors"):
		var d := node as Door
		var mid := d.global_position + d.global_basis.x * d.width / 2.0
		var dist := Vector2(mid.x - at.x, mid.z - at.z).length()
		if dist < best and absf(mid.y - at.y) < 1.5 and not d.double:
			best = dist
			door = d
	if door == null:
		push_warning("Keine Tür am Spind des Hausmeisters – der Aushang Betriebsferien fehlt")
		return
	leave_door = door
	var basis := door.global_basis
	var mid := door.global_position + basis.x * door.width / 2.0
	var away := -signf(basis.z.dot(at - mid))   # Flurseite: weg vom Spind
	var along := -1.0 if door.hinge_end else 1.0   # gegenüber dem Scharnier
	var face := basis.z * away
	leave_notice = NoticeBoard.Sheet.new()
	leave_notice.name = "AushangBetriebsferien"
	leave_notice.doc_id = LEAVE_DOC
	leave_notice.prompt = "Aushang lesen [E]"
	leave_notice.jot_id = LEAVE_DOC
	leave_notice.jot = LEAVE_JOT
	leave_notice.jot_from = "Personalflur"
	leave_notice.show_text(LEAVE_SIZE, "", LEAVE_TEXT, LEAVE_TITLE, LEAVE_TEXT)
	add_child(leave_notice)
	var pos := mid + basis.x * along * (door.width / 2.0 + LEAVE_GAP + LEAVE_SIZE.x / 2.0) + face * LEAVE_OFF
	leave_notice.global_transform = Transform3D(Basis.looking_at(face, Vector3.UP, true), Vector3(pos.x, door.global_position.y + LEAVE_HEIGHT, pos.z))


## Spind des Hausmeisters: der mit Slice CARETAKER_LOCKER im Plan (SteelLocker.names) – solange der Slice fehlt
## (GEGENSTAENDE), der einzige Stahlspind im Erdgeschoss; laut Legende steht nur seiner dort (PLANFARBEN „Spind“).
func _caretaker_locker() -> SteelLocker:
	var ground: Array[SteelLocker] = []
	for node in get_tree().get_nodes_in_group("steel_lockers"):
		var locker := node as SteelLocker
		if CARETAKER_LOCKER in locker.names.values():
			return locker
		if absf(locker.global_position.y) < GROUND_SPAN:
			ground.append(locker)
	return ground[0] if ground.size() == 1 else null


## Getipptes von der Maschine der Chefsekretärin lesen (2.11): Blatt mit springendem „e“, Notiz (jot, einmal je id),
## dann JUMP_JOT, sobald der Willkommensbrief und eins der Blätter aus Sekretariat/Büro gelesen sind.
func read_typed(id: String, title: String, text: String, jot: String = "", jot_from: String = "") -> void:
	if Game.menus:
		Game.menus.open_typed(title, text)
	if Game.notebook == null:
		return
	if jot != "":
		Game.notebook.add_note(id, jot, jot_from)
	var letter := id == WELCOME_DOC or (Game.contest != null and Game.contest.letter_read)
	if letter and OLD_DOCS.any(func(doc: String) -> bool: return Game.notebook.has_note(doc)):
		Game.notebook.add_note(JUMP_NOTE, JUMP_JOT)


## Vertrag lesen (Item.Kind.CONTRACT in der Hand, Linksklick)
func read_contract() -> void:
	read_typed(CONTRACT_DOC, CONTRACT_TITLE, CONTRACT_TEXT, CONTRACT_JOT, "Büro der Direktion")


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
