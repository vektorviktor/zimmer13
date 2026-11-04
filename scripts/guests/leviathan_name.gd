class_name LeviathanName
extends Node
## Der Name: Leviathan (Spielkonzept 4.32). Bis zur ersten bestätigten Sichtung sagen die Gäste „es“, „das Ding“.
##   · Bestätigt: Ein erwachsener Gast sieht das Monster (Guest._watch_monster) oder wird erschreckt bzw. reißt sich
##     los (scared_by_monster) – und lebt CONFIRM_AFTER s später noch. Kinder zählen nicht, ihnen glaubt keiner (6.13).
##   · Am selben Abend (ab EVENING, nach LATEST erst am nächsten) holt Hugo Stein (H27) Dorés „Die Zerstörung des
##     Leviathan“ aus dem Koffer und legt es auf den Couchtisch der Lobby; der Zeuge, Hugos Freunde und ein Skeptiker
##     kommen dazu (wie zur Siegerehrung, join_party mit Blick). Er wartet WAIT_PLAYER auf den Spieler, dann die Sätze.
##     Ist Hugo tot, gibt Liesel Brück (H26) den Namen – über das Buch Hiob, ohne Druck.
##   · Danach kennen ihn die Anwesenden; über das Gerede (zwei Freunde nah beieinander, wie Talk) erfahren es die
##     anderen, nach ALL_KNOW_AFTER alle. Wer ihn kennt, sagt die Sätze aus RENAMED statt „es“ (Guest.line → speak);
##     das Gerede lockt das Monster wie jedes andere (4.7).
##   · Der Spieler kennt den Namen, wenn er dabei war, ihn in seiner Nähe hört oder den Druck ansieht: Notizbuch und
##     Tagebuch übernehmen ihn, seine Erzähl-Knöpfe auch (Talk.tell_label).
##   · Der Druck hängt danach neben der Fotowand (5.14), [E] sieht ihn an.
##   · Das Foto (ZIM-101): Paula Jansen (H30) fotografiert ihn beim ersten Angriff, den sie mitbekommt – das Monster
##     packt oder erschreckt einen Gast (MonsterDirector.kill_guest) und sie sieht es (PHOTO_SIGHT, freie Sicht) oder
##     hört den Schrei (Senses wie Social.on_alarm), bzw. sie war es selbst und lebt. Das zählt auch als ihre Sichtung.
##     Im nächsten ruhigen Moment nach PIN_AFTER heftet sie das Sofortbild an die Fotowand (PhotoWall.pin_snapshot),
##     [E] sieht es an; von da an sind die Skeptiker still (SILENCED, Talk._believes, kein Einwand in Hugos Szene).
##     Stirbt Paula vorher, gibt es kein Foto. Das Bild ist ein Platzhalter (PhotoWall.draw_leviathan_photo, ZIM-135).
## Erreichbar über Game.leviathan_name; gespeichert unter „leviathan“.
## Offen (Vorschläge in 4.32): Liesels Abendgebet, Marion, die hinausgeht – beides gibt es im Spiel noch nicht.

enum Stage { NONE, SEEN, GATHERING, SCENE, NAMED }

const HUGO := "H27"
const LIESEL := "H26"
## Sichtung bestätigt, wenn der Zeuge so lange danach noch lebt (s Spielzeit)
const CONFIRM_AFTER := 120.0
## Hugo holt den Druck frühestens um EVENING Uhr hervor; ist die Sichtung nach LATEST, erst am nächsten Abend
const EVENING := 19.0
const LATEST := 22.5
## So lange wartet Hugo am Tisch auf den Spieler; spätestens so lange nach dem Aufbruch beginnt die Szene
const WAIT_PLAYER := 0.75 * Calendar.HOUR
const GATHER_MAX := 2.0 * Calendar.HOUR
## Plätze um den Tisch: Hugo so weit davor, die anderen im Kreis mit diesem Abstand, höchstens so viele
const HUGO_GAP := 0.75
const RING := 1.4
const MAX_GATHER := 7
## Abstand der Sätze in der Szene, so lange stehen sie danach noch am Tisch
const LINE_GAP := 4.5
const LINGER := 20.0
## Der Spieler hört Sätze mit dem Namen aus dieser Nähe
const HEAR_RANGE := 6.0
## Weitererzählen (wie Talk): so nah, so oft geschaut, so wahrscheinlich; nach so langer Zeit kennen ihn alle
const TELL_RANGE := 3.2
const TELL_SCAN := 1.5
const TELL_CHANCE := 0.45
const ALL_KNOW_AFTER := 1.5 * Calendar.DAY_SECONDS
## So oft ersetzt ein eigener Leviathan-Satz einen Satz über das Monster
const OWN_LINE_CHANCE := 0.3
## Der Druck an der Wand: Ausstattung „Leviathan-Druck“ im Plan (ZIM-158, Mitte so hoch wie PRINT_AT), sonst PRINT_AT
## an der Westwand der Lobby zwischen Aushangbrett und Wandlampe, gegenüber der Fotowand (ZIM-133); Bildmaß
const PRINT_PATH := "res://assets/textures/dore_leviathan.jpg"
const PRINT_AT := Vector3(-7.38, 1.72, -18.3)
const PRINT_SIZE := Vector2(0.36, 0.455)
const PRINT_TABLE_SIZE := Vector2(0.24, 0.3)
const PRINT_TITLE := "Gustave Doré: Die Zerstörung des Leviathan"
const PRINT_TEXT := "Ein Holzstich aus einer alten Bibel, 1865. Ein Ungeheuer windet sich in der Brandung – Zacken am Rücken, ein langer Schädel, das Maul offen. Hugo hat es hier aufgehängt; unten am Rand steht in seiner Schrift: »Der Leviathan. Hiob 40.«"

