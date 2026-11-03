class_name Tender
## Schwere Momente: empfindlicher Zustand (Spielkonzept 6.18 Punkt 3, verallgemeinert 6.17; entschieden 2026-11-03,
## ZIM-161). Fünf Zustände, jeder mit eigener Dauer:
##   · verletzt (6.17, Guest.wound) – bis er geheilt ist
##   · trauernd (6.12, Haltung „grieving“, GuestMourning) – 1–2 Spieltage, je enger der Tote ihm stand (grief_time)
##   · verwaist (6.13, Guest.is_orphan) – bis Halloween, also bis zum Schluss
##   · nach einem Angriff des Lakengeists (Haltung „after_ghost“: losgerissen oder als Kind erschreckt) und
##   · Puppe vor der eigenen Tür (Haltung „doll_door“, JuryDoll) – beide bis zum nächsten Morgen (until_morning)
## Gemeinsame Regeln wie bei Verletzten: Taten zählen doppelt (Social.change_relation), Geschenke dreifach und passende
## noch mehr (DialogUI._gift, fitting), Besuche zählen – wer als Freund in der Trauer nie kommt, kränkt (on_grief_ended,
## wie Wounds.NEGLECT nach der Heilung) –, eigene Sätze (GREET).
## Jeder Zustand ergibt einen Wunsch (GuestRequests.make_tender): Kerze für den Toten (Trauer, schon GuestMourning),
## Deko für die Tür (Puppe), etwas Warmes ans Bett (verletzt), eine Katze zum Trösten (verwaist, nach dem Lakengeist);
## dazu, ohne empfindlichen Zustand, die Deko zurück, die eine Katze verschleppt hat (Haltung „cat_took“, ein Spieltag).
## Kernfiguren haben eigene Wünsche. Nur Daten, Sätze und Regeln – den Zustand tragen Gast und Haltungen (gespeichert).

## Bis zum nächsten Morgen: um diese Uhrzeit vorbei, aber mindestens so lange (Spielsekunden)
const MORNING_HOUR := 6.0
const MORNING_MIN := 2.0 * Calendar.HOUR
## Trauer: Familie und Haushalt zwei Spieltage, Freunde einer plus je gemeinsamer Tat über GuestPals.PAL_DEEDS hinaus
## GRIEF_PER_DEED (höchstens zwei), Nachbarn einer
const GRIEF_DAYS := Vector2(1.0, 2.0)
const GRIEF_PER_DEED := 1.0 / 6.0
## Die verschleppte Deko vermisst er so lange
const CAT_TOOK_TIME := Calendar.DAY_SECONDS
## Wer als Freund in der Trauer nie kam, ist gekränkt (wie Wounds.NEGLECT)
const NEGLECT := -6.0
## Passende Geschenke für Waisen
const ORPHAN_GIFTS := [Item.Kind.SWEETS, Item.Kind.SODA_CAN]
## Wunsch „etwas Warmes ans Bett“: Die Kürbissuppe lässt sich nicht tragen (3.8) – das Warme aus der Küche, das geht
const WARM_FOOD := [Item.Kind.ROAST_PUMPKIN, Item.Kind.TEA]
## Wunsch „Katze“: so nah musst du sie auf dem Arm herantragen
const CAT_RANGE := 2.5
## Die Katze tröstet: so viel weniger Angst
const CAT_CALM := 25.0
## Reihenfolge, wenn mehreres zugleich gilt (Trauer geht vorher schon als „memorial“)
const ORDER := ["doll", "ghost", "wound", "orphan", "cat_took"]

