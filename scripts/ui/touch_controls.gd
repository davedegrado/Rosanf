extends CanvasLayer
## Controlli touch (visibili solo su schermi touch): ◀ ▶ a sinistra, A (salto) e B (attacco) a destra.

var _buttons := {}


func _ready() -> void:
	layer = 30
	# Visibili su mobile; su desktop si possono forzare con l'argomento "-- --touch".
	visible = OS.has_feature("mobile") or (OS.has_feature("web") and DisplayServer.is_touchscreen_available()) \
		or "--touch" in OS.get_cmdline_user_args()
	for spec in [["left", "move_left"], ["right", "move_right"], ["a", "jump"], ["b", "attack"], ["pause", "pause"]]:
		var b := TouchScreenButton.new()
		b.texture_normal = load("res://assets/ui/touch_%s.png" % spec[0])
		b.action = spec[1]
		b.passby_press = spec[0] != "pause"
		var shape := CircleShape2D.new()
		shape.radius = 18
		b.shape = shape
		b.shape_centered = true
		b.scale = Vector2(1.25, 1.25) if spec[0] != "pause" else Vector2(0.75, 0.75)
		add_child(b)
		_buttons[spec[0]] = b
	get_viewport().size_changed.connect(_layout)
	_layout()


func _layout() -> void:
	var s := get_viewport().get_visible_rect().size
	_buttons.left.position = Vector2(6, s.y - 46)
	_buttons.right.position = Vector2(50, s.y - 46)
	_buttons.b.position = Vector2(s.x - 92, s.y - 42)
	_buttons.a.position = Vector2(s.x - 48, s.y - 52)
	_buttons.pause.position = Vector2(s.x - 28, 16)
