extends PanelContainer

var staff_name: String = ""
var view_callback: Callable

func setup(data: Dictionary, assigned: bool, floor_level: int, view_action: Callable) -> void:
	staff_name = str(data.get("name", ""))
	view_callback = view_action
	for child in get_children(): child.queue_free()
	custom_minimum_size = Vector2(0, 104)
	var row: HBoxContainer = HBoxContainer.new(); row.add_theme_constant_override("separation", 12); add_child(row)
	var portrait: ColorRect = ColorRect.new(); portrait.color = quality_color(str(data.get("quality", "R"))); portrait.custom_minimum_size = Vector2(64, 64); row.add_child(portrait)
	var text_box: VBoxContainer = VBoxContainer.new(); text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(text_box)
	var title: Label = Label.new(); title.text = "%s [%s]" % [staff_name, str(data.get("quality", "R"))]; title.add_theme_font_size_override("font_size", 27); text_box.add_child(title)
	var status: Label = Label.new(); status.text = "%s · %s" % [str(data.get("role", "")), "%dF 上岗" % floor_level if assigned else "员工仓库"]; status.add_theme_font_size_override("font_size", 22); text_box.add_child(status)
	var view: Button = Button.new(); view.text = "查看" if assigned else "选择"; view.custom_minimum_size = Vector2(116, 64); view.pressed.connect(view_callback); row.add_child(view)

func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview: Label = Label.new(); preview.text = staff_name; preview.add_theme_font_size_override("font_size", 28)
	set_drag_preview(preview)
	return {"night_brew_staff": staff_name}

func quality_color(quality: String) -> Color:
	if quality == "SSS": return Color("d8ad43")
	if quality == "SSR": return Color("8a63c9")
	if quality == "SR": return Color("4e91c9")
	return Color("719184")
