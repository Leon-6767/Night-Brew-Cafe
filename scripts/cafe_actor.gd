class_name CafeActor
extends Node2D

const CharacterVisualScene = preload("res://scenes/actors/CharacterVisual.tscn")

var display_name: String = ""
var role: String = ""
var state_text: String = ""
var target_position: Vector2 = Vector2.ZERO
var move_speed: float = 120.0
var is_moving: bool = false
var visual: Node2D


func _ready() -> void:
	visual = CharacterVisualScene.instantiate()
	add_child(visual)
	visual.call("configure", role, display_name, Color.WHITE)

func refresh_visual(task_name: String = "") -> void:
	if not visual: return
	visual.call("set_status", state_text, is_moving)
	if task_name != "": visual.call("play_task", task_name)


func move_toward_target(delta: float) -> void:
	var remaining: float = position.distance_to(target_position)
	if remaining <= 1.0:
		position = target_position
		is_moving = false
		return
	position = position.move_toward(target_position, move_speed * delta)
	is_moving = true
	refresh_visual()
