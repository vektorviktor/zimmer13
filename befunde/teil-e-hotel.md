# Befunde Teil E – Hotel, Menüs, Speichern, Rest

Geprüft wurden SPIELKONZEPT Kap. 7–11 (Z. 5132–6287) vollständig, dazu gezielt per Grep HANDLUNG.md, HAUSHALTE.md,
die Kap. 2.1, 2.8, 4.21 und 6.19 sowie 14 Code-Stichproben. Kapitel 7 ist über drei Wochen schichtweise gewachsen: Die
Entscheidungen vom 27.10. (Keller/U2), 30.10. (Halloween-Schlüssel, Einbruch) und 3.11. (ZIM-14, ZIM-42, ZIM-58) stehen
neben älteren Absätzen, die ihnen widersprechen. Am schwersten wiegen drei Lücken in der Hauptgeschichte: Das Lager in
U2 hat keinen Zugang, obwohl dort der Halloween-Schlüssel liegt; wann man den Schlüssel holen kann, ist nicht
festgelegt; und für U2 gibt es noch keinen Plan. Kap. 8 (Speichern) ist inhaltlich stimmig, beschreibt den Stand des
Autosaves aber nicht mehr richtig. Kap. 10 und 11 sind seit YouTrack weitgehend überholt.

## Befunde

### E-01 Lager in U2 ohne Zugang – dort liegt der Halloween-Schlüssel
- Art: Lücke
- Schwere: hoch
- Fundstellen: `SK 7.4` (SPIELKONZEPT.md:5457), (SPIELKONZEPT.md:5461), (SPIELKONZEPT.md:5365-5368); `HANDLUNG.md:73`, `HANDLUNG.md:211-212`
- Befund: Das Lager ist „ein Verschlag aus Maschendraht mit Vorhängeschloss – wie man hineinkommt, ist offen“. Der
  Bolzenschneider ist eingefroren und soll „von der Werkzeugwand“ kommen. Diese Wand gehörte zur Werkstatt, die am
  27.10. gestrichen wurde, also hat auch der Bolzenschneider keinen Ort mehr. Im Lager liegen aber der Halloween-Schlüssel
  (Koffer Rudolf Hain), Josefs Sachen und die Taschenuhr fürs Ritual (M15a) sowie Heinrich Brehms Koffer (K5). Ohne
  Öffnungsweg sind damit M11, M15a, M18, M19a und das gute Ende nicht erreichbar.
- Vorschlag: einen Weg festlegen. Die einfachste Variante: Das Schloss ist schon aufgebrochen, weil das Monster
  dekoriert und frühere Gäste dort waren. Alternativ öffnet Josefs Bund (2.8) auch das Lager, oder der Bolzenschneider
  bekommt einen neuen Ort (Technikraum, Werkzeugkasten). Danach den eingefrorenen Bolzenschneider aus 7.4 streichen.
- Entscheidung nötig: ja

### E-02 Halloween-Schlüssel: Ort entschieden, Zeitpunkt offen, Doku uneinheitlich
- Art: Widerspruch
- Schwere: hoch
- Fundstellen: `SK 7.4` (SPIELKONZEPT.md:5461), `SK 7.10` (SPIELKONZEPT.md:5748), `SK 2.1` (SPIELKONZEPT.md:173), (SPIELKONZEPT.md:175-180), `SK 10` (SPIELKONZEPT.md:6248); `HANDLUNG.md:84`, `HANDLUNG.md:229-233`
- Befund: Laut 7.4 ist seit 30.10. entschieden, dass der Schlüssel im Lager liegt. Die Ebenentabelle in 7.10 nennt U2
  aber noch „Kandidat für den Halloween-Schlüssel“. 2.1 führt die Orte weiter als „Auswahl offen“ und sagt, an
  Halloween „taucht ein Schlüssel auf“. HANDLUNG K6/M18 listet weiter Kandidaten, und Frage 1 in Kap. 10 ist noch
  offen. Inhaltlich fehlt die zeitliche Regel: Liegt der Schlüssel seit 2008 im Koffer, kann man ihn schon bei der
  ersten U2-Fahrt um den 10.–14. mitnehmen. Damit verlieren Akt V („Den Schlüssel holen“, 28.–31.10.) und „Du brauchst
  die anderen“ ihr Gewicht, und ein früh gefundener Schlüssel kann monatelang (Spielzeit) gestohlen, verloren oder
  verkauft werden.
- Vorschlag: einen Zeitpunkt entscheiden. Entweder ist der Koffer bis zum 31. verschlossen bzw. leer und der Schlüssel
  „taucht auf“ (2.1), oder man kann ihn früh holen und muss ihn dann bis Halloween verwahren (Tasche, Diebstahlschutz).
  Danach 2.1, 7.10, Kap. 10 Frage 1 und HANDLUNG K6/M18 angleichen.
- Entscheidung nötig: ja

### E-03 U2 ohne Plan, Inhalt über fünf Kapitel verstreut
- Art: Lücke
- Schwere: hoch (bekannt, steht in Kap. 11)
- Fundstellen: `SK 7.10` (SPIELKONZEPT.md:5824), `SK 7.4` (SPIELKONZEPT.md:5403-5410), (SPIELKONZEPT.md:5456-5461), `SK 2.8` (SPIELKONZEPT.md:800-805), `SK 5.19` (SPIELKONZEPT.md:3813); `HANDLUNG.md:73`, `HANDLUNG.md:91`
- Befund: In U2 spielen Akt III–VI (Lager, Koffer, alter Heizkeller, Ritual, Josefs Bund am Kessel). Was dort liegen
  muss, steht aber verstreut: Karton „Personal 1987“ und Taschenuhr (HANDLUNG M15a, 2.8), Brehms Koffer (K5), Josefs
  Bund (2.8), die fehlende Maskenseite „beim alten Heizkessel“ (5.19), Kürbisreihen und Knochen (7.4). Die Liste
  „Inhalt“ des Lagers in 7.4 nennt davon nur die Koffer. Mehrere Dinge liegen bis dahin an Zwischenorten (Josefs Bund
  am Kessel in U1).
