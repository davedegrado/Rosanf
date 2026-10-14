extends Control
## Cutscene a pannelli: illustrazione pixel art + testo "macchina da scrivere".
## Tap / OK = avanti (o completa il testo), PAUSA/ESC = salta tutto.

const CHARS_PER_SEC := 38.0

var panels: Array = []
var index := -1
var _shown := 0.0
var _full := ""
var _shake := 0.0
var _image_home := Vector2.ZERO

var image: TextureRect
var text_box: Label
var hint: Label
var flash: ColorRect


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var data: Dictionary = Game.cutscenes.get(Game.cutscene_id, {})
	panels = data.get("panels", [])
	if data.has("music"):
		Music.play(data.music)
	_build_ui()
	_next()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color8(16, 10, 14)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	image = TextureRect.new()
	image.stretch_mode = TextureRect.STRETCH_KEEP
	UiUtil.place(image, 0.5, 0.0, Rect2(-96, 8, 192, 108))
	add_child(image)
	var frame := ReferenceRect.new()
	frame.border_color = Game.LCD_BG
	frame.editor_only = false
	UiUtil.place(frame, 0.5, 0.0, Rect2(-97, 7, 194, 110))
	add_child(frame)
	text_box = Label.new()
	text_box.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_box.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_box.add_theme_color_override("font_color", Game.LCD_BG)
	UiUtil.place(text_box, 0.5, 0.0, Rect2(-140, 124, 280, 44))
	add_child(text_box)
	hint = Label.new()
	hint.add_theme_color_override("font_color", Game.LCD_MID)
	UiUtil.place(hint, 1.0, 1.0, Rect2(-70, -12, 66, 10))
	hint.text = Game.tr_ui("next") + " ▶"
	add_child(hint)
	var skip := Label.new()
	skip.add_theme_color_override("font_color", Game.LCD_MID)
	UiUtil.place(skip, 0.0, 1.0, Rect2(4, -12, 70, 10))
	skip.text = Game.tr_ui("skip") + " ▶▶"
	skip.mouse_filter = Control.MOUSE_FILTER_STOP
	skip.gui_input.connect(func(e):
		if e is InputEventMouseButton and e.pressed:
			accept_event()
			_finish())
	add_child(skip)
	flash = ColorRect.new()
	flash.color = Color(1, 1, 0.9, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(flash)


func _next() -> void:
	index += 1
	if index >= panels.size():
		_finish()
		return
	var p: Dictionary = panels[index]
	image.texture = load("res://assets/cutscenes/%s.png" % p.get("image", "titolo"))
	_full = Game.loc(p.get("text", ""))
	_shown = 0.0
	text_box.text = _full
	text_box.visible_characters = 0
	match p.get("fx", ""):
		"shake":
			_shake = 0.6
			Game.vibrate(150)
		"flash":
			flash.color.a = 1.0
			create_tween().tween_property(flash, "color:a", 0.0, 1.2)
			_shake = 1.2
			Game.vibrate(400)
	if p.has("sfx"):
		Music.sfx(p.sfx)


func _finish() -> void:
	set_process(false)
	set_process_input(false)
	Game.finish_cutscene()


func _process(delta: float) -> void:
	if _shown < _full.length():
		var before := int(_shown)
		_shown += delta * CHARS_PER_SEC
		text_box.visible_characters = int(_shown)
		if int(_shown) != before and int(_shown) % 3 == 0:
			Music.sfx("testo")
	hint.visible = _shown >= _full.length() and fmod(Time.get_ticks_msec() / 1000.0, 0.8) < 0.5
	_image_home = Vector2(floor((size.x - 192.0) / 2.0), 8)
	if _shake > 0.0:
		_shake -= delta
		image.position = _image_home + Vector2(randi_range(-2, 2), randi_range(-2, 2))
	else:
		image.position = _image_home


func _advance() -> void:
	if _shown < _full.length():
		_shown = _full.length()
		text_box.visible_characters = -1
	else:
		_next()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		accept_event()
		_advance()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("jump") or event.is_action_pressed("attack"):
		_advance()
	elif event.is_action_pressed("ui_cancel"):
		_finish()
	else:
		return
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_finish()
