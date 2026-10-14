extends Control
## Avvio: verifica età (contenuti per adulti) e poi menu principale.

var screen: NokiaScreen


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Music.play("menu")
	if Game.age_confirmed:
		Router.goto.call_deferred(Game.MENU_SCENE)
		return
	screen = NokiaScreen.new()
	add_child(screen)
	screen.body = Game.tr_ui("age_body")
	screen.setup(Game.tr_ui("age_title"), [{"text": Game.tr_ui("age_yes")}, {"text": Game.tr_ui("age_no")}])
	screen.selected = 1
	screen.activated.connect(_on_choice)


func _on_choice(i: int) -> void:
	if i == 0:
		Game.age_confirmed = true
		Game.save()
		Router.goto(Game.MENU_SCENE)
	else:
		screen.body = Game.tr_ui("age_denied")
		screen.setup(Game.tr_ui("age_title"), [{"text": Game.tr_ui("age_yes")}])
