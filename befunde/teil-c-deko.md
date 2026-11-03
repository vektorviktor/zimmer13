# Befunde Teil C – Halloween-Deko und Gegenstände

Geprüft wurden Kapitel 5 des Spielkonzepts (Z. 3072–3850) und `GEGENSTAENDE.md` vollständig, dazu gezielte Querbezüge zu
Kap. 2, 4, 6, 7, `HANDLUNG.md` und 13 Code-Stichproben. Die Zahlen in 5.8, 5.10 (Stufe 1), 5.12 und 5.13 stimmen mit dem
Code überein. Die größten Probleme liegen nicht im Text, sondern zwischen Text und Plan: Die Knappheitskurve aus 5.10
hängt an Dekokisten und Wäschekisten, die im Plan fehlen oder für Gäste unerreichbar sind, und der Weiße Kürbis hat
kein Beet. Außerdem ist offen, ob große Kürbisse überhaupt knapp werden. `GEGENSTAENDE.md` hinkt an mehreren Stellen dem
Spielkonzept vom 3.11. hinterher (Puppenmaske, Lückenliste, Brunos Herzensbitte), und einige Gegenstände, die die
Geschichte tragen, fehlen dort ganz.

## Befunde

### C-01 Dekokisten und Wäschekisten fehlen im Plan – die Knappheitskurve läuft ins Leere
- Art: Lücke
- Schwere: hoch
- Fundstellen: `SK 5.10` (SPIELKONZEPT.md:3396–3407), `SK 5.10` Tabelle (SPIELKONZEPT.md:3446–3452), `SK 5.6` (SPIELKONZEPT.md:3217, 3221–3222), `SK 5.7` (SPIELKONZEPT.md:3243–3244), `scripts/level/level_builder.gd:594–596`
- Befund: Die Mengen 15/8/10 stehen im Code. Laut 5.10 steht im Plan aber noch keine Dekokiste und keine Wäschekiste (geprüft am 3.11.). Damit gibt es Lichterketten, Fledermäuse, Plastikspinnen und Lakengespenster nur aus Kommoden, von Bruno, von Mila oder aus der Startdeko. Die Dramaturgie „erste Woche Fülle, Monatsmitte leer, letzte Woche nur fremde Türen“ (3446–3452) und die Regel „bis zum Tag d höchstens Menge × d / 15“ (3403–3405) haben so nichts, woran sie greifen könnten. Der Kern des Pitches („Die Deko ist knapp“, 3387) ist im Spiel derzeit nicht zu erleben.
- Vorschlag: Im Plan die Dekokisten setzen (Anzahl und Orte festlegen, z. B. Lager EG und Partyraum) und die Wäschekisten außerhalb des UG (siehe C-02). Bis dahin in 5.10 deutlich vermerken, dass die Stufen 1–3 ohne Kisten nicht prüfbar sind.
- Entscheidung nötig: ja (Zahl und Orte der Kisten; liegt beim Zeichner)

### C-02 Wäschekisten liegen in der Wäscherei im UG – Gäste gehen seit 3.11. nicht mehr ins UG
- Art: Widerspruch
- Schwere: mittel
- Fundstellen: `SK 5.9` (SPIELKONZEPT.md:3309–3310, 3335–3337), `SK 5.10` (SPIELKONZEPT.md:3396–3401), `SK 7` Wäscherei (SPIELKONZEPT.md:5773), `SK 5.19` (SPIELKONZEPT.md:3826), `scripts/guests/deco_search.gd:4`
- Befund: Allein-Schmücken und Deko-Suche schicken Gäste zu den Wäschekisten, und 5.10 lässt sie dort ein Stück am Tag nehmen. Laut 7 stehen die Wäschekisten mit den alten Lakengespenstern in der Wäscherei (U1), und seit 3.11. (7.9) betritt kein Gast mehr das UG. In 5.10 wurde nur die alte Deko im Heizkeller angepasst („leert nur noch der Spieler“, 3400–3401), die Wäschekiste nicht. Damit bekommen Gäste keine Lakengespenster, und die Kiste mit 8 Stück leert sich nicht „um die Monatsmitte“.
- Vorschlag: Entweder Wäschekisten mit Deko zusätzlich im EG/OG (z. B. Wäschekammer je Flur, „Deko vom letzten Jahr“), oder in 5.9/5.10 festhalten, dass die Lakengespenster wie die alte Deko nur dem Spieler gehören. Dann wird das Lakengespenst automatisch zur Spielerware im Handel.
- Entscheidung nötig: ja

