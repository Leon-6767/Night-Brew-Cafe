extends PanelContainer

var remove_callback: Callable

func setup(callback: Callable) -> void:
	remove_callback = callback

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and (data as Dictionary).has("night_brew_staff")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not remove_callback.is_valid(): return
	var payload: Dictionary = data as Dictionary
	remove_callback.call(str(payload.get("night_brew_staff", "")))
