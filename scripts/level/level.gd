extends Node2D
## Livello generico guidato dai dati: legge il capitolo corrente da data/chapters.json
## e la mappa ASCII da data/levels/*.txt (legenda in docs/LIVELLI.md).

const T := 16
const TILESET := "res://assets/tiles/tileset.png"
const ITEM_CHARS := {
	"u": "uranio", "b": "bottiglia", "f": "fungo", "x": "merda", "k": "scopa", "*": "farfalla",
	"h": "pianta_mutante", "w": "donna", "d": "donna_ballo", "E": "porta", "C": "crepa", "S": "pecora",
}
const ENEMY_CHARS := {"U": "uomo", "M": "mutante"}
const DECOR_CHARS := {"1": 4, "2": 5, "3": 6, "4": 7}

var chapter: Dictionary
var map_size := Vector2i.ZERO
var player: Player
var camera: Camera2D
var hud: Hud
var tiles: TileMapLayer
var trip_rect: ColorRect

var goal_item := ""
var goal_count := 0
var collected := 0
var exits: Array[Thing] = []
var hazards: Array[Area2D] = []
var meter := 0.0
var meter_cfg = null
var _finished := false
var _pause_lock := 0.0
var _msg_cooldown := 0.0


func _ready() -> void:
	add_to_group("level")
	chapter = Game.current_chapter()
	var goal: Dictionary = chapter.get("goal", {})
	goal_item = goal.get("item", "")
	goal_count = int(goal.get("count", 0))
	meter_cfg = chapter.get("meter")

	_build_background()
	var rows := _read_map(chapter.map)
	_build_tiles(rows)
	_spawn_entities(rows)
	_build_camera()
	hud = Hud.new()
	add_child(hud)
	add_child(preload("res://scripts/ui/touch_controls.gd").new())
	_build_fx()

	hud.set_hearts(player.hearts)
	player.hearts_changed.connect(hud.set_hearts)
	player.died.connect(_on_player_died)
	if meter_cfg is Dictionary:
		hud.set_meter_visible(true, Game.loc(meter_cfg.name))
	_update_goal()
	_check_goal()
	Music.play(chapter.music, true)
	Music.cue.connect(_on_cue)
	hud.show_banner("%s %d\n%s\n\n%s" % [Game.tr_ui("chapter"), int(chapter.id), Game.loc(chapter.title), Game.loc(chapter.hint)], 4.0)


# ------------------------------------------------------------------ costruzione
func _read_map(path: String) -> PackedStringArray:
	var f := FileAccess.open(path, FileAccess.READ)
	var rows := PackedStringArray()
	for line in f.get_as_text().split("\n"):
		if line.strip_edges() != "":
			rows.append(line.rstrip("\r"))
	var w := 0
	for r in rows:
		w = maxi(w, r.length())
	map_size = Vector2i(w, rows.size())
	return rows


func _cell(rows: PackedStringArray, x: int, y: int) -> String:
	if y < 0 or y >= rows.size() or x < 0 or x >= rows[y].length():
		return "."
	return rows[y][x]


func _make_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	var src := TileSetAtlasSource.new()
	src.texture = load(TILESET)
	src.texture_region_size = Vector2i(T, T)
	ts.add_source(src, 0)
	var h := T / 2.0
	for y in 3:
		for x in 8:
			var coords := Vector2i(x, y)
			src.create_tile(coords)
			var td := src.get_tile_data(coords, 0)
			if x <= 1:
				td.add_collision_polygon(0)
				td.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)]))
			elif x == 2:
				td.add_collision_polygon(0)
				td.set_collision_polygon_points(0, 0, PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, -h + 5), Vector2(-h, -h + 5)]))
				td.set_collision_polygon_one_way(0, 0, true)
	return ts


func _build_tiles(rows: PackedStringArray) -> void:
	tiles = TileMapLayer.new()
	tiles.tile_set = _make_tileset()
	add_child(tiles)
	var theme_row := int(chapter.get("theme", 0))
	for y in rows.size():
		for x in rows[y].length():
			var c := rows[y][x]
			var pos := Vector2i(x, y)
			if c == "#":
				var top := _cell(rows, x, y - 1) != "#"
				tiles.set_cell(pos, 0, Vector2i(0 if top else 1, theme_row))
			elif c == "=":
				tiles.set_cell(pos, 0, Vector2i(2, theme_row))
			elif c == "^":
				tiles.set_cell(pos, 0, Vector2i(3, theme_row))
				_add_hazard(pos)
			elif DECOR_CHARS.has(c):
				tiles.set_cell(pos, 0, Vector2i(DECOR_CHARS[c], theme_row))


func _add_hazard(cell: Vector2i) -> void:
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	var s := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(T - 2, T - 6)
	s.shape = r
	a.position = Vector2(cell.x * T + T / 2.0, cell.y * T + T / 2.0 + 3)
	a.add_child(s)
	add_child(a)
	hazards.append(a)


