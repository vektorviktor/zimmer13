class_name GardenBed
extends RefCounted
## Kürbisbeet als Erdwall (Spielkonzept 5.4): je Pflanzenreihe ein gewölbter Wall aus lockerer Erde, um jede Pflanze
## ein Hügel darauf, zu den Enden und Seiten rund auslaufend und am Rand knapp unter dem Rasen. Darauf feine Klumpen
## aus Rauschen. Ein Netz im Raster STEP (gut 100 Dreiecke je Meter Beet) mit Fototextur und eigener Kollision –
## Füße, Gegenstände und das NavMesh liegen auf dem Wall, die Pflanzen stehen auf height(p).

const RIDGE := 0.17                   ## Höhe des Walls ohne Hügel (m)
const HILL := 0.1                     ## so viel höher an jeder Pflanze
const HILL_RADIUS := 0.5              ## Halbmesser eines Hügels entlang der Reihe
const ROUND := 0.55                   ## Länge, über die der Wall an den Enden ausläuft
const SINK := 0.012                   ## so tief liegt der Rand unter dem flachen Boden (kein Spalt zum Rasen)
const CLODS := 0.025                  ## Klumpen ± (m), am Rand weniger
const CLOD_SIZE := 0.22               ## Größe eines Klumpens
const STEP := 0.15                    ## Raster des Netzes
const SEED := 5413

var rect: Rect2                       ## Grundfläche (x, z)
var _plants: PackedFloat32Array       ## x der Pflanzen, Reihe in der Mitte von rect
var _noise := FastNoiseLite.new()


func _init(p_rect: Rect2, plant_xs: Array) -> void:
	rect = p_rect
	_plants = PackedFloat32Array(plant_xs)
	_noise.seed = SEED + int(rect.position.y * 10.0)
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.frequency = 1.0 / CLOD_SIZE
	_noise.fractal_octaves = 2
	_noise.fractal_gain = 0.4


## Höhe der Erde an p (x, z); außerhalb des Beets -SINK.
func height(p: Vector2) -> float:
	var half := rect.size / 2.0
	var c := rect.get_center()
	var across := clampf(absf(p.y - c.y) / half.y, 0.0, 1.0)
	var end := clampf((half.x - absf(p.x - c.x)) / ROUND, 0.0, 1.0)   # 0 am Ende, 1 ab ROUND davor
	# quer: oben breit gewölbt, zum Rand steiler (wie aufgehäufte Erde, die abrutscht)
	var shape := pow(1.0 - across * across, 1.4) * (1.0 - pow(1.0 - end, 2.0))
	var hill := 0.0
	for x in _plants:
		var t := clampf(absf(p.x - x) / HILL_RADIUS, 0.0, 1.0)
		hill = maxf(hill, (cos(t * PI) + 1.0) / 2.0)
	var top := (RIDGE + HILL * hill) * shape
	return top - SINK + CLODS * _noise.get_noise_2dv(p) * minf(shape * 3.0, 1.0)


## Netz und Kollision unter parent bauen.
func build(parent: Node3D, mat: Material) -> StaticBody3D:
	var nx := maxi(2, ceili(rect.size.x / STEP))
	var nz := maxi(2, ceili(rect.size.y / STEP))
	var grid := PackedVector3Array()
	for j in nz + 1:
		for i in nx + 1:
			var p := rect.position + Vector2(rect.size.x * i / nx, rect.size.y * j / nz)
			grid.append(Vector3(p.x, height(p), p.y))
	var tris := PackedVector3Array()
	var normals := PackedVector3Array()
	var w := nx + 1
	for j in nz:
		for i in nx:
			var a := grid[j * w + i]
			var b := grid[j * w + i + 1]
			var c := grid[(j + 1) * w + i + 1]
			var d := grid[(j + 1) * w + i]
			for v in [a, b, c, a, c, d]:
				tris.append(v)
				normals.append(_normal(Vector2(v.x, v.z)))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = tris
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var body := StaticBody3D.new()
	body.name = "Kürbisbeet"
	parent.add_child(body)
	var shape := ConcavePolygonShape3D.new()
	shape.set_faces(tris)
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	body.add_child(mi)
	return body


## Weiche Normale aus der Höhe (Differenzen über einen halben Rasterschritt).
func _normal(p: Vector2) -> Vector3:
	var e := STEP * 0.5
	var dx := height(p + Vector2(e, 0)) - height(p - Vector2(e, 0))
	var dz := height(p + Vector2(0, e)) - height(p - Vector2(0, e))
	return Vector3(-dx, 2.0 * e, -dz).normalized()
