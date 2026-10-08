class_name ActorVisual
extends Node2D

const Catalog = preload("res://scripts/visual_catalog.gd")

@onready var shadow: Sprite2D = $Shadow
@onready var body: Sprite2D = $Body
@onready var head: Sprite2D = $Head
@onready var role_badge: Sprite2D = $RoleBadge
@onready var state_icon: Sprite2D = $StateBubble/Icon
@onready var state_bubble: Node2D = $StateBubble
@onready var animator: AnimationPlayer = $AnimationPlayer
var moving: bool = false

func _ready() -> void:
	var library: AnimationLibrary = AnimationLibrary.new()
	for animation_name in ["idle", "walk", "make", "deliver", "clean"]:
		var animation: Animation = Animation.new()
		animation.length = 0.5
		animation.loop_mode = Animation.LOOP_LINEAR
		var track: int = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track, NodePath("Body:position"))
		animation.track_insert_key(track,0.0,Vector2(0,-8))
		animation.track_insert_key(track,0.25,Vector2(0,-11 if animation_name == "walk" else (-9 if animation_name == "idle" else -10)))
		animation.track_insert_key(track,0.5,Vector2(0,-8))
		var head_track: int = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(head_track,NodePath("Head:position"))
		animation.track_insert_key(head_track,0.0,Vector2(0,-22))
		animation.track_insert_key(head_track,0.25,Vector2(1 if animation_name == "clean" else 0,-24 if animation_name == "walk" else -23))
		animation.track_insert_key(head_track,0.5,Vector2(0,-22))
		library.add_animation(animation_name, animation)
	animator.add_animation_library("", library)

func configure(role_id: String, variant_id: String, tint: Color) -> void:
	var texture: Texture2D = Catalog.actor_texture(role_id, variant_id)
	body.texture = texture
	head.texture = texture
	# Placeholder textures contain the whole person, so a second copy is not a head.
	head.visible = false
	shadow.texture = texture
	shadow.position = Vector2(0,14)
	head.scale = Vector2(0.42, 0.42)
	head.position = Vector2(0, -22)
	body.modulate = tint
	role_badge.texture = Catalog.state_icon_texture()
	role_badge.visible = role_id != "Customer"
	state_icon.texture = Catalog.state_icon_texture()
	animator.play("idle")

func set_status(status: String, is_moving: bool) -> void:
	moving = is_moving
	state_bubble.visible = status in ["制作", "送餐", "清洁", "付款中", "等待不满", "Make", "Deliver", "Clean", "端咖啡送餐"]
	if moving: select_animation("walk")

func set_direction(direction: Vector2) -> void:
	if absf(direction.x) > 0.01:
		body.flip_h = direction.x < 0.0
		head.flip_h = body.flip_h

func select_animation(animation_name: String) -> void:
	if animator.current_animation != animation_name: animator.play(animation_name)

func play_task(task_name: String) -> void:
	if moving: select_animation("walk"); return
	select_animation(task_name if task_name in ["make", "deliver", "clean"] else "idle")
