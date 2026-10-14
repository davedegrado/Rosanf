class_name Player
extends CharacterBody2D
## La coccinella. Movimento platform con coyote time e jump buffer, corsa,
## attacco corpo a corpo, scopa volante e stati alterati (sbronza, sballo, follia).

signal hearts_changed(hearts: int)
signal died

const WALK := 80.0
const RUN := 135.0
const ACCEL := 700.0
const FRICTION := 900.0
const GRAVITY := 900.0
const JUMP_V := -350.0  # ~68 px: 4 tile + margine (vedi tools/check_levels.py)
const MAX_FALL := 320.0
const COYOTE := 0.1
const BUFFER := 0.12
const RUN_AFTER := 0.5
const INVULN := 1.2

var hearts := Game.MAX_HEARTS
var facing := 1
var dead := false
var controls_enabled := true

var drunk_t := 0.0
var high_t := 0.0
var madness_t := 0.0
var broom_t := 0.0

var _coyote := 0.0
var _buffer := 0.0
var _run_hold := 0.0
var _invuln := 0.0
var _hurt_t := 0.0
var _attack_t := 0.0
var _action_anim_t := 0.0
var _action_anim := ""
var _wobble := 0.0

var sprite: AnimatedSprite2D
var attack_area: Area2D
var safe_position := Vector2.ZERO
var _safe_timer := 0.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 4.0
	add_to_group("player")
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = SpriteUtil.frames_from_sheet("res://assets/sprites/coccinella")
	sprite.play("idle")
	add_child(sprite)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(10, 15)
	shape.shape = rect
	shape.position = Vector2(0, 4.5)
	add_child(shape)
	attack_area = Area2D.new()
	attack_area.collision_layer = 0
	attack_area.collision_mask = 4
	attack_area.monitoring = false
	var ashape := CollisionShape2D.new()
	var arect := RectangleShape2D.new()
	arect.size = Vector2(16, 14)
	ashape.shape = arect
	ashape.position = Vector2(12, 2)
	attack_area.add_child(ashape)
	add_child(attack_area)
	attack_area.area_entered.connect(_on_attack_hit)
	safe_position = global_position


# ------------------------------------------------------------------ input
func _axis() -> float:
	if not controls_enabled:
		return 0.0
	var x := Input.get_axis("move_left", "move_right")
	if madness_t > 0.0:
		x = -x
	if drunk_t > 0.0:
		x += sin(_wobble * 2.3) * 0.35
	return clampf(x, -1.0, 1.0)


func _physics_process(delta: float) -> void:
	if dead:
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		move_and_slide()
		return
	_wobble += delta
	for t in ["drunk_t", "high_t", "madness_t", "broom_t", "_invuln", "_hurt_t", "_attack_t", "_action_anim_t"]:
		set(t, maxf(0.0, get(t) - delta))
	sprite.visible = _invuln <= 0.0 or fmod(_invuln, 0.12) > 0.05

	var axis := _axis()
	if broom_t > 0.0:
		_broom_physics(axis, delta)
	else:
		_ground_physics(axis, delta)
	move_and_slide()

	if attack_area.monitoring and _attack_t <= 0.0:
		attack_area.monitoring = false
	if is_on_floor():
		_safe_timer += delta
		if _safe_timer > 0.3:
			safe_position = global_position
			_safe_timer = 0.0
	_animate(axis)


func _ground_physics(axis: float, delta: float) -> void:
	if is_on_floor():
		_coyote = COYOTE
	else:
		_coyote -= delta
		velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	if controls_enabled and Input.is_action_just_pressed("jump"):
		_buffer = BUFFER
	else:
		_buffer -= delta
	if _buffer > 0.0 and _coyote > 0.0:
		var jv := JUMP_V * (1.25 if high_t > 0.0 else 1.0)
		velocity.y = jv
		_buffer = 0.0
		_coyote = 0.0
		Music.sfx("salto", 1.0 + randf() * 0.1)
	if not Input.is_action_pressed("jump") and velocity.y < -120.0:
		velocity.y = -120.0  # salto variabile
	if controls_enabled and Input.is_action_just_pressed("attack") and _attack_t <= 0.0:
		_attack()

	if _hurt_t > 0.0:
		velocity.x = move_toward(velocity.x, 0, FRICTION * 0.3 * delta)
		return
	if absf(axis) > 0.2:
		_run_hold += delta
		facing = 1 if axis > 0 else -1
		var target := axis * (RUN if _run_hold > RUN_AFTER else WALK)
		velocity.x = move_toward(velocity.x, target, ACCEL * delta)
	else:
		_run_hold = 0.0
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)


