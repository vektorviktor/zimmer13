# Zimmer 13 – Offene Ideen

Ideen, die noch nicht entschieden sind. Hier werden sie gesammelt und durchgesprochen; was entschieden ist, wandert
mit Datum ins [Spielkonzept](SPIELKONZEPT.md) und wird hier gestrichen bzw. mit Verweis markiert.

Jede Idee: kurze Beschreibung, wie sie zum Spielkonzept passt, offene Fragen.

---

## 1. Jumpscare: Der Lakengeist in der Dusche (2026-10-25)

→ Entschieden und umgesetzt am 2026-10-25, steht jetzt im [Spielkonzept 4.24](SPIELKONZEPT.md#424-der-lakengeist-in-der-dusche-entschieden-und-umgesetzt-2026-10-25).

## 2. Die Kesselkatze als Mechanik (2026-10-25)

Gebaut ist sie als Führerin zu Kessel und UV-Schrift ([Spielkonzept 4.26](SPIELKONZEPT.md#426-die-schwarze-kesselkatze-entschieden-und-umgesetzt-2026-10-25)).
Der Nutzer möchte sie später als Mechanik besprechen: Geisterkatze, Augen im Dunkeln.

Offene Fragen: Wann und wo zeigt sie sich (nur unten, nur nachts)? Hilft oder warnt sie – und wie unterscheidet sie
sich von den drei Hotelkatzen (6.11)?

## 3. Der Rattenkönig im Glas (2026-10-25)

Sieben Ratten mit verknoteten Schwänzen in trübem Spiritus, in einem Glas auf einem Wandbord im Müllraum des
Untergeschosses; am Glas ein Zettel. Gedacht als reine Stimmung neben den Ratten ([Spielkonzept 4.25](SPIELKONZEPT.md#425-tiere-als-vorzeichen-krähen-ratten-motten-hund-entschieden-und-umgesetzt-2026-10-25)).

**Umsetzungsstand:**
- **Code:** `scripts/world/rat_king.gd` (`RatKing`), eingehängt in `main.gd` (`RatKing.place`). [E] „Glas ansehen“
  zeigt den Zettel und legt einen Notizbuch-Eintrag an („Müllraum“). Nicht gespeichert.
- **Modell:** keins – Wandbord, Glas, Ratten, Schwänze und Knoten aus Grundkörpern, aus der Nähe grob.
- **Ort:** kein Eintrag im Plan, bis dahin feste Koordinaten an der Nordwand des Müllraums (`FALLBACK`).
- **Story:** keine. Der Zettel („Gefunden im Kohlenkeller, Winter 1962. Sieben Stück. Nicht wegwerfen. – A. R.“)
  ist frei erfunden; wer „A. R.“ ist und was 1962 war, steht nirgends.
- Kein Debug-Parameter, kein Rauchtest-Szenario, im Spiel noch nicht angesehen.

Offene Fragen: Bleibt er? Wenn ja: Modell, Platz im Plan, und bekommt der Zettel einen Bezug zur Geschichte oder
wird er neutral?

## 4. Das Foto vom Leviathan (2026-10-25)

Ein Gast schafft es, **während eines Angriffs ein Foto** vom Leviathan zu machen. Danach reden die Gäste darüber, und
die Bedrohung wird **zum ersten Mal wirklich und greifbar**: kein Gerücht mehr, sondern ein Bild, das man in der Hand
halten kann.

Passt zu: der Benennung durch Hugo Stein ([Spielkonzept 4.32](SPIELKONZEPT.md#432-der-name-leviathan-entschieden-2026-10-25)),
die an der ersten bestätigten Sichtung hängt (ein Gast sieht es und überlebt) – das Foto wäre ein zweiter, späterer
Schritt. Außerdem zur Fotowand in der Lobby (5.14) und zur Frage aus 4.22, ob ein Foto einen Vampir verrät.

Offene Fragen: Welcher Gast (Paula Jansen, H30, die über das Hotel schreibt, oder das Paar Engel, H14, das den Spuk
beweisen will)? Wann – fest oder bei einem beliebigen Angriff? Hängt das Foto danach an der Fotowand? Was ändert
sich bei den Gästen, wenn es greifbar ist (Angst, Skeptiker geben auf, Magda Seidel, H36, sieht den Trick der
Direktion bestätigt)?

## 5. Die verbotenen Masken: Regel und Herkunft (2026-10-25)

Die acht verbotenen Masken sind entschieden ([Spielkonzept 5.19](SPIELKONZEPT.md#519-der-maskenball-und-die-verbotenen-masken-entschieden-2026-10-25)):
Jede ruft ihre eigene Bedrohung, sie hängen gesammelt in Zimmer 13 und werden an Gäste nur verliehen. Offen ist,
**warum** sie verboten sind und **wie** sie zum Spieler und zu den Gästen kommen. Das darf der Umsetzung des
Maskenballs nicht im Weg stehen.

Offene Fragen:
- **Die unbekannte Regel:** Wer oder was verbietet sie? Gehören sie zum Abkommen von 1987 (2.3) – etwa Masken vom
  ersten Ball, nach denen das Hotel die Dinge geformt hat, die heute umgehen? Erfährt man die Regel je, und wodurch
  (Dokument, Edna, Hugo)?
- **Wie kommen sie in Umlauf?** Nur über feste Verstecke (Vorschläge in 5.19), oder tauchen sie auch auf –
  morgens vor Zimmer 13, bei einem Gast im Zimmer, als Gewinn beim Ball? Finden Gäste selbst eine und tragen sie,
  ohne zu wissen, was sie tun?
- Kann Hugo Stein (H27) sie erkennen, kaufen oder verkaufen?

## 6. Der Ring im Dachnest (2026-10-25)

Ein Gast hat seinen **Ring** draußen auf einem Tisch liegen lassen, eine Krähe ist vorbeigekommen und hat ihn
geholt. Er liegt jetzt im **Nest am Dach**, direkt vor einem Dachfenster im Dachgeschoss, mit ausgestrecktem Arm zu
erreichen ([Spielkonzept 4.25](SPIELKONZEPT.md#425-tiere-als-vorzeichen-krähen-ratten-motten-hund-entschieden-und-umgesetzt-2026-10-25),
Erweiterung). Passt als Gastauftrag der Art „Wiederfinden“ (6.14).

Offene Fragen: Wessen Ring (Ehering, Erbstück, ein Ring mit Bezug zu 1987)? Wie kommt der Auftrag zum Spieler –
fragt der Gast, oder findet man den Ring zuerst und muss den Besitzer suchen? Welches Dachfenster (hängt an der Form
des Dachs)? Was ist der Lohn?

## 7. Ein eigenes Grab für jeden Toten (2026-10-26)

Bisher bekommen nur Tote mit Leiche ein Grab (Lakengeist, Kürbismann); die Opfer des Leviathan stehen nur auf der
Gedenktafel, mit einer Grabkerze je Name ([Spielkonzept 5.15](SPIELKONZEPT.md#515-friedhof-und-grablichter-entschieden-und-umgesetzt-2026-10-25)).
Dort lassen sich keine persönlichen Dinge ablegen: Zwischen 2 und 30 Grablichtern wirkt etwa Gustavs Brille (2.9)
zufällig. Mit einem **eigenen Platz je Toten** – auch für Vermisste, ein leeres Grab oder ein Gedenkstein – könnte man
Fundstücke dort ablegen (Brille, Hausschuh, Briefe), und die Frage stellt sich nicht bei jedem Gast neu.

Offene Fragen: Leeres Grab oder Gedenkstein für Vermisste? Reichen die 43 Grabplätze? Bringt Ablegen etwas (Gedenken,
Beziehung bei den Freunden) oder ist es nur Stimmung? Legen Gäste selbst Dinge ab?
