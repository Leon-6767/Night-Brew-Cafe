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

func _ready() -> void:
	var library: AnimationLibrary = AnimationLibrary.new()
	for animation_name in ["idle", "walk", "make", "deliver", "clean"]:
		var animation: Animation = Animation.new()
		animation.length = 0.5
		animation.loop_mode = Animation.LOOP_LINEAR
		library.add_animation(animation_name, animation)
	animator.add_animation_library("", library)

func configure(role_id: String, variant_id: String, tint: Color) -> void:
	var texture: Texture2D = Catalog.actor_texture(role_id, variant_id)
	body.texture = texture
	head.texture = texture
	head.scale = Vector2(0.42, 0.42)
	head.position = Vector2(0, -22)
	body.modulate = tint
	role_badge.texture = Catalog.state_icon_texture()
	role_badge.visible = role_id != "Customer"
	state_icon.texture = Catalog.state_icon_texture()
	animator.play("idle")

func set_status(status: String, moving: bool) -> void:
	state_bubble.visible = status in ["制作", "送餐", "清洁", "付款中", "等待不满"]
	if moving and animator.current_animation != "walk": animator.play("walk")
	elif not moving and animator.current_animation == "walk": animator.play("idle")

func play_task(task_name: String) -> void:
	if task_name == "make": animator.play("make")
	elif task_name == "deliver": animator.play("deliver")
	elif task_name == "clean": animator.play("clean")
