extends Control

var screen: NokiaScreen


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Music.play("game_over", true)
	Game.vibrate(300)
	screen = NokiaScreen.new()
	add_child(screen)
	screen.header = load("res://assets/ui/menu_morta.png")
	screen.body = "%s: %06d" % [Game.tr_ui("points"), Game.score]
	screen.setup(Game.tr_ui("game_over"), [{"text": Game.tr_ui("retry")}, {"text": Game.tr_ui("main_menu")}])
	screen.activated.connect(func(i):
		if i == 0:
			Game.retry_after_game_over()
		else:
			Router.goto(Game.MENU_SCENE))