## Das Foto (ZIM-101): Paulas Haushalt, so weit sieht sie einen Angriff, so lange danach heftet sie es an
const PAULA := "H30"
const PHOTO_SIGHT := 15.0
const PIN_AFTER := 0.5 * Calendar.HOUR
const PAULA_SNAP := "Halt still … Ich hab's! Ich hab es auf dem Bild!"
const PHOTO_TITLE := "Paulas Sofortbild"
const PHOTO_PROMPT := "Sofortbild ansehen [E] – mit einer Reißzwecke angeheftet"
const PHOTO_TEXT := "Ein Sofortbild, schief an die Wand geheftet. Ein dunkler Flur im Blitzlicht, vorn alles überstrahlt. Mitten im Bild eine lange, dünne Gestalt, verwischt, als wäre sie gerade losgesprungen – Zacken am Rücken, ein langer Schädel, ein Lichtpunkt, wo ein Auge sein müsste. Unten auf dem weißen Rand, in Paulas Schrift: »%s – P. J., %s«"
const PHOTO_CAPTION := "Es ist echt."
const PHOTO_CAPTION_NAMED := "Der Leviathan. Er ist echt."
const NOTE_PHOTO := "Paula Jansen hat es fotografiert. Das Sofortbild hängt an der Fotowand – unscharf, aber da ist etwas. Die Skeptiker sagen seitdem nichts mehr."
const NOTE_PHOTO_NAMED := "Paula Jansen hat den Leviathan fotografiert. Das Sofortbild hängt an der Fotowand – unscharf, aber er ist es. Die Skeptiker sagen seitdem nichts mehr."
const DIARY_PHOTO := "Paula hat ein Foto davon gemacht. Unscharf, aber jetzt kann es keiner mehr wegreden."
## Zweifel-Sätze der Skeptiker (GuestGenerator) → was sie sagen, seit das Foto hängt
const SILENCED := {
	"Es gibt für alles eine Erklärung. Ich hab sie nur noch nicht gefunden.":
		"Ich hab Paulas Foto gesehen. Ich … sag dazu lieber nichts mehr.",
	"Ich führe Buch: Wann das Licht flackert, wo es rauscht. Da steckt ein Muster drin.":
		"Ich hab aufgehört, Buch zu führen. Seit dem Foto.",
}

## Szene: [Sprecher, Satz] – Sprecher hugo, liesel, witness, skeptic; fehlt er, entfällt der Satz
const SCENE_HUGO := [
	["hugo", "Ich habe da etwas im Koffer. Seht euch das an."],
	["hugo", "Die Stacheln am Rücken. Dieser lange Schädel. Das ist er."],
	["witness", "So … ja. So ungefähr. Nur dünner."],
	["hugo", "Der Leviathan. Im Buch Hiob heißt es, niemand kann ihn fangen."],
	["skeptic", "Ein Bild aus einer alten Bibel, Hugo. Mehr nicht."],
	["hugo", "Ich hänge es an die Wand. Bei den Fotos. Damit es jeder sieht."],
]
const SCENE_LIESEL := [
	["liesel", "Ich habe gebetet. Die ganze Nacht. Und dann stand es da, im Buch Hiob."],
	["liesel", "»Kannst du den Leviathan ziehen mit dem Haken?« – Das ist er. Der Leviathan."],
	["witness", "Ich weiß nicht, wie es heißt. Aber … ja. Das passt."],
	["skeptic", "Jetzt geben wir ihm schon Namen aus der Bibel, Liesel."],
]
## Hugo war selbst der Zeuge
const HUGO_WITNESS := "Ich habe ihn gesehen. So ungefähr – nur dünner."
## Hugo bzw. Liesel auf dem Weg zum Tisch (einmal, wenn sie aufbrechen)
const CALL_HUGO := "Kommt mal alle her. Ich muss euch etwas zeigen."
const CALL_LIESEL := "Kommt her … bitte. Ich weiß jetzt, was es ist."
## Weitererzählt
const TELL_LINES := ["Hugo sagt, es ist der Leviathan. Wie in der Bibel.", "Hast du's gehört? Es hat jetzt einen Namen: der Leviathan.",
	"Der Leviathan – so nennt Hugo es. Ein altes Bild hat er auch.", "Sie nennen es jetzt den Leviathan. Klingt nicht besser, oder?"]
const TELL_LINES_LIESEL := ["Liesel sagt, es ist der Leviathan. Aus dem Buch Hiob.", "Es hat jetzt einen Namen: der Leviathan. Liesel hat ihn in der Bibel gefunden."]
const TELL_REPLY := ["Der Leviathan … na großartig.", "Ein Name macht es auch nicht kleiner.", "Hör auf. Mir reicht schon „es“."]
## Eigene Sätze über den Leviathan (Thema „monster“), wenn man den Namen kennt
const OWN_LINES := ["Hugo hat ein Bild davon. Der Leviathan. Seitdem schlafe ich noch schlechter.",
	"Der Leviathan. Seit es einen Namen hat, ist es irgendwie … wirklicher.",
	"Im Buch Hiob heißt es, niemand kann den Leviathan fangen. Na, dann halten wir uns eben fern.",
	"Sag den Namen nicht so laut. Wer weiß, ob er ihn kennt."]
## Notizbuch, Tagebuch (je nach dem, wer ihn benannt hat)
const NOTE_HUGO := "Hugo nennt es den Leviathan – nach einem alten Bibeldruck aus seinem Koffer. Stacheln am Rücken, langer Schädel."
const NOTE_LIESEL := "Liesel nennt es den Leviathan – aus dem Buch Hiob. Niemand kann ihn fangen, steht da."
const DIARY_ENTRY := "Sie haben ihm einen Namen gegeben: der Leviathan. Ein Ungeheuer aus der Bibel. Es passt besser, als mir lieb ist."