- Vorschlag: in 7.4 eine vollständige Inventarliste für U2 anlegen (Lager und alter Heizkeller), als Vorlage für den
  Plan des Nutzers. Dazu eine Liste der Zwischenorte, die beim Bau von U2 umziehen.
- Entscheidung nötig: nein (Plan malt der Nutzer)

### E-04 Gäste im Aufzug und in U2: drei ältere Stellen widersprechen ZIM-42
- Art: Widerspruch
- Schwere: mittel
- Fundstellen: `SK 7.4` (SPIELKONZEPT.md:5299-5300), (SPIELKONZEPT.md:5362), (SPIELKONZEPT.md:5464-5465), (SPIELKONZEPT.md:5468), `SK 7.10` (SPIELKONZEPT.md:5794); `HANDLUNG.md:183-184`
- Befund: Seit 3.11. gilt: „Niemand fährt mit: Gäste nehmen die Treppe“, und U2 gehört allein dem Monster (5766). In
  7.4 steht dagegen weiter, dass nach der Reparatur auch Gäste den Fahrstuhl nutzen (5362). „Teilen“ heißt dort, dass
  Gäste selbst nach U2 fahren (5464), und sie können den Schaltschlüssel klauen und das Lager plündern (5465). Auch die
  Frage nach Sabotage (5468) hängt an Gästen im Aufzug. HANDLUNG K3 lässt Bruno „mit nach U2“ wollen. Damit fehlt der
  „sozialen Entscheidung“ beim Lager (Geheim halten oder Teilen) ihre Mechanik.
- Vorschlag: Teilen neu fassen: Der Spieler bringt Deko herauf und verteilt sie, Gäste fahren nicht. Den Klau des
  Schaltschlüssels und die Sabotagefrage streichen. Brunos Anteil in K3 als Anteil am Fund formulieren statt als
  Mitfahrt.
- Entscheidung nötig: ja (wie Teilen jetzt wirkt)

### E-05 Spind des Hausmeisters: Zahlenschloss mit Code umgeht den Einbruch
- Art: Widerspruch
- Schwere: mittel
- Fundstellen: `SK 7.4` (SPIELKONZEPT.md:5323-5324), (SPIELKONZEPT.md:5331), (SPIELKONZEPT.md:5335-5336), `SK 7.18` (SPIELKONZEPT.md:5941-5945); `scripts/world/steel_locker.gd:61-64` (nicht committete Änderung einer parallelen Sitzung); `HANDLUNG.md:55`, `HANDLUNG.md:61`
- Befund: In 7.4 hängt am Spind ein Vorhängeschloss: Wer früh kommt, findet ihn zu. Früher hinein kommt nur, wer
  aufbricht (Vorschlag Brecheisen). 7.18 macht daraus ein Zahlenschloss mit festem Code. Im Arbeitsbaum steht dazu
  `STORY_CODES = {"Hausmeister": "3110"}`, mit „Hinweis im Notizbuch in Zimmer 18“. Zimmer 18 liegt in HANDLUNG am
  4.–6.10. (M8), der Einbruch erst in der fünften Nacht. Wer das Notizbuch am 4. liest, öffnet den Spind also mit dem
  Code und nimmt Sicherung und Sekretariatsschlüssel. Bruno, der Aushang (6.10.) und K3 laufen dann ins Leere, und
  7.4 regelt diesen Fall nicht. Nur das Aufbrechen mit dem Brecheisen ist bedacht.
- Vorschlag: entweder den Code-Hinweis erst nach Nacht 5 zugänglich machen bzw. den Code nicht ins Notizbuch legen,
  oder den Fall „Spieler kommt mit Code zuerst“ wie den Brecheisen-Fall regeln (der Aushang gilt dem Spieler, Bruno
  geht leer aus).
- Entscheidung nötig: ja

### E-06 Gäste gehen ins UG – Kap. 7.10 und 11 widersprechen ZIM-58
- Art: Widerspruch
- Schwere: mittel
- Fundstellen: `SK 7.9` (SPIELKONZEPT.md:5675-5679), `SK 7.10` (SPIELKONZEPT.md:5778-5779), `SK 11` (SPIELKONZEPT.md:6270-6271)
- Befund: Seit 3.11. (ZIM-58) gehen Gäste weder von sich aus noch auf Bitte ins UG. In 7.10 steht weiter „Gäste
  gehen hinunter – nicht von selbst, aber mit Grund: Aufträge, Bitten des Spielers (‚Hol die Wäsche‘). Noch nicht
  gebaut.“ Kap. 11 Punkt 3 plant „Gäste gehen mit Grund hinunter (7.10)“.
- Vorschlag: den Absatz in 7.10 streichen bzw. auf 7.9 verweisen und in Kap. 11 Punkt 3 den Teilsatz streichen. Der
  Wäscherei-Bezug zum Lakengeist (5773-5774) bleibt dann nur für den Spieler.
- Entscheidung nötig: nein

### E-07 Kessel im Keller schützt im Code noch, laut 7.4 nicht mehr
- Art: Code-Abweichung
- Schwere: mittel
- Fundstellen: `SK 7.4` (SPIELKONZEPT.md:5389-5390), (SPIELKONZEPT.md:5366-5367), `SK 7.9` (SPIELKONZEPT.md:5700-5704); `scripts/world/boiler.gd:6-9`
- Befund: Laut 7.4 (27.10.) ist der Kessel in U1 eine nicht angeschlossene Attrappe, „kein Feuerschein, kein
  Schutzplatz“. Anheizen ist gestrichen, nicht eingefroren. Im Code und in 7.9 brennt in U1 weiter der alte Kohlekessel,
  und sein Schein „zählt für MonsterDirector.light_at“: Er macht den Platz am Kessel sicherer, also genau das, was
  gestrichen ist. 7.9 und `boiler.gd` sprechen außerdem von „eingefroren“. 7.9 kennzeichnet den alten Stand zwar
  („Gebaut ist noch der alte Stand“), spielerisch wirkt er aber weiter.
