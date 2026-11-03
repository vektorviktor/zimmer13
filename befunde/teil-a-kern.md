# Befunde Teil A – Pitch, Stimmung, Kernschleife, Handlung

Geprüft: `SPIELKONZEPT.md` Kap. 1–3 (Z. 144–1681) und `HANDLUNG.md` vollständig, dazu Querbezüge per Grep in 4.33, 5.9,
6.17, 6.19, 7.4, `HAUSHALTE.md` und 15 Code-Stichproben. Die meisten Werte aus Kap. 3 stimmen mit dem Code überein.
Die Probleme liegen vor allem in der Hauptgeschichte: Der Halloween-Schlüssel hat seit 2.10 einen festen Fundort, aber
kein Zeitfenster. Ednas Belohnung widerspricht 2.10, und die Halloween-Nacht hat keinen Zeitplan. Dazu kommt viel
Text, der von späteren Entscheidungen überholt wurde: die harmlose Phase (4.33), „jedes Jahr“, die Wachzeit und die
Status-Köpfe. Bei den Code-Abweichungen fallen die Inhalte der Warnungszettel und der UV-Schrift auf, die der Lore von
2.3/2.7/2.10 widersprechen.

## Befunde

### A-01 Der Halloween-Schlüssel ist ab etwa dem 14. greifbar, nicht erst an Halloween
- Art: Widerspruch
- Schwere: hoch
- Fundstellen: `SK 2.1` (SPIELKONZEPT.md:173, 175–180), `SK 2.3` (SPIELKONZEPT.md:245), `SK 2.10` (SPIELKONZEPT.md:1031–1033), `SK 7.4` (SPIELKONZEPT.md:5461), `SK 2.8` (SPIELKONZEPT.md:793, 803), `HANDLUNG.md:84`, `HANDLUNG.md:229–233`, `scripts/world/warning_note.gd:30`
- Befund: 2.1 sagt: „An Halloween taucht in einem Zimmer ein Schlüssel auf.“ Der Zettel von 2011 im Code sagt:
  „Am 31. lag der Schlüssel einfach da.“ Laut HANDLUNG M18 holt man ihn am 28.–31. Seit 2.10/7.4 liegt er aber seit
  2008 im Koffer von Rudolf Hain bei den Fundsachen in U2. U2 erreicht man mit dem Aufzug etwa ab dem 14. (M11) oder
  durch die Mauer ab Tag 15. Damit kann man den Schlüssel gut zwei Wochen vor dem Ende haben. Die
  „Ideen zum Schlüssel“ in 2.1 stehen weiter als offene Auswahl da. K6 nennt noch „Kandidaten“, darunter Edna, und
  M18 hat den Status „Kandidat“.
- Vorschlag: Ein Zeitfenster festlegen. Eine Möglichkeit: Der Koffer ist bis zum 31. leer bzw. verschlossen, und der
  Schlüssel „liegt am 31. einfach da“. Das passt zum Zettel von 2011 und zu 2.1. Die andere Möglichkeit: Der Schlüssel
  ist früh greifbar, dann braucht A-02 eine Antwort. Danach 2.1 (Ideenliste), M18 und K6 auf den Stand von 2.10
  bringen.
- Entscheidung nötig: ja

### A-02 Den Ausgangsschlüssel muss man in der Hand tragen – über Wochen, und Diebstahl ist nicht geregelt
- Art: Lücke
- Schwere: hoch
- Fundstellen: `SK 3.2` (SPIELKONZEPT.md:1252), `SK 7.4` (SPIELKONZEPT.md:5464–5465), `SK 3.2` (SPIELKONZEPT.md:1242)
- Befund: Der Schlüssel passt bewusst nicht an den Bund, man soll ihn auf der Flucht nicht fallen lassen dürfen.
  Nach 2.10 läuft die Öffnung aber erst mit der Mitternachtsglocke ab (2.7, SPIELKONZEPT.md:667–668). Eine Flucht
  mit dem Schlüssel in der Hand gibt es also nicht mehr. Wer ihn früh findet (A-01), legt ihn ab. Abgelegtes ist
  „klaubar“, und Gäste fahren selbst nach U2 und plündern das Lager. Es fehlen Regeln dafür: ob Gäste den
  Schlüssel stehlen oder einstecken können, ob er in die Tasche passt und was passiert, wenn ein Gast mit ihm stirbt.
- Vorschlag: Entweder der Schlüssel ist unstehlbar wie die Brille (2.9: „Gäste stehlen sie nicht“) und darf in
  Truhe oder Tasche. Oder der Diebstahl wird bewusst zur Spannung: Dann braucht es einen Rückweg, etwa „Gerücht, wer
  ihn hat“. Die Begründung in 3.2 („Flucht bleibt ein Lauf“) an 2.7 anpassen.
- Entscheidung nötig: ja

### A-03 Ednas Belohnung widerspricht 2.10: 1987 war der Haupteingang gar nicht verschlossen
- Art: Widerspruch
- Schwere: hoch
- Fundstellen: `HANDLUNG.md:222`, `HANDLUNG.md:233`, `SK 6.17` (SPIELKONZEPT.md:4696), `SK 2.10` (SPIELKONZEPT.md:981–983)
- Befund: Rettet man Edna um den 20., „erzählt sie, wie sich der Haupteingang 1987 geöffnet hat“. K6 führt sie
  sogar als möglichen Weg zum Schlüssel. Nach 2.10 war das Hotel 1987 aber nicht verschlossen, und wer überlebte,
  ging am Morgen einfach hinaus. Edna hat damit kein Wissen über den Schlüssel. Der Lohn für die einzige rettbare
  Kernfigur ist leer.
