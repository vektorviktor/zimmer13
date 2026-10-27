class_name Social
extends Node
## Das soziale Gefüge im Hotel (Spielkonzept 6 + 7.1): Gäste, Beziehungen, Gerüchte,
## Diebstahl (mit Zeugen), Panik, Tod & Schock, Gedenken und Feiern im Partyraum.
## Dazu (4.13): Gäste berichten von Spuren – nicht immer zuverlässig – und klopfen nachts
## an Zimmer 13. Manchmal klopft auch etwas anderes …
## Freundschaft und Feindschaft in neun Stufen (6.3): Die Extreme brauchen Taten (Spiele, Austausch bzw.
## Klauen, Beleidigen, Rammen, Schlagen und Rache); gute Freunde besuchen dich, Erzfeinde schlagen zu.
## Kinder (6.13): kommen mit Mama oder Papa (Zimmer nebenan), petzen, klopfen zu „Süßes oder Saures“ an Zimmer 13,
## kommen immer zu Feiern und vergessen schnell – im Guten wie im Schlechten.

## Freundschaftsstufen (Spielkonzept 6.3), vom schlechtesten zum besten
enum Tier { STRONG_ENEMY, ENEMY, ANGRY, ANNOYED, NEUTRAL, NICE, FRIENDLY, FRIEND, GOOD_FRIEND }
const TIER_NAMES := ["stark verfeindet", "verfeindet", "wütend", "genervt", "neutral", "nett", "freundlich",
	"befreundet", "guter Freund"]
## Bedingungen für die Extreme: so viele Taten (Guest.deeds)
const BOND_GAMES := 3
const BOND_GIFTS_TO := 2
const BOND_GIFTS_FROM := 1
const FEUD_HOSTILE := 4
const FEUD_REVENGE := 1
## Ohne Kontakt wandern die Extreme zurück – so viele Punkte pro Sekunde (1,2 je Spieltag, 2.4)
const DRIFT := 1.2 / Calendar.DAY_SECONDS
## Gute Freunde besuchen Zimmer 13 (Abstand zwischen zwei Besuchen), Erzfeinde lauern dir auf
const VISIT_COOLDOWN := Vector2(240.0, 480.0)
const ATTACK_COOLDOWN := Vector2(120.0, 200.0)
const VISIT_LINES := ["Ich bin's. Hast du kurz Zeit?", "Klopf, klopf – ich bin's nur. Lässt du mich rein?",
	"Ich hab mich gelangweilt. Darf ich reinkommen?"]
const VISIT_HELLO := ["Schön hast du's hier. Na ja – für Zimmer 13.", "Ich bleib nur kurz. Erzähl mal, wie geht's dir?",
	"Endlich jemand, mit dem man reden kann."]
const THREAT_LINES := ["Komm mir nicht zu nahe. Ich warne dich.", "Noch einmal, und du wirst es bereuen.",
	"Pass auf, wo du langgehst. Hier ist es dunkel."]
const ATTACK_LINES := ["Jetzt reicht's!", "Das hast du verdient!", "Hier sieht dich keiner …"]

const PARTY_DURATION := 90.0
const PARTY_COOLDOWN := 240.0
## Klopfen an Zimmer 13
const KNOCK_COOLDOWN := Vector2(120.0, 240.0)
const KNOCK_WAIT := 10.0          ## so lange klopft es, bevor es still wird
const FAKE_KNOCK_CHANCE := 0.3
const HIDE_MONSTER_DISTANCE := 8.0  ## Verstecke so nah am Monster meiden Gäste
const BELL_DELAY := 3.0             ## so lange nach einem Tod läutet die Totenglocke
## Gäste: zum Start so viele, und nie dauerhaft weniger als MIN_GUESTS Lebende –
## nach einem Todesfall wacht irgendwann ein neuer Gast in einem freien Zimmer auf.
const START_GUESTS := 67
const MIN_GUESTS := 33
## Kinder (Spielkonzept 6.13): so viele der START_GUESTS, jedes mit einem erzeugten Erwachsenen als Mama oder
## Papa; ihre Beziehung wandert so viel schneller zur Mitte (überall, nicht nur an den Extremen); Süßes oder
## Saures: Abstand zwischen zwei Besuchen an Zimmer 13, so lange wartet das Kind an der offenen Tür
const CHILDREN := 13
## Eine Tür je Haushalt (Spielkonzept 6.20): so viel Startdeko hängt höchstens an ihr; so weit stehen Mitbewohner
## beim Einzug auseinander
const HOUSEHOLD_START_DECO := 3
var _spot_rooms := {}   ## Versteck → Zimmernummer (spot_room)
const SPAWN_SPACING := 0.6
const CHILD_DRIFT := 4.0
const TRICK_COOLDOWN := Vector2(100.0, 220.0)
const TRICK_WAIT := 15.0
## Süßigkeiten an der Tür: höchstens so viele je Besuch, so viel Beziehung bringt die erste, zweite, dritte (je mehr,
## desto mehr – zusammen 21); nach einer Süßigkeit wartet es noch so lange auf die nächste
const TRICK_SWEETS_MAX := 3
const TREAT_RELATION := [5.0, 7.0, 9.0]
const TRICK_MORE_WAIT := 8.0
const TREAT_LINES := ["Danke!", "Noch eins? Juhu!", "Drei! Danke, danke, danke!"]
## Mit einem Wurf getroffen (Spielkonzept 3.13): so viel weniger mag dich der Gast – mit Kürbis, Kerze, Tasse (was
## zerplatzt oder zerbricht) stärker
const THROWN_AT := -6.0
const THROWN_AT_MESSY := -12.0
## Lärm vor der Tür (Spielkonzept 4.15, 6.2): Lautes ab NOISE_ANNOY_MIN m Hörweite, das der Spieler höchstens
## NOISE_ANNOY_REACH m vor einer Zimmertür macht, ärgert alle, die drin sind – schlafend doppelt. Je Gast nur alle
## NOISE_ANNOY_QUIET s, sonst kostet einmal Vorbeirennen mehrfach. Klopfen, Tür auf/zu und Schlüssel sind höflich
## bzw. alltäglich, Aufbrechen und Schlagen haben eigene Folgen; ist das Monster hinter dem Spieler her, zählt es nicht.
const NOISE_ANNOY_MIN := 4.0
const NOISE_ANNOY_REACH := 4.0
const NOISE_ANNOY := -3.0
const NOISE_ANNOY_ASLEEP := -6.0
const NOISE_ANNOY_QUIET := 30.0
const NOISE_POLITE := ["knock", "door", "unlock", "keys", "door_force", "punch"]
## Was sie durch die Tür rufen – nicht in GuestGenerator.COMMON (verschöbe die Zufallsfolge); feste Gäste können
## eigene unter demselben Schlüssel in ihren lines haben
const NOISE_LINES := {
	"noise": ["Ruhe da draußen!", "Geht's vielleicht auch leiser?", "Muss das ausgerechnet vor meiner Tür sein?"],
	"noise_night": ["Es ist mitten in der Nacht!", "Manche Leute wollen hier schlafen!"],
}
## Von Tür zu Tür (Spielkonzept 6.13): so oft zieht ein Kind los, zu so vielen Türen, so lange klopft es
const ROUND_COOLDOWN := Vector2(45.0, 110.0)
const ROUND_DOORS := 3
const ROUND_RANGE := 60.0
const ROUND_KNOCK_EVERY := 2.2
const ROUND_WAIT := 9.0
const TRICK_GIVE := 0.6             ## so oft gibt ein Erwachsener Süßes (Griesgram: TRICK_GIVE_GRUMPY)
const TRICK_GIVE_GRUMPY := 0.2
const TRICK_GIVE_LINES := ["Na, ihr kleinen Gespenster – hier, nehmt!", "Süßes, natürlich! Aber nicht alles auf einmal essen.",
	"Oh, wie schaurig! Hier, für dich.", "Moment … ja, ich hab noch was. Hier."]
const TRICK_SCOLD_LINES := ["Es ist spät, geh zu deinen Eltern!", "Nichts da. Ab mit dir!", "Süßes? Hier gibt's nichts. Husch!"]
const ARRIVAL_DELAY := Vector2(150.0, 360.0)
const TRACE_TEXT := {
	"footprint": "nasse Fußspuren", "scratch": "Kratzspuren", "blood": "Blut",
	"handprint": "einen Handabdruck an einer Tür", "drops": "Blutstropfen",
}
## Eigene Erlebnisse (Spielkonzept 6.12): was ein Gast beim nächsten Gespräch erzählt – je nach seiner
## Schreckreaktion (Guest.shock_style). {zone} = Ort, {who} = der Tote.
const EXPERIENCE_LINES := {
	"flee": {
		"blood": ["Da war Blut! Eine riesige Lache, bei {zone}! Ich bin nur noch gerannt!", "Bei {zone} … überall Blut. Ich hab geschrien und bin weg. Geh da nicht hin!"],
		"corpse": ["{who} … liegt bei {zone}. Ganz still. Die Augen offen! Ich bin weggerannt, ich konnte nicht …", "Ich habe {who} gefunden. Tot! Bei {zone}! Bitte sag mir, dass ich das geträumt habe."],
		"ghost": ["Vor meinem Fenster! Ein Laken, das schwebt – mit Händen! Ich bin sofort raus!", "Da war etwas am Fenster, bei {zone}. Weiß, mit blutigen Händen. Ich lass nie wieder den Vorhang offen!"],
		"ghost_attack": ["Es kam DURCH das Fenster! Kalte Hände an meinem Hals! Ich hab mich losgerissen und bin gerannt …", "Das Laken … es wollte mich erwürgen! Bei {zone}! Schau, die Striemen!"],
		"pumpkin": ["Ein Mann mit einem KÜRBIS als Kopf! Und einer Axt! Bei {zone}! Ich bin nur gerannt!", "Er kam auf uns zu, bei {zone} – Kürbiskopf, blutige Axt. Feier nicht mehr, hörst du?"],
	},
	"freeze": {
		"blood": ["Bei {zone} ist eine Blutlache. Ich stand bestimmt eine Minute davor und konnte mich nicht rühren.", "Ich hab das Blut bei {zone} gesehen. Viel zu viel. Da hat niemand überlebt."],
		"corpse": ["{who} liegt tot bei {zone}. Ich stand nur da. Ich wusste nicht, was ich tun soll.", "Ich habe {who} gefunden. Bei {zone}. Kein Kratzer – aber tot. Das war nicht das Ding aus dem Keller."],
		"ghost": ["Draußen vor dem Fenster schwebte ein Laken. Ich hab nur gestarrt. Es hat mich angesehen, glaube ich.", "Etwas am Fenster bei {zone}. Hat die Hände kreisen lassen. Ich konnte nicht wegsehen."],
		"ghost_attack": ["Dieses Laken hat mich am Hals gepackt. Ich weiß nicht, wie ich freigekommen bin. Mach nie das Licht aus.", "Es war im Zimmer. Bei {zone}. Ich lebe noch, aber frag mich nicht, warum."],
		"pumpkin": ["Bei {zone} stand einer mit einem Kürbis auf den Schultern. Und einer Axt. Ich konnte mich nicht rühren.", "Der Kürbiskopf hat mich angesehen. Ich glaube, er hat gegrinst. Der Kürbis, meine ich."],
	},
	"cry": {
		"blood": ["*schnieft* Bei {zone} … so viel Blut. Wer war das? Wer fehlt?", "Ich hab das Blut gesehen, bei {zone}. Ich musste so weinen … wer kann denn so etwas tun?"],
		"corpse": ["*weint* {who} … liegt da bei {zone}. Wir haben doch erst gestern zusammen gelacht.", "Ich habe {who} gefunden. *schluchzt* Kannst du … kannst du eine Kerze für {who} anzünden?"],
		"ghost": ["*zittert* Vor meinem Fenster war ein Geist. Ein richtiger! Ich kann gar nicht mehr aufhören zu weinen.", "Bei {zone}, am Fenster … ein Laken mit Händen. Ich kann seitdem nicht aufhören zu zittern."],
		"ghost_attack": ["*weint* Es hat mich gewürgt! Ich dachte, jetzt ist es vorbei … ich will nach Hause!", "Ich hab mich losgerissen, irgendwie … *schluchzt* Bitte bleib heute nicht allein im Dunkeln."],
		"pumpkin": ["*schluchzt* Wir haben doch nur gefeiert … und dann kam er. Mit der Axt. Bei {zone}.", "Ein Kürbis … wo ein Kopf sein sollte. *weint* Ich will nie wieder Musik hören."],
	},
	"cling": {
		"blood": ["Da war ganz viel Blut! Bei {zone}! Ich hab geschrien, so laut ich konnte!", "Bei {zone} ist alles rot. Ist da wer hingefallen?"],
		"corpse": ["{who} liegt bei {zone} und wacht nicht auf. Ich hab gerufen und gerufen …", "Warum schläft {who} auf dem Boden? Bei {zone}. Die Augen sind offen …"],
		"ghost": ["Am Fenster war ein Gespenst! Ein echtes, mit Händen! Aber keiner glaubt mir!", "Ein Laken ist geflogen, draußen vor dem Fenster! Ehrlich! Es hat mit den Händen so gemacht …"],
		"ghost_attack": ["Das Gespenst ist reingekommen und hat nach mir gegriffen! Ich hab ganz laut geschrien, und dann war es weg!", "Es war in meinem Zimmer! Ganz kalte Hände! {eltern} sagt, ich hab geträumt."],
		"monster": ["Ich hab das Monster gesehen! Ganz lang und dünn, mit einer Zunge! Es hat mich angeguckt und ist weitergegangen!", "Bei {zone} war das Monster! Ich lüg nicht! Warum glaubt mir denn keiner?"],
		"pumpkin": ["Da war ein Mann mit einem Kürbiskopf! Mit einer Axt! Bei {zone}! Er ist hinter uns hergerannt!", "Der Kürbismann! Der will kein Süßes, der will … *weint*"],
	},
}
## Was Erwachsene erzählen, wenn ein Kind ihnen etwas Schreckliches berichtet hat (6.13: niemand glaubt ihnen)
const CHILD_SAW_LINES := [
	"{who} erzählt jedem, bei {zone} wäre ein Monster gewesen. Kinder und ihre Fantasie … aber das Kind zittert immer noch.",
	"{who} hat geschrien wie am Spieß. Angeblich ein Gespenst. Wahrscheinlich ein Vorhang im Wind.",
	"Hast du {who} gehört? Bei {zone} soll etwas gewesen sein. Ich sag dir, die Kleinen schauen zu viele Gruselfilme.",
]
## Später am selben Tag, beim Reden über das Monster
## Grollen vor einem Angriff (Puppe, 5.5): so viel Angst je Durchgang (× Lautstärke × (1,2 − Mut)), ab dieser Lautstärke
## löst sich eine Feier auf; was Gäste dabei sagen, und was sie später erzählen
const RUMBLE_FEAR := 12.0
const RUMBLE_PARTY_END := 0.5
const RUMBLE_TALK_CHANCE := 0.3   ## so oft hört das Monster mit (on_monster_talk)
const RUMBLE_LINES := ["Hört ihr das? Dieses Grollen …", "Das kommt von unten. Aus dem Keller.", "Es wird lauter. Ich geh lieber rein.",
	"Wo ist die Puppe? Hat jemand die Puppe gesehen?", "So hat es letztes Mal auch angefangen …", "Schließt eure Türen ab. Bitte."]
const RUMBLE_STORIES := ["Hast du das Grollen gehört? Ganz tief unten im Haus.", "Jedes Mal, bevor es kommt, grollt das ganze Hotel.",
	"Ich hab die Puppe vor einer Tür sitzen sehen – und dann ging das Grollen los.", "Beim Grollen bleib ich in meinem Zimmer. Tür zu, Licht an."]
