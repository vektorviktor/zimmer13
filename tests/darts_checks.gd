extends Node
## Darts (Spielkonzept 6.10) ohne Hotel: Felder der Scheibe, Zielpunkte, was ein Gast mit seinem Rest anwirft, 301 mit
## einfachem Aus, und als Simulation, wie viele Aufnahmen Gäste je nach Treffsicherheit brauchen. Läuft über
## tests/run.tscn.

var _ok := true


func run() -> bool:
	_fields()
	_aims()
	_targets()
	_rules()
	_simulation()
	print("Darts: alles richtig" if _ok else "Darts: FEHLER")
	return _ok


func _check(good: bool, text: String) -> void:
	print(("ok      " if good else "FALSCH  ") + text)
	_ok = _ok and good


## Bull, Triple-20 oben, die 3 unten, die 6 rechts, die 11 links, Double-Ring, Zahlenring, Wand.
func _fields() -> void:
	var cases := [[Vector2.ZERO, 50], [Vector2(0, 0.012), 25], [Vector2(0, 0.103), 60], [Vector2(0, 0.166), 40],
		[Vector2(0, 0.135), 20], [Vector2(0, -0.103), 9], [Vector2(0.103, 0), 18], [Vector2(-0.103, 0), 33],
		[Vector2(0, 0.19), 0], [Vector2(0, 0.5), 0]]
	var wrong: Array[String] = []
	for c in cases:
		var hit := Darts.score_at(c[0])
		if int(hit["value"]) != int(c[1]):
			wrong.append("%s → %s (%d statt %d)" % [c[0], hit["text"], hit["value"], c[1]])
	_check(wrong.is_empty(), "Felder: Bull, T20, D20, T3 unten, T6 rechts, T11 links, Zahlenring%s" % (
		"" if wrong.is_empty() else " – " + "; ".join(wrong)))
	var ring := Darts.score_at(Vector2(0, 0.19))
	var wall := Darts.score_at(Vector2(0, 0.5))
	_check(ring["board"] and not ring["surround"] and not wall["board"] and not wall["surround"],
		"Zahlenring zählt zur Scheibe, 50 cm daneben ist Wand")


## Jedes Feld trifft man in seiner Mitte.
func _aims() -> void:
	var wrong: Array[String] = []
	for number: int in Darts.SEGMENTS:
		for ring in [Darts.Ring.SINGLE, Darts.Ring.DOUBLE, Darts.Ring.TRIPLE]:
			var want: int = number * {Darts.Ring.SINGLE: 1, Darts.Ring.DOUBLE: 2, Darts.Ring.TRIPLE: 3}[ring]
			var got := int(Darts.score_at(Darts.aim_point(number, ring))["value"])
			if got != want:
				wrong.append("%d/%d → %d" % [number, ring, got])
	_check(wrong.is_empty(), "60 Felder in der Mitte getroffen%s" % ("" if wrong.is_empty() else ": " + ", ".join(wrong)))


## Wer genau zielt, überwirft nie: Für jeden Rest bis 301 bleibt das Zielfeld darunter; bis 60 geht es oft genau auf.
func _targets() -> void:
	var over: Array[int] = []
	var exact := 0
	for rest in range(1, Darts.START + 1):
		for skill: float in [0.1, 0.8]:
			var t := Darts.target_for(rest, skill)
			var value := int(Darts.score_at(Darts.aim_point(int(t["number"]), t["ring"]))["value"])
			if value > rest:
				over.append(rest)
			if skill > 0.5 and rest <= 60 and value == rest:
				exact += 1
	_check(over.is_empty(), "Zielfeld nie größer als der Rest%s" % ("" if over.is_empty() else ": " + str(over.slice(0, 8))))
	_check(exact >= 40, "%d von 60 kleinen Resten gehen mit einem Pfeil genau auf" % exact)


func _rules() -> void:
	var bust := Darts.apply(10, 20, 70)
	var won := Darts.apply(20, 20, 60)
	var normal := Darts.apply(100, 60, 160)
	_check(bust["bust"] and int(bust["rest"]) == 70, "überworfen: Aufnahme zählt nicht (Rest zurück auf 70)")
	_check(won["won"] and int(won["rest"]) == 0, "genau auf null gewinnt")
	_check(not normal["bust"] and int(normal["rest"]) == 40, "sonst abziehen")


## So spielen die Gäste: Aufnahmen bis 0 (höchstens 20) im Mittel – schwach länger als sicher, der Sichere meist
## innerhalb der zehn Aufnahmen.
func _simulation() -> void:
	seed(1987)
	var means := {}
	for skill: float in [0.1, 0.5, 0.9]:
		var sigma := lerpf(DartMatch.GUEST_SIGMA.x, DartMatch.GUEST_SIGMA.y, skill)
		var total := 0
		var in_ten := 0
		for game in 300:
			var visits := _play(skill, sigma)
			total += visits
			in_ten += 1 if visits <= Darts.MAX_VISITS else 0
		means[skill] = total / 300.0
		print("        Treffsicherheit %.1f (Streuung %.1f cm): %.1f Aufnahmen, %d %% in zehn" % [skill, sigma * 100.0,
			means[skill], in_ten * 100 / 300])
	_check(means[0.1] > means[0.5] and means[0.5] > means[0.9], "schwächer wirft länger")
	_check(means[0.9] < 9.0 and means[0.1] < 20.0, "sicher meist in zehn Aufnahmen, schwach nicht endlos")


func _play(skill: float, sigma: float) -> int:
	var rest := Darts.START
	for visit in 20:
		var start := rest
		for dart in Darts.DARTS_PER_VISIT:
			var t := Darts.target_for(rest, skill)
			var hit := Darts.score_at(Darts.scatter(Darts.aim_point(int(t["number"]), t["ring"]), sigma))
			var result := Darts.apply(rest, int(hit["value"]), start)
			rest = int(result["rest"])
			if result["won"]:
				return visit + 1
			if result["bust"]:
				break
	return 20