- Vorschlag: Ednas Lohn neu fassen. Eine Möglichkeit: Sie erkennt den alten Herrn auf dem Foto von 1987
  (2.10, SPIELKONZEPT.md:1054). Eine andere: Sie führt zum Koffer Heinrich Brehms und darin zu einem Hinweis auf
  Rudolf Hain. Oder sie hilft beim Holen des Schlüssels („einer lenkt ab“, 2.1). K6 und 6.17 dann angleichen.
- Entscheidung nötig: ja

### A-04 Die Halloween-Nacht hat keinen Ablauf: Fest, Ritual, letztes Urteil und Glocke überschneiden sich
- Art: Lücke
- Schwere: hoch
- Fundstellen: `SK 2.7` (SPIELKONZEPT.md:667–671), `SK 2.8` (SPIELKONZEPT.md:768–770, 815–826), `HANDLUNG.md:90–95`, `SK 2.4` (SPIELKONZEPT.md:341–342)
- Befund: Am Abend des 31. gibt es das Fest mit Gruppenfoto (M19). Das Ritual läuft „vom Fest am Abend bis zur
  Öffnung“ in U2, und U2 gehört dann schon dem Monster (M17). Ohne Erlösung kommen „das letzte Urteil und der letzte
  Angriff vor der Öffnung“, und die Mitternachtsglocke löst das Ende aus. Offen bleibt:
  - wann das letzte Urteil fällt, also vor oder nach dem Ritual;
  - was passiert, wenn der Spieler um Mitternacht noch in U2 ist oder nicht am Tor steht, denn Ende 1 verlangt, dass
    er den Schlüssel steckt;
  - ob der Spieler beim Fest dabei sein muss;
  - wie die Gäste in die Lobby kommen, während das Monster angreift.
- Vorschlag: Einen Zeitplan der letzten Nacht festlegen, etwa Fest 19–21 Uhr, Urteil 22 Uhr, Ritualfenster bis
  23:45 Uhr, Glocke. Dazu die Regel „Glocke ohne Spieler am Tor = …“.
- Entscheidung nötig: ja

### A-05 Fall „Vertrag verbrannt, aber nicht erlöst“ ist keinem Ende zugeordnet
- Art: Lücke
- Schwere: mittel
- Fundstellen: `SK 2.8` (SPIELKONZEPT.md:832–833), `SK 2.10` (SPIELKONZEPT.md:1062–1065), `SK 2.7` (SPIELKONZEPT.md:693–699), `HANDLUNG.md:201`
- Befund: Die Enden teilen sich nur am Merkmal „erlöst“. 2.10 knüpft das Vergessen aber ans Abkommen: „Ende 1 teilt
  sich am erlösten Leviathan (2.8, der Vertrag verbrannt)“. Wer den Vertrag verbrennt, aber keine Sachen bringt,
  hat das Abkommen gebrochen, ohne Josef zu erlösen. Ob dann vergessen wird (1a oder 1b), welcher Epilog folgt und
  wie Ende 2 bzw. 3 aussieht, steht nirgends.
- Vorschlag: Zwei Merkmale trennen, nämlich „Abkommen gebrochen“ (Vergessen, Epilog 1b) und „erlöst“ (letzter
  Angriff, Ende 3), und eine kleine Tabelle der Kombinationen anlegen.
- Entscheidung nötig: ja

### A-06 Harmlose Phase: Kap. 2 beschreibt noch die „neun Aufbrüche, anderthalb Tage“ statt der drei harmlosen Raubzüge
- Art: veraltet
- Schwere: mittel
- Fundstellen: `SK 2.1` (SPIELKONZEPT.md:161–163, 171–172), `SK 2.4` (SPIELKONZEPT.md:295–298), `SK 2.6` (SPIELKONZEPT.md:592–593, 643), `SK 2.9` (SPIELKONZEPT.md:958–959), `SK 4.33` (SPIELKONZEPT.md:2938–2950, 3038–3040), `scripts/monster/monster_director.gd:135`
- Befund: Nach 4.33 und im Code (`HARMLESS_RAIDS := 3`) sind nur die ersten drei Raubzüge harmlos. Bei 10–13
  Raubzügen im Monat reicht das eher über eine Woche als über anderthalb Tage. Kap. 2 nennt weiter „neun Aufbrüche,
  etwa anderthalb Spieltage“. Laut 2.6 zählt Gustav „als erster Aufbruch der harmlosen Phase“. 2.4 sagt außerdem, es
  „bricht etwa sechsmal am Tag auf, die übrigen Aufbrüche sind Umsehen“. 4.33 hat das ersetzt: kein Modus 0, 24–33
  Auftritte im ganzen Spiel. 2.1 Z. 171 benennt den Ersatz zwar, lässt den alten Satz aber stehen.
- Vorschlag: 2.1, 2.4 und 2.6 auf 4.33 umschreiben bzw. dorthin verweisen. Die Sättigung (2.6, Z. 592) als
  Erklärung der harmlosen Phase streichen, denn sie senkt seit 4.33 nur die Dreistigkeit.
- Entscheidung nötig: nein

### A-07 Die Urteile der Puppe sind nie harmlos – die versprochene Lernzeit gibt es nicht
- Art: Widerspruch
- Schwere: mittel
- Fundstellen: `SK 2.5` (SPIELKONZEPT.md:401–403, 430–432), `SK 4.33` (SPIELKONZEPT.md:2938, 2966–2967), `HANDLUNG.md:43`, `scripts/monster/monster_director.gd:93`, `scripts/monster/monster_director.gd:664–667`
- Befund: 2.5 verspricht: „Die Puppe urteilt schon … Ein- oder zweimal sieht man die Regel, bevor jemand vor der
  Puppentür stirbt.“ Nach 4.33 holt aber jedes Urteil jemanden, nur die Raubzüge sind anfangs harmlos. Im Code fällt
  das erste Urteil zufällig zwischen dem 3. und 6. Oktober (`JUDGMENT_FIRST` 4–5 ± 0,6, gerundet). Schon das erste
  Urteil kann also töten, auch den Spieler, wenn seine Tür die schwächste ist. HANDLUNG M5 legt das erste Urteil fest
  auf den 3.10.
