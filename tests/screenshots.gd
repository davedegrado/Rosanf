extends Node
## Cattura screenshot di menu, cutscene e livelli (serve un display, es. xvfb-run).
## Uso: godot --path . res://tests/screenshots.tscn -- <cartella_output>

var out_dir := "user://screenshots"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	Game.age_confirmed = true
	get_tree().current_scene = null
	_run.call_deferred()


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec, true, false, true).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, name])


func _run() -> void:
	Game.age_confirmed = false
	Router.goto("res://scenes/boot/boot.tscn", 0.01)
	await _wait(0.6); await _shot("00_eta")
	Game.age_confirmed = true
	for s in [["01_menu", Game.MENU_SCENE], ["02_capitoli", "res://scenes/ui/chapter_select.tscn"],
			["03_opzioni", "res://scenes/ui/options.tscn"], ["04_game_over", Game.GAME_OVER_SCENE]]:
		Router.goto(s[1], 0.01)
		await _wait(0.6)
		await _shot(s[0])
	Game.cutscene_id = "cap1_outro"
	Router.goto(Game.CUTSCENE_SCENE, 0.01)
	await _wait(0.6)
	Input.action_press("jump"); await _wait(0.05); Input.action_release("jump")
	await _wait(0.2)
	await _shot("05_cutscene")
	for i in 3:
		Game.chapter_index = i
		Router.goto(Game.LEVEL_SCENE, 0.01)
		await _wait(1.0)
		await _shot("1%d_livello_a" % i)
		var lvl = get_tree().current_scene
		lvl.hud.banner.visible = false
		Input.action_press("move_right")
		await _wait(2.2)
		Input.action_release("move_right")
		if i == 1:
			lvl.player.high_t = 3.0
		if i == 2:
			lvl.player.madness_t = 0.0
			lvl.player.broom_t = 3.0
		await _wait(0.4)
		await _shot("1%d_livello_b" % i)
	get_tree().quit()
