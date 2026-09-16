class_name ConfirmDialogCard
extends PanelContainer

var callback: Callable
var title_label: Label
var message_label: Label
var confirm_button: Button

func _ready() -> void:
	var box: VBoxContainer = VBoxContainer.new(); box.add_theme_constant_override("separation", 18); add_child(box)
	title_label = Label.new(); title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; title_label.add_theme_font_size_override("font_size", 42); box.add_child(title_label)
	message_label = Label.new(); message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; message_label.add_theme_font_size_override("font_size", 28); box.add_child(message_label)
	var actions: HBoxContainer = HBoxContainer.new(); actions.alignment = BoxContainer.ALIGNMENT_END; box.add_child(actions)
	var cancel: Button = Button.new(); cancel.text = "取消"; cancel.custom_minimum_size = Vector2(160, 76); cancel.pressed.connect(hide); actions.add_child(cancel)
	confirm_button = Button.new(); confirm_button.custom_minimum_size = Vector2(180, 76); confirm_button.pressed.connect(confirm); actions.add_child(confirm_button)

func show_confirmation(title_text: String, message: String, action_text: String, action_callback: Callable, danger: bool = false) -> void:
	callback = action_callback
	if title_label: title_label.text = title_text
	if message_label: message_label.text = message
	if confirm_button:
		confirm_button.text = action_text
		confirm_button.modulate = Color("e77d72") if danger else Color.WHITE
	show()

func confirm() -> void:
	hide()
	if callback.is_valid(): callback.call()