- Vorschlag: Entweder das erste Urteil harmlos machen, wie die Raubzüge: Die Puppe sitzt, es kommt, bricht ab.
  Oder den Satz in 2.5 streichen und M5 auf „3.–6.10.“ setzen. Spielerisch spricht viel fürs harmlose erste Urteil,
  weil der Warnungszettel 1999 erst am Morgen danach kommt.
- Entscheidung nötig: ja

### A-08 Doris' Bogen kann vor dem 4.10. durch ein Urteil zerbrechen
- Art: Lücke
- Schwere: mittel
- Fundstellen: `SK 2.9` (SPIELKONZEPT.md:936, 956–959), `SK 6.17` (SPIELKONZEPT.md:4700–4701), `SK 4.33` (SPIELKONZEPT.md:2970)
- Befund: Der Vorschlag „In der harmlosen Phase kann Doris nicht sterben“ trägt nicht, weil die Urteile nicht
  harmlos sind (A-07). Doris ist keine Kernfigur und hat keinen Schutz auf Zeit. Stirbt sie am 3. oder 4. durch ein
  Urteil oder einen Raubzug, laufen M5a, M7a und M7b ins Leere: Es gibt keine Übergabe der Brille, keine Blechdose,
  keine Ohrenzeugin und keine Schuld.
- Vorschlag: Doris bis zum 4.10. um 20 Uhr wie eine Kernfigur schützen, also nach 6.17 „Schutz auf Zeit“ unter
  „Weitere Figuren“ aufnehmen, oder einen Ersatzweg für ihren Tod festlegen.
- Entscheidung nötig: ja

### A-09 Schicht 4 „Wahrheit“ hat keinen Träger: Der einzige schweigende Täter ist nie zu sehen
- Art: Lücke
- Schwere: mittel
- Fundstellen: `SK 2.3` (SPIELKONZEPT.md:247, 260, 264), `SK 2.11` (SPIELKONZEPT.md:1141, 1148–1150), `SK 2.8` (SPIELKONZEPT.md:800–806), `SK 3.10` (SPIELKONZEPT.md:1601), `HANDLUNG.md:24`
- Befund: Nach 2.3 bricht ein Mitwisser sein Schweigen, „wenn man ihm den Beweis vorlegt“. Als
  „wahrscheinlichster, der bricht“ gilt der Page bzw. Hausmeister. Man sieht ihn aber nie (2.11). Wie man ihm etwas
  vorlegt, ist offen. Der genannte Kandidat, der zweite Weg ins Büro (ZIM-6), ist inzwischen anders entschieden,
  nämlich mit Josefs Bund am Kessel. In HANDLUNG fehlt ein Meilenstein für diese Schicht. Das Tagebuch
  hat trotzdem den Meilenstein „ein Mitwisser bricht sein Schweigen“.
- Vorschlag: Den Bruch des Hausmeisters über Spuren erzählen, etwa einen Zettel, den er hinlegt, nachdem man einen
  Beweis an einen festen Ort gebracht hat (Hausmeisterraum, warme Tasse). Oder die Wahrheit-Schicht bewusst Marion,
  Edna, Liesel und Mila zuordnen und den Satz in 2.3 und 2.11 anpassen.
- Entscheidung nötig: ja

### A-10 „Erste Ernte“: 1987 oder 1990?
- Art: Widerspruch
- Schwere: mittel
- Fundstellen: `SK 2.10` (SPIELKONZEPT.md:969–970, 981–983, 1009), `SK 2.3` (SPIELKONZEPT.md:279), `SK 2.7` (SPIELKONZEPT.md:683)
- Befund: 2.10 zählt 1987 mit („1987, 1990 … 2026 … 14 Ernten“). Zugleich heißt es dort und in 2.3 und 2.7, die
  erste Ernte sei 1990 gewesen, und 1987 sei das Abkommen noch nicht besiegelt gewesen. Das berührt das Rätsel
  direkt: Der Code der Generalschlüssel-Schublade ist 1990, „die erste Ernte, aus dem Gästebuch“. Wer 14 Rahmen ab
  1987 zählt, probiert 1987.
- Vorschlag: Begriffe trennen. 1987 als „das Jahr des Abkommens bzw. des Brandes“, 1990 als „erste Ernte“, und die
  Fotowand als „14 Halloween-Wochen“ beschreiben. Prüfen, ob das Gästebuch 1990 eindeutig als erste Ernte zeigt.
- Entscheidung nötig: ja

### A-11 Code: Warnungszettel und Zettelorte noch mit Nicht-Erntejahren (1994, 2003, 2019)
- Art: Code-Abweichung
- Schwere: mittel
- Fundstellen: `SK 2.10` (SPIELKONZEPT.md:1096), `SK 4.13` (SPIELKONZEPT.md:1903), `scripts/world/warning_note.gd:13`, `scripts/world/warning_note.gd:23`, `scripts/world/warning_note.gd:31`, `scripts/level/level_builder.gd:451`, `scripts/level/level_builder.gd:456–457`
- Befund: 2.10 verlangt, die Zettel von 1994, 2003 und 2019 auf Erntejahre zu legen (2003 → 2005). Im Code stehen
  sie unverändert. Besonders störend ist der Zettel 2003 in Zimmer 014: Das ist das Zimmer von Rudolf Hain 2005/2008
  und die zentrale Fährte zum Schlüssel. Ein Gast von 2003 dort widerspricht „zwischen den Ernten keine Toten“. 4.13
  nennt noch „1987–2019“. Laut 2.10 ist das als „beim Bau“ vorgemerkt (ZIM-117), also bekannt, aber noch offen.
