class_name NokiaScreen
extends Control
## Schermata "LCD Nokia 3310" riutilizzabile: titolo, lista voci, opzioni ◀ ▶, softkey.
## Funziona con tastiera/pad (frecce, invio, esc) e touch (tap sulle voci e sui softkey).

signal activated(index: int)
signal changed(index: int, direction: int)
signal back

const ROW_H := 13
const LCD_W := 236
const LCD_H := 164

@export var title := ""
@export var body := ""
var header: Texture2D
var items: Array = []        # [{text, value?, icon?, disabled?}]
var soft_left := ""
var soft_right := ""
var selected := 0
var active := true
var show_cursor := true

var _scroll := 0
var _blink := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	if soft_left == "":
		soft_left = Game.tr_ui("select")
	if soft_right == "":
		soft_right = Game.tr_ui("ok")
	resized.connect(queue_redraw)


func setup(p_title: String, p_items: Array, p_left := "", p_right := "") -> void:
	title = p_title
	items = p_items
	if p_left != "":
		soft_left = p_left
	if p_right != "":
		soft_right = p_right
	selected = clampi(selected, 0, maxi(0, items.size() - 1))
	_skip_disabled(1)
	queue_redraw()


func set_item(index: int, data: Dictionary) -> void:
	items[index] = data
	queue_redraw()


func _process(delta: float) -> void:
	_blink += delta
	if fmod(_blink, 0.5) < delta:
		queue_redraw()


# ------------------------------------------------------------------ geometria
func lcd_rect() -> Rect2:
	var w := mini(LCD_W, int(size.x) - 8)
	var h := mini(LCD_H, int(size.y) - 8)
	return Rect2(floor((size.x - w) / 2.0), floor((size.y - h) / 2.0), w, h)


func _list_top() -> float:
	var r := lcd_rect()
	var y := r.position.y + 21
	if header:
		y += header.get_height() + 4
	if body != "":
		y += _body_lines() * 11 + 6
	return y


func _visible_rows() -> int:
	var r := lcd_rect()
	return maxi(1, int((r.end.y - 20 - _list_top()) / ROW_H))


func _body_lines() -> int:
	var r := lcd_rect()
	var width := r.size.x - 16
	return int(Game.font.get_multiline_string_size(body, HORIZONTAL_ALIGNMENT_CENTER, width, Game.FONT_SIZE).y / 11.0 + 0.5)


