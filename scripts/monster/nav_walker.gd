class_name NavWalker
extends CharacterBody3D
## Gemeinsame Fortbewegung von Monster und Kürbismann auf dem NavMesh: hinlaufen, anhalten, sich drehen,
## Schwerkraft. Die Unterklasse legt `agent` an.

## Ab diesem Abstand zum nächsten Wegpunkt geht es zum übernächsten (wächst mit der Schrittlänge, siehe _move_to)
const PATH_DISTANCE := 0.3

var agent: NavigationAgent3D

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _last_pos := Vector3.ZERO
var _stuck_time := 0.0


## true = angekommen (im Grundriss 0,7 m, auf demselben Stockwerk).
func _move_to(point: Vector3, speed: float, delta: float) -> bool:
	if agent.target_position.distance_to(point) > 0.25:
		agent.target_position = point
	var near := Vector2(point.x - global_position.x, point.z - global_position.z).length() < 0.7 \
		and absf(point.y - global_position.y) < 1.5
	if near or agent.is_navigation_finished():
		_stop(delta)
		return true
	# Große Schritte (Zeitraffer beim Schlafen, wenige Bilder) springen über den Wegpunkt – ohne größeren Abstand
	# pendelte er dann um ihn herum, ohne je weiterzuschalten
	agent.path_desired_distance = maxf(PATH_DISTANCE, speed * get_physics_process_delta_time() * 1.5)
	var dir := agent.get_next_path_position() - global_position
	dir.y = 0.0
	if dir.length() > 0.01:
		dir = dir.normalized()
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), minf(1.0, 8.0 * delta))
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	_apply_gravity(delta)
	move_and_slide()
	# Festgefahren (z. B. an einer Türkante)? Seitlich ausweichen, Weg neu berechnen.
	if global_position.distance_to(_last_pos) < speed * delta * 0.2:
		_stuck_time += delta
		if _stuck_time > 0.6:
			_stuck_time = 0.0
			global_position += Vector3(-dir.z, 0, dir.x) * (0.15 if randf() < 0.5 else -0.15)
			agent.target_position = point + Vector3(0.01, 0, 0)
	else:
		_stuck_time = 0.0
	_last_pos = global_position
	return false


func _stop(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_apply_gravity(delta)
	move_and_slide()


func _face(pos: Vector3, delta: float) -> void:
	var to := pos - global_position
	if Vector2(to.x, to.z).length() < 0.01:
		return
	rotation.y = lerp_angle(rotation.y, atan2(-to.x, -to.z), minf(1.0, 6.0 * delta))


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta
