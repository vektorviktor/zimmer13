class_name PerfLog
extends Node
## Debug (--perf[=s]): schreibt jeden Frame Zeiten und Zählwerte nach temp/perf.csv und beendet das Spiel nach s Sekunden
## (Standard 20). Für Ruckler: Skripte (process/physics, Höchstwert der letzten Sekunde – so meldet Godot sie),
## Navigation, Rendering (CPU/GPU) und Zeichenaufrufe.
## process_ms enthält im Fenster auch Rendern und VSync (Godot misst den ganzen Schritt); reine Skriptzeit des Bildes
## steht in script_ms (alle _process zwischen einer Sonde ganz vorn und diesem Knoten ganz hinten) und
## physics_script_ms (alle _physics_process, längster Physikschritt seit dem letzten Bild). Nicht darin: Aufrufe
## über call_deferred, SceneTreeTimer und Tweens.

const FIRST := -1_000_000_000
const LAST := 1_000_000_000

var _left := 20.0
var _file: FileAccess
var _vp := RID()
var _t0 := 0          # Beginn der _process-Runde (µs)
var _p0 := 0          # Beginn des Physikschritts (µs)
var _phys_us := 0     # längster Physikschritt seit dem letzten Bild


func _init(seconds: float) -> void:
	_left = seconds


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	process_priority = LAST
	process_physics_priority = LAST
	var probe := _Probe.new()
	probe.perf = self
	add_child(probe)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://temp"))
	_file = FileAccess.open("res://temp/perf.csv", FileAccess.WRITE)
	_file.store_line("t;frame_ms;process_ms;physics_ms;nav_ms;cpu_render_ms;gpu_render_ms;draws;objects;prims;nodes;"
			+ "script_ms;physics_script_ms")
	_vp = get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(_vp, true)


func _physics_process(_delta: float) -> void:
	_phys_us = maxi(_phys_us, Time.get_ticks_usec() - _p0)


func _process(delta: float) -> void:
	var script_us := Time.get_ticks_usec() - _t0
	_left -= delta
	_file.store_line("%.3f;%.1f;%.1f;%.1f;%.1f;%.1f;%.1f;%d;%d;%d;%d;%.2f;%.2f" % [
		Time.get_ticks_msec() / 1000.0, delta * 1000.0,
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.TIME_NAVIGATION_PROCESS) * 1000.0,
		RenderingServer.viewport_get_measured_render_time_cpu(_vp),
		RenderingServer.viewport_get_measured_render_time_gpu(_vp),
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		script_us / 1000.0, _phys_us / 1000.0])
	_phys_us = 0
	if _left <= 0.0:
		_file.close()
		get_tree().quit()


## Sonde, die vor allen anderen Knoten an die Reihe kommt und die Startzeit notiert
class _Probe extends Node:
	var perf: PerfLog

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_priority = PerfLog.FIRST
		process_physics_priority = PerfLog.FIRST

	func _process(_delta: float) -> void:
		perf._t0 = Time.get_ticks_usec()

	func _physics_process(_delta: float) -> void:
		perf._p0 = Time.get_ticks_usec()