## Sätze der Gäste vorher → nachher (Guest.line). Neue Sätze über das Monster mit „es“ hier nachtragen.
const RENAMED := {
	# Grundstock (GuestGenerator.COMMON)
	"Wenn das Rauschen lauter wird, ist es nah. Dann such dir ein Versteck – eins, bei dem es dich nicht sieht.":
		"Wenn das Rauschen lauter wird, ist der Leviathan nah. Dann such dir ein Versteck – eins, bei dem er dich nicht sieht.",
	"Licht hält es fern. Ein geschnitzter Kürbis mit Kerze vor der Tür wirkt Wunder.":
		"Licht hält den Leviathan fern. Ein geschnitzter Kürbis mit Kerze vor der Tür wirkt Wunder.",
	"Es kommt aus dem Keller. Ganz unten im Treppenhaus, wo die Treppe aufhört … da gehe ich nicht hin.":
		"Der Leviathan kommt aus dem Keller. Ganz unten im Treppenhaus, wo die Treppe aufhört … da gehe ich nicht hin.",
	"Die Lampen flackern dort, wo es gerade ist. Achte darauf.":
		"Die Lampen flackern dort, wo der Leviathan gerade ist. Achte darauf.",
	"Je mehr wir darüber reden, desto dreister wird es. Also … leise.":
		"Je mehr wir über den Leviathan reden, desto dreister wird er. Also … leise.",
	"In den Flügeln ist es am dunkelsten. Da streift es am liebsten herum.":
		"In den Flügeln ist es am dunkelsten. Da streift der Leviathan am liebsten herum.",
	"Es ist hinter mir! Mach auf!": "Der Leviathan ist hinter mir! Mach auf!",
	# Skeptiker, Griesgram (GuestGenerator)
	"Es kommt in Phasen. Mal ist es lange ruhig – dann ist es im Keller.":
		"Der Leviathan kommt in Phasen. Mal ist es lange ruhig – dann ist er im Keller.",
	"Es reagiert auf Blicke. Starr es nicht an, wenn du nicht gefunden werden willst.":
		"Der Leviathan reagiert auf Blicke. Starr ihn nicht an, wenn du nicht gefunden werden willst.",
	"Zu laut, zu dunkel, zu kalt. Und dann dieses Ding im Keller.":
		"Zu laut, zu dunkel, zu kalt. Und dann dieser Leviathan im Keller.",
	# Edna
	"Es mag kein Licht, glaube ich. Ich lasse meine Kerzen immer brennen.":
		"Der Leviathan mag kein Licht, glaube ich. Ich lasse meine Kerzen immer brennen.",
	"Zuckt das Licht nur kurz, sieht es sich bloß um. Aber wenn es lange flackert … dann hat es Hunger.":
		"Zuckt das Licht nur kurz, sieht der Leviathan sich bloß um. Aber wenn es lange flackert … dann hat er Hunger.",
	"Hörst du das Rauschen auch? Je lauter es wird, desto näher ist es.":
		"Hörst du das Rauschen auch? Je lauter es wird, desto näher ist der Leviathan.",
	"Es ist hinter mir! Lass mich rein!": "Der Leviathan ist hinter mir! Lass mich rein!",
	"Hier ist Edna … ich flüstere, entschuldige. Es ist {where}. Bleib in deinem Zimmer, Kind.":
		"Hier ist Edna … ich flüstere, entschuldige. Der Leviathan ist {where}. Bleib in deinem Zimmer, Kind.",
	# Bruno
	"Das Ding schläft im Keller. Wenn's ruhig ist, ist es dort unten.":
		"Der Leviathan schläft im Keller. Wenn's ruhig ist, ist er dort unten.",
	"Starr es bloß nicht an. Dann weiß es Bescheid.": "Starr den Leviathan bloß nicht an. Dann weiß er Bescheid.",
	"Wenn es dich in einen Schrank springen sieht, bist du erledigt.":
		"Wenn der Leviathan dich in einen Schrank springen sieht, bist du erledigt.",
	"Bruno hier. Kurz und knapp: Es ist {where}. Und ich hab dich nicht angerufen, klar?":
		"Bruno hier. Kurz und knapp: Der Leviathan ist {where}. Und ich hab dich nicht angerufen, klar?",
	# Mila
	"Ich glaube, Gerede lockt es an. Je mehr wir darüber reden, desto frecher wird es.":
		"Ich glaube, Gerede lockt den Leviathan an. Je mehr wir über ihn reden, desto frecher wird er.",
	"In der Wäscherei hängen Spinnweben. Die hält es angeblich auch fern.":
		"In der Wäscherei hängen Spinnweben. Die halten den Leviathan angeblich auch fern.",
	"Es kriecht durch die dunklen Zimmer. Zimmer 017 ist schon lange verlassen …":
		"Der Leviathan kriecht durch die dunklen Zimmer. Zimmer 017 ist schon lange verlassen …",
	"Verlass dich nicht auf ein kurzes Flackern. Ich glaube, manchmal lügt es.":
		"Verlass dich nicht auf ein kurzes Flackern. Ich glaube, manchmal lügt der Leviathan.",
	"Bitte! Mach auf, es kommt!": "Bitte! Mach auf, der Leviathan kommt!",
	"Ich bin's, Mila! Es ist {where}, ich hab's gerade gesehen! Geh da bloß nicht hin!":
		"Ich bin's, Mila! Der Leviathan ist {where}, ich hab ihn gerade gesehen! Geh da bloß nicht hin!",
}

var stage := Stage.NONE
var witness := ""           ## Gast-ID des ersten bestätigten Zeugen
var seen_at := -1.0         ## wann die Sichtung bestätigt wurde (MonsterDirector.elapsed)
var namer := ""             ## Haushalt, der den Namen gab (HUGO oder LIESEL)
var named_at := -1.0
var knowers := {}           ## Gast-ID → true
var player_knows := false

