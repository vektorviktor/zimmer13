# Zimmer 13 – Gegenstände

Übersicht aller Gegenstände: was es im Spiel schon gibt, was geplant ist und was die Hauptgeschichte trägt. Die Regeln
stehen im [Spielkonzept](SPIELKONZEPT.md), der Ablauf der Geschichte in [HANDLUNG.md](HANDLUNG.md), der Code in
`scripts/world/item.gd` (`Item.Kind`).

**Stand:** **gebaut** = im Spiel · **teilweise** = da, aber nicht fertig · **geplant** = entschieden oder vorgemerkt,
nicht gebaut · **eingefroren** = bewusst zurückgestellt.
**Handlung:** **Hauptgeschichte** = ohne ihn kein Fortschritt in der Hauptgeschichte (HANDLUNG.md) · **Nebenstrang** =
trägt einen Auftrag (Kürbismann, Marion) · **–** = Spielmechanik, nicht handlungsrelevant.

Stand: 2026-10-25.

---

## 1. Schlüssel

| Gegenstand | Code | Stand | Handlung | Wozu / wo | Konzept |
|---|---|---|---|---|---|
| Schlüssel Zimmer 18 | `KEY` „zimmer_18“ | gebaut | **Hauptgeschichte** (Aufzug) | liegt im Heizkeller; öffnet Zimmer 18 mit Hausmeister-Notizbuch und Schaltschlüssel | 7.4, M7 |
| Generalschlüssel | Schlüsselbund | gebaut | – | Schlüsselschrank in der Lobby, Scheibe einschlagen; öffnet jede Zimmertür | 6.19 |
| Dachbodenschlüssel | `KEY` „dachboden“ | **teilweise** – Tür gebaut, Schlüssel fehlt | Nebenstrang (Kürbismann) | hinter dem Gitter im Heizkeller, ab etwa Tag 15 | 4.21, M14 |
| Schlüssel zum Haupteingang | `KEY` „ausgang“ | **teilweise** – Tür gebaut, Schlüssel fehlt (nur in der Hand, nicht am Bund) | **Hauptgeschichte** (Ende) | an Halloween; Fundort offen (K6) | 2.1, 2.7, M18 |
| Schaltschlüssel (Aufzug) | – | geplant | **Hauptgeschichte** (Aufzug) | Zimmer 18 | 7.4, M8 |
| Schlüsselbund des Rezeptionisten | – | geplant (Vorschlag) | Nebenstrang (Marion) | in der Jeansjacke des erlösten Kürbismanns; öffnet das Büro der Direktion | 2.8, M15b |
| Werkstattschlüssel | – | geplant (Vorschlag) | Nebenstrang (Marion) | Schlüsselbrett im Büro der Direktion; öffnet die Werkstatt im Tiefkeller | 2.8, M15b |
| Schlüssel von 1987 (Messinganhänger) | – | geplant | – (optional; Edna, K5) | im Krähennest im großen Baum; öffnet das versiegelte Zimmer 042 des Mannes, der 1987 nicht hinauskam | 4.25, 6.19 (7) |
| Schlüssel der übrigen versiegelten Zimmer | – | geplant | – (optional) | je Zimmer ein eigener Weg (Krähen, Freund, Dokument, Wagnis) | 6.19 (7) |

## 2. Auftrags- und Fundstücke

