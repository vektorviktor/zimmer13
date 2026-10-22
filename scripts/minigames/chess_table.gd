class_name ChessTable
extends GameTable
## Schachtisch in der Lobby (Spielkonzept 6.10). Gespielt wird nur, wenn das Schachbrett auf dem Tisch
## liegt (oder du es mitbringst) – das Brett ist ein normaler Gegenstand wie der Würfelbecher und kann
## weggetragen werden, etwa ins eigene helle Zimmer … dort steht aber kein Tisch.


func has_board(player: Player) -> bool:
	return _has_gear(Item.Kind.CHESS_BOARD, player)


func get_prompt(player: Player) -> String:
	if busy:
		return "Hier wird gerade Schach gespielt …"
	if not has_board(player):
		return "Schachtisch – das Schachbrett fehlt!"
	return "Schachtisch – lade einen Gast zu einer Partie ein"


func interact(_player: Player) -> void:
	pass
