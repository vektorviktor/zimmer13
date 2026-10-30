class_name StaticWalker
extends CharacterBody3D
## Laufen durch die statische Erdgeschoss-Szene (StaticExport): WASD, Maus, Umschalt rennt, Leertaste springt, Esc gibt
## die Maus frei, ein Klick fängt sie wieder. Eigene Tasten (physisch), nichts vom Spiel.
## Messlauf (ZIM-122, Startparameter --bench[=pfad] nach --): die Messpunkte der Szene der Reihe nach, je Punkt erst
## einschwingen, dann jedes Bild Zeiten nach pfad (Standard res://temp/bench_godot.csv), am Ende je Punkt eine Zeile
## Übersicht in die Konsole und beenden. Ohne VSync – Auflösung über Godots --resolution, GPU über --gpu-index.

const SPEED := 3.0
const RUN := 6.0
const JUMP := 4.0
const MOUSE := 0.003
const EYE := 1.6
const BENCH_PATH := "res://temp/bench_godot.csv"
## Sekunden je Messpunkt: erst einschwingen (Schatten, Shader), dann messen
const BENCH_WARMUP := 2.0
const BENCH_HOLD := 6.0

var _cam: Camera3D
var _bench: Array[Camera3D] = []
var _bench_index := -1
var _bench_time := 0.0
var _bench_file: FileAccess
var _bench_frames: Array[float] = []
var _bench_gpu: Array[float] = []
var _vp := RID()


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
	for arg in OS.get_cmdline_user_args():
		if arg == "--bench" or arg.begins_with("--bench="):
			_start_bench(arg.trim_prefix("--bench=") if arg.begins_with("--bench=") else BENCH_PATH)


func _start_bench(path: String) -> void:
	var holder := get_parent().get_node_or_null("Messpunkte")
	if holder == null:
		push_error("[bench] keine Messpunkte in der Szene – mit --static-eg neu exportieren")
		get_tree().quit(1)
		return
	for cam: Camera3D in holder.get_children():
		_bench.append(cam)
	set_physics_process(false)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_vp = get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(_vp, true)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	_bench_file = FileAccess.open(path, FileAccess.WRITE)
	_bench_file.store_line("point;frame_ms;cpu_render_ms;gpu_render_ms")
	print("[bench] %s, %s, %s" % [RenderingServer.get_video_adapter_name(), DisplayServer.window_get_size(),
		ProjectSettings.get_setting("rendering/renderer/rendering_method")])
	_next_point()


func _next_point() -> void:
	if _bench_index >= 0:
		_report_point()
	_bench_index += 1
	_bench_time = 0.0
	_bench_frames.clear()
	_bench_gpu.clear()
	if _bench_index >= _bench.size():
		_bench_file.close()
		get_tree().quit()
		return
	_bench[_bench_index].make_current()


func _report_point() -> void:
	var sorted := _bench_frames.duplicate()
	sorted.sort()
	var avg := 0.0
	for f in sorted:
		avg += f
	avg /= maxf(sorted.size(), 1.0)
	var gpu := 0.0
	for g in _bench_gpu:
		gpu += g
	gpu /= maxf(_bench_gpu.size(), 1.0)
	var p99: float = sorted[int(sorted.size() * 0.99)] if not sorted.is_empty() else 0.0
	print("[bench] %-14s Ø %5.1f ms (%3d FPS)  99 %%: %5.1f ms  GPU Ø %5.1f ms  (%d Bilder)" % [
		_bench[_bench_index].name, avg, roundi(1000.0 / maxf(avg, 0.001)), p99, gpu, sorted.size()])


func _process(delta: float) -> void:
	if _bench_index < 0 or _bench_index >= _bench.size():
		return
	_bench_time += delta
	if _bench_time < BENCH_WARMUP:
		return
	var gpu := RenderingServer.viewport_get_measured_render_time_gpu(_vp)
	_bench_frames.append(delta * 1000.0)
	_bench_gpu.append(gpu)
	_bench_file.store_line("%s;%.2f;%.2f;%.2f" % [_bench[_bench_index].name, delta * 1000.0,
		RenderingServer.viewport_get_measured_render_time_cpu(_vp), gpu])
	if _bench_time >= BENCH_WARMUP + BENCH_HOLD:
		_next_point()


func _unhandled_input(event: InputEvent) -> void:
	if not _bench.is_empty():
		return
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
