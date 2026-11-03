# Befunde Teil D – Gäste und Haushalte

Geprüft: `SPIELKONZEPT.md` Kap. 6 (6.0–6.21) und `HAUSHALTE.md` vollständig, dazu gezielt `HANDLUNG.md` (K3–K8),
SK 2.9/2.10, 5.5, 7.7 sowie 13 Code-Stichproben in `scripts/guests/`, `scripts/monster/` und `scripts/minigames/`.
Die Zahlen der Haushalte stimmen durchweg: 67 = 54 + 13 in 39 Haushalten; Charaktere, Generationen und Geschlechter
in `HAUSHALTE.md` sind nachgezählt. Die meisten Befunde sind **veraltete Stellen**: Seit dem 30.10. (2.10, Ernte alle
drei Jahre) und den Fragerunden vom 3.11. sind HAUSHALTE.md und mehrere Kopf- und Altabsätze in Kap. 6 nicht
nachgezogen. Inhaltlich wiegen am schwersten die **späten Herzensbitten der Kernfiguren**, die zu ihrem Schutz
nicht passen, die **zentralen Gäste**, die laut Doku „nicht besetzt“, in der Handlung aber längst tragend sind, und
die Ausnahme **018**, die der eigenen Definition versiegelter Zimmer widerspricht.
*Während der Prüfung kam Commit 300594a (ZIM-120, Kernschutz für Marion, Liesel und Oskar) herein. Die Befunde sind
daran angepasst; ab SK 6.17 haben sich die Zeilennummern um +7 verschoben und gelten im Stand nach diesem Commit.*

## Befunde

### D-01 Brunos neue Herzensbitte ist erst erreichbar, wenn Bruno längst ungeschützt ist
- Art: Widerspruch
- Schwere: mittel
- Fundstellen: `SK 6.14` (SPIELKONZEPT.md:4574, 4606–4609), `SK 6.17` (SPIELKONZEPT.md:4694), `SK 2.8` (SPIELKONZEPT.md:798), `HANDLUNG.md:71`, `HANDLUNG.md:180`, `HANDLUNG.md:194`
- Befund: Die Herzensbitte soll „eher früh im Oktober“ kommen, damit sie bei 20 % Überleben nicht meist mit einem Kreuz endet (4574). Brunos neue Bitte (ZIM-8) ist aber der Silberstock im Büro der Direktion. Ins Büro kommt man nur mit Josefs Schlüsselbund aus der Jeansjacke des Kürbismanns, also nach dessen Erlösung (798, HANDLUNG M14 „ab Tag 15“). Brunos Schutz endet schon, sobald der Spieler die Hauptsicherung hat, etwa am 5. bis 10. (4694, HANDLUNG:180). Die Bitte bleibt also gut eine Woche offen, während Bruno als Mitwisser gezielt bedroht ist. In den meisten Durchläufen dürfte sie mit einem Kreuz enden.
- Vorschlag: Entweder verlängert man Brunos Schutz bis zur Übergabe des Stocks (eine weitere Marke in CoreRoles) oder man legt den Stock an einen Ort, der früher erreichbar ist (Sekretariat statt Büro). Alternativ bekommt Bruno eine frühe Herzensbitte, und der Stock wird eine spätere zweite Bitte.
- Entscheidung nötig: ja

### D-02 Zentrale Gäste gelten als „noch nicht besetzt“, tragen aber längst die Handlung
- Art: veraltet / Lücke
- Schwere: mittel
- Fundstellen: `SK 6.0` (SPIELKONZEPT.md:3871), `SK 6.14` (SPIELKONZEPT.md:4578, 4613), `SK 6.20` (SPIELKONZEPT.md:5112), `HAUSHALTE.md:11`, `HAUSHALTE.md:66–69`, `HAUSHALTE.md:76`, `HAUSHALTE.md:81`, `scripts/autoload/save_manager.gd:565`
- Befund: Kap. 6 sagt an drei Stellen, die 10–12 zentralen Gäste seien „noch zu besetzen“. Tatsächlich haben Gustav (2.6), Doris (2.9), Liesel (2.7, K7), Hugo (4.32), Oskar (2.10), Walter (2.10) und Gerda (seltene Bitte, 4.25) feste Rollen, und Liesel und Oskar sind seit ZIM-120 im Code geschützt. Die ★-Vorschläge in HAUSHALTE.md passen nicht dazu. **Doris** (H34) und **Oskar** (H39) haben keinen ★, obwohl sie einen eigenen Bogen haben. Umgekehrt haben H05 Sommer, H09 Berger und H14 Engel einen ★, aber keinen Faden in SK oder HANDLUNG. Folgen davon: Keine dieser Figuren hat eine eigene Herzensbitte (6.14 sieht das für zentrale Gäste vor), und der Tagebuchsatz nennt nur die drei Profil-Kernfiguren mit Namen (save_manager.gd:565).
- Vorschlag: Die zentralen Gäste offiziell besetzen, mit Liste in 6.0 und ★ in HAUSHALTE.md, mindestens Gustav, Doris, Liesel, Hugo, Oskar und Walter. Die übrigen ★ prüfen. Danach Herzensbitten und Tagebuchnamen für diese Ebene als Aufgabe festhalten.
- Entscheidung nötig: ja

