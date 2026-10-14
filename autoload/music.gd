extends Node
## Musica + SFX, con sincronizzazione ritmica.
##
## Segnali:
##   beat(index)   ogni battito (index cumulativo dall'inizio del brano)
##   bar(index)    ogni battuta
##   cue(name)     eventi nominati definiti in data/music.json ("cues": {battito: nome})
## I livelli e le cutscene li usano per far saltare i nemici, pulsare l'HUD,
## attivare la "follia" del capitolo 3, ecc.

signal beat(index: int)
signal bar(index: int)
signal cue(name: String)

const SFX_DIR := "res://assets/audio/sfx/"

var tracks: Dictionary = {}
var current_id := ""
var current: Dictionary = {}
var music_volume := 0.75
var sfx_volume := 1.0

var _player: AudioStreamPlayer
var _sfx: Array[AudioStreamPlayer] = []
var _sfx_cache: Dictionary = {}
var _last_beat := -1
var _loops := 0
var _last_pos := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	add_child(_player)
	_player.finished.connect(_on_finished)
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx.append(p)
	var f := FileAccess.open("res://data/music.json", FileAccess.READ)
	if f:
		var data = JSON.parse_string(f.get_as_text())
		if data is Dictionary:
			tracks = data


func set_volumes(music: float, sfx: float) -> void:
	music_volume = music
	sfx_volume = sfx
	if _player:
		_player.volume_db = _lin_db(music_volume)


func _lin_db(v: float) -> float:
	return -80.0 if v <= 0.001 else linear_to_db(v)


func play(id: String, restart := false) -> void:
	if id == current_id and _player.playing and not restart:
		return
	if not tracks.has(id):
		push_warning("Brano sconosciuto: %s" % id)
		return
	current_id = id
	current = tracks[id]
	_player.stream = load(current.file)
	_player.volume_db = _lin_db(music_volume)
	_player.play()
	_last_beat = -1
	_loops = 0
	_last_pos = 0.0


func stop() -> void:
	_player.stop()
	current_id = ""


func _on_finished() -> void:
	if current.get("loop", true) and current_id != "":
		_loops += 1
		_player.play()


## Tempo del brano compensato con la latenza audio (tecnica dalla doc di Godot).
func song_time() -> float:
	if not _player.playing:
		return -1.0
	var t := _player.get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()
	return t - float(current.get("offset", 0.0))


func seconds_per_beat() -> float:
	return 60.0 / float(current.get("bpm", 120))


## Fase 0..1 all'interno del battito corrente (utile per animazioni a tempo).
func beat_phase() -> float:
	var t := song_time()
	if t < 0.0:
		return 0.0
	return fmod(t / seconds_per_beat(), 1.0)


func _process(_delta: float) -> void:
	if current_id == "" or not _player.playing:
		return
	var t := song_time()
	if t < 0.0:
		return
	var beat_in_loop := int(floor(t / seconds_per_beat()))
	var length := _player.stream.get_length() if _player.stream else 0.0
	var beats_per_loop := maxi(1, int(round(length / seconds_per_beat())))
	var total := _loops * beats_per_loop + beat_in_loop
	if total <= _last_beat:
		return
	for b in range(_last_beat + 1, total + 1):
		var in_loop := b % beats_per_loop
		beat.emit(b)
		if b % int(current.get("beats_per_bar", 4)) == 0:
			bar.emit(b / int(current.get("beats_per_bar", 4)))
		var cues: Dictionary = current.get("cues", {})
		if cues.has(str(in_loop)):
			cue.emit(cues[str(in_loop)])
	_last_beat = total


func sfx(name: String, pitch := 1.0) -> void:
	if sfx_volume <= 0.001:
		return
	var stream: AudioStream = _sfx_cache.get(name)
	if stream == null:
		var path := SFX_DIR + name + ".wav"
		if not ResourceLoader.exists(path):
			return
		stream = load(path)
		_sfx_cache[name] = stream
	for p in _sfx:
		if not p.playing:
			p.stream = stream
			p.pitch_scale = pitch
			p.volume_db = _lin_db(sfx_volume)
			p.play()
			return
	_sfx[0].stream = stream
	_sfx[0].play()
