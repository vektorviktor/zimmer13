class_name GuestGenerator
## Zufällige Hotelgäste (Spielkonzept 6). Aus einem Seed entsteht immer derselbe Gast –
## Spielstände speichern deshalb nur Seed und Zimmer. Ein Gast bekommt einen Namen, einen
## Charakter (Archetyp) mit passenden Werten und Sätzen, Aussehen, Vorrat und Würfelstil.
## Das Profil hat dieselbe Form wie die handgeschriebenen in GuestProfiles.ALL.
## Kinder (6.13) kommen aus make_child() – mit eigenen Namen, Werten und Sätzen.

const NAMES := [
	"Anton", "Berta", "Carla", "Dieter", "Elif", "Frieda", "Gustav", "Hanna", "Ida", "Jonas",
	"Karl", "Lotte", "Malte", "Nora", "Otto", "Paula", "Rosa", "Sami", "Theo", "Uschi",
	"Vera", "Walter", "Yara", "Zoe", "Henrik", "Greta", "Lena", "Kemal", "Ines", "Fritz",
	"Marta", "Luis", "Selma", "Ole", "Johanna", "Enno", "Wilma", "Arne", "Tilda", "Konrad",
	"Agnes", "Bastian", "Clara", "Detlef", "Emil", "Fiona", "Gerda", "Hugo", "Irma", "Jakob",
	"Klara", "Leon", "Magda", "Niklas", "Olga", "Peter", "Ruth", "Simon", "Thea", "Ulrich",
	"Viktor", "Wanda", "Xaver", "Yusuf", "Zita", "Alma", "Bernd", "Cem", "Doris", "Elias",
	"Franz", "Gisela", "Hedwig", "Ivo", "Jule", "Kurt", "Liesel", "Moritz", "Nele", "Oskar",
]
## Frauennamen aus NAMES (alle anderen sind Männernamen) – bestimmt den Grundkörper (GuestBody)
const FEMALE := [
	"Berta", "Carla", "Elif", "Frieda", "Hanna", "Ida", "Lotte", "Nora", "Paula", "Rosa", "Uschi", "Vera",
	"Yara", "Zoe", "Greta", "Lena", "Ines", "Marta", "Selma", "Johanna", "Wilma", "Tilda", "Agnes", "Clara",
	"Fiona", "Gerda", "Irma", "Klara", "Magda", "Olga", "Ruth", "Thea", "Wanda", "Zita", "Alma", "Doris",
	"Gisela", "Hedwig", "Jule", "Liesel", "Nele",
]
## Generation des Vornamens (Spielkonzept 6.0, „Gastmodelle“) – bestimmt mit dem Geschlecht den Grundkörper.
## Alle übrigen Namen sind „mid“. Je Geschlecht etwa ein Drittel jung und alt.
const OLD := [
	"Berta", "Gerda", "Gisela", "Hedwig", "Irma", "Liesel", "Magda", "Olga", "Ruth", "Wilma", "Zita", "Agnes",
	"Uschi", "Doris",
	"Anton", "Fritz", "Franz", "Gustav", "Hugo", "Karl", "Konrad", "Kurt", "Oskar", "Otto", "Walter", "Xaver",
	"Dieter",
]
const YOUNG := [
	"Elif", "Hanna", "Yara", "Zoe", "Lena", "Jule", "Nele", "Fiona", "Clara", "Paula", "Ida", "Greta", "Lotte",
	"Thea",
	"Cem", "Elias", "Emil", "Enno", "Jakob", "Jonas", "Leon", "Luis", "Moritz", "Niklas", "Ole", "Theo", "Yusuf",
]
## Körpergröße in cm je Geschlecht: Mittel, Streuung, Grenzen (Spielkonzept 6.0: 150–185, selten über 190)
const HEIGHT_CM := {"m": [176.0, 6.0, 160.0, 193.0], "f": [164.0, 5.5, 150.0, 180.0]}
## Schulterbreite in cm je Geschlecht (Spielkonzept 6.0: 35–50)
const WIDTH_CM := {"m": Vector2(41.0, 50.0), "f": Vector2(35.0, 43.0)}
const CLOTHING := ["Mütze", "Schal", "Handschuh", "Brille", "Halstuch", "Strickjacke", "Taschenuhr", "Hut", "Haarspange"]
const TELLS := [
	"%s trommelt mit den Fingern auf den Tisch.", "%s blinzelt auffällig oft.", "%s räuspert sich.",
	"%s kratzt sich am Ohr.", "%s grinst eine Spur zu breit.", "%s schaut kurz zur Decke.",
	"%s wippt mit dem Fuß.", "%s beißt sich auf die Lippe.",
]
## Oberteile: gedeckte Töne, dazu helle und bunte (hellrot, weiß, senf, hellblau, mint, rosa, hellgrau, orange,
## creme, königsblau).
const COATS := [
	Color(0.42, 0.28, 0.48), Color(0.3, 0.25, 0.18), Color(0.2, 0.45, 0.4), Color(0.5, 0.15, 0.12),
	Color(0.18, 0.22, 0.4), Color(0.45, 0.42, 0.3), Color(0.25, 0.3, 0.15), Color(0.55, 0.35, 0.1),
	Color(0.15, 0.15, 0.15), Color(0.6, 0.55, 0.5),
	Color(0.88, 0.3, 0.28), Color(0.9, 0.9, 0.88), Color(0.88, 0.7, 0.28), Color(0.55, 0.72, 0.88),
	Color(0.55, 0.8, 0.62), Color(0.92, 0.6, 0.66), Color(0.72, 0.72, 0.74), Color(0.92, 0.52, 0.2),
	Color(0.9, 0.84, 0.7), Color(0.3, 0.42, 0.78),
]
## Hosen: dunkle Stoffhosen, fünf Jeanstöne (dunkel, mittel, stonewashed, hell, verwaschen schwarzblau – zusammen
## gut ein Drittel), dazu beige, hellgrau, khaki und creme.
const PANTS := [
	Color(0.2, 0.18, 0.22), Color(0.15, 0.15, 0.17), Color(0.25, 0.2, 0.3), Color(0.3, 0.25, 0.2), Color(0.12, 0.14, 0.2),
	Color(0.16, 0.22, 0.36), Color(0.25, 0.36, 0.55), Color(0.42, 0.53, 0.68), Color(0.58, 0.67, 0.8), Color(0.18, 0.19, 0.24),
	Color(0.8, 0.72, 0.58), Color(0.62, 0.62, 0.64), Color(0.55, 0.52, 0.38), Color(0.88, 0.86, 0.8),
]
## Haare: Platin-, Gold-, Dunkelblond, Hell-, Kastanien-, Dunkelbraun, Schwarz, Kupferrot, Rotbraun, Grau, Silberweiß
const HAIR := [
	Color(0.9, 0.84, 0.66), Color(0.78, 0.6, 0.32), Color(0.55, 0.42, 0.26), Color(0.45, 0.3, 0.18),
	Color(0.36, 0.2, 0.11), Color(0.22, 0.14, 0.09), Color(0.08, 0.07, 0.07), Color(0.7, 0.32, 0.14),
	Color(0.48, 0.2, 0.11), Color(0.58, 0.58, 0.6), Color(0.85, 0.85, 0.87),
]
## Hauttöne (Spielkonzept 6.0) von sehr hell bis sehr dunkel – GuestBody rechnet je Grundkörper den Faktor auf
## die Textur-Haut aus, damit derselbe Ton auf jedem Modell gleich aussieht.
const SKIN := [
	Color(0.94, 0.8, 0.7), Color(0.88, 0.7, 0.58), Color(0.78, 0.62, 0.46), Color(0.68, 0.5, 0.36),
	Color(0.56, 0.39, 0.27), Color(0.44, 0.29, 0.2), Color(0.33, 0.21, 0.14), Color(0.24, 0.15, 0.1),
]
const DECO := [Item.Kind.CANDLE, Item.Kind.LEAVES, Item.Kind.PUMPKIN, Item.Kind.CARVED_PUMPKIN, Item.Kind.COBWEB]

