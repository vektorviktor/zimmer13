extends Node
## Die vier Modi des Leviathan (Spielkonzept 4.33): Der Plan, den MonsterDirector._make_plan nach dem ersten Angriff
## würfelt, hält für viele Seeds die Zahlen je Modus ein (8–12 Urteile, 4–5 Snacks, 10–13 Raubzüge), Snacks liegen
## nie an einem Tag mit Urteil, zwei Auftritte liegen mindestens MODE_GAP auseinander, alles vor Halloween-Ende; die
## Opferzahl der Anforderung bleibt bei 1–7. Läuft über tests/run.tscn.

const SEEDS := 200

var _ok := true


func run() -> bool:
	var d := MonsterDirector.new()
	add_child(d)
	d.set_physics_process(false)
	for i in SEEDS:
		seed(i)
		d.elapsed = Calendar.at(2, 22.0)   # nach der Siegerehrung (2.5)
		d._make_plan()
		var counts := {}
		var judgment_days: Array[int] = []
		for e in d.plan:
			counts[e["mode"]] = int(counts.get(e["mode"], 0)) + 1
			if e["mode"] == MonsterDirector.Mode.JUDGMENT:
				judgment_days.append(int(e["day"]))
		_range(counts, MonsterDirector.Mode.JUDGMENT, MonsterDirector.JUDGMENTS, i)
		_range(counts, MonsterDirector.Mode.SNACK, MonsterDirector.SNACKS, i)
		_range(counts, MonsterDirector.Mode.RAID, MonsterDirector.RAIDS, i)
		for j in d.plan.size():
			var e: Dictionary = d.plan[j]
			if e["mode"] == MonsterDirector.Mode.SNACK:
				_check(not int(e["day"]) in judgment_days, "Seed %d: Snack am Tag eines Urteils (%d)" % [i, e["day"]])
			if j > 0:
				_check(float(e["at"]) - float(d.plan[j - 1]["at"]) >= MonsterDirector.MODE_GAP - 0.01,
					"Seed %d: Auftritte zu dicht" % i)
		if not d.plan.is_empty():
			_check(float(d.plan.back()["at"]) < Calendar.at(Calendar.HALLOWEEN + 1, 6.0), "Seed %d: nach Halloween" % i)
		var n := d._draw_victims()
		_check(n >= 1 and n <= 7, "Seed %d: Opferzahl %d" % [i, n])
	d.queue_free()
	print("Modi des Leviathan: alles richtig" if _ok else "Modi des Leviathan: FEHLER")
	return _ok


func _range(counts: Dictionary, m: MonsterDirector.Mode, wanted: Vector2i, i: int) -> void:
	var n := int(counts.get(m, 0))
	_check(n >= wanted.x and n <= wanted.y, "Seed %d: %d × %s (soll %d–%d)" % [i, n, MonsterDirector.MODE_NAMES[m],
		wanted.x, wanted.y])


func _check(good: bool, text: String) -> void:
	if not good and _ok:
		print("  FEHLER: " + text)
	if not good:
		_ok = false
