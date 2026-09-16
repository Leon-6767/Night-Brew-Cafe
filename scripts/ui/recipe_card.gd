class_name RecipeCard
extends PanelContainer

func setup(drink: String, recipe: Dictionary, researched: bool, active: bool, action_callback: Callable) -> void:
	for child in get_children(): child.queue_free()
	custom_minimum_size = Vector2(0, 148)
	var row: HBoxContainer = HBoxContainer.new(); row.add_theme_constant_override("separation", 16); add_child(row)
	var icon: ColorRect = ColorRect.new(); icon.color = Color("b98153"); icon.custom_minimum_size = Vector2(96, 96); row.add_child(icon)
	var info: VBoxContainer = VBoxContainer.new(); info.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(info)
	var title: Label = Label.new(); title.text = drink; title.add_theme_font_size_override("font_size", 32); info.add_child(title)
	var details: Label = Label.new(); details.text = "售价 %d · 制作 %.1f 秒 · 人气 %s\n原料 %s" % [int(recipe.get("price", 0)), float(recipe.get("time", 0.0)), str(recipe.get("popular", "")), str(recipe.get("ingredients", {}))]; details.add_theme_font_size_override("font_size", 24); info.add_child(details)
	var action: Button = Button.new(); action.text = ("下架" if active else "上架") if researched else "研发"; action.custom_minimum_size = Vector2(160, 86); action.pressed.connect(action_callback); row.add_child(action)
