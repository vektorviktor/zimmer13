extends Node
## Tasche für Kleines (Spielkonzept 3.2) ohne Hotel: einstecken, [Q] halten und wählen (Gehaltenes fällt zu Boden),
## abbrechen, volle Tasche, große Dinge und brennende Kerzen, Verbrauchen aus der Tasche. Läuft über tests/run.tscn
## (braucht die Autoloads).

var _ok := true
var _player: Player


func run() -> bool:
	_player = Player.new()
	add_child(_player)
	_player.process_mode = Node.PROCESS_MODE_DISABLED   # nur die Tasche, keine Bewegung, Sicht, Ausdauer
	_pick_and_stow()
	_choose()
	_full_bag()
	_blocked_hands()
	_consume()
	_player.queue_free()
	print("Tasche: alles richtig" if _ok else "Tasche: FEHLER")
	return _ok


func _check(good: bool, text: String) -> void:
	print(("ok      " if good else "FALSCH  ") + text)
	_ok = _ok and good


func _make(kind: Item.Kind, extra: String = "") -> Item:
	var item := Item.create(kind, extra)
	add_child(item)
	return item


func _names() -> String:
	return ", ".join(_player.bag.map(func(i: Item) -> String: return i.display_name))


func _empty_hands() -> void:
	_player.set_bag([])
	if _player.held:
		_player.consume_held()


## Wie [Q] halten, Fach `slot` wählen (−1 = keins) und loslassen
func _menu(slot: int, choose: bool = true) -> void:
	_player.open_bag()
	_player.bag_sel = slot
	_player.close_bag(choose)


## Kleines mit leerer Hand in die Hand, mit voller Hand gleich in die Tasche; ein leeres Fach steckt die Hand ein.
func _pick_and_stow() -> void:
	_empty_hands()
	var sweets := _make(Item.Kind.SWEETS)
	_player.try_pick_up(sweets)
	_check(_player.held == sweets and _player.bag.is_empty(), "Süßigkeiten mit leerer Hand: in der Hand")
	var can := _make(Item.Kind.SODA_CAN, "cola")
	_player.try_pick_up(can)
	_check(_player.held == sweets and _player.bag == [can], "Dose mit voller Hand: in die Tasche (%s)" % _names())
	_check(not can.visible and not can.is_in_group("items") and not can.has_meta("interactable"),
		"in der Tasche: unsichtbar, nicht in der Welt (Gruppe items, Interaktion)")
	_menu(4)
	_check(_player.held == null and _player.bag == [can, sweets], "leeres Fach gewählt: Süßigkeiten aus der Hand ans Ende (%s)" % _names())


## Loslassen nimmt das gewählte Fach in die Hand, was die Hand hielt, fällt zu Boden; ohne Wahl oder abgebrochen nichts.
func _choose() -> void:
	_empty_hands()
	var a := _make(Item.Kind.SWEETS)
	var b := _make(Item.Kind.BATTERY)
	var c := _make(Item.Kind.MINI_PUMPKIN)
	for item in [a, b, c]:
		_player.bag_add(item)
	_menu(1)
	_check(_player.held == b and _player.bag == [a, c], "Fach 2 mit leerer Hand: Batterie in die Hand")
	_check(b.visible and b.is_in_group("items") and b.is_held and not _player.bag_open, "aus der Tasche: wieder sichtbar und in der Welt")
	_menu(0)
	_check(_player.held == a and _player.bag == [c] and not b.is_held and not b.in_bag and b.is_in_group("items"),
		"Fach 1 mit Batterie in der Hand: Batterie fällt zu Boden (%s)" % _names())
	_menu(-1)
	_check(_player.held == a and _player.bag == [c], "nichts gewählt: Loslassen ändert nichts")
	_menu(0, false)
	_check(_player.held == a and _player.bag == [c], "abgebrochen (Rechtsklick): nichts")
	_player.take_from_bag(0)
	_check(_player.held == c and _player.bag.is_empty() and not a.is_held, "[1] ohne Tasche: gleich in die Hand, Süßigkeiten fallen")