## Begrüßung je Zustand (eigene Sätze; verletzt: Wounds.GREET)
const GREET := {
	"grief": ["Ich kann noch gar nicht glauben, dass {who} nicht mehr da ist.", "Entschuldige … ich bin heute nicht ich selbst.",
		"Es ist so still ohne {who}."],
	"grief_child": ["{who} kommt nicht wieder, oder?", "Ich will nicht, dass {who} weg ist."],
	"orphan": ["Ich bin jetzt ganz allein.", "Bleibst du ein bisschen?", "Die anderen gucken mich so komisch an."],
	"ghost": ["Ich krieg das Laken nicht aus dem Kopf …", "*zuckt zusammen* Ach, du bist's.",
		"Mach bitte kein Licht aus, solange du hier bist."],
	"ghost_child": ["Das Gespenst war da! Ganz echt!", "Ich hab dem Gespenst nichts getan …"],
	"doll": ["Diese Puppe … Ich weiß, was das heißt.", "Ich schlaf heute Nacht bestimmt nicht.",
		"Ausgerechnet vor meiner Tür. Warum ich?"],
}
## Nachher, beim nächsten Gespräch (Guest.wound_note)
const NOTE_LINES := {
	"grief_neglect": "Als es mir so schlecht ging, hast du dich nicht ein einziges Mal blicken lassen.",
	"grief_visited": "Danke, dass du da warst, als es mir so schlecht ging. Das vergess ich dir nicht.",
}

## Wünsche je Zustand. kind: door_deco (irgendeine Deko, er stellt sie vor die Tür), cat (eine Katze herantragen),
## soup (etwas Warmes: WARM_FOOD), deco_back (das verschleppte Stück zurück). Platzhalter wie GuestRequests._fill_texts,
## dazu {cat} und {thing} (deco_back).
const WISHES := {
	"doll": {"kind": "door_deco", "task": "Deko für {name}s Tür (die Puppe saß davor)",
		"ask": "Die Puppe saß vor meiner Tür … Bringst du mir etwas für die Tür? Irgendwas Helles. Hauptsache, sie sieht nicht mehr so verlassen aus.",
		"thanks": "Danke. Das kommt gleich vor die Tür – soll man sehen, dass hier jemand wohnt."},
	"ghost": {"kind": "cat", "task": "Eine Katze zu {name} bringen – zum Trösten",
		"ask": "Ich trau mich nicht mehr allein ins Dunkle … Bringst du mir eine von den Katzen? Nur für ein Weilchen.",
		"thanks": "*krault die Katze* … Schon besser. Danke, wirklich."},
	"ghost_child": {"ask": "Das Gespenst war an meinem Fenster! Bringst du mir eine Katze? Mit einer Katze hab ich keine Angst.",
		"thanks": "Die schnurrt! Jetzt kann das Gespenst kommen."},
	"orphan": {"kind": "cat", "task": "Eine Katze zu {name} bringen – zum Trösten",
		"ask": "Ich bin jetzt ganz allein … Bringst du mir eine Katze? Die kann bei mir schlafen.",
		"thanks": "Die ist so weich … Danke."},
	"wound": {"kind": "soup", "task": "Etwas Warmes aus der Küche zu {name} (gebratener Kürbis oder Tee)",
		"ask": "Ich fühl mich wie gerädert. Bringst du mir was Warmes aus der Küche? Einen gebratenen Kürbis oder einen Tee – irgendwas.",
		"thanks": "Warm … das tut so gut. Danke, dass du an mich denkst."},
	"cat_took": {"kind": "deco_back", "task": "{name} {thing} zurückbringen ({cat} hat es verschleppt)",
		"ask": "{cat} hat mir {thing} weggeschleppt. Wenn du es irgendwo findest – bringst du es mir zurück?",
		"thanks": "Da ist es ja wieder! Danke. Und dieser Katze sag ich was."},
}
## Was die Katze verschleppt (HotelCat.GIFT_KINDS) – als Satzteil
const THINGS := {Item.Kind.LEAVES: "mein Herbstlaub", Item.Kind.COBWEB: "meine Spinnweben", Item.Kind.CANDLE: "meine Kerze"}
## Kernfiguren (6.0): eigener Wunsch statt Deko, Katze oder Warmem (Puppe, Lakengeist, verletzt) – ein Gegenstand
const CORE := {
	"edna": {"kind": "item", "item": Item.Kind.TEA, "task": "Edna einen Kamillentee bringen",
		"ask": "Liebes … mir zittern noch die Hände. Machst du mir einen Tee? Kamille, wie früher.",
		"thanks": "Kamille … danke. Jetzt hören die Hände auf zu zittern."},
	"bruno": {"kind": "item", "item": Item.Kind.LIGHT_STRING, "task": "Bruno eine Lichterkette bringen",
		"ask": "Bring mir 'ne Lichterkette. Ich lass heute Nacht Licht an, und keiner lacht. Klar?",
		"thanks": "Na also. Jetzt sieht man wenigstens, was kommt."},
	"mila": {"kind": "item", "item": Item.Kind.SWEETS, "task": "Mila etwas Süßes bringen",
		"ask": "Ich krieg kein Auge zu. Hast du was Süßes? Zucker hilft gegen alles – fast.",
		"thanks": "Oh, danke! Siehst du – schon fast alles wieder gut."},
}
const CORE_STATES := ["doll", "ghost", "wound"]