| Gegenstand | Code | Stand | Handlung | Wozu / wo | Konzept |
|---|---|---|---|---|---|
| Kopf des Kürbismanns | `PUMPKIN_HEAD` | **teilweise** – Platzhaltermodell auf dem Dachboden, Ritual fehlt | Nebenstrang (Liesel) | Kürbismann erlösen | 4.21, 2.7, M14 |
| Ersatzsicherung | – | geplant | **Hauptgeschichte** (Aufzug) | ein Gast hat sie (Kandidat: Bruno); Sicherungskasten im UG | 7.4, M9 |
| Seine Sachen: Taschenuhr, Mütze, Foto von Marion | – | geplant (Inhalt: Vorschlag) | Nebenstrang (Marion) | Karton „Personal 1987“ im Lager im Tiefkeller | 2.8, M15a |
| Vertrag (das Abkommen) | – | geplant | Nebenstrang (Marion) | Büro der Direktion; im Feuer von 1987 verbrennen | 2.3, 2.8, M15b |
| Schädel des Kürbismanns | – | geplant | – (Belohnung) | nach der Erlösung; stärkste Deko | 4.21 |
| Blutige Axt | – | geplant | – (Belohnung) | nach der Erlösung; an der Tür klaut keiner | 4.21 |
| Jeansjacke | – | geplant | Nebenstrang (Marion, Schlüsselbund) | nach der Erlösung; Deko | 4.21, 2.8 |
| Fundsachen-Koffer früherer Gäste | – | geplant | Hauptgeschichte (Lager, K5) | Lager im Tiefkeller; Namen der Warnungszettel | 7.4, M11 |
| Ring eines Gastes | – | geplant | – (Gastauftrag, offen) | im Krähennest vor einem Dachfenster | 4.25, IDEEN.md 6 |
| Kohle | – | eingefroren | – | Kessel anheizen | 7.4 |
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
| UV-Schrift an Wänden (Heizer 1987, „J. A.“) | `UvMark` | teilweise (Texte teils neu zu fassen) | Hauptgeschichte (Name Ahrend) | Heizkeller, Zimmer 017, Zimmer 18 | 4.16, 2.3 |
| Gustavs Tagebuch | – | geplant | **Hauptgeschichte** (Regel, Zug zum Keller) | Zimmer 020, nach der Siegerehrung | 2.6, M4 |
| Hotelregister | – | geplant | **Hauptgeschichte** (Kreuze, „geb. Ahrend“, „geb. K…“) | Rezeption | 2.3, K1, M6, M13 |
| Notizbuch des Hausmeisters | – | geplant | **Hauptgeschichte** (drei Mängel am Aufzug) | Zimmer 18 | 7.4, M8 |
| Kesselbuch des Heizers | – | geplant | **Hauptgeschichte** (Name Ahrend → Marion) | Heizkeller | 2.3, 7.4, M12 |
| Personalakte des Heizers | – | geplant | Hauptgeschichte (Name, Foto) | Büro der Direktion? | 2.3 |
| Zeitungsausschnitt „Brand im Grandhotel“ | – | geplant | Hauptgeschichte (Indiz) | offen | 2.3 |
| Marions Brief | – | offen | Nebenstrang (war: falls sie vorher stirbt – Kernfiguren sterben seit 2026-10-25 nicht; streichen oder anders auslösen) | Zimmer 001 | 2.8 |
| Dorés „Die Zerstörung des Leviathan“ | – | geplant | – (gibt dem Monster seinen Namen) | Hugo Steins Koffer, danach an der Fotowand | 4.32 |

## 4. Deko

| Gegenstand | Code | Stand | Handlung | Wozu | Konzept |
|---|---|---|---|---|---|
| Kürbis (Sorten bis Riesenkürbis) | `PUMPKIN` | gebaut | – | Deko, schnitzen, braten, werfen; betäubt den Kürbismann | 5.8, 4.21 |
| Geschnitzter Kürbis | `CARVED_PUMPKIN` | gebaut | – | Deko, mit Kerze Licht | 5.4 |
| Zierkürbis | `MINI_PUMPKIN` | gebaut | – | kleine Deko, passt in die Tasche | 5.8 |
| Kerze | `CANDLE` | gebaut | – | Licht, geht aus, anzünden | 5.12 |
| Lakengespenst | `SHEET_GHOST` | gebaut | – | Deko zum Aufhängen; lockt den Lakengeist | 5.6 |
| Lichterkette | `LIGHT_STRING` | gebaut | – | Deko zum Aufhängen | 5.6 |
| Spinnenweben | `COBWEB` | gebaut | – | Deko aus dunklen Ecken | 5.4 |
| Herbstlaub | `LEAVES` | gebaut | – | Deko aus dem Garten | 5.4 |
| Fledermausgirlande | `BAT_GARLAND` | gebaut | – | Deko zum Aufhängen | 5.7 |
| Plastikspinne | `SPIDER` | gebaut | – | Deko zum Aufhängen | 5.7 |
| Totenkopf | `SKULL` | gebaut | – | starke Deko, mit Kerze Licht | 5.7 |
| Hexenbesen | `BROOM` | gebaut | – | Deko, lehnt an der Wand | 5.7 |
| Maske (eigene) | – | geplant | – | für den Maskenball und das Maskenspiel; von Ruth Behrens genäht oder irgendwo gefunden (Gäste-Masken sind keine Gegenstände) | 5.19 |
| Verbotene Masken (acht: Leviathan, Kürbismann, Lakengeist, Vampir, Puppe, Vogelscheuche, Krähe, Kesselkatze) | – | geplant | – | rufen ihre eigene Bedrohung; Sammlung an acht Haken in Zimmer 13 (Trophäen 8.11), an Gäste nur verliehen | 5.19 |

## 5. Licht und Werkzeug

