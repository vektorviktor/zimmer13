class_name ChessTable
extends GameTable
## Schachtisch in der Lobby (Spielkonzept 6.10). Gespielt wird nur, wenn das Schachbrett auf dem Tisch
## liegt (oder du es mitbringst) – das Brett ist ein normaler Gegenstand wie der Würfelbecher und kann
## weggetragen werden, etwa ins eigene helle Zimmer … dort steht aber kein Tisch.


func board() -> Item:
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.kind == Item.Kind.CHESS_BOARD and not item.is_held and item.global_position.distance_to(top_center()) < 0.8:
			return item
	return null


func has_board(player: Player) -> bool:
	return board() != null or (player != null and player.held_kind() == Item.Kind.CHESS_BOARD)


func get_prompt(player: Player) -> String:
	if busy:
		return "Hier wird gerade Schach gespielt …"
	if not has_board(player):
		return "Schachtisch – das Schachbrett fehlt!"
	return "Schachtisch – lade einen Gast zu einer Partie ein"


func interact(_player: Player) -> void:
	pass
