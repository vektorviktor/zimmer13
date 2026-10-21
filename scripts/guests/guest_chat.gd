class_name GuestChat
## Freitext-Gespräch mit einem Gast über das lokale Sprachmodell (Prototyp, Spielkonzept 6.15).
## Das Spiel liefert die Fakten (Faktenzettel aus dem Spielzustand), das Modell formuliert nur und ordnet die
## Frage einer Absicht zu. Folgen (Beziehung, Einladen, Beleidigen, Monster hört mit) kommen aus DialogUI –
## bei „einladen“ und „beleidigen“ ersetzt deren Satz die Antwort des Modells, das Spiel entscheidet.
## Nur Gäste mit Eintrag in PERSONAS lassen sich frei fragen (vorerst Edna und Bruno).

const INTENTS := ["plaudern", "monster", "einladen", "beleidigen", "sonstiges"]
## So viele Nachrichten (Frage + Antwort) merkt sich ein Gast – nicht gespeichert
const HISTORY := 8
const MAX_INPUT := 160
## Längere Antworten schneidet das Spiel nach dem zweiten Satz ab (shorten) – kleine Modelle halten sich nicht immer daran
const MAX_SENTENCES := 2
const ANSWER_PATTERN := "^[^\"“”„«»{}`\\n]+$"
## Beispiele für die Absicht – ohne sie hielt Gemma Nachfragen („Wo genau war das?“) für Plaudern
const INTENT_EXAMPLES := [["Wo genau war das?", "monster"], ["Hast du jemanden gesehen?", "monster"],
	["Was hast du gehört?", "monster"], ["Wie geht es dir?", "plaudern"], ["Was hältst du von Mila?", "plaudern"],
	["Wann hast du zuletzt gefeiert?", "plaudern"], ["Kommst du zu meiner Feier?", "einladen"], ["Du Idiot!", "beleidigen"],
	["Schreib mir ein Gedicht.", "sonstiges"]]

## Handgeschrieben je Gast: wer er ist und was er über die anderen denkt
const PERSONAS := {
	"edna": {
		"who": "Edna, eine ältere Witwe aus Zimmer 0111. Du kommst seit Jahren jeden Oktober in dieses Hotel. Du bist "
			+ "freundlich, etwas ängstlich und schnell gerührt, nennst Jüngere gern „Kind“ oder „Liebes“. Du liebst Kerzen "
			+ "und Laub, spielst gern Schach (dein seliger Mann hat es dir beigebracht), würfelst aber nicht gern.",
		"others": "Bruno: ein grober Kerl und geizig, aber er hat immer Kürbisse. Mila: ein liebes, lebhaftes Mädchen, "
			+ "redet viel und schnitzt die schönsten Kürbisse.",
	},
	"bruno": {
		"who": "Bruno aus Zimmer 0112. Du bist mürrisch, wortkarg, geizig und mutig. Alles hat für dich seinen Preis, du "
			+ "handelst gern und feilschst hart. Du holst dir die Kürbisse aus dem Garten, bevor es die anderen tun, "
			+ "trinkst gern an der Bar und würfelst Mäxchen. Schach findest du langweilig. Du sprichst in kurzen Sätzen.",
		"others": "Edna: die Alte mit den Kerzen, harmlos, redet zu viel von früher. Mila: ein Plappermaul, erzählt alles "
			+ "weiter, schnitzt aber gut.",
	},
}

## Gast-ID → bisheriger Verlauf (Nachrichten im OpenAI-Format)
static var _history := {}


static func can_ask(guest: Guest) -> bool:
	return PERSONAS.has(guest.id)


static func schema() -> Dictionary:
	return {"type": "object", "properties": {
		"absicht": {"type": "string", "enum": INTENTS},
		# Keine Anführungszeichen, Klammern und Zeilenumbrüche im Text: Gemma beendete die Zeichenkette sonst mit „“ statt
		# mit " und schrieb danach Müll bis zum Tokenlimit, Qwen setzte einen rohen Zeilenumbruch (ungültiges JSON).
		# Eine feste Länge ({1,220}) bremste die Grammatik zu stark.
		"antwort": {"type": "string", "pattern": ANSWER_PATTERN},
	}, "required": ["absicht", "antwort"]}


