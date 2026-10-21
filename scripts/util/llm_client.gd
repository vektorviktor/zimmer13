class_name LlmClient
extends Node
## Prototyp: lokales Sprachmodell für Freitext-Gespräche (GuestChat). Startet llama-server aus llama.cpp
## als eigenen Prozess (nur 127.0.0.1) und spricht per HTTP mit ihm. Liegt unter Game (Game.llm) und
## überlebt damit Szenenwechsel – das Modell wird nur einmal geladen.
## Erwartet im Ordner `dir` (Standard ~/llm, sonst --llm=pfad): llama.cpp/llama-server.exe und
## models/*.gguf. Fehlt etwas, bleibt state "off" und das Spiel bietet kein Freitext-Gespräch an.

const PORT := 8137
## Sekunden bis zum Aufgeben beim Laden des Modells
const START_TIMEOUT := 90.0
## Nach so vielen Sekunden ohne Anfrage gibt der Server den Grafikspeicher frei (lädt bei Bedarf neu) –
## auch, falls er nach einem harten Abbruch des Spiels weiterläuft
const IDLE_SLEEP := 600
const MAX_TOKENS := 160
## Zeitlimit einer Antwort; das Aufwärmen darf länger dauern (frischer Server und Spiel auf derselben Grafikkarte: über 60 s)
const ASK_TIMEOUT := 60.0
const WARM_TIMEOUT := 180.0

## Ordner mit llama.cpp/ und models/ – --llm=pfad setzt ihn (main.gd)
static var dir := ""

var state := "off"     ## off, starting, warming (erste Anfrage übersetzt die Shader der Grafikkarte), ready, failed
var model_name := ""
var _pid := -1
var _wait := 0.0
var _poll := 0.0
var _health: HTTPRequest
var _chat: HTTPRequest
var _callback := Callable()
var _sent_at := 0


## Der Client unter Game – beim ersten Aufruf angelegt und gestartet.
static func ensure() -> LlmClient:
	if Game.llm == null:
		Game.llm = LlmClient.new()
		Game.llm.name = "Llm"
		Game.add_child(Game.llm)
		Game.llm.start()
	return Game.llm


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_health = HTTPRequest.new()
	_health.timeout = 2.0
	_health.request_completed.connect(_on_health)
	add_child(_health)
	_chat = HTTPRequest.new()
	_chat.timeout = ASK_TIMEOUT
	_chat.request_completed.connect(_on_chat)
	add_child(_chat)


func is_ready() -> bool:
	return state == "ready"


func busy() -> bool:
	return _callback.is_valid()


## Läuft schon ein Server (z. B. vom letzten Start übrig), wird er übernommen; sonst gestartet.
func start() -> void:
	if state in ["starting", "warming", "ready"]:
		return
	var base := dir if dir != "" else OS.get_environment("USERPROFILE").path_join("llm")
	var exe := base.path_join("llama.cpp/llama-server.exe")
	var model := _find_model(base.path_join("models"))
	if not FileAccess.file_exists(exe) or model == "":
		state = "off"
		print("[LLM] nicht gefunden: %s bzw. models/*.gguf in %s" % [exe, base])
		return
	model_name = model.get_file().get_basename()
	state = "starting"
	_wait = 0.0
	_poll = 0.0
	_health.request(_url("/health"))   # schon da? → _on_health übernimmt ihn
	var args := ["-m", model, "--host", "127.0.0.1", "--port", str(PORT), "-ngl", "99", "-c", "4096",
		"-np", "1", "--no-webui", "--reasoning", "off", "--sleep-idle-seconds", str(IDLE_SLEEP)]
	get_tree().create_timer(0.5).timeout.connect(func() -> void:
		if state == "starting" and _pid < 0:
			_pid = OS.create_process(exe, args)
			print("[LLM] starte llama-server (%s), PID %d" % [model_name, _pid]))


func _find_model(models_dir: String) -> String:
	var files := DirAccess.get_files_at(models_dir) if DirAccess.dir_exists_absolute(models_dir) else PackedStringArray()
	for file in files:
		if file.ends_with(".gguf") and not file.begins_with("mmproj"):
			return models_dir.path_join(file)
	return ""