### C-03 Der Weiße Kürbis („Casper“) hat kein Beet im Plan
- Art: Lücke
- Schwere: mittel
- Fundstellen: `SK 5.8` (SPIELKONZEPT.md:3254–3255, 3277), `SK 6.14` (SPIELKONZEPT.md:4585), `tools/build_map.py:156`, `assets/maps/eg.json` (HEAD und Arbeitsbaum: 15 × Halloween, 9 × Hokkaido, 9 × Muskat, 9 × Turban, 6 × Butternut, 4 × Riese, 0 × `pumpkin_plant:casper`), `scripts/world/stove.gd:29`
- Befund: Die Sorte ist im Code komplett (Deko 12, leuchtet kalt-weiß, Suppensorte), die Planfarbe „Kürbispflanze Weiß“ gibt es auch. Im Plan steht aber keine einzige Pflanze. Gäste mit Lieblingssorte Casper können ihre Bitte nie erfüllt bekommen, und ausgerechnet das Beispiel in 6.14 („einen Casper vor meiner Tür – geschnitzt“) ist unerfüllbar. Die stärkste schnitzbare Normalsorte fehlt also im Spiel.
- Vorschlag: Ein Casper-Beet in den Plan setzen (Zeichner). Bis dahin Casper als Lieblingssorte im Generator ausschließen oder im SK vermerken.
- Entscheidung nötig: nein (nur Planarbeit), ja falls Casper bewusst selten bleiben soll

### C-04 Große Kürbisse werden wahrscheinlich nie knapp
- Art: Optimierung (Balance)
- Schwere: mittel
- Fundstellen: `SK 5.10` (SPIELKONZEPT.md:3411–3413, 3462–3463, 3450–3452), `SK 5.8` (SPIELKONZEPT.md:3270–3271), `scripts/world/pumpkin_plant.gd:4`, `README.md:88` („acht Kürbisfelder … über 60 Pflanzen“)
- Befund: 5.10 sagt „je **Beet** einmal am Tag“, der Code lässt aber jede **Pflanze** nachwachsen. Im Plan stehen 28 Einträge für große Sorten (15 Halloween, 9 Muskat, 4 Riese). Seit der Frost gestrichen ist, tragen alle Beete bis Halloween. Damit gibt es täglich bis zu etwa 24 große Kürbisse, dazu den Riesen alle zwei Tage. Laut 5.10 braucht eine Tür an Halloween 4 geschnitzte Kürbisse, die nach 3 Tagen faulen. Ein fleißiger Spieler hält so mehrere Türen dauerhaft, und der Satz „Letzte Woche: starke Deko gibt es nur noch an fremden Türen“ trifft für Kürbisse nicht zu. Ob ein Planeintrag genau eine Pflanze ist und wie viel die Gäste morgens ernten, habe ich nicht gemessen.
- Vorschlag: Mit einem Monatslauf im Rauchtest zählen, wie viele große Kürbisse am 25.–30. noch frei sind. Mögliche Hebel: „Beet“ wirklich als Beet zählen (eine reife Frucht je Feld und Tag), Gäste ab der zweiten Monatshälfte gieriger ernten lassen oder die Reifezeit großer Sorten mit dem Monat verlängern. Den Begriff „Beet“ in 5.8/5.10 an den Code angleichen.
- Entscheidung nötig: ja

### C-05 „Dekokiste“ ist doppelt belegt, und es gibt vier Quellen alter Deko, nur zwei mit Menge
- Art: Widerspruch
- Schwere: mittel
- Fundstellen: `SK 5.10` (SPIELKONZEPT.md:3396–3399, 3460–3461), `SK 5.7` (SPIELKONZEPT.md:3247–3248), `SK 4.21` Dachboden (SPIELKONZEPT.md:2509–2510), `SK 7.4` Lager U2 (SPIELKONZEPT.md:5460)
- Befund: Die Planfarbe „Ausstattung: Dekokiste“ steht einmal für die öffentliche Kiste mit 15 Stück (Lichterketten, Fledermäuse, Spinnen; Gäste nehmen daraus) und einmal für die Kisten auf dem Dachboden mit „wertvollerer alter Deko“ (Totenkopf, Hexenbesen, Lichterkette; „wenige Stücke“). Der Code kann die beiden nicht unterscheiden: Eine Dachbodenkiste bekäme 15 Stück, und Gäste würden sich dort bedienen. Dazu kommen die Kiste im Heizkeller (10 Stück) und das Lager in U2 („der größte Schatz im Hotel“, mit „Girlanden“ und „Laternen“, die es als Gegenstand nicht gibt). Für die letzten beiden gibt es keine Menge.
- Vorschlag: Eine eigene Planfarbe „Kiste alte Deko“ einführen (Dachboden, Heizkeller, U2), in 5.10 eine kleine Tabelle der Quellen mit Ort, Inhalt, Menge und „Gäste ja/nein“ anlegen und „Girlanden/Laternen“ in 7.4 auf vorhandene Gegenstände abbilden.
- Entscheidung nötig: ja (Mengen Dachboden/U2)

