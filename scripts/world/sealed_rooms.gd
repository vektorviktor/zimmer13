class_name SealedRooms
extends Node
## Versiegelte Zimmer von 1987 (Spielkonzept 6.19 (7); ZIM-30): seit Halloween 1987 hat niemand sie betreten. Jedes hat
## sein altes Schloss – Brecheisen und Generalschlüssel helfen nicht (Door.sealed) – und die Fenstertür ist von innen
## verriegelt (Door.bolt_room). Je Weg aus 2.3 ein Zimmer, der Schlüssel heißt „zimmer_<Nummer>“ wie bei jeder Zimmertür:
##   · 042 Geduld: der Schlüssel im Krähennest (Crows, 4.25); drinnen Tagebuch und Sturmlaterne – noch nicht gebaut
##   · 132 Vertrauen: Liesel Brück (H26) hat den Schlüssel ihrer Familie nie abgegeben und gibt ihn dem Spieler, sobald
##     er ihr Freund ist und ihr begegnet (_offer_key). Drinnen das Familienfoto von 1987 (Item.Kind.FAMILY_PHOTO) –
##     bringt man es ihr, ist das ein Abschluss für sie (photo_back), kein Werkzeug.
##   · 038 Wissen: Ein älterer Witwer war 1987 allein zur Kur hier. Sein Brief an die Tochter (Letter) liegt nie
##     abgeschickt im Postausgang auf dem Schreibtisch des Sekretariats (bestätigt 3.11.): Er hat das Zimmer abgeschlossen und
##     den Schlüssel im Rahmen des Bildes im Flur vor 038 versteckt. Erst wer den Brief gelesen hat, tastet hinter den
##     Rahmen (Painting → frame_ready). Drinnen ein Ölkännchen (Item.Kind.OIL_CAN, Door._oil).
##   · 018 Wagnis: eigenes Zimmer des Hausmeisters von 2003 (LevelBuilder.LOCKED_ROOM, CaretakerBook) – nicht hier.
## Nichts Eigenes im Spielstand: Schlüssel stehen am Bund, gelesen ist der Brief über die Notiz LETTER_NOTE (ohne
## Notizbuch nur bis zum Neuladen), Foto und Kännchen sind Gegenstände; geölte Türen speichert der SaveManager (doors).
## Erreichbar über Game.sealed_rooms.

## Versiegelte Zimmer (042 hat seinen Schlüssel in Crows.OLD_KEY)
const ROOMS: Array[String] = ["042", "132", "038"]
const TRUST_ROOM := "132"
const KNOWLEDGE_ROOM := "038"
## Liesel (HAUSHALTE.md H26): ab dieser Stufe gibt sie den Schlüssel, so nah muss sie dir begegnen (m)
const LIESEL_HOUSEHOLD := "H26"
const KEY_TIER := Social.Tier.FRIEND
const KEY_RANGE := 3.0
const CHECK_EVERY := 0.5
const KEY_LINE := "Den hier trag ich seit 1987 mit mir rum. Zimmer 132 – da haben wir gewohnt, Mama, Papa und ich. Ich war nie wieder drin. Geh du. Und wenn da noch was von uns liegt … bring es mir."
const KEY_NOTE := "Liesel hat mir den Schlüssel von Zimmer 132 gegeben – dort hat ihre Familie 1987 gewohnt. Sie war nie wieder drin."
## Familienfoto zurück: Beziehung danach mindestens so hoch (wie der Ehering, GuestRequests.RING_FRIEND)
const PHOTO_FRIEND := 80.0
const PHOTO_LINE := "Das sind wir. Vor dem Haupteingang, gleich am ersten Tag. Danach hat keiner mehr Fotos gemacht … Ich hab gedacht, ich weiß nicht mehr, wie sie ausgesehen haben. Danke."
const PHOTO_NOTE := "Liesel hat das Foto ihrer Familie von 1987 wieder. Sie hat lange draufgesehen."
const PHOTO_DIARY := "Ich habe Liesel das Foto ihrer Familie gebracht, aus Zimmer 132. Sie hat nicht geweint. Sie hat nur genickt, als hätte sie lange darauf gewartet."
## Brief aus 038 (Texte Vorschlag, 6.19 (7)) und was danach im Notizbuch steht
const LETTER_NOTE := "brief_038"
const LETTER_TITLE := "Brief im Postausgang, Oktober 1987"
const LETTER_TEXT := "Ein Umschlag mit Marke, nie gestempelt. „An Frau Ingrid Saalfeld“ steht darauf, darunter eine Anschrift, die das Wasser verwischt hat.

