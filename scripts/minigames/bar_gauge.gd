class_name BarGauge
extends Control
## Balken für die Geschick-Barspiele (Spielkonzept 6.10): Wackelnadel mit ruhiger Mitte (Bierdeckel-Turm,
## Trinkduell) oder Kräftemessen von links nach rechts (Armdrücken). Die Partie setzt value und zone.

var value := 0.0              ## −1..1: Lage der Nadel bzw. des Arms (+1 = du gewinnst)
var zone := 0.25              ## halbe Breite der grünen Mitte (0 = keine, Armdrücken)
var tug := false              ## Kräftemessen: Enden rot (Gast) und grün (du)


func _init() -> void:
	custom_minimum_size = Vector2(120, 24)


func set_value(v: float) -> void:
	value = clampf(v, -1.0, 1.0)
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	var mid := w / 2.0
	draw_rect(Rect2(0, h * 0.3, w, h * 0.4), Color(0.18, 0.13, 0.09))
	if tug:
		draw_rect(Rect2(0, h * 0.3, 8, h * 0.4), Color(0.6, 0.15, 0.1))
		draw_rect(Rect2(w - 8, h * 0.3, 8, h * 0.4), Color(0.2, 0.55, 0.2))
	elif zone > 0.0:
		draw_rect(Rect2(mid - zone * mid, h * 0.3, zone * w, h * 0.4), Color(0.2, 0.5, 0.2))
	var x := mid + value * (mid - 3.0)
	draw_rect(Rect2(x - 2.0, 0, 4.0, h), Color(0.95, 0.85, 0.6))
