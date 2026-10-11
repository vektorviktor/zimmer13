# Spielkonzept – Arbeitstitel: „Zimmer 13“

> Status: Grobkonzept · Stand: 2026-10-11
> Engine: **Godot 4.7** · 3D-Assets: **Blender (lokal)**

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

**Ideen für das Scheitern (Auswahl offen)**
- **Zeitschleife:** Nach Halloween beginnt alles wieder am 1. Oktober – nur schlimmer.
- **Das Hotel behält einen:** schlechtes Ende.

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
| **Laufen** | Gehen, evtl. Rennen (macht Lärm) |
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

### 3.2 Kein Inventar – alles in den Händen
- **Es gibt kein verstecktes Inventar.** Jeder Gegenstand (Deko, Schlüssel, Kerze, Messer, Gießkanne, Puppe …) existiert physisch in der Welt und wird **einzeln in den Händen** getragen.
- **Einzige Ausnahme: Geld.** Geld ist ein reiner Zahlenwert, den der Spieler besitzt (Anzeige z. B. dezent im HUD oder beim Handeln).
- **Folgen für das Gameplay:**
  - Jeder Weg will geplant sein: Erst den Schlüssel holen, Tür öffnen, Schlüssel ablegen, dann den Kürbis tragen …
  - Mit vollen Händen ist man verwundbar: keine Tür öffnen, nichts anderes aufheben, evtl. langsamer bei großen Dingen.
  - Im Notfall muss man Dinge **fallen lassen**, um zu fliehen – und sie liegen dann im Flur (für Gäste zum Klauen, für die Puppe zum Bewerten).
- **Das eigene Zimmer ist das Lager:** Dinge werden auf Tisch, Regal, Bett, Boden abgelegt. Dadurch sind sie auch **sichtbar und klaubar** für unfreundliche Gäste, wenn die Tür offen ist oder sie einen Schlüssel haben.
- **Offen:** Genau ein Gegenstand gleichzeitig – oder zwei Hände (z. B. kleine Dinge je eine Hand, große Dinge wie Kürbis/Puppe beide Hände)?

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

---

## 4. Das Monster

### 4.1 Grundprinzip
- Das Monster ist **fast immer unsichtbar oder nur angedeutet**: Silhouette am Flurende, Schatten hinter Milchglas, Geräusche hinter Wänden.
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
| **Handabdrücke** (z. B. auf dem Milchglas) | es stand direkt vor diesem Raum |
| **Warnungszettel** | jemand (früherer Gast?) will warnen – auch Story-Hinweis |
| **Kleidungsstücke** | von Verschwundenen – Andeutung statt Gore |

- **Klopfen an der Tür – mit Geschrei** (entschieden), in zwei Varianten:
  - **Meistens der echte Gast:** Er klopft panisch und schreit „Mach auf!“, weil das Monster hinter ihm ist. Öffnet man nicht, hört man einen Schrei – danach ist es still.
  - **Manchmal nicht:** Es klopft, man hört eine bekannte Stimme. Öffnet man, ist niemand da – nur ein Kleidungsstück auf dem Boden.
- **Warnungszettel** stammen von **früheren Gästen**, die es nicht hinausgeschafft haben. Sie liegen in verlassenen Zimmern, im Keller, unter Matratzen, geben Tipps zum Monster und deuten den Schlüssel an Halloween an – zugleich der Story-Faden (offene Frage 4).
- **Lampen flackern nur noch lokal** in der Nähe des Monsters: Flackern zeigt, *wo* es ist; Rauschen zeigt, *wie nah*.
- **Spuren:** Fußspuren **verblassen** über einige Minuten (man liest ab, wie frisch sie sind), Kratzspuren **bleiben**. Spuren am eigenen Zimmer kann man wegputzen.
- **Das Hotel verändert sich** (Punkt „unzuverlässiges Hotel“): Kleine Veränderungen, wenn man nicht hinsieht – teils durch das Monster, teils bleibt offen, wer es war.
- **Gäste als Quelle der Angst:** Gäste berichten von Spuren und Geräuschen, nicht immer zuverlässig.
- **Spuren der Gäste (umgesetzt 2026-10-11):** Nicht jede Spur stammt vom Monster. Gäste hinterlassen **schlammige Schuhabdrücke** nach dem Garten (verblassen), **Wachsflecken**, wenn sie etwas Brennendes tragen, **Blutstropfen** nach einem Angriff (sie wurden verletzt) und **verlorene Münzen**, wenn sie in Panik fliehen. Dazu **Zettel**: an manchen Türen von Anfang an („Bitte nicht stören.“), nach einem Todesfall („Klopft dreimal, wenn ihr es seid.“) und manchmal am Ort einer Sichtung. Man muss lernen, Monster- und Gästespuren zu unterscheiden.
- **Technische Atmosphäre:** mehr Nebel, Lichtkegel statt gleichmäßigen Lichts, Brummen mit dem Rauschen, engerer Blick unter Stress.