### C-06 Grollen und Feierende sind für 1–2 Minuten Frist gebaut, nicht für 2–5 Spielstunden
- Art: Widerspruch / Optimierung (Spielerlebnis)
- Schwere: mittel
- Fundstellen: `SK 5.5` (SPIELKONZEPT.md:3133–3134, 3145–3146, 3156–3161), `SK 5.16` (SPIELKONZEPT.md:3727–3728), `scripts/world/doll_house.gd:7`
- Befund: Seit 25.10. sitzt die Puppe 2–5 Spielstunden vor der Tür. Die Regeln zum Grollen stammen vom 22.10. (Frist 1–2 min): Es ist „im ganzen Hotel“ zu hören und wird lauter, Gäste bekommen Angst und rennen heim, ab halber Lautstärke löst sich jede Feier auf. Bei 8–12 Urteilen sind das 16–60 Spielstunden im Monat mit Grollen und ohne Feier, also über Stunden ein Ausnahmezustand statt eines kurzen Alarms. Auch das Puppenhaus ist mit der langen Frist entwertet: „Vorwarnung um Minuten“ (3728, im Code ausdrücklich „nicht um Stunden“) bringt kaum etwas, wenn die große Puppe ohnehin Stunden vorher sitzt.
- Vorschlag: Das Grollen erst in der letzten halben bis ganzen Stunde vor dem Aufbruch hörbar machen (davor nur in Türnähe) und das Feierende daran koppeln. Dem Puppenhaus einen neuen Zweck geben, z. B. die winzige Puppe schon vor dem Urteil an der Tür, die gerade die schwächste ist, als stille Prognose.
- Entscheidung nötig: ja

### C-07 Spieluhr „fürs Ritual“, aber nicht unter „seinen Sachen“
- Art: Lücke / Optimierung (Story)
- Schwere: mittel
- Fundstellen: `SK 5.17` (SPIELKONZEPT.md:3740), `SK 2.8` (SPIELKONZEPT.md:791–792, 822), `GEGENSTAENDE.md:47`, `GEGENSTAENDE.md:144`, `HANDLUNG.md:73`, `SK 5.5` Herkunft (SPIELKONZEPT.md:3202)
- Befund: 5.17 und `GEGENSTAENDE.md` sagen, die Spieluhr gehöre „später zu seinen Sachen fürs Ritual“. 2.8, HANDLUNG M15a und `GEGENSTAENDE.md:47` nennen als „seine Sachen“ aber nur Taschenuhr, Mütze und Foto aus dem Karton „Personal 1987“. Außerdem gibt es drei Geschenke Josefs an Marion mit fast demselben Motiv: die Puppe (5.5), die Spieluhr (5.17) und die Taschenuhr („hat sie mir immer ans Ohr gehalten“).
- Vorschlag: Die Spieluhr ausdrücklich zum Ritualgegenstand machen. Sie wird früh gefunden, Marion erkennt sie, und das Monster horcht schon jetzt auf die Melodie – das ist der stärkste spielerische Faden. Die Taschenuhr kann dann entfallen oder nur Beigabe sein. 2.8, M15a/M19a und `GEGENSTAENDE.md:47` entsprechend angleichen.
- Entscheidung nötig: ja