var _builder: LevelBuilder
var print_at := Transform3D(Basis(Vector3.UP, PI / 2.0), PRINT_AT)   ## Druck an der Wand (global), +Z in den Raum
var _pending := {}          ## Gast-ID → Zeitpunkt der Sichtung (noch nicht bestätigt)
var _gather_since := 0.0
var _in_lobby := 0.0
var _spots := {}            ## Gast-ID → Platz am Tisch
var _gathered: Array[Guest] = []
var _lines: Array = []
var _line_t := 0.0
var _cast := {}             ## Sprecher → Gast
var _sheet: PrintSheet      ## Druck auf dem Tisch bzw. an der Wand
var _tell := TELL_SCAN
var _check := 1.0
var _debug_now := false     ## Debug: Hugo wartet nicht auf den Abend
var photo_at := -1.0        ## wann Paula den Angriff fotografiert hat (MonsterDirector.elapsed), -1 = noch nicht
var photo_pinned := false   ## das Foto hängt an der Fotowand – die Skeptiker sind still
var _photo_check := 1.0


func setup(builder: LevelBuilder) -> LeviathanName:
	_builder = builder
	print_at = builder.planned_at("leviathan_print", print_at, PRINT_AT.y, 0.02)
	return self


func is_named() -> bool:
	return stage == Stage.NAMED


## Kennt dieser Gast den Namen?
func knows(g: Guest) -> bool:
	if stage != Stage.NAMED or g == null:
		return false
	return knowers.has(g.id) or (Game.director != null and Game.director.elapsed - named_at >= ALL_KNOW_AFTER)


# --- Sichtungen -----------------------------------------------------------------------------

## Ein Gast hat das Monster gesehen oder wurde von ihm erschreckt (Guest). Bestätigt erst, wenn er überlebt.
func on_sighting(g: Guest) -> void:
	if stage != Stage.NONE or g.is_child() or g.dead or (Game.director and Game.director.skipping):
		return
	if not _pending.has(g.id):
		_pending[g.id] = Game.director.elapsed if Game.director else 0.0


func _check_pending() -> void:
	var now := Game.director.elapsed
	for id in _pending.keys():
		var g := Game.social.guest_by_id(id)
		if g == null or g.dead:
			_pending.erase(id)
		elif now - float(_pending[id]) >= CONFIRM_AFTER:
			_confirm(g)
			return


func _confirm(g: Guest) -> void:
	_pending.clear()
	stage = Stage.SEEN
	witness = g.id
	seen_at = Game.director.elapsed
	if Game.tracing:
		print("[Leviathan] bestätigte Sichtung: %s" % g.display_name)


## Wann Hugo den Druck hervorholt: am Abend der Sichtung, war sie zu spät, am nächsten.
func _gather_time() -> float:
	var day := Calendar.day_of(seen_at)
	if Calendar.hour_of(seen_at) >= LATEST:
		day += 1
	return maxf(seen_at, Calendar.at(day, EVENING))


# --- Ablauf ---------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if Game.game_over or Game.director == null or Game.social == null:
		return
	if photo_at >= 0.0 and not photo_pinned:
		_photo_check -= delta
		if _photo_check <= 0.0:
			_photo_check = 1.0
			_photo_step()
	match stage:
		Stage.NONE:
			_check -= delta
			if _check <= 0.0:
				_check = 1.0
				_check_pending()
		Stage.SEEN:
			_check -= delta
			if _check <= 0.0:
				_check = 1.0
				if (_debug_now or Game.director.elapsed >= _gather_time()) and _quiet():
					_begin_gathering()
		Stage.GATHERING:
			_gathering_step(delta)
		Stage.SCENE:
			_scene_step(delta)
		Stage.NAMED:
			_tell -= delta
			if _tell <= 0.0:
				_tell = TELL_SCAN
				if not Game.social.sleep_active:
					_spread()


## Kein Monster, keine andere Bedrohung, kein Schlaf, keine Feier, keine Siegerehrung.
func _quiet() -> bool:
	return not Game.monster.is_active() and not Game.director.other_threat_active(Game.monster) \
		and not Game.social.sleep_active and not Game.social.party_active and not (Game.contest and Game.contest.is_gathering())


func _namer_guest() -> Guest:
	for id in [HUGO, LIESEL]:
		for node in Game.social.living_guests():
			var g: Guest = node
			if not g.is_child() and String(g.profile.get("household", "")) == id:
				return g
	return null


func _begin_gathering() -> void:
	var lead := _namer_guest()
	if lead == null or _builder.lobby_table == Vector3.INF:
		_name_without_scene(lead)
		return
	stage = Stage.GATHERING
	namer = String(lead.profile["household"])
	_gather_since = Game.director.elapsed
	_in_lobby = 0.0
	_spots.clear()
	_gathered.clear()
	_cast = {"lead": lead}
	var w := Game.social.guest_by_id(witness)
	if w and not w.dead:
		_cast["witness"] = w
	lead.say(CALL_HUGO if namer == HUGO else CALL_LIESEL)
	_gather()
	if Game.tracing:
		print("[Leviathan] %s holt die anderen an den Couchtisch (%d kommen)" % [lead.display_name, _gathered.size()])


## Wer zum Tisch kommt: der Benenner, der Zeuge, seine Freunde, ein Skeptiker – höchstens MAX_GATHER.
func _gather() -> void:
	var lead: Guest = _cast["lead"]
	var table := _builder.lobby_table
	var want: Array[Guest] = [lead]
	if _cast.has("witness") and _cast["witness"] != lead:
		want.append(_cast["witness"])
	for g in Game.social.pals.pals_of(lead):
		if not g.is_child() and not g in want:
			want.append(g)
	if not _cast.has("skeptic"):
		for node in Game.social.living_guests():
			var g: Guest = node
			if Talk.temper(g) == "Skeptiker" and not g in want and g.global_position.distance_to(table) < 25.0:
				_cast["skeptic"] = g
				break
	if _cast.has("skeptic") and not _cast["skeptic"] in want:
		want.append(_cast["skeptic"])
	want.resize(mini(want.size(), MAX_GATHER))
	var look := table + Vector3.UP * 0.1
	for i in want.size():
		var g: Guest = want[i]
		if g in _gathered or not _can_gather(g):
			continue
		if not _spots.has(g.id):
			_spots[g.id] = _spot(i)
		g.join_party(_spots[g.id], look)
		if g.state == Guest.State.PARTY:
			_gathered.append(g)


