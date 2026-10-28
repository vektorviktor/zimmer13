# Zimmer 13 – Offene Punkte

Alles, was noch nicht fertig oder nicht entschieden ist, an einer Stelle. Ausführlich steht es in den verlinkten
Kapiteln; hier nur Stichpunkte und Verweis. Was keinen ausführlicheren Ort hat, ist knapp beschrieben (vor allem die
Ideen in 6, früher IDEEN.md).

**Kürzel:** SK = [SPIELKONZEPT.md](SPIELKONZEPT.md) · HA = [HANDLUNG.md](HANDLUNG.md) (M = Meilenstein,
K = Kandidat) · GE = [GEGENSTAENDE.md](GEGENSTAENDE.md) · TE = [TECHNIK.md](TECHNIK.md)

**Pflege:** Entschiedenes wandert mit Datum ins Spielkonzept, Gebautes fliegt hier raus. Neue Ideen kommen nach 6.

Stand: 2026-10-27

---

## 1. Hauptgeschichte: was dem Durchlauf noch fehlt

Reihenfolge wie im Durchlauf (HA 2, GE „Was die Hauptgeschichte braucht“). Alles entschieden, nichts davon gebaut
(gebaut 27.10.: die Mitteilung „abgereist“ am Brett).

| Stück | Verweis | Stand |
|---|---|---|
| Doris' Suche: Bitte, Suchtrupp an der Kellertür, Brille an der Leviathanmauer, Abschied/Brief | SK 2.9 · HA M5a–M7b, K8 | nicht gebaut; Mauer malt der Nutzer neu |
| Aufzug reparieren: Schaltschlüssel einstecken, Ersatzsicherung, Bremse, erste Fahrt nach „T“ | SK 7.4 · HA M9–M11, K3 | Aufzug fährt, Reparatur als Sperre fehlt; Schaltschlüssel und die drei Aufgaben im Notizbuch gibt es (Durchstreichen: `CaretakerBook.fixed`) |
| **U2** (Lager, Fundsachen-Koffer, alter Heizkeller, Deko des Monsters) | SK 7.4, 7.10 · HA M11, M17 | **Plan steht aus** |
| **Keller-Ordnung** (7.4, 2026-10-27): Vorhängeschlösser Ost/West, Monster bricht Ost auf, Westschlüssel im Keller, zugemauerte Treppen, Heizraum als Attrappe (moderner Kessel, heiße Rohre nach unten, Spind), Leviathanmauer statt Gitter, Monster nur Minuten draußen, U2-Knopf/Hugo | SK 7.4 · HA K2, M11, M14, M17 | nicht gebaut; der Plan (Schlösser, Mauer, Treppen) malt der Nutzer |
| Zimmer 18 als Zimmer des Gastes von 2003, UV-Hinweise 13/018, Jahresfoto 2003 | SK 7.4, 5.14 | nicht gebaut |
| Puppe: Herkunft (Marion), Brandspuren unter UV, Marion erstarrt vor ihr | SK 5.5 | nicht gebaut |
| Kesselbuch, Marion entlarven, Marions Auftrag | SK 2.8 · HA M12–M13, M16a, K4 | Marion gibt es im Spiel noch nicht |
| Kürbismann aufhalten und erlösen (Leviathanmauer, Dachbodenschlüssel, Ritual, Belohnungen) | SK 4.21 · HA M14, K7 · GE | nur der Dachboden mit Platzhalterkopf |
| Seine Sachen, Büro der Direktion, Vertrag | SK 2.8 · HA M15a–b · GE | nicht gebaut |
| Schlüssel zum Haupteingang holen | SK 2.1, 2.7 · HA M18, K6 · GE | Tür gebaut, Schlüssel und Fundort fehlen |
| Ritual in der Halloween-Nacht | SK 2.8 · HA M19a | nicht gebaut |
| Die drei Enden (mit/ohne Schlüssel, erlöst/nicht erlöst) als Zwischensequenzen | SK 2.7 · HA M21–M21b | nicht gebaut |
| Autosave bei Fortschritt: Aufzug, Erlösung, Fluchtweg rufen `SaveManager.on_progress` (Schlüssel zu Zimmer 18 und Dachboden schon; Zimmer 18 mit Schaltschlüssel beim Zusammenführen nachziehen) | SK 8.6, 8.10 · TE 7 | Aufruf gebaut, die Ereignisse fehlen |

## 2. Konzeptlücken (Entscheidung fehlt)

