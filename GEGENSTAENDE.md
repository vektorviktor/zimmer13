# Zimmer 13 – Gegenstände

Übersicht aller Gegenstände: was es im Spiel schon gibt, was geplant ist und was die Hauptgeschichte trägt. Die Regeln
stehen im [Spielkonzept](SPIELKONZEPT.md), der Ablauf der Geschichte in [HANDLUNG.md](HANDLUNG.md), der Code in
`scripts/world/item.gd` (`Item.Kind`).

**Stand:** **gebaut** = im Spiel · **teilweise** = da, aber nicht fertig · **geplant** = entschieden oder vorgemerkt,
nicht gebaut · **eingefroren** = bewusst zurückgestellt.
**Handlung:** **Hauptgeschichte** = ohne ihn kein Fortschritt in der Hauptgeschichte (HANDLUNG.md) · **Nebenstrang** =
trägt einen Auftrag (Kürbismann, Marion) · **–** = Spielmechanik, nicht handlungsrelevant.

Stand: 2026-11-03.

---

## 1. Schlüssel

| Gegenstand | Code | Stand | Handlung | Wozu / wo | Konzept |
|---|---|---|---|---|---|
| Schlüssel Zimmer 18 | `KEY` „zimmer_18“ | gebaut | **Hauptgeschichte** (Aufzug) | an der Leviathanmauer im Heizraum (2005 von Martin Ebert aus 018 verloren); öffnet Zimmer 18 mit Hausmeister-Notizbuch und Schaltschlüssel | 7.4, M7 |
| Generalschlüssel | Schlüsselbund „general“ | gebaut – Fundort seit 3.11. (ZIM-6) | – | Schlüsselschrank in der Lobby entfallen (ZIM-136); im Schreibtisch des Sekretariats in der zweiten Schublade mit Zahlenschloss (Code 1990, Vorschlag; Milas Ziffer aus der Nachtpartie fehlt, ZIM-8); öffnet jede Zimmertür | 6.19, 2.10 |
| Zweitschlüssel | Schlüsselbund „zimmer_…“ | gebaut | – | ein guter Freund gibt ihn dir bei der nächsten Begegnung; öffnet sein Zimmer, dort bist du willkommen, bleibt beim Schlosstausch | 6.19, 6.3 |
| Gestohlener Zimmerschlüssel | Schlüsselbund „zimmer_…“ (getauscht: „alt_zimmer_…“) | gebaut | – | einem schlafenden Gast vom Nachttisch genommen; öffnet sein Zimmer bis zum Morgen danach, dann ist das Schloss getauscht | 6.19 |
| Dachbodenschlüssel | `KEY` „dachboden“ | **teilweise** – Tür gebaut, Schlüssel fehlt | Nebenstrang (Kürbismann) | hinter der Leviathanmauer, ab etwa Tag 15 | 4.21, M14 |
| Schlüssel zum Haupteingang | `KEY` „ausgang“ | **teilweise** – Tür gebaut, Schlüssel fehlt (nur in der Hand, nicht am Bund) | **Hauptgeschichte** (Ende) | an Halloween; Fundort offen (K6) | 2.1, 2.7, M18 |
| Schaltschlüssel (Aufzug) | `KEY` „aufzug“ | gebaut – 28.10. in Zimmer 18, an den Bund; seit 3.11. (ZIM-14) in den Schlüsselschalter im Bedienfeld der Kabine (einer der drei Mängel) | **Hauptgeschichte** (Aufzug) | Tisch in Zimmer 18 | 7.4, M8 |
| Schlüsselbund des Rezeptionisten | – | geplant (Vorschlag) | Nebenstrang (Marion) | in der Jeansjacke des erlösten Kürbismanns; öffnet das Büro der Direktion | 2.8, M15b |
| Josefs Schlüsselbund | Schlüsselbund „josefs_bund“ | gebaut 3.11. (ZIM-6) mit **Zwischenort**: ab dem 14. seitlich am Kessel im Heizkeller, bis es U2 gibt | Nebenstrang (Marion) | gehört an den alten Kessel im alten Heizkeller (U2), ab Aufzug oder Leviathanmauer; öffnet Sekretariat und Büro der Direktion – zweiter Weg, wenn der Kürbismann nicht erlöst ist; Hinweis von Marion (gebaut, ab dem 14. im Gespräch) oder im Kesselbuch (fehlt) | 2.8, M15b |
| Sekretariatsschlüssel | Schlüsselbund „sekretariat“ | gebaut 3.11. (ZIM-6) mit **Zwischenort**: ab dem 6. an der Wand neben dem Sicherungskasten im Maschinenraum, bis es Spind und Bruno gibt (ZIM-4) | Nebenstrang (Marion; Generalschlüssel, Foto 2005) | hing neben der Hauptsicherung im Spind des Hausmeisters; Bruno behält ihn ab Nacht 5, zu bekommen über Freundschaft, Handel, Mäxchen, Klauen | 2.10, K3 |
| Schlüssel zum westlichen Kellerschloss | – | geplant (Ort 2026-11-03, ZIM-12) | – (Abkürzung in den Westteil des Kellers) | Werkzeugkasten im Technikraum (UG) | 7.4 |
| ~~Werkstattschlüssel~~ | – | gestrichen 2026-10-27 (Werkstatt entfällt zugunsten des alten Heizkellers) | – | – | 2.8, 7.4 |
| Schlüssel von 1987 (Messinganhänger) | `KEY` „zimmer_042“ | gebaut (Zimmer 042 selbst noch nicht versiegelt) | – (optional; Edna, K5 – Zimmer ihres Verlobten Heinrich Brehm) | im Krähennest im großen Baum gegenüber 042; kommt als Geschenk der Krähen bei hoher Gunst nach Fütterungen an drei Tagen oder fällt beim Wurf ins Nest heraus; schließt Zimmer 042 auf (der Mann, der 1987 nicht hinauskam) | 4.25, 6.19 (7) |
| Spindschlüssel (Pool-Umkleiden) | `KEY` „spind_NN“ (Bund: „Spindschlüssel N“) | **teilweise** – Spinde 7, 20, 32, 44 schließen damit auf (ZIM-145, `LockerBank.OPENABLE`), Schlüssel liegen noch nirgends | – | Fundorte offen; ohne Modell (Nutzer 31.10.) | – |
| Schlüssel der übrigen versiegelten Zimmer | – | geplant | – (optional) | 132 von Liesel (Freund), 038 über einen Brief des Gastes von 1987 (Versteck offen), 018 an der Leviathanmauer | 6.19 (7), ZIM-30 |
| Familienfoto der Brücks (1987) | – | geplant | – (optional; Liesel) | im versiegelten Zimmer 132; Liesel bringen = Abschluss für sie | 6.19 (7), ZIM-30 |
| Brief des Gastes aus 038 | – | geplant | – (optional) | nie abgeschickt, nennt das Versteck des Schlüssels zu 038; Ort offen | 6.19 (7), ZIM-30 |