### C-08 Fehlende Einträge in `GEGENSTAENDE.md` für Dinge, die Geschichte oder Bitten tragen
- Art: Lücke
- Schwere: mittel
- Fundstellen: `SK 5.19` (SPIELKONZEPT.md:3812–3814, 3819–3820, 3797), `SK 5.14` (SPIELKONZEPT.md:3637–3642), `HANDLUNG.md:75`, `GEGENSTAENDE.md:29`, `GEGENSTAENDE.md:43`
- Befund: In der Übersicht fehlen: die **fehlende Seite des Kesselbuchs** (beim alten Kessel in U2, erklärt die verbotenen Masken), die acht **Warnzettel an den Maskenverstecken**, das **Foto von 2005** (Sekretariat, ZIM-117; in Z. 29 nur im Handlungsfeld erwähnt) und das **Ankunftsfoto 2026**, **Milas Skizze** (HANDLUNG M15c), **Stoff** für Ruths Maske („gegen Stoff“, 3797 – als Gegenstand gibt es ihn nirgends) und der Inhalt der Blechdose (Pappgespenst).
- Vorschlag: Die Zeilen nachtragen, die ersten drei mit „Hauptgeschichte“ bzw. „Nebenstrang“. Bei „Stoff“ entscheiden: neuer Gegenstand oder Bettlaken (`BED_SHEET`) wiederverwenden. Letzteres ist kleiner und passt zur Lakenmotivik.
- Entscheidung nötig: ja (nur Stoff)

### C-09 Salz plus Lakengespenster macht ein Zimmer dauerhaft sicher vor dem Lakengeist
- Art: Optimierung (Balance)
- Schwere: mittel
- Fundstellen: `SK 5.13` (SPIELKONZEPT.md:3595–3600), `SK 5.9` (SPIELKONZEPT.md:3377), `SK 5.6` (SPIELKONZEPT.md:3227–3232)
- Befund: Vor einer gesalzenen Tür mit Lakengespenstern „erscheint er gar nicht erst“. Ohne Erscheinen gibt es keine Abweisung, und das Salz wird nie grau. Der Spieler verwischt die Linie nicht, wenn er geduckt darübersteigt, und das ist bei jedem Verlassen leicht machbar. Eine Linie aus 12 hält damit Zimmer 13 den ganzen Monat frei, solange kein Gast über die Schwelle geht. Das widerspricht „Sie dürfen nie ganz sicher machen“ (3377).
- Vorschlag: Eine kleine Abnutzung einführen, z. B. dass Salz nach 2–3 Spieltagen von selbst vergraut (Luftfeuchte, Regen am Fenster) oder dass ein Nicht-Erscheinen wegen der Gespenster als halbe Abweisung zählt.
- Entscheidung nötig: ja

### C-10 „Starke Deko“ im Text, schwache Werte im Code – die Deko-Stärken stehen nirgends im SK
- Art: Optimierung (Balance) / Lücke
- Schwere: mittel
- Fundstellen: `SK 5.10` (SPIELKONZEPT.md:3393, 3456–3461, 3480), `scripts/world/item.gd:211` (`FILLER_KINDS`), `scripts/world/item.gd:1326` (Spinnweben 12), `:1336` (Laub 5), `:1479` (Lichterkette 10), `:1497` (Fledermaus 9), `:1503` (Spinne 6), `:1509` (Totenkopf 16), `:1521` (Besen 15)
- Befund: 5.10 zählt Fledermäuse, Spinnen und Lichterketten zur „starken Deko“ aus endlichen Kisten. Im Code ist die Spinnwebe (Füllmaterial, „wächst nach“) mit 12 stärker als Lichterkette (10), Fledermausgirlande (9) und Plastikspinne (6). Fledermaus und Spinne zählen ohne Licht dazu nur ×0,5. Die Kerze ist zugleich Füllmaterial (Deckel 20) und Lichtdeko mit Schein ×1,6. Nur die Kürbissorten haben im SK eine Wertetabelle (5.8), alle anderen Stärken stehen nur im Code.
- Vorschlag: In 5.10 eine Tabelle „Deko-Stärke, Licht ja/nein, Füllmaterial/endlich, brennt (5.11), schwingt (5.6)“ ergänzen und dabei die Rangfolge glätten: Spinnweben unter Fledermaus/Spinne, Lichterkette deutlich über Spinnweben. Alternativ „stark“ in „endlich“ umbenennen, wenn die Werte bleiben sollen.
- Entscheidung nötig: ja

### C-11 Puppenmaske in `GEGENSTAENDE.md` noch mit der alten Wirkung
- Art: veraltet
- Schwere: niedrig
- Fundstellen: `GEGENSTAENDE.md:99`, `SK 5.19` (SPIELKONZEPT.md:3757–3762, 3828–3831), `scripts/guests/guest.gd:2679`
- Befund: In `GEGENSTAENDE.md` steht „Puppe: nächstes Urteil auf die Tür des Trägers“. Laut SK und Code ist diese Wirkung seit 3.11. (ZIM-102) entfernt; jetzt werden Kinder still und halten Abstand. Die gebauten leichten Wirkungen von Vogelscheuche, Krähe und Kesselkatze (nur im Debug) fehlen ganz.
- Vorschlag: Die Zeile auf den Stand von ZIM-102 bringen und „im Spiel nur Kürbismann und Puppe, drei weitere im Debug“ ergänzen.
- Entscheidung nötig: nein