- Vorschlag: Mit ZIM-117 umsetzen. Zimmer 014 bekommt einen Zettel von 2005/2008 oder gar keinen.
- Entscheidung nötig: nein

### A-12 Code: UV-Schrift in 018 „NUR EINER KOMMT HINAUS“ widerspricht 2.7
- Art: Code-Abweichung
- Schwere: mittel
- Fundstellen: `scripts/level/level_builder.gd:454`, `SK 2.7` (SPIELKONZEPT.md:651–657), `SK 2.3` (SPIELKONZEPT.md:245)
- Befund: Seit 25.10. öffnet der Schlüssel das Tor für alle Überlebenden. Die alte Regel „für genau einen“ ist
  ersetzt. Die UV-Schrift im Zimmer des Gastes von 2005 behauptet das Gegenteil. Gerade dieser Gast wusste nach
  2.10, dass Rudolf Hain die anderen hinausbringen würde.
- Vorschlag: Neuer Text im Sinne von 2.10, z. B. „R. HAT IHN. WIR NICHT MEHR.“
- Entscheidung nötig: nein

### A-13 Code: Ednas UV-Schrift „ICH HABE ES GEBLENDET“ widerspricht ZIM-9 („1987 formlos, gesehen hat es keiner“)
- Art: Code-Abweichung
- Schwere: niedrig
- Fundstellen: `scripts/level/level_builder.gd:452–453`, `SK 2.3` (SPIELKONZEPT.md:277–281)
- Befund: Ednas Zettel ist seit 3.11. an die Entscheidung angepasst, dass es 1987 formlos war („Gesehen hat es
  keiner“). Ihre UV-Schrift in 017 sagt aber „Ich habe es geblendet. Jetzt kennt es meine Tür.“
- Vorschlag: UV-Zeile anpassen, z. B. „Es ist warm vor meiner Tür. Es weiß, wo ich schlafe.“
- Entscheidung nötig: nein

### A-14 Code: Der Grinch hasst auch Doris, obwohl sie „seine einzige Freundin“ ist
- Art: Code-Abweichung
- Schwere: niedrig
- Fundstellen: `SK 2.6` (SPIELKONZEPT.md:605, 616), `SK 2.9` (SPIELKONZEPT.md:854), `scripts/guests/grinch.gd` (keine Ausnahme für Doris bzw. H34)
- Befund: 2.6 sagt „Er hasst alle“. 2.6 (Reaktionen) und 2.9 machen Doris zu seiner einzigen Freundin, mit der
  gemeinsamen Abneigung gegen die Musik. In `grinch.gd` gibt es keine Ausnahme. Er kann ihr also die Deko zerschlagen
  und sie schlagen, und sie wird mit ihm verfeindet. Das untergräbt die Trauer in 2.9.
- Vorschlag: Doris im Grinch-Absatz und im Code ausnehmen, so dass sie Freundin bleibt und er sie nicht angreift.
- Entscheidung nötig: nein

### A-15 Ressourcen gegen Erschöpfung werden nie knapp: Automaten ohne Ende, Dose füllt die Ausdauer ganz
- Art: Optimierung (Spielerlebnis/Balance)
- Schwere: mittel
- Fundstellen: `SK 3.1` (SPIELKONZEPT.md:1199–1203), `SK 3.7` (SPIELKONZEPT.md:1443–1446), `SK 3.2` (SPIELKONZEPT.md:1243), `SK 3.11` (SPIELKONZEPT.md:1627), `scripts/world/vending_machine.gd:8`, `scripts/player/player.gd:1738`
- Befund: „Wer flieht, muss sich gut überlegen, wann er rennt“ hält nicht: Eine Dose kostet 1 Geld, ist an Automaten
  „ohne Ende“ zu haben und füllt die Ausdauer sofort ganz. Sechs Dosen passen in die Tasche, das sind sechs volle
  Sprints im Gepäck. Kaffee ist an der Maschine kostenlos. Die Ausdauer als Fluchtentscheidung wird damit zur
  Formsache, sobald man etwas Geld hat.
- Vorschlag: Die Dose nur teilweise auffüllen (z. B. +40 %) oder mit einer Trinkdauer und lautem Öffnen (das Zischen
  als Lärm verraten lassen). Oder den Vorrat der Automaten je Spieltag begrenzen bzw. die Dose nur außerhalb der Jagd
  wirken lassen.
- Entscheidung nötig: ja

### A-16 Siegerehrung: Wer um 22 Uhr in Zimmer 020 steht, stirbt ohne Warnung
- Art: Optimierung (Spielerlebnis)
- Schwere: niedrig
- Fundstellen: `SK 2.6` (SPIELKONZEPT.md:647–648), `SK 3.6` (SPIELKONZEPT.md:1395–1396)
- Befund: Gebaut ist, dass der Spieler mitstirbt, wenn er die Siegerehrung schwänzt und bei Gustav steht. Sonst gilt
  der Grundsatz „kein Tod ohne Chance zu reagieren“. Ein neugieriger Spieler, der dem Grinch etwas vor die Tür legt,
  verliert so den ersten Abend ohne jedes Signal.
- Vorschlag: Ein kurzes Vorzeichen (Licht flackert in 020, Rauschen, 3 s), dann geht es wie in 2.6 weiter.
- Entscheidung nötig: ja

