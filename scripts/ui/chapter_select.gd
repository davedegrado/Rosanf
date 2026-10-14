extends Control

var screen: NokiaScreen


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	Music.play("menu")
	screen = NokiaScreen.new()
	add_child(screen)
	var items := []
	var lock: Texture2D = load("res://assets/ui/icona_lock.png")
	for i in Game.chapters.size():
		var ch: Dictionary = Game.chapters[i]
		var unlocked := i < Game.unlocked_chapter
		items.append({
			"text": "%d. %s" % [ch.id, Game.loc(ch.title)],
			"icon": load(ch.icon) if unlocked else lock,
			"disabled": not unlocked,
		})
	screen.setup(Game.tr_ui("select_chapter"), items, Game.tr_ui("back"), Game.tr_ui("ok"))
	screen.selected = clampi(Game.unlocked_chapter - 1, 0, items.size() - 1)
	screen.activated.connect(_on_pick)
	screen.back.connect(func(): Router.goto(Game.MENU_SCENE))
	_genre_label()


func _genre_label() -> void:
	# il genere musicale del capitolo selezionato appare sotto il titolo
	var refresh := func():
		var ch: Dictionary = Game.chapters[screen.selected]
		screen.body = "\u266a " + Game.loc(ch.genre).to_upper()
	refresh.call()
	screen.draw.connect(refresh)


func _on_pick(i: int) -> void:
	Game.score = 0
	Game.lives = Game.START_LIVES
	Game.start_chapter(i)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		Router.goto(Game.MENU_SCENE)
