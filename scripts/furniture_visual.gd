class_name FurnitureVisual
extends Node2D

const Catalog = preload("res://scripts/visual_catalog.gd")

@export var furniture_id: String = "SingleTable"
@export var texture_override: Texture2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var state_icon: Sprite2D = $StateIcon

func configure(item_id: String, state: String = "") -> void:
	furniture_id = item_id
	sprite.texture = texture_override if texture_override else Catalog.furniture_texture(furniture_id)
	state_icon.texture = Catalog.state_icon_texture()
	state_icon.visible = state in ["Occupied", "Dirty", "Ready"]
	if state == "Dirty": state_icon.modulate = Color("#d97d68")
	elif state == "Ready": state_icon.modulate = Color("#f3d27a")
	else: state_icon.modulate = Color.WHITE