const EXPERIENCE_AGAIN := {
	"rumble": "Dieses Grollen … ich hör es immer noch, wenn es still ist.",
	"blood": "Ich bekomme die Blutlache bei {zone} nicht aus dem Kopf.",
	"corpse": "Ich sehe {who} immer noch da liegen. Bei {zone}.",
	"ghost": "Ich trau mich nicht mehr ans Fenster. Seit dem Laken.",
	"ghost_attack": "Mein Hals tut immer noch weh. Ich mache das Licht nie wieder aus.",
	"monster": "Ich hab das Monster echt gesehen. Ehrlich!",
	"pumpkin": "Ich höre immer noch seine Schritte. Und die Axt, wie sie über den Boden schleift.",
	"child_saw": "{who} redet immer noch von diesem Monster. Kinder …",
}
## Gerüchte über Gehörtes (4.15): was man gehört hat, und wie man davon erzählt
const HEARD_TEXT := {
	"scream": "Jemand hat geschrien", "death_scream": "Jemand hat geschrien – und dann war es still", "door_burst": "Eine Tür ist aufgeflogen, mit einem Knall",
	"hide_burst": "Ein Schrank ist aufgerissen worden", "bulb_burst": "Eine Glühbirne ist geplatzt",
	"cat_cry": "Eine Katze hat jämmerlich geweint", "axe_swing": "Etwas hat durch die Luft gesaust, dann ein dumpfer Schlag",
	"pumpkin_land": "Etwas Schweres ist vom Dach gefallen", "elevator_alarm": "Im Aufzug hat jemand Alarm geläutet",
}
const HEARD_LINES := [
	"Hast du das auch gehört? %s – bei %s.",
	"%s. Bei %s. Ich hab's genau gehört.",
	"Da war was. %s, irgendwo bei %s.",
]
## Zettel, die Gäste hinterlassen ({name}, {room}, {dead}, {zone})
const DEATH_NOTES := [
	"{dead} ist fort. Ich habe den Schrei gehört. Wer das liest: Bleibt nicht allein im Flur.\n– {name}",
	"Für {dead}. Wir zünden eine Kerze an, wenn es ruhig ist. Lobby.\n– {name}",
	"Es hat {dead} geholt. Ich schließe ab und mache nicht mehr auf. Für niemanden.\n– {name}, Zimmer {room}",
	"Klopft dreimal, wenn ihr es seid. Sonst bleibt die Tür zu.\n– {name}, Zimmer {room}",
	"Wer hat {dead} zuletzt gesehen? Bitte meldet euch. Zimmer {room}.\n– {name}",
]
const SIGHT_NOTES := [
	"Ich habe es gesehen. Hier. ({zone})\nKommt nicht allein hierher.\n– {name}",
	"Es stand am Ende des Flurs und hat mich angesehen. {zone}. Ich schwöre es.\n– {name}",
	"Nicht rennen. Nicht hinsehen. Verstecken.\n– {name}",
]
## Dieselben, wenn er den Namen Leviathan kennt (Spielkonzept 4.32)
const SIGHT_NOTES_NAMED := [
	"Ich habe den Leviathan gesehen. Hier. ({zone})\nKommt nicht allein hierher.\n– {name}",
	"Der Leviathan stand am Ende des Flurs und hat mich angesehen. {zone}. Ich schwöre es.\n– {name}",
	"Nicht rennen. Nicht hinsehen. Verstecken.\n– {name}",
]
const DOOR_NOTES := [
	"Bitte nicht stören.\n– {name}",
	"Tausche Kerzen gegen Kürbisse. Einfach klopfen.\n– {name}, Zimmer {room}",
	"Wer meine Deko anfasst, bekommt Ärger.\n– {name}",
	"Bin in der Lobby. Oder an der Bar. Oder schlafe.\n– {name}",
	"Halloween-Feier? Ich bin dabei!\n– {name}, Zimmer {room}",
]
const MAX_GUEST_NOTES := 30
## Nachtruhe (Spielkonzept 2.4, 4.18): jeden Tag etwa 23–6 Uhr schlafen alle Gäste in ihren Betten, das Licht ist
## aus – dann kommt der Lakengeist auch in den Flur. Beginn und Ende streuen je Nacht um bis zu SLEEP_JITTER Stunden.
const SLEEP_START := 23.0
const SLEEP_END := 6.0
const SLEEP_JITTER := 0.5
## Fremdes Bett (Spielkonzept 3.6): So oft hält ein guter Freund Wache, statt sich woanders hinzulegen; so viel kostet
## es, wenn ein Gast dich wecken muss (beim Hinauswerfen noch BED_EVICT), so viele Münzen klaut ein Feind im Schlaf
const BED_GUARD_CHANCE := 0.5
const BED_ANNOY := -8.0
const BED_EVICT := -4.0
const BED_ROB := Vector2i(3, 8)
## Gäste wecken (Spielkonzept 3.6): mit gutem Grund (echte Gefahr) dankbar und WAKE_ALERT s wach (Zeuge gegen den
## Geist), ohne Grund verärgert (Freunde weniger) und WAKE_GRUMPY s gereizt, er legt sich nach WAKE_BACK s wieder hin.
## Falscher Alarm (Halluzination) kostet mehr – WAKE_DOUBT s lang glaubt er einem Wecken nicht. Gefahr: das Monster
## unterwegs im selben Geschoss oder näher als WAKE_DANGER_RANGE m, eine echte Flackerwelle, Lakengeist, Kürbismann.
const WAKE_THANKS := 6.0
const WAKE_ANNOY := -5.0
const WAKE_ANNOY_FRIEND := -2.0
const WAKE_FALSE := -8.0
const WAKE_ALERT := Vector2(Calendar.HOUR, 2.0 * Calendar.HOUR)
const WAKE_BACK := Vector2(20.0, 40.0)
const WAKE_GRUMPY := 2.0 * Calendar.HOUR
const WAKE_DOUBT := 6.0 * Calendar.HOUR
const WAKE_DANGER_RANGE := 25.0


var guests: Array[Guest] = []
var builder: LevelBuilder
var record_player: RecordPlayer
var decorating: Decorating               ## Schmück-Aktionen (Spielkonzept 5.9)
var pals: GuestPals                      ## Freundschaften unter Gästen (Spielkonzept 6.16)
var pranks: Pranks                      ## Streiche der Kinder (Spielkonzept 6.13)
var access: RoomAccess                  ## Zimmerzugang: Klopfen, Einlass, Hausfriedensbruch (Spielkonzept 6.19)
var tidying: Tidying                    ## Flecken: Beschweren und Putzen (Spielkonzept 6.13)
var search: DecoSearch                   ## Deko-Suche mit Gästen (Spielkonzept 5.9)
var talk: Talk                           ## Erzählen, Lügen, Fragen, Gedächtnis der Gäste (Spielkonzept 6.9)
var requests: GuestRequests              ## Bitten der Gäste (Spielkonzept 6.14)
var grinch: Grinch                       ## Gustav Peters, der „Halloween-Grinch“, und sein Ende (Spielkonzept 2.6)
var party_active := false
var party_host := ""            ## "player" oder Gast-ID

var _party_time := 0.0
var _party_presence := 0.0
var _dance_spots := {}          ## Gast-ID → Index in builder.party_spots (free_party_spot)
var _party_noise := 0.0
var _party_cooldown := 150.0
var _spontaneous_timer := 30.0
var _gossip: Array[Dictionary] = []      ## {delay, amount}
var _thefts := {}                        ## Gast-ID → Zeitpunkt des letzten Diebstahls durch den Spieler
var _noise_annoyed := {}                 ## Gast-ID → Zeitpunkt, an dem ihn zuletzt Lärm vor der Tür geärgert hat
var _reserved := {}                      ## HideSpot → Guest
var _memorial_doors: Array[Vector3] = []
var _check_timer := 0.0
var _time := 0.0
## Minispiele (Spielkonzept 6.10)
var _watched := {}                       ## Gast-ID → du kennst seine Ticks beim Bluffen
var _rematches: Array[Guest] = []
var _challenge_timer := 45.0
var _bar_game := {}                      ## laufende Partie zweier Gäste
var _bar_timer := 25.0
var _chess_watched := {}                 ## Gast-ID → du weißt, wie stark er Schach spielt
var _chess_game := {}                    ## laufende Schachpartie zweier Gäste in der Lobby
var _chess_timer := 40.0
var _darts_watched := {}                 ## Gast-ID → du weißt, wie sicher er Darts wirft
var _dart_game := {}                     ## laufendes Darts zweier Gäste an der Bar
var _dart_timer := 35.0
## Spuren, von denen die Gäste erzählen: {kind, zone, time}
var _reports: Array[Dictionary] = []
## Hotelkatzen (6.11): Gast-ID → Name der Katze, die ihm etwas weggetragen hat; ob schon eine geweint hat
var cat_thefts := {}
## Gast-ID → so viel Beziehung hat er dem Spieler für Deko abgezogen, die eine Katze weggetragen hat (6.11) –
## bekommt der Spieler zurück, sobald er erzählt, wer es war (cat_line)
var cat_blame := {}
var cats_have_cried := false
var sleep_active := false
var night_seed := randi()                ## Streuung der Nachtruhe je Nacht – fest, damit Laden die Nacht nicht verschiebt
## Klopfen an Zimmer 13: {guest, fake, time, opened}
var _knock: Dictionary = {}
var _knock_cooldown := 90.0
var debug_fake_knock := false
var _world: Node3D
var _arrival_timer := -1.0
var _next_guest := 1                     ## laufende Nummer für IDs erzeugter Gäste
var _visit_cooldown := 200.0
var _feud_timer := 2.0
var _trick_cooldown := 240.0
var _trick: Dictionary = {}              ## Süßes oder Saures an der offenen Tür: {guest, time}
var _round_cooldown := 120.0
## Kinder auf Runde von Tür zu Tür: Gast-ID → {kid, doors (Zimmernummern), no, phase, time, next, knocks, host}
var _rounds: Dictionary = {}

const CHESS_LINES := [
	"%s schiebt die Dame vor. %s runzelt die Stirn.",
	"%s: „Schach!“ – %s seufzt.",
	"Es ist still am Schachtisch. %s grübelt, %s trommelt mit den Fingern.",
	"%s schlägt einen Springer. %s murmelt etwas.",
]

const DART_LINES := [
	"%s trifft die Triple-20. %s pfeift anerkennend.",
	"%s: „Ha, Bull!“ – %s verdreht die Augen.",
	"Der Pfeil von %s prallt an der Wand ab. %s lacht.",
	"%s zieht die Pfeile aus der Scheibe. %s rechnet laut nach.",
]

const BAR_LINES := [
	"%s: „Zweiundsechzig!“ – %s: „Glaub ich dir nicht!“",
	"%s knallt den Becher auf den Tisch: „Mäxchen!“ – %s stöhnt.",
	"%s: „Aufdecken!“ – %s lacht laut.",
	"Würfel klappern. %s grinst %s herausfordernd an.",
	"%s: „Einundfünfzig …“ – %s zieht eine Augenbraue hoch.",
]


static func tier_of(value: float) -> Tier:
	if value <= -80.0:
		return Tier.STRONG_ENEMY
	if value <= -55.0:
		return Tier.ENEMY
	if value <= -30.0:
		return Tier.ANGRY
	if value < -10.0:
		return Tier.ANNOYED
	if value < 10.0:
		return Tier.NEUTRAL
	if value < 30.0:
		return Tier.NICE
	if value < 55.0:
		return Tier.FRIENDLY
	if value < 80.0:
		return Tier.FRIEND
	return Tier.GOOD_FRIEND


static func tier(guest: Guest) -> Tier:
	return tier_of(guest.relation)


static func relation_word(value: float) -> String:
	return TIER_NAMES[tier_of(value)]


func _ready() -> void:
	add_to_group("time_skip")   # Zeitsprung im Schlaf (SleepSkip)


func setup(p_builder: LevelBuilder, world: Node3D) -> void:
	builder = p_builder
	_world = world
	GuestProfiles.generated.clear()
	GuestProfiles.placed.clear()
	if not _add_households():   # ohne Haushaltsdatei: die alte Verteilung (jeder für sich, Kinder nebenan)
		for id in GuestProfiles.ALL:
			_spawn(id, true)
		while guests.size() < START_GUESTS - CHILDREN:
			if _add_generated(randi(), "", false) == null:
				break
		_add_families()
	# Manche Gäste haben schon einen Zettel an ihre Tür gelegt
	for guest in guests:
		if randf() < 0.25:
			_leave_note(guest, DOOR_NOTES, (guest.home["door_front"] as Vector3) + (guest.home["into"] as Vector3) * 0.35, "")
	record_player = RecordPlayer.new()
	record_player.position = builder.record_player_pos
	world.add_child(record_player)
	decorating = Decorating.new()   # Schmück-Aktionen (Spielkonzept 5.9)
	decorating.name = "Decorating"
	add_child(decorating)
	decorating.setup(builder)
	pals = GuestPals.new()   # Freundschaften unter Gästen (Spielkonzept 6.16)
	pals.name = "Pals"
	add_child(pals)
	search = DecoSearch.new()   # Deko-Suche (Spielkonzept 5.9)
	search.name = "DecoSearch"
	add_child(search)
	pranks = Pranks.new()   # Streiche der Kinder (Spielkonzept 6.13)
	pranks.name = "Pranks"
	add_child(pranks)
	access = RoomAccess.new()   # Klopfen, Einlass, Hausfriedensbruch (Spielkonzept 6.19)
	access.name = "RoomAccess"
	add_child(access)
	tidying = Tidying.new()   # Flecken: Beschweren und Putzen (6.13)
	tidying.name = "Tidying"
	add_child(tidying)
	talk = Talk.new()   # Erzählen, Lügen, Fragen, Gedächtnis (6.9)
	talk.name = "Talk"
	add_child(talk)
	requests = GuestRequests.new()   # Bitten der Gäste (6.14)
	requests.name = "Requests"
	add_child(requests)
	grinch = Grinch.new()   # Gustav Peters (2.6)
	grinch.name = "Grinch"
	add_child(grinch)
	grinch.setup(builder)


## Gast ins Hotel setzen (Profil muss schon bekannt sein); mit Start-Deko vor der Tür. slot: Platz im Zimmer, wenn
## mehrere dort wohnen (nebeneinander statt übereinander).
func _spawn(id: String, with_deco: bool, slot: int = 0) -> Guest:
	var profile := GuestProfiles.get_profile(id)
	var info: Dictionary = builder.rooms[profile["room"]]
	info["kind"] = "guest"
	var guest := Guest.new().setup(id, info)
	guest.name = "Gast_" + id
	guest.position = (info["center"] as Vector3) + Vector3(0, 0.05, 0) + (info["along"] as Vector3) * SPAWN_SPACING * \
		(slot - (slot % 2) * 2 * slot) * 0.5
	_world.add_child(guest)
	guests.append(guest)
	if with_deco:
		_place_start_deco(guest, profile["start_deco"])
	return guest


func _place_start_deco(guest: Guest, kinds: Array) -> void:
	for kind in kinds:
		var item := guest.stock_item(kind)
		item.owner_id = guest.id
		if item.can_light():
			item.light_up(false)   # die Startdeko brennt schon (Spielkonzept 5.12) – anzünden können Gäste sonst nicht
		item.position = guest.deco_place_point() + Vector3(0, 0.02, 0)
		_world.add_child(item)
		if item.can_hang():
			var spot := guest.door_hang_spot(kind)
			item.hang(spot["point"], spot["out"], float(spot.get("length", 0.0)))
	guest.expected_deco = kinds.size()


## Haushalte (Spielkonzept 6.20): wer mit wem in welchem Zimmer wohnt, steht in HAUSHALTE.md (LevelBuilder.households,
## je Zimmernummer). Kernfiguren behalten ihr eigenes Profil, die übrigen erzeugt der Generator mit fester Identität;
## erst die Erwachsenen, dann die Kinder. false: keine Haushaltsdatei.
func _add_households() -> bool:
	if builder.households.is_empty():
		return false
	for no: String in builder.households:
		var members: Array = builder.households[no]["members"]
		for child in [false, true]:
			for i in members.size():
				if bool(members[i].get("child", false)) == child:
					_add_member(no, i)
		_household_deco(no)
		var sw := LightSwitch.find(get_tree(), no)
		if sw:
			sw.set_on.call_deferred(true, true)   # nach dem „Licht aus“ des LevelBuilders
	return true


## Mitglied i des Haushalts in Zimmer no einziehen lassen. Seed fest je Person (von Spiel zu Spiel gleich, 6.20).
func _add_member(no: String, i: int, id: String = "", restoring: bool = false) -> Guest:
	var h: Dictionary = builder.households[no]
	var member: Dictionary = h["members"][i]
	var is_child := bool(member.get("child", false))
	var core := String(h.get("core", ""))
	if core != "" and not is_child and GuestProfiles.ALL.has(core) and GuestProfiles.ALL[core]["name"] == member["name"]:
		if restoring:
			return null   # Kernfiguren stehen nicht im Roster
		var own: Dictionary = GuestProfiles.ALL[core].duplicate(true)
		own["room"] = no
		own["surname"] = h["surname"]
		own["household"] = h["id"]
		own["member"] = i
		GuestProfiles.placed[core] = own
		return _spawn(core, false, i)
	var gen_seed := ("%s/%s" % [h["id"], member["name"]]).hash() & 0x7FFFFFFF
	if id == "":
		id = "gast%d" % _next_guest
	_next_guest = maxi(_next_guest, int(id.trim_prefix("gast")) + 1)
	var profile: Dictionary
	if is_child:
		var parents := guests.filter(func(g: Guest) -> bool: return g.home["no"] == no and not g.is_child())
		if parents.is_empty():
			push_warning("HAUSHALTE.md: %s – Kind %s ohne Erwachsenen im Zimmer" % [h["id"], member["name"]])
			return null
		profile = GuestGenerator.make_child(gen_seed, no, parents[0].id, parents[0].profile, member,
			parents[1].profile if parents.size() > 1 else {})
	else:
		profile = GuestGenerator.make_member(gen_seed, no, member, String(h["surname"]))
	profile["surname"] = h["surname"]
	profile["household"] = h["id"]
	profile["member"] = i
	GuestProfiles.generated[id] = profile
	var guest := _spawn(id, false, i)
	guest.gen_seed = gen_seed
	return guest