## Hand und Tasche voll: Das Kleine bleibt liegen bzw. landet vor einem.
func _full_bag() -> void:
	_empty_hands()
	for i in Player.BAG_SLOTS:
		_player.bag_add(_make(Item.Kind.SWEETS))
	_player.try_pick_up(_make(Item.Kind.KNIFE))
	var extra := _make(Item.Kind.BATTERY)
	_player.try_pick_up(extra)
	_check(_player.bag.size() == Player.BAG_SLOTS and _player.held_kind() == Item.Kind.KNIFE and not extra.in_bag and not extra.is_held,
		"Hand und Tasche voll: Batterie bleibt liegen")
	_check(not _player.can_take(Item.Kind.BATTERY), "can_take: kein Platz mehr")


## Große Dinge brauchen beide Hände: nichts hinein, beim Herausnehmen fallen sie; Brennendes und Großes passt nicht hinein.
func _blocked_hands() -> void:
	_empty_hands()
	_player.bag_add(_make(Item.Kind.SWEETS))
	var pumpkin := _make(Item.Kind.CARVED_PUMPKIN)
	_player.try_pick_up(pumpkin)
	_check(_player.held == pumpkin and _player.hands_blocked(), "Kürbislaterne braucht beide Hände")
	_check(not _player.bag_takes(_make(Item.Kind.SODA_CAN)), "mit vollen Händen nichts hinein")
	_menu(3)
	_check(_player.held == pumpkin, "leeres Fach: Kürbis passt nicht in die Tasche")
	_menu(0)
	_check(_player.held_kind() == Item.Kind.SWEETS and not pumpkin.is_held and _player.bag.is_empty(),
		"Fach 1 mit Kürbislaterne: die Laterne wird abgestellt, Süßigkeiten in der Hand")
	_player.consume_held()
	var candle := _make(Item.Kind.CANDLE)
	_check(not candle.lit and candle.fits_pocket(), "neue Kerze brennt nicht und passt hinein (Spielkonzept 5.12)")
	candle.light_up(false)
	_check(candle.lit and not candle.fits_pocket(), "brennende Kerze passt nicht hinein")
	candle._extinguish()
	_check(candle.fits_pocket(), "ausgegangene Kerze passt hinein")
	var lamp := _make(Item.Kind.FLASHLIGHT)
	_player.try_pick_up(lamp)
	_check(_player.can_take(Item.Kind.CANDLE) and _player.can_take(Item.Kind.BULB),
		"Kerze aus dem Vorrat (aus) und Glühbirne auch in die Tasche")
	var can := _make(Item.Kind.SODA_CAN)
	_player.try_pick_up(can)
	_check(can.in_bag, "Taschenlampe in der Hand: Kleines trotzdem einstecken")
	_menu(0)
	_check(_player.held == can and not lamp.is_held, "Dose gewählt: Taschenlampe fällt zu Boden")


## Süßes oder Saures und Handel: Verbrauchen und Weggeben gehen auch aus der Tasche.
func _consume() -> void:
	_empty_hands()
	_player.try_pick_up(_make(Item.Kind.KNIFE))
	var sweets := _make(Item.Kind.SWEETS)
	_player.bag_add(sweets)
	_check(_player.consume_kind(Item.Kind.SWEETS) and _player.bag.is_empty() and _player.held_kind() == Item.Kind.KNIFE,
		"Süßigkeiten aus der Tasche verschenkt, Messer bleibt in der Hand")
	_check(not _player.consume_kind(Item.Kind.SWEETS), "keine Süßigkeiten mehr")
	var can := _make(Item.Kind.SODA_CAN)
	_player.bag_add(can)
	var given := _player.give_away(can)
	_check(given == can and _player.bag.is_empty() and can.is_in_group("items"), "Dose aus der Tasche weggeben")
	given.queue_free()
