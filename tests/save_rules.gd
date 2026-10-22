extends Node
## Feste Vergleichswerte für die Spielstand-Regeln aus CLAUDE.md: Item.Kind nur am Ende erweitern, Zufallsaufrufe in
## GuestGenerator.make()/make_child() nur am Ende (gespeichert wird nur der Seed), jede gespeicherte Gruppe in
## SaveManager.WORLD_GROUPS und beim Laden angewendet.
## Läuft über tests/run.tscn (braucht die Autoloads). Nach einer gewollten Änderung (dann auch VERSION/MIN_VERSION
## erhöhen) die Vergleichswerte neu schreiben: … res://tests/run.tscn -- save_rules --update

const GOLDEN := "res://tests/golden/save_rules.json"
const SEEDS := [1, 2, 3, 17, 4242, 99991]

var _ok := true


func run() -> bool:
	var current := {"kinds": Item.Kind.keys(), "guests": _guests()}
	if "--update" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(GOLDEN.get_base_dir()))
		var file := FileAccess.open(GOLDEN, FileAccess.WRITE)
		file.store_string(JSON.stringify(current, "\t", true))
		file.close()
		print("Vergleichswerte neu geschrieben: %s" % GOLDEN)
		return true
	var golden: Variant = JSON.parse_string(FileAccess.get_file_as_string(GOLDEN))
	if not golden is Dictionary:
		print("Keine Vergleichswerte – erst mit `-- save_rules --update` anlegen (%s)" % GOLDEN)
		return false
	_kinds(golden["kinds"], current["kinds"])
	_profiles(golden["guests"], current["guests"])
	_save_groups()
	print("Spielstand-Regeln: alles richtig" if _ok else "Spielstand-Regeln: FEHLER")
	return _ok


func _check(good: bool, text: String) -> void:
	print(("ok      " if good else "FALSCH  ") + text)
	_ok = _ok and good


## Bisherige Arten behalten Namen und Nummer, neue nur hinten dran.
func _kinds(before: Array, now: Array) -> void:
	var moved: Array = []
	for i in before.size():
		if i >= now.size() or now[i] != before[i]:
			moved.append(before[i])
	_check(moved.is_empty(), "Item.Kind: %d bisherige Arten an ihrem Platz, %d neue%s" % [before.size() - moved.size(),
		now.size() - before.size(), "" if moved.is_empty() else " – verschoben/fehlt: %s" % ", ".join(moved)])


## Jeder bisherige Wert eines erzeugten Gastes bleibt gleich; neue Felder (Zufall hinten angehängt) sind erlaubt.
func _profiles(before: Dictionary, now: Dictionary) -> void:
	for key: String in before:
		var diffs: Array = []
		_diff(before[key], now.get(key), key, diffs)
		_check(diffs.is_empty(), "GuestGenerator %s%s" % [key, "" if diffs.is_empty() else ": " + "; ".join(diffs.slice(0, 4))])


func _diff(a: Variant, b: Variant, path: String, out: Array) -> void:
	if a is Dictionary and b is Dictionary:
		for k: String in a:
			if not (b as Dictionary).has(k):
				out.append("%s.%s fehlt" % [path, k])
			else:
				_diff(a[k], b[k], "%s.%s" % [path, k], out)
	elif JSON.stringify(a) != JSON.stringify(b):
		out.append("%s: %s → %s" % [path, JSON.stringify(a).left(60), JSON.stringify(b).left(60)])


## Wie im Spielstand: über JSON, damit Zahlen und Schlüssel gleich aussehen wie beim Vergleich mit der Datei.
func _guests() -> Dictionary:
	var out := {}
	for gen_seed: int in SEEDS:
		var adult := GuestGenerator.make(gen_seed, "0101")
		out["make_%d" % gen_seed] = adult
		out["child_%d" % gen_seed] = GuestGenerator.make_child(gen_seed + 1, "0101", "gast1", adult)
	return JSON.parse_string(JSON.stringify(out))


## Jede Gruppe, die collect sammelt, steht in WORLD_GROUPS (Fingerabdruck der Welt) und wird in apply angewendet.
func _save_groups() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/autoload/save_manager.gd")
	var world: Array = (load("res://scripts/autoload/save_manager.gd") as Script).get_script_constant_map()["WORLD_GROUPS"]
	var collected := _names(source, "_collect_group\\(\"(\\w+)\"")
	var applied := _names(source, "_apply_group\\(\"(\\w+)\"")
	var outside := collected.filter(func(g: String) -> bool: return not g in world)
	_check(outside.is_empty(), "Gespeicherte Gruppen stehen in WORLD_GROUPS%s" % ("" if outside.is_empty() else
		" – fehlen: " + ", ".join(outside)))
	_check(collected.all(func(g: String) -> bool: return g in applied) and applied.all(func(g: String) -> bool: return g in collected),
		"Jede gespeicherte Gruppe wird geladen und umgekehrt (%d Gruppen)" % collected.size())


func _names(source: String, pattern: String) -> Array:
	var regex := RegEx.create_from_string(pattern)
	var found: Array = []
	for m in regex.search_all(source):
		if not m.get_string(1) in found:
			found.append(m.get_string(1))
	return found