func _foot(cell: Vector2i, height: float) -> Vector2:
	return Vector2(cell.x * T + T / 2.0, (cell.y + 1) * T - height / 2.0)


func _spawn_entities(rows: PackedStringArray) -> void:
	for y in rows.size():
		for x in rows[y].length():
			var c := rows[y][x]
			var cell := Vector2i(x, y)
			if c == "P":
				player = Player.new()
				player.position = _foot(cell, 24) - Vector2(0, 0.5)
				add_child(player)
			elif ENEMY_CHARS.has(c):
				var e := Enemy.new()
				e.kind = ENEMY_CHARS[c]
				e.hop_on_beat = chapter.get("enemies_hop_on_beat", false)
				e.position = _foot(cell, 24) - Vector2(0, 0.5)
				add_child(e)
			elif ITEM_CHARS.has(c):
				var t := Thing.new()
				t.kind = ITEM_CHARS[c]
				match t.kind:
					"porta":
						t.position = Vector2(x * T + T, (y + 1) * T - 16)
					"crepa":
						t.position = Vector2(x * T + T, (y + 1) * T - 24)
					"donna", "donna_ballo":
						t.position = _foot(cell, 24)
					"pecora":
						t.position = _foot(cell, 16)
					_:
						t.position = Vector2(x * T + T / 2.0, y * T + T / 2.0)
				if t.kind in ["porta", "crepa"]:
					t.active = goal_count <= 0
					exits.append(t)
					t.z_index = -1
				add_child(t)
				t.touched.connect(_on_thing)
	if player == null:
		push_error("La mappa non ha una 'P' (partenza del giocatore)")
		player = Player.new()
		player.position = Vector2(32, 32)
		add_child(player)
	move_child(player, -1)


func _build_background() -> void:
	var bg := ParallaxBackground.new()
	add_child(bg)
	var name: String = chapter.get("background", "esterno")
	for spec in [["far", 0.15], ["near", 0.45]]:
		var layer := ParallaxLayer.new()
		layer.motion_scale = Vector2(spec[1], 0.0)
		layer.motion_mirroring = Vector2(320, 0)
		var s := Sprite2D.new()
		s.texture = load("res://assets/backgrounds/%s_%s.png" % [name, spec[0]])
		s.centered = false
		layer.add_child(s)
		bg.add_child(layer)


func _build_camera() -> void:
	camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = map_size.x * T
	camera.limit_bottom = map_size.y * T
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.ignore_rotation = false
	add_child(camera)
	camera.global_position = player.global_position
	camera.reset_smoothing()


func _build_fx() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	trip_rect = ColorRect.new()
	trip_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	trip_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/trip.gdshader")
	trip_rect.material = mat
	trip_rect.visible = false
	layer.add_child(trip_rect)


# ------------------------------------------------------------------ loop
func _process(delta: float) -> void:
	_pause_lock = maxf(0.0, _pause_lock - delta)
	_msg_cooldown = maxf(0.0, _msg_cooldown - delta)
	if Input.is_action_just_pressed("pause") and _pause_lock <= 0.0 and not _finished:
		_open_pause()
	# telecamera: segue la coccinella, ondeggia se sbronza
	camera.global_position = player.global_position + Vector2(player.facing * 24, -8)
	camera.rotation = sin(Time.get_ticks_msec() / 600.0) * 0.04 if player.drunk_t > 0.0 else 0.0
	# shader effetti
	var mat := trip_rect.material as ShaderMaterial
	var trip := clampf(player.high_t / 2.0, 0.0, 1.0)
	var mad := clampf(player.madness_t * 2.0, 0.0, 1.0)
	var drunk := clampf(player.drunk_t / 2.0, 0.0, 1.0)
	trip_rect.visible = trip > 0.0 or mad > 0.0 or drunk > 0.0
	mat.set_shader_parameter("trip", trip)
	mat.set_shader_parameter("madness", mad)
	mat.set_shader_parameter("drunk", drunk)


func _physics_process(delta: float) -> void:
	if _finished or player.dead:
		return
	for h in hazards:
		if h.overlaps_body(player) and not player.is_invulnerable():
			player.hurt(player.global_position.x - player.facing)
			if not player.dead:
				player.bounce(240.0)
	for child in get_children():
		if child is Thing and child.kind == "pianta_mutante" and child.overlaps_body(player):
			player.hurt(child.global_position.x)
	# caduta nel vuoto
	if player.global_position.y > map_size.y * T + 24:
		player.hurt(player.global_position.x)
		if not player.dead:
			player.respawn_at_safe()
	# barra NOIA / FAME
	if meter_cfg is Dictionary:
		meter += float(meter_cfg.rise_per_sec) * delta
		if meter >= 100.0:
			meter = 55.0
			player.hurt(player.global_position.x - player.facing)
			hud.show_banner(Game.tr_ui("bored" if goal_item == "festa" else "starving"), 1.5)
		hud.set_meter(meter)