### C-12 Die Liste „Lücken für die Hauptgeschichte“ nennt Gebautes als fehlend
- Art: veraltet
- Schwere: niedrig
- Fundstellen: `GEGENSTAENDE.md:150–157`, gegen `GEGENSTAENDE.md:26`, `:69`, `:72`, `:73`
- Befund: Punkt 1 und 2 führen Gustavs Tagebuch (gebaut 26.10.), Hotelregister (gebaut 28.10.), Notizbuch des Hausmeisters und Schaltschlüssel (gebaut 28.10./3.11.) als fehlend. Tatsächlich fehlen nur Brille, Sicherung im Spiel (ZIM-4), Kesselbuch und seine fehlende Seite, Dachbodenschlüssel, Ritualsachen, Vertrag, Ausgangsschlüssel und Foto 2005.
- Vorschlag: Die Liste neu erzeugen und nur „geplant/teilweise“ mit Handlung = Hauptgeschichte aufnehmen. Am besten ganz streichen und durch einen Filterhinweis ersetzen, damit sie nicht doppelt gepflegt wird.
- Entscheidung nötig: nein

### C-13 Heizkeller oder Heizraum – die Ortsangaben in Kap. 5 stammen von vor dem Umbau
- Art: veraltet
- Schwere: niedrig
- Fundstellen: `SK 5.7` (SPIELKONZEPT.md:3247), `SK 5.10` (SPIELKONZEPT.md:3397, 3400), `SK 5.17` (SPIELKONZEPT.md:3735), `SK 7.4` (SPIELKONZEPT.md:5372–5373, 5386, 5391–5392), `GEGENSTAENDE.md:28`, `GEGENSTAENDE.md:144`
- Befund: Seit 27.10. heißt der Raum in U1 „Heizraum“ (eine Attrappe), und „alter Heizkeller“ ist der Kesselraum in U2, das Reich des Monsters. In Kap. 5 heißt es weiter „Heizkeller“ bzw. „im Versteck des Monsters“ (Kiste alter Deko, Spieluhr auf dem alten Regal). 7.4 stellt das alte Regal mit Spieluhr ausdrücklich in den Heizraum, `GEGENSTAENDE.md` schreibt einmal Heizraum und einmal Heizkeller. Nach dem Bau von U2 ist so unklar, ob Kiste und Spieluhr oben bleiben oder umziehen.
- Vorschlag: In 5.7, 5.10 und 5.17 „Heizraum (U1)“ schreiben und bei der Kiste festhalten, ob sie mit U2 umzieht.
- Entscheidung nötig: nein (ja, falls die Kiste nach U2 soll)

### C-14 Veraltete Absätze und Kopfzeilen mit falschem Stand in Kap. 5
- Art: veraltet (Doku-Struktur)
- Schwere: niedrig
- Fundstellen: `SK 5.12` (SPIELKONZEPT.md:3519–3521, 3542–3548), `SK 5.14` (SPIELKONZEPT.md:3634, 3640), `SK 5.3` (SPIELKONZEPT.md:3082–3092), `SK 5.9` (SPIELKONZEPT.md:3292), `SK 5.11` (SPIELKONZEPT.md:3502–3503), `SK 5.19` (SPIELKONZEPT.md:3749)
- Befund: 5.12 führt „Unbegrenzt“ und „Gäste zünden nichts an“ als vollständige, nur kursiv markierte Absätze weiter. „Neue Kerzen brennen nicht“ (3542) ist laut 3515 nur für Gäste ersetzt, aber unmarkiert, und unklar bleibt, ob neue Kerzen für den Spieler weiter dunkel sind. Die Kopfnotiz von 5.14 sagt „noch nicht umgesetzt“, zwei Absätze weiter steht „umgesetzt 2026-11-03“. Die Überschriften von 5.9 („vorgemerkt“), 5.11 und 5.19 („entschieden“) verschweigen den Baustand. 5.3 ist eine „vorläufige“ Ideentabelle vom Anfang, die die gebaute Deko nicht abbildet.
- Vorschlag: Überholte Absätze in 5.12 auf einen Satz mit Datum kürzen, die Kopfzeilen auf „entschieden …, umgesetzt …“ vereinheitlichen und 5.3 durch die Übersichtstabelle aus C-10 ersetzen. Die Ideen (Girlande, Vogelscheuche) kommen dann in einen Satz „nicht gebaut“.
- Entscheidung nötig: nein