## Ist er gerade empfindlich (irgendein schwerer Moment)?
static func is_tender(g: Guest) -> bool:
	return g.wound != "" or g.has_stance("grieving") or g.has_stance("after_ghost") or g.has_stance("doll_door") \
		or g.is_orphan()


## Gilt der Zustand (oder Anlass, „cat_took“) noch?
static func has_state(g: Guest, state: String) -> bool:
	match state:
		"wound": return g.wound != ""
		"grief": return g.has_stance("grieving")
		"orphan": return g.is_orphan()
		"ghost": return g.has_stance("after_ghost")
		"doll": return g.has_stance("doll_door")
		"cat_took": return g.has_stance("cat_took")
	return false


## Woran sich dieser Zustand von einem früheren unterscheidet (für erfüllte Wünsche, GuestRequests.granted):
## das Ende der Haltung; verletzt und verwaist "" (Guest.wound_by vergisst den erfüllten Wunsch).
static func instance(g: Guest, state: String) -> String:
	var key := {"ghost": "after_ghost", "doll": "doll_door", "cat_took": "cat_took"}.get(state, "") as String
	return str(int(float(g.stances[key]["until"]))) if key != "" and g.stances.has(key) else ""


## Spielsekunden bis zum nächsten Morgen (MORNING_HOUR), mindestens MORNING_MIN.
static func until_morning() -> float:
	var hour := Calendar.hour_of(Game.director.elapsed if Game.director else 0.0)
	return maxf(fposmod(MORNING_HOUR - hour, 24.0) * Calendar.HOUR, MORNING_MIN)


## Wie lange trauert pal um dead? Familie und Haushalt zwei Spieltage, sonst nach gemeinsamen Taten 1–2.
static func grief_time(pal: Guest, dead: Guest) -> float:
	var days := GRIEF_DAYS.x
	if pal.parent_guest() == dead or dead.parent_guest() == pal or pal.housemate_of(dead) \
			or str(dead.profile.get("parent", "")) == pal.id or str(pal.profile.get("parent", "")) == dead.id:
		days = GRIEF_DAYS.y
	elif Game.social and Game.social.pals:
		var deeds := int(Game.social.pals.counts.get(GuestPals.key(pal, dead), 0))
		days = clampf(GRIEF_DAYS.x + maxf(0.0, deeds - GuestPals.PAL_DEEDS) * GRIEF_PER_DEED, GRIEF_DAYS.x, GRIEF_DAYS.y)
	return days * Calendar.DAY_SECONDS


## Losgerissen vom Lakengeist oder als Kind von ihm erschreckt: bis zum nächsten Morgen.
static func after_ghost(g: Guest) -> void:
	if g == null or g.dead:
		return
	g.set_stance("after_ghost", until_morning())
	if Game.tracing:
		print("[Zustand] %s nach dem Lakengeist – bis %s" % [g.display_name, Calendar.time_text(float(g.stances["after_ghost"]["until"]))])


