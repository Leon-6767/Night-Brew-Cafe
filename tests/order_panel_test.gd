extends SceneTree

class TestCafe extends Node:
	var ingredients: Dictionary = {"Beans": 2, "Milk": 0}
	var staff: Array = []
	var customers: Array = []
	func available_drinks() -> Array[String]: return ["Latte"]
	func menu_recipe(_drink: String) -> Dictionary: return {"ingredients": {"Beans": 1, "Milk": 1}}
	func ingredients_for(_drink: String) -> bool: return int(ingredients.get("Milk", 0)) > 0

func _initialize() -> void:
	call_deferred("check_panel")

func check_panel() -> void:
	var cafe: TestCafe = TestCafe.new()
	root.add_child(cafe)
	var panel: Variant = preload("res://scripts/ui/order_panel.gd").new()
	root.add_child(panel)
	panel.cafe = cafe
	var button: Button = Button.new()
	root.add_child(button)
	panel.order_button = button
	panel.refresh()
	assert(panel.stock_label.text.contains("缺少牛奶"))
	assert(button.text.contains("!"))
	cafe.ingredients["Milk"] = 2
	panel.refresh()
	assert(panel.stock_label.text.contains("食材充足"))
	assert(not button.text.contains("!"))
	assert(panel.orders_label.text.contains("暂无订单"))
	var worker: Staff = Staff.new()
	worker.display_name = "June"
	worker.assigned = true
	worker.task = {"kind":"deliver", "stage":"move_pickup"}
	cafe.staff.append(worker)
	panel.refresh()
	assert(panel.staff_label.text.contains("June"))
	assert(panel.staff_label.text.contains("前往吧台取餐"))
	worker.task["stage"] = "move_table"
	panel.refresh()
	assert(panel.staff_label.text.contains("送餐前往桌位"))
	worker.free()
	panel.refresh()
	print("PASS: shortage, replenishment, empty orders, live tasks, freed actor guard")
	quit()
