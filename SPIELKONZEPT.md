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
- [3. Core Gameplay Loop](#3-core-gameplay-loop)
  - [3.1 Spieler-Aktionen (Grundumfang)](#31-spieler-aktionen-grundumfang)
  - [3.2 Kein Inventar – alles in den Händen](#32-kein-inventar--alles-in-den-händen)
  - [3.3 Truhen](#33-truhen)
  - [3.4 Verstecken (inspiriert von Roblox *Doors*)](#34-verstecken-inspiriert-von-roblox-doors)
  - [3.5 Kommoden im Flur (entschieden und umgesetzt 2026-10-14)](#35-kommoden-im-flur-entschieden-und-umgesetzt-2026-10-14)
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
- [5. Halloween-Dekoration](#5-halloween-dekoration)
  - [5.1 Funktion](#51-funktion)
  - [5.2 Platzierung](#52-platzierung)
  - [5.3 Ideen für Deko-Typen (vorläufig)](#53-ideen-für-deko-typen-vorläufig)
  - [5.4 Deko selbst herstellen](#54-deko-selbst-herstellen)
  - [5.5 Die Puppe – „Halloween-Jury“](#55-die-puppe--halloween-jury)
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
  - [6.9 Dialog](#69-dialog)
  - [6.10 Minispiele mit Gästen](#610-minispiele-mit-gästen)
  - [6.11 Hotelkatzen (vorgemerkt 2026-10-14, umgesetzt 2026-10-17)](#611-hotelkatzen-vorgemerkt-2026-10-14-umgesetzt-2026-10-17)
  - [6.12 Schreck & Erlebnisse (entschieden und umgesetzt 2026-10-18)](#612-schreck--erlebnisse-entschieden-und-umgesetzt-2026-10-18)
- [7. Spielwelt: Das Hotel](#7-spielwelt-das-hotel)
  - [7.1 Die Lobby – Gemeinschaftsraum](#71-die-lobby--gemeinschaftsraum)
  - [7.2 Maße & Architektur](#72-maße--architektur)
  - [7.3 Fenster, Vorhänge & Wandlampen](#73-fenster-vorhänge--wandlampen)
  - [7.4 Fahrstuhl & Tiefkeller (vorgemerkt 2026-10-11)](#74-fahrstuhl--tiefkeller-vorgemerkt-2026-10-11)
  - [7.5 Neuer Grundriss aus dem Gebäudeplan (entschieden 2026-10-18)](#75-neuer-grundriss-aus-dem-gebäudeplan-entschieden-2026-10-18)
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
- [9. Technische Umsetzung (grob)](#9-technische-umsetzung-grob)
  - [9.1 Godot 4.7](#91-godot-47)
  - [9.2 Blender (lokal)](#92-blender-lokal)
- [10. Offene Fragen für die Detaildiskussion](#10-offene-fragen-für-die-detaildiskussion)
- [11. Nächste Schritte](#11-nächste-schritte)

---

## 1. Kurzbeschreibung (Pitch)

Ein 3D-First-Person-Horrorspiel. Der Spieler ist in einem alten Hotel eingeschlossen. Irgendwo in den Fluren lauert ein Monster, das man fast nie richtig sieht – es bleibt diffus im Hintergrund, bis es sich plötzlich zeigt. Schutz bieten nur Halloween-Dekorationen, die man vor seiner Zimmertür oder im Flur platziert. Die Deko ist knapp: Man bekommt sie über andere Hotelgäste – durch Freundschaft, Handel … oder Diebstahl. Doch wer andere bestiehlt, wird selbst bestohlen.

**Kernfrage für den Spieler:** *Vertraue ich den anderen Gästen – oder nehme ich mir, was ich zum Überleben brauche?*

**Spielziel:** Dem Horrorhotel **entkommen**. Die Zeit läuft **durchgängig** (keine Level), gezählt in **Ingame-Tagen vom 1. Oktober bis Halloween** – draußen ist immer Nacht (siehe 2.1). Grafik: **Low-Poly im PS1-Look**.

---

## 2. Genre & Stimmung

- **Genre:** First-Person-Horror / Survival mit sozialer Simulation
- **Tonalität:** Unterschwelliger, atmosphärischer Horror statt Dauer-Jumpscares. Halloween-Ästhetik (Kürbisse, Kerzen, Girlanden) als warmer Kontrast zur kalten, bedrohlichen Hotelkulisse.
- **Inspirationen (Richtung):** Andeutungs-Horror à la „Alien: Isolation“ (Bedrohung präsent, aber selten sichtbar), Retro-Hotel-Atmosphäre à la „The Shining“, soziale Dynamik ähnlich „Animal Crossing“-Beziehungen – nur mit Paranoia.

### 2.1 Zeit & Dramaturgie: Vom 1. Oktober bis Halloween (entschieden 2026-10-10)
> Im Prototyp umgesetzt (2026-10-11): Kalender, friedlicher Anfang, erster Angriff bei einer Feier am 3./4. Oktober (spätestens am 5.), zwei harmlose Angriffe. Noch offen: Schlüssel an Halloween und das Scheitern.

- **Kalender:** Das Spiel beginnt am **1. Oktober**. Die Zeit läuft durchgängig und wird in **Ingame-Tagen** gezählt. Draußen ist **immer Nacht** – der „Tag“ ist nur die Zähleinheit, kein Wechsel von Hell und Dunkel.
- **Tageslänge: ca. 5 Minuten Echtzeit** → 31 Tage ≈ 2,5 Stunden bis Halloween. Zentral einstellbar (Tuning-Wert, `Calendar.DAY_SECONDS`).
- **Datum sichtbar:** Abreißkalender an der Wand von Zimmer 13, im Spielmenü und kurz eingeblendet, wenn ein neuer Tag beginnt. Spielstände zeigen das Ingame-Datum.
- **Der friedliche Anfang:** Zu Beginn wirkt alles wie ein **gemütliches Hotel-Party-Spiel** – Gäste kennenlernen, Deko basteln, Kürbisse ziehen, Würfeln, Feiern. Keine Vorwarnung, kein Rauschen, nichts Bedrohliches. Auch Einführungstext und Gäste deuten nichts an. Der Spieler soll glauben, es sei ein friedliches Halloween-Spiel.
- **Der erste Angriff bricht das – am 3. oder 4. Oktober während einer Feier in der Lobby:** Musik, alle sind fröhlich, dann geht das Licht aus, Stille, Rauschen. Ab jetzt ist es nicht mehr friedlich.
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
- Gilt die Schleife pro Spielstand-Slot (Vorschlag: ja, Zähler und Zettel im Spielstand) oder slotübergreifend?
- Gibt es nach mehreren Schleifen ein Ende, oder endet es nur durch Flucht?

### 2.3 Fortschritt & Geheimnis (vorgemerkt 2026-10-11)
> Noch nicht umgesetzt. Gibt dem Spiel eine Richtung: Bisher überlebt man, kommt aber nirgendwohin. Verbindet Story (offene Frage 4), Zeitschleife (2.2), Warnungszettel (4.13), Fahrstuhl & Tiefkeller (7.4) und die Gäste (6).

**Grundidee:** Nicht alle Bereiche des Hotels sind von Anfang an erreichbar. Einige sind verschlossen und müssen **verdient** werden. Hinter ihnen liegt nach und nach ein **großes Geheimnis**: warum man hier ist, was das Monster ist, was das Hotel mit den früheren Gästen zu tun hat. Man erfährt es aus **Dokumenten** und von **Mitwissern** – Gästen, die mehr wissen, als sie sagen.

**Fortschritt: Bereiche verdienen statt finden**
- **Offen bleibt der Alltag:** Erdgeschoss, Zimmerflure, Lobby, Bar, Garten, Keller. Gesperrt werden nur die **Geheimnis-Orte** – damit das Spiel eine Sandbox mit Gästen bleibt und kein Schlüssel-Parcours wird.
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
- **Der Heizer – das erste Opfer:** Halloween 1987 kam es im **Tiefkeller** zum Unglück (Kesselbrand). Der Heizer blieb beim Feuer, um andere hinauszubringen. Das Personal schloss die Tür hinter ihm ab – so wurde das Abkommen besiegelt. **Er ist zu dem geworden, was es jetzt verlangt.** Das Personal hält ihn seitdem mit Gästen ruhig und hinter dem Gitter (7.4). Bevor er starb, schrieb er den **ältesten Warnungszettel** (4.13); sein **Kesselbuch** liegt im Heizkeller (7.4).
- **Was das erklärt:**
  - **Deko schützt**, weil sie einmal Teil des Rituals war: Wer schmückt, gilt als *Gastgeber*, nicht als *Gabe*. Und weil sie ihn an das Fest erinnert, das er retten wollte – in geschmückten Bereichen zögert er.
  - **Die Puppe** (5.5) ist die Jury des Abkommens: Sie bestimmt, wer zu wenig schmückt und damit „angeboten“ wird.
  - **Kerzen gehen aus**, wenn er vorbeikommt: das Feuer, das ihn getötet hat.
  - **Das Gitter wird lockerer** (7.4, 4.8): Das Abkommen hält jedes Jahr schlechter.
  - **Der Schlüssel an Halloween** (2.1) öffnet die Tür für **genau einen**. Das Hotel behält immer einen. Fliehen heißt, jemanden zurückzulassen – Opfern (4.11) wird zur Kernfrage.
- **Zwei Arten von Mitwissern:**
  - **Täter, die schweigen:** der **Erbe der Familie**, als uralter Dauergast getarnt, der das Abkommen am Laufen hält; der **Page von 1987**, der die Tür abgeschlossen hat und heute verbittert ist – seine Schuld hält ihn hier, er ist der wahrscheinlichste, der bricht.
  - **Angehörige, die suchen:** die **Tochter des Heizers**, nicht zufällig Gast in diesem Jahr. Sie sucht dasselbe wie der Spieler – Verbündete oder Konkurrentin um den einen Schlüssel.
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
- **Kein Inventar, kein Questmenü:** Dokumente liest man vor Ort (oder steckt sie ein wie Kartenblätter, 3.2). Wichtiges notiert der Spieler-Charakter **im Tagebuch** (8.5) – das Tagebuch wird so zum Notizbuch der Ermittlung.
- **Zeitschleife (2.2):** Die Welt setzt sich zurück, Wissen kann bleiben – über die eigenen Zettel. Codes, Namen und wer lügt, gibt man sich selbst weiter. So wird jeder Durchgang schneller und tiefer, auch wenn man scheitert.

**Zu klären**
- **Mitwisser besetzen:** Sind Erbe, Page und Tochter eigene feste Figuren, oder steckt das in Edna, Bruno, Mila? Namen, Zimmer, wie man sie erkennt.
- **Was ist das Ding unter dem Hotel** vor dem Abkommen gewesen – bleibt das bewusst offen?
- Wie viel erfährt man **vor dem ersten Angriff** (2.1)? Vorschlag: nichts, was den friedlichen Anfang verrät – höchstens das Gästebuch.
- **Was überlebt die Zeitschleife?** Nur die eigenen Zettel (2.2), oder erinnern sich auch Mitwisser an einen?
- **Wie viele Sperrbereiche** für den Anfang? Vorschlag: drei bis vier (siehe Kandidaten oben).
- Wie hängt das Geheimnis mit dem **Schlüssel an Halloween** (2.1) zusammen – ist die Wahrheit Voraussetzung für die Flucht, oder ein eigenes, besseres Ende?

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
| **Ducken** *(Vorschlag)* | Nötig für die Kellertür (siehe 7.2), evtl. leiser |
| **Gegenstände nehmen** | Aufheben per Blick + Taste (RayCast) |
| **Gegenstände benutzen** | Kerze anzünden, Kürbis schnitzen, Pflanze gießen, Deko aufhängen … |
| **Licht & Vorhänge** | Licht ein-/ausschalten, Vorhänge auf-/zuziehen (siehe 7.3) – Licht aus lockt das Monster an |
| **Gegenstände tragen** | Alles wird **sichtbar in den Händen** getragen, einzeln (siehe 3.2) |
| **Ablegen / Werfen** | Gegenstand bewusst abstellen, platzieren oder fallen lassen |
| **Mit Gästen interagieren** | Ansprechen, Dialog, Handel, Geschenke |
| **Mit Gästen spielen** | An einem Spieltisch (Schachbrett, Kartentisch …) eine Partie starten, evtl. um einen Einsatz (siehe 6.10) |

**Spieler-Hitbox:** Kapsel, **1,80 m hoch, 45 cm breit** (Radius 0,225 m). Kamera auf Augenhöhe ca. 1,65–1,70 m.

**Ausdauer (entschieden und umgesetzt 2026-10-19):** Rennen verbraucht Ausdauer – etwa 10 Sekunden am Stück, dann ist
man **außer Atem**. Es gibt **keine Anzeige**: Man merkt es nur am Körper. Geht die Ausdauer zur Neige, hört man schon
leise den eigenen Atem; ist sie leer, werden **Herzschlag und Keuchen** deutlich hörbar und **Rennen geht nicht mehr**,
bis man sich beruhigt hat (im Stehen, Sitzen oder Versteck rund 7 Sekunden, beim Gehen doppelt so lange). Beim
Luftanhalten verstummt das Keuchen. Wer flieht, muss sich also gut überlegen, wann er rennt.
- **Keuchen verrät einen (umgesetzt 2026-10-19):** Lautes Keuchen ist Lärm (4 m, 4.15) – auch aus dem Versteck. Findet
  das Monster einen keuchenden Spieler im Versteck, ist die Chance ×1,8 (höchstens 90 %); der Lakengeist vor dem Schrank
  fliegt mit +25 % eher hinein, wenn er einen keuchen gehört hat (4.18).
- **Außer Atem hält man die Luft kürzer an:** voll erschöpft geht der Atem dreimal so schnell aus, beruhigt wieder
  normal. Wer gerade gerannt ist und sich versteckt, muss also wählen: keuchen oder bald nach Luft schnappen.

### 3.2 Kein Inventar – alles in den Händen
- **Es gibt kein verstecktes Inventar.** Jeder Gegenstand (Deko, Schlüssel, Kerze, Messer, Gießkanne, Puppe …) existiert physisch in der Welt und wird **einzeln in den Händen** getragen.
- **Einzige Ausnahme: Geld.** Geld ist ein reiner Zahlenwert, den der Spieler besitzt (Anzeige z. B. dezent im HUD oder beim Handeln).
- **Folgen für das Gameplay:**
  - Jeder Weg will geplant sein: Erst den Schlüssel holen, Tür öffnen, Schlüssel ablegen, dann den Kürbis tragen …
  - Mit vollen Händen ist man verwundbar: keine Tür öffnen, nichts anderes aufheben, evtl. langsamer bei großen Dingen.
  - Im Notfall muss man Dinge **fallen lassen**, um zu fliehen – und sie liegen dann im Flur (für Gäste zum Klauen, für die Puppe zum Bewerten).
- **Das eigene Zimmer ist das Lager:** Dinge werden auf Tisch, Regal, Bett, Boden abgelegt. Dadurch sind sie auch **sichtbar und klaubar** für unfreundliche Gäste, wenn die Tür offen ist oder sie einen Schlüssel haben.
- **Offen:** Genau ein Gegenstand gleichzeitig – oder zwei Hände (z. B. kleine Dinge je eine Hand, große Dinge wie Kürbis/Puppe beide Hände)?
- **Ausnahme am Körper (entschieden 2026-10-11, im Prototyp umgesetzt):** Drei Dinge trägt man am Körper statt in der Hand – sie sind Werkzeug für Orientierung und Zutritt, keine Beute. Man kann sie nicht ablegen, verlieren, handeln oder gestohlen bekommen.
  - **Kompass** (Zimmer 226): beim Aufheben eingesteckt, **F halten** holt ihn mit der linken Hand hervor.
  - **Karte aus losen Blättern**, ein Blatt je Ebene, **jedes einzeln zu finden** (Erdgeschoss in Zimmer 13, Obergeschoss an der Rezeption, Kellerskizze eines früheren Gastes in Zimmer 17; künftige Ebenen wie Tiefkeller bekommen eigene Blätter). **Tab halten** zeigt sie, das Blatt der aktuellen Ebene liegt oben, **Linksklick / Mausrad** blättert.
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

---

## 4. Das Monster

### 4.1 Grundprinzip
- Das Monster ist **fast immer unsichtbar oder nur angedeutet**: Silhouette am Flurende, Schatten hinter einem Vorhang, Geräusche hinter Wänden.
- Es **zeigt sich zufällig** (gewichteter Zufall, siehe unten) – nicht skriptgesteuert und nicht vorhersehbar.
- **Aussehen** (entschieden 2026-10-11): dürr, mit langen Gliedmaßen, Rippen und Stacheln am Rücken, langgezogenem Schädel, offenem Maul und langer Zunge. Es **geht aufrecht auf den Hinterbeinen** und ist dabei gut zwei Meter groß, gestreckt noch größer. Es kann **auf alle Viere** gehen: zum Schleichen, Lauern und an Verstecken. Unter Türen duckt es sich.
  > Im Prototyp umgesetzt (2026-10-11): Meshy-Modell mit Skelett, Bewegung im Stop-Motion-Stil, Hocke beim Wegschleichen, Lauern und Prüfen von Verstecken.

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
- Evtl. auch **Gewöhnung an konkrete Deko**: Immer derselbe Kürbis an derselben Stelle wirkt schwächer; Abwechslung wirkt besser.

### 4.9 Versteckte Werte: Dreistigkeit & Neugier
Das Verhalten des Monsters wird aus **für den Spieler unsichtbaren Werten** berechnet. Der Spieler soll sie nur indirekt spüren (häufigere Vorwarnungen, Geräusche näher am Zimmer, …).

**Dreistigkeit (global, 0–100)** – *wie viel traut es sich?*
- ↑ mit der Zeit (langsam, stetig)
- ↑ wenn es Gespräche über sich belauscht (4.7)
- ↑ wenn es bemerkt wurde / Sichtungen (4.5)
- ↑ wenn Gäste in Panik sind (6.5)
- ↓ kurzzeitig, wenn es von starker Deko abgewiesen wurde
- ↓↓ **stark, wenn es einen Gast geholt hat → Sättigung** (siehe 4.10)

**Neugier (pro Ort/Zone, 0–100)** – *wohin zieht es?*
- ↑ Dunkelheit in der Zone
- ↑ wenig/schwache Deko (im Verhältnis zum aktuellen Anspruch, 4.8)
- ↑ Sichtung in der Nähe / Spielerzimmer im Suchmodus (4.5)
- ↑ **Puppe wurde dort blockiert oder weggetragen** (5.5)
- ↑ schlechtes Urteil der Puppe (5.5)
- ↑ Lärm
- ↓ langsamer Abbau über Zeit

**Abschreckung (pro Zone)**
```
Abschreckung = (Summe Deko-Stärke × Licht-Faktor) / Anspruch(Zeit)
```

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
| **Die Puppe vor seine Tür tragen** | Die Puppe bewertet seine (schwache) Deko → Monster wird neugierig |
| **Lärm machen** | Wecker / Spieluhr / Radio in seinem Zimmer oder Flur abstellen |
| **Gerüchte & Panik säen** | Mit dem Gast über das Monster reden → er gerät in Panik, macht Lärm, versteckt sich auffällig |
| **Ihn in den Keller / Garten schicken** | Per Dialog oder Auftrag in eine dunkle Gefahrenzone locken |
| **Sein Zimmertelefon klingeln lassen** | Klingeln ist Lärm in seinem Zimmer → Neugier ↑ dort (4.14) |
| **Ihn zum Heizkessel schicken** | Bitten, im Tiefkeller Kohle nachzulegen – nahe am Versteck des Monsters (7.4) |

- **Risiko:** Wird man dabei erwischt (von dem Gast selbst oder anderen), **sinkt der Ruf bei allen** massiv. Das kann zu Diebstahl-Rache führen.
- **Schuld:** Stirbt ein Gast, den man selbst „geopfert“ hat, gibt es eigene Folgen (6.8).
- Das schafft die zentrale moralische Spannung: *Opfere ich jemanden, um selbst Ruhe zu haben?*

### 4.12 Sehen & Jagen (entschieden 2026-10-10)
**Grundsatz: Wer offen im Flur steht, wenn das Monster kommt, ist in Lebensgefahr.** Das Monster muss einen sehen können.

- **Deko schützt nur, wer drinsteht:** Deko (und Licht) bilden einen Schutzbereich um sich herum (Radius, 5.2). Wer **in diesem Bereich steht**, ist sicher – das Monster bricht die Jagd an dessen Rand ab. Wer **hinter** oder **neben** dem Bereich steht, ist **nicht** geschützt: Das Monster darf den Bereich durchqueren, um ihn zu holen. → Zur Deko flüchten rettet einen, sich hinter ihr verstecken nicht.
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
| **Blutspuren** | dass jemand verletzt oder geholt wurde |
| **Geprüfte Verstecke** (offene Schranktür) | dass es gesucht hat |
| **Aufgewühlte Betten** | es war im Zimmer, hat unter/im Bett gesucht |
| **Handabdrücke** (an Zimmertüren, auf der Seite, von der es kam) | es stand direkt vor diesem Raum |
| **Warnungszettel** | jemand (früherer Gast?) will warnen – auch Story-Hinweis |
| **Kleidungsstücke** | von Verschwundenen – Andeutung statt Gore |

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
- Die **ersten beiden Angriffe bleiben harmlos** (2.1) – auch mit F5 gerufen. Erst ab dem dritten holt es jemanden.

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
- **Batterien** sind kleine Gegenstände. Batterie in der Hand + Lampe (oder umgekehrt) → einlegen, wie die Kerze in den Kürbis. Eine Batterie reicht für **einen Ingame-Tag normales Licht** – oder für **etwa 9 Sekunden UV**. Skeptiker handeln damit.
- **Kein Schutzbereich:** Die Lampe zählt nicht als Licht für die Abschreckung (4.9) – sonst wäre sie eine helle Zone zum Mitnehmen.
- **Verrät einen** (4.15): Auffälligkeit normal **+0,9**, UV **+1,2** (Kerze +0,6).
- **Flackert in der Nähe des Monsters** wie die Wandlampen; bei schwacher Batterie wird sie dunkel und unruhig.
- **Im Versteck bleibt sie aus** – sie geht beim Hineinsteigen aus und lässt sich drinnen nicht einschalten.

**UV gegen das Monster**
- Steht es nah genug (≤ 6 m) etwa **1 Sekunde** mitten im UV-Kegel, zuckt es zurück, kreischt und **flieht in den Keller**. Im Kegel wird es langsamer. Auf der Flucht jagt es niemanden.
- **Der Preis:** Es **weiß, wer es war** – Dreistigkeit +6, Neugier rund um Zimmer 13 +40 (wie „bemerkt“, 4.5). Es **ruht danach nur kurz** (Ruhephase ×0,4). Und es **gewöhnt sich daran** (4.8): Jedes weitere Mal muss es 0,5 s länger im Kegel stehen (höchstens 3,5 s) – irgendwann reicht eine Batterie nicht mehr.
- Nicht, wenn es schon zupackt (Jumpscare) oder sich ohnehin zurückzieht.

**UV zeigt Verborgenes**
- **Fußspuren des Monsters** leuchten unter UV noch lange, nachdem sie für das Auge verblasst sind (drei Ingame-Tage).
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
  - **Umsehen:** Es jagt dich trotzdem (4.12). Erwischt es dich, starrt es dich an und verschwindet wie bei den
    harmlosen Angriffen (2.1).
  - **Einen holen:** Du kannst der eine sein.
  - **Raubzug:** Du bist eines der n Opfer.
  - Weil es manchmal täuscht, ist ein kurzes Zucken trotzdem keine Garantie.

**Drumherum**
- **Gäste reagieren:** Bei langem Flackern verstecken sich die Ängstlichen sofort (Edna), Mutige ignorieren das
  kurze Zucken. Ein Raubzug trifft also vor allem die Unvorsichtigen. Gäste sprechen darüber („Wenn es lange
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

**Noch offen:** genaue Tuning-Werte (Täuschungsrate, Angriffschance je Tag, ob die Opferzahl doch einen Deckel
braucht), beim Ausprobieren festlegen.

### 4.18 Der Lakengeist am Fenster (entschieden 2026-10-17)
> **Im Prototyp umgesetzt (2026-10-17):** Erscheinen bei Licht aus und offenem Vorhang (70 % beim Betreten,
> danach 90 s Pause), Stufen 1–4 inklusive Handabdrücken auf der Scheibe, Hypnose (langsamer, Blickzug), Hereinkommen
> (ab dem 4. Mal durch den Vorhang), Würgen mit Losreißen (drei Richtungswechsel in 1,5 s) oder Tod, Zeugen
> (ein wacher Gast mit Sicht) vertreiben ihn, Ausblenden in 0,5 s. Erst nach dem ersten Angriff des Monsters,
> nicht während das Monster nah ist. Debug: F6 und `--ghost=n`.
> **Später am Tag umgesetzt:** **Nachtruhe zu zufälligen Zeiten** (alle 4–9 min für 70–140 s: alle Gäste im
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
> - **Früher, häufiger, schneller (2026-10-18):** Er spukt **ab Tag 2** (oder schon nach dem ersten Angriff, falls
>   früher). Die Licht-aus-Falle bleibt: Wer im dunklen Raum mit offenem Vorhang **bleibt**, für den wird alle **6 s**
>   neu gewürfelt (**25 %**, beim Betreten weiter 70 %). Pause nach einem Besuch **45 s** statt 90 s, er schwebt
>   schneller heran (1,6 statt 1,1 m/s) und kommt schneller herein (1,1 statt 0,8 m/s). Gilt auch für Gäste.
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

**Später auch im Flur** (ab dem **6.–7. Mal**): Wenn **alle Gäste schlafen**, taucht er wahrscheinlicher
**im Flur** auf statt nur vor Fenstern. Dann gibt es keine Zeugen, die ihn vertreiben – der nächtliche Flur wird
zum gefährlichsten Ort.
- **Nachtruhe** (entschieden 2026-10-17): zu **zufälligen Zeiten** gehen alle Gäste schlafen – ins eigene Zimmer,
  Licht aus, ins Bett. Schlafende zählen nicht als Zeugen und bemerken nichts (auch nicht das Monster, das sie
  im Bett finden kann). Danach wachen alle wieder auf.

**Passt zu den bestehenden Systemen**
- **Licht aus** lockt schon das Monster an (4.4) – jetzt auch den Geist. Licht an schützt vor beidem.
- **Vorhang zu** hält den Geist draußen, macht den Raum aber dunkler (weniger Mondlicht).
- **Handabdrücke** gibt es schon an Türen (`Traces`); neu ist die Scheibe als Untergrund.

**Zu klären**
- **Herkunft:** Eigenes Wesen, einer der Verschwundenen (mit jedem geholten Gast häufiger?) oder Teil des
  Monsters? Bisher kennt das Konzept *ein* Monster, und die Geschichte (2.3) hängt daran.
- ~~**Befreien genau:** Wie viel Hin-und-Her reicht?~~ Balken gegen den Griff (2026-10-18). Hilft UV-Licht?
- **Wie viele Zeugen genau:** einer oder zwei? Reicht es, dass sie im Raum sind, oder müssen sie ihn sehen?
- ~~**Gäste:** Kommt er auch zu Gästen, die bei sich das Licht aus und den Vorhang offen haben?~~ Ja, wie zum Spieler (2026-10-18, 6.12).
- **Zähler:** gilt er für das ganze Hotel oder pro Zimmer? Wird er zurückgesetzt?
- **Wechselwirkung mit dem Monster:** Darf der Geist kommen, während das Monster unterwegs ist?

---

## 5. Halloween-Dekoration

### 5.1 Funktion
Deko ist **Schutzmittel und Währung** zugleich.

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

- Mögliche Mechanik: **Verfall/Haltbarkeit** (Kerzen brennen ab, Kürbisse verrotten, Laub wird zertreten), damit Deko nicht einmal platziert und vergessen wird.

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

### 5.5 Die Puppe – „Halloween-Jury“
- Eine **kleine Puppe** wandert versteckt durch das Hotel und **bewertet die Deko** in jeder Zone.
- Sie ist schwer zu entdecken: taucht kurz in Türspalten auf, sitzt plötzlich auf einem Sessel, war gerade noch woanders.
- Ihr Urteil fließt in die **Neugier** des Monsters ein (5.5 → 4.9): Schlecht dekorierte Zonen werden quasi „gemeldet“.
- **Der Spieler kann eingreifen:**
  - **Blockieren** (Tür schließen, Weg verstellen)
  - **Wegtragen** (aufheben wie einen großen Gegenstand, woanders absetzen)
- **Aber:** Jeder Eingriff erhöht die **Neugier des Monsters an genau dieser Stelle** – es will wissen, was dort versteckt wird.
- Dilemma: Puppe sieht schlechte Deko → Monster wird neugierig. Puppe verjagen → Monster wird *auch* neugierig. Beste Lösung: einfach gut dekorieren.

---

## 6. Die anderen Gäste (NPCs)

### 6.0 Gäste im Prototyp
| Gast | Zimmer | Persönlichkeit | Besonderheit |
|------|--------|----------------|--------------|
| **Edna** | 11 | freundlich, sehr ängstlich | Kerzen, versteckt sich beim ersten Flackern |
| **Bruno** | 12 | mürrischer Händler, mutig, gierig | teure Preise, erntet Kürbisse, klaut schnell, wenn er dich nicht mag |
| **Mila** | 15 | junge Künstlerin, gesprächig | erntet und schnitzt Kürbisse, verbreitet Gerüchte am stärksten |
| **zufällige Gäste** | freie Zimmer | einer von sechs Charakteren | siehe unten |

**Zufällig erzeugte Gäste (umgesetzt 2026-10-11):** Neben den drei festen Figuren erzeugt das Spiel zu Beginn weitere Gäste, sodass **30** im Hotel sind. Jeder hat einen Namen, einen Charakter (**ängstlich, geschäftstüchtig, Plaudertasche, Skeptiker, Bastler, Griesgram**) mit passenden Werten (Mut, Gier, Tratsch, Preise, Zuverlässigkeit), eigene Sätze (gemischt mit einem gemeinsamen Grundstock), Vorrat und Start-Deko, Würfelstil mit verräterischer Geste, Kleidungsstück, Farben und Größe.
- **Nie weniger als 24:** Sterben Gäste und sind weniger als 24 am Leben, **wacht nach einigen Minuten ein neuer Gast in einem freien Zimmer auf** – das Hotel ist ja verschlossen. Er weiß nicht, wie er hergekommen ist („Ich bin in Zimmer 27 aufgewacht …“). Man hört eine Tür, in seinem Zimmer geht das Licht an. Zimmer von Verschwundenen bleiben leer.
- Aus einem Seed entsteht immer derselbe Gast; Spielstände speichern nur Seed und Zimmer (`scripts/guests/guest_generator.gd`).

**Gastmodelle (geplant 2026-10-17, erster Grundkörper „Mann“ eingebaut 2026-10-17):** Die Klötzchen-Gäste werden durch Meshy-Modelle ersetzt – keine Einzelmodelle, sondern **eigene Modelle für Edna, Bruno und Mila** und **6–8 Grundkörper** (Frau/Mann × jung/mittel/alt, evtl. weitere Statur) für die erzeugten Gäste. Jeder Grundkörper ist eine ganze Figur mit eigenem Kopf; alle haben denselben Knochenaufbau (Meshy-Auto-Rigging mit Skelettvorlage Mixamo), Animationen gibt es deshalb nur einmal. Der Grundkörper folgt aus Geschlecht und Generation des Namens und wird reihum statt zufällig verteilt, damit sich keiner häuft.
- **Variiert wird:** Körpergröße **150–185 cm** (selten über 190), Breite **35–50 cm**, Körperbau (schlank bis kräftig), Kleidungs- und Haarfarbe (Einfärben über Masken). Das Kleidungsstück („Lottes Hut“) wird, wo es geht, als echtes Teil am Körper sichtbar.
- **Vorerst nicht:** getrennte Frisuren, andere Kleidungsschnitte, Augenfarbe.
- Modelle in Meshy: A-Pose, Kleidung und Haare entsättigt hell- bzw. mittelgrau (Ober- und Unterteil verschieden), keine Muster, keine Accessoires, Haare nicht auf den Schultern, keine eingebrannten Schatten.

### 6.1 Rolle
- Leben ebenfalls im Hotel, haben eigene Zimmer, eigene Deko, eigene Persönlichkeit.
- Sind **Handelspartner, potenzielle Freunde – und potenzielle Gegner**.

### 6.2 Beziehungssystem
- Jeder Gast hat einen **Beziehungswert** zum Spieler (z. B. -100 … +100).
- **Positiv** beeinflusst durch: nette Dialogoptionen, Geschenke, Gefallen, faire Trades, Hilfe bei Monster-Ereignissen.
- **Negativ** beeinflusst durch: unhöfliche Antworten, Deko-Diebstahl, schlechte Trades, „blöde Aktionen“ (z. B. Lärm vor deren Tür, Monster anlocken).
- Optional: **Ruf / Gerüchte** – Gäste reden miteinander, schlechtes Verhalten spricht sich herum.

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

- **Langsamer nach oben:** Je besser man schon steht, desto weniger bringt jede nette Tat (bei 50 gut die Hälfte). Plaudern zählt pro Tag nur zweimal voll, danach kaum noch.
- **Die Extreme brauchen Taten, nicht nur Punkte:**
  - **Guter Freund:** mindestens 3 gemeinsame Partien (Mäxchen oder Schach), 2 Geschenke an ihn **und** 1 Gegenstand von ihm (Deko geschenkt bekommen oder gekauft) – Austausch in beide Richtungen. Bis dahin bleibt er bei „befreundet“ stehen.
  - **Stark verfeindet:** mindestens 4 feindselige Taten von dir (Deko klauen, beleidigen, rammen, schlagen) **und** er hat sich mindestens einmal gerächt (dich bestohlen, angerempelt oder geschlagen). Bis dahin bleibt er bei „verfeindet“.
- **Zerfall:** Oberhalb von „befreundet“ und unterhalb von „verfeindet“ wandert der Wert ohne Kontakt langsam zurück (gut 1 Punkt pro Tag).
- **Rammen:** Rennst du in einen Gast, stolpert er – Beziehung ↓, Zeugen merken es. Wütende Gäste rempeln dich ihrerseits im Vorbeigehen an (du wirst weggeschubst).
- **Schlagen (Linksklick auf einen Gast in Armlänge, ohne Taschenlampe in der Hand):** Beim ersten Mal fragt das Spiel nach („Wirklich zuschlagen?“ – zweiter Klick). Der Gast fällt sofort auf höchstens „wütend“, Zeugen mögen dich weniger, es spricht sich herum, Schläge machen Lärm (Neugier des Monsters). Ängstliche Gäste fliehen, mutige oder stolze schlagen zurück. Ein geschlagener Gast ist eine Weile langsamer.
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
- Ein Gast in **Panik**: rennt umher, schließt sich ein, handelt nicht, macht Lärm, plündert evtl. Deko anderer, um sich selbst zu schützen.
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
- **Tagesablauf:** Essen im Speisesaal, im Zimmer sein, Garten, Lobby → der Spieler kann Gewohnheiten lernen (wann ist welches Zimmer leer?).
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

### 6.9 Dialog
- Einfaches Dialogsystem mit Antwortoptionen (nett / neutral / unhöflich).
- Umsetzung in Godot z. B. über eigene Ressourcen oder ein Dialog-Plugin (z. B. Dialogue Manager).

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
- **Leichen** gibt es nur vom **Lakengeist**: Ein erwürgter Gast bleibt liegen, wo er starb.
- Der **Lakengeist** selbst – am eigenen Fenster oder als Zeuge, wenn er zu jemand anderem kommt.
- Jeder Fund erschreckt einen Gast **nur einmal**. Schlafende und Versteckte sehen nichts.

**Die Reaktion** – der Gast bleibt **2–5 Sekunden** stehen (je mutiger, desto kürzer) und starrt hin. Wie, liegt
fest am Charakter, nicht am Zufall:

| Reaktion | Wer | Danach |
|----------|-----|--------|
| **Hände hoch** (zitternd, weicht zurück) | ängstlich, geschäftstüchtig, Edna | rennt weg und versteckt sich |
| **Starr vor Schreck** (Hand vor dem Mund) | Skeptiker, Griesgram, Bruno | macht weiter |
| **Weinen** (zusammengesunken, Hände vorm Gesicht) | Plaudertasche, Bastler, Mila | geht weinend ins Zimmer |

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
- Zimmer ohne Außenfenster (z. B. Milas Zimmer 15) sind sicher.

**Noch offen:** Werden Leichen irgendwann weggebracht (von Gästen, vom Monster)? Trauer der Gäste um Freunde (6.8)?

## 7. Spielwelt: Das Hotel

- **Bereiche (Vorschlag):** Lobby, Flure mehrerer Etagen, Gästezimmer, Speisesaal/Küche, Wäscherei, Keller, Treppenhaus, **Hotelgarten** (Kürbisbeete, Laubbäume, umzäunt), **Bibliothek / Salon** (Schachbrett, Kamin, Billard), **Hotelbar** (Würfel, Darts).
- **Spinnenweben-Zonen:** verlassene Zimmer, Keller, Dachboden – dunkel und gefährlich.
- **Im Prototyp umgesetzt (2026-10-10, Hotel vergrößert 2026-10-11):**
  - **Lobby** (West, 14 × 14 m, Decke 5 m): Rezeption, Sofas, Säulen, Plattenspieler, Ausgangs-Doppeltür (verriegelt)
  - **Küche** (südlich der Lobby): Messer, Kerzenvorrat
  - **Hotelgarten** hinter einer **Glastür** (plus Fenster in der Lobby-Nordwand): Kürbisbeete, Bäume mit Laubhaufen, Hecken, Laternen, Mondlicht
  - **Erdgeschoss:** Hauptflur (78 m nach Osten) mit **drei Flurkreuzungen** – A und B mit langen Nord- und Südflügeln, C mit kurzen Flügeln – **44 Zimmer**
  - **Obergeschoss** (4 m höher) über ein **Treppenhaus** mit Wendepodest am Ende des Nordflügels: Hauptflur mit zwei Kreuzungen, **30 Zimmer** (211–244), zwei davon verfallen (Tür offen, Spinnweben). Zusammen **74 Zimmer** für rund 30 Gäste
  - Zimmer 11 (Edna), 13 (Spieler), 15 (Mila), 17 (verlassen, dunkel), 12 (Bruno), 14 (leer), 16 (Wäscherei, dunkel, Spinnweben), 18 (abgeschlossen); alle übrigen sind zu Beginn mit Zufallsgästen belegt oder **unbewohnt** – eingerichtet, Licht aus, hier und da eine Kerze oder Münzen. Zimmer, hinter deren Rückwand ein Flügel liegt, haben kein Außenfenster.
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
- **Wann wird gefeiert?** Feiern entstehen **spontan durch die Gäste**, z. B. wenn:
  - die Stimmung gut ist (wenig Panik, Monster lange nicht gesehen / gesättigt),
  - ein Gast etwas zu feiern hat (guter Handel, große Kürbisernte),
  - nach einem Todesfall als Trauerfeier / „Jetzt erst recht“.
  - Ein Gast lädt ein → es spricht sich herum → Gäste kommen je nach Laune und Beziehung zum Gastgeber.
- **Der Spieler kann selbst eine Feier ausrichten:**
  - Gäste persönlich einladen (Dialog) – ob sie kommen, hängt von der Beziehung ab.
  - **Tänze** (umgesetzt 2026-10-14): Gäste tanzen verschieden – hüpfen, wiegen, drehen, Arme hoch, Twist,
    schunkeln. Jeder hat einen Lieblingstanz und wechselt ab und zu.
    > 2026-10-18: Gäste mit Modell tanzen echte Tanzanimationen (Mixamo): Chicken Dance, Macarena, Hip-Hop –
    > ein Download gilt für alle Grundkörper. Die Code-Tänze bleiben für die Klötzchenfiguren.
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

> ⚠ **Kellertür und Spieler sind beide genau 1,80 m hoch.** Die Kapsel würde stecken bleiben. Optionen: Ducken nötig (passt atmosphärisch: man muss sich in den Keller *bücken*), Kellertür leicht erhöhen (z. B. 1,85 m) oder Hitbox minimal kleiner als 1,80 m.

- **Blender:** Maßeinheit Meter, 1 Blender-Einheit = 1 m = 1 Godot-Einheit. Modulares Kit z. B. im 1-m- oder 2-m-Raster, Wandhöhe 3,5 m als Standard.
- **Eigenes Zimmer:** sicherer Rückzugsort, Lager für Deko, **einziger Speicherpunkt** (Tagebuch auf dem Schreibtisch, siehe 8.5).
- **Atmosphäre:** lange Flure (ideal für Silhouetten am Ende), schwaches Licht, alte Tapeten, knarrende Böden.
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
- **Ein Lichtschalter pro Raum** (entschieden): schaltet alle Wandlampen des Raums bzw. Flurabschnitts gemeinsam ein und aus. Die Deko-Kerzen brennen immer.
- **Licht aus = das Monster kommt** (4.4). Ausschalten ist also eine bewusste Entscheidung – z. B. um nicht gesehen zu werden – mit hohem Preis.
- **Flackern trotzdem:** Eingeschaltete Lampen flackern weiterhin, wenn das Monster sich ankündigt (4.2). Kaputte Lampen bleiben kaputt, egal wie der Schalter steht.
- **Glühbirnen herausdrehen & mitnehmen** (entschieden): Jede Lampe hat eine Glühbirne, die man herausdrehen kann. Die Birne ist ein **normaler Gegenstand** (3.2): klein, einhändig, zerbrechlich (Vorschlag: fällt sie herunter, zerspringt sie).
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
> Noch nicht umgesetzt. Der bestehende Keller (Versteck des Monsters) bleibt über die Kellertreppe erreichbar; der **Tiefkeller** liegt noch tiefer und ist **nur mit dem Fahrstuhl** erreichbar.

**Grundidee:** Neben der Rezeption in der Lobby steht ein alter Gitterfahrstuhl mit dem Schild „Außer Betrieb“. Man kann ihn im Lauf des Oktobers **reparieren** und damit den **Tiefkeller** mit **Heizkeller** und **Lager** freischalten. Die Reparatur ist die erste größere Aufgabe des Spiels: Sie führt einmal durch das ganze Hotel und verlangt jedes Mal eine andere Art von Mut.

**Vor der Reparatur – Atmosphäre**
- Die **Stockwerksanzeige** über der Tür bewegt sich trotzdem manchmal. Niemand weiß, warum. Der Spieler lernt: Wenn die Anzeige wandert, ist etwas unterwegs.
- Aus dem Schacht hört man gelegentlich Kratzen. **Das Monster klettert im Schacht** – an den Schachttüren tauchen später Handabdrücke auf (neue Spur, 4.13).

**Die Reparatur – drei Teile, drei Gefahren**
Hinweise liefert das **Notizbuch des Hausmeisters**, kein Questmenü. Was man schon erledigt hat, notiert der Spieler-Charakter auf einer eigenen Seite im **Tagebuch** (8.5), handschriftlich und abgehakt.

| Schritt | Wo | Gefahr / Mechanik |
|---------|----|-------------------|
| **1. Notizbuch & Schaltschlüssel** | **Zimmer 18** (abgeschlossen; der Schlüssel liegt schon heute im Keller) | Ausflug ins Monster-Versteck – am besten während einer Ruhephase, wenn es woanders schläft, oder in der Sättigung (4.10). Im Zimmer: Notizbuch mit den drei Mängeln und der **Schaltschlüssel** für die Kabine. |
| **2. Hauptsicherung** | Ein **Gast** hat die Ersatzsicherung (er hat sie dem Hausmeister „abgekauft“) | **Sozial:** Freundschaft, Handel, Mäxchen-Einsatz – oder Klauen mit allen Folgen (6.2). Gerüchte verraten, wer sie hat; nicht immer der Richtige. Eingesetzt wird sie am Sicherungskasten **im Keller** – noch ein Ausflug dorthin. |
| **3. Bremse lösen** | **Maschinenraum** am Ende des Obergeschosses (über dem Schacht) | **Lärm:** Die Bremse wird mit einer Kurbel gelöst – E gedrückt halten, ca. 20 Sekunden, laut und quietschend (Neugier ↑ im Obergeschoss). Loslassen unterbricht, der Fortschritt bleibt. Man steht dabei mit dem Rücken zur Tür. |

- **Tempo:** Realistisch in der zweiten Oktoberwoche, wenn das Monster schon gefährlich ist. Wer früh mutig ist, schafft es eher.
- **Belohnung beim ersten Start:** Das Licht in der Kabine geht an, ein „Ding“ – und die Anzeige springt ohne Zutun auf **„T“ (Tiefkeller)**. Die Kabine war schon unten.

**Den Fahrstuhl benutzen**
- **Halte:** Tiefkeller · Erdgeschoss (Lobby) · Obergeschoss. Eine Abkürzung zum Obergeschoss, ohne durch den Nordflügel und das Treppenhaus zu müssen.
- **Lärm:** Motor und Glocke sind an **Abfahrt und Ziel** zu hören → Neugier ↑ an beiden Orten.
- **Falle:** Die Kabine ist eng, es gibt kein Versteck. Steht das Monster an der Zielhalte, öffnet sich die Tür trotzdem. Das Rauschen hört man schon während der Fahrt – mit dem **Nothalt** bleibt man zwischen zwei Etagen stehen. Sicher? Bis es oben auf dem Kabinendach kratzt.
- **Die Anzeige verrät, wo die Kabine ist.** Fährt sie ohne einen selbst, benutzt sie jemand: ein Gast (nach der Reparatur nutzen auch Gäste den Fahrstuhl) – oder niemand.
- **Notruftelefon** in der Kabine (4.14): Man kann die Rezeption anrufen. Manchmal klingelt es, wenn niemand darin ist.

**Heizkeller**
- Großer, verrußter Raum mit einem **alten Kohlekessel**, Kohlenbunker, Rohren an der Decke und einer Werkzeugwand.
- **Anheizen:** Kohle ist ein **großer Gegenstand** (beidhändig, 3.2) und muss vom Bunker zum Kessel getragen werden; angezündet wird mit einer Kerze. Schaufeln ist laut.
- **Solange der Kessel brennt:**
  - Das ganze Hotel wird warm → Stimmung der Gäste ↑, Panik klingt schneller ab, Schock und Trauer (6.8) lassen schneller nach.
  - Die Glut taucht den Heizkeller in rotes Licht → er ist hell und damit relativ sicher (4.4). Geht das Feuer aus, wird er stockdunkel.
  - **Die Rohre klopfen und zischen im ganzen Hotel.** Das überdeckt eigenen Lärm (Rennen, Würfeln locken weniger) – aber auch Rauschen und Schritte des Monsters sind schwerer zu hören. Ein Tausch, kein reiner Vorteil.
- **Nachlegen:** Eine Ladung brennt etwa einen Ingame-Tag. Danach muss jemand wieder hinunter – der Spieler selbst oder ein Gast, den man darum bittet (Beziehung; moralisch heikel, 4.11).
- **Ofenklappe:** Hier lassen sich Dinge **verbrennen**: geklaute Gegenstände, blutige Kleidung, belastende Zettel. Ohne Beweis verlieren Gerüchte über einen an Kraft (6.2). Deko verbrennen geht nicht – das Feuer „will“ sie nicht.
- **Das Gitter:** Zwischen Heizkeller und dem alten Keller (Versteck des Monsters) liegt ein rostiges **Gitter**. Anfangs kommt das Monster nicht hindurch; man hört es dahinter atmen, wenn es ruht – wer dann Kohle schaufelt, weckt es. **Mit jedem Tag wird das Gitter lockerer** (4.8), gegen Ende des Monats ist es offen und der Tiefkeller gehört zu seinem Revier.
- **Story:** das **Kesselbuch des Heizers** von 1987 – derselbe Name wie auf dem ältesten Warnungszettel.

**Lager**
- Ein Verschlag aus Maschendraht mit Vorhängeschloss. Den **Bolzenschneider** findet man an der Werkzeugwand im Heizkeller – eine kleine Aufgabe innerhalb des Tiefkellers.
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
- Später weitere Halte (Dachboden über dem Obergeschoss)?
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
- **Größe:** ca. 151 × 130 m, **129 Zimmer** im Erdgeschoss: Ostflügel und Westflügel mit je einem
  Rundflur um zwei Innenhöfe, dazwischen ein großer Garten, im Süden die Lobby mit Bar + Spiele, Partyraum
  und Toiletten, im Westen Küche, Speisesaal, Lager und Kühlräume, im Norden der Indoor-Pool.
- **Bauphasen:** zuerst **Lobby, Mittelgarten und Ostflügel**, der Westflügel später.
- **Zimmernummern (vierstellig):** Stockwerk · Flügel · Zimmer. Erdgeschoss 0, erstes Obergeschoss 1;
  Ostflügel x1xx, Westflügel x2xx. Gezählt wird nach Laufweg: ab der Lobby einmal um den Rundflur, danach der
  Querflur zwischen den Höfen; **in Laufrichtung rechts ungerade, links gerade**. Erdgeschoss: Ost 0101–0181,
  West 0201–0272; Zimmer darüber tragen dieselbe Nummer mit 1 vorne.
- **Spielerzimmer ist 0113:** An der Tür ist das Schild abgebrochen, zu lesen ist nur noch **„13“**. Gäste
  sprechen von „Zimmer 13“.
- **Lobby mit Galerie:** Über Rezeption und Eingang ist die Lobby doppelt hoch (Luftraum ca. 7,4 × 20 m).
  Das Obergeschoss umschließt ihn als Galerie mit Geländer, von der man in die Halle hinunterschaut. Die
  Treppe links hinter der Rezeption führt hinauf; daneben zwei Aufzüge.
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
| Autosave | **Bei wichtigen Ereignissen**, nur in sicheren Momenten |
| Nach dem Tod | **Letzten Spielstand laden** (oder Hauptmenü) |
| Esc-Menü | **Spiel pausiert komplett**; Esc schließt zuerst ein offenes Fenster |
| Tagebuch-Ansicht | **Pausiert** ebenfalls |
| Beenden | **Kein automatisches Speichern**, nur Rückfrage |
| Titelbildschirm | **Ja**, beim Spielstart |

### 8.2 Titelbildschirm (Hauptmenü)
- Erscheint beim Start des Spiels, vor dem Intro.
- **Hintergrund (Vorschlag):** Die verriegelte Lobby-Doppeltür oder ein langer Flur im PS1-Look – Nebel, eine flackernde Lampe, leichtes Bildrauschen. Ab und zu steht am Flurende eine Silhouette … und beim nächsten Flackern ist sie weg.
- **Einträge:**
  - **Fortsetzen** – lädt den neuesten Spielstand (Slot oder Autosave). Nur sichtbar, wenn einer existiert.
  - **Neues Spiel** – Slot wählen; ist er belegt → Rückfrage „Überschreiben?“. Danach Intro-Text, Start in Zimmer 13.
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
  - **Steuerung** (Tastenübersicht)
  - **Zum Hauptmenü** – mit Rückfrage und Hinweis „Zuletzt gespeichert vor 12 Minuten – ungespeicherter Fortschritt geht verloren.“
  - **Spiel beenden** – gleiche Rückfrage. Es wird **nicht** automatisch gespeichert (sonst ließe sich die Regel „nur im Zimmer speichern“ umgehen).
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
| **Bild** | **Helligkeit/Gamma mit Kalibrierbild** („Der Kürbis soll gerade noch erkennbar sein“) – wichtig, weil Dunkelheit Spielmechanik ist (4.4) · Vollbild/Fenster (Start immer im Fenster, 11.10.2026) · VSync · Sichtfeld (FOV) |
| **PS1-Look** | Hauptschalter an/aus · Interne Auflösung · Vertex-Wackeln an/aus · Dithering an/aus |
| **Ton** | Gesamt · Musik · Effekte · Stimmen |
| **Steuerung** | Mausempfindlichkeit · Y-Achse invertieren · Ducken halten/umschalten · später Tastenbelegung |
| **Barrierefreiheit** | **Flacker- und Rausch-Intensität reduzieren** (Fotosensibilität – Warnhinweis beim ersten Start) · Untertitel für wichtige Geräusche („Schritte hinter der Wand“) |

### 8.5 Speichern am Tagebuch
- Auf dem Schreibtisch in Zimmer 13 liegt das **Tagebuch** des Spielers. **E** → Blick aufs Tagebuch → **Slot 1–3 wählen** → ein Eintrag wird geschrieben = gespeichert. Solange die Tagebuch-Ansicht offen ist, **pausiert das Spiel** (wie im Menü).
- **Gesperrt während Vorwarnung/Manifestation:** Das Tagebuch lässt sich nicht beschreiben – *„Meine Hände zittern zu sehr.“* Alle anderen Situationen sind erlaubt (auch bei offener Tür oder mit einem Gegenstand in der Hand – der wird einfach mitgespeichert).
- **Der Eintrag als Slot-Beschreibung:** Das Spiel formuliert automatisch einen kurzen Tagebuchsatz aus dem aktuellen Stand, z. B. *„Edna ist fort. Bruno redet nicht mehr mit mir. Vor meiner Tür brennen zwei Kürbisse.“* Dieser Satz erscheint in der Slot-Übersicht.
- **Slot-Übersicht zeigt:** Vorschaubild (480 × 270, passt zum PS1-Look), Tagebuchsatz, Spielzeit, Datum/Uhrzeit, lebende Gäste.
- Das Tagebuch ist **fest verankert** (nicht tragbar, nicht klaubar) – sonst könnte man sich das Speichern verbauen.

### 8.6 Autosave
- **Ein eigener Slot**, der sich selbst überschreibt. Kann nur geladen, nicht manuell beschrieben werden.
- **Auslöser (wichtige Ereignisse):**
  - Tod eines Gastes (sobald die Gefahr vorbei ist)
  - Ende einer Feier
  - Fortschritt beim Fluchtweg (Schlüssel gefunden, Rätsel gelöst)
  - Erstes Betreten eines neuen Bereichs (Vorschlag)
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
Weil es **kein Inventar** gibt (3.2), *ist die Welt der Spielstand*: Jeder Gegenstand muss mit Ort und Zustand gespeichert werden.

| Bereich | Inhalt |
|---------|--------|
| **Spieler** | Position, Blickrichtung, geduckt, Gegenstand in der Hand, Geld, Schock/Trauer/Schuld (6.8) |
| **Gegenstände** | Typ (inkl. Glühbirnen), Position/Rotation, Zustand (geschnitzt, Kerze drin, Brenndauer, Verfall), Ort (Boden, Truhe, Hand eines Gastes) |
| **Welt** | Türen (offen/zu/abgeschlossen), Truhen-Inhalte, Lampen (intakt/kaputt, Birne drin/fehlt), Lichtschalter je Raum (an/aus), Vorhänge (offen/zu), Kürbisbeete (Stufe, Wachstum), Laub-/Spinnweben-Vorräte, Plattenspieler, Kommoden (Schubladen offen/zu, schon durchsucht) |
| **Gäste** | lebt/tot, Position, aktuelle Tätigkeit im Tagesablauf, Beziehung, Panik, Wissen/Gerüchte, Diebstahl-Erinnerungen, Wettschulden, getragener Gegenstand |
| **Monster** | Position auf der Route, Dreistigkeit, Neugier je Zone, Sättigung, Deko-Anspruch und -Gewöhnung (4.8–4.10) |
| **Puppe** | Position, bisherige Urteile |
| **Ablauf** | Spielzeit, laufende Feier, Fortschritt Fluchtweg, Story-Flags, Tagebuchtexte |
| **Nicht** | Einstellungen (eigene Datei), laufende Minispiel-Partien von Gästen (starten nach dem Laden neu) |

### 8.9 Ausbau-Ideen (später)
- **Gäste lesen das Tagebuch:** Kommt ein Gast in Zimmer 13 (offene Tür, Schlüssel, Feier), kann er das Tagebuch lesen und so erfahren, wen man bestohlen oder dem Monster „geopfert“ hat (4.11, 6.2) → Abschließen lohnt sich doppelt. Das Tagebuch bleibt dabei fest im Zimmer.
- **„Albtraum-Modus“:** ein einziger Slot, der Tod löscht ihn.

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
- **Stil: Low-Poly im PS1-Look** – wenige Polygone, kleine Texturen (64–256 px), Nearest-Filter, keine glatten Normalen nötig
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
2. ~~Zeitstruktur~~ → **durchgängig**, keine Level; Ingame-Tage à ca. 5 min vom 1. Oktober bis Halloween, draußen immer Nacht (2.1, entschieden).
3. ~~Monster-Kontakt~~ → Jumpscare + Sterbebildschirm, danach letzten Spielstand laden (entschieden, siehe 8).
3a. **„Bemerkt“-Auslöser:** Reicht Hinschauen, oder muss der Spieler sichtbar reagieren?
3b. ~~Spieler-Lichtquelle~~ → **Taschenlampe**, verrät die eigene Position, schützt nicht; mit UV-Aufsatz (späterer Fund) kurz vertreiben, kostet Batterien und macht es dreister (4.16, entschieden 2026-10-11).
3c. **Garten-Zeit:** Wie lange wächst ein Kürbis – Minuten Echtzeit oder Ingame-Tage?
3d. **Kellertür vs. Hitbox:** Ducken, Tür erhöhen oder Hitbox verkleinern?
3e. **Puppe:** Kann sie auch Deko verändern/umwerfen, oder nur beobachten? Kann der Spieler ihr Urteil irgendwie sehen?
3g. ~~Verstecke~~ → Zeitlimit wie in Doors, beim Hineingehen gesehen = Tod, Gäste können sterben (entschieden).
3i. **Schock-Malus:** Welche Mali aus 6.9? Wie stark, wie lange?
3j. ~~Feiern~~ → spontan durch Gäste, Spieler kann auch eine ausrichten (entschieden).
3k. **Minispiele (6.10):** Welche Spiele für den ersten Umfang? Echte Schachregeln (aufwendiger) oder zuerst ein einfaches Würfel-/Kartenspiel? Welche Möbel dürfen als Einsatz dienen?
3h. **Truhen:** Abschließbar? Gibt es eine eigene Truhe im Spielerzimmer?
3f. ~~Tragen~~ → kein Inventar, alles in den Händen, nur Geld als Wert (entschieden); Ausnahme am Körper: Kompass, Kartenblätter, Schlüsselbund (3.2, entschieden 2026-10-11). Offen: ein oder zwei Hände?
4. ~~Story~~ → **Das Abkommen und der Heizer** (2.3, entschieden 2026-10-11). Offen: Mitwisser besetzen, was das Ding vor 1987 war.
5. **Anzahl & Tiefe der Gäste:** Wenige tiefe Charaktere (3–5) oder viele einfache?
6. **Können Gäste sterben / verschwinden?** (starke emotionale Konsequenz)
7. ~~Grafikstil~~ → **Low-Poly im PS1-Look** (entschieden).
8. **Umfang:** Kleines Halloween-Projekt (Jam-Größe) oder größeres Spiel?
9. **Single-Player** – oder später Koop denkbar?
10. **Sprache:** Deutsch, Englisch, beides?

---

## 11. Nächste Schritte

1. ~~Offene Fragen klären~~ ✔
2. ~~Godot-Projekt anlegen~~ ✔
3. ~~Vertical Slice~~ ✔ (2026-10-10)
4. ~~Ausbau~~ ✔ (2026-10-10): feste Patrouillenroute · Lobby, Küche, Garten mit Glastür, 8 Zimmer, Wäscherei · Kürbisbeet, Laub, Spinnweben, Kerzenvorrat · Schnitzen + Kerze einsetzen · 3 Gäste mit Tagesablauf, Dialog, Handel, Beziehung, Geschenken, Klauen (beidseitig), Zeugen & Gerüchten, Panik, Verstecken, Tod, Sättigung, Schock/Schuld, Gedenken · Feiern (spontan + selbst ausgerichtet)
5. Minispiele mit Gästen (6.10): ~~Mäxchen an der Hotelbar~~ ✔ · als Nächstes Kürbis-Schnitz-Duell, Möbel-Einsätze, Bibliothek/Salon mit Schach
6. Puppe („Halloween-Jury“) inkl. Deko-Wettbewerb bei Feiern
7. Fluchtweg aus dem Hotel (Ausgangsschlüssel / Rätsel / Hilfe der Gäste) · Scheitern als Zeitschleife mit eigenen Zetteln (2.2) · Fortschritt & Geheimnis: Sperrbereiche, Dokumente, Mitwisser (2.3)
7a. Fahrstuhl reparieren, Tiefkeller mit Heizkeller und Lager (7.4) · ~~Zimmertelefone (4.14)~~ ✔ (2026-10-11)
7b. ~~Lärm & Sichtbarkeit als ein gemeinsames System (4.15)~~ ✔ (2026-10-11)
7c. ~~Taschenlampe mit Batterien und UV-Aufsatz (4.16)~~ ✔ (2026-10-11)
7d. Gäste bedienen Lichtschalter aktiv: Licht an im Dunkeln, beim Verlassen leerer Zimmer aus, manchmal vergessen (7.3, vorgemerkt 2026-10-13)
7e. ~~Angriffe zu kurz – das Monster kehrt nach wenigen Metern um~~ ✔ (4.13, behoben 2026-10-17)
7f. ~~Hotelkatzen: frei laufend, streicheln, Lieblingsgäste, vom Monster verschont, fliehen und weinen in seiner Nähe, werfen Deko um, bringen selten Deko und schlafen auf deinem Bett (6.11)~~ ✔ (2026-10-17)
7g. ~~Angriffsabsicht & Flacker-Signal: Eine Flackerwelle vom Keller aus verrät mit ihrer Dauer, ob es sich umsieht, einen holt oder auf Raubzug geht (n Opfer ∝ 1/n², Flackern 1 + 2 × n s, Spieler zählt mit, täuscht manchmal) (4.17)~~ ✔ (2026-10-17)
7h. ~~Lakengeist am Fenster: kommt bei Licht aus und offenem Vorhang, wird von Mal zu Mal dreister (Handabdrücke auf der Scheibe, Hypnose, kommt herein und würgt), verschwindet vor Zeugen in 0,5 s, ab dem 6. Mal im Flur, wenn alle schlafen (Nachtruhe zu zufälligen Zeiten) (4.18)~~ ✔ (2026-10-17)
7i. ~~Lakengeist hartnäckiger: Losreißen kaum noch möglich, wartet vor dem Schrank und fliegt hinein, Schlafen im eigenen Bett, Schlafmangel lockt ihn – nach drei Nächten sicher im Flur (4.18)~~ ✔ (2026-10-18)
7j. ~~Schach in der Lobby: Schachtisch und Brett, KI-Gegner mit Spielstärke je Gast, Einsätze, Herausforderungen, Gäste spielen untereinander (6.10)~~ ✔ (2026-10-18)
8. Echte Modelle aus Blender (glTF) statt Platzhalter, echte Sounds
9. ~~Titelbildschirm, Spielmenü (Esc), Einstellungen, Speichern/Laden~~ ✔ (2026-10-10, siehe 8) · ~~Fenster, Vorhänge, Wandlampen, Lichtschalter, Glühbirnen~~ ✔ (7.3) · ~~Sehen & Jagen~~ ✔ (4.12)
10. Balancing, weitere Etagen
11. Zerbrechende Fenster (7.3, für später vorgemerkt)