| Gegenstand | Code | Stand | Handlung | Wozu | Konzept |
|---|---|---|---|---|---|
| Taschenlampe | `FLASHLIGHT` | gebaut | – | Licht, mit Aufsatz UV | 4.16 |
| Batterie | `BATTERY` | gebaut | – | Taschenlampe | 4.16 |
| UV-Aufsatz | `UV_FILTER` | gebaut | – (zeigt UV-Hinweise, vertreibt das Monster) | Taschenlampe | 4.16 |
| Glühbirne (heil/kaputt) | `BULB` | gebaut | – | Lampen ein- und ausdrehen | 7.3 |
| Streichholzschachtel | `MATCHBOX` | gebaut | – | Kerzen anzünden; Zimmer 022 | 5.12 |
| Messer | `KNIFE` | gebaut | – | schnitzen | 5.4 |
| Brecheisen | `CROWBAR` | gebaut | – | Zimmertüren aufbrechen; Heizkeller | 6.19 |
| Werkzeugkasten | `TOOLBOX` | gebaut | – | Türen reparieren | 6.19 |
| Kompass | `COMPASS` | gebaut | – | Orientierung | 3.2 |
| Bettlaken | `BED_SHEET` | gebaut | – | selbst verkleiden; Zimmer 13 | 5.9 |
| Sturmlaterne | – | geplant (Vorschlag) | – (optional) | Licht, das draußen nicht ausgeht; im versiegelten Zimmer 042 | 6.19 (7), 5.12 |
| Salzpackung | `SALT` | gebaut | – | Salzlinien an Tür und Fenster halten den Lakengeist aus dem Zimmer; drei auf der Küchenzeile | 5.13 |

## 6. Essen und Trinken

| Gegenstand | Code | Stand | Handlung | Wozu | Konzept |
|---|---|---|---|---|---|
| Süßigkeiten | `SWEETS` | gebaut | – | Kinder, Süßes oder Saures, Geschenk | 6.13 |
| Getränkedose (Cola, Limo) | `SODA_CAN` | gebaut | – | zu Atem kommen, beruhigt | 3.2 |
| Kaffee | `COFFEE` | gebaut | – | wach halten | 3.11 |
| Tee | `TEA` | gebaut | – | beruhigt | 3.12 |
| Gebratener Kürbis | `ROAST_PUMPKIN` | gebaut | – | Essen | 3.8 |
| Kürbismatsch | `PUMPKIN_MUSH` | gebaut | – | Rest eines zerplatzten Kürbisses | 5.8, 3.13 |
| Apfel | `APPLE` | gebaut | – | beim Apfeltauchen erbeutet, essbar | 6.21 |
| Brotkrumen | – | geplant | – | Krähenfutter für den Tisch im Gärtchen von Zimmer 13; Vorrat in der Küche | 4.25 |
| Kürbiskerne | – | geplant | – | Krähenfutter; fallen beim Schnitzen ab | 4.25, 5.4 |

## 7. Spiele und Sonstiges

| Gegenstand | Code | Stand | Handlung | Wozu | Konzept |
|---|---|---|---|---|---|
| Würfelbecher | `DICE_CUP` | gebaut | – | Mäxchen | 6.10 |
| Gezinkte Würfel | `LOADED_DICE` | gebaut | – | beim Mäxchen schummeln | 6.10 |
| Schachbrett | `CHESS_BOARD` | gebaut | – | Schach mit Gästen | 6.10 |
| Dartpfeile | `DARTS` | gebaut | – | Darts | 6.10 |
| Marions Spieluhr | `MUSIC_BOX` | gebaut | Josef Ahrend, Marion (2.3); später fürs Ritual (2.8) | Aufziehen lockt das Monster, nah horcht es; im Heizkeller auf dem alten Regal | 5.17 |
| Münzen | `COINS` | gebaut | – | werden zu Geld; draußen holen sie die Krähen | 3.2, 4.25 |
| Kleidungsstück | `CLOTHING` | gebaut | – (Spur eines Geholten) | bleibt nach einem Todesfall liegen | 6.7, 4.13 |

---

## Lücken für die Hauptgeschichte

Was die Hauptgeschichte braucht und noch fehlt, in der Reihenfolge des Durchlaufs (HANDLUNG.md):
1. Gustavs Tagebuch (M4) · Hotelregister (M6)
2. Notizbuch des Hausmeisters und Schaltschlüssel (M8) · Ersatzsicherung (M9)
3. Kesselbuch (M12) · Dachbodenschlüssel (M14)
4. Seine Sachen, Vertrag, Schlüsselbund, Werkstattschlüssel (M15a, M15b) – nur für die Erlösung (Kür, 2.8)
5. Schlüssel zum Haupteingang (M18) – Fundort noch offen