## Eine Tür je Haushalt (6.20): die Startdeko der Erwachsenen zusammen, höchstens HOUSEHOLD_START_DECO Stück, alle im
## Besitz des ersten Erwachsenen (household_lead) – er hält sie auch später in Schuss.
func _household_deco(no: String) -> void:
	var lead := household_lead(no)
	if lead == null:
		return
	if Grinch.is_grinch(lead):
		return   # Gustav schmückt nicht (2.6)
	var kinds: Array = []
	for g in guests:
		if g.home["no"] == no and not g.is_child():
			kinds.append_array(g.profile["start_deco"])
	_place_start_deco(lead, kinds.slice(0, HOUSEHOLD_START_DECO))


## Erster lebender Erwachsener eines Zimmers (Haushalt, 6.20): schmückt die Tür, kümmert sich um Lampen und Birnen –
## damit nicht jeder im Zimmer dasselbe tut. null: keiner (nur Kinder oder niemand).
func household_lead(no: String) -> Guest:
	for g in guests:
		if g.home["no"] == no and not g.dead and not g.is_child():
			return g
	return null


## Einen zufälligen Gast erzeugen. room = "": ein freies Zimmer wählen.
## arrived: neu aufgewacht (eigene Sätze, Licht geht sofort an). Beim Laden (restoring)
## bleibt das Licht, wie es ist – der Spielstand setzt die Schalter selbst.
## parent ≠ "": ein Kind dieses Gastes (Spielkonzept 6.13, GuestGenerator.make_child).
func _add_generated(gen_seed: int, room: String, arrived: bool, id: String = "", restoring: bool = false, parent: String = "") -> Guest:
	if room == "":
		room = _free_room()
		if room == "":
			return null
	if not restoring:
		# Jeder Name nur einmal im Hotel
		var taken := guests.map(func(g: Guest) -> String: return g.display_name)
		var tries := 0
		while (GuestGenerator.child_name_for(gen_seed) if parent != "" else GuestGenerator.name_for(gen_seed)) in taken \
				and tries < 60:
			gen_seed += 1
			tries += 1
	if id == "":
		id = "gast%d" % _next_guest
	_next_guest = maxi(_next_guest, int(id.trim_prefix("gast")) + 1)
	if parent != "":
		GuestProfiles.generated[id] = GuestGenerator.make_child(gen_seed, room, parent, GuestProfiles.get_profile(parent))
	else:
		GuestProfiles.generated[id] = GuestGenerator.make(gen_seed, room, room if arrived else "")
	var guest := _spawn(id, true)
	guest.gen_seed = gen_seed
	guest.set_meta("arrived", arrived)
	var sw := LightSwitch.find(get_tree(), room)
	if sw and not restoring:
		if arrived:
			sw.set_on(true, true)
		else:
			sw.set_on.call_deferred(true, true)   # nach dem „Licht aus“ des LevelBuilders
	return guest


## Familien (Spielkonzept 6.13): CHILDREN Kinder, jedes bei einem anderen erzeugten Erwachsenen, im freien
## Zimmer am nächsten zu Mama oder Papa.
func _add_families() -> void:
	var parents := guests.filter(func(g: Guest) -> bool: return g.gen_seed >= 0)
	parents.shuffle()
	for parent in parents.slice(0, CHILDREN):
		var room := _room_near(parent.home["center"])
		if room == "":
			return
		_add_generated(randi(), room, false, "", false, parent.id)


## Das unbewohnte Zimmer, das diesem Punkt am nächsten liegt (gleiches Stockwerk), sonst "".
func _room_near(pos: Vector3) -> String:
	var best := ""
	var best_d := INF
	for no in builder.rooms:
		var info: Dictionary = builder.rooms[no]
		var c: Vector3 = info["center"]
		if info["kind"] == "vacant" and absf(c.y - pos.y) < 1.5 and c.distance_to(pos) < best_d:
			best_d = c.distance_to(pos)
			best = no
	return best


## Ein unbewohntes Zimmer (nie das eines Verschwundenen), möglichst weit weg vom Spieler.
func _free_room() -> String:
	var free: Array[String] = []
	for no in builder.rooms:
		if builder.rooms[no]["kind"] == "vacant":
			free.append(no)
	if free.is_empty():
		return ""
	free.shuffle()
	if Game.player:
		for no in free:
			var c: Vector3 = builder.rooms[no]["center"]
			if c.distance_to(Game.player.global_position) > 12.0 and not Game.director.player_can_see(c + Vector3.UP):
				return no
	return free[0]


## Nach Todesfällen: Ist das Hotel zu leer, taucht irgendwann jemand Neues auf.
func _update_arrivals(delta: float) -> void:
	if living_guests().size() >= MIN_GUESTS:
		_arrival_timer = -1.0
		return
	if _arrival_timer < 0.0:
		_arrival_timer = randf_range(ARRIVAL_DELAY.x, ARRIVAL_DELAY.y)
		return
	_arrival_timer -= delta
	if _arrival_timer > 0.0:
		return
	_arrival_timer = -1.0
	var guest := _add_generated(randi(), "", true)
	if guest:
		Game.say("Irgendwo im Hotel fällt eine Tür ins Schloss. In Zimmer %s brennt plötzlich Licht." % guest.home["no"], 5.0)


## Für Spielstände: die erzeugten Gäste (lebend und verschwunden) mit Seed und Zimmer.
func roster_state() -> Array:
	var list: Array = []
	for guest in guests:
		if guest.gen_seed >= 0:
			var entry := {"id": guest.id, "seed": guest.gen_seed, "room": guest.home["no"], "arrived": bool(guest.get_meta("arrived", false)),
				"parent": String(guest.profile.get("parent", ""))}
			if guest.profile.has("household"):   # Haushaltsmitglied (6.20): Identität aus HAUSHALTE.md
				entry["household"] = guest.profile["household"]
				entry["member"] = int(guest.profile["member"])
			list.append(entry)
	return list


## Spielstand laden: erzeugte Gäste der frischen Partie durch die gespeicherten ersetzen.
func restore_roster(list: Array) -> void:
	for guest in guests.duplicate():
		if guest.gen_seed < 0:
			continue
		if not builder.households.has(guest.home["no"]):   # Haushaltszimmer bleiben bewohnt (6.20)
			builder.rooms[guest.home["no"]]["kind"] = "vacant"
		GuestProfiles.generated.erase(guest.id)
		guests.erase(guest)
		guest.queue_free()
	_reserved.clear()
	for entry in list:
		var room := String(entry["room"])
		if entry.has("household"):
			if builder.households.has(room) and builder.households[room]["id"] == entry["household"]:
				_add_member(room, int(entry["member"]), String(entry["id"]), true)
			continue
		_add_generated(int(entry["seed"]), room, bool(entry.get("arrived", false)), String(entry["id"]), true, String(entry.get("parent", "")))
	if not builder.households.is_empty():
		_household_order()


## Gästeliste wieder in die Reihenfolge des Einzugs bringen (je Haushalt erst die Erwachsenen, dann die Kinder) – nach
## dem Laden stünden sonst die Kernfiguren vorn, weil nur die erzeugten Gäste neu entstehen.
func _household_order() -> void:
	var rank := {}
	for no: String in builder.households:
		var members: Array = builder.households[no]["members"]
		for child in [false, true]:
			for i in members.size():
				if bool(members[i].get("child", false)) == child:
					rank["%s/%d" % [no, i]] = rank.size()
	var key := func(g: Guest) -> int:
		return int(rank.get("%s/%d" % [g.home["no"], int(g.profile.get("member", -1))], 100000 + guests.find(g)))
	guests.sort_custom(func(a: Guest, b: Guest) -> bool: return key.call(a) < key.call(b))


## Ein Zettel eines Gastes (Spur der Gäste): an pos, Text aus templates.
func _leave_note(guest: Guest, templates: Array, pos: Vector3, dead: String) -> void:
	if Game.traces == null:
		return
	var notes := get_tree().get_nodes_in_group("guest_notes")
	if notes.size() >= MAX_GUEST_NOTES:
		notes[0].queue_free()
	var text := String(templates[randi() % templates.size()]).format({
		"name": guest.display_name, "room": guest.home["no"], "dead": dead,
		"zone": Game.director.zone_name_at(pos) if Game.director else "",
	})
	Game.traces.add_guest_note(pos + guest._jitter(0.3), "Zettel von %s" % guest.display_name, text)


func living_guests() -> Array:
	var list: Array = []
	for guest in guests:
		if not guest.dead:
			list.append(guest)
	return list


func guest_by_id(id: String) -> Guest:
	for guest in guests:
		if guest.id == id:
			return guest
	return null


## Debug-Konsole und Startparameter: Gast nach ID oder Namen – Vorname, auch mit Nachnamen („emil“, „EmilBecker“);
## Groß-/Kleinschreibung egal, ä/ö/ü/ß auch als ae/oe/ue/ss. Heißen zwei gleich, der lebende. null = keiner.
## (Nur die Kernfiguren haben ihren Namen als ID, alle anderen heißen gast1, gast2 …)
func find_guest(text: String) -> Guest:
	var exact := guest_by_id(text)
	if exact:
		return exact
	var key := _name_key(text)
	if key == "":
		return null
	var found: Guest = null
	for guest in guests:
		var g: Guest = guest
		if key in [_name_key(g.id), _name_key(g.display_name), _name_key(g.display_name + String(g.profile.get("surname", "")))]:
			if found == null or (found.dead and not g.dead):
				found = g
	return found


static func _name_key(text: String) -> String:
	return text.to_lower().replace(" ", "").replace("ä", "ae").replace("ö", "oe").replace("ü", "ue").replace("ß", "ss")


func guest_name(id: String) -> String:
	var guest := guest_by_id(id)
	return guest.display_name if guest else id


## Beziehung ändern (6.3): Nach oben wird es zäh (bei 50 nur gut die Hälfte), und über „befreundet“
## bzw. unter „verfeindet“ kommt man nur mit den passenden Taten. cap: Zuwachs höchstens bis hierhin
## (Weitererzählen unter Freunden, 6.16).
func change_relation(guest: Guest, amount: float, cap: float = 100.0) -> void:
	var before := guest.relation
	if guest.wound != "":
		amount *= Wounds.RELATION_FACTOR   # verletzt zählt alles doppelt (6.17)
	if amount > 0.0:
		amount *= 1.0 - clampf(before, 0.0, 100.0) / 110.0
	var value := clampf(before + amount, -100.0, 100.0)
	if amount > 0.0:
		value = minf(value, maxf(before, cap))
	if value >= 80.0 and not can_be_good_friend(guest):
		value = minf(value, maxf(before, 79.0))
	if value <= -80.0 and not can_be_strong_enemy(guest):
		value = maxf(value, minf(before, -79.0))
	guest.relation = value
	_announce_tier(guest, tier_of(before), tier_of(value))
	if pals and tier_of(value) >= Tier.FRIEND and tier_of(before) < Tier.FRIEND:
		pals.on_player_befriended(guest)   # Freund meines Feindes (6.16)


func add_deed(guest: Guest, key: String, count: int = 1) -> void:
	guest.deeds[key] = int(guest.deeds.get(key, 0)) + count


func deed(guest: Guest, key: String) -> int:
	return int(guest.deeds.get(key, 0))


## Guter Freund: oft zusammen gespielt und Gegenstände in beide Richtungen getauscht.
func can_be_good_friend(guest: Guest) -> bool:
	return deed(guest, "games") >= BOND_GAMES and deed(guest, "gifts_to") >= BOND_GIFTS_TO \
		and deed(guest, "gifts_from") >= BOND_GIFTS_FROM


## Stark verfeindet: du warst oft feindselig – und er hat sich schon gerächt.
func can_be_strong_enemy(guest: Guest) -> bool:
	return deed(guest, "hostile") >= FEUD_HOSTILE and deed(guest, "revenge") >= FEUD_REVENGE


## Neue Stufe an den Rändern kurz einblenden – die Stufen dazwischen stehen im Gesprächsprompt.
func _announce_tier(guest: Guest, before: Tier, after: Tier) -> void:
	if before == after or Game.hud == null:
		return
	var text := ""
	match after:
		Tier.GOOD_FRIEND:
			text = "%s ist jetzt ein guter Freund." % guest.display_name
		Tier.FRIEND:
			if before < after:
				text = "%s und du seid jetzt befreundet." % guest.display_name
		Tier.ENEMY:
			if before > after:
				text = "%s und du seid jetzt verfeindet." % guest.display_name
		Tier.STRONG_ENEMY:
			text = "%s hasst dich. Pass auf, wenn du ihm allein begegnest." % guest.display_name
	if text != "":
		Game.hud.show_message(text, 4.0)


# --- Diebstahl & Gerüchte ----------------------------------------------------------

## Der Spieler nimmt Deko, die einem Gast gehört. Haben es Gäste gesehen?
func on_player_took(item: Item) -> void:
	var owner_guest := guest_by_id(item.owner_id)
	if owner_guest == null or owner_guest.dead:
		return
	_thefts[owner_guest.id] = _time
	add_deed(owner_guest, "hostile")
	if Game.diary:   # eine dunkle Tat – Meilenstein im Tagebuch (3.10), Gäste können es dort lesen (8.9)
		Game.diary.note("first_theft", "Ich habe %s etwas weggenommen. Ich brauche es dringender, rede ich mir ein." % owner_guest.display_name)
	var witnesses: Array[Guest] = []
	var masked: Array[Guest] = []   # sehen es, erkennen unter dem Laken aber niemanden (5.9)
	for guest in guests:
		if guest.can_see_actor(Game.player):
			if Game.player.recognized_by(guest):
				witnesses.append(guest)
			else:
				masked.append(guest)
	if witnesses.is_empty():
		if not masked.is_empty():
			masked[0].say("He! Ein Gespenst klaut %s Deko!" % ("meine" if masked[0] == owner_guest else owner_guest.display_name + "s"))
		return   # unbemerkt – der Besitzer merkt es später an seiner Tür
	if owner_guest in witnesses:
		change_relation(owner_guest, -35.0)
		owner_guest.say(owner_guest.line("caught"))
		owner_guest.expected_deco = maxi(0, owner_guest.expected_deco - 1)
	else:
		change_relation(owner_guest, -15.0)
		var witness: Guest = witnesses[0]
		witness.say(witness.line("tattle") if witness.is_child() \
			else "Ich hab genau gesehen, wie du %s' Sachen genommen hast!" % owner_guest.display_name)
	for witness in witnesses:
		if witness != owner_guest:
			change_relation(witness, -10.0)
	var involved: Array = [owner_guest]
	involved.append_array(witnesses)
	# Kinder petzen (6.13) – und das glauben Mama und Papa sofort
	for witness in witnesses:
		var parent := witness.parent_guest()
		if parent and not parent in involved:
			change_relation(parent, -10.0)
			involved.append(parent)
	_spread_gossip(-8.0, involved)


## Plauderei über die Hotelkatzen (Spielkonzept 6.11) – Lieblingsgast, Diebin oder einfach so.
func cat_line(guest: Guest) -> String:
	var cats := get_tree().get_nodes_in_group("cats")
	if cats.is_empty():
		return ""
	if cat_thefts.has(guest.id):
		var thief: String = cat_thefts[guest.id]
		cat_thefts.erase(guest.id)
		_clear_cat_blame(guest)
		return "%s hat mir meine Deko weggeschleppt! Ich dachte erst, das warst du." % thief
	for cat in cats:
		if cat.favourite == guest.id:
			return (["%s läuft mir den ganzen Tag hinterher.", "%s schläft ständig auf meinem Bett. Ich hab's aufgegeben.",
				"Ohne %s würde ich hier verrückt werden."] as Array).pick_random() % cat.display_name
	var any = cats.pick_random()
	return (["Hast du %s heute schon gesehen?", "%s hat mir eine Kerze umgeworfen. Frechheit.",
		"Die Katzen haben es hier besser als wir. %s schläft einfach überall.",
		"Neulich hat %s vor meiner Tür miaut, bis ich aufgemacht habe."] as Array).pick_random() % any.display_name


## Nach dem ersten Weinen einer Katze wissen die Gäste: Die Katzen spüren es zuerst.
func cat_monster_line() -> String:
	if not cats_have_cried:
		return ""
	return (["Die Katzen spüren es. Wenn sie weinen, ist es in der Nähe.",
		"Hör auf die Katzen. Wenn sie jammern und rennen, renn auch.",
		"Es tut den Katzen nichts. Aber sie haben trotzdem Angst vor ihm."] as Array).pick_random()


## Ein Gast merkt, dass Deko vor seiner Tür fehlt.
func on_guest_noticed_missing(guest: Guest, count: int) -> void:
	var before := guest.relation
	change_relation(guest, -5.0 * count)
	if cat_thefts.has(guest.id) and count > 0:   # ein Stück davon hat eine Katze weggetragen (6.11)
		cat_blame[guest.id] = float(cat_blame.get(guest.id, 0.0)) + (before - guest.relation) / count
	guest.say(guest.line("missing"))


