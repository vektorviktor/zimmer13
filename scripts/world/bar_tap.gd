class_name BarTap
extends StaticBody3D
## Flasche und Glas auf der Bartheke: etwas trinken (Spielkonzept 3.7). Drei nebeneinander, je eine Sorte (SORTS,
## ZIM-35): Bier, Rotwein und Schnaps (Korn). Mit freien Händen kauft man ein Glas (Item.Kind.GLASS, Sorte im
## Zusatz) – trinken mit Linksklick oder verschenken –, mit vollen trinkt man es gleich an der Theke. Ein Glas nimmt
## etwas Schock und macht betrunken. Die Stufen des Rauschs gelten für Spieler und Gäste: Rausch steigt je Glas um
## die Stärke der Sorte (ohne Sorte DRINK – Runde ausgeben, Trinkduell, Wahrheit oder Pflicht) und baut sich mit der
## Spielzeit ab (voller Rausch in SOBER_TIME Sekunden).

const PRICE := 1
const DRINK := 0.3            ## Rausch je Glas ohne Sorte (wie Rotwein)
const SOBER_TIME := 300.0     ## so viele Spielsekunden, bis voller Rausch (1,0) abgebaut ist
const TIPSY := 0.35           ## angetrunken (ab dem 2. Glas): schwankt, stolpert, zittert beim Bluffen
const DRUNK := 0.7            ## betrunken (ab dem 3. Glas): Halluzinationen
const ENOUGH := 0.9           ## mehr geht nicht – weder beim Spieler noch beim Gast
const CALM := 0.15            ## so viel Schock nimmt ein Glas ohne Sorte (Gäste: ×100 Angst)
## Sorten (ZIM-35, Entscheidung 3.11.): Name, Name des Glases, Preis, Rausch je Glas, Schock weniger. Bier: angetrunken
## ab dem 2., betrunken ab dem 4.; Rotwein wie bisher (2./3.); Schnaps am stärksten – angetrunken schon nach einem,
## betrunken nach dem 2., dann ist Schluss.
const SORTS := {
	"bier": {"name": "Bier", "glass": "Glas Bier", "price": 1, "drink": 0.2, "calm": 0.1},
	"wein": {"name": "Rotwein", "glass": "Glas Rotwein", "price": 2, "drink": 0.3, "calm": 0.15},
	"schnaps": {"name": "Schnaps", "glass": "Glas Schnaps", "price": 2, "drink": 0.45, "calm": 0.2},
}
## Reihenfolge auf der Theke
const ORDER := ["bier", "wein", "schnaps"]
## Rotwein ist für jeden WINE_SHARE-ten Erwachsenen ein Lieblingsgeschenk (aus der ID, likes_wine)
const WINE_SHARE := 3

var sort := "wein"


## Wie stark man schwankt (0..1): ab TIPSY, voll bei 1,0.
static func sway(drunk: float) -> float:
	return clampf((drunk - TIPSY) / (1.0 - TIPSY), 0.0, 1.0)


## Rausch je Glas dieser Sorte („“: ein Glas ohne Sorte)
static func strength(p_sort: String) -> float:
	return float(SORTS[p_sort]["drink"]) if SORTS.has(p_sort) else DRINK


## So viel Schock nimmt ein Glas dieser Sorte (Gäste: ×100 Angst)
static func calm(p_sort: String) -> float:
	return float(SORTS[p_sort]["calm"]) if SORTS.has(p_sort) else CALM


static func price_of(p_sort: String) -> int:
	return int(SORTS[p_sort]["price"]) if SORTS.has(p_sort) else PRICE


## Rotwein als Lieblingsgeschenk (ZIM-35): fest aus der ID, ohne Zufall im Generator – Kinder nie.
static func likes_wine(guest: Guest) -> bool:
	return not guest.is_child() and absi(hash(guest.id + "|wein")) % WINE_SHARE == 0


## Was er an der Bar trinkt und sich bringen lässt: Weinfreunde Rotwein, sonst meist Bier, manche Schnaps (aus der ID).
static func favorite_of(guest: Guest) -> String:
	if likes_wine(guest):
		return "wein"
	return ["bier", "bier", "schnaps"][absi(hash(guest.id + "|glas")) % 3]


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	set_meta("interactable", self)
	add_to_group("bar_taps")
	BarDrinks.bottle(self, sort, Vector3(-0.045, 0, 0))
	BarDrinks.glass(self, sort, Vector3(0.05, 0, 0.01))
	Geo.add_box_shape(self, Vector3(0.18, 0.3, 0.1), Vector3(0, 0.15, 0))


func get_prompt(player: Player) -> String:
	var price := price_of(sort)
	var cost := " – %d Geld [E]" % price + ("" if Game.money >= price else " (kein Geld)")
	if player.can_take(Item.Kind.GLASS):
		return "%s kaufen" % String(SORTS[sort]["glass"]) + cost
	if player.drunk >= ENOUGH:
		return "Du hast genug"
	return "%s trinken" % String(SORTS[sort]["name"]) + cost


func get_icon(_player: Player) -> String:
	return "alcohol"


func interact(player: Player) -> void:
	var price := price_of(sort)
	var take := player.can_take(Item.Kind.GLASS)
	if not take and player.drunk >= ENOUGH:
		Game.say("Noch eins, und ich falle um.", 2.5)
	elif Game.money < price:
		Game.say("Ohne Geld kein Glas.", 2.5)
	else:
		Game.money -= price
		if take:
			player.receive_item(Item.create(Item.Kind.GLASS, sort))
		else:
			player.drink(false, sort)