### D-03 Marion ist Kernfigur, aber ohne eigenes Profil und ohne Inhalte der Kernfiguren
- Art: Lücke / Code-Abweichung
- Schwere: mittel
- Fundstellen: `SK 6.0` (SPIELKONZEPT.md:3870), `SK 6.14` (SPIELKONZEPT.md:4601–4612), `SK 6.18` (SPIELKONZEPT.md:4813–4815), `SK 6.12` (SPIELKONZEPT.md:4386–4391), `HAUSHALTE.md:10`, `HAUSHALTE.md:64`, `scripts/guests/guest_profiles.gd:19`/`76`/`133`, `tools/build_households.py:22`, `scripts/guests/guest.gd:399–400`
- Befund: 6.0 zählt vier Kernfiguren, und HAUSHALTE.md sagt „Die vier Kernfiguren haben ihr eigenes Profil“. Im Code haben nur Edna, Bruno und Mila ein Profil (`GuestProfiles.ALL`). Marion wird als normales Haushaltsmitglied mit **gewürfeltem Charakter** erzeugt, `is_core()` ist bei ihr falsch, laut build_households.py:22 „hat Marion noch keins“. Seit ZIM-120 ist sie zwar geschützt, aber alles, was an `is_core()` hängt, fehlt ihr: eigene Herzensbitte (6.14 nennt nur Edna, Bruno, Mila), eigene Zustandswünsche (6.18 Z. 4813 „Kernfiguren (Edna, Bruno, Mila)“), eigene Schreckreaktion (Tabelle 6.12), Spielstil bei Mäxchen, Schach und Darts, Namensnennung im Tagebuch und Start-Deko.
- Vorschlag: Marion ein Profil geben, mit festem Charakter (passend zu „sucht, was 1987 geschah“) und eigenen Sätzen. Die Listen „Kernfiguren“ in 6.12, 6.14 und 6.18 um sie ergänzen oder ausdrücklich ausnehmen, z. B. „Marions Herzensbitte ist ihr Auftrag (2.8)“.
- Entscheidung nötig: ja (Charakter, Herzensbitte)

### D-04 018 passt nicht zur Definition versiegelter Zimmer
- Art: Widerspruch
- Schwere: mittel
- Fundstellen: `SK 6.19 (7)` (SPIELKONZEPT.md:5000, 5003–5004, 5015, 5035), `SK 2.10` (SPIELKONZEPT.md:1024), `HANDLUNG.md:52`, `HAUSHALTE.md:125`
- Befund: Versiegelte Zimmer sind laut 6.19 (7) „seit Halloween 1987 niemand betreten“, haben alte Schlösser („1988 hat das Hotel alle Schlösser getauscht, nur diese Türen nicht“) und sind **optionale Secrets** (5035). 018 ist aber seit **2005** versiegelt (5015, 2.10). Nach dieser Regel hätte es ein neues Schloss, das der Generalschlüssel öffnet, und es ist kein optionales Secret: Der Schlüssel gehört zu M7 „fest“, dem ersten Abstieg in Akt I (HANDLUNG:52). In HAUSHALTE.md steht 018 nur als „abgeschlossen (bisher 18)“.
- Vorschlag: Aus 018 eine eigene Klasse „Sperrzimmer der Direktion (2005)“ machen. Dafür braucht es eine Regel, warum Brecheisen und Generalschlüssel nicht helfen, z. B. ein Schloss zusätzlich angebracht oder die Tür zugeschraubt. Den Weg „Wagnis“ dann einem echten optionalen Zimmer von 1987 geben oder ausdrücklich die Hauptgeschichte damit belegen.
- Entscheidung nötig: ja

### D-05 „Nachrücker“ widerspricht „Keine neuen Gäste“
- Art: Widerspruch
- Schwere: mittel
- Fundstellen: `SK 6.0` (SPIELKONZEPT.md:3863), `SK 6.19 (1)` (SPIELKONZEPT.md:4946–4947), `SK 6.0` (SPIELKONZEPT.md:3884)
- Befund: Am 21.10. wurde entschieden: keine neuen Gäste, Zimmer von Verschwundenen bleiben leer. In 6.19 (1) steht am 26.10. trotzdem: „Nachrücker ziehen nur in leere Zimmer.“ Das hat Folgen für die offene Balancefrage „ohne Nachschub“ (3884).
- Vorschlag: Den Satz in 6.19 streichen, sofern Nachrücker nicht bewusst wieder eingeführt werden sollen.
- Entscheidung nötig: nein (außer Nachrücker sind gewollt)

