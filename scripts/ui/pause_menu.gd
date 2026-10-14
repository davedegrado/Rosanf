extends CanvasLayer
## Menu di pausa in stile Nokia (funziona a gioco in pausa).

signal resumed

var screen: NokiaScreen
var _options: Control


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	screen = NokiaScreen.new()
	add_child(screen)
	screen.setup(Game.tr_ui("pause"), [
		{"text": Game.tr_ui("resume")},
		{"text": Game.tr_ui("options")},
		{"text": Game.tr_ui("restart")},
		{"text": Game.tr_ui("main_menu")},
	])
	screen.activated.connect(_on_item)
	screen.back.connect(_resume)


func _on_item(i: int) -> void:
	match i:
		0:
			_resume()
		1:
			screen.active = false
			screen.visible = false
			_options = preload("res://scripts/ui/options_menu.gd").new()
			_options.as_overlay = true
			add_child(_options)
			_options.closed.connect(func():
				_options.queue_free()
				screen.active = true
				screen.visible = true)
		2:
			Game.score = Game.score_at_chapter_start
			Router.goto(Game.LEVEL_SCENE)
		3:
			Router.goto(Game.MENU_SCENE)


func _resume() -> void:
	get_tree().paused = false
	resumed.emit()
	queue_free()
