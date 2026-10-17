class_name TraceMark
extends StaticBody3D
## Eine bleibende Spur des Monsters (Spielkonzept 4.13): Kratzspuren, Blut, Handabdruck.
## Lokale +Z zeigt von der Fläche weg (zum Betrachter). Spuren rund um Zimmer 13
## kann der Spieler wegwischen.

const WIPE_RANGE := 4.5   ## so nah an der Tür von Zimmer 13 darf man putzen
const NAMES := {"scratch": "Kratzspuren", "blood": "Blutspuren", "handprint": "Ein Handabdruck",
	"wax": "Wachsflecken", "drops": "Blutstropfen",
	"bloody_hand": "Blutige Handabdrücke"}

var kind := "scratch"
## Auf Türen nicht anklickbar (sonst ließe sich die Tür nicht mehr öffnen) – bleibt dort.
var solid := true


func setup(p_kind: String) -> TraceMark:
	kind = p_kind
	return self


func _ready() -> void:
	collision_layer = 4 if solid else 0
	collision_mask = 0
	if solid:
		set_meta("interactable", self)
	add_to_group("trace_marks")
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(get_instance_id()))
	match kind:
		"scratch":
			var dark := Mat.psx(Color(0.06, 0.03, 0.02))
			for i in 4:
				var line := Geo.mesh(self, Geo.box(Vector3(0.025, 0.55, 0.006)), dark, Vector3(-0.09 + i * 0.06, -i * 0.02, 0.004))
				line.rotation.z = 0.25 + rng.randf_range(-0.05, 0.05)
			Geo.add_box_shape(self, Vector3(0.35, 0.6, 0.05), Vector3.ZERO)
		"blood":
			var red := Mat.psx(Color(0.22, 0.02, 0.02))
			# Lache aus überlappenden Flecken (~1 m)
			for i in 6:
				var pool := Geo.mesh(self, Geo.box(Vector3(rng.randf_range(0.3, 0.55), rng.randf_range(0.25, 0.5), 0.006)), red,
					Vector3(rng.randf_range(-0.25, 0.25), rng.randf_range(-0.25, 0.25), 0.003))
				pool.rotation.z = rng.randf() * TAU
			# Spritzer drumherum
			for i in 12:
				var a := rng.randf() * TAU
				var r := rng.randf_range(0.5, 1.1)
				var s := rng.randf_range(0.04, 0.16)
				var splat := Geo.mesh(self, Geo.box(Vector3(s, s * rng.randf_range(0.5, 2.5), 0.006)), red,
					Vector3(cos(a) * r, sin(a) * r, 0.003))
				splat.rotation.z = a
			# Schleifspur: breit, mit Lücken, wird schmaler
			for i in 7:
				var w := lerpf(0.34, 0.12, i / 6.0) * rng.randf_range(0.8, 1.1)
				var seg := Geo.mesh(self, Geo.box(Vector3(w, rng.randf_range(0.2, 0.32), 0.005)), red,
					Vector3(0.05 + rng.randf_range(-0.05, 0.05), -0.65 - i * 0.3, 0.0025))
				seg.rotation.z = rng.randf_range(-0.12, 0.12)
			Geo.add_box_shape(self, Vector3(1.6, 1.6, 0.05), Vector3.ZERO)
		"bloody_hand":
			# Lange Finger, verschmiert, mit Läufern nach unten (Lakengeist, 4.18)
			var blood := Mat.psx(Color(0.35, 0.03, 0.03))
			Geo.mesh(self, Geo.box(Vector3(0.1, 0.11, 0.003)), blood, Vector3(0, -0.04, 0))
			for i in 5:
				var finger := Geo.mesh(self, Geo.box(Vector3(0.018, rng.randf_range(0.11, 0.17), 0.003)), blood,
					Vector3(-0.045 + i * 0.022, 0.07 + rng.randf_range(-0.01, 0.02), 0))
				finger.rotation.z = (i - 2) * 0.12 if i > 0 else 0.7
			for i in 3:
				Geo.mesh(self, Geo.box(Vector3(0.008, rng.randf_range(0.08, 0.25), 0.003)), blood,
					Vector3(rng.randf_range(-0.04, 0.04), -0.15 - rng.randf_range(0.0, 0.08), 0))
		"handprint":
			var smudge := Mat.psx(Color(0.12, 0.07, 0.06))
			Geo.mesh(self, Geo.box(Vector3(0.09, 0.1, 0.004)), smudge, Vector3(0, -0.02, 0.002))
			for i in 4:
				var finger := Geo.mesh(self, Geo.box(Vector3(0.018, 0.07, 0.004)), smudge, Vector3(-0.033 + i * 0.022, 0.065, 0.002))
				finger.rotation.z = (i - 1.5) * 0.08
			var thumb := Geo.mesh(self, Geo.box(Vector3(0.02, 0.06, 0.004)), smudge, Vector3(0.06, -0.01, 0.002))
			thumb.rotation.z = -0.7
			Geo.add_box_shape(self, Vector3(0.18, 0.2, 0.05), Vector3.ZERO)
		"wax":
			# Spur eines Gastes: getropftes Kerzenwachs
			var wax := Mat.psx(Color(0.9, 0.85, 0.7))
			for i in rng.randi_range(2, 4):
				Geo.mesh(self, Geo.box(Vector3(rng.randf_range(0.02, 0.05), rng.randf_range(0.02, 0.05), 0.005)), wax,
					Vector3(rng.randf_range(-0.08, 0.08), rng.randf_range(-0.08, 0.08), 0.0025))
			Geo.add_box_shape(self, Vector3(0.25, 0.25, 0.04), Vector3.ZERO)
		"drops":
			# Spur eines verletzten Gastes: einzelne Blutstropfen
			var red := Mat.psx(Color(0.3, 0.02, 0.02))
			for i in rng.randi_range(2, 5):
				var s := rng.randf_range(0.015, 0.035)
				Geo.mesh(self, Geo.box(Vector3(s, s, 0.005)), red, Vector3(rng.randf_range(-0.1, 0.1), rng.randf_range(-0.1, 0.1), 0.0025))
			Geo.add_box_shape(self, Vector3(0.25, 0.25, 0.04), Vector3.ZERO)


func can_wipe() -> bool:
	return Game.director != null and global_position.distance_to(Game.director.player_door_front) < WIPE_RANGE \
		or (Game.director != null and Game.director.zone_name_at(global_position) == "Zimmer 13")


func get_prompt(_player: Player) -> String:
	var label: String = NAMES.get(kind, "Eine Spur")
	return "%s – wegwischen [E]" % label if can_wipe() else label


func interact(_player: Player) -> void:
	if not can_wipe():
		return
	remove_from_group("trace_marks")
	set_meta("interactable", null)
	collision_layer = 0
	Game.noise("wipe", global_position, Game.player)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3(1, 1, 0.01) * 0.2, 0.6)
	tw.tween_callback(queue_free)
