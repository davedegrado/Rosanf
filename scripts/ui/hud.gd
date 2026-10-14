class_name Hud
extends CanvasLayer
## HUD: cuori, vite, punti, obiettivo, barra NOIA/FAME, banner messaggi.

var hearts: Array[TextureRect] = []
var lives_label: Label
var score_label: Label
var goal_label: Label
var meter_label: Label
var meter_back: ColorRect
var meter_fill: ColorRect
var banner: PanelContainer
var banner_label: Label
var _tex_full: Texture2D = preload("res://assets/ui/cuore.png")
var _tex_empty: Texture2D = preload("res://assets/ui/cuore_vuoto.png")
var _banner_t := 0.0
var _pulse := 0.0


func _ready() -> void:
	layer = 20
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	for i in Game.MAX_HEARTS:
		var t := TextureRect.new()
		t.texture = _tex_full
		t.position = Vector2(4 + i * 10, 4)
		root.add_child(t)
		hearts.append(t)
	var icon := TextureRect.new()
	icon.texture = _atlas(preload("res://assets/sprites/coccinella.png"), Rect2(4, 4, 18, 18))
	icon.scale = Vector2(0.6, 0.6)
	icon.position = Vector2(3, 13)
	root.add_child(icon)
	lives_label = _label(root, Vector2(16, 14))
	score_label = _label(root, Vector2.ZERO)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UiUtil.place(score_label, 1.0, 0.0, Rect2(-124, 3, 120, 10))
	goal_label = _label(root, Vector2.ZERO)
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiUtil.place(goal_label, 0.5, 0.0, Rect2(-60, 3, 120, 10))
	meter_label = _label(root, Vector2.ZERO)
	meter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UiUtil.place(meter_label, 0.5, 0.0, Rect2(-66, 14, 58, 10))
	meter_back = ColorRect.new()
	meter_back.color = Game.LCD_FG
	UiUtil.place(meter_back, 0.5, 0.0, Rect2(-4, 16, 54, 6))
	root.add_child(meter_back)
	meter_fill = ColorRect.new()
	meter_fill.color = Color8(250, 210, 60)
	meter_fill.position = Vector2(1, 1)
	meter_fill.size = Vector2(0, 4)
	meter_back.add_child(meter_fill)
	set_meter_visible(false)

	banner = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Game.LCD_BG
	sb.border_color = Game.LCD_FG
	sb.set_border_width_all(2)
	sb.set_content_margin_all(5)
	banner.add_theme_stylebox_override("panel", sb)
	banner.grow_vertical = Control.GROW_DIRECTION_BOTH
	UiUtil.place(banner, 0.5, 0.5, Rect2(-110, -10, 220, 20))
	banner_label = Label.new()
	banner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.add_theme_color_override("font_color", Game.LCD_FG)
	banner_label.custom_minimum_size = Vector2(206, 0)
	banner.add_child(banner_label)
	banner.visible = false
	root.add_child(banner)
	Music.beat.connect(_on_beat)


func _on_beat(_i: int) -> void:
	_pulse = 1.0


func _atlas(tex: Texture2D, r: Rect2) -> AtlasTexture:
	var a := AtlasTexture.new()
	a.atlas = tex
	a.region = r
	return a


func _label(parent: Control, pos: Vector2) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_shadow_color", Color(0.1, 0.06, 0.09))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(l)
	return l


func set_hearts(n: int) -> void:
	for i in hearts.size():
		hearts[i].texture = _tex_full if i < n else _tex_empty


func set_goal(text: String) -> void:
	goal_label.text = text


func set_meter_visible(v: bool, title := "") -> void:
	meter_label.visible = v
	meter_back.visible = v
	meter_label.text = title


func set_meter(value: float) -> void:
	meter_fill.size.x = 52.0 * clampf(value / 100.0, 0.0, 1.0)
	meter_fill.color = Color8(250, 210, 60) if value < 75 else Color8(214, 48, 49)


func show_banner(text: String, seconds := 2.5) -> void:
	banner_label.text = text
	banner.visible = true
	_banner_t = seconds


func _process(delta: float) -> void:
	score_label.text = "%s: %06d" % [Game.tr_ui("points"), Game.score]
	lives_label.text = "x %02d" % maxi(0, Game.lives)
	if _banner_t > 0.0:
		_banner_t -= delta
		if _banner_t <= 0.0:
			banner.visible = false
	# i cuori pulsano a tempo di musica
	_pulse = maxf(0.0, _pulse - delta * 6.0)
	for h in hearts:
		h.scale = Vector2.ONE * (1.0 + 0.15 * _pulse)