### C-15 Wo die Puppe zwischen den Urteilen ist, steht dreimal verschieden da
- Art: Widerspruch
- Schwere: niedrig
- Fundstellen: `SK 5.5` (SPIELKONZEPT.md:3180–3182, 3188–3191, 3205)
- Befund: Z. 3188 sagt, zwischen den Urteilen sitzt sie wieder in der Lobby. Z. 3189–3190 sagt, nach der Siegerehrung ist sie fort, bis sie vor dem nächsten Angriff an einer Tür liegt. Z. 3180 sagt, Kinder nehmen sie zwischen den Angriffen mit. Gemeint ist vermutlich: bis zum ersten Urteil fort, danach Lobby oder beim Kind. Der Satz von 3189 ist der Stand vor 25.10.
- Vorschlag: Z. 3189–3191 auf „nach der Siegerehrung fort bis zum ersten Urteil, danach Lobby“ kürzen.
- Entscheidung nötig: nein

### C-16 Gruppenfoto an Halloween: ein Bild oder zwei?
- Art: Widerspruch
- Schwere: niedrig
- Fundstellen: `SK 5.9` (SPIELKONZEPT.md:3382–3384), `SK 2.7` (SPIELKONZEPT.md:676, 745–746, 1013), `SK 5.14` (SPIELKONZEPT.md:3644), `HANDLUNG.md:90`, `HANDLUNG.md:93`
- Befund: 5.9 legt das Gruppenfoto auf das Fest am 31. In 2.7 entsteht „das Gruppenfoto (5.9)“ draußen nach der Öffnung, Z. 1013 nennt beide „eigene Bilder“, und HANDLUNG führt beide (M19 und M21). Auch 5.14 nennt das Ankunftsfoto der Fotowand „Halloween-Gruppenfoto“.
- Vorschlag: Bei einem Bild bleiben, dem draußen im Morgengrauen bei Ende 1. Es ist das stärkere Bild und kann die Vampirpointe (4.22) tragen. Das Festfoto in 5.9 und M19 streichen und das Fotowandbild „Ankunftsfoto“ nennen.
- Entscheidung nötig: ja

### C-17 Brunos Herzensbitte doppelt in `GEGENSTAENDE.md`
- Art: Widerspruch (Stand)
- Schwere: niedrig
- Fundstellen: `GEGENSTAENDE.md:87`, `GEGENSTAENDE.md:53`, `SK 6.14` (SPIELKONZEPT.md:4601, 4606–4609)
- Befund: Beim geschnitzten Kürbis steht „Brunos Herzensbitte“, beim Silberstock „statt Lieblingskürbis“. Beides stimmt für sich (gebaut bzw. entschieden), aber ohne Hinweis, dass der Kürbis mit ZIM-8 entfällt.
- Vorschlag: Bei Z. 87 „(bis ZIM-8, dann Silberstock)“ ergänzen.
- Entscheidung nötig: nein

### C-18 Kürbismann-Betäubung: SK sagt „ein Kürbis“, Code nimmt nur große und geschnitzte
- Art: Code-Abweichung
- Schwere: niedrig
- Fundstellen: `SK 4.21` (SPIELKONZEPT.md:2455), `GEGENSTAENDE.md:86–87`, `scripts/monster/pumpkin_man.gd:1091`
- Befund: Im Code betäuben nur `CARVED_PUMPKIN` oder große `PUMPKIN`. Zierkürbis, Hokkaido, Butternut und Turban wirken nicht. `GEGENSTAENDE.md` beschreibt das richtig, 4.21 nicht. Für Spieler ist das wichtig, denn kleine Sorten passen in eine Hand und wären die naheliegende „Waffe“.
- Vorschlag: 4.21 präzisieren und dem Spieler eine Rückmeldung geben, wenn ein kleiner Kürbis nicht wirkt (Kürbismann ignoriert ihn sichtbar). Das liegt in Block B.
- Entscheidung nötig: nein

