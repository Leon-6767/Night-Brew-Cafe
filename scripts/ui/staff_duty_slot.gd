extends PanelContainer

var floor_level: int = 1
var role_name: String = ""
var assignment_callback: Callable
var occupant_name: String = ""

func setup(slot_role: String, floor_value: int, occupant: Dictionary, slot_number: int, slot_total: int, callback: Callable) -> void:
	role_name = slot_role
	floor_level = floor_value
	assignment_callback = callback
	for child in get_children(): child.queue_free()
	custom_minimum_size = Vector2(0, 104)
	var box: VBoxContainer = VBoxContainer.new(); add_child(box)
	var title: Label = Label.new(); title.text = "%dF · %s  %d/%d" % [floor_level, display_role(role_name), slot_number, slot_total]; title.add_theme_font_size_override("font_size", 23); box.add_child(title)
	occupant_name = str(occupant.get("name", ""))
	var body: Label = Label.new(); body.text = "%s · 拖动可换人" % occupant_name if occupant_name != "" else "空岗位 · 从员工仓库拖入"; body.add_theme_font_size_override("font_size", 26); box.add_child(body)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and (data as Dictionary).has("night_brew_staff")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not assignment_callback.is_valid(): return
	var payload: Dictionary = data as Dictionary
	assignment_callback.call(str(payload.get("night_brew_staff", "")), floor_level, role_name)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if occupant_name == "": return null
	var preview: Label = Label.new(); preview.text = occupant_name; preview.add_theme_font_size_override("font_size", 28)
	set_drag_preview(preview)
	return {"night_brew_staff": occupant_name}

func _gui_input(event: InputEvent) -> void:
	if occupant_name != "": return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if assignment_callback.is_valid(): assignment_callback.call("", floor_level, role_name)
		accept_event()
	if event is InputEventScreenTouch and event.pressed:
		if assignment_callback.is_valid(): assignment_callback.call("", floor_level, role_name)
		accept_event()

func display_role(value: String) -> String:
	var names: Dictionary = {"Barista":"咖啡师", "Waiter":"服务员", "Cleaner":"清洁员", "Manager":"店长"}
	return str(names.get(value, value))