## Er weiß jetzt, dass es die Katze war (Spielkonzept 6.11): Der Verdacht gegen den Spieler ist vom Tisch.
func _clear_cat_blame(guest: Guest) -> void:
	var blame := float(cat_blame.get(guest.id, 0.0))
	cat_blame.erase(guest.id)
	if blame <= 0.0:
		return
	var before := guest.relation
	guest.relation = clampf(before + blame, -100.0, 100.0)
	_announce_tier(guest, tier_of(before), tier_of(guest.relation))


## Ein Gast merkt, dass in seinem Zimmer eine Glühbirne fehlt.
func on_guest_noticed_missing_bulb(guest: Guest) -> void:
	change_relation(guest, -5.0)
	guest.say("Wer hat meine Glühbirne herausgedreht?! Das warst doch du …")


func on_guest_stole_bulb(guest: Guest, lamp: Lamp, room_id: String) -> void:
	if room_id == LevelBuilder.PLAYER_ROOM:
		add_deed(guest, "revenge")
	if room_id == LevelBuilder.PLAYER_ROOM and Game.player and Game.director.player_can_see(lamp.global_position) \
			and Game.player.global_position.distance_to(guest.global_position) < 15.0:
		Game.say("%s dreht deine Glühbirne heraus!" % guest.display_name, 4.0)


func on_guest_stole(guest: Guest, item: Item, victim: String) -> void:
	if victim == "player":
		add_deed(guest, "revenge")
	if victim == "player" and Game.player and Game.director.player_can_see(guest.global_position + Vector3.UP * 1.4) \
			and Game.player.global_position.distance_to(guest.global_position) < 15.0:
		Game.say("%s klaut deine Deko (%s)!" % [guest.display_name, item.display_name], 4.0)


func on_insult(guest: Guest) -> void:
	add_deed(guest, "hostile")
	_spread_gossip(-3.0, [guest])


## Gerüchte verbreiten sich zeitversetzt – je nach Tratschfreude der Gäste.
func _spread_gossip(amount: float, exclude: Array) -> void:
	for guest in guests:
		if guest.dead or guest in exclude:
			continue
		_gossip.append({"guest": guest, "amount": amount * float(guest.profile["gossip"]), "delay": randf_range(15.0, 40.0)})


# --- Monster, Tod, Schock ---------------------------------------------------------------

func on_guest_saw_monster(guest: Guest) -> void:
	guest.say_panic()
	if randf() < 0.08:
		var named := Game.leviathan_name != null and Game.leviathan_name.knows(guest)
		_leave_note(guest, SIGHT_NOTES_NAMED if named else SIGHT_NOTES, guest.global_position, "")


## Über das Monster reden: hilfreich – aber es hört mit (Spielkonzept 4.7).
func on_monster_talk(guest: Guest) -> void:
	Game.director.on_monster_talk(guest.global_position)


## cause "ghost": vom Lakengeist erwürgt – kein Schrei durchs Hotel, er liegt in seinem Zimmer (6.12).
## Nach `BELL_DELAY` s läutet bei jedem Tod die Totenglocke. Schläft der Spieler (der Schrei hat ihn nicht geweckt),
## bekommt er nichts mit – was geschah, findet er später (Morgenbilanz, Spielkonzept 3.6).
func on_guest_died(guest: Guest, cause: String = "monster") -> void:
	for other in living_guests():
		other.fear = minf(100.0, other.fear + 50.0)
	if (Game.player and Game.player.sleeping) or cause == "unseen":
		pass   # unseen: Gustav bei der Siegerehrung (2.6) – keiner hat es gehört, man erfährt es später (Grinch)
	elif cause == "ghost":   # mit Totenkopf (IconArt „dead“)
		Game.say("Irgendwo im Hotel bricht ein Röcheln ab …", 4.0, "dead")
	elif cause == "pumpkin":
		Game.say("Ein Schrei – dann ein dumpfer Schlag. Dann ist es still.", 4.0, "dead")
	else:
		Game.say("Ein Schrei hallt durch das Hotel …", 4.0, "dead")
		var gone := guest.display_name
		get_tree().create_timer(5.0, false).timeout.connect(func() -> void:
			Game.say("%s ist verschwunden." % gone, 4.0, "dead"))
	# Die Totenglocke läutet – nach dem Schrei, für jeden Toten, im ganzen Hotel zu hören (nur nicht im Schlaf)
	get_tree().create_timer(BELL_DELAY, false).timeout.connect(func() -> void:
		if not (Game.player and Game.player.sleeping):
			Game.play_sound("bell"))
	_memorial_doors.append(guest.home["door_front"])
	if Game.cemetery:   # Grab oder Gedenktafel auf dem Friedhof (5.15)
		Game.cemetery.on_guest_died(guest)
	if Game.mirror_omens:   # die Familie verhängt die Spiegel (4.27)
		Game.mirror_omens.on_guest_died(guest)
	if talk:   # Schuld bei „da war nichts“, Trauer der Freunde (6.9)
		talk.on_guest_died(guest)
	if Game.notebook:   # Kreuz neben seinem Namen bei seinen Aufgaben (3.10)
		Game.notebook.on_guest_died(guest)
	if requests:   # seine Bitte fällt weg, im Notizbuch bleibt sie offen (6.14)
		requests.on_guest_died(guest)
	if Game.diary and cause != "unseen":   # Gustav: erst, wenn man Zimmer 020 findet (Grinch)
		Game.diary.note("first_death", "%s aus Zimmer %s ist tot. Bis heute dachte ich, es tut niemandem etwas." % [
			guest.display_name, String(guest.home["sign"])])
	# Ein Kind verliert Mama oder Papa (6.13): große Angst – es sucht sich jemanden, bei dem es bleiben kann
	for other in living_guests():
		if other.is_child() and String(other.profile.get("parent", "")) == guest.id:
			other.fear = 100.0
	# Ein, zwei Gäste schreiben einen Zettel und legen ihn vor ihre Tür
	var writers := living_guests()
	writers.shuffle()
	var dead_name := guest.display_name   # der Tote kann beim Laden freigegeben sein, bevor der Zettel kommt
	for writer in writers.slice(0, randi_range(1, 2)):
		var w: Guest = writer
		get_tree().create_timer(randf_range(20.0, 60.0), false).timeout.connect(func() -> void:
			if is_instance_valid(w) and not w.dead:
				_leave_note(w, DEATH_NOTES, w.home["door_front"], dead_name))
	SaveManager.request_autosave("Tod eines Gastes")
	if party_active and party_host == guest.id:
		end_party("")
	# Schock, wenn es ein Freund war – stärker, wenn man ihn vorher bestohlen hat (Schuld)
	if tier(guest) >= Tier.FRIEND and Game.player:
		var guilt := _thefts.has(guest.id) and _time - float(_thefts[guest.id]) < 600.0
		var amount := clampf(guest.relation / 100.0, 0.5, 1.0) * (1.5 if guilt else 1.0)
		Game.player.add_shock(amount, guilt)


func find_hide_spot(guest: Guest) -> HideSpot:
	var best: HideSpot = null
	var best_score := INF
	var own_spots: Array = guest.home["spots"]
	for node in get_tree().get_nodes_in_group("hide_spots"):
		var spot := node as HideSpot
		if spot.occupant != null or (_reserved.has(spot) and _reserved[spot] != guest):
			continue
		var d := guest.global_position.distance_to(spot.global_position)
		if d > 25.0:
			continue
		if behind_lock(spot_room(spot), guest):
			continue   # in einem fremden, abgeschlossenen Zimmer (Spielkonzept 6.19)
		# Nicht direkt vor dem Monster hineinklettern – es sähe ihn und reißt die Tür gleich wieder auf
		if Game.monster.is_active() and Game.monster.global_position.distance_to(spot.global_position) < HIDE_MONSTER_DISTANCE:
			continue
		var score := d - (6.0 if spot in own_spots else 0.0)
		if score < best_score:
			best_score = score
			best = spot
	if best:
		_reserved[best] = guest
	return best


## Zimmer, in dem ein Versteck steht ("" = keins, etwa im Flur).
func spot_room(spot: HideSpot) -> String:
	if _spot_rooms.is_empty():
		for no in builder.rooms:
			for s in builder.rooms[no]["spots"]:
				_spot_rooms[s] = no
	return String(_spot_rooms.get(spot, ""))


## Liegt Zimmer no hinter einer abgeschlossenen Tür, die guest nicht aufschließen kann (fremdes Zimmer, 6.19)?
func behind_lock(no: String, guest: Guest) -> bool:
	if no == "" or no == String(guest.home["no"]) or not builder.rooms.has(no):
		return false
	var door: Door = builder.rooms[no]["door"]
	return door.locked and not door.is_open and not door.broken


## Gibt die Reservierung frei – nur die eigene (ein anderer kann das Versteck inzwischen reserviert haben).
func release_hide_spot(spot: HideSpot, guest: Guest) -> void:
	if _reserved.get(spot) == guest:
		_reserved.erase(spot)


func is_in_closed_chest(item: Item) -> bool:
	for node in get_tree().get_nodes_in_group("chests"):
		var chest := node as Chest
		if not chest.is_open and chest.global_position.distance_to(item.global_position) < 0.6:
			return true
	return false


# --- Feiern ---------------------------------------------------------------------------

## Wer gerade Spaß hat (Spielkonzept 4.19 – lockt den Kürbismann): feiert, sitzt am Spieltisch, zieht als Kind
## zu Süßes oder Saures von Tür zu Tür oder steht damit an Zimmer 13.
func has_fun(guest: Guest) -> bool:
	return fun_kind(guest) != ""


## Welcher Spaß (für den Spaßwert des Kürbismanns, 4.19): "party", "game", "decorate", "eat", "trick" – "" = keiner.
func fun_kind(guest: Guest) -> String:
	if guest.dead or guest.hiding != null:
		return ""
	if guest.state == Guest.State.PARTY:
		return "party"
	if guest.state == Guest.State.MINIGAME:
		return "game"
	if decorating and decorating.is_crew(guest):
		return "decorate"   # Schmücken ist auch Spaß (Spielkonzept 5.9, 4.19)
	if Game.kitchen and Game.kitchen.is_eating(guest):
		return "eat"   # gemeinsam Kürbissuppe essen (3.8)
	if _rounds.has(guest.id) or (not _trick.is_empty() and _trick["guest"] == guest):
		return "trick"
	return ""


func fun_guests() -> Array[Guest]:
	var result: Array[Guest] = []
	for guest in guests:
		if has_fun(guest):
			result.append(guest)
	return result


## Der Spieler hat Spaß: Mäxchen, Schach oder Darts, auf der Feier im Partyraum, Süßes oder Saures an seiner Tür, beim
## Schmücken dabei (5.9) oder beim gemeinsamen Suppenessen (3.8).
func player_has_fun() -> bool:
	var p := Game.player
	if p == null or p.dead or p.hiding != null:
		return false
	if Game.table_game_active():
		return true
	if decorating and decorating.player_joins():
		return true
	if Game.kitchen and Game.kitchen.player_eats():
		return true
	if Game.apple_tub and Game.apple_tub.active:   # Apfeltauchen (6.21)
		return true
	return (party_active and builder.in_area(p.global_position, "partyraum")) or not _trick.is_empty()


## Alle, die gerade Spaß haben – Gäste und der Spieler (für den Kürbismann).
func fun_actors() -> Array[Node3D]:
	var result: Array[Node3D] = []
	for guest in fun_guests():
		result.append(guest)
	if player_has_fun():
		result.append(Game.player)
	return result


## Wie lange läuft die Feier schon?
func party_age() -> float:
	return PARTY_DURATION - _party_time if party_active else 0.0


func party_center() -> Vector3:
	return builder.party_center


## Eigener Tanzplatz für den Gast, so nah an der Mitte wie frei (Spielkonzept 7.1): Gäste gehen
## durcheinander durch, ohne festen Platz stünden sie auf einem Knubbel. Belegt ist ein Platz, solange
## sein Gast feiert; wer wieder dazukommt, bekommt seinen alten zurück, wenn er noch frei ist.
func free_party_spot(guest: Guest) -> Vector3:
	var spots := builder.party_spots
	var taken := {}
	for other in living_guests():
		if other != guest and other.state == Guest.State.PARTY and _dance_spots.has(other.id):
			taken[_dance_spots[other.id]] = true
	if _dance_spots.has(guest.id) and not taken.has(_dance_spots[guest.id]):
		return spots[_dance_spots[guest.id]]
	for i in spots.size():
		if not taken.has(i):
			_dance_spots[guest.id] = i
			return spots[i]
	return spots[randi() % spots.size()]   # Raum voll


func start_party(host: String) -> bool:
	if party_active:
		return false
	if not Game.director.is_quiet(party_center(), 25.0):
		if host == "player":
			Game.say("Jetzt nicht – es ist zu unruhig im Hotel.")
		return false
	party_active = true
	party_host = host
	_party_time = PARTY_DURATION
	_party_presence = 0.0
	_party_noise = 0.0
	record_player.set_playing(true)
	_dance_spots.clear()
	var coming: Array[String] = []
	for guest in living_guests():
		var comes := false
		if Grinch.is_grinch(guest):
			comes = false   # Gustav hasst Feiern (2.6)
		elif guest.is_child():
			comes = true   # Kinder kommen immer (6.13)
		elif host == "player":
			comes = guest.invited or tier(guest) >= Tier.FRIENDLY
		else:
			comes = guest.id == host or randf() < 0.75
		if comes and guest.fear < 60.0 and guest.state != Guest.State.TALKING and guest.wound_bed <= 0.0:
			guest.invited = true
			guest.join_party(free_party_spot(guest))
			coming.append(guest.display_name)
	if host == "player":
		if coming.is_empty():
			Game.say("Die Musik spielt … aber niemand kommt.", 4.0)
		else:
			Game.say("Feier im Partyraum! Es kommen: %s" % ", ".join(coming), 4.0)
	else:
		Game.say("Aus dem Partyraum klingt Musik – %s feiert." % guest_name(host), 4.0)
	return true


## Versammeln sich die Gäste gerade zur Siegerehrung (Spielkonzept 2.5)? Dann kein Besuch, kein Süßes oder Saures.
func _gathering() -> bool:
	return Game.contest != null and Game.contest.is_gathering()


## Nachtruhe nach der Uhr (2.4): beginnt, sobald es so weit ist und keine Feier oder Schmück-Aktion mehr läuft,
## und endet am Morgen.
func _update_sleep(_delta: float) -> void:
	var due := night_due()
	if sleep_active:
		if not due:
			_end_sleep()
	elif due and not party_active and not (decorating and decorating.active):   # erst zu Ende feiern bzw. schmücken
		start_sleep()


## Die Nacht, die am Abend von day beginnt: Spielzeit von Beginn und Ende (je Nacht gestreut, aus night_seed).
func night_window(day: int) -> Vector2:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([night_seed, day])
	var from := Calendar.at(day, SLEEP_START + rng.randf_range(-SLEEP_JITTER, SLEEP_JITTER))
	var to := Calendar.at(day + 1, SLEEP_END + rng.randf_range(-SLEEP_JITTER, SLEEP_JITTER))
	return Vector2(from, to)


## Spielzeit, zu der die laufende (oder nächste) Nachtruhe endet.
func night_ends_at() -> float:
	var now := Game.director.elapsed
	var day := Calendar.raw_day_of(now)
	var last := night_window(day - 1)
	return last.y if now < last.y else night_window(day).y


## Zeitsprung im Schlaf (SleepSkip, Spielkonzept 3.6): Beziehungen, Gerede, Nachrücker und Pausen um dt.
func skip_time(dt: float) -> void:
	for guest in guests:
		if guest.dead:
			continue
		var target := 0.0 if guest.is_child() else clampf(guest.relation, -55.0, 55.0)
		guest.relation = move_toward(guest.relation, target, DRIFT * (CHILD_DRIFT if guest.is_child() else 1.0) * dt)
	for entry in _gossip:
		entry["delay"] = maxf(0.001, float(entry["delay"]) - dt)
	if _arrival_timer > 0.0:
		_arrival_timer = maxf(0.001, _arrival_timer - dt)
	_party_cooldown -= dt
	_knock_cooldown -= dt
	_visit_cooldown -= dt
	_trick_cooldown -= dt
	_round_cooldown -= dt


## Ist laut Uhr Nachtruhe (auch wenn eine Feier sie gerade noch aufhält)?
func night_due() -> bool:
	return seconds_to_night() <= 0.0


## Sekunden bis zur nächsten Nachtruhe; 0, solange sie fällig ist.
func seconds_to_night() -> float:
	var now := Game.director.elapsed
	var day := Calendar.raw_day_of(now)
	var last := night_window(day - 1)   # die Nacht von gestern Abend bis heute Morgen
	if now < last.y:
		return maxf(0.0, last.x - now)
	var tonight := night_window(day)
	return maxf(0.0, tonight.x - now) if now < tonight.y else 0.0


func _end_sleep() -> void:
	sleep_active = false
	for guest in living_guests():
		guest.wake_up()
	Game.say("Türen gehen auf, Schritte im Flur – die Gäste sind wieder wach.", 3.5)


