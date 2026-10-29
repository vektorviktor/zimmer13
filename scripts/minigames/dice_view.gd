class_name DiceView
extends Control
## Zeichnet zwei oder mehr Würfel (oder einen geschlossenen Becher) – Mäxchen zwei, Schocken drei.

var dice: Array[int] = []
var covered := true


func show_dice(values: Array[int]) -> void:
	dice = values
	covered = false
	queue_redraw()


func hide_dice() -> void:
	covered = true
	queue_redraw()


func _draw() -> void:
	var size_px := 22.0
	var gap := 6.0
	if covered or dice.size() < 2:
		# Umgedrehter Becher
		var cup := Rect2(Vector2(0, 0), Vector2(size_px * maxi(dice.size(), 2) + gap * (maxi(dice.size(), 2) - 1), size_px))
		draw_rect(cup, Color(0.35, 0.18, 0.1))
		draw_rect(Rect2(cup.position, Vector2(cup.size.x, 3)), Color(0.55, 0.32, 0.15))
		return
	for i in dice.size():
		var origin := Vector2(i * (size_px + gap), 0)
		draw_rect(Rect2(origin, Vector2(size_px, size_px)), Color(0.92, 0.9, 0.84))
		for pip in _pips(dice[i]):
			draw_rect(Rect2(origin + pip * size_px - Vector2(2, 2), Vector2(4, 4)), Color(0.1, 0.05, 0.05))


func _pips(n: int) -> Array[Vector2]:
	var c := Vector2(0.5, 0.5)
	var tl := Vector2(0.25, 0.25)
	var tr := Vector2(0.75, 0.25)
	var bl := Vector2(0.25, 0.75)
	var br := Vector2(0.75, 0.75)
	var ml := Vector2(0.25, 0.5)
	var mr := Vector2(0.75, 0.5)
	match n:
		1:
			return [c]
		2:
			return [tl, br]
		3:
			return [tl, c, br]
		4:
			return [tl, tr, bl, br]
		5:
			return [tl, tr, c, bl, br]
	return [tl, tr, ml, mr, bl, br]