func _process(delta: float) -> void:
	if state != "starting":
		return
	_wait += delta
	_poll -= delta
	if _wait > START_TIMEOUT:
		state = "failed"
		print("[LLM] Server antwortet nicht – aufgegeben")
	elif _poll <= 0.0 and _health.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		_poll = 0.5
		_health.request(_url("/health"))


## Server antwortet → aufwärmen: Die erste lange Anfrage nach dem Start dauert bis zu einer Minute (Vulkan baut seine
## Shader), danach geht ein Faktenzettel in unter einer Sekunde durch. Darum gleich eine Probeanfrage, solange
## das Spiel noch „lädt …“ anzeigt.
func _on_health(result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	if state != "starting" or result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return
	state = "warming"
	print("[LLM] Server da nach %.1f s%s – wärme auf" % [_wait, "" if _pid >= 0 else " (lief schon)"])
	var filler := "Im Hotel brennt in jedem Flur eine Lampe, und hinter jeder Tür wohnt ein Gast. ".repeat(40)
	var body := {"messages": [{"role": "system", "content": filler}, {"role": "user", "content": "Hallo?"}],
		"max_tokens": 1, "chat_template_kwargs": {"enable_thinking": false}}
	_callback = func(_answer: Dictionary) -> void: pass
	_sent_at = Time.get_ticks_msec()
	_chat.timeout = WARM_TIMEOUT
	_chat.request(_url("/v1/chat/completions"), ["Content-Type: application/json"], HTTPClient.METHOD_POST,
		JSON.stringify(body))


## Chat-Anfrage im OpenAI-Format; `schema` erzwingt die Form der Antwort (JSON).
## callback(Dictionary): die geparste Antwort, dazu "_seconds" und "_tokens_per_s" – {} bei Fehler.
func ask(messages: Array, schema: Dictionary, callback: Callable) -> bool:
	if not is_ready() or busy():
		return false
	var body := {
		"messages": messages, "temperature": 0.7, "top_p": 0.9, "max_tokens": MAX_TOKENS,
		"response_format": {"type": "json_schema", "json_schema": {"name": "antwort", "schema": schema}},
		"chat_template_kwargs": {"enable_thinking": false},
	}
	_chat.timeout = ASK_TIMEOUT
	var error := _chat.request(_url("/v1/chat/completions"), ["Content-Type: application/json"],
		HTTPClient.METHOD_POST, JSON.stringify(body))
	if error != OK:
		return false
	_callback = callback
	_sent_at = Time.get_ticks_msec()   # nur zum Messen der Antwortzeit, nicht für Spielzeit
	return true


func _on_chat(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var callback := _callback
	_callback = Callable()
	if state == "warming":
		# Auch wenn das Aufwärmen scheitert: Der Server läuft, die erste Frage dauert dann eben länger
		state = "ready"
		print("[LLM] bereit (Aufwärmen %.1f s%s)" % [(Time.get_ticks_msec() - _sent_at) / 1000.0,
			"" if result == HTTPRequest.RESULT_SUCCESS and code == 200 else ", ohne Erfolg: result %d, HTTP %d" % [result, code]])
		return
	var answer := {}
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var data = JSON.parse_string(body.get_string_from_utf8())
		if data is Dictionary and not (data.get("choices", []) as Array).is_empty():
			var parsed = JSON.parse_string(String(data["choices"][0]["message"]["content"]))
			if parsed is Dictionary:
				answer = parsed
				answer["_seconds"] = (Time.get_ticks_msec() - _sent_at) / 1000.0
				answer["_tokens_per_s"] = float(data.get("timings", {}).get("predicted_per_second", 0.0))
				answer["_prompt_tokens"] = int(data.get("timings", {}).get("prompt_n", 0))
	else:
		print("[LLM] Fehler: result %d, HTTP %d" % [result, code])
	if callback.is_valid():
		callback.call(answer)


func _url(path: String) -> String:
	return "http://127.0.0.1:%d%s" % [PORT, path]


func _exit_tree() -> void:
	if _pid >= 0:
		OS.kill(_pid)
		_pid = -1
