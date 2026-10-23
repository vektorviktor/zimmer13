extends Node
## Führt die Tests aus, die Klassen des Spiels brauchen – die hängen an den Autoloads (Game, Settings …), die Godot
## mit `-s` nicht lädt; darum als Szene. Jeder Test ist ein Node mit `run() -> bool`.
## Aufruf: Godot --headless --path . res://tests/run.tscn [-- math_checks save_rules] (ohne Namen: alle)

const TESTS := ["math_checks", "save_rules", "bag_checks", "notebook_checks"]


func _ready() -> void:
	await get_tree().process_frame
	var names: Array = Array(OS.get_cmdline_user_args()).filter(func(a: String) -> bool: return not a.begins_with("--"))
	if names.is_empty():
		names = TESTS
	var ok := true
	for test_name: String in names:
		var test: Node = (load("res://tests/%s.gd" % test_name) as Script).new()
		add_child(test)
		ok = await test.run() and ok
		test.queue_free()
	print("Tests: alles richtig" if ok else "Tests: FEHLER")
	get_tree().quit(0 if ok else 1)
