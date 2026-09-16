class_name ResourceBar
extends PanelContainer

var value_label: Label

func _ready() -> void:
	value_label = Label.new(); value_label.add_theme_font_size_override("font_size", 28); add_child(value_label)

func set_values(coins: int, reputation: int, environment: int, day: int) -> void:
	if value_label: value_label.text = "◎ %d    ★ Lv.%d    ✦ %d    ◷ 第 %d 天" % [coins, reputation, environment, day]
