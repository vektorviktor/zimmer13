class_name GuestProfiles
## Die Hotelgäste: Persönlichkeit, Vorrat, Handel und Sätze (Spielkonzept 6).
##   brave  – wie schnell sie in Panik geraten (0 = sehr ängstlich)
##   greed  – wie schnell sie klauen, wenn sie dich nicht mögen
##   gossip – wie stark sich Gerüchte über dich bei ihnen verbreiten
##   sell / buy – Preisfaktor beim Verkaufen an dich / Ankaufen von dir
##   money  – Bargeld (für Handel und Einsätze)
##   dice   – Mäxchen: likes (Lieblingsspiel), honesty (sagt die Wahrheit, wenn möglich),
##            jump (wie weit beim Bluffen überboten wird), perception (durchschaut Bluffs
##            und Schummeleien), pride (gekränkt, wenn er verliert), tell (verräterische Geste)
##   reliable – wie zuverlässig sie von Spuren berichten (Rest: verwechselt, erfunden, übertrieben)
##   shock  – Schreckreaktion (flee, freeze, cry; erzeugte Gäste: nach Charakter, Guest.SHOCK_STYLES)
##   report   – wie sie davon erzählen (%s = was, %s = wo)
##   clothing – was von ihnen zurückbleibt, wenn sie verschwinden
##   sex / gen – Geschlecht und Generation (young, mid, old) wie bei erzeugten Gästen – für ihre Stimme (Guest.voice)