### Geschichte
- **Fundort des Ausgangsschlüssels** und wie die Gäste helfen – SK 2.7, HA K6, M18.
- **Wer hat die Ersatzsicherung** (Kandidat Bruno) – HA K3.
- **Edna als Mitwisserin** (Bedrohung um den 20.10.) noch Kandidat; **Lücke 16.–22. Oktober** braucht evtl. einen
  zweiten festen Moment – HA K5, HA 4.
- **Büro der Direktion:** Lage, zweiter Weg hinein ohne erlösten Kürbismann – HA 4, SK 2.8, 6.19.
- **Hotelregister** (gebaut 28.10.): Ednas voller Geburtsname (steht als „geb. K…“); wer 2003 in 13 und 018 wohnte
  (beide Zimmer bleiben in den alten Jahren leer); ob Zimmer 13 – der Spieler – darin steht (bisher nicht, die Figur
  hat keinen Namen); die Namen früherer Jahre sind gewürfelt (fester Seed) – sollen sie zu den Koffern im Lager und den
  Warnungszetteln passen? – SK 2.3, 2.7, 7.4.
- **Mila Hellwig** ohne Rolle im Geheimnis (Vorschlag Skizzen) – HA 4; allgemein Bezug der Kernfiguren-Bitten zum
  Geheimnis – SK 6.14.
- **Lore 1987:** Warnungszettel vor dem Kesselbrand; was das Ding unter dem Hotel vorher war – HA 4, SK 10 (Frage 4).
- **Enden:** Epilog im nächsten Jahr? eigenes Vampir-Ende? Sequenz steuerbar? Darstellung von Ende 3 bei ab 16 –
  SK 2.7 „Zu den Enden noch offen“.
- **Mit „Vorschlag“ markierte Punkte** in SK 2.9, 4.22, 4.32, 4.33, 5.19, 7.4 (Texte im Notizbuch des Hausmeisters) und HA (Daten, Inhalte, Wege) sind noch
  zu bestätigen. In 4.32 gebaut wie vorgeschlagen: Hugos Sätze, Druck an der Wand (zwischen Aushangbrett und
  Wandlampe statt an der vollen Fotowand); Liesel benennt ihn, wenn Hugo tot ist. Neu dazu: Kinder zählen nicht als
  Zeugen, „überlebt“ = 2 min danach noch am Leben, Hugo wartet ¾ Stunde am Tisch auf den Spieler.

### Systeme
- **Grundsatzfragen** SK 10: Bemerkt-Auslöser (3a), Truhen abschließbar/eigene Truhe (3h), Umfang (8), Koop (9),
  Sprache (10).
- **Leviathan-Modi:** gilt die längere Frist auch beim Raubzug? – SK 4.33. Tuning (Anforderungen um Tag 14 und 21,
  Bilanz 15–20 Opfer, Gerede-/Lärm-Boni, langsamere Dreistigkeit gegen Deko-Abschreckung) bisher nur headless
  geprüft – SK 4.33, 4.9.
- **Kürbismann aufhalten:** wie lang „sehr kurz“, Zeige-Entfernung, welche Kürbisse zählen – SK 4.21.
- **Vampir:** Biss, Verwandlung, „schwach“, hereinbitten – fast alles Vorschlag – SK 4.22.
- **Versiegelte Zimmer:** welche drei neben 042, Schlüssel, Gegenstände – SK 6.19 (7).
- **Krähen:** welches Dachfenster fürs Dachnest (hängt am Dach) – SK 4.25.
- **Salz:** zwei Gäste mit „kreisenden Händen“ – welche, wann, fest oder zufällig; streuen ältere Gäste selbst? – SK 5.13.
- **Aufträge:** wie viele gleichzeitig, Ablehnen ohne Beziehungsverlust – SK 6.14. Streit unter Gästen – SK 6.16.
- **Handel:** woher kommt Geld – SK 6.4.
- **Bar/Küche:** weitere Getränke; macht Kochen Lärm, Zutaten aus dem Kühlraum – SK 3.7, 3.8.
- **Balkon:** Geländer übersteigen, in den Garten springen? – SK 7.7.
- **UV:** zeigt es weggewischte Spuren an Zimmer 13? – SK 4.16.
- **Katzenraum:** vertagt (Kürbismann kommt hinein) – SK 4.20, 7.7.
- **Kommoden:** Gäste durchsuchen/befüllen, Kommoden in Zimmern – SK 3.5.
- **Kesselraum-Käfig:** wie man hineinkommt – SK 7.4.
- **Trauer der Gäste um Freunde** – SK 6.12.
- **Aufzug:** hält er im Dachgeschoss (heute nicht)? Gäste und Monster im Aufzug? – SK 7.10 „Zu klären“, 7.4.
- **Dachform** offen (eigene Idee des Nutzers), Dachgeschoss mit flacher Zwischenlösung – SK 7.10.

