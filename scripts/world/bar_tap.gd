class_name BarTap
extends StaticBody3D
## Flasche und Glas auf der Bartheke: etwas trinken (Spielkonzept 3.7). Ein Glas kostet PRICE Geld, nimmt
## etwas Schock und macht betrunken. Die Stufen des Rauschs gelten für Spieler und Gäste: Rausch steigt je
## Glas um DRINK und baut sich mit der Spielzeit ab (voller Rausch in SOBER_TIME Sekunden).

const PRICE := 1
const DRINK := 0.3            ## Rausch je Glas
const SOBER_TIME := 300.0     ## so viele Spielsekunden, bis voller Rausch (1,0) abgebaut ist
const TIPSY := 0.35           ## angetrunken (ab dem 2. Glas): schwankt, stolpert, zittert beim Bluffen
const DRUNK := 0.7            ## betrunken (ab dem 3. Glas): Halluzinationen
const ENOUGH := 0.9           ## mehr geht nicht – weder beim Spieler noch beim Gast
const CALM := 0.15            ## so viel Schock nimmt ein Glas (Gäste: ×100 Angst)


## Wie stark man schwankt (0..1): ab TIPSY, voll bei 1,0.
static func sway(drunk: float) -> float:
	return clampf((drunk - TIPSY) / (1.0 - TIPSY), 0.0, 1.0)


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	set_meta("interactable", self)
	Geo.mesh(self, Geo.cylinder(0.04, 0.24, 8), Mat.psx(Color(0.12, 0.24, 0.12)), Vector3(-0.08, 0.12, 0))
	Geo.mesh(self, Geo.cylinder(0.015, 0.08, 6), Mat.psx(Color(0.12, 0.24, 0.12)), Vector3(-0.08, 0.28, 0))
	Geo.mesh(self, Geo.cylinder(0.035, 0.1, 8), Mat.psx(Color(0.62, 0.42, 0.16)), Vector3(0.09, 0.05, 0))
	Geo.add_box_shape(self, Vector3(0.32, 0.32, 0.16), Vector3(0, 0.16, 0))


func get_prompt(player: Player) -> String:
	if player.drunk >= ENOUGH:
		return "Du hast genug"
	return "Etwas trinken – %d Geld [E]" % PRICE + ("" if Game.money >= PRICE else " (kein Geld)")


func get_icon(_player: Player) -> String:
	return "alcohol"


func interact(player: Player) -> void:
	if player.drunk >= ENOUGH:
		Game.say("Noch eins, und ich falle um.", 2.5)
	elif Game.money < PRICE:
		Game.say("Ohne Geld kein Glas.", 2.5)
	else:
		Game.money -= PRICE
		player.drink()
