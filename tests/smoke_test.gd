extends Node
## Smoke test: apre ogni schermata e gioca ogni capitolo per qualche secondo con input simulato.
## Uso: godot --headless --path . res://tests/smoke_test.tscn

var log_lines := []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.age_confirmed = true
	# il test sopravvive ai cambi scena: non è più la "scena corrente"
	get_tree().current_scene = null
	_run.call_deferred()


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec, true, false, true).timeout


func _press(action: String, sec: float) -> void:
	Input.action_press(action)
	await _wait(sec)
	Input.action_release(action)


func _run() -> void:
	for scene in ["res://scenes/boot/boot.tscn", Game.MENU_SCENE, "res://scenes/ui/chapter_select.tscn",
			"res://scenes/ui/options.tscn", Game.GAME_OVER_SCENE, Game.END_SCENE]:
		Router.goto(scene, 0.01)
		await _wait(0.5)
		print("OK scena ", scene, " -> ", get_tree().current_scene.name)
	for i in Game.chapters.size():
		Game.cutscene_id = Game.chapters[i].intro
		Game.cutscene_done = Callable()
		Router.goto(Game.CUTSCENE_SCENE, 0.01)
		await _wait(0.3)
		for k in 6:
			Input.action_press("jump"); await _wait(0.05); Input.action_release("jump"); await _wait(0.05)
		print("OK cutscene ", Game.chapters[i].intro)
		Game.chapter_index = i
		Game.lives = 3
		Router.goto(Game.LEVEL_SCENE, 0.01)
		await _wait(0.5)
		var lvl = get_tree().current_scene
		print("OK livello ", i + 1, " mappa ", lvl.map_size, " oggetti ", lvl.get_child_count())
		Input.action_press("move_right")
		for k in 12:
			await _press("jump", 0.3)
			await _press("attack", 0.1)
			await _wait(0.2)
		Input.action_release("move_right")
		var p = lvl.player
		print("   giocatore x=%.0f y=%.0f cuori=%d morto=%s punti=%d" % [p.global_position.x, p.global_position.y, p.hearts, p.dead, Game.score])
		# effetti speciali
		p.high_t = 2.0; p.drunk_t = 2.0; p.madness_t = 1.0; p.broom_t = 1.0
		await _wait(0.5)
		lvl._open_pause()
		await _wait(0.3)
		print("   pausa: ", get_tree().paused)
		get_tree().paused = false
		# completa il capitolo forzando l'obiettivo
		lvl.collected = lvl.goal_count
		lvl._check_goal()
		lvl._complete()
		await _wait(2.0)
		print("   dopo completamento -> ", get_tree().current_scene.name, " sbloccato=", Game.unlocked_chapter)
	print("SMOKE TEST FINITO")
	get_tree().quit()