## Sätze, die jeder Gast sagen kann – Archetypen ersetzen oder ergänzen sie.
const COMMON := {
	"greet_friend": ["Da bist du ja! Gut, dich zu sehen.", "Ah, du! Endlich jemand, dem ich trauen kann."],
	"greet": ["Hallo.", "Oh – hallo. Ich hab dich gar nicht kommen hören.", "Guten Abend. Oder ist es Morgen? Hier weiß man das nie."],
	"greet_enemy": ["Was willst du?", "Ach, du schon wieder."],
	"smalltalk": ["Die Flure hier sind endlos. Ich verlaufe mich ständig.", "In der Küche ist nie jemand. Trotzdem steht immer frisches Brot da.", "Hast du die Zimmernummern gesehen? Es gibt eine 13. Das traut sich sonst kein Hotel."],
	"monster": [
		"Wenn das Rauschen lauter wird, ist es nah. Dann such dir ein Versteck – eins, bei dem es dich nicht sieht.",
		"Licht hält es fern. Ein geschnitzter Kürbis mit Kerze vor der Tür wirkt Wunder.",
		"Es kommt aus dem Keller. Ganz unten im Treppenhaus, wo die Treppe aufhört … da gehe ich nicht hin.",
		"Die Lampen flackern dort, wo es gerade ist. Achte darauf.",
		"Je mehr wir darüber reden, desto dreister wird es. Also … leise.",
		"In den Flügeln ist es am dunkelsten. Da streift es am liebsten herum.",
	],
	"odd": ["Die Fenster gehen alle nicht auf. Ich hab's bei jedem versucht.", "Manchmal höre ich nachts jemanden in den leeren Zimmern umräumen.", "Ich freue mich auf Halloween. Glaube ich."],
	"knock": ["Mach auf! Bitte!", "Lass mich rein, schnell!", "Es ist hinter mir! Mach auf!"],
	"sheltered": ["Danke. Ich … ich bleibe nur kurz.", "Danke. Das vergesse ich dir nicht."],
	"left_outside": ["Du hast mich draußen gelassen. Ich hab gehört, wie du hinter der Tür standest."],
	"insult": ["Bitte?!", "Das hab ich nicht verdient."],
	"thanks": ["Danke!", "Oh, das ist nett von dir."],
	"thanks_like": ["Genau so etwas habe ich gesucht!"],
	"give_deco": ["Hier, nimm. Du brauchst es dringender als ich."],
	"refuse_deco": ["Das brauche ich selbst, tut mir leid."],
	"panic": ["Es ist hier! Weg, weg, weg!", "Ich hab es gesehen! Ich muss mich verstecken!"],
	"calm": ["Danke … es geht wieder."],
	"party_yes": ["Eine Feier? Gern!"],
	"party_no": ["Nein danke."],
	"caught": ["He! Das gehört mir!"],
	"missing": ["Wer hat meine Deko vor der Tür genommen?"],
	"dice_yes": ["Na gut, eine Runde."],
	"dice_no": ["Nicht jetzt."],
	"dice_win": ["Gewonnen!"],
	"dice_lose": ["Gut gespielt."],
	"challenge": ["Lust auf eine Runde Mäxchen an der Bar?"],
	"caught_cheat": ["Gezinkte Würfel? Ernsthaft?!"],
	"patronized": ["Du hast mich gewinnen lassen. Lass das."],
}

