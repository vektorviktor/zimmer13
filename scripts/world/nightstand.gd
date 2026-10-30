class_name Nightstand
extends Dresser
## Nachttisch neben dem Bett (30.10.): Kasten aus heller Eiche wie das Balkenbett (BedModel.beam), 0,5 × 0,5 m und so
## hoch wie die Bettpfosten. Deckplatte auf zwei Seitenwänden, die bis zum Boden reichen, dahinter eine Rückwand; oben
## eine Schublade mit bündiger Front ohne Griff, darunter ein offenes Fach ohne Bodenbrett. Die Schublade verhält sich
## wie die der Kommode (Fund beim ersten Öffnen, Spinnen, gespeichert in der Gruppe dressers). Lokale +Z = Vorderseite.

const OUTER := Vector3(0.5, BedModel.POST_TOP, 0.5)
## Stärke von Deckplatte und Seiten, Rückwand, Fachboden unter der Schublade
const BOARD := 0.025
const BACK := 0.012
const SHELF := 0.02
## Höhe der Schubladenöffnung, Fuge rings um die Front, Wandstärke des Schubkastens
const DRAWER_H := 0.16
const GAP := 0.003
const TRAY_WALL := 0.012
const OUT := 0.28
## Erste Nummer der Maserung (BedModel.beam) – die Bretter versetzen sie, damit nicht alle gleich aussehen
const GRAIN_N := 20


func _build() -> void:
	var inner_w := OUTER.x - 2.0 * BOARD
	size = OUTER
	tray = Vector3(inner_w - 2.0 * GAP - 0.01, DRAWER_H - 0.05, OUTER.z - BACK - 0.025 - 0.015)
	slide = OUT
	var n := GRAIN_N
	_board(self, Vector3(OUTER.x, BOARD, OUTER.z), Vector3(0, OUTER.y - BOARD / 2.0, 0), 0, n)
	for side in [-1.0, 1.0]:
		n += 1
		_board(self, Vector3(BOARD, OUTER.y - BOARD, OUTER.z), Vector3(side * (OUTER.x - BOARD) / 2.0, (OUTER.y - BOARD) / 2.0, 0), 1, n)
	_board(self, Vector3(inner_w, OUTER.y - BOARD, BACK), Vector3(0, (OUTER.y - BOARD) / 2.0, (BACK - OUTER.z) / 2.0), 1, n + 1)
	var shelf_top := OUTER.y - BOARD - DRAWER_H
	_board(self, Vector3(inner_w, SHELF, OUTER.z - BACK), Vector3(0, shelf_top - SHELF / 2.0, BACK / 2.0), 0, n + 2)
	# Schublade: Front in der Öffnung, Kasten dahinter (Boden, Rückwand, Seiten), Faser der Front waagerecht
	var drawer := add_drawer(shelf_top + GAP)
	var front_h := DRAWER_H - 2.0 * GAP
	var z_front := OUTER.z / 2.0 - 0.0125
	_board(drawer, Vector3(inner_w - 2.0 * GAP, front_h, 0.025), Vector3(0, front_h / 2.0, z_front), 0, n + 3)
	var tray_z := z_front - 0.0125 - tray.z / 2.0
	_board(drawer, Vector3(tray.x, TRAY_WALL, tray.z), Vector3(0, TRAY_WALL / 2.0, tray_z), 2, n + 4)
	_board(drawer, Vector3(tray.x, tray.y, TRAY_WALL), Vector3(0, tray.y / 2.0, tray_z - (tray.z - TRAY_WALL) / 2.0), 0, n + 5)
	for side in [-1.0, 1.0]:
		_board(drawer, Vector3(TRAY_WALL, tray.y, tray.z), Vector3(side * (tray.x - TRAY_WALL) / 2.0, tray.y / 2.0, tray_z), 2, n + 6)


## Brett mit Maserung (wie die Balken des Betts) und gleich großer Kollisionsform.
func _board(body: CollisionObject3D, dims: Vector3, pos: Vector3, grain: int, n: int) -> void:
	BedModel.beam(body, dims, pos, grain, n)
	Geo.add_box_shape(body, dims, pos)