Meine liebe Ingrid,

der Doktor sagt, die Luft hier tut mir gut, und ich soll Dir das auch so schreiben. Aber ich will Dir nichts vormachen, das hat Deine Mutter nie gemocht: Hier stimmt etwas nicht. Nachts wird es warm im Flur, und in den Rohren atmet etwas. Beim Frühstück fehlen jeden Morgen mehr, und keiner fragt nach ihnen.

Ich habe mein Zimmer abgeschlossen, die 038, und den Schlüssel nicht bei mir behalten. Er steckt im Flur vor meiner Tür, hinten im Rahmen des Bildes. Was drin ist, soll keiner anfassen, bevor Du kommst.

Wenn Du diesen Brief bekommst und ich mich nicht melde, dann frag nach mir. Lass Dich nicht abwimmeln.

Ich gebe ihn morgen an der Rezeption auf. Morgen ist der 31.

Dein Vater"
const LETTER_JOT := "Der Witwer aus 038 (1987) hat sein Zimmer abgeschlossen. Der Schlüssel steckt im Rahmen des Bildes im Flur vor 038."
## Brief auf dem Schreibtisch des Sekretariats (lokal zum Tisch: links hinten auf der Platte, Desk.layout „size“)
const LETTER_SPOT := Vector3(-0.42, 0.0, -0.12)
## So weit (m, waagerecht) vor der Tür von 038 darf das Bild mit dem Schlüssel im Flur hängen
const FRAME_RANGE := 6.0

var _builder: LevelBuilder
var _frame: Painting           ## Bild im Flur vor 038 (aus dem Plan) – null, wenn der Plan dort keins zeigt
var _letter: Letter
var _letter_read := false      ## in dieser Sitzung gelesen (ohne Notizbuch bleibt es nur bis zum Neuladen)
var _check := 0.0


## Schlüssel eines versiegelten Zimmers (Messing von 1987, eigenes Aussehen und Etikett in Item)?
static func is_old_key(id: String) -> bool:
	return id in ROOMS.map(func(no: String) -> String: return "zimmer_" + no)


## Türen versiegeln, Fenstertüren verriegeln, Foto und Kännchen hineinlegen, Brief und Rahmen suchen. Nach dem Bau der
## Welt (Desk, Painting stehen schon) und nach add_child.
func setup(builder: LevelBuilder) -> SealedRooms:
	_builder = builder
	for no in ROOMS:
		if not builder.rooms.has(no):
			push_warning("Versiegeltes Zimmer %s fehlt im Plan" % no)
			continue
		var door: Door = builder.rooms[no]["door"]
		door.sealed = true
		door.locked = true
		door.key_id = "zimmer_" + no
		door.locked_text = "Zimmer %s ist abgeschlossen. Dunkle Eiche, ein altes Kastenschloss." % no
	for node in get_tree().get_nodes_in_group("french_doors"):
		var door := node as Door
		if door.room_id in ROOMS:   # Terrasse bzw. Balkon: seit 1987 von innen verriegelt
			door.bolt_room = door.room_id
			door.locked = true
			door.key_id = "riegel"
			door.monster_can_open = false
			door.locked_text = "Von innen verriegelt. Hinter dem Glas sind die Vorhänge zugezogen."
	_put_inside(TRUST_ROOM, Item.Kind.FAMILY_PHOTO)
	_put_inside(KNOWLEDGE_ROOM, Item.Kind.OIL_CAN)
	_place_letter()
	_frame = _find_frame()
	if _frame == null and builder.rooms.has(KNOWLEDGE_ROOM):
		push_warning("Gebäudeplan: kein Bild im Flur vor Zimmer %s – der Schlüssel aus dem Brief hat kein Versteck (Bild in den Plan malen, Spielkonzept 6.19 (7))" % KNOWLEDGE_ROOM)
	return self


## Fund auf den Tisch des Zimmers, ohne Tisch in die Mitte auf den Boden (die Zimmer sind im Plan noch leer).
func _put_inside(no: String, kind: Item.Kind) -> void:
	if not _builder.rooms.has(no):
		return
	var room: Dictionary = _builder.rooms[no]
	var item := Item.create(kind)
	_builder.world.add_child(item)
	item.global_position = (_builder.room_tables.get(no, room["center"]) as Vector3) + Vector3.UP * 0.03


