extends Node
## Tastenbelegung (Spielkonzept 8.4, Keys): Tausch bei Doppelbelegung, gesperrte Tasten (F8, feste Belegungen,
## Mausrad), Speichern und Wiederherstellen der Abweichungen, Spieltexte mit der aktuellen Taste. Läuft über
## tests/run.tscn; ändert nur die InputMap und stellt am Ende die Belegung aus dem Profil wieder her.

var _ok := true


func run() -> bool:
	Keys.reset()
	_check(Keys.changed().is_empty(), "nach reset() noch Abweichungen")
	_check(Keys.key_name("interact") == "E", "Standard Interagieren ist %s" % Keys.key_name("interact"))
	_check(Keys.fill("{crouch}") == "Strg / C", "Ducken heißt %s" % Keys.fill("{crouch}"))

	# Doppelbelegung: tauschen, Texte in einem Durchgang umschreiben
	var note := Keys.assign("interact", 0, _key(KEY_G))
	_check(note.contains("Getauscht"), "kein Tauschhinweis: " + note)
	_check(Keys.key_name("interact") == "G" and Keys.key_name("drop") == "E", "Tausch E ↔ G fehlt")
	var text := Keys.localize("Öffnen [E] · ablegen [G] · [Ein Knall] · [1]")
	_check(text == "Öffnen [G] · ablegen [E] · [Ein Knall] · [1]", "localize: " + text)

	# Gespeicherte Abweichungen kommen genauso wieder
	var saved := Keys.changed()
	_check(saved.size() == 2 and saved.has("interact") and saved.has("drop"), "changed(): %s" % saved)
	Keys.reset()
	Keys.apply_saved(saved)
	_check(Keys.key_name("interact") == "G" and Keys.key_name("drop") == "E", "apply_saved stellt nicht wieder her")
	Keys.apply_saved({"interact": ["key:%d" % KEY_F8], "jump": ["unsinn"], "gibtsnicht": ["key:65"]})
	_check(Keys.key_name("interact") == "G" and Keys.key_name("jump") == "Leertaste", "Ungültiges aus dem Profil übernommen")
	Keys.reset()

	# Gesperrt: F8, feste Belegungen (Debug, Menü, Taschenfächer), Mausrad
	for event: InputEvent in [_key(KEY_F8), _key(KEY_F3), _key(KEY_ESCAPE), _key(KEY_1), _mouse(MOUSE_BUTTON_WHEEL_UP)]:
		_check(Keys.assign("jump", 0, event) != "", "%s ließ sich belegen" % Keys.encode(event))
	_check(Keys.key_name("jump") == "Leertaste", "Springen nach gesperrten Tasten: %s" % Keys.key_name("jump"))

	# Leerer Zweitplatz übernimmt die einzige Taste einer anderen Aktion: deutlich warnen
	note = Keys.assign("jump", 1, _key(KEY_E))
	_check(note.contains("keine Taste") and Keys.key_names("interact") == "–", "Warnung fehlt: " + note)
	_check(Keys.key_names("jump") == "Leertaste / E", "Springen: %s" % Keys.key_names("jump"))
	_check(Keys.clear("jump", 0) == "" and Keys.key_names("jump") == "E", "Haupttaste leeren")
	_check(Keys.clear("jump", 0) != "", "letzte Taste ließ sich leeren")
	Keys.reset()

	# Maustasten: Tausch zwischen Benutzen und Luft anhalten, Namen
	Keys.assign("use_item", 0, _mouse(MOUSE_BUTTON_RIGHT))
	_check(Keys.key_name("use_item") == "Rechtsklick" and Keys.key_name("hold_breath") == "Linksklick", "Maustausch")
	_check(Keys.localize("[Linksklick]") == "[Rechtsklick]", "localize Maus: " + Keys.localize("[Linksklick]"))
	Keys.assign("use_item", 0, _mouse(MOUSE_BUTTON_MIDDLE))
	_check(Keys.key_name("use_item") == "Mittelklick" and Keys.key_name("hold_breath") == "Linksklick", "Mittelklick")

	Keys.reset()
	Keys.apply_saved(Settings.key_bindings)
	print("Tastenbelegung: alles richtig" if _ok else "Tastenbelegung: FEHLER")
	return _ok


func _key(code: Key) -> InputEvent:
	return Keys.decode("key:%d" % code)


func _mouse(button: MouseButton) -> InputEvent:
	return Keys.decode("mouse:%d" % button)


func _check(good: bool, text: String) -> void:
	if not good and _ok:
		print("  FEHLER: " + text)
	if not good:
		_ok = false