**Beobachteter Fehler im Prototyp (behoben 2026-10-11):** Nach einem harmlosen Angriff auf einen Gast jagte das Monster ihn beim Rückzug sofort wieder, oder der Gast kletterte direkt vor ihm zurück ins selbe Versteck. Folge: endloses Erschrecken, und Bruno rief in einem fort „Bleib weg!“. Jetzt gilt: Nach einem harmlosen Schreck verschwindet das Monster, ohne erneut zu jagen; Gäste meiden Verstecke in der Nähe des Monsters (8 m); denselben Panik-Satz sagt ein Gast höchstens alle 45 s.

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

### 6.1 Rolle
- Leben ebenfalls im Hotel, haben eigene Zimmer, eigene Deko, eigene Persönlichkeit.
- Sind **Handelspartner, potenzielle Freunde – und potenzielle Gegner**.

### 6.2 Beziehungssystem
- Jeder Gast hat einen **Beziehungswert** zum Spieler (z. B. -100 … +100).
- **Positiv** beeinflusst durch: nette Dialogoptionen, Geschenke, Gefallen, faire Trades, Hilfe bei Monster-Ereignissen.
- **Negativ** beeinflusst durch: unhöfliche Antworten, Deko-Diebstahl, schlechte Trades, „blöde Aktionen“ (z. B. Lärm vor deren Tür, Monster anlocken).
- Optional: **Ruf / Gerüchte** – Gäste reden miteinander, schlechtes Verhalten spricht sich herum.

### 6.3 Konsequenzen

| Beziehung | Verhalten des Gastes |
|-----------|----------------------|
| Freund    | Schenkt Deko, bietet gute Trades, warnt vor dem Monster |
| Neutral   | Normaler Handel |
| Feind     | Verweigert Handel, **klaut Deko** vom Spieler (vor dessen Tür / aus dem Flur) |

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
- Noch offen: Möbel als Einsatz, Wettschulden, weitere Spiele (Schach, Karten, Schnitz-Duell …).

---

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

> ⚠ **Kellertür und Spieler sind beide genau 1,80 m hoch.** Die Kapsel würde stecken bleiben. Optionen: Ducken nötig (passt atmosphärisch: man muss sich in den Keller *bücken*), Kellertür leicht erhöhen (z. B. 1,85 m) oder Hitbox minimal kleiner als 1,80 m.

- **Blender:** Maßeinheit Meter, 1 Blender-Einheit = 1 m = 1 Godot-Einheit. Modulares Kit z. B. im 1-m- oder 2-m-Raster, Wandhöhe 3,5 m als Standard.
- **Eigenes Zimmer:** sicherer Rückzugsort, Lager für Deko, **einziger Speicherpunkt** (Tagebuch auf dem Schreibtisch, siehe 8.5).
- **Atmosphäre:** lange Flure (ideal für Silhouetten am Ende), schwaches Licht, alte Tapeten, knarrende Böden.
- **Eingeschlossen:** Ausgänge verriegelt – warum? (Story-Frage, siehe offene Punkte)

### 7.3 Fenster, Vorhänge & Wandlampen
> Stand: 2026-10-10 · im Prototyp umgesetzt (Außenfenster mit Vorhängen in Lobby und Zimmern, Milchglas zwischen Flur und Zimmern, Wandleuchten, ein Lichtschalter pro Raum/Flurabschnitt, Glühbirnen als Gegenstand)

Alle drei sind **interaktive Objekte** mit derselben Schnittstelle `interact(actor)` wie Türen und Truhen (9.1) – **Gäste benutzen sie genauso wie der Spieler**.

**Fenster**
- Wirken wie eine **Wand**: Man kommt nicht hindurch, kann aber **hindurchsehen**.
- Vorhandene Grundlage: Die Glasscheiben in der Lobby-Nordwand (eigene Kollisionsebene „Glas“) blockieren Bewegung, lassen aber den Blick durch.
- **Sicht in beide Richtungen (Vorschlag):** Auch Monster und Gäste sehen hindurch → das Monster kann einen durchs Fenster bemerken (4.5), Gäste können einen durchs Fenster beim Klauen beobachten und werden zu Zeugen (6.2).
- Mondlicht fällt durch offene Fenster herein (Helligkeit der Zone, 4.4).
- **Milchglasfenster im Flur** (entschieden): Innenfenster zwischen Flur und Räumen. Man sieht **nicht klar** hindurch, nur **Licht, Schatten und Umrisse** – genau dort zeigt sich das Monster gern als diffuser Schatten (4.1). Umgekehrt sieht man von innen, ob im Flur Licht brennt oder sich etwas bewegt. Milchglas lässt Licht durch, aber **keine Sicht für die „bemerkt“-Erkennung** (4.5) und keine Zeugenschaft – nur einen Hinweis „da war jemand“.