### A-17 Drei Gruppenfotos: Das Festfoto mit „leeren Plätzen“ ist überholt
- Art: Widerspruch / Optimierung (Umfang)
- Schwere: niedrig
- Fundstellen: `SK 2.7` (SPIELKONZEPT.md:676, 729, 745–746), `SK 2.8` (SPIELKONZEPT.md:772), `SK 2.10` (SPIELKONZEPT.md:987–988, 1013), `SK 5.9` (SPIELKONZEPT.md:3382), `SK 4.22` (SPIELKONZEPT.md:2602), `HANDLUNG.md:90`, `HANDLUNG.md:93`
- Befund: Es gibt das Ankunftsfoto (2.10), ein Gruppenfoto beim Fest (5.9, M19, „mit leeren Plätzen“) und ein Foto
  draußen in Ende 1 (2.7). 2.7 verweist beim Foto draußen auf 5.9, als wäre es dasselbe. 2.10 hat das Foto beim Fest
  gerade verworfen, weil Tote beim Fest fehlen und keine „Plätze“ haben. Am selben Abend entstehen so zwei Fotos.
  Am Festfoto hängt außerdem die Vampir-Enthüllung (4.22).
- Vorschlag: Das Festfoto streichen. Das Foto draußen (nur Ende 1) wird das Gruppenfoto. Die Vampir-Enthüllung
  verlegt man ans Ankunftsfoto bzw. an die Fotowand oder ins Ende. Danach 5.9, M19 und 2.7 angleichen.
- Entscheidung nötig: ja

### A-18 Zu viele Schlüssel mit überlappender Reichweite
- Art: Optimierung (Umfang)
- Schwere: niedrig
- Fundstellen: `SK 2.8` (SPIELKONZEPT.md:797–809), `SK 2.10` (SPIELKONZEPT.md:1000–1012), `SK 2.7` (SPIELKONZEPT.md:720), `SK 6.19` (SPIELKONZEPT.md:4938)
- Befund: Ins Büro führen der Bund des Rezeptionisten und Josefs Bund („das ganze Haus am Gürtel“). Dazu kommen der
  Sekretariatsschlüssel, der Generalschlüssel und der Dachbodenschlüssel „hinter der Leviathanmauer“. Josefs Bund
  hängt ebenfalls hinter der Mauer. Wer ihn hat, müsste nach seiner eigenen Beschreibung auch Dachboden und
  Gästezimmer öffnen. Das ist nicht geregelt. 6.19 nennt den Generalschlüssel noch „von der Rezeption“, seit 2.10
  liegt er im Sekretariat.
- Vorschlag: Josefs Bund auf Büro und Sekretariat beschränken („die Direktionsschlüssel“), den Dachbodenschlüssel
  davon ausnehmen. 6.19 auf das Sekretariat umstellen.
- Entscheidung nötig: ja

### A-19 Ende 3 setzt voraus, dass man den Schlüssel bewusst liegen lässt
- Art: Optimierung (Story)
- Schwere: niedrig
- Fundstellen: `SK 2.7` (SPIELKONZEPT.md:682–690), `SK 2.8` (SPIELKONZEPT.md:791–793), `SK 7.4` (SPIELKONZEPT.md:5461)
- Befund: Für die Erlösung braucht man Josefs Sachen aus den Fundsachen in U2. Dort liegt auch der Koffer mit dem
  Ausgangsschlüssel. Ende 3 („erlöst, ohne Schlüssel“) erreicht man so fast nur absichtlich, das bitterste Ende wird
  zum Sonderfall. Hängt mit A-01 zusammen.
- Vorschlag: Mit A-01 entscheiden. Ein Zeitfenster für den Schlüssel (31.) macht Ende 3 zur echten Folge eines
  gescheiterten Schlüssel-Laufs in der letzten Nacht.
- Entscheidung nötig: ja

### A-20 HANDLUNG.md hinkt 2.10 hinterher: Schlüssel-Fährte, Fotowand, Walter, Oskar, Sekretariat fehlen
- Art: veraltet / Optimierung (Doku, Story)
- Schwere: mittel
- Fundstellen: `SK 2.10` (SPIELKONZEPT.md:1040–1044, 1081–1090, 996–1012), `HANDLUNG.md:84`, `HANDLUNG.md:226–233`, `HANDLUNG.md:181–182`
- Befund: Die ausgearbeitete Fährte zum Schlüssel hat keinen Meilenstein in HANDLUNG. Dazu gehören die Bleistiftnotiz
  in Zimmer 18 („R. hat ihn“), Walter Ruprecht als falsche Fährte, das Gästebuch 014, das Foto 2005 im Sekretariat
  und Oskars Erinnerung. Rudolf Hain, Oskar, Walter und die Fotowand kommen in HANDLUNG nicht vor. Sekretariat und
  Generalschlüssel stehen nur in K3 und in den „Offenen Fragen“.
- Vorschlag: In Akt III/IV Meilensteine „Fährte zum Schlüssel“ (M11b o. ä.) und „Sekretariat: Foto 2005,
  Generalschlüssel (Code 1990)“ aufnehmen. M18 und K6 auf den Stand von 2.10 setzen.
- Entscheidung nötig: nein

### A-21 Veraltete Status-Köpfe und „Zu klären“-Punkte, die längst entschieden sind
- Art: veraltet
- Schwere: niedrig
- Fundstellen: `SK 2.1` (SPIELKONZEPT.md:161–163), `SK 2.2` (SPIELKONZEPT.md:192), `SK 2.3` (SPIELKONZEPT.md:215, 284), `SK 2.4` (SPIELKONZEPT.md:341–342), `SK 2.7` (SPIELKONZEPT.md:748), `SK 2.8` (SPIELKONZEPT.md:838–840), `SK 2.9` (SPIELKONZEPT.md:845), `SK 2.11` (SPIELKONZEPT.md:1150), `SK 3.5` (SPIELKONZEPT.md:1313), `HANDLUNG.md:262–274`
- Befund: Folgende Stellen sind überholt:
  - 2.1: „Noch offen: Schlüssel und Scheitern“, obwohl beides in 2.7 und 2.10 entschieden ist.
  - 2.2: „Favorit … noch nicht umgesetzt“ steht im verworfenen Abschnitt.
  - 2.3: „Noch nicht umgesetzt“, obwohl Register, Büro, Sekretariat, Porträt und das Notizbuch des Hausmeisters
    gebaut sind. Die Frage „Wie hängt das Geheimnis mit dem Schlüssel zusammen“ beantworten 2.8 und 2.10.
  - 2.4: „Ende bleibt offen (2.1, 2.2)“.
  - 2.7: Die Vampir-Frage (Z. 748) ist in Z. 701–703 entschieden.
  - 2.8: „Offen: zweiter Weg ins Büro (ZIM-6)“ ist in Z. 800–812 entschieden und gebaut.
  - 2.9: „Noch nicht gebaut“, obwohl Register, Mitteilung und Klingel gebaut sind.
  - 2.11: Kandidat ZIM-6 ist überholt.
  - 3.5: „abschließbare Schubladen kommen mit ZIM-6“ ist gebaut (Z. 1010–1012).
  - HANDLUNG §4: alle Punkte erledigt.