### D-06 Doris ist vor ihrer Frist nicht geschützt, ihr Bogen setzt aber voraus, dass sie lebt
- Art: Lücke
- Schwere: mittel
- Fundstellen: `SK 6.17` (SPIELKONZEPT.md:4700–4707), `SK 2.9` (SPIELKONZEPT.md:958), `HANDLUNG.md:49–54`, `scripts/guests/core_roles.gd:18`
- Befund: Doris trägt M5a bis M7b (Akt I/II, fest): Sie gibt den Auftrag und ist damit der Grund für den ersten Abstieg. Nach der Regel in 6.17 („Schutz nur, wenn es ohne die Figur keinen Weg weiter gibt“) bräuchte sie bis zum 4.10. 20 Uhr Schutz oder einen Ersatzweg. CoreRoles kennt sie nicht (nur H22, H26, H39). 2.9 Z. 958 lässt die Frage als Vorschlag offen („in der harmlosen Phase kann sie es nicht“). Unklar bleibt, ob die harmlose Phase auch für Lakengeist und Kürbismann gilt.
- Vorschlag: Doris in 6.17 aufnehmen (Schutz bis zur Brille oder bis zur Frist) oder festhalten, dass in den ersten Tagen keine Bedrohung tötet. Gehört auch zu Teil A (2.9).
- Entscheidung nötig: ja

### D-07 HAUSHALTE.md: Ideen von Walter, Oskar und den Schultes sind durch 2.10 überholt
- Art: veraltet
- Schwere: mittel
- Fundstellen: `HAUSHALTE.md:65`, `HAUSHALTE.md:81`, `HAUSHALTE.md:49`, `SK 2.10` (SPIELKONZEPT.md:1037, 1081–1089), `SK 2.2` (SPIELKONZEPT.md:188)
- Befund: H23 Walter steht als „Dauergast, kennt jeden Winkel – und schweigt“. 2.10 sagt ausdrücklich „ändert HAUSHALTE.md“: kein Dauergast, erst nach der Ernte 2023 hier, eine falsche Fährte. H39 Oskar „meint, er sei schon einmal hier gewesen“ verweist auf **2.2**, die am 25.10. verworfene Zeitschleife. Laut 2.10 hat er 2005 überlebt und erinnert sich. Bei H12 Schulte steht „jedes Jahr hier“. Wenn die Ernte alle drei Jahre kommt, müssten sie 2023 eine erlebt haben. Damit wären sie Überlebende, und Walter wäre nicht der Einzige, dem „Letztes Jahr gab's keinen“ auffällt (1088–1089).
- Vorschlag: Die Ideen von H23 und H39 nach 2.10 umschreiben. Für die Schultes entscheiden, ob „jedes Jahr“ bleibt (dann als Überlebende von 2023 und weitere Fährte) oder auf „zum ersten Mal“ geändert wird.
- Entscheidung nötig: ja (Schulte)

### D-08 HAUSHALTE.md: Kopf, Summen und Zimmerliste sind veraltet
- Art: veraltet
- Schwere: niedrig
- Fundstellen: `HAUSHALTE.md:3`, `HAUSHALTE.md:99`, `HAUSHALTE.md:145`, `HAUSHALTE.md:187`, `HAUSHALTE.md:190`, `SK 6.20` (SPIELKONZEPT.md:5068, 5087–5089, 5096), `SK 6.19 (7)` (SPIELKONZEPT.md:5013–5015)
- Befund: (a) Kopfzeile „Entwurf … noch nicht im Spiel“ (Z. 3). Laut 6.20 ist die Datei seit 24.10. umgesetzt, und laut Z. 20 liest das Spiel sie ein. (b) „Mit Sonderzimmern und Reserve rund 55“ (Z. 99) widerspricht 81 Zimmern. (c) 038 und 132 stehen als „unbewohnt, abgeschlossen“ (Z. 145, 187), obwohl sie seit ZIM-30 versiegelte Zimmer sind. 042 ist schon nachgetragen. (d) Damit stimmt auch „4 Sonderzimmer, 37 unbewohnt“ nicht mehr (Z. 190, SK 5087–5089). (e) Außenzugang: HAUSHALTE nennt 18 bewohnte plus Zimmer 13, SK 6.20 „17 davon bewohnt“ (5096). Nachgezählt sind es 18 Haushalte.
- Vorschlag: Kopf auf „im Spiel, Quelle für households.json“ ändern. Zeilen 99 und 190 neu zählen, 038/132/018 als „versiegelt (6.19 (7))“ eintragen. In SK 6.20 die Zimmerzahlen streichen und auf HAUSHALTE.md verweisen (siehe D-21).
- Entscheidung nötig: nein

### D-09 6.18 nennt eine Puppe, die der Spieler legt, als Ursache und als Klage, obwohl er das nicht kann
- Art: Widerspruch / veraltet
- Schwere: niedrig
- Fundstellen: `SK 6.18 (1)` (SPIELKONZEPT.md:4744), `SK 6.18 (2)` (SPIELKONZEPT.md:4762), `SK 6.18 (2)` (SPIELKONZEPT.md:4777–4778)
- Befund: In der Liste der Klagen steht „Puppe vor die Tür gelegt“, in der Liste der Todesursachen „Puppe vor seine Tür gelegt (5.5)“. Der gebaute Teil derselben Nummer stellt fest: „Legen kann der Spieler sie nicht (5.5)“.
- Vorschlag: Beide Aufzählungen bereinigen, z. B. die Puppe als Ursache ohne Schuld führen.
- Entscheidung nötig: nein

