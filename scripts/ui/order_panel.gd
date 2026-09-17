extends "res://scripts/ui/panel_shell.gd"

var cafe: Variant
var order_button: Button
var stock_label: Label
var staff_label: Label
var orders_label: Label
var refresh_elapsed: float = 0.0

func _ready() -> void:
	super._ready()
	set_title("订单与店内工作")
	stock_label = add_section("食材状况")
	staff_label = add_section("员工当前工作")
	orders_label = add_section("当前订单")

func add_section(heading: String) -> Label:
	var card: PanelContainer = PanelContainer.new()
	content.add_child(card)
	var box: VBoxContainer = VBoxContainer.new()
	card.add_child(box)
	var title: Label = Label.new()
	title.text = heading
	title.add_theme_font_size_override("font_size", 36)
	box.add_child(title)
	var body: Label = Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 30)
	box.add_child(body)
	return body

func _process(delta: float) -> void:
	refresh_elapsed += delta
	if refresh_elapsed >= 0.5 and is_instance_valid(cafe):
		refresh_elapsed = 0.0
		refresh()

func refresh() -> void:
	var foods: Dictionary = {"Beans":"咖啡豆", "Milk":"牛奶", "Syrup":"糖浆", "Flour":"面粉", "Cream":"奶油"}
	var drinks: Dictionary = {"Americano":"美式", "Latte":"拿铁", "Mocha":"摩卡", "Sea Salt Latte":"海盐拿铁"}
	var phases: Dictionary = {"queue":"排队中", "walking":"前往座位", "stairs_up":"上楼中", "seated":"等待接单", "ordered":"等待制作", "making":"制作中", "ready":"等待取餐", "drinking":"已送达 · 用餐中", "paying":"付款中"}
	var tasks: Dictionary = {"take":"接单", "make":"制作咖啡", "deliver":"送餐", "clean":"清洁桌面"}
	var shortages: PackedStringArray = []
	for drink in cafe.available_drinks():
		var recipe: Dictionary = cafe.menu_recipe(str(drink))
		var needs: Dictionary = recipe.get("ingredients", {})
		var missing: PackedStringArray = []
		for item in needs:
			if int(cafe.ingredients.get(item, 0)) < int(needs[item]):
				missing.append(str(foods.get(item, item)))
		if not missing.is_empty():
			shortages.append("%s：缺少%s" % [str(drinks.get(drink, drink)), "、".join(missing)])
	stock_label.text = "食材充足，当前上架饮品均可制作" if shortages.is_empty() else "\n".join(shortages) + "\n可到下方「补给」购买材料"
	stock_label.modulate = Color.WHITE if shortages.is_empty() else Color("#ffb789")
	var workers: PackedStringArray = []
	for worker in cafe.staff:
		if not is_instance_valid(worker) or not worker.assigned: continue
		var kind: String = str(worker.task.get("kind", ""))
		var action: String = "休息恢复体力" if worker.resting else "待命"
		if not kind.is_empty():
			var stage: String = str(worker.task.get("stage", ""))
			action = str(tasks.get(kind, "工作"))
			if kind == "deliver": action = "前往吧台取餐" if stage == "move_pickup" else "送餐前往桌位"
			elif stage == "move": action = "前往" + action
			else: action += "中"
		workers.append("%s · %d楼 · %s" % [worker.display_name, worker.floor_level, action])
	staff_label.text = "暂无上岗员工" if workers.is_empty() else "\n".join(workers)
	var lines: PackedStringArray = []
	for guest in cafe.customers:
		if not is_instance_valid(guest) or not phases.has(guest.phase): continue
		var place: String = "%d楼 · %d号桌" % [guest.floor_level, guest.table_index + 1] if guest.table_index >= 0 else "入口排队"
		var drink_name: String = str(drinks.get(guest.order, guest.order)) if guest.phase not in ["queue", "walking", "stairs_up"] else "尚未点单"
		var status: String = str(phases[guest.phase])
		if guest.phase in ["seated", "ordered"] and not cafe.ingredients_for(guest.order): status = "缺货，等待补给或改点"
		lines.append("%s · %s\n%s" % [place, drink_name, status])
	orders_label.text = "暂无订单，顾客进店后会显示在这里" if lines.is_empty() else "\n\n".join(lines)
	if is_instance_valid(order_button):
		order_button.text = "订单 %d%s" % [lines.size(), " !" if not shortages.is_empty() else ""]