# ------------------------------------------------------------------ eventi
func _on_thing(t: Thing) -> void:
	match t.kind:
		"uranio":
			_collect(t, 50)
		"bottiglia":
			player.drunk_t = 6.0
			player.play_action("drink")
			Music.sfx("bevi")
			float_text(Game.tr_ui("drunk"), t.global_position)
			_collect(t, 30, true)
		"fungo":
			player.high_t = 8.0
			player.play_action("drug")
			float_text(Game.tr_ui("high"), t.global_position)
			_collect(t, 30, true)
		"merda":
			player.heal(1)
			Music.sfx("mangia")
			float_text(Game.tr_ui("yum"), t.global_position)
			_collect(t, 10)
		"scopa":
			player.broom_t = 7.0
			float_text(Game.tr_ui("broom"), t.global_position)
			_collect(t, 50)
		"farfalla":
			_collect(t, 50)
		"donna":
			_rescue(t)
		"pianta_mutante":
			player.hurt(t.global_position.x)
		"porta", "crepa":
			if t.active:
				_complete()
			elif _msg_cooldown <= 0.0:
				_msg_cooldown = 2.0
				hud.show_banner(Game.tr_ui("bunker_closed" if t.kind == "porta" else "crack_closed"), 1.5)
		"pecora":
			_complete()


func _collect(t: Thing, points: int, party := false) -> void:
	Game.add_score(points)
	Music.sfx("raccogli", 1.0 + randf() * 0.15)
	float_text("+%d" % points, t.global_position + Vector2(0, -10))
	if meter_cfg is Dictionary and t.kind in meter_cfg.refill_items:
		meter = maxf(0.0, meter - float(meter_cfg.refill))
	if t.kind == goal_item or (party and goal_item == "festa"):
		collected += 1
		_update_goal()
		_check_goal()
	t.consume()


func _rescue(t: Thing) -> void:
	t._used = true
	t.set_deferred("monitoring", false)
	Game.add_score(200)
	Music.sfx("salva")
	Game.vibrate(40)
	float_text(Game.tr_ui("saved") + " +200", t.global_position + Vector2(0, -16))
	t.sprite.play("happy")
	var tw := t.create_tween().set_parallel()
	tw.tween_property(t, "position:y", t.position.y - 60, 1.2).set_delay(0.4)
	tw.tween_property(t, "modulate:a", 0.0, 1.2).set_delay(0.4)
	tw.chain().tween_callback(t.queue_free)


func _update_goal() -> void:
	if goal_count <= 0:
		hud.set_goal("")
	elif goal_item == "uranio":
		hud.set_goal("☢ %d/%d" % [mini(collected, goal_count), goal_count])
	else:
		hud.set_goal("♪ %d/%d" % [mini(collected, goal_count), goal_count])


func _check_goal() -> void:
	if goal_count > 0 and collected == goal_count:
		for e in exits:
			e.set_active(true)
		hud.show_banner(Game.loc(chapter.get("goal_done", "")), 2.5)
		Music.sfx("salva")


func _on_cue(name: String) -> void:
	if name in chapter.get("madness_cues", []) and not _finished and not player.dead:
		player.madness_t = Music.seconds_per_beat() * 8.0
		Music.sfx("follia")
		Game.vibrate(200)
		hud.show_banner(Game.tr_ui("madness"), 1.2)


func _complete() -> void:
	if _finished:
		return
	_finished = true
	player.controls_enabled = false
	player.velocity.x = 0
	Music.sfx("salva")
	Game.add_score(500 + player.hearts * 100)
	await get_tree().create_timer(1.2).timeout
	Game.complete_chapter()


func _on_player_died() -> void:
	_finished = true
	await get_tree().create_timer(1.8).timeout
	Game.player_died()


func _open_pause() -> void:
	get_tree().paused = true
	var p := preload("res://scripts/ui/pause_menu.gd").new()
	add_child(p)
	p.resumed.connect(func(): _pause_lock = 0.25)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not get_tree().paused:
		_open_pause()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and not get_tree().paused and not _finished:
		_open_pause()


## Testo fluttuante (punti, messaggi). Chiamato anche dai nemici via gruppo "level".
func float_text(text: String, pos: Vector2) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_shadow_color", Color(0.1, 0.06, 0.09))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	l.position = pos - Vector2(text.length() * 3, 8)
	l.z_index = 50
	add_child(l)
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "position:y", l.position.y - 18, 0.9)
	tw.tween_property(l, "modulate:a", 0.0, 0.9).set_delay(0.4)
	tw.chain().tween_callback(l.queue_free)