### D-10 Kinder und Puppe: „bemerken sie nicht“ widerspricht „tragen sie herum“
- Art: Widerspruch
- Schwere: niedrig
- Fundstellen: `SK 6.18 (3)` (SPIELKONZEPT.md:4820–4821), `SK 6.13` (SPIELKONZEPT.md:4511–4513), `SK 5.5` (SPIELKONZEPT.md:3180)
- Befund: Laut 6.18 bekommen Kinder keinen Puppen-Zustand, weil „sie die Puppe nicht bemerken (5.5)“. 6.13 und 5.5 sagen dagegen, Kinder sehen sie, tragen sie herum und erzählen von ihr.
- Vorschlag: Begründung ändern in „Kinder fürchten die Puppe nicht – sie ist ihr Spielzeug“.
- Entscheidung nötig: nein

### D-11 6.19 holt den Generalschlüssel noch „von der Rezeption“
- Art: veraltet
- Schwere: niedrig
- Fundstellen: `SK 6.19 (1)` (SPIELKONZEPT.md:4938), `SK 6.19` (SPIELKONZEPT.md:5053–5056), `SK 2.10` (SPIELKONZEPT.md:1007)
- Befund: In 6.19 (1) kommt man mit dem Generalschlüssel „von der Rezeption“ hinein. Seit ZIM-6 liegt er im Sekretariat in der Schublade mit Zahlenschloss, wie es die „Einzelheiten“ desselben Abschnitts richtig sagen.
- Vorschlag: In 4938 auf „aus dem Sekretariat (2.10)“ ändern.
- Entscheidung nötig: nein

### D-12 6.18: Statuszeile und „Zu klären“ überholt
- Art: veraltet
- Schwere: niedrig
- Fundstellen: `SK 6.18` (SPIELKONZEPT.md:4734), `SK 6.18` (SPIELKONZEPT.md:4901), `SK 6.18 (2)` (SPIELKONZEPT.md:4774–4776)
- Befund: Der Kopf sagt „Großteils noch nicht umgesetzt“, zählt dann aber (1), (2), (3), (5) und große Teile von (4) als gebaut auf. „Zu klären: wie lange eine Ursache frisch genug ist“ ist durch ZIM-160 beantwortet (4774–4776).
- Vorschlag: Kopf in „gebaut bis auf …“ umdrehen und die Restliste nennen (Telefon- und Ruf-Warnen, Themen nach Stufe, Kränkung bei Zuständen bis zum Morgen). „Zu klären“ streichen.
- Entscheidung nötig: nein

### D-13 Warnen: 6.18 (4) beschreibt Telefon und Ruf, gebaut ist nur das Gespräch
- Art: veraltet
- Schwere: niedrig
- Fundstellen: `SK 6.18 (4)` (SPIELKONZEPT.md:4826–4827), `SK 6.9` (SPIELKONZEPT.md:4017–4018)
- Befund: 6.18 (4) führt Warnen „im Gespräch oder am Telefon“ und „als Ruf an alle“ als geltende Regel. 6.9 vermerkt, dass nur das Warnen im Gespräch gebaut ist. Ob Telefon und Ruf noch gewollt sind (der Ruf „Holt Kürbisse!“ ist für den Kürbismann wichtig, 4.21), ist nirgends entschieden.
- Vorschlag: Klären, ob Telefon und Ruf noch gewollt sind. Wenn ja, als offen markieren; wenn nein, streichen. Mit 4.21 abgleichen (Teil B).
- Entscheidung nötig: ja

### D-14 Kernfiguren-Bitten der Geheimnis-Stufe: Mila, Edna und der Code-Stand
- Art: Lücke / Code-Abweichung
- Schwere: niedrig
- Fundstellen: `SK 6.14` (SPIELKONZEPT.md:4604–4605, 4610–4612), `SK 2.10` (SPIELKONZEPT.md:1009–1012), `SK 6.17` (SPIELKONZEPT.md:4699), `HANDLUNG.md:211–213`, `scripts/guests/requests.gd:94`, `scripts/guests/requests.gd:95`
- Befund: (a) Milas Nachtpartie liefert „eine Ziffer“ für das Zahlenschloss. Der Code 1990 lässt sich aber vollständig aus Dokumenten ermitteln (1009–1010), die Belohnung ist also überflüssig. Zugleich ist Mila nur bis zur Skizze um den 18. geschützt. Wann die Nachtpartie kommt, ist nicht festgelegt. (b) Ednas Dank im Code sagt „Mein **Mann** hat früher immer eine ins Fenster gestellt“ (requests.gd:94). Laut K5 und ZIM-8 geht es aber um ihren **Verlobten** Heinrich Brehm, der 1987 verschwand. (c) Im Code ist Brunos Bitte noch der Lieblingskürbis (requests.gd:95). Das ist so gewollt („nicht gebaut“), gehört aber in die Bauliste von ZIM-8.
- Vorschlag: Für Mila eine eigene Belohnung festlegen (z. B. der Hinweis, *welches* Jahr gemeint ist, statt einer Ziffer) und das Datum der Nachtpartie vor dem 18. setzen. Ednas Dankessatz beim Bau von ZIM-8 an Heinrich anpassen.
- Entscheidung nötig: ja (Milas Belohnung)

