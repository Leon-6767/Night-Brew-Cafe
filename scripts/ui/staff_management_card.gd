class_name StaffManagementCard
extends PanelContainer

func setup(data: Dictionary, assigned: bool, floor: int, stamina: int, loyalty: int, level: int, view_callback: Callable) -> void:
	for child in get_children(): child.queue_free()
	custom_minimum_size = Vector2(0, 166)
	var row: HBoxContainer = HBoxContainer.new(); row.add_theme_constant_override("separation", 16); add_child(row)
	var portrait: ColorRect = ColorRect.new(); portrait.color = quality_color(str(data.get("quality", "R"))); portrait.custom_minimum_size = Vector2(106, 112); row.add_child(portrait)
	var info: VBoxContainer = VBoxContainer.new(); info.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(info)
	var title: Label = Label.new(); title.text = "%s  ·  %s  ·  Lv.%d" % [str(data.get("name", "")), str(data.get("role", "")), level]; title.add_theme_font_size_override("font_size", 30); info.add_child(title)
	var detail: Label = Label.new(); detail.text = "%s · %d楼\n体力 %d  忠诚 %d  ·  制作 %d / 服务 %d / 清洁 %d" % ["上岗中" if assigned else "待岗中", floor, stamina, loyalty, int(data.get("make", 0)), int(data.get("service", 0)), int(data.get("clean", 0))]; detail.add_theme_font_size_override("font_size", 24); info.add_child(detail)
	var state: Label = Label.new(); state.text = str(data.get("skill", "")); state.add_theme_font_size_override("font_size", 22); info.add_child(state)
	var action: Button = Button.new(); action.text = "查看／管理"; action.custom_minimum_size = Vector2(185, 104); action.pressed.connect(view_callback); row.add_child(action)

func quality_color(quality: String) -> Color:
	if quality == "SSS": return Color("d8ad43")
	if quality == "SSR": return Color("8a63c9")
	if quality == "SR": return Color("4e91c9")
	return Color("719184")