## Charaktere: Wertebereiche (Vector2 = zufällig dazwischen), Vorlieben und eigene Sätze.
## Schach (Spielkonzept 6.10): wie gern jeder Typ spielt, und seine Sätze dazu
const CHESS_LIKES := {"ängstlich": 0.4, "geschäftstüchtig": 0.3, "Plaudertasche": 0.4, "Skeptiker": 0.85, "Bastler": 0.6, "Griesgram": 0.7}
const CHESS_LINES := {
	"ängstlich": {"chess_yes": ["Schach ist gut. Da ist es so schön still."], "chess_no": ["Ich kann mich gerade auf nichts konzentrieren."],
		"chess_win": ["Oh … ich habe gewonnen? Entschuldige."], "chess_lose": ["Danke. Das hat mich abgelenkt."],
		"chess_challenge": ["Würdest du … eine Partie Schach mit mir spielen? In der Lobby, da ist Licht."]},
	"geschäftstüchtig": {"chess_yes": ["Schach? Gut – aber nur mit Einsatz."], "chess_no": ["Schach bringt kein Geld."],
		"chess_win": ["Matt. Zahlen bitte."], "chess_lose": ["Glück. Reines Glück."],
		"chess_challenge": ["Revanche am Schachbrett. Leg was drauf."]},
	"Plaudertasche": {"chess_yes": ["Schach! Da können wir nebenbei so schön reden."], "chess_no": ["Ach, jetzt nicht, ich muss noch jemandem was erzählen!"],
		"chess_win": ["Ups, Matt! Das muss ich gleich allen erzählen."], "chess_lose": ["Du spielst ja richtig gut! Wer hätte das gedacht."],
		"chess_challenge": ["Spielst du Schach? Komm, eine Partie in der Lobby!"]},
	"Skeptiker": {"chess_yes": ["Schach. Endlich etwas Logisches in diesem Hotel."], "chess_no": ["Nicht jetzt. Ich denke nach."],
		"chess_win": ["Matt. Das war absehbar."], "chess_lose": ["Interessant. Diese Variante kannte ich nicht."],
		"chess_challenge": ["Eine Partie Schach? Ich möchte wissen, ob du rechnen kannst."]},
	"Bastler": {"chess_yes": ["Schach! Ich hab mal Figuren geschnitzt, weißt du."], "chess_no": ["Später, ich bastle gerade."],
		"chess_win": ["Matt! Hehe."], "chess_lose": ["Schöner Zug, der letzte. Den merk ich mir."],
		"chess_challenge": ["Lust auf Schach? Das Brett in der Lobby ist ein schönes altes Stück."]},
	"Griesgram": {"chess_yes": ["Schach. Wenigstens redet man dabei nicht."], "chess_no": ["Lass mich in Ruhe mit deinem Brettkram."],
		"chess_win": ["Matt. Und jetzt geh."], "chess_lose": ["Hm. Nicht schlecht."],
		"chess_challenge": ["Du. Schach. Lobby. Oder hast du Angst?"]},
}

