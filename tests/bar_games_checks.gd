extends Node
## Barspiele (Spielkonzept 6.10, 28.10.) ohne Hotel: Wertung und Deckel beim Schocken, Kartenwerte bei 17 und 4,
## Auszahlung und Erwartungswert des Spielautomaten (er muss auf Dauer mehr schlucken, als er gibt), gezinkte
## Würfel im Becher überstehen das Speichern (Zusatz).
## Läuft über tests/run.tscn.

var _ok := true


func run() -> bool:
	_schocken()
	_seventeen()
	_slot()
	_loaded_cup()
	print("Barspiele: alles richtig" if _ok else "Barspiele: FEHLER")
	return _ok


func _check(good: bool, text: String) -> void:
	print(("ok      " if good else "FALSCH  ") + text)
	_ok = _ok and good


func _dice(a: int, b: int, c: int) -> Array[int]:
	return [a, b, c]


func _schocken() -> void:
	_check(Schocken.label(_dice(1, 1, 1)) == "Schock aus!" and Schocken.deckel(_dice(1, 1, 1)) == Schocken.DECKEL,
		"Schocken: 1-1-1 ist Schock aus, alle Deckel")
	_check(Schocken.label(_dice(6, 1, 1)) == "Schock 6" and Schocken.deckel(_dice(1, 6, 1)) == 6, "Schocken: 1-1-6 ist Schock 6, 6 Deckel")
	_check(Schocken.deckel(_dice(4, 4, 4)) == 3 and Schocken.deckel(_dice(3, 5, 4)) == 2 and Schocken.deckel(_dice(6, 4, 2)) == 1,
		"Schocken: General 3, Straße 2, Hausnummer 1 Deckel")
	var order := [_dice(1, 1, 1), _dice(1, 1, 6), _dice(1, 1, 2), _dice(6, 6, 6), _dice(2, 2, 2), _dice(4, 5, 6),
		_dice(1, 2, 3), _dice(6, 6, 5), _dice(6, 5, 3), _dice(2, 2, 1)]
	var sorted := true
	for i in order.size() - 1:
		sorted = sorted and Schocken.score(order[i]) > Schocken.score(order[i + 1])
	_check(sorted, "Schocken: Reihenfolge Schock aus > Schock 6 > Schock 2 > General > Straße > Hausnummer")
	_check(Schocken.label(_dice(3, 6, 5)) == "Hausnummer 653", "Schocken: Hausnummer groß nach klein gelesen (653)")
	_check(Schocken.beats(_dice(6, 5, 3), 1, _dice(5, 6, 3), 2, false), "Schocken: gleicher Wurf – weniger Würfe gewinnen")
	_check(Schocken.beats(_dice(6, 5, 3), 2, _dice(5, 6, 3), 2, true), "Schocken: gleicher Wurf, gleich oft – wer zuerst war")
	var kept := Schocken.reroll(_dice(1, 4, 1), true)
	_check(kept[0] == 1 and kept[2] == 1, "Schocken: Einsen bleiben beim Nachwürfeln liegen")


func _seventeen() -> void:
	var fire: Array[String] = ["Herz Ass", "Pik Ass"]
	var mixed: Array[String] = ["Kreuz König", "Karo 10", "Herz Bube"]
	_check(SeventeenFourMatch.hand_value(fire) == 21, "17 und 4: zwei Asse sind Feuer (21)")
	_check(SeventeenFourMatch.hand_value(mixed) == 16, "17 und 4: König 4 + Zehn + Bube 2 = 16")
	var total := 0
	for rank in SeventeenFourMatch.RANKS:
		total += int(SeventeenFourMatch.RANKS[rank])
	_check(total == 54, "17 und 4: eine Farbe zählt 54 Augen (7–10, B 2, D 3, K 4, A 11)")


func _slot() -> void:
	var r: Array[int] = [0, 0, 0]
	_check(SlotMachine.payout(r) == 20, "Spielautomat: drei Siebenen zahlen 20")
	r = [5, 5, 5]
	_check(SlotMachine.payout(r) == 0, "Spielautomat: drei Augen zahlen nichts")
	r = [2, 3, 2]
	_check(SlotMachine.payout(r) == SlotMachine.PRICE, "Spielautomat: zwei Gleiche geben den Einsatz zurück")
	# Erwartungswert über alle Walzenkombinationen mit ihren Gewichten
	var total := 0
	for s in SlotMachine.SYMBOLS:
		total += int(s[2])
	var expected := 0.0
	for a in SlotMachine.SYMBOLS.size():
		for b in SlotMachine.SYMBOLS.size():
			for c in SlotMachine.SYMBOLS.size():
				var p := float(SlotMachine.SYMBOLS[a][2]) * float(SlotMachine.SYMBOLS[b][2]) * float(SlotMachine.SYMBOLS[c][2]) / pow(total, 3)
				var combo: Array[int] = [a, b, c]
				expected += p * SlotMachine.payout(combo)
	_check(expected < 0.85 * SlotMachine.PRICE, "Spielautomat: zahlt im Mittel %.2f je Geld aus (< 0,85)" % expected)


func _loaded_cup() -> void:
	var cup := Item.create(Item.Kind.DICE_CUP)
	_check(not cup.dice_loaded and cup.create_extra() == "", "Würfelbecher: frisch ohne gezinkte Würfel")
	cup.dice_loaded = true
	var copy := Item.create(Item.Kind.DICE_CUP, cup.create_extra())
	_check(copy.dice_loaded, "Würfelbecher: gezinkte Würfel bleiben über den Zusatz erhalten (Speichern)")
	cup.free()
	copy.free()