- Vorschlag: Beim Umbau des Heizraums (Attrappe, Leviathanmauer) den Schein aus `lamps` nehmen. Bis dahin in 7.9
  ausdrücklich vermerken, dass der Schutz noch wirkt. „Eingefroren“ durch „gestrichen“ ersetzen.
- Entscheidung nötig: nein

### E-08 Schlüssel zu Zimmer 18: drei Orte, und im Spiel liegt er ab dem ersten Tag
- Art: Widerspruch / Code-Abweichung
- Schwere: mittel
- Fundstellen: `SK 7` (SPIELKONZEPT.md:5141), `SK 7.4` (SPIELKONZEPT.md:5318), (SPIELKONZEPT.md:5395-5396), `SK 7.9` (SPIELKONZEPT.md:5691); `scripts/level/level_builder.gd:5897`; `HANDLUNG.md:52`
- Befund: Der Schlüssel liegt laut Einleitung „im Heizkeller“, laut 7.4 „an der Leviathanmauer im Heizraum“ und dort
  erst „nach Gustavs Tod“. 7.9 und der Code legen ihn im gebauten Heizkeller ab Spielbeginn hin. Da die
  Kellerschlösser noch fehlen (E-09), kann man Zimmer 18 samt Notizbuch und Schaltschlüssel schon am 1.10. holen, vor
  Gustav, vor M7. Damit fehlt auch der Grund für den „ersten Abstieg“.
- Vorschlag: Den Schlüssel im Code erst nach der Siegerehrung erscheinen lassen (wie die Brille). Die Einleitung von
  Kap. 7 auf „an der Leviathanmauer (7.4)“ ändern.
- Entscheidung nötig: nein

### E-09 Keller ab dem ersten Tag offen: Schlösser fehlen, Aufzug-Sperre ist aus
- Art: Lücke / Code-Abweichung
- Schwere: mittel
- Fundstellen: `SK 7.4` (SPIELKONZEPT.md:5374-5377), (SPIELKONZEPT.md:5298), (SPIELKONZEPT.md:5351-5352), `SK 7.9` (SPIELKONZEPT.md:5683-5684)
- Befund: „Vor dem 2.10., 20 Uhr kommt niemand in den Keller“ ist eine Kernregel für den friedlichen Akt I und für
  M6a/M7. Im Code habe ich keine Vorhängeschlösser an den Kellerzugängen gefunden (Grep nach padlock/Kellertür/
  cellar_*), und Aufzug 1 „fährt schon jetzt“ ins UG, weil die Sperre bis ZIM-4 aus ist. Beide Wege führen am ersten
  Tag in den Keller. Weder 7.4 noch 7.9 sagen, dass die Schlösser fehlen.
- Vorschlag: In 7.4 die Schlösser als „noch nicht gebaut“ kennzeichnen. Die Aufzug-Sperre einschalten, sobald die
  Sicherung über den Spind kommt. Das ist im Code schon fertig, es fehlt nur die Entscheidung, ab wann sie gilt.
- Entscheidung nötig: ja (ab wann die Sperre gilt)

### E-10 Autosave: Doku nennt den alten Stand, Generalschlüssel widerspricht dem Code
- Art: veraltet / Code-Abweichung
- Schwere: mittel
- Fundstellen: `SK 8.6` (SPIELKONZEPT.md:6035-6037), `SK 8.10` (SPIELKONZEPT.md:6083-6087); `scripts/autoload/save_manager.gd:185`, `scripts/autoload/save_manager.gd:197`, `scripts/world/elevator.gd:725`, `scripts/world/elevator.gd:753`; `SK 2.8` (SPIELKONZEPT.md:811-812)
- Befund: Laut 8.6/8.10 sind „Fortschritt bisher nur die Schlüssel zu Zimmer 18 und zum Dachboden – Aufzug … gibt es
  noch nicht“, und neue Bereiche sind nur Dachboden, U2 und Zimmer 18. Der Code meldet Fortschritt auch bei
  Aufzug-Reparatur, Halt im DG, Schaltschlüssel, Sekretariat, Josefs Bund und **Generalschlüssel**. Das Büro der
  Direktion gilt als neuer Bereich. 8.10 sagt ausdrücklich: „Der Generalschlüssel (6.19) zählt nicht“. Der Kommentar im
  Code begründet ihn mit ZIM-6.
- Vorschlag: klären, ob der Generalschlüssel zählen soll. Danach 8.6 und 8.10 auf die Listen im Code bringen oder nur
  noch auf `PROGRESS_KEYS`/`NEW_AREAS` verweisen.
- Entscheidung nötig: ja (Generalschlüssel)

### E-11 Kap. 7 hat kein Raumverzeichnis, die Einleitung ist veraltet
- Art: Optimierung (Doku-Struktur) / veraltet
- Schwere: mittel
- Fundstellen: `SK 7` (SPIELKONZEPT.md:5134-5143), `SK 7.10` (SPIELKONZEPT.md:5746-5752), (SPIELKONZEPT.md:5768-5779); `SK 2.8` (SPIELKONZEPT.md:810), `SK 2.10` (SPIELKONZEPT.md:997-999)
- Befund: Die Bereichsliste nennt „Untergeschoss mit Heizkeller“ und „Dachboden (4.21)“. Es fehlen Büro der Direktion
  und Sekretariat (OG, ZIM-150, Ziel von M15b), Hausmeisterraum (EG, M9), Speisesaal, Poolhalle mit Umkleiden und
  Duschen, das Lager im EG West, Technikraum und Kühlraum. Diese Räume sind nur aus 2.x, 7.11–7.18 oder dem Code
  zusammenzusuchen. Die Sonderzimmer-Zeile sagt „018 abgeschlossen (Schlüssel im Heizkeller …)“, obwohl es versiegelt
  ist und der Schlüssel an der Mauer liegt. Die Ebenentabelle in 7.10 nennt für EG und OG1 keinen Zugang und für OG1
  weder Büro noch Bibliothek.
