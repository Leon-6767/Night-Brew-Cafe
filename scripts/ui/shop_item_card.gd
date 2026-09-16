class_name ShopItemCard
extends PanelContainer

var quantity: int = 1
var item_name: String = ""
var purchase_callback: Callable
var quantity_label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(0, 142)

func setup(item: String, stock: int, capacity: int, price: int, trend: String, callback: Callable) -> void:
	item_name = item
	purchase_callback = callback
	for child in get_children(): child.queue_free()
	var row: HBoxContainer = HBoxContainer.new(); row.add_theme_constant_override("separation", 16); add_child(row)
	var icon: TextureRect = TextureRect.new(); icon.custom_minimum_size = Vector2(92, 92); icon.modulate = Color("d8a65c"); row.add_child(icon)
	var info: VBoxContainer = VBoxContainer.new(); info.size_flags_horizontal = Control.SIZE_EXPAND_FILL; row.add_child(info)
	var title: Label = Label.new(); title.text = "%s  ·  库存 %d / %d" % [item, stock, capacity]; title.add_theme_font_size_override("font_size", 30); info.add_child(title)
	var detail: Label = Label.new(); detail.text = "今日 %s  ·  单价 %d 金币" % [trend, price]; detail.add_theme_font_size_override("font_size", 26); info.add_child(detail)
	var meter: ProgressBar = ProgressBar.new(); meter.max_value = max(1, capacity); meter.value = stock; meter.show_percentage = false; info.add_child(meter)
	var controls: VBoxContainer = VBoxContainer.new(); controls.custom_minimum_size = Vector2(240, 0); row.add_child(controls)
	var stepper: HBoxContainer = HBoxContainer.new(); controls.add_child(stepper)
	var minus: Button = Button.new(); minus.text = "−"; minus.custom_minimum_size = Vector2(58, 52); minus.pressed.connect(change_quantity.bind(-1)); stepper.add_child(minus)
	quantity_label = Label.new(); quantity_label.text = "1"; quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; quantity_label.custom_minimum_size = Vector2(64, 52); quantity_label.add_theme_font_size_override("font_size", 28); stepper.add_child(quantity_label)
	var plus: Button = Button.new(); plus.text = "+"; plus.custom_minimum_size = Vector2(58, 52); plus.pressed.connect(change_quantity.bind(1)); stepper.add_child(plus)
	var buy: Button = Button.new(); buy.text = "购买"; buy.custom_minimum_size = Vector2(0, 62); buy.pressed.connect(request_purchase); controls.add_child(buy)

func change_quantity(delta: int) -> void:
	quantity = clampi(quantity + delta, 1, 10)
	if quantity_label: quantity_label.text = str(quantity)

func request_purchase() -> void:
	if purchase_callback.is_valid(): purchase_callback.call(item_name, quantity)