## Zeitsprung am Tag vorbei (SleepSkip, Spielkonzept 3.6): Die Gäste stehen, wo ihr Tagesablauf sie hinschickt.
func after_day_skip() -> void:
	for guest in living_guests():
		guest.after_day_skip()


# --- Fremdes Bett (Spielkonzept 3.6) --------------------------------------------------------------

## Ein Gast will schlafen und findet den Spieler schlafend in einem Bett seines Zimmers. Freunde stört das nicht – ein
## guter Freund hält vielleicht Wache, sonst legen sie sich woanders hin. Neutrale bis genervte (und Kinder) wecken ihn:
## Die Beziehung sinkt, es spricht sich herum; liegt er beim nächsten Mal noch da, werfen sie ihn hinaus. Verfeindete
## beklauen ihn im Schlaf oder wecken ihn mit einem Schlag. true = der Gast legt sich (noch) nicht hin.
func player_in_bed(guest: Guest) -> bool:
	var p := Game.player
	var bed: HideSpot = p.hiding if p and not p.dead else null
	if bed == null or bed.type != HideSpot.Type.BED or bed.own_bed or not bed in guest.home["spots"]:
		guest.remove_meta("guards_player")
		guest.remove_meta("woke_player")
		return false
	if not p.sleeping:
		if not guest.has_meta("woke_player"):
			return false   # liegt wach darunter – wie in jedem Versteck
		guest.remove_meta("woke_player")
		guest.say("Raus aus meinem Bett. Sofort!")
		p.exit_hide()
		change_relation(guest, BED_EVICT)
		guest.wait_awake(4.0)
		if Game.tracing:
			print("[Fremdes Bett] %s wirft dich hinaus" % guest.display_name)
		return true
	var t := tier(guest)
	if t >= Tier.FRIEND:
		if t == Tier.GOOD_FRIEND and not guest.is_child() and (guest.has_meta("guards_player") or randf() < BED_GUARD_CHANCE):
			if not guest.has_meta("guards_player"):
				guest.set_meta("guards_player", true)
				guest.say("Schlaf nur. Ich pass auf dich auf.")
				if Game.tracing:
					print("[Fremdes Bett] %s hält Wache" % guest.display_name)
			guest.wait_awake(30.0)
			return true
		if Game.tracing:
			print("[Fremdes Bett] %s legt sich woanders hin" % guest.display_name)
		return false   # _fall_asleep: kein freies Bett – er schläft im Sessel bzw. im Stehen
	if t >= Tier.ANNOYED or guest.is_child():
		p.wake_up("Jemand rüttelt dich wach – %s steht vor dem Bett." % guest.display_name)
		guest.say(["Das ist MEIN Bett!", "Was machst du in meinem Bett?!", "Raus da, das ist mein Zimmer!"].pick_random())
		change_relation(guest, BED_ANNOY)
		_spread_gossip(-2.0, [guest])   # „hat in meinem Bett geschlafen“
		guest.set_meta("woke_player", true)
		guest.wait_awake(6.0)
		if Game.tracing:
			print("[Fremdes Bett] %s weckt dich (Beziehung %.0f)" % [guest.display_name, guest.relation])
		return true
	if randf() < 0.5 and Game.money > 0:
		var n := mini(Game.money, randi_range(BED_ROB.x, BED_ROB.y))
		Game.money -= n
		guest.money += n
		add_deed(guest, "revenge")
		p.robbed = "Mir fehlen %d Münzen. Wer war hier, während ich geschlafen habe?" % n
		if Game.tracing:
			print("[Fremdes Bett] %s beklaut dich im Schlaf (%d Münzen)" % [guest.display_name, n])
		return false
	p.wake_up("Ein Schlag reißt dich aus dem Schlaf – %s!" % guest.display_name)
	p.hurt(0.25, guest.global_position)
	on_guest_hit_player(guest)
	guest.say("Verschwinde aus meinem Bett!")
	guest.set_meta("woke_player", true)
	guest.wait_awake(5.0)
	if Game.tracing:
		print("[Fremdes Bett] %s schlägt dich wach" % guest.display_name)
	return true


## instant (Debug): alle liegen sofort im Bett.
func start_sleep(instant: bool = false) -> void:
	sleep_active = true
	for guest in living_guests():
		guest.bedtime(instant)
	Game.say("Im Hotel wird es still – die Gäste gehen schlafen.", 3.5)
	if Game.shower_scare:
		Game.shower_scare.on_night_rest()   # im Bad von Zimmer 13 läuft vielleicht die Dusche (4.24)
	if Game.tracing:
		print("[Nachtruhe] %s, %s" % [Calendar.date_text(Game.director.elapsed), Calendar.time_text(Game.director.elapsed)])


## Debug: Nachtruhe sofort – die Uhr springt auf den Beginn der heutigen Nacht, falls es noch nicht so weit ist.
func debug_sleep(instant: bool = false) -> void:
	Game.director.elapsed += seconds_to_night()
	if not sleep_active:
		start_sleep(instant)


## Schlafen alle lebenden Gäste gerade?
func all_asleep() -> bool:
	if not sleep_active:
		return false
	for guest in living_guests():
		if not guest.is_asleep() and not guest.is_child():   # ein wachliegendes Kind ist kein Zeuge (6.13)
			return false
	return true


func end_party(message: String) -> void:
	if not party_active:
		return
	party_active = false
	record_player.set_playing(false)
	var present := _party_presence / PARTY_DURATION >= 0.4
	pals.note_group(living_guests().filter(func(g: Guest) -> bool: return g.state == Guest.State.PARTY))   # 6.16
	for guest in living_guests():
		if guest.state == Guest.State.PARTY:
			guest.fear = maxf(0.0, guest.fear - 40.0)
			if present:
				change_relation(guest, 10.0)
		guest.leave_party()
	if present and Game.player:
		Game.player.shock = maxf(0.0, Game.player.shock - 0.3)
	_party_cooldown = PARTY_COOLDOWN
	if message != "":
		Game.say(message, 3.5)
	SaveManager.request_autosave("Ende einer Feier")


func _update_party(delta: float) -> void:
	if party_active:
		_party_time -= delta
		var p := Game.player
		if p and builder.in_area(p.global_position, "partyraum"):
			_party_presence += delta
		# Musik ist laut – das Monster wird neugierig auf den Partyraum
		_party_noise -= delta
		if _party_noise <= 0.0:
			_party_noise = 8.0
			Game.noise("party", party_center())
		if not Game.director.is_quiet(party_center(), 22.0):
			end_party("Die Musik verstummt abrupt.")
		elif _party_time <= 0.0:
			end_party("Die Feier ist vorbei.")
		return
	_party_cooldown -= delta
	_spontaneous_timer -= delta
	if _spontaneous_timer > 0.0:
		return
	_spontaneous_timer = 30.0
	if sleep_active or Calendar.phase() != Calendar.Phase.EVENING:
		return   # Feiern gibt es abends (Spielkonzept 2.4), in der Nachtruhe feiert niemand
	if Game.contest and Game.contest.holds_parties():
		return   # am Abend der Siegerehrung feiert niemand (Spielkonzept 2.5) – der erste Angriff kommt dort
	var alive := living_guests()
	if _party_cooldown > 0.0 or alive.size() < 2 or not Game.director.is_quiet(party_center(), 30.0):
		return
	var total_fear := 0.0
	for guest in alive:
		total_fear += guest.fear
	if total_fear / alive.size() < 35.0 and randf() < 0.15:
		var host: Guest = alive[randi() % alive.size()]
		start_party(host.id)


# --- Gäste wecken (Spielkonzept 3.6) --------------------------------------------------------------

## Der Spieler weckt einen schlafenden Gast (am Bett oder durch Klopfen, knock). Was er davon hält, hängt am Grund:
## echte Gefahr → dankbar, steht auf und bleibt wach; keine → verärgert und gereizt, legt sich wieder hin; nur eine
## Halluzination → falscher Alarm, er glaubt dir eine Weile nicht. Gibt den Grund zurück ("danger", "none", "false").
func wake_guest(guest: Guest, knock: bool = false) -> String:
	var why := wake_reason(guest)
	if guest.has_stance("doubts_waking") and why != "none":
		why = "doubted"   # nach einem falschen Alarm glaubt er dir nicht – auch wenn es diesmal echt ist
	guest.wake_up()
	match why:
		"danger":
			change_relation(guest, WAKE_THANKS)
			guest.set_stance("woken_alert", randf_range(WAKE_ALERT.x, WAKE_ALERT.y))
			guest.clear_stance("grumpy")
			guest.say(["Was ist … das Licht flackert! Danke, dass du mich geweckt hast.", "Es ist unterwegs, oder? Danke!",
					"Gut, dass du mich geweckt hast. Ich bleib wach."].pick_random())
		"false":
			change_relation(guest, WAKE_FALSE)
			guest.set_stance("doubts_waking", WAKE_DOUBT)
			guest.set_stance("grumpy", WAKE_GRUMPY)
			guest.say(["Da ist doch nichts! Du siehst Gespenster.", "Alles ruhig. Weck mich nie wieder wegen nichts!"].pick_random())
		"doubted":
			guest.set_stance("grumpy", WAKE_GRUMPY)
			guest.say("Schon wieder? Ich glaub dir kein Wort.")
		_:
			change_relation(guest, WAKE_ANNOY_FRIEND if tier(guest) >= Tier.FRIEND else WAKE_ANNOY)
			guest.set_stance("grumpy", WAKE_GRUMPY)
			guest.say(["Was soll das? Ich hab geschlafen!", "Mitten in der Nacht … was willst du?",
					"Hast du eine Ahnung, wie spät es ist?"].pick_random())
	if not knock:   # beim Klopfen geht er zur Tür (RoomAccess) und danach wieder ins Bett bzw. bleibt wach
		guest.after_woken(why == "danger")
	if Game.tracing:
		print("[Wecken] %s (%s, Beziehung %.0f)" % [guest.display_name, why, guest.relation])
	return why


## Gibt es gerade einen guten Grund, ihn zu wecken? "danger" (echte Gefahr), "false" (nur eine Halluzination), "none".
func wake_reason(guest: Guest) -> String:
	var director := Game.director
	if director == null:
		return "none"
	var p := guest.global_position
	var m := Game.monster
	if m and m.is_active() and (absf(m.global_position.y - p.y) < LevelBuilder.UP_Y / 2.0
			or m.global_position.distance_to(p) < WAKE_DANGER_RANGE):
		return "danger"
	if director.is_signalling() and not director.wave_fake:
		return "danger"
	if (Game.ghost and Game.ghost.is_active()) or (Game.pumpkin and (Game.pumpkin.in_house() or Game.pumpkin.announcing())):
		return "danger"
	return "false" if director.is_hallucinating() or (director.is_signalling() and director.wave_fake) else "none"


# --- Minispiele -------------------------------------------------------------------------

func has_watched(guest: Guest) -> bool:
	return _watched.has(guest.id)


func on_cheat_caught(guest: Guest) -> void:
	_spread_gossip(-10.0, [guest])


func queue_rematch(guest: Guest) -> void:
	if not guest in _rematches:
		_rematches.append(guest)


## game: "dice" (Mäxchen an der Bar), "chess" (Schach in der Lobby) oder "darts" (Scheibe in der Bar)
func challenge(guest: Guest, game: String = "dice") -> void:
	guest.challenge_time = 30.0
	guest.challenge_cooldown = 240.0
	guest.challenge_game = game
	if game == "darts":
		guest.say(DartMatch.line_of(guest, "darts_challenge"))
	else:
		guest.say(guest.line("chess_challenge" if game == "chess" else "challenge"))


func has_watched_chess(guest: Guest) -> bool:
	return _chess_watched.has(guest.id)


func has_watched_darts(guest: Guest) -> bool:
	return _darts_watched.has(guest.id)


func on_challenge_ignored(guest: Guest) -> void:
	if Game.player and Game.player.global_position.distance_to(guest.global_position) < 15.0:
		change_relation(guest, -2.0)
		guest.say("Pff. Dann eben nicht.")


## Gäste fordern dich heraus: Revanche nach einer Niederlage oder einfach aus Spaß. Ab „wütend“ spielen sie nicht
## mehr mit dir (Spielkonzept 6.3) – auch eine offene Revanche verfällt dann.
func _update_challenges(delta: float) -> void:
	_challenge_timer -= delta
	if _challenge_timer > 0.0:
		return
	_challenge_timer = 20.0
	var p := Game.player
	if p == null or p.in_dialog or Game.table_game_active() \
			or not Game.director.is_quiet(p.global_position, 25.0):
		return
	for guest in living_guests():
		var g: Guest = guest
		if g.challenge_cooldown > 0.0 or g.challenge_time > 0.0 or g.fear >= 40.0:
			continue
		if not (g.state == Guest.State.IDLE or g.state == Guest.State.WALK):
			continue
		if g.global_position.distance_to(p.global_position) > 6.0:
			continue
		if tier(g) <= Tier.ANGRY:
			_rematches.erase(g)
			continue
		if g in _rematches:
			_rematches.erase(g)
			challenge(g, g.challenge_game)
			return
		var dice: Dictionary = g.profile["dice"]
		var chess := ChessMatch.chess_profile(g)
		var board := builder.chess_table.has_board(null)
		if chess["likes"] and board and tier(g) >= Tier.FRIENDLY and randf() < (0.15 if dice["likes"] else 0.25):
			challenge(g, "chess")
			return
		var darts := DartMatch.darts_profile(g)
		var darts_ready := builder.dart_board != null and builder.dart_board.has_darts(null) and not g.is_child()
		if darts["likes"] and darts_ready and tier(g) >= Tier.FRIENDLY and randf() < 0.2:
			challenge(g, "darts")
			return
		if dice["likes"] and tier(g) >= Tier.FRIENDLY and randf() < 0.25:
			challenge(g)
			return


## Gäste würfeln auch untereinander – Zuschauen verrät ihre Ticks beim Bluffen.
func _update_bar_game(delta: float) -> void:
	var table := builder.game_table
	if _bar_game.is_empty():
		_bar_timer -= delta
		if _bar_timer > 0.0:
			return
		_bar_timer = 20.0
		if table.busy or not table.has_cup(null) or not Game.director.is_quiet(table.global_position, 25.0):
			return
		var pair := _seat_pair(table, 0.35, func(_g: Guest) -> bool: return true)
		if not pair.is_empty():
			_bar_game = {"a": pair[0], "b": pair[1], "time": 0.0, "noise": 0.0, "watch": 0.0}
		return
	if _pair_broken(_bar_game, table):
		_end_bar_game(false)
		return
	if not (_bar_game["a"].seated and _bar_game["b"].seated):
		return
	var dist := _pair_time(_bar_game, table, delta)
	_bar_game["noise"] = float(_bar_game["noise"]) - delta
	if float(_bar_game["noise"]) <= 0.0:
		_bar_game["noise"] = 7.0
		Game.noise("dice", table.global_position)
		if dist < 7.0:
			_pair_line(_bar_game, BAR_LINES)
	if float(_bar_game["time"]) > 45.0:
		_end_bar_game(true)


## Gäste spielen auch untereinander Schach (leise, lange Partien). Wer ≥ 30 s zusieht, weiß danach, wie
## stark beide spielen – das steht dann schon bei der Einsatz-Frage.
func _update_chess_game(delta: float) -> void:
	var table := builder.chess_table
	if _chess_game.is_empty():
		_chess_timer -= delta
		if _chess_timer > 0.0:
			return
		_chess_timer = 30.0
		if table.busy or not table.has_board(null) or not Game.director.is_quiet(table.global_position, 25.0):
			return
		var pair := _seat_pair(table, 0.3, func(g: Guest) -> bool: return ChessMatch.chess_profile(g)["likes"])
		if pair.is_empty():
			return
		_chess_game = {"a": pair[0], "b": pair[1], "time": 0.0, "talk": 12.0, "watch": 0.0, "length": randf_range(70.0, 120.0)}
		if Game.tracing:
			print("[Schach] %s gegen %s in der Lobby" % [pair[0].display_name, pair[1].display_name])
		return
	if _pair_broken(_chess_game, table):
		_end_chess_game(false)
		return
	if not (_chess_game["a"].seated and _chess_game["b"].seated):
		return
	var dist := _pair_time(_chess_game, table, delta)
	_chess_game["talk"] = float(_chess_game["talk"]) - delta
	if float(_chess_game["talk"]) <= 0.0:
		_chess_game["talk"] = randf_range(14.0, 22.0)
		if dist < 7.0:
			_pair_line(_chess_game, CHESS_LINES)
	if float(_chess_game["time"]) > float(_chess_game["length"]):
		_end_chess_game(true)