const ALL := {
	"edna": {
		"name": "Edna", "room": "0111", "sex": "f", "gen": "old",
		"coat": Color(0.42, 0.28, 0.48), "pants": Color(0.2, 0.18, 0.22), "hair": Color(0.82, 0.82, 0.84),
		"brave": 0.2, "greed": 0.15, "gossip": 0.5, "sell": 1.0, "buy": 0.6,
		"harvester": false, "carver": false,
		"likes": [Item.Kind.CANDLE, Item.Kind.LEAVES],
		"stock": {Item.Kind.CANDLE: 4, Item.Kind.COBWEB: 1, Item.Kind.SWEETS: 2, Item.Kind.MINI_PUMPKIN: 1},   # Süßigkeiten für die Kinder (6.13)
		"start_deco": [Item.Kind.CANDLE, Item.Kind.LEAVES],
		"activities": {"room": 3.0, "lobby": 4.0, "kitchen": 2.0, "garden": 0.5, "wander": 0.5, "bar": 0.7},
		"money": 12,
		"reliable": 0.5, "clothing": "Ednas Strickschal", "shock": "flee",
		"report": "Ich habe %s gesehen … bei %s. Glaube ich. Oder habe ich das geträumt?",
		"dice": {"likes": false, "honesty": 0.9, "jump": 1, "perception": 0.15, "pride": 0.1, "tell": "Edna kichert nervös und schaut weg."},
		"chess": {"likes": true, "skill": 0.6, "pride": 0.1},
		"lines": {
			"greet_friend": ["Ach, du bist es! Schön, ein freundliches Gesicht zu sehen."],
			"greet": ["Oh! Du hast mich erschreckt.", "Guten Abend … falls es Abend ist. Die Uhren hier stehen alle."],
			"greet_enemy": ["Was willst du denn noch?"],
			"smalltalk": ["Ich wohne seit Jahren jeden Oktober hier. Aber so still war es noch nie.", "Kerzen beruhigen mich. Ich habe immer welche dabei.", "Früher gab es hier jeden Abend Musik in der Lobby."],
			"monster": ["Ich habe Schritte gehört … im Keller. Dort ist doch niemand!", "Es mag kein Licht, glaube ich. Ich lasse meine Kerzen immer brennen.", "Wenn die Lampen flackern, verstecke ich mich. Sofort.", "Zuckt das Licht nur kurz, sieht es sich bloß um. Aber wenn es lange flackert … dann hat es Hunger.", "Hörst du das Rauschen auch? Je lauter es wird, desto näher ist es."],
			"odd": ["Die Uhren hier stehen alle still. Seltsam, nicht?", "Ich freue mich so auf Halloween! Dieses Jahr schmücke ich meine Tür besonders schön.", "Hast du den Keller gesehen? Ich gehe da nicht hinunter. Zu staubig."],
			"knock": ["Mach auf! Bitte, mach auf!", "Es ist hinter mir! Lass mich rein!"],
			"sheltered": ["Danke … danke. Ich bleibe nur kurz, versprochen."],
			"phone_warn": ["Hier ist Edna … ich flüstere, entschuldige. Es ist {where}. Bleib in deinem Zimmer, Kind."],
			"left_outside": ["Du hast mich einfach draußen stehen lassen …"],
			"insult": ["Wie unhöflich!", "So etwas muss ich mir nicht anhören."],
			"thanks": ["Oh, wie lieb von dir!", "Das hätte es nicht gebraucht … danke!"],
			"thanks_like": ["Eine Kerze! Du weißt, was mir gefällt."],
			"give_deco": ["Hier, nimm das. Pass auf dich auf, Kind."],
			"refuse_deco": ["Ich brauche meine Sachen selbst … noch kenne ich dich kaum."],
			"panic": ["Es war hier! Ich habe es gesehen! Lass mich in Ruhe!"],
			"calm": ["Danke … ja. Ich atme. Ein … aus …"],
			"party_yes": ["Eine Feier? Wie früher! Ich komme gern."],
			"party_no": ["Feiern? Mit dir? Lieber nicht."],
			"caught": ["He! Das gehört mir! Das hätte ich nie von dir gedacht!"],
			"missing": ["Jemand hat meine Deko vor der Tür genommen … warst du das?"],
			"dice_yes": ["Würfeln? Na gut, aber sei nett zu einer alten Dame."],
			"dice_no": ["Ach nein, heute nicht."],
			"dice_win": ["Oh! Ich habe gewonnen? Wie aufregend!"],
			"dice_lose": ["Das war ein schönes Spiel, danke dir."],
			"challenge": ["Hättest du Lust auf eine Runde Würfeln an der Bar? Ganz gemütlich."],
			"caught_cheat": ["Du … du hast geschummelt! Das tut weh."],
			"patronized": ["Du hast mich gewinnen lassen. Ich bin alt, nicht dumm."],
			"chess_yes": ["Schach! Mein seliger Mann hat es mir beigebracht. Ich nehme Schwarz."],
			"chess_no": ["Heute nicht, Liebes. Mir schwirrt der Kopf."],
			"chess_win": ["Matt! Ach, das hat mein Mann immer gehasst."],
			"chess_lose": ["Sehr schön gespielt. Du hast Geduld, das mag ich."],
			"chess_challenge": ["Spielst du Schach? In der Lobby steht ein Brett. Ganz gemütlich."],
		},
	},
	"bruno": {
		"name": "Bruno", "room": "0112", "sex": "m", "gen": "mid",
		"coat": Color(0.3, 0.25, 0.18), "pants": Color(0.15, 0.15, 0.17), "hair": Color(0.15, 0.1, 0.08),
		"brave": 0.8, "greed": 0.9, "gossip": 0.2, "sell": 1.5, "buy": 0.5,
		"harvester": true, "carver": false,
		"likes": [Item.Kind.CARVED_PUMPKIN, Item.Kind.KNIFE],
		"stock": {Item.Kind.PUMPKIN: 2, Item.Kind.CARVED_PUMPKIN: 1, Item.Kind.LEAVES: 3, Item.Kind.SWEETS: 3, Item.Kind.LIGHT_STRING: 2, Item.Kind.SKULL: 1},
		"start_deco": [Item.Kind.CARVED_PUMPKIN],
		"activities": {"room": 3.0, "lobby": 2.0, "kitchen": 1.0, "garden": 2.0, "wander": 1.0, "bar": 3.0},
		"money": 30,
		"reliable": 0.9, "clothing": "Brunos Hut", "shock": "freeze",
		"report": "Da waren %s, bei %s. Na und? Wahrscheinlich nur Dreck.",
		"dice": {"likes": true, "honesty": 0.45, "jump": 2, "perception": 0.35, "pride": 0.85, "tell": "Bruno zieht den Mundwinkel hoch."},
		"chess": {"likes": false, "skill": 0.35, "pride": 0.85},
		"lines": {
			"greet_friend": ["Na, Partner. Was brauchst du?"],
			"greet": ["Hm. Was gibt's?", "Mach's kurz."],
			"greet_enemy": ["Verschwinde, bevor ich ungemütlich werde."],
			"smalltalk": ["Alles hat seinen Preis. Auch hier drin.", "Ich hole mir die Kürbisse aus dem Garten, bevor es die anderen tun.", "Die Lobbytür kriegst du nicht auf. Hab's versucht."],
			"monster": ["Das Ding schläft im Keller. Wenn's ruhig ist, ist es dort unten.", "Starr es bloß nicht an. Dann weiß es Bescheid.", "Wenn es dich in einen Schrank springen sieht, bist du erledigt.", "Folg den nassen Spuren nicht. Die sind frisch, wenn sie glänzen."],
			"odd": ["Für die Halloween-Woche zahlt man hier ein Vermögen. Da will ich auch was davon haben.", "Der Hausmeister ist nie da. Wer schraubt eigentlich die Birnen rein?", "Ruhig hier. Gefällt mir."],
			"knock": ["Aufmachen! Sofort!", "Mach die verdammte Tür auf!"],
			"sheltered": ["Hm. Danke. Erzähl's keinem."],
			"phone_warn": ["Bruno hier. Kurz und knapp: Es ist {where}. Und ich hab dich nicht angerufen, klar?"],
			"left_outside": ["Das vergess ich dir nicht. Du hast mich draußen gelassen."],
			"insult": ["Pass auf, was du sagst.", "Das merk ich mir."],
			"thanks": ["Hm. Nicht schlecht.", "Gutes Geschäft – für mich."],
			"thanks_like": ["Jetzt reden wir! Das ist was wert."],
			"give_deco": ["Hier. Aber erzähl's nicht rum."],
			"refuse_deco": ["Umsonst? Ich bin doch nicht die Wohlfahrt."],
			"panic": ["Bleib weg! Jeder ist sich selbst der Nächste!"],
			"calm": ["Schon gut. Schon gut … ich hab's im Griff."],
			"party_yes": ["Wenn's Getränke gibt."],
			"party_no": ["Mit dir? Nee."],
			"caught": ["Finger weg von meinem Zeug! Das kriegst du zurück, verlass dich drauf!"],
			"missing": ["Irgendwer bedient sich an meiner Deko. Wenn ich den erwische …"],
			"dice_yes": ["Mäxchen? Dann leg was auf den Tisch."],
			"dice_no": ["Mit dir würfle ich nicht."],
			"dice_win": ["Ha! Das Haus gewinnt immer."],
			"dice_lose": ["Glück gehabt. Das nächste Mal nicht."],
			"challenge": ["Revanche! Bar. Jetzt.", "Na, Lust, dein Geld loszuwerden? Mäxchen an der Bar."],
			"caught_cheat": ["Gezinkte Würfel?! Der Pott gehört mir – und das vergess ich dir nicht!"],
			"patronized": ["Willst du mich verarschen? Ich brauch keine Almosen."],
			"chess_yes": ["Schach. Meinetwegen. Aber nur mit Einsatz."],
			"chess_no": ["Schach ist was für Leute mit zu viel Zeit."],
			"chess_win": ["Matt. Hab ich doch gesagt."],
			"chess_lose": ["Pff. Dein Läufer stand da nur aus Zufall."],
			"chess_challenge": ["Revanche. Schachbrett. Lobby. Jetzt."],
		},
	},
	"mila": {
		"name": "Mila", "room": "0115", "sex": "f", "gen": "young",
		"coat": Color(0.2, 0.45, 0.4), "pants": Color(0.25, 0.2, 0.3), "hair": Color(0.55, 0.2, 0.1),
		"brave": 0.5, "greed": 0.4, "gossip": 0.9, "sell": 1.1, "buy": 0.8,
		"harvester": true, "carver": true,
		"likes": [Item.Kind.PUMPKIN, Item.Kind.COBWEB],
		"stock": {Item.Kind.CARVED_PUMPKIN: 2, Item.Kind.PUMPKIN: 1, Item.Kind.SHEET_GHOST: 1, Item.Kind.MINI_PUMPKIN: 2, Item.Kind.BAT_GARLAND: 1},
		"start_deco": [Item.Kind.CARVED_PUMPKIN, Item.Kind.SHEET_GHOST],
		"activities": {"room": 2.0, "lobby": 3.0, "kitchen": 1.0, "garden": 3.0, "wander": 1.0, "bar": 1.5},
		"money": 8,
		"reliable": 0.65, "clothing": "Milas Halstuch", "shock": "cry",
		"report": "Ich schwör's dir: %s, bei %s! Riesig! Überall!",
		"dice": {"likes": true, "honesty": 0.6, "jump": 1, "perception": 0.55, "pride": 0.4, "tell": "Mila spielt auffällig mit einer Haarsträhne."},
		"chess": {"likes": true, "skill": 0.85, "pride": 0.4},
		"lines": {
			"greet_friend": ["Hey du! Ich hab gerade einen neuen Kürbis geschnitzt – willst du sehen?"],
			"greet": ["Oh, hi! Bist du auch hier gestrandet?", "Hallo! Hast du schon gehört, was Edna erzählt?"],
			"greet_enemy": ["Ah. Du. Alle wissen, was du getan hast."],
			"smalltalk": ["Ich schnitze Kürbisse, seit ich klein bin. Mit Messer aus der Küche geht's am besten.", "Bruno ist ein Geizhals, aber er hat immer Kürbisse.", "Im Garten wachsen die Kürbisse nach. Man muss nur schneller sein als Bruno."],
			"monster": ["Ich glaube, Gerede lockt es an. Je mehr wir darüber reden, desto frecher wird es.", "In der Wäscherei hängen Spinnweben. Die hält es angeblich auch fern.", "Es kriecht durch die dunklen Zimmer. Zimmer 0117 ist schon lange verlassen …", "Hast du die Zettel gefunden? Da waren schon andere vor uns hier.", "Verlass dich nicht auf ein kurzes Flackern. Ich glaube, manchmal lügt es."],
			"odd": ["Ich mache die beste Halloween-Deko im ganzen Hotel. Wetten?", "Zimmer 0117 steht leer, seit ich hier bin. Ob da jemand ausgezogen ist?", "Wir sollten bald eine richtige Party feiern! Mit Musik und allem!"],
			"knock": ["Bitte! Mach auf, es kommt!", "Hilfe! Lass mich rein!"],
			"sheltered": ["Okay … okay. Danke. Ich zittere total."],
			"phone_warn": ["Ich bin's, Mila! Es ist {where}, ich hab's gerade gesehen! Geh da bloß nicht hin!"],
			"left_outside": ["Du hast mich nicht reingelassen. Das erzähl ich allen."],
			"insult": ["Wow. Okay.", "Das erzähl ich weiter, nur damit du's weißt."],
			"thanks": ["Für mich? Wie süß!", "Danke! Das kann ich gut gebrauchen."],
			"thanks_like": ["Perfekt, daraus mach ich was Gruseliges!"],
			"give_deco": ["Nimm den hier – frisch geschnitzt!"],
			"refuse_deco": ["Meine Kürbisse verschenke ich nur an Freunde."],
			"panic": ["Nicht jetzt! Ich muss mich verstecken!"],
			"calm": ["Okay … okay. Danke, dass du da bist."],
			"party_yes": ["Party?! Ich bin dabei!"],
			"party_no": ["Ohne mich."],
			"caught": ["Hey! Das ist meiner! Das erfahren alle!"],
			"missing": ["Mein Kürbis vor der Tür ist weg! Wer macht denn so was?"],
			"dice_yes": ["Oh ja! Ich durchschau dich sowieso."],
			"dice_no": ["Nee, ich hab grad keinen Kopf dafür."],
			"dice_win": ["Ich hab dir angesehen, dass du blöffst!"],
			"dice_lose": ["Okay, okay, du bist gut. Nochmal irgendwann!"],
			"challenge": ["Hey! Mäxchen an der Bar? Ich will wissen, wie gut du lügst."],
			"caught_cheat": ["Schummler! Das erzähl ich allen!"],
			"patronized": ["Haha, sehr witzig. Du hast extra verloren, oder?"],
			"chess_yes": ["Schach? Oh ja! Ich war im Schachclub, nur damit du's weißt."],
			"chess_no": ["Nee, nicht jetzt – ich kann mich grad nicht konzentrieren."],
			"chess_win": ["Matt! Hab ich dir doch gesagt – Schachclub!"],
			"chess_lose": ["Wow. Okay. Revanche, irgendwann. Ehrlich, gut gespielt!"],
			"chess_challenge": ["Hey! Lust auf Schach in der Lobby? Ich will sehen, wie du denkst."],
		},
	},
}


## Zufällig erzeugte Gäste dieser Partie (ID → Profil), siehe GuestGenerator.
static var generated := {}


## Profil eines Gastes – handgeschrieben oder erzeugt; {} wenn unbekannt.
static func get_profile(id: String) -> Dictionary:
	if ALL.has(id):
		return ALL[id]
	return generated.get(id, {})


static func line(profile: Dictionary, key: String) -> String:
	var lines: Dictionary = profile["lines"]
	var options: Array = lines.get(key, ["…"])
	return options[randi() % options.size()]