## 3. Entschieden, noch nicht gebaut (Systeme)

**Bedrohungen**
- Name Leviathan, Reste: Liesels Abendgebet gegen den Leviathan, Marion geht hinaus, wenn sie den Namen hört (beides
  gibt es im Spiel noch nicht) – SK 4.32. Gebaut 27.10.: Sichtung, Hugos Szene mit Doré-Druck, Satzwechsel.
- Vier Modi des Leviathan, Reste: kein Modus an Balltagen (Bälle gibt es noch nicht, 5.19); keine Kellerrunde,
  solange der Suchtrupp nach Gustav läuft (2.9, nicht gebaut) – SK 4.33. Gebaut 27.10.: Plan der Modi, Urteil, Snack,
  Raubzug (die ersten drei harmlos), Anforderung, Kellerrunde, Geräusche ohne Körper, Schutz gegen Fehlverhalten
  (Erreichbarkeit, Ziel festnageln, Aufzug-Haltestelle, Dachboden-Szene, `--navcheck=tueren`).
- **Drei Bedrohungen** je Ebene, gleiche Sicht für den Kürbismann – SK 4.20.
- Vampir als vierte Bedrohung (Fledermäuse ohne Biss gebaut, draußen und auf dem Dachboden) – SK 4.22.
- Krähen-Erweiterung: Ruf, Futtertisch, zwei Nester, Ring – SK 4.25 · GE (Brotkrumen; Kürbiskerne fallen seit 27.10.
  beim Schnitzen ab).
- Kesselkatze: Marion erkennt sie, beim Ritual – SK 4.26.

**Gäste und Sozialsystem**
- **Sozialsystem verknüpft** (Gerüchte als Kanal, Tod mit Ursache, Wünsche, Wache, Tagesbudgets, Geschenke, Vergebung,
  Neid) – SK 6.18 (großteils offen). Daran hängen: Schock+Trauer als ein Wert – SK 6.8; Gerüchte im Notizbuch – SK 3.10.
- Zimmerzugang, Reste: Einbruch sehr wütender Gäste bei 13, Schlüssel stehlen, Zweitschlüssel, Reparatur-Tagesbudget,
  Badtür-Riegel – SK 6.19.
- Telefon: Gäste rufen sich an, Panik-Anrufe, Telefonzentrale – SK 4.14.
- Aufträge, Reste: zentrale Gäste, Verstecken/Apfeltauchen als „Spielen“, Kuscheltier, Bitten am Telefon/als Zettel –
  SK 6.14. Antworten mit Tonlage – SK 6.9.
- Kinder: Funde in engen Ecken (am Geheimnis), Eier-Streich – SK 6.13.
- Gäste gehen mit Grund ins UG („Leg Kohle nach“, „Hol die Wäsche“) – SK 7.9, 7.10.

**Spieler**
- **Schlaf & Müdigkeit:** Gebaut 27.10.: Wachzeit, Stufen, ausgeschlafen/übermüdet, fremde Betten, Sprung am Tag,
  Gäste wecken; Werte (16/24/36 h, 48–72 h, ausgeschlafen 4 min, Wecken +6/−5/−8) nur headless geprüft – im Spiel
  tunen. Wache eines Freundes in Zimmer 13 (6.18) fehlt weiter. Feuer als Weckgrund, sobald es Feuer gibt.
- **Ersatzbirnen-Lager:** „Ausstattung: Ersatzbirnen“ ist in keinem Plan gemalt (z. B. Lager im EG) – bis dahin holen
  Gäste Ersatz nur durch Klauen oder meiden das Zimmer (SK 7.3).
- Taschenlampe: alles gebaut; UV-Spuren an 13 offen (s. 2).

**Deko und Halloween**
- Kerzen brennen ab (gebaut 27.10.), Reste: Werte (Brenndauer, Stummel, Anteil mit Feuer, Pflege-Wahrscheinlichkeit)
  nur headless geprüft – im Spiel tunen; „Feuer?“ ist nur ein Satz, keine Bitte im Notizbuch – SK 5.12.