- Vorschlag: Status-Köpfe nachziehen, erledigte „Zu klären“ entfernen. Den verworfenen 2.2 ganz ins Archiv bzw. auf
  einen Verweis kürzen (25 Zeilen ohne Geltung). HANDLUNG §4 leeren.
- Entscheidung nötig: nein

### A-22 Reste von „jedes Jahr“ und vom Dauergast Walter
- Art: veraltet
- Schwere: niedrig
- Fundstellen: `SK 2.5` (SPIELKONZEPT.md:394), `SK 2.7` (SPIELKONZEPT.md:689–690, 733), `HAUSHALTE.md:65`, `HAUSHALTE.md:81`, `SK 2.10` (SPIELKONZEPT.md:1081–1084)
- Befund: Diese Stellen sind seit 2.10 überholt:
  - 2.5: Das Abkommen veranstalte „jedes Jahr dasselbe“.
  - 2.7: „erklärt, warum es jedes Jahr wieder ein Monster gibt“ und „Darum wirkt die Einladung jedes Jahr“.
  - HAUSHALTE H23 nennt Walter „Dauergast, kennt jeden Winkel“. Laut 2.10 ist er erst seit 2023 hier und eine
    falsche Fährte. 2.10 sagt ausdrücklich „ändert HAUSHALTE.md“, das ist nicht geschehen.
  - H39 Oskar verweist auf den verworfenen 2.2.
- Vorschlag: Auf „jede Ernte“ bzw. „alle drei Jahre“ umstellen. H23 und H39 nach 2.10 anpassen.
- Entscheidung nötig: nein

### A-23 2.4 beschreibt noch das alte Schlafmodell (Nächte zählen, Zeitraffer ×5)
- Art: veraltet
- Schwere: niedrig
- Fundstellen: `SK 2.4` (SPIELKONZEPT.md:303–304, 330–332), `SK 3.6` (SPIELKONZEPT.md:1330–1337, 1404–1405)
- Befund: In 2.4 steht noch, „Nächte ohne Schlaf zählen bis drei … bis die Wachzeit sie ersetzt“ und „im eigenen Bett
  läuft die Zeit fünfmal so schnell; in der Nachtruhe springt sie“. Seit 27.10. gibt es die Wachzeit in Stunden, die
  Schwelle 48–72 h und den Sprung auch am Tag. ×5 gibt es nur noch für Reste unter einer Minute.
- Vorschlag: In 2.4 nur auf 3.6 verweisen.
- Entscheidung nötig: nein

### A-24 3.6 und 3.11: drei Schichten Schlaftext, Kaffee noch in „Nächten“
- Art: Optimierung (Doku-Struktur)
- Schwere: niedrig
- Fundstellen: `SK 3.6` (SPIELKONZEPT.md:1346–1358, 1360–1381), `SK 3.11` (SPIELKONZEPT.md:1618–1622), `scripts/player/player.gd:135`, `scripts/player/player.gd:137`
- Befund: 3.6 enthält den gebauten Stand (27.10.) und daneben die überholte „Vorstufe“ mit Nächten (24.10./20.10.). Dazu
  kommt ein „Ziel“-Block, der dieselben Stufen noch als „Vorschlag“ führt (~16 h / ~24 h). 3.11 beschreibt die
  Wirkung des Kaffees als „eine Nacht weniger“ bzw. „eine halbe Nacht mehr“. Der Code rechnet in Stunden
  (`COFFEE_MASK` 12 h, `COFFEE_LOW` 6 h). Die Werte passen, die Begriffe nicht mehr.
- Vorschlag: 3.6 auf einen Block „So ist es gebaut“ kürzen, Vorstufe und Ziel streichen. 3.11 auf „überdeckt
  12 Wachstunden, Tief +6 h“ umstellen.
- Entscheidung nötig: nein

### A-25 Marion als „Konkurrentin um den einen Schlüssel“
- Art: veraltet
- Schwere: niedrig
- Fundstellen: `SK 2.3` (SPIELKONZEPT.md:248), `SK 2.7` (SPIELKONZEPT.md:656–657), `SK 2.8` (SPIELKONZEPT.md:771)
- Befund: Seit 2.7 öffnet der Schlüssel das Tor für alle, und Marion bleibt freiwillig. Die Rolle als Konkurrentin
  ergibt keinen Sinn mehr.
- Vorschlag: Den Satz streichen bzw. durch „Verbündete, die nicht mit hinaus will (2.8)“ ersetzen.
- Entscheidung nötig: nein

### A-26 2.5 beschreibt noch die dunkle Gestalt in der Lobbyecke
- Art: veraltet
- Schwere: niedrig
- Fundstellen: `SK 2.5` (SPIELKONZEPT.md:416–418), `SK 2.6` (SPIELKONZEPT.md:547–548), `SK 2.1` (SPIELKONZEPT.md:171)
- Befund: „Das Monster steht in der dunklen Ecke der Lobby“ ist in 2.6 aufgehoben, steht aber noch als Hauptsatz da.
  Der Zusatz folgt erst danach. 2.1 sagt über die ersten Angriffe „man sieht es und weiß: Es ist real“. Das passt nur
  noch für die harmlosen Raubzüge.