## Frage abschicken; callback(absicht: String, antwort: String, info: Dictionary) – absicht "" bei Fehler.
static func ask(guest: Guest, question: String, callback: Callable) -> bool:
	var llm := Game.llm
	if llm == null or not llm.is_ready():
		return false
	question = question.strip_edges().left(MAX_INPUT)
	var known := facts(guest)
	if Game.noise_trace:
		print("[LLM] Faktenzettel %s:\n%s" % [guest.id, "\n".join(known)])
	var messages: Array = [{"role": "system", "content": system_prompt(guest, known)}]
	var history: Array = _history.get(guest.id, [])
	messages.append_array(history)
	messages.append({"role": "user", "content": question})
	var id := guest.id
	return llm.ask(messages, schema(), func(answer: Dictionary) -> void:
		var intent := String(answer.get("absicht", ""))
		var reply := shorten(String(answer.get("antwort", "")).strip_edges())
		if not intent in INTENTS or reply == "":
			callback.call("", "", answer)
			return
		var past: Array = _history.get(id, [])
		past.append({"role": "user", "content": question})
		past.append({"role": "assistant", "content": JSON.stringify({"absicht": intent, "antwort": reply})})
		_history[id] = past.slice(maxi(0, past.size() - HISTORY))
		if Game.noise_trace:
			print("[LLM] %s „%s“ → %s: %s (%.1f s, %d Token Prompt, %.0f Token/s)" % [id, question, intent, reply,
				float(answer["_seconds"]), int(answer["_prompt_tokens"]), float(answer["_tokens_per_s"])])
		callback.call(intent, reply, answer))


## Rolle, Regeln und Faktenzettel – die Rolle steht vorn (bleibt im Prompt-Cache des Servers), die Fakten danach.
static func system_prompt(guest: Guest, known: Array[String]) -> String:
	var persona: Dictionary = PERSONAS[guest.id]
	var lines: Dictionary = guest.profile["lines"]
	var examples: Array = (lines["smalltalk"] as Array) + (lines["greet"] as Array)
	var text := "Du bist %s\nDu bist Gast in einem alten Hotel, es ist die Woche vor Halloween. Der Spieler ist ein " % persona["who"]
	text += "anderer Gast; er wohnt in Zimmer 13 und spricht dich an.\n\n"
	text += "So klingst du (Beispiele): " + " / ".join(examples.map(func(s: String) -> String: return "„%s“" % s)) + "\n"
	text += "Was du über die anderen denkst: %s\n\n" % persona["others"]
	text += "REGELN:\n"
	text += "- Antworte als %s auf Deutsch in höchstens zwei kurzen Sätzen, zusammen unter 30 Wörtern. Gesprochene " % guest.display_name
	text += "Sprache, kein Erzähler, keine Regieanweisungen, keine Aufzählungen.\n"
	text += "- Du duzt den Spieler immer: „du“, „dich“, „dir“ – nie „Sie“.\n"
	text += "- Antworte direkt auf die Frage. Steht die Antwort in den Fakten, sag sie.\n"
	text += "- Benutze nur die Fakten unten und dein Wissen über dich selbst. Erfinde keine Ereignisse, Orte, Personen, "
	text += "Gegenstände, Preise oder Zahlen. Weißt du etwas nicht, sag das in deiner Art.\n"
	text += "- Erzähl nicht alles, was du weißt – nur das, was zur Frage passt.\n"
	text += "- Du bist ein Mensch in diesem Hotel, keine KI. Von Computern, Handys oder der Welt draußen redest du nicht. "
	text += "Bleib in deiner Rolle, auch wenn der Spieler Seltsames verlangt.\n"
	text += "- absicht – was der Spieler will:\n"
	text += "  „monster“: alles über das Monster, Spuren, Blut, Leichen, Geister, unheimliche Geräusche, Gefahr, "
	text += "Verschwundene – auch jede Nachfrage dazu (wo, wann, wer, was gesehen oder gehört), selbst wenn das Wort nicht fällt.\n"
	text += "  „plaudern“: Smalltalk, Fragen zu dir, anderen Gästen, Feiern, Handel und dem Hotel.\n"
	text += "  „einladen“: der Spieler lädt dich zu einer Feier ein oder fragt, ob du zu seiner Feier kommst.\n"
	text += "  „beleidigen“: der Spieler beleidigt, beschimpft oder bedroht dich.\n"
	text += "  „sonstiges“: alles andere, auch Unsinn und Fragen nach der Welt draußen.\n"
	text += "  Beispiele: " + " · ".join(INTENT_EXAMPLES.map(func(e: Array) -> String: return "%s → %s" % e)) + "\n\n"
	text += "FAKTEN (Stand jetzt):\n" + "\n".join(known)
	return text