- Knappheit Stufe 2 (Schutzkreis = Lichtschein, sichtbare Abweisung) und 3 (Gäste schmücken mit Plan, klauen) – SK 5.10.
- Puppe: die „vorgemerkten“ Punkte, u. a. Jury beim Großen Schmücken – SK 5.5.
- **Maskenball**, Reste: sechs Masken, Verstecke und Zettel, der Ball, Verleihen, Rückkehr an den Haken, Trophäen;
  eigene Maske (Ruth Behrens) – SK 5.19 · GE. Dazu die Masken-Erfolge – SK 8.11.
- Halloween im Hotel: Gruselgeschichten-Abend, alte Bräuche, Durchsagen, **Gruppenfoto** mit leeren Plätzen – SK 5.9 · HA M19.
- Minispiele: Kürbis-Schnitz-Duell; Schach-Dame als Suche, Mühle, Turnier; Darts-Kreidetafel – SK 6.10.

**Welt**
- Wetter, Rest: Wind an den Kerzen (Flamme geht im Garten bisher nach Regen aus; wie der Wind wirken soll, ist nicht
  entschieden) – SK 7.8.
- UG: Maschinen- und Müllraum fertig ausbauen – SK 7.9. Der gebaute Kohlekessel mit Feuerschein und Schutzwirkung
  muss dem modernen Attrappenkessel weichen; Kesselkatze (Ziel: heiße Rohre), Leviathan-Sichtung (an der Mauer statt
  hinter dem Kessel), Monster-Versteck (`spawn_points[0]`, `cellar_center()` → U2) und die Aufzugsanzeige („T“ → „U2“)
  ziehen nach – SK 7.4, 4.26, 4.32.
- Flecken auf den Tapeten – SK 7.2.

**Menüs und Speichern**
- **Speicherregel 8.10** gebaut (2026-10-28). Offen: zentrale Gäste für den Tagebuchsatz besetzen
  (`SaveManager._named_in_diary`, SK 6.0); weitere Sperrbereiche (Personaltrakt, Büro der Direktion) und U2 in
  `NEW_AREAS`, sobald gebaut – SK 8.10, 2.3.
- Lautstärke „Stimmen“ (es gibt keine Sprachausgabe) – SK 8 (Kopf), 8.4. Ausbau-Ideen – SK 8.9.

## 4. Gebäudeplan, Modelle, Ton

Plan nur der Nutzer (`map*.aseprite`).
- **U2-Plan** fehlt – SK 7.10.
- **Leviathanmauer #9c5a5a** im Heizraum: neu malen, Legende und Einbau fehlen – SK 2.9, 7.4.
- Offen aus 7.4: Ort des Westschlüssels, Kommentar zu den zugemauerten Treppen, Hugos Text zum U2-Knopf, UV-Texte von
  13/018, Hinweise auf dem Jahresfoto 2003, Deko des Monsters in U2.
- Ausstattung im Plan fehlt für Rattenkönig, Fotowand, Puppenhaus, Apfelbottich (laufen auf festen Ausweichplätzen) – TE 1573 ff.
- Kommode in Zimmer 022 (Streichhölzer) – SK 5.12 · TE (`CONTENT["022"]`).
- Echte Modelle und Klänge für die übrigen Platzhalter, u. a. weißer Kürbis wie der orange (Meshy + Farbatlas),
  Kopf des Kürbismanns, Splash-Klang – SK 11 (12), TE 1, GE.
- Kieseltextur für die Kieswege – SK 7.10.
- Eigener PS1-Modus – ganz am Ende – SK 9.2.

## 5. Technik und Pflege

- **Segfault beim Beenden** headless (etwa jeder dritte Lauf, Exit 139), Ursache unbekannt – TE (Bekannt, offen).
- Balancing insgesamt – SK 11 (13).

## 6. Ideen (unentschieden, früher IDEEN.md)

Je Idee: kurz, wozu sie passt, offene Fragen.

**I1 – Lakengeist in der Dusche** → entschieden und gebaut (SK 4.24).

**I2 – Die Kesselkatze als Mechanik** (2026-10-25). Gebaut als Führerin zu Kessel und UV-Schrift (SK 4.26). Der
Nutzer möchte sie später als Mechanik besprechen: Geisterkatze, Augen im Dunkeln.
Offen: Wann und wo zeigt sie sich (nur unten, nur nachts)? Hilft oder warnt sie, und wie unterscheidet sie sich von
den drei Hotelkatzen (SK 6.11)?

