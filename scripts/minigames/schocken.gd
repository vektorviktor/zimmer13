class_name Schocken
## Regeln für Schocken (Spielkonzept 6.10, Entscheidung 28.10.): drei Würfel, bis zu drei Würfe, Einsen dürfen
## liegen bleiben. Von oben: Schock aus (1-1-1, alle Deckel) > Schock 6 … Schock 2 (1-1-X, X Deckel) > General
## (drei Gleiche, 3 Deckel) > Straße (drei in Folge, 2 Deckel) > Hausnummer (der Rest, groß nach klein gelesen,
## 1 Deckel). Wer die Runde verliert, bekommt so viele Deckel, wie der Wurf des Gewinners wert ist.

const DECKEL := 13


static func roll(count: int) -> Array[int]:
	var result: Array[int] = []
	for i in count:
		result.append(randi_range(1, 6))
	return result


## Wertung zum Vergleichen: Klasse × 1000 + Feinwert (Hausnummer 0, Straße 1, General 2, Schock 3, Schock aus 4).
static func score(dice: Array[int]) -> int:
	var d := dice.duplicate()
	d.sort()
	if d[2] == 1:
		return 4000
	if d[0] == 1 and d[1] == 1:
		return 3000 + d[2]
	if d[0] == d[1] and d[1] == d[2]:
		return 2000 + d[0]
	if d[1] == d[0] + 1 and d[2] == d[1] + 1:
		return 1000 + d[2]
	return d[2] * 100 + d[1] * 10 + d[0]


## So viele Deckel ist der Wurf wert.
static func deckel(dice: Array[int]) -> int:
	var s := score(dice)
	if s >= 4000:
		return DECKEL
	if s >= 3000:
		return s - 3000
	if s >= 2000:
		return 3
	if s >= 1000:
		return 2
	return 1


static func label(dice: Array[int]) -> String:
	var s := score(dice)
	if s >= 4000:
		return "Schock aus!"
	if s >= 3000:
		return "Schock %d" % (s - 3000)
	if s >= 2000:
		return "General (%der)" % (s - 2000)
	if s >= 1000:
		return "Straße bis %d" % (s - 1000)
	return "Hausnummer %d" % s


## Gewinnt Wurf a gegen b? Gleiche Wertung: weniger Würfe gewinnt, sonst der, der zuerst gewürfelt hat (a_first).
static func beats(a: Array[int], a_throws: int, b: Array[int], b_throws: int, a_first: bool) -> bool:
	var sa := score(a)
	var sb := score(b)
	if sa != sb:
		return sa > sb
	if a_throws != b_throws:
		return a_throws < b_throws
	return a_first


## Würfel neu werfen, Einsen bleiben liegen (keep_ones) – gibt die neuen Würfel zurück.
static func reroll(dice: Array[int], keep_ones: bool) -> Array[int]:
	var result: Array[int] = []
	for v in dice:
		result.append(v if keep_ones and v == 1 else randi_range(1, 6))
	return result