## Brief in den Postausgang auf dem Schreibtisch des Sekretariats (6.19 (7), Ort bestätigt 3.11.).
func _place_letter() -> void:
	for node in get_tree().get_nodes_in_group("desks"):
		var desk := node as Desk
		if desk.variant != "sekretariat":
			continue
		var top := float((Desk.layout(desk.variant)["size"] as Array)[1])
		_letter = Letter.new()
		_letter.name = "Brief038"
		_letter.rooms = self
		desk.add_child(_letter)
		_letter.position = LETTER_SPOT + Vector3.UP * (top + 0.001)
		_letter.rotation.y = 0.2
		return
	push_warning("Kein Schreibtisch im Sekretariat – der Brief aus Zimmer %s fehlt" % KNOWLEDGE_ROOM)


## Das Bild im Flur vor 038: das nächste aus dem Plan, höchstens FRAME_RANGE vor der Tür, auf demselben Stockwerk.
func _find_frame() -> Painting:
	if not _builder.rooms.has(KNOWLEDGE_ROOM):
		return null
	var front: Vector3 = _builder.rooms[KNOWLEDGE_ROOM]["door_front"]
	var best: Painting = null
	var best_d := FRAME_RANGE
	for node in get_tree().get_nodes_in_group("paintings"):
		var pic := node as Painting
		var at := pic.global_position
		var d := Vector2(at.x - front.x, at.z - front.z).length()
		if d < best_d and absf(at.y - front.y) < 3.0 and _builder.room_at(at + pic.global_basis.z * 0.3) != KNOWLEDGE_ROOM:
			best = pic
			best_d = d
	return best


func _process(delta: float) -> void:
	_check -= delta
	if _check <= 0.0:
		_check = CHECK_EVERY
		_offer_key()


# --- Vertrauen: Liesel und Zimmer 132 --------------------------------------------------------------------------------

static func is_liesel(g: Guest) -> bool:
	return g != null and not g.is_child() and String(g.profile.get("household", "")) == LIESEL_HOUSEHOLD


## Gäbe Liesel dir jetzt den Schlüssel? Ab KEY_TIER, solange er nicht schon am Bund ist.
func would_give(g: Guest) -> bool:
	return is_liesel(g) and not g.dead and Social.tier(g) >= KEY_TIER and Game.player != null \
		and not Game.player.has_key("zimmer_" + TRUST_ROOM)


## Wie der Zweitschlüssel (RoomAccess._offer_spares): Liesel in der Nähe, sie sieht dich, ist frei und nicht in Panik,
## keine Gefahr, kein Gespräch.
func _offer_key() -> void:
	var p := Game.player
	if p == null or p.dead or p.sleeping or p.hiding or Game.social == null or (Game.dialog and Game.dialog.visible):
		return
	for g in Game.social.living_guests():
		var liesel: Guest = g
		if not would_give(liesel) or not liesel.state in [Guest.State.IDLE, Guest.State.WALK] or liesel.fear >= 60.0 \
				or liesel.global_position.distance_to(p.global_position) > KEY_RANGE or not liesel.can_see_actor(p) \
				or not p.recognized_by(liesel):
			continue
		give_key(liesel)
		return


func give_key(liesel: Guest) -> void:
	Game.player.add_key("zimmer_" + TRUST_ROOM)
	liesel.say(KEY_LINE)
	Game.say("%s gibt dir einen alten Messingschlüssel. Am Anhänger steht 132." % liesel.display_name, 4.0)
	if Game.notebook:
		Game.notebook.add_note("liesels_schluessel", KEY_NOTE, liesel.display_name)
	if Game.tracing:
		print("[Versiegelt] %s gibt dir den Schlüssel von Zimmer %s" % [liesel.display_name, TRUST_ROOM])


static func is_liesels_photo(g: Guest, item: Item) -> bool:
	return item != null and item.kind == Item.Kind.FAMILY_PHOTO and is_liesel(g)


## Das Familienfoto zurück (DialogUI._gift): Sie behält es, Beziehung mindestens PHOTO_FRIEND, die Angst fällt, im
## Notizbuch und im Tagebuch. Gibt ihre Antwort zurück.
func photo_back(liesel: Guest, photo: Item) -> String:
	if photo:
		photo.queue_free()
	var damp := 1.0 - clampf(liesel.relation, 0.0, 100.0) / 110.0
	Game.social.change_relation(liesel, maxf(GuestRequests.HEART_REWARD, (PHOTO_FRIEND - liesel.relation) / damp + 0.5))
	liesel.relation = maxf(liesel.relation, PHOTO_FRIEND)   # die Abflachung bleibt sonst knapp darunter
	Game.social.add_deed(liesel, "gifts_from")
	liesel.fear = 0.0
	if Game.notebook:
		Game.notebook.add_note("liesels_foto", PHOTO_NOTE, liesel.display_name)
	if Game.diary:
		Game.diary.note("liesels_foto", PHOTO_DIARY, liesel.id)
	if Game.tracing:
		print("[Versiegelt] %s hat ihr Familienfoto: Beziehung %.0f (%s)" % [liesel.display_name, liesel.relation,
			Social.relation_word(liesel.relation)])
	return PHOTO_LINE


