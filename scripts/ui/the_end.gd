extends Control
## Schermata finale (finale aperto...).

var screen: NokiaScreen


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Music.play("menu")
	Game.save()
	screen = NokiaScreen.new()
	add_child(screen)
	screen.header = load("res://assets/ui/menu_coccinella.png")
	screen.body = "%s: %06d\n%s: %06d" % [Game.tr_ui("points"), Game.score, Game.tr_ui("best"), Game.best_score]
	screen.setup(Game.tr_ui("the_end"), [{"text": Game.tr_ui("main_menu")}])
	screen.activated.connect(func(_i): Router.goto(Game.MENU_SCENE))