### D-15 Lakengeist: Losreißen in der Doku 5 % + 20 % × Mut, im Code 10 % + 20 % × Mut
- Art: Code-Abweichung
- Schwere: niedrig
- Fundstellen: `SK 6.12` (SPIELKONZEPT.md:4402), `scripts/monster/sheet_ghost.gd:74`
- Befund: Die Doku nennt 5 % + 20 % × Mut, der Code hat `GUEST_ESCAPE := Vector2(0.1, 0.2)` mit dem Kommentar „im Mittel etwa 2 von 10 (6.17)“. Der Code passt zu 6.17 (20 %), 6.12 wurde nicht nachgezogen.
- Vorschlag: 6.12 auf 10 % + 20 % × Mut ändern.
- Entscheidung nötig: nein

### D-16 „Guter Freund“: Die Doku nennt nur Mäxchen und Schach, der Code zählt jede Partie
- Art: Code-Abweichung (Doku veraltet)
- Schwere: niedrig
- Fundstellen: `SK 6.3` (SPIELKONZEPT.md:3922), `SK 6.16` (SPIELKONZEPT.md:4653), `scripts/minigames/dart_match.gd:483`, `scripts/minigames/bar_match.gd:253`, `scripts/minigames/truth_dare_match.gd:199`
- Befund: Laut 6.3 braucht es „3 gemeinsame Partien (Mäxchen oder Schach)“. Im Code zählen auch Darts, alle Barspiele und Wahrheit oder Pflicht. Wahrheit oder Pflicht hat keinen Einsatz und ist kurz, damit ist es der billigste Weg zu „guter Freund“. Ob die Freundschaften unter Gästen (6.16) die neuen Spiele mitzählen, ist nicht beschrieben.
- Vorschlag: 6.3 auf „3 gemeinsame Partien (alle Spiele in 6.10)“ ändern. Prüfen, ob schnelle Spiele ohne Einsatz voll zählen sollen.
- Entscheidung nötig: ja (Gewichtung)

### D-17 Herzensbitte der Kinder bietet Darts an, Kinder dürfen aber kein Darts
- Art: Code-Abweichung
- Schwere: niedrig
- Fundstellen: `scripts/guests/requests.gd:86`, `SK 6.10` (SPIELKONZEPT.md:4304)
- Befund: Die Notizbuchzeile lautet „Mit {name} spielen – Würfeln, Schach oder Darts“. Laut 6.10 spielen Kinder kein Darts („Pfeile sind nichts für Kinder“).
- Vorschlag: Text auf „Würfeln, Schach oder ein Barspiel“ ändern. Kinder dürfen nur zum Spaß spielen, das Trinkduell ist ausgeschlossen.
- Entscheidung nötig: nein

### D-18 Zuschauen: Vorteil oder „nur Stimmung“?
- Art: Widerspruch
- Schwere: niedrig
- Fundstellen: `SK 6.10` (SPIELKONZEPT.md:4218, 4241–4242, 4311, 4267)
- Befund: Bei Mäxchen verrät Zuschauen die Bluff-Ticks, bei Schach (30 s) und Darts (25 s) die Stärke. ZIM-73 legt fest: „Zuschauen ist nur Stimmung: … kein Vorteil, nichts gespeichert.“ Aus dem Text geht nicht hervor, dass das nur für Schocken und Armdrücken gilt.
- Vorschlag: In 4267 „bei den neuen Barspielen (Schocken, Armdrücken)“ ergänzen.
- Entscheidung nötig: nein

### D-19 Minispiel-Tabelle und Grundregeln in 6.10 sind veraltet
- Art: veraltet
- Schwere: niedrig
- Fundstellen: `SK 6.10` (SPIELKONZEPT.md:4104, 4187, 4192, 4198, 4205–4206, 4213), vgl. 4140–4146, 4227, 4248
- Befund: Das Schachbrett steht laut Grundregeln und Tabelle in „Bibliothek/Salon“, tatsächlich in der Lobby (4227). „Kniffel“ wurde durch Schocken ersetzt (4140). Bowling hat „Ort offen“, liegt aber in der Bar (4146). Der Spieleschrank steht als Idee „abschließbar in der Lobby“ (4213), gebaut ist er in der Bar und offen. Darts/Billard stehen in „Bar / Salon“. Gebautes, Vorgemerktes und Eingefrorenes stehen ununterscheidbar in einer Tabelle.
- Vorschlag: Die Tabelle um eine Spalte Stand ergänzen (gebaut / vorgemerkt / eingefroren) und die Orte nachziehen.
- Entscheidung nötig: nein

