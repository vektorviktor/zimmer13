extends Node
## Halt des Aufzugs im Dachgeschoss (Spielkonzept 7.10, ZIM-42) an einem Probe-Aufzug mit vier Halten (U, 0, 1, D) –
## das Hotel hat oben noch keinen Schacht im Plan. Vor dem Freischalten fährt die Kabine nicht hinauf (Knopf „D“,
## Debug-Fahrt, Ruf des Monsters), der erste Ruf von oben schaltet frei und holt sie, danach Fahrt EG → DG; Speichern
## und Laden behalten die Freischaltung. Läuft über tests/run.tscn.

const STEP := 0.1

var _ok := true


func run() -> bool:
	var lift := _probe()
	_check(lift._label(3) == "D" and lift._floor_name(3) == "Dachgeschoss", "Halt oben heißt %s" % lift._label(3))
	_check(not lift.serves(3) and lift.serves(2), "Dachgeschoss vor dem Freischalten schon angefahren")

	# vorher: Knopf „D“ in der Kabine, Debug-Fahrt nach oben, Ruf des Monsters – keiner bringt sie hinauf
	lift.press(_push(lift, Elevator.Do.FLOOR, 3))
	_check(lift._queue.is_empty(), "Knopf „D“ vor dem Freischalten angenommen")
	_check(lift.prompt(_push(lift, Elevator.Do.FLOOR, 3)).contains("rührt sich nicht"), "Hinweis am Knopf „D“ fehlt")
	lift.call_cabin(3)
	_check(lift._queue.is_empty() and not lift.unlocked, "Ruf des Monsters schaltet frei")
	lift.ride_to_top()
	_run(lift)
	_check(lift._at == 2, "Debug-Fahrt nach oben endet an Halt %d statt im 1. OG" % lift._at)

	# Ruf von oben: freigeschaltet, die Kabine kommt
	lift.press(_push(lift, Elevator.Do.CALL, 3))
	_check(lift.unlocked and lift.serves(3), "Ruf von oben schaltet nicht frei")
	_run(lift)
	_check(lift._at == 3, "Kabine nach dem Ruf an Halt %d statt im Dachgeschoss" % lift._at)

	# danach: ins EG und von dort mit Knopf „D“ wieder hinauf
	lift.press(_push(lift, Elevator.Do.FLOOR, 1))
	_run(lift)
	_check(lift._at == 1, "Fahrt DG → EG endet an Halt %d" % lift._at)
	lift.press(_push(lift, Elevator.Do.FLOOR, 3))
	_run(lift)
	_check(lift._at == 3, "Fahrt EG → DG endet an Halt %d" % lift._at)

	# Speichern und Laden: die Freischaltung bleibt, ein alter Stand ohne sie lässt den Halt gesperrt
	var saved := lift.save_state()
	var again := _probe()
	again.load_state(saved)
	_check(again.unlocked and again._at == 3, "nach dem Laden: frei %s, Halt %d" % [again.unlocked, again._at])
	var old := _probe()
	old.load_state({"y": 0.0, "queue": [], "open": false})
	_check(not old.unlocked, "alter Stand ohne „unlocked“ schaltet frei")

	# ohne Dachgeschoss (heutiger Plan): nichts gesperrt, nichts freizuschalten
	var plain := _probe(false)
	plain.unlock()
	_check(plain.serves(3) and not plain.unlocked, "Aufzug ohne Dachgeschoss gesperrt oder freigeschaltet")

	for n in [lift, again, old, plain]:
		n.free()
	print("[Aufzug] Dachgeschoss: %s" % ("alles richtig" if _ok else "FEHLER"))
	return _ok


## Probe-Aufzug weit weg vom Ursprung: Halte U, 0, 1 und (with_attic) das Dachgeschoss oben.
func _probe(with_attic := true) -> Elevator:
	var stops: Array[float] = [-3.5, 0.0, 3.5, 7.0]
	var levels: Array[int] = [-1, 0, 1, 2]
	var attic: Array[bool] = [false, false, false, with_attic]
	var lift := Elevator.new().setup(true, stops, levels, Vector2(2.5, 2.4), Rect2(-1.65, -3.9, 3.3, 3.8), attic)
	lift.position = Vector3(500, 0, 500)
	add_child(lift)
	return lift


func _push(lift: Elevator, action: Elevator.Do, stop: int) -> Elevator.Push:
	var push := Elevator.Push.new()
	push.elevator = lift
	push.action = action
	push.stop = stop
	return push


## Den Aufzug laufen lassen, bis er steht und die Tür wieder zu ist (höchstens zwei Minuten Spielzeit).
func _run(lift: Elevator) -> void:
	for k in 1200:
		lift._physics_process(STEP)
		if not lift.moving() and lift._queue.is_empty() and lift._door <= 0.0 and lift._door_dir == 0 and k > 0:
			return


func _check(ok: bool, what: String) -> void:
	if not ok:
		print("FALSCH  Aufzug: " + what)
		_ok = false
