class_name PerfLog
extends Node
## Debug (--perf[=s]): schreibt jeden Frame Zeiten und Zählwerte nach temp/perf.csv und beendet das Spiel nach s Sekunden
## (Standard 20). Für Ruckler: Skripte (process/physics, Höchstwert der letzten Sekunde – so meldet Godot sie),
## Navigation, Rendering (CPU/GPU) und Zeichenaufrufe.

var _left := 20.0
var _file: FileAccess
var _vp := RID()


func _init(seconds: float) -> void:
	_left = seconds


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://temp"))
	_file = FileAccess.open("res://temp/perf.csv", FileAccess.WRITE)
	_file.store_line("t;frame_ms;process_ms;physics_ms;nav_ms;cpu_render_ms;gpu_render_ms;draws;objects;prims;nodes")
	_vp = get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(_vp, true)


func _process(delta: float) -> void:
	_left -= delta
	_file.store_line("%.3f;%.1f;%.1f;%.1f;%.1f;%.1f;%.1f;%d;%d;%d;%d" % [
		Time.get_ticks_msec() / 1000.0, delta * 1000.0,
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.TIME_NAVIGATION_PROCESS) * 1000.0,
		RenderingServer.viewport_get_measured_render_time_cpu(_vp),
		RenderingServer.viewport_get_measured_render_time_gpu(_vp),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT)])
	if _left <= 0.0:
		_file.close()
		get_tree().quit()
