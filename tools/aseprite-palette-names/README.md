# Palettennamen – Aseprite-Erweiterung

Zeigt die Palette der aktiven Datei als Liste: **Farbkachel, Index, Name**. Gedacht für den Gebäudeplan
`map.aseprite`, dessen Legende in den Farbnamen steht („Wand“, „Tür Flur“, „Möbel: Bett“, „Licht: Kerze“ …).
Die Namen stehen in der **Legende `map.gpl`** neben der Datei (GIMP-Palette, eine Zeile „R G B<Tab>Name“ je
Palettenfarbe in Palettenreihenfolge): Aseprite 1.3.18 behält keine Farbnamen, schon Öffnen und Speichern
verwirft sie. Ohne `.gpl` liest die Erweiterung die Namen aus dem Paletten-Chunk der Datei (ältere Dateien).
Getestet mit Aseprite 1.3.18.6 (Steam).

## Installieren

Doppelklick auf `palettennamen.aseprite-extension` – oder in Aseprite
*Edit > Preferences > Extensions > Add Extension* und die Datei wählen.

Neu packen nach Änderungen an den Lua-Dateien (aus dem Projektwurzelverzeichnis), danach erneut installieren:

```bash
python tools/aseprite-palette-names/pack.py
```

## Benutzen

- Öffnen und schließen über **View > Palettennamen** oder im Paletten-Menü (☰-Knopf über der Palette)
  **Palettennamen anzeigen**. Schließen auch mit dem ✕ im Fenstertitel. Das Fenster lässt sich verschieben
  und in Breite und Höhe ziehen, auch recht schmal (zu lange Namen werden dann abgeschnitten, die Fußzeile
  zeigt den vollen Namen); Lage und Einstellungen bleiben gespeichert.
- **Beim ersten Öffnen fragt Aseprite** „The following script … wants to access this file“. Die Erweiterung
  liest die Legende (bzw. die gespeicherte Datei), weil Aseprites Skript-Schnittstelle keine Farbnamen kennt. Am besten
  *Give full trust to this script* anhaken und *Allow Read Access* klicken – dann kommt die Frage nicht wieder.
  Die Erweiterung schreibt nie etwas; Palette, Legende und Datei bleiben unverändert.
- **Linksklick** auf einen Eintrag setzt die Vordergrundfarbe, **Rechtsklick** die Hintergrundfarbe.
  Die aktuelle Vordergrundfarbe ist in der Liste markiert. Die Fußzeile unter der Liste zeigt den Eintrag
  unter der Maus (oder die Vordergrundfarbe) mit Index, vollem Namen und Hex-Wert, darunter Datei und Anzahl.
- **Auswahl oben (Gruppe):** nur einen Namensvorsatz zeigen (`Möbel`, `Ausstattung`, `Gegenstand`, `Licht`,
  `Ohne Vorsatz`, `Ohne Namen`). Die Liste wird aus der Palette gebildet, neue Vorsätze erscheinen von selbst.
- **Gruppiert:** Überschrift je Vorsatz; der Vorsatz fällt dann im Namen weg. Klick auf eine Überschrift
  klappt die Gruppe ein und aus.
- **Textfeld unter „Gruppiert“ (Suche):** Teil des Namens, Index (`29`) oder Hex-Wert (`#7a3b`).
- Mausrad oder Leiste rechts zum Blättern.

## Wann sich die Liste aktualisiert

- Andere Datei (Tab) gewählt → Liste dieser Datei.
- Palette geändert (Farbe bearbeitet, verschoben, hinzugefügt, Rückgängig) → Farben sofort.
- Gespeichert → Namen neu aus der Legende.
- **Neu einlesen** liest die Namen von Hand nach (z. B. nach einer Änderung an `map.gpl`).

Die **Farben** kommen immer live aus der Palette, die **Namen aus der Legende**. Weicht die Palette von der
Legende ab (Farbe verschoben oder ihr Wert geändert), ordnet die Erweiterung die Namen nach Farbwert bzw. Index
zu und hängt ein `*` an (unsicher); unten steht die Anzahl. Neue, nie gespeicherte Dateien und andere Formate
als `.aseprite`/`.ase` haben keine Namen.

Farbnamen lassen sich mit der Erweiterung nicht ändern – dafür `map.gpl` im Texteditor bearbeiten: neue Farbe
in der Palette → neue Zeile am Ende (gleiche Reihenfolge wie in der Palette), Farbwert geändert → auch dort.
`tools/build_map.py` ordnet die Namen nach Farbwert zu.

## Dateien

| Datei | Inhalt |
|---|---|
| `package.json` | Beschreibung der Erweiterung für Aseprite |
| `palette-names.lua` | Fenster, Menübefehle, Ereignisse (Dateiwechsel, Palettenänderung, Speichern) |
| `palette-file.lua` | liest die Legende `<datei>.gpl` (sonst den Paletten-Chunk 0x2019 des ersten Frames) und ordnet die Namen zu |
| `test.lua` | Test im Batch-Modus, siehe unten |
| `pack.py` | baut `palettennamen.aseprite-extension` |

Test ohne Fenster (verändert nichts):

```bash
"C:/Steam/steamapps/common/Aseprite/Aseprite.exe" -b map.aseprite --script tools/aseprite-palette-names/test.lua
```

Bei mehreren Paletten in einer Datei (Palettenwechsel in späteren Frames) werden nur die Namen der
Palette im ersten Frame gelesen.
