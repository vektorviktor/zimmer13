class_name TableStakes
extends RefCounted
## Einsätze auf einem Spieltisch (Spielkonzept 6.10) – für Mäxchen und Schach gleich. Sie liegen echt auf
## dem Tisch: Münzen im Pott, dein Gegenstand gegen etwas Gleichwertiges aus dem Koffer des Gastes.
## Gewinnst du, gehören sie dir (selbst vom Tisch nehmen); bricht die Partie ab, gehören sie niemandem.

var pot: Item
var player_item: Item
var guest_item: Item
var pot_value := 0


## stake: {"money": int, "item": bool}
func place(table: GameTable, guest: Guest, stake: Dictionary) -> void:
	var world := Game.player.get_parent()
	var money := int(stake.get("money", 0))
	if money > 0:
		Game.money -= money
		guest.money -= money
		pot_value = money * 2
		pot = Item.create(Item.Kind.COINS, str(pot_value))
		pot.owner_id = "stake"
		world.add_child(pot)
		pot.global_position = table.stake_spot(0)
	if stake.get("item", false) and Game.player.held:
		player_item = Game.player.held
		Game.player.drop_held()
		player_item.global_position = table.stake_spot(-1)
		player_item.owner_id = "stake"
		var kind := _counter_stake(guest, player_item.price())
		if kind >= 0:
			guest.stock[kind] = int(guest.stock[kind]) - 1
			guest_item = Item.create(kind)
			guest_item.owner_id = "stake"
			world.add_child(guest_item)
			guest_item.global_position = table.stake_spot(1)


## Kann der Spieler den Gegenstand in seiner Hand setzen? (Schlüssel und Spielgerät nicht)
static func can_stake_item(guest: Guest, gear: Item.Kind) -> bool:
	var held := Game.player.held
	if held == null or held.kind == Item.Kind.KEY or held.kind == gear:
		return false
	for kind in guest.stock:
		if int(guest.stock[kind]) > 0:
			return true
	return false


## Was legt der Gast gegen deinen Gegenstand? Etwas Gleichwertiges aus seinem Koffer.
static func _counter_stake(guest: Guest, value: int) -> int:
	var best := -1
	var best_diff := 999
	for kind in guest.stock:
		if int(guest.stock[kind]) <= 0:
			continue
		var diff := absi(int(Item.PRICES.get(kind, 1)) - value)
		if diff < best_diff:
			best_diff = diff
			best = kind
	return best


## Für die Titelzeile: „6 Geld“, „Kerze“ …
func labels() -> Array[String]:
	var result: Array[String] = []
	if pot_value > 0:
		result.append("%d Geld" % pot_value)
	if is_instance_valid(player_item):
		result.append(player_item.display_name)
	if is_instance_valid(guest_item):
		result.append(guest_item.display_name)
	return result


func any_left() -> bool:
	return is_instance_valid(pot) or is_instance_valid(player_item) or is_instance_valid(guest_item)


func take_for_player() -> void:
	for item in [pot, player_item, guest_item]:
		if is_instance_valid(item):
			item.owner_id = "player"


func give_to_guest(guest: Guest) -> void:
	if is_instance_valid(pot):
		guest.money += pot_value
		pot.queue_free()
	for item in [player_item, guest_item]:
		if is_instance_valid(item):
			guest.stock[item.kind] = int(guest.stock.get(item.kind, 0)) + 1
			item.queue_free()
	pot = null
	player_item = null
	guest_item = null


## Partie abgebrochen: Die Einsätze bleiben liegen und gehören niemandem mehr.
func abandon() -> void:
	for item in [pot, player_item, guest_item]:
		if is_instance_valid(item):
			item.owner_id = ""


## Bei Gleichstand (Remis) bekommt jeder seinen Teil zurück.
func split(guest: Guest) -> void:
	if is_instance_valid(pot):
		Game.money += pot_value >> 1
		guest.money += pot_value >> 1
		pot.queue_free()
	if is_instance_valid(player_item):
		player_item.owner_id = "player"
	if is_instance_valid(guest_item):
		guest.stock[guest_item.kind] = int(guest.stock.get(guest_item.kind, 0)) + 1
		guest_item.queue_free()
	pot = null
	guest_item = null