func _broom_physics(axis: float, delta: float) -> void:
	# Sulla scopa si vola: SALTO = su, altrimenti si plana lentamente.
	var up := controls_enabled and (Input.is_action_pressed("jump") or Input.is_action_pressed("move_up"))
	var target_y := -110.0 if up else 45.0
	if Input.is_action_pressed("move_down"):
		target_y = 120.0
	velocity.y = move_toward(velocity.y, target_y, 600.0 * delta)
	if absf(axis) > 0.2:
		facing = 1 if axis > 0 else -1
	velocity.x = move_toward(velocity.x, axis * RUN * 1.1, ACCEL * delta)
	if global_position.y < 16:
		velocity.y = maxf(velocity.y, 0.0)
	if controls_enabled and Input.is_action_just_pressed("attack") and _attack_t <= 0.0:
		_attack()


func _attack() -> void:
	_attack_t = 0.25
	attack_area.monitoring = true
	sprite.play("attack")
	sprite.frame = 0
	Music.sfx("attacco")


func _on_attack_hit(area: Area2D) -> void:
	var owner_node := area.get_parent()
	if owner_node and owner_node.has_method("hit"):
		owner_node.hit(facing)


# ------------------------------------------------------------------ animazione
func _animate(axis: float) -> void:
	sprite.flip_h = facing < 0
	attack_area.scale.x = facing
	var anim := "idle"
	if dead:
		anim = "dead"
	elif _hurt_t > 0.0:
		anim = "hurt"
	elif _attack_t > 0.0:
		anim = "attack"
	elif broom_t > 0.0:
		anim = "broom"
	elif _action_anim_t > 0.0:
		anim = _action_anim
	elif not is_on_floor():
		anim = "jump" if velocity.y < 0 else "fall"
	elif absf(velocity.x) > 5.0:
		anim = "run" if absf(velocity.x) > WALK + 5.0 else "walk"
	if sprite.animation != anim:
		sprite.play(anim)
	# effetti visivi degli stati
	sprite.rotation = sin(_wobble * 3.0) * 0.15 if drunk_t > 0.0 else 0.0
	if madness_t > 0.0:
		sprite.modulate = Color(1.0, 0.5 + randf() * 0.5, 0.5 + randf() * 0.5)
	elif high_t > 0.0:
		sprite.modulate = Color.from_hsv(fmod(_wobble * 0.7, 1.0), 0.35, 1.0)
	else:
		sprite.modulate = Color.WHITE


func play_action(anim: String, duration := 0.6) -> void:
	_action_anim = anim
	_action_anim_t = duration


# ------------------------------------------------------------------ danni
func is_invulnerable() -> bool:
	return _invuln > 0.0 or dead


func hurt(from_x: float, amount := 1) -> void:
	if is_invulnerable():
		return
	hearts = maxi(0, hearts - amount)
	hearts_changed.emit(hearts)
	Music.sfx("colpo")
	Game.vibrate(120)
	broom_t = 0.0
	if hearts <= 0:
		die()
		return
	_invuln = INVULN
	_hurt_t = 0.3
	velocity = Vector2(signf(global_position.x - from_x) * 140.0, -200.0)


func heal(amount := 1) -> void:
	hearts = mini(Game.MAX_HEARTS, hearts + amount)
	hearts_changed.emit(hearts)


func bounce(strength := 260.0) -> void:
	velocity.y = -strength
	_coyote = 0.0


func die() -> void:
	if dead:
		return
	dead = true
	controls_enabled = false
	sprite.play("dead")
	sprite.modulate = Color.WHITE
	sprite.rotation = 0
	velocity = Vector2(0, -200)
	collision_mask = 0
	Music.sfx("morte")
	Game.vibrate(400)
	died.emit()


func respawn_at_safe() -> void:
	global_position = safe_position
	velocity = Vector2.ZERO
	_invuln = INVULN