const ARCHETYPES := [
	{
		"kind": "ängstlich",
		"brave": Vector2(0.05, 0.3), "greed": Vector2(0.05, 0.25), "gossip": Vector2(0.3, 0.6),
		"sell": Vector2(0.9, 1.1), "buy": Vector2(0.6, 0.8), "reliable": Vector2(0.35, 0.6),
		"money": Vector2i(4, 14), "harvester": 0.1, "carver": 0.2, "dice_likes": 0.3,
		"likes": [Item.Kind.CANDLE, Item.Kind.CARVED_PUMPKIN],
		"stock": {Item.Kind.CANDLE: Vector2i(1, 4), Item.Kind.LEAVES: Vector2i(0, 2)},
		"activities": {"room": 4.0, "lobby": 2.5, "kitchen": 1.5, "garden": 0.3, "wander": 0.3, "bar": 0.6},
		"report": "Ich … ich glaube, da waren %s. Bei %s. Bitte sag, dass ich mir das eingebildet habe.",
		"lines": {
			"greet": ["Oh! Du bist es nur. Gott sei Dank.", "Hast du das gehört? Nein? Dann … ist ja gut."],
			"smalltalk": ["Ich schlafe nur noch mit Licht. Alle Lampen an.", "Ich zähle jede Nacht die Schritte im Flur. Es sind immer mehr, als Gäste da sind."],
			"odd": ["Ich habe meine Tür dreimal abgeschlossen. Dreimal!", "Das Hotel kam mir im Prospekt viel freundlicher vor."],
			"party_yes": ["Eine Feier … mit vielen Leuten? Ja, das ist sicherer."],
			"party_no": ["Laut sein? Jetzt? Lieber nicht …"],
			"dice_no": ["Ich kann mich gerade auf nichts konzentrieren."],
			"panic": ["Nein, nein, nein! Es ist da!", "Ich wusste es! Ich wusste es!"],
			"calm": ["Ja … ja. Atmen. Danke, dass du bleibst."],
		},
	},
	{
		"kind": "geschäftstüchtig",
		"brave": Vector2(0.6, 0.9), "greed": Vector2(0.7, 0.95), "gossip": Vector2(0.1, 0.3),
		"sell": Vector2(1.3, 1.7), "buy": Vector2(0.4, 0.6), "reliable": Vector2(0.75, 0.95),
		"money": Vector2i(20, 40), "harvester": 0.8, "carver": 0.3, "dice_likes": 0.9,
		"likes": [Item.Kind.KNIFE, Item.Kind.COINS, Item.Kind.CARVED_PUMPKIN],
		"stock": {Item.Kind.PUMPKIN: Vector2i(1, 3), Item.Kind.LEAVES: Vector2i(1, 3), Item.Kind.CANDLE: Vector2i(0, 2)},
		"activities": {"room": 2.5, "lobby": 2.0, "kitchen": 1.0, "garden": 2.0, "wander": 1.0, "bar": 3.0},
		"report": "%s, bei %s. Ich sag's dir umsonst. Ausnahmsweise.",
		"lines": {
			"greet": ["Na? Kaufen oder verkaufen?", "Zeit ist Geld. Was gibt's?"],
			"greet_friend": ["Mein bester Kunde! Was darf's sein?"],
			"smalltalk": ["In so einem Haus braucht jeder irgendwas. Und ich hab's.", "Kerzen werden knapp. Die Preise steigen. So ist das."],
			"thanks": ["Gutes Geschäft.", "Das merk ich mir – im Guten."],
			"refuse_deco": ["Umsonst? Ich bin doch nicht die Wohlfahrt."],
			"give_deco": ["Hier. Aber du schuldest mir was."],
			"dice_yes": ["Mäxchen? Leg was auf den Tisch."],
			"dice_win": ["Das Haus gewinnt immer."],
			"dice_lose": ["Glück. Nächstes Mal nicht."],
			"challenge": ["Revanche. Bar. Jetzt.", "Na, Lust, dein Geld loszuwerden?"],
			"panic": ["Jeder ist sich selbst der Nächste!", "Aus dem Weg!"],
		},
	},
	{
		"kind": "Plaudertasche",
		"brave": Vector2(0.35, 0.6), "greed": Vector2(0.2, 0.5), "gossip": Vector2(0.8, 1.0),
		"sell": Vector2(1.0, 1.2), "buy": Vector2(0.7, 0.9), "reliable": Vector2(0.4, 0.7),
		"money": Vector2i(6, 18), "harvester": 0.4, "carver": 0.4, "dice_likes": 0.6,
		"likes": [Item.Kind.LEAVES, Item.Kind.CANDLE, Item.Kind.PUMPKIN],
		"stock": {Item.Kind.LEAVES: Vector2i(1, 3), Item.Kind.CANDLE: Vector2i(0, 2), Item.Kind.PUMPKIN: Vector2i(0, 1)},
		"activities": {"room": 1.5, "lobby": 4.0, "kitchen": 1.5, "garden": 1.0, "wander": 1.5, "bar": 2.0},
		"report": "Hast du's schon gehört? %s! Bei %s! Alle reden davon!",
		"lines": {
			"greet": ["Hey! Hast du schon das Neueste gehört?", "Da bist du ja! Ich muss dir was erzählen!"],
			"smalltalk": ["Weißt du, wer gestern mit wem an der Bar gewürfelt hat? Ich schon.", "Ich kenne hier jeden. Na ja. Fast jeden.", "Im Nordflügel soll es nachts klopfen. Hat mir jemand erzählt."],
			"insult": ["Wow. Das erzähl ich weiter.", "Das wird jeder erfahren, nur damit du's weißt."],
			"caught": ["Hey! Das erfahren alle!"],
			"party_yes": ["Party?! Ich bin dabei!", "Endlich! Ich sag den anderen Bescheid!"],
			"left_outside": ["Du hast mich nicht reingelassen. Das erzähl ich allen."],
		},
	},
	{
		"kind": "Skeptiker",
		"brave": Vector2(0.7, 0.95), "greed": Vector2(0.2, 0.45), "gossip": Vector2(0.05, 0.25),
		"sell": Vector2(1.0, 1.2), "buy": Vector2(0.6, 0.8), "reliable": Vector2(0.85, 0.98),
		"money": Vector2i(10, 25), "harvester": 0.3, "carver": 0.2, "dice_likes": 0.5,
		"likes": [Item.Kind.BULB, Item.Kind.KNIFE],
		"stock": {Item.Kind.CANDLE: Vector2i(0, 2), Item.Kind.BULB: Vector2i(0, 2)},
		"activities": {"room": 3.0, "lobby": 2.0, "kitchen": 1.0, "garden": 1.0, "wander": 2.0, "bar": 1.5},
		"report": "Nüchtern betrachtet: %s, bei %s. Das ist eine Beobachtung, keine Geschichte.",
		"lines": {
			"greet": ["Guten Abend.", "Ah. Ein vernünftiges Gesicht."],
			"smalltalk": ["Es gibt für alles eine Erklärung. Ich hab sie nur noch nicht gefunden.", "Ich führe Buch: Wann das Licht flackert, wo es rauscht. Da steckt ein Muster drin."],
			"odd": ["Ein Hotel ohne Personal, aber mit frischer Bettwäsche. Interessant.", "Die Stromleitungen hier sind älter als ich."],
			"monster": ["Es kommt in Phasen. Mal ist es lange ruhig – dann ist es im Keller.", "Es reagiert auf Blicke. Starr es nicht an, wenn du nicht gefunden werden willst."],
			"panic": ["Okay. Okay. Das ist … real.", "Rückzug. Sofort."],
			"calm": ["Schon gut. Ich hab mich wieder im Griff."],
			"dice_yes": ["Wahrscheinlichkeiten. Gut. Spielen wir."],
		},
	},
	{
		"kind": "Bastler",
		"brave": Vector2(0.4, 0.65), "greed": Vector2(0.25, 0.5), "gossip": Vector2(0.4, 0.7),
		"sell": Vector2(1.0, 1.3), "buy": Vector2(0.8, 1.0), "reliable": Vector2(0.55, 0.8),
		"money": Vector2i(5, 15), "harvester": 0.9, "carver": 0.95, "dice_likes": 0.4,
		"likes": [Item.Kind.PUMPKIN, Item.Kind.COBWEB, Item.Kind.KNIFE],
		"stock": {Item.Kind.PUMPKIN: Vector2i(1, 2), Item.Kind.CARVED_PUMPKIN: Vector2i(1, 2), Item.Kind.COBWEB: Vector2i(0, 1)},
		"activities": {"room": 2.0, "lobby": 2.0, "kitchen": 1.5, "garden": 3.5, "wander": 1.0, "bar": 1.0},
		"report": "%s! Bei %s! Gruselig – das wäre eine tolle Deko-Idee.",
		"lines": {
			"greet": ["Hi! Schon gesehen, was ich vor meine Tür gestellt hab?", "Oh, hallo! Ich hab Kürbisreste an den Händen, sorry."],
			"smalltalk": ["Mit dem Messer aus der Küche schnitzt es sich am besten.", "Spinnweben in den dunklen Ecken – perfekt für Deko. Wenn man sich traut."],
			"thanks_like": ["Perfekt, daraus mach ich was richtig Gruseliges!"],
			"give_deco": ["Nimm den hier – frisch geschnitzt!"],
			"refuse_deco": ["Meine Deko verschenke ich nur an Freunde."],
			"odd": ["Ich mache die schönste Tür im ganzen Hotel. Wetten?"],
		},
	},
	{
		"kind": "Griesgram",
		"brave": Vector2(0.5, 0.8), "greed": Vector2(0.45, 0.75), "gossip": Vector2(0.3, 0.6),
		"sell": Vector2(1.2, 1.5), "buy": Vector2(0.5, 0.7), "reliable": Vector2(0.6, 0.85),
		"money": Vector2i(8, 22), "harvester": 0.5, "carver": 0.1, "dice_likes": 0.5,
		"likes": [Item.Kind.CANDLE, Item.Kind.COINS],
		"stock": {Item.Kind.CANDLE: Vector2i(0, 2), Item.Kind.LEAVES: Vector2i(1, 2)},
		"activities": {"room": 4.0, "lobby": 1.0, "kitchen": 2.0, "garden": 1.0, "wander": 1.0, "bar": 2.0},
		"report": "%s. Bei %s. Hätte man ja auch mal wegmachen können.",
		"lines": {
			"greet": ["Hm.", "Was denn jetzt schon wieder?"],
			"greet_friend": ["Ach, du. Na, du bist wenigstens erträglich."],
			"smalltalk": ["Zu laut, zu dunkel, zu kalt. Und dann dieses Ding im Keller.", "Früher war das ein anständiges Hotel."],
			"party_yes": ["Wenn's sein muss."],
			"party_no": ["Feiern. Jetzt. Natürlich nicht."],
			"thanks": ["Hm. Danke.", "Na also. Geht doch."],
			"dice_no": ["Lass mich in Ruhe mit deinem Würfelkram."],
			"panic": ["Bleib mir vom Leib!", "Weg da!"],
		},
	},
]


