extends Node
## Werfen (Spielkonzept 3.13) ohne Hotel: Abwurftempo nach Masse und Kraft, der lange Spritzer im Zusatzfeld des
## Kürbismatschs (lesen, schreiben, ältere Stände ohne ihn). Läuft über tests/run.tscn (braucht die Autoloads).

var _ok := true


func run() -> bool:
	_speeds()
	_streak_extra()
	print("Werfen: alles richtig" if _ok else "Werfen: FEHLER")
	return _ok


func _check(good: bool, text: String) -> void:
	print(("ok      " if good else "FALSCH  ") + text)
	_ok = _ok and good


## Schweres fliegt langsamer, den Riesenkürbis schubst man nur weg, Leichtes ist gedeckelt; mehr Kraft, mehr Tempo.
func _speeds() -> void:
	var pumpkin := Player.throw_speed(4.0, 1.0)
	var giant := Player.throw_speed(60.0, 1.0)
	var candle := Player.throw_speed(0.2, 1.0)
	_check(pumpkin > 4.0 and pumpkin < 8.0, "Kürbis voll geworfen: %.1f m/s (4 … 8)" % pumpkin)
	_check(giant < 2.0, "Riesenkürbis nur weggeschubst: %.1f m/s" % giant)
	_check(is_equal_approx(candle, Player.THROW_MAX), "Kerze gedeckelt auf %.1f m/s" % candle)
	var weak := Player.throw_speed(4.0, 0.0)
	_check(is_equal_approx(weak, pumpkin * Player.THROW_WEAK) and weak < Player.throw_speed(4.0, 0.5),
		"wenig Kraft: %.1f m/s, mehr Kraft schneller" % weak)


## „s=Drehung:Länge“ im Zusatzfeld: wird gelesen, wieder geschrieben, gedeckelt; ohne das Feld kein langer Spritzer.
func _streak_extra() -> void:
	var mush := Item.create(Item.Kind.PUMPKIN_MUSH, Item.mush_extra("halloween", 10.0, 0.9, 1) + ",s=0.500:1.20")
	_check(is_equal_approx(mush.streak_yaw, 0.5) and is_equal_approx(mush.streak_len, 1.2),
		"langer Spritzer gelesen (%.2f, %.2f m)" % [mush.streak_yaw, mush.streak_len])
	_check(mush.create_extra().contains("s=0.500:1.20") and is_equal_approx(mush.mush_size, 0.9),
		"und wieder geschrieben: %s" % mush.create_extra())
	mush.free()
	var long := Item.create(Item.Kind.PUMPKIN_MUSH, Item.mush_extra("halloween", 10.0, 0.9, 1) + ",s=1.0:99")
	_check(is_equal_approx(long.streak_len, Item.STREAK_MAX), "zu lang wird gedeckelt (%.1f m)" % long.streak_len)
	long.free()
	var old := Item.create(Item.Kind.PUMPKIN_MUSH, Item.mush_extra("halloween", 10.0, 0.9, 1))
	_check(old.streak_len == 0.0 and not old.create_extra().contains("s="), "ohne Feld kein langer Spritzer")
	old.free()