- Vorschlag: Den Hauptsatz in 2.5 ersetzen.
- Entscheidung nötig: nein

### A-27 Notizbuch-Beispiel „Edna · Zi. 021“ – Edna wohnt in 003
- Art: Widerspruch
- Schwere: niedrig
- Fundstellen: `SK 3.10` (SPIELKONZEPT.md:1529, 1572), `HAUSHALTE.md:61`, `HAUSHALTE.md:63`, `HANDLUNG.md:72`
- Befund: In 021 wohnt Mila, Edna wohnt in 003, wie es auch HANDLUNG M15 und K5 („Notiz in 003“) sagen.
- Vorschlag: Beispiel auf „Zi. 003“ ändern.
- Entscheidung nötig: nein

### A-28 Kein Kartenblatt fürs Dachgeschoss
- Art: Lücke
- Schwere: niedrig
- Fundstellen: `SK 3.2` (SPIELKONZEPT.md:1251), `scripts/level/level_builder.gd:449`, `scripts/level/level_builder.gd:452`, `scripts/level/level_builder.gd:457`
- Befund: Blätter gibt es für EG, OG und Keller, „künftige Ebenen wie U2 bekommen eigene Blätter“. Das Dachgeschoss
  ist seit 24.10. gebaut, hat aber weder Blatt noch Fundort.
- Vorschlag: Fundort festlegen, etwa im Sekretariat (Baupläne, 2.3 „Baupläne als neue Kartenblätter“) oder bei
  Liesel.
- Entscheidung nötig: ja

### A-29 Zimmer-13-Truhe als „sicheres Lager“ gegen „Gäste klauen aus fremden Truhen“
- Art: Widerspruch
- Schwere: niedrig
- Fundstellen: `SK 3.3` (SPIELKONZEPT.md:1258–1260), `SK 3.2` (SPIELKONZEPT.md:1242)
- Befund: Die Truhe in Zimmer 13 ist nur so sicher wie die Zimmertür. Laut 3.2 sind abgelegte Dinge „klaubar“, wenn
  die Tür offen ist oder ein Gast einen Schlüssel hat. Ob Gäste in Zimmer 13 auch die Truhe öffnen, sagt 3.3 nicht.
- Vorschlag: Klarstellen, entweder „die Truhe in Zimmer 13 rührt kein Gast an“ oder „sicher nur bei abgeschlossener
  Tür“.
- Entscheidung nötig: ja

### A-30 HANDLUNG: Status „vorgemerkt“ nicht in der Legende, Abhängigkeiten ohne Grund
- Art: Optimierung (Doku-Struktur)
- Schwere: niedrig
- Fundstellen: `HANDLUNG.md:8–9`, `HANDLUNG.md:90`, `HANDLUNG.md:117`, `HANDLUNG.md:121`, `HANDLUNG.md:137`
- Befund: Folgendes passt nicht zusammen:
  - M19 hat den Status „vorgemerkt“, die Legende kennt nur fest, Anker und Kandidat.
  - Der Graph lässt Ednas Bedrohung (M15) und Milas Skizze (M15c) von der Aufzugsfahrt M11 abhängen. Beide sind aber
    datiert (um den 20. bzw. 18.) und brauchen den Aufzug nicht.
  - §3 heißt „Kandidaten im Detail“, enthält aber fast nur feste Stränge.
- Vorschlag: Legende ergänzen. M15 und M15c im Graph frei bzw. am Datum hängen lassen. §3 in „Stränge im Detail“
  umbenennen.
- Entscheidung nötig: nein

### A-31 „Anderthalb Spieltage“ und erster Raubzug: Kein fester Erstkontakt nach der Siegerehrung
- Art: Optimierung (Spielerlebnis, Tempo)
- Schwere: niedrig
- Fundstellen: `SK 2.1` (SPIELKONZEPT.md:171), `SK 4.33` (SPIELKONZEPT.md:3018–3019, 3038–3040), `SK 2.5` (SPIELKONZEPT.md:416–418)
- Befund: Nach der Siegerehrung, in der man das Monster gar nicht sieht (2.6), hängt der erste sichtbare Beweis
  „Es ist real“ am Zufall des ersten Raubzugs. Bei 10–13 Raubzügen im Monat kann das mehrere Tage dauern. Bis dahin
  trägt nur Gustavs Spur den Horror.
- Vorschlag: Den ersten harmlosen Raubzug fest in die Nacht 3./4.10. legen, während der Lernzeit des Suchtrupps bzw.
  vor dem ersten Abstieg.
- Entscheidung nötig: ja

## Annahmen über andere Systeme

- Die ersten drei Raubzüge sind harmlos, Urteile nie (4.33, SPIELKONZEPT.md:2938–2940, 3038). Das erste Urteil kommt
  im Code zwischen dem 3. und 6.10. (`monster_director.gd:93`).
- Im Keller patrouilliert er etwa dreimal am Tag je ~90 Spielminuten. Solange der Suchtrupp an der Kellertür wartet,
  patrouilliert er nicht (4.33, SPIELKONZEPT.md:2955–2961; Grundlage für M6a/M7).
- Die Leviathanmauer bleibt ab etwa Tag 15 nach Angriffen offen, um den 25. dauerhaft (7.4, SPIELKONZEPT.md:5397–5398;
  SK 2.8 Z. 783). Dahinter liegen der Dachbodenschlüssel und Josefs Bund (SK 2.7 Z. 720, 7.4 Z. 5409).