## Platz i um den Tisch: 0 = der Benenner, die anderen im Kreis, auf dem NavMesh.
func _spot(i: int) -> Vector3:
	var table := _builder.lobby_table
	var angle := PI / 2.0 + i * TAU / MAX_GATHER
	var p := Vector3(table.x, 0, table.z) + Vector3(cos(angle), 0, sin(angle)) * (HUGO_GAP if i == 0 else RING)
	var map := Game.player.get_world_3d().navigation_map
	return NavigationServer3D.map_get_closest_point(map, p)


func _can_gather(g: Guest) -> bool:
	return not g.dead and g.hiding == null and g.fear < 60.0 and g.wound_bed <= 0.0 and g.state in [Guest.State.IDLE,
		Guest.State.WALK, Guest.State.CARRY_HOME, Guest.State.PLACE_DECO, Guest.State.HARVEST, Guest.State.PARTY]


func _gathering_step(delta: float) -> void:
	var lead: Guest = _cast["lead"]
	if not is_instance_valid(lead) or lead.dead:
		_release()
		stage = Stage.SEEN   # beim nächsten ruhigen Moment übernimmt der andere
		return
	if Game.monster.is_active() or Game.director.other_threat_active(Game.monster):
		return   # alle verstecken sich – danach geht es weiter
	_check -= delta
	if _check <= 0.0:
		_check = 4.0
		_gathered = _gathered.filter(func(g: Guest) -> bool: return is_instance_valid(g) and not g.dead and g.state == Guest.State.PARTY)
		_gather()
	var at_table := lead.global_position.distance_to(_spots.get(lead.id, lead.global_position)) < 1.2
	if at_table and _sheet == null:
		_sheet = _place_on_table()
	_in_lobby = _in_lobby + delta if _player_here() else 0.0
	var waited := Game.director.elapsed - _gather_since
	if (at_table and (_in_lobby >= 3.0 or waited >= WAIT_PLAYER)) or waited >= GATHER_MAX:
		_begin_scene()


func _player_here() -> bool:
	var p := Game.player
	return p != null and not p.dead and not p.sleeping and p.hiding == null and _builder.in_lobby(p.global_position)


func _begin_scene() -> void:
	stage = Stage.SCENE
	if _sheet == null:
		_sheet = _place_on_table()
	_lines = (SCENE_HUGO if namer == HUGO else SCENE_LIESEL).duplicate()
	_line_t = 1.0
	if _player_here():
		learn()


func _scene_step(delta: float) -> void:
	_line_t -= delta
	if _line_t > 0.0:
		return
	if _lines.is_empty():
		_finish()
		return
	_line_t = LINE_GAP
	var entry: Array = _lines.pop_front()
	var who := String(entry[0])
	var text := String(entry[1])
	var speaker: Guest = _cast["lead"] if who in ["hugo", "liesel"] else _cast.get(who)
	if who == "witness" and speaker == _cast["lead"]:
		text = HUGO_WITNESS
	if speaker == null or not is_instance_valid(speaker) or speaker.dead or (who == "skeptic" and photo_pinned):
		_line_t = 0.5   # fehlt – oder Paulas Foto hängt schon und der Skeptiker schweigt (ZIM-101)
		return
	speaker.say(text)
	if _player_here():
		learn()
	if text.contains("Leviathan"):
		Game.social.on_monster_talk(speaker)   # das Monster hört mit (4.7)


func _finish() -> void:
	stage = Stage.NAMED
	named_at = Game.director.elapsed
	for g in _gathered:
		if is_instance_valid(g) and not g.dead:
			knowers[g.id] = true
	var lead: Guest = _cast["lead"]
	knowers[lead.id] = true
	if namer == HUGO and _sheet:
		_sheet.hang(print_at)   # an die Wand neben der Fotowand
	elif _sheet:
		_sheet.queue_free()
		_sheet = null
	get_tree().create_timer(LINGER, false).timeout.connect(_release)
	if Game.tracing:
		print("[Leviathan] benannt von %s, %d kennen den Namen" % [lead.display_name, knowers.size()])


## Hugo und Liesel sind beide tot (oder kein Couchtisch): der Zeuge nennt es selbst so, ohne Szene.
func _name_without_scene(lead: Guest) -> void:
	stage = Stage.NAMED
	namer = String(lead.profile["household"]) if lead else LIESEL
	named_at = Game.director.elapsed
	if lead:
		knowers[lead.id] = true
	var w := Game.social.guest_by_id(witness)
	if w and not w.dead:
		knowers[w.id] = true


func _release() -> void:
	for g in _gathered:
		if is_instance_valid(g) and not g.dead:
			g.leave_party()
	_gathered.clear()


func _place_on_table() -> PrintSheet:
	var sheet := PrintSheet.new()
	sheet.owner_system = self
	add_child(sheet)
	sheet.lay(_builder.lobby_table)
	return sheet


# --- Verbreitung ----------------------------------------------------------------------------

## Zwei Freunde nah beieinander: Wer den Namen kennt, erzählt ihn weiter.
func _spread() -> void:
	if Game.director.elapsed - named_at >= ALL_KNOW_AFTER:
		return
	var social := Game.social
	for node in social.living_guests():
		var a: Guest = node
		if not knowers.has(a.id) or not _free(a):
			continue
		for other in social.living_guests():
			var b: Guest = other
			if b == a or knowers.has(b.id) or not _free(b) or b.global_position.distance_to(a.global_position) > TELL_RANGE:
				continue
			if not social.pals.are_pals(a, b):
				continue
			if randf() > maxf(TELL_CHANCE, float(a.profile["gossip"])):
				continue   # behält es diesmal für sich
			knowers[b.id] = true
			a.say((TELL_LINES if namer == HUGO else TELL_LINES_LIESEL).pick_random())
			_heard(a)
			social.on_monster_talk(a)
			get_tree().create_timer(2.5, false).timeout.connect(func() -> void:
				if is_instance_valid(b) and not b.dead:
					b.say(TELL_REPLY.pick_random()))
			if Game.tracing:
				print("[Leviathan] %s erzählt %s den Namen" % [a.display_name, b.display_name])
			return