- Vorschlag: An den Anfang von Kap. 7 eine Tabelle stellen: Raum · Ebene · Zugang/Schlüssel · Zweck/Mechanik · Rolle in
  der Handlung (Meilenstein) · Abschnitt. Sie ersetzt die Bereichsliste und die Sonderzimmer-Zeile und macht Lücken wie
  E-01 sichtbar.
- Entscheidung nötig: nein

### E-12 Vorgeschichte von Zimmer 18 hat Lücken
- Art: Lücke (Story)
- Schwere: mittel
- Fundstellen: `SK 7.4` (SPIELKONZEPT.md:5413-5416), (SPIELKONZEPT.md:5395-5396), (SPIELKONZEPT.md:5441-5443), (SPIELKONZEPT.md:5461)
- Befund: (a) „gaben ihn dem Schlüsselträger; ihn holte das Monster“: grammatisch ist der Schlüsselträger gemeint.
  Rudolf Hain überlebte 2005 aber und starb 2008 (5461). Gemeint ist wohl Martin Ebert, gesagt wird es nirgends.
  (b) Eberts Zimmerschlüssel lag seit 2005 an der Mauer, erscheint aber erst „nach Gustavs Tod“. Warum er 21 Jahre
  unbemerkt blieb (der Hausmeister arbeitet dort), ist nicht erklärt. (c) Im Notizbuch schreibt der Hausmeister über den
  Schaltschlüssel „Bleibt bei mir“, gab ihn 2005 aber an Ebert. Wie der Aufzug seither außerhalb der Ernten fuhr, bleibt
  offen.
- Vorschlag: In (a) den Namen setzen. Für (b) reicht ein Satz: Das Hotel legt den Schlüssel hin, wenn es einen neuen
  Gast in 13 hat (passt zu „das Hotel öffnet die Mauer“). Für (c): Es gibt einen Zweitschlüssel bei der Direktion, oder
  der Aufzug stand seit 2005 still. Das passt auch zu „Aufzug 1 – steht“.
- Entscheidung nötig: ja (b, c)

### E-13 Abschnitt 7.4 Aufzug: Stand veraltet, Tabelle zerrissen
- Art: veraltet / Optimierung (Doku-Struktur)
- Schwere: niedrig
- Fundstellen: `SK 7.4` (SPIELKONZEPT.md:5291), (SPIELKONZEPT.md:5293), (SPIELKONZEPT.md:5299), (SPIELKONZEPT.md:5303), (SPIELKONZEPT.md:5319-5337), (SPIELKONZEPT.md:5361), (SPIELKONZEPT.md:5363), (SPIELKONZEPT.md:5436), (SPIELKONZEPT.md:5439); `scripts/world/elevator.gd:982`
- Befund: Die Überschrift sagt „vorgemerkt 2026-10-11“. Der Kasten nennt „Noch nicht gebaut: die Reparatur“ (5303),
  obwohl sie seit 3.11. gebaut ist (ZIM-14, 5344). Der Schaltschlüssel ist noch „im Aufzug ohne Wirkung“ (5436), und
  durchgestrichen werde, „sobald die Reparatur gebaut ist“ (5439). Die Anzeige hat laut 5293 nur „U, 0, 1“, inzwischen
  gibt es „D“ (5796). Für U2 ist keine Beschriftung festgelegt; der Code würde für Ebene −2 „-2“ anzeigen. Der Block
  „Der Einbruch“ steht mitten in der Tabelle der drei Schritte (zwischen Zeile 2 und 3), sodass Schritt 3 als
  verwaiste Tabellenzeile rendert. Der Nothalt (5361) fehlt in der Beschreibung des Bedienfelds (5296-5297).
  Notruftelefon (5363) und „Noch offen: Notruftelefon“ (5299) stehen nebeneinander.
- Vorschlag: Kopfzeile und Kasten auf den Stand bringen, „Der Einbruch“ hinter die Tabelle setzen, U2-Beschriftung
  festlegen (z. B. „U2“ oder „−2“), Nothalt und Notruftelefon als offen kennzeichnen.
- Entscheidung nötig: nein

### E-14 Zwei Räume heißen „Lager“, Ersatzbirnen doppelt
- Art: Widerspruch (Begriff)
- Schwere: niedrig
- Fundstellen: `SK 7.3` (SPIELKONZEPT.md:5242), (SPIELKONZEPT.md:5259), `SK 7.4` (SPIELKONZEPT.md:5456-5459), `SK 7.18` (SPIELKONZEPT.md:5932); `scripts/level/level_builder.gd:616`
- Befund: Das Ersatzbirnen-Lager liegt „im Lager im EG West“, Stahlspinde stehen „im Lager“. Gleichzeitig ist „Lager“
  der Verschlag in U2, dessen Inhalt auch „Kisten mit Ersatzglühbirnen und Kerzen“ sind. 5242 vermutet sie noch „im
  Hausmeisterraum/Keller“. Beim Lesen von HANDLUNG („Lager (M11)“) ist nicht klar, welcher Raum gemeint ist.
- Vorschlag: U2-Raum umbenennen (etwa „Fundsachenlager“ oder „Verschlag“), 5242 auf das EG-Lager festlegen und
  Ersatzbirnen in U2 streichen oder bewusst als zweite, späte Quelle kennzeichnen.
- Entscheidung nötig: nein

