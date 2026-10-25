# Spielkonzept – Arbeitstitel: „Zimmer 13“

> Status: Grobkonzept · Stand: 2026-10-11
> Engine: **Godot 4.7** · 3D-Assets: **Blender (lokal)**

---

**Inhalt**

- [1. Kurzbeschreibung (Pitch)](#1-kurzbeschreibung-pitch)
- [2. Genre & Stimmung](#2-genre--stimmung)
  - [2.1 Zeit & Dramaturgie: Vom 1. Oktober bis Halloween (entschieden 2026-10-10)](#21-zeit--dramaturgie-vom-1-oktober-bis-halloween-entschieden-2026-10-10)
  - [2.2 Scheitern als Zeitschleife – mit eigenen Zetteln (vorgemerkt 2026-10-11)](#22-scheitern-als-zeitschleife--mit-eigenen-zetteln-vorgemerkt-2026-10-11)
  - [2.3 Fortschritt & Geheimnis (vorgemerkt 2026-10-11)](#23-fortschritt--geheimnis-vorgemerkt-2026-10-11)
  - [2.4 Tagesuhr & Tagesablauf (entschieden 2026-10-21, umgesetzt 2026-10-23)](#24-tagesuhr--tagesablauf-entschieden-2026-10-21-umgesetzt-2026-10-23)
  - [2.5 Der Anfang: Türschmuck-Wettbewerb (entschieden und umgesetzt 2026-10-23)](#25-der-anfang-türschmuck-wettbewerb-entschieden-und-umgesetzt-2026-10-23)
- [3. Core Gameplay Loop](#3-core-gameplay-loop)
  - [3.1 Spieler-Aktionen (Grundumfang)](#31-spieler-aktionen-grundumfang)
  - [3.2 Kein verstecktes Inventar – Hände und Tasche](#32-kein-verstecktes-inventar--hände-und-tasche)
  - [3.3 Truhen](#33-truhen)
  - [3.4 Verstecken (inspiriert von Roblox *Doors*)](#34-verstecken-inspiriert-von-roblox-doors)
  - [3.5 Kommoden im Flur (entschieden und umgesetzt 2026-10-14)](#35-kommoden-im-flur-entschieden-und-umgesetzt-2026-10-14)
  - [3.6 Schlaf & Müdigkeit (vorgemerkt 2026-10-19)](#36-schlaf--müdigkeit-vorgemerkt-2026-10-19)
  - [3.7 Trinken an der Bar (entschieden 2026-10-19)](#37-trinken-an-der-bar-entschieden-2026-10-19)
  - [3.8 Kochen in der Küche (entschieden 2026-10-21)](#38-kochen-in-der-küche-entschieden-2026-10-21)
  - [3.9 Spielerfigur und Charaktererstellung (entschieden und umgesetzt 2026-10-23)](#39-spielerfigur-und-charaktererstellung-entschieden-und-umgesetzt-2026-10-23)
  - [3.10 Notizbuch und Tagebuch (entschieden 2026-10-23, Stufe 1 umgesetzt 2026-10-23)](#310-notizbuch-und-tagebuch-entschieden-2026-10-23-stufe-1-umgesetzt-2026-10-23)
  - [3.11 Kaffee (entschieden und umgesetzt 2026-10-24)](#311-kaffee-entschieden-und-umgesetzt-2026-10-24)
  - [3.12 Tee (entschieden und umgesetzt 2026-10-24)](#312-tee-entschieden-und-umgesetzt-2026-10-24)
  - [3.13 Werfen (Entwurf 2026-10-25, noch nicht gebaut)](#313-werfen-entwurf-2026-10-25-noch-nicht-gebaut)
- [4. Das Monster](#4-das-monster)
  - [4.1 Grundprinzip](#41-grundprinzip)
  - [4.2 Ankündigung („Manifestation“)](#42-ankündigung-manifestation)
  - [4.3 Verhalten](#43-verhalten)
  - [4.4 Licht & Dunkelheit](#44-licht--dunkelheit)
  - [4.5 Wahrnehmung: „Es weiß, dass du es gesehen hast“](#45-wahrnehmung-es-weiß-dass-du-es-gesehen-hast)
  - [4.6 Wenn das Monster dich erwischt](#46-wenn-das-monster-dich-erwischt)
  - [4.7 Das Monster lauscht](#47-das-monster-lauscht)
  - [4.8 Es wird mit der Zeit anspruchsvoller](#48-es-wird-mit-der-zeit-anspruchsvoller)
  - [4.9 Versteckte Werte: Dreistigkeit & Neugier](#49-versteckte-werte-dreistigkeit--neugier)
  - [4.10 Sättigung](#410-sättigung)
  - [4.11 Die Aufmerksamkeit des Monsters lenken](#411-die-aufmerksamkeit-des-monsters-lenken)
  - [4.12 Sehen & Jagen (entschieden 2026-10-10)](#412-sehen--jagen-entschieden-2026-10-10)
  - [4.13 Ständige Präsenz (entschieden 2026-10-10)](#413-ständige-präsenz-entschieden-2026-10-10)
  - [4.14 Zimmertelefone (vorgemerkt 2026-10-11)](#414-zimmertelefone-vorgemerkt-2026-10-11)
  - [4.15 Lärm & Sichtbarkeit – ein gemeinsames System (entschieden 2026-10-11)](#415-lärm--sichtbarkeit--ein-gemeinsames-system-entschieden-2026-10-11)
  - [4.16 Taschenlampe & UV-Licht (entschieden 2026-10-11)](#416-taschenlampe--uv-licht-entschieden-2026-10-11)
  - [4.17 Angriffsabsicht & Flacker-Signal (entschieden 2026-10-17)](#417-angriffsabsicht--flacker-signal-entschieden-2026-10-17)
  - [4.18 Der Lakengeist am Fenster (entschieden 2026-10-17)](#418-der-lakengeist-am-fenster-entschieden-2026-10-17)
  - [4.19 Der Kürbismann (entschieden und umgesetzt 2026-10-20)](#419-der-kürbismann-entschieden-und-umgesetzt-2026-10-20)
  - [4.20 Drei Bedrohungen, ein Hotel (entschieden 2026-10-21)](#420-drei-bedrohungen-ein-hotel-entschieden-2026-10-21)
  - [4.21 Den Kürbismann aufhalten – und erlösen (entschieden 2026-10-21)](#421-den-kürbismann-aufhalten--und-erlösen-entschieden-2026-10-21)
  - [4.22 Fledermäuse und der Vampir (vorgemerkt 2026-10-23)](#422-fledermäuse-und-der-vampir-vorgemerkt-2026-10-23)
  - [4.23 Spinnen (entschieden und umgesetzt 2026-10-23)](#423-spinnen-entschieden-und-umgesetzt-2026-10-23)
- [5. Halloween-Dekoration](#5-halloween-dekoration)
  - [5.1 Funktion](#51-funktion)
  - [5.2 Platzierung](#52-platzierung)
  - [5.3 Ideen für Deko-Typen (vorläufig)](#53-ideen-für-deko-typen-vorläufig)
  - [5.4 Deko selbst herstellen](#54-deko-selbst-herstellen)
  - [5.5 Die Puppe – „Halloween-Jury“ (entschieden 2026-10-21, neu gefasst 2026-10-22)](#55-die-puppe--halloween-jury-entschieden-2026-10-21-neu-gefasst-2026-10-22)
  - [5.8 Kürbissorten (entschieden und umgesetzt 2026-10-20)](#58-kürbissorten-entschieden-und-umgesetzt-2026-10-20)
  - [5.9 Halloween im Hotel (vorgemerkt 2026-10-20)](#59-halloween-im-hotel-vorgemerkt-2026-10-20)
  - [5.10 Knappheit, Wert & Verfall (entschieden 2026-10-21)](#510-knappheit-wert--verfall-entschieden-2026-10-21)
  - [5.11 Feuer: Deko kann brennen (entschieden 2026-10-22)](#511-feuer-deko-kann-brennen-entschieden-2026-10-22)
- [6. Die anderen Gäste (NPCs)](#6-die-anderen-gäste-npcs)
  - [6.0 Gäste im Prototyp](#60-gäste-im-prototyp)
  - [6.1 Rolle](#61-rolle)
  - [6.2 Beziehungssystem](#62-beziehungssystem)
  - [6.3 Konsequenzen – neun Stufen (entschieden und umgesetzt 2026-10-18)](#63-konsequenzen--neun-stufen-entschieden-und-umgesetzt-2026-10-18)
  - [6.4 Handel](#64-handel)
  - [6.5 Panik](#65-panik)
  - [6.6 Gäste-KI & Pathfinding](#66-gäste-ki--pathfinding)
  - [6.7 Gäste können sterben](#67-gäste-können-sterben)
  - [6.8 Schock & Trauer (Ideen – noch zu diskutieren)](#68-schock--trauer-ideen--noch-zu-diskutieren)
  - [6.9 Dialog: Anlässe, Fragen, Erzählen, Lügen, Gedächtnis (entschieden 2026-10-24)](#69-dialog-anlässe-fragen-erzählen-lügen-gedächtnis-entschieden-2026-10-24)
  - [6.10 Minispiele mit Gästen](#610-minispiele-mit-gästen)
  - [6.11 Hotelkatzen (vorgemerkt 2026-10-14, umgesetzt 2026-10-17)](#611-hotelkatzen-vorgemerkt-2026-10-14-umgesetzt-2026-10-17)
  - [6.12 Schreck & Erlebnisse (entschieden und umgesetzt 2026-10-18)](#612-schreck--erlebnisse-entschieden-und-umgesetzt-2026-10-18)
  - [6.13 Kinder (entschieden und umgesetzt 2026-10-19)](#613-kinder-entschieden-und-umgesetzt-2026-10-19)
  - [6.14 Aufträge von Gästen (vorgemerkt 2026-10-20)](#614-aufträge-von-gästen-vorgemerkt-2026-10-20)
  - [6.16 Freundschaften unter Gästen (entschieden 2026-10-21)](#616-freundschaften-unter-gästen-entschieden-2026-10-21)
  - [6.17 Überlebende & Verletzungen (entschieden 2026-10-21)](#617-überlebende--verletzungen-entschieden-2026-10-21)
  - [6.18 Das Sozialsystem verknüpft (entschieden 2026-10-21)](#618-das-sozialsystem-verknüpft-entschieden-2026-10-21)
  - [6.19 Zimmer gehören den Gästen: Klopfen, Einlass, Aufbrechen (entschieden 2026-10-24)](#619-zimmer-gehören-den-gästen-klopfen-einlass-aufbrechen-entschieden-2026-10-24)
  - [6.20 Haushalte (entschieden 2026-10-24)](#620-haushalte-entschieden-2026-10-24)
- [7. Spielwelt: Das Hotel](#7-spielwelt-das-hotel)
  - [7.1 Die Lobby – Gemeinschaftsraum](#71-die-lobby--gemeinschaftsraum)
  - [7.2 Maße & Architektur](#72-maße--architektur)
  - [7.3 Fenster, Vorhänge & Wandlampen](#73-fenster-vorhänge--wandlampen)
  - [7.4 Fahrstuhl & Tiefkeller (vorgemerkt 2026-10-11)](#74-fahrstuhl--tiefkeller-vorgemerkt-2026-10-11)
  - [7.5 Neuer Grundriss aus dem Gebäudeplan (entschieden 2026-10-18)](#75-neuer-grundriss-aus-dem-gebäudeplan-entschieden-2026-10-18)
  - [7.6 Partikeleffekte (entschieden und umgesetzt 2026-10-20)](#76-partikeleffekte-entschieden-und-umgesetzt-2026-10-20)
  - [7.7 Obergeschoss: Zimmer, Balkone, Katzenraum, Bibliothek (vorgemerkt und umgesetzt 2026-10-20)](#77-obergeschoss-zimmer-balkone-katzenraum-bibliothek-vorgemerkt-und-umgesetzt-2026-10-20)
  - [7.8 Wetter & Geräusche von draußen (vorgemerkt 2026-10-20)](#78-wetter--geräusche-von-draußen-vorgemerkt-2026-10-20)
  - [7.9 Untergeschoss (entschieden und umgesetzt 2026-10-20)](#79-untergeschoss-entschieden-und-umgesetzt-2026-10-20)
  - [7.10 Kleineres Hotel, mehr Ebenen (entschieden 2026-10-21)](#710-kleineres-hotel-mehr-ebenen-entschieden-2026-10-21)
- [8. Menüs, Speichern & Laden](#8-menüs-speichern--laden)
  - [8.1 Entscheidungen im Überblick](#81-entscheidungen-im-überblick)
  - [8.2 Titelbildschirm (Hauptmenü)](#82-titelbildschirm-hauptmenü)
  - [8.3 Spielmenü (Esc)](#83-spielmenü-esc)
  - [8.4 Einstellungen](#84-einstellungen)
  - [8.5 Speichern am Tagebuch](#85-speichern-am-tagebuch)
  - [8.6 Autosave](#86-autosave)
  - [8.7 Laden & Tod](#87-laden--tod)
  - [8.8 Was gespeichert wird](#88-was-gespeichert-wird)
  - [8.9 Ausbau-Ideen (später)](#89-ausbau-ideen-später)
  - [8.10 Speicherregel geschärft (entschieden 2026-10-21)](#810-speicherregel-geschärft-entschieden-2026-10-21)
- [9. Technische Umsetzung (grob)](#9-technische-umsetzung-grob)
  - [9.1 Godot 4.7](#91-godot-47)
  - [9.2 Blender (lokal)](#92-blender-lokal)
- [10. Offene Fragen für die Detaildiskussion](#10-offene-fragen-für-die-detaildiskussion)
- [11. Nächste Schritte](#11-nächste-schritte)

---

## 1. Kurzbeschreibung (Pitch)

Ein 3D-First-Person-Horrorspiel. Der Spieler ist in einem alten Hotel eingeschlossen. Irgendwo in den Fluren lauert ein Monster, das man fast nie richtig sieht – es bleibt diffus im Hintergrund, bis es sich plötzlich zeigt. Schutz bieten nur Halloween-Dekorationen, die man vor seiner Zimmertür oder im Flur platziert. Die Deko ist knapp: Man bekommt sie über andere Hotelgäste – durch Freundschaft, Handel … oder Diebstahl. Doch wer andere bestiehlt, wird selbst bestohlen.

**Kernfrage für den Spieler:** *Vertraue ich den anderen Gästen – oder nehme ich mir, was ich zum Überleben brauche?*

**Spielziel:** Dem Horrorhotel **entkommen**. Die Zeit läuft **durchgängig** (keine Level), gezählt in **Ingame-Tagen vom 1. Oktober bis Halloween** – draußen ist immer Nacht (siehe 2.1). Grafik: **realistischer Look** – der PS1-Look bleibt als Umschalter und wird am Ende als eigener Modus nachoptimiert (9.2, Entscheidung 2026-10-25).

---

## 2. Genre & Stimmung

- **Genre:** First-Person-Horror / Survival mit sozialer Simulation
- **Tonalität:** Unterschwelliger, atmosphärischer Horror statt Dauer-Jumpscares. Halloween-Ästhetik (Kürbisse, Kerzen, Girlanden) als warmer Kontrast zur kalten, bedrohlichen Hotelkulisse.
- **Inspirationen (Richtung):** Andeutungs-Horror à la „Alien: Isolation“ (Bedrohung präsent, aber selten sichtbar), Retro-Hotel-Atmosphäre à la „The Shining“, soziale Dynamik ähnlich „Animal Crossing“-Beziehungen – nur mit Paranoia.

### 2.1 Zeit & Dramaturgie: Vom 1. Oktober bis Halloween (entschieden 2026-10-10)
> Im Prototyp umgesetzt (2026-10-11): Kalender, friedlicher Anfang, erster Angriff bei einer Feier am 3./4. Oktober (spätestens am 5.), zwei harmlose Angriffe. Noch offen: Schlüssel an Halloween und das Scheitern.
> **Mit der Tagesuhr (2.4, umgesetzt 2026-10-23):** erster Angriff auf einer Feier **am Abend des 2. Oktober**
> (spätestens am 3. um 20 Uhr), harmlos bleibt es etwa **anderthalb Spieltage** (neun Aufbrüche).
> **Mit dem Türschmuck-Wettbewerb (2.5, entschieden 2026-10-23):** Der erste Angriff ist die **Siegerehrung am 2. Oktober
> um 20 Uhr in der Lobby** – sie wartet auf den Spieler, spätestens um 22 Uhr. Die spontane Feier und der Ausweichtermin
> am 3. entfallen.

- **Kalender:** Das Spiel beginnt am **1. Oktober**. Die Zeit läuft durchgängig und wird in **Ingame-Tagen** gezählt. Draußen ist **immer Nacht** – der „Tag“ ist nur die Zähleinheit, kein Wechsel von Hell und Dunkel.
- ~~**Tageslänge: ca. 5 Minuten Echtzeit** → 31 Tage ≈ 2,5 Stunden bis Halloween.~~ **Seit 2026-10-21: 24 Minuten
  Echtzeit** (24 Stunden = 24 Minuten) → 31 Tage ≈ 12½ Stunden, mit Uhrzeit und Tagesablauf (2.4). Zentral einstellbar (Tuning-Wert, `Calendar.DAY_SECONDS`).
- **Datum sichtbar:** Abreißkalender an der Wand von Zimmer 13, im Spielmenü und kurz eingeblendet, wenn ein neuer Tag beginnt. Spielstände zeigen das Ingame-Datum.
- **Der friedliche Anfang:** Zu Beginn wirkt alles wie ein **gemütliches Hotel-Party-Spiel** – Gäste kennenlernen, Deko basteln, Kürbisse ziehen, Würfeln, Feiern. Keine Vorwarnung, kein Rauschen, nichts Bedrohliches. Auch Einführungstext und Gäste deuten nichts an. Der Spieler soll glauben, es sei ein friedliches Halloween-Spiel. Den Faden dafür gibt seit 2026-10-23 der **Türschmuck-Wettbewerb** (2.5).
- **Der erste Angriff bricht das – ~~am 3. oder 4. Oktober~~ am Abend des 2. Oktober (seit 2.4) ~~während einer Feier in der Lobby~~ bei der Siegerehrung des Wettbewerbs in der Lobby (seit 2.5):** Alle stehen um die Puppe, sie steigt auf und löst sich in Rauch auf, dann geht das Licht aus, Stille, Rauschen. Ab jetzt ist es nicht mehr friedlich.
- **Die ersten ein bis zwei Angriffe sind noch nicht tödlich:** Das Monster holt **niemanden**. Erwischt es den Spieler, **steht es direkt vor ihm, starrt ihn an und verschwindet im Flackern** – man sieht es zum ersten Mal und weiß: Es ist real. Erst danach wird es gefährlich.
- **Halloween (31. Oktober):** In einem Zimmer **taucht ein Schlüssel auf** – der Weg hinaus. Es ist **sehr schwer**, an ihn heranzukommen.

**Ideen zum Schlüssel (Auswahl offen)**
- Er liegt **im Keller, im Versteck des Monsters** – und es ist gerade dort.
- Er liegt in **Zimmer 18**, das seit Spielbeginn verschlossen ist; dafür braucht man vorher Hilfe.
- Er erscheint in einem **zufälligen Zimmer** – und das Monster weiß es auch.
- **Man braucht die Gäste:** einer lenkt ab, einer hält Wache – belohnt gute Beziehungen.

- Er liegt im **Lager im Tiefkeller**, in einem Koffer früherer Gäste – erreichbar nur mit dem reparierten Fahrstuhl (7.4).

**Ideen für das Scheitern (Auswahl offen)**
- **Zeitschleife:** Nach Halloween beginnt alles wieder am 1. Oktober – nur schlimmer. Ausgearbeitet in 2.2.
- **Das Hotel behält einen:** schlechtes Ende.

### 2.2 Scheitern als Zeitschleife – mit eigenen Zetteln (vorgemerkt 2026-10-11)
> Favorit für das Scheitern. Noch nicht umgesetzt.

**Grundidee:** Wer an Halloween nicht entkommt, wacht wieder am **1. Oktober in Zimmer 13** auf. Kurz vor dem Ende darf man **Zettel für den nächsten Durchgang** schreiben – und wird so selbst zu einem der „früheren Gäste“, deren Warnungszettel man die ganze Zeit gefunden hat (4.13).

**Ablauf**
- **Auslöser:** Die Nacht des 31. Oktober endet, ohne dass man das Hotel verlassen hat. (Tod bleibt wie bisher: letzten Spielstand laden, 8.)
- **Die letzte Seite:** In der letzten Stunde vor dem Ende bietet das **Tagebuch in Zimmer 13** eine zusätzliche Seite an: *„Für den, der nach mir kommt.“* Man schreibt **bis zu drei Zettel** (kurzer Freitext, ca. 140 Zeichen; alternativ Bausteine wie „Traue nicht …“, „Der Schlüssel liegt …“). Wer es nicht rechtzeitig zum Tagebuch schafft, hinterlässt nichts.
- **Neuer Durchgang:** Die eigenen Zettel liegen **zwischen den alten Warnungszetteln** – unter Matratzen, im Keller, hinter Bildern –, ohne Jahreszahl und mit „Zimmer 13“ unterschrieben. Man findet sie nicht sofort wieder; sie tauchen nach und nach auf, wie die anderen auch.
- **„Nur schlimmer“:** Das Monster startet mit etwas höherer Dreistigkeit (4.9), die Ruhephasen sind von Anfang an kürzer, und der friedliche Anfang (2.1) ist um einen Tag kürzer. Pro Durchgang ein wenig, damit eine Schleife kein Strafmarathon wird.
- **Das Hotel erinnert sich:** Kratzspuren und Kerzenstummel der letzten Schleife sind noch da. Einzelne Gäste haben ein **Déjà-vu** („Kennen wir uns?“, „Du warst doch letztes Jahr schon hier …“). Wer im letzten Durchgang gestorben ist, sagt manchmal einen Satz, den er damals gesagt hat.

**Warum das gut passt**
- Verbindet drei offene Fäden auf einmal: **Scheitern** (2.1), **Warnungszettel** (4.13) und **Story** (offene Frage 4).
- Der Spieler gibt sein Wissen selbst weiter, statt dass das Spiel es ihm erklärt.
- **Twist-Option:** Einer der festen Warnungszettel von 1987–2019 ist in derselben Handschrift geschrieben und mit „Zimmer 13“ unterschrieben. Man versteht erst nach der ersten Schleife, was das bedeutet.

**Zu klären**
- Was bleibt erhalten? Vorschlag: nur Zettel, Spuren und Déjà-vu – **kein** Geld, keine Gegenstände, der Fahrstuhl (7.4) ist wieder kaputt.
- ~~Gilt die Schleife pro Spielstand-Slot (Vorschlag: ja, Zähler und Zettel im Spielstand) oder slotübergreifend?~~
  Übergreifend für alle Stände eines Durchgangs: Setzt die Schleife ein, werden die alten zu „Erinnerungen“, nicht mehr
  ladbar (8.10, entschieden 2026-10-21).
- Gibt es nach mehreren Schleifen ein Ende, oder endet es nur durch Flucht?

### 2.3 Fortschritt & Geheimnis (vorgemerkt 2026-10-11)
> Noch nicht umgesetzt. Gibt dem Spiel eine Richtung: Bisher überlebt man, kommt aber nirgendwohin. Verbindet Story (offene Frage 4), Zeitschleife (2.2), Warnungszettel (4.13), Fahrstuhl & Tiefkeller (7.4) und die Gäste (6).

**Grundidee:** Nicht alle Bereiche des Hotels sind von Anfang an erreichbar. Einige sind verschlossen und müssen **verdient** werden. Hinter ihnen liegt nach und nach ein **großes Geheimnis**: warum man hier ist, was das Monster ist, was das Hotel mit den früheren Gästen zu tun hat. Man erfährt es aus **Dokumenten** und von **Mitwissern** – Gästen, die mehr wissen, als sie sagen.

**Fortschritt: Bereiche verdienen statt finden**
- **Offen bleibt der Alltag:** Erdgeschoss, Zimmerflure, Lobby, Bar, Garten, Keller. Gesperrt werden nur die **Geheimnis-Orte** – damit das Spiel eine Sandbox mit Gästen bleibt und kein Schlüssel-Parcours wird. Die Zimmer der Gäste sind ihr eigener Raum: hinein nur mit Einlass, Schlüssel oder Gewalt (6.19).
- **Möglichst mehrere Wege hinein.** Was man aufbringt, um einen Bereich zu öffnen:

| Art | Beispiel | baut auf |
|-----|----------|----------|
| **Vertrauen** | Ein Gast gibt den Schlüssel erst als Freund – oder man klaut ihn und riskiert Zeugen | Beziehungen, Diebstahl (6.2) |
| **Wissen** | Die Kombination steht in einem Brief, der Code ist ein Datum aus einem Zeitungsausschnitt | Dokumente, Karte (3.2) |
| **Wagnis** | Offen, aber dunkel und nah am Monster; man braucht Licht in der Hand – das verrät einen | Licht, Lärm & Sichtbarkeit (4.4, 4.15) |
| **Zeit** | Manche Türen öffnen sich erst an bestimmten Tagen, andere schließen sich wieder (z. B. wenn ein Gast stirbt) | Kalender (2.1) |

- **Erstes Beispiel steht schon:** Die Fahrstuhl-Reparatur (7.4) verlangt alle drei – Wagnis (Keller, Zimmer 18), Vertrauen (Hauptsicherung beim Gast), Lärm (Bremse).
- **Kandidaten für Sperrbereiche:** Zimmer 18 · Personaltrakt bzw. Büro der Direktion · Tiefkeller (7.4) · Dachboden oder Turm.

**Das Geheimnis: Das Abkommen und der Heizer (entschieden 2026-10-11)**
- **Das Abkommen:** Die Gründerfamilie des Hotels hat **1987** einen Handel mit dem geschlossen, was unter dem Hotel lebt. Jedes Jahr gibt es eine **Halloween-Woche mit Gästen**, und es darf sich nehmen, wen es will. Dafür besteht das Hotel weiter, und die Familie lebt. Die Gäste werden eingeladen, ohne es zu wissen. Das Hotel ist ab dem 1. Oktober verschlossen.
- **Der Heizer – das erste Opfer:** Halloween 1987 kam es im **Tiefkeller** zum Unglück (Kesselbrand). Der Heizer blieb beim Feuer, um andere hinauszubringen. Das Personal schloss die Tür hinter ihm ab – so wurde das Abkommen besiegelt. **Er ist zu dem geworden, was es jetzt verlangt.** Das Personal hält ihn seitdem mit Gästen ruhig und hinter dem Gitter (7.4). Bevor er starb, schrieb er den **ältesten Warnungszettel** (4.13); sein **Kesselbuch** liegt im Heizkeller (7.4). **Er hieß Josef Ahrend** (entschieden 2026-10-24) – derselbe Name in Kesselbuch, Personalakte und auf dem ältesten Warnungszettel.
- **Was das erklärt:**
  - **Deko schützt**, weil sie einmal Teil des Rituals war: Wer schmückt, gilt als *Gastgeber*, nicht als *Gabe*. Und weil sie ihn an das Fest erinnert, das er retten wollte – in geschmückten Bereichen zögert er.
  - **Die Puppe** (5.5) ist die Jury des Abkommens: Sie bestimmt vor jedem Angriff, wer am wenigsten schmückt und
    damit „angeboten“ wird – vor dessen Tür liegt sie, und dort stirbt jemand.
  - **Kerzen gehen aus**, wenn er vorbeikommt: das Feuer, das ihn getötet hat.
  - **Das Hotel behält jeden, der dort stirbt** (entschieden 2026-10-21, 4.20): der Heizer als das Monster, der
    Rezeptionist von 1987 als Kürbismann (4.19), die Verschwundenen als Lakengeist (4.18).
  - **Das Gitter wird lockerer** (7.4, 4.8): Das Abkommen hält jedes Jahr schlechter.
  - **Der Schlüssel an Halloween** (2.1) öffnet die Tür für **genau einen**. Das Hotel behält immer einen. Fliehen heißt, jemanden zurückzulassen – Opfern (4.11) wird zur Kernfrage.
- **Zwei Arten von Mitwissern:**
  - **Täter, die schweigen:** der **Erbe der Familie**, als uralter Dauergast getarnt, der das Abkommen am Laufen hält; der **Page von 1987**, der die Tür abgeschlossen hat und heute verbittert ist – seine Schuld hält ihn hier, er ist der wahrscheinlichste, der bricht.
  - **Angehörige, die suchen:** die **Tochter des Heizers**, nicht zufällig Gast in diesem Jahr. Sie sucht dasselbe wie der Spieler – Verbündete oder Konkurrentin um den einen Schlüssel. **Marion Teske, geb. Ahrend** (entschieden 2026-10-24), um 1975 geboren – 1987 war sie zwölf. An ihrer Tür steht „Marion Teske“, im **Hotelregister „geb. Ahrend“**: Wer die Personalakte des Heizers kennt und das Register liest, erkennt sie (6.20).
- **Beweise und Orte:** **Vertrag** im Büro der Direktion (Sperrbereich) · **Gästebuch/Hotelregister** mit Kreuzen neben Namen seit 1987 · **Zeitungsausschnitt** „Brand im Grandhotel – ein Toter“ · **Personalakte** des Heizers mit Foto (die Statur passt) · **Kesselbuch** und die abgeschlossene **Werkstatt** im Tiefkeller · die Koffer früherer Gäste im Lager (7.4).
- **Enden (Vorschlag):**
  - **Flucht:** mit dem Schlüssel hinaus – jemand bleibt zurück.
  - **Das Abkommen brechen:** den Vertrag im Kessel verbrennen (Ofenklappe, 7.4). Er ist nicht mehr gebunden – ob das gut ist, bleibt offen.
  - **Ihn erlösen:** seine Sachen aus dem Fundsachen-Koffer zurückbringen und den Kessel ein letztes Mal anzünden – mitten in seinem Revier.
- **Aus der verworfenen Variante „Zimmer 13 bist du“ bleibt nur ein Andeutungs-Twist:** ein Warnungszettel in der Handschrift des Spielers (2.2) – nie erklärt.

**Das Geheimnis in Schichten** – man setzt es zusammen, statt es zu lesen:
1. **Gerücht:** Gäste erzählen Halbwahres (Berichte, Telefon, 4.13/4.14).
2. **Indiz:** Ein Dokument bestätigt das Gerücht – oder widerspricht ihm.
3. **Beweis:** ein Ort, den man erst betreten muss.
4. **Wahrheit:** Ein Mitwisser bricht sein Schweigen, wenn man ihm den Beweis vorlegt.

**Mitwisser**
- **Wenige Gäste wissen mehr**, als sie sagen. Sie schweigen aus Angst, Schuld oder Eigennutz.
- **Zum Reden bringt man sie mit Beziehung *und* Beweis**, nicht mit Beziehung allein.
- **Sie können lügen und sterben.** Holt das Monster einen Mitwisser, ist sein Wissen weg – oder es liegt nur noch als Notiz in seinem Zimmer. Gäste zu schützen (oder zu opfern, 4.11) bekommt dadurch Gewicht.
- Idee: Das Monster **will gerade die Mitwisser**. Wen man beschützt, entscheidet dann auch, was man erfahren kann.

**Dokumente (Lore)**
- **Jedes Dokument zeigt auf etwas** – einen Ort, eine Person, einen Code. Lore, die nur Sammelgut ist, liest niemand.
- **Arten:** Gästebuch und Hotelregister (Namen, Daten), Zeitungsausschnitte, Briefe, Personalakten, Baupläne (als neue Kartenblätter), Notizbuch des Hausmeisters und Kesselbuch des Heizers (7.4), die Warnungszettel früherer Gäste (4.13) als roter Faden, die Koffer im Lager (7.4).
- **Kein Inventar, kein Questmenü:** Dokumente liest man vor Ort (oder steckt sie ein wie Kartenblätter, 3.2). Was ein Dokument verrät, notiert der Spieler-Charakter als eine Zeile mit Quelle im **Notizbuch** (Lesezeichen „Notizen“, 3.10), ebenso Gerüchte – mit dem, von dem sie stammen, ohne zu sagen, ob sie stimmen. Wendepunkte der Ermittlung (ein Mitwisser bricht sein Schweigen) schreibt er ins **Tagebuch** (3.10, 8.5). *(Bis 2026-10-23 sollte das Tagebuch selbst das Notizbuch der Ermittlung sein.)*
- **Zeitschleife (2.2):** Die Welt setzt sich zurück, Wissen kann bleiben – über die eigenen Zettel. Codes, Namen und wer lügt, gibt man sich selbst weiter. So wird jeder Durchgang schneller und tiefer, auch wenn man scheitert.

**Zu klären**
- ~~**Mitwisser besetzen:** Sind Erbe, Page und Tochter eigene feste Figuren, oder steckt das in Edna, Bruno, Mila?~~ **Entschieden 2026-10-21:** Die **Tochter des Heizers** wird die **vierte Kernfigur** (6.0). Erbe und Page gibt es nur noch über Dokumente und Notizen. Name und wie man sie erkennt: entschieden 2026-10-24 (Marion Teske, geb. Ahrend – über Personalakte und Hotelregister). Offen: Zimmer.
- **Was ist das Ding unter dem Hotel** vor dem Abkommen gewesen – bleibt das bewusst offen?
- Wie viel erfährt man **vor dem ersten Angriff** (2.1)? Vorschlag: nichts, was den friedlichen Anfang verrät – höchstens das Gästebuch.
- **Was überlebt die Zeitschleife?** Nur die eigenen Zettel (2.2), oder erinnern sich auch Mitwisser an einen?
- **Wie viele Sperrbereiche** für den Anfang? Vorschlag: drei bis vier (siehe Kandidaten oben).
- Wie hängt das Geheimnis mit dem **Schlüssel an Halloween** (2.1) zusammen – ist die Wahrheit Voraussetzung für die Flucht, oder ein eigenes, besseres Ende?

### 2.4 Tagesuhr & Tagesablauf (entschieden 2026-10-21, umgesetzt 2026-10-23)
> Ersetzt die Tageslänge aus 2.1 (5 Minuten) und die Nachtruhe zu zufälligen Zeiten (4.18).
>
> **Umgesetzt (2026-10-23)** wie unten, mit diesen Entscheidungen aus der Durchsprache am selben Tag:
> - **Anreise am 1. Oktober um 15 Uhr**; das Kalenderblatt wechselt um Mitternacht, mitten in der Nachtruhe. Die
>   erste Nacht kommt nach gut 8 Minuten.
> - **Nachtruhe** 23–6 Uhr, Beginn und Ende je Nacht ± ½ Stunde. Eine Feier oder Schmück-Aktion, die noch läuft,
>   schiebt den Beginn hinaus.
> - **Phasen:** Morgens zieht es die Gäste in Küche und Garten, abends an die Bar und in die Lobby, die Zimmer sind
>   fast leer. Spontane Feiern gibt es nur abends; zum Schmücken und zur Deko-Suche rufen die Gäste nur tagsüber auf
>   (der Spieler jederzeit). Das große Schmücken kommt in Spieltagen wie bisher (anfangs alle 2½–3½ Tage, ab dem 24. täglich).
> - **Monster:** Ruhe- und Aktivphasen bleiben in Echtzeit – es ist ständig präsent (4.13) und bricht etwa sechsmal am
>   Tag auf statt gut einmal. Die **Angriffschance je Aufbruch ist deshalb ein Fünftel** der bisherigen (4.17), damit es
>   je Tag etwa gleich oft angreift; die übrigen Aufbrüche sind Umsehen. Ebenso eskaliert Gerede nur noch selten (3 %).
>   Harmlos ist es neun Aufbrüche lang (etwa anderthalb Tage wie bisher zwei).
> - **Dreistigkeit** +12 je Spieltag, **Deko-Anspruch** +100 % je drei Spieltage (wie bisher je Tag); die Umbauten aus
>   4.9 und 5.10 kommen eigens.
> - **Bleiben in Sekunden:** Batterie 5 Minuten Licht (etwa ein Abend, sonst wären Batterien kaum noch knapp), Rausch
>   5 und Kater 4 Spielstunden, Kürbiswachstum (3c, entscheidet sich mit 5.10), UV-Spuren 15 Spielstunden.
> - **Nächte ohne Schlaf** zählen weiter bis drei (Lakengeist sicher im Flur, 4.18) – bis Schlaf & Müdigkeit (3.6)
>   sie ersetzt. ~~Ausgeschlafen ist, wer zwei Spielstunden geschlafen hat. Der Spieler schläft wie bisher nur in der
>   Nachtruhe.~~ Seit 2026-10-24 schläft er jederzeit 1–8 Stunden, die Nächte zählen anteilig (3.6).
> - **Uhrzeit sichtbar:** Wanduhr in der Lobby, Abreißkalender in Zimmer 13 und Spielmenü.

**Warum:** Bisher gab es zwei Uhren, die nichts miteinander zu tun hatten – den Kalendertag als reine Zähleinheit und
die Nachtruhe zu zufälligen Zeiten. Die Wanduhr stand fest, obwohl das Konzept Uhrzeiten braucht („die letzte
Stunde“ 2.2, Mitternachtsglocke 7.8, „Die Bar schließt um Mitternacht“ 5.9), und den Tagesablauf der Gäste (6.6)
konnte man nicht lernen.

**Die Uhr**
- **24 Stunden = 24 Minuten Echtzeit** – eine Spielstunde dauert eine Minute, eine Spielminute eine Sekunde.
  31 Tage ≈ **12½ Stunden** bis Halloween (bisher 2½). Tuning-Wert bleibt `Calendar.DAY_SECONDS` (dann 1440).
- Die **Wanduhr** (über dem Haupteingang) und die Uhren im Hotel zeigen die Zeit; die Zeiger bewegen sich sichtbar.
- Draußen ist weiterhin **immer Nacht** (2.1). Die Uhr ist der Rhythmus des Hotels, nicht des Himmels.

**Tagesablauf der Gäste – vier Phasen** (Uhrzeiten als Vorschlag)

| Phase | Zeit | Was die Gäste tun |
|-------|------|-------------------|
| **Morgen** | 6–11 Uhr | aufwachen, Küche, Garten, ernten |
| **Tag** | 11–18 Uhr | freie Zeit: Schmücken (5.9), Deko-Suche, Spiele (6.10), Handel |
| **Abend** | 18–23 Uhr | Bar (3.7), Feiern (7.1), Gruselgeschichten (5.9) – die Zimmer sind leer |
| **Nacht** | 23–6 Uhr | **Nachtruhe** (4.18): alle im eigenen Bett, Licht aus |

- **Innerhalb der Phasen** bleibt es zufällig wie bisher. Lernbar wird der Rahmen: Abends sind die Zimmer leer (Zeit
  zum Klauen, 7.1), nachts schlafen alle.
- **Feste Nachtruhe mit Streuung:** Beginn und Ende schwanken etwas (Vorschlag ± eine halbe Stunde), damit sie nicht
  auf die Sekunde vorhersagbar ist. Eine Nachtruhe dauert damit rund 7 Minuten Echtzeit.
- **Nur für die Gäste.** Der **Spieler** darf so lange wach bleiben, wie er will – mit den Nachteilen der Wachzeit
  (3.6). Schläft er im eigenen Bett, läuft die Zeit weiter fünfmal so schnell – so lange, wie er gewählt hat (3.6);
  in der Nachtruhe springt sie (Zeitsprung, 3.6, seit 2026-10-24).
- **Das Monster bleibt unberechenbar:** Seine Aktivphasen bleiben zufällig, die ständige Präsenz (4.13) gilt weiter.
  Fest wird nur der Rhythmus der Menschen – der Alltag wird planbar, der Horror nicht.

**Was daraus folgt**
- **Die Nacht ist jeden Tag die gefährliche Zeit:** Alle schlafen, keine Zeugen, der Lakengeist kommt in den Flur
  (4.18) – jetzt zu einer Zeit, auf die man sich vorbereiten kann.
- **Anker für Uhrzeiten:** Durchsagen (5.9), Glocke (7.8), Öffnungszeiten der Bar, Fristen bei Aufträgen („vor der
  Nachtruhe“, 6.14).
- **Halloween** bekommt einen Zeitpunkt: das Fest am Abend des 31., danach die letzte Nacht. Wie das Ende abläuft,
  bleibt offen (2.1, 2.2).

**Umrechnen** – der Tag ist fast fünfmal so lang. Alle Werte müssen deshalb einmal durchgesehen werden:
- **In Spieltagen** (Heilung 2–3 Tage 6.17, Batterie einen Tag 4.16, Zerfall der Beziehung je Tag 6.3, Plaudern
  zweimal am Tag, Kostüme ab dem 25., Angriffschance und Ruhephasen je Tag 4.13/4.17, Schmück-Häufigkeit 5.9) –
  bleiben in Tagen und dauern damit entsprechend länger.
- **In Spielminuten oder Sekunden** (Rausch 5 min, Kater 4 min, Kürbisse 2,5–7,5 min, Nachschub der Deko-Quellen,
  Dreistigkeit je Sekunde, Deko-Anspruch je 900 s): je Wert entscheiden. Faustregel als Vorschlag: was dem Rhythmus
  des Hotels folgt (Wachstum, Rausch, Kater, Nachschub), in Spielstunden; was im Moment passiert (Flackern, Jagd,
  Kochen, Hypnose, Losreißen), in Sekunden wie bisher; die Steigerung des Monsters (Dreistigkeit, Anspruch) in Tagen.

**Zu klären**
- ~~**Der friedliche Anfang** (2.1) bis zum 3./4. Oktober dauert jetzt rund 1–1½ Stunden. Bleibt das so, oder kommt
  der erste Angriff früher (z. B. am Abend des 2.)?~~ → **Abend des 2.** (etwa 27–32 min), spätestens am 3. um 20 Uhr
  (entschieden 2026-10-23).
- Ob die Uhrzeiten der Phasen so passen – im Spiel prüfen.

### 2.5 Der Anfang: Türschmuck-Wettbewerb (entschieden und umgesetzt 2026-10-23)
> **Umgesetzt (2026-10-23)** wie unten. Beim Bauen festgelegt: Das Brett hängt an der **Westwand der Lobby** zwischen der
> Glastür zur Bar und der Wandleuchte. Vor der Puppe bleibt ein **Halbkreis frei** (gut 2,5 m), damit man sie über die
> Versammelten hinweg sieht; sie steigt etwa 1,5 m über das Sofa. Die Gäste schauen dabei zur Puppe statt zu tanzen. Am
> Tag nach dem Angriff gehen bis zu drei Gäste zugleich ans Brett (höchstens acht am Tag). Der Zettel kommt erst, wenn man
> die Stelle hinter der Tür gerade nicht sieht (man hört ihn rascheln). Der Tagebuchsatz zum ersten Urteil gilt bis zum
> Tag danach. Kein eigener Sieger, kein Preis.
>
> Gibt dem friedlichen Anfang (2.1) einen Faden: ein Ziel mit Frist, das nebenbei das Schmücken
> lehrt, und einen festen Termin für den ersten Angriff. Ändert 5.5: Die Regel der Puppe wird mitgeteilt, und einmal
> bewegt sie sich vor den Augen des Spielers.

**Warum:** Die ersten rund 30 Minuten tragen bisher nur die Systeme. Der Einführungstext sagt „Lerne die anderen Gäste
kennen, schmücke deine Tür und feiere mit“, ein Ziel gibt es nicht. Alles, was Richtung gibt – Aufzug (7.4), Aufträge
(6.14), Geheimnis (2.3), Großes Schmücken (5.9) –, setzt erst nach dem ersten Angriff ein. Das Spiel wirkt wie eine
Sandbox.

**Spielstart: Brief statt Einführungstext**
- Der lange Einführungstext entfällt, ebenso die Tastenzeile. Jede Aktion nennt ihre Taste ohnehin im Hinweis
  („Brief lesen [E]“), WASD setzen wir voraus. Wer nachsehen will, findet die Hilfeseite im Spielmenü (8.3).
- Nach dem Bestätigen am Spiegel (3.9) erscheint nur ein **kurzer Gedanke** (ca. 3 s): *„Da liegt ein Brief auf dem
  Schreibtisch.“*
- Auf dem Schreibtisch in Zimmer 13 liegt neben dem Tagebuch ein **Umschlag mit Hotelwappen**: der Willkommensbrief der
  Direktion (Wortlaut unten). Wer ihn liest, dem schreibt die Figur den **ersten Tagebucheintrag**. Der Brief bleibt
  liegen und lässt sich wieder lesen. Im Umschlag steckt außerdem das **Notizbuch** (3.10) – die erste Aufgabe darin
  ist die eigene Tür.
- Der Brief schickt den Spieler zum **Aushangbrett in der Lobby** – das erste Ziel.

**Das Aushangbrett in der Lobby**
- Eine **Korktafel** in dunklem Holzrahmen, etwa 1,2 × 0,9 m, oben ein Messingschild **„Mitteilungen der Direktion“**,
  darüber eine eigene kleine **Bilderleuchte** aus Messing – man sieht es von Weitem, und es hängt selbst im Licht.
- **Wo:** prominent an der Lobbywand, auf die man vom Flur von Zimmer 13 kommend schaut. Die genaue Stelle legen wir im
  Spiel fest; das Brett setzt der Code, nicht der Plan.
- **Einzelne Blätter**, jedes für sich lesbar wie ein Warnungszettel: **in der Mitte groß der Wettbewerb** (die
  Überschrift quer durch die Lobby lesbar), **daneben die Hausordnung**.
- **Nach dem Angriff** hängt in der Mitte der veränderte Aushang. Damit man es merkt, stehen am nächsten Tag Gäste davor
  und reden darüber („Hast du gelesen, was am Brett steht?“).
- **Später** kann das Brett das Anschlagbrett ohne Questmenü werden (2.3, 6.14): Großes Schmücken, Suchzettel von
  Gästen („Minka vermisst“), Aufträge. Durchsagen zum Nachlesen stehen im Notizbuch (3.10). Für den Anfang reichen die
  beiden Blätter.

**Der Wettbewerb**
- **Das Hotel ruft ihn aus:** im Willkommensbrief, auf dem Aushangbrett und mit Durchsagen (5.9). Personal sieht man
  nie – die unsichtbare Hotelleitung ist das Abkommen (2.3), das jedes Jahr dasselbe veranstaltet.
- **Die Jury ist die Puppe** (5.5). Sie sitzt bis zur Siegerehrung auf dem Lobby-Sofa, mit einem kleinen Schild „Jury“.
  Kinder nehmen sie vorher **nicht** mit.
- **Bis dahin** (1. Oktober 15 Uhr bis 2. Oktober 20 Uhr, knapp 30 Minuten): Deko besorgen und an die Tür bringen –
  geschenkt, getauscht, gebastelt, geerntet, aus den Kisten oder geklaut. Die Gäste schmücken ihre Türen ebenfalls und
  reden über den Wettbewerb (wer vorn liegt, wer nichts tut). Es zählt, was vor der Tür im Lichtschein hängt, also so,
  wie das Monster zählt (5.10) – das sagt das Spiel nicht.
- **Kein Sieger.** Wer gewonnen hätte, erfährt man nie. Der Lohn fürs Mitmachen ist die Deko, die an der Tür bleibt:
  Beim ersten Urteil der Puppe ist man geschützt, wer nichts getan hat, ist das erste Ziel. Der Wettbewerb hat doch
  entschieden – nur nicht über den Sieger.

**Die Siegerehrung – der erste Angriff**
- **Am 2. Oktober um 20 Uhr** kommen die Gäste in die Lobby (alle wachen Erwachsenen und die Kinder, wie zu einer
  Feier, 7.1), stehen um die Puppe herum und reden über den Wettbewerb. Das ersetzt die spontane Feier im Partyraum, auf
  der bisher der erste Angriff kam (2.1), und den Ausweichtermin am 3. um 20 Uhr.
- **Sie wartet auf den Spieler:** Die Szene beginnt erst, wenn er in der Lobby ist; bis dahin warten die Gäste und
  reden („Wo bleibt denn die Jury?“). Spätestens um **22 Uhr** passiert es ohne ihn. Dann erfährt er es aus Erzählungen
  (6.12) und sieht an der leeren Sofaecke, dass sie fort ist.
- **Blick statt Kameraschnitt:** Der Kopf des Spielers wird sanft zur Puppe gezogen, die Steuerung ist für die Szene
  gesperrt – kein Schnitt, man bleibt in der eigenen Figur (wie beim Erwachen am Waschbecken, 3.9). Die Gäste
  verstummen und schauen ebenfalls hin.
- **Die Puppe steht auf**, hebt ab, schwebt einen Moment über dem Sofa und **löst sich in einer Rauchwolke auf** (7.6).
  Das ist das **einzige Mal**, dass sie sich vor den Augen des Spielers bewegt (5.5).
- **Direkt danach** geht das Licht aus, Stille, Rauschen – das Monster steht in der dunklen Ecke der Lobby. Sonst wie
  bisher beim ersten Angriff (2.1).

**Die Regel danach** (abweichend von 5.5, wo der Spieler sie selbst herausfinden sollte)
1. **Der Aushang wechselt** – das trägt die Regel. Nach dem Angriff hängt am Brett derselbe Zettel in derselben
   Schrift, nur mit anderem Text (unten). Niemand hat ihn ausgetauscht. Der Satz „Die Jury sieht nur, was im Licht
   hängt“ steht auf beiden: vorher ein Tipp für den Wettbewerb, nachher eine Überlebensregel – und die einzige Stelle,
   an der das Spiel die Lichtschein-Regel (5.10) verrät.
2. **Ein Warnungszettel** (4.13) liegt am Morgen danach unter der Tür von Zimmer 13, von einem früheren Gast, der
   denselben Wettbewerb erlebt hat. Er sagt, was der Aushang nicht sagt: Die Puppe ist eine Warnung, kein Todesurteil
   (5.5). Für Spieler, die nicht am Brett vorbeikommen.
3. **Die Bestätigung:** Beim ersten Urteil sagt der Gast es laut („Bei mir sitzt die Puppe …“, 5.5), und die Spielfigur
   notiert es im Tagebuch.
- **Die harmlose Phase ist die Lernzeit:** Die nächsten Angriffe holen noch niemanden (2.1), die Puppe urteilt aber
  schon (5.5). Ein- oder zweimal sieht man die Regel, bevor jemand vor der Puppentür stirbt – wie beim Flacker-Signal
  (4.17).

**Die Texte** (entschieden 2026-10-23) – das Hotel spricht förmlich und etwas altmodisch, immer gezeichnet „Die
Direktion“; die Zettel früherer Gäste wie die bisherigen (4.13): kurz, erste Person, Kürzel und Zimmer, eine Zeile im
UV-Licht (4.16).

*Gedanke nach der Charaktererstellung:*
> Da liegt ein Brief auf dem Schreibtisch.

*Willkommensbrief* (Schreibtisch in Zimmer 13):
> **Hotel – Mitteilung der Direktion**
>
> Verehrter Gast,
> herzlich willkommen in Zimmer 13. Wir wünschen Ihnen einen schaurig-schönen Oktober.
>
> Wie jedes Jahr lädt die Direktion zum Türschmuck-Wettbewerb: Die Jury kürt am 2. Oktober um 20 Uhr in der Lobby die
> schönste Tür. Alles Weitere finden Sie am Brett in der Lobby.
>
> *Die Direktion*

„Wie jedes Jahr“ klingt harmlos und passt später zu den Zetteln früherer Gäste; „Verehrter Gast“ passt zu jeder Figur.

*Erster Tagebucheintrag* (nach dem Lesen des Briefs; ersetzt „Ich bin in Zimmer 13 aufgewacht. Die Tür nach draußen ist
verriegelt.“, das schon etwas andeutete, 2.1):
> Angekommen. Zimmer 13 ist hübsch, wenn auch etwas altmodisch. Morgen Abend kürt eine Jury die schönste Tür – ich
> brauche Deko.

Das Erwachen am Waschbecken (3.9) liest sich damit als kaltes Wasser ins Gesicht nach der Anreise.

*Aushangbrett, Mitte – vorher:*
> **HALLOWEEN IM HOTEL**
> Großer Türschmuck-Wettbewerb
>
> Verehrte Gäste, schmücken Sie Ihre Zimmertür!
> Die Jury kürt am 2. Oktober um 20 Uhr in der Lobby die schönste Tür.
> Die Jury sieht nur, was im Licht hängt.
>
> *Die Direktion*

*Aushangbrett, Mitte – nach dem ersten Angriff:*
> **HALLOWEEN IM HOTEL**
>
> Die Jury hat entschieden.
> Von nun an besucht sie die Tür, die am wenigsten zu bieten hat.
> Die Jury sieht nur, was im Licht hängt.
>
> *Die Direktion*

*Aushangbrett, daneben – Hausordnung:*
> Nachtruhe von 23 bis 6 Uhr.
> Die Bar schließt um Mitternacht.
> Zu Ihrer Sicherheit bleibt der Haupteingang nachts verschlossen.
>
> *Die Direktion*

Der letzte Satz erklärt die verriegelte Tür harmlos – bis man begreift, dass draußen immer Nacht ist (2.1).

*Durchsagen* (Gong, Text als Einblendung; die ersten Durchsagen aus 5.9):

| Wann | Text |
|------|------|
| 1. Okt., ca. 15:30 | „Verehrte Gäste, herzlich willkommen. Die Direktion lädt zum Türschmuck-Wettbewerb. Die Jury kürt morgen um 20 Uhr in der Lobby die schönste Tür.“ |
| 2. Okt., 12 Uhr | „Verehrte Gäste, noch acht Stunden bis zur Siegerehrung. Die Jury freut sich auf Ihre Türen.“ |
| 2. Okt., 19:45 | „Verehrte Gäste, die Jury bittet in einer Viertelstunde in die Lobby.“ |
| 2. Okt., 20 Uhr | „Die Siegerehrung beginnt, sobald alle Gäste versammelt sind.“ |

Bewusst neutral – die letzte erklärt nebenbei, warum die Szene auf den Spieler wartet. Unheimliche, verzerrte
Durchsagen (5.9) erst nach dem Bruch.

*Warnungszettel* (am Morgen nach dem ersten Angriff unter der Tür von Zimmer 13):
> **Vergilbter Zettel, 1999**
>
> Uns haben sie auch einen Wettbewerb versprochen. Einen Sieger gab es nie.
> Die Puppe sitzt vor der Tür, an der am wenigsten hängt. Wer dann in dem Zimmer ist, kommt nicht mehr heraus.
> Schmück mehr als die anderen. Und wenn sie doch vor deiner sitzt – geh woanders hin.
> – M. B., Zimmer 021
>
> *Im UV-Licht:* Wer schmückt, ist Gastgeber. Wer nicht, ist die Gabe.

Die UV-Zeile führt zum Abkommen (2.3), ohne es zu erklären. Nicht „Zimmer 013“ – das bleibt dem Twist der Zeitschleife
(2.2).

*Tagebuch beim ersten Urteil:*
> Die Puppe saß vor Zimmer 21. An der Tür hing fast nichts.

Zimmernummer eingesetzt; der zweite Satz richtet sich danach, wie viel dort tatsächlich hing.

**Zu klären**
- ~~Wie die Puppe aufsteht~~ → die Beine schwingen nach unten, der Kopf richtet sich auf, sie hebt ab (umgesetzt).
- ~~Die genaue Stelle des Aushangbretts~~ → Westwand der Lobby (umgesetzt, im Spiel noch einmal ansehen).
- **Zeitschleife (2.2):** Im nächsten Durchgang weiß man, was bei der Siegerehrung kommt. Rückt sie mit dem um einen Tag
  kürzeren friedlichen Anfang auf den Abend des 1.?

---

## 3. Core Gameplay Loop

```
Erkunden ──► Gäste treffen / reden / handeln ──► Deko erhalten (oder klauen)
   ▲                                                       │
   │                                                       ▼
Überleben ◄── Monster-Ereignis ◄── Deko platzieren (Tür / Flur)
```

1. **Erkunden** des Hotels (Flure, Zimmer, Lobby, Keller …), Gegenstände finden.
2. **Soziale Interaktion** mit Gästen: Gespräche, Handel, Gefallen, **Minispiele** (Schach, Karten … – siehe 6.10).
3. **Deko beschaffen:** geschenkt, ertauscht, gefunden – oder geklaut.
4. **Deko platzieren** an strategischen Punkten (eigene Tür, Flurabschnitte).
5. **Monster-Ereignis** überstehen – Ankündigung erkennen, rechtzeitig in Sicherheit gehen.
6. Konsequenzen tragen (Beziehungen, verlorene Deko, Ruf) → nächster Zyklus.

### 3.1 Spieler-Aktionen (Grundumfang)

| Aktion | Beschreibung |
|--------|--------------|
| **Laufen** | Gehen, Rennen (macht Lärm, kostet Ausdauer – siehe unten) |
| **Springen** | Normale Sprunghöhe, z. B. über Laubhaufen/Hindernisse |
| **Ducken** *(Vorschlag)* | Leiser, schwerer zu sehen (die niedrige Kellertür aus 7.2 gibt es seit dem Untergeschoss, 7.9, nicht mehr) |
| **Gegenstände nehmen** | Aufheben per Blick + Taste (RayCast) |
| **Gegenstände benutzen** | Kerze anzünden, Kürbis schnitzen, Pflanze gießen, Deko aufhängen … |
| **Licht & Vorhänge** | Licht ein-/ausschalten, Vorhänge auf-/zuziehen (siehe 7.3) – Licht aus lockt das Monster an |
| **Gegenstände tragen** | Alles wird **sichtbar in den Händen** getragen, einzeln (siehe 3.2) |
| **Ablegen / Werfen** | Gegenstand bewusst abstellen, platzieren oder fallen lassen; werfen mit G lange halten (3.13, noch nicht gebaut) |
| **Mit Gästen interagieren** | Ansprechen, Dialog, Handel, Geschenke |
| **Mit Gästen spielen** | An einem Spieltisch (Schachbrett, Kartentisch …) eine Partie starten, evtl. um einen Einsatz (siehe 6.10) |
| **Hinsetzen** | Auf Sofas, Bänke, Stühle, Bettkanten und Toiletten (siehe unten) |

**Spieler-Hitbox:** Kapsel, **1,80 m hoch, 45 cm breit** (Radius 0,225 m). Kamera auf Augenhöhe ca. 1,65–1,70 m.

**Ausdauer (entschieden und umgesetzt 2026-10-19):** Rennen verbraucht Ausdauer – etwa ~~10~~ **15** Sekunden am Stück
(2026-10-24 erhöht, Abzüge wie der Kater gelten anteilig weiter), dann ist
man **außer Atem**. Es gibt **keine Anzeige**: Man merkt es nur am Körper. Geht die Ausdauer zur Neige, hört man schon
leise den eigenen Atem; ist sie leer, werden **Herzschlag und Keuchen** deutlich hörbar und **Rennen geht nicht mehr**,
bis man sich beruhigt hat (im Stehen, Sitzen oder Versteck rund 7 Sekunden, beim Gehen doppelt so lange). Beim
Luftanhalten verstummt das Keuchen. Wer flieht, muss sich also gut überlegen, wann er rennt.
- **Keuchen verrät einen (umgesetzt 2026-10-19):** Lautes Keuchen ist Lärm (4 m, 4.15) – auch aus dem Versteck. Findet
  das Monster einen keuchenden Spieler im Versteck, ist die Chance ×1,8 (höchstens 90 %); der Lakengeist vor dem Schrank
  fliegt mit +25 % eher hinein, wenn er einen keuchen gehört hat (4.18).
- **Außer Atem hält man die Luft kürzer an:** voll erschöpft geht der Atem dreimal so schnell aus, beruhigt wieder
  normal. Wer gerade gerannt ist und sich versteckt, muss also wählen: keuchen oder bald nach Luft schnappen.

**Hinsetzen (entschieden und umgesetzt 2026-10-23):** Der Spieler kann sich mit [E] auf jede Sitzgelegenheit setzen:
Sofas, Bänke, Stühle, die Kante jedes Bettes und Toiletten. Jedes Sitzmöbel hat **feste Plätze** (Sofa drei, Bank je
60 cm einer, Bettkante zwei auf der Ausstiegsseite, Stuhl und Toilette einer); man nimmt den freien Platz, auf den man
schaut. Belegt ist ein Platz, wenn dort die Katze schläft, die Puppe sitzt oder ein Gast steht.
- **Blick:** höchstens 90° nach links und rechts, also 180° nach vorn; nach oben und unten frei. [E] wirkt weiter auf
  alles in Reichweite.
- **Aufstehen:** Leertaste oder eine Bewegungstaste – vor das Möbel, sonst daneben oder dahinter. Ein Stoß (Anrempeln,
  Schlag) oder der Würgegriff des Lakengeists reißt einen hoch.
- **Bett:** stehend [E] setzt sich auf die Kante, **geduckt [E] kriecht man darunter** (wie schon beim eigenen Bett,
  wo stehend während der Nachtruhe Schlafen bleibt). Auf der Flucht muss man sich also erst ducken.
- **Nicht dabei:** die Hocker an Spiel- und Schachtisch (nur für Partien, 6.10). Sitzen ist kein Versteck und still;
  man erholt sich wie im Stehen. Gespeichert wird die Stelle, an der man aufstünde – geladen wird stehend.

### 3.2 Kein verstecktes Inventar – Hände und Tasche
- **Es gibt kein verstecktes Inventar.** Jeder Gegenstand (Deko, Schlüssel, Kerze, Messer, Gießkanne, Puppe …) existiert physisch in der Welt und wird **einzeln in den Händen** getragen.
- **Einzige Ausnahme: Geld.** Geld ist ein reiner Zahlenwert, den der Spieler besitzt (Anzeige z. B. dezent im HUD oder beim Handeln).
- **Folgen für das Gameplay:**
  - Jeder Weg will geplant sein: Erst den Schlüssel holen, Tür öffnen, Schlüssel ablegen, dann den Kürbis tragen …
  - Mit vollen Händen ist man verwundbar: keine Tür öffnen, nichts anderes aufheben, evtl. langsamer bei großen Dingen.
  - Im Notfall muss man Dinge **fallen lassen**, um zu fliehen – und sie liegen dann im Flur (für Gäste zum Klauen).
- **Das eigene Zimmer ist das Lager:** Dinge werden auf Tisch, Regal, Bett, Boden abgelegt. Dadurch sind sie auch **sichtbar und klaubar** für unfreundliche Gäste, wenn die Tür offen ist oder sie einen Schlüssel haben.
- ~~**Offen:** Genau ein Gegenstand gleichzeitig – oder zwei Hände?~~ → **Tasche für Kleines (entschieden 2026-10-22, im Prototyp umgesetzt):** Große Dinge (Kürbisse, Deko, Taschenlampe …) trägt man weiter in der Hand. Kleines passt zusätzlich in eine **Tasche mit 6 Fächern**: Süßigkeiten, **Getränkedosen**, Zierkürbisse, Messer, Batterien, Glühbirnen, UV-Aufsatz, Würfel(becher) und Kerzen, die nicht brennen.
  - Kleines nimmt man mit E in die Hand; ist die Hand schon voll, wandert es gleich in die Tasche (mit einem großen Ding in beiden Händen nicht).
  - **[Q] halten** (geändert 2026-10-22, vorher [I]/Mausrad): Die Fächer erscheinen groß mit Bildern der Gegenstände, das Spiel dahinter verschwimmt – **es läuft weiter**, man kann weiterlaufen, nur die Maus wählt (links/rechts, Mausrad oder [1]–[6]). **Loslassen** nimmt den gewählten Gegenstand in die Hand; **was man vorher trug – groß oder klein –, fällt zu Boden** (Lärm wie Ablegen, ein Kürbis poltert). Ein leeres Fach wählen steckt Kleines aus der Hand ein; nichts wählen oder Rechtsklick bricht ab. [1]–[6] ohne [Q] nehmen gleich heraus.
  - Mit einer Katze im Arm kommt man nicht an die Tasche, im Versteck nur mit leerer Hand (dort ist kein Platz zum Ablegen).
  - Immer sichtbar: kleine Fächer mit Bildern unten rechts, sobald etwas in der Tasche ist.
  - Die Dinge in der Tasche bleiben echte Gegenstände: Man kann sie wieder herausnehmen, ablegen, verschenken und verkaufen (im Gespräch „Aus der Tasche …“), Kinder an der Tür bekommen Süßigkeiten auch aus der Tasche. Gäste sehen und stehlen sie nicht.
- **Ausnahme am Körper (entschieden 2026-10-11, im Prototyp umgesetzt):** Drei Dinge trägt man am Körper statt in der Hand – sie sind Werkzeug für Orientierung und Zutritt, keine Beute. Man kann sie nicht ablegen, verlieren, handeln oder gestohlen bekommen.
  - **Kompass** (Zimmer 226): beim Aufheben eingesteckt, **F halten** holt ihn mit der linken Hand hervor.
  - **Karte aus losen Blättern** (seit 2026-10-23 im Notizbuch, 3.10), ein Blatt je Ebene, **jedes einzeln zu finden** (Erdgeschoss in Zimmer 13, Obergeschoss an der Rezeption, Kellerskizze eines früheren Gastes in Zimmer 17; künftige Ebenen wie Tiefkeller bekommen eigene Blätter). **Tab halten** zeigt sie, das Blatt der aktuellen Ebene liegt oben, **Linksklick / Mausrad** blättert.
  - **Schlüsselbund:** Gefundene Schlüssel (später auch Schlüsselkarten) hängen am Bund; Türen schließt man damit auf, egal was die rechte Hand trägt. Das letzte Kartenblatt listet den Bund. **Ausnahme: Der Ausgangsschlüssel an Halloween (2.1) passt nicht an den Bund** – er muss in der Hand getragen werden, die Flucht bleibt ein Lauf, bei dem man ihn nicht fallen lassen darf.
  - Die linke Hand braucht man dafür: Mit einem **großen Gegenstand** (Kürbis) sind beide Hände voll – dann weder Karte noch Kompass noch Aufschließen.

### 3.3 Truhen
- Truhen sind **physische Behälter** in der Welt (kein Inventar-Ersatz im Menü): Deckel auf → man sieht die Gegenstände darin liegen → einzeln herausnehmen / hineinlegen.
- Stehen in Zimmern, Fluren, Keller, Lobby.
- Ideen: **abschließbar** (Schlüssel nötig), begrenzte Plätze, eigene Truhe im Zimmer als sicheres Lager.
- Auch Gäste nutzen Truhen – und können aus fremden Truhen klauen.

### 3.4 Verstecken (inspiriert von Roblox *Doors*)
Verstecke dienen nicht nur zur Flucht, sondern auch dazu, das Monster **gezielt zu beobachten** oder **an Patrouillenwegen vorbeizukommen**.

| Versteck | Ort | Besonderheit |
|----------|-----|--------------|
| **Hotelkleiderschrank** | Zimmer **und Flure** | Blick durch Türspalt / Lamellen, schnell erreichbar |
| **Unter dem Bett** | Zimmer | Niedrige Perspektive, sieht nur Füße/Boden, dafür schwerer zu entdecken? |
| **Truhe** *(optional)* | Diverse | Nur große Truhen, sehr eingeschränkte Sicht |

**Mechanik (angelehnt an Doors):**
- Interaktion mit dem Versteck → kurze Animation hinein, Kamera wechselt in **eingeschränkte Ansicht** (Spalt, Lamellen, Bettkante). Leicht umsehen möglich.
- Herauskommen per Taste (mit kurzer Animation – im falschen Moment gefährlich).
- **Mit vollen Händen:** Großes muss vorher abgestellt werden → es liegt verräterisch vor dem Schrank.
- **Nicht zu lange bleiben:** Wie in Doors wird es nach einer Weile unangenehm (Herzschlag, Rauschen, Atemnot-Effekt) → irgendwann muss man raus. Verhindert „Schrank-Camping“.
- **Im Versteck gesehen = Tod:** Hat das Monster beobachtet, wie man in den Schrank springt oder unters Bett kriecht, **reißt es heftig die Schranktüren auf** (bzw. zerrt einen unter dem Bett hervor) → **Jumpscare → Tod**. Kein Entkommen.
- **Das Monster kann Verstecke auch ohne Sichtung prüfen**, v. a. wenn:
  - es im Suchmodus ist (4.5) und der Schrank nahe am Spielerzimmer steht,
  - die Dreistigkeit hoch ist (4.9).
  - Dann: Es bleibt vor dem Versteck stehen, schnüffelt, rüttelt evtl. – mit Glück (und angehaltenem Atem) geht es weiter.
- **Verstecke können belegt sein:** Ein Gast sitzt schon drin → man muss weiter. Oder: Ein Gast will in *deinen* Schrank.
- **Luft anhalten** (Taste halten), wenn das Monster ganz nah ist – zu lange halten = Keuchen/Geräusch.
- Gleiche Regeln gelten für **Gäste**: Sieht das Monster einen Gast ins Versteck gehen, holt es ihn (6.7).

### 3.5 Kommoden im Flur (entschieden und umgesetzt 2026-10-14)
- An einigen Stellen in den Hauptfluren stehen **Kommoden mit drei Schubladen** (im Prototyp vier je
  Geschoss, unter Bildern und Wandleuchten).
- Jede Schublade lässt sich **aufziehen und zuschieben**. Beim **ersten Öffnen** liegt manchmal etwas darin:
  **Münzen** (1–4) oder ein **Gegenstand** (Kerze, Glühbirne, Batterie, Messer, gezinkte Würfel) –
  oder nur Staub. Im Prototyp: 40 % leer, 30 % Münzen, 30 % Gegenstand.
- Wie Truhen sind Schubladen **physische Behälter**: Was man hineinlegt, bleibt darin und fährt mit auf
  und zu – ein Versteck für Dinge im Flur (3.2).
- Eine offene Schublade verrät, dass hier schon jemand gesucht hat. Aufziehen macht leisen Lärm (3 m, 4.15).
- **Später (offen):** Gäste durchsuchen Kommoden auch / legen Dinge hinein; Kommoden auch in Zimmern;
  Nachschub (z. B. der Hausmeister füllt nach)?

### 3.6 Schlaf & Müdigkeit (vorgemerkt 2026-10-19)
Baut auf dem Schlafen im eigenen Bett und der Nachtruhe auf (4.18). Müdigkeit fließt in die **Schwäche** ein, nach
der sich der Lakengeist seine Opfer sucht (4.18).

> **Entschieden 2026-10-21 (2.4):** Die feste Nachtruhe gilt nur für die Gäste. Der Spieler bleibt wach, so lange er
> will – die **Wachzeit bleibt** und tritt an die Stelle der gezählten Nächte. Die Stufen unten waren für Tage von
> 5 Minuten gedacht und werden in Spielstunden umgerechnet.

- **Wachzeit statt Nächte zählen:** Statt „Nächte ohne Schlaf“ zählt die **Zeit seit dem letzten Schlaf** in
  ~~Spielminuten~~ **Spielstunden** (2.4). Schlaf senkt sie je nach Dauer – eine ganze Nachtruhe auf null, wer früh geweckt wird, ist nur
  halb erholt.
- **Stufen** (Vorschlag): ~~ab ~5 min **müde** · ab ~8 min **übermüdet** · nach 10–15 min~~ – umgerechnet auf die
  Tagesuhr (2.4, Vorschlag 2026-10-21): ab ~**16 Stunden** wach **müde** (Gedanke, Gähnen, die Augen fallen kurz zu) ·
  ab ~**24 Stunden** **übermüdet** (Halluzinationen wie in 4.13/6.8, der Lakengeist kommt deutlich öfter, Werte
  schlechter) · nach **48–72 Stunden ohne Schlaf** kommt der Lakengeist **sicher in den Flur**, sobald man dort allein ist. Keine Anzeige –
  man merkt es am Körper (wie die Ausdauer, 3.1). Vielleicht bei starker Übermüdung **Sekundenschlaf**: die Augen
  fallen eine halbe Sekunde zu, auch auf der Flucht.
- **Ausgeschlafen** (einige Minuten nach einer ganzen Nachtruhe): mehr Ausdauer, länger Luft anhalten, Schock baut
  schneller ab, die Hypnose des Geists ist schwächer, Losreißen leichter. Übermüdet umgekehrt.
- **In fremden Betten schlafen:**
  - **Freies Bett** (leeres Zimmer): geht, aber das Zimmer ist fremd – keine Deko vor der Tür, das Monster biegt
    eher ab.
  - **Bett eines Gastes:** Er kommt zur Nachtruhe heim und findet dich. **Freunde** stört das nicht – sie legen sich
    woanders hin, gute Freunde **halten vielleicht Wache** (ein wacher Zeuge vertreibt den Geist). **Neutrale bis
    genervte** Gäste wecken dich, die Beziehung sinkt, das Gerücht „hat in meinem Bett geschlafen“ geht herum.
    **Verfeindete** wecken dich unsanft, schlagen zu – oder beklauen dich im Schlaf.
- **Gäste wecken:** macht sie unglücklich (Beziehung sinkt, bei Freunden weniger; eine Weile gereizt). **Mit gutem
  Grund** – das Monster ist wirklich nah, es flackert – sind sie dankbar (Beziehung steigt); ein **falscher Alarm**
  (etwa aus einer Halluzination) kostet Vertrauen. Ein geweckter Gast ist auch ein Zeuge gegen den Geist, schläft
  aber bald wieder ein.

> **Entschieden und umgesetzt 2026-10-24: Schlafdauer wählen.** Am eigenen Bett stellt man mit dem **Mausrad** ein,
> wie lange man schläft – **1 bis 8 Stunden**, voreingestellt **eine** (nach jedem Schlaf wieder). Schlafen geht
> **jederzeit**, nicht nur in der Nachtruhe; wer schläft, wenn sie endet, schläft weiter. Sind die Stunden um, steht
> man auf. Geweckt wird man wie bisher (Monster nah, Geräusch). Die **Nächte ohne Schlaf zählen anteilig** – eine
> Vorstufe zur Wachzeit oben: **Sechs Stunden** sind ganz ausgeschlafen (die Schuld fällt auf null), weniger baut sie
> anteilig ab (eine Stunde um ein Sechstel). Am Ende jeder Nachtruhe kommt hinzu, was seit der letzten an sechs
> Stunden fehlte (gar nicht geschlafen: eine ganze Nacht). Wer jede Nacht nur eine Stunde schläft, ist nach
> etwa fünf solchen Nächten so müde wie nach drei durchwachten; mit drei Stunden pendelt es sich bei einer Nacht ein, mit vier bei
> einer halben. Kater gibt es weiter ab zwei Stunden Schlaf im Rausch (3.7). Debug: `--sleep=bett[,h]`.

> **Entschieden und umgesetzt 2026-10-24: Zeitsprung beim Schlafen.** Ein 60-facher Zeitraffer geht nicht: Godot
> rechnet weiter 60 Physikschritte je Sekunde, jeder wäre eine Spielsekunde lang – Gäste sprängen 1,4 m (ferne über
> 4 m) je Schritt, das Monster stünde am Bett, bevor man aufwacht. Stattdessen **springt** die Zeit in Stundenschritten.
> - **So fühlt es sich an:** Augen zu, dunkel, gedämpfte Geräusche, leises Ticken, die Uhrzeit läuft sichtbar mit –
>   etwa **eine halbe Sekunde je Stunde** (8 Stunden ≈ 4 s), mit [E] abbrechbar. Kein Ladebildschirm-Gefühl.
> - **Was nur an der Zeit hängt, rechnet nach:** Uhr, Kürbisse, Fäulnis, Nachwachsen (5.10), Rausch, Kater, Schock.
> - **Gefahr wird je Stunde gewürfelt:** ob etwas zu einem kommt – Monster, Lakengeist am Fenster oder im Flur
>   (4.18), ein Gast an der Tür –, aus den Werten, die heute schon zählen: Deko vor der Tür, Tür abgeschlossen,
>   Licht, Vorhang, Schwäche, Dreistigkeit. Kommt etwas, **endet der Sprung einige Sekunden vorher** (Vorschlag:
>   5 s Echtzeit Vorlauf), man schreckt in normalem Tempo hoch – das Monster ist noch auf dem Weg, der Lakengeist
>   steht am Fenster. **Kein Tod im Schlaf ohne Chance zu reagieren.**
> - **Die anderen leben weiter – Morgenbilanz:** Der Director würfelt seine Aufbrüche auch im Sprung, mit Opfern.
>   Was nachts geschah, erfährt man **danach in der Welt**: ein leeres Zimmer, Spuren, eine Leiche (6.12), Gerede,
>   Tagebuch – keine Übersicht (Vorschlag, wie „man merkt es am Körper“). So hat Schlafen Gewicht und ist kein
>   sicheres Vorspulen.
> - **Nur in der Nachtruhe** wird gesprungen – dann liegen alle Gäste ohnehin im Bett. Endet sie, endet der Sprung;
>   den Rest der gewählten Stunden schläft man im Zeitraffer ×5 weiter (Vorschlag), ebenso jedes Nickerchen am Tag.
>   Ein Sprung auch am Tag (Gäste stehen danach, wo ihr Tagesablauf sie hinschickt, laufende Aktionen sind vorbei)
>   kommt später.
> - **Termine wecken** wie ein Geräusch: Mitternachtsglocke (7.8), Geisterstunde (4.18), Durchsagen (5.9), Klopfen
>   vor einem Pflichttermin wie der Siegerehrung (2.5). Verschlafen ist nie ein Fehler, den man nicht kommen sieht.
> - **Wache (6.18):** Ein guter Freund in Zimmer 13 senkt die Chancen und weckt einen früher (Vorschlag: doppelter
>   Vorlauf).
> - **Spannung der Nacht (2.4):** Die Nacht bleibt die gefährliche Zeit nur, wenn das Würfeln so gefährlich ist,
>   dass Wachbleiben und Schlafen beide ihren Preis haben – Tuning beim Bauen.
>
> **So gebaut (2026-10-24):** Gewürfelt wird nicht „je Stunde“ mit eigenen Chancen, sondern mit dem Zeitplan des
> Monsters selbst – seine Aufbrüche, Absichten, die Puppe, der Weg zur Puppentür, das Abbiegen in Zimmer und das
> Aufreißen von Verstecken laufen nach denselben Regeln, nur ohne zu gehen. Es kommt zu einem, wenn sein Weg zu
> Zimmer 13 führt (Puppe davor oder Zimmer 13 als Ziel und die Deko hält nicht) – oder wenn man hörte, was es tut
> (ein Schrei, ein aufgerissenes Versteck in der Nähe): Dann ist es ab da wirklich unterwegs, 5 s vor dem Ziel.
> Abweichungen und Ergänzungen:
> - **Lakengeist:** Zu Schlafenden kommt er nie (das Bett ist ein Versteck), schlafende Gäste sucht er auch nicht auf –
>   im Sprung gibt es für ihn nichts zu würfeln. Geht er um (Geisterstunde) oder ist der Kürbismann angekündigt oder
>   unterwegs, springt die Zeit nicht; sie springt weiter, sobald es wieder ruhig ist.
> - **Termine:** Die Mitternachtsglocke weckt (auch im Zeitraffer). Durchsagen gibt es nachts keine, die Siegerehrung
>   liegt am Abend.
> - **Telefon:** Das Telefon in Zimmer 13 klingelt wie sonst (nachts die unheimlichen Anrufe) und weckt – wer
>   durchschlafen will, legt den Hörer daneben (4.14).
> - **Morgenbilanz:** Wer im Schlaf stirbt, ohne dass man es hört, bekommt keine Meldung und keine Totenglocke – man
>   findet Blut, das Kleidungsstück, aufgerissene Verstecke, verängstigte Gäste, das Notizbuch und das Tagebuch.
> - **Wache:** Die Wache (6.18) gibt es noch nicht. Ein wacher Erwachsener in Zimmer 13 zählt schon jetzt als Wache.

**Zu klären**
- ~~**Wann schlafen:** nur in der Nachtruhe wie bisher – oder jederzeit ein **Nickerchen** (ohne Zeitraffer, wenig
  Erholung)?~~ Jederzeit, 1–8 Stunden mit Zeitraffer (2026-10-24, oben).
- ~~**Ersetzt die Wachzeit die Nächte-Zählung** (4.18: ab 3 Nächten sicher im Flur) ganz?~~ Ja (2.4, 2026-10-21):
  Der Spieler schläft, wann er will; gezählt wird die Wachzeit. Die verschwommene Sicht (unten) hängt dann auch daran.
- **Schwelle:** fest (z. B. 60 Stunden) oder zufällig zwischen 48 und 72 Stunden je Spiel?
- ~~**Wache halten:** Sollen Freunde wach bleiben und aufpassen, während man schläft?~~ Ja: gute Freunde auf Bitte (6.18, 2026-10-21).

> **Umgesetzt (2026-10-20): verschwommene Sicht.** Jede Nacht ohne Schlaf macht die Sicht unschärfer – nach einer
> Nacht ein Hauch, nach drei deutlich. Sie wird in langsamen Schüben schlimmer und wieder etwas klarer, als fielen
> einem die Augen zu. Mit Kater ist die Sicht noch leicht getrübt (3.7). Debug: `--awake=n`.

### 3.7 Trinken an der Bar (entschieden 2026-10-19)
An der Bar kann man **etwas trinken** (kostet Geld) – und betrunken werden. Rausch fließt in die **Schwäche** ein,
nach der sich der Lakengeist seine Opfer sucht (4.18).

- **Warum man trinkt:** Ein Glas senkt den **Schock** sofort (man trinkt sich Mut an). Eine **Runde mit einem
  Gast** hebt die Beziehung; an der Bar wird ohnehin Mäxchen gespielt (6.10).
- **Rausch** steigt mit jedem Glas und baut sich mit der Spielzeit ab:
  - **leicht:** etwas weniger Schock, sonst nichts.
  - **angetrunken:** die Kamera schwankt leicht, die Maus reagiert etwas verzögert, man **stolpert** ab und zu – das
    ist Lärm (4.15).
  - **betrunken:** **Halluzinationen** (wie bei Müdigkeit, 3.6), man ist geschwächt und desorientiert – ab einem
    Schwellenwert kommt der **Lakengeist** deutlich öfter, auch in den Flur.
- **Danach:** Betrunken schläft man schnell ein, aber man wacht mit einem **Kater** auf – schlechtere Werte statt
  „ausgeschlafen“ (3.6).
- **Mäxchen:** Betrunken zittert man beim Bluffen, Gäste durchschauen einen leichter – und ein betrunkener Gast
  blufft schlechter.
- **Gäste trinken auch:** Sie werden betrunken, gesprächiger (erzählen mehr, auch Gerüchte) und für den Geist
  schwächer. **Kinder** trinken nie (6.13).
- **Offen:** welche Getränke; ~~ob es auch für Erwachsene Alkoholfreies gibt (für Kinder Kakao und Limo, 6.13)~~ →
  Kaffee, auch an der Bar (3.11, 2026-10-24).
- **Getränkedosen (umgesetzt 2026-10-22, 3.2):** Limo und Cola – Kisten in Kühlraum und Lager, auf der Bartheke für 1 Geld. Eine Dose (Linksklick) bringt einen sofort wieder zu Atem (Ausdauer voll, 3.1) und nimmt etwas Schock; das Zischen beim Öffnen ist leiser Lärm (3 m). Gäste trinken geschenkte Dosen, Kinder freuen sich darüber wie über etwas, das sie mögen.
- **Automaten (entschieden und umgesetzt 2026-10-22):** **Snackautomaten** (Süßigkeiten) und **Getränkeautomaten**
  (Cola) für je 1 Geld, ohne Ende. Ihre beleuchtete Front ist ein schwaches Licht im Flur. *Geändert 2026-10-22:* Sie
  stehen, wo der Plan sie zeigt (bisher ein Paar in der Lobby), statt automatisch auf jedem Stockwerk (7.10).
- **Süßigkeiten-Truhe (entschieden und umgesetzt 2026-10-22):** Eine kleine Truhe mit **6 Süßigkeiten** zum Start –
  sichtbar darin, wie alles (3.2). Gäste geben Kindern daraus (6.13). *Geändert 2026-10-22:* Nicht mehr automatisch in
  jedem Zimmer – jede Truhe, die der Plan in ein Hotelzimmer stellt, ist dessen Süßigkeiten-Truhe (7.10).

> **Umgesetzt (2026-10-19):** Flasche und Glas auf der Bartheke, ein Glas **1 Geld**, nimmt etwas Schock. Ab dem
> **2. Glas angetrunken** (Blick schwankt und driftet, die Maus zieht nach, man stolpert ab und zu – das ist
> Lärm), ab dem **3. betrunken** (Halluzinationen), nach dem 3. ist Schluss. Voller Rausch ist nach 5 Spielminuten
> verflogen. Wer betrunken in seinem Bett ausschläft, wacht mit **Kater** auf (4 min: Rennen erschöpft schneller,
> etwas schwächer). Gäste trinken an der Bar meist ein Glas, schwanken, sagen „*hicks*“ und erzählen mehr; „Eine
> Runde ausgeben“ (2 Geld) hebt die Beziehung. Beim Mäxchen zittert die Hand beim Bluffen, betrunkene Gäste
> verraten ihre Bluffs. Debug: `--drunk=n[,gast]`.
>
> **Ergänzt (2026-10-20): verschwommene Sicht.** Im Rausch wird die Sicht unscharf, angetrunken leicht, betrunken
> deutlich. Die Unschärfe pulsiert langsam, das Bild wabert, und man sieht einen blassen, schwankenden zweiten
> Blick (Doppelbild). Nach dem 1. Glas sieht man noch klar.

### 3.8 Kochen in der Küche (entschieden 2026-10-21)
> **Gäste kochen selbst (entschieden und umgesetzt 2026-10-22):** Ist der Herd frei, geht alle paar Minuten ein
> Erwachsener mit einem Kürbis aus seinem Koffer in die Küche, gibt ihn in den Topf, schneidet ihn mit dem eigenen
> Messer und wartet, bis die Suppe fertig ist – dann kommen die Esser wie bei deiner Suppe. Mögen dich dafür nicht mehr
> (das gibt es nur für deine Suppe), werden aber mit dem Koch vertrauter (6.16).
Aus den geernteten Kürbissen (5.8) kocht man am **Herd in der Küche** – **Kürbissuppe** zum Teilen oder **gebratenen
Kürbis** für sich.
- **Ablauf, alles in den Händen (3.2):** Kürbis in der Hand, am Herd [E] → er kommt in den Topf (große Sorten:
  Halloween-Kürbis, Weißer Kürbis, Muskat) bzw. in die Pfanne (kleine: Hokkaido, Butternut, Türkenturban,
  Zierkürbis). Dann mit dem **Messer** in der Hand [E] → klein schneiden, es kocht. Suppe braucht **40 s**, der
  Braten **25 s** Spielzeit; Topf und Pfanne blubbern bzw. brutzeln, es dampft. Den Riesenkürbis kocht keiner.
  **Kürbismatsch** (zerplatzter Kürbis, 5.8, 2026-10-22) kommt direkt in den Topf und wird zu Suppe, ohne Messer.
- **Kürbissuppe – gemeinsam essen:** Ist sie fertig, heißt es „Es gibt Kürbissuppe in der Küche!“ – freie Gäste
  auf demselben Stockwerk kommen (die nächsten), **bis zu sechs**, auch Kinder. Jeder isst eine Schale am Herd:
  **Angst sinkt** (−30), wer mitisst, **mag dich mehr** (+6), und wer zusammen isst, wird miteinander vertrauter
  (6.16). Du selbst isst mit [E] am Topf: **Schock sinkt** (−0,3). Der Topf reicht für **acht Schalen** und wird nach
  drei Minuten kalt. Das gemeinsame Essen ist **Spaß** – es lockt den Kürbismann (4.19).
- **Gebratener Kürbis – für dich:** Er kommt als Teller in die Hand. Mit [Linksklick] isst man ihn (**Schock −0,2**),
  oder man **verschenkt** ihn im Gespräch: wie ein Geschenk (6.3), in der **Lieblingssorte** des Gastes noch mehr
  (5.8), dazu sinkt seine Angst. Der Teller bleibt im Spielstand; was gerade auf dem Herd steht, nicht.
- **Offen:** Ob Kochen Lärm macht oder Gäste selbst kochen; Zutaten aus dem Kühlraum (Eier, 6.13).

### 3.9 Spielerfigur und Charaktererstellung (entschieden und umgesetzt 2026-10-23)
Der Spieler hat einen **Körper**: Er sieht sich im Spiegel – und später sehen ihn Mitspieler, falls es einmal Koop
gibt (10, Frage 9). In der Ich-Perspektive sieht man ihn (vorerst) nicht, nur **im Spiegel** und als **Schatten**
an Lampen und Kerzen.
- **Erwachen am Waschbecken (neues Spiel):** Das Bild ist schwarz, Wasser läuft, ein Klatsch ins Gesicht. Dann
  blendet das Bad von Zimmer 13 langsam ein, erst verschwommen, dann klar, und der Blick hebt sich vom Becken zum
  Spiegel. Dort stellt man sich ein; bis zur Bestätigung steht die Uhr, man kann sich nicht bewegen. „So sehe ich
  aus.“ fragt noch einmal nach – **später lässt sich nichts mehr ändern**, auch die Kleidung nicht.
- **Was man wählt:** Frau oder Mann und das **Alter** (jung, mittel, alt – die sechs erwachsenen Grundkörper der
  Gäste, 6.0). **Kein Kind:** Kinder haben im Spiel Vorteile (das Monster holt keine Kinder, 6.13). **Größe 1,45–2,00 m**,
  die **Statur** in einem Dreieck mit den Ecken **schlank**, **definiert** und **kräftig** (= dick; die Mitte ist
  der Grundkörper), dazu **Hautton**, **Haarfarbe**, **Oberteil** und **Hose** aus den Farben der Gäste. Kein Name.
- **Nur Aussehen:** Größe und Statur ändern weder Tempo noch Ausdauer. Augenhöhe, Kapsel und Hocken wachsen mit
  der Größe – wer 2 m groß ist, sieht über mehr hinweg und stößt sich eher.
- **Spiegel über dem Waschbecken** reicht von 1,10 bis 2,04 m, damit sich jede Figur darin sieht (Scheitel bei
  2 m, Bauch bei 1,45 m); seit 24.10. mit Modell (Stahlrahmen über einem Aufsatzbecken mit Wandarmatur).
- **Vorgemerkt:** Atem und Keuchen passend zur Figur (Frau/Mann, Alter); den eigenen Körper beim Blick nach unten
  sehen; Haare später über einen Gegenstand färben.

### 3.10 Notizbuch und Tagebuch (entschieden 2026-10-23, Stufe 1 umgesetzt 2026-10-23)
> Ändert 2.3, 2.5, 3.2, 6.14, 7.4 und 8.5.
>
> **Stufe 1 umgesetzt (2026-10-23):** Notizbuch im Umschlag des Briefs, mit der Karte zusammengelegt, drei Reiter am
> rechten Rand; **Rechtsklick** (mit Tab) springt zum nächsten Lesezeichen, Mausrad und Linksklick blättern durchs
> ganze Buch (im Versteck hält Rechtsklick die Luft an, dort reicht das Mausrad). Aufgaben: vorerst nur die eigene
> Tür für den Wettbewerb (bei der Siegerehrung durchgestrichen, ohne Deko vor der Tür „zu spät“) – die Aufträge (6.14)
> tragen sich später mit einem Aufruf ein. Notizen: Durchsagen (Kurzfassung), Aushänge am Brett, was die Zettel
> früherer Gäste verraten (auch die UV-Zeile), Einladungen zur Feier und zum Schmücken am Telefon, der Anruf eines
> Toten. Tagebuch: Ankunft, Siegerehrung (mit oder ohne den Spieler), erstes Urteil, erster Toter, erster Diebstahl,
> Lakengeist, Kürbismann; die fremde Zeile (4.13) steht beim Aufschreiben darunter; „Im Tagebuch blättern“ am
> Schreibtisch. Beim Bauen festgelegt: Unter einer Aufgabe steht klein *„Edna · Zi. 021 · vor der Nachtruhe“*, das
> Kreuz direkt hinter dem Namen; der Tageskopf ohne Wochentag (das Spiel hat kein Jahr). Die Seiten sind
> **ungeschattet** – beleuchtet war die Schrift grau auf grau, und so liest man auch im Dunkeln. Eine Seite fasst
> 14 Zeilen, groß genug für 480 × 270. Noch offen: Gerüchte im Gespräch (es gibt noch kein System, das sie trägt).
>
> **Ergänzt (2026-10-24): Lesezeichen „Gesehen“.** Wer eine der drei Bedrohungen (4.20) selbst sieht – aktiv, im Blick,
> höchstens 30 m weit –, hat ihr Bild im Notizbuch: wie ein eingeklebtes Foto (gezeichnetes Porträt), darunter Name,
> Tag und Uhrzeit des ersten Mals. Der vierte Reiter erscheint erst nach der ersten. Dieselben Porträts zeigt der
> Sterbebildschirm (8.7) – wer einen geholt hat, mit einem Satz dazu. Ein Totenkopf steht über den Todesmeldungen und
> an Leichen („Edna – tot“). Über dem Interaktions-Hinweis steht ein gezeichnetes Symbol: Tür, Kommode, Verstecken,
> Versteck verlassen, Schlafen, Bar, Kaffee, Schmücken.

**Warum:** Bisher sollte das Tagebuch alles tragen: Aufträge (6.14), die Seite zur Fahrstuhl-Reparatur (7.4), das
Wissen der Ermittlung (2.3) – und es liegt fest in Zimmer 13 (8.5). Wer unterwegs wissen will, was er versprochen hat
und bis wann, müsste zurücklaufen. Durchsagen (5.9) sind eine Einblendung von wenigen Sekunden und dann weg. Deshalb
zwei Bücher mit klar getrennten Rollen:

| | **Notizbuch** | **Tagebuch** |
|---|---|---|
| Wo | am Körper, immer dabei (3.2) | fest auf dem Schreibtisch in Zimmer 13 |
| Spiel | läuft weiter, wie bei der Karte | pausiert (8.5) |
| Inhalt | Stichpunkte: Aufgaben und Notizen | Prosa: Meilensteine der Geschichte |
| Wann geschrieben | sofort, wenn es passiert | beim nächsten Speichern |
| Wer liest mit | niemand | Gäste, die ins Zimmer kommen (8.9) |

**Das Notizbuch**
- **Woher:** Es liegt im Umschlag des Willkommensbriefs (2.5), ein kleines Notizbuch mit dem Hotelwappen – ein
  Geschenk der Direktion, also des Abkommens (2.3). Wer den Brief liest, steckt es ein.
- **Am Körper** wie Kompass und Schlüsselbund (3.2): nicht ablegen, nicht verlieren, nicht handeln, nicht stehlen.
- **Karte und Notizbuch sind ein Ding:** Die losen Kartenblätter (3.2) liegen darin. **Tab halten** öffnet es mit der
  linken Hand auf der Karte, wie bisher; drei **Lesezeichen** führen zu **Karte**, **Aufgaben** und **Notizen**. Jedes
  Lesezeichen merkt sich seine Seite, die Seiten blättert man wie die Kartenblätter. (Wer noch kein Notizbuch hat,
  sieht mit Tab nur die Blätter.) Den Wechsel der Lesezeichen macht der Rechtsklick (siehe oben).
- **Das Spiel läuft weiter**, man kann dabei gehen. Mit einem großen Gegenstand in beiden Händen geht es nicht, im
  Gespräch auch nicht – wie bei der Karte.
- **Neuer Eintrag:** kurzes Kritzeln und der Hinweis *„Notiert.“* – mehr nicht, kein Aufblinken im HUD.
- **Nur, was die Figur weiß:** handschriftlich, knapp, erste Person. **Keine Wegmarken, keine Zähler wie „2/3“, keine
  Prioritäten.** Das Notizbuch ist kein Questmenü (2.3), es ersetzt nur das Gedächtnis der Figur.
- **Zeitschleife (2.2):** Das Notizbuch ist im neuen Durchgang leer. Wissen bleibt nur über die eigenen Zettel.
- **Im Spielstand** (Einträge und ihr Zustand).

**Lesezeichen „Aufgaben“**
- **Fortlaufend in der Reihenfolge, in der man sie bekommt** – nichts wird umsortiert, nichts hervorgehoben. Jeder
  Spieltag beginnt mit einem Tageskopf (*„3. Oktober“*).
- **Eine Zeile je Aufgabe:** was, von wem mit **Zimmernummer** (bei 67 Gästen findet man sonst niemanden) und die
  Frist, falls es eine gibt – *„Kerze bringen“*, darunter klein *„Edna · Zi. 021 · vor der Nachtruhe“*.
- **Eingetragen beim Annehmen.** Eine abgelehnte Bitte kommt nicht hinein.
- **Drei Enden:**
  - **Erledigt:** durchgestrichen – sobald die Figur es merkt (der Gast bedankt sich, die Szene ist vorbei), nicht
    stillschweigend im Hintergrund.
  - **Verpasst:** bleibt stehen, daneben *„zu spät“*.
  - **Der Gast ist tot:** ein Kreuz neben dem Namen – wie die Kreuze im Hotelregister seit 1987 (2.3). Die Aufgabe
    bleibt offen stehen (*„Ich hatte es ihm versprochen“*, 6.14).
- Alte offene Aufgaben rutschen auf frühere Seiten – das ist gewollt. Erinnern tut der Gast im Gespräch (6.14).
- **Die ersten Einträge:** *„Tür schmücken – Direktion · bis 2. Okt., 20 Uhr“* nach dem Lesen des Briefs (2.5),
  durchgestrichen bei der Siegerehrung. Später die drei Mängel am Aufzug aus dem Notizbuch des Hausmeisters (7.4) als
  drei Zeilen.

**Lesezeichen „Notizen“**
- **Fortlaufend mit Datum und Uhrzeit**, dazu von wem: *„2. Okt., 12:00 – Durchsage: noch acht Stunden bis zur
  Siegerehrung.“*
- **Nur ausgewählte Arten**, sonst wird es ein Gesprächsprotokoll:
  - **Durchsagen** (5.9) – auch die, die es nicht geben dürfte. Die Figur schreibt sie genauso nüchtern auf.
  - **Termine:** Feiern, Öffnungszeiten, was ein Gast verabredet.
  - **Regeln:** die Hausordnung beim ersten Lesen des Bretts, die Regel der Puppe (2.5).
  - **Gerüchte** mit Bezug zum Geheimnis (Schicht 1 in 2.3), am Telefon (4.14) oder im Gespräch.
  - **Was ein Dokument verrät** (Code, Name, Ort – 2.3) als eine Zeile mit Quelle; den Wortlaut liest man vor Ort.
- **Die Quelle steht immer dabei**, ob sie stimmt, nie. Mitwisser lügen (2.3) – abwägen muss der Spieler selbst.
- Das Aushangbrett (2.5) bleibt die Stimme des Hotels und kann sich ändern; das Notizbuch hält fest, was man selbst
  gelesen und gehört hat. Nach dem ersten Angriff steht im Buch noch der alte Aushang.

**Das Tagebuch: Meilensteine**
- Das Tagebuch in Zimmer 13 bekommt **Einträge in Prosa bei Wendepunkten**, z. B.: Ankunft (2.5), das erste Auftauchen
  des Monsters, das erste Urteil der Puppe, der erste Tod eines Gastes, die erste Nacht mit dem Lakengeist (4.18), der
  Kürbismann (4.19), Aufzug repariert und Tiefkeller betreten (7.4), ein Mitwisser bricht sein Schweigen (2.3),
  Halloween.
- **Auch die dunklen Taten** sind Meilensteine: ein Diebstahl, ein Gast, den man ins Dunkle geschickt hat (4.11, 6.2).
  Davon leben die Gäste, die das Tagebuch lesen (8.9).
- **Geschrieben wird beim nächsten Speichern:** Was seit dem letzten Mal geschehen ist, schreibt die Figur am
  Schreibtisch auf. Damit wird *„ein Tod kostet alles seit dem letzten Tagebucheintrag“* (8) wörtlich wahr – und wer
  speichert, schreibt auch sein Geständnis nieder.
- Man kann die Einträge in Zimmer 13 nachlesen (Spiel pausiert, 8.5). Der **Tagebuchsatz** in der Slot-Übersicht
  bleibt davon getrennt: Er beschreibt den Stand, die Einträge erzählen den Weg dorthin.

**Zu klären**
- ~~Liest man das Notizbuch im Dunkeln?~~ → ja, die Seiten sind ungeschattet (umgesetzt).
- ~~Wie viele Zeilen auf eine Seite passen~~ → 14 (umgesetzt, im Spiel noch einmal ansehen).
- Die **Kartenblätter** haben denselben grauen Schleier wie die Notizbuchseiten vorher – auch ungeschattet machen?

### 3.11 Kaffee (entschieden und umgesetzt 2026-10-24)
Gegen die Müdigkeit (3.6) half bisher nur Schlaf. Kaffee **überdeckt** sie – er baut sie nicht ab. So bleibt die
Nacht gefährlich (2.4): Wer wach bleibt, zahlt später. Zugleich das Alkoholfreie für Erwachsene, das 3.7 offen ließ.

- **Wirkung:** Eine Tasse wirkt **3 Spielstunden**. So lange fühlt man sich, als hätte man **eine Nacht weniger**
  Schlaf nachzuholen – Sicht und Schwäche (Lakengeist, 4.18) wie ausgeruhter. Die Schuld selbst läuft weiter. Weitere
  Tassen verlängern die Wirkung nur, sie überdecken nicht mehr.
- **Das Tief:** Lässt die Wirkung nach, kommt die Müdigkeit **eine Spielstunde lang schwerer** zurück (eine halbe
  Nacht mehr). Wer da schon schläft, verschläft es.
- **Schlecht schlafen:** Solange der Kaffee wirkt, zählt Schlaf **nur halb** – erst Kaffee, dann ins Bett, bringt wenig.
- **Zu viel:** Ab der **dritten Tasse** kurz hintereinander zittert die Hand (der Gegenstand darin bebt), man hört sein
  Herz klopfen, und beim Mäxchen verrät das Zittern den Bluff wie im Rausch (3.7). Es legt sich, wenn der Kaffee
  abgebaut ist. Nüchtern macht Kaffee nicht – der Rausch bleibt.
- **Kaffeemaschine in der Küche:** links auf der Küchenzeile, umsonst. [E] mit leeren Händen – sie mahlt und gurgelt
  **20 Sekunden** (Lärm, 6 m: nachts Kaffee zu kochen ist ein Risiko), dann steht die Tasse unter dem Auslauf.
- **An der Bar:** Tassen auf der Theke, **1 Geld** je Tasse.
- **Die Tasse:** nur in der Hand (passt nicht in die Tasche), [Linksklick] trinkt. Fällt sie tiefer als einen Meter
  oder wird sie geworfen, zerbricht sie – ein **Kaffeefleck** bleibt, den man vor Zimmer 13 wegwischen kann und über
  den sich Gäste beschweren wie über Wachs.
- **Gäste trinken morgens Kaffee:** Zwischen 6 und 11 Uhr geht ab und zu ein Erwachsener aus der Küche zur Maschine,
  kocht sich eine Tasse und trinkt sie dort. Wer kurz nacheinander an der Maschine Kaffee trinkt, wird miteinander
  vertrauter (6.16). Kinder trinken nie Kaffee (6.13).
- **Verschenken:** wie eine Getränkedose – der Gast trinkt ihn gleich. Kinder lehnen ab.
- **Gespeichert:** Wirkung, Tief und Zittern des Spielers, die Tasse als Gegenstand. Was die Maschine gerade tut, nicht.
  Debug: `--kaffee=n` (n Tassen getrunken), `--kaffee=maschine` (vor der Maschine, fast fertig), `--kaffee=gast[,id]`.

### 3.12 Tee (entschieden und umgesetzt 2026-10-24)
Das Gegenstück zum Kaffee (3.11): **Kräutertee** beruhigt und hilft beim Schlafen. Er überdeckt keine Müdigkeit – er
macht den Schlaf, der sie abbaut, besser.

- **Wirkung:** Eine Tasse nimmt etwas **Schock** (−0,1). **2 Spielstunden** lang danach ist Schlaf um **30 % besser**
  (zählt ×1,3), und der Kaffee stört ihn in der Zeit nicht mehr – Kaffee am Abend, Tee vor dem Bett geht also.
- **Wasserkocher in der Küche:** rechts neben der Kaffeemaschine, umsonst. [E] mit leeren Händen – das Wasser rauscht
  **15 Sekunden** (leiser Lärm, 4 m), zum Schluss pfeift er leise (8 m), dann steht die Tasse neben ihm.
- **An der Bar:** Tassen Tee neben dem Kaffee, **1 Geld** je Tasse.
- **Die Tasse:** wie beim Kaffee – nur in der Hand, [Linksklick] trinkt, zerbricht ab einem Meter und hinterlässt einen
  hellen **Teefleck** (Beschwerden und Putzen wie beim Kaffee).
- **Gäste trinken abends Tee:** Zwischen 18 und 23 Uhr holt sich ab und zu ein Gast aus der Küche einen Tee am
  Wasserkocher, **auch Kinder** – Tee nimmt ihnen Angst, und wer kurz nacheinander dort trinkt, wird vertrauter (6.16).
- **Verschenken:** Der Gast trinkt ihn gleich, seine Angst sinkt. **Kinder** freuen sich darüber wie über Limo.
- **Symbol:** Bis es ein eigenes gibt (Icon_tea.png), steht über dem Hinweis die Tasse vom Kaffee.
- **Gespeichert:** die Nachwirkung beim Spieler und die Tasse. Debug: `--tee=n|kocher|gast[,id]`.

### 3.13 Werfen (Entwurf 2026-10-25, noch nicht gebaut)
Bisher werfen nur Kinder bei ihren Streichen (6.13), dort steht schon: „auch der Spieler kann werfen“. So soll es gehen –
Wunsch des Spielers vom 2026-10-24, im Gespräch ausgearbeitet; die letzte Frage unten ist noch offen.

- **Steuerung:** **G kurz** bleibt Aufhängen bzw. Verstreuen (5.6). **G lange halten** holt aus: ab etwa 0,3 s baut sich
  die Wurfkraft auf (voll nach etwa 1,2 s), **Loslassen wirft** in Blickrichtung. Schweres fliegt weniger weit (Masse);
  den Riesenkürbis kann man nur kurz wegschubsen. Eine kleine Anzeige am Fadenkreuz zeigt die Kraft.
- **Aufprall** (wie bei den Streichen, `Item.throw_from`): **Kürbisse zerplatzen** aus jeder Höhe, **Kerzen zerbrechen**,
  **Glühbirnen platzen** (7.3), alles andere landet einfach.
- **Lange Spritzer:** Ein geworfener Kürbis hinterlässt einen **langen, in Flugrichtung gezogenen Fleck** – je schneller,
  desto länger. Gebaut wie der Strom auf Treppen: als Kette unverzerrter Flecken, keine gestauchten Grafiken.
- **Wände:** Trifft etwas Flüssiges eine Wand (Kürbis, Kerze, Kaffee, Tee), klatscht ein Fleck an die Wand und **läuft als
  kleiner Strom herunter** bis zum Boden, dort eine kleine Pfütze (wie auf Treppen).
- **Personen treffen:** Der Gast ruft auf und **mag dich weniger** (mit einem Kürbis stärker); ein getroffenes **Kind**
  verärgert seine Eltern (wie Rammen, 6.13); wer es sieht, erzählt es weiter (Gerede). Das Monster bleibt unbeeindruckt,
  ebenso der Kürbismann – ihn betäubt nur ein gezeigter Kürbis, nie ein Wurf (4.21, geändert 2026-10-25).
- **Lärm:** Der Aufprall macht Lärm am Aufschlagort (4.15). **Offen:** Soll Werfen damit ausdrücklich als **Ablenkung
  fürs Monster** taugen (es geht zum Aufschlagort)? Das wäre ein großer Zuwachs an Spielmechanik – Vorschlag ja.
- **Gespeichert:** nichts Neues – die Folgen sind Flecken und Beziehungen, die schon gespeichert werden.
  Debug: `--wurf=kraft[,gegenstand]`.

---

## 4. Das Monster

### 4.1 Grundprinzip
- Das Monster ist **fast immer unsichtbar oder nur angedeutet**: Silhouette am Flurende, Schatten hinter einem Vorhang, Geräusche hinter Wänden.
- Es **zeigt sich zufällig** (gewichteter Zufall, siehe unten) – nicht skriptgesteuert und nicht vorhersehbar.
- **Aussehen** (entschieden 2026-10-11): dürr, mit langen Gliedmaßen, Rippen und Stacheln am Rücken, langgezogenem Schädel, offenem Maul und langer Zunge. Es **geht aufrecht auf den Hinterbeinen** und ist dabei gut zwei Meter groß, gestreckt noch größer. Es kann **auf alle Viere** gehen: zum Schleichen, Lauern und an Verstecken. Unter Türen duckt es sich.
  > Im Prototyp umgesetzt (2026-10-11): Meshy-Modell mit Skelett, Bewegung im Stop-Motion-Stil, Hocke beim Wegschleichen, Lauern und Prüfen von Verstecken.

- **Immer nur eine Bedrohung im Haus (entschieden und umgesetzt 2026-10-20):** Monster, Lakengeist (4.18) und Kürbismann
  (4.19) sind nie gleichzeitig unterwegs. Ist einer da, warten die anderen, bis er wieder weg ist – das Monster
  verschiebt seinen Aufbruch, der Lakengeist erscheint nicht, der Kürbismann würfelt erst danach.
  **Ersetzt (2026-10-21):** eine Bedrohung **je Ebene** und außer Hörweite voneinander (4.20).

### 4.2 Ankündigung („Manifestation“)
> Im Prototyp durch 4.13 ersetzt: keine globale Vorwarnung mehr, stattdessen Rauschen nach Entfernung und lokales Flackern.

Bevor das Monster erscheint, gibt es eine Vorwarnphase (z. B. 5–15 Sekunden):
- **Flackerndes Bild** (Post-Processing-Shader: kurze Helligkeits-/Frame-Aussetzer)
- **Dezent flackernde Lichter** in der Umgebung (OmniLights / SpotLights mit Flicker-Script)
- **Rauschen im Bild** (Film-Grain / VHS-Noise-Shader, Intensität steigt an)
- Optional: Audio-Rauschen, tiefes Brummen, Verstummen der Umgebungsgeräusche

### 4.3 Verhalten
> Die feste Patrouillenroute ist im Prototyp durch 4.13 ersetzt (Umherstreifen im ganzen Hotel, Ruhephasen im Keller). Abbiegen in Zimmer, Abschreckung durch Deko und die Abweichungen gelten weiter.

- **Phasen:** `Latent` (Hintergrund) → `Vorwarnung` → `Manifestation` (sichtbar/aktiv) → `Rückzug`
- **Feste Patrouillenroute** (entschieden): Das Monster startet im **Keller** und läuft immer dieselbe Runde – Ostflur an allen Zimmertüren vorbei → Lobby → Garten → Lobby → Küche → Flur → zurück in den Keller. *Wann* es kommt, bleibt zufällig; *wo* es langgeht, kann man lernen.
- **An jeder Zimmertür** entscheidet es, ob es abbiegt (Neugier des Zimmers × Dreistigkeit). Im Zimmer prüft es Bett und Schrank. Deko vor der Tür hält es schon im Flur auf → es überspringt die Tür.
- Abweichungen von der Route: Geräusch (nachsehen), bemerkt (Suche ums Spielerzimmer), Sichtung (Jagd) – danach zurück auf die Route.
- Wahrscheinlichkeit einer Manifestation steigt mit Zeit, Lärm, fehlender Deko in der Nähe.
- **Deko wirkt abschreckend:** Bereiche mit Deko werden gemieden; zu wenig Deko = Monster kann durch.

### 4.4 Licht & Dunkelheit
- Das Monster **bevorzugt dunkle Bereiche** und meidet helle.
- Jeder Bereich hat einen **Helligkeitswert** (Lichtquellen in der Nähe, defekte Lampen, Tageszeit).
- Manifestationen und Wege des Monsters werden zur Dunkelheit hin gewichtet.
- Konsequenz: Licht wird zur Ressource. Flackernde/ausfallende Lampen (Teil der Vorwarnung) machen sichere Zonen plötzlich unsicher.
- Synergie: Ein **geschnitzter Kürbis mit Kerze** ist Deko *und* Lichtquelle zugleich.
- **Licht aus = das Monster kommt** (entschieden): Wird ein Raum oder Flurabschnitt per **Lichtschalter** dunkel gemacht (7.3), steigt die Neugier dort stark an und das Monster wird angelockt. Das gilt für Spieler *und* Gäste – wer bei sich das Licht ausmacht, lädt es ein.
- **Flackern bleibt:** Auch eingeschaltete Lampen **flackern weiterhin**, wenn das Monster sich ankündigt (4.2). Licht schützt, aber es warnt nicht ab.
- **Vorhänge** (7.3) bestimmen, ob Mondlicht hereinfällt – zugezogen wird ein Zimmer dunkler.

### 4.5 Wahrnehmung: „Es weiß, dass du es gesehen hast“
- Das Monster registriert, wenn der Spieler es **bemerkt** hat.
- Mögliche Auslöser (zu entscheiden):
  - Spieler schaut es länger als ~1 Sekunde direkt an (Monster im Sichtkegel der Kamera, Sichtlinie frei)
  - Spieler reagiert sichtbar (rennt weg, leuchtet es an)
- Folge: Das Monster wechselt in einen **Suchmodus** und durchsucht gezielt die **Umgebung des Spielerzimmers** – Flur, Nachbartüren, dunkle Ecken.
- Dadurch entsteht Spannung: Der eigene sichere Ort wird zum Ziel. Gut platzierte Deko vor der Tür wird jetzt wirklich auf die Probe gestellt.

### 4.6 Wenn das Monster dich erwischt
- **Jumpscare** (Monster erstmals voll sichtbar, lautes Audio-Stinger, Kamera-Ruck)
- Danach **Sterbebildschirm** (z. B. verrauschtes VHS-Standbild, Text, Optionen: Neu laden / Hauptmenü)
- Danach: **letzten Spielstand laden** (entschieden, siehe 8.7).

### 4.7 Das Monster lauscht
- Wenn der Spieler mit Gästen **über das Monster spricht** (deren Erfahrungen, Sichtungen), kann das Monster mithören.
- Folge: Es wird **dreister** (siehe 4.9). Reden hilft also (Infos, Beziehung, Gäste beruhigen), hat aber einen Preis.
- Idee: Leise reden ist sicherer – z. B. Gespräche im hellen, dekorierten Zimmer statt im dunklen Flur.

### 4.8 Es wird mit der Zeit anspruchsvoller
- Das Monster gewöhnt sich an Deko: Was in Nacht 1 reicht, reicht in Nacht 3 nicht mehr.
- Die **benötigte Deko-Stärke** steigt mit der Spielzeit → Spieler muss ständig nachlegen, verbessern, schnitzen, handeln.
  **Seit 2026-10-21 (5.10):** in Spieltagen gerechnet und gedeckelt – von ×1 beim ersten Angriff auf etwa ×3 an Halloween.
- Evtl. auch **Gewöhnung an konkrete Deko**: Immer derselbe Kürbis an derselben Stelle wirkt schwächer; Abwechslung wirkt besser.

### 4.9 Versteckte Werte: Dreistigkeit & Neugier
Das Verhalten des Monsters wird aus **für den Spieler unsichtbaren Werten** berechnet. Der Spieler soll sie nur indirekt spüren (häufigere Vorwarnungen, Geräusche näher am Zimmer, …).

> **Vereinfacht (entschieden 2026-10-21), noch nicht umgesetzt:**
> - **Dreistigkeit** steigt wie der Anspruch (4.8) **in Spieltagen** statt je Sekunde – mit der Tagesuhr (2.4) wäre
>   sie sonst nach gut einem Tag bei 100, und danach wirkte kein Ereignis mehr. Ereignisse (belauscht, bemerkt, UV)
>   geben **abklingende Boni** obendrauf. Die „Delle“ nach einer Abweisung entfällt.
> - **Neugier je Zone** (über 300 Zonen, fast ohne Wirkung) wird durch eine **kurze Liste heißer Stellen** ersetzt –
>   Ort, Stärke, Abklingen (Lärm, Licht aus, Sichtung, „Angst riecht“). Das Urteil der Puppe (5.5) wirkt ohnehin direkt.

**Dreistigkeit (global, 0–100)** – *wie viel traut es sich?*
- ↑ mit der Zeit (langsam, stetig – seit 2026-10-21 in Spieltagen)
- ↑ wenn es Gespräche über sich belauscht (4.7)
- ↑ wenn es bemerkt wurde / Sichtungen (4.5)
- ↑ wenn Gäste in Panik sind (6.5)
- ~~↓ kurzzeitig, wenn es von starker Deko abgewiesen wurde~~ (entfällt 2026-10-21)
- ↓↓ **stark, wenn es einen Gast geholt hat → Sättigung** (siehe 4.10)

**Neugier (pro Ort/Zone, 0–100)** – *wohin zieht es?*
- ↑ Dunkelheit in der Zone
- ↑ wenig/schwache Deko (im Verhältnis zum aktuellen Anspruch, 4.8)
- ↑ Sichtung in der Nähe / Spielerzimmer im Suchmodus (4.5)
- *Die Puppe (5.5) wirkt nicht über die Neugier, sondern direkt: Vor ihrer Tür endet jeder Angriff, und wer dort
  ist, stirbt (neu gefasst 2026-10-22; ersetzt „Puppe blockiert/weggetragen“ und „schlechtes Urteil“).*
- ↑ Lärm
- ↓ langsamer Abbau über Zeit

**Abschreckung (pro Zone)**
```
Abschreckung = (Summe Deko-Stärke × Licht-Faktor) / Anspruch(Zeit)
```
*Seit 2026-10-21 (5.10):* Jede Deko zählt in ihrem **Lichtschein**; Deko ohne Licht nur halb und nur direkt an der
Tür. Der Anspruch ist an den Tag gebunden und gedeckelt (4.8).

**Entscheidung (Vorschlag)**
```
Druck(Zone) = Dreistigkeit × Neugier(Zone)
Druck > Abschreckung  → Monster wählt diese Zone als Ziel / kann eindringen
sonst                 → Monster hält sich fern, bleibt diffus im Hintergrund
```
- Die Zone mit dem höchsten Druck wird bevorzugt angesteuert (mit etwas Zufall, damit es nicht vorhersehbar wird).
- Die Wahrscheinlichkeit einer **Manifestation** (Flackern/Rauschen → Erscheinen) wächst mit dem höchsten Druck-Wert.
- Alle Gewichtungen sind Tuning-Parameter → zentral in einer Ressource, damit man sie im Godot-Editor ausbalancieren kann.
- **Debug-Overlay** (nur in Entwicklung): zeigt alle Werte live an.

### 4.10 Sättigung
- Hat das Monster einen Gast geholt, ist es **eine Zeit lang gesättigt**:
  - Dreistigkeit fällt stark ab, Manifestationen werden seltener, es zieht sich in den Hintergrund zurück.
  - Die Sättigung klingt mit der Zeit ab – danach steigt die Dreistigkeit wieder (evtl. schneller als vorher: „Es hat Geschmack gefunden“).
- Für den Spieler entsteht ein **Zeitfenster**: sicherer in dunkle Bereiche, Spinnweben holen, nachts in den Garten …
- Dem Spieler wird die Sättigung nicht angezeigt, aber spürbar gemacht (Stille, Lichter flackern nicht mehr, Gäste wirken erleichtert/geschockt).

### 4.11 Die Aufmerksamkeit des Monsters lenken
Der Spieler kann – bewusst und moralisch fragwürdig – das Monster **auf andere Gäste lenken**. Ideen:

| Methode | Wirkung |
|---------|---------|
| **Deko eines Gastes klauen** | Seine Zone wird schwächer → Neugier ↑ dort |
| **Licht sabotieren** | Lichtschalter seines Raums ausschalten, **Glühbirnen klauen** (7.3), Kerze auspusten → dunkle Zone; geklaute Birnen machen das eigene Zimmer heller |
| ~~**Die Puppe vor seine Tür tragen**~~ | entfällt 2026-10-22 – niemand trägt sie mehr hin; statt dessen ihm die Deko klauen: dann liegt sie vor seiner Tür (5.5) |
| **Lärm machen** | Wecker / Spieluhr / Radio in seinem Zimmer oder Flur abstellen |
| **Gerüchte & Panik säen** | Mit dem Gast über das Monster reden → er gerät in Panik, macht Lärm, versteckt sich auffällig |
| **Ihn in den Keller / Garten schicken** | Per Dialog oder Auftrag in eine dunkle Gefahrenzone locken |
| **Sein Zimmertelefon klingeln lassen** | Klingeln ist Lärm in seinem Zimmer → Neugier ↑ dort (4.14) |
| **Ihn zum Heizkessel schicken** | Bitten, im Tiefkeller Kohle nachzulegen – nahe am Versteck des Monsters (7.4) |

- **Risiko:** Wird man dabei erwischt (von dem Gast selbst oder anderen), **sinkt der Ruf bei allen** massiv. Das kann zu Diebstahl-Rache führen.
- **Schuld:** Stirbt ein Gast, den man selbst „geopfert“ hat, gibt es eigene Folgen (6.8).
- Das schafft die zentrale moralische Spannung: *Opfere ich jemanden, um selbst Ruhe zu haben?*

### 4.12 Sehen & Jagen (entschieden 2026-10-10)
> **Tempo (entschieden und umgesetzt 2026-10-22):** Das Monster **rast** durch die Flure – schon beim Umherstreifen fast
> so schnell wie du rennend, jagend **deutlich schneller** (etwa 7 m/s gegen 4,8). Davonlaufen hilft nicht mehr –
> verstecken, Licht und Deko schon.
**Grundsatz: Wer offen im Flur steht, wenn das Monster kommt, ist in Lebensgefahr.** Das Monster muss einen sehen können.

- **Deko schützt nur, wer drinsteht:** Deko (und Licht) bilden einen Schutzbereich um sich herum (Radius, 5.2; seit 2026-10-21 **ihr sichtbarer Lichtschein**, 5.10). Wer **in diesem Bereich steht**, ist sicher – das Monster bricht die Jagd an dessen Rand ab. Wer **hinter** oder **neben** dem Bereich steht, ist **nicht** geschützt: Das Monster darf den Bereich durchqueren, um ihn zu holen. → Zur Deko flüchten rettet einen, sich hinter ihr verstecken nicht.
- **Kein sicherer Rückzug:** Auch auf dem Rückweg in den Keller nimmt das Monster jeden wahr, den es sieht, und **beginnt die Jagd erneut**. Am Monster vorbeilaufen ist nie sicher.
- **Sichtweite (Tuning-Werte, Vorschlag):**

| Situation | Sichtweite |
|-----------|------------|
| Dunkel | ca. **8 m** (bisher 3 m) |
| Hell | deutlich mehr (ca. 15–20 m) |
| Spieler rennt | + Bonus (Lärm, Bewegung) |
| Spieler duckt sich / steht still | − Abzug |
| Während der Jagd | + Bonus, Sichtkegel entfällt |
| Durch Fenster (7.3) | normal; **Milchglas**: nur Umriss, keine Jagd |

- Verstecken (3.4) bleibt der wichtigste Ausweg: Wer **ungesehen** in ein Versteck kommt, ist vorerst sicher.
- **Kinder und Katzen** sieht es nicht als Beute – es jagt sie nicht (6.11, 6.13).
- **Beobachteter Fehler im Prototyp:** Spieler steht im Flur hinter einer Deko-Zone → das Monster jagt ihn, wird an der Deko „abgewiesen“, zieht sich zurück und läuft dabei durch den Spieler hindurch, ohne ihn anzugreifen. Die drei Regeln oben beheben das. *(umgesetzt)*

### 4.13 Ständige Präsenz (entschieden 2026-10-10)
> Ersetzt die globale Vorwarnung (4.2) und die feste Route (4.3).
> **Im Prototyp umgesetzt (2026-10-11):** Umherstreifen im ganzen Hotel im Wechsel mit Ruhephasen im Keller (anfangs lang, mit jedem Tag kürzer), weicht dem Blick des Spielers aus, Rauschen ab 20 m (am stärksten bei 4 m), Lampen flackern nur in seiner Nähe, Halluzinationen nach einem Todesfall, alle Spuren aus der Tabelle (Fußspuren verblassen, Kratzspuren bleiben, Spuren an Zimmer 13 lassen sich wegwischen), Klopfen in beiden Varianten, Warnungszettel ab dem ersten Angriff, kleine Veränderungen im Hotel, Gäste berichten (nicht immer zuverlässig) von Spuren, Brummen mit dem Rauschen. Spielstände sichern Monster, Spuren und geprüfte Verstecke.
> **Noch nicht:** engerer Blick unter Stress.

**Entschieden**
- **Das Monster patrouilliert im ganzen Hotel** (Flure, Zimmer, Lobby, Küche, Bar, Garten, Keller) und **bleibt dabei oft verborgen**: bewegt sich bevorzugt außerhalb des Blickfelds und im Dunkeln.
- **Langsamer Einstieg:** In den **ersten Minuten bzw. ersten Phasen kommt es nicht**. Anfangs **zieht es sich regelmäßig in den Keller zurück**; die Ruhephasen werden mit der Zeit kürzer (passt zu 4.8).
- **Rauschen nach Entfernung:** Das Rauschen beginnt, wenn das Monster eine bestimmte Distanz zum Spieler unterschreitet, und **wird langsam lauter**, je näher es kommt (Vorschlag: ab ca. 20 m, am stärksten bei ca. 4 m) – auch durch Wände.
- **Halluzination:** Ist ein Gast gestorben (Schock/Trauer, 6.8), kommt das Rauschen **manchmal auch ohne Monster**.
- **Der friedliche Anfang** und die **ersten harmlosen Angriffe**: siehe 2.1.
- **Spuren des Monsters** (entschieden):

| Spur | Was sie verrät |
|------|----------------|
| **Ausgehende Kerzen** (und Kürbisse) auf seinem Weg | wo es gerade vorbeiging |
| **Kratzspuren** an Türen, Wänden, Schränken | dass es *hier* etwas wollte |
| **Fußspuren** (dunkel, nass) | Weg und Richtung |
| **Blutspuren** | dass jemand verletzt oder geholt wurde – am Boden und an der nächsten Wand (Spritzer mit Läufern, umgesetzt 2026-10-20); dazu tauchen als Spuk **blutige Schmierspuren** an Flurwänden auf (eine Hand, die hinuntergerutscht ist), wo man gerade nicht hinsieht |
| **Geprüfte Verstecke** (offene Schranktür) | dass es gesucht hat |
| **Aufgewühlte Betten** | es war im Zimmer, hat unter/im Bett gesucht |
| **Handabdrücke** (an Zimmertüren, auf der Seite, von der es kam) | es stand direkt vor diesem Raum |
| **Warnungszettel** | jemand (früherer Gast?) will warnen – auch Story-Hinweis |
| **Kleidungsstücke** | von Verschwundenen – Andeutung statt Gore |
| **Aschespur** (schwarze Flocken, die noch ein paar Sekunden in der Luft hängen und sinken – 2026-10-20, siehe 7.6) | wo es eben noch war |

- **Klopfen an der Tür – mit Geschrei** (entschieden), in zwei Varianten:
  - **Meistens der echte Gast:** Er klopft panisch und schreit „Mach auf!“, weil das Monster hinter ihm ist. Öffnet man nicht, hört man einen Schrei – danach ist es still.
  - **Manchmal nicht:** Es klopft, man hört eine bekannte Stimme. Öffnet man, ist niemand da – nur ein Kleidungsstück auf dem Boden.
- **Warnungszettel** stammen von **früheren Gästen**, die es nicht hinausgeschafft haben. Sie liegen in verlassenen Zimmern, im Keller, unter Matratzen, geben Tipps zum Monster und deuten den Schlüssel an Halloween an – zugleich der Story-Faden (offene Frage 4).
- **Lampen flackern nur noch lokal** in der Nähe des Monsters: Flackern zeigt, *wo* es ist; Rauschen zeigt, *wie nah*. (Umgesetzt 2026-10-17: Flackerwelle vom Keller aus beim Aufbruch, ihre Dauer verrät die Absicht, 4.17.)
- **Das Poolwasser spürt es (entschieden und umgesetzt 2026-10-19):** gemessen vom Monster zum Wasser, nicht zum
  Spieler. Ab ~30 m legen sich die Wellen, bei 20 m ist das Becken **spiegelglatt**. Ab 20 m (wo das Rauschen
  beginnt) laufen **feine zitternde Ringe** von seiner Seite her übers Wasser, Stoß um Stoß, am stärksten bei 4 m –
  man sieht sie nur in den Spiegelungen. Ist es **in der Halle**, schwappt das Becken unruhig wie eine Badewanne,
  die Kämme brechen zu Schaum, an den Enden spritzt Gischt. Bewusst leise: kein Überlaufen, keine meterhohen
  Wellen – das Monster schleicht, es tobt nicht, und ein tobender Pool wäre ein zu eindeutiges Warnsignal.
- **Spuren:** Fußspuren **verblassen** über einige Minuten (man liest ab, wie frisch sie sind), Kratzspuren **bleiben**. Spuren am eigenen Zimmer kann man wegputzen.
- **Das Hotel verändert sich** (Punkt „unzuverlässiges Hotel“): Kleine Veränderungen, wenn man nicht hinsieht – teils durch das Monster, teils bleibt offen, wer es war.
- **Gäste als Quelle der Angst:** Gäste berichten von Spuren und Geräuschen, nicht immer zuverlässig.
- **Spuren der Gäste (umgesetzt 2026-10-11):** Nicht jede Spur stammt vom Monster. Gäste hinterlassen **schlammige Schuhabdrücke** nach dem Garten (verblassen), **Wachsflecken**, wenn sie etwas Brennendes tragen, **Blutstropfen** nach einem Angriff (sie wurden verletzt) und **verlorene Münzen**, wenn sie in Panik fliehen. Dazu **Zettel**: an manchen Türen von Anfang an („Bitte nicht stören.“), nach einem Todesfall („Klopft dreimal, wenn ihr es seid.“) und manchmal am Ort einer Sichtung. Man muss lernen, Monster- und Gästespuren zu unterscheiden.
- **Regen verwischt (entschieden und umgesetzt 2026-10-23, nachgeschärft 2026-10-24):** Unter freiem Himmel (Garten,
  Kies, Terrasse, Balkon) beginnen **Blutlachen, große Wachsflecken und Kürbismatsch** mit dem ersten Regen langsam zu
  verlaufen – dramatisch, nicht blass: Der Fleck läuft auseinander (fast doppelt so breit), wird dünnflüssig, leuchtender
  und glänzt nass. Zugleich breitet sich von ihm aus langsam ein **Schleier** aus (Blut etwa 7–11 m, Kürbismatsch nur 3–5 m, Wachs bis
  25 m; durchscheinend; mit dem Wind, auf Treppen und Gefälle bergab, nie ins Haus): eine breite Fläche und darüber richtige **Schlieren** in
  Fließrichtung, Blut satt rot. Nach etwa anderthalb Stunden Regen ist der Fleck ganz verlaufen und weg, der Schleier ganz
  da; dann verblasst er (im Regen in etwa 3, im Trockenen in etwa 7 Stunden) und verschwindet. Damit bleiben Spuren
  draußen anders als drinnen **nicht**: Der Regen nimmt Beweise mit, weggewaschenes Blut erschreckt niemanden mehr,
  verlaufener Kürbismatsch lässt sich nicht mehr aufsammeln (5.8). Drinnen und unter Dach ändert sich nichts.
- **Technische Atmosphäre:** mehr Nebel, Lichtkegel statt gleichmäßigen Lichts, Brummen mit dem Rauschen, engerer Blick unter Stress.

**Beobachteter Fehler im Prototyp (behoben 2026-10-11):** Nach einem harmlosen Angriff auf einen Gast jagte das Monster ihn beim Rückzug sofort wieder, oder der Gast kletterte direkt vor ihm zurück ins selbe Versteck. Folge: endloses Erschrecken, und Bruno rief in einem fort „Bleib weg!“. Jetzt gilt: Nach einem harmlosen Schreck verschwindet das Monster, ohne erneut zu jagen; Gäste meiden Verstecke in der Nähe des Monsters (8 m); denselben Panik-Satz sagt ein Gast höchstens alle 45 s.

**Angriffe waren zu kurz (beobachtet 2026-10-13, behoben 2026-10-17)**
- **Beobachtung:** Kaum hatte eine Aktivphase begonnen, kam das Monster nur ein paar Meter aus dem Kellerflur
  und verschwand wieder – auch mit F5 gerufen.
- **Ursache:** (1) Die Deko der Gäste säumt die Flure; ihr Schutzradius (3 m) deckt den ganzen Flur ab. Das
  Monster lauerte deshalb alle paar Meter. (2) Viermal Lauern oder einmal von Deko/Licht zurückgeschreckt
  führte direkt in den Rückzug, und (3) der Rückzug endet sofort, wenn der Spieler weit weg ist. (4) Nach
  einem harmlosen Schreck an einem Gast zog es sich ebenfalls zurück.
- **Jetzt:** Deko und Licht **drängen es ab, statt es nach Hause zu schicken.** Vorbeigehen darf es; abgeschreckt
  wird es nur, wenn sein **Ziel** im Schutz liegt (beim Jagen wie bisher, wenn der Gejagte im Schutz steht).
  Zurückgeschreckt sucht es sich ein anderes Ziel und lässt den Geschützten ~15 s in Ruhe. Nach einem
  harmlosen Schreck schleicht es aus dem Blick und streift weiter; den Erschreckten verschont es bis zur
  nächsten Aktivphase. In den Keller geht es nur noch am Ende der Aktivphase, satt oder vom UV-Licht vertrieben.
- Die **ersten beiden Angriffe bleiben harmlos** (2.1) – auch mit F5 gerufen (seit der Tagesuhr, 2.4: die ersten neun
  Aufbrüche, etwa anderthalb Tage). Erst danach holt es jemanden
  (seit 4.17 nur, wenn es das beim Aufbruch will – mit einer Chance, die von Tag zu Tag steigt).

**Offen**
- Was steht konkret auf den Warnungszetteln (Story)? (Im Prototyp gibt es fünf erste Zettel aus den Jahren 1987–2019, siehe `scripts/world/warning_note.gd`.)

### 4.14 Zimmertelefone (vorgemerkt 2026-10-11)
> **Im Prototyp umgesetzt (2026-10-11):** Telefon in jedem Zimmer (außer Wäscherei), Haupttelefon mit Gästeverzeichnis an der Rezeption (Nummer 0). Anrufe für Zimmer 13: Freunde warnen (nicht immer richtig), Feinde lügen, Bekannte plaudern oder laden zur Feier ein, unheimliche Anrufe (Atmen aus einem leeren Zimmer oder Zimmer 18, Stimme eines Verschwundenen, es steht vor der Tür) – danach liegt dort ein Hörer daneben. Selbst anrufen: plaudern (halbe Beziehung), nach dem Monster fragen, einladen; Klingeln ist Lärm im Zielzimmer; Telefonstreiche sprechen sich herum; in leeren Zimmern nimmt manchmal doch jemand ab. Hörer daneben legen. Ferne Telefone klingeln als Atmosphäre (und Lärm).
> **Noch nicht:** Gäste rufen sich gegenseitig an und verbreiten Gerüchte schneller, Panik-Anrufe ängstlicher Gäste, Telefonzentrale.

**Grundidee:** In jedem Zimmer steht ein altes **Wählscheibentelefon**, an der Rezeption der Hauptapparat mit der Zimmerliste. Das Telefon verbindet das Klopfen (4.13), das Ablenken (4.11) und die Beziehungen zu den Gästen (6.2) – mit wenig neuer Technik.

**Anrufe bekommen**
- **Warnung von Freunden:** Ein Gast mit guter Beziehung ruft an: *„Es ist bei mir im Flur.“* oder *„Geh heute nicht zur Bar.“* Wie oft und wie zuverlässig, hängt von der Beziehung ab; Feinde rufen nie an – oder lügen.
- **Alltägliches:** Einladung zur Feier, Handelsangebot, Bitte um Hilfe („Ich habe kein Licht mehr“).
- **Die unheimliche Variante** (wie die falsche Stimme beim Klopfen):
  - Atmen, dann Stille.
  - Ein Anruf aus einem **unbewohnten Zimmer** oder aus dem abgeschlossenen **Zimmer 18**. Geht man hin, ist niemand da – der Hörer liegt neben dem Apparat.
  - Nach einem Todesfall die **Stimme des Toten** (Halluzination, 6.8).
  - Ganz selten: Es klingelt, während das Monster **direkt vor der Tür** steht.

**Selbst anrufen**
- Zimmernummer an der Wählscheibe wählen (Zifferntasten). Mit Gästen **auf Distanz reden** – sicherer als im dunklen Flur, aber die Beziehung steigt nur halb so stark wie im persönlichen Gespräch.
- **Klingeln ist Lärm im Zielzimmer** → Neugier des Monsters dort ↑ (4.11). Wer immer wieder anruft und auflegt, wird verdächtigt; der Gast erzählt es weiter (Gerücht).
- Über den Hauptapparat an der Rezeption kann man **jedes** Zimmer anrufen – auch unbewohnte, um das Monster dorthin zu locken.

**Der Preis**
- Auch das **eigene** Telefon klingelt laut – im falschen Moment (Versteck, Monster im Flur) verrät es einen.
- **Hörer daneben legen** macht still, aber dann erreicht einen auch keine Warnung mehr.
- Gäste nutzen die Telefone ebenfalls: Gerüchte verbreiten sich schneller, und ängstliche Gäste rufen in Panik herum.
- Der **reparierte Fahrstuhl** hat ein Notruftelefon in der Kabine (7.4), das manchmal klingelt, wenn niemand darin ist.

**Zu klären**
- Funktionieren die Telefone von Anfang an, oder muss erst die Telefonzentrale an der Rezeption eingeschaltet werden?
- Freitext-Gespräche nein – Telefonate nutzen das bestehende Dialogsystem mit eigenen Sätzen.

### 4.15 Lärm & Sichtbarkeit – ein gemeinsames System (entschieden 2026-10-11)
> **Im Prototyp umgesetzt (2026-10-11):** Alle Werte stehen in `scripts/util/senses.gd`. Jedes Geräusch in der Welt läuft über einen Einstieg (`Game.noise`) und ist zugleich Lärm nach der Tabelle unten. Gedämpft wird über Sichtlinien-Strahlen: Wände ×0,4, geschlossene Türen (und klares Glas) ×0,6, je Geschossdecke ×0,3. Das Monster geht in Hörweite nachsehen, bis zur doppelten Hörweite wird es neugierig (0,25 Neugier je Meter Hörweite), ruhend zählt nur Lautes ab 8 m. Gäste hören erschreckende Geräusche (Schrei, aufgerissene Tür oder Schrank, platzende Birne) mit halber Reichweite: Angst steigt, ängstliche verstecken sich in Panik, mutige gehen nachsehen, die anderen erzählen davon („Hast du das gehört?“, nicht immer mit dem richtigen Ort). Gäste in Panik machen beim Rennen Lärm. Sehen: eine Rechnung für Jagd, „beim Verstecken gesehen“ und Zeugen beim Klauen, mit eigenem Licht in der Hand.
> **Abweichungen beim Umsetzen:** Rasen schluckt Schritte wie Teppich. Neu in der Tabelle: Hörer abnehmen, auflegen oder daneben legen (2 m). Schritte von Gästen beim Gehen machen (noch) keinen Lärm, nur Rennen. Das Klopfen-Geschrei lockt das Monster nicht mehr fest an, sondern nur, wenn es in Hörweite ist.
> **Noch nicht:** Untertitel wie „[Die Tür knarrt]“ für leise Geräusche; Gäste ärgern sich über Lärm des Spielers vor ihrer Tür (6.2).

**Grundsatz:** Jede Aktion hat eine **Lautstärke** und jeder Akteur eine **Auffälligkeit**. Spieler, Gäste und Monster benutzen dieselben Werte, und alle Beobachter (Monster *und* Gäste) rechnen gleich – nur mit eigenen Ohren und Augen. Die Werte stehen an **einer** Stelle und werden hier abgestimmt.

#### Lärm
- **Lautstärke = Hörweite in Metern.** Was man hört, ist zugleich Lärm in der Welt: Es gibt kein Geräusch mehr, das nur der Spieler hört (Ausnahme: Menüs, Meldungen, Monster-Stinger).
- **Dämpfung (Vorschlag):** je Wand ×0,4, je geschlossene Tür ×0,6, offene Tür ungedämpft. Durch Decke/Boden zwischen den Geschossen ×0,3.
- **Monster:** Innerhalb der Hörweite geht es nachsehen (wenn es unterwegs ist); bis zur doppelten Hörweite steigt nur die Neugier dort (4.9). Lautes zählt also auch, wenn es ruht.
- **Gäste:** hören mit halber Reichweite. Leises ignorieren sie, Lautes (Schrei, Knall, aufgerissene Tür) erschreckt sie, sie sehen nach oder erzählen davon (Gerüchte, 6.5) – ängstliche Gäste geraten in Panik.
- **Licht aus** (4.4) und **über das Monster reden** (4.7) bleiben eigene Regeln: Das ist kein Geräusch, sondern Einladung bzw. Lauschen.

| Aktion | bisher | Hörweite (Vorschlag) | Anmerkung |
|--------|--------|----------------------|-----------|
| Gehen | – | 0 m (Teppich, Rasen) · 2 m (Holz, Fliesen) | geduckt immer 0 |
| Rennen | 1,0 alle 0,6 s | 10 m | |
| Landen nach Sprung | – | 4 m | |
| Tür öffnen/schließen (Knarren) | – | 5 m | |
| Abgeschlossene Tür rütteln | – | 6 m | |
| Aufschließen (Schlüssel klirren) | – | 3 m | |
| Tür vom Monster aufgerissen | – | 20 m | Gäste erschrecken |
| In ein Versteck gehen (Schranktür) | – | 4 m | |
| Versteck vom Monster aufgerissen | – | 20 m | |
| Gegenstand ablegen | – | 2 m · Kürbis 4 m | |
| Vor Schreck fallen lassen (Schock, 6.8) | – | 6 m | |
| Truhe öffnen | – | 4 m | |
| Schublade aufziehen/zuschieben | – | 3 m | |
| Katze miaut · schnurrt · wirft Deko um | – | 8 m · 1,5 m · 5 m | das Monster überhört Katzen (6.11) |
| Katze weint (Flucht vor dem Monster) | – | 16 m | Gäste werden unruhig; das Monster überhört es |
| Vorhang ziehen | – | 2 m | |
| Glühbirne heraus-/eindrehen | – | 2 m | |
| Glühbirne platzt | – | 8 m | |
| Lichtschalter | – | 1 m | Licht aus zusätzlich nach 4.4 |
| Kürbis ernten · schnitzen | – | 3 m | |
| Spur wegwischen | – | 2 m | |
| Kartenblatt blättern | – | 1 m | |
| Gespräch mit einem Gast | – | 3 m | Lauschen nach 4.7 bleibt |
| Nach Luft schnappen (Luft zu lange angehalten) | 1,5 einmal | 10 m | |
| Atmen im Versteck | Sonderregel | – | bleibt: angehaltener Atem senkt die Chance, entdeckt zu werden (×0,35) |
| Keuchen außer Atem (3.1) | – | 4 m alle 1,5 s | im Versteck zudem ×1,8 Chance, entdeckt zu werden (beim Umsetzen ergänzt) |
| Klopfen an eine Tür | – | 8 m | |
| Telefon klingelt | 0,8 je Klingeln | 18 m | 4.14 |
| Hörer abnehmen, auflegen, daneben legen | – | 2 m | (beim Umsetzen ergänzt) |
| Würfeln, Spiel am Tisch | 0,7 | 10 m | |
| Feier mit Musik | 1,5 | 25 m | |
| Gast schreit | – | 20 m | |

#### Sichtbarkeit
- **Sichtweite = Grundweite des Beobachters × Auffälligkeit des Gesehenen**, danach Sichtkegel und freie Sichtlinie.
- **Auffälligkeit** (Faktor, 1,0 = steht normal im Dunkeln):

| Einfluss | Faktor (Vorschlag) | Anmerkung |
|----------|--------------------|-----------|
| Licht am Ort | 1,0 (dunkel) … 2,2 (hell) | entspricht heute 8 m → 18 m beim Monster |
| Eigenes Licht in der Hand | Kerze +0,6 · Kürbislaterne +0,8 · Taschenlampe +0,9 · UV +1,2 | **neu:** wer Licht trägt, wird gesehen (Taschenlampe: 4.16) |
| Rennen | +0,4 | heute +3 m |
| Gehen | ±0 | |
| Stillstehen | −0,1 | heute −1 m |
| Ducken | −0,25 | heute −2 m |
| Karte oder Kompass vor dem Gesicht | ±0 | leuchten zu schwach |
| Im Versteck | unsichtbar | gesehen wird nur das Hineingehen |

- **Beobachter:**

| Beobachter | Grundweite | Sichtkegel | Besonderheiten |
|------------|-----------|------------|----------------|
| Monster | 8 m | ca. 145° | während der Jagd +5 m und kein Kegel (4.12) |
| Gast | 5 m (heute fest 10 m) | 180° | abgelenkt (Gespräch, Würfeln, Panik) ×0,6 |

- **Gilt überall gleich:** Jagd beginnen, „beim Verstecken gesehen“ (heute fest 16 m) und Zeugen beim Klauen (heute fest 10 m) nutzen dieselbe Rechnung. → Im Dunkeln und geduckt klaut man unbemerkter; wer mit Kerze in den Schrank steigt, wird gesehen.
- Was der **Spieler** sieht (Verschwinden aus dem Blickfeld, 4.13), bleibt der Kamera-Ausschnitt.

**Folgen fürs Spiel:** Türen, Schränke und Truhen werden zu Entscheidungen (leise und langsam oder schnell und laut). Licht in der Hand schützt nicht nur, es verrät auch. Gäste reagieren auf das, was im Hotel passiert, statt nur auf Gespräche.

**Entschieden beim Umsetzen (2026-10-11)**
- Dämpfungswerte wie vorgeschlagen; Gehen auf Holz und Fliesen macht 2 m Lärm.
- Gäste reagieren auf erschreckenden Lärm mit Gerüchten **und** gehen nachsehen (die mutigen) – sie können dabei selbst in Gefahr geraten.

**Zu klären**
- Ob der Spieler sieht, wie laut er gerade ist (kein HUD – vielleicht nur über Untertitel wie „[Die Tür knarrt]“).
- Die Dämpfung im Spiel nachhören: Reicht ×0,4 je Wand, oder hört man Zimmer nebenan zu gut bzw. zu schlecht?

### 4.16 Taschenlampe & UV-Licht (entschieden 2026-10-11)
> **Im Prototyp umgesetzt (2026-10-11):** Taschenlampe an der Rezeption (halb leer), Batterien in Wäscherei, Keller und einigen unbewohnten Zimmern sowie bei Skeptikern im Handel, UV-Aufsatz in Zimmer 18. Werte in `scripts/world/flashlight.gd` und oben im `MonsterDirector`.

**Grundsatz:** Die Taschenlampe ist Licht zum **Sehen**, kein Schutz. Erst der UV-Aufsatz macht sie zur Notwehr – teuer und mit Folgen. Deko und Verstecken bleiben der eigentliche Schutz (4.12, 3.4).

- **Eine Lampe, zwei Modi:** Man findet früh eine normale Taschenlampe. Der **UV-Aufsatz** ist ein **späterer Fund** (Zimmer 18, Schlüssel im Keller – „Wagnis“ nach 2.3). Danach schaltet man um.
- **Gegenstand in der Hand** (3.2), nicht am Körper: Mit Lampe trägt man keinen Kürbis. [Linksklick] an/aus, [R] normal ↔ UV.
- **Batterien** sind kleine Gegenstände. Batterie in der Hand + Lampe (oder umgekehrt) → einlegen, wie die Kerze in den Kürbis. Eine Batterie reicht für ~~**einen Ingame-Tag normales Licht**~~ **5 Minuten normales Licht** (etwa einen Abend, 2.4) – oder für **etwa 9 Sekunden UV**. Skeptiker handeln damit.
- **Kein Schutzbereich:** Die Lampe zählt nicht als Licht für die Abschreckung (4.9) – sonst wäre sie eine helle Zone zum Mitnehmen.
- **Verrät einen** (4.15): Auffälligkeit normal **+0,9**, UV **+1,2** (Kerze +0,6).
- **Flackert in der Nähe des Monsters** wie die Wandlampen; bei schwacher Batterie wird sie dunkel und unruhig.
- **Im Versteck bleibt sie aus** – sie geht beim Hineinsteigen aus und lässt sich drinnen nicht einschalten.

**UV gegen das Monster**
- Steht es nah genug (≤ 6 m) etwa **1 Sekunde** mitten im UV-Kegel, zuckt es zurück, kreischt und **flieht in den Keller**. Im Kegel wird es langsamer. Auf der Flucht jagt es niemanden.
- **Der Preis:** Es **weiß, wer es war** – Dreistigkeit +6, Neugier rund um Zimmer 13 +40 (wie „bemerkt“, 4.5). Es **ruht danach nur kurz** (Ruhephase ×0,4). Und es **gewöhnt sich daran** (4.8): Jedes weitere Mal muss es 0,5 s länger im Kegel stehen (höchstens 3,5 s) – irgendwann reicht eine Batterie nicht mehr.
- Nicht, wenn es schon zupackt (Jumpscare) oder sich ohnehin zurückzieht.

**UV zeigt Verborgenes**
- **Fußspuren des Monsters** leuchten unter UV noch lange, nachdem sie für das Auge verblasst sind (~~drei Ingame-Tage~~ 15 Spielstunden, 2.4).
- **Schrift an Wänden**, nur unter UV: in Zimmer 13 („Du warst schon einmal hier“ – Andeutung zur Zeitschleife, 2.2), in Zimmer 17 (E. K. hat es geblendet), im Keller (1987, der Heizer), in Zimmer 18 („Nur einer kommt hinaus“).
- **Jeder Warnungszettel** hat eine unsichtbare zweite Zeile, die man nur mit eingeschaltetem UV-Licht liest – Hinweise auf das Abkommen und den Heizer (2.3).
- **Warum UV?** Bewusst offen. Gäste und Zettel deuten an, dass es „dieses Licht hasst“ – eine Erklärung im Geheimnis (2.3) ist möglich, aber nicht nötig.

**Zu klären**
- Gäste mit eigener Taschenlampe (Bitte „Ich habe kein Licht mehr“, „Ich brauche Batterien“, 4.14/6.4)?
- Zeigt UV später auch weggewischte Spuren an Zimmer 13?

### 4.17 Angriffsabsicht & Flacker-Signal (entschieden 2026-10-17)
> Ergänzt 4.13, ersetzt sie nicht: Das lokale Flackern bleibt.
> **Im Prototyp umgesetzt (2026-10-17):** drei Absichten mit Flackerwelle vom Keller aus (über das
> Treppenhaus ins Obergeschoss), Täuschung, Opferzahl nach 1/n² (Spieler zählt mit), Flackern 1 + 2 × n Sekunden, Umsehen wird
> bei Sichtung oder Gerede zum Angriff, Gäste verstecken sich bei langem Flackern, Halluzination mit
> langem Flackern, Tagebuch gesperrt, Würfelpartie bricht ab, Sirren im Stromnetz und Untertitel,
> Hinweise bei Edna, Mila und auf dem Zettel von 1994. Werte oben im `MonsterDirector`.

**Grundidee:** Bricht das Monster aus dem Keller auf, **läuft eine Flackerwelle durchs Haus**. Wie lange die
Lichter flackern, verrät, **was es vorhat**. Kurzes Zucken: Es will sich umsehen, höchstens einen holen. Langes Flackern: Es hat
Hunger und wird mehrere holen.

**Warum das gut passt**
- Bisher kommt jede Aktivphase gleich: lautlos aus dem Keller, erst das Rauschen verrät es. Damit wird aus dem
  Flackern eine **Information, auf die man reagieren kann**: weitermachen oder sofort in Sicherheit. Das ist genau
  der Kern-Loop „Ankündigung erkennen, rechtzeitig in Sicherheit gehen“ (3).
- Die drei Signale ergänzen sich: **Flackerwelle = wie schlimm**, lokales Flackern = **wo**, Rauschen =
  **wie nah** (4.13).
- Die versteckten Werte (4.9) werden spürbar, ohne dass man sie anzeigt.

**Drei Absichten** (gewählt beim Aufbruch, Werte als Vorschlag)

| Absicht | Was es will | Flackern beim Aufbruch |
|---------|-------------|------------------------|
| **Umsehen** | streift umher, hinterlässt Spuren, spukt (Türen, Betten …), holt niemanden | ein kurzes Zucken (1 s) |
| **Einen holen** | wie heute: holt einen (Gast oder Spieler), danach satt (4.10) | 3 s |
| **Raubzug** | holt **n Opfer** (ab zwei); nach jedem Opfer gleich weiter, erst das letzte macht satt, bleibt länger draußen | 1 + 2 × n Sekunden (zwei: 5 s, drei: 7 s, vier: 9 s …), heftig, einzelne Lampen fallen kurz ganz aus |

- **Wie viele Opfer** (entschieden 2026-10-17, ersetzt „höchstens zwei bis drei“): Greift es an, will es
  **n Opfer mit Wahrscheinlichkeit ∝ 1/n²**, normiert. Etwa **61 % eins, 15 % zwei, 7 % drei, 4 % vier** …;
  höchstens so viele, wie Gäste leben, plus den Spieler. Kein fester Deckel – sehr große Raubzüge sind selten,
  aber möglich.
- **Flackerdauer** (entschieden 2026-10-17): **Sekunden = 1 + 2 × n** (n = angezeigte Opfer, Umsehen n = 0).

- **Was die Absicht bestimmt:** Satt → nur umsehen. Sonst greift es mit einer **Chance an, die von Tag zu Tag
  steigt** (entschieden 2026-10-17), gleitend zwischen diesen Punkten, beim Angriff die Opferzahl wie oben:

  | Tag | bis 4 | 7 | 10 | 20 | ab 30 |
  |-----|-------|---|----|----|-------|
  | will mindestens einen holen | 20 % | 50 % | 75 % | 90 % | 95 % |
  | **seit der Tagesuhr (2.4), je Aufbruch** | 4 % | 10 % | 16 % | 19 % | 20 % |

  Seit 2026-10-23 bricht es etwa sechsmal am Tag auf statt gut einmal – je Tag greift es damit etwa so oft an wie
  zuvor nach der oberen Zeile.

  Gedeckelt bei 95 %, damit ein kurzes Zucken auch an Halloween nicht immer gelogen ist. Die ersten Tage bleiben
  ohne Monster, die ersten beiden Angriffe harmlos (2.1) – die Kurve gilt danach. **Vom UV-Licht vertrieben** (4.16) → beim nächsten Aufbruch mindestens zwei:
  Es kommt wütend zurück. Bei den harmlosen Angriffen (2.1) wird gewürfelt und geflackert, geholt wird niemand.
- **Unscharf, nicht ablesbar:** Die Dauer schwankt etwas. Wer genau hinsieht, unterscheidet kurz und lang, aber
  „3 Opfer“ lässt sich nicht abzählen.
- **Es täuscht manchmal** (entschieden): Selten zuckt das Licht nur kurz, obwohl es einen holen will oder auf
  Raubzug geht. Je dreister es ist, desto öfter (Vorschlag: höchstens jedes fünfte Mal, nie bei den harmlosen
  Angriffen). Umgekehrt flackert es nach einem Todesfall manchmal lang, ohne dass etwas kommt (Halluzination,
  siehe unten). Auf ein kurzes Zucken ist also nie ganz Verlass.
- **Als Welle vom Keller nach oben** (entschieden): Zuerst flackern die Kellerlampen, dann das Erdgeschoss vom
  Kellerabgang aus, zuletzt das Obergeschoss über das Treppenhaus (Vorschlag: etwa 15 m pro Sekunde, jede Lampe
  flackert die volle Dauer). Man sieht, dass es *jetzt* aufbricht, und wer weit weg wohnt, hat ein paar Sekunden
  mehr.
- **Die Absicht kann sich ändern:** Lärm, Sichtungen und Gespräche über das Monster (4.7) können aus „Umsehen“
  einen Angriff machen. Die Lichter flackern dann noch einmal.
- **Die Absicht gilt auch für den Spieler** (entschieden): Der Spieler zählt wie ein Gast.
  - **Umsehen:** Es jagt dich trotzdem (4.12). ~~Erwischt es dich, starrt es dich an und verschwindet wie bei den
    harmlosen Angriffen (2.1).~~ **Erwischt es dich, stirbst du – immer** (entschieden 2026-10-22, auch bei den ersten,
    für Gäste harmlosen Angriffen). Harmlos bleiben die nur für die Gäste.
  - **Einen holen:** Du kannst der eine sein.
  - **Raubzug:** Du bist eines der n Opfer.
  - Weil es manchmal täuscht, ist ein kurzes Zucken trotzdem keine Garantie.

**Drumherum**
- **Gäste reagieren:** Bei langem Flackern verstecken sich die Ängstlichen sofort (Edna), Mutige ignorieren das
  kurze Zucken. Ein Raubzug trifft also vor allem die Unvorsichtigen (entschieden 2026-10-19: Es sucht nicht
  gezielt nach Opfern – wer sich beim Flackern versteckt, bleibt geschützt; etwa jede zweite Aktivphase mit
  Absicht endet deshalb ohne Opfer). Gäste sprechen darüber („Wenn es lange
  flackert, geh nicht raus.“), ebenso ein Warnungszettel. So lernt der Spieler das Signal.
- **Die ersten harmlosen Angriffe** (2.1) zeigen das Signal schon. Man lernt es kennen, bevor es ernst wird.
  Der erste Angriff während der Feier behält seinen eigenen Auftakt (Licht aus, Musik aus).
- **Halluzinationen** (4.13, 6.8): Nach einem Todesfall flackert es manchmal lang, ohne dass etwas kommt.
- **Konzentration** (6.10): Beim Würfeln sieht man das Flackern nur halb so stark. Langes Flackern bricht die
  Partie ab, wie die Vorwarnung.
- **Tagebuch** (8.5): Während des Flackerns gesperrt.
- **Barrierefreiheit** (8.4): Wer das Flackern abschwächt, braucht ein zweites Signal mit derselben Dauer: Die
  Glühbirnen sirren und das Stromnetz knistert. Dazu kommt ein Untertitel („Die Lichter flackern lange.“).
- **Satt:** Nach einem Opfer flackert beim nächsten Aufbruch nichts oder fast nichts (4.10: „Lichter flackern
  nicht mehr“).

**Technik (Skizze):** `MonsterDirector._start_activity` wählt die Absicht und startet die Flackerwelle für
die passende Dauer (alle `lamps`, verzögert nach Abstand zum Kellerabgang, dazu Bild-Flackern). Wie viele Gäste es in dieser Phase schon geholt hat, zählt
`kill_guest` bzw. `kill_player` mit. Die Sättigung je Opfer hängt von der Absicht ab. Absicht und Zähler kommen in den Spielstand
des Directors. Die Zuordnung fester Weltobjekte ändert sich nicht.

**Entschieden (2026-10-17):** Absicht gilt auch für den Spieler · das Signal täuscht manchmal · höchstens zwei
bis drei Opfer pro Raubzug · Flackern als Welle vom Keller nach oben. Später am selben Tag geändert: Opferzahl
nach 1/n² ohne festen Deckel, Flackern 1 + 2 × n Sekunden.

**Mit der Puppe (2026-10-22, 5.5):** Vor jedem echten Angriff (einen holen, Raubzug) liegt 1–2 Minuten vorher die Puppe
vor der schwächsten bewohnten Tür, und ein Grollen schwillt im ganzen Hotel an. Beim Aufbruch läuft die Flackerwelle
wie bisher. Das Monster geht dann nicht mehr ziellos umher, sondern zur Puppentür und greift unterwegs bis zu fünf
schwache bewohnte Türen an, solange es noch hungrig ist. Die Opferzahl gilt für diese Türen unterwegs; das
Puppenzimmer kommt immer dazu. Beim Umsehen bleibt alles wie oben.

**Noch offen:** genaue Tuning-Werte (Täuschungsrate, Angriffschance je Tag, ob die Opferzahl doch einen Deckel
braucht), beim Ausprobieren festlegen.

### 4.18 Der Lakengeist am Fenster (entschieden 2026-10-17)
> **Garantien (entschieden und umgesetzt 2026-10-22):** War er bis **Tag 10** noch nie beim Spieler, kommt er ab dann
> sicher **im Flur**, sobald der Spieler dort allein ist – als **Warnung**: Er schwebt heran und verschwindet kurz vor
> ihm. War er an **Tag 20** noch keine **drei Mal** da, holt er auf: Jeder dunkle Raum mit Fenster ruft ihn sicher, und
> nach nur wenigen Sekunden kommt er wieder – **mehrmals hintereinander beim Betreten**, auch mehr als dreimal (am
> Tag 20 den ganzen Tag). Alle diese Besuche zählen für seine Stufen.
> **Im Prototyp umgesetzt (2026-10-17):** Erscheinen bei Licht aus und offenem Vorhang (70 % beim Betreten,
> danach 90 s Pause), Stufen 1–4 inklusive Handabdrücken auf der Scheibe, Hypnose (langsamer, Blickzug), Hereinkommen
> (ab dem 4. Mal durch den Vorhang), Würgen mit Losreißen (drei Richtungswechsel in 1,5 s) oder Tod, Zeugen
> (ein wacher Gast mit Sicht) vertreiben ihn, Ausblenden in 0,5 s. Erst nach dem ersten Angriff des Monsters,
> nicht während das Monster nah ist. Debug: F6 und `--ghost=n`.
> **Später am Tag umgesetzt:** **Nachtruhe zu zufälligen Zeiten** (seit 2026-10-21 entschieden, seit 2026-10-23 umgesetzt: feste Zeit
> mit Streuung, 23–6 Uhr ± ½ h, nur für die Gäste, 2.4) (~~alle 4–9 min für 70–140 s~~ jede Nacht etwa 7 min: alle Gäste im
> eigenen Bett, Licht aus; schlafende Gäste sind keine Zeugen und bemerken nichts) und der Geist **im Flur** ab
> dem 6. Mal, wenn alle schlafen. Außerdem sind die Zimmerfenster jetzt **breiter und deutlich höher**
> (1,9 m breit, 0,75–3,05 m statt 1,4 m breit, 0,9–2,3 m).
> **Gäste als Opfer (entschieden und umgesetzt 2026-10-18):** Er behandelt Gäste wie den Spieler, mit eigenem
> Zähler je Gast; Erwürgte bleiben als Leiche liegen – siehe 6.12.
> **Gefährlicher und hartnäckiger (entschieden und umgesetzt 2026-10-18):**
> - **Losreißen ist die seltene Ausnahme:** Ein Balken füllt sich mit jedem Richtungswechsel, der Griff zieht ihn
>   ständig zurück; in 3 s schafft man es erst mit etwa 6–7 Wechseln je Sekunde, ab dem 4. Mal greift er noch fester zu.
>   Gäste reißen sich nur noch mit 5 % + 20 % × Mut los.
> - **Verstecken im Schrank:** Er verschwindet nicht, sondern wartet **20–35 s vor den Schranktüren** (rüttelt,
>   flüstert). Wer herauskommt, wird sofort gepackt. Danach fliegt er mit **40 %** (ab dem 6. Mal **75 %**, +10 % je
>   Nacht ohne Schlaf) **hinein** und würgt im Schrank – sonst gibt er auf. Luft anhalten senkt die Chance (bis zur
>   Hälfte), Keuchen verrät einen sofort. Zeugen vertreiben ihn auch hier. Nur ab dem 3. Mal (wenn er ohnehin
>   hereinkäme) und nur am Schrank – unterm Bett verschwindet er wie bisher.
> - **Schlafen:** Der Spieler schläft **während der Nachtruhe im eigenen Bett** (Zimmer 13; geduckt kriecht man
>   darunter). Augen zu, die Zeit läuft fünfmal so schnell bis zum Ende der Nachtruhe. Das Monster kann einen im
>   Bett finden; ist es nah oder gibt es ein lautes Geräusch, wacht man auf. Eine **Nacht** ist eine Nachtruhe.
> - **Schlafmangel:** Endet eine Nachtruhe ohne Schlaf (nach dem ersten Angriff), zählt eine Nacht ohne Schlaf.
>   Je Nacht kommt er häufiger (+10 % am Fenster, kürzere Pause, öfter im Flur), ab **2** Nächten auch vor dem
>   6. Mal im Flur, ab **3** Nächten **sicher im Flur**, sobald man dort allein ist – auch ohne Nachtruhe. Zeugen
>   vertreiben ihn weiterhin. Schlafen setzt den Zähler zurück. Debug: `--awake=n`, `--ghost=schrank`, `--sleep=bett`.
> - **Früher, häufiger, schneller (2026-10-18):** Er spukt ~~**ab Tag 2**~~ (seit 2026-10-21 erst nach dem ersten
>   Angriff, 4.20) (oder schon nach dem ersten Angriff, falls
>   früher). Die Licht-aus-Falle bleibt: Wer im dunklen Raum mit offenem Vorhang **bleibt**, für den wird alle **6 s**
>   neu gewürfelt (**25 %**, beim Betreten weiter 70 %). Pause nach einem Besuch **45 s** statt 90 s, er schwebt
>   schneller heran (1,6 statt 1,1 m/s) und kommt schneller herein (1,1 statt 0,8 m/s). Gilt auch für Gäste.
> **Fenstertüren (entschieden und umgesetzt 2026-10-22):** Er kommt auch an Fenstertüren nach draußen (Terrasse,
> Garten, Balkon) – gerade dort sehr wahrscheinlich: Sie haben keinen Vorhang, es reicht Licht aus. **90 %** beim
> Betreten, **40 %** alle 6 s beim Bleiben (statt 70 % / 25 %). Er schwebt über dem Boden davor heran, ab dem 2. Mal
> Handabdrücke auf der Scheibe, ab dem 3. Mal **öffnet er die Tür lautlos** und kommt herein. Gilt auch für Gäste.
> **Noch nicht:** Einstellung für den Blickzug. Modell: `temp/Meshy_AI_floating_ghost_3d_…glb` – Laken mit Mundloch, ~1,9 m, zwei
> blutige Hände nach vorn gestreckt. **Gerigget (2026-10-17):** `tools/build_ghost.py` → `assets/models/ghost.glb`
> (0,8 MB, 512er-Textur, alle 10 159 Dreiecke behalten, damit die Finger heil bleiben) mit Saum, Rumpf, Kopf,
> Armen und je fünf Fingern à drei Gliedern. Schweben, Handkreisen und Würgen macht später der Code.

**Grundidee:** Ein Lakengeist schwebt draußen vor den Außenfenstern heran. Er kommt nur, wenn man es ihm leicht
macht: **Licht aus und Vorhang offen**. Mit jedem Erscheinen wird er dreister – vom Blick durchs Glas bis zum
Würgen im Zimmer.

**Wann er kommt**
- Man betritt einen Raum mit Außenfenster (oder ist darin), **das Licht ist aus und der Vorhang offen** → er kommt
  **sehr wahrscheinlich**. Ist eins davon nicht erfüllt, kommt er nicht.
- Er taucht weit draußen im Dunkeln auf und schwebt auf **Fensterhöhe** heran – im Obergeschoss also frei über
  dem Garten.
- Milchglas (falls es wieder Milchglasfenster gibt): nur ein Umriss, keine Hypnose (wie 4.12).

**Er wird von Mal zu Mal dreister** (Zähler über das ganze Spiel)

| Mal | Was passiert |
|-----|--------------|
| **1.** | Er schwebt kurz auf das Fenster zu – und ist wieder weg. |
| **2.** | Er fasst das Fenster an: **blutige Handabdrücke** auf der Scheibe (bleiben als Spur). Ab hier (2./3. Mal) **kreist er mit den Händen**, um dich zu hypnotisieren. |
| **3.** | Ist der Vorhang offen, **kommt er herein** (durch die Scheibe). |
| **4.** und danach | Er kommt **sicher** herein – **auch bei zugezogenem Vorhang**. |

**Hypnose** (ab dem 2./3. Mal): Solange du ihn ansiehst, während er die Hände kreisen lässt, wirst du
**langsamer**, und dein Blick wird sanft zu ihm gezogen. Wegsehen lässt die Hypnose wieder abklingen.
Der Blickzug bekommt eine Einstellung zum Abschwächen (wie das Flackern, 8.4).

**Im Zimmer: Er versucht, dich zu erwürgen.**
- Er schwebt auf dich zu und greift nach deinem Hals.
- **Befreien:** Nur wer sich **wild hin und her bewegt**, reißt sich los – und hat dafür **3 Sekunden**, gegen
  einen Griff, der ständig zurückzieht (2026-10-18; vorher 1,5 s und drei Wechsel). Schafft man es nicht,
  **stirbt man** (Sterbebildschirm wie beim Monster, 4.6).
- **Er verschwindet, wenn mindestens ein bis zwei weitere Gäste zu sehen sind** – Zeugen vertreiben ihn.
  Allein im dunklen Zimmer ist man ihm ausgeliefert; in Gesellschaft ist man sicher. Das stärkt die Gäste
  (Kapitel 6): Wer Freunde hat, die mit ins Zimmer kommen, hat weniger zu fürchten.
- **Verschwinden:** Er wird in **0,5 Sekunden durchsichtig** und ist weg – immer so, ob vertrieben oder am Ende
  eines kurzen Auftritts (1. Mal).
- **Man hört ihn** (entschieden 2026-10-19): Solange er da ist, verrät ihn ein geisterhafter Klang
  (`assets/sound/ghost_ambience.mp3`) aus seiner Richtung – er schwillt mit seinem Erscheinen an und verklingt,
  wenn er verschwindet. Auch wer gerade nicht zum Fenster sieht oder im Schrank sitzt, weiß: Er ist hier.

**Später auch im Flur** (ab dem **6.–7. Mal**): Wenn **alle Gäste schlafen**, taucht er wahrscheinlicher
**im Flur** auf statt nur vor Fenstern. Dann gibt es keine Zeugen, die ihn vertreiben – der nächtliche Flur wird
zum gefährlichsten Ort.
- **Nachtruhe** (entschieden 2026-10-17; seit 2026-10-21 zu **fester Zeit** mit Streuung, 2.4, umgesetzt 2026-10-23): ~~zu **zufälligen Zeiten**~~ gehen alle Gäste schlafen – ins eigene Zimmer,
  Licht aus, ins Bett. Schlafende zählen nicht als Zeugen und bemerken nichts (auch nicht das Monster, das sie
  im Bett finden kann). Danach wachen alle wieder auf.

**Die Geisterstunde (entschieden und umgesetzt 2026-10-23)**
> **Umgesetzt (2026-10-23)** wie unten, mit den beiden Vorschlägen (kaum sichtbar, ab der 4. Begegnung würgt er) und der
> Glocke aus 7.8. Er geht im Obergeschoss um; in der Stunde kommt er nicht zu Türen mit Lakengespenstern und nicht zu
> Gästen an Fenstern – wer dort gerade Besuch hat, den verlässt er, wenn die Glocke ausgeschlagen hat. Debug:
> `--ghost=stunde[,n]`.

Von **0 bis 1 Uhr** (2.4) zieht er durch die **Flure**, jede Nacht – wie alles von ihm erst nach dem ersten Angriff
(4.20). Er sucht niemanden gezielt, er patrouilliert.
- **Ankündigung:** die **Kirchturmglocke**, die zur Mitternacht zwölfmal schlägt (7.8). Danach Flocken und
  Geisterklang in den Fluren.
- **Kurz und heftig:** Die Stunde dauert eine Minute Echtzeit (im Bett, fünfmal so schnell, 12 s) – ein Moment,
  kein Abschnitt der Nacht. Genug für ein, zwei Durchgänge durch einen Flur.
- **Versteckt** (Vorschlag): Bis er einen bemerkt, ist er kaum zu sehen – nur leiser Geisterklang und Flocken. Er
  sieht nach 4.15 (`Senses.can_see`): Ducken und Dunkel helfen, man kann ihm bewusst ausweichen.
- **Hat er dich gesehen,** schwebt er auf dich zu. Die **ersten Begegnungen** in der Geisterstunde sind eine Warnung:
  Er verschwindet kurz vor dir (wie die Garantie an Tag 10). Danach – Vorschlag: **ab der 4. Begegnung** – kann er
  **würgen** (Losreißen wie im Zimmer). Dafür zählt ein **eigener Zähler** für Begegnungen in der Geisterstunde;
  seine Stufen am Fenster (Tabelle oben) bleiben davon unberührt.
- **Nur Flure, keine Zimmer:** In den Zimmern gilt weiter die Regel am Fenster. Wer um 0 Uhr mit Licht im Zimmer
  ist, ist sicher – man kann rechtzeitig drinnen sein oder die Minute bewusst riskieren.
- **Die anderen Flur-Regeln bleiben** (ab dem 6. Mal, Schwäche, Nächte ohne Schlaf, Tag 10) und wirken in der
  Geisterstunde mit: Greift eine davon, dreht sich der umherziehende Geist zu einem um.
- **Zeugen** vertreiben ihn wie sonst; um 0 Uhr schlafen fast alle. Die Bar schließt um Mitternacht (5.9) –
  angetrunkene Gäste auf dem Heimweg sind schwach und mitten in der Geisterstunde unterwegs. Ab dem 25. stehen
  Bettlaken-Kostüme im Flur (5.9).
- **Ebenen** (4.20): Er nimmt das Obergeschoss, ist dort schon eine andere Bedrohung, das Erdgeschoss. Solange im Code
  noch „nur eine Bedrohung im Haus“ gilt (4.1): Ist das Monster um 0 Uhr unterwegs, beginnt die Geisterstunde erst, wenn
  es wieder ruht (oder fällt aus); läuft sie, verschiebt das Monster seinen Aufbruch.

**Passt zu den bestehenden Systemen**
- **Licht aus** lockt schon das Monster an (4.4) – jetzt auch den Geist. Licht an schützt vor beidem.
- **Vorhang zu** hält den Geist draußen, macht den Raum aber dunkler (weniger Mondlicht).
- **Handabdrücke** gibt es schon an Türen (`Traces`); neu ist die Scheibe als Untergrund.

**Er sucht die Schwachen (entschieden 2026-10-19)**
Der Geist achtet darauf, wer **schwach und ängstlich** ist. Spieler und Gäste haben dafür einen versteckten Wert
**Schwäche**, in den alles einfließt, was angreifbar macht: **Angst bzw. Schock**, **Trauer** nach einem Todesfall
(6.8), **Müdigkeit** (3.6), **Rausch** (3.7) und bei **Kindern** ein hoher Grundwert (6.13).
- Je schwächer jemand ist, desto **öfter kommt er** zu ihm.
- Ab einer **Schwelle** kommt er auch **in den Flur**, sobald man dort allein ist – egal ob man übermüdet,
  betrunken oder verängstigt ist.
- So gilt für Müdigkeit, Alkohol, Trauer und Kinder **eine** Regel statt vieler Sonderfälle.
- **Umgesetzt (2026-10-19):** Schwäche 0–1. Spieler: je Nacht ohne Schlaf ⅓, Rausch (betrunken, ab dem 3. Glas, allein schon ganz schwach), halber Schock,
  frische Trauer bis 0,3, Kater 0,2. Gäste: Angst × 0,6 plus Rausch. Volle Schwäche bringt bis zu +30 % Chance und
  eine viermal kürzere Pause; ab **⅔** kommt er auch vor dem 6. Mal in den Flur, ab **1** sicher, sobald man dort
  allein ist. Zwei bzw. drei Nächte ohne Schlaf wirken damit wie bisher; nach drei Gläsern kommt er etwa eine Minute lang sicher
  in den Flur, nach zwei auch früher, wenn alle schlafen.

**Zu klären**
- ~~**Herkunft:** Eigenes Wesen, einer der Verschwundenen (mit jedem geholten Gast häufiger?) oder Teil des
  Monsters? Bisher kennt das Konzept *ein* Monster, und die Geschichte (2.3) hängt daran.~~ Die Verschwundenen – mit
  jedem geholten Gast häufiger (4.20, 2026-10-21).
- ~~**Befreien genau:** Wie viel Hin-und-Her reicht?~~ Balken gegen den Griff (2026-10-18). Hilft UV-Licht?
- **Wie viele Zeugen genau:** einer oder zwei? Reicht es, dass sie im Raum sind, oder müssen sie ihn sehen?
- ~~**Gäste:** Kommt er auch zu Gästen, die bei sich das Licht aus und den Vorhang offen haben?~~ Ja, wie zum Spieler (2026-10-18, 6.12).
- **Zähler:** gilt er für das ganze Hotel oder pro Zimmer? Wird er zurückgesetzt?
- ~~**Wechselwirkung mit dem Monster:** Darf der Geist kommen, während das Monster unterwegs ist?~~ Ja, auf einer
  anderen Ebene und außer Hörweite (4.20, 2026-10-21).

### 4.19 Der Kürbismann (entschieden und umgesetzt 2026-10-20)
> **Im Prototyp umgesetzt (2026-10-20):** Auslöser, Jagd, Schlag mit dem Beil in der rechten Hand (Mixamo „Standing
> Melee Attack Downward“), Leichen in einer Blutlache, Schreck und Erlebnisse der Gäste; seit 2026-10-21 die Ankunft
> übers Lobbydach mit Sprung in den Garten und Suche in der Lobby. Debug: F9 bzw. `--pumpkin=dach`,
> `--pumpkin=jagd[,gast]`, `--pumpkin=garten`.
> **Noch nicht:** eigene Geräusche, die Vorgeschichte als Fundstück im Spiel, eigene Kletter- und Landeanimation.

**Vorgeschichte:** Der Kürbismann („Pumpkinhead“) war der **Rezeptionist** des Hotels. An einem Halloween klopften zwei Kinder zu
**Süßes oder Saures** an seine Tür, und er gab ihnen nichts. Da holten die Kinder **seine Axt**, köpften ihn und
setzten ihm **als Streich einen Kürbis** auf. Seitdem jagt er alle, die Spaß haben.

**Eine dritte Bedrohung mit eigener Regel:** Das Monster kommt aus der Dunkelheit (4.4), der Lakengeist zu den
Schwachen (4.18), der Kürbismann zum **Spaß**. ~~Er hat nichts mit dem Abkommen (2.3) zu tun.~~ **Seit 2026-10-21:**
Er war der Rezeptionist von 1987 und gehörte zum Personal des Abkommens – das Hotel behält jeden, der dort stirbt
(4.20). Ankündigung in Stufen, gleiche Sicht wie das Monster und keine Feier, solange er im Haus ist: 4.20.
Aufhalten und erlösen: 4.21.

**Wann er kommt**
- Wer Spaß hat: **feiern** (7.1), am **Spieltisch** sitzen (Mäxchen, Schach – Gäste unter sich oder mit dem
  Spieler, 6.10), als Kind zu **Süßes oder Saures** von Tür zu Tür ziehen oder damit an Zimmer 13 stehen (6.13),
  gemeinsam **schmücken** (5.9, entschieden 2026-10-20 – auch der Spieler, wenn er dabei ist).
- ~~Haben **mindestens 15 Gäste gleichzeitig Spaß**, erscheint er mit **30 %**.~~ **Spaßwert (entschieden und umgesetzt
  2026-10-22):** Das Hotel hat einen unsichtbaren **Spaßwert** (0–100, Start 30). Er sinkt ständig von selbst gegen 0;
  jeder Gast mit Spaß hebt ihn je nach Beschäftigung – am **Spieltisch** und auf **Feiern** stark, beim Schmücken,
  Suppenessen und Süßes oder Saures weniger, der Spieler zählt wie ein Gast. **Deko platzieren** hebt ihn kurz. Über der
  **Schwelle (60)** wird alle 30 s gewürfelt: an der Schwelle 40 %, bei 100 dann 90 % – je mehr Spaß, desto sicherer
  kommt er. Nach seinem Besuch fängt der Wert bei 0 an.
- **Garantie:** War er bis **Tag 15** noch keine zwei Mal da, kommt er **an Tag 15 und an Tag 16 sicher** – zu einer
  zufälligen Tageszeit, auch wenn gerade keiner Spaß hat (dann zu den Gästen und dem Spieler). Kam er an einem dieser
  Tage schon von selbst, zählt das.
- Nicht vor dem **ersten Angriff** des Monsters – der friedliche Anfang (2.1) bleibt.

**Was er tut**
- ~~Er taucht **an den Kürbisbeeten** auf (entschieden 2026-10-20).~~ **Er kommt übers Lobbydach** (entschieden und
  umgesetzt 2026-10-21): Er klettert an der Straßenseite neben dem Haupteingang hinauf, geht über das Dach der Lobby,
  bleibt kurz an der Kante über dem Mittelgarten stehen und springt vor einer der Glastüren der Lobby hinunter –
  mitten zu den Kürbisbeeten; der Aufprall ist weit zu hören. Dann **sucht er zuerst die Lobby ab** (hinter der Tür,
  neben der Treppe, hinter der Rezeption – sein alter Platz –, vor dem Haupteingang). Wen er dabei sieht, den jagt er;
  danach wie unten. Warum dort: Der Haupteingang ist verriegelt, und die Gartentüren sind der einzige Weg in die
  Lobby. Seine Zeit im Hotel (2–3 Minuten) beginnt mit der Landung.
- **Er nimmt sich immer den Nächsten vor** (entschieden 2026-10-20): Zu jemandem, der **gerade Spaß hat**, **sprintet**
  er; hat keiner Spaß, **folgt** er dem nächsten erwachsenen Gast. Alle paar Sekunden sucht er neu aus.
- **Den Spieler verfolgt er, sobald er ihn in der Nähe sieht** (entschieden 2026-10-20, etwa 14 m) – ob er Spaß hat
  oder nicht; er lässt dafür sogar sein Opfer stehen (außer im Partyraum). Weiter weg jagt er ihn, wenn der selbst
  Spaß hat und am nächsten ist.
- **Im Partyraum greift er jeden an, den er sieht** (entschieden 2026-10-20) – Gäste und Spieler, ob sie noch
  feiern, vor Schreck erstarrt sind oder nur dabeistehen. Diese Opfer kommen vor allen anderen; zu ihnen sprintet er.
- **Wer ihm im Weg steht, stirbt auch** (entschieden 2026-10-20) – ob mit Spaß oder ohne, Gast oder Spieler. Auf
  seinem Weg zum Opfer erschlägt er jeden Erwachsenen, der direkt vor ihm steht.
- Sobald er sein Opfer sieht, **rennt** er los: schneller als ein rennender Gast,
  langsamer als der rennende Spieler (aber der hat nur begrenzt Puste, 3.1).
- Ist er nah genug, **holt er mit der Axt aus**. Ein Gast erstarrt vor Angst; der Spieler kann im letzten Moment
  noch wegrennen. Wer getroffen wird, **stirbt**.
- **Entkommen:** verstecken (3.4) oder ihm lange genug aus den Augen bleiben – dann sucht er kurz, wo er sein
  Opfer zuletzt sah, und nimmt sich das nächste vor.
- **Keine Opfergrenze, sondern Zeit** (entschieden 2026-10-20): Er ist **2–3 Minuten** im Hotel und holt in der Zeit,
  wen er erwischt; ist kein erwachsener Gast mehr da, streift er umher (wer im Weg steht, stirbt trotzdem). Danach hat er **keine Lust mehr**, geht zum **Haupteingang und verlässt das Hotel** – auf dem Weg tut er
  niemandem mehr etwas.
- **Kinder sind geschützt** (entschieden 2026-10-20, wie 6.13): Sie haben Spaß und zählen bei den 15 mit – sie locken
  ihn also –, aber ihnen tut er nie etwas, auch wenn sie ihm im Weg stehen. Sie sind **kein Schutzschild**: Wer
  neben einem Kind steht, wird genauso gejagt und erschlagen.
- Der **Spieler** ist ein Opfer wie jeder Gast: Wer mitfeiert oder spielt, wird gejagt; erwischt er ihn, ist das
  Spiel vorbei (Sterbebildschirm, 4.6).

**Was er hinterlässt und auslöst**
- Opfer bleiben **als Leiche in einer Blutlache** liegen (wie beim Lakengeist, 6.12) – Gäste erschrecken davor.
- Wo er hinkommt, ist es **nicht ruhig**: Die Musik verstummt, Partien brechen ab, Süßes oder Saures ist vorbei.
- Wer ihn sieht, **erschrickt** (auch am Spieltisch) und erzählt später davon (6.12).

**Zu klären**
- **Abschreckung:** Hilft irgendetwas gegen ihn – Licht, Deko, Süßigkeiten, die man ihm hinlegt (er wollte ja
  nichts geben)? Bisher nicht. **Weiter offen (2026-10-21):** Süßigkeiten als Gegenspiel sind verworfen – mit Süßem
  vor einem Axtmörder zu wedeln, fühlt sich falsch an. **Entschieden (2026-10-21):** mit Kürbissen und Freunden
  betäuben (seit 2026-10-25 durch Zeigen, nicht durch Treffer), mit seinem richtigen Kopf vom Dachboden erlösen (4.21).
- **Vorgeschichte im Spiel:** Wie erfährt man sie – Zeitungsausschnitt, Personalakte an der Rezeption, Gerüchte?
- ~~**Geräusch:** Man sollte ihn hören (schwere Schritte, Axt, die über den Boden schleift).~~ Entschieden als
  Ankündigung in Stufen (4.20, 2026-10-21).

### 4.20 Drei Bedrohungen, ein Hotel (entschieden 2026-10-21)
> Noch nicht umgesetzt. Ersetzt „Immer nur eine Bedrohung im Haus“ (4.1) und ergänzt Lakengeist (4.18) und
> Kürbismann (4.19).

**Die Probleme bisher**
- **„Nur eine im Haus“ gegen die Steigerung:** Das Monster ist gegen Monatsende den größten Teil der Zeit unterwegs –
  Lakengeist und Kürbismann kämen kaum noch dran, gerade wenn Schwäche und große Feiern sie häufiger machen sollen.
- **Der Kürbismann kommt fast ohne Ankündigung** – der schnellste und tödlichste Angreifer, nur der Aufprall verrät ihn.
- **Er sieht nach eigenen Regeln** (18 m rundum, Licht und Ducken egal) statt nach 4.15.
- **Drei Bedrohungen, drei unverbundene Geschichten** – und der Kürbismann ist ein ausgeleuchteter Slasher in einem
  Spiel, das andeuten will (2).
- **Der friedliche Anfang war gebrochen:** Der Lakengeist spukte ab Tag 2, vor dem ersten Angriff.

**1. Eine Bedrohung je Ebene – und außer Hörweite**
- **Grundsatz:** Zwei Bedrohungen sind **nie gleichzeitig auf derselben Ebene** und **nie in Hörweite voneinander**
  (Vorschlag etwa 30 m, auch durch Decken). So können alle drei zugleich unterwegs sein, und an jedem Ort gibt es nur die
  Signale *einer* Bedrohung: Rauschen ist das Monster, Geisterklang und Flocken der Lakengeist, Schritte und Axt der
  Kürbismann.
- **Ebenen wechseln** dürfen alle, solange auf der Ziel-Ebene gerade keine andere Bedrohung ist.
- **Wo wer erscheint und wohin wer darf:**

  | Ebene | Monster | Lakengeist | Kürbismann |
  |-------|---------|------------|------------|
  | **Dachgeschoss** | erscheint nicht, verfolgt einen aber hinauf – auch in den Dachboden (4.21) | erscheint nicht, verfolgt einen aber hinauf – auch in den Dachboden | erscheint nicht, verfolgt einen hinauf, aber **nie in den Dachboden** (4.21) |
  | **Obergeschoss** | ja | **ja** (zu Hause) | ja |
  | **Erdgeschoss** | ja | **ja**, solange dort keine andere Bedrohung ist | **ja** (zu Hause, kommt übers Lobbydach) |
  | **Untergeschoss** | **ja** (zu Hause) | erscheint nicht, verfolgt einen aber durchs Treppenhaus hinunter | ja |
  | **Tiefkeller** | **nur das Monster** | nie | nie |

- „ja“ heißt: darf dort unterwegs sein, solange die Ebene frei ist. **Erscheinen** tut das Monster im Untergeschoss
  (Ruhephase im Heizraum), der Lakengeist an Fenstern und in Fluren von Obergeschoss und Erdgeschoss (4.18), der
  Kürbismann übers Lobbydach (4.19).
- **Der Lakengeist bevorzugt das Obergeschoss:** Dort kommt er mit der vollen Chance (4.18); im Erdgeschoss mit etwa
  **einem Drittel** davon und **nur an Außenfenstern**. Lakengespenster an einer Tür (5.6) ziehen ihn auf beiden
  Ebenen an.
- Die Hausherren aus 7.10 bleiben, wo jeder **zu Hause** ist; unterwegs sein dürfen sie nach der Tabelle.

**2. Der Kürbismann kündigt sich an** – in Stufen wie das Monster mit seiner Flackerwelle (4.17)
1. ~~**Vorzeichen:** Fällt der Wurf (4.19), **lodern alle geschnitzten Kürbisse im Hotel kurz orange auf** – sein
   Gegenstück zur Flackerwelle. Zugleich **leiert die Musik**.~~ **Ankündigung (entschieden und umgesetzt 2026-10-22,
   ersetzt das Auflodern):** Fällt der Wurf (oder die Garantie, 4.19), kommt er erst **3–4 Minuten später – dann aber
   sicher**, auch wenn der Spaß inzwischen vorbei ist. So lange werden **alle Lampen rot** und flackern ab und zu (rotes
   Licht schützt wie jedes Licht), der **Plattenspieler leiert eine schrille, verzerrte Melodie im ganzen Hotel** (lässt
   sich nicht abstellen), und **alle Kinder bleiben stehen und singen** das Lied vom Kürbiskopf (eigener Text, als
   Untertitel; spricht man sie an, antworten sie nur mit der nächsten Zeile). Ängstliche bekommen Angst und gehen heim,
   die meisten feiern weiter, Betrunkene erst recht. Rot und Melodie bleiben, bis er wieder weg ist; die Kinder hören
   auf, sobald er landet. **In seiner Nähe** leuchten die Lampen **greller und flackern stärker** – wo er ist, kann man
   sich schlechter verstecken. Solange er sich ankündigt, kommen Monster und Lakengeist nicht, gespeichert wird nicht.
2. **Klettern:** Kratzen an der Fassade, dann schwere Schritte auf dem Lobbydach – in Lobby und Partyraum durch die
   Decke zu hören.
3. **Landung:** der Aufprall, wie bisher.
4. **Im Haus:** schwere Schritte und eine **Axt, die über den Boden schleift** – Lärm nach 4.15, die Gäste hören ihn.
- **Solange er im Haus ist, gibt es keine normale Feier.** Die Musik wechselt sofort zu einer **leiernden Musik, die
  im ganzen Haus zu hören ist** und sich nicht abstellen lässt – bis er das Hotel verlässt.
- Gäste lernen das Signal und reden darüber („Wenn die Kürbisse auflodern, lauf.“); beim Auflodern verstecken sich
  die Ängstlichen sofort.
- **Gegenspiel:** mit gezeigten Kürbissen und der Hilfe der Gäste betäuben, mit seinem Kopf erlösen (4.21).

**3. Gleiche Sicht für alle:** Auch der Kürbismann sieht nach 4.15 (`Senses.can_see`), mit eigener Grundweite (Vorschlag
etwa 12 m). Licht und Ducken wirken bei ihm wie beim Monster – im hellen Partyraum ändert das wenig, im dunklen Flur
viel.

**4. Eine Geschichte: Das Hotel behält jeden, der dort stirbt** (ergänzt 2.3)
- **Monster:** der **Heizer** von 1987 (2.3).
- **Kürbismann:** der **Rezeptionist**, ebenfalls Halloween 1987. Er gehörte zum Personal, das das Abkommen am Laufen
  hielt – er führte die Gästeliste. Die Geschichte mit den Kindern (4.19) bleibt: So hat das Hotel ihn sich genommen.
- **Lakengeist:** die **Verschwundenen** – Laken aus der Wäscherei, die jedes Jahr ein Gesicht mehr bekommen. Mit jedem
  geholten Gast wird er häufiger (beantwortet „Herkunft“ in 4.18).
- „Das Hotel behält immer einen“ (2.3) wird damit wörtlich.
- **Ton:** Den Kürbismann sieht man meist als **leuchtendes Kürbisgesicht im Dunkeln**, nicht als ausgeleuchteten
  Slasher.

**5. Der friedliche Anfang bleibt friedlich:** Der Lakengeist kommt **erst nach dem ersten Angriff** des Monsters
(2.1); „ab Tag 2“ (4.18) entfällt.

**Vertagt (2026-10-21): der Katzenraum.** 7.7 verspricht, er sei vor allem sicher; tatsächlich kommen Monster und
Lakengeist nicht hinein, der Kürbismann schon. Zugleich ist Ausharren dort die stärkste Strategie. Bis zur eigenen
Runde bleibt es, wie es ist.

**Zu klären:** Hörweite zwischen den Bedrohungen (30 m?) · ob die leiernde Musik als Lärm zählt (im ganzen Haus würde
sie das Monster überall hinlocken – Vorschlag: nein) · was passiert, wenn eine Verfolgung auf eine Ebene führt, auf der
schon eine andere Bedrohung ist (Vorschlag: die Verfolgung bricht an der Treppe ab).

### 4.21 Den Kürbismann aufhalten – und erlösen (entschieden 2026-10-21)
> Noch nicht umgesetzt. Beantwortet „Abschreckung“ aus 4.19 und nutzt das Sozialsystem (6.18): Allein kann man ihn nur
> kurz aufhalten, mit Freunden lange genug, um ihn zu erlösen.

**1. Betäuben: einen Kürbis zeigen** (geändert 2026-10-25)
- **Hält man ihm einen Kürbis entgegen,** sodass er ihn sieht, **ist er betäubt** – immer, kein Würfeln. Er bleibt
  wie gebannt stehen. Der Kürbis bleibt dabei heil.
- **Er wird nie beworfen oder geschlagen:** Würfe (3.13) und Schläge bewirken bei ihm nichts.
- **Allein hält das nur sehr kurz** – genug zum Fliehen oder um einen Gast aus seiner Reichweite zu holen.
- **Woher der Kürbis kommt:** aus den Beeten (dort, wo er landet, 4.19) oder von einer Tür – bei Knappheit (5.10)
  eine echte Entscheidung: meine Deko oder die des Nachbarn?
- *Verworfen:* ein Treffer nur von hinten (zu albern) und eine Trefferwahrscheinlichkeit – seit 2026-10-25 jeder
  Treffer überhaupt, ob geworfen oder zugeschlagen.
- **Offen:** wie lange „sehr kurz“ ist, aus welcher Entfernung das Zeigen wirkt und welche Kürbisse zählen (nur große
  wie bisher, jede Sorte, auch geschnitzte, der Zierkürbis aus der Tasche?).

**2. Hilfe der Gäste**
- **Gute Freunde** in der Nähe holen sich von selbst einen Kürbis, kommen dazu und halten ihn ihm entgegen.
- **Rufen:** eine Ruf-Aktion an alle Gäste in Hörweite – „Holt Kürbisse!“ (dieselbe Mechanik wie „Warnen“, 6.18: beim
  Flackern „Versteckt euch!“). Jeder entscheidet selbst nach Beziehung, Angst und Mut; wer wenig von dir hält oder viel
  Angst hat, flieht schreiend. Rufen ist Lärm – auch der Kürbismann hört es.
- **Jeder Helfer, der ihm einen Kürbis zeigt, verlängert die Betäubung.** Zu dritt, zu viert reicht sie für das
  Ritual (3).
- **Der Preis:** Helfer können sterben – das zählt als Ursache in der Schuld-Kette (6.18).

**3. Erlösen**
- **Möglich, sobald man seinen richtigen Kopf hat.** Der liegt auf dem **Dachboden** (4) – frühestens ab etwa Tag 15
  erreichbar (ersetzt „ab Tag 20“ aus der Ideensammlung).
- **Das Ritual:** Während er betäubt ist, nimmt man ihm den Kürbiskopf ab und setzt ihm seinen Kopf wieder auf – [E]
  einige Sekunden halten (wie die Kurbel, 7.4). Solange die Helfer ihm ihre Kürbisse zeigen, läuft die Betäubung
  weiter.
  Bricht man ab, wacht er auf – wütend.
- **Danach** ist er vom Fluch befreit und **verschwindet für immer**. Feiern sind wieder sicher, das Erdgeschoss ist
  frei (4.20).
- **Er hinterlässt drei starke Deko-Stücke** (einmalig, 5.10):
  - seinen **Schädel** – nach fast 40 Jahren kein Kopf mehr; die stärkste Deko im Spiel, wie der Totenkopf (5.7);
  - die **blutige Axt** – an einer Tür trauen sich wütende Gäste nicht mehr zu klauen;
  - seine **Jeansjacke** – er trägt Freizeitkleidung, keine Uniform.
- **Ruf:** Es spricht sich über das Freundesnetz herum („Der aus Zimmer 13 hat den Kürbismann erlöst“, 6.18); alle
  Helfer werden Freunde.
- **Das Monster nimmt es als Verlust** – „es hat einen der Seinen verloren“ (4.20, „Das Hotel behält jeden“): Für den
  Rest des Monats liegt die Angriffschance (4.17) eine Stufe höher.
- **Vorbild fürs Ende:** Dasselbe Muster – Fluch, Fundstück, Ritual – kennt 2.3 als Ende „Ihn erlösen“ für den Heizer.
  Der Kürbismann ist die kleinere Probe davor.

**4. Der Dachboden**
> **Gebaut 2026-10-24 nach dem Plan des Zeichners** (Fläche „Dachboden“ #404262): Das ganze Dachgeschoss ist Dachboden.
> Statt einer Kette in fester Reihenfolge ist der Westflügel ein **Gewirr aus Kammern** (je 6 × 6 m, viele Türen, keine
> Nummern), Mitte und Ostflügel sind große offene Böden. Hinauf führt eine **steile Treppe im Treppenhaus West** vom
> Obergeschoss zur verschlossenen Kniestocktür; der Aufzug hält (noch) nicht oben. Der Kopf liegt auf dem roten Kreuz
> des Plans (Kammer im Südwesten). Aussehen: grobe Bohlen an Boden, Wänden und Decke (2,2 m), **alle Türen 1,65 m**
> (nur geduckt), in jeder Kammer ein **Stützbalken** mit Balkenkreuz auf knapp 2 m und Kopfbändern unter 45°, an den
> Außenwänden ein Kniestock (1,3 m) mit **Dachschräge** und **Fenstern mit Holzkreuz**, durch die kaltes Licht fällt,
> **blaugrauer Staubnebel**, der leicht flimmert. **Kisten mit wertvollerer alter Deko** (Totenkopf, Hexenbesen,
> Lichterkette; wenige Stücke, kein Nachschub) setzt der Zeichner als „Ausstattung: Dekokiste“ in den Plan. Die
> Fensterfarbe des Zeichners: #c9e7ff („Dachfenster“, auf der Außenwand). Die Dachform darüber bleibt offen.
- ~~**Das Dachgeschoss** (7.10) hat offene Bereiche; der Aufzug hält dort. **Hinter einer niedrigen Kniestocktür** liegt
  nur der Dachboden: eine **Kette von Kammern** wie in *Doors* – nummerierte Türen hintereinander, mit Schränken, Kisten
  und Kommoden, **in fester Reihenfolge**. In der letzten liegt der Kopf.~~ (siehe oben)
- **Der Schlüssel** zur Kniestocktür liegt im **Heizraum hinter dem Gitter** (7.4), das mit jedem Tag lockerer wird – ab
  etwa Tag 15 kommt man hindurch. Ein Wagnis im Revier des Monsters (2.3), wie der Schlüssel zu 0118.
- **Durch die Tür nur geduckt** – einen großen Kürbis bekommt man nicht mit hinein. (Gilt seit 24.10. für jede Tür
  dort oben.)
- **Warum der Kopf dort liegt:** Die Kinder von 1987 haben ihn auf dem Dachboden versteckt – Kinder kommen überall hin
  (6.13). Heutige Kinder erzählen davon, und keiner glaubt ihnen: eine Spur.
- **Nicht wirklich tödlich, aber selten eine kleine Gefahr (präzisiert 2026-10-23):** Spinnen in den Schubladen (4.23)
  und ganz selten ein Vampir (4.22) – nur er kann dort sehr stark beißen, sodass man stirbt, oder einen selbst zum
  Vampir machen. Das ist das Schlimmstmögliche auf dem Dachboden.
- **Still und dunkel, kein eigenes Monster.** Auf dem Dachboden erscheint keine Bedrohung (4.20). **Monster und
  Lakengeist verfolgen einen auch hinein, der Kürbismann nicht** – aus mystischen Gründen (Vorschlag: Er kommt seinem
  eigenen Kopf nicht nahe).
- **Kurz halten:** Das Dachgeschoss bekommt einen **kleineren Grundriss** und wenige, gezielte Aufgaben – man ist dort
  nicht lange, Bedrohungen tauchen dort selten auf.
- **Blitz-Dreh (entschieden und umgesetzt 2026-10-24):** Blitzt es, während man in einer der Kammern steht, dreht einen
  der Spuk im grellen Blitzbild um genau 90° nach links oder rechts – die Kinder von 1987 spielen einem einen Streich, kurz
  danach kichert es leise. Höchstens einmal je Gewitter, nicht bei jedem Blitz, nie während einen etwas verfolgt, nicht
  im Versteck oder im Sitzen, nicht auf den offenen Böden. Der Kompass verrät den Dreh. Wer das Flackern abschwächt
  (Barrierefreiheit), bekommt nur das Kichern.
- **Unheimlich ohne Gefahr** (Vorschläge): gedämpfte Musik von unten, Regen und Wind auf dem Dach (7.8), man braucht
  die Taschenlampe (4.16); **Möbel unter Laken**, die aussehen wie der Lakengeist – hier ist es nie einer (wie die
  Kostüme, 5.9); Kreidezeichen, ein Kinderschuh, ein Abzählreim der Kinder von 1987.
- **Hängt an der Dachform:** Wie die Kammern aussehen (Schrägen, Kniestock, Gauben), folgt aus der Dachform, die noch
  aussteht.

### 4.22 Fledermäuse und der Vampir (vorgemerkt 2026-10-23)
> Noch nicht umgesetzt. Eine vierte Bedrohung – für sie gilt dieselbe Ebenenregel wie für die anderen drei (4.20).
> Mit „Vorschlag“ markierte Punkte sind aus der Durchsprache noch nicht bestätigt.
> **Fledermäuse umgesetzt (2026-10-23), ohne Biss:** draußen in den Bäumen des Gartens (das Dachgeschoss fehlt im Plan
> noch) – tagsüber hängen sie schlafend am unteren Rand der Krone, abends und nachts kreisen sie zackig um die Kronen.
> Scheu, Frühwarnung (sie fliehen vor Monster, Kürbismann und Lakengeist) und der Schwarm als Lärm wie unten
> vorgeschlagen; wie nah man ihrem Baum kommen darf, hängt an der Auffälligkeit (4.15: Licht, Rennen, Ducken), laute
> Geräusche wecken sie. Biss, Vampir und Knoblauch/Kreuz kommen mit den offenen Fragen unten. Debug:
> `--fledermaus[=tag|schwarm]`.

**Fledermäuse**
- Echte Fledermäuse im **Dachgeschoss** und **draußen**. Meist sind sie **scheu** und fliegen vom Spieler weg.
- **Beißen:** mit **geringer** Wahrscheinlichkeit den Spieler, mit **sehr geringer** einen Gast – erst nach dem
  ersten Angriff, der friedliche Anfang bleibt friedlich (4.20).
- Vorschläge:
  - **Tagesrhythmus** (2.4): tagsüber hängen sie schlafend an den Balken im Dachgeschoss, Licht oder Lärm schreckt
    sie als Schwarm auf; nachts sind sie draußen über dem Garten.
  - **Frühwarnung:** Sie fliehen vor allem, auch vor den Bedrohungen – fliegt draußen oder oben plötzlich ein Schwarm
    auf, kommt etwas (wie die schwingenden Lakengespenster, 5.6). Ein aufgeschreckter Schwarm ist Lärm (4.15).
  - **Echt oder Papier?** Verwechslung mit der Fledermausgirlande (5.7).
  - **Die gefährliche kündigt sich an:** Sie fliegt nicht weg, sondern bleibt sitzen und starrt. Die Chance hängt an der
    Schwäche (4.18), die Taschenlampe vertreibt sie.
  - **Im Dachgeschoss kein Biss** – dort bleibt es still und ohne eigene Bedrohung (4.20, 4.21); gebissen wird draußen.

**Der Biss**
- Wer gebissen wird, wird **schwach** – Vorschlag: Schwäche **+0,5** (4.18), die Wunde heilt in zwei bis drei
  Spieltagen (6.17). Damit kommt auch der **Lakengeist wahrscheinlicher und schneller** – ohne Sonderregel.
- **Das Bild:** Nach dem Biss wird der Bildschirm abwechselnd **dunkler und heller**, ist ziemlich **dunkel und
  verschwommen**. Vorschlag: direkt nach dem Biss stark, wie ein Herzschlag, dann klingt es mit der Schwäche ab;
  abschwächbar in den Einstellungen (wie das Flackern, 8.4) – Dunkelheit ist Spielmechanik (4.4).
- **Wer im schwachen Zustand gebissen wird, stirbt.**
- **Gäste** genauso: Gebissene haben **Bissmale am Hals** und sind blass (Eintrag für 6.17); zweimal gebissen bleiben sie
  als blasse Leiche liegen.

**Der Vampir**
- Die **Fledermaus, die gebissen hat, verwandelt sich selbst** in einen Vampir.
- **Ebenenregel** (4.20): Draußen ist Erdgeschoss, die Balkone gehören zum Obergeschoss. Ist die Ebene schon belegt,
  verwandelt sie sich nicht – es bleibt beim Biss, sie flattert davon.
- **Nicht nur einmal, aber selten.** Vorschlag: nach jedem Vampir einige Spieltage Pause, in der keine Fledermaus beißt;
  etwa **3–5 im Monat**, gegen Halloween etwas häufiger.
- **Vertreiben mit Knoblauch oder Kreuz:** Er erschrickt, und sein **Körper zerfällt in 20–30 Fledermäuse**, die alle
  in eine Richtung davonfliegen und aus dem Bild verschwinden. Damit ist der Besuch vorbei. Vorschläge: vom Spieler weg
  (drinnen den Flur hinunter, draußen in den Himmel); der Schwarm ist Lärm, Gäste, die ihn sehen, erschrecken und reden
  darüber.
- **Knoblauch und Kreuz** sind neue Gegenstände (klein, Tasche). Vorschläge: Sie wirken nur **in der Hand, hochgehalten
  mit Blick auf ihn** (wie der UV-Aufsatz, 4.16). **Knoblauch** ist häufig (Küche, ein Beet im Garten) und welkt nach
  ein paar Tagen (5.10); Gäste rümpfen die Nase. **Kreuze** sind selten (zwei, drei im Hotel: eine Schublade, eine
  gläubige ältere Frau, über einem Bett) und halten ewig.

**Dachboden (2026-10-23):** Ganz selten begegnet man dort einem Vampir. Nur er kann auf dem Dachboden tödlich sein
(sehr starker Biss) oder einen selbst verwandeln – das Schlimmstmögliche dort (4.21).

**Twist: Man wird selbst zum Vampir**
- Der Spieler kann selbst zum Vampir werden. Dann muss er **Gäste beißen, sonst verhungert er**.
- **Am Ende, beim Gruppenfoto** an Halloween (5.9), stellt sich heraus, dass man ein Vampir ist: Man fehlt auf dem Bild
  – ein leerer Platz wie bei den Verschwundenen. **Danach fehlt auch das Spiegelbild** (3.9). Der Vampir versetzt die
  **Stadt** in Chaos – ein eigenes, dunkles Ende neben der Flucht und der Zeitschleife (2.1, 2.2).
- Vorschläge: Als Vampir spielt man die Rolle des Lakengeists – schlafende Gäste in der Nachtruhe, keine Zeugen, Zeugen
  verraten einen. **Kinder nie** (6.13). Das Spiegelbild **verblasst schon während der Verwandlung** als Hinweis für
  Aufmerksame.

**Zu klären**
- **Was macht den Spieler zum Vampir?** Vorschlag: Nach einem Biss hat man zwei, drei Tage Zeit, sich zu heilen
  (Knoblauch essen, richtig schlafen); wer es nicht schafft, verwandelt sich. Keine Strafe aus dem Nichts.
- **Was heißt „schwach“ beim tödlichen Biss?** (a) die Bisswunde ist noch offen – zwischen zwei Vampiren liegen aber
  Tage, das passiert kaum; (b) Schwäche ab ⅔, egal woher. Vorschlag: beides, und nach dem ersten Biss lässt er **5–8 s
  los** und kommt dann wieder – ein zweiter Biss in derselben Begegnung tötet. Der erste Biss ist die Warnung, wer schon
  schwach ist, bekommt keine.
- **Muss man ihn hereinbitten?** Vorschlag: ja – er klopft an Türen und Fenstertüren, gibt sich als neuer Gast aus, und
  ein Gast, der ihn nicht erkennt, lässt ihn herein (ab dem 25. gibt es Vampirkostüme, 5.9). Seine Regel wäre dann
  **Leichtsinn und Gastfreundschaft** – neben Dunkelheit (Monster), Schwäche (Lakengeist) und Spaß (Kürbismann).
- **Weiß der Spieler, dass er ein Vampir ist?** Beim Beißen ja – das Foto verrät es dann den anderen.
- **Herkunft:** Er steht außerhalb von „Das Hotel behält jeden“ (4.20) – bewusst so lassen oder einbinden (etwa ein
  Gast von 1987, der nie abgereist ist)? Lässt das Hotel den Vampir gehen, weil er nicht mehr zum Abkommen gehört?
- Wie er sich bewegt und jagt, was Monster und Lakengeist mit einem Spieler-Vampir tun, wie Hunger und Beißen als Spieler
  gehen, wie Gäste reagieren, ob Knoblauch und Kreuz dann gegen einen selbst wirken.

### 4.23 Spinnen (entschieden und umgesetzt 2026-10-23)
> **Umgesetzt (2026-10-23)** wie unten. Noch nicht: Katzen jagen Spinnen, Plastikspinnen (5.7) als Kugeln bei der
> Arachnophobie-Einstellung, das Dachgeschoss (fehlt im Plan). Debug: `--spinne[=gesicht|schublade]`.

Inspiriert von *Doors*. Kleine Tiere, keine Bedrohung im Sinne von 4.20 – ein Ärgernis mit kleinem Preis. **5–6 cm**
groß (Beinspanne), sehr dunkel (Feinschliff 2026-10-23).
- **Wo:** im **Keller** (Untergeschoss, Tiefkeller) und im **Dachgeschoss** ganz häufig, in den anderen Etagen selten.
  Es gibt sie nur in der Nähe des Spielers; neue tauchen auf, wo man nicht hinsieht.
- **Krabbeln:** Sie laufen über den Boden. **Wo Spinnen leben, wachsen Spinnweben schneller nach** (5.4, 5.10).
  Die **Fäden** am Boden (verblassen, reißen, wenn jemand hindurchläuft – Spur wie die Kratzer, 4.13) sind wieder
  **ausgebaut** (2026-10-24).
- **Scheu und zertreten:** Nahe Füße scheuchen sie weg (geduckt und still kommt man näher). Wer auf eine tritt,
  **zertritt** sie. **Mutige Gäste** zertreten sie auch, **ängstliche erschrecken** (etwas Angst), Kinder ebenso.
- **Aus der Schublade ins Gesicht:** Beim Aufziehen einer Schublade (3.5) springt selten eine heraus – in **1 %** der
  Fälle, überall gleich (2026-10-23; vorher 15 % im Keller, 5 % sonst), danach eine Minute Ruhe. Man **schnappt nach Luft** (Lärm, 4.15 – das
  lockt vielleicht das Monster) und muss sie **abschütteln** (Maus ein- bis zweimal hin und her, knapp 2 s). Sonst **beißt sie**:
  Das wirkt wie **ein Glas** an der Bar (angetrunken, 3.7) und macht damit auch schwächer (4.18); mehrere Bisse
  summieren sich wie Gläser.
- **Der friedliche Anfang bleibt friedlich** (2.1): Krabbeln und Spinnen von Anfang an, Springen und Beißen erst nach
  dem ersten Angriff.
- **Arachnophobie:** Einstellung „Spinnen als Kugeln“ (8.4) – schlichte Kugeln ohne Beine, auch im Gesicht.
- **Nicht gespeichert:** Nach dem Laden krabbeln neue.

---

## 5. Halloween-Dekoration

### 5.1 Funktion
Deko ist **Schutzmittel und Währung** zugleich. Wie knapp sie ist, wie sie wirkt und verfällt: 5.10.

### 5.2 Platzierung
- **Vor der eigenen Zimmertür** → schützt den sicheren Rückzugsort
- **Im Flur** → schützt Wege / schafft sichere Zonen
- Platzierung über ein einfaches Bau-/Platzierungssystem (Vorschau-Ghost, Raster oder Snap-Punkte)

### 5.3 Ideen für Deko-Typen (vorläufig)

| Deko             | Herkunft                    | Idee zur Wirkung                          | Seltenheit |
|------------------|-----------------------------|-------------------------------------------|------------|
| Geschnitzter Kürbis (Jack-o'-Lantern) | Garten → selbst schnitzen | Starker Schutz **+ Licht**, Kerze brennt ab | mittel |
| Ungeschnitzter Kürbis | Garten                  | Schwacher Schutz, Rohstoff / Handelsware   | häufig     |
| Spinnenweben     | In bestimmten Hotelbereichen einsammeln | An Tür / im Flur aufhängen; Schutz, evtl. Frühwarnung (bewegen sich bei Monsternähe)? | mittel |
| Herbstlaub       | Bäume im Garten             | Am Boden auslegen; schwacher Schutz, **raschelt** (verrät Schritte – auch die von Dieben?) | häufig |
| Kerzen           | Fundstücke / Handel         | Kleiner Radius, Licht                       | häufig     |
| Girlande / Lichterkette | Handel                | Schützt Flurabschnitt linear, Licht         | mittel     |
| Vogelscheuche    | Handel / Belohnung          | Großer Radius                               | selten     |

- Mögliche Mechanik: **Verfall/Haltbarkeit** (Kerzen brennen ab, Kürbisse verrotten, Laub wird zertreten), damit Deko nicht einmal platziert und vergessen wird. **Entschieden 2026-10-21 (5.10).**

### 5.4 Deko selbst herstellen

**Kürbisse – Anbau & Schnitzen**
- Im **Hotelgarten** gibt es Beete: Kürbis pflanzen → wachsen lassen (zeitbasiert, evtl. gießen) → ernten.
- **Schnitzen:** Eigene Interaktion am Tisch / in der Küche. Ideen:
  - Mini-Spiel: Gesicht aus Vorlagen wählen oder frei schnitzen
  - Messer nötig (Werkzeug-Item), Kerze nötig für die Leuchtwirkung
  - Evtl. „gruseligere“ Schnitzerei = stärkerer Schutz?
- Kürbisse sind auch **Handelsware** – wer einen guten Garten hat, ist bei den Gästen beliebt.
- Konfliktpotenzial: Gäste können auch **aus dem Garten klauen** bzw. selbst anbauen.

**Spinnenweben**
- Kommen nur in bestimmten (oft dunklen, verlassenen) Bereichen vor → Risiko: Man muss dorthin, wo das Monster gern ist.
- Einsammeln (evtl. mit Werkzeug, z. B. Besen/Stock) und an Tür oder im Flur aufhängen.

**Herbstlaub**
- Von Bäumen im Garten sammeln (Haufen aufheben, evtl. Baum schütteln).
- Leicht zu bekommen, aber schwach – gut als „Füllmaterial“ und Frühwarnsystem.

**Garten als Ort**
- Draußen, aber umzäunt/eingeschlossen (man kommt trotzdem nicht aus dem Hotel heraus).
- Tagsüber relativ sicher, nachts dunkel und gefährlich → Ernten wird zum Risiko-Abwägen.

### 5.5 Die Puppe – „Halloween-Jury“ (entschieden 2026-10-21, neu gefasst 2026-10-22)
> **Umgesetzt (2026-10-22):** alles außer „Vorgemerkt“. Die Puppe ist vorerst aus Grundkörpern gebaut (Stoffpuppe mit
> Porzellangesicht, orangem Kleid und Hexenhut) und sitzt am Anfang auf einem Lobby-Sofa.
> Ersetzt die Fassung vom 2026-10-21 (Urteil schon beim Rückzug in den Keller, Spieler trägt sie, Opfern durch
> Hintragen, Monster geht nur „zuerst“ zu ihr) und davor die wandernde Puppe, die Zonen bewertet.
>
> **Geändert und umgesetzt 2026-10-23 (2.5):** Bis zum ersten Angriff ist sie die **Jury des
> Türschmuck-Wettbewerbs** auf dem Lobby-Sofa. Bei der Siegerehrung steigt sie auf und löst sich in Rauch auf – das
> einzige Mal vor den Augen des Spielers. Ihre Regel wird danach **mitgeteilt** (Aushang, Warnungszettel), statt dass
> der Spieler sie selbst herausfinden muss.

**Grundidee:** Die Puppe ist keine Figur, die herumläuft, sondern das **sichtbare Urteil** des Abkommens (2.3): Kurz vor
einem Angriff liegt sie vor der Tür dessen, der am wenigsten schmückt – und **dort stirbt jemand**. Was bisher
unsichtbar ist (wie gut die Deko gegen den wachsenden Anspruch noch reicht, 4.8, 4.9), wird so lesbar. ~~Dass sie
immer vor der schwächsten Tür liegt, sagt das Spiel nicht – der Spieler muss es selbst herausfinden.~~ Seit 2026-10-23
sagt es das Hotel nach dem ersten Angriff selbst: der veränderte Aushang am Brett in der Lobby und ein Warnungszettel (2.5).

**Das Urteil**
- **Wann:** nur vor einem **echten Angriff** (einen holen oder Raubzug, 4.17) – nie beim Umsehen. Seit 2026-10-22 auch vor
  den ersten, für Gäste harmlosen Angriffen (2.1): Dann bricht es ebenfalls ein, erschreckt die Gäste aber nur – dich tötet
  es, wenn es dich erwischt. **1–2 Minuten vor dem Aufbruch** liegt sie plötzlich vor der Tür. Ist die
  Ruhephase kürzer (spät im Monat, 4.13), wartet das Monster, bis die Frist um ist.
- **Wen:** nur **bewohnte Türen** – die Zimmer der erwachsenen Gäste und **Zimmer 13**. Keine Flure, keine Lobby, keine
  leeren Zimmer, keine Zimmer, in denen nur Kinder schlafen (sie sind nie Opfer, 6.13).
- **Wie:** die Tür mit der **wenigsten Deko** (so, wie das Monster sie zählt – im Lichtschein, 5.10). Haben mehrere
  gleich wenig, die **dunkelste**; sind auch die gleich dunkel, eine **zufällige**. Es gibt immer eine schlechteste
  Tür, egal wie viel im Hotel hängt – und der Nachbar wird zur Konkurrenz (Klaue ich ihm einen Kürbis, ist er der
  Schwächste).
- **Sie bewegt sich nie vor den Augen des Spielers.** Sie springt um, wenn er weder ihren alten noch ihren neuen Platz
  sieht: eben war der Flur leer, jetzt sitzt sie da, mit dem Gesicht zur Tür. Einzige Ausnahme ist die Siegerehrung
  (2.5), bei der sie aufsteigt und sich in Rauch auflöst.
- **Grollen:** Solange sie vor der Tür liegt, hört man **im ganzen Hotel** ein tiefes Grollen, das immer lauter wird –
  dann bricht das Monster auf, und die Flackerwelle (4.17) verrät, wie viele es holen will.
- **Das Grollen wirkt (entschieden und umgesetzt 2026-10-22):** Die Gäste bekommen Angst (Mutige weniger) und reden
  darüber („Hört ihr das? Dieses Grollen …“, „Wo ist die Puppe?“) – das Monster hört mit (4.7). Wer genug Angst hat, rennt
  heim und schließt die Tür, Kinder laufen zu Mama oder Papa, ab halber Lautstärke **löst sich jede Feier auf**. Später
  erzählen sie davon („Jedes Mal, bevor es kommt, grollt das ganze Hotel.“).
- **Beim Aufbruch bringen sich alle in Sicherheit (entschieden und umgesetzt 2026-10-22):** Sobald die Flackerwelle sie
  erreicht, rennen alle Gäste – auch Feiernde – **heim und machen die Tür zu** oder, wenn ihr Zimmer zu weit weg ist, **ins
  nächste Versteck**, und bleiben drinnen, solange das Monster unterwegs ist.
- **Nachbessern hilft:** Wer bis zum Aufbruch Deko nachlegt und nicht mehr der Schwächste ist, den verlässt sie beim
  nächsten unbeobachteten Moment, und sie liegt vor der neuen schwächsten Tür. Mit dem Aufbruch steht das Urteil fest.
- **Niemand kann sie bewegen** (entschieden 2026-10-22): Der Spieler nie, Kinder nur zwischen den Angriffen (unten).

**Der Angriff** (entschieden 2026-10-22)
- **Weg:** Vom Keller zur Puppentür. **Unterwegs** greift das Monster bis zu **fünf bewohnte Türen** an, deren Deko
  nicht hält – undekorierte oder billig geschmückte (4.9: Abschreckung kleiner als der Druck). Das tut es nur,
  **solange es noch hungrig ist** (Opferzahl aus 4.17); die Puppentür kommt immer zuletzt dran.
- **Ein gewähltes Zimmer:** Die Tür fällt, auch abgeschlossene. Das Monster geht hinein und **reißt jedes Versteck
  auf** – Schrank und Bett schützen hier nicht. Jeder darin wird mit **60 %** geholt, sonst überlebt er verletzt
  (wie 6.17, vier von zehn). Der Spieler stirbt (8.7).
- **Das Puppenzimmer:** Die Tür fällt **immer**, auch gut geschmückt. **Wer darin ist, stirbt** – keine 40 %. Es zählt
  nicht gegen die Opferzahl; danach ist das Monster satt und kehrt in den Keller zurück.
- Wer weiß, wohin es geht, ist **nicht** dort: Die Puppe ist eine Warnung, kein Todesurteil – für den, der sie liest.

**Kinder**
- Zwischen den Angriffen (erst nach dem ersten – vorher ist sie die Jury in der Lobby, 2.5) sehen Kinder die Puppe, nehmen sie zum Spielen mit und legen sie gern **vor die Tür ihrer
  eigenen Familie**. Kurz vor einem Angriff springt sie von dort (unbeobachtet) zur schwächsten Tür, und ab dann
  können auch Kinder sie nicht mehr bewegen.
- Kinder erzählen von ihr („Die Puppe hat mich angeguckt“) – keiner glaubt es.

**Gäste:** Findet ein Gast sie vor seiner Tür, steigt seine Angst, und er sagt es laut („Bei mir sitzt die Puppe …“).
~~Er bittet den Spieler um Deko~~ – kommt mit den Wünschen (6.14, 6.18).

**Zwischen den Urteilen** bleibt sie, wo sie zuletzt lag – oder wo ein Kind sie hingelegt hat. Am Anfang sitzt sie in
der Lobby, als Jury des Wettbewerbs (2.5); nach der Siegerehrung ist sie fort, bis sie vor dem nächsten echten Angriff
vor einer Tür liegt. Sie ist **keine Bedrohung** und zählt nicht zur Regel „immer nur eine Bedrohung im Haus“ (4.1).

**Vorgemerkt**
- **Jury beim Schmücken (5.9) und beim Schnitz-Wettbewerb (6.10):** Am Ende eines Großen Schmückens sitzt sie an der
  schönsten Stelle – Ruf für die Mitmacher. Kein Muss.
- **Das letzte Urteil an Halloween:** „Das Hotel behält immer einen“ (2.3) – am 31. sitzt sie ein letztes Mal vor
  einer Tür: bei dem, den das Hotel behält. Erst festlegen, wenn das Ende (2.1) steht.
- ~~Opfern durch Hintragen, Ruf-Verlust beim Hintragen~~ (entfällt 2026-10-22: niemand trägt sie mehr dorthin). Opfern
  geht über Diebstahl: Wer dem Nachbarn die Deko klaut, macht ihn zum Schwächsten (4.11).

**Spielstand:** Lage, Urteil (Tür), welches Kind sie trägt, Frist bis zum Aufbruch.

### 5.6 Aufhängen, Lakengespenster, Lichterketten (entschieden und umgesetzt 2026-10-20)
- **Aufhängen:** Lakengespenster, Lichterketten und Spinnweben hängt man an die Wand – an eine Wand sehen und
  [G]. Herbstlaub verstreut man am Boden (in der Hand ist es ein Haufen). Abnehmen mit [E].
- **Lakengespenster** sind festliche Deko, nicht der Lakengeist: ein Laken mit fröhlichem Gesicht (Kulleraugen,
  Lachen, rote Bäckchen, orange Fliege), eher witzig als gruselig. Man gibt ihnen einen **Zierkürbis** in die
  Hände; bei einem zu starken Ruck (Monster ganz nah) fällt er herunter. Herkunft: alte Laken mit aufgemalten
  Gesichtern in den **Wäschekisten** (Deko vom letzten Jahr), Mila bastelt welche, manche Gäste haben eins an
  der Tür.
- **Zierkürbisse** fallen beim Ernten oft mit ab; Edna und Mila haben welche.
- **Lichterketten:** bunte Birnen in Bögen entlang der Wand, bis zur nächsten Ecke oder Tür (höchstens 3 m);
  leuchten (zählt als Licht) und flackern mit den Lampen. Herkunft: **Dekokiste** im Lager (Plan-Ausstattung
  „Dekokiste“), selten in Kommoden, Bruno handelt damit.
- **Frühwarnung:** Alles, was hängt, bewegt sich immer ganz leicht. Naht das Monster, schwingen Lakengespenster,
  Spinnweben und Lichterketten schon ab etwa 16 m – sanft, gleichmäßiger, dann stärker –, lange bevor die Lampen
  flackern (9 m). Ab dort flackern die Lichterketten mit. Beim Lakengeist rühren sie sich auch – er selbst ist
  vor der Tür lautlos, die Deko verrät ihn.
- **Der Lakengeist vor der Tür** (siehe 4.18): Hängen Lakengespenster an einer Zimmertür und ist jemand drinnen,
  zieht es ihn manchmal dorthin. Er steht **einige Zeit** (1½–2½ Minuten) lautlos vor der geschlossenen Tür und
  kreist mit den Händen; die Lakengespenster kreisen mit. Drinnen wird der Blick ganz langsam zur Tür gedreht –
  Hypnose durch die Wand, bei Schwachen stärker. Wer die Tür öffnet, den packt er. Danach ist er weg.
  - **Entschieden 2026-10-20:** Er verschwindet nach der Zeit; wer aufmacht oder ihm im Flur zu nah kommt, wird
    gepackt. Die Gespenster halten ihn also von den Fenstern fern, binden ihn aber an die Tür.
  - **Gäste:** Hängt die Deko an der Tür eines Gastes, starrt er zur Tür. Schwache (ängstlich, betrunken) gehen
    irgendwann aufmachen, die meisten anderen starren nur, bis er weg ist – und keiner geht, wenn jemand bei ihm
    im Zimmer ist. Wer ihn anspricht oder im Flur auftaucht und den Geist sieht, rettet ihn.
    Vor der Tür vertreiben ihn Gäste erst aus der Nähe (6 m), sonst bliebe er in den belebten Fluren nie stehen.
  - **Richtung:** Die Deko schwingt nur schwach von ihm weg – aufmerksame Spieler können daran ablesen, woher es
    kommt.

### 5.7 Mehr Deko: Fledermäuse, Spinne, Totenkopf, Hexenbesen (entschieden und umgesetzt 2026-10-20)
| Deko | Woher | Was sie kann |
|------|-------|--------------|
| **Fledermausgirlande** | Dekokiste, alte Deko im Keller, Kommoden, Mila | hängt an der Wand (1,2 m Leine, vier Papierfledermäuse); die Flügel flattern im Luftzug leicht und bei Unruhe kräftig |
| **Plastikspinne** | Dekokiste, Kommoden | hängt am Faden; wippt immer ein wenig und hüpft bei Unruhe wie ein Jo-Jo |
| **Totenkopf** | alte Deko im Keller, Bruno | steht auf Boden oder Möbeln; mit einer Kerze darin glimmen die Augen (Licht, stärker als ohne) – wie beim Kürbis, kippt um |
| **Hexenbesen** | alte Deko im Keller | lehnt an der Wand (groß, beide Hände); beim starken Ruck rutscht er weg und fällt polternd um – noch eine Warnung |
- **Alte Deko im Keller:** Im Versteck des Monsters steht eine Kiste mit Halloween-Deko früherer Jahre (Totenkopf,
  Hexenbesen, Fledermäuse) – der Weg dorthin ist das Risiko (wie bei den Spinnweben, 5.4).
- Manche Gäste hängen Fledermäuse oder eine Spinne an ihre Tür; Gäste stellen und hängen die neue Deko wie die
  übrige an ihre Tür, Besen lehnen daneben.

### 5.8 Kürbissorten (entschieden und umgesetzt 2026-10-20)
> **Umgesetzt (2026-10-20):** sieben Sorten mit eigenem Aussehen, Tragen, Schnitzen, Deko-Stärke, Wert und Wachstum,
> Lieblingskürbisse der Gäste. **Beete:** Der Gebäudeplan hat je Sorte eine eigene Palettenfarbe („Ausstattung:
> Kürbispflanze Hokkaido“ usw.; ohne Sorte = Halloween-Kürbis). Weitere Beete malt der Nutzer im Plan.
>
> **Zerplatzen und Kürbismatsch (entschieden und umgesetzt 2026-10-22):** Ein Kürbis – auch ein geschnitzter –, der
> **tiefer als 3 m** fällt (vom Balkon, von der Galerie), zerplatzt mit einem dumpfen Klatschen; Stücke spritzen davon.
> Übrig bleibt **Kürbismatsch** (Grafik `pumpkin_splash.png`): Man kann ihn aufsammeln und in der Küche zu
> **Kürbissuppe** kochen (3.8) – jede Sorte, ohne Schneiden. Liegen gelassen, **verblasst er nach einem Spieltag ganz
> langsam, kaum merklich, und verschwindet** (nur der Matsch – Blut, Laub und Kürbisse bleiben).
>
> **Nachtrag (2026-10-22):** **Alle** Kürbisse zerplatzen, auch Zierkürbisse. Der Spritzer ist so groß wie der Kürbis
> und hat seine Farbe (halb Schale, halb Fruchtfleisch: der weiße hell, der Muskat bräunlich): Zierkürbis ~40 cm,
> Hokkaido ~50 cm, Halloween-Kürbis ~90 cm, **Riesenkürbis 4–5 m**. Der Riesenspritzer reicht für **10–20 Hände voll**
> Kürbismatsch – man sammelt ihn Hand für Hand auf, er wird dabei kleiner. Beim Aufprall **fliegen Kürbisstücke**
> (Schale und Fruchtfleisch) davon, schlagen auf, bleiben ein paar Sekunden liegen und vergehen. Der **Riesenkürbis
> lässt sich jetzt tragen** – mit beiden Händen, man geht nur gut halb so schnell und sieht über ihn kaum hinweg.

Im Garten wachsen nicht nur Halloween-Kürbisse. Welche Sorte wo wächst, bestimmt der Plan – so gibt es Beete, in denen
nur eine bestimmte Sorte wächst (der Riese nur in seinem eigenen Beet).

> **Felder im Garten (2026-10-20):** Der Mittelgarten hat jetzt acht Kürbisfelder – sieben neue mit je einer Sorte
> (Hokkaido, Weiß, Butternut, Muskat, Türkenturban, Riese, Halloween-Kürbis) neben dem alten Beet am Südende – und
> vier weitere Bäume; auch der Innenhof Südwest hat nun einen Baum (Plan `map.aseprite`).

| Sorte | Tragen | Schnitzen | Deko | Wert | Reif nach | Aussehen |
|-------|--------|-----------|------|------|-----------|----------|
| **Halloween-Kürbis** | beide Hände | ja | 10 | 4 | ~~etwa 4 min~~ 1 Tag (5.10) | groß, rund, orange |
| **Hokkaido** | eine Hand | nein | 4 | 2 | ~2,5 min | klein, rot-orange |
| **Weißer Kürbis** („Casper“) | beide Hände | ja – leuchtet kalt-weiß | 12 | 6 | ~~etwa 5 min~~ 1 Tag | groß, weiß |
| **Butternut** | eine Hand | nein | 5 | 4 | ~3,5 min | beige Flaschenform |
| **Muskatkürbis** | beide Hände | nein (zu hart) | 8 | 6 | ~~etwa 4,5 min~~ 1 Tag | flach, grün-braun, gerippt |
| **Türkenturban** | eine Hand | nein | 9 | 6 | ~4 min | rot-orange mit heller, gestreifter Kappe |
| **Riesenkürbis** | beide Hände, sehr langsam | ja | 25 | – | ~~etwa 7,5 min~~ 2 Tage | riesig (fast 1 m) |

- **Kleine Sorten** trägt man in einer Hand – Karte, Kompass und Aufschließen gehen dann weiter (3.2).
- **Geschnitzt** zählen die Sorten wie ihre Deko-Stärke: der weiße Kürbis mehr, der Riese zweieinhalbmal so viel
  wie der Halloween-Kürbis.
- **Riesenkürbis:** Beim Ernten rollt er neben das Beet, Gäste ernten ihn nie. Mit dem Messer wird er zur riesigen
  Laterne. Tragen kann man ihn (seit 2026-10-22) mit beiden Händen, aber nur gut halb so schnell wie sonst.
- **Lieblingskürbis:** Jeder Gast hat eine Lieblingssorte (nie den Riesen). Schenkt man sie ihm, freut er sich besonders
  (wie über etwas, das er mag, und noch mehr); bei anderen Kürbissen verrät er manchmal, welche er lieber hätte. Beim
  Ernten nimmt er seine Sorte zuerst, und seine eigene Kürbisdeko ist aus dieser Sorte.

### 5.9 Halloween im Hotel (vorgemerkt 2026-10-20)
Das Gefühl „Halloween mit lauter Leuten“ soll mit jedem Tag wachsen, bis zum Fest am 31. (2.1) – und der Grusel mit
ihm.
- **Das Hotel schmückt sich:** Mit jedem Tag hängt mehr Deko. Gäste tragen Girlanden und Kürbisse sichtbar durch die
  Flure, in der letzten Woche herrscht Hochbetrieb. Der Kalender wird so zum spürbaren Countdown.
  **Partyraum und Lobby sind immer voll geschmückt (entschieden 2026-10-20)** – sie sind die Treffpunkte; wachsen
  tut die Deko im übrigen Hotel. *(Für die Lobby später am selben Tag geändert: Sie wird mitgeschmückt, siehe unten.)*
  > **Umgesetzt (2026-10-20): Schmück-Aktionen.** Ab und zu ruft ein Gast zum gemeinsamen Schmücken auf – eine
  > Zimmertür, einen Flurabschnitt oder eine Flurecke in der Nähe seines Zimmers, nie Lobby oder Partyraum, am liebsten
  > dort, wo noch wenig hängt. Gäste aus der Nähe (auch Kinder) machen mit: Sie holen Deko aus ihrem Zimmer (aus dem
  > Koffer, sonst ~~etwas Gebasteltes~~ Füllmaterial wie Laub und Spinnweben, seit 5.10), tragen sie sichtbar durch den Flur und hängen bzw. stellen sie auf – oben eine
  > Lichterkette, an der Wand Lakengespenster, Fledermäuse, Spinnen und Spinnweben, am Boden Kürbisse, Totenköpfe,
  > Besen und Laub. Der Spieler wird per Meldung eingeladen, in Zimmer 13 per Anruf. Wer selbst Deko dazuhängt oder eine
  > Weile dabei ist, gewinnt die Mitmacher als Freunde, sein Schock sinkt; allen Mitmachern sinkt die Angst.
  > Schmücken ist **Spaß** – es lockt also den Kürbismann (4.19), Mitmacher wie den Spieler.
  > **Auch die Lobby und die Zimmer (entschieden 2026-10-20, ersetzt „Lobby immer voll geschmückt“):** Etwa jede dritte
  > Aktion schmückt eine Wand der Lobby – dafür kommen Gäste aus dem ganzen Hotel. Außerdem trägt ab und zu ein Gast
  > **allein** ein Stück Deko herum: Er holt es aus einer Kiste im Hotel (Dekokiste, Wäschekiste, Laub im Garten – nie
  > aus dem Keller) und hängt es in **seinem Zimmer** auf, oder er bringt etwas aus seinem Koffer **in die Lobby**. Am
  > Monatsanfang alle ein, zwei Minuten einer, am Ende fast ständig jemand; bis zu drei gleichzeitig. Nur der
  > Partyraum bleibt, wie er ist. Nie während
  > einer Feier, in der Nachtruhe oder wenn das Monster, der Lakengeist oder der Kürbismann unterwegs ist – kommt so etwas
  > dazwischen, laufen alle auseinander. Am Monatsanfang etwa alle zwei Tage mit zwei, drei Leuten, am Ende mehrmals am
  > Tag mit sechs, sieben; die Deko bleibt hängen, so wächst sie bis Halloween. Debug: `--decorate[=gast][,hin]`.
  >
  > **Selbst aufrufen, große Aktionen, mehrere zugleich (entschieden 2026-10-21):**
  > - **Selbst aufrufen:** Im Gespräch ab „nett“: „Lass uns hier schmücken!“ – geschmückt wird, **wo du stehst**:
  >   an einer Zimmertür (auch an **Zimmer 13** – die Deko gehört weiter den Gästen, schützt aber dein Zimmer), im
  >   Flur oder in der Lobby; nie im Partyraum. Der Gast ruft, seine **Freunde** (6.16) kommen zuerst, dann wer in
  >   der Nähe wohnt. Je Gast einmal am Spieltag, nicht während Feier, Nachtruhe oder Unruhe. Du giltst als dabei.
  > - **Mehrere zugleich:** Ab Monatsmitte laufen bis zu zwei Aktionen der Gäste gleichzeitig an verschiedenen
  >   Stellen, dazu deine eigene.
  > - **Immer jemand unterwegs:** Dauerhaft sind mindestens ein (ab Monatsmitte zwei) Gäste gemächlich mit Deko im
  >   Hotel unterwegs – die Hälfte davon bringt ihr Stück irgendwohin, wo noch am wenigsten hängt, auf allen
  >   Stockwerken. So ist am Ende alles festlich geschmückt.
  > - **Großes Schmücken:** Ab und zu schmücken **10–20 Gäste aus dem ganzen Hotel** einen ganzen Flurbereich
  >   (drei bis fünf Stellen nebeneinander: Türen, Flurwände, Ecken) oder die Lobby samt Fluren davor. Jeder trägt
  >   einen **Armvoll Deko** (zwei, drei Stücke auf einmal) und hängt sie nacheinander auf – die Flure sind voll von
  >   Gästen mit Deko. Am Monatsanfang etwa alle drei Tage, gegen Ende häufiger, in der letzten Woche täglich.
  >   Angekündigt per Meldung bzw. Anruf in Zimmer 13. **Selbst ausrufen:** im Gespräch „Großes Schmücken ausrufen!“,
  >   wenn mindestens acht Gäste mit dir mindestens „freundlich“ sind – einmal am Spieltag, geschmückt wird rund um
  >   die Stelle, an der du stehst. Belohnung wie bei den kleinen Aktionen, für jeden Mitmacher.
  >
  > **Deko-Suche mit Gästen (entschieden 2026-10-21):** Gäste gehen auch **auf Deko-Suche**: Laub im Garten,
  > Dekokiste, Wäschekisten, Kommoden – Mutige auch Spinnweben in dunklen Ecken oder die alte Deko im Keller. Trifft
  > ein suchender Gast dich, fragt er „Ich geh Deko suchen – kommst du mit?“; du kannst auch selbst fragen
  > („Lass uns zusammen Deko suchen“, ab „nett“). Dann **führt er, du folgst** – er wartet, wenn du zurückfällst, und
  > gibt auf, wenn du ihn ganz verlierst. Am Fundort nimmt er zwei Stück und **gibt dir eins ab** (in die Hand, sonst
  > vor die Füße). Danach trägt er seins heim und hängt es auf. **Anerkennung:** Beziehung +8 bei ihm, und er
  > **erzählt es seinen Freunden** (6.16) – die mögen dich auch etwas mehr (+3). Zwei Gäste suchen manchmal auch
  > zusammen und werden dabei Freunde.
- **Kostüme ab etwa dem 25.:** Gäste verkleiden sich (Hexe, Vampir, Kürbiskopf, Bettlaken). Das **Bettlaken** (bei
  Erwachsenen und Kindern, siehe Vorschlag in 6.13) ist der Kern: Eine Lakengestalt im dunklen Flur – Gast oder
  Lakengeist? Unterscheiden kann man sie nur, wenn man genau hinsieht: Gäste haben Schuhe, gehen statt zu schweben,
  hinterlassen keine Flocken (7.6) und man hört keinen Geisterklang. Der Spieler kann sich selbst verkleiden (Laken
  im eigenen Zimmer); Gäste erkennen ihn dann schlechter – als Zeugen beim Klauen, aber auch beim Grüßen.
  > **Umgesetzt (2026-10-20):** Ab dem **25.** tragen etwa sieben von zehn Gästen ein festes Kostüm (je nach Gast):
  > **Bettlaken** (ein Viertel, bei Kindern 40 %), **Hexenhut**, **Kürbiskopf** mit glühendem Gesicht oder
  > **Vampirumhang** mit rotem Kragen. Das Laken hat Augen- und Mundlöcher wie der Lakengeist und endet knapp über
  > dem Boden – die Schuhe und gehenden Füße schauen heraus, die Arme bleiben darunter (beim Tanzen nicht).
  > Unter dem Laken zeigt der Gast **keinen Namen**. Im Bett wird es ausgezogen. Debug: `--costumes[=art]`.
  > **Selbst verkleiden (umgesetzt 2026-10-20):** Auf dem Bett in Zimmer 13 liegt ein **Bettlaken**. In der Hand
  > + [Linksklick] wirft man es über, [G] mit leeren Händen nimmt es wieder ab. Man sieht nur noch durch zwei
  > ausgefranste Augenlöcher. Gäste erkennen einen nur aus **1,5 m**: Wer weiter weg beim Klauen zusieht, ruft
  > „Ein Gespenst klaut Deko!“ statt einen zu verpetzen; Verfeindete greifen nicht an, Wütende rempeln nicht,
  > gute Freunde schließen sich nicht an, Kinder bringen keine Geschenke. Wer den Spieler im Laken zum ersten Mal
  > sieht, staunt („Huch! … Ach, ein Kostüm.“) – im Dunkeln erschrickt er wirklich, Kinder freuen sich. Im
  > Gespräch: „Wer steckt denn da drunter? … Ach, du bist's!“ Debug: `--disguise`.
- **Verkleiden aus Fundstücken (vorgemerkt 2026-10-23):** Spieler **und Gäste** ziehen sich einfache Verkleidungen
  an – einen **Kürbis als Hut**, **Masken**, **Gespensterlaken** oder andere kleine Gegenstände. Vorschläge: Ein
  geschnitzter, **brennender Kürbis auf dem Kopf leuchtet** – man trägt Licht, das das Monster sieht (4.15).
  **Masken** sind ein neuer Gegenstand; woher (Kiste im Partyraum, basteln, von Gästen) ist offen.
- **Maskenspiel „Wer steckt dahinter?“ (vorgemerkt 2026-10-23):** Ein Spiel im **Partyraum** mit den Gästen. Alle
  Mitspieler tragen Masken, die **Namen über ihnen verschwinden**, und man muss erraten, wer wer ist – **einmal je
  Gast**. Man sammelt **Beliebtheit**: stärker, wenn man richtig rät, aber auch falsch geraten, weil das Spiel den
  Gästen Spaß macht. Vorschläge:
  - **Fair raten:** Die Maske verdeckt Gesicht und Haare; **Kleidung, Größe, Statur, Schuhe und Stimme** bleiben – genau
    das, was der Gastgenerator variiert (6.0). Wer die Gäste kennt, gewinnt. Laken sind beim Spiel nicht erlaubt.
  - **Ablauf:** einen Maskierten ansprechen, einen Namen aus der Liste der Mitspielenden wählen.
  - **Beliebtheit** über die Beziehungen (6.2): richtig **+8**, falsch **+3** (er lacht), dazu ein wenig bei allen
    Mitspielern.
  - **Spaß ruft den Kürbismann:** Das Spiel zählt wie Spieltisch und Feier stark für den Spaßwert (4.19).
  - **Wann:** abends; ausrufen wie das große Schmücken, Gäste starten es auf Feiern auch selbst.
  - **Twist: eine Maske zu viel** – acht spielen mit, neun stehen im Raum: der hereingebetene Vampir (4.22) oder eine
    Halluzination.
  - **Offen:** neuer, hotelweiter Wert „Beliebtheit“ statt der Beziehungen? Erst ab dem 25. oder schon früher?
- **Gruselgeschichten-Abend:** Abends sitzen Gäste bei Kerzen in der Lobby und erzählen Geschichten – mit wenig
  Licht, also nicht ohne Risiko (4.4). Manche Geschichten enthalten **echte Hinweise** auf das Geheimnis (2.3);
  Mitwisser verraten sich dabei. Erzählt der Spieler selbst eine, steigt die Angst der Zuhörer und damit ihre
  Schwäche (4.18) – das geht auch gezielt gegen Feinde.
- **Gemeinsam etwas tun:** Kürbissuppe in der Küche kochen (Kürbis, Messer; wer mitisst, hat weniger Angst und
  mag den Spieler mehr – entschieden 2026-10-21, siehe 3.8), die Lobby zusammen schmücken, der Kürbis-Schnitz-Wettbewerb (6.10) mit der Puppe als
  Jury (5.5, vorgemerkt).
- **Alte Bräuche als Schutz:** eine **Kerze ins Fenster** (hält den Lakengeist vielleicht fern, ohne den Vorhang
  zuzuziehen), **Salz** vor die Tür, **Rübenlaternen** als ältere Form des Kürbisses. Sie dürfen nie ganz sicher
  machen – offen, wie stark sie wirken.
- **Durchsagen:** Die Rezeption sagt über Lautsprecher an, was im Hotel passiert („Die Bar schließt um
  Mitternacht“, „Feier im Partyraum“, Nachtruhe). Nachts klingen sie verzerrt – und manchmal kommt eine Durchsage,
  die es nicht geben dürfte: der Name eines Verschwundenen, „Zimmer 13 wird erwartet“. Wer spricht da (2.3)? Alle
  Durchsagen notiert die Figur mit Uhrzeit im Notizbuch (3.10) – die falschen genauso nüchtern wie die echten.
- **Gruppenfoto an Halloween:** Beim Fest am 31. ein Gruppenbild aller Überlebenden – mit leeren Plätzen für die
  Verschwundenen. Es landet im Tagebuch bzw. im Abspann. Mit der Zeitschleife (2.2) hängt das Foto des letzten
  Durchgangs in der Lobby – und man steht selbst darauf. Wer zum Vampir geworden ist, **fehlt auf dem Bild** (4.22,
  vorgemerkt 2026-10-23).

### 5.10 Knappheit, Wert & Verfall (entschieden 2026-10-21, Stufe 1 umgesetzt 2026-10-23)
> Macht den Pitch (1) wahr – „Die Deko ist knapp“ – und ändert Anspruch (4.8), Abschreckung (4.9) und Schutzbereich
> (4.12). In drei Stufen: **1** Anspruch, Kisten, Kürbisse und Verfall · **2** Schutzkreis = Lichtschein, sichtbare
> Abweisung (Teil 3 unten) · **3** Gäste schmücken mit Plan und klauen bei Knappheit (Teil 5).
>
> **Stufe 1 umgesetzt (2026-10-23)** mit diesen Zahlen aus der Durchsprache am selben Tag:
> - **Anspruch** gleitend von ×1 am 2. Oktober bis ×3 an Halloween, dann gedeckelt (bisher +100 % alle drei Tage,
>   also ×11). Grob gerechnet braucht eine hell beleuchtete Tür zur Monatsmitte 2–3, an Halloween 4 geschnitzte
>   Kürbisse mit Licht.
> - **Füllmaterial** (Laub, Spinnweben, Kerzen, Zierkürbisse, Hokkaido, Butternut, Turban) zählt an einer Stelle
>   **zusammen höchstens 20** – in den ersten Tagen ein Grundschutz, ab etwa dem 5. reicht es allein nie (beantwortet
>   „wie stark Füllmaterial sein darf“; bis Stufe 2, in der Deko ohne Licht ohnehin nur halb zählt).
> - **Kisten ohne Nachschub:** Dekokiste je 15 (Lichterketten, Fledermäuse, Spinnen), Wäschekiste 8 Lakengespenster,
>   alte Deko im Heizkeller 10 (Totenköpfe, Besen, Fledermäuse). Gäste nehmen aus jeder Kiste **höchstens ein Stück am
>   Spieltag** – so leeren sie sich gegen die Monatsmitte, mit dem Spieler schneller. Dekokisten trägt der Plan
>   (`map_a`) noch nicht – sie kommen von Hand dazu.
> - **Nichts Starkes mehr aus dem Nichts:** Mit leerem Koffer bringen Gäste beim Schmücken nur noch Füllmaterial
>   (Laub, Spinnweben, Zierkürbisse); Lichterketten oben nur aus dem Koffer. Allein-Schmücken und Deko-Suche
>   verbrauchen den Vorrat der Fundorte (mit dem Tageslimit der Kisten). Katzen bringen weiter einmal am Tag etwas.
> - **Große Kürbisse:** Halloween, Weißer und Muskat werden je Beet **einmal am Tag** reif, der Riese alle zwei Tage;
>   **Frost ab dem 25.**: Danach tragen große Beete nicht mehr (neu). Kleine Sorten wachsen wie bisher (3c beantwortet).
> - **Faulen:** geschnitzte nach 3 Tagen, ungeschnitzte und Zierkürbisse nach 7; ab 60 % der Zeit **welk** (dunkler,
>   zählt ×0,7), ab 85 % **eingefallen** (gestaucht, ×0,4), dann weg. Schnitzen setzt die Restzeit auf höchstens 3 Tage.
>   Was im Koffer eines Gastes liegt (nur gezählt), fault nicht.

**Die Probleme bisher**
- **Zu viel:** Jede Quelle wächst nach (Laub, Kerzen, Lakengespenster, alte Deko im Keller, über 60 Beete), dazu
  schmückt sich das Hotel selbst (5.9), Freunde schenken, Katzen bringen. Wer etwas braucht, wartet – Handel und
  Klauen lohnen nicht, die Kernfrage „vertrauen oder nehmen?“ stellt sich nicht.
- **Wird wertlos:** Der Anspruch wuchs ohne Obergrenze (an Halloween etwa ×11, mit der Tagesuhr 2.4 sogar ×50) –
  ab Monatsmitte schützte Deko faktisch nicht mehr, ohne dass man es merkte.
- **Unsichtbar:** Radius, Stockwerk und dass nur das Ziel geschützt ist, waren nicht zu erkennen.
- **Einmal hingestellt, erledigt:** Außer Kerzen nutzte sich nichts ab.
- **Gäste schmückten ohne Plan:** dort, wo wenig hängt, nicht dort, wo es gefährlich ist.

**Grundidee: am Anfang Fülle, am Ende Mangel** – passend zur Dramaturgie (2.1)

| Phase | Deko | Gefühl |
|-------|------|--------|
| Erste Woche | Kisten voll, jeder schenkt | Party-Spiel |
| Monatsmitte | Kisten werden leer, Kürbisse faulen, der Anspruch steigt | planen und pflegen |
| Letzte Woche | starke Deko gibt es nur noch an fremden Türen | vertrauen oder nehmen? |

**Einmalig und am stärksten:** Schädel, blutige Axt und Jeansjacke des Kürbismanns nach seiner Erlösung (4.21).

**1. Zwei Klassen von Material**
- **Füllmaterial wächst nach:** Laub, Spinnweben, Zierkürbisse, Kerzen und die kleinen Kürbissorten (5.8). Schwach,
  ein Grundschutz.
- **Starke Deko ist endlich:**
  - Lichterketten, Totenköpfe, Lakengespenster, Fledermäuse, Besen und die alte Deko kommen aus **Kisten, die sich
    leeren** (Dekokiste, Wäschekisten, alte Deko im Keller, zuletzt das Lager im Tiefkeller als Schatz, 7.4).
  - **Große Kürbisse** (Halloween-Kürbis, Weißer, Muskat, Riese) tragen je Beet höchstens **einmal am Tag** (Wachstum in
    Spielstunden, 2.4).
  - Die **Startdeko der Gäste** ist ihr eigener Vorrat. Was ein Gast verschenkt (6.3), fehlt ihm an seiner Tür – ein
    Geschenk ist ein Stück seines Schutzes.
- **Gäste nehmen aus denselben Kisten.** Das Schmücken (5.9) verbraucht den gemeinsamen Vorrat; in der letzten Woche
  sind die Kisten leer, und die einzige Quelle für starke Deko sind die Türen der anderen.

**2. Anspruch an den Tag gebunden und gedeckelt** (ändert 4.8)
- Der Anspruch steigt in **Spieltagen** statt Sekunden: von **×1** beim ersten Angriff auf etwa **×3 an Halloween**.
- Eine Tür mit drei, vier starken Stücken und Licht schützt damit bis zum Schluss; ein einzelner Kürbis reicht ab
  Monatsmitte nicht mehr.
- Zusammen mit der Puppe (5.5): Der Anspruch entscheidet, **ob** eine Tür hält, die Puppe, **wer** der Schwächste
  ist. Gut schmücken lohnt sich immer – beim Nachbarn klauen aber auch.

**3. Schutz ist dort, wo ihr Licht hinfällt** (ändert 4.9, 4.12)
- Der **Schutzkreis einer Deko ist ihr sichtbarer Lichtschein** – Kürbis, Totenkopf mit Kerze, Lichterkette, Kerze.
  Lernbar ohne Anzeige: *Wo der Kerzenschein hinfällt, bin ich sicher.* Der bisherige Licht-Faktor der Abschreckung
  geht darin auf.
- **Deko ohne Licht** (Laub, Spinnweben, Fledermäuse, Spinne, Besen, ungeschnitzte Kürbisse) zählt **nur halb und nur
  direkt an der Tür**.
- **Abweisung sichtbar machen:** Weist Deko das Monster ab, **ducken sich die Flammen** und die Deko schwingt – man
  sieht, dass sie gerade gewirkt hat.

**4. Verfall**
- Kerzen brennen ab (wie bisher), das Monster bläst sie aus (4.13).
- **Kürbisse faulen:** geschnitzte nach etwa **drei Tagen**, ungeschnitzte nach etwa **einer Woche** – erst welk, dann
  eingefallen, dann weg. **Laub wird zertreten.**
- Pflege wird tägliche Aufgabe; daraus entstehen Wünsche für Aufträge („Mein Kürbis fault“, 6.14).

**5. Gäste schmücken mit Plan – und klauen bei Knappheit**
- **Wer Angst hat, schmückt zuerst die eigene Tür.** Nach einem Todesfall in der Nähe schmücken die Nachbarn nach.
- **Freunde schmücken auch die Türen ihrer Freunde** (6.16) – Freundschaft schützt im Horror, auch die Tür von
  Zimmer 13.
- **Diebstahl unter Gästen:** Wird es knapp, klauen Gäste auch einander (füllt „Streit unter Gästen“, 6.16). Weil die
  Puppe relativ urteilt, macht jeder Diebstahl jemanden zum Schwächsten.

**Zu klären:** Inhalt und Größe der Kisten (wann genau sie leer sind) · wie stark Füllmaterial im Verhältnis zum
Anspruch sein darf, damit es nie allein reicht · ob die Gäste-Startdeko für die Kernfiguren (6.0) größer ist.

### 5.11 Feuer: Deko kann brennen (entschieden 2026-10-22)
> **Umgesetzt (2026-10-22).**
- **Was brennt:** nur leichte Deko – Laub, Spinnweben, Lakengespenster, Fledermausgirlanden, Plastikspinnen,
  Hexenbesen, Bettlaken. Kürbisse, Totenköpfe, Kerzen und Lichterketten nicht; **Möbel und das Hotel nie**.
- **Wie es anfängt:** Eine **brennende Kerze**, die ein Kind vor eine Tür wirft (6.13), zündet leichte Deko in der Nähe
  an. Feuer springt auf leichte Deko daneben über.
- **Brennen:** Die Deko lodert ein paar Sekunden (Flammen, Licht, Knistern – Lärm, 4.15) und ist dann weg; zurück
  bleibt ein Rußfleck. Die Tür ist danach schwächer – vielleicht schwach genug für die Puppe (5.5).
- **Löschen:** Der Spieler kann brennende Deko austreten [E]; was gelöscht ist, bleibt angesengt erhalten.
- Brennende Deko zählt nicht als Deko, aber als Licht.

## 6. Die anderen Gäste (NPCs)

### 6.0 Gäste im Prototyp
| Gast | Zimmer | Persönlichkeit | Besonderheit |
|------|--------|----------------|--------------|
| **Edna** | 11 | freundlich, sehr ängstlich | Kerzen, versteckt sich beim ersten Flackern |
| **Bruno** | 12 | mürrischer Händler, mutig, gierig | teure Preise, erntet Kürbisse, klaut schnell, wenn er dich nicht mag |
| **Mila** | 15 | junge Künstlerin, gesprächig | erntet und schnitzt Kürbisse, verbreitet Gerüchte am stärksten |
| **zufällige Gäste** | freie Zimmer | einer von sechs Charakteren | siehe unten |

**Zufällig erzeugte Gäste (umgesetzt 2026-10-11):** Neben den drei festen Figuren erzeugt das Spiel zu Beginn weitere Gäste, sodass **67** im Hotel sind (seit 2026-10-20, vorher 30; davon **13 Kinder**; seit 2026-10-24 in 39 festen Haushalten, 6.20; es kommen keine neuen hinzu, siehe unten). Jeder hat einen Namen, einen Charakter (**ängstlich, geschäftstüchtig, Plaudertasche, Skeptiker, Bastler, Griesgram**) mit passenden Werten (Mut, Gier, Tratsch, Preise, Zuverlässigkeit), eigene Sätze (gemischt mit einem gemeinsamen Grundstock), Vorrat und Start-Deko, Würfelstil mit verräterischer Geste, Kleidungsstück, Farben und Größe.
- ~~**Nie weniger als 24:** Sterben Gäste und sind weniger als 24 am Leben, **wacht nach einigen Minuten ein neuer Gast in einem freien Zimmer auf** – das Hotel ist ja verschlossen. Er weiß nicht, wie er hergekommen ist („Ich bin in Zimmer 27 aufgewacht …“). Man hört eine Tür, in seinem Zimmer geht das Licht an.~~ Im Code zuletzt 33 statt 24. **Zurückgenommen (2026-10-21):** Es kommen **keine neuen Gäste** hinzu. Wer stirbt, ist weg (6.7) – das Hotel ist ab dem 1. Oktober verschlossen (2.3), und jeder Tod soll zählen. Zimmer von Verschwundenen bleiben leer.

**Drei Ebenen von Gästen (entschieden 2026-10-21):** Es bleibt bei **67 Gästen**, aber nicht alle sind gleich wichtig.
Inhalt (eigene Sätze, Geschichte, Aufträge) wird nach dieser Rangfolge gebaut:

| Ebene | Anzahl | Wer | Was sie bekommen |
|-------|--------|-----|------------------|
| **Kernfiguren** | 4 | Edna, Bruno, Mila (6.0) und die **Tochter des Heizers** (2.3, entschieden 2026-10-21) | Klare Priorität: eigene Geschichte, Mitwisser des Geheimnisses (2.3), eigene Aufträge (6.14), die meisten eigenen Sätze |
| **Zentrale Gäste** | ca. 10–12 | noch zu besetzen | Fester Name und Zimmer, ein eigener Faden (Wunsch, Sorge, Beziehung zu anderen), tragen die Beziehungsnetze (6.16) |
| **Übrige Gäste** | der Rest (ca. 50, mit den Kindern) | erzeugt (`GuestGenerator`) | Füllen das Hotel: schmücken, feiern, tratschen, reagieren – und sind Monsterfutter. Kein eigener Inhalt über Charakter und Grundstock hinaus |

- **Mehr retten ist trotzdem besser:** Auch die übrigen Gäste zählen am Ende (siehe „Zu klären“).
- Die Systeme (Beziehung 6.3, Schreck 6.12, Verletzungen 6.17) gelten weiter für alle; die Ebenen bestimmen nur, wie
  viel eigener Inhalt dazukommt.

**Zu klären**
- ~~**Wer die vierte Kernfigur ist**~~ – die Tochter des Heizers (2026-10-21). Offen: welche Rolle Edna, Bruno und Mila
  im Geheimnis spielen.
- **Können Kernfiguren sterben?** Das Konzept sagt ja (2.3: „Sie können lügen und sterben“); dann ist ihr Wissen weg
  oder liegt nur noch als Notiz im Zimmer.
- **Balance ohne Nachschub:** Das Monster darf das Hotel nicht vor Halloween leeren. Angriffschance (4.17), Opferzahl,
  Überlebende (6.17), Lakengeist und Kürbismann müssen gegen 54 Erwachsene ausbalanciert werden. Der Kürbismann regelt
  sich selbst (er braucht 15 Gäste, die Spaß haben, 4.19).
- **Wofür das Retten zählt:** Wenn der Schlüssel an Halloween nur für einen die Tür öffnet (2.3), muss das Ende (2.1)
  sagen, was die Geretteten bewirken – zum Beispiel das Gruppenfoto mit den leeren Plätzen (5.9) oder ein anderes Ende.
- Aus einem Seed entsteht immer derselbe Gast; Spielstände speichern nur Seed und Zimmer (`scripts/guests/guest_generator.gd`).

**Gastmodelle (geplant 2026-10-17, erster Grundkörper „Mann“ eingebaut 2026-10-17, „Frau ~40“, „junge Frau“, „junger Mann“, „alte Frau“ und „alter Mann“ 2026-10-20 – damit alle sechs, Generation
je Vorname in `GuestGenerator.OLD`/`YOUNG`):** Die Klötzchen-Gäste werden durch Meshy-Modelle ersetzt – keine Einzelmodelle, sondern **eigene Modelle für Edna, Bruno und Mila** und **6–8 Grundkörper** (Frau/Mann × jung/mittel/alt, evtl. weitere Statur) für die erzeugten Gäste. Jeder Grundkörper ist eine ganze Figur mit eigenem Kopf; alle haben denselben Knochenaufbau (Meshy-Auto-Rigging mit Skelettvorlage Mixamo), Animationen gibt es deshalb nur einmal. Der Grundkörper folgt aus Geschlecht und Generation des Namens und wird reihum statt zufällig verteilt, damit sich keiner häuft.
- **Variiert wird:** Körpergröße **150–185 cm** (selten über 190), Breite **35–50 cm**, Körperbau (schlank bis kräftig), Kleidungs- und Haarfarbe (Einfärben über Masken), seit 2026-10-23 auch der **Hautton** (acht Stufen von sehr hell bis sehr dunkel, Kinder wie ein Elternteil). Kleidung auch hell und bunt (Weiß, Hellrot, Pastell), Hosen zu gut einem Drittel Jeans. Das Kleidungsstück („Lottes Hut“) wird, wo es geht, als echtes Teil am Körper sichtbar.
- **Vorerst nicht:** getrennte Frisuren, andere Kleidungsschnitte, Augenfarbe.
- Modelle in Meshy: A-Pose, Kleidung und Haare entsättigt hell- bzw. mittelgrau (Ober- und Unterteil verschieden), keine Muster, keine Accessoires, Haare nicht auf den Schultern, keine eingebrannten Schatten.

### 6.1 Rolle
- Leben ebenfalls im Hotel, haben eigene Zimmer, eigene Deko, eigene Persönlichkeit.
- Sind **Handelspartner, potenzielle Freunde – und potenzielle Gegner**.

### 6.2 Beziehungssystem
- Jeder Gast hat einen **Beziehungswert** zum Spieler (z. B. -100 … +100).
- **Positiv** beeinflusst durch: nette Dialogoptionen, Geschenke, Gefallen, faire Trades, Hilfe bei Monster-Ereignissen.
- **Negativ** beeinflusst durch: unhöfliche Antworten, Deko-Diebstahl, schlechte Trades, „blöde Aktionen“ (z. B. Lärm vor deren Tür, Monster anlocken).
- Optional: **Ruf / Gerüchte** – Gäste reden miteinander, schlechtes Verhalten spricht sich herum. **Seit 2026-10-21:**
  über das Freundesnetz, Gutes wie Schlechtes (6.18).

### 6.3 Konsequenzen – neun Stufen (entschieden und umgesetzt 2026-10-18)

| Stufe | Wert | Verhalten des Gastes |
|-------|------|----------------------|
| **Guter Freund** | ≥ 80 | Nur mit Taten (unten). Besucht dich in Zimmer 13 zum Quatschen, geht von sich aus ein Stück mit, bester Preis |
| **Befreundet** | 55 … 80 | Schenkt Deko, kommt auf Bitte mit („Komm mit“), warnt am Telefon, guter Preis |
| **Freundlich** | 30 … 55 | Warnt am Telefon, kommt zur Feier, fordert zum Spielen heraus, kleiner Rabatt |
| **Nett** | 10 … 30 | Plaudert am Telefon, etwas Rabatt |
| **Neutral** | −10 … 10 | Normaler Handel |
| **Genervt** | −30 … −10 | Kurz angebunden, sagt Einladungen ab |
| **Wütend** | −55 … −30 | Klaut deine Deko, spielt nicht mehr mit dir, rempelt dich im Vorbeigehen an |
| **Verfeindet** | −80 … −55 | Redet nur noch, wenn du dich entschuldigst; lügt am Telefon |
| **Stark verfeindet** | ≤ −80 | Nur mit Taten (unten). Droht dir und **schlägt zu**, wenn er dich allein erwischt |

- **Langsamer nach oben:** Je besser man schon steht, desto weniger bringt jede nette Tat (bei 50 gut die Hälfte). Plaudern zählt pro Tag nur zweimal voll, danach kaum noch. **Seit 2026-10-21:** gilt für alle freundlichen Gesten zusammen, dazu eine Gesprächsbereitschaft nach Stufe (6.18).
- **Die Extreme brauchen Taten, nicht nur Punkte:**
  - **Guter Freund:** mindestens 3 gemeinsame Partien (Mäxchen oder Schach), 2 Geschenke an ihn **und** 1 Gegenstand von ihm (Deko geschenkt bekommen oder gekauft) – Austausch in beide Richtungen. Bis dahin bleibt er bei „befreundet“ stehen.
  - **Stark verfeindet:** mindestens 4 feindselige Taten von dir (Deko klauen, beleidigen, rammen, schlagen) **und** er hat sich mindestens einmal gerächt (dich bestohlen, angerempelt oder geschlagen). Bis dahin bleibt er bei „verfeindet“.
- **Zerfall:** Oberhalb von „befreundet“ und unterhalb von „verfeindet“ wandert der Wert ohne Kontakt langsam zurück (gut 1 Punkt pro Tag). Feindselige Taten verblassen über Tage (Vergebung, 6.18).
- **Rammen:** Rennst du in einen Gast, stolpert er – Beziehung ↓, Zeugen merken es. Wütende Gäste rempeln dich ihrerseits im Vorbeigehen an (du wirst weggeschubst).
- **Schlagen (Linksklick auf einen Gast in Armlänge, ohne Taschenlampe in der Hand):** Beim ersten Mal fragt das Spiel nach („Wirklich zuschlagen?“ – zweiter Klick). Der Gast fällt sofort auf höchstens „wütend“, Zeugen mögen dich weniger, es spricht sich herum, Schläge machen Lärm (Neugier des Monsters). Ängstliche Gäste fliehen, mutige oder stolze schlagen zurück. Ein geschlagener Gast ist eine Weile langsamer. **Kinder** kann man nicht schlagen (6.13).
- **Verletzungen des Spielers:** Schläge von Gästen verletzen dich – roter Blitz, du wirst langsamer und hinterlässt Blutstropfen (Spur fürs Monster, 4.13). Heilt mit der Zeit; ein Gast kann dich nicht töten.
- **Besuch:** Gute Freunde klopfen ab und zu ruhig an Zimmer 13 („Hast du kurz Zeit?“). Machst du auf, kommen sie eine Weile herein; ignorieren kostet kaum etwas.
- **Mitkommen:** Befreundete Gäste folgen dir auf Bitte etwa zwei Minuten (oder bis du sie wegschickst, dich versteckst oder sie in Panik geraten). Gute Freunde schließen sich manchmal von selbst an. Ein Begleiter ist Schutz und Gefahr zugleich – er ist ein Opfer mehr, das das Monster holen kann.

### 6.4 Handel
- **Geld** als Währung (einziger abstrakter Besitz, siehe 3.2) – Kaufen und Verkaufen von Deko & Gegenständen.
- Zusätzlich **Tausch** (Gegenstand gegen Gegenstand) und **Gefallen**.
- Handel ist physisch: Der Spieler muss den Gegenstand in der Hand zum Gast bringen bzw. bekommt ihn in die Hand gedrückt.
- Offen: Woher kommt Geld? (Startgeld, Fundstücke, Verkauf von Kürbissen, Aufträge für Gäste?)
- Gäste haben Bedürfnisse/Wünsche (z. B. „Ich brauche Batterien“, „Bring mir etwas aus der Küche“).

### 6.5 Panik
- Gäste können **vom Monster erfahren** (eigene Sichtung, Gerüchte, Gespräch mit dem Spieler).
- Ein Gast in **Panik**: rennt umher, schließt sich ein (Feinde schließen auch vor dem Spieler ab, 6.18), handelt nicht, macht Lärm, plündert evtl. Deko anderer, um sich selbst zu schützen.
- Spieler kann Gäste **beruhigen** (Gespräch, Deko schenken) → Beziehung ↑.
- **Über Erfahrungen sprechen:** liefert Hinweise (wo es gesehen wurde, was es mag/meidet), aber das Monster hört evtl. mit (4.7).

### 6.6 Gäste-KI & Pathfinding
- Gäste werden **vom Spiel gesteuert** und nutzen **dieselben Interaktionen wie der Spieler**:
  - Gegenstände in den Händen tragen, ablegen, klauen
  - Türen öffnen/schließen/abschließen, Truhen benutzen
  - Deko platzieren (vor ihrer eigenen Tür)
  - Sich in Schränken / unter Betten verstecken (v. a. in Panik)
  - Im Garten ernten
- **Pathfinding:** Gäste bewegen sich über ein NavMesh durchs Hotel, über Etagen (Treppen), durch Türen.
- **Entscheidungen** über einfache Bedürfnisse/Ziele (Utility-KI): z. B. *Sicherheit*, *Deko besitzen*, *Handeln*, *Ruhe*, *Rache* (bei schlechter Beziehung → Deko klauen).
- **Tagesablauf:** Essen im Speisesaal, im Zimmer sein, Garten, Lobby → der Spieler kann Gewohnheiten lernen (wann ist welches Zimmer leer?). **Entschieden 2026-10-21:** vier Phasen – Morgen, Tag, Abend, Nacht – nach der Tagesuhr (2.4); innerhalb der Phasen zufällig.
- **Reagieren auf das Monster:** Vorwarnung erkannt → Panik → nächstes freies Versteck suchen.

### 6.7 Gäste können sterben
- Das Monster kann Gäste holen: im Flur, in dunklen Bereichen, aus Verstecken (wenn es gesehen hat, wie sie hineingingen).
- Gestorbene Gäste sind **dauerhaft weg**.
- **Folgen in der Welt:**
  - Sein Zimmer steht leer; seine Deko und Gegenstände sind „herrenlos“ → Gäste (und Spieler) streiten sich darum.
  - Andere Gäste geraten in Panik, Dialoge ändern sich, die Feierstimmung in der Lobby kippt.
  - Monster ist gesättigt (4.10).
- Evtl. Spuren: zerkratzte Tür, umgekippte Deko, ein einzelner Schuh im Flur – Andeutung statt Gore, passend zum diffusen Horror.
- **Das Monster** lässt keine Leiche zurück, nur Blut und ein Kleidungsstück. **Der Lakengeist** (4.18) schon: Wen er
  erwürgt, der bleibt liegen (2026-10-18). Wer Blut oder Leiche sieht, erschrickt und erzählt davon (6.12).

### 6.8 Schock & Trauer (Ideen – noch zu diskutieren)
> **Stand 2026-10-21:** Großteils schon umgesetzt (Schock nach Beziehung, Zittern, Fallenlassen, kürzeres Verstecken,
> „Angst riecht“, Halluzinationen, Anrufe Toter, Gedenkkerze, Feier). Schock und Trauer werden ein Wert, Schuld folgt
> aus der Ursache jedes Todes, und die Freunde des Toten trauern mit – siehe 6.18 (2).

Stirbt ein Gast, mit dem man **gut befreundet** war, erleidet der Spieler einen **Schock** mit einem Malus. Stärke abhängig vom Beziehungswert.

**Mögliche Mali (Vorschläge):**
- **Zittrige Hände:** Gegenstände rutschen gelegentlich aus der Hand; Schnitzen wird ungenauer → schwächere Kürbisse.
- **Unruhiger Blick:** Leichtes Kamerazittern, Tunnelblick, schwereres Atmen (lauter → schlechter beim Verstecken).
- **Kürzere Zeit im Versteck:** Panik setzt schneller ein.
- **Halluzinationen:** Falsche Vorwarnungen (Flackern/Rauschen ohne Monster), die Stimme des Freundes, Silhouetten, die keine sind → man weiß nicht mehr, was echt ist.
- **Angst riecht:** Das Monster wird in der Nähe des Spielers neugieriger (Neugier ↑ um den Spieler).
- **Sozial:** Weniger Lust/Optionen für Smalltalk & Handel.

**Erholung (Vorschläge):**
- Mit anderen Freunden über den Verstorbenen reden (aber: Monster hört evtl. mit → 4.7).
- **Gedenken:** Eine Kerze / einen geschnitzten Kürbis vor die Tür des Verstorbenen stellen.
- An einer Feier in der Lobby teilnehmen (7.1).
- Zeit.

**Schuld vs. Trauer:**
- **Trauer** (Freund ist einfach gestorben): Malus wie oben, klingt ab.
- **Schuld** (man hat das Monster selbst auf ihn gelenkt, 4.11): stärkerer/länger anhaltender Malus, evtl. wiederkehrende Halluzinationen *dieses* Gastes. Bei hoher Schuld: Gäste werden misstrauisch, wenn sie es herausfinden.

### 6.9 Dialog: Anlässe, Fragen, Erzählen, Lügen, Gedächtnis (entschieden 2026-10-24)
> **Umgesetzt (2026-10-24)** wie unten (Talk, DialogUI), mit diesen Abweichungen: „Er war selbst dort“ prüft nur, wo
> er beim Lügen gerade steht (einer der vier angebotenen Orte ist immer seiner). Warnen gibt es nur im Gespräch, nicht
> am Telefon und nicht als Ruf an alle (6.18). Die Antworten auf Fragen haben noch keine eigenen Tonlagen
> (nett/neutral/unhöflich), nur wahr oder gelogen. Ein Versprechen an ein Kind gilt mit jeder Partie Mäxchen oder Schach
> als gehalten. Lügen über die Nacht („Es war unheimlich“, obwohl nichts war) fliegen nur auf, wenn er sie sofort
> durchschaut.
- Einfaches Dialogsystem mit Antwortoptionen (nett / neutral / unhöflich).
- ~~Umsetzung in Godot z. B. über eigene Ressourcen oder ein Dialog-Plugin (z. B. Dialogue Manager).~~ Eigenes
  System im Code (DialogUI), kein Plugin.

**Ausbau (2026-10-24):** Bisher war das Gespräch ein Menü von Tätigkeiten (Plaudern, Handeln, Schenken …). Jetzt
kommen Fragen, Bitten, Erzählen und Lügen dazu, und **Gäste merken sich, was du sagst, und handeln danach**.

**1. Menü in fester Ordnung**
- **Oben: Anlässe** – höchstens zwei, je nach Lage (2), auf Taste 1 und 2.
- **Mitte, immer in derselben Reihenfolge:** Plaudern · Ich muss dir was erzählen … · Sag mal … · Könntest du … ·
  Handeln · Schenken · Spielen · über das Monster reden.
- **Unten** das Seltene (Einladen, Beleidigen), ganz zuletzt **Tschüss** (auch Esc).
- Reicht der Platz nicht, **scrollt** die Liste (Mausrad); Ziffern 1–9 und 0 gelten für die ersten zehn Zeilen.

**2. Anlässe: Die Lage bestimmt, was man sagen kann**
- Was der Gast gerade tut: schmückt → „Schön geworden!“ · isst → „Lass es dir schmecken.“
- Was gerade los ist: Gewitter → „Hast du auch Angst vor dem Gewitter?“ · das Monster ist unterwegs → „Versteck
  dich!“ (das Warnen aus 6.18: er bringt sich in Sicherheit, Beziehung ↑)
- Wie es ihm geht: ein Freund von ihm ist gestorben → „Er fehlt mir auch.“ (tröstet, Angst ↓)
- Wer daneben steht: ein anderer Gast in der Nähe → „Was hältst du von …?“ rückt nach oben.
- Das frischeste eigene Erlebnis (3), das man ihm noch nicht erzählt hat → „Hast du das Gespenst gesehen?“
- **Jeder Anlass einmal je Lage** (je Gast und Spieltag), und er zählt zum Beziehungsbudget (6.18) – sonst wird
  „Schön geworden!“ zur Beziehungsquelle.

**3. Erzählen, was man erlebt hat**
- Der Spieler sammelt **eigene Erlebnisse** wie die Gäste (6.12): Monster, Lakengeist, Kürbismann gesehen, eine Leiche
  oder eine Blutlache gefunden, vom Lakengeist heimgesucht, im Dachboden umgedreht worden (4.21).
- **Frisch** ist ein Erlebnis am Tag, an dem es geschah; **jedem Gast erzählt man es einmal**.
- Die Antwort hängt vom Gast ab: Hat er es **auch erlebt** → „Du auch?!“, das verbindet. **Ängstliche** glauben es,
  bekommen Angst und erzählen es weiter. **Skeptiker** glauben es nicht („Du hast zu viel Punsch getrunken.“), außer sie
  haben selbst etwas erlebt. **Kinder** sind aufgeregt – Mama oder Papa finden das gar nicht gut.
- Wie jedes Monster-Gespräch hört das Monster mit (4.7).

**4. Lügen**
- Unter „Ich muss dir was erzählen …“ steht **„Mir ist was passiert …“**: erst *was* (Geist, Monster, Kürbismann, eine
  Leiche von …, … hat geklaut), dann *wo*. Wer es glaubt, reagiert wie auf die Wahrheit (3).
- **Wie eine Lüge auffliegt:**
  1. **Gegenbeweis:** Der angeblich Tote läuft ihm über den Weg.
  2. **Er war selbst dort:** „Ich war die ganze Zeit an der Bar – da war nichts.“ (fliegt sofort auf)
  3. **Der Beschuldigte widerspricht:** Treffen sich er und der angebliche Dieb, glaubt er dem eher, mit dem er
     befreundet ist.
  4. **Vergleich unter Gästen:** Zwei Freunde merken, dass du ihnen dasselbe an verschiedenen Orten erzählt hast.
  5. **Die Wahrheit kommt raus:** Wer „Da war nichts“ gehört hat, erfährt bald, dass doch jemand gestorben ist.
- Spuk-Lügen ohne Ort, den er kennt, sind kaum zu widerlegen: sichere Lüge, kleine Wirkung. Lügen über Menschen
  wirken stark und sind riskant.
- **Aufgeflogen:** Er ist **sauer** (Beziehung ↓↓), sagt es dir, wenn du in Hörweite bist, und spricht dich beim
  nächsten Gespräch darauf an. Er **erzählt es seinen Freunden** („Glaub ihm kein Wort.“) und **glaubt dir einen Tag
  lang nichts** – auch nicht die Wahrheit.
- Das Notizbuch merkt sich Lügen **nicht** – sich zu erinnern, wem man was erzählt hat, gehört zum Risiko.

**5. Gäste fragen – und du antwortest**
- Höchstens **eine Frage je Gespräch**, gleich zu Beginn statt der Begrüßung; ab „neutral“, Freunde öfter.
- **Ein Wechsel:** Frage → Antwort → Reaktion, danach zurück ins Menü. Keine Gesprächsbäume.
- Erste Fragen: „Glaubst du an Geister?“ · „Hast du letzte Nacht was gehört?“ · „Wer gewinnt wohl den
  Türschmuck?“ (bis zur Siegerehrung) · „Warst du in meinem Zimmer?“ (nach einem Einbruch, bei dem er dich nicht
  gesehen hat) · „Hast du eigentlich keine Angst hier?“ · Kinder: „Spielst du mit mir?“
- Antworten haben einen Ton (nett / neutral / unhöflich) und sind **wahr oder gelogen**.

**6. Gedächtnis und Haltungen**
- Jeder Gast merkt sich, **was du ihm gesagt hast** – Antworten, Erzähltes, Lügen. Darauf greift er später zurück
  („Du hast doch gesagt, du glaubst nicht an Geister!“), und daran fliegen Lügen auf (4).
- Aus dem Gesagten entstehen **Haltungen**, die sein **Verhalten** steuern:

  | Du sagst … | Haltung | Er … |
  |---|---|---|
  | „Ja, nachts war was“ / eine Spukgeschichte, die er glaubt | vorsichtig | bleibt öfter im Zimmer, meidet Flure und Garten, versteckt sich schneller |
  | „Ach, da war nichts“ | sorglos | läuft mehr herum, nimmt Flackern nicht ernst. Stirbt er so, ist das **Schuld** (6.8) |
  | „X hat geklaut“ | misstraut X | ist mit X nicht mehr befreundet (6.16), solange es gilt |
  | „Ich hab keine Angst“ | hält dich für mutig | bittet dich, ihn heimzubringen, wenn er Angst hat – lehnst du ab, war es gelogen |
  | Kind: „Später, versprochen!“ | wartet | erinnert dich; spielst du nicht bis zum Abend mit ihm, ist es enttäuscht |
  | „Ich glaube (nicht) an Geister“ | Meinung | Gleiche Meinung verbindet; widersprichst du dir später, wird er misstrauisch |

- Haltungen **verfallen** nach einem Tag (das Versprechen am Abend). Neues überschreibt Altes.
- **Weitererzählen:** Was er glaubt, erzählt er Freunden, die er trifft (6.16) – sie bekommen etwas Angst und hören
  dieselbe Geschichte. **Bremse:** nur Freunde, jede Geschichte einmal je Paar, höchstens zwei Schritte weit.

**Zu klären:** weitere Fragen und Anlässe (Balkon, Dachboden, offene Aufgabe) · ob Skeptiker dich in den Keller
mitnehmen · „Ich mag Kürbissuppe“ → er bringt dir welche · Wache halten (6.18) als Bitte.

### 6.10 Minispiele mit Gästen
Neben Reden und Handeln kann man mit Gästen **kleine Spiele spielen** – um sich anzufreunden, um Zeit zu überbrücken oder **um einen Einsatz** (Geld, Deko, sogar Einrichtungsgegenstände).

**Grundregeln**
- **Spiele sind physisch an Orte gebunden:** Ohne Schachbrett kein Schach. Das Brett steht irgendwo im Hotel (z. B. Bibliothek / Salon), die Karten liegen im Speisesaal, die Würfel an der Bar.
- Spielgeräte sind **normale Gegenstände** (3.2): Man kann das Schachbrett **wegtragen** – z. B. ins eigene, helle Zimmer, um dort sicher zu spielen. Man kann es aber auch **klauen** oder verstecken, damit ein Gast „seinen“ Spieltisch verliert.
- **Fehlende Teile:** Idee – dem Schachbrett fehlt anfangs die Dame. Sie liegt irgendwo im Hotel (vielleicht im Keller …). Notfalls tut es eine Kerze als Ersatzfigur.
- Jeder Gast hat **Lieblingsspiele** und eine **Spielstärke**. Wer mit jemandem dessen Lieblingsspiel spielt, gewinnt schneller seine Sympathie.
- **Gäste spielen auch untereinander** (Teil des Tagesablaufs, 6.6) → man kann zuschauen, Gewohnheiten und Schwächen lernen, Gerüchte aufschnappen – oder sich einmischen.

**Freundschaft durch Spielen**
- Eine Partie = gemeinsame Zeit → Beziehung ↑ (unabhängig vom Ausgang, solange fair).
- **Gewinnen** gegen einen stolzen Gast kann ihn kränken; **knapp verlieren** freut ihn.
- **Absichtlich verlieren** als verstecktes Geschenk – aufmerksame Gäste merken das und fühlen sich evtl. bevormundet.
- Während der Partie läuft ein **lockerer Dialog** → gute Gelegenheit für Fragen, Gerüchte, Infos über das Monster (Achtung: Lauschen, 4.7).

**Spielen um Einsätze**
- Vor der Partie wird der Einsatz ausgehandelt: **Geld, Deko, Gegenstände, Gefallen – oder Einrichtungsgegenstände** (Stehlampe, Sessel, Spiegel, Teppich, Radio …).
- Einsätze werden **physisch auf den Tisch gelegt** bzw. – bei Möbeln – per Handschlag vereinbart. Danach muss der Gewinner das Möbelstück **selbst ins Zimmer tragen** (groß, beide Hände, langsam – und ein Weg durch den Flur).
- **Möbel haben Spielwirkung:** Eine gewonnene **Stehlampe** macht das eigene Zimmer heller (4.4), ein **Radio** ist Feier-Musik oder Lärmquelle (4.11), ein **schwerer Sessel** kann eine Tür verbarrikadieren, ein **Schrank** ist ein zusätzliches Versteck.
- Umgekehrt kann man **die eigene Einrichtung verspielen** – und das Zimmer wird dunkler, leerer, unsicherer.
- **Wettschulden:** Wer verliert und nicht zahlt, verliert massiv Ruf (spricht sich herum, 6.2). Gäste mit Wettschulden beim Spieler **holen sich ihren Gewinn selbst** – notfalls nachts aus dem Zimmer.
- **Schummeln** ist möglich (Karte im Ärmel, Figur verschieben, gezinkte Würfel) – wird man erwischt: Beziehung ↓↓, Partie geplatzt, evtl. Racheklau.

**Das Monster spielt mit**
- Spiele brauchen **Konzentration**: Während einer Partie ist der Blick aufs Brett gerichtet → eine **Vorwarnung (4.2) wird leichter übersehen**.
- Jedes Spiel hat einen **Lärmwert** (Schach leise, Würfeln/Billard laut, Kartenrunde mit Gelächter sehr laut) → Neugier ↑ in der Zone.
- Bei einer Vorwarnung **bricht die Partie ab**: Gäste rennen weg, das Brett bleibt stehen, Einsätze liegen offen auf dem Tisch … (wer holt sie sich zuerst?).
- Stärkere Gäste/Spiele in **dunklen Bereichen** sind riskanter – helle Spielorte sind sicherer, aber oft belegt.

**Vorschläge für weitere Minispiele**

> **Umfang (entschieden 2026-10-21):** Neben Mäxchen und Schach sind **Darts** und das **Kürbis-Schnitz-Duell** als
> Nächstes vorgemerkt. Alles andere in dieser Tabelle und in den Ideen darunter (Möbel als Einsatz, Wettschulden,
> Turniere …) ist **eingefroren** – eine Ideensammlung, nicht geplant.

| Spiel | Ort / Gegenstand | Besonderheit | Lärm |
|-------|------------------|--------------|------|
| **Schach** | Schachbrett (Bibliothek/Salon) | Ruhiges Duell, lange Partien, viel Zeit für Gespräche. Gäste mit unterschiedlicher Stärke. | leise |
| **Dame / Mühle** | Rückseite des Schachbretts, Spieleschrank | Kürzere Alternative für Gäste, die kein Schach können | leise |
| **Kartenspiel** (z. B. Poker, Mau-Mau, Schwarzer Peter) | Kartendeck im Speisesaal | **Mehrere Gäste gleichzeitig**, Bluffen, Schummeln möglich, guter Ort für Gerüchte | mittel–laut |
| **Würfeln / Knobeln** | Würfelbecher an der Bar | Schnelle Glücksrunden um kleine Einsätze, ideal für Geld | laut |
| **Mikado** | Stäbchen in einer Schublade | Ruhige Hand nötig → mit **Schock-Malus „zittrige Hände“ (6.8)** kaum gewinnbar | leise |
| **Darts / Billard** | Bar / Salon | Geschick-Spiel, Lärm durch Treffer bzw. Kugeln | mittel |
| **Äpfelfischen** | Wasserbottich in der Küche, Äpfel aus dem Garten | Typisch Halloween, gut für Feiern (7.1); Kopf im Wasser = nichts hören und sehen … | mittel |
| **Kürbis-Schnitz-Duell** | Küche / Lobby | Wer schnitzt den gruseligsten Kürbis? Puppe (5.5) oder Gäste als Jury. Gewinner-Kürbis ist zugleich starke Deko | leise |
| **Gruselgeschichten-Runde** | Kamin in der Lobby | Reihum erzählen, beste Geschichte gewinnt. Starker Beziehungs-Bonus – aber **Gerede über Monster** lockt es an (4.7) | mittel |
| **Ouija-Brett / Séance** | Dachboden, verschlossener Schrank | Hochriskant: liefert **echte Hinweise** (Ausgang, Monster, Story) – aber Dreistigkeit ↑↑. Halluzinationen möglich | leise, aber … |
| **Mutprobe** | – (Dialog) | „Wer holt eine Spinnwebe aus dem Keller?“ Gewinner bekommt Einsatz + Respekt; beide Spieler sind in Gefahr | – |
| **Versteckspiel** | ganzes Stockwerk | Mit Gästen spielerisch Verstecke ausprobieren – bis man merkt, dass einer der Suchenden kein Gast ist | leise |

**Spielerische Nebenwirkungen (Ideen)**
- **Ruf als Spieler:** Wer oft gewinnt, wird zum „Champion“ – manche Gäste meiden ihn, andere fordern ihn heraus.
- **Turnier bei Feiern (7.1):** Schachturnier oder Kartenrunde als Teil einer Feier, Hauptpreis z. B. eine Vogelscheuche.
- **Herausforderungen durch Gäste:** Ein Gast fordert den Spieler aktiv heraus („Revanche!“) – Ablehnen kostet ein wenig Beziehung.
- **Hotel-Spieleschrank:** Ein abschließbarer Schrank in der Lobby mit Spielen; der Schlüssel ist selbst ein begehrter Gegenstand.

**Umsetzungsstand (2026-10-10): Mäxchen an der Hotelbar**
- **Hotelbar** südöstlich der Lobby: Theke, Flaschen, Würfeltisch mit zwei Hockern. Der **Würfelbecher** ist ein normaler Gegenstand – ohne Becher am Tisch kein Spiel (man kann ihn wegtragen).
- **Regeln:** verdeckt würfeln, ansagen (wahr oder geblufft), glauben oder aufdecken; Mäxchen (21) > Pasch > Rest; Best-of-3.
- **Starten:** (1) Gast einladen („Mäxchen an der Bar spielen“), (2) Herausforderung eines Gastes annehmen (Revanche nach Niederlage gegen stolze Gäste, Freunde fragen von sich aus; ignorieren kostet etwas Beziehung), (3) Gäste würfeln untereinander – **Zuschauen** (≥ 25 s in der Nähe) verrät ihre Ticks beim Bluffen.
- **Einsätze** liegen echt auf dem Tisch: nur Spaß · 3 / 8 Geld · der Gegenstand in deiner Hand (Gast setzt Gleichwertiges aus seinem Vorrat). Gewinnst du, nimmst du die Einsätze selbst vom Tisch.
- **Spielstil der Gäste:** Edna fast immer ehrlich; Bruno blufft dreist, ist stolz und will Revanche, spielt nicht „nur zum Spaß“; Mila durchschaut Bluffs und Schummeleien am besten.
- **Beziehung:** fair spielen ↑, Lieblingsspiel ↑↑, gewinnen gegen Stolze ↓, knapp verlieren ↑, absichtlich verlieren: bemerkt ↓ / unbemerkt ↑.
- **Schummeln:** gezinkte Würfel (Zimmer 17) in den Becher schmuggeln → „Gezinkt nachwürfeln“; erwischt: Beziehung ↓↓, Gerücht, Gast nimmt den ganzen Einsatz.
- **Monster:** jeder Wurf macht Lärm (Neugier ↑ an der Bar); am Tisch ist man konzentriert → Flackern/Rauschen nur halb so stark sichtbar; bei Vorwarnung springt der Gast auf (Mutige später) – die Einsätze bleiben liegen und gehören niemandem mehr.
- Noch offen: Möbel als Einsatz, Wettschulden, weitere Spiele (Karten, Schnitz-Duell …).

**Umsetzungsstand (entschieden und umgesetzt 2026-10-18): Schach in der Lobby** – „wie Mäxchen“
- **Schachtisch** in der Lobby (vorn rechts, unter dem Gartenfenster), zwei Hocker. Das **Schachbrett** ist ein
  normaler Gegenstand – ohne Brett am Tisch kein Schach (man kann es wegtragen oder mitbringen).
- **Spielen:** Du spielst **Weiß**. Das Brett erscheint **von oben**: Figur anklicken, dann Zielfeld (Bauern werden
  automatisch zur Dame). Volle Regeln inklusive Rochade, en passant, Patt, 50 Züge, dreifache Wiederholung.
  Dazu **Remis anbieten** (ab Zug 10, der Gast nimmt an, wenn er nicht klar besser steht), **aufgeben** und
  **absichtlich verlieren**.
- **Spielstärke je Gast:** Edna spielt ordentlich, Bruno schwach (und mag Schach nicht, ist aber stolz), Mila stark
  (Schachclub). Zufallsgäste würfeln Lust (Skeptiker und Griesgrame am liebsten) und Stärke. Die KI rechnet 1–3
  Halbzüge voraus und patzt je nach Stärke (45 % bis 5 % der Züge, mit Angst öfter). Schwache Gäste ohne Stolz
  geben eine hoffnungslose Stellung auf.
- **Einsätze, Beziehung, Revanche** wie bei Mäxchen: fair spielen ↑, Lieblingsspiel ↑↑, gewinnen gegen Stolze ↓
  (die fordern Revanche), Remis ↑ und die Einsätze werden geteilt. Absichtlich verlieren merken gute Spieler eher,
  besonders wenn du gut standest.
- **Herausforderungen:** Wer Schach mag und dich mag, fordert dich auch zum Schach heraus.
- **Gäste spielen untereinander** Schach (70–120 s, der Stärkere gewinnt meist). Wer **30 s zusieht**, weiß danach,
  wie stark beide spielen – das steht dann schon bei der Frage nach dem Einsatz.
- **Monster:** Schach ist **leise** (kein Lärm), aber man sitzt konzentriert (Flackern/Rauschen schwächer sichtbar).
  Bei einer Vorwarnung springt der Gast auf, die Einsätze bleiben liegen.
- Noch offen: die fehlende Dame als Suche (Idee oben), Dame/Mühle auf der Rückseite, Schachturnier bei Feiern.

---

### 6.11 Hotelkatzen (vorgemerkt 2026-10-14, umgesetzt 2026-10-17)
> **Im Prototyp umgesetzt (2026-10-17):** drei Katzen – **Minka** (alt, verschlafen, startet auf dem Lobby-Sofa),
> **Socke** (scheu, startet in der Küche), **Kasimir** (rot getigert, neugierig und tollpatschig, startet vor
> Zimmer 13). Sie streifen umher, schlafen auf den Sofas und auf den Betten der Gäste und in Zimmer 13, folgen
> ihrem Lieblingsgast, miauen vor geschlossenen Türen (können keine öffnen), lassen sich streicheln (Spieler:
> Schock sinkt; Gäste im Vorbeigehen: Angst sinkt), fliehen weinend vor dem Monster (es überhört sie), werfen
> Kürbisse und Kerzen um (Kerze geht meist aus; „aufstellen [E]“, Gäste stellen ihre eigene Deko wieder auf)
> und bringen selten Laub, Spinnweben oder eine Kerze vor Zimmer 13. Wer oft streichelt, bekommt öfter Besuch
> auf dem Bett. In Panik vor einer geschlossenen Tür duckt sich eine Katze und weint weiter.
> **Ergänzt (2026-10-17):** Manchmal trägt eine Katze Deko eines Gastes vor Zimmer 13 (der Gast vermisst sie und
> verdächtigt dich – bis er im Gespräch erzählt, wer es war). Liegeplätze auch auf der Rezeption und auf den
> Fensterbänken (Lobby und bewohnte Zimmer). Gäste plaudern über die Katzen (Lieblingskatze, umgeworfene Kerze)
> und wissen nach dem ersten Weinen: „Wenn die Katzen weinen, ist es in der Nähe.“ Das Weinen erzählen sie wie
> andere Geräusche weiter.
> **Tragen (entschieden und umgesetzt 2026-10-20):** Nach dem Streicheln nimmt man eine Katze mit [E] auf den Arm
> (scheue Socke erst, wenn sie einen kennt – ein paar Mal gestreichelt). Auf dem Arm schnurrt sie und beruhigt
> (Schock sinkt langsam), die Hände sind dann aber nicht frei für Gegenstände; Türen gehen noch. [G] setzt sie ab,
> nach einer Weile (länger, je vertrauter) windet sie sich von selbst heraus. Beim Verstecken, Schlafen oder wenn
> der Lakengeist zupackt, springt sie herunter. Naht das Monster, faucht sie, kratzt (ein kleiner Schreck) und
> flieht – auch auf dem Arm ist sie eine Frühwarnung.
> **Noch nicht:** Heizkeller als Liegeplatz – den Tiefkeller (7.4) gibt es noch nicht.
- **Ein paar Katzen gehören zum Hotel** (Vorschlag: 2–3, mit Namen, z. B. eine alte, eine scheue, eine neugierige).
- **Sie laufen frei durchs Hotel:** NavMesh wie die Gäste, eigene Lieblingsplätze (Rezeption, Sofa in der
  Lobby, warm in der Küche, Fensterbank, Heizkeller), schlafen viel, schlüpfen durch offene Türen.
- **Streicheln:** Spieler und Gäste können sie streicheln („Streicheln [E]“). Wer gestreichelt wird,
  schnurrt (Geräusch) – Vorschlag: senkt beim Spieler die Anspannung kurz, bei Gästen die Angst (6.5).
- **Mit Menschen:** Katzen suchen sich Lieblingsgäste, folgen ihnen ein Stück, legen sich in ihr Zimmer.
  Gäste reden über die Katzen („Hast du Minka gesehen?“) und streicheln sie im Vorbeigehen.
- **Das Monster greift keine Katzen an** (entschieden 2026-10-14): Katzen waren immer lieb zu ihm. Es jagt
  sie nicht, holt sie nicht und sieht über sie hinweg (Sehen & Jagen, 4.12, gilt für sie nicht).
- **Die Katzen haben trotzdem Angst vor ihm** (entschieden 2026-10-14): Kommt es in die Nähe, laufen sie
  weg und fangen an zu **weinen** (klagendes Miauen/Jammern) – hörbar auch durch Wände.
  - Das ist eine **Frühwarnung**: Eine weinende, fliehende Katze zeigt, dass es in der Nähe ist – oft
    bevor das Rauschen beginnt (4.13). Ein Hinweis, keine Garantie.
  - Vorschlag: Das Weinen ist **Lärm** (4.15) – das Monster ignoriert es aber (es mag die Katzen),
    Gäste hören es dagegen und werden unruhig.
- **Katzen werfen Dekoration um** (entschieden 2026-10-14): beim Herumstreifen, Spielen oder auf der Flucht.
  Umgeworfene Deko (Kürbis, Kerze, 5.) **schützt nicht mehr**, bis jemand sie wieder aufstellt; eine
  Kerze kann dabei ausgehen. Gäste können glauben, ein anderer Gast habe sabotiert (6.2, Gerüchte).
  Das Umwerfen macht ein Geräusch (Lärm, 4.15).
- **Geschenke und Gesellschaft** (entschieden 2026-10-14), beides mit **geringer Wahrscheinlichkeit**:
  - Eine Katze **bringt dir Dekoration** – sie legt sie vor Zimmer 13 oder in dein Zimmer.
    Vorschlag: kleine Deko (Spinnweben, Laub, eine Kerze), manchmal auch etwas, das einem Gast gehört –
    der sucht es dann und verdächtigt vielleicht dich (6.2).
  - Eine Katze **legt sich auf dein Bett** in Zimmer 13 und schläft dort eine Weile.
  - Vorschlag: Je öfter man eine Katze streichelt, desto eher kommt sie zu einem.
- **Ideen für später** (Vorschläge, noch offen):
  - Miauen vor einer geschlossenen Tür kann einen im Versteck verraten – Gästen gegenüber, nicht dem Monster.
- **Technik:** eigene Klasse ähnlich `Guest` (einfacher Zustandsautomat), interagierbar über
  `set_meta("interactable", self)`. Katzen gehören in den Spielstand (Position, Zustand) → neue Liste,
  kein Eingriff in die Reihenfolge der festen Welt-Objekte.

### 6.12 Schreck & Erlebnisse (entschieden und umgesetzt 2026-10-18)
Gäste reagieren **sichtbar erschrocken**, wenn sie etwas Schreckliches sehen, und erzählen dem Spieler später davon.

**Was erschreckt**
- **Blutlachen**, die das Monster hinterlässt, wenn es einen Gast holt (große Blutspur und Kleidungsstück – keine
  Leiche). Kleine Blutstropfen verletzter Gäste erschrecken **nicht** (zu häufig).
- **Leichen** gibt es vom **Lakengeist** (ein erwürgter Gast bleibt liegen, wo er starb) und seit 2026-10-20 vom
  **Kürbismann** (4.19: liegt in einer Blutlache).
- Der **Lakengeist** selbst – am eigenen Fenster oder als Zeuge, wenn er zu jemand anderem kommt.
- Jeder Fund erschreckt einen Gast **nur einmal**. Schlafende und Versteckte sehen nichts.

**Die Reaktion** – der Gast bleibt **2–5 Sekunden** stehen (je mutiger, desto kürzer) und starrt hin. Wie, liegt
fest am Charakter, nicht am Zufall:

| Reaktion | Wer | Danach |
|----------|-----|--------|
| **Hände hoch** (zitternd, weicht zurück) | ängstlich, geschäftstüchtig, Edna | rennt weg und versteckt sich |
| **Starr vor Schreck** (Hand vor dem Mund) | Skeptiker, Griesgram, Bruno | macht weiter |
| **Weinen** (zusammengesunken, Hände vorm Gesicht) | Plaudertasche, Bastler, Mila | geht weinend ins Zimmer |
| **Klammern** (an Mutter oder Vater) | Kinder (6.13) | rennt zu den Eltern, wenn keins in Sicht ist; erzählt es allen |

**Gesprächsthema:** Beim **nächsten Gespräch** erzählt der Gast zuerst davon (eigene Sätze je Reaktion: Blut,
Leiche, Geist, Angriff des Geists). Danach kommt es **einen Spieltag lang** beim Reden über das Monster noch
einmal vor. Wie jedes Gespräch über das Monster hört es mit (4.7).

**Der Lakengeist behandelt Gäste wie den Spieler** (4.18):
- Steht ein **wacher** Gast in einem Raum mit Außenfenster, **Licht aus, Vorhang offen** (meist: er ruht im eigenen
  Zimmer), kommt er mit derselben Chance – mit **eigenem Zähler je Gast** (1. Mal heranschweben, 2. Handabdrücke
  und Hypnose, ab 3. herein und würgen, ab 4. durch den Vorhang). Der Zähler des Spielers bleibt davon unberührt.
- Ab der Hypnose bleibt der Gast **gebannt stehen**, statt wegzulaufen.
- **Würgen:** Mutige reißen sich eher los (5 % + 20 % × Mut, seit 2026-10-18; vorher 25 % + 50 %) und rennen in Panik davon, sonst **stirbt der Gast und
  bleibt als Leiche liegen**. Im Hotel hört man nur ein abbrechendes Röcheln.
- **Zeugen** vertreiben ihn wie beim Spieler – bei einem Gast zählt **auch der Spieler** als Zeuge. Wer ihn so
  sieht, erschrickt ebenfalls.
- Wer ihn erlebt hat, **lässt einen Tag lang den Vorhang zu** und ruht nicht im Dunkeln.
- Zimmer ohne Außenfenster sind sicher. (Seit 2026-10-23 hat im Erdgeschoss jedes Zimmer ein Fenster oder eine Gartentür, auch Milas Zimmer 15 – die Regel greift dort vorerst nicht.)

**Noch offen:** Werden Leichen irgendwann weggebracht (von Gästen, vom Monster)? Trauer der Gäste um Freunde (6.8)?

### 6.13 Kinder (entschieden und umgesetzt 2026-10-19)
Kinder als neue Gästegruppe – kommt **nach** dem Trinken (3.7), weil sie eigene Modelle, Sätze und Tänze brauchen.
> **Im Prototyp umgesetzt (2026-10-19):** vier Kinder (seit 2026-10-20 dreizehn) (6–11 Jahre) bei je einem erzeugten Erwachsenen, Zimmer nebenan,
> eigene Namen und Sätze („Mama“/„Papa“), ab und zu ein Schach-Wunderkind. Alles unter „Kinder und die bestehenden
> Systeme“ – bis auf die Lücken unten. Als Modelle gibt es das Mädchen ~10 (`guest_girl10`) und seit 2026-10-20 auch das
> Mädchen ~7 und die Jungen ~7 und ~10 (`guest_girl7`, `guest_boy7`, `guest_boy10`) – alle vier Grundkörper.
> **Noch nicht:** Das Geheimnis (2.3) und die Zeitschleife (2.2) gibt es noch nicht – deshalb keine
> Funde in engen Ecken und kein Déjà-vu. Die Puppe (5.5) tragen Kinder seit 2026-10-22. Der Lakengeist erschreckt Kinder am Fenster,
> noch nicht im Flur. Ein Waisenkind schließt sich nur dem Spieler an, noch keinem Gast. „Erzählt es allen“ heißt
> vorerst: den Eltern und den Erwachsenen in der Nähe.
- **Der Lakengeist erschreckt Kinder häufiger** – sie sind schwach und ängstlich (hoher Grundwert an Schwäche,
  4.18). Er will Angst säen, nicht töten.
- **Kinder sind nie Opfer (entschieden 2026-10-19):** Der Geist erschreckt sie (am Fenster, unter dem Bett, im
  Flur), würgt sie aber nie; auch das **Monster holt keine Kinder**. **Ausnahme (entschieden 2026-10-20):** der
  **Kürbismann** (4.19) – Kinder haben ihn umgebracht, er jagt sie wie alle, die Spaß haben. **Zurückgenommen
  (2026-10-20):** Auch er tut Kindern nichts; sie bleiben im ganzen Spiel geschützt.
- **Familien:** Kinder kommen mit ihren Eltern und wohnen in deren Zimmer (seit 2026-10-24, 6.20; manche nur mit einem Elternteil). Wird ein Kind erschreckt, steigt die Angst der Eltern stark – sie
  werden schwächer, und der Geist kommt über das Kind an die Erwachsenen.
- **Niemand glaubt ihnen:** Kinder erzählen, was sie gesehen haben, die Erwachsenen tun es ab – der Spieler merkt,
  dass sie recht haben (passt zu den unzuverlässigen Berichten, 4.13).
- **Kein Alkohol (entschieden 2026-10-19):** Kinder trinken nicht und lehnen jedes Glas ab, auch eine Runde mit dem
  Spieler (3.7). Rausch fließt bei ihnen also nie in die Schwäche ein.
- **Feiern (entschieden 2026-10-19):** Kinder kommen **immer freiwillig** zu Feiern – egal, wer einlädt, wie sie zum
  Gastgeber stehen und wie die Stimmung ist (sonst entscheiden Laune und Beziehung, 7.1).

**Kinder und die bestehenden Systeme (entschieden 2026-10-19)**

*Monster und Lakengeist*
- **Das Monster übersieht Kinder** wie die Katzen (6.11): Es jagt sie nicht, sieht über sie hinweg (4.12 gilt für
  sie nicht) und geht an ihnen vorbei – auch an ihren Verstecken. Wer so nah dran war, erzählt es danach („Der große
  Mann mit der langen Zunge hat mich angeschaut.“) – und keiner glaubt es.
- **Kinder schützen niemanden:** Ein Kind daneben hält das Monster nicht von einem Erwachsenen ab, und vor dem
  Lakengeist zählt ein Kind **nicht als Zeuge**. Sonst würden Kinder zum Schild.
- **Kinder sind laut** (4.15): Sie rennen oft (10 m), lachen laut beim Spielen und schreien beim Erschrecken (20 m).
  Ihnen passiert nichts – aber sie locken das Monster zu den Erwachsenen in ihrer Nähe. So kommt die Gefahr auch
  beim Monster über das Kind an die Eltern.
- **Angst vor der Dunkelheit:** Kinder schalten selbst nie das Licht aus. Dunkel wird ihr Zimmer erst in der
  **Nachtruhe** (4.18), wenn die Eltern es ausmachen – dann gelten für den Geist die normalen Regeln (Licht aus,
  Vorhang offen), dazu die hohe Schwäche.
- **Nachts unterwegs:** Manchmal kann ein Kind nicht schlafen und schleicht in der Nachtruhe aus dem Zimmer. Im Flur
  erschreckt es der Geist. Bringt der Spieler es zurück ins Zimmer, sind die Eltern dankbar (Beziehung ↑). Ein
  Kind, das nicht schlafen kann, klopft manchmal auch an Zimmer 13 („Ich kann nicht schlafen.“).

*Halloween, Deko und Puppe*
- **Süßes oder Saures:** Kinder klopfen ab und zu an Zimmer 13.
  **Von Tür zu Tür (entschieden und umgesetzt 2026-10-20):** Kinder ziehen auch durch die Flure und klopfen an
  zwei, drei Gästetüren in der Nähe. Ist jemand zu Hause, macht er auf und gibt Süßes (meist) oder schimpft
  (Griesgrame meist); schimpft er oder öffnet keiner, gibt es Saures – Laub vor der Tür. Man hört das Klopfen
  im Flur. Gibt man ihnen **Süßigkeiten** (neuer kleiner
  Gegenstand, in der Küche und in Schubladen, 3.5), steigt die Beziehung; gibt man nichts, spielen sie einen
  **Streich** – Laub vor der Tür oder ein Klingelstreich am Telefon (Lärm, 4.14). Weil Klopfen schon unheimlich
  belegt ist (4.13), weiß man nie sicher, ob es nur die Kinder sind.
  **Eier (vorgemerkt 2026-10-20):** Saures kann auch heißen, dass Kinder **Eier an Türen oder Zimmerfenster**
  werfen – an Fenster auch von draußen aus dem Garten. Das Klatschen ist Lärm (4.15). Der Fleck bleibt als Spur,
  bis man ihn wegwischt (wie die Spuren an Zimmer 13, 4.13); getroffene Gäste sind sauer – auf die Kinder oder, wenn
  der Spieler in der Nähe stand, auf ihn. Am Fenster verdeckt das Eigelb ein Stück der Sicht, und nachts sieht der
  verschmierte Fleck aus wie die Handabdrücke des Lakengeists: Ei oder Geist? Eier gibt es in der Küche (neuer
  Gegenstand) – auch der Spieler kann werfen, etwa an die Tür eines Feindes (Zeugen, 6.3; wie, steht in 3.13).
  **Streiche (entschieden und umgesetzt 2026-10-22):** Saures ist nicht mehr nur Laub. Das Kind sucht sich einen Streich aus:
  - **Laub** vor die Tür streuen (wie bisher),
  - einen **Kürbis holen und vor die Tür werfen** – er zerplatzt beim Aufprall, egal aus welcher Höhe (Kürbismatsch,
    5.8); geholt wird er aus dem Koffer der Familie (Zierkürbis oder Kürbis),
  - eine **Kerze holen und vor die Tür werfen** – sie zerbricht und hinterlässt einen **großen weißen Wachsfleck**;
    brennt sie, kann sie leichte Deko anzünden (5.11),
  - **Deko umwerfen**, die vor der Tür steht (Kürbisse, Kerzen, Totenköpfe) – umgeworfene Deko schützt nicht mehr, bis
    sie jemand aufstellt (5.10), und kann die Tür zur schwächsten machen (5.5),
  - an Zimmer 13 weiterhin auch den **Klingelstreich** (4.14).
  Hat die Familie nichts zum Werfen, bleibt es bei Laub oder Umwerfen.
  **Zeugen:** Erwachsene, die das Kind dabei sehen, **verpetzen es sehr wahrscheinlich** – nur die eigenen Eltern nicht.
  Erzählt wird es dem **Bewohner der getroffenen Tür**: Er ist danach sauer auf die Eltern des Kindes, die beiden sind
  **verfeindet** (erste Feindschaft unter Gästen, 6.16).
  **Mehr Süßes (entschieden und umgesetzt 2026-10-22):** Kinder klopfen **viel häufiger** – an Zimmer 13 etwa alle
  2–4 Minuten, auf Runden von Tür zu Tür etwa jede Minute. An Zimmer 13 gibt man ihnen Süßigkeiten mit [E] (oder im
  Gespräch): **bis zu 3 je Besuch**. Schon **eine** verhindert den Streich, und das Kind mag dich etwas mehr – **jede
  weitere mehr als die vorige**. Nach einer wartet es noch kurz auf die nächste, dann geht es zufrieden. Süßigkeiten
  gibt es in der **Truhe jedes Zimmers** (6 Stück zum Start) und am **Snackautomaten**; Gäste geben Kindern an ihrer Tür
  aus ihrer eigenen Truhe, solange sie nicht leer ist.
  **Flecken (entschieden und umgesetzt 2026-10-22):** Kürbismatsch, große Wachsflecken und Ruß vor der eigenen Tür
  bemerken die Bewohner und **beschweren sich** („Wer schmeißt hier mit Kürbissen?!“). **Ordentliche Gäste** (etwa vier
  von zehn) **putzen**: Wachs und Ruß wischen sie weg, Kürbismatsch sammeln sie auf (vom Riesenspritzer eine Hand voll)
  und **bringen ihn in die Küche** – ist der Herd frei, kochen sie daraus **Kürbissuppe**, sonst legen sie ihn dort ab.
- **Gebastelte Geschenke:** Kinder schenken dem Spieler kleine, schwache Deko (Laub, eine Kerze) – mehr Herz als
  Schutz, aber es zählt als Geschenk (6.3).
- **Die Puppe** (5.5, neu gefasst 2026-10-22): Kinder sehen sie und **tragen sie zum Spielen herum** – zwischen den
  Angriffen, meist vor die Tür der eigenen Familie. Ihr Urteil wandert nicht mit: Kurz vor einem Angriff springt sie
  unbeobachtet zur schwächsten Tür, und dann kann sie auch kein Kind mehr bewegen.

*Gäste und Beziehung*
- **Kinder schlägt man nicht** (6.3): Der Schlag geht bei Kindern nicht. **Rammen** schon: Das Kind fällt hin und
  weint, die Eltern werden wütend (Beziehung ↓↓), Zeugen merken es.
- **Schnell beleidigt, schnell vergessen:** Die Beziehung eines Kindes wandert ohne Kontakt **schneller zur Mitte**
  zurück als bei Erwachsenen (6.3) – in beide Richtungen.
- **Kinder petzen:** Sehen sie dich klauen, erzählen sie es ihren Eltern – und **das** glauben die sofort. Beim
  Monster glaubt ihnen keiner, beim Diebstahl jeder.
- **Waisenkind** (6.7, 6.8): Stirbt ein Elternteil und ist keiner mehr da, hängt sich das Kind an den Spieler
  (wenn er ihm am nächsten steht) oder an einen freundlichen Gast wie Edna und folgt ihm wie ein Begleiter (6.3).
  Es wird selbst nie geholt, macht aber Lärm – und bringt seinen Beschützer in Gefahr.
- **Eigene Schreckreaktion** (6.12): Kinder **klammern sich an die Eltern**, wenn eins in Sicht ist, sonst rennen
  sie zu ihnen. Danach erzählen sie es **allen**, nicht nur beim nächsten Gespräch.

*Bar, Handel, Spiele*
- **Kakao statt Alkohol** (3.7): An der Bar gibt es für Kinder Kakao bzw. Limo. Er senkt bei ihnen die Angst; eine
  Limo spendieren ist ein kleines Geschenk (Beziehung ↑).
- **Kein Spiel um Einsätze** (6.10): Kinder spielen nur zum Spaß. Beim Schach kann ein Kind ein **Wunderkind** sein
  und fast jeden schlagen (hohe Spielstärke, stolz – will Revanche).
- **Keine Messer:** Gibt man einem Kind ein Messer, werden die Eltern wütend. Beim Kürbisschnitzen brauchen Kinder
  einen Erwachsenen.
- **Tauschen statt kaufen** (6.4): Kinder haben kaum Geld. Sie tauschen Süßigkeiten, Laub oder Fundstücke.

*Geheimnis und Zeitschleife*
- **Kinder kommen überall hin** (2.3): Sie finden Dinge unter Möbeln und in engen Ecken – auch Dokumente und
  Hinweise – und erzählen davon in Kindersprache.
- **Déjà-vu** (2.2): Kinder sagen offener als Erwachsene, dass sie einen kennen („Du warst letztes Jahr auch hier.“).

**Vorschläge (offen, 2026-10-19)**
- **Bettlaken-Kostüm:** Ein Kind im Laken-Kostüm steht im dunklen Flur – Kind oder Lakengeist? Braucht ein eigenes
  Modell (Kinderkörper unter einem Laken) und gehört dann zu Halloween bzw. den Feiern.
- **Versteckspiel mit Kindern:** Kinder fragen den Spieler von sich aus und kennen die besten Verstecke – bis einer
  der Suchenden kein Kind ist (Versteckspiel, 6.10). Ein eigenes Minispiel, deshalb später.

**Modelle (geplant 2026-10-19, „Mädchen ~10“ eingebaut 2026-10-19 als `guest_girl10`, „Mädchen ~7“, „Junge ~7“ und
„Junge ~10“ 2026-10-20 als `guest_girl7`, `guest_boy7` und `guest_boy10`):** Wie bei den Erwachsenen (6.0) eigene **Grundkörper** statt Einzelmodelle, vier
Stück: **Mädchen und Junge, je etwa 7 und etwa 10 Jahre**. Dieselben Regeln für Meshy (A-Pose, Kleidung und Haare
entsättigt grau, Oberteil heller als die Hose, Haare nicht auf den Schultern, keine Muster, Accessoires oder
eingebrannten Schatten) und dasselbe Skelett (Auto-Rigging mit Vorlage **Mixamo**, „Alle hinzugefügt“, eine
Datei), damit die Tänze und Animationen der Gäste ohne Umbau passen. Dazu:
- **Kopf etwas größer** als bei Erwachsenen, damit man Kinder auch auf Entfernung und im Halbdunkel erkennt.
- **Freundliche Gesichter**, Mund zu – Kinder sind Ziel des Geists, keine Horrorfiguren.
- **Lange Hosen, keine Röcke oder Kleider** (Stoff zwischen den Beinen verzieht sich beim Riggen), **keine Kapuze**
  (Kopf- und Hals-Knochen werden als Haare eingefärbt, `build_guest.py`).
- Höchstens 15 000 Dreiecke; fragt Meshy beim Riggen nach der Größe: etwa 1,20 m bzw. 1,40 m.

| Grundkörper | Körperbau, Gesicht | Haare | Oberteil |
|-------------|--------------------|-------|----------|
| Mädchen, ~7 | schlank, freundlich und ruhig | kinnlanger Bob | Pullover |
| Junge, ~7 | etwas pummelig, neugierig | kurz, zerzaust | Langarmshirt |
| Mädchen, ~10 | schlaksig, schüchtern und ernst | kleiner Dutt am Hinterkopf | Pullover |
| Junge, ~10 | schlaksig, dünn, frech und wach | kurz, Seitenscheitel | Strickweste über Langarmshirt |

Beschreibung für Meshy (Beispiel Mädchen, ~7; für die anderen Alter, Körperbau, Gesicht, Haare und Oberteil
nach der Tabelle tauschen):

```text
Full-body 3D character of a 7-year-old girl, child proportions with a slightly larger head, slim build. Standing in A-pose, arms angled down away from the body, hands open with fingers slightly apart, legs straight and slightly apart. Friendly, calm face, mouth closed. Short chin-length bob, hair not touching the shoulders, medium gray hair. Plain light gray long-sleeved sweater, plain medium gray long trousers, simple dark shoes. No patterns, no logos, no accessories, no hood, no bag, no toys. Even flat lighting, no baked shadows.
```

### 6.14 Aufträge von Gästen (vorgemerkt 2026-10-20)
> **Erste Form (entschieden 2026-10-21):** Wünsche aus schweren Momenten – verletzt, trauernd, verwaist, nach dem
> Lakengeist, Puppe vor der Tür (6.18, 3). Die Tabelle unten bleibt der Ausbau.

Gäste bitten den Spieler um Hilfe – kleine Aufgaben, die die bestehenden Systeme nutzen. **Kein Questmenü** (2.3):
Angenommene Aufträge notiert der Spieler-Charakter im **Notizbuch** unter „Aufgaben“ (3.10) – fortlaufend, mit Name,
Zimmer und Frist, erledigte durchgestrichen –, der Gast erinnert beim nächsten Gespräch daran. *(Bis 2026-10-23 im
Tagebuch, das aber in Zimmer 13 liegt.)*
- **Wie man sie bekommt:** im Gespräch (der Gast fragt von sich aus oder auf „Kann ich dir helfen?“), am Telefon
  (4.14, „Ich habe kein Licht mehr“) oder als Zettel an der Tür von Zimmer 13.

| Art | Beispiel | nutzt |
|-----|----------|-------|
| **Bringen** | „Bring mir eine Kerze“ – ein Kürbis, ein Glas von der Bar, Süßigkeiten für die Kinder | Tragen (3.2), Bar (3.7) |
| **Wiederfinden** | „Mein Schal liegt irgendwo im Flur“, verlorene Münzen, das Kuscheltier eines Kindes | Kommoden (3.5), Spuren (4.13) |
| **Reparieren** | „Meine Lampe ist kaputt“ | Glühbirnen (7.3) |
| **Begleiten** | „Bring mich zur Bar, ich trau mich nicht allein durch den Flur“ | Mitkommen (6.3), Monster |
| **Nachsehen** | „Bruno geht nicht ans Telefon – schau mal nach ihm“ – manchmal findet man eine Leiche | Telefon (4.14), Schreck (6.12) |
| **Überbringen** | ein Geschenk oder eine Entschuldigung an einen anderen Gast, zwei Verfeindete versöhnen | Beziehungen (6.3) |
| **Schmücken** | „Häng mir eine Fledermaus an die Tür“ | Deko (5.6, 5.7) |
| **Suchen** | „Minka ist seit gestern weg“ | Hotelkatzen (6.11) |
| **Mutprobe** | Kinder und Mutige: „Hol einen Stein aus dem Keller“ | Wagnis (2.3) |
| **Streich** | Kinder: „Besorg uns Eier“ – man macht sich mitschuldig (6.13) | Küche, Zeugen |

- **Belohnung:** Geld, Deko aus dem Vorrat des Gastes, Beziehung ↑ – und manchmal ein **Hinweis** zum Geheimnis oder
  ein **Schlüssel** (2.3). Mitwisser geben das Wichtigste nur über Aufträge heraus.
- **Fristen:** Viele Aufträge gelten nur bis zu einem Ereignis („vor der Nachtruhe“, „bis zur Feier“); verpasst sinkt
  die Beziehung ein wenig, im Notizbuch steht dann *„zu spät“*. Stirbt der Gast, bleibt der Auftrag im Notizbuch offen
  stehen, mit einem Kreuz neben dem Namen („Ich hatte es ihm versprochen“) – ein kleiner Stich Schuld (6.8).
- **Falsche Aufträge:** Feinde schicken einen bewusst in Gefahr („Hol meinen Schlüssel aus dem Keller“) – das
  Gegenstück dazu, wie man selbst Gäste in den Keller lockt (4.11).
- **Offen:** wie viele Aufträge gleichzeitig; ob man ablehnen kann, ohne dass die Beziehung sinkt. Fest steht
  (3.10): Ins Notizbuch kommt ein Auftrag erst beim Annehmen, eine abgelehnte Bitte gar nicht.

### 6.15 Freitext-Gespräche (Prototyp 2026-10-20)
> **Gestrichen (2026-10-21):** Der Prototyp kommt nicht ins Spiel, der Code wird entfernt. Gespräche laufen nur über
> das Menü. Der Abschnitt bleibt als Historie stehen.

Mit Gästen frei reden statt nur aus dem Menü wählen – über ein **lokales Sprachmodell** (läuft auf dem Rechner des
Spielers, kein Internet). Das Menü bleibt das Rückgrat; „Etwas fragen …“ kommt als Option dazu.
- **Wofür:** vor allem **Ausfragen** – Zeugen befragen („Hast du heute Nacht was gehört?“), Gerüchte prüfen, Gäste
  kennenlernen. Der Spieler muss selbst draufkommen, was er fragt.
- **Grundsatz: Das Spiel weiß, das Modell formuliert.** Jeder Gast bekommt einen Faktenzettel aus dem Spielzustand
  (Erlebnisse 6.12, Gerüchte 4.13, Feiern, Beziehung 6.3). Was nicht darauf steht, weiß er nicht. Unzuverlässige Gäste
  erzählen Gerüchte so falsch wie sonst auch.
- **Folgen nur über die bestehende Dialoglogik:** Das Modell ordnet die Frage einer Absicht zu (plaudern, Monster,
  einladen, beleidigen, sonstiges); Beziehung, Einladen und Beleidigen entscheidet das Spiel wie im Menü. Reden über das
  Monster lockt es weiter an (4.7). Handel, Spiele, Geschenke bleiben im Menü.
- **Prototyp:** nur Edna und Bruno, Gesprächsverlauf wird nicht gespeichert.
- **Offen:** Ob es ins fertige Spiel kommt (Downloadgröße +2,5 GB mit Gemma 3 4B, braucht eine Grafikkarte mit ~3 GB freiem Speicher –
  abschaltbar, das Menü bleibt immer); Telefon (4.14) weiter ohne Freitext; Lügen nach Charakter (Spiel entscheidet,
  Modell formuliert die Ausrede); Gerüchte über ein Gespräch hinweg gleich halten; erzeugte Gäste.

### 6.16 Freundschaften unter Gästen (entschieden 2026-10-21)
Gäste freunden sich auch **miteinander** an – und Freunde erzählen sich Gutes über dich.
- **Wie Gäste Freunde werden:** durch gemeinsame Taten – zusammen schmücken (5.9), Deko suchen, Kürbissuppe essen
  (3.8), Mäxchen oder Schach spielen (6.10), feiern (7.1) und an der Bar trinken (3.7). Jede gemeinsame Tat zählt;
  ab **drei** sind zwei Gäste Freunde. **Familie** (Kinder und ihre Eltern, 6.13) und **Zimmernachbarn** (Tür an
  Tür) sind es von Anfang an.
- **Weitererzählen:** Ist ein Gast mit dir mindestens **„befreundet“** und trifft einen seiner Freunde (beide wach,
  frei, nah beieinander), erzählt er ihm Gutes über dich – man sieht es an der Sprechblase („Der aus Zimmer 13 ist
  echt in Ordnung!“). Der Freund mag dich dann mehr (**+8**, je Paar einmal am Spieltag), bis höchstens
  **„befreundet“** (dann geht auch „Komm mit“); „guter Freund“ braucht weiter eigene Taten (6.3). Wer verfeindet ist,
  lässt sich nichts erzählen. Beim nächsten Gespräch sagt der Freund, wer ihm von dir erzählt hat.
- **Ruf:** Was man mit einem Gast zusammen tut (Deko suchen), erzählt er seinen Freunden ebenfalls (+3).
- Gast-Freundschaften stehen im Spielstand (Zähler je Paar); Familie und Nachbarn ergeben sich aus dem Hotel.
- **Freunde schmücken die Türen ihrer Freunde mit** (5.10, entschieden 2026-10-21), auch Zimmer 13.
- **Offen:** Streit unter Gästen (Freundschaften, die zerbrechen – ein Anfang ist Diebstahl unter Gästen bei
  Knappheit, 5.10). ~~Schlechtes über dich, das Freunde weitertragen.~~ Gutes und Schlechtes laufen künftig über
  dasselbe Netz (6.18, 1).
- **Feindschaften (2026-10-22):** Ein erster Anfang sind die Streiche der Kinder (6.13): Wer verpetzt bekommt, wessen
  Kind ihm einen Kürbis vor die Tür geworfen hat, ist mit dessen Eltern **verfeindet** – Verfeindete sind keine
  Freunde mehr, auch nicht als Zimmernachbarn.
- **Freund meines Feindes (entschieden und umgesetzt 2026-10-22):** Wird der Spieler mit einem Gast **befreundet**,
  erfahren dessen Feinde es nach einer Weile und mögen ihn weniger (−15, je Paar einmal; „Du bist also mit … befreundet?“).

### 6.17 Überlebende & Verletzungen (entschieden 2026-10-21)
Nicht jeder Angriff endet tödlich: **Etwa vier von zehn Gästen überleben** – ohne Lebenspunkte, es wird beim Angriff
entschieden. Wer überlebt, ist verletzt, erzählt viel und lässt sich in dieser Zeit schneller gewinnen – oder verlieren.
Das gilt nur für Gäste (der Spieler stirbt wie bisher, 8.7); Kinder sind ohnehin nie Opfer (6.13). Wer überlebt, zählt
nicht als Opfer – das Monster bleibt hungrig (4.10).

| Angreifer | Was er überlebt | Verletzung | Folgen |
|-----------|-----------------|------------|--------|
| **Monster** | reißt sich los, als es ihn wegschleppen will | **Kratzer und Schrammen** – nichts Großes | sichtbare Kratzer, kurz ein paar Blutstropfen, kein Bett; heilt in gut einem Spieltag |
| **Kürbismann** (4.19) | der Axthieb trifft nicht voll | **Axtwunde** | Verband, humpelt stark, kann nicht rennen; **blutet sichtbar** – eine Spur auf dem Weg (wie die Blutstropfen, 4.13, aber deutlicher), erst nach einer Weile weniger |
| **Lakengeist** (4.18) | reißt sich beim Würgen los | **Würgemale** | spricht **heiser**, **atmet schwer** (hörbar), panische Angst im Dunkeln, schwächer – der Geist kommt eher wieder |
| **Vampir** (4.22, vorgemerkt) | der erste Biss | **Bissmale am Hals** | blass und schwach – der Geist kommt eher wieder; ein zweiter Biss im schwachen Zustand tötet |

- **Heilung:** zwei bis drei Spieltage. Nach Axt und Würgen liegt er den **ersten Spieltag im eigenen Bett** (wach,
  ansprechbar – er feiert, schmückt und sucht nicht), danach schont er sich noch ein, zwei Tage. Geschenke und Besuche
  lassen ihn etwas schneller heilen. Verletzung und Heilung stehen im Spielstand.
- **Zeuge:** Ein Überlebender erzählt **viel und zuverlässig** – anders als Gerüchte (4.13) stimmt alles: wo es
  passiert ist, wie der Angreifer aussah, woher er kam und wohin er verschwand, wovor er zurückwich. Bei jedem Gespräch
  ein neues Detail. Er erzählt es auch seinen Freunden und den Gästen ringsum – die Angst im Hotel steigt. ~~Auch im
  Freitext-Gespräch (6.15) weiß er es.~~ (Freitext gestrichen 2026-10-21)
- **Beziehung in dieser Zeit** (gilt seit 2026-10-21 für alle schweren Momente, 6.18): Alles zählt **doppelt** – Plaudern, Hilfe, aber auch Beleidigen und Klauen. **Geschenke
  dreifach**, und **passende** noch mehr: eine Kerze für den, den der Geist gewürgt hat (er hat Angst im Dunkeln),
  Süßes, Suppe oder gebratener Kürbis für den, der im Bett liegt, und immer der Lieblingskürbis. Ein Geschenk zählt in
  dieser Zeit wie zwei für „guter Freund“ (6.3). Wer mit ihm befreundet ist und ihn kein einziges Mal besucht, kränkt
  ihn ein bisschen.
- **Geschenke trägt er (gilt für alle Gäste):** Was man einem Gast schenkt, verschwindet nicht mehr, sondern er hält
  es in der Hand und bringt es in sein Zimmer; Essbares (Süßes, gebratener Kürbis) isst er nach einer Weile. Wer im
  Bett liegt, behält das Geschenk eine Weile in den Händen. **Schachbrett und Würfelbecher** gehören dem Hotel und
  lassen sich nicht verschenken (entschieden 2026-10-21).

### 6.18 Das Sozialsystem verknüpft (entschieden 2026-10-21)
> Noch nicht umgesetzt. Knüpft die losen Enden aus 6.2–6.17 zu einem Kreislauf zusammen: Was man tut, spricht sich
> herum (1), jeder Tod hat eine Ursache (2), schwere Momente erzeugen Wünsche (3), Freundschaft schützt (4), und die
> Beziehung lässt sich nicht mehr erschleichen (5).

**1. Ein Kanal fürs Weitersagen: das Freundesnetz**
- *Bisher:* drei Kanäle – Negatives lief hotelweit an alle, Positives nur über Freunde (6.16), Monster-Wissen in einem
  eigenen Topf; gewichtet mit dem Tratsch des *Empfängers*.
- **Jetzt:** Alles läuft über das Netz aus **Freunden, Familie und Zimmernachbarn** (6.16) – Lob, Klagen (Diebstahl,
  Schlag, Beleidigung, Puppe vor die Tür gelegt), Monster-Wissen (Erlebnisse 6.12, Zeugenaussagen 6.17) und
  Todesnachrichten. Erzählt wird, wenn sich zwei Freunde treffen.
- **Stärke:** nach dem Tratsch des **Erzählers** (Mila verbreitet am stärksten, 6.0); bei jedem Weitererzählen halb so
  stark, nach **höchstens zwei Stationen** ist Schluss.
- **Zeugen** reagieren sofort; petzende Kinder (6.13) sind der Fall „Familie“.
- **Freunde suchen einander auf:** zusammen an die Bar, an den Schachtisch, zum Schmücken – es entstehen sichtbare
  Grüppchen, man sieht, wo Gerede entlangläuft.
- **Folge:** Wer keine Freunde hat, hört nichts. Der Ruf hängt davon ab, *wen* man verärgert – ein gut vernetzter
  Gast schadet mehr als ein Einzelgänger.

**2. Jeder Tod hat eine Ursache** (ersetzt „Schuld vs. Trauer“, 6.8)
- *Bisher:* Schuld hieß nur „kürzlich bestohlen“; Trauer (`grief`) und Schock hatten verschiedene Auslöser und kamen
  nur beim Monster; die Gedenkkerze wirkte nur auf den Spieler.
- **Jeder Tod merkt sich, wie es dazu kam:** Klopfen an Zimmer 13 ignoriert (4.13) · Puppe vor seine Tür gelegt (5.5) ·
  sein Telefon kurz vorher klingeln lassen (4.14) · als Begleiter mitgenommen (6.3) · Deko oder Birne von ihm geklaut ·
  Licht bei ihm ausgemacht (4.11). Daraus ergibt sich die **Schuld** des Spielers an *diesem* Toten.
- **Ein Wert für den Spieler:** Schock und Trauer werden eins – bei allen drei Bedrohungen, stärker nach Beziehung und
  Schuld.
- **Halluzinationen haben einen Namen:** Stimme am Telefon und falsches Klopfen (4.13, 4.14) kommen von dem Toten, mit
  dem man befreundet war oder an dessen Tod man schuld ist.
- **Seine Freunde trauern** (3). Erfahren sie die Ursache – als Zeuge oder über das Netz (1) –, sinkt ihre Beziehung
  zum Spieler stark.
- **Gedenken:** Eine Kerze vor seiner Tür senkt Schuld und Schock und bringt *seinen Freunden* Beziehung. Gäste zünden
  dort auch selbst Kerzen an – ein sichtbarer Gedenkort.

**3. Schwere Momente: empfindlicher Zustand und Wünsche** (verallgemeinert 6.17, erste Form von 6.14)
- **Zustände:** verletzt (6.17) · trauernd (ein Freund ist gestorben) · verwaist (6.13) · nach einem Angriff des
  Lakengeists · Puppe vor der eigenen Tür (5.5).
- **Gemeinsame Regeln** (wie bisher bei Verletzten): Taten zählen doppelt, im Guten wie im Schlechten · passende
  Geschenke · Besuche zählen, und wer als Freund nie kommt, kränkt · eigene Sätze.
- **Jeder Zustand ergibt einen Wunsch** – der Auftrag aus 6.14 ohne eigenes System: eine Kerze für den Toten, Deko für
  die Tür, Suppe ans Bett, eine Katze zum Trösten, die Deko zurück, die die Katze verschleppt hat. Der Gast nennt ihn
  im Gespräch, das Notizbuch notiert ihn (6.14, 3.10). Erfüllt: Beziehung ↑, und er erzählt es weiter (1).
- **Nach Ebenen** (6.0): Kernfiguren und zentrale Gäste haben eigene Wünsche, die übrigen allgemeine.

**4. Freundschaft schützt** (Freunde schmücken deine Tür mit: 5.10; Begleiter verstecken sich wirklich: behoben)
- **Zuflucht:** Wirst du gejagt und klopfst bei einem **befreundeten** Gast, macht er auf – das Gegenstück zum Klopfen
  an Zimmer 13 (4.13). Feinde machen nicht auf. Verallgemeinert in 6.19 (Klopfen und Einlass überhaupt).
- **Warnen:** neue Aktion im Gespräch oder am Telefon, solange es flackert: „Versteck dich!“ – dazu als **Ruf** an alle
  in Hörweite („Versteckt euch!“; beim Kürbismann „Holt Kürbisse!“, 4.21). Der Gast versteckt sich.
  Kam wirklich etwas, steigt die Beziehung deutlich (die „Hilfe bei Monster-Ereignissen“ aus 6.2); ein falscher Alarm
  (z. B. aus einer Halluzination) kostet Vertrauen (wie 3.6).
- **Wache halten:** Gute Freunde bleiben auf Bitte in Zimmer 13, während du schläfst – ein wacher Zeuge vertreibt den
  Lakengeist (4.18, beantwortet 3.6).
- **Feinde:** schließen ihre Tür ab, wenn sie dich kommen sehen (6.5). Sieht ein **stark Verfeindeter** dich ins
  Versteck gehen, ruft er es laut aus („Da drin ist er!“) – Lärm (4.15).

**5. Die Beziehung lässt sich nicht erschleichen**
- *Bisher:* Geschenke ohne Pause (Laub liegt gratis herum), Kerze schenken und zurückkaufen erfüllte „guter Freund“,
  „über das Monster reden“ und „beruhigen“ gingen endlos, Plaudern am Telefon umging das Tageslimit, feindselige Taten
  verfielen nie – und Schlechtes kam nur durch eigene Taten.
- **Zwei Tagesbudgets je Gast:**
  - **Beziehungsbudget:** Alle freundlichen Gesten – Plaudern (Gespräch und Telefon zusammen), Beruhigen,
    Monster-Gespräch – zählen am Spieltag nur **zweimal voll**, danach kaum noch.
  - **Gesprächsbereitschaft** nach Stufe (6.3): **Wohlgesinnte reden mehr** – je besser die Beziehung, desto mehr
    Gespräche am Tag und desto mehr Themen (Gerüchte, Erlebnisse, Wünsche, Tipps); gute Freunde suchen das Gespräch von
    sich aus (Besuch, 6.3). Über das Beziehungsbudget hinaus bringt Smalltalk **Inhalt, aber keine Beziehung** – Reden
    mit Freunden bleibt nützlich, lässt sich aber nicht abschöpfen. **Verärgerte** (ab „genervt“) haben wenige
    Gespräche am Tag, bieten weniger Optionen und **brechen früher ab** („Ich hab zu tun.“); ab „verfeindet“ bleibt nur
    das Entschuldigen (6.3). Kinder sind gesprächig, aber schnell abgelenkt.
  - Beide Budgets gelten auch fürs Telefon (4.14) und füllen sich am Morgen (2.4) wieder.
- **Geschenke nach Wert:** Füllmaterial (5.10) bringt Erwachsenen kaum etwas, Kindern schon. Für „guter Freund“ zählt
  nur ein Geschenk ab einem Mindestwert; was man vom Gast selbst gekauft hat, zählt nicht.
- **Beruhigen** bringt nur Beziehung, wenn der Spieler die Angst nicht selbst kurz vorher geschürt hat.
- **Vergebung:** Feindselige Taten verblassen langsam über Tage – wer sich lange benimmt, kommt aus „stark verfeindet“
  wieder heraus.
- **Neid** – Schlechtes, das nicht vom Spieler ausgeht: Ist Zimmer 13 in der Knappheit (5.10) sichtbar besser
  geschmückt als die Nachbartüren, werden schlecht geschmückte Nachbarn neidisch – die Beziehung sinkt langsam,
  Wütende klauen. Die Paranoia kommt aus dem Mangel.

**Zu klären:** Zahlen (Gespräche je Stufe, Mindestwert eines Geschenks, wie schnell Vergebung wirkt, wie stark Neid
ist) · wie lange eine Ursache „frisch“ genug ist, um als Schuld zu zählen.

### 6.19 Zimmer gehören den Gästen: Klopfen, Einlass, Aufbrechen (entschieden 2026-10-24)
> **Umgesetzt (2026-10-24)** wie unten, mit diesen Abweichungen: Gäste lassen nur Türen offen, durch die sie nicht
> durchkommen (zu lange jemand im Weg); die Badtür zum Abschließen von innen und das Einbrechen sehr wütender Gäste bei
> Zimmer 13 fehlen noch; das Tagesbudget aus 6.18 (5) für den Reparaturdank gibt es noch nicht (einmal je Tür und Tag
> gilt). Brecheisen (Heizkeller), Werkzeugkasten (Technikraum) und Schlüsselschrank stehen im Plan – der Schrank an der
> **Ostwand der Lobby** statt hinter der Rezeption (dort steht keine Wand, an der Westwand hängt das Aushangbrett).
>
> Verallgemeinert Zuflucht und Abschließen aus 6.18 (4): Freundschaft öffnet Türen – im
> wörtlichen Sinn. Zimmer werden sozialer Raum; Verstecke, Diebstahl (6.2) und Birnen (7.3) brauchen erst einen Weg
> hinein. Anlass: Gäste öffneten jede Tür, an der sie vorbeigingen, und ließen sie offen (nebenbei leuchteten dadurch
> viel mehr Lampen ins Bild, als nötig).

**1. Besitz und Schloss**
- Jedes bewohnte Zimmer **gehört seinem Gast** (bzw. seinem Haushalt – siehe „Zu klären“). Nur er hat den Schlüssel.
- **Gäste öffnen eine Zimmertür nur, wenn ihr Weg hindurchführt**, und schließen sie hinter sich – auch, wer nur
  durchgeht. Wer geht, schließt ab; wer daheim ist, hat die Tür zu, aber nicht immer abgeschlossen (Gesellige lassen
  sie manchmal einen Spalt offen).
- **Offen steht eine Tür nur,** wenn gerade jemand hindurchgeht, wenn der Gast in Panik geflohen ist (6.5), wenn das
  Monster sie aufgerissen hat oder wenn sie kaputt ist (5).
- **Unbewohnte Zimmer schließt das Hotel ab.** Hinein kommt man mit dem **Generalschlüssel** von der Rezeption
  (schwer zu bekommen, ein Wagnis nach 2.3) oder durch Aufbrechen. Verfallene und verlassene Zimmer bleiben offen.
- **Gilt auch umgekehrt:** Gäste klopfen an Zimmer 13 und kommen nur mit Erlaubnis, durch eine offene Tür oder mit
  einem Schlüssel hinein (sie lesen sonst das Tagebuch, 3.10). Sehr wütende Gäste können auch bei dir einbrechen – mit Lärm und Zeugen wie
  beim Spieler.

**2. Klopfen**
- An einer verschlossenen Zimmertür heißt [E] **„Klopfen“** (Lärm, 8 m, 4.15).
- **Niemand da:** Keiner antwortet – auch das ist eine Auskunft (er ist nicht im Zimmer).
- **Er schläft:** Er wacht auf und ist genervt (Beziehung ↓), nachts umso mehr.
- **Er ist da:** Er kommt an die Tür, öffnet einen Spalt, und es beginnt ein kurzes Gespräch an der Tür (3).
- **Ob er hereinlässt,** hängt an der Stufe (6.3) – guter Freund fast immer, neutral selten, Feinde nie (sie schließen
  eher noch ab, 6.18) –, am Charakter und an der Lage: Ist etwas unterwegs, lassen Freunde dich eher herein, Fremde
  eher nicht. Echt gejagt ist das die **Zuflucht** aus 6.18.

**3. Gespräch an der Tür** – vier Wege:
- **Ehrlich fragen:** „Darf ich reinkommen?“ – entschieden nach Stufe, Charakter, Lage.
- **Lügen:** Ausreden nach Lage („Die Rezeption schickt mich, wegen deiner Lampe“, „Ich hab was für dich“).
  Misstrauische fallen seltener darauf herein. Fliegt die Lüge auf (Geschenk versprochen, keins dabei), sinkt die
  Beziehung, und es spricht sich herum (6.18, 1).
- **Panik machen:** „Es ist hinter mir, lass mich rein!“ – wirkt bei Ängstlichen stark. Kommt nichts, zählt es als
  **falscher Alarm** und kostet Vertrauen (6.18, 4).
- **Bestechen:** Geld oder ein Geschenk in der Hand als Eintritt (physischer Handel, 6.4).
- **Drinnen** behält der Gast dich im Auge: Wer vor seinen Augen etwas nimmt, ist ein ertappter Dieb (6.2). Nach einer
  Weile bittet er dich zu gehen.

**4. Reinmogeln**
- **Durch eine offene Tür** einfach hinein. Erwischt der Besitzer dich uneingeladen drinnen, wirft er dich hinaus,
  die Beziehung sinkt, und er erzählt es weiter.
- **Hinterherschlüpfen,** wenn er gerade aufschließt.
- **Den Schlüssel** stehlen – oder ein **guter Freund** gibt dir einen Zweitschlüssel (Belohnung der höchsten Stufe).
- Eine offene **Fenstertür** von Terrasse, Garten oder Balkon (die nutzt auch der Lakengeist, 4.18).

**5. Aufbrechen**
- Mit einem **Werkzeug** (Brecheisen o. ä.), dauert ein paar Sekunden.
- **Laut** wie eine aufgerissene Tür: Neugier des Monsters (4.11), Gäste in der Nähe erschrecken und sehen nach (4.15).
- **Gesehen:** eine **feindselige Tat** gegenüber dem Besitzer und allen Zeugen, über das Freundesnetz weitererzählt
  (6.18, 1). Ungesehen weiß niemand, wer es war – wie beim Diebstahl.
- **Die Tür ist danach kaputt:** Sie steht offen und lässt sich nicht abschließen, bis sie repariert ist. Denselben
  Zustand hinterlässt das **Monster**, wenn bei einem Angriff „die Tür fällt“ (5.5) – die meisten kaputten Türen
  kommen von ihm.

**6. Reparieren**
- Der **Besitzer** repariert seine Tür nach einer Weile selbst (etwa am nächsten Tag); bis dahin ist sein Zimmer offen,
  und er hat Angst.
- Der **Spieler** kann sie mit Werkzeug reparieren: Beziehung zum Besitzer ↑, als Hilfe weitererzählt.
- **Kein Bonus für eigene Einbrüche:** Das Spiel merkt sich, wer eine Tür aufgebrochen hat – auch wenn kein Gast es
  weiß. Wer seine eigene reparieren will, bekommt nichts dafür (aber auch keinen Malus). Höchstens einmal je Tür und
  Tag, im Tagesbudget aus 6.18 (5).

**Verhältnis zu 2.3:** „Offen bleibt der Alltag“ gilt weiter für Flure, Lobby, Bar, Garten und Keller. Zimmer sind
kein Geheimnis-Ort, sondern sozialer Raum – mehrere Wege hinein, keiner davon ein Schlüssel-Parcours.

**Haushalte** (6.20): Jeder im Haushalt hat den Schlüssel; über Einlass entscheiden die Erwachsenen. **Kinder allein
im Zimmer** öffnen nur Bekannten – Freunden der Familie und anderen Kindern („Mama sagt, ich darf nicht aufmachen“).
Ein Kind lässt sich leichter beschwatzen; merken die Eltern es, sind sie wütend.

**Einzelheiten (entschieden 2026-10-24)**
- **Badtüren** gehören nicht zur Zugangsregel: Gäste schließen sie, wenn sie das Bad benutzen, und von innen lässt sie
  sich abschließen – ein Schutzraum im Zimmer (Idee „Bad“, 7.7).
- **Leise schließen:** Gäste schließen Zimmertüren leise; nur wer in Panik oder wütend ist, **knallt** sie (Lärm,
  4.15). Das Öffnen knarrt weiter.
- **Werkzeug:** **ein Brecheisen** im **Heizkeller** (UG) – im Revier des Monsters. Ein **Werkzeugkasten** zum
  Reparieren im **Technikraum** (UG), leichter zu erreichen. **Konrad Lorenz** (Bastler, HAUSHALTE.md H11) hat
  eigenes Werkzeug und leiht es Freunden.
- **Generalschlüssel:** im **verglasten Schlüsselschrank hinter der Rezeption**. Die Scheibe einschlagen ist laut,
  mitten in der Lobby – besser nachts. Er öffnet jede Zimmertür, außer der Bewohner ist drin und hat den **Riegel**
  vorgeschoben. Wer gesehen wird, wie er damit eine fremde Tür aufschließt, gilt als Einbrecher (5), nur ohne Lärm.
- **Erste Zahlen** (zum Probespielen):
  - **Einlass je Stufe** (6.3): guter Freund 95 % · befreundet 80 % · freundlich 60 % · nett 40 % · neutral 20 % ·
    genervt 5 % · ab wütend nie.
  - **Gespräch (3):** Lüge +25 (Skeptiker −20) · Panik +40 bei Ängstlichen, sonst +15 (Skeptiker −30) · Bestechen
    +10 je kleinem Geschenk oder Geldbetrag.
  - **Lage:** nachts −20 · ist etwas unterwegs, Freunde +20, Fremde −20. Je Gast **ein Versuch pro Spielstunde**.
  - **Aufbrechen:** 4 s, so laut wie eine vom Monster aufgerissene Tür (20 m, Alarm, 4.15).
  - **Reparieren:** Der Besitzer repariert am nächsten Morgen; ist er tot, bleibt die Tür kaputt (passt zum Gedenkort,
    6.18, 2). Der Spieler braucht mit Werkzeug 6 s: +8 Beziehung, weitererzählt.

### 6.20 Haushalte (entschieden 2026-10-24)
> **Umgesetzt (2026-10-24)** wie unten (HAUSHALTE.md → assets/data/households.json, beim Start neu eingelesen).
>
> Wer mit wem wohnt, entscheidet, wer eine Tür öffnen darf (6.19). Bisher hatte jedes Kind
> genau ein Elternteil und wohnte im Zimmer nebenan; jeder Gast hatte ein eigenes Zimmer.

- **67 Gäste = 54 Erwachsene + 13 Kinder in 39 Haushalten** (die Gesamtzahl aus 6.0 bleibt):

| Haushalt | Anzahl | Erwachsene | Kinder | Betten je Zimmer |
|----------|--------|------------|--------|------------------|
| Eltern + 2 Kinder | 3 | 6 | 6 | Doppelbett + 2 (oder Suite) |
| Eltern + 1 Kind | 3 | 6 | 3 | Doppelbett + 1 |
| Ein Elternteil + 2 Kinder | 1 | 1 | 2 | 3 |
| Ein Elternteil + 1 Kind | 2 | 2 | 2 | 2 |
| Paar ohne Kinder | 9 | 18 | – | Doppelbett |
| Allein | 21 | 21 | – | 1 (darunter die vier Kernfiguren) |

- **Kinder wohnen nie allein,** sondern im Zimmer ihrer Eltern (6.13) – dort stehen entsprechend mehr Betten.
- **Alles fest:** Jeder Haushalt wird von Hand festgelegt – Zusammensetzung, Namen, Generation, Charakter. Entwurf zum
  Bearbeiten: **[HAUSHALTE.md](HAUSHALTE.md)** (H01–H39, mit Vorschlägen für die zentralen Gäste).
- **Zimmerbedarf:** 3 Zimmer mit vier Betten, 4 mit drei, 9 mit Doppelbett, 2 mit zwei Betten, 21 Einzelzimmer, dazu
  Zimmer 13 – **40 bewohnte**. Der überarbeitete Plan (`map_a.aseprite`, 2026-10-24) hat **81 Zimmer** (EG 48, OG1 33):
  40 bewohnt, 4 Sonderzimmer (verlassen, abgeschlossen, zwei verfallene), **37 unbewohnt** und vom Hotel abgeschlossen
  (6.19).
- **Folgen:** Partner gehören zur Familie im Freundesnetz (6.16). Stirbt einer, bleibt der andere als Zeuge und
  Trauernder im selben Zimmer (6.18, 2); wache Partner sind füreinander Zeugen, der Lakengeist bleibt weg (Idee
  „Mehrbettzimmer“, 7.7).
- **Zimmer zugeordnet (2026-10-24) nach Größe:** Familien in die 103-m²-Zimmer (alle im OG1), Haushalte zu zweit in
  80–103 m² (die alten Paare im EG, ohne Treppe), die Kernfiguren in 68-m²-Zimmer (drei um Zimmer 13 – Zimmernachbarn, 6.16 –, Bruno im OG1),
  die übrigen Alleinstehenden in die kleinen 34-m²-Zimmer im EG. Danach fünf Tausche zugunsten von **Terrasse und
  Balkon** (41 Zimmer haben einen Außenzugang, bewohnt jetzt 17 statt 12): eine Familie ins 103-m²-Zimmer mit Balkon,
  zwei Paare in 68-m²-Zimmer mit Balkon, zwei Alleinstehende in kleine Zimmer mit Terrasse. Weitere Tausche vom Zeichner stehen nur in HAUSHALTE.md. Liste in **[HAUSHALTE.md](HAUSHALTE.md)**
  („Zimmerliste“). Die Nummern sind **Platzhalter** und werden noch ausgetauscht – die Zuordnung hängt an der
  **Stelle** im Plan (Lage, Größe, Mitte in Pixeln), nicht an der Nummer. Nur Zimmer 13 bleibt.
- **Nachnamen** (entschieden 2026-10-24, präzisiert am selben Tag) erscheinen **beim Hinsehen an der Tür** (im
  Hinweis, kein Schild an der Wand) und im **Hotelregister** (2.3): bei mehreren Personen der Nachname („Brandt“),
  bei einer Person Vor- und Nachname („Walter Ruprecht“).

- **Liste und Generator** (entschieden 2026-10-24): Die Liste legt fest, **wer** jemand ist – Name, Nachname,
  Geschlecht, Generation, Charakter, Haushalt. Der Generator würfelt **alles Übrige** wie bisher, mit festem Seed je
  Person (von Spiel zu Spiel gleich): Werte in der Spanne des Charakters (Mut, Gier, Tratsch, Preise, Zuverlässigkeit,
  Geld), Vorrat und Startdeko, Ernten/Schnitzen, Tagesablauf, Sätze, Würfel- und Schachstil, Aussehen (Farben,
  Hautton, Größe, Statur) und das Kleidungsstück für Spuren. Eigene Geschichten bekommen weiter nur Kern- und zentrale
  Gäste (6.0) – eine feste Familie ist eine Gruppe mit Namen, kein eigener Erzählfaden.

**Einzelheiten (entschieden 2026-10-24)**
- **Eigene Werte für zentrale Gäste:** Für Kernfiguren und ★-Gäste darf die Liste wenige gewürfelte Felder
  überschreiben – Haar- und Kleidungsfarbe, Lieblingsdinge, Startdeko, eigene Sätze. Alles andere würfelt der Generator.
- **Kinder mit zwei Eltern:** Je Kind bestimmt der Seed ein Elternteil; von ihm erbt es mit 70 % die Haarfarbe
  (Geschwister können verschieden aussehen). Der **Hautton** liegt zwischen beiden Eltern (Mittel der acht Stufen,
  zufällig gerundet).
- **Eine Tür je Haushalt** (39 statt rund 66):
  - **Startdeko** der Erwachsenen zusammengelegt, höchstens drei Stück an der Tür. Jeder Erwachsene behält seinen
    eigenen Vorrat und schmückt damit dieselbe Tür.
  - **Anspruch des Monsters** (4.8, 5.10) je Tür × (1 + 0,35 je weiteren Erwachsenen) – ein Paar ×1,35. Kinder zählen
    nicht (nie Opfer). Mehr Leute bringen mehr Deko, sind aber auch mehr Beute.
  - **Kisten** (5.10): „höchstens ein Stück am Spieltag“ gilt schon je Kiste für alle Gäste zusammen – bleibt so.
  - **Angriff** (5.5: bis zu fünf Türen, Opferzahl) und **Wettbewerb** (2.5) bleiben; nachstellen im Probespiel.
- **Nachnamen der Kernfiguren:** **Edna Wiegand**, **Bruno Kaminski**, **Mila Hellwig**; die Tochter des Heizers heißt
  **Marion Teske, geb. Ahrend** (2.3) – an der Tür „Marion Teske“, im Hotelregister mit „geb. Ahrend“.

## 7. Spielwelt: Das Hotel

- **Bereiche (Vorschlag):** Lobby, Flure mehrerer Etagen, Gästezimmer, Speisesaal/Küche, Wäscherei, Keller, Treppenhaus, **Hotelgarten** (Kürbisbeete, Laubbäume, umzäunt), **Bibliothek / Salon** (Schachbrett, Kamin, Billard), **Hotelbar** (Würfel, Darts).
- **Spinnenweben-Zonen:** verlassene Zimmer, Keller, Dachboden – dunkel und gefährlich.
- **Im Prototyp umgesetzt (2026-10-10, Hotel vergrößert 2026-10-11):**
  - **Lobby** (West, 14 × 14 m, Decke 5 m): Rezeption, Sofas, Säulen, Plattenspieler, Ausgangs-Doppeltür (verriegelt)
  - **Küche** (südlich der Lobby): Messer, Kerzenvorrat
  - **Hotelgarten** hinter einer **Glastür** (plus Fenster in der Lobby-Nordwand): Kürbisbeete, Bäume mit Laubhaufen, Hecken, Laternen, Mondlicht
  - **Erdgeschoss:** Hauptflur (78 m nach Osten) mit **drei Flurkreuzungen** – A und B mit langen Nord- und Südflügeln, C mit kurzen Flügeln – **44 Zimmer**
  - **Obergeschoss** (4 m höher) über ein **Treppenhaus** mit Wendepodest am Ende des Nordflügels: Hauptflur mit zwei Kreuzungen, **30 Zimmer** (211–244), zwei davon verfallen (Tür offen, Spinnweben). Zusammen **74 Zimmer** für rund 30 Gäste (veraltet: heute 67 Gäste in 39 Haushalten, 6.20)
  - Zimmer 11 (Edna), 13 (Spieler), 15 (Mila), 17 (verlassen, dunkel), 12 (Bruno), 14 (leer), 18 (abgeschlossen), 26 (Doppelzimmer für eine Familie, vorgemerkt); die **Wäscherei** hat seit 2026-10-23 keine Zimmernummer mehr, sie liegt im Untergeschoss (Zettel 1994 dort). Der Grundriss des Erdgeschosses bleibt ab 2026-10-23, wie er ist; alle übrigen sind zu Beginn mit Zufallsgästen belegt oder **unbewohnt** – eingerichtet, Licht aus, hier und da eine Kerze oder Münzen. Zimmer, hinter deren Rückwand ein Flügel liegt, haben kein Außenfenster.
  - **Kellertreppe** hinter der niedrigen Kellertür am Ostende des Erdgeschosses: 3,5 m hinab
  - **Keller** unter der Erde: Versteck des Monsters, Schlüssel zu Zimmer 18, altes Regal
  - Noch nicht gebaut: Bibliothek/Salon, Speisesaal, weitere Etagen; Gäste gibt es weiterhin nur drei

### 7.1 Die Lobby – Gemeinschaftsraum
- Großer, zentraler Raum **in der Mitte des Hotels**; von hier aus gehen Flure und Treppen ab. Hinter der monumentalen Doppeltür (2,50 × 2,50 m) liegt der verschlossene Ausgang.
- Treffpunkt der Gäste: Handeln, Reden, Gerüchte austauschen.
- **Feiern:** Gäste treffen sich und feiern zusammen (Musik, Kerzen, Snacks, viel Deko).
  - Positiv: Beziehungen ↑, Panik ↓, Trauer ↓, gute Handelsgelegenheiten.
  - Risiko: **Lärm** → Neugier des Monsters ↑ in der Lobby; während alle feiern, sind die **Zimmer leer** → Zeit zum Klauen (für einen selbst – und für andere).
  - Idee: **Deko-Wettbewerb** bei der Feier, die Puppe (Jury) kürt die beste Deko → Belohnung (Geld, seltene Deko).
    Vorgemerkt als Jury beim Großen Schmücken (5.5).
- **Wann wird gefeiert?** Feiern entstehen **spontan durch die Gäste**, z. B. wenn:
  - die Stimmung gut ist (wenig Panik, Monster lange nicht gesehen / gesättigt),
  - ein Gast etwas zu feiern hat (guter Handel, große Kürbisernte),
  - nach einem Todesfall als Trauerfeier / „Jetzt erst recht“.
  - Ein Gast lädt ein → es spricht sich herum → Gäste kommen je nach Laune und Beziehung zum Gastgeber. **Kinder
    kommen immer** (6.13).
- **Der Spieler kann selbst eine Feier ausrichten:**
  - Gäste persönlich einladen (Dialog) – ob sie kommen, hängt von der Beziehung ab.
  - **Tänze** (umgesetzt 2026-10-14): Gäste tanzen verschieden – hüpfen, wiegen, drehen, Arme hoch, Twist,
    schunkeln. Jeder hat einen Lieblingstanz und wechselt ab und zu.
    > 2026-10-18: Gäste mit Modell tanzen echte Tanzanimationen (Mixamo): Chicken Dance, Macarena, Hip-Hop –
    > ein Download gilt für alle Grundkörper. Die Code-Tänze bleiben für die Klötzchenfiguren.
    > 2026-10-19: Jeder Tänzer hat seinen eigenen Platz mit mindestens 1,5–2 m² Freiraum (Raster mit 1,4 m
    > Abstand, von der Tanzfläche aus nach außen) – vorher standen alle auf sechs Punkten im Knubbel.
  - Vorbereitung physisch in den Händen: Musik (Radio/Plattenspieler), Kerzen, Snacks aus der Küche, Deko in die Lobby tragen. Evtl. Geld für Extras.
  - Gelungene Feier → Beziehungen ↑ bei allen Gästen, Ruf ↑, Trauer/Schock ↓.
  - **Taktischer Einsatz:** Feier als Ablenkung, um in leere Zimmer zu schleichen – oder bewusst Lärm machen, um das Monster in die Lobby statt zum eigenen Zimmer zu locken (riskant für alle Anwesenden!).
  - Kaum Gäste erscheinen (schlechter Ruf) → peinlich, leer, und das Monster hört trotzdem die Musik.
- Die Lobby ist hell und gut dekoriert → relativ sicher, solange die Lichter brennen.

### 7.2 Maße & Architektur
Großzügige, etwas überdimensionierte Architektur – der Spieler soll sich klein fühlen.

| Element | Maße (B × H) | Bemerkung |
|---------|--------------|-----------|
| Deckenhöhe | 3,0 – 4,0 m | Hohe Decken, Schatten oben |
| Standard-Tür (Zimmer) | 1,20 × 2,10 m | Breit, komfortabel |
| Lobby-Tür | 2,50 × 2,50 m | **Doppeltür**, je Flügel 1,25 m, monumental |
| Kellertür | 0,90 × 1,80 m | Eng und niedrig |
| Spieler | 0,45 × 1,80 m | Kapsel-Hitbox |

> **Rahmen (2026-10-17):** Türen, Fenster und Durchgänge haben Rahmen im Craftsman-Stil aus braunem Holz:
> Zarge in der Laibung, glatte Seitenbekleidung, darüber Leiste, Friesbrett und Abdeckung mit Kehle;
> Fenster mit Fensterbank, Schürze und Rahmen um die Scheibe. Profil-Kit per Blender-Skript (9.2).

> **Überholt (2026-10-20):** Die niedrige Kellertür ist mit dem Untergeschoss (7.9) weggefallen – das Treppenhaus
> führt durch eine normale Tür in die Kellergänge.
>
> ⚠ **Kellertür und Spieler sind beide genau 1,80 m hoch.** Die Kapsel würde stecken bleiben. Optionen: Ducken nötig (passt atmosphärisch: man muss sich in den Keller *bücken*), Kellertür leicht erhöhen (z. B. 1,85 m) oder Hitbox minimal kleiner als 1,80 m.

- **Blender:** Maßeinheit Meter, 1 Blender-Einheit = 1 m = 1 Godot-Einheit. Modulares Kit z. B. im 1-m- oder 2-m-Raster, Wandhöhe 3,5 m als Standard.
- **Eigenes Zimmer:** sicherer Rückzugsort, Lager für Deko, **einziger Speicherpunkt** (Tagebuch auf dem Schreibtisch, siehe 8.5).
- **Atmosphäre:** lange Flure (ideal für Silhouetten am Ende), schwaches Licht, alte Tapeten, knarrende Böden.
  > **Offen (2026-10-20): Die Tapeten sollen wieder Flecken bekommen.** Die Flecken aus Rauschen im Wand-Shader
  > (Wasserränder, matter und etwas dunkler) gefielen nicht und sind vorerst raus; der abgegriffene Sockel bleibt.
  > Vermutlich braucht es eine manuelle Lösung (z. B. von Hand gemalte Flecken).
- **Eingeschlossen:** Ausgänge verriegelt – warum? (Story-Frage, siehe offene Punkte)

### 7.3 Fenster, Vorhänge & Wandlampen
> Stand: 2026-10-19 · im Prototyp umgesetzt (Außenfenster mit Vorhängen in Lobby und Zimmern, Wandleuchten und Kerzen, Deckenleuchten nur wo der Plan sie setzt – bisher vier in der Lobby, ein Lichtschalter pro Raum/Flurabschnitt, Glühbirnen als Gegenstand)

Alle drei sind **interaktive Objekte** mit derselben Schnittstelle `interact(actor)` wie Türen und Truhen (9.1) – **Gäste benutzen sie genauso wie der Spieler**.

**Fenster**
- Wirken wie eine **Wand**: Man kommt nicht hindurch, kann aber **hindurchsehen**.
- Vorhandene Grundlage: Die Glasscheiben in der Lobby-Nordwand (eigene Kollisionsebene „Glas“) blockieren Bewegung, lassen aber den Blick durch.
- **Sicht in beide Richtungen (Vorschlag):** Auch Monster und Gäste sehen hindurch → das Monster kann einen durchs Fenster bemerken (4.5), Gäste können einen durchs Fenster beim Klauen beobachten und werden zu Zeugen (6.2).
- Mondlicht fällt durch offene Fenster herein (Helligkeit der Zone, 4.4).
- **Milchglasfenster im Flur** – **entfernt (2026-10-17):** Die Innenfenster zwischen Flur und Zimmern gibt es nicht mehr; Zimmertüren haben stattdessen einen Rahmen mit breiterem, überstehendem Sturz. Handabdrücke des Monsters landen auf den Türen. (Früher: Licht, Schatten und Umrisse sichtbar, keine Sicht für Monster und Zeugen.)

**Vorhänge**
- Jedes Außenfenster hat Vorhänge, die man **aufziehen und zuziehen** kann.
- **Zugezogen:** kein Blick hinein und hinaus, aber auch **kein Mondlicht** → der Raum wird dunkler (und damit für das Monster attraktiver).
- **Aufgezogen:** Licht und Sicht – aber man ist auch von außen zu sehen.
- **Gäste** nutzen Vorhänge ebenfalls, z. B. zieht die ängstliche Edna sie nachts zu, um nicht gesehen zu werden – und macht ihr Zimmer damit dunkler.

**Wandlampen**
- **Keine Deckenlampen mehr (entschieden 2026-10-17):** Mit Deckenlampen wirkte das Hotel zu hell und zu gemütlich. Licht kommt nur noch von **vereinzelten, gedimmten Wandlampen** und **festen Kerzen** (Flurkommoden, Bank, Lobby, Theke, Zimmertische). Die hellsten Lichter sind Kerzen und Kürbisse; die Decken sind aus demselben Holz wie die Zimmerböden und nur schwach zu erkennen. Ein erster, noch dunklerer Stand war zu finster – jetzt bleiben dunkle Ecken als Umriss sichtbar.
- **Deckenleuchten wieder, aber gezielt (entschieden 2026-10-19):** Wo der Gebäudeplan eine Deckenleuchte setzt, hängt eine – gedimmt wie die Wandlampen, nicht flächendeckend. Zuerst vier in der Lobby: Über dem Luftraum hängen sie als Pendel von der hohen Decke herab (auch von der Galerie aus zu sehen). Sie gehören zum Raum und hängen am selben Lichtschalter, ihre Birnen lassen sich wie alle anderen herausdrehen, wo man sie erreicht.
- **Ein Lichtschalter pro Raum** (entschieden): schaltet alle Wandlampen des Raums bzw. Flurabschnitts gemeinsam ein und aus. Die Deko-Kerzen brennen immer. Große Räume dürfen mehrere Schalter haben (an jedem Eingang einen); sie schalten gemeinsam wie eine Wechselschaltung (2026-10-20).
- **Licht aus = das Monster kommt** (4.4). Ausschalten ist also eine bewusste Entscheidung – z. B. um nicht gesehen zu werden – mit hohem Preis.
- **Flackern trotzdem:** Eingeschaltete Lampen flackern weiterhin, wenn das Monster sich ankündigt (4.2). Kaputte Lampen bleiben kaputt, egal wie der Schalter steht.
- **Glühbirnen herausdrehen & mitnehmen** (entschieden): Jede Lampe hat eine Glühbirne, die man herausdrehen kann. Die Birne ist ein **normaler Gegenstand** (3.2): klein, einhändig, zerbrechlich: **Fällt sie tiefer als 1,5 m, platzt sie** (entschieden und umgesetzt 2026-10-24) – Knall (8 m weit), Splitter und Scherben, die Birne ist weg. Ebenso **zerbricht eine Kerze, die tiefer als 2 m fällt**, zu einem großen Wachsfleck (brennend kann sie Deko anzünden, 5.11); aus der Hand fallen lassen geht beides heil.
  - **Fehlt die Birne, bleibt die Lampe dunkel** – egal wie der Schalter steht → die Zone wird dunkel → das Monster kommt (4.4).
  - **Einsetzen:** Eine Birne kann in jede leere Fassung geschraubt werden – z. B. ins eigene Zimmer, um es heller und sicherer zu machen. Ersatz für kaputte Lampen.
  - **Monster lenken durch Birnen-Klau:** Wer einem Gast die Birnen aus Zimmer oder Flurabschnitt klaut, macht dessen Bereich dunkel und lenkt das Monster auf ihn (4.11). Gleichzeitig wird das eigene Zimmer mit der Beute heller → doppelter Vorteil, doppeltes Risiko.
  - **Entdeckung:** Gäste bemerken fehlende Birnen. Wird man beim Herausdrehen gesehen, gilt es als Diebstahl (6.2, Gerüchte). Eine Birne in der Hand vor fremder Tür ist verdächtig.
  - **Gäste klauen auch Birnen**, z. B. in Panik für ihr eigenes Zimmer – oder als Racheklau beim Spieler.
  - Birnen sind **Handelsware** (Ersatzbirnen evtl. im Hausmeisterraum/Keller).
  - **Birnen brennen durch** (entschieden): Mit **geringer Wahrscheinlichkeit** geht eine eingeschraubte Birne kaputt, wenn
    - das Licht **stark flackert** (Vorwarnung, 4.2) – je stärker das Flackern, desto höher die Chance,
    - das **Monster in der Nähe** ist (je näher, desto wahrscheinlicher).
    - Folge: kurzes Aufblitzen, Knall/Klirren, die Lampe bleibt dunkel → die Zone wird dunkel → das Monster wird noch mehr angezogen (4.4). Eine sichere, helle Zone kann so mitten in einer Begegnung kippen.
    - Kaputte Birnen sind nutzlos (Vorschlag: bleiben als Scherben in der Fassung, müssen herausgedreht und ersetzt werden). Ersatzbirnen werden dadurch wertvoll.
- **Gäste schalten Licht** ebenfalls: in ihrem Tagesablauf (Schlafen → Licht aus) – oder als **Sabotage** im Flur vor fremden Türen (4.11). Umgekehrt kann der Spieler einem Gast das Licht ausmachen und so das Monster auf ihn lenken.

**To-do: Gäste bedienen Lichtschalter aktiv (vorgemerkt 2026-10-13, noch nicht umgesetzt)**
> Stand im Prototyp: Gäste schalten nur das Licht **ihres eigenen Zimmers** – per Fernzugriff auf den
> Schalter (`Guest._set_room_light()`), ohne hinzugehen: an beim Heimkommen (`_check_lights()`), aus zum
> Ausruhen.
- **Dunkelheit ist unangenehm:** Betritt ein Gast einen dunklen Raum oder Flurabschnitt, geht er zum
  Schalter und macht das Licht an – in jedem Raum, nicht nur bei sich. Ängstliche Gäste schneller und
  zuverlässiger, mutige lassen es auch mal dunkel.
- **Beim Verlassen ausschalten:** Verlässt ein Gast ein **Hotelzimmer** und ist **sonst niemand mehr darin**
  (kein Gast, nicht der Spieler), schaltet er das Licht aus. Flure, Lobby, Bar usw. bleiben an.
- **Manchmal vergessen sie es** (Vorschlag: je nach Gast 10–30 %, in Panik oder auf der Flucht immer).
- **Sichtbar und hörbar:** Der Gast geht wirklich zum Schalter (NavMesh-Weg, kurze Pause, Klick-Geräusch)
  statt aus der Ferne zu schalten. Damit verraten Lichtwechsel, wo Gäste unterwegs sind.
- **Wechselwirkungen:**
  - **Licht aus = das Monster kommt** (4.4): Leere Zimmer werden dunkel und damit für das Monster
    interessanter – ein vergessenes Licht schützt ein Zimmer, das niemand braucht.
  - **Ausruhen** bleibt wie bisher (bewusst Licht aus im eigenen Zimmer, solange er drin ist).
  - **Fehlende oder kaputte Birne:** Der Schalter hilft nicht → Gast beschwert sich, holt evtl. Ersatz
    oder meidet den Raum (Anknüpfung an Birnen-Klau, 4.11).
  - **Spieler im Zimmer:** Ist der Spieler noch drin, bleibt das Licht an. Ein Gast, der das Licht
    ausmacht, während der Spieler sich darin versteckt, wäre ein eigener Schreckmoment (später).
- **Technik-Ideen:** Wer ist im Raum? (Raum-Zuordnung über Position, wie bei `LightSwitch.find()`);
  Schalter als Wegziel; neuer Gast-Zustand fürs Schalten; Spielstand ändert sich nicht (Schalter werden
  schon gespeichert).

**Für später vorgemerkt**
- **Zerbrechende Fenster** – wird in einer späteren Runde geplant (bis dahin sind Fenster unzerbrechlich).

**Zu klären**
- Brauchen Glühbirnen eine heiße Lampe / Verbrennungsgefahr beim Herausdrehen bei eingeschaltetem Licht? (Vorschlag: erst ausschalten, sonst kurz „Autsch“ und Birne fällt evtl.) – im Prototyp noch ohne.
- Zerspringt eine heruntergefallene Birne? – im Prototyp noch nicht.

### 7.4 Fahrstuhl & Tiefkeller (vorgemerkt 2026-10-11)
> **Stand 2026-10-23 – Aufzug gebaut:** Statt des Gitterfahrstuhls ein Hotelaufzug mit **Teleskoptüren**, die
> beidseitig zur Mitte schließen, in einem Holzportal; darüber die **Lampenanzeige** „U“, „0“, „1“ (runde Lampen, 8 cm),
> daneben ein Rufknopf. Die Kabine **fährt wirklich** zwischen Untergeschoss, Erdgeschoss und Obergeschoss: drei goldene
> Handläufe wie an der Rezeption, gegenüber der Tür ein **Spiegel** (echtes Spiegelbild, seit 23.10. mit der Spielerfigur, 3.9),
> eine Deckenleuchte, links ein **Bedienfeld** aus Messing (drei Etagenknöpfe untereinander, darunter Tür auf / Tür zu,
> darunter Alarm). Motor und Glocke an Abfahrt und Ziel machen das Monster neugierig, der **Alarm** ist laut und
> erschreckt Gäste. **Aufzug 1 fährt schon jetzt** – die Reparatur unten kommt später als Sperre davor. **Aufzug 2 ist
> tot** (7.10), sieht aber gleich aus; seine Anzeige wandert ab und zu ohne Kabine. Noch offen: Gäste und Monster im
> Aufzug (Falle, Nothalt), Notruftelefon, Halt im Tiefkeller und Dachgeschoss (sobald die Pläne stehen).
>
> **Stand 2026-10-21 (7.10):** Der **Tiefkeller kommt** – nur mit dem Aufzug erreichbar, Plan steht aus. Von den zwei
> Schächten wird **einer repariert**, der andere bleibt der Weg des Monsters. Der **Maschinenraum liegt im
> Untergeschoss** (nicht mehr am Ende des Obergeschosses), der **Heizraum** ebenfalls; der Aufzug hält auf allen
> Ebenen bis zum neuen **Dachgeschoss**. Was unten über Heizkeller, Kessel und Gitter steht, muss danach neu verortet
> werden (7.10, „Zu klären“).
>
> **Stand 2026-10-20:** Der Keller ist jetzt das **Untergeschoss** (7.9) mit einem **Heizkeller** als Versteck des
> Monsters – noch ohne Kessel, Kohle und Gitter. Ob Tiefkeller und Lager darunter kommen, ist offen.
>
> Noch nicht umgesetzt. Der bestehende Keller (Versteck des Monsters) bleibt über die Kellertreppe erreichbar; der **Tiefkeller** liegt noch tiefer und ist **nur mit dem Fahrstuhl** erreichbar.

**Grundidee:** Neben der Rezeption in der Lobby steht ein alter Gitterfahrstuhl mit dem Schild „Außer Betrieb“. Man kann ihn im Lauf des Oktobers **reparieren** und damit den **Tiefkeller** mit **Heizkeller** und **Lager** freischalten. Die Reparatur ist die erste größere Aufgabe des Spiels: Sie führt einmal durch das ganze Hotel und verlangt jedes Mal eine andere Art von Mut.

**Vor der Reparatur – Atmosphäre**
- Die **Stockwerksanzeige** über der Tür bewegt sich trotzdem manchmal. Niemand weiß, warum. Der Spieler lernt: Wenn die Anzeige wandert, ist etwas unterwegs.
- Aus dem Schacht hört man gelegentlich Kratzen. **Das Monster klettert im Schacht** – an den Schachttüren tauchen später Handabdrücke auf (neue Spur, 4.13).

**Die Reparatur – drei Teile, drei Gefahren**
Hinweise liefert das **Notizbuch des Hausmeisters**, kein Questmenü. Hat man es gelesen, schreibt der Spieler-Charakter die drei Mängel als drei Zeilen in sein eigenes **Notizbuch** unter „Aufgaben“ (3.10) und streicht sie durch, sobald sie behoben sind. Der erste Start des Aufzugs ist ein Meilenstein im **Tagebuch**. *(Bis 2026-10-23: eigene Seite im Tagebuch.)*

| Schritt | Wo | Gefahr / Mechanik |
|---------|----|-------------------|
| **1. Notizbuch & Schaltschlüssel** | **Zimmer 18** (abgeschlossen; der Schlüssel liegt schon heute im Keller) | Ausflug ins Monster-Versteck – am besten während einer Ruhephase, wenn es woanders schläft, oder in der Sättigung (4.10). Im Zimmer: Notizbuch mit den drei Mängeln und der **Schaltschlüssel** für die Kabine. |
| **2. Hauptsicherung** | Ein **Gast** hat die Ersatzsicherung (er hat sie dem Hausmeister „abgekauft“) | **Sozial:** Freundschaft, Handel, Mäxchen-Einsatz – oder Klauen mit allen Folgen (6.2). Gerüchte verraten, wer sie hat; nicht immer der Richtige. Eingesetzt wird sie am Sicherungskasten **im Keller** – noch ein Ausflug dorthin. |
| **3. Bremse lösen** | **Maschinenraum** im Untergeschoss, nahe dem Heizraum (7.10; vorher am Ende des Obergeschosses) | **Lärm:** Die Bremse wird mit einer Kurbel gelöst – E gedrückt halten, ca. 20 Sekunden, laut und quietschend (Neugier ↑ im Untergeschoss – dort, wo das Monster ruht). Loslassen unterbricht, der Fortschritt bleibt. Man steht dabei mit dem Rücken zur Tür. |

- **Tempo:** Realistisch in der zweiten Oktoberwoche, wenn das Monster schon gefährlich ist. Wer früh mutig ist, schafft es eher.
- **Belohnung beim ersten Start:** Das Licht in der Kabine geht an, ein „Ding“ – und die Anzeige springt ohne Zutun auf **„T“ (Tiefkeller)**. Die Kabine war schon unten.

**Den Fahrstuhl benutzen**
- **Halte:** Tiefkeller · Untergeschoss · Erdgeschoss (Lobby) · Obergeschoss · Dachgeschoss (7.10). Der Tiefkeller ist nur so erreichbar; für die anderen Ebenen ist er eine Abkürzung, ohne durch die Treppenhäuser zu müssen.
- **Lärm:** Motor und Glocke sind an **Abfahrt und Ziel** zu hören → Neugier ↑ an beiden Orten.
- **Falle:** Die Kabine ist eng, es gibt kein Versteck. Steht das Monster an der Zielhalte, öffnet sich die Tür trotzdem. Das Rauschen hört man schon während der Fahrt – mit dem **Nothalt** bleibt man zwischen zwei Etagen stehen. Sicher? Bis es oben auf dem Kabinendach kratzt.
- **Die Anzeige verrät, wo die Kabine ist.** Fährt sie ohne einen selbst, benutzt sie jemand: ein Gast (nach der Reparatur nutzen auch Gäste den Fahrstuhl) – oder niemand.
- **Notruftelefon** in der Kabine (4.14): Man kann die Rezeption anrufen. Manchmal klingelt es, wenn niemand darin ist.

> **Umfang (entschieden 2026-10-21):** Es bleibt der **Kern** – **Lager** mit den **Fundsachen-Koffern**, das **Gitter**
> und das **Kesselbuch**. **Eingefroren** (nicht geplant, erst später wieder anfassen): Kessel **anheizen** (Kohle,
> Wärme, Rohre), die **Ofenklappe** und der **Bolzenschneider** fürs Lager.

**Heizkeller**
- Großer, verrußter Raum mit einem **alten Kohlekessel**, Kohlenbunker, Rohren an der Decke und einer Werkzeugwand.
- *(eingefroren 2026-10-21)* **Anheizen:** Kohle ist ein **großer Gegenstand** (beidhändig, 3.2) und muss vom Bunker zum Kessel getragen werden; angezündet wird mit einer Kerze. Schaufeln ist laut.
- **Solange der Kessel brennt:**
  - Das ganze Hotel wird warm → Stimmung der Gäste ↑, Panik klingt schneller ab, Schock und Trauer (6.8) lassen schneller nach.
  - Die Glut taucht den Heizkeller in rotes Licht → er ist hell und damit relativ sicher (4.4). Geht das Feuer aus, wird er stockdunkel.
  - **Die Rohre klopfen und zischen im ganzen Hotel.** Das überdeckt eigenen Lärm (Rennen, Würfeln locken weniger) – aber auch Rauschen und Schritte des Monsters sind schwerer zu hören. Ein Tausch, kein reiner Vorteil.
- **Nachlegen:** Eine Ladung brennt etwa einen Ingame-Tag. Danach muss jemand wieder hinunter – der Spieler selbst oder ein Gast, den man darum bittet (Beziehung; moralisch heikel, 4.11).
- *(eingefroren 2026-10-21)* **Ofenklappe:** Hier lassen sich Dinge **verbrennen**: geklaute Gegenstände, blutige Kleidung, belastende Zettel. Ohne Beweis verlieren Gerüchte über einen an Kraft (6.2). Deko verbrennen geht nicht – das Feuer „will“ sie nicht.
- **Das Gitter:** Zwischen Heizkeller und dem alten Keller (Versteck des Monsters) liegt ein rostiges **Gitter**. Anfangs kommt das Monster nicht hindurch; man hört es dahinter atmen, wenn es ruht – wer dann Kohle schaufelt, weckt es. **Mit jedem Tag wird das Gitter lockerer** (4.8), gegen Ende des Monats ist es offen und der Tiefkeller gehört zu seinem Revier. **Seit 2026-10-21:** Hinter dem
  Gitter im Heizraum liegt der Schlüssel zur Kniestocktür des Dachbodens – ab etwa Tag 15 kommt man hindurch (4.21).
  Wo das Gitter genau sitzt, seit der Heizraum im Untergeschoss liegt, ist noch offen (7.10).
- **Story:** das **Kesselbuch des Heizers** von 1987 – derselbe Name wie auf dem ältesten Warnungszettel.

**Lager**
- Ein Verschlag aus Maschendraht mit Vorhängeschloss. *(Bolzenschneider eingefroren 2026-10-21 – wie man ins Lager kommt, ist damit offen.)* Den **Bolzenschneider** findet man an der Werkzeugwand im Heizkeller – eine kleine Aufgabe innerhalb des Tiefkellers.
- **Inhalt (endlich, wird nicht nachgefüllt):**
  - Kisten mit **Ersatzglühbirnen** und **Kerzen** (7.3).
  - **Alte Halloween-Deko früherer Jahre:** Girlanden, Hexenbesen, ein Totenkopf, Laternen – seltene, starke Deko (5.3). Der größte Schatz im Hotel.
  - **Fundsachen-Regal:** Koffer früherer Gäste mit Namensschildern von 1987 bis 2019 – dieselben Namen wie auf den Warnungszetteln. Kleidung, Fotos, Briefe. Ein möglicher Ort für den **Halloween-Schlüssel** (2.1).
- **Die soziale Entscheidung:**
  - **Geheim halten:** Man hat alles für sich. Aber Gäste bemerken plötzlich viel Deko vor Zimmer 13 – *„Woher hat sie/er das?“* → Gerüchte, Neid, Diebstahl (6.2).
  - **Teilen:** Ruf ↑ bei allen, vielleicht eine Feier zum Fund. Aber die Vorräte sind schneller weg, und Gäste fahren dann selbst in den Tiefkeller – manche kommen nicht zurück.
  - Gäste können den Bolzenschneider oder den Schaltschlüssel klauen und das Lager auf eigene Faust plündern.

**Zu klären**
- Lässt sich der Fahrstuhl nach der Reparatur wieder sabotieren (Sicherung herausdrehen, wie Glühbirnen), etwa von Gästen oder dem Spieler selbst?
- ~~Später weitere Halte (Dachboden über dem Obergeschoss)?~~ Ja: Dachgeschoss (7.10, entschieden 2026-10-21).
- Bleibt der Fahrstuhl in einer Zeitschleife (2.2) repariert? (Vorschlag: nein.)

### 7.5 Neuer Grundriss aus dem Gebäudeplan (entschieden 2026-10-18)
> Der bisherige, im Code festgelegte Grundriss (7, „Im Prototyp umgesetzt“) ist mit dem Git-Tag `alte-karte`
> gesichert. Das Hotel wird neu auf Grundlage des gezeichneten Plans `map.aseprite` gebaut.

- **Plan statt Code:** Der Grundriss wird in Aseprite gezeichnet, **1 m = 10 px**, Wände 2 px (20 cm). Ein
  Skript liest daraus Wände, Türen, Fenster, Räume und Einbauten; Möbel setzt weiterhin der LevelBuilder.
- **Vorlage für alle Stockwerke:** je Stockwerk eine Ebenengruppe (`EG`, `OG1` …, `Keller`) mit den Ebenen
  „Grundriss“ und „Beschriftung“ (frei, wird nicht gelesen); in `OG1` liegt das EG als Referenzebene zum
  Abzeichnen. Die **Legende steht als Farbnamen in `map.gpl`** neben der Plandatei (Aseprite speichert keine
  Palettennamen, 19.10.). Raumnamen, Bereiche, Treppen (mit Richtung)
  und künftig einzelne Objekte (mit Vorderseite) werden als **benannte Slices** eingetragen, z. B.
  „Raum: Küche“, „Treppe: Lobby“, „Objekt: Sofa“, im Obergeschoss mit Vorsatz: „OG1 Raum: Bibliothek“.
  Der Luftraum über der Lobby ist im OG1 als eigene Farbe „Luftraum“ eingezeichnet.
- **Legende:** Zimmer orange · Flure und Lobby hellblau-grau · Gärten hellgrün (draußen) · Terrassen vor den
  Gartenzimmern blassgrün · Pflanzen in ca. 60 cm hohen Steineinfassungen dunkelgrüne Quadrate · Bäume ·
  Striche auf der Wand: Flurtür hellgrün, Terrassentür knallgrün, Fenster blau, **Doppel-Glastür gelb**,
  Betriebstür fast weiß, Aufzugtür türkis, Haupteingang rot (verschlossen) · Glaswand gestrichelt (Pool).
- **Türanschlag (entschieden 2026-10-20):** Ein magenta Pixel „Türanschlag“ (#f300ff) an einem Ende eines
  Türstrichs gibt Scharnier und Aufgehseite vor: Es sitzt in der Wandhälfte, in die die Tür aufgeht, und dort
  steht die offene Tür. Ohne Pixel gehen Türen in Räume auf, nicht in Flure. Lichtschalter gehören auf die
  Griffseite – liegt einer hinter der offenen Tür, warnt der Build.
- **Größe** (wird verkleinert: Nord-Süd 60 m, 7.10)**:** ca. 151 × 130 m, **129 Zimmer** im Erdgeschoss: Ostflügel und Westflügel mit je einem
  Rundflur um zwei Innenhöfe, dazwischen ein großer Garten, im Süden die Lobby mit Bar + Spiele, Partyraum
  und Toiletten, im Westen Küche, Speisesaal, Lager und Kühlräume, im Norden der Indoor-Pool.
- **Bauphasen:** zuerst **Lobby, Mittelgarten und Ostflügel**, der Westflügel später.
- **Zimmernummern (dreistellig seit 2026-10-23, vorher vierstellig mit Flügel):** Stockwerk · zwei Ziffern.
  Erdgeschoss 0, erstes Obergeschoss 1; Ostflügel 01–49, Westflügel 51–99. Gezählt wird nach Laufweg: ab der Lobby
  einmal um den Rundflur, danach der Querflur zwischen den Höfen; **in Laufrichtung rechts ungerade, links gerade**.
  Zimmer darüber tragen dieselbe Nummer mit 1 vorne (über 013 liegt 113).
- **Spielerzimmer ist 013:** An der Tür ist die führende Null abgefallen, zu lesen ist nur **„13“** – anders als
  bei 012, 014 … nebenan. Gäste sprechen von „Zimmer 13“. Es liegt am rechten Innenhof, seit 23.10. ein
  Doppelzimmer mit Bad (Waschbecken für das Erwachen, 3.9); die Zimmer rund um diesen Hof werden Doppelzimmer.
- **Lobby mit Galerie:** Über Rezeption und Eingang ist die Lobby doppelt hoch (Luftraum ca. 7,4 × 20 m).
  Das Obergeschoss umschließt ihn als Galerie mit Geländer, von der man in die Halle hinunterschaut. Die
  Treppe hinter der Rezeption führt hinauf; daneben zwei Aufzüge.
- **Lobbytreppe (entschieden 2026-10-21):** eine richtige Hoteltreppe statt des Betonblocks – mittig im
  Luftraum (Eingang → Rezeption → Treppe → Galerie vor den Aufzügen), 3,8 m breit, 24 flache Stufen (16,7 cm
  hoch, 30 cm tief) auf 6,9 m Lauf, unten offen. Gebeizte Trittstufen, helle Setzstufen und Wangen, Läufer mit
  Messingstangen; beidseitig ein Geländer mit gedrechselten Stäben, Handlauf und Pfosten mit Knauf. Die
  Galeriegeländer bekommen denselben Stil. Im Code gebaut, nicht als Modell: Die Treppe folgt dem Plan.
- **Treppenhäuser:** zwei am Nordende der Flügel. Sie verbinden Keller, Erdgeschoss und Obergeschoss. Das
  östliche ist der Kellerzugang der ersten Bauphase.
- **Bis es Pläne für Obergeschoss und Keller gibt:** Galerie und Treppenhäuser enden oben an verschlossenen
  Türen; der bisherige Keller kommt sinngemäß unter das östliche Treppenhaus. Vorschlag für später: ein
  Kellergang unter der Nordseite verbindet beide Treppenhäuser.
- **Umgesetzt (2026-10-18), erste Bauphase:** Das ganze Erdgeschoss steht; bewohnbar ist der **Ostflügel**.
  Im Westflügel sind Flure, Innenhöfe und der **Küchenblock** (Küche, Speisesaal, Lager, Kühlräume) offen,
  die Zimmer bleiben verschlossen (Vorhänge zu, auch das Monster kommt nicht hinein), ebenso das Treppenhaus West.
  - **Sonderzimmer behalten ihre alten Nummern als Endziffern:** 0111 Edna, 0112 Bruno, 0113 Spieler,
    0114 leer, 0115 Mila, 0116 Wäscherei, 0117 verlassen, 0118 verschlossen (Schlüssel im Keller), 0126
    verfallen mit dem Kompass (vorher 226 im Obergeschoss), 0137 verfallen.
  - **Feiern finden im Partyraum statt** (Plattenspieler, Tanzfläche) statt in der Lobby; dort beginnt auch der
    erste Angriff. Würfeltisch in der Bar, Schachtisch in der Lobby unter der Galerie.
  - Das Kartenblatt „Obergeschoss“ liegt vorerst nicht aus (es zeigt nur die Galerie); die Kellerskizze liegt
    weiter im verlassenen Zimmer.

---

### 7.6 Partikeleffekte (entschieden und umgesetzt 2026-10-20)
- **Plattenspieler:** Solange Musik läuft, steigen **Noten** aus dem Trichter – wenige, langsam, schaukelnd, sie
  **leuchten in Regenbogenfarben** und wandern beim Aufsteigen durch den Farbkreis. Man sieht schon von Weitem,
  dass gefeiert wird (und das Monster hört es).
- **Feiermusik (entschieden und umgesetzt 2026-10-20):** Zum Original-Walzer kommen zwei echte Stücke; jede Feier
  spielt ein anderes als die letzte.
- **Discokugel (umgesetzt 2026-10-20):** Über der Tanzfläche im Partyraum hängt eine Discokugel an einer Schnur
  vom Dach des Luftraums, auf Höhe der Galerie. Sie spiegelt die Lampen und funkelt; auf Feiern dreht sie sich
  langsam, und **Lichtpunkte** ziehen über Wände, Decke und Tänzer. Endet die Feier (oder kommt beim ersten
  Angriff das Monster), steht sie still und die Punkte erlöschen; ist das Licht aus, bleibt sie dunkel.
- **Bunte Partylampen (entschieden 2026-10-21):** Rund um die Tanzfläche hängen farbige Strahler unter der Decke.
  Auf Feiern leuchten sie auf und **wechseln langsam die Farben** (rot, orange, grün, blau, lila – jeder versetzt,
  ab und zu ein gemeinsamer Wechsel im Takt), außerhalb sind sie aus. Mit dem ersten Angriff oder dem Ende der Feier
  erlöschen sie.
- **Konfetti (entschieden 2026-10-21):** Zu Beginn einer Feier und dann alle paar Sekunden schießt buntes
  Konfetti über der Tanzfläche hoch und rieselt herab; zum Abschluss eines großen Schmückens (5.9) auch dort. Was
  landet, bleibt als bunte Schnipsel am Boden liegen und verblasst erst nach einigen Spieltagen.
- ~~**Tränen (entschieden 2026-10-21):** Wer weint, dem laufen kleine helle Tropfen aus beiden Augen – bei der
  Schreckreaktion „Weinen“ (6.12) noch auf dem Weg ins Zimmer, bei Kindern, die sich vor Angst an Mama oder Papa
  klammern, bei umgerannten Kindern, bei Freunden eines Verstorbenen (6.16) und bei Kindern, die Mama oder Papa
  verloren haben.~~ **Entfernt (2026-10-22):** keine Tränenpartikel mehr.
- **Lakengeist:** Vom Saum rieseln **weiße Flocken**, sparsam, sie blenden mit ihm ein und aus. Im Flur können
  sie ihn etwas früher verraten – gewollt, als leise Vorwarnung.
- **Monster:** **keine ständige Aura** – es soll verborgen bleiben (4.13). Stattdessen eine **Aschespur**: Wo es
  war, hängen schwarze Flocken noch einige Sekunden in der Luft und sinken. Sie ist eine Spur wie die
  Fußabdrücke (Tabelle in 4.13). Idee für später: Halluzinationen legen falsche Asche.
- **Bäume:** Aus den Kronen löst sich **Herbstlaub**, trudelt zu Boden, bleibt kurz flach liegen und verblasst.
- ~~Alles im PS1-Stil: wenige, kleine, pixelige Partikel~~ → Partikel auf den realistischen Look ausgelegt (9.2, 2026-10-25); sparsam bleiben sie trotzdem.

### 7.7 Obergeschoss: Zimmer, Balkone, Katzenraum, Bibliothek (vorgemerkt und umgesetzt 2026-10-20)
- **Zimmer:** grundsätzlich **Doppel- bis Dreibettzimmer**, so groß wie unten (5,8 × 5,8 m) oder über zwei
  Zellen (5,8 × 11,8 m bzw. L-förmig). **Einige haben ein eigenes Bad** (Plan: „Bad“). Manche Zimmer sind über
  **Verbindungstüren** zu Suiten verbunden; die Zimmernummer ist die des EG-Zimmers darunter mit 1 vorne (7.5).
- **Türanschlag (entschieden 2026-10-20):** meist per Pixel im Plan (7.5). Ohne Pixel gehen **Badtüren ins Zimmer**
  auf (das Bad ist klein), **Verbindungstüren ins Zimmer mit der höheren Nummer**; Flurtüren wie bisher ins Zimmer.
- **Betten:** zwei bzw. drei **Einzelbetten** (1,5 × 2,1 m wie unten) statt Doppelbett – jedes bleibt ein Versteck
  (3.4). Im Plan stehen Betten und Lichter (Nachttisch-, Tür-, Bad- und in großen Zimmern Deckenleuchten); in die
  Flure sind die Wandleuchten des EG übernommen.
- **Balkone:** im Plan „Balkon“ (blassgrün-grau), erreichbar über die Terrassentür des Zimmers, je Zimmer durch
  ein **Balkongeländer** abgetrennt. Sie stehen **gewollt etwa 3 m über** – darunter liegt im Erdgeschoss ein
  überdachter, dunkler Streifen der Terrassen. Zum Mittelgarten hin sind die Balkone vorerst in Terrassenfarbe.
- **Katzenraum** über der Bar: mit **Kratzbäumen** und **mehr Katzen** als nur den dreien von 6.11. Er ist der
  **einzige Raum, in dem man wirklich vor allem sicher ist** – Katzen waren immer lieb: Monster und Lakengeist
  kommen nicht hinein. *Der Kürbismann kommt bisher doch hinein, und Ausharren dort ist die stärkste Strategie –
  vertagt, bis dahin bleibt es so (4.20, 2026-10-21).*
- **Bibliothek** im Westflügel (ca. 40 × 18 m) über dem Küchenblock.
- **Partyraum über zwei Stockwerke:** wie die Lobby mit einer **Galerie** im OG1 rund um den Luftraum, von der man
  auf die Tanzfläche hinunterschaut.
- **Ideen (Vorschlag):**
  - **Lakengeist (5.x):** Oben schwebt er nicht mehr nur vor dem Fenster, er **landet auf dem Balkon**, kratzt an
    der Balkontür und kommt ab einem späteren Mal durch sie herein. Die Balkontür zählt wie ein Außenfenster.
  - **Zwei Seiten:** Mit der Balkontür ist ein Zimmer keine Sackgasse mehr – Fluchtweg, aber auch eine zweite
    Seite, die man im Blick behalten muss. Vom Balkon aus beobachtet man den Garten.
  - **Gäste rauchen nachts auf dem Balkon** – Gespräche über das Geländer, Lauschen (4.7).
  - **Bad:** Badewanne bzw. Duschvorhang als Versteck (3.4), abschließbare Badtür als Schutzraum im Zimmer,
    laufendes Wasser ist Lärm und übertönt zugleich. Wer oben mit Bad wohnt, ist wohlhabender – Gerede und Neid (6.2).
  - **Mehrbettzimmer:** Paare sind wach füreinander Zeugen (der Lakengeist bleibt weg), schlafend nicht.
    Verschwindet einer, bleibt der andere als Zeuge und Trauernder zurück (4.18). Familien mit Kindern (6.13)
    wohnen oben zusammen statt im Zimmer nebenan.
  - **Katzenraum:** Verängstigte Gäste flüchten dorthin; wer sich dort versteckt, verliert nur Zeit (Speichern
    weiter nur in Zimmer 13, die Woche läuft weiter).
> **Umgesetzt (2026-10-20):** Das Obergeschoss steht im Spiel (Ostflügel bewohnbar, Westflügel wie unten nur mit
> offenen Fluren; Bibliothek offen): 87 Zimmer 1101–1182 / 1202–1273 mit 2–3 Einzelbetten, Bädern, Balkonen mit
> Geländern, Suiten über Verbindungstüren; Galerien mit Geländer um die Lufträume von Lobby und Partyraum; das
> Treppenhaus Ost führt vom Keller bis oben (Treppenhaus West weiter gesperrt). Zimmer ohne Schalter im Plan
> bekommen einen neben der Tür. **Katzenraum:** acht Kratzbäume, vier eigene Katzen (Luna, Fussel, Tiger, Mausi),
> Monster und Lakengeist kommen nicht hinein bzw. zu niemandem, der drin ist. Das Kartenblatt „Obergeschoss“
> zeigt jetzt das ganze Stockwerk; es liegt aus, sobald auf der Rezeption eine Karte im Plan liegt.
> Zimmer über keinem EG-Zimmer zählen im Flügel weiter (1182, 1273).
> **Treppenhäuser (entschieden 2026-10-20):** Was auf der Ebene eines Stockwerks an der Wand gegenüber der
> Treppenhaustür hängt, sitzt über dem Wendepodest – eine halbe Etage höher. Gilt für jedes Treppenhaus in jeder
> Ausrichtung; das Podest zum Keller setzt der Code.

- **Offen:**
  - Kann man das **Balkongeländer übersteigen** (langsam, laut) – ein geheimer Weg von Zimmer zu Zimmer?
  - **Hinunterspringen** in den Garten (4 m) als Notausgang mit Preis (laut, eine Weile humpeln) – oder gar nicht?
  - Bei rund 30 Gästen wird das Hotel mit Mehrbettzimmern noch leerer: Gäste oben bündeln, Flügel unten verlassen?

### 7.8 Wetter & Geräusche von draußen (vorgemerkt 2026-10-20)
Draußen ist immer Nacht (2.1) – aber nicht immer dieselbe. Der Himmel (Mond, Wolken, Waldkante) steht schon.
- **Gewitter**, zufällig und gegen Monatsende häufiger: Ein **Blitz** erhellt für einen Moment Garten und Flure durch
  die Fenster – und manchmal steht dabei eine Gestalt zwischen den Bäumen oder an der Waldkante (Halluzination oder
  Lakengeist?). **Donner** ist Lärm ohne Quelle: Er übertönt kurz Schritte – das Monster hört schlechter, der
  Spieler aber auch.
- **Regen** an den Scheiben, Wind in den Bäumen, mehr fallendes Laub (7.6).
- **Tiere und Ferne:** Krähen, eine Eule, ferne Hunde – und eine **Kirchturmglocke**, die hinter der Waldkante zur
  Mitternacht zwölfmal schlägt (umgesetzt 2026-10-23, kündigt die Geisterstunde an, 4.18).
- **Steigerung bis Halloween:** Der Nebel wird mit jedem Tag dichter, der Himmel wolkiger; an Halloween ist
  Vollmond.
- ~~**Offen:** wann „Mitternacht“ ist, solange es keine echte Uhrzeit gibt (nach Spieltag oder Nachtruhe?).~~ → 0 Uhr
  der Tagesuhr (2.4).
> **Umgesetzt (2026-10-20): Regen und Gewitter.** Meist ist es klar; alle paar Spieltage regnet es 2–4 Minuten, gegen
> Monatsende öfter, und öfter als Gewitter (ein Drittel am Anfang, drei Viertel an Halloween). Der Regen fällt draußen
> und ist durch die Fenster zu sehen, drinnen nie; man hört ihn (drinnen dumpfer), der Himmel zieht zu und der Mond wird
> schwächer. Beim Gewitter blitzt es alle 10–30 s – zwei, drei Zuckungen, das Licht fällt kurz durch die Fenster, der
> Himmel leuchtet auf –, Donner folgt nach bis zu 3,5 s (je später, desto leiser). Donner lockt niemanden, aber
> **das Monster hört danach ein paar Sekunden schlechter**. Noch nicht: Regen an den Scheiben, Gestalt im Blitz,
> Wind, Tiere, Kirchturmglocke, dichterer Nebel.

### 7.9 Untergeschoss (entschieden und umgesetzt 2026-10-20)
> **Wird neu gezeichnet (7.10, entschieden 2026-10-21):** Das Untergeschoss wird ausgebaut statt verkleinert – mit
> Heizraum, Maschinenraum, Wäscherei und Müllraum; darunter kommt der Tiefkeller. Gäste gehen künftig mit Grund
> hinunter.

Der alte Keller hinter der niedrigen Tür unter dem Treppenhaus Ost ist durch ein ganzes **Untergeschoss** ersetzt,
gezeichnet im Gebäudeplan (Gruppe „UG“, 7.5).
- **Treppenhäuser:** Beide Treppenhäuser im Norden enden im Untergeschoss, tiefer geht keine Treppe. Offen ist wie
  oben nur das Treppenhaus Ost; seine Tür führt in die Kellergänge.
- **Kellergänge:** grauer Boden, Wände aus **Brettschalungsbeton** (Abdruck der Schalbretter, Ankerlöcher;
  seit 2026-10-21, vorher einfach grau). Licht geben nur
  **Halogenleuchten**: 80 cm lange Röhren unter der Decke, kaltweiß, ohne Schalter. Jede **flackert von selbst**
  alle 10–30 Sekunden ein- bis dreimal kurz – unabhängig vom Monster (dessen Flackern kommt dazu).
- **Heizkeller** (dunkelrot im Plan): das **Versteck des Monsters**. Dort liegt nur, was früher im Keller lag:
  Kisten, das alte Regal, der Schlüssel zu Zimmer 18, Münzen, eine Batterie, der Warnungszettel von 2011, die
  UV-Schrift von 1987, Spinnweben und die Kiste mit alter Deko (5.7), dazu die kaputte Kellerleuchte mit Schalter.
  Der Eingang ist ein schmaler Gang zwischen zwei verschlossenen Kellerräumen.
- **Technikraum:** zugänglich, aber leer. **Wäscherei:** zugänglich, an beiden Längswänden Waschmaschinen.
- **Alle anderen Räume** sind verschlossen (rote Türen wie der Haupteingang) und leer; Servicetüren wie oben.
- **Aufzüge:** auch unten zwei Schachttüren, außer Betrieb.
- **Gäste** gehen nicht hinunter; das Monster streift auch durch die Kellergänge.
- **Kartenblatt „Keller“** (Zimmer 0117): die handgezeichnete Skizze zeigt jetzt das ganze Untergeschoss, der
  Heizkeller ist rot eingekreist („hier unten schläft es“).
- **Kessel und Rohre (2026-10-24):** Mittig an der Ostwand des Heizkellers steht ein alter **Kohlekessel**. Seine
  Feuerklappe steht offen, im Feuerraum lodern Flammen über der Glut und knistern; die Glut wirft einen orangeroten
  Lichtkegel aus der Klappe auf den Boden. Das Feuer **brennt vorerst immer** – Anheizen, Kohle, Nachlegen und Ausgehen
  (7.4) bleiben eingefroren. Wie in 7.4 macht der Schein den Platz am Kessel etwas sicherer: Licht schreckt das
  Monster ab, macht einen aber auch sichtbarer. Vom Kessel steigt ein Rohr auf und mündet in eine **Ringleitung**, die
  unter der Decke an allen vier Wänden entlangläuft, mit Abzweigen hinab (Rücklauf über dem Boden, Blindkappe, ein
  offenes Rohrende, eines durch die Decke) – nur Atmosphäre.
- **Offen:** übrige Technik sowie Tiefkeller und Lager aus 7.4.

### 7.10 Kleineres Hotel, mehr Ebenen (entschieden 2026-10-21)
> Teilweise umgesetzt (2026-10-22): Der neue Plan `map_a.aseprite` (EG, OG1 und UG untereinander, 151 × 60 m) ist
> gebaut; Pläne für Tiefkeller und Dachgeschoss stehen noch aus. Alte Spielstände spielen dabei vorerst keine Rolle.
>
> **Entschieden 2026-10-22:** Der Plan wird **von Hand eingerichtet** – der Code stellt nichts mehr selbst in die
> Zimmer (auch keine Süßigkeiten-Truhen und Automaten, 3.2/6.13); braucht eine Mechanik etwas, kommt es in den Plan.
> Eine Ebene `Zimmer` markiert, welche Räume zu einem Hotelzimmer gehören. Neue Möbel nach `map_legend.png`
> (Doppelbett – hellere Kante = Kopfende –, Badewanne, Waschbecken mit Spiegel, Dusche, WC, Fußmatte, Tisch mit drei
> Stühlen, Mülleimer, Snack- und Getränkeautomat; sonst zeigt die hellere Kante die Vorderseite), vorerst als
> Platzhalter bis zu den Modellen. **Badewanne** (entschieden und umgesetzt 2026-10-23): eingeflieste Wanne, 2,2 m lang,
> 50 cm tief auf 10 cm Sockel im gefliesten Block, der die Nische füllt (2,8 × 0,6 m) – Schürze und Rand um die Wanne
> gefliest, Messing-Wandarmatur 10 cm darüber. Für 3,8 m breite Bäder (2026-10-24) gibt es statt einer längeren
> Wanne eine **Wannenablage**: 1 m gefliester Block in Wannenhöhe, eigene Planfarbe, wird an die Wanne angesetzt
> (modular, noch nirgends eingebaut). **Fensterunterkanten** liegen überall im Hotel auf **90 cm** (2026-10-23).
> **Kieswege** im Garten (Kieseltextur folgt), **Müllraum** im Keller, nicht gebaute
> Kellerräume bleiben zu. **Bäume** im Plan sind nur Standortmarken, jeder Baum hat dieselbe Größe. **Grasbüschel**
> (entschieden und umgesetzt 2026-10-22) nur **ohne PS1-Look**: verwildert, bis 30 cm, wiegen sich im Wind und neigen
> sich unter Schritten und Gegenständen zur Seite – niedrig genug, dass nichts darin verschwindet (beide Looks spielen
> sich gleich); Wege, Beete, Kübel, Baumwurzeln und Gegenstände des Plans bleiben frei. **Zimmer 13**
> liegt, wo der Plan es beschriftet (Innenhofblock Ost, Tür zum Südflur); die übrigen fest belegten Zimmer stehen
> vorerst auf ihren alten Nummern, bis sie neu verteilt sind.

**Warum:** Mit ca. 151 × 130 m und rund 130 Zimmern je Stockwerk sind die Wege für 5-Minuten-Tage (2.1) zu lang, und
viele Zimmer bleiben leer. Ein kompaktes Hotel kennt man nach ein, zwei Tagen – Ortskenntnis (wo steht der nächste
Schrank?) ist im Horror die halbe Spannung. Dasselbe Monster auf halber Fläche ist dichter: Rauschen, Flackern und
Spuren treffen öfter dort, wo der Spieler ist. Statt in die Breite wächst das Hotel **in die Höhe und Tiefe** – und
das Geheimnis (2.3: Heizer, Kessel, Abkommen) liegt ohnehin unten.

**Grundriss**
- **Ost-West bleibt, Nord-Süd wird 60 m** statt bisher bis zu 130 m (7.5).
- **Das Schwimmbad** rutscht nach Süden und bleibt – das Wasser, das das Monster spürt (4.13), ist eine der schönsten
  Frühwarnungen.
- **Kürbisfelder** (5.8) und Gärten bekommen im kleineren Plan einen neuen Platz.
- **Zimmer mit fester Bedeutung** werden neu verteilt (bisher 0111 Edna, 0112 Bruno, 0113 Spieler, 0115 Mila, 0116
  Wäscherei, 0117 Kellerskizze, 0118 UV-Aufsatz, 0126 Kompass, 7.5).
- **Gästezahl:** wird separat geklärt (6.0) – weniger Zimmer heißt weniger Gäste.

**Ebenen** (von unten nach oben)

| Ebene | Erreichbar | Inhalt |
|-------|------------|--------|
| **Tiefkeller** (neu) | **nur mit dem Aufzug** (7.4) | Lager, Fundsachen-Koffer früherer Gäste (7.4), Kandidat für den Halloween-Schlüssel (2.1) – Plan steht aus |
| **Untergeschoss** | Treppenhäuser, Aufzug | Heizraum, Maschinenraum, Wäscherei, Müllraum (unten) |
| **Erdgeschoss** | | Lobby, Bar, Partyraum, Küche, Garten, Schwimmbad, Zimmer |
| **1. Obergeschoss** | | Zimmer, Balkone, Katzenraum (7.7) |
| **Dachgeschoss** (neu) | Treppenhaus, Aufzug | **kleinerer Grundriss**, offene Bereiche mit wenigen, gezielten Aufgaben (Plan steht aus); hinter einer **Kniestocktür** der **Dachboden**: eine Kette von Kammern wie in *Doors*, am Ende der Kopf des Kürbismanns (4.21). Weitere Kandidaten: Spinnweben-Zone (5.4), Séance (6.10) |

**Jede Ebene hat einen Hausherrn.** Weil jede Bedrohung ihr eigenes Lockmittel hat – das Monster die Dunkelheit,
der Lakengeist Fenster und Schwäche, der Kürbismann den Spaß –, ergibt sich eine Ordnung, die der Spieler lernen kann:

| Ebene | Hausherr | Warum |
|-------|----------|-------|
| 1. Obergeschoss | **Lakengeist** (4.18) | Schlafzimmer, Außenfenster, Balkone, Nachtruhe |
| Erdgeschoss | **Kürbismann** (4.19) | Lobby, Partyraum, Bar, Garten – hier wird Spaß gehabt |
| Untergeschoss, Tiefkeller | **Monster** (4.13) | keine Fenster (kein Geist), kaum Spaß (kein Kürbismann), sein Versteck |

Das Monster streift weiter durchs ganze Hotel, aber unten ist es zu Hause. Wer hinuntergeht, weiß, wem er begegnet.
Wer wohin darf und wo keiner erscheint (Dachgeschoss), regelt 4.20: eine Bedrohung je Ebene, außer Hörweite
voneinander; der Tiefkeller gehört allein dem Monster.

**Räume im Untergeschoss**
- **Heizraum:** Versteck des Monsters, Kessel, Kohle, Kesselbuch des Heizers (7.4, 2.3).
- **Maschinenraum:** Antrieb des Aufzugs. Hier wird die Bremse gelöst (7.4) – die laute Kurbel direkt neben dem
  schlafenden Monster.
- **Wäscherei:** Waschmaschinen (7.9), Wäschekisten mit den alten Lakengespenstern (5.6) – Laken als Brücke zum
  Lakengeist. Ersetzt die Wäscherei im Erdgeschoss (0116).
- **Müllraum** (neu): Ein **Müllschlucker** führt von den oberen Stockwerken hinunter.
  - Er beantwortet die offene Frage, was mit den Leichen passiert (6.12).
  - Er ist ein **Klangkanal**: Was hineinfällt, poltert durchs ganze Haus (Lärm, 4.15).
  - Er ist ein **Kletterweg des Monsters** wie der tote Aufzugsschacht: Kratzen hinter den Klappen auf jeder Etage.
- **Gäste gehen künftig hinunter** – nicht von selbst, aber mit Grund: Aufträge (6.14), Bitten des Spielers (4.11:
  „Leg Kohle nach“, „Hol die Wäsche“). Ersetzt „Gäste gehen nicht hinunter“ (7.9), sobald es Gründe gibt.

**Aufzug** (Einzelheiten 7.4)
- Von den **zwei Schächten** wird nur **einer repariert**. Der andere bleibt tot und ist der Weg des Monsters: Kratzen
  im Schacht, Handabdrücke an den Schachttüren, die Stockwerksanzeige wandert ohne Kabine.
- Er hält auf allen Ebenen; der **Tiefkeller** ist der Halt, den nur der Aufzug erreicht – erst dadurch hat die
  Reparatur einen echten Lohn. Mittelziel der zweiten Oktoberwoche.

**Leere Räume** (Speisesaal, Toiletten, Technikraum, Kühlräume, Bibliothek, Balkone …): werden beim Neuzeichnen des
Plans **einzeln entschieden** (2026-10-21) – je Raum, ob er eine Funktion bekommt, als Atmosphäre bleibt oder entfällt.

**Zu klären:** Pläne für Tiefkeller und Dachgeschoss · ob das Dachgeschoss auch über ein Treppenhaus erreichbar ist
oder nur mit dem Aufzug · wo Kessel und Gitter (7.4) liegen, seit der Heizraum im Untergeschoss ist.

## 8. Menüs, Speichern & Laden

> Stand: 2026-10-10 · im Prototyp umgesetzt · Ausbau-Ideen siehe 8.9
> Nicht umgesetzt: Lautstärke „Stimmen“ (es gibt noch keine Sprachausgabe), Tastenbelegung ändern, Fortschritt Fluchtweg als Autosave-Auslöser (Fluchtweg fehlt noch – bis dahin löst das Aufschließen einer Tür den Autosave aus).

**Leitgedanke:** Speichern ist Teil des Horrors. Man kann **nur im eigenen Zimmer** speichern – jeder Ausflug in Flur, Keller oder Garten ist also ein echtes Risiko. Ein Tod kostet den Fortschritt seit dem letzten Tagebucheintrag.

### 8.1 Entscheidungen im Überblick

| Thema | Entscheidung |
|-------|--------------|
| Speicherort | **Nur in Zimmer 13**, am **Tagebuch auf dem Schreibtisch** |
| Speichern gesperrt | **Während Vorwarnung und Manifestation** (Flackern, Rauschen, Monster aktiv) |
| Speicherplätze | **3 manuelle Slots + 1 Autosave** |
| Autosave | **Bei wichtigen Ereignissen**, nur in sicheren Momenten – seit 2026-10-21 nur Fortschritt, neue Bereiche und Aufwachen in Zimmer 13 (8.10) |
| Nach dem Tod | **Letzten Spielstand laden** (oder Hauptmenü) |
| Esc-Menü | **Spiel pausiert komplett**; Esc schließt zuerst ein offenes Fenster |
| Tagebuch-Ansicht | **Pausiert** ebenfalls |
| Beenden | **Kein automatisches Speichern**, nur Rückfrage – dazu „Unterbrechen und beenden“ mit einmaligem Zwischenstand (8.10) |
| Titelbildschirm | **Ja**, beim Spielstart |

### 8.2 Titelbildschirm (Hauptmenü)
- Erscheint beim Start des Spiels, vor dem Intro.
- **Hintergrund (Vorschlag):** Die verriegelte Lobby-Doppeltür oder ein langer Flur im PS1-Look – Nebel, eine flackernde Lampe, leichtes Bildrauschen. Ab und zu steht am Flurende eine Silhouette … und beim nächsten Flackern ist sie weg.
- **Einträge:**
  - **Fortsetzen** – lädt den neuesten Spielstand (Slot oder Autosave). Nur sichtbar, wenn einer existiert.
  - **Neues Spiel** – Slot wählen; ist er belegt → Rückfrage „Überschreiben?“. ~~Danach Intro-Text, Start in Zimmer 13.~~ Danach Erwachen am Waschbecken in Zimmer 13 (3.9) und der
    Willkommensbrief auf dem Schreibtisch statt eines Einführungstexts (2.5, 2026-10-23).
  - **Laden** – Slot-Übersicht (siehe 8.5).
  - **Einstellungen** (siehe 8.4)
  - **Beenden**
- **Altersempfehlung: ab 16 Jahren** (eingebaut 2026-10-11, selbst eingeschätzt – keine offizielle USK-/PEGI-Prüfung). Begründung: dauerhafte Bedrohung und Schreckmomente, Figuren sterben (angedeutet, Blutspuren statt Gore), Stehlen und das Opfern anderer Gäste als Spielmechanik, Würfelglücksspiel um Spielgeld. Hinweis beim ersten Start (zusammen mit dem Fotosensibilitäts-Hinweis, 8.4), dazu ein kleines Kennzeichen „ab 16“ unten rechts – im Stil des Spiels, kein nachgemachtes USK-Logo. Für eine Veröffentlichung: offizielle Einstufung über USK bzw. IARC (Steam, Konsolen-Stores) einholen.

### 8.3 Spielmenü (Esc)
- **Esc** öffnet das Spielmenü, das Spiel **pausiert komplett** (Monster, Gäste, Spielzeit, Kerzen, Wachstum). Ton wird gedämpft (z. B. Tiefpass), das Bildrauschen darf weiterlaufen.
- **Einträge:**
  - **Fortsetzen** (auch erneut Esc)
  - **Laden**
  - **Einstellungen**
  - **Steuerung** (Tastenübersicht) – **wird zur Hilfe** (entschieden und umgesetzt 2026-10-23): eine kleine Hilfeseite mit der
    Tastenübersicht und ein paar Sätzen zu den Grundlagen (Tagebuch speichert, Hand und Tasche, Licht, Hinsetzen …).
    Ersatz für die Tastenzeile, die bisher im Einführungstext stand (2.5). Vorschlag: nichts, was den friedlichen
    Anfang verrät (2.1) – Einträge zu Monster und Verstecken erscheinen erst nach dem ersten Angriff.
  - **Zum Hauptmenü** – mit Rückfrage und Hinweis „Zuletzt gespeichert vor 12 Minuten – ungespeicherter Fortschritt geht verloren.“
  - **Spiel beenden** – gleiche Rückfrage. Es wird **nicht** automatisch gespeichert (sonst ließe sich die Regel „nur im Zimmer speichern“ umgehen).
  - **Unterbrechen und beenden** (entschieden 2026-10-21, 8.10) – legt einen Zwischenstand an, der beim nächsten Laden gelöscht wird.
- **Esc-Reihenfolge:**
  1. Ist ein Fenster offen (Dialog, Schnitzen, Tagebuch, Handel) → Esc **schließt dieses Fenster**.
  2. Sonst → Esc **öffnet das Spielmenü**.
  3. **Im Versteck und im Minispiel** öffnet Esc direkt das Menü (pausiert); verlassen wird das Versteck/die Partie über die normale Taste (E).
- **Kein „Speichern“-Eintrag.** Stattdessen ein ausgegrauter Hinweis: *„Speichern nur am Tagebuch in Zimmer 13.“*
- **Gesperrt** während Jumpscare und Sterbebildschirm.
- **Optik (Vorschlag):** Gestaltet wie ein vergilbter Hotel-Meldezettel / eine Seite aus dem Gästebuch, passend zum Retro-Hotel.
- Das bisherige „Esc = Maus freigeben“ entfällt – das Menü gibt die Maus frei.

### 8.4 Einstellungen
Werden **getrennt vom Spielstand** gespeichert (gelten für alle Slots).

| Bereich | Optionen (Vorschlag) |
|---------|----------------------|
| **Bild** | **Helligkeit/Gamma mit Kalibrierbild** („Der Kürbis soll gerade noch erkennbar sein“) – wichtig, weil Dunkelheit Spielmechanik ist (4.4) · Vollbild/Fenster (Start immer im Fenster, 11.10.2026) · VSync · Sichtfeld (FOV) · Spiegelungen an/aus (glatte Flächen spiegeln, kostet Leistung – 21.10.2026) |
| **PS1-Look** | Hauptschalter an/aus · Interne Auflösung · Vertex-Wackeln an/aus · Dithering an/aus |
| **Ton** | Gesamt · Musik · Effekte · Stimmen |
| **Steuerung** | Mausempfindlichkeit · Y-Achse invertieren · Ducken halten/umschalten · später Tastenbelegung |
| **Barrierefreiheit** | **Flacker- und Rausch-Intensität reduzieren** (Fotosensibilität – Warnhinweis beim ersten Start) · Untertitel für wichtige Geräusche („Schritte hinter der Wand“) · **Spinnen als Kugeln** (Arachnophobie, 4.23, umgesetzt 2026-10-23) |

### 8.5 Speichern am Tagebuch
- Auf dem Schreibtisch in Zimmer 13 liegt das **Tagebuch** des Spielers. **E** → Blick aufs Tagebuch → **Slot 1–3 wählen** → ein Eintrag wird geschrieben = gespeichert. Solange die Tagebuch-Ansicht offen ist, **pausiert das Spiel** (wie im Menü).
- **Gesperrt während Vorwarnung/Manifestation** (seit 2026-10-21 auch, solange der Kürbismann im Haus oder der Lakengeist beim Spieler ist)**:** Das Tagebuch lässt sich nicht beschreiben – *„Meine Hände zittern zu sehr.“* Alle anderen Situationen sind erlaubt (auch bei offener Tür oder mit einem Gegenstand in der Hand – der wird einfach mitgespeichert).
- **Der Eintrag als Slot-Beschreibung:** Das Spiel formuliert automatisch einen kurzen Tagebuchsatz aus dem aktuellen Stand, z. B. *„Edna ist fort. Bruno redet nicht mehr mit mir. Vor meiner Tür brennen zwei Kürbisse.“* Dieser Satz erscheint in der Slot-Übersicht. **Seit 2026-10-21:** Namen nur von Kernfiguren und zentralen Gästen, der Rest wird gezählt (8.10).
- **Slot-Übersicht zeigt:** Vorschaubild (480 × 270), Tagebuchsatz, Spielzeit, Datum/Uhrzeit, lebende Gäste.
- Das Tagebuch ist **fest verankert** (nicht tragbar, nicht klaubar) – sonst könnte man sich das Speichern verbauen.
- **Meilensteine (3.10, entschieden 2026-10-23):** Beim Speichern schreibt die Figur auf, was seit dem letzten Eintrag
  an Wendepunkten geschehen ist – erstes Auftauchen des Monsters, erster Tod, Aufzug repariert, aber auch ein
  Diebstahl oder ein Opfer. Die Einträge lassen sich am Schreibtisch nachlesen. Aufgaben und Notizen stehen nicht im
  Tagebuch, sondern im Notizbuch, das man bei sich trägt (3.10).

### 8.6 Autosave
- **Ein eigener Slot**, der sich selbst überschreibt. Kann nur geladen, nicht manuell beschrieben werden.
- **Auslöser (wichtige Ereignisse):**
  - ~~Tod eines Gastes (sobald die Gefahr vorbei ist)~~ (gestrichen 2026-10-21, 8.10)
  - ~~Ende einer Feier~~ (gestrichen 2026-10-21, 8.10)
  - Fortschritt beim Fluchtweg (Schlüssel gefunden, Rätsel gelöst) – auch Aufzug, Kopf, Erlösung (8.10)
  - Erstes Betreten eines neuen Bereichs (Vorschlag; entschieden 2026-10-21)
  - **Aufwachen in Zimmer 13** nach einer Nacht Schlaf (neu 2026-10-21, 8.10)
- **Nur in sicheren Momenten**, sonst wird der Autosave **aufgeschoben**, bis alle Bedingungen erfüllt sind:
  - keine Vorwarnung/Manifestation, kein Such- oder Jagdmodus
  - Spieler nicht im Versteck, nicht im Dialog, nicht in einem Minispiel
  - Monster weit genug entfernt (Mindestabstand, Tuning-Wert)
  - Damit wird verhindert, dass ein Autosave den Spieler in eine ausweglose Lage speichert.
- Dezente Anzeige: kleine flackernde Kerze in der Bildschirmecke.

### 8.7 Laden & Tod
- **Laden** ist jederzeit möglich: über das Spielmenü und den Titelbildschirm.
- **Sterbebildschirm** (4.6) bekommt die Optionen:
  - **Letzten Spielstand laden** – der neueste von Slot 1–3 und Autosave
  - **Spielstand wählen**
  - **Hauptmenü**
- Gibt es noch keinen Spielstand → „Neu beginnen“ (Start in Zimmer 13).

### 8.8 Was gespeichert wird
Weil es **kein verstecktes Inventar** gibt (3.2), *ist die Welt der Spielstand*: Jeder Gegenstand muss mit Ort und Zustand gespeichert werden (die Tasche für Kleines mit dem Spieler).

| Bereich | Inhalt |
|---------|--------|
| **Spieler** | Position, Blickrichtung, geduckt, Gegenstand in der Hand, Geld, Schock/Trauer/Schuld (6.8) |
| **Gegenstände** | Typ (inkl. Glühbirnen), Position/Rotation, Zustand (geschnitzt, Kerze drin, Brenndauer, Verfall), Ort (Boden, Truhe, Hand eines Gastes) |
| **Welt** | Türen (offen/zu/abgeschlossen), Truhen-Inhalte, Lampen (intakt/kaputt, Birne drin/fehlt), Lichtschalter je Raum (an/aus), Vorhänge (offen/zu), Kürbisbeete (Stufe, Wachstum), Laub-/Spinnweben-Vorräte, Plattenspieler, Kommoden (Schubladen offen/zu, schon durchsucht) |
| **Gäste** | lebt/tot, Position, aktuelle Tätigkeit im Tagesablauf, Beziehung, Panik, Wissen/Gerüchte, Diebstahl-Erinnerungen, Wettschulden, getragener Gegenstand |
| **Monster** | Position auf der Route, Dreistigkeit, Neugier je Zone, Sättigung, Deko-Anspruch und -Gewöhnung (4.8–4.10) |
| **Puppe** | Position, beurteilte Tür, wer sie trägt (5.5) |
| **Ablauf** | Spielzeit, laufende Feier, Fortschritt Fluchtweg, Story-Flags, Tagebuchtexte |
| **Nicht** | Einstellungen (eigene Datei), laufende Minispiel-Partien von Gästen (starten nach dem Laden neu) |

### 8.9 Ausbau-Ideen (später)
- **Gäste lesen das Tagebuch:** Kommt ein Gast in Zimmer 13 (offene Tür, Schlüssel, Feier), kann er das Tagebuch lesen und so erfahren, wen man bestohlen oder dem Monster „geopfert“ hat (4.11, 6.2) → Abschließen lohnt sich doppelt. Das Tagebuch bleibt dabei fest im Zimmer. Drin steht es erst, wenn man seitdem gespeichert hat (3.10); das Notizbuch am Körper liest niemand.
- **„Albtraum-Modus“:** ein einziger Slot, der Tod löscht ihn.

### 8.10 Speicherregel geschärft (entschieden 2026-10-21)
> Noch nicht umgesetzt (die Sperre während Kürbismann und Lakengeist schon, 2026-10-21). Ändert 8.1, 8.3, 8.5 und
> 8.6 und beantwortet eine Frage aus 2.2.

**Die Probleme bisher**
- **Der Autosave war ein Checkpoint-System:** Tod eines Gastes, Ende einer Feier und das Aufschließen *jeder* Tür
  speicherten mitten im Hotel – bei 67 Gästen ohne Nachschub (6.0) alle paar Minuten. Der Leitgedanke „jeder Ausflug
  ist ein Risiko“ (8) war ausgehöhlt.
- **Beenden kostete viel:** Mit Tagen von 24 Minuten (2.4) verliert man leicht eine halbe Stunde, wenn man aufhören muss.
- **Die Zeitschleife (2.2) ließ sich umgehen:** einfach einen Stand vor dem 31. laden.
- **Der Tagebuchsatz** war für drei Gäste geschrieben und wird bei 67 zur Liste.

**1. Autosave nur bei Fortschritt und beim Aufwachen**
- **Auslöser:** Fortschritt (Aufzug repariert 7.4, Kopf gefunden und Kürbismann erlöst 4.21, wichtige Schlüssel,
  später der Fluchtweg) · **erstes Betreten eines neuen Bereichs** (Tiefkeller, Dachboden, Sperrbereiche 2.3) ·
  **Aufwachen in Zimmer 13** nach einer Nacht Schlaf (2.4, 3.6).
- **Fallen weg:** Tod eines Gastes, Ende einer Feier, Aufschließen einer Tür.
- Wer schläft, ist einmal am Tag gesichert; **wer wach bleibt, hat auch hier einen Nachteil.**
- Kein Autosave mehr kurz nach einem Tod: Einen Freund zurückholen geht nur über einen älteren *eigenen* Stand – und
  kostet den Fortschritt seitdem.
- Die Bedingungen für sichere Momente (8.6) bleiben.

**2. „Unterbrechen und beenden“**
- Neuer Eintrag im Spielmenü (8.3): Das Spiel legt einen **Zwischenstand** an, der **beim nächsten Laden gelöscht** wird.
- So kann man jederzeit aufhören, ohne Fortschritt zu verlieren – aber nicht speichern und laden, um etwas
  auszuprobieren, denn den Stand gibt es nur einmal. Die Regel „nur in Zimmer 13“ bleibt.

**3. Spielstände gehören zu einem Durchgang** (beantwortet 2.2 „pro Slot oder übergreifend?“)
- Setzt die Zeitschleife ein, werden alle Stände des alten Durchgangs zu **„Erinnerungen“**: ansehbar (Tagebuchsatz,
  Bild), aber **nicht mehr ladbar**.
- Der neue Durchgang beginnt mit den eigenen Zetteln und dem Zähler der Schleife (2.2).

**4. Der Tagebuchsatz nennt nur, wer zählt**
- Namen nur von **Kernfiguren und zentralen Gästen** (6.0), der Rest wird gezählt: *„Edna ist fort. Neun andere auch.
  Vor meiner Tür brennen zwei Kürbisse.“*

---

## 9. Technische Umsetzung (grob)

### 9.1 Godot 4.7
- **Renderer:** Forward+ (für Licht, Schatten, Volumetric Fog)
- **Spieler:** `CharacterBody3D` + Kamera, Interaktion per RayCast
- **Monster-KI:** State Machine + `NavigationAgent3D`
  - Helligkeit: kein echtes Pixel-Sampling, sondern **Licht-Zonen** (`Area3D` mit Helligkeitswert, der sich ändert, wenn Lampen flackern/ausfallen oder Kürbisse ausgehen)
  - „Bemerkt“-Erkennung: Monster im Kamera-Frustum + RayCast-Sichtlinie + Dauer-Timer
  - Suchmodus: Wegpunkte rund um das Spielerzimmer
- **NPCs:** `NavigationAgent3D` mit Avoidance (Gäste weichen einander/Spieler aus), `NavigationLink3D` für Türen & Treppen, Utility-KI + State Machine
- **Interaktions-Objekte („Smart Objects“):** Schrank, Bett, Truhe, Tür, Beet teilen sich eine gemeinsame Schnittstelle (`interact(actor)`), die **Spieler und Gäste gleichermaßen** nutzen. Verstecke haben eine **Reservierung**, damit nicht zwei Personen gleichzeitig hinein.
- **Minispiele:** Spieltisch als Smart Object (`GameTable`, gleiche `interact(actor)`-Schnittstelle) → Kamera schwenkt auf den Tisch, Spiel läuft diegetisch auf dem 3D-Brett. Ein gemeinsames **`Wager`-System** (Einsatz aushandeln, hinterlegen, auszahlen, Wettschulden) für alle Spiele. Schach-KI: einfacher Minimax mit Suchtiefe je nach Gast-Spielstärke. Partie-Zustand bleibt beim Abbruch erhalten.
- **Garten:** Pflanzen als Nodes mit Wachstumsstufen (Timer / Spielzeit), Modell-Wechsel je Stufe
- **Jumpscare:** eigene Kamera-Animation + Monster-Modell nah vor der Kamera, danach Death-Screen-Szene
- **NPCs:** State Machine (Tagesablauf, Handeln, Klauen), `NavigationAgent3D`
- **Effekte:**
  - Bild-Flackern & Rauschen: Fullscreen-Shader (CanvasLayer + ColorRect mit `screen_texture`) oder Compositor-Effekt
  - Licht-Flackern: Script auf Lichtquellen, zentral gesteuert über ein `MonsterEventManager`-Signal
  - Volumetric Fog für diffuse Silhouetten
- **Systeme (Autoloads):** `GameState`, `RelationshipManager`, `PlayerHands` (Tragen) + `Wallet` (Geld), `MonsterDirector`, `DecorationManager`, `SaveManager`, `Settings`
- **Speichern & Laden (siehe 8):**
  - **JSON** in `user://saves/` – `slot_1.json` … `slot_3.json`, `autosave.json`, je ein Vorschaubild `.png`. Jede Datei enthält eine **Versionsnummer**, damit ältere Spielstände nach Updates migriert werden können.
  - **Sicheres Schreiben:** erst in eine `.tmp`-Datei, dann umbenennen → kein kaputter Spielstand bei Absturz.
  - **Schnittstelle:** Alle speicherbaren Nodes sind in der Gruppe `saveable`, haben eine **stabile `save_id`** und implementieren `save_state() -> Dictionary` / `load_state(data)`.
  - **Dynamische Gegenstände** (geerntete Kürbisse, geschnitzte Varianten …) werden über ihren Typ neu erzeugt. Laden = Hotel ohne Start-Gegenstände aufbauen, dann alles aus dem Spielstand befüllen.
  - **Pause:** `get_tree().paused = true`; Menüs mit `process_mode = ALWAYS`. Spielzeit, Timer und Abläufe müssen über pausierbares `delta` laufen (nicht über Systemzeit), damit im Menü wirklich nichts weiterläuft.
  - **Einstellungen:** `ConfigFile` unter `user://settings.cfg`.
  - Debug-Startparameter (Vorschlag): `--load=1` (Slot laden), `--savetest` (speichern → laden → Zustand vergleichen).

### 9.2 Blender (lokal)
- Modellierung: Hotelmodule (Wand-, Boden-, Türsegmente als modulares Kit), Möbel, Deko-Objekte, Gäste, Monster
- Export: **glTF 2.0 (.glb)** → direkter Import in Godot
- Godot kann `.blend`-Dateien auch direkt importieren, wenn Blender lokal installiert und im Editor konfiguriert ist
- ~~**Stil: Low-Poly im PS1-Look** – wenige Polygone, kleine Texturen (64–256 px), Nearest-Filter, keine glatten Normalen nötig~~
- **Stil: realistischer Look (entschieden 2026-10-25).** Alle neuen Materialien, Shader und Modelle werden auf das Bild
  **ohne** PS1-Look ausgelegt: Texturen in voller Auflösung mit Mipmaps und linearem Filter, Normal- und
  Rauheitskarten, glatte Normalen, Polygonzahl nach Bedarf. Der PS1-Look bleibt als Umschalter in den Einstellungen
  (8.4) und darf nicht kaputtgehen, wird aber nicht mehr bevorzugt. Am Ende kommt ein eigens darauf optimierter
  Zusatzmodus (eigene Texturgrößen, Filter, ggf. eigene Materialvarianten).
- **Aufgabenteilung Blender ↔ Godot (Vorschlag):**
  - **Blender liefert das Aussehen:** einzelne Assets und ein modulares Kit (Wandsegment, Wandsegment mit Fenster, Vorhang, Wandlampe, Lichtschalter, Tür …) – **keine** große Blender-Szene des ganzen Hotels.
  - **Godot liefert das Verhalten:** Jedes Asset bekommt eine eigene Szene (`.tscn`), die das `.glb`-Modell mit Kollision, Licht und Skript verbindet (z. B. Fenster mit Glas-Kollisionsebene, Wandlampe mit flackerfähigem Licht).
  - **Platzieren:** zunächst weiter per Code im LevelBuilder, der diese Szenen statt Platzhalter-Kästen setzt; später optional eine von Hand gebaute Hotel-Szene im Editor.
  - Vorteil: Ein Objekt funktioniert spielerisch schon als Platzhalter, das Modell wird später einfach ausgetauscht.

**Wechsel zu Editor-Szenen – besprochen, bewusst verschoben (2026-10-17)**

Der Code-Workflow funktioniert gut und bleibt vorerst. Erst ausbauen: **Untergeschoss (Keller)** und **Aufzug**.
Danach steht das Hotel im Grundriss fest, und der Wechsel lohnt sich. Spätestens wenn Räume eher *gestaltet* als
*gebaut* werden (Deko nach Gefühl statt Koordinatenlisten im LevelBuilder), ist der richtige Zeitpunkt.

- **Ziel:** eine `hotel.tscn`, die man im Editor öffnet und als Ganzes sieht. Darin stecken Raum-Szenen als
  Instanzen (`rooms/lobby.tscn`, `rooms/guest_room.tscn` …), darin wiederum Asset-Szenen (`dresser.tscn` = Modell +
  Kollision + Skript). Godot setzt das beim Laden selbst zusammen, es gibt kein eigenes Zusammenbauen zur Laufzeit.
- **Warum verschachtelt statt einer flachen Datei:** gleiche Zimmer einmal einrichten und mehrfach verwenden (mit
  Abweichungen pro Zimmer), kleine Dateien für Claude, und Spieler und Claude können parallel an verschiedenen
  Räumen arbeiten, ohne sich zu überschreiben.
- **Rohbau:** Wände, Böden und Türen erzeugt heute erst der LevelBuilder beim Spielstart, im Editor wäre das Hotel
  leer. Geplant: den Rohbau **einmal per Werkzeug als `.tscn` speichern** und ab dann im Editor pflegen. Der
  LevelBuilder schrumpft entsprechend. (Alternative `@tool`-LevelBuilder nur als Zwischenlösung.)
- **Speicherformat:** Die Zuordnung über die Reihenfolge in Gruppen ist bei Editor-Szenen nicht verlässlich. Vorher
  auf **feste `save_id`s** umstellen (siehe 9.1). Reine Deko ohne Zustand ist nicht betroffen.
- **Reihenfolge:** 1. Asset-Szenen für vorhandene Modelle · 2. Rohbau exportieren + Raum-Szenen · 3. feste
  Speicher-IDs · danach interaktive Objekte auch in Editor-Szenen.
- **Zusammenarbeit:** Spieler platziert nach Gefühl im Editor, Claude bearbeitet dieselben `.tscn`-Dateien auf
  Anweisung weiter (verschieben, drehen, ergänzen, umräumen). `.tscn` ist Text, Claude prüft das Ergebnis über
  Screenshots aus dem Spiel. Dafür gilt: **sprechende Knotennamen** (`Candle_Left` statt `MeshInstance3D7`) und
  **nicht gleichzeitig dieselbe Szene bearbeiten** (vorher speichern bzw. committen, Godot lädt die Datei neu).
- Beim Wechsel die Regel „keine Editor-Szenen“ in CLAUDE.md und TECHNIK.md anpassen.

---

## 10. Offene Fragen für die Detaildiskussion

1. ~~Ziel~~ → **Dem Horrorhotel entkommen** (entschieden). Offen: Wie genau? (Schlüssel für die Lobbytür zusammensuchen, Rätsel, Hilfe der Gäste?)
2. ~~Zeitstruktur~~ → **durchgängig**, keine Level; Ingame-Tage à ~~ca. 5 min~~ 24 min mit Tagesuhr (2.4) vom 1. Oktober bis Halloween, draußen immer Nacht (2.1, entschieden).
3. ~~Monster-Kontakt~~ → Jumpscare + Sterbebildschirm, danach letzten Spielstand laden (entschieden, siehe 8).
3a. **„Bemerkt“-Auslöser:** Reicht Hinschauen, oder muss der Spieler sichtbar reagieren?
3b. ~~Spieler-Lichtquelle~~ → **Taschenlampe**, verrät die eigene Position, schützt nicht; mit UV-Aufsatz (späterer Fund) kurz vertreiben, kostet Batterien und macht es dreister (4.16, entschieden 2026-10-11).
3c. ~~**Garten-Zeit:** Wie lange wächst ein Kürbis – Minuten Echtzeit oder Ingame-Tage?~~ → kleine Sorten Minuten, große
    einen Spieltag (Riese zwei), Frost ab dem 25. (5.10, entschieden 2026-10-23)
3d. **Kellertür vs. Hitbox:** Ducken, Tür erhöhen oder Hitbox verkleinern?
3e. ~~Puppe~~ → **sichtbares Urteil statt wandernder Jury:** sitzt vor der am schwächsten geschützten bewohnten Tür,
    dorthin geht das Monster beim Angriff zuerst; tragen dürfen sie nur Spieler und Kinder (5.5, entschieden 2026-10-21).
3g. ~~Verstecke~~ → Zeitlimit wie in Doors, beim Hineingehen gesehen = Tod, Gäste können sterben (entschieden).
3i. **Schock-Malus:** Welche Mali aus 6.9? Wie stark, wie lange?
3j. ~~Feiern~~ → spontan durch Gäste, Spieler kann auch eine ausrichten (entschieden).
3k. **Minispiele (6.10):** Welche Spiele für den ersten Umfang? Echte Schachregeln (aufwendiger) oder zuerst ein einfaches Würfel-/Kartenspiel? Welche Möbel dürfen als Einsatz dienen?
3h. **Truhen:** Abschließbar? Gibt es eine eigene Truhe im Spielerzimmer?
3f. ~~Tragen~~ → kein Inventar, alles in den Händen, nur Geld als Wert (entschieden); Ausnahme am Körper: Kompass, Kartenblätter, Schlüsselbund (3.2, entschieden 2026-10-11). ~~Offen: ein oder zwei Hände?~~ → eine Hand für alles, dazu eine Tasche mit 6 Fächern für Kleines (3.2, entschieden 2026-10-22) ✔
4. ~~Story~~ → **Das Abkommen und der Heizer** (2.3, entschieden 2026-10-11). ~~Offen: Mitwisser besetzen~~ (Tochter des Heizers als Kernfigur, 2026-10-21). Offen: was das Ding vor 1987 war.
5. **Anzahl & Tiefe der Gäste:** Wenige tiefe Charaktere (3–5) oder viele einfache?
6. **Können Gäste sterben / verschwinden?** (starke emotionale Konsequenz)
7. ~~Grafikstil~~ → ~~**Low-Poly im PS1-Look**~~ → **realistischer Look**, PS1-Look als optimierter Zusatzmodus am Ende (9.2, entschieden 2026-10-25).
8. **Umfang:** Kleines Halloween-Projekt (Jam-Größe) oder größeres Spiel?
9. **Single-Player** – oder später Koop denkbar?
10. **Sprache:** Deutsch, Englisch, beides?

---

## 11. Nächste Schritte

1. ~~Offene Fragen klären~~ ✔
2. ~~Godot-Projekt anlegen~~ ✔
3. ~~Vertical Slice~~ ✔ (2026-10-10)
4. ~~Ausbau~~ ✔ (2026-10-10): feste Patrouillenroute · Lobby, Küche, Garten mit Glastür, 8 Zimmer, Wäscherei · Kürbisbeet, Laub, Spinnweben, Kerzenvorrat · Schnitzen + Kerze einsetzen · 3 Gäste mit Tagesablauf, Dialog, Handel, Beziehung, Geschenken, Klauen (beidseitig), Zeugen & Gerüchten, Panik, Verstecken, Tod, Sättigung, Schock/Schuld, Gedenken · Feiern (spontan + selbst ausgerichtet)
5. Minispiele mit Gästen (6.10): ~~Mäxchen an der Hotelbar~~ ✔ · als Nächstes **Darts und Kürbis-Schnitz-Duell** (2026-10-21; der Rest eingefroren) · ~~Möbel-Einsätze~~, Bibliothek/Salon mit Schach
6. Puppe („Halloween-Jury“) als sichtbares Urteil vor der schwächsten bewohnten Tür (5.5, entschieden 2026-10-21) ·
   später Jury beim Großen Schmücken
7. Fluchtweg aus dem Hotel (Ausgangsschlüssel / Rätsel / Hilfe der Gäste) · Scheitern als Zeitschleife mit eigenen Zetteln (2.2) · Fortschritt & Geheimnis: Sperrbereiche, Dokumente, Mitwisser (2.3)
7a. Hotel verkleinern (Nord-Süd 60 m), Untergeschoss ausbauen (Heizraum, Maschinenraum, Wäscherei, Müllraum),
    Tiefkeller und Dachgeschoss dazu – Pläne neu zeichnen (7.10, entschieden 2026-10-21) ·
    Fahrstuhl reparieren (ein Schacht), Tiefkeller mit Lager (7.4, 7.10) · ~~Zimmertelefone (4.14)~~ ✔ (2026-10-11)
7b. ~~Lärm & Sichtbarkeit als ein gemeinsames System (4.15)~~ ✔ (2026-10-11)
7c. ~~Taschenlampe mit Batterien und UV-Aufsatz (4.16)~~ ✔ (2026-10-11)
7d. Gäste bedienen Lichtschalter aktiv: Licht an im Dunkeln, beim Verlassen leerer Zimmer aus, manchmal vergessen (7.3, vorgemerkt 2026-10-13)
7e. ~~Angriffe zu kurz – das Monster kehrt nach wenigen Metern um~~ ✔ (4.13, behoben 2026-10-17)
7f. ~~Hotelkatzen: frei laufend, streicheln, Lieblingsgäste, vom Monster verschont, fliehen und weinen in seiner Nähe, werfen Deko um, bringen selten Deko und schlafen auf deinem Bett (6.11)~~ ✔ (2026-10-17)
7g. ~~Angriffsabsicht & Flacker-Signal: Eine Flackerwelle vom Keller aus verrät mit ihrer Dauer, ob es sich umsieht, einen holt oder auf Raubzug geht (n Opfer ∝ 1/n², Flackern 1 + 2 × n s, Spieler zählt mit, täuscht manchmal) (4.17)~~ ✔ (2026-10-17)
7h. ~~Lakengeist am Fenster: kommt bei Licht aus und offenem Vorhang, wird von Mal zu Mal dreister (Handabdrücke auf der Scheibe, Hypnose, kommt herein und würgt), verschwindet vor Zeugen in 0,5 s, ab dem 6. Mal im Flur, wenn alle schlafen (Nachtruhe zu zufälligen Zeiten) (4.18)~~ ✔ (2026-10-17)
7i. ~~Lakengeist hartnäckiger: Losreißen kaum noch möglich, wartet vor dem Schrank und fliegt hinein, Schlafen im eigenen Bett, Schlafmangel lockt ihn – nach drei Nächten sicher im Flur (4.18)~~ ✔ (2026-10-18)
7j. ~~Schach in der Lobby: Schachtisch und Brett, KI-Gegner mit Spielstärke je Gast, Einsätze, Herausforderungen, Gäste spielen untereinander (6.10)~~ ✔ (2026-10-18)
7k. ~~Trinken an der Bar (Rausch, Halluzinationen, Kater, Gäste trinken mit, 3.7) und der Wert **Schwäche**, nach
    dem sich der Lakengeist seine Opfer sucht (4.18)~~ ✔ (2026-10-19)
7l. Schlaf & Müdigkeit: Wachzeit statt Nächte, fremde Betten, Gäste wecken, ausgeschlafen/übermüdet (3.6) – vorgemerkt
    2026-10-19, Fragen offen · ~~Tagesuhr 24 Stunden = 24 Minuten, feste Nachtruhe der Gäste, Tagesablauf in vier
    Phasen, Werte umrechnen (2.4, entschieden 2026-10-21)~~ ✔ (2026-10-23)
7m. ~~Kinder: nur erschreckt, nie Opfer, Familien, kein Alkohol, immer auf Feiern, vom Monster übersehen, laut,
    Süßes oder Saures, petzen, Waisenkind, Kakao (6.13)~~ ✔ (2026-10-19) · alle vier Grundkörper aus Meshy ✔ (2026-10-20)
7m0. Drei Bedrohungen: eine je Ebene und außer Hörweite, Kürbismann mit Ankündigung in Stufen und leiernder Musik,
    gleiche Sicht, gemeinsame Lore („Das Hotel behält jeden“), Lakengeist erst nach dem ersten Angriff (4.20,
    entschieden 2026-10-21) · vertagt: Katzenraum
7m00. Kürbismann aufhalten und erlösen: mit gezeigten Kürbissen und gerufenen Helfern betäuben, Schlüssel hinter dem Gitter
    (ab etwa Tag 15), Dachboden als Kammernkette mit seinem Kopf, Ritual, Schädel/Axt/Jeansjacke als Deko (4.21,
    entschieden 2026-10-21)
7m1. Sozialsystem verknüpfen: Freundesnetz als einziger Kanal, Tod mit Ursache, schwere Momente mit Wünschen,
    Zuflucht/Warnen/Wache, Tagesbudgets, Geschenke nach Wert, Vergebung, Neid (6.18, entschieden 2026-10-21)
7m2. Deko knapp machen: ~~Füllmaterial wächst nach, starke Deko endlich, Anspruch je Tag bis ×3~~, Schutzkreis = Lichtschein,
    ~~Kürbisse faulen~~, Gäste schmücken nach Angst und Freundschaft und klauen bei Knappheit (5.10, entschieden 2026-10-21;
    Stufe 1 ✔ 2026-10-23)
7m3. Monsterwerte vereinfachen: Dreistigkeit in Spieltagen mit abklingenden Boni, heiße Stellen statt Zonen-Neugier
    (4.9) · Freitext-Prototyp entfernen (6.15) · Tiefkeller auf den Kern beschränken (7.4) · Tochter des Heizers als
    vierte Kernfigur (2.3, 6.0) – entschieden 2026-10-21
7n. Halloween im Hotel: Hotel schmückt sich bis zum 31., ~~Kostüme mit Lakengeist-Verwechslung, selbst verkleiden~~ ✔
    (2026-10-20), Gruselgeschichten-Abend, Kürbissuppe, alte Bräuche als Schutz, unheimliche Durchsagen,
    Gruppenfoto (5.9) – vorgemerkt 2026-10-20
7o. Eier-Streich der Kinder an Türen und Fenstern (6.13) · Aufträge von Gästen ohne Questmenü, notiert im Notizbuch (3.10)
    (6.14) · Gewitter, Regen, Kirchturmglocke, dichter werdender Nebel (7.8) – vorgemerkt 2026-10-20
7p. ~~Geisterstunde: 0–1 Uhr zieht der Lakengeist versteckt durch die Flure, angekündigt von der Kirchturmglocke,
    schwebt auf einen zu, wenn er einen sieht, verschwindet die ersten Male kurz davor und würgt danach (eigener
    Zähler), nur Flure (4.18)~~ ✔ (2026-10-23)
7q. ~~Fledermäuse (scheu, Frühwarnung, Schwarm als Lärm)~~ ✔ (2026-10-23) · Biss und der Vampir als vierte Bedrohung: Biss macht schwach, im schwachen Zustand
    tödlich, Knoblauch und Kreuz lassen ihn in einen Schwarm zerfallen; Twist: selbst Vampir werden, fehlt auf dem
    Gruppenfoto und im Spiegel (4.22, vorgemerkt 2026-10-23)
7q1. ~~Spinnen: krabbeln, zertreten, springen aus Schubladen ins
    Gesicht – abschütteln oder Biss wie ein Glas; Keller häufig, sonst selten; Arachnophobie-Einstellung (4.23)~~ ✔
    (2026-10-23)
7r. Verkleiden aus Fundstücken (Kürbis als Hut, Masken, Laken) und Maskenspiel „Wer steckt dahinter?“ im Partyraum
    (5.9, vorgemerkt 2026-10-23)
7s. ~~Türschmuck-Wettbewerb als Faden für den Anfang: Willkommensbrief statt Einführungstext, Aushangbrett in der Lobby,
    Durchsagen, Puppe als Jury in der Lobby, Siegerehrung am 2. um 20 Uhr als erster Angriff (wartet bis 22 Uhr auf den
    Spieler, Blick zur Puppe, sie löst sich in Rauch auf), danach veränderter Aushang und Warnungszettel mit der Regel
    der Puppe · Hilfeseite im Spielmenü statt Tastenzeile (2.5, 8.3, entschieden 2026-10-23)~~ ✔ (2026-10-23)
7t. ~~Schlafdauer 1–8 Stunden, jederzeit, Nächte anteilig (3.6)~~ ✔ (2026-10-24) · ~~Zeitsprung in der Nachtruhe:
    Gefahr nach dem Zeitplan des Monsters, Aufwachen mit Vorlauf, Morgenbilanz, Termine wecken, Wache (3.6)~~ ✔
    (2026-10-24) · Zeitsprung auch am Tag (später)
8. Echte Modelle aus Blender (glTF) statt Platzhalter, echte Sounds
9. ~~Titelbildschirm, Spielmenü (Esc), Einstellungen, Speichern/Laden~~ ✔ (2026-10-10, siehe 8) · ~~Fenster, Vorhänge, Wandlampen, Lichtschalter, Glühbirnen~~ ✔ (7.3) · ~~Sehen & Jagen~~ ✔ (4.12) · Speicherregel schärfen: Autosave nur bei Fortschritt, neuen Bereichen und Aufwachen, „Unterbrechen und beenden“, Stände je Durchgang, Tagebuchsatz (8.10, entschieden 2026-10-21)
10. Balancing, weitere Etagen
11. Zerbrechende Fenster (7.3, für später vorgemerkt)
12. Flecken auf den Tapeten, vermutlich von Hand (7.2, offen seit 2026-10-20)