## Kinder (Spielkonzept 6.13): Namen, Kleidungsstück, Tagesablauf (keine Bar), großer Kopf (GuestBody),
## ab und zu ein Schach-Wunderkind, eigene Sätze ({eltern} = Mama/Papa, {eltern_dat} = meiner Mama/meinem Papa).
const CHILD_NAMES := ["Max", "Lina", "Paul", "Emma", "Ben", "Merle", "Finn", "Juna", "Tom", "Ella", "Jan", "Pia",
	"Felix", "Ronja", "Till", "Smilla"]
const CHILD_FEMALE := ["Lina", "Emma", "Merle", "Juna", "Ella", "Pia", "Ronja", "Smilla"]
const CHILD_CLOTHING := ["Kuscheltier", "Pudelmütze", "Fäustling", "Haarspange", "Murmelbeutel"]
const CHILD_ACTIVITIES := {"room": 2.0, "lobby": 3.0, "kitchen": 1.0, "garden": 3.0, "wander": 2.5}
const CHILD_HEAD := 1.25
const CHILD_PRODIGY := 0.2
const CHILD_LINES := {
	"greet_friend": ["Hallo! Spielst du mit mir?", "Da bist du ja! Ich hab dich überall gesucht!"],
	"greet": ["Hallo. Wer bist du?", "Hi! Ich darf eigentlich nicht mit Fremden reden.", "Bist du auch in den Ferien hier?"],
	"greet_enemy": ["Mit dir red ich nicht.", "Geh weg!"],
	"smalltalk": ["Im Garten gibt es Kürbisse, die sind größer als ich!", "Ich hab einen Käfer gefunden. Der wohnt jetzt in meiner Hosentasche.",
		"{eltern} sagt, ich soll nicht so rennen. Aber die Flure sind sooo lang!", "Ich hab die Zimmer gezählt. Bis hundert, dann hab ich aufgehört.",
		"Die Katzen mögen mich. Minka hat mir die Hand abgeleckt!"],
	"monster": ["Im Keller wohnt ein Monster. Ehrlich! Aber keiner glaubt mir.", "Wenn die Lampen flackern, versteck ich mich unter der Decke.",
		"Es hat mich angeschaut. Mit ganz vielen Zähnen. Und dann ist es einfach weitergegangen.", "Die Katzen haben Angst vor ihm. Ich auch."],
	"odd": ["Nachts klopft es manchmal an mein Fenster.", "{eltern} sagt, Gespenster gibt es nicht.", "Ich freu mich auf Halloween! Ich will gaaanz viel Süßes!"],
	"knock": ["Mach auf! Bitte, bitte!", "Hilfe! Ich will zu {eltern}!"],
	"sheltered": ["Danke … darf ich kurz bleiben?"],
	"left_outside": ["Du hast mich nicht reingelassen. Ich hatte ganz doll Angst."],
	"insult": ["Du bist gemein!", "Das sag ich {eltern_dat}!"],
	"thanks": ["Danke!", "Juhu!"],
	"thanks_like": ["Wow! Darf ich das echt behalten?"],
	"give_deco": ["Hier, für dich! Hab ich selbst gesammelt."],
	"refuse_deco": ["Das ist meins!", "Nur, wenn du mein Freund bist."],
	"panic": ["{eltern}! {eltern}!", "Ich will nach Hause!"],
	"calm": ["Okay … bleibst du noch ein bisschen?"],
	"party_yes": ["Eine Party? JAAA!", "Darf ich tanzen? Ich tanz am allerbesten!"],
	"party_no": ["…"],
	"caught": ["Das ist meins! Das sag ich {eltern_dat}!"],
	"tattle": ["Ich hab genau gesehen, wie du das geklaut hast! Das sag ich {eltern_dat}!"],
	"missing": ["Wer hat mein Laub weggenommen?!"],
	"dice_yes": ["Würfeln! Aber nur zum Spaß, sagt {eltern}."],
	"dice_no": ["Nö."],
	"dice_win": ["Gewonnen! Gewonnen!"],
	"dice_lose": ["Menno."],
	"challenge": ["Spielst du mit mir Würfeln?"],
	"caught_cheat": ["Du schummelst! Das ist unfair!"],
	"patronized": ["Du hast mich extra gewinnen lassen. Das ist doof."],
	"chess_yes": ["Schach! Das kann ich schon!"], "chess_no": ["Schach ist langweilig."],
	"chess_win": ["Schachmatt! Hihi."], "chess_lose": ["Nochmal! Nochmal!"],
	"chess_challenge": ["Spielst du Schach mit mir? Ich bin richtig gut!"],
	"only_fun": ["Nur zum Spaß! Um Geld darf ich nicht spielen, sagt {eltern}."],
	"no_drink": ["Iiih, das riecht komisch. {eltern} sagt, das ist nur für Erwachsene."],
	"cocoa": ["Kakao! Mit Sahne? Danke!", "Mmmh. Jetzt hab ich einen Kakaobart."],
	"knife": ["Ein echtes Messer! {eltern} erlaubt mir das nie."],
	"trick": ["Süßes oder Saures!", "Süßes, sonst gibt's Saures!"],
	"treat": ["Danke! Du bist der Allerbeste!", "Juhu! Die teil ich nicht."],
	"prank": ["Keine Süßigkeiten? Dann gibt's Saures!", "Ätsch! Saures!"],
	"treat_other": ["Danke!", "Juhu, Bonbons!", "Danke schön! Fröhliches Halloween!"],
	"scolded": ["Menno. Dann eben Saures!", "Pff, gemein. Saures!"],
	"sleepless": ["Ich kann nicht schlafen.", "Da war was am Fenster … darf ich zu dir?"],
	"to_bed": ["Na gut … aber du bleibst, bis ich eingeschlafen bin.", "Okay. Gute Nacht."],
	"orphan": ["{eltern} ist nicht wiedergekommen. Darf ich bei dir bleiben?", "Wo ist {eltern}? Ich bleib bei dir, ja?"],
	"phone_chat": ["Hallo? Hier ist {name}! Ich hab das Telefon ganz allein bedient!", "Rate mal, wer hier ist! … {name}!"],
	"phone_warn": ["Hier ist {name}! Das Monster ist {where}! Ich hab's gesehen, echt!"],
	"phone_warn_near": ["{name} hier … es ist bei mir im Flur … ich hab Angst …"],
	"phone_party": ["Hier ist {name}! In der Lobby ist Party! Kommst du?"],
	"phone_answer": ["Hallo? Hier ist {name}!"],
}


