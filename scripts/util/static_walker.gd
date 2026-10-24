class_name StaticWalker
extends CharacterBody3D
## Laufen durch die statische Erdgeschoss-Szene (StaticExport): WASD, Maus, Umschalt rennt, Leertaste springt, Esc gibt
## die Maus frei, ein Klick fängt sie wieder. Eigene Tasten (physisch), nichts vom Spiel.

const SPEED := 3.0
const RUN := 6.0
const JUMP := 4.0
const MOUSE := 0.003
const EYE := 1.6

var _cam: Camera3D


## Kollision und Kamera anlegen (beim Export – danach gehören sie zur Szene).
func build() -> void:
	collision_mask = 1 | 16   # 16: Böden verschlossener Zimmer liegen auf der Ebene der Decken (LevelBuilder.LAYER_CEILING)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.75
	shape.shape = capsule
	shape.position.y = capsule.height / 2.0
	add_child(shape)
	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.position.y = EYE
	cam.fov = 75.0
	add_child(cam)


func _ready() -> void:
	_cam = get_node_or_null("Camera3D")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE)
		_cam.rotation.x = clampf(_cam.rotation.x - event.relative.y * MOUSE, -1.5, 1.5)
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	var dir := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))).normalized()
	var speed := RUN if Input.is_physical_key_pressed(KEY_SHIFT) else SPEED
	var move := (transform.basis * Vector3(dir.x, 0.0, dir.y)) * speed
	velocity.x = move.x
	velocity.z = move.z
	if is_on_floor():
		if Input.is_physical_key_pressed(KEY_SPACE):
			velocity.y = JUMP
	else:
		velocity.y -= float(ProjectSettings.get_setting("physics/3d/default_gravity")) * delta
	move_and_slide()
