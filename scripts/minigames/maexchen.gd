class_name Maexchen
## Regeln für Mäxchen: zwei Würfel unter dem Becher, höhere Augenzahl zuerst
## (3 und 1 → 31). Reihenfolge aufsteigend: 31 … 65, dann Pasch 11 … 66,
## ganz oben 21 – das „Mäxchen“. Wer ansagt, muss die vorige Ansage überbieten –
## ob es stimmt, weiß nur er selbst.

const ORDER := [31, 32, 41, 42, 43, 51, 52, 53, 54, 61, 62, 63, 64, 65, 11, 22, 33, 44, 55, 66, 21]


static func roll() -> Array[int]:
	return [randi_range(1, 6), randi_range(1, 6)]


static func value_of(dice: Array[int]) -> int:
	return maxi(dice[0], dice[1]) * 10 + mini(dice[0], dice[1])


static func rank(value: int) -> int:
	return ORDER.find(value)


static func beats(a: int, b: int) -> bool:
	return rank(a) > rank(b)


static func label(value: int) -> String:
	if value == 21:
		return "Mäxchen!"
	if value % 11 == 0:
		return "%der-Pasch" % (value / 11)
	return str(value)


## Wahrscheinlichkeit, dass ein zufälliger Wurf mindestens diesen Wert hat.
static func chance_at_least(value: int) -> float:
	var total := 0.0
	for i in range(rank(value), ORDER.size()):
		var v: int = ORDER[i]
		total += 1.0 / 36.0 if v % 11 == 0 else 2.0 / 36.0
	return total


## Die nächsten `count` Werte, die `value` überbieten (value = −1 → von unten).
static func higher_than(value: int, count: int) -> Array[int]:
	var result: Array[int] = []
	var start := 0 if value < 0 else rank(value) + 1
	for i in range(start, mini(start + count, ORDER.size())):
		result.append(ORDER[i])
	return result