**I3 – Der Rattenkönig im Glas** (2026-10-25, **ruht**, bis der Nutzer ihn anspricht). Sieben Ratten mit verknoteten
Schwänzen in trübem Spiritus, Glas auf einem Wandbord im Müllraum; reine Stimmung neben den Ratten (SK 4.25).
- Stand: `scripts/world/rat_king.gd` (`RatKing.place` in `main.gd`); [E] zeigt den Zettel und legt einen
  Notizbuch-Eintrag an („Müllraum“), nicht gespeichert. Kein Modell (Grundkörper), kein Platz im Plan (`FALLBACK`
  an der Nordwand), kein Debug-Parameter, kein Rauchtest, im Spiel nicht angesehen.
- Zettel frei erfunden („Gefunden im Kohlenkeller, Winter 1962. Sieben Stück. Nicht wegwerfen. – A. R.“); wer
  „A. R.“ ist und was 1962 war, steht nirgends.
- Offen: Bleibt er? Wenn ja: Modell, Platz im Plan, Zettel mit Bezug zur Geschichte oder neutral?

**I4 – Das Foto vom Leviathan** (2026-10-25). Ein Gast fotografiert ihn während eines Angriffs; danach ist die
Bedrohung erstmals greifbar – ein Bild statt Gerücht. Zweiter Schritt nach der Benennung durch Hugo Stein (SK 4.32);
passt zur Fotowand (SK 5.14) und zur Frage, ob ein Foto einen Vampir verrät (SK 4.22).
Offen: Welcher Gast (Paula Jansen H30, die über das Hotel schreibt, oder das Paar Engel H14, das den Spuk beweisen
will)? Fest oder bei einem beliebigen Angriff? Hängt es an der Fotowand? Was ändert sich bei den Gästen (Angst,
Skeptiker geben auf, Magda Seidel H36 sieht den Trick der Direktion bestätigt)?

**I5 – Die verbotenen Masken: Regel und Herkunft** (2026-10-25). Die acht Masken sind entschieden (SK 5.19); offen
ist, **warum** sie verboten sind und **wie** sie in Umlauf kommen. Darf dem Bau des Maskenballs nicht im Weg stehen.
- Wer oder was verbietet sie? Teil des Abkommens von 1987 (SK 2.3) – etwa Masken vom ersten Ball, nach denen das
  Hotel die heutigen Dinge geformt hat? Erfährt man die Regel je (Dokument, Edna, Hugo)?
- Nur feste Verstecke (Vorschläge in 5.19) oder tauchen sie auch auf – morgens vor 13, bei einem Gast, als
  Ballgewinn? Finden Gäste selbst eine und tragen sie ahnungslos?
- Kann Hugo Stein (H27) sie erkennen, kaufen, verkaufen?

**I6 – Der Ring im Dachnest** (2026-10-25). Ein Gast ließ seinen Ring draußen liegen, eine Krähe holte ihn ins Nest
vor einem Dachfenster, mit ausgestrecktem Arm erreichbar (SK 4.25, Erweiterung). Gastauftrag „Wiederfinden“ (SK 6.14).
Offen: Wessen Ring (Ehering, Erbstück, Bezug zu 1987)? Fragt der Gast, oder findet man ihn zuerst und sucht den
Besitzer? Welches Dachfenster (hängt am Dach)? Lohn?

**I7 – Ein eigenes Grab für jeden Toten** (2026-10-26). Bisher bekommen nur Tote mit Leiche ein Grab; Opfer des
Leviathan stehen nur auf der Gedenktafel mit einer Kerze je Name (SK 5.15). Dort wirkt ein abgelegtes Fundstück
(Gustavs Brille, SK 2.9) zwischen vielen Grablichtern zufällig. Ein eigener Platz je Toten – auch leeres Grab oder
Gedenkstein für Vermisste – erlaubt Ablegen von Brille, Hausschuh, Briefen.
Offen: Leeres Grab oder Gedenkstein? Reichen die 43 Grabplätze? Bringt Ablegen etwas (Gedenken, Beziehung bei
Freunden) oder nur Stimmung? Legen Gäste selbst etwas ab?

## 7. Leichte Ausbaustufen (direkt ableitbar)

Nur was sich fast ohne neue Entscheidung aus Bestehendem ergibt.
- **Kochen macht Lärm:** eine Entscheidung, dann ein `Game.noise`-Aufruf am Herd (SK 3.8, 4.15).