### D-20 Kleinere Altstellen in Kap. 6
- Art: veraltet
- Schwere: niedrig
- Fundstellen: `SK 6.11` (SPIELKONZEPT.md:4341), `SK 7.7` (SPIELKONZEPT.md:5596), `scripts/guests/hotel_cat.gd:47–55`; `SK 6.13` (SPIELKONZEPT.md:4429); `SK 6.20` (SPIELKONZEPT.md:5124–5125), `HAUSHALTE.md:61`; `SK 6.14→6.16` (SPIELKONZEPT.md:4650); `SK 6.4` (SPIELKONZEPT.md:3960)
- Befund: (a) „Drei Katzen gehören zum Hotel“. Im Katzenraum leben seit 7.7 vier weitere (Luna, Fussel, Tiger, Mausi), insgesamt also sieben. (b) 6.13: „Das Geheimnis (2.3) gibt es noch nicht – deshalb keine Funde in engen Ecken“ ist inzwischen falsch, das Geheimnis ist weitgehend entschieden. Es fehlt nur der Bau der Kinderfunde. (c) Ednas Geburtsname „geb. Kessler“ steht in HAUSHALTE.md und im Code (hotel_register.gd:24), aber nicht bei den Nachnamen der Kernfiguren in 6.20. (d) Abschnitt 6.15 fehlt, die Nummerierung springt von 6.14 auf 6.16. (e) „Ich brauche Batterien“ (6.4) ist ein alter Wunsch ohne Gegenstück in 6.14.
- Vorschlag: Alles in einem Doku-Durchgang nachziehen. 6.15 als „entfallen“ markieren, damit Verweise stabil bleiben.
- Entscheidung nötig: nein

### D-21 Doppelpflege SK 6.20 ↔ HAUSHALTE.md
- Art: Optimierung (Doku-Struktur)
- Schwere: niedrig
- Fundstellen: `SK 6.20` (SPIELKONZEPT.md:5072–5099), `HAUSHALTE.md:83–99`, `HAUSHALTE.md:190`
- Befund: Haushaltstabelle, Zimmerbedarf, Zimmerzahlen und Außenzugänge stehen in beiden Dateien. Sie laufen bereits auseinander (D-08 e). HAUSHALTE.md ist die maschinenlesbare Quelle.
- Vorschlag: In SK 6.20 nur die Regeln behalten (Kinder nie allein, Tür je Haushalt, Anspruch × 1,35, Liste vs. Generator) und für Zahlen auf HAUSHALTE.md verweisen. HAUSHALTE.md bekommt eine Spalte „Faden/Rolle“ mit Verweis auf SK oder HANDLUNG, statt die Geschichte in der Spalte „Idee“ nachzuerzählen.
- Entscheidung nötig: nein

### D-22 Bitten-Wildwuchs: sechs Arten von Bitten mit eigenen Regeln
- Art: Optimierung (Umfang / Lesbarkeit)
- Schwere: mittel
- Fundstellen: `SK 6.14` (SPIELKONZEPT.md:4573–4616, 4640–4648), `SK 6.12` (SPIELKONZEPT.md:4420–4422), `SK 6.18 (3)` (SPIELKONZEPT.md:4809–4818), `SK 6.16` (SPIELKONZEPT.md:4670–4673)
- Befund: Neben Herzensbitte und kleinen Bitten (Budget, Frist bis Tagesende, −2) gibt es seltene Bitten (ohne Frist), den Trauerwunsch, Zustandswünsche (+8, doppelt, verfallen still), das Vermitteln im Streit und die Bitte um ein Glas abends (jeder zweite Erwachsene). Jede Art hat eigene Fristen, Budgets und Belohnungen, über drei Abschnitte verteilt. Der Richtwert „eine am Tag im ganzen Hotel, kein Lieferdienst“ (4583) gilt nur für die kleinen Bitten. Mit Trauer (alle Freunde eines Toten), Zuständen und Glas-Bitten kann das Notizbuch nach einem Todesfall schnell volllaufen. Die Ausbau-Tabelle in 6.14 nennt außerdem Fristen „bis zu einem Ereignis“, falsche Aufträge, Nachsehen, Suchen und Bitten per Telefon oder Zettel (4621–4622, 4640, 4643), ohne Stand.
- Vorschlag: In 6.14 eine Übersicht anlegen (Art · Auslöser · Frist · Budget · Belohnung · Malus · Stand). Eine gemeinsame Obergrenze offener Bitten erwägen. Die Ausbau-Tabelle als „Ideen, nicht geplant“ kennzeichnen oder ausdünnen.
- Entscheidung nötig: ja (Obergrenze)

### D-23 Geldkurve: Spiele um Einsätze dürften den Handel schnell entwerten
- Art: Optimierung (Balance)
- Schwere: mittel
- Fundstellen: `SK 6.4` (SPIELKONZEPT.md:3952–3959), `SK 6.10` (SPIELKONZEPT.md:4219, 4235)
- Befund: Die Übersicht rechnet nach den ersten Tagen mit „≈ 3–8 je Tag von selbst“. Einsätze von +3/+8 je Sieg bei 2–6 Partien am Tag bringen aber 6–48 je Tag. Die Schach-KI rechnet 1–3 Halbzüge voraus und patzt 5–45 % der Züge. Ein geübter Spieler gewinnt fast immer, und Gegner gibt es reichlich, weil jeder Gast sein eigenes Geld hat (~700–1000 zusammen). Damit ist der Geldmangel praktisch aufgehoben, sobald man Schach oder Darts beherrscht. Zum Beispiel kosten Entschuldigen (5/15) und Bestechen (3) dann nichts mehr.
- Vorschlag: Je Gast und Tag nur eine Partie mit Einsatz, oder Gäste, die gegen dich verloren haben, wollen nur noch zum Spaß spielen (außer stolze Revanche). Danach im Probespiel nachmessen.
- Entscheidung nötig: ja

