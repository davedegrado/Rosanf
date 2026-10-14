extends Control
## Opzioni stile Nokia: AUDIO / MUSICA a tacche, VIBRAZIONE, LINGUA.
## Riutilizzabile anche come overlay di pausa (emette `closed`).

signal closed

var screen: NokiaScreen
var as_overlay := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if not as_overlay:
		Music.play("menu")
	screen = NokiaScreen.new()
	add_child(screen)
	screen.changed.connect(_on_changed)
	screen.activated.connect(func(i): _on_changed(i, 1))
	screen.back.connect(_close)
	_refresh()


func _bars(v: int) -> String:
	return "█".repeat(v) + "░".repeat(4 - v)


func _refresh() -> void:
	screen.setup(Game.tr_ui("options"), [
		{"text": Game.tr_ui("audio") + " ♪", "value": _bars(Game.sfx_volume)},
		{"text": Game.tr_ui("music") + " ♪", "value": _bars(Game.music_volume)},
		{"text": Game.tr_ui("vibration"), "value": Game.tr_ui("yes") if Game.vibration else Game.tr_ui("no")},
		{"text": Game.tr_ui("language"), "value": "ITA" if Game.language == "it" else "ENG"},
	], Game.tr_ui("back"), Game.tr_ui("ok"))


func _on_changed(i: int, dir: int) -> void:
	match i:
		0:
			Game.sfx_volume = clampi(Game.sfx_volume + dir, 0, 4)
		1:
			Game.music_volume = clampi(Game.music_volume + dir, 0, 4)
		2:
			Game.vibration = not Game.vibration
			Game.vibrate(120)
		3:
			Game.language = "en" if Game.language == "it" else "it"
	Game.apply_audio()
	Music.sfx("menu_ok")
	_refresh()


func _close() -> void:
	Game.save()
	if as_overlay:
		closed.emit()
	else:
		Router.goto(Game.MENU_SCENE)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not as_overlay:
		_close()
