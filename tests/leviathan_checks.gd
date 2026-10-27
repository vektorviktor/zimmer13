extends Node
## Der Name Leviathan (Spielkonzept 4.32): Jeder Satz in LeviathanName.RENAMED muss wörtlich bei den Gäste-Sätzen
## stehen – sonst bliebe der Wechsel von „es“ zu „der Leviathan“ nach einer Textänderung stillschweigend aus.
## Läuft über tests/run.tscn.

const SOURCES := ["res://scripts/guests/guest_generator.gd", "res://scripts/guests/guest_profiles.gd"]

var _ok := true


func run() -> bool:
	var pool := ""
	for path in SOURCES:
		pool += FileAccess.get_file_as_string(path)
	for before: String in LeviathanName.RENAMED:
		var after := String(LeviathanName.RENAMED[before])
		_check(pool.contains("\"%s\"" % before), "Satz steht bei den Gästen: %s" % before)
		_check(after.contains("Leviathan"), "Ersatz nennt den Namen: %s" % after)
		_check(before.count("{") == after.count("{"), "Platzhalter gleich: %s" % after)
	print("Leviathan-Sätze: alles richtig" if _ok else "Leviathan-Sätze: FEHLER")
	return _ok


func _check(good: bool, text: String) -> void:
	if not good:
		_ok = false
		print("  FEHLER: " + text)
