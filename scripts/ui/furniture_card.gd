class_name FurnitureCard
extends PanelContainer

func setup(title_text: String, price: int, footprint: String, effect: String, action_text: String, action_callback: Callable, accent: Color = Color("b98153")) -> void:
	for child in get_children(): child.queue_free()
	custom_minimum_size = Vector2(0, 138)
	var row: HBoxContainer = HBoxContainer.new(); row.add_theme_constant_override("separation", 16); add_child(row)
	var icon: ColorRect = ColorRect.new(); icon.color = accent; icon.custom_minimum_size = Vector2(94, 90); row.add_child(icon)
	var info: VBoxContainer = VBoxContainer.new(); info.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(info)
	var title: Label = Label.new(); title.text = title_text; title.add_theme_font_size_override("font_size", 30); info.add_child(title)
	var details: Label = Label.new(); details.text = "占地 %s · %s · %d 金币" % [footprint, effect, price]; details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; details.add_theme_font_size_override("font_size", 24); info.add_child(details)
	var action: Button = Button.new(); action.text = action_text; action.custom_minimum_size = Vector2(150, 78); action.pressed.connect(action_callback); row.add_child(action)
