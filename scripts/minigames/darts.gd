class_name Darts
extends RefCounted
## Regeln fürs Darts an der Bar (Spielkonzept 6.10) als reine Rechnung: welches Feld ein Punkt auf der Scheibe trifft,
## wohin man für ein Feld zielt, was ein Gast als Nächstes anwirft. Gespielt wird 301 mit einfachem Aus: Wer genau
## auf 0 kommt, gewinnt; wer überwirft, bekommt die Aufnahme nicht angerechnet. Nach MAX_VISITS Aufnahmen je Spieler
## gewinnt der kleinere Rest. Punkte auf der Scheibe in Metern, x nach rechts, y nach oben, Mitte = Bull.

const START := 301
const MAX_VISITS := 10
const DARTS_PER_VISIT := 3

## Zahlen im Uhrzeigersinn, oben beginnend (Turniermaß)
const SEGMENTS := [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5]
## Ringe (Radius in m, Turniermaß): Bull, Single-Bull, Triple innen/außen, Double innen/außen, Rand der Scheibe
const R_BULL := 0.00635
const R_OUTER_BULL := 0.0159
const R_TRIPLE_IN := 0.099
const R_TRIPLE_OUT := 0.107
const R_DOUBLE_IN := 0.162
const R_DOUBLE_OUT := 0.170
const R_BOARD := 0.2255
## So weit wie der schwarze Ring um die Scheibe (Surround) – was weiter weg landet, trifft die Wand
const R_SURROUND := 0.34

enum Ring { MISS, SINGLE, DOUBLE, TRIPLE, OUTER_BULL, BULL }


## Was der Punkt p trifft: {value, ring, number, text, board (auf der Scheibe), surround (im Ring drumherum)}.
static func score_at(p: Vector2) -> Dictionary:
	var r := p.length()
	var number := number_at(p)
	var hit := {"value": 0, "ring": Ring.MISS, "number": number, "text": "daneben", "board": r <= R_BOARD,
		"surround": r > R_BOARD and r <= R_SURROUND}
	if r <= R_BULL:
		hit.merge({"value": 50, "ring": Ring.BULL, "text": "Bull"}, true)
	elif r <= R_OUTER_BULL:
		hit.merge({"value": 25, "ring": Ring.OUTER_BULL, "text": "25"}, true)
	elif r < R_TRIPLE_IN or (r > R_TRIPLE_OUT and r < R_DOUBLE_IN):
		hit.merge({"value": number, "ring": Ring.SINGLE, "text": str(number)}, true)
	elif r <= R_TRIPLE_OUT:
		hit.merge({"value": number * 3, "ring": Ring.TRIPLE, "text": "T%d" % number}, true)
	elif r <= R_DOUBLE_OUT:
		hit.merge({"value": number * 2, "ring": Ring.DOUBLE, "text": "D%d" % number}, true)
	elif r <= R_BOARD:
		hit["text"] = "Zahlenring"
	return hit


## Zahl des Segments, in dem p liegt (auch außerhalb der Ringe).
static func number_at(p: Vector2) -> int:
	var angle := fposmod(rad_to_deg(atan2(p.x, p.y)) + 9.0, 360.0)   # im Uhrzeigersinn ab oben
	return SEGMENTS[int(angle / 18.0) % 20]


## Mitte des Feldes: number 1–20 (25 = Bull-Ring, 50 = Bull), ring aus Ring.
static func aim_point(number: int, ring: Ring) -> Vector2:
	if ring == Ring.BULL or number == 50:
		return Vector2.ZERO
	if ring == Ring.OUTER_BULL or number == 25:
		return Vector2(0, (R_BULL + R_OUTER_BULL) / 2.0)
	var radius := 0.0
	match ring:
		Ring.TRIPLE:
			radius = (R_TRIPLE_IN + R_TRIPLE_OUT) / 2.0
		Ring.DOUBLE:
			radius = (R_DOUBLE_IN + R_DOUBLE_OUT) / 2.0
		_:
			radius = (R_TRIPLE_OUT + R_DOUBLE_IN) / 2.0   # das große äußere Single-Feld
	var angle := deg_to_rad(SEGMENTS.find(number) * 18.0)
	return Vector2(sin(angle), cos(angle)) * radius


## Wohin ein Gast mit diesem Rest wirft: {number, ring}. Planlose (skill < 0.3) werfen auf die 20, bis der Rest
## klein ist; die anderen suchen das Feld, das genau aufgeht, sonst eines, das einen leichten Rest lässt.
static func target_for(rest: int, skill: float) -> Dictionary:
	if rest > 60 or (skill < 0.3 and rest > 20):
		return {"number": 20, "ring": Ring.TRIPLE if skill >= 0.3 else Ring.SINGLE}
	if rest <= 20:
		return {"number": rest, "ring": Ring.SINGLE}
	if rest == 25:
		return {"number": 25, "ring": Ring.OUTER_BULL}
	if rest == 50:
		return {"number": 50, "ring": Ring.BULL}
	if rest <= 40 and rest % 2 == 0:
		return {"number": int(rest / 2.0), "ring": Ring.DOUBLE}
	if rest % 3 == 0:
		return {"number": int(rest / 3.0), "ring": Ring.TRIPLE}
	if rest - 20 <= 20:
		return {"number": rest - 20, "ring": Ring.SINGLE}   # lässt 20 übrig
	return {"number": 20, "ring": Ring.SINGLE}


## Punkt mit normalverteilter Streuung (sigma in m) um aim.
static func scatter(aim: Vector2, sigma: float) -> Vector2:
	return aim + Vector2(randfn(0.0, sigma), randfn(0.0, sigma))


## Rest nach einem Wurf: {rest, bust (überworfen), won}. visit_start = Rest zu Beginn der Aufnahme.
static func apply(rest: int, value: int, visit_start: int) -> Dictionary:
	var left := rest - value
	if left < 0:
		return {"rest": visit_start, "bust": true, "won": false}
	return {"rest": left, "bust": false, "won": left == 0}