- Der Aufzug ist etwa ab dem 14. repariert (SK 2.8 Z. 803; HANDLUNG M11). Sein Halt in U2 ist nur über die
  Reparatur erreichbar (7.4, Z. 5359).
- Der Halloween-Schlüssel liegt im Koffer Rudolf Hains in den Fundsachen in U2 (7.4, Z. 5461). Ein Zeitfenster gibt
  es dafür nicht (A-01).
- Kernfiguren haben Schutz auf Zeit: Bruno bis zur Hauptsicherung, Edna bis um den 20., Marion bis Halloween, Mila bis
  zur Skizze (6.17, Z. 4691–4699). Laut 6.17 ist das „noch nicht umgesetzt“ (ZIM-120). Doris hat keinen Schutz (A-08).
- Die Puppe sitzt 2–5 Spielstunden vor dem Angriff vor der schwächsten bewohnten Tür, auch vor Zimmer 13; wer
  nachbessert, den verlässt sie (4.33 Z. 2970–2971, 5.5). Für Edna um den 20. setzt HANDLUNG K5 sie fest vor deren
  Tür (HANDLUNG.md:220). Diese Ausnahme von der Regel der schwächsten Tür steht nicht in 5.5. Nicht geprüft, ob 5.5
  sie kennt.
- Gäste gehen nicht in den Keller, außer bei Suchtrupp und Doris (4.33, Z. 2958–2961). Laut 7.4 Z. 5464 fahren Gäste
  nach U2 und plündern das Lager. Das widerspricht sich womöglich; das gehört zu Teil B bzw. E.
- Das Hotelregister setzt Kreuze ab 6 Uhr am Morgen nach einem Tod, und die Fotowand verwischt zugleich (SK 2.9 Z. 873,
  2.10 Z. 993). Das Gästebuch zeigt 1990 als erste Ernte (für den Code 1990, A-10). Nicht geprüft, ob die Seiten
  1987/1990 im Code so lesbar sind.
- Der Warnungszettel 1999 von M. B. liegt am Morgen nach der Siegerehrung unter der Tür von Zimmer 13 (SK 2.5 Z. 501–509).
- Das Kesselbuch liegt in Josefs Spind im Heizraum (UG) und ist ab M7 erreichbar (HANDLUNG.md:69). Laut SK 2.8 Z. 809
  fehlt es noch im Code. Davon hängt das Entlarven Marions (M13) ab.
- Die Mitternachtsglocke (7.8) schlägt in der Nacht zum 1.11. zwölfmal und löst das Ende aus (SK 2.7 Z. 667–668). Nicht
  geprüft, ob 7.8 sie als Auslöser beschreibt.
- Das Fest am Abend des 31. (5.9) ist der Sammelpunkt aller lebenden Gäste in der Lobby (SK 2.7 Z. 660).
- Die Hauptsicherung und der Sekretariatsschlüssel liegen im Spind des Hausmeisters. Bruno bricht ihn in der fünften
  Nacht auf (7.4, HANDLUNG K3). Gebaut ist nur der Zwischenort im Maschinenraum (SK 2.10 Z. 1004–1006).
- Der Generalschlüssel öffnet unbewohnte bzw. fremde Zimmer (6.19, Z. 4938). Dort steht er noch „von der Rezeption“
  (A-18).
- Milas Ziffer für das Zahlenschloss kommt aus ihrer Nachtpartie (6.14, ZIM-8), noch nicht gebaut (SK 2.10 Z. 1012).
- Das Ankunftsfoto 2026 hängt ab dem Morgen des 2.10. (SK 2.10 Z. 992; laut 2.10 Z. 962 noch nicht gebaut außer
  14 Rahmen und Fleck).
- Die Gedenktafel auf dem Friedhof führt Gustavs Namen (SK 2.9 Z. 917; 5.15).

## Nicht geprüft

- Kap. 4–9 nur gezielt per Grep. 5.5 (Puppe), 5.9 (Fest, Durchsagen), 6.14 (Herzensbitten) und 7.8 (Glocke) habe ich
  nicht gelesen, nur einzelne Zeilen gefunden.
- Ob der Code die Siegerehrung und Gustavs Tod wie in 2.5/2.6 beschrieben ablaufen lässt. Geprüft sind nur die Uhrzeiten
  (`door_contest.gd:68–70`: Tag 2, 20 Uhr, spätestens 22 Uhr – stimmt).
- Ohne Abweichung geprüft:
  - `Calendar.DAY_SECONDS` 1440, Start 15 Uhr;
  - Ausdauer 15 s, Erholung ~7 s (12 s × 0,6);
  - Augenhöhe 1,62 m;
  - Tasche 6 Fächer;
  - Wachschwelle 48–72 h;
  - Sprung 0,5 s je Stunde;
  - Kaffee 3 h / 12 h / 6 h, Tee 2 h ×1,3;
  - Batterie 300 s;
  - Gäste setzen sich (50 %, 60–180 s, 5 m);
  - Gäste wecken (+6/−5/−2/−8, 1–2 h, 20–40 s, 2 h gereizt);
  - drei harmlose Raubzüge.
- Raub-, Rausch- und Kochwerte (3.7, 3.8), Werfen (3.13) und das Hinsetzen des Spielers (3.1) habe ich nicht im Code
  nachgesehen.
- Ob 3.4 (Truhe als Versteck, „unter dem Bett schwerer zu entdecken?“) gebaut ist. Der Abschnitt hat keinen
  Status-Kopf.
- YouTrack nicht abgefragt (laut Auftrag). Ob A-01 bis A-05 schon als Ticket existieren, klärt die Zusammenführung.
- Die anderen Teile (`befunde/teil-b…e`) habe ich nicht gelesen, Doppelungen sind möglich, besonders bei A-06/A-07
  (Monster) und A-17 (Fest/5.9).
