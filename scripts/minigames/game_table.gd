class_name GameTable
extends StaticBody3D
## Würfeltisch in der Hotelbar. Gespielt wird nur, wenn der Würfelbecher auf dem
## Tisch liegt (oder du ihn mitbringst) – der Becher ist ein normaler Gegenstand
## und kann weggetragen oder geklaut werden. Gezinkte Würfel stecken im Becher selbst
## (Item.dice_loaded), loaded fragt den Becher am Tisch. Lokale −Z = Platz des Spielers.

const TOP_HEIGHT := 0.76

var busy := false        ## gerade läuft eine Partie
## Gezinkte Würfel im Becher auf dem Tisch bzw. in der Hand des Spielers (setzen: nur, wenn ein Becher da ist)
var loaded: bool:
	get:
		var cup := cup_here()
		return cup != null and cup.dice_loaded
	set(value):
		var cup := cup_here()
		if cup != null:
			cup.dice_loaded = value

var player_seat: Marker3D
var guest_seat: Marker3D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	set_meta("interactable", self)
	add_to_group("game_tables")
	var wood := Mat.psx(Color(0.3, 0.17, 0.09))
	var felt := Mat.psx(Color(0.08, 0.25, 0.12))
	Geo.mesh(self, Geo.cylinder(0.5, 0.05, 12), felt, Vector3(0, TOP_HEIGHT - 0.025, 0))
	Geo.mesh(self, Geo.cylinder(0.53, 0.04, 12), wood, Vector3(0, TOP_HEIGHT - 0.06, 0))
	Geo.mesh(self, Geo.cylinder(0.07, 0.7, 6), wood, Vector3(0, 0.35, 0))
	Geo.add_box_shape(self, Vector3(0.9, TOP_HEIGHT, 0.9), Vector3(0, TOP_HEIGHT / 2.0, 0))
	player_seat = _seat(-0.85)
	guest_seat = _seat(0.85)


func top_center() -> Vector3:
	return global_position + Vector3.UP * TOP_HEIGHT


## Stelle auf dem Tisch für Einsätze: −1 = Spielerseite, +1 = Gastseite, 0 = Pott.
func stake_spot(side: int) -> Vector3:
	return global_transform * Vector3(0.28 if side != 0 else -0.25, TOP_HEIGHT + 0.01, side * 0.22)


func has_cup(player: Player) -> bool:
	return _has_gear(Item.Kind.DICE_CUP, player)


## Der Würfelbecher auf dem Tisch, sonst der in der Hand des Spielers (null = keiner).
func cup_here() -> Item:
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.kind == Item.Kind.DICE_CUP and not item.is_held and item.global_position.distance_to(top_center()) < 0.8:
			return item
	var player := Game.player
	if player != null and player.held_kind() == Item.Kind.DICE_CUP:
		return player.held
	return null


## Liegt das Spielgerät (Würfelbecher, Schachbrett) auf dem Tisch oder in der Hand des Spielers?
## player darf null sein: nur der Tisch.
func _has_gear(kind: Item.Kind, player: Player) -> bool:
	if player != null and player.held_kind() == kind:
		return true
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.kind == kind and not item.is_held and item.global_position.distance_to(top_center()) < 0.8:
			return true
	return false


func get_prompt(player: Player) -> String:
	if player.held_kind() == Item.Kind.LOADED_DICE and cup_here() != null and not loaded:
		return "Gezinkte Würfel in den Becher schmuggeln [E]"
	if busy:
		return "Hier wird gerade gewürfelt …"
	if not has_cup(player):
		return "Würfeltisch – der Würfelbecher fehlt!"
	return "Würfeltisch – lade einen Gast zu Mäxchen ein"


func interact(player: Player) -> void:
	if player.held_kind() == Item.Kind.LOADED_DICE and cup_here() != null:
		cup_here().load_dice(player)


func _seat(z: float) -> Marker3D:
	var seat := Marker3D.new()
	seat.position = Vector3(0, 0, z)
	seat.rotation.y = 0.0 if z < 0.0 else PI   # Blick zum Tisch
	add_child(seat)
	var stool := Geo.mesh(self, Geo.cylinder(0.2, 0.05, 8), Mat.psx(Color(0.4, 0.1, 0.1)), Vector3(0, 0.5, z * 1.05))
	Geo.mesh(stool, Geo.cylinder(0.04, 0.5, 5), Mat.psx(Color(0.2, 0.12, 0.08)), Vector3(0, -0.25, 0))
	return seat