## 2. Auftrags- und Fundstücke

| Gegenstand | Code | Stand | Handlung | Wozu / wo | Konzept |
|---|---|---|---|---|---|
| Gustavs Brille | – | geplant | **Hauptgeschichte** (Grund für den ersten Abstieg; Doris' Aufgabe) | an der Leviathanmauer im Heizraum; Doris geben bis 4.10., 20 Uhr, dann verschwindet sie – sonst gewöhnlicher Gegenstand, Gäste stehlen sie nicht | 2.9, M7, M7a |
| Gustavs Blechdose | – | geplant (eigener Gegenstand oder nur der Inhalt: offen) | – (Doris' Dank; Faden der Kinder) | Doris gibt sie nach der Brille; darin Süßes, Pappgespenst, Zierkürbis für die Kinder | 2.9, M7a |
| Kopf des Kürbismanns | `PUMPKIN_HEAD` | **teilweise** – Platzhaltermodell auf dem Dachboden, Ritual fehlt | Nebenstrang (Liesel) | Kürbismann erlösen | 4.21, 2.7, M14 |
| Hauptsicherung des Aufzugs | `FUSE` | **teilweise** – Gegenstand und Fach „AUFZUG“ am Sicherungskasten gebaut 3.11. (ZIM-14); Spind, Einbruch und Bruno fehlen (ZIM-4), im Spiel bisher nicht zu finden | **Hauptgeschichte** (Aufzug) | jede Ernte im Spind des Hausmeisters (Hausmeisterraum, EG); Bruno bricht ihn in Nacht 5 auf und behält sie als Faustpfand; Sicherungskasten im UG | 7.4, M9, K3 |
| Spind des Hausmeisters | – | geplant (Plan: `#747567`) | **Hauptgeschichte** (Aufzug) | Hausmeisterraum (`#c4d35b`); Vorhängeschloss, ab Nacht 5 aufgebrochen; Brecheisen öffnet ihn vorher (laut) | 2.11, 7.4 |
| Seine Sachen: Taschenuhr, Mütze, Foto von Marion | – | geplant (Inhalt: Vorschlag) | Nebenstrang (Marion) | Karton „Personal 1987“ im Lager in U2 | 2.8, M15a |
| Vertrag (das Abkommen) | – | geplant | Nebenstrang (Marion) | Büro der Direktion; im Feuer von 1987 verbrennen | 2.3, 2.8, M15b |
| Schädel des Kürbismanns | – | geplant | – (Belohnung) | nach der Erlösung; stärkste Deko | 4.21 |
| Blutige Axt | – | geplant | – (Belohnung) | nach der Erlösung; an der Tür klaut keiner | 4.21 |
| Jeansjacke | – | geplant | Nebenstrang (Marion, Schlüsselbund) | nach der Erlösung; Deko | 4.21, 2.8 |
| Fundsachen-Koffer früherer Gäste | – | geplant | Hauptgeschichte (Lager, K5) | Lager in U2; Namen der Warnungszettel, fest auch im Register (u. a. Heinrich Brehm 1987, Rudolf Hain 2008) | 7.4, M11 |
| Silberstock des alten Herrn | – | geplant (2026-11-03, ZIM-8) | – (Brunos Herzensbitte statt Lieblingskürbis) | lehnt im Büro der Direktion am roten Sessel wie auf dem Porträt; Schlangenkopf aus Silber, unter dem Knauf „31.10.1987“; Bruno kennt ihn von der Fotowand | 6.14, 2.10 |
| Goldener Ehering („O. & G. 1976“) | `RING` | gebaut 2026-11-03 | – (seltene Bitte „Wiederfinden“) | Gerda Wagners (H10, Zimmer 007); im Krähennest vor dem Dachfenster nahe dem Futtertisch, durchs aufgeklappte Fenster zu greifen; ihr schenken → Freundschaft und ein kleines Geschenk (Kerze, sonst Bonbons); sie steckt ihn gleich an; draußen abgelegt stehlen ihn die Krähen wieder | 4.25, 6.14, ZIM-50 |
| ~~Kohle~~ | – | gestrichen 2026-10-27 (Kessel ist Attrappe) | – | – | 7.4 |
| Bolzenschneider | – | eingefroren | – | Lager aufbrechen | 7.4 |

## 3. Dokumente und Lesbares

| Gegenstand | Code | Stand | Handlung | Wozu / wo | Konzept |
|---|---|---|---|---|---|
| Willkommensbrief | Brief auf dem Schreibtisch | gebaut | **Hauptgeschichte** (Start) | Zimmer 13; schickt zum Aushangbrett | 2.5, M1 |
| Notizbuch des Spielers | `Notebook` | gebaut | **Hauptgeschichte** (Aufgaben, Notizen) | immer dabei | 3.10 |
| Tagebuch in Zimmer 13 | `Diary` | gebaut | – (Speichern, Wendepunkte) | Zimmer 13 | 3.10, 8.5 |
| Aushangbrett (Wettbewerb, Hausordnung) | `NoticeBoard` | gebaut | **Hauptgeschichte** (Regel der Puppe) | Lobby | 2.5, M5 |
| Warnungszettel 1987–2019 | `WarningNote` | gebaut (sechs Zettel) | Hauptgeschichte (Hinweise; 1987 = Edna) | verteilt; je eine UV-Zeile | 4.13, 2.5, 2.7 |
| Kartenblätter (EG, OG, Keller) | `MAP` | gebaut | – (Orientierung; Keller: „hier unten schläft es“) | Keller-Skizze in Zimmer 017 | 3.2, 7.9 |
| UV-Schrift an Wänden (Josef 1987, „J. A.“) | `UvMark` | teilweise (Texte teils neu zu fassen) | Hauptgeschichte (Name Ahrend) | Heizraum, Zimmer 017, Zimmer 18, Zimmer 13 (Claras Botschaft an Martin, 2005, ZIM-37; weitere Hinweise von 13 und 018: Entwürfe in 7.4 – Fleck an der Fotowand, Leviathanmauer) | 4.16, 2.3, 7.4 |
| Gustavs Tagebuch | – | gebaut 26.10. (fest auf dem Tisch, wächst mit den Tagen) | **Hauptgeschichte** (Regel, Zug zum Keller) | Zimmer 020, nach der Siegerehrung | 2.6, M4 |
| Mitteilung „Herr Peters ist abgereist“ | `NoticeBoard` | gebaut | Hauptgeschichte (Lüge der Direktion) | Aushangbrett, 3.10. morgens | 2.9, M6 |
| Doris' Brief | – | geplant | – (Schuld, wenn man ihre Aufgabe nicht erfüllt) | Tisch in Zimmer 033, ab 4.10., 20 Uhr | 2.9, M7b |
| Hotelregister | – (festes Buch, `HotelRegister`) | gebaut 28.10. – [E] blättert von Oktober 2026 zurück bis 1987; Kreuz am Morgen nach einem Tod | **Hauptgeschichte** (Kreuze, „geb. Ahrend“, „geb. Kessler“, feste Namen 1987/2005/2008, ZIM-7) | Rezeption | 2.3, K1, M6, M13 |
| Notizbuch des Hausmeisters | – (festes Buch, `CaretakerBook`) | gebaut 28.10. – vier Seiten, gelesen: drei Aufgaben im Notizbuch; Texte Vorschlag (Sicherung im Spind seit 30.10.) | **Hauptgeschichte** (drei Mängel am Aufzug) | Tisch in Zimmer 18 | 7.4, M8 |
| Kesselbuch Josefs | – | geplant | **Hauptgeschichte** (Name Ahrend → Marion) | Josefs Spind im Heizraum | 2.3, 7.4, M12 |
| Personalakte Josefs | – | geplant | Hauptgeschichte (Name, Foto) | Büro der Direktion? | 2.3 |
| Dienstplan vom 31.10.1987 | – | Vorschlag | Hauptgeschichte (der Page am Heizkeller) | Karton „Personal 1987“ oder Sekretariat | 2.11 |
| Schreibmaschine der Chefsekretärin | – | Vorschlag | Hauptgeschichte (springende Type: Briefe von heute = Vertrag 1987) | Sekretariat | 2.11 |
| Aushang „Eigentum entwendet“ | `NoticeBoard` | geplant | Hauptgeschichte (Sicherung) | Aushangbrett, 6.10. morgens | 7.4, K3 |
| Zeitungsausschnitt „Brand im Grandhotel“ | – | geplant | Hauptgeschichte (Indiz) | offen | 2.3 |
| Dorés „Die Zerstörung des Leviathan“ | – (fester Druck, `LeviathanName.PrintSheet`) | **gebaut** – echter Holzstich (gemeinfrei), [E] ansehen | – (gibt dem Monster seinen Namen) | Hugo Steins Koffer → Couchtisch der Lobby → Westwand der Lobby neben dem Aushangbrett | 4.32 |

## 4. Deko

| Gegenstand | Code | Stand | Handlung | Wozu | Konzept |
|---|---|---|---|---|---|
| Kürbis (Sorten bis Riesenkürbis) | `PUMPKIN` | gebaut | – | Deko, schnitzen, braten, werfen; große Sorten betäuben den Kürbismann gezeigt etwa 5 s · als Lieblingskürbis erbeten (Bitte, 6.14) | 5.8, 4.21 |
| Geschnitzter Kürbis | `CARVED_PUMPKIN` | gebaut | – | Deko, mit Kerze Licht; betäubt den Kürbismann gezeigt etwa 5 s · Brunos Herzensbitte, Lieblingskürbis geschnitzt (6.14) | 5.4, 4.21 |
| Zierkürbis | `MINI_PUMPKIN` | gebaut | – | kleine Deko, passt in die Tasche | 5.8 |
| Kerze | `CANDLE` | gebaut (Abbrennen 27.10.) | – | Licht, geht aus, anzünden, brennt in etwa einem Spieltag ab · Ednas Herzensbitte, kleine Bitte am Abend (6.14) | 5.12 |
| Lakengespenst | `SHEET_GHOST` | gebaut | – | Deko zum Aufhängen; lockt den Lakengeist | 5.6 |
| Lichterkette | `LIGHT_STRING` | gebaut | – | Deko zum Aufhängen | 5.6 |
| Spinnenweben | `COBWEB` | gebaut | – | Deko aus dunklen Ecken · Herzensbitte der Skeptiker (6.14) | 5.4 |
| Herbstlaub | `LEAVES` | gebaut | – | Deko aus dem Garten | 5.4 |
| Fledermausgirlande | `BAT_GARLAND` | gebaut | – | Deko zum Aufhängen | 5.7 |
| Plastikspinne | `SPIDER` | gebaut | – | Deko zum Aufhängen | 5.7 |
| Totenkopf | `SKULL` | gebaut | – | starke Deko, mit Kerze Licht · Herzensbitte der Geschäftstüchtigen, 15 Geld (6.14) | 5.7 |
| Hexenbesen | `BROOM` | gebaut | – | Deko, lehnt an der Wand | 5.7 |
| Maske (eigene) | – | geplant | – | für den Maskenball und das Maskenspiel; von Ruth Behrens genäht oder irgendwo gefunden (Gäste-Masken sind keine Gegenstände) | 5.19 |
| Verbotene Masken (acht: Leviathan, Kürbismann, Lakengeist, Vampir, Puppe, Vogelscheuche, Krähe, Kesselkatze) | `MASK` „pumpkin“, „doll“ | **teilweise** – Kürbismann und Puppe gebaut (Modell, tragen, Wirkung), die übrigen sechs fehlen; Verstecke, Zettel, Verleihen und Trophäen fehlen | – | rufen ihre eigene Bedrohung; Maskenboard mit acht Stiften in Zimmer 13 (leere zeigen nur, wie viele fehlen, nicht welche) – Kürbismann und Puppe hängen vorerst von Anfang an dort; Kürbismann: Spaßschwelle drastisch tiefer, Träger ist sein Ziel · Puppe: nächstes Urteil auf die Tür des Trägers | 5.19 |

## 5. Licht und Werkzeug

| Gegenstand | Code | Stand | Handlung | Wozu | Konzept |
|---|---|---|---|---|---|
| Taschenlampe | `FLASHLIGHT` | gebaut | – | Licht, mit Aufsatz UV | 4.16 |
| Batterie | `BATTERY` | gebaut | – | Taschenlampe | 4.16 |
| UV-Aufsatz | `UV_FILTER` | gebaut | – (zeigt UV-Hinweise, vertreibt das Monster) | auf die Taschenlampe; liegt auf dem Tisch in Zimmer 18 (fehlte seit dem Gebäudeplan, wieder da seit 28.10.) | 4.16, 7.4 |
| Glühbirne (heil/kaputt) | `BULB` | gebaut | – | Lampen ein- und ausdrehen · Herzensbitte der Bastler (6.14) · Gäste holen Ersatz aus dem Lager (EG West) oder klauen ihn | 7.3 |
| Streichholzschachtel | `MATCHBOX` | gebaut | – | Kerzen anzünden; Zimmer 022 | 5.12 |
| Messer | `KNIFE` | gebaut | – | schnitzen | 5.4 |
| Brecheisen | `CROWBAR` | gebaut | – | Zimmertüren aufbrechen; Heizraum | 6.19 |
| Werkzeugkasten | `TOOLBOX` | gebaut | – | Türen reparieren | 6.19 |
| Kompass | `COMPASS` | gebaut | – | Orientierung | 3.2 |
| Bettlaken | `BED_SHEET` | gebaut | – | selbst verkleiden; Zimmer 13 | 5.9 |
| Sturmlaterne | – | geplant | – (optional) | Licht, das draußen nicht ausgeht; im versiegelten Zimmer 042 | 6.19 (7), 5.12 |
| Ölkännchen | – | geplant | – (optional) | eine geölte Tür quietscht nicht mehr (Lärm 4.15), begrenzte Füllung; im versiegelten Zimmer 038 | 6.19 (7), ZIM-30 |
| Salzpackung | `SALT` | gebaut | – | Salzlinien an Tür und Fenster halten den Lakengeist aus dem Zimmer; drei auf der Küchenzeile; rettet die zwei Gäste mit „kreisenden Händen“ (Edna streut aus eigener Packung, kein Gegenstand) | 5.13 |

## 6. Essen und Trinken

| Gegenstand | Code | Stand | Handlung | Wozu | Konzept |
|---|---|---|---|---|---|
| Süßigkeiten | `SWEETS` | gebaut | – | Kinder, Süßes oder Saures, Geschenk · kleine Bitte der Kinder (6.14) | 6.13 |
| Getränkedose (Cola, Limo) | `SODA_CAN` | gebaut | – | zu Atem kommen, beruhigt | 3.2 |
| Kaffee | `COFFEE` | gebaut | – | wach halten · kleine Bitte am Morgen (6.14) | 3.11 |
| Tee | `TEA` | gebaut | – | beruhigt · Herzensbitte der Griesgrame (6.14) | 3.12 |
| Glas von der Bar (Bier, Rotwein, Schnaps) | `GLASS` (Sorte im Zusatz) | gebaut | – | Rausch und weniger Schock, verschenkbar – Rotwein ist manchen Gästen Lieblingsgeschenk · kleine Bitte am Abend (6.14) · Kinder nie | 3.7 |
| Gebratener Kürbis | `ROAST_PUMPKIN` | gebaut | – | Essen | 3.8 |
| Kürbismatsch | `PUMPKIN_MUSH` | gebaut | – | Rest eines zerplatzten Kürbisses | 5.8, 3.13 |
| Apfel | `APPLE` | gebaut | – | beim Apfeltauchen erbeutet, essbar | 6.21 |
| Brotkrumen | `PUMPKIN_SEEDS` „brot“ | gebaut | – | Krähenfutter für den Tisch im Gärtchen von Zimmer 13 (Tisch fehlt noch im Plan); Vorrat auf der Küchenzeile, wächst nach (Tasche) | 4.25 |
| Kürbiskerne | `PUMPKIN_SEEDS` | gebaut | – | fallen beim Schnitzen ab (Tasche); Krähenfutter für den Tisch im Gärtchen von Zimmer 13 | 4.25, 5.4 |
| Ei | `EGG` | gebaut | – | Eierkarton in der Küche (morgens wieder 10, Tasche); zerplatzt beim Wurf oder Fall – Fleck an Tür, Scheibe, Wand oder Boden, wegwischen; Kinder werfen sie bei Saures, du auch (Zeugen) | 6.13, 3.13 |

## 7. Spiele und Sonstiges

| Gegenstand | Code | Stand | Handlung | Wozu | Konzept |
|---|---|---|---|---|---|
| Würfelbecher | `DICE_CUP` | gebaut | – | Mäxchen | 6.10 |
| Gezinkte Würfel | `LOADED_DICE` | gebaut | – | beim Mäxchen schummeln | 6.10 |
| Schachbrett | `CHESS_BOARD` | gebaut | – | Schach mit Gästen | 6.10 |
| Dartpfeile | `DARTS` | gebaut | – | Darts | 6.10 |
| Kartenspiel, Bierdeckel, Quizkarten, Leere Flasche | `BAR_GAME` (Sorte im Zusatz) | gebaut | – | Barspiele aus dem Spieleschrank: 17 und 4, Bierdeckel-Turm, Kneipenquiz, Wahrheit oder Pflicht | 6.10 |
| Marions Spieluhr | `MUSIC_BOX` | gebaut | Josef Ahrend, Marion (2.3); später fürs Ritual (2.8) | Aufziehen lockt das Monster, nah horcht es; im Heizraum auf dem alten Regal | 5.17 |
| Münzen | `COINS` | gebaut | – | werden zu Geld; draußen holen sie die Krähen ins Nest; Geschenk der Krähen | 3.2, 4.25 |
| Kleidungsstück | `CLOTHING` | gebaut | – (Spur eines Geholten) | bleibt nach einem Todesfall liegen | 6.7, 4.13 |

---

## Lücken für die Hauptgeschichte

Was die Hauptgeschichte braucht und noch fehlt, in der Reihenfolge des Durchlaufs (HANDLUNG.md):
1. Gustavs Tagebuch (M4) · Hotelregister (M6) · Gustavs Brille (M7)
2. Notizbuch des Hausmeisters und Schaltschlüssel (M8) · Hauptsicherung aus dem Spind (M9)
3. Kesselbuch (M12) · Dachbodenschlüssel (M14)
4. Seine Sachen, Vertrag, Schlüsselbund (M15a, M15b) – nur für die Erlösung (Kür, 2.8)
5. Schlüssel zum Haupteingang (M18) – Fundort noch offen
