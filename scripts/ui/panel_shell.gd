class_name PanelShell
extends PanelContainer

var title_label: Label
var content: VBoxContainer
var footer: HBoxContainer

func _ready() -> void:
	var root: VBoxContainer = VBoxContainer.new(); root.add_theme_constant_override("separation", 14); add_child(root)
	var header: HBoxContainer = HBoxContainer.new(); root.add_child(header)
	title_label = Label.new(); title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL; title_label.add_theme_font_size_override("font_size", 40); header.add_child(title_label)
	var close: Button = Button.new(); close.text = "×"; close.custom_minimum_size = Vector2(70, 64); close.pressed.connect(hide); header.add_child(close)
	var scroll: ScrollContainer = ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; root.add_child(scroll)
	content = VBoxContainer.new(); content.size_flags_horizontal = Control.SIZE_EXPAND_FILL; content.add_theme_constant_override("separation", 12); scroll.add_child(content)
	footer = HBoxContainer.new(); footer.alignment = BoxContainer.ALIGNMENT_END; root.add_child(footer)

func set_title(value: String) -> void:
	if title_label: title_label.text = value