### E-15 „Heizkeller“ meint zwei Räume
- Art: Widerspruch (Begriff)
- Schwere: niedrig
- Fundstellen: `SK 7.4` (SPIELKONZEPT.md:5372-5373), (SPIELKONZEPT.md:5392), `SK 7.9` (SPIELKONZEPT.md:5691), `SK 6.19` (SPIELKONZEPT.md:4899), (SPIELKONZEPT.md:5040); `scripts/level/level_builder.gd:616`
- Befund: Seit 27.10. ist „Heizraum“ der Raum in U1 und „alter Heizkeller“ der Raum in U2. 6.19 legt das Brecheisen
  aber „im Heizkeller (UG)“ ab, 7.4 dagegen „im Heizraum“. Code, Plan und 7.9 nennen den U1-Raum weiter „Heizkeller“.
  Bei Verweisen wie „Schlüssel im Heizkeller“ ist so nicht klar, welche Ebene gemeint ist.
- Vorschlag: in Doku und `ROOM_NAMES` für U1 durchgehend „Heizraum“ verwenden, „Heizkeller“ nur noch für U2.
- Entscheidung nötig: nein

### E-16 Jahreszahl 2003 in 7.9 nicht nachgezogen
- Art: veraltet
- Schwere: niedrig
- Fundstellen: `SK 7.9` (SPIELKONZEPT.md:5683); vgl. `SK 7.4` (SPIELKONZEPT.md:5382)
- Befund: In 7.9 steht „zugemauert (nach 2003, 7.4)“, in 7.4 ist es seit 30.10. „nach 2005“.
- Vorschlag: auf 2005 ändern.
- Entscheidung nötig: nein

### E-17 „Offen: Balkon übersteigen, hinunterspringen“ ist längst gebaut
- Art: veraltet
- Schwere: niedrig
- Fundstellen: `SK 7.7` (SPIELKONZEPT.md:5596-5598), vgl. (SPIELKONZEPT.md:5552-5558)
- Befund: Beide offenen Fragen sind am 3.11. entschieden und gebaut (ZIM-36). Die Werte passen zum Code
  (Humpeln 3 Spielstunden, `player.gd:175`).
- Vorschlag: den Block „Offen“ streichen.
- Entscheidung nötig: nein

### E-18 U2 „nur durch den Aufzug“ gegen „auch durch die Mauer“
- Art: Widerspruch
- Schwere: niedrig
- Fundstellen: `SK 7.10` (SPIELKONZEPT.md:5784), `SK 2.1` (SPIELKONZEPT.md:180); vgl. `SK 7.4` (SPIELKONZEPT.md:5359), (SPIELKONZEPT.md:5410), `SK 7.10` (SPIELKONZEPT.md:5748)
- Befund: „U2 ist der Halt, den nur der Aufzug erreicht“ und „erreichbar nur mit dem reparierten Fahrstuhl“ stehen
  gegen die Leviathanmauer ab etwa Tag 15. Spielerisch heißt das: Wer den Aufzug nicht repariert, erreicht U2 trotzdem.
  Die Reparatur ist dann eine Abkürzung, kein Muss. „Erst dadurch hat die Reparatur einen echten Lohn“ gilt also nur bis
  Tag 15.
- Vorschlag: Satz in 7.10 anpassen (U2 vor Tag 15 nur per Aufzug).
- Entscheidung nötig: nein

### E-19 Dachgeschoss: Deckenhöhe und Dachform zwischen 4.21 und 7.10 uneinheitlich
- Art: Widerspruch
- Schwere: niedrig
- Fundstellen: `SK 4.21` (SPIELKONZEPT.md:2506), (SPIELKONZEPT.md:2511), (SPIELKONZEPT.md:2513), `SK 7.10` (SPIELKONZEPT.md:5801-5802), (SPIELKONZEPT.md:5820)
- Befund: In 4.21 steht Decke 2,2 m und „Die Dachform darüber bleibt offen“. 7.10 nennt 2,4 m (ZIM-170) und das am
  3.11. entschiedene Mansarddach. Für den Halt im DG sind Kabine (2,5 m) und Lampenanzeige (bis 2,6 m) höher als beide
  Werte; 7.10 nennt das selbst nur als „zu prüfen“. In 4.21 steht außerdem der Tippfehler „Schlüssel zu 0118“.
- Vorschlag: 4.21 auf 2,4 m und Verweis 7.10 bringen. Für den DG-Halt vorab festlegen, ob die Decke über dem Schacht
  höher wird oder das Portal niedriger.
- Entscheidung nötig: ja (Aufzugsportal im DG)

### E-20 Feiern: Lobby oder Partyraum?
- Art: Widerspruch
- Schwere: niedrig
- Fundstellen: `SK 7.1` (SPIELKONZEPT.md:5148), (SPIELKONZEPT.md:5166), (SPIELKONZEPT.md:5168), `SK 7.5` (SPIELKONZEPT.md:5512)
- Befund: 7.1 steht unter „Lobby“ und verlegt die Feier selbst in den Partyraum. Die Vorbereitung heißt aber „Deko in
  die Lobby tragen“, und der taktische Einsatz soll das Monster „in die Lobby“ locken. Das stammt aus der Zeit vor dem
  Grundriss vom 18.10.
- Vorschlag: „Lobby“ in 5166/5168 durch „Partyraum“ ersetzen und den Feier-Teil als eigenen Unterabschnitt
  „Partyraum“ führen.
- Entscheidung nötig: nein

### E-21 Albtraum-Modus: Ausstieg vor dem Tod, Menüregeln nicht nachgezogen
- Art: Lücke / Optimierung (Speicher-Exploit)
- Schwere: niedrig
- Fundstellen: `SK 8.9` (SPIELKONZEPT.md:6075-6078), `SK 8.7` (SPIELKONZEPT.md:6046), `SK 8.1` (SPIELKONZEPT.md:5955-5967)
- Befund: Im Albtraum-Modus kann man vor einem sicheren Tod über „Zum Hauptmenü“ oder Beenden aussteigen und behält
  den letzten Stand. 8.9 nennt das „offen“. Damit hat der Modus ein Schlupfloch für jeden, der es sucht. 8.7 („Laden ist
  jederzeit möglich“) und die Übersicht 8.1 erwähnen den Modus nicht.