## "young", "mid" oder "old" – nur vom Vornamen abhängig, kein Zufall (Spielstände bleiben gleich)
static func generation(guest_name: String) -> String:
	if guest_name in OLD:
		return "old"
	if guest_name in YOUNG:
		return "young"
	return "mid"


## Der Name eines Gastes hängt nur vom Seed ab (erste Zufallszahl) – Social prüft damit,
## ob ein Name schon vergeben ist, ohne den ganzen Gast zu erzeugen.
static func name_for(gen_seed: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = gen_seed
	return NAMES[rng.randi() % NAMES.size()]


## Ein vollständiges Profil. arrived_room ≠ "": der Gast ist neu im Hotel aufgewacht.
static func make(gen_seed: int, room: String, arrived_room: String = "") -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = gen_seed
	var guest_name: String = NAMES[rng.randi() % NAMES.size()]
	var arche: Dictionary = ARCHETYPES[rng.randi() % ARCHETYPES.size()]
	var lines := {}
	var own: Dictionary = arche["lines"]
	for key in COMMON:
		var pool: Array = (own.get(key, []) as Array).duplicate()
		# Etwas Grundstock dazu, damit sich Gäste desselben Typs nicht gleich anhören
		var common: Array = COMMON[key]
		if pool.is_empty() or rng.randf() < 0.5:
			pool.append(common[rng.randi() % common.size()])
		lines[key] = pool
	if arrived_room != "":
		lines["smalltalk"].append("Ich bin in Zimmer %s aufgewacht. Ich weiß nicht mehr, wie ich hergekommen bin." % arrived_room)
		lines["greet"].append("Entschuldigung … wo bin ich hier? Was ist das für ein Hotel?")
	var stock := {}
	var stock_ranges: Dictionary = arche["stock"]
	for kind in stock_ranges:
		var r: Vector2i = stock_ranges[kind]
		var count := rng.randi_range(r.x, r.y)
		if count > 0:
			stock[kind] = count
	var start_deco: Array = []
	for kind in stock:
		if kind in DECO and start_deco.size() < 2 and rng.randf() < 0.7:
			start_deco.append(kind)
	if start_deco.is_empty():
		start_deco.append(Item.Kind.LEAVES)
	var activities := {}
	var base: Dictionary = arche["activities"]
	for key in base:
		activities[key] = float(base[key]) * rng.randf_range(0.6, 1.4)
	var profile := {
		"name": guest_name, "room": room, "archetype": arche["kind"], "generated": true,
		"sex": "f" if guest_name in FEMALE else "m", "gen": generation(guest_name),
		"coat": COATS[rng.randi() % COATS.size()], "pants": PANTS[rng.randi() % PANTS.size()],
		"hair": HAIR[rng.randi() % HAIR.size()], "height": rng.randf_range(0.92, 1.07),
		"brave": _range(rng, arche["brave"]), "greed": _range(rng, arche["greed"]),
		"gossip": _range(rng, arche["gossip"]), "sell": _range(rng, arche["sell"]), "buy": _range(rng, arche["buy"]),
		"harvester": rng.randf() < float(arche["harvester"]), "carver": rng.randf() < float(arche["carver"]),
		"likes": arche["likes"], "stock": stock, "start_deco": start_deco, "activities": activities,
		"money": rng.randi_range((arche["money"] as Vector2i).x, (arche["money"] as Vector2i).y),
		"reliable": _range(rng, arche["reliable"]),
		"clothing": "%s %s" % [_genitive(guest_name), CLOTHING[rng.randi() % CLOTHING.size()]],
		"report": arche["report"],
		"dice": {
			"likes": rng.randf() < float(arche["dice_likes"]), "honesty": rng.randf_range(0.35, 0.9),
			"jump": rng.randi_range(1, 2), "perception": rng.randf_range(0.15, 0.6),
			"pride": rng.randf_range(0.1, 0.9), "tell": TELLS[rng.randi() % TELLS.size()] % guest_name,
		},
		"lines": lines,
	}
	# Neue Zufallswerte nur hier anhängen (Spielstände speichern nur den Seed):
	# Skeptiker haben Batterien für Taschenlampen (Spielkonzept 4.16)
	var batteries := rng.randi_range(0, 2)
	if arche["kind"] == "Skeptiker" and batteries > 0:
		stock[Item.Kind.BATTERY] = batteries
	# Körper fürs Gastmodell (GuestBody): Größe, Schulterbreite, Körperbau (−0,6 schlank … 1 kräftig)
	var h: Array = HEIGHT_CM[profile["sex"]]
	profile["height_cm"] = clampf(rng.randfn(h[0], h[1]), h[2], h[3])
	var w: Vector2 = WIDTH_CM[profile["sex"]]
	profile["width_cm"] = rng.randf_range(w.x, w.y)
	profile["build"] = rng.randf_range(-0.6, 1.0)
	# Schach (Spielkonzept 6.10): Lust und Spielstärke 0..1, Stolz wie beim Würfeln
	var chess_likes := rng.randf() < float(CHESS_LIKES.get(arche["kind"], 0.4))
	profile["chess"] = {"likes": chess_likes, "skill": rng.randf(), "pride": profile["dice"]["pride"]}
	var chess_lines: Dictionary = CHESS_LINES.get(arche["kind"], {})
	for key in chess_lines:
		lines[key] = chess_lines[key]
	# Aufgehängte Deko (Spielkonzept 5.6): manche haben ein Lakengespenst oder eine Lichterkette an der Tür
	var festive := rng.randf()
	if festive < 0.25:
		start_deco.append(Item.Kind.SHEET_GHOST)
	elif festive < 0.35:
		start_deco.append(Item.Kind.LIGHT_STRING)
	elif festive < 0.45:
		start_deco.append(Item.Kind.BAT_GARLAND)
	elif festive < 0.5:
		start_deco.append(Item.Kind.SPIDER)
	profile["skin"] = SKIN[rng.randi() % SKIN.size()]
	return profile


## Ein Kind (Spielkonzept 6.13) – eigener Zufall, damit make() für gespeicherte Seeds gleich bleibt.
## Es gehört zu parent_id (erzeugter Erwachsener), wohnt im Zimmer nebenan und spricht von „Mama“ bzw. „Papa“.
static func make_child(gen_seed: int, room: String, parent_id: String, parent: Dictionary) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = gen_seed
	var child_name: String = CHILD_NAMES[rng.randi() % CHILD_NAMES.size()]
	var mum: bool = parent.get("sex", "m") == "f"
	var words := {"eltern": "Mama" if mum else "Papa", "eltern_dat": "meiner Mama" if mum else "meinem Papa"}
	var lines := {}
	for key in CHILD_LINES:
		lines[key] = (CHILD_LINES[key] as Array).map(func(s: String) -> String: return s.format(words))
	var age := rng.randi_range(6, 11)
	var prodigy := rng.randf() < CHILD_PRODIGY
	var activities := {}
	for key in CHILD_ACTIVITIES:
		activities[key] = float(CHILD_ACTIVITIES[key]) * rng.randf_range(0.6, 1.4)
	var height_cm := 112.0 + (age - 6) * 6.0 + rng.randf_range(-4.0, 4.0)
	var profile := {
		"name": child_name, "room": room, "archetype": "Kind", "generated": true, "child": true, "parent": parent_id,
		"age": age, "sex": "f" if child_name in CHILD_FEMALE else "m",
		"coat": COATS[rng.randi() % COATS.size()], "pants": PANTS[rng.randi() % PANTS.size()],
		# meist dieselbe Haarfarbe wie Mama oder Papa
		"hair": parent.get("hair", HAIR[0]) if rng.randf() < 0.7 else HAIR[rng.randi() % HAIR.size()],
		"skin": parent.get("skin", SKIN[0]),   # Hautton wie Mama oder Papa
		"height": height_cm / 170.0, "height_cm": height_cm, "width_cm": rng.randf_range(27.0, 33.0),
		"build": rng.randf_range(-0.4, 0.6), "head": CHILD_HEAD,
		"brave": rng.randf_range(0.05, 0.3), "greed": rng.randf_range(0.0, 0.1), "gossip": rng.randf_range(0.8, 1.0),
		"sell": rng.randf_range(0.8, 1.0), "buy": rng.randf_range(0.9, 1.1), "reliable": rng.randf_range(0.9, 1.0),
		"harvester": false, "carver": false,
		"likes": [Item.Kind.SWEETS, Item.Kind.LEAVES, Item.Kind.PUMPKIN, Item.Kind.CANDLE],
		"stock": {Item.Kind.LEAVES: rng.randi_range(1, 3)}, "start_deco": [Item.Kind.LEAVES], "activities": activities,
		"money": rng.randi_range(0, 3), "shock": "cling",
		"clothing": "%s %s" % [_genitive(child_name), CHILD_CLOTHING[rng.randi() % CHILD_CLOTHING.size()]],
		"report": "Ich hab %s gesehen! Bei %s! Ehrlich, ich lüg nicht!",
		"dice": {
			"likes": rng.randf() < 0.5, "honesty": rng.randf_range(0.8, 1.0), "jump": 1,
			"perception": rng.randf_range(0.1, 0.3), "pride": rng.randf_range(0.3, 0.8),
			"tell": "%s kichert und hält sich die Hand vor den Mund." % child_name,
		},
		# Schach: ab und zu ein Wunderkind, das fast jeden schlägt (und Revanche will)
		"chess": {"likes": prodigy or rng.randf() < 0.35, "skill": 0.97 if prodigy else rng.randf_range(0.0, 0.35),
			"pride": 0.85 if prodigy else 0.4},
		"prodigy": prodigy,
		"lines": lines,
	}
	if prodigy:
		lines["chess_challenge"] = ["Ich hab noch nie verloren. Willst du's versuchen?"]
		lines["chess_lose"] = ["Das … das gibt's nicht! Revanche! Sofort!"]
	return profile


## Name eines Kindes – wie name_for() die erste Zufallszahl.
static func child_name_for(gen_seed: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = gen_seed
	return CHILD_NAMES[rng.randi() % CHILD_NAMES.size()]


static func _range(rng: RandomNumberGenerator, r: Vector2) -> float:
	return rng.randf_range(r.x, r.y)


## „Annas Schal“, aber „Hans' Schal“.
static func _genitive(guest_name: String) -> String:
	var last := guest_name.right(1).to_lower()
	return guest_name + ("'" if last in ["s", "x", "z", "ß"] else "s")