### D-24 Lesbarkeit: Fortschritt zu „guter Freund“ und Budgets bleiben unsichtbar
- Art: Optimierung (Spielerlebnis)
- Schwere: niedrig
- Fundstellen: `SK 6.3` (SPIELKONZEPT.md:3920–3923), `SK 6.18 (5)` (SPIELKONZEPT.md:4884–4887), `scripts/guests/guest.gd:677`
- Befund: Die Stufe sieht man im Hinweis („Mit X sprechen [E] (befreundet)“). Nicht sichtbar ist dagegen, warum ein Gast bei „befreundet“ stehen bleibt (Partien, Geschenke ab Preis 5, Gegenstand von ihm) und dass das Beziehungsbudget erschöpft ist (danach 15 %). Ohne Rückmeldung wirkt beides wie ein Fehler.
- Vorschlag: Eine Zeile im Notizbuch je Gast mit Stufe und fehlenden Taten, oder eine Sprechblase, wenn das Budget erschöpft ist („Wir haben heute schon viel geredet.“).
- Entscheidung nötig: nein

### D-25 Story: Gäste-Ideen in HAUSHALTE.md ohne Mechanik und Kinder als Hinweisträger
- Art: Optimierung (Story)
- Schwere: niedrig
- Fundstellen: `HAUSHALTE.md:30`, `HAUSHALTE.md:41`, `HAUSHALTE.md:72`, `HAUSHALTE.md:73`, `HAUSHALTE.md:69`, `SK 6.13` (SPIELKONZEPT.md:4537–4538), `SK 6.20` (SPIELKONZEPT.md:5108–5109)
- Befund: Mehrere Ideen sind gute Fäden, aber ohne Regel. Lindner „glaubt den Kindern kein Wort – bis es zu spät ist“, obwohl Kinder nie Opfer werden. Was ist dann „zu spät“? Malte „verliert er Till, bricht er zusammen“. Paula „schreibt über das Hotel“, Moritz' Freunde „kamen nie an“, Hugo „kauft Dokumente“. Laut 6.20 bekommen übrige Gäste keinen eigenen Faden. Gleichzeitig stehen Kinderfunde in engen Ecken als Hinweisweg (6.13) ohne Inhalt da.
- Vorschlag: Die passenden Ideen den zentralen Gästen aus D-02 zuordnen. Zum Beispiel Paula als Sammlerin von Gerüchten (Zeitungsartikel im Lager, Teil der Fährte zu 2005), Lindner-Kinder als Finder eines Warnungszettels, den der Vater wegwirft. Wie stark Hugos Dokumentenhandel mit 4.32 zusammenhängt, bitte in Teil B/C gegenprüfen. Die übrigen Ideen als Stimmung kennzeichnen.
- Entscheidung nötig: ja

