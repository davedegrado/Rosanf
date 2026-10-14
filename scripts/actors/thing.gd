class_name Thing
extends Area2D
## Qualsiasi oggetto interattivo della mappa: raccoglibili, NPC, pericoli, uscite.
## Il comportamento dipende da `kind`; il livello gestisce gli effetti tramite il segnale `touched`.

signal touched(thing: Thing)

const SPRITES := {
	"uranio": "res://assets/sprites/uranio.png",
	"bottiglia": "res://assets/sprites/bottiglia.png",
	"fungo": "res://assets/sprites/fungo.png",
	"merda": "res://assets/sprites/merda.png",
	"scopa": "res://assets/sprites/scopa.png",
	"farfalla": "res://assets/sprites/farfalla.png",
	"pianta_mutante": "res://assets/sprites/pianta_mutante.png",
	"porta": "res://assets/sprites/porta.png",
	"crepa": "res://assets/sprites/crepa.png",
}
const SIZES := {"porta": Vector2(32, 32), "crepa": Vector2(32, 48), "pecora": Vector2(24, 16),
	"donna": Vector2(16, 24), "donna_ballo": Vector2(16, 24)}

var kind := ""
var active := true      # per porta/crepa: diventa true quando l'obiettivo è completato
var sprite: AnimatedSprite2D
var _t := randf() * TAU
var _origin := Vector2.ZERO
var _used := false


func _ready() -> void:
	collision_layer = 8
	collision_mask = 2
	monitorable = false
	sprite = AnimatedSprite2D.new()
	match kind:
		"donna", "donna_ballo":
			sprite.sprite_frames = SpriteUtil.frames_from_sheet("res://assets/sprites/donna")
			sprite.play("idle")
		"pecora":
			sprite.sprite_frames = SpriteUtil.frames_from_sheet("res://assets/sprites/pecora")
			sprite.play("idle")
		_:
			var fw := int(SIZES.get(kind, Vector2(16, 16)).x)
			sprite.sprite_frames = SpriteUtil.frames_strip(SPRITES[kind], fw, 4.0 if kind != "farfalla" else 8.0)
			if kind in ["porta", "crepa"]:
				sprite.frame = 1 if active else 0
			else:
				sprite.play("default")
	add_child(sprite)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZES.get(kind, Vector2(12, 12)) - Vector2(4, 2)
	shape.shape = rect
	add_child(shape)
	body_entered.connect(_on_body)
	_origin = position
	if kind in ["uranio", "pianta_mutante", "donna_ballo"]:
		Music.beat.connect(_on_beat)
	if kind == "pianta_mutante":
		sprite.pause()
	if kind == "donna_ballo":
		sprite.play("dance")
		sprite.pause()
		monitoring = false


func set_active(v: bool) -> void:
	active = v
	if kind in ["porta", "crepa"]:
		sprite.frame = 1 if v else 0
		if v:
			var tw := create_tween().set_loops(4)
			tw.tween_property(sprite, "modulate", Color(2, 2, 2), 0.1)
			tw.tween_property(sprite, "modulate", Color.WHITE, 0.1)


func _process(delta: float) -> void:
	_t += delta
	match kind:
		"bottiglia", "fungo", "scopa", "merda":
			position.y = _origin.y + sin(_t * 3.0) * 1.5
		"farfalla":
			position = _origin + Vector2(sin(_t * 0.9) * 24.0, sin(_t * 2.1) * 8.0)
			sprite.flip_h = cos(_t * 0.9) < 0


## Sincronizzazione musicale: piante e ballerine si muovono a tempo.
func _on_beat(i: int) -> void:
	if not is_inside_tree():
		return
	match kind:
		"uranio":
			sprite.scale = Vector2(1.25, 1.25)
			create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.15)
		"pianta_mutante":
			sprite.frame = i % 2
		"donna_ballo":
			sprite.frame = i % sprite.sprite_frames.get_frame_count("dance")


func _on_body(body: Node) -> void:
	if body is Player and not _used and not (body as Player).dead:
		touched.emit(self)


func consume() -> void:
	_used = true
	set_deferred("monitoring", false)
	var tw := create_tween().set_parallel()
	tw.tween_property(self, "scale", Vector2(1.6, 1.6), 0.15)
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.chain().tween_callback(queue_free)