func _end_chess_game(completed: bool) -> void:
	var ga: Guest = _chess_game["a"]
	var gb: Guest = _chess_game["b"]
	if completed:
		# Der Stärkere gewinnt meistens
		var sa := float(ChessMatch.chess_profile(ga)["skill"]) + randf_range(-0.3, 0.3)
		var sb := float(ChessMatch.chess_profile(gb)["skill"]) + randf_range(-0.3, 0.3)
		var winner := ga if sa >= sb else gb
		var loser := gb if winner == ga else ga
		pals.note(ga, gb)   # zusammen gespielt (6.16)
		if Game.tracing:
			print("[Schach] %s setzt %s matt (zugesehen %.0f s)" % [winner.display_name, loser.display_name, float(_chess_game["watch"])])
		if Game.player and Game.player.global_position.distance_to(builder.chess_table.global_position) < 7.0:
			Game.say("%s setzt %s matt." % [winner.display_name, loser.display_name], 3.5)
		if float(_chess_game["watch"]) > 30.0 and not (has_watched_chess(ga) and has_watched_chess(gb)):
			_chess_watched[ga.id] = true
			_chess_watched[gb.id] = true
			Game.say("Du hast zugesehen: %s %s, %s %s." % [ga.display_name, ChessMatch.strength_text(ga),
				gb.display_name, ChessMatch.strength_text(gb)], 4.5)
	_release_pair(_chess_game, builder.chess_table)
	_chess_game = {}


## Gäste werfen auch untereinander Darts (laut genug für die Bar): je Aufnahme drei Pfeile, abwechselnd. Wer ≥ 25 s
## zusieht, weiß danach, wie sicher beide werfen.
func _update_dart_game(delta: float) -> void:
	var board := builder.dart_board
	if board == null:
		return
	if _dart_game.is_empty():
		_dart_timer -= delta
		if _dart_timer > 0.0:
			return
		_dart_timer = 25.0
		if board.busy or not board.has_darts(null) or not Game.director.is_quiet(board.global_position, 25.0):
			return
		var pair := _seat_pair(board, 0.3, func(g: Guest) -> bool:
			return DartMatch.darts_profile(g)["likes"] and not g.is_child(), true)
		if pair.is_empty():
			return
		_dart_game = {"a": pair[0], "b": pair[1], "time": 0.0, "talk": 10.0, "watch": 0.0, "length": randf_range(60.0, 90.0),
			"next": 1.5, "darts": 0, "turn": 0}
		if Game.tracing:
			print("[Darts] %s gegen %s an der Bar" % [pair[0].display_name, pair[1].display_name])
		return
	if _pair_broken(_dart_game, board):
		_end_dart_game(false)
		return
	if not (_dart_game["a"].seated and _dart_game["b"].seated):
		return
	var dist := _pair_time(_dart_game, board, delta)
	_dart_game["next"] = float(_dart_game["next"]) - delta
	if float(_dart_game["next"]) <= 0.0:
		# Wer dran ist, tritt vor die Mitte – hier wirft er einfach von seinem Platz; nach drei Pfeilen ziehen
		if int(_dart_game["darts"]) >= Darts.DARTS_PER_VISIT:
			board.clear_darts()
			_dart_game["darts"] = 0
			_dart_game["turn"] = 1 - int(_dart_game["turn"])
			_dart_game["next"] = 1.5
		else:
			var thrower: Guest = _dart_game["a"] if int(_dart_game["turn"]) == 0 else _dart_game["b"]
			board.guest_throw(thrower, Darts.aim_point(20, Darts.Ring.TRIPLE), DartMatch.sigma_of(thrower),
				DartMatch.PLAYER_FLIGHT if int(_dart_game["turn"]) == 0 else DartMatch.GUEST_FLIGHT)
			_dart_game["darts"] = int(_dart_game["darts"]) + 1
			_dart_game["next"] = randf_range(1.2, 1.8)
	_dart_game["talk"] = float(_dart_game["talk"]) - delta
	if float(_dart_game["talk"]) <= 0.0:
		_dart_game["talk"] = randf_range(14.0, 22.0)
		if dist < 8.0:
			_pair_line(_dart_game, DART_LINES)
	if float(_dart_game["time"]) > float(_dart_game["length"]):
		_end_dart_game(true)


func _end_dart_game(completed: bool) -> void:
	var ga: Guest = _dart_game["a"]
	var gb: Guest = _dart_game["b"]
	if completed:
		# Der Sicherere gewinnt meistens
		var sa := float(DartMatch.darts_profile(ga)["skill"]) + randf_range(-0.35, 0.35)
		var sb := float(DartMatch.darts_profile(gb)["skill"]) + randf_range(-0.35, 0.35)
		var winner := ga if sa >= sb else gb
		var loser := gb if winner == ga else ga
		pals.note(ga, gb)   # zusammen gespielt (6.16)
		if Game.tracing:
			print("[Darts] %s gewinnt gegen %s (zugesehen %.0f s)" % [winner.display_name, loser.display_name, float(_dart_game["watch"])])
		if Game.player and Game.player.global_position.distance_to(builder.dart_board.global_position) < 8.0:
			Game.say("%s gewinnt beim Darts gegen %s." % [winner.display_name, loser.display_name], 3.5)
		if float(_dart_game["watch"]) > 25.0 and not (has_watched_darts(ga) and has_watched_darts(gb)):
			_darts_watched[ga.id] = true
			_darts_watched[gb.id] = true
			Game.say("Du hast zugesehen: %s %s, %s %s." % [ga.display_name, DartMatch.strength_text(ga),
				gb.display_name, DartMatch.strength_text(gb)], 4.5)
	builder.dart_board.clear_darts()
	_release_pair(_dart_game, builder.dart_board)
	_dart_game = {}


func _end_bar_game(completed: bool) -> void:
	var ga: Guest = _bar_game["a"]
	var gb: Guest = _bar_game["b"]
	if completed:
		var winner := ga if randf() < 0.5 else gb
		var loser := gb if winner == ga else ga
		pals.note(ga, gb)   # zusammen gespielt (6.16)
		if Game.player and Game.player.global_position.distance_to(builder.game_table.global_position) < 7.0:
			Game.say("%s gewinnt beim Würfeln gegen %s." % [winner.display_name, loser.display_name], 3.5)
		if float(_bar_game["watch"]) > 25.0 and not (has_watched(ga) and has_watched(gb)):
			_watched[ga.id] = true
			_watched[gb.id] = true
			Game.say("Du hast genau hingesehen: Jetzt kennst du die Ticks von %s und %s beim Bluffen." % [ga.display_name, gb.display_name], 4.5)
	_release_pair(_bar_game, builder.game_table)
	_bar_game = {}


## Partien zweier Gäste (Mäxchen an der Bar, Schach in der Lobby, Darts): Zwei freie Gäste (IDLE, Angst < 40, nicht
## zur Feier eingeladen, `likes`) setzen sich an den Tisch – mit dieser Chance; stand: stellen sich an die Linie.
## [] = zu wenige oder keine Lust.
func _seat_pair(table: GameTable, chance: float, likes: Callable, stand: bool = false) -> Array:
	var free: Array = living_guests().filter(func(g: Guest) -> bool:
		return g.state == Guest.State.IDLE and g.fear < 40.0 and not g.invited and likes.call(g))
	if free.size() < 2 or randf() > chance:
		return []
	free.shuffle()
	table.busy = true
	if stand:
		var board := table as DartBoard
		(free[0] as Guest).stand_for_game(table.player_seat.global_position, board.bull())
		(free[1] as Guest).stand_for_game(table.guest_seat.global_position, board.bull())
	else:
		(free[0] as Guest).sit_for_game(table.player_seat.global_position, table.top_center())
		(free[1] as Guest).sit_for_game(table.guest_seat.global_position, table.top_center())
	return [free[0], free[1]]


## Partie vorbei, weil einer tot ist, aufgestanden ist oder es am Tisch unruhig wird?
func _pair_broken(game: Dictionary, table: GameTable) -> bool:
	var ga: Guest = game["a"]
	var gb: Guest = game["b"]
	return ga.dead or gb.dead or ga.state != Guest.State.MINIGAME or gb.state != Guest.State.MINIGAME \
		or not Game.director.is_quiet(table.global_position, 22.0)


## Spielzeit und Zuschauzeit des Spielers (näher als 5 m) weiterzählen; gibt seinen Abstand zum Tisch zurück.
func _pair_time(game: Dictionary, table: GameTable, delta: float) -> float:
	game["time"] = float(game["time"]) + delta
	var dist := Game.player.global_position.distance_to(table.global_position) if Game.player else INF
	if dist < 5.0:
		game["watch"] = float(game["watch"]) + delta
	return dist


## Ein Satz vom Tisch, die beiden Namen in zufälliger Reihenfolge.
func _pair_line(game: Dictionary, lines: Array) -> void:
	var pair := [(game["a"] as Guest).display_name, (game["b"] as Guest).display_name]
	pair.shuffle()
	Game.say(String(lines[randi() % lines.size()]) % pair, 3.0)


func _release_pair(game: Dictionary, table: GameTable) -> void:
	for g: Guest in [game["a"], game["b"]]:
		if not g.dead:
			g.end_game()
	table.busy = false


# --- Laufend ----------------------------------------------------------------------------

func _process(delta: float) -> void:
	_time += delta
	var i := _gossip.size() - 1
	while i >= 0:
		var entry := _gossip[i]
		entry["delay"] = float(entry["delay"]) - delta
		if float(entry["delay"]) <= 0.0:
			var guest = entry["guest"]   # nach dem Laden kann der Gast neu erzeugt worden sein
			if is_instance_valid(guest) and not guest.dead:
				change_relation(guest, entry["amount"])
			_gossip.remove_at(i)
		i -= 1
	_update_party(delta)
	_update_arrivals(delta)
	_update_knocking(delta)
	_update_tricks(delta)
	_update_rounds(delta)
	_update_bar_game(delta)
	_update_chess_game(delta)
	_update_dart_game(delta)
	_update_challenges(delta)
	_update_sleep(delta)
	_update_bonds(delta)
	_check_timer -= delta
	if _check_timer <= 0.0:
		_check_timer = 2.0
		_update_memorials()
	if Game.audio and record_player:
		var target := 0.0
		if record_player.playing and Game.player:
			var d := record_player.global_position.distance_to(Game.player.global_position)
			target = clampf(1.0 - d / 30.0, 0.08, 1.0) * 0.6
		Game.audio.music = move_toward(Game.audio.music, target if record_player.synth_track() else 0.0, delta)
		record_player.fade_to(target, delta)   # oder eines der MP3-Stücke


## Gedenken: Brennt ein Licht vor der Tür eines verschwundenen Freundes, heilt der Schock schneller.
func _update_memorials() -> void:
	var p := Game.player
	if p == null:
		return
	var mult := 1.0
	if not _memorial_doors.is_empty():
		for node in get_tree().get_nodes_in_group("items"):
			var item := node as Item
			if item.lit and not item.is_held and _memorial_doors.any(func(door_front: Vector3) -> bool:
					return item.global_position.distance_to(door_front) < 2.5):
				mult = 3.0
				break
	if party_active and builder.in_area(p.global_position, "partyraum"):
		mult = maxf(mult, 2.0)
	p.shock_recovery = mult


# --- Spuren & Berichte (Spielkonzept 4.13) -----------------------------------------------------

## Ein erschreckendes Geräusch (Spielkonzept 4.15): Gäste hören mit halber Reichweite,
## gedämpft durch Wände und Türen. Gibt die Reaktionen zurück (Debug).
func on_alarm(kind: String, pos: Vector3, loudness: float, source: Node) -> Array[String]:
	var result: Array[String] = []
	var reach := loudness * Senses.GUEST_HEARING
	var told := false
	for guest in guests:
		if guest == source or guest.dead or guest.hiding:
			continue
		var ear := guest.global_position + Vector3.UP * 1.5
		var d := ear.distance_to(pos)
		if d > reach or d > Senses.audible_range(guest.get_world_3d(), pos, ear, reach, d):
			continue
		var reaction := guest.hear_alarm(pos)
		if reaction == "":
			continue
		result.append("%s %s" % [guest.display_name, reaction])
		if reaction == "erzählt davon" and not told:
			told = true
			_add_report({"kind": kind, "heard": true, "zone": Game.director.zone_name_at(pos), "time": _time})
	return result


## Lärm des Spielers vor einer Zimmertür (Spielkonzept 4.15, 6.2): Wer drin ist, ärgert sich und schimpft durch die
## Tür. Gibt die Reaktionen zurück (Debug).
func on_player_noise(kind: String, pos: Vector3, loudness: float) -> Array[String]:
	var result: Array[String] = []
	if loudness < NOISE_ANNOY_MIN or kind in NOISE_POLITE or Game.director.player_threat > 0.0:
		return result   # auf der Flucht vor dem Monster nimmt es keiner übel
	var player_room := builder.room_at(Game.player.global_position)
	var spoken := {}
	for guest in guests:
		if guest.dead or guest.hiding or guest.is_child():
			continue
		var no := String(guest.home["no"])
		if player_room == no or builder.room_at(guest.global_position) != no:
			continue   # Besuch drinnen oder nicht zu Hause
		var front: Vector3 = guest.home["door_front"]
		if absf(front.y - pos.y) > 2.0 or Vector2(front.x - pos.x, front.z - pos.z).length() > NOISE_ANNOY_REACH:
			continue
		if _time - float(_noise_annoyed.get(guest.id, -INF)) < NOISE_ANNOY_QUIET:
			continue
		_noise_annoyed[guest.id] = _time
		var asleep := guest.is_asleep()
		change_relation(guest, NOISE_ANNOY_ASLEEP if asleep else NOISE_ANNOY)
		if not spoken.has(no):   # je Zimmer schimpft nur einer
			spoken[no] = true
			var key := "noise_night" if asleep else "noise"
			guest.say(guest.line(key) if guest.profile["lines"].has(key) else NOISE_LINES[key].pick_random())
		result.append("%s ärgert sich" % guest.display_name)
	return result


func note_trace(kind: String, pos: Vector3) -> void:
	_add_report({"kind": kind, "zone": Game.director.zone_name_at(pos), "time": _time})


## Die letzten zwölf Berichte bleiben.
func _add_report(report: Dictionary) -> void:
	_reports.append(report)
	if _reports.size() > 12:
		_reports.pop_front()


## Irgendein Ort im Hotel – für falsch Erinnertes (Berichte, Warnanrufe).
func random_zone_name() -> String:
	var names: Array = Game.director.zones.map(func(z: Dictionary) -> String: return z["name"])
	return names.pick_random() if not names.is_empty() else ""


## Was ein Gast von einem eigenen Erlebnis erzählt (Spielkonzept 6.12). again: später am Tag, kürzer.
func experience_line(guest: Guest, experience: Dictionary, again: bool = false) -> String:
	var kind: String = experience["kind"]
	var zone: String = experience["zone"] if experience["zone"] != "" else "hier"
	var keys := {"zone": zone, "who": experience["who"]}
	if guest.is_child():
		keys["eltern"] = "Mama" if GuestProfiles.get_profile(String(guest.profile.get("parent", ""))).get("sex", "m") == "f" else "Papa"
	if kind.begins_with("survivor_"):   # ein Überlebender hat es ihm erzählt (6.17)
		return String(Wounds.HEARD.get(kind.trim_prefix("survivor_"), "")).format(keys)
	if again:
		return String(EXPERIENCE_AGAIN[kind]).format(keys)
	if kind == "child_saw":
		return String(CHILD_SAW_LINES.pick_random()).format(keys)
	if kind == "rumble":
		return RUMBLE_STORIES.pick_random()
	var lines: Array = EXPERIENCE_LINES[guest.shock_style()][kind]
	return String(lines[randi() % lines.size()]).format(keys)


## Was ein Gast über Spuren erzählt – je nach Persönlichkeit zuverlässig oder nicht.
## Leer, wenn es nichts zu berichten gibt.
func report_line(guest: Guest) -> String:
	var recent: Array[Dictionary] = []
	for r in _reports:
		if _time - float(r["time"]) < 600.0:
			recent.append(r)
	if recent.is_empty():
		return ""
	var r: Dictionary = recent[randi() % recent.size()]
	var zone: String = r["zone"]
	if r.get("heard", false):
		var heard: String = HEARD_TEXT.get(r["kind"], "Ein lautes Geräusch")
		if randf() > float(guest.profile.get("reliable", 0.7)):
			zone = random_zone_name()
		return HEARD_LINES[randi() % HEARD_LINES.size()] % [heard, zone]
	var what: String = TRACE_TEXT.get(r["kind"], "etwas Seltsames")
	if randf() > float(guest.profile.get("reliable", 0.7)):
		# Falsch erinnert, erfunden oder übertrieben
		zone = random_zone_name()
		what = TRACE_TEXT.values()[randi() % TRACE_TEXT.size()]
	var template: String = guest.profile.get("report", "Ich habe %s gesehen. %s.")
	return template % [what, zone]


# --- Klopfen an Zimmer 13 -----------------------------------------------------------------------

func is_knocking() -> bool:
	return not _knock.is_empty()