- Vorschlag: Bei gesperrtem Tagebuch (Bedrohung aktiv) wirkt „Zum Hauptmenü/Beenden“ im Albtraum wie der Tod oder ist
  gesperrt. Mindestens 8.1 und 8.7 um eine Zeile „außer im Albtraum-Modus (8.9)“ ergänzen.
- Entscheidung nötig: ja

### E-22 Tabelle „Was gespeichert wird“ (8.8) ist vom 10.10.
- Art: veraltet
- Schwere: niedrig
- Fundstellen: `SK 8.8` (SPIELKONZEPT.md:6053-6065), `SK 8` (SPIELKONZEPT.md:5949)
- Befund: Es fehlen Lakengeist und Kürbismann, Aufzug (Reparatur, DG-Halt), Zwischenstand, Blutregen, Spinde,
  Haushalte usw. Die Tabelle ist kein Maßstab mehr. Den echten Stand haben `collect`/`apply` und TECHNIK.
- Vorschlag: auf „Grundsatz + Verweis auf TECHNIK.md“ kürzen statt nachzupflegen.
- Entscheidung nötig: nein

### E-23 Kap. 11 „Nächste Schritte“ veraltet
- Art: veraltet
- Schwere: niedrig
- Fundstellen: `SK 11` (SPIELKONZEPT.md:6264), (SPIELKONZEPT.md:6267), (SPIELKONZEPT.md:6270-6272), (SPIELKONZEPT.md:6277-6281), (SPIELKONZEPT.md:6285); `SK 6.10` (SPIELKONZEPT.md:4138)
- Befund: Punkt 3 nennt „Fahrstuhl reparieren“ (gebaut, ZIM-14) und „Gäste gehen mit Grund hinunter“ (verworfen,
  ZIM-58). Punkt 4 (ZIM-48, ZIM-38) ist am 3.11. gebaut. Punkt 1 sagt „der Rest eingefroren“, obwohl das Einfrieren
  für die Barspiele aufgehoben ist (4138). Die Punkte 7 und 9 sind durchgestrichen, bleiben aber stehen, entgegen der
  eigenen Regel „Gebautes fliegt hier raus“. Punkt 13 verweist auf 7.3, wo zerbrechende Fenster gar nicht vorkommen.
- Vorschlag: Kap. 11 auf fünf, sechs große Brocken mit Verweis auf die Epics in YouTrack kürzen oder ganz durch einen
  Verweis auf YouTrack ersetzen. Wenn Punkt 13 bleibt, braucht er einen echten Abschnitt (siehe Memory: bewusst
  vertagt).
- Entscheidung nötig: nein

### E-24 Kap. 10 „Offene Fragen“ fast leer, Frage 1 faktisch beantwortet
- Art: veraltet / Optimierung (Doku-Struktur)
- Schwere: niedrig
- Fundstellen: `SK 10` (SPIELKONZEPT.md:6246-6257)
- Befund: Von sieben Fragen sind fünf durchgestrichen. Frage 1 (Flucht) ist durch 2.7, 7.4 (Schlüssel im Lager) und
  HANDLUNG im Kern beantwortet, offen ist nur noch der Zeitpunkt (E-02). Frage 4 (was das Ding vor 1987 war) ist
  noch offen.
- Vorschlag: Kap. 10 auf Frage 4 reduzieren bzw. als Verweis auf YouTrack (`To be discussed`) führen. Die Nummern
  bleiben nur, wenn noch Verweise darauf zeigen.
- Entscheidung nötig: nein

### E-25 Leere Räume ohne Spielwert, Entscheidung „einzeln“ nie nachgeholt
- Art: Optimierung (Spielerlebnis / Umfang)
- Schwere: mittel
- Fundstellen: `SK 7.10` (SPIELKONZEPT.md:5787-5788), `SK 7.7` (SPIELKONZEPT.md:5562-5574), `SK 7.9` (SPIELKONZEPT.md:5694-5695); `HAUSHALTE.md:190`
- Befund: Am 21.10. sollten Speisesaal, Toiletten, Technikraum, Kühlräume, Bibliothek und Balkone „einzeln
  entschieden“ werden. Seitdem haben Speisesaal und Bibliothek viel Ausstattung bekommen (7.14–7.16, ZIM-152/153),
  aber keine Funktion („nur Ausstattung“). Dazu kommen 37 unbewohnte, abgeschlossene Zimmer und im UG „alle anderen
  Räume verschlossen und leer“. Das Hotel ist bewusst verkleinert (7.10 „Warum“). Große, schön gebaute Räume ohne Anlass
  zum Hingehen arbeiten gegen diese Begründung.
- Vorschlag (je ein Satz): **Speisesaal** als fester Treffpunkt im Tagesablauf (Frühstück/Abendessen, Gerüchte,
  Handel; ersetzt einen Teil der Lobby-Rolle). **Bibliothek** als Ort für Lesestoff der Ermittlung (Hotelchronik,
  Zeitungsbände 1987/2005, Ticket „Hinweisbücher“ schon vorgesehen). **Unbewohnte Zimmer** sind als Beute/Unterschlupf
  über 6.19 abgedeckt. **UG-Räume** zu (Müllraum) als bewusst tote Türen kennzeichnen.
- Entscheidung nötig: ja

### E-26 Doppelte Klang- und Kletterkanäle: Streichkandidaten
- Art: Optimierung (Umfang)
- Schwere: niedrig
- Fundstellen: `SK 7.10` (SPIELKONZEPT.md:5775-5777), (SPIELKONZEPT.md:5782-5783), `SK 7.4` (SPIELKONZEPT.md:5361), (SPIELKONZEPT.md:5363), (SPIELKONZEPT.md:5468); `SK 4.14` (SPIELKONZEPT.md:1905)
- Befund: Der Müllschlucker ist „Klangkanal“ und „Kletterweg des Monsters“, genau wie der tote Aufzugsschacht
  (Kratzen, Handabdrücke, wandernde Anzeige). Das Notruftelefon in der Kabine verdoppelt die vorgemerkten
  Zimmertelefone (4.14). Die Sabotagefrage hängt an Gästen im Aufzug, die es nicht mehr gibt (E-04).