func _free(g: Guest) -> bool:
	return not g.dead and g.hiding == null and g.fear < 60.0 and g.state in [Guest.State.IDLE, Guest.State.WALK, Guest.State.PARTY]


# --- Sätze ----------------------------------------------------------------------------------

## Guest.line: Wer den Namen kennt, sagt „der Leviathan“ statt „es“ – manchmal einen eigenen Satz.
func speak(g: Guest, key: String, text: String) -> String:
	if photo_pinned and SILENCED.has(text):
		text = SILENCED[text]   # Paulas Foto hängt (ZIM-101)
	if g.is_child() or not knows(g):
		return text
	if key == "monster" and randf() < OWN_LINE_CHANCE:
		text = OWN_LINES.pick_random()
	text = String(RENAMED.get(text, text))
	if text.contains("Leviathan"):
		_heard(g)
	return text


## Der Spieler steht nah genug: Jetzt kennt auch er den Namen.
func _heard(g: Guest) -> void:
	if not player_knows and Game.player and not Game.player.sleeping \
			and Game.player.global_position.distance_to(g.global_position) <= HEAR_RANGE:
		learn()


## Der Spieler kennt den Namen: Notizbuch, Tagebuch, seine eigenen Worte.
func learn() -> void:
	if player_knows:
		return
	player_knows = true
	if Game.notebook:
		Game.notebook.add_note("leviathan", NOTE_HUGO if namer == HUGO else NOTE_LIESEL, "Hugo" if namer == HUGO else "Liesel")
	if Game.diary:
		Game.diary.note("leviathan", DIARY_ENTRY)


## „das Monster“ in den Worten des Spielers bzw. eines Gastes, der den Namen kennt (Talk).
func name_for(thing: String, speaker_knows: bool) -> String:
	if not speaker_knows:
		return thing
	return thing.replace("das Monster", "den Leviathan")


func look_at_print() -> void:
	learn()
	if Game.menus:
		Game.menus.open_photo(PRINT_TITLE, PrintSheet.texture(), PRINT_TEXT)


# --- Das Foto (ZIM-101) ---------------------------------------------------------------------

func _paula() -> Guest:
	for node in Game.social.living_guests():
		var g: Guest = node
		if not g.is_child() and String(g.profile.get("household", "")) == PAULA:
			return g
	return null


## Das Monster hat einen Gast gepackt oder erschreckt (MonsterDirector.kill_guest, aufgeschoben bis nach dem Ausgang,
## at: wo der Gast war). Bekommt Paula es mit, fotografiert sie es – nur beim ersten Mal.
func on_attack(victim: Guest, at: Vector3) -> void:
	if photo_at >= 0.0 or Game.director == null or Game.director.skipping or Game.social == null:
		return
	var paula := _paula()
	if paula != null and notices_attack(paula, victim, at, Game.monster.global_position):
		_take_photo(paula)


## Bekommt Paula den Angriff mit? Selbst gepackt und am Leben, gesehen (frei, PHOTO_SIGHT) oder den Schrei gehört
## (wie Social.on_alarm: halbe Reichweite, gedämpft durch Wände und Türen). Versteckt bekommt sie nichts zu fassen.
func notices_attack(paula: Guest, victim: Guest, at: Vector3, monster_at: Vector3) -> bool:
	if paula.dead:
		return false
	if paula == victim:
		return true
	if paula.hiding:
		return false
	var world := paula.get_world_3d()
	var eye := paula.global_position + Vector3.UP * paula.eye_height()
	var head := monster_at + Vector3.UP * 1.7
	if eye.distance_to(head) <= PHOTO_SIGHT and Senses.clear_line(world, eye, head, paula):
		return true
	var reach := float(Senses.NOISE["scream"]["range"]) * Senses.GUEST_HEARING
	var d := eye.distance_to(at)
	return d <= reach and d <= Senses.audible_range(world, at, eye, reach, d)


func _take_photo(paula: Guest) -> void:
	photo_at = Game.director.elapsed
	_photo_check = 1.0
	paula.say(PAULA_SNAP)
	on_sighting(paula)   # sie hat es gesehen – lebt sie danach noch, ist es eine bestätigte Sichtung (4.32)
	if Game.tracing:
		print("[Leviathan] %s fotografiert den Angriff (%s)" % [paula.display_name, Calendar.date_text(photo_at)])


## Im nächsten ruhigen Moment nach PIN_AFTER heftet Paula das Foto an die Fotowand. Ist sie vorher gestorben, ist es fort.
func _photo_step() -> void:
	if _paula() == null:
		photo_at = -1.0   # Paula ist tot – kein Foto, und es macht keiner mehr eins
		if Game.tracing:
			print("[Leviathan] Paula ist tot – ihr Foto ist fort")
		return
	if Game.director.elapsed - photo_at >= PIN_AFTER and _quiet():
		photo_pinned = true
		_show_photo()
		if Game.tracing:
			print("[Leviathan] Paulas Foto hängt an der Fotowand – die Skeptiker sind still")


func _show_photo() -> void:
	if Game.photo_wall:
		Game.photo_wall.pin_snapshot(photo_texture(), PHOTO_PROMPT, look_at_photo)


static var _photo_tex: ImageTexture

static func photo_texture() -> Texture2D:
	if _photo_tex == null:
		var img := PhotoWall.draw_leviathan_photo()
		img.generate_mipmaps()
		_photo_tex = ImageTexture.create_from_image(img)
	return _photo_tex


