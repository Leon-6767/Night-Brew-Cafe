class_name StaffCandidateCard
extends PanelContainer

func setup(data: Dictionary, view_callback: Callable) -> void:
	for child in get_children(): child.queue_free()
	custom_minimum_size = Vector2(0, 178)
	var row: HBoxContainer = HBoxContainer.new(); row.add_theme_constant_override("separation", 16); add_child(row)
	var portrait: ColorRect = ColorRect.new(); portrait.color = quality_color(str(data.get("quality", "R"))); portrait.custom_minimum_size = Vector2(112, 122); row.add_child(portrait)
	var info: VBoxContainer = VBoxContainer.new(); info.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(info)
	var name_label: Label = Label.new(); name_label.text = "%s  [%s]" % [str(data.get("name", "")), str(data.get("quality", "R"))]; name_label.add_theme_font_size_override("font_size", 32); info.add_child(name_label)
	var role_label: Label = Label.new(); role_label.text = "%s · %s\n制作 %d  服务 %d  清洁 %d" % [str(data.get("role", "")), str(data.get("personality", "")), int(data.get("make", 0)), int(data.get("service", 0)), int(data.get("clean", 0))]; role_label.add_theme_font_size_override("font_size", 25); info.add_child(role_label)
	var skill: Label = Label.new(); skill.text = str(data.get("skill", "")); skill.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; skill.add_theme_font_size_override("font_size", 23); info.add_child(skill)
	var action: Button = Button.new(); action.text = "查看\n签约 %d\n日薪 %d" % [int(data.get("fee", 0)), int(data.get("salary", 0))]; action.custom_minimum_size = Vector2(190, 118); action.pressed.connect(view_callback); row.add_child(action)

func quality_color(quality: String) -> Color:
	if quality == "SSS": return Color("d8ad43")
	if quality == "SSR": return Color("8a63c9")
	if quality == "SR": return Color("4e91c9")
	return Color("719184")
