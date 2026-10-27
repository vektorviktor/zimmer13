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
## Der Druck an der Wand: Westwand der Lobby zwischen Aushangbrett und Wandlampe, südlich der Fotowand; Bildmaß
const PRINT_PATH := "res://assets/textures/dore_leviathan.jpg"
const PRINT_AT := Vector3(-7.38, 1.72, -18.3)
const PRINT_SIZE := Vector2(0.36, 0.455)
const PRINT_TABLE_SIZE := Vector2(0.24, 0.3)
const PRINT_TITLE := "Gustave Doré: Die Zerstörung des Leviathan"
const PRINT_TEXT := "Ein Holzstich aus einer alten Bibel, 1865. Ein Ungeheuer windet sich in der Brandung – Zacken am Rücken, ein langer Schädel, das Maul offen. Hugo hat es hier aufgehängt; unten am Rand steht in seiner Schrift: »Der Leviathan. Hiob 40.«"

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


func setup(builder: LevelBuilder) -> LeviathanName:
	_builder = builder
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
	if speaker == null or not is_instance_valid(speaker) or speaker.dead:
		_line_t = 0.5
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
		_sheet.hang()   # an die Fotowand
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


# --- Speichern & Debug ----------------------------------------------------------------------

func save_state() -> Dictionary:
	var s := stage
	if s in [Stage.GATHERING, Stage.SCENE]:
		s = Stage.SEEN   # die Versammlung beginnt nach dem Laden neu
	return {"stage": int(s), "witness": witness, "seen_at": seen_at, "namer": namer, "named_at": named_at,
		"knowers": knowers.keys(), "player_knows": player_knows}


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
	if stage == Stage.NAMED and namer == HUGO:
		_sheet = _place_on_table()
		_sheet.hang()


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
			_sheet.hang()
		TeleportUI.place_player(PRINT_AT + Vector3(1.4, -1.7, 0), Vector3(-1, 0.2, 0))
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

	## In einen schlichten Rahmen an die Wand neben der Fotowand.
	func hang() -> void:
		_hung = true
		for c in get_children():
			c.queue_free()
		rotation = Vector3(0, PI / 2.0, 0)   # +Z in die Lobby, wie PhotoWall
		global_position = LeviathanName.PRINT_AT
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