# --- Wissen: der Brief und Zimmer 038 --------------------------------------------------------------------------------

func letter_read() -> bool:
	return _letter_read or (Game.notebook != null and Game.notebook.has_note(LETTER_NOTE))


## show = false: nur als gelesen merken (Debug, ohne das Blatt aufzuschlagen).
func read_letter(show := true) -> void:
	if show and Game.menus:
		Game.menus.open_note(LETTER_TITLE, LETTER_TEXT)
	_letter_read = true
	if Game.notebook:
		Game.notebook.add_note(LETTER_NOTE, LETTER_JOT, "Brief aus dem Sekretariat")


## Hinter diesem Rahmen tasten? Das Bild vor 038, den Brief gelesen, der Schlüssel noch nicht am Bund.
func frame_ready(pic: Painting) -> bool:
	return pic == _frame and letter_read() and Game.player != null \
		and not Game.player.has_key("zimmer_" + KNOWLEDGE_ROOM)


func take_frame_key(player: Player) -> void:
	player.add_key("zimmer_" + KNOWLEDGE_ROOM)
	Game.say("Hinten im Rahmen, zwischen Leiste und Wand, steckt ein alter Messingschlüssel. Am Anhänger: 038.", 4.0)
	Game.noise("keys", _frame.global_position, player)
	if Game.tracing:
		print("[Versiegelt] Schlüssel von Zimmer %s aus dem Rahmen" % KNOWLEDGE_ROOM)


## Das Bild, hinter dem der Schlüssel steckt (null = der Plan zeigt vor 038 keins).
func frame() -> Painting:
	return _frame


func letter() -> Node3D:
	return _letter


## Nur für --versiegelt=pruefen: Zeigt der Plan vor 038 kein Bild, hängt ein Probebild neben der Tür an der Flurwand –
## im Spiel gibt es dann keins (das malt der Nutzer in den Plan).
func debug_probe_frame() -> Painting:
	if _frame != null or not _builder.rooms.has(KNOWLEDGE_ROOM):
		return _frame
	var room: Dictionary = _builder.rooms[KNOWLEDGE_ROOM]
	var into: Vector3 = room["into"]
	var wall := (room["door_inside"] as Vector3) - into * 1.11   # Flurseite der Wand mit der Tür
	var pic := Painting.new().setup(Painting.pick("corridor", 0), "corridor")
	_builder.world.add_child(pic)
	pic.global_position = wall + (room["along"] as Vector3) * 1.6 + Vector3.UP * 1.75
	pic.rotation.y = atan2(-into.x, -into.z)
	_frame = pic
	return pic


## Brief im Postausgang: ein Umschlag auf einem Stapel Ablage, fest (nicht tragbar), [E] liest ihn.
class Letter extends StaticBody3D:
	var rooms: SealedRooms

	func _ready() -> void:
		collision_layer = 4
		collision_mask = 0
		set_meta("interactable", self)
		add_to_group("sealed_letters")
		Geo.mesh(self, Geo.box(Vector3(0.24, 0.02, 0.32)), Mat.psx(Color(0.45, 0.32, 0.2)), Vector3(0, 0.01, 0))   # Ablagekorb
		Geo.mesh(self, Geo.box(Vector3(0.22, 0.006, 0.11)), Mat.psx(Color(0.86, 0.8, 0.66)), Vector3(0, 0.023, 0.02))   # Umschlag
		Geo.mesh(self, Geo.box(Vector3(0.022, 0.001, 0.026)), Mat.psx(Color(0.55, 0.2, 0.18)), Vector3(0.09, 0.0265, -0.01))   # Marke
		Geo.add_box_shape(self, Vector3(0.26, 0.06, 0.34), Vector3(0, 0.03, 0))

	func get_prompt(_player: Player) -> String:
		return "Brief lesen [E]"

	func interact(_player: Player) -> void:
		rooms.read_letter()