### C-19 „Laub wird zertreten“ ist nicht gebaut
- Art: Code-Abweichung
- Schwere: niedrig
- Fundstellen: `SK 5.10` (SPIELKONZEPT.md:3489), `SK 5.3` (SPIELKONZEPT.md:3096)
- Befund: Unter „Verfall“ steht ohne Einschränkung „Laub wird zertreten“. Im Code gibt es nur das Zertreten von Spinnen (`scripts/world/spiders.gd`), keinen Verfall von `LEAVES`. Stufe 1 (3414–3416) nennt nur das Faulen. Laub ist damit das einzige Füllmaterial ohne Verfall und ohne Grenze außer dem Deckel 20.
- Vorschlag: Entweder bauen (Laub unter Schritten wird dünner, nach n Tritten weg) oder im Text als „nicht gebaut“ markieren.
- Entscheidung nötig: ja

### C-20 Zwei Maskenverstecke haben keinen Ort im Hotel – die Goldtrophäe ist unerreichbar
- Art: Lücke
- Schwere: niedrig
- Fundstellen: `SK 5.19` (SPIELKONZEPT.md:3827, 3829, 3839–3840, 3752–3756), `SK 8.11` (SPIELKONZEPT.md:6172–6173)
- Befund: Die Gruft für die Vampirmaske und der Geräteschuppen für die Vogelscheuchenmaske „gibt es noch nicht“. Kürbismann- und Puppenmaske hängen vorerst ab Spielbeginn am Board, also ohne Fund. Wird die Trophäenregel („sobald sie an ihrem Haken hängt“) so gebaut, gäbe es zwei Bronzetrophäen geschenkt.
- Vorschlag: Für Vampir und Vogelscheuche Ersatzverstecke an vorhandenen Orten wählen (z. B. Friedhof-Gedenkstätte, Gartentisch-Hecke) und für die Trophäe „erstmals aufgenommen“ statt „hängt am Haken“ zählen.
- Entscheidung nötig: ja

### C-21 „Vogelscheuche“ und „Girlande“: dieselben Wörter für verschiedene Dinge
- Art: Optimierung (Umfang/Begriffe)
- Schwere: niedrig
- Fundstellen: `SK 5.3` (SPIELKONZEPT.md:3091–3092, 3095), `SK 4.30` (SPIELKONZEPT.md:2851), `SK 5.19` (SPIELKONZEPT.md:3829), `SK 6.10` (SPIELKONZEPT.md:4211), `SK 5.9` (SPIELKONZEPT.md:3295), `SK 7.4` (SPIELKONZEPT.md:5460)
- Befund: Die Vogelscheuche ist Deko-Idee mit großem Radius (5.3), Spuk, der näher kommt (4.30, gebaut), verbotene Maske (5.19) und Turnierpreis (6.10). Die „Girlande“ ist Idee (5.3), wird von Gästen getragen (5.9) und liegt als alte Deko in U2 (7.4), gebaut ist aber nur die Fledermausgirlande.
- Vorschlag: Die Deko-Idee Vogelscheuche streichen (der Spuk ist stärker und gebaut) und „Girlande“ überall durch „Fledermausgirlande/Lichterkette“ ersetzen. So bleibt jedes Wort für ein Ding.
- Entscheidung nötig: ja (Streichung der Deko-Idee)

### C-22 Löschen durch Austreten – auch bei hängender Deko?
- Art: Lücke
- Schwere: niedrig
- Fundstellen: `SK 5.11` (SPIELKONZEPT.md:3504, 3510)
- Befund: Brennen können vor allem hängende Stücke (Lakengespenster, Fledermausgirlanden, Spinnen, Spinnweben), gelöscht wird aber durch „Austreten [E]“. Wie man eine brennende Girlande an der Wand löscht und ob Gäste löschen, steht nicht da. Nicht im Code geprüft (Speichermangel beim Grep).
- Vorschlag: Einen Satz ergänzen: [E] reißt Hängendes ab und tritt es aus (angesengt, liegt dann am Boden). Dazu, ob Gäste helfen.
- Entscheidung nötig: nein