## Die Puppe vor der eigenen Tür bemerkt (JuryDoll): bis zum nächsten Morgen.
static func doll_door(g: Guest) -> void:
	if g == null or g.dead:
		return
	g.set_stance("doll_door", until_morning())
	if Game.tracing:
		print("[Zustand] %s hat die Puppe vor der Tür – bis %s" % [g.display_name, Calendar.time_text(float(g.stances["doll_door"]["until"]))])


## Eine Katze hat ihm ein Stück Deko weggeschleppt (HotelCat): Er vermisst es einen Spieltag. Das Stück trägt die
## Meta „cat_took“ – wer es findet und aufhebt, klaut nicht (Player.pick_up).
static func cat_took(owner: Guest, item: Item, cat_name: String) -> void:
	if owner == null or owner.dead or not THINGS.has(item.kind):
		return
	owner.set_stance("cat_took", CAT_TOOK_TIME, {"kind": int(item.kind), "cat": cat_name})
	item.set_meta("cat_took", owner.id)
	if Game.tracing:
		print("[Zustand] %s hat %s weggeschleppt – %s vermisst es" % [cat_name, item.display_name, owner.display_name])


## Ein passendes Geschenk in diesem Moment? Verletzt wie Wounds.fitting; Licht für Trauernde und Geist-Opfer (Angst im
## Dunkeln), Deko nach der Puppe, Süßes für Waisen.
static func fitting(g: Guest, item: Item) -> bool:
	if g.wound != "" and Wounds.fitting(g.wound, item, g.in_sickbed()):
		return true
	var light := item.kind == Item.Kind.CANDLE or (item.kind in Item.CANDLE_HOLDERS and item.lit)
	if light and (g.has_stance("grieving") or g.has_stance("after_ghost")):
		return true
	if g.has_stance("doll_door") and item.deco_strength > 0.0 and not item.kind in Guest.FOOD_GIFTS:
		return true
	return g.is_orphan() and item.kind in ORPHAN_GIFTS


## Begrüßung im schweren Moment ("" = keine eigene; verletzt grüßt schon über Wounds.GREET).
static func greet(g: Guest) -> String:
	var who := ""
	var key := ""
	if g.has_stance("grieving"):
		key = "grief"
		who = String(g.stances["grieving"].get("who", ""))
	elif g.has_stance("after_ghost"):
		key = "ghost"
	elif g.has_stance("doll_door"):
		key = "doll"
	elif g.is_orphan():
		key = "orphan"
	if key == "":
		return ""
	if g.is_child() and GREET.has(key + "_child"):
		key += "_child"
	return String((GREET[key] as Array).pick_random()).replace("{who}", who)


## Ein Gespräch im schweren Moment zählt als Besuch (Trauer: gegen die Kränkung).
static func on_visit(g: Guest) -> void:
	if g.has_stance("grieving"):
		(g.stances["grieving"] as Dictionary)["visited"] = true


## Die Trauer ist vorbei (Guest.prune_stances): Wer befreundet ist und nie vorbeikam, kränkt ihn; wer kam, dem dankt er.
static func on_grief_ended(g: Guest, s: Dictionary) -> void:
	if g.dead or Game.social == null:
		return
	if bool(s.get("visited", false)):
		g.wound_note = "grief_visited"
	elif Social.tier(g) >= Social.Tier.FRIEND:
		g.wound_note = "grief_neglect"
		Game.social.change_relation(g, NEGLECT)
	if Game.tracing:
		print("[Zustand] %s trauert nicht mehr%s" % [g.display_name, {"grief_visited": " – du warst da",
			"grief_neglect": " – du kamst nie, gekränkt"}.get(g.wound_note, "")])


## Der Satz zur Notiz nach einem schweren Moment ("" = keine von hier).
static func note_line(note: String) -> String:
	return String(NOTE_LINES.get(note, ""))