## Meistens ein echter Gast in Panik („Mach auf!“) – manchmal nicht (bekannte Stimme,
## aber draußen ist niemand, nur ein Kleidungsstück).
func _update_knocking(delta: float) -> void:
	if not _knock.is_empty():
		_knock_step(delta)
		return
	_knock_cooldown -= delta
	var director := Game.director
	var p := Game.player
	if _knock_cooldown > 0.0 or not director.first_attack_done or p == null or p.dead:
		return
	var door: Door = builder.rooms[LevelBuilder.PLAYER_ROOM]["door"]
	if door.is_open or director.zone_name_at(p.global_position) != "Zimmer 13":
		return
	if not Game.monster.is_active() or Game.monster.global_position.distance_to(door.center()) > 28.0:
		return
	_knock_cooldown = randf_range(KNOCK_COOLDOWN.x, KNOCK_COOLDOWN.y)
	var fake := debug_fake_knock or randf() < FAKE_KNOCK_CHANCE
	var guest: Guest = null
	if not fake:
		# auch Versteckte: Sie halten es nicht mehr aus und rennen zu deiner Tür
		var candidates: Array = living_guests().filter(func(g: Guest) -> bool:
			return not g.state in [Guest.State.TALKING, Guest.State.MINIGAME, Guest.State.KNOCK, Guest.State.SHELTER])
		if candidates.is_empty():
			fake = true
		else:
			guest = candidates[randi() % candidates.size()]
	if fake:
		# Am liebsten die Stimme eines Verschwundenen – sonst die eines Gastes (der woanders ist)
		var voices: Array = guests.filter(func(g: Guest) -> bool: return g.dead)
		if voices.is_empty():
			voices = guests.duplicate()
		guest = voices[randi() % voices.size()]
	_knock = {"guest": guest, "fake": fake, "time": 0.0, "next": 0.0, "said": 0}
	if not fake:
		guest.start_knock(builder.rooms[LevelBuilder.PLAYER_ROOM]["door_front"])


func _knock_step(delta: float) -> void:
	if _knock.get("visit", false):
		_visit_step(delta)
		return
	var guest: Guest = _knock["guest"]
	var fake: bool = _knock["fake"]
	var door: Door = builder.rooms[LevelBuilder.PLAYER_ROOM]["door"]
	_knock["time"] = float(_knock["time"]) + delta
	var t := float(_knock["time"])
	if not fake and (guest.dead or guest.state != Guest.State.KNOCK):
		_knock = {}
		return
	if door.is_open:
		if door.opened_by_monster:
			_knock_ignored(guest, fake)   # nicht der Spieler hat aufgemacht – es war schneller
		else:
			_knock_answered(guest, fake)
		return
	if t >= KNOCK_WAIT:
		_knock_ignored(guest, fake)
		return
	_knock["next"] = float(_knock["next"]) - delta
	if float(_knock["next"]) <= 0.0:
		_knock["next"] = randf_range(1.0, 1.6) if not fake else 2.4
		Game.noise("knock", builder.rooms[LevelBuilder.PLAYER_ROOM]["door_front"], guest)
		Game.caption("[Es klopft an deiner Tür]")
	var said := int(_knock["said"])
	if fake and said == 0 and t > 1.5:
		_knock["said"] = 1
		Game.say("%s: „Ich bin's … mach bitte auf.“" % guest.display_name, 4.0)
	elif not fake and said < 2 and t > 0.8 + said * 4.0:
		_knock["said"] = said + 1
		Game.say("%s: „%s“" % [guest.display_name, guest.line("knock")], 3.5)
		if said == 1:
			# Das Geschrei lockt es an – jetzt bleibt nicht mehr viel Zeit
			Game.noise("scream", guest.global_position, guest)


func _knock_answered(guest: Guest, fake: bool) -> void:
	_knock = {}
	var front: Vector3 = builder.rooms[LevelBuilder.PLAYER_ROOM]["door_front"]
	if fake:
		# Niemand da. Nur ein Kleidungsstück auf dem Boden.
		var cloth := Item.create(Item.Kind.CLOTHING, guest.id)
		get_parent().add_child(cloth)
		cloth.global_position = front + Vector3(0, 0.02, -0.2)
		Game.play_sound("sting", 0.6)
		Game.say("Draußen ist niemand.", 3.0)
		Game.director.add_curiosity(front, 30.0)
		if Game.monster.is_active():
			Game.monster.investigate(front)
		return
	guest.enter_shelter(builder.rooms[LevelBuilder.PLAYER_ROOM]["center"])
	change_relation(guest, 15.0)
	guest.say(guest.line("sheltered"))


func _knock_ignored(guest: Guest, fake: bool) -> void:
	_knock = {}
	if fake:
		# Stille. Später findet man Kratzspuren an der Tür.
		if Game.traces:
			Game.traces.add_door_scratch(builder.rooms[LevelBuilder.PLAYER_ROOM]["door"], builder.rooms[LevelBuilder.PLAYER_ROOM]["door_front"] + Vector3(0, 0, -1.0))
		return
	if Game.director.is_harmless() or not Game.director.may_hunt(guest) or guest.is_child() or randf() < 0.5:
		Game.noise("scream", guest.global_position, guest)
		guest.scared_by_monster()
		change_relation(guest, -20.0)
		get_tree().create_timer(4.0, false).timeout.connect(func() -> void:
			if not guest.dead:
				guest.say(guest.line("left_outside")))
	else:
		Game.monster.spawn_near_unseen(guest.global_position)
		Game.director.kill_guest(guest, null)


# --- Freundschaft & Feindschaft (Spielkonzept 6.3) ------------------------------------

func _update_bonds(delta: float) -> void:
	# Ohne Kontakt wandern die Extreme langsam zurück
	for guest in guests:
		if guest.dead:
			continue
		if guest.is_child():
			guest.relation = move_toward(guest.relation, 0.0, DRIFT * CHILD_DRIFT * delta)
			continue
		if guest.relation > 55.0:
			guest.relation = maxf(55.0, guest.relation - DRIFT * delta)
		elif guest.relation < -55.0:
			guest.relation = minf(-55.0, guest.relation + DRIFT * delta)
	_update_visits(delta)
	_feud_timer -= delta
	if _feud_timer <= 0.0:
		_feud_timer = 2.0
		_update_feuds()


## Gute Freunde klopfen ab und zu an Zimmer 13 – nur, wenn du drin bist und es ruhig ist.
func _update_visits(delta: float) -> void:
	_visit_cooldown -= delta
	if _visit_cooldown > 0.0 or not _knock.is_empty() or sleep_active or party_active or _gathering() or not _player_home_quiet():
		return
	_visit_cooldown = randf_range(VISIT_COOLDOWN.x, VISIT_COOLDOWN.y)
	var friends := living_guests().filter(func(g: Guest) -> bool:
		return tier(g) == Tier.GOOD_FRIEND and g.state in [Guest.State.IDLE, Guest.State.WALK] and g.fear < 40.0)
	if not friends.is_empty():
		start_visit(friends.pick_random())


## Der Spieler ist in Zimmer 13 – frei (kein Gespräch, Schlaf oder Versteck), kein Monster unterwegs, ruhig ringsum.
func _player_home_quiet() -> bool:
	var p := Game.player
	if p == null or p.dead or p.in_dialog or p.sleeping or p.hiding:
		return false
	return Game.director.zone_name_at(p.global_position) == "Zimmer 13" and not Game.monster.is_active() \
		and Game.director.is_quiet(p.global_position, 25.0)


func start_visit(guest: Guest) -> void:
	guest.start_visit(builder.rooms[LevelBuilder.PLAYER_ROOM]["door_front"])


## Der Gast steht vor Zimmer 13: Bei offener Tür kommt er gleich herein, sonst klopft er.
## why (Meta „visit“ am Gast): "" Besuch eines Freundes, "trick" Süßes oder Saures, "sleepless" Kind kann nicht schlafen.
func on_visit_arrived(guest: Guest) -> void:
	if grinch.on_arrived(guest):   # Gustav räumt Deko weg, stellt die Musik ab, geht auf jemanden los (2.6)
		return
	if pranks.on_arrived(guest):   # holt etwas für einen Streich bzw. wirft es (6.13)
		return
	if tidying.on_arrived(guest):   # putzt einen Fleck weg bzw. bringt Kürbismatsch in die Küche
		return
	if _rounds.has(guest.id):
		_round_arrived(guest)
		return
	var door: Door = builder.rooms[LevelBuilder.PLAYER_ROOM]["door"]
	var why := String(guest.get_meta("visit", ""))
	guest.set_meta("visit", "")
	if door.is_open:
		_visit_door_open(guest, why)
		return
	if not _knock.is_empty():
		guest.end_visit()
		return
	guest.knock_politely()
	_knock = {"guest": guest, "fake": false, "visit": true, "why": why, "time": 0.0, "next": 0.0, "said": 0}


func _visit_step(delta: float) -> void:
	var guest: Guest = _knock["guest"]
	var door: Door = builder.rooms[LevelBuilder.PLAYER_ROOM]["door"]
	_knock["time"] = float(_knock["time"]) + delta
	var t := float(_knock["time"])
	if guest.dead or guest.state != Guest.State.KNOCK:
		_knock = {}
		return
	var why := String(_knock.get("why", ""))
	if door.is_open:
		_knock = {}
		_visit_door_open(guest, why)
		return
	if t >= KNOCK_WAIT * 1.5:
		_knock = {}
		if why == "trick":
			_trick_prank(guest)   # nicht aufgemacht – dann gibt's Saures
			return
		guest.say("Na gut … dann ein andermal.")
		change_relation(guest, -1.0)
		guest.end_visit()
		return
	_knock["next"] = float(_knock["next"]) - delta
	if float(_knock["next"]) <= 0.0:
		_knock["next"] = 2.6
		Game.noise("knock", builder.rooms[LevelBuilder.PLAYER_ROOM]["door_front"], guest)
		Game.caption("[Es klopft leise an deiner Tür]")
	if int(_knock["said"]) == 0 and t > 1.2:
		_knock["said"] = 1
		var text: String = guest.line(why) if why != "" else VISIT_LINES.pick_random()
		Game.say("%s: „%s“" % [guest.display_name, text], 4.0)


func _visit_door_open(guest: Guest, why: String) -> void:
	if why == "trick":
		_trick_at_door(guest)
		return
	_visit_enter(guest)
	if why == "sleepless":
		guest.say(guest.line("sleepless"))


# --- Süßes oder Saures (Spielkonzept 6.13) ---------------------------------------------------

## Ab und zu klopft ein Kind an Zimmer 13 – nur, wenn du drin bist und es ruhig ist.
func _update_tricks(delta: float) -> void:
	if not _trick.is_empty():
		var kid: Guest = _trick["guest"]
		if kid.dead or not kid.state in [Guest.State.KNOCK, Guest.State.TALKING]:
			_trick = {}
		elif kid.state == Guest.State.KNOCK:
			_trick["time"] = float(_trick["time"]) - delta
			if float(_trick["time"]) <= 0.0:
				if int(_trick.get("given", 0)) > 0:
					_treat_done(kid)   # hat schon etwas bekommen – kein Streich
				else:
					_trick_prank(kid)
		return
	_trick_cooldown -= delta
	if _trick_cooldown > 0.0 or not _knock.is_empty() or sleep_active or party_active or _gathering() or not _player_home_quiet():
		return
	_trick_cooldown = randf_range(TRICK_COOLDOWN.x, TRICK_COOLDOWN.y)
	var kids := living_guests().filter(func(g: Guest) -> bool:
		return g.is_child() and g.state in [Guest.State.IDLE, Guest.State.WALK] and g.fear < 40.0 and not g.is_following())
	if not kids.is_empty():
		var kid: Guest = kids.pick_random()
		kid.set_meta("visit", "trick")
		start_visit(kid)
		if Game.tracing:
			print("[Süßes oder Saures] %s kommt zu Zimmer 13" % kid.display_name)


## Die Tür ist auf: Das Kind wartet eine Weile vor der Tür. Gibst du ihm Süßigkeiten ([E] am Kind, give_trick_sweet,
## oder im Gespräch), spielt es keinen Streich – bis zu TRICK_SWEETS_MAX Stück, und jedes mag dich mehr (TREAT_RELATION).
## Nach dem ersten wartet es nur noch TRICK_MORE_WAIT auf das nächste; bekommt es nichts, gibt es Saures.
func _trick_at_door(kid: Guest) -> void:
	kid.knock_politely()   # bleibt vor der Tür stehen
	kid.say(kid.line("trick"))
	_trick = {"guest": kid, "time": TRICK_WAIT, "given": 0}
	if Game.extra_child:   # manchmal steht eins zu viel dahinter (4.31)
		Game.extra_child.on_trick_at_door(kid)


## Wartet dieses Kind gerade vor Zimmer 13 auf (weitere) Süßigkeiten? Gibt zurück, wie viele es schon hat, sonst −1.
func trick_sweets_given(kid: Guest) -> int:
	if _trick.is_empty() or _trick["guest"] != kid or kid.state != Guest.State.KNOCK:
		return -1
	var given := int(_trick.get("given", 0))
	return given if given < TRICK_SWEETS_MAX else -1


## Der Spieler gibt dem wartenden Kind eine Süßigkeit (aus Hand oder Tasche). false = geht nicht.
func give_trick_sweet(kid: Guest) -> bool:
	if trick_sweets_given(kid) < 0 or not Game.player.consume_kind(Item.Kind.SWEETS):
		return false
	on_sweets_given(kid)
	return true


## Eine Süßigkeit bekommen (an der Tür oder im Gespräch, DialogUI._gift): Wartet das Kind gerade an der Tür, spielt es
## keinen Streich mehr und mag dich – je mehr Stück, desto mehr; ab dem dritten geht es zufrieden.
func on_sweets_given(kid: Guest) -> void:
	var given := trick_sweets_given(kid)
	if given < 0:
		return
	given += 1
	_trick["given"] = given
	_trick["time"] = TRICK_MORE_WAIT
	change_relation(kid, TREAT_RELATION[given - 1])
	add_deed(kid, "gifts_to")
	kid.say(TREAT_LINES[given - 1])
	if Game.tracing:
		print("[Süßes oder Saures] %s bekommt die %d. Süßigkeit (Beziehung %.0f)" % [kid.display_name, given, kid.relation])
	if given >= TRICK_SWEETS_MAX:
		_treat_done(kid)


## Zufrieden: Das Kind bedankt sich und geht.
func _treat_done(kid: Guest) -> void:
	_trick = {}
	kid.say(kid.line("treat"))
	kid.end_visit()


## Saures: ein Streich vor der Tür von Zimmer 13 (Pranks) – oder ein Klingelstreich ein wenig später.
func _trick_prank(kid: Guest) -> void:
	_trick = {}
	if Game.tracing:
		print("[Süßes oder Saures] %s: Saures" % kid.display_name)
	kid.say(kid.line("prank"))
	change_relation(kid, -2.0)
	kid.end_visit()
	if randf() < 0.5 and Game.phones:
		get_tree().create_timer(randf_range(15.0, 30.0), false).timeout.connect(func() -> void:
			if is_instance_valid(kid) and not kid.dead:
				Game.phones.kid_prank(kid))
		return
	pranks.play(kid, LevelBuilder.PLAYER_ROOM)


## Saures: Laub vor die Tür dieses Zimmers.
func _leaves_at(no: String, kid: Guest) -> void:
	var leaves := Item.create(Item.Kind.LEAVES)
	_world.add_child(leaves)
	leaves.global_position = (builder.rooms[no]["door_front"] as Vector3) + kid._jitter(0.3) + Vector3(0, 0.02, 0)


# --- Süßes oder Saures von Tür zu Tür (Spielkonzept 6.13) -------------------------------------------

## Ab und zu zieht ein Kind los und klopft an die Türen der Gäste in der Nähe (nicht an Zimmer 13 – dorthin
## kommt es eigens, _update_tricks). Ist jemand wach zu Hause, macht er auf und gibt Süßes oder schimpft;
## schimpft er oder öffnet keiner, gibt es Saures: Laub vor der Tür. Man hört das Klopfen im Flur.
func _update_rounds(delta: float) -> void:
	for id in _rounds.keys():
		_round_step(_rounds[id], delta)
	_round_cooldown -= delta
	if _round_cooldown > 0.0 or sleep_active or party_active or _gathering() or Game.monster.is_active():
		return
	_round_cooldown = randf_range(ROUND_COOLDOWN.x, ROUND_COOLDOWN.y)
	var kids := living_guests().filter(func(g: Guest) -> bool:
		return g.is_child() and g.state in [Guest.State.IDLE, Guest.State.WALK] and g.fear < 40.0 \
			and not g.is_following() and not _rounds.has(g.id) and (_trick.is_empty() or _trick["guest"] != g))
	if not kids.is_empty():
		start_round(kids.pick_random())