func look_at_photo() -> void:
	var named := player_knows or stage == Stage.NAMED
	var text := PHOTO_TEXT % [PHOTO_CAPTION_NAMED if stage == Stage.NAMED else PHOTO_CAPTION, Calendar.date_text(photo_at)]
	if Game.menus:
		Game.menus.open_photo(PHOTO_TITLE, photo_texture(), text)
	if Game.notebook:
		Game.notebook.add_note("leviathan_photo", NOTE_PHOTO_NAMED if named else NOTE_PHOTO, "Fotowand")
	if Game.diary:
		Game.diary.note("leviathan_photo", DIARY_PHOTO)


# --- Speichern & Debug ----------------------------------------------------------------------

func save_state() -> Dictionary:
	var s := stage
	if s in [Stage.GATHERING, Stage.SCENE]:
		s = Stage.SEEN   # die Versammlung beginnt nach dem Laden neu
	return {"stage": int(s), "witness": witness, "seen_at": seen_at, "namer": namer, "named_at": named_at,
		"knowers": knowers.keys(), "player_knows": player_knows, "photo_at": photo_at, "photo_pinned": photo_pinned}


func load_state(d: Dictionary) -> void:
	_release()
	if _sheet:
		_sheet.queue_free()
		_sheet = null
	_pending.clear()
	stage = int(d.get("stage", Stage.NONE)) as Stage
	witness = String(d.get("witness", ""))
	seen_at = float(d.get("seen_at", -1.0))
	namer = String(d.get("namer", ""))
	named_at = float(d.get("named_at", -1.0))
	knowers.clear()
	for id in d.get("knowers", []):
		knowers[String(id)] = true
	player_knows = bool(d.get("player_knows", false))
	photo_at = float(d.get("photo_at", -1.0))
	photo_pinned = bool(d.get("photo_pinned", false))
	if photo_pinned:
		_show_photo()
	elif Game.photo_wall:
		for n in Game.photo_wall.get_children():
			if n is PhotoWall.Snapshot:
				n.queue_free()
	if stage == Stage.NAMED and namer == HUGO:
		_sheet = _place_on_table()
		_sheet.hang(print_at)


## --leviathan[=benannt|liesel] (Spielkonzept 4.32): Ein Gast hat es eben gesehen und überlebt, es ist Abend, du stehst
## in der Lobby am Couchtisch · benannt: alles schon geschehen, der Druck hängt · liesel: Hugo ist tot.
func debug(value: String) -> void:
	if value == "liesel":
		var hugo := _namer_guest()
		if hugo and String(hugo.profile["household"]) == HUGO:
			hugo.die("unseen")
	var g := _namer_guest()
	if g == null:
		return
	_debug_now = true
	_pending.clear()
	_confirm(g if value == "benannt" else _debug_witness(g))
	if value == "benannt":
		namer = String(g.profile["household"])
		named_at = Game.director.elapsed
		stage = Stage.NAMED
		knowers[g.id] = true
		if namer == HUGO:
			_sheet = _place_on_table()
			_sheet.hang(print_at)
		var out := print_at.basis.z
		TeleportUI.place_player(print_at.origin + out * 1.4 + Vector3.DOWN * 1.7, -out + Vector3.UP * 0.2)
		return
	var t := _builder.lobby_table
	TeleportUI.place_player(Vector3(t.x + 2.5, t.y - 0.4, t.z + 2.5), Vector3(-1, -0.2, -1))


## Ein erwachsener Zeuge, nicht der Benenner – sonst er selbst.
func _debug_witness(lead: Guest) -> Guest:
	for node in Game.social.living_guests():
		var g: Guest = node
		if g != lead and not g.is_child() and not Grinch.is_grinch(g):
			return g
	return lead


## Dorés Druck: erst flach auf dem Couchtisch, dann im Rahmen neben der Fotowand. [E] sieht ihn an.
class PrintSheet extends StaticBody3D:
	var owner_system: LeviathanName
	var _hung := false
	static var _tex: Texture2D

	static func texture() -> Texture2D:
		if _tex == null:
			_tex = load(LeviathanName.PRINT_PATH)
		return _tex

	func _ready() -> void:
		collision_layer = 4
		collision_mask = 0
		set_meta("interactable", self)

	func _paper(size: Vector2) -> ShaderMaterial:
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/psx_surface.gdshader")
		m.set_shader_parameter("albedo", Color(0.93, 0.89, 0.8))   # vergilbtes Papier
		m.set_shader_parameter("albedo_tex", texture())
		return m

	## Flach auf den Tisch, etwas schräg, zum Platz des Benenners hin lesbar.
	func lay(top: Vector3) -> void:
		var quad := QuadMesh.new()
		quad.size = LeviathanName.PRINT_TABLE_SIZE
		Geo.mesh(self, quad, _paper(quad.size), Vector3.ZERO).rotation.x = -PI / 2.0
		Geo.add_box_shape(self, Vector3(quad.size.x, 0.02, quad.size.y), Vector3.ZERO)
		global_position = top + Vector3.UP * 0.004
		rotation.y = PI + 0.12

	## In einen schlichten Rahmen an die Wand (at: global, +Z in den Raum).
	func hang(at: Transform3D) -> void:
		_hung = true
		for c in get_children():
			c.queue_free()
		global_transform = at
		var size := LeviathanName.PRINT_SIZE
		var frame := PhotoWall.FRAME
		var outer := size + Vector2.ONE * frame * 2.0
		var wood := Mat.psx(Color(0.16, 0.09, 0.05))
		for side in [-1.0, 1.0]:
			Geo.mesh(self, Geo.box(Vector3(outer.x, frame, 0.025)), wood, Vector3(0, side * (size.y + frame) / 2.0, 0.012))
			Geo.mesh(self, Geo.box(Vector3(frame, size.y, 0.025)), wood, Vector3(side * (size.x + frame) / 2.0, 0, 0.012))
		var quad := QuadMesh.new()
		quad.size = size
		Geo.mesh(self, quad, _paper(size), Vector3(0, 0, 0.004))
		Geo.add_box_shape(self, Vector3(outer.x, outer.y, 0.04), Vector3(0, 0, 0.02))

	func get_prompt(_player: Player) -> String:
		return "Druck ansehen [E] – Der Leviathan" if _hung else "Druck ansehen [E]"

	func interact(_player: Player) -> void:
		owner_system.look_at_print()