**Vorhänge**
- Jedes Außenfenster hat Vorhänge (Milchglas im Flur: Vorschlag ohne Vorhang), die man **aufziehen und zuziehen** kann.
- **Zugezogen:** kein Blick hinein und hinaus, aber auch **kein Mondlicht** → der Raum wird dunkler (und damit für das Monster attraktiver).
- **Aufgezogen:** Licht und Sicht – aber man ist auch von außen zu sehen.
- **Gäste** nutzen Vorhänge ebenfalls, z. B. zieht die ängstliche Edna sie nachts zu, um nicht gesehen zu werden – und macht ihr Zimmer damit dunkler.

**Wandlampen**
- Zusätzliche Lichtquellen an den Wänden von Fluren und Zimmern, neben den Deckenlampen.
- **Ein Lichtschalter pro Raum** (entschieden): schaltet alle Lampen des Raums bzw. Flurabschnitts gemeinsam (Decken- und Wandlampen) ein und aus.
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

**Für später vorgemerkt**
- **Zerbrechende Fenster** – wird in einer späteren Runde geplant (bis dahin sind Fenster unzerbrechlich).

**Zu klären**
- Brauchen Glühbirnen eine heiße Lampe / Verbrennungsgefahr beim Herausdrehen bei eingeschaltetem Licht? (Vorschlag: erst ausschalten, sonst kurz „Autsch“ und Birne fällt evtl.) – im Prototyp noch ohne.
- Zerspringt eine heruntergefallene Birne? – im Prototyp noch nicht.

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
| **Bild** | **Helligkeit/Gamma mit Kalibrierbild** („Der Kürbis soll gerade noch erkennbar sein“) – wichtig, weil Dunkelheit Spielmechanik ist (4.4) · Vollbild/Fenster · VSync · Sichtfeld (FOV) |
| **PS1-Look** | Interne Auflösung · Vertex-Wackeln an/aus · Dithering an/aus |
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
| **Welt** | Türen (offen/zu/abgeschlossen), Truhen-Inhalte, Lampen (intakt/kaputt, Birne drin/fehlt), Lichtschalter je Raum (an/aus), Vorhänge (offen/zu), Kürbisbeete (Stufe, Wachstum), Laub-/Spinnweben-Vorräte, Plattenspieler |
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

---

## 10. Offene Fragen für die Detaildiskussion

1. ~~Ziel~~ → **Dem Horrorhotel entkommen** (entschieden). Offen: Wie genau? (Schlüssel für die Lobbytür zusammensuchen, Rätsel, Hilfe der Gäste?)
2. ~~Zeitstruktur~~ → **durchgängig**, keine Level; Ingame-Tage à ca. 5 min vom 1. Oktober bis Halloween, draußen immer Nacht (2.1, entschieden).
3. ~~Monster-Kontakt~~ → Jumpscare + Sterbebildschirm, danach letzten Spielstand laden (entschieden, siehe 8).
3a. **„Bemerkt“-Auslöser:** Reicht Hinschauen, oder muss der Spieler sichtbar reagieren?
3b. **Spieler-Lichtquelle:** Hat der Spieler eine Taschenlampe/Laterne? (Schützt vor dem Monster, aber verrät die eigene Position?)
3c. **Garten-Zeit:** Wie lange wächst ein Kürbis – Minuten Echtzeit oder Ingame-Tage?
3d. **Kellertür vs. Hitbox:** Ducken, Tür erhöhen oder Hitbox verkleinern?
3e. **Puppe:** Kann sie auch Deko verändern/umwerfen, oder nur beobachten? Kann der Spieler ihr Urteil irgendwie sehen?
3g. ~~Verstecke~~ → Zeitlimit wie in Doors, beim Hineingehen gesehen = Tod, Gäste können sterben (entschieden).
3i. **Schock-Malus:** Welche Mali aus 6.9? Wie stark, wie lange?
3j. ~~Feiern~~ → spontan durch Gäste, Spieler kann auch eine ausrichten (entschieden).
3k. **Minispiele (6.10):** Welche Spiele für den ersten Umfang? Echte Schachregeln (aufwendiger) oder zuerst ein einfaches Würfel-/Kartenspiel? Welche Möbel dürfen als Einsatz dienen?
3h. **Truhen:** Abschließbar? Gibt es eine eigene Truhe im Spielerzimmer?
3f. ~~Tragen~~ → kein Inventar, alles in den Händen, nur Geld als Wert (entschieden). Offen: ein oder zwei Hände?
4. **Story:** Warum ist man eingeschlossen? Was ist das Monster? Wer sind die Gäste?
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
7. Fluchtweg aus dem Hotel (Ausgangsschlüssel / Rätsel / Hilfe der Gäste)
7a. ~~Zimmertelefone (4.14)~~ ✔ (2026-10-11)
8. Echte Modelle aus Blender (glTF) statt Platzhalter, echte Sounds
9. ~~Titelbildschirm, Spielmenü (Esc), Einstellungen, Speichern/Laden~~ ✔ (2026-10-10, siehe 8) · ~~Fenster, Vorhänge, Wandlampen, Lichtschalter, Glühbirnen~~ ✔ (7.3) · ~~Sehen & Jagen~~ ✔ (4.12)
10. Balancing, weitere Etagen
11. Zerbrechende Fenster (7.3, für später vorgemerkt)
