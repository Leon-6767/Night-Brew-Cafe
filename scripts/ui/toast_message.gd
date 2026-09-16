class_name ToastMessage
extends PanelContainer

var label: Label
var timer: Timer

func _ready() -> void:
	label = Label.new(); label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; label.add_theme_font_size_override("font_size", 28); add_child(label)
	timer = Timer.new(); timer.one_shot = true; timer.timeout.connect(hide); add_child(timer)

func show_toast(message: String) -> void:
	if label: label.text = message
	show()
	if timer: timer.start(2.5)