## --leviathanfoto[=haengt|pruefen] (ZIM-101): Paula hat eben einen Angriff fotografiert, im nächsten ruhigen Moment
## nach PIN_AFTER hängt es – du vor der Fotowand · haengt: es hängt schon und ist gleich aufgeschlagen · pruefen:
## _check_photo.
func debug_photo(value: String) -> void:
	if Game.photo_wall:
		Game.photo_wall.debug_show("")
	if value == "pruefen":
		_check_photo()
		return
	var paula := _paula()
	if paula == null:
		push_warning("--leviathanfoto: Paula Jansen (H30) ist nicht im Hotel")
		return
	_take_photo(paula)
	if value == "haengt":
		photo_pinned = true
		_show_photo()
		get_tree().create_timer(0.5).timeout.connect(look_at_photo)


## Prüfung des Fotos (ZIM-101): wann Paula einen Angriff mitbekommt, das Foto an der Fotowand ohne einen Rahmen zu
## verdecken, die Skeptiker vorher und nachher, Speichern, und dass es ohne Paula keins gibt. Meldet
## „[Leviathanfoto] … ok“ bzw. „FEHLER“, zuletzt „[Leviathanfoto] Prüfung fertig“.
func _check_photo() -> void:
	var check := func(text: String, ok: bool) -> void:
		print("[Leviathanfoto] %s: %s" % [text, "ok" if ok else "FEHLER"])
	var paula := _paula()
	check.call("Paula Jansen da, Skeptikerin", paula != null and Talk.temper(paula) == "Skeptiker")
	if paula == null:
		print("[Leviathanfoto] Prüfung fertig")
		return
	var other: Guest = null
	for node in Game.social.living_guests():
		if node != paula and not (node as Guest).is_child():
			other = node
			break
	var here := paula.global_position
	var far := here + Vector3(300.0, 0.0, 300.0)
	check.call("Angriff weit weg: merkt sie nicht", not notices_attack(paula, other, far, far))
	var near := here + Vector3(0.3, 0.0, 0.0)
	check.call("Angriff neben ihr: merkt sie", notices_attack(paula, other, near, near))
	var doubt: String = SILENCED.keys()[0]
	check.call("vorher zweifeln Skeptiker", speak(paula, "smalltalk", doubt) == doubt
		and not Game.social.talk._believes(paula, "monster", "", false))
	on_attack(paula, here)   # selbst angegriffen und am Leben
	var taken := photo_at
	check.call("Foto gemacht, zählt als Sichtung", taken >= 0.0 and (_pending.has(paula.id) or stage != Stage.NONE))
	on_attack(paula, here)
	check.call("nur beim ersten Angriff", photo_at == taken)
	photo_at = Game.director.elapsed - PIN_AFTER - 1.0
	_photo_step()
	var snaps := Game.photo_wall.get_children().filter(func(n: Node) -> bool:
		return n is PhotoWall.Snapshot and not n.is_queued_for_deletion())
	check.call("hängt im ruhigen Moment an der Fotowand", photo_pinned and snaps.size() == 1)
	if snaps.size() == 1:
		var snap: Node3D = snaps[0]
		var free := true
		var outer := PhotoWall.PHOTO + Vector2.ONE * PhotoWall.FRAME * 2.0
		for n in Game.photo_wall.get_children():
			if n is PhotoWall.PhotoFrame or n is PhotoWall.BarePatch:
				var p: Vector3 = (n as Node3D).global_transform.affine_inverse() * snap.global_position
				if absf(p.x) < (outer.x + PhotoWall.Snapshot.SIZE.x) / 2.0 and absf(p.y) < (outer.y + PhotoWall.Snapshot.SIZE.y) / 2.0:
					free = false
					print("[Leviathanfoto] überdeckt %s" % n.name)
		check.call("verdeckt keinen Rahmen und keinen Fleck", free)
		var on_wall: float = (snap.global_position - Game.photo_wall.pin_spot().origin).length()
		check.call("an pin_spot (%.2f m)" % on_wall, on_wall < 0.01)
	check.call("danach sind Skeptiker still", speak(paula, "smalltalk", doubt) == SILENCED[doubt]
		and Game.social.talk._believes(paula, "monster", "", false))
	var saved := save_state()
	load_state(saved)
	snaps = Game.photo_wall.get_children().filter(func(n: Node) -> bool:
		return n is PhotoWall.Snapshot and not n.is_queued_for_deletion())
	check.call("Speichern: hängt nach dem Laden", bool(saved.get("photo_pinned", false)) and photo_pinned and snaps.size() == 1)
	if Game.notebook and not Game.notebook.owned:
		Game.notebook.give(true)   # ohne Notizbuch wird nichts notiert
	look_at_photo()
	check.call("Notiz beim Ansehen", Game.notebook == null or Game.notebook.has_note("leviathan_photo"))
	var img := PhotoWall.draw_leviathan_photo()
	var dark := 0
	for y in range(30, 90):
		if img.get_pixel(104, y).get_luminance() < 0.12:
			dark += 1
	check.call("Bild: dunkle Gestalt in der Mitte (%d/60)" % dark, dark > 30)
	# Ohne Paula kein Foto
	load_state({})
	paula.die("unseen")
	on_attack(other, other.global_position)
	check.call("Paula tot: kein Foto", photo_at < 0.0)
	photo_at = Game.director.elapsed
	_photo_step()
	check.call("Paula tot vor dem Anheften: Foto fort", photo_at < 0.0 and not photo_pinned)
	print("[Leviathanfoto] Prüfung fertig")
