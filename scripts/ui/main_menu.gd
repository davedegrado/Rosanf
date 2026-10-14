extends Control

var screen: NokiaScreen
var _actions: Array[Callable] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Music.play("menu")
	screen = NokiaScreen.new()
	add_child(screen)
	screen.header = load("res://assets/ui/menu_coccinella.png")
	var items := []
	_add(items, Game.tr_ui("new_game"), Game.new_game)
	if Game.unlocked_chapter > 1:
		_add(items, Game.tr_ui("continue"), Game.continue_game)
	_add(items, Game.tr_ui("chapters"), func(): Router.goto("res://scenes/ui/chapter_select.tscn"))
	_add(items, Game.tr_ui("options"), func(): Router.goto("res://scenes/ui/options.tscn"))
	if not OS.has_feature("mobile") and not OS.has_feature("web"):
		_add(items, Game.tr_ui("quit"), func(): get_tree().quit())
	screen.setup("! ROSANF? !", items)
	screen.activated.connect(func(i): _actions[i].call())
	screen.back.connect(func():
		if not OS.has_feature("ios"):
			get_tree().quit())


func _add(items: Array, text: String, action: Callable) -> void:
	items.append({"text": text})
	_actions.append(action)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().quit()