- Vorschlag: Müllschlucker als Kletterweg streichen (Schacht genügt), ihn höchstens als Klangkanal behalten.
  Notruftelefon nur zusammen mit 4.14 entscheiden. Sabotagefrage streichen.
- Entscheidung nötig: ja

### E-27 Verschlossenes ohne Öffnungsweg (kleinere Fälle)
- Art: Lücke
- Schwere: niedrig
- Fundstellen: `SK 7.11` (SPIELKONZEPT.md:5837-5840), `SK 7.18` (SPIELKONZEPT.md:5944-5945)
- Befund: Vier Pool-Spinde (7, 20, 32, 44) gehen „nur mit Schlüssel“, dessen Ort offen ist. Stahlspinde mit Schloss
  haben Codes ohne Fundort. Für Josefs Spind sieht der Arbeitsbaum Marions Geburtstag vor (nicht committet). Beides ist
  harmlos, solange nichts Wichtiges darin liegt. Josefs Spind enthält aber das Kesselbuch (M12, Pflicht für M13).
- Vorschlag: Josefs Code in 7.18/2.8 festhalten, sobald er committet ist. Die Pool-Spinde mit Schlüssel streichen oder
  die Schlüssel an Gäste geben (Handel).
- Entscheidung nötig: nein

### E-28 Orientierung im Hotel: kaum Hilfen bei 81 Zimmern und fünf Ebenen
- Art: Optimierung (Spielerlebnis)
- Schwere: niedrig
- Fundstellen: `SK 7.5` (SPIELKONZEPT.md:5495-5498), `SK 7.7` (SPIELKONZEPT.md:5590-5591), `SK 7.9` (SPIELKONZEPT.md:5698-5699), `SK 7` (SPIELKONZEPT.md:5142)
- Befund: Bewusst gibt es keine Schilder an Bar, Pool, Treppenhaus. Kartenblätter gibt es für OG (Rezeption) und Keller
  (Zimmer 017); für das EG mit 48 Zimmern habe ich keines gefunden. Der Kompass liegt in 026, laut HAUSHALTE.md ein
  bewohntes Zimmer (Fiona Kühn, H32), also nur über 6.19 zu holen.
- Vorschlag: im Treppenhaus je Etage einen gerahmten Flucht- und Rettungsplan, realistisch für ein Hotel und bitter
  ironisch in einem verschlossenen Haus. Er ersetzt fehlende Schilder, ohne die Atmosphäre zu brechen. Den Kompass in
  der Sonderzimmer-Zeile als „bei Fiona (026)“ kennzeichnen.
- Entscheidung nötig: ja

### E-29 Story: Orte, die mehr tragen könnten
- Art: Optimierung (Story)
- Schwere: niedrig
- Fundstellen: `SK 7` (SPIELKONZEPT.md:5140), `HANDLUNG.md:208`; `SK 7.4` (SPIELKONZEPT.md:5424-5428); `SK 7.7` (SPIELKONZEPT.md:5559-5561)
- Befund: (a) Zimmer 017 ist „verlassen, dunkel, Kellerskizze“. Laut HANDLUNG K5 ist es Ednas Zimmer von 1987 („E. K.,
  Zimmer 017“). Kap. 7 stellt diese Verbindung nicht her, dabei könnte 017 Ednas Strang einen Ort geben. (b) Die
  UV-Spur von Clara und Martin hat drei Stationen (13, Lobby, Mauer). Eine vierte in Zimmer 18 bzw. U2 würde den Weg
  dorthin schließen. (c) Katzenraum, Pool und Bibliothek tragen nichts zur Hauptgeschichte bei. Das ist für
  Nebenschauplätze in Ordnung, betrifft aber drei der größten Räume.
- Vorschlag: 017 in Kap. 7 als Ednas Zimmer von 1987 benennen (Inhalt offen). Eine UV-Zeile in U2 vorsehen. Für die
  Bibliothek siehe E-25.
- Entscheidung nötig: ja (a)

## Annahmen über andere Systeme

- Gustav stirbt bei der Siegerehrung am 2.10., 20 Uhr. Erst danach liegen Brille und Schlüssel 18 an der Mauer (SK 7.4,
  Z. 5395-5396; HANDLUNG M3/M7, Z. 41, 52). Geprüft: HANDLUNG stimmt, Code nicht (E-08).
- Das Monster bricht beim ersten Aufbruch das östliche Kellerschloss auf; Gustavs Spur, der Suchtrupp und Doris laufen
  über das Treppenhaus Ost (SK 7.4, Z. 5376-5377 → 2.6, 2.9). Nicht geprüft, ob 2.6/2.9 das Treppenhaus Ost nennen.
- Bruno Kaminski bricht in Nacht 5 den Spind auf und behält Sicherung und Sekretariatsschlüssel (SK 7.4, Z. 5325-5330;
  HANDLUNG K3, Z. 176-182). Bruno ist bis dahin geschützt (6.17, Z. 5334). 6.17 nicht geprüft.
- Magda schleicht nachts herum, um den „Trick der Direktion“ zu beweisen (SK 7.4, Z. 5332-5333 → 6.20). Nicht geprüft.
- Hugo Stein baut nach der Reparatur den U2-Knopf ein und spricht den Spieler an (SK 7.4, Z. 5353-5356). Hugos Szene
  fehlt laut Z. 5352. 6.x nicht geprüft.
- Das Hotel öffnet und schließt die Leviathanmauer für das Monster; ab etwa Tag 15 bleibt sie nach Angriffen offen, ab
  dem 25. ganz (SK 7.4, Z. 5397-5399). Erwartet von 4.8/4.33 (Block B).