## Annahmen über andere Systeme
- Gäste gehen seit 3.11. nicht ins UG (SK 7.9; genutzt in 5.9 Z. 3336, 5.10 Z. 3400) – steht im Widerspruch zu den Wäschekisten in der Wäscherei (C-02).
- Anspruch steigt ab dem ersten Angriff bzw. dem 2. Oktober von ×1 auf ×3 an Halloween (SK 4.8 Z. 1742, 5.10 Z. 3391, 3470) – der Code rechnet ab Tag 2 (`monster_director.gd:52`). Das passt, solange der erste Angriff die Siegerehrung am 2.10. ist (HANDLUNG M3).
- Abschreckung = Deko-Stärke × Licht / Anspruch, Schutzkreis = Lichtschein (SK 4.9 Z. 1774–1776, 5.10 Z. 3476–3481).
- Das Monster bläst Kerzen aus (4.13), zögert drei Sekunden vor Salz (5.13 Z. 3603) und hält im Schein des Kesselfeuers Abstand (README) – in Block B zu prüfen.
- Der Lakengeist: Lakengespenster ziehen ihn an die Tür, halten ihn von Fenstern fern (5.6 Z. 3227–3232, 4.20 Z. 2400). In der Geisterstunde kommt er nicht zu Türen mit Lakengespenstern (4.18 Z. 2235). Die Salzlinie schützt das ganze Zimmer (5.13 Z. 3592).
- Kürbismann: Spaßwert aus Schmücken und Feiern ruft ihn (5.9 Z. 3306, 5.19 Z. 3774–3775). Die Kürbismaske senkt die Schwelle drastisch (5.19 Z. 3825). Betäubung nur durch gezeigte Kürbisse (4.21 Z. 2455, vgl. C-18). Belohnungen Schädel, Axt und Jeansjacke (4.21 Z. 2490–2492) sind nicht gebaut.
- Urteil (4.33): 8–12 Mal, etwa alle drei Tage, nie an Balltagen (5.19 Z. 3776–3777). Die Puppe zählt nicht zur Regel „eine Bedrohung je Ebene“ (5.5 Z. 3191).
- Kinder werfen Kerzen bei Streichen (6.13 Z. 4490; 5.11 Z. 3506, 5.12 Z. 3547). Laut 6.13 zerbricht die Kerze mit Wachsfleck – ob eine brennende Kerze dabei Deko anzündet (5.11), muss Block D gegenprüfen.
- Katzen bringen einmal am Tag Deko vor Zimmer 13 (5.10 Z. 3410, 6.11 Z. 4361).
- Herzensbitten und Lieblingskürbis: 6.14 Z. 4585–4609 (Casper-Beispiel unerfüllbar, C-03).
- Freundschaften und Streit nach Diebstahl (6.16; 5.10 Z. 3434–3436), Beziehungswerte +8/+3 für die Deko-Suche (5.9 Z. 3341–3342) und +10/+3 für Beerdigen (5.15 Z. 3692, 3703).
- Kostüme ab dem 25. und Lakenkostüm vs. Lakengeist (5.9 Z. 3344–3353) – setzt Flocken (7.6) und Geisterklang (4.18) voraus.
- Die Fotowand trägt die Ernten 1987–2026 im Dreijahresrhythmus (2.10 Z. 970; 5.14 Z. 3634–3640).
- Kesselbuch in Josefs Spind im Heizraum, fehlende Seite am alten Kessel in U2 (7.4 Z. 5391; 5.19 Z. 3812–3814) – U2 ist nicht gebaut.
- Generalschlüssel und Brecheisen sind die Wege zur Streichholzschachtel in 022 (5.12 Z. 3537–3539). Der Generalschlüssel liegt seit ZIM-6 im Sekretariat hinter einem Zahlenschloss, also spät; früh bleibt nur das Brecheisen aus dem Heizraum.
- Wetter: Böen löschen stehende offene Kerzen (5.12 Z. 3530, 7.8).

## Nicht geprüft
- Code-Stichproben, die wegen Speichermangel abgebrochen wurden: Rascheln von Laub als Lärm (5.3 Z. 3089), Löschen hängender Deko (C-22), Frühwarnung ab 16 m (5.6 Z. 3224), Nachfüllen des Kerzenvorrats auf die halbe Zahl bewohnter Zimmer (5.12 Z. 3572–3573), drei Sekunden Zögern des Monsters vor Salz.
- Ob ein Planeintrag `pumpkin_plant` genau eine Pflanze ist und wie viel Gäste ernten (C-04); dafür bräuchte es einen Spiellauf.
- Die Werte der Stufen 2 und 3 aus 5.10 (Lichtreichweiten, ×1,6, Chancen beim Diebstahl) und die Wirkungen der Masken aus ZIM-102 im Code.
- Friedhof (5.15) und Fotowand (5.14) nur gegen die Querbezüge gelesen, nicht gegen den Code.
- Kapitel 2, 4, 6 und 7 nur an den genannten Stellen per Grep; YouTrack wie vereinbart nicht abgefragt.