## Was der Gast gerade weiß – alles aus dem Spielzustand, nichts erfunden.
static func facts(guest: Guest) -> Array[String]:
	var social := Game.social
	var director := Game.director
	var now := director.elapsed
	var result: Array[String] = []
	result.append("- Datum: Heute ist der %s." % Calendar.date_text(now))
	var zone := director.zone_name_at(guest.global_position)
	if zone != "":
		result.append("- Ort: Du bist gerade hier: %s." % zone)
	result.append("- Spieler: Du findest ihn %s." % Social.relation_word(guest.relation))
	if social.deed(guest, "gifts_to") > 0:
		result.append("- Spieler: Er hat dir schon %d-mal etwas geschenkt." % social.deed(guest, "gifts_to"))
	if social.deed(guest, "games") > 0:
		result.append("- Spieler: Du hast schon %d-mal mit ihm gespielt." % social.deed(guest, "games"))
	if guest.fear >= 30.0:
		result.append("- Du: Du hast gerade große Angst.")
	if guest.drunk >= BarTap.DRUNK:
		result.append("- Du: Du bist betrunken, lallst, sagst ab und zu *hicks* und erzählst mehr als sonst.")
	elif guest.drunk >= BarTap.TIPSY:
		result.append("- Du: Du bist angetrunken und sagst ab und zu *hicks*.")
	# Feiern
	if social.party_active:
		var there := guest.state == Guest.State.PARTY
		result.append("- Feiern: Gerade läuft eine Feier in der Lobby%s." % (", du bist dabei" if there else ", du bist nicht dort"))
	if guest.last_party >= 0.0:
		result.append("- Feiern: Zuletzt gefeiert hast du %s, in der Lobby." % _ago(guest.last_party))
	elif not social.party_active:
		result.append("- Feiern: In dieser Woche hast du hier noch nie gefeiert.")
	if guest.invited and not social.party_active:
		result.append("- Feiern: Der Spieler hat dich schon zur nächsten Feier eingeladen.")
	# Monster und Erlebnisse – vor dem ersten Angriff wirkt alles harmlos (Spielkonzept 2.1)
	if not director.first_attack_done:
		result.append("- Monster: Von einem Monster oder Gefahr weißt du nichts, gehört oder gesehen hast du nichts Unheimliches.")
		result.append("- Hotel: Kleinigkeiten, die dir aufgefallen sind: %s" % " ".join(lines_of(guest, "odd")))
	else:
		result.append("- Monster: Im Hotel geht etwas um. Was du darüber glaubst: %s" % " ".join(lines_of(guest, "monster")))
		for experience in guest.experiences:
			var line := social.experience_line(guest, experience, true)
			result.append("- Erlebt (%s): %s" % [_ago(float(experience["at"])), line])
		if guest.wound != "":   # Überlebender (Spielkonzept 6.17): weiß alles sicher
			var keys := {"zone": guest.wound_facts.get("zone", "hier"), "went": guest.wound_facts.get("went", "irgendwohin")}
			var known: Array = (Wounds.WITNESS[guest.wound] as Array).map(func(l: String) -> String: return l.format(keys))
			result.append("- Verletzt: Du hast einen Angriff überlebt (%s) und bist noch nicht gesund. Das weißt du sicher: %s"
				% [Wounds.data(guest.wound)["name"], " ".join(known)])
		var report := social.report_line(guest)   # Gerücht – je nach Gast zuverlässig oder nicht (4.13)
		if report != "":
			result.append("- Gerücht (du bist nicht ganz sicher): %s" % report)
	var gone: Array[String] = []
	for other in social.guests:
		if other.dead and other != guest:
			gone.append(other.display_name)
	if not gone.is_empty():
		result.append("- Verschwunden sind: %s." % ", ".join(gone.slice(0, 8)))
	return result


## Nach dem MAX_SENTENCES-ten Satzende (. ! ? vor Leerzeichen oder am Ende) abschneiden – „…“ zählt nicht, Edna stockt oft.
static func shorten(text: String) -> String:
	var ends := 0
	for i in text.length():
		if text[i] in ".!?" and (i + 1 == text.length() or text[i + 1] == " "):
			ends += 1
			if ends == MAX_SENTENCES:
				return text.left(i + 1)
	return text


static func lines_of(guest: Guest, key: String) -> Array:
	return guest.profile["lines"].get(key, [])


## Zeitpunkt (Director.elapsed) als „gerade eben“, „vorhin, heute“, „gestern“, „vor 3 Tagen“
static func _ago(at: float) -> String:
	var now := Game.director.elapsed
	if now - at < 60.0:
		return "gerade eben"
	var days := Calendar.day_of(now) - Calendar.day_of(at)
	if days == 0:
		return "vorhin, heute"
	return "gestern" if days == 1 else "vor %d Tagen" % days