- Das Monster ist nie länger als ein paar Minuten am Stück außerhalb des alten Heizkellers (SK 7.4, Z. 5401-5402; 7.10,
  Z. 5763-5764). Erwartet von 4.13/4.33 (Block B), nicht geprüft.
- Ebenen-Hausherren: Lakengeist OG1, Kürbismann EG, Monster U1/U2; mehrere Bedrohungen dürfen zugleich auf einer Ebene
  sein (SK 7.10, Z. 5754-5766 → 4.20). Stichprobe: 4.20 (Z. 2378, 2390) stimmt.
- Der Kürbismann läuft übers Lobbydach (SK 7.10, Z. 5821 → 4.19). Nicht geprüft.
- Der Lakengeist kommt durch ein Badfenster nur, solange das Bad dunkel ist (SK 7.3, Z. 5233 → 4.18). Nicht geprüft.
- Der Leviathan im Spion zählt als Sichtung (4.5), Neugier ≥ 70 (SK 7.17, Z. 5921-5925). Code stimmt
  (`peephole_view.gd:22-25`). Ob 4.5 den Spion kennt, nicht geprüft.
- Das Kind zu viel (4.31) ist im Spion nur einmal zu sehen (SK 7.17, Z. 5920). Nicht geprüft.
- Josefs Bund hängt ab dem 14. am Kessel in U1 (Zwischenort) und später am alten Kessel in U2 (SK 2.8, Z. 803-807).
  Marion deutet ab dem 14. an, dass Josef ihr Vater ist („Vater hatte das ganze Haus am Gürtel“). Das könnte das
  „Entlarven“ (M13) und die Selbstoffenbarung am 24.10. (M16a) vorwegnehmen. Bitte von Block A prüfen. Dasselbe gilt
  für den Code-Satz im Arbeitsbaum (`steel_locker.gd:68`), wo Marion schon nach dem ersten Abstieg „Vater hat …“ sagt.
- Das Sekretariat ist im Plan gemalt und gebaut (SK 2.10, Z. 1102). In 2.10, Z. 999 steht noch „im Plan fehlt es noch“.
  Für Block A.
- Der Generalschlüssel liegt im Sekretariat (SK 2.10, Z. 1007); laut 8.10 zählt er nicht als Fortschritt, laut Code
  doch (E-10).
- Edna wohnte 1987 in 017 (HANDLUNG K5, Z. 208). Ihr Wissen liegt bei ihrem Tod als Notiz in 003 (HANDLUNG Z. 222).
  003 steht nicht in Kap. 7.
- Heinrich Brehms Zimmer 042 ist versiegelt, sein Schlüssel liegt im Krähennest (HANDLUNG K5; SK 6.19, Z. 5019-5021).
  Der Futtertisch fehlt laut Memory im Plan; nicht geprüft.
- Gäste schalten Zimmer 13 nie aus und holen Ersatzbirnen aus dem EG-Lager, höchstens einmal je Spielstunde (SK 7.3,
  Z. 5253, 5258-5259). Code stimmt (`guest.gd:70` 10–30 % Vergessen, `guest.gd:73` BULB_RETRY = 1 h).
- Glühbirne platzt ab 1,5 m, Kerze zerbricht ab 2 m (SK 7.3, Z. 5236). Code stimmt (`item.gd:107`).
- Die Kurbel der Bremse läuft 20 s, quietscht alle 1,6 s, 18 m weit (SK 7.4, Z. 5347). Code stimmt
  (`lift_drive.gd:11-12`, `senses.gd:101`).
- Pool-Duschen sind 7 m weit Lärm (SK 7.13, Z. 5867). Code stimmt (`senses.gd:42`).
- Die Halogenröhren im Keller flackern alle 10–30 s (SK 7.9, Z. 5688). Code stimmt (`flicker_light.gd:25`).
- Drei Autoloads Settings, Game, SaveManager (SK 9.1, Z. 6179). Stimmt mit `project.godot`.
- Tagesuhr: Tage zu 24 Minuten (SK 8.10, Z. 6100 → 2.4). Nicht geprüft.
- 67 Gäste in 39 Haushalten, 40 bewohnte Zimmer, 81 Zimmer (SK 7.10, Z. 5742; 7.5, Z. 5491). Stimmt mit
  HAUSHALTE.md:6 und :190.
- Die Masken-Erfolge fehlen noch (SK 8.11, Z. 6163-6167). Stimmt mit `scripts/ui/achievements.gd:19`.

## Nicht geprüft

- Die Karten `map*.aseprite`: nicht geöffnet (Vorgabe). Ob Hausmeisterraum, Maschinenraum, Aufzugsantrieb, Müllraum
  mit Müllschlucker-Klappen, Werkzeugkasten im Technikraum, Sicherungskasten und die Story-Spinde wirklich im Plan
  stehen, habe ich nicht nachgesehen.
- TECHNIK.md und PLANFARBEN.md nur über die Code-Stichproben, nicht textlich gegen Kap. 7–9 abgeglichen.
- Kap. 2, 4, 5, 6 nur an den genannten Stellen. Ob dort weitere Verweise auf alte Raumnamen (Werkstatt, Tiefkeller,
  Gitter) stehen, gehört zu den Blöcken A–D.
- Ob der Code für die Kellerzugänge Schlösser unter anderem Namen hat (gesucht nach padlock, Kellertür, cellar_*). Das
  Fehlen in E-09 ist ein Grep-Befund, kein Lauf im Spiel.
- Die nicht committeten Änderungen paralleler Sitzungen im Arbeitsbaum (u. a. `steel_locker.gd`, `caretaker_book.gd`,
  `level_builder.gd`, Karten-JSON): nur dort gelesen, wo E-05/E-27 sie betreffen.
- YouTrack (laut Auftrag nicht nötig). Ob E-01, E-02, E-09 oder E-19 schon als Ticket existieren, prüft die
  Zusammenführung.