# ------------------------------------------------------------------ disegno
func _draw() -> void:
	var fg := Game.LCD_FG
	var bg := Game.LCD_BG
	var font := Game.font
	var fs := Game.FONT_SIZE
	draw_rect(Rect2(Vector2.ZERO, size), Game.PHONE)
	var r := lcd_rect()
	# cornice dello schermo con angoli smussati
	draw_rect(r.grow(3), Color8(20, 28, 24))
	draw_rect(r, bg)
	for c in [r.position, Vector2(r.end.x - 1, r.position.y), Vector2(r.position.x, r.end.y - 1), r.end - Vector2.ONE]:
		draw_rect(Rect2(c, Vector2.ONE), Color8(20, 28, 24))
	# ombra LCD (pixel "fantasma" tipici dei display monocromatici)
	draw_rect(Rect2(r.position + Vector2(4, 4), Vector2(r.size.x - 8, 1)), Game.LCD_MID * Color(1, 1, 1, 0.25))

	var x0 := r.position.x
	var y := r.position.y + 4
	# titolo
	if title != "":
		var tw := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, Vector2(x0 + (r.size.x - tw) / 2.0, y + 9), title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, fg)
		draw_rect(Rect2(x0 + 8, y + 13, r.size.x - 16, 1), fg)
	y = r.position.y + 21
	if header:
		draw_texture(header, Vector2(x0 + floor((r.size.x - header.get_width()) / 2.0), y))
		y += header.get_height() + 4
	if body != "":
		draw_multiline_string(font, Vector2(x0 + 8, y + 9), body, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 16, fs, -1, fg)
		y += _body_lines() * 11 + 6

	# voci
	var rows := _visible_rows()
	if selected < _scroll:
		_scroll = selected
	elif selected >= _scroll + rows:
		_scroll = selected - rows + 1
	for i in range(_scroll, mini(items.size(), _scroll + rows)):
		var it: Dictionary = items[i]
		var row_y := y + (i - _scroll) * ROW_H
		var is_sel := i == selected and show_cursor
		var col := fg
		if is_sel:
			draw_rect(Rect2(x0 + 6, row_y, r.size.x - 12, ROW_H - 1), fg)
			col = bg
		if it.get("disabled", false):
			col = Game.LCD_MID if not is_sel else bg.darkened(0.2)
		var tx := x0 + 10
		if is_sel and not it.has("value"):
			draw_string(font, Vector2(tx, row_y + 10), "▶", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		tx += 8
		draw_string(font, Vector2(tx, row_y + 10), it.get("text", ""), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		if it.has("value"):
			var v := "◀ " + str(it.value) + " ▶"
			var vw := font.get_string_size(v, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			draw_string(font, Vector2(r.end.x - 10 - vw, row_y + 10), v, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
		if it.get("icon") is Texture2D:
			var ic: Texture2D = it.icon
			var ip := Vector2(r.end.x - 10 - ic.get_width(), row_y + (ROW_H - 1 - ic.get_height()) / 2.0)
			if is_sel:
				draw_texture(ic, ip, bg)
			else:
				draw_texture(ic, ip, fg)
	# frecce di scorrimento
	if _scroll > 0:
		draw_string(font, Vector2(r.end.x - 12, y - 2), "▲", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, fg)
	if _scroll + rows < items.size():
		draw_string(font, Vector2(r.end.x - 12, y + rows * ROW_H + 6), "▼", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, fg)

	# softkey
	var sy := r.end.y - 15
	draw_rect(Rect2(x0 + 4, sy, r.size.x - 8, 1), fg)
	draw_string(font, Vector2(x0 + 8, sy + 12), soft_left, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, fg)
	if items.size() > 1 and fmod(_blink, 1.0) < 0.6:
		draw_string(font, Vector2(x0 + r.size.x / 2.0 - 3, sy + 12), "◆", HORIZONTAL_ALIGNMENT_LEFT, -1, fs, fg)
	var rw := font.get_string_size(soft_right, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, Vector2(r.end.x - 8 - rw, sy + 12), soft_right, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, fg)


# ------------------------------------------------------------------ input
func _move(dir: int) -> void:
	if items.is_empty():
		return
	var start := selected
	for _i in items.size():
		selected = wrapi(selected + dir, 0, items.size())
		if not items[selected].get("disabled", false):
			break
	if selected != start:
		Music.sfx("menu_muovi")
	queue_redraw()


func _skip_disabled(dir: int) -> void:
	if items.is_empty() or not items[selected].get("disabled", false):
		return
	_move(dir)


func _activate() -> void:
	if items.is_empty() or items[selected].get("disabled", false):
		return
	Music.sfx("menu_ok")
	Game.vibrate(25)
	activated.emit(selected)


func _change(dir: int) -> void:
	if items.is_empty() or not items[selected].has("value"):
		return
	Music.sfx("menu_muovi")
	changed.emit(selected, dir)


func _unhandled_input(event: InputEvent) -> void:
	if not active or not is_visible_in_tree():
		return
	if event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		_move(-1)
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		_move(1)
	elif event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		_change(-1)
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		_change(1)
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("jump"):
		_activate()
	elif event.is_action_pressed("ui_cancel"):
		Music.sfx("menu_muovi")
		back.emit()
	else:
		return
	get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if not active:
		return
	var pressed: bool = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if not pressed:
		return
	accept_event()
	var p: Vector2 = event.position
	var r := lcd_rect()
	if p.y >= r.end.y - 16:  # softkey
		if p.x < r.position.x + r.size.x / 2.0:
			if soft_left == Game.tr_ui("back"):
				Music.sfx("menu_muovi")
				back.emit()
			else:
				_activate()
		else:
			_activate()
		return
	var top := _list_top()
	var idx := int((p.y - top) / ROW_H) + _scroll
	if p.y < top or idx < 0 or idx >= mini(items.size(), _scroll + _visible_rows()):
		return
	if items[idx].get("disabled", false):
		return
	selected = idx
	queue_redraw()
	if items[idx].has("value"):
		_change(-1 if p.x < r.get_center().x + 30 else 1)
	else:
		_activate()