## Annahmen über andere Systeme
- Monster, Lakengeist und Kürbismann töten **nie Kinder**. Das Monster übersieht Kinder und Katzen und geht an ihren Verstecken vorbei (SK 6.13, Z. 4435–4437, 4450–4452; 6.11, Z. 4348–4349).
- **20 % Überleben** gelten für alle drei Bedrohungen, beim Urteil endet es mit Überleben (SK 6.17, Z. 4683–4689; 5.5, Z. 3173–3175).
- Kernschutz ist an **Marken im Spielstand** gebunden (Hauptsicherung ZIM-4, Bedrohung ZIM-5, Skizze ZIM-8), die bisher niemand setzt (SK 6.17, Z. 4702–4707). Ungeprüft: ob 4.33 (Urteil) und 5.13 (Heimsuchung) dieselbe Abfrage nutzen.
- Doris kann vor dem 4.10. 20 Uhr nicht sterben, weil die ersten Angriffe harmlos sind (SK 2.9, Z. 958, Vorschlag). Ungeprüft für Lakengeist und Kürbismann.
- **Schlafende und Versteckte sehen nichts**, auch keine Leichen und kein Blut (SK 6.12, Z. 4381).
- Der Lakengeist behandelt Gäste wie den Spieler, mit eigenem Zähler je Gast. Wache Partner im Doppelzimmer halten ihn fern (SK 6.12, Z. 4397–4407; 6.20, Z. 5091–5092; 4.18, 7.7).
- Anspruch des Monsters je Tür × (1 + 0,35 je weiteren Erwachsenen), Kinder zählen nicht (SK 6.20, Z. 5120–5121). Das muss in 4.8/5.10/4.33 so verwendet werden.
- Bei einer Flackerwelle gehen Gäste heim oder ins nächste Versteck, Partien brechen ab, Einsätze bleiben liegen (SK 6.6, Z. 3978; 6.10, Z. 4127, 4223).
- Das Monster hört jedes Gespräch über sich mit (4.7), auch Erzählen und Gerüchte (SK 6.5, Z. 3966; 6.9, Z. 4052; 6.12, Z. 4395).
- Kurz vor einem Angriff springt die Puppe zur schwächsten Tür, danach können Kinder sie nicht mehr bewegen (SK 6.13, Z. 4511–4513; 5.5, Z. 3180–3182).
- **Spieltag = 24 min**, Budgets füllen sich am Morgen um 6 Uhr, Nachtruhe nach 4.18 (SK 6.4, Z. 3942; 6.18, Z. 4863; 6.13, Z. 4458–4460).
- Wache halten verlängert im Zeitsprung den Vorlauf (3.6) (SK 6.18 (4), Z. 4830–4838).
- Telefon (4.14): Plaudern am Telefon zählt zu Gesprächsbudget und Beziehungsbudget, Abweisende legen auf (SK 6.18 (5), Z. 4882–4887).
- Notizbuch (3.10) führt Aufgaben mit Frist, Kreuz bei Tod und gestrichene, verfallene Wünsche. Lügen merkt es sich bewusst nicht (SK 6.14, Z. 4618–4620; 6.9, Z. 4069).
- Der Generalschlüssel liegt im Sekretariat und öffnet alle Zimmertüren außer bei vorgeschobenem Riegel und außer den versiegelten Zimmern. Josefs Bund öffnet zusätzlich Sekretariat und Büro (SK 6.19, Z. 5053–5056; `scripts/world/director_office.gd:9`).
- Der Schlüssel zu 042 liegt im Krähennest und kommt als Geschenk bei hoher Gunst oder per Wurf ins Nest (SK 6.19 (7), Z. 5012; HANDLUNG.md:214–217; 4.25).
- Kürbissuppe lässt sich nicht tragen, daher gibt es gebratenen Kürbis oder Tee für Verletzte (SK 6.18 (3), Z. 4810–4811; 3.8).
- Lärmwerte nach 4.15: Klopfen 8 m, Aufbrechen 20 m, Wortwechsel im Streit 10 m, Ausrufen eines Verstecks 12 m, Kinder rennen 10 m und schreien 20 m, Katzenweinen 16 m (vom Monster ignoriert) (SK 6.19, 6.16, 6.18, 6.13, 6.11).
- Das Hotelregister zeigt Nachnamen und Geburtsnamen (Marion „geb. Ahrend“, Edna „geb. Kessler“), Zimmer 13 steht nicht darin (SK 6.20, Z. 5100–5102; `scripts/world/hotel_register.gd:24`).
- Mit dem Schlüssel kommen alle Überlebenden hinaus; Marion und Liesel bleiben freiwillig (HAUSHALTE.md:64, 68; HANDLUNG.md:198, 253; 2.7/2.8).
- Edna stellt ihre Kerze ins „Fenster zum Garten“ (SK 6.14, Z. 4604). Zimmer 003 liegt aber an der Südseite (EG Ost) ohne Außenzugang (HAUSHALTE.md:111). Ungeprüft, ob sein Fenster zum Garten zeigt.
- Doris wohnt in 033 „gegenüber von 020“. Laut 2.9 (Z. 956) ist ungeklärt, ob das im Plan wirklich so liegt.
- Tagebuch (8.9/8.10) nennt nur Kernfiguren mit Profil beim Namen (`scripts/autoload/save_manager.gd:565`).

## Nicht geprüft
- YouTrack: nicht abgefragt, wie vereinbart. Ob D-01, D-14, D-22 und D-23 schon als Tickets existieren, prüft die Ausgangssitzung.
- Plan und Karten (`map*.aseprite`, `assets/maps/*.json`): Lage der Zimmer, Fenster von 003, „gegenüber“ von 020/033 und Nachbarschaft für Neid (6,5 m).
- Code-Stichproben nur zu: Kernprofilen, Kernschutz (`is_core`, CoreRoles), Überleben (`wounds.gd`, `sheet_ghost.gd`), Beziehungsstufen und Drift (`social.gd`), Partien für „guter Freund“, Herausforderungen, Gesprächsbudget (`talk.gd`), Herzensbitten (`requests.gd`), Einlass (`room_access.gd`), Katzen. **Nicht** geprüft: Lügen und Haltungen (6.9), Streiche und Eier (6.13), Streit (`quarrels.gd`), Neid, Trauer und Gedenkort (`mourning.gd`), Einbruch und Tagebuch (`break_in.gd`), Gästemodelle.
- `TECHNIK.md` Abschnitt 6 und `GEGENSTAENDE.md` nur per Grep für einzelne Gegenstände (Lichterkette, Silberstock).
- Im Spiel ist nichts geprüft, auch kein Rauchtest.
- Spielbalance (D-23) nur rechnerisch aus den Zahlen der Doku, ohne Messung.