## Ein Kind zieht los (auch Debug --trick): die nächsten Türen von Erwachsenen, außer den Eltern. false = keine.
func start_round(kid: Guest) -> bool:
	var parent := kid.parent_guest()
	var doors: Array = []
	for guest in living_guests():
		var g: Guest = guest
		var no := String(g.home["no"])
		if g.is_child() or g == parent or no == LevelBuilder.PLAYER_ROOM or no in doors or no == String(kid.home["no"]):
			continue
		if (g.home["door_front"] as Vector3).distance_to(kid.global_position) < ROUND_RANGE:
			doors.append(no)
	if doors.is_empty():
		return false
	# zuerst Türen, hinter denen jemand zu Hause ist, dann die nächsten
	var order := func(no: String) -> float:
		var d := (builder.rooms[no]["door_front"] as Vector3).distance_to(kid.global_position)
		return d + (0.0 if _round_host(no) else 1000.0)
	doors.sort_custom(func(a: String, b: String) -> bool: return order.call(a) < order.call(b))
	_rounds[kid.id] = {"kid": kid, "doors": doors.slice(0, ROUND_DOORS), "no": "", "phase": "walk", "time": 0.0,
		"next": 0.0, "knocks": 0, "host": null}
	if Game.tracing:
		print("[Süßes oder Saures] %s zieht los: %s" % [kid.display_name, ", ".join(_rounds[kid.id]["doors"])])
	_round_next(_rounds[kid.id])
	return true


## Zur nächsten Tür der Runde – oder fertig.
func _round_next(entry: Dictionary) -> void:
	var kid: Guest = entry["kid"]
	var doors: Array = entry["doors"]
	if doors.is_empty() or kid.dead:
		_rounds.erase(kid.id)
		if not kid.dead:
			kid.end_visit()
		return
	entry["no"] = doors.pop_front()
	entry["phase"] = "walk"
	kid.start_visit(builder.rooms[entry["no"]]["door_front"])


## Vor der Tür angekommen (Guest._arrive in VISIT): klopfen.
func _round_arrived(kid: Guest) -> void:
	var entry: Dictionary = _rounds[kid.id]
	var room: Dictionary = builder.rooms[entry["no"]]
	kid.knock_politely((room["door"] as Door).center())
	entry["phase"] = "knock"
	entry["time"] = 0.0
	entry["next"] = 0.0
	entry["knocks"] = 0
	entry["host"] = null


func _round_step(entry: Dictionary, delta: float) -> void:
	var kid: Guest = entry["kid"]
	var phase := String(entry["phase"])
	var allowed: Array = [Guest.State.KNOCK, Guest.State.TALKING]
	if phase == "walk":
		allowed = [Guest.State.VISIT]
	elif phase == "pause":
		allowed = [Guest.State.IDLE, Guest.State.WALK, Guest.State.TALKING]   # kurz zwischen zwei Türen
	if kid.dead or sleep_active or not kid.state in allowed:
		_rounds.erase(kid.id)   # erschreckt, versteckt, ins Bett geschickt, feiert … – die Runde ist vorbei
		if kid.state == Guest.State.KNOCK:
			kid.end_visit()
		return
	if phase == "walk" or kid.state == Guest.State.TALKING:
		return
	entry["time"] = float(entry["time"]) + delta
	if phase == "pause":
		if float(entry["time"]) >= float(entry["next"]):
			_round_next(entry)
		return
	var room: Dictionary = builder.rooms[entry["no"]]
	var door: Door = room["door"]
	var front: Vector3 = room["door_front"]
	match phase:
		"knock":
			if float(entry["time"]) >= float(entry["next"]) and int(entry["knocks"]) < 3:
				entry["next"] = float(entry["time"]) + ROUND_KNOCK_EVERY
				entry["knocks"] = int(entry["knocks"]) + 1
				Game.noise("knock", front, kid)
				if Game.player and Game.player.global_position.distance_to(front) < 12.0:
					Game.caption("[Es klopft an Zimmer %s]" % room["sign"])
				if int(entry["knocks"]) == 1:
					kid.say(kid.line("trick"))
			var host := _round_host(entry["no"])
			if host and float(entry["time"]) > 1.5:
				entry["host"] = host
				entry["phase"] = "host"
				entry["time"] = 0.0
				host._walk_to(room["door_inside"], Guest.State.WALK)   # geht aufmachen (_open_doors)
			elif float(entry["time"]) > ROUND_KNOCK_EVERY * 3.0 + 2.0:
				_round_prank(entry, null)
		"host":
			var host: Guest = entry["host"]
			if host == null or host.dead or float(entry["time"]) > ROUND_WAIT:
				_round_prank(entry, null)
			elif door.is_open and host.global_position.distance_to(door.center()) < 2.0:
				_round_answer(entry, host)


## Wer dort wohnt, wach im Zimmer ist und nichts anderes tut.
func _round_host(no: String) -> Guest:
	for guest in living_guests():
		var g: Guest = guest
		if String(g.home["no"]) == no and not g.is_child() and g.hiding == null and builder.room_at(g.global_position) == no \
				and g.state in [Guest.State.IDLE, Guest.State.WALK]:
			return g
	return null


## Der Gast macht auf: Süßes (aus dem Vorrat, sonst irgendwas Süßes aus der Tasche) oder Schimpfe.
func _round_answer(entry: Dictionary, host: Guest) -> void:
	var kid: Guest = entry["kid"]
	var grumpy := String(host.profile.get("archetype", "")) == "Griesgram"
	var grinch := Grinch.is_grinch(host)   # Gustav gibt nie etwas (2.6)
	var sweets := 0 if grinch else int(host.stock.get(Item.Kind.SWEETS, 0))
	# Mit Süßem im Koffer gibt er immer, sonst nach Laune – aus der Süßigkeiten-Truhe seines Zimmers, solange sie nicht leer ist
	if sweets > 0 or (not grinch and randf() < (TRICK_GIVE_GRUMPY if grumpy else TRICK_GIVE) and take_room_sweet(String(host.home["no"]))):
		if sweets > 0:
			host.stock[Item.Kind.SWEETS] = sweets - 1
		kid.stock[Item.Kind.SWEETS] = int(kid.stock.get(Item.Kind.SWEETS, 0)) + 1
		host.say(TRICK_GIVE_LINES.pick_random())
		kid.say(kid.line("treat_other"))
		if Game.tracing:
			print("[Süßes oder Saures] %s bekommt Süßes von %s" % [kid.display_name, host.display_name])
		_round_done(entry, host)
		return
	host.say(TRICK_SCOLD_LINES.pick_random())
	_round_prank(entry, host)


## Eine Süßigkeit aus der Süßigkeiten-Truhe dieses Zimmers nehmen (Truhe aus dem Plan, LevelBuilder._sweets_chest) – sie
## liegt sichtbar darin. false = leer oder keine Truhe im Zimmer.
func take_room_sweet(no: String) -> bool:
	for node in get_tree().get_nodes_in_group("sweet_chests"):
		var chest := node as Chest
		if String(chest.get_meta("sweets_room", "")) != no:
			continue
		for item_node in get_tree().get_nodes_in_group("items"):
			var item := item_node as Item
			if item.kind == Item.Kind.SWEETS and not item.is_held and not item.is_queued_for_deletion() \
					and item.global_position.distance_to(chest.global_position) < 0.4:
				item.queue_free()
				return true
		return false
	return false


## Saures: ein Streich vor der Tür (Pranks, Spielkonzept 6.13) – dann weiter; holt das Kind dafür etwas, ist die Runde
## vorbei.
func _round_prank(entry: Dictionary, host: Guest) -> void:
	var kid: Guest = entry["kid"]
	kid.say(kid.line("scolded" if host else "prank"))
	if Game.tracing:
		print("[Süßes oder Saures] %s: Saures vor Zimmer %s" % [kid.display_name, entry["no"]])
	var busy := pranks.play(kid, entry["no"])
	_round_done(entry, host)
	if busy:
		_rounds.erase(kid.id)


## Tür wieder zu (der Gast geht zurück ins Zimmer), das Kind zur nächsten Tür.
func _round_done(entry: Dictionary, host: Guest) -> void:
	var kid: Guest = entry["kid"]
	var door: Door = builder.rooms[entry["no"]]["door"]
	if host:
		host._set_idle(randf_range(3.0, 6.0))
		get_tree().create_timer(2.5, false).timeout.connect(func() -> void:
			if is_instance_valid(door) and door.is_open and is_instance_valid(host) and not host.dead:
				door.set_open(false, false, true, host)
				door.locked = door.room_no == String(host.home["no"]))   # wieder abgeschlossen (6.19)
	entry["phase"] = "pause"
	entry["time"] = 0.0
	entry["next"] = randf_range(1.5, 3.0)
	kid.end_visit()


## Ein Kind, das nicht schlafen kann, klopft an Zimmer 13 – nur, wenn du drin bist. false = geht nicht.
func sleepless_visit(kid: Guest) -> bool:
	var p := Game.player
	if not _knock.is_empty() or p == null or p.dead or Game.director.zone_name_at(p.global_position) != "Zimmer 13":
		return false
	kid.set_meta("visit", "sleepless")
	start_visit(kid)
	return true


func _visit_enter(guest: Guest) -> void:
	guest.enter_shelter(builder.rooms[LevelBuilder.PLAYER_ROOM]["center"])
	guest.say(VISIT_HELLO.pick_random())
	change_relation(guest, 3.0)


## Erzfeinde: drohen, wenn sie dich allein sehen – beim nächsten Mal schlagen sie zu.
func _update_feuds() -> void:
	var p := Game.player
	if p == null or p.dead or p.hiding or p.in_dialog or p.sleeping:
		return
	for guest in living_guests():
		var g: Guest = guest
		if g.is_child() or tier(g) != Tier.STRONG_ENEMY or g.attack_cooldown > 0.0 or g.fear >= 60.0:
			continue
		if not g.state in [Guest.State.IDLE, Guest.State.WALK]:
			continue
		if g.global_position.distance_to(p.global_position) > 8.0 or not g.can_see_actor(p) or not p.recognized_by(g) \
				or _watched_by_others(p, g):
			continue
		if not g.threatened:
			g.threatened = true
			g.attack_cooldown = 25.0
			g.say(THREAT_LINES.pick_random())
			continue
		g.threatened = false
		g.attack_cooldown = randf_range(ATTACK_COOLDOWN.x, ATTACK_COOLDOWN.y)
		g.say(ATTACK_LINES.pick_random())
		g.start_attack()
		return


## Sieht außer `except` noch ein Gast den Spieler?
func _watched_by_others(p: Player, except: Guest) -> bool:
	for guest in living_guests():
		if guest != except and guest.can_see_actor(p):
			return true
	return false


## Alle Gäste außer `except`, die den Spieler gerade sehen – und erkennen (unter dem Laken nur aus der Nähe, 5.9).
func _witnesses_of_player(except: Guest) -> Array[Guest]:
	var list: Array[Guest] = []
	for guest in living_guests():
		if guest != except and guest.can_see_actor(Game.player) and Game.player.recognized_by(guest):
			list.append(guest)
	return list


## Der Spieler schlägt zu (Player, Linksklick): höchstens noch „wütend“, Zeugen, Gerede, Lärm.
func on_player_punched(guest: Guest, dir: Vector3) -> void:
	add_deed(guest, "hostile")
	change_relation(guest, minf(-30.0, -30.0 - guest.relation))
	Game.noise("punch", guest.global_position, Game.player)
	var witnesses := _witnesses_of_player(guest)
	for witness in witnesses:
		change_relation(witness, -10.0)
	if not witnesses.is_empty():
		witnesses[0].say("Hast du gerade %s geschlagen?!" % guest.display_name)
	var involved: Array = [guest]
	involved.append_array(witnesses)
	_spread_gossip(-6.0, involved)
	guest.stagger(dir * 3.5, true)


## Der Spieler rennt einen Gast um.
## Ein Kind umgerannt (6.13): Es weint, Mama oder Papa sind wütend, Zeugen mögen dich weniger.
func on_player_rammed(guest: Guest, dir: Vector3) -> void:
	add_deed(guest, "hostile")
	change_relation(guest, -8.0)
	for witness in _witnesses_of_player(guest):
		change_relation(witness, -6.0 if guest.is_child() else -3.0)
	var parent := guest.parent_guest()
	if parent:
		change_relation(parent, -20.0)
		add_deed(parent, "hostile")
		parent.say("Lass mein Kind in Ruhe!")
	guest.stagger(dir * 2.5, false)


## Der Spieler trifft einen Gast mit einem Wurf (Spielkonzept 3.13): Er ruft auf und mag dich weniger, mit einem Kürbis
## (oder etwas, das zerplatzt bzw. zerbricht) stärker; ein getroffenes Kind verärgert seine Eltern (wie Rammen, 6.13);
## Zeugen mögen dich weniger und erzählen es weiter (Gerede).
func on_player_threw_at(guest: Guest, item: Item, velocity: Vector3) -> void:
	if guest.dead:
		return
	var messy := item.kind in Item.BURST_KINDS
	add_deed(guest, "hostile")
	change_relation(guest, THROWN_AT_MESSY if messy else THROWN_AT)
	var witnesses := _witnesses_of_player(guest)
	for witness in witnesses:
		change_relation(witness, -6.0 if guest.is_child() else -3.0)
	var parent := guest.parent_guest()
	if parent:
		change_relation(parent, -20.0)
		add_deed(parent, "hostile")
		parent.say("Lass mein Kind in Ruhe!")
	if not witnesses.is_empty():   # wer es sah, erzählt es weiter
		var involved: Array = [guest]
		involved.append_array(witnesses)
		_spread_gossip(-4.0, involved)
	var push := Vector3(velocity.x, 0.0, velocity.z)
	guest.stagger(push.normalized() * minf(2.5, 0.25 * push.length() * sqrt(item.mass)), false)
	if Game.tracing:
		print("[Wurf] %s getroffen (%s)%s" % [guest.display_name, item.display_name,
			" – %d Zeugen" % witnesses.size() if not witnesses.is_empty() else ""])


## Ein wütender Gast rempelt dich an – seine Rache.
func on_guest_rammed_player(guest: Guest) -> void:
	add_deed(guest, "revenge")


## Ein Gast hat dich geschlagen.
func on_guest_hit_player(guest: Guest) -> void:
	add_deed(guest, "revenge")
	Game.noise("punch", Game.player.global_position, guest)


## Debug (--trick=13[,n]): Ein Kind steht vor der offenen Tür von Zimmer 13 und will Süßes; der Spieler gibt ihm n Stück
## (je 1,5 s eine, wie [E] am Kind).
func debug_trick_at_13(give: int) -> void:
	var kids := living_guests().filter(func(g: Guest) -> bool: return g.is_child())
	if kids.is_empty():
		return
	var kid: Guest = kids[0]
	var room: Dictionary = builder.rooms[LevelBuilder.PLAYER_ROOM]
	kid.global_position = (room["door_front"] as Vector3) + Vector3.UP * 0.05
	(room["door"] as Door).set_open(true, true, true)
	_trick_at_door(kid)
	for i in give:
		get_tree().create_timer(1.5 * (i + 1), false).timeout.connect(func() -> void:
			Game.player.receive_item(Item.create(Item.Kind.SWEETS))
			give_trick_sweet(kid))


## Es grollt (MonsterDirector, alle paar Sekunden bis zum Aufbruch, k = Lautstärke 0..1, Puppe 5.5): Die Gäste bekommen
## Angst (Mutige weniger), merken es sich als Erlebnis (sie erzählen davon), wer genug Angst hat, rennt heim und macht die
## Tür zu, Kinder laufen zu Mama oder Papa. Einer redet darüber – das Monster hört mit (4.7). Ab RUMBLE_PARTY_END löst
## sich eine Feier auf.
func on_rumble(k: float) -> void:
	for guest in living_guests():
		var g: Guest = guest
		if g.state in [Guest.State.SLEEP, Guest.State.GHOSTED]:
			continue
		if not g.remembers("rumble"):
			g.remember("rumble", g.global_position)
		if g.is_child():
			if k > 0.4 and randf() < 0.1 and g.parent_guest() and g.state in [Guest.State.IDLE, Guest.State.WALK]:
				g._run_to_parent()
			continue
		g.fear = minf(100.0, g.fear + RUMBLE_FEAR * k * (1.2 - float(g.profile["brave"])))
		if g.fear >= 60.0 and g.state in [Guest.State.IDLE, Guest.State.WALK] and not g._is_home():
			g.take_cover()
	if k >= RUMBLE_PARTY_END and party_active:
		end_party("Das Grollen übertönt die Musik. Die Feier löst sich auf.")
	var talkers := living_guests().filter(func(g: Guest) -> bool:
		return not g.is_child() and g.state in [Guest.State.IDLE, Guest.State.WALK, Guest.State.PARTY] and g.hiding == null)
	talkers.shuffle()
	for talker: Guest in talkers.slice(0, 6):
		var company := Game.player != null and Game.player.global_position.distance_to(talker.global_position) < 6.0
		for other in living_guests():
			if company:
				break
			company = other != talker and other.global_position.distance_to(talker.global_position) < 4.0
		if not company:
			continue
		talker.say(RUMBLE_LINES.pick_random())
		if randf() < RUMBLE_TALK_CHANCE:
			on_monster_talk(talker)   # es hört mit
		if Game.tracing:
			print("[Grollen] %s redet darüber (Angst %.0f)" % [talker.display_name, talker.fear])
		return
