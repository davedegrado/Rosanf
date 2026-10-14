class_name Enemy
extends CharacterBody2D
## Umano (o umano mutante). Pattuglia, gira ai bordi, salta a tempo di musica.
## Si elimina saltandogli in testa o con l'attacco.

var kind := "uomo"
var speed := 28.0
var hp := 1
var points := 100
var hop_on_beat := false
var dir := -1
var dying := false

var sprite: AnimatedSprite2D
var hurtbox: Area2D
var _ledge: RayCast2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	if kind == "mutante":
		speed = 45.0
		hp = 2
		points = 200
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = SpriteUtil.frames_from_sheet("res://assets/sprites/" + kind)
	sprite.play("walk")
	add_child(sprite)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(8, 20)
	shape.shape = rect
	shape.position = Vector2(0, 2)
	add_child(shape)
	hurtbox = Area2D.new()
	hurtbox.collision_layer = 4
	hurtbox.collision_mask = 2
	var hs := CollisionShape2D.new()
	var hr := RectangleShape2D.new()
	hr.size = Vector2(10, 20)
	hs.shape = hr
	hs.position = Vector2(0, 2)
	hurtbox.add_child(hs)
	add_child(hurtbox)
	hurtbox.body_entered.connect(_on_body)
	_ledge = RayCast2D.new()
	_ledge.target_position = Vector2(0, 16)
	_ledge.collision_mask = 1
	add_child(_ledge)
	if hop_on_beat:
		Music.beat.connect(_on_beat)


func _physics_process(delta: float) -> void:
	velocity.y = minf(velocity.y + 900.0 * delta, 320.0)
	if dying:
		position += velocity * delta
		rotation += delta * 6.0
		return
	_ledge.position = Vector2(6 * dir, 10)
	if is_on_floor() and (is_on_wall() or not _ledge.is_colliding()):
		dir = -dir
	velocity.x = speed * dir
	move_and_slide()
	sprite.flip_h = dir < 0


func _on_beat(_i: int) -> void:
	if not dying and is_on_floor() and is_inside_tree():
		velocity.y = -110.0


func _on_body(body: Node) -> void:
	if dying or not body is Player:
		return
	var p: Player = body
	if p.velocity.y > 0.0 and p.global_position.y < global_position.y - 4.0:
		p.bounce()
		hit(signi(int(global_position.x - p.global_position.x)), true)
	else:
		p.hurt(global_position.x)


func hit(from_dir: int, stomp := false) -> void:
	if dying:
		return
	hp -= 2 if stomp else 1
	Music.sfx("colpo", 1.2)
	if hp > 0:
		velocity = Vector2(from_dir * 120.0, -120.0)
		sprite.modulate = Color(3, 3, 3)
		create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.2)
		return
	dying = true
	Game.add_score(points)
	get_tree().call_group("level", "float_text", "+%d" % points, global_position + Vector2(0, -16))
	sprite.play("hurt")
	hurtbox.set_deferred("monitoring", false)
	velocity = Vector2(from_dir * 60.0, -220.0)
	await get_tree().create_timer(1.5).timeout
	queue_free()
