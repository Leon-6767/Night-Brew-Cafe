extends SceneTree

class TestCafe extends "res://scripts/main.gd":
	func _ready() -> void: pass
	func _process(_delta: float) -> void: pass
	func simulate(delta: float) -> void: super._process(delta)
	func save_game() -> void: pass
	func show_alert(_message: String) -> void: pass
	func update_ui() -> void: pass
	func _exit_tree() -> void: pass

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	seed(6767)
	var cafe := TestCafe.new()
	root.add_child(cafe)
	cafe.shop_layer = Node2D.new()
	cafe.add_child(cafe.shop_layer)
	cafe.world = CafeWorld.new()
	cafe.shop_layer.add_child(cafe.world)
	cafe.sync_furniture_state()
	cafe.phase = "Open"
	cafe.spawned_today = 3
	cafe.spawn_customer()
	assert(cafe.customers.size() == 1, "Day one must accept a fourth customer")
	var guest: Customer = cafe.customers[0]
	guest.phase = "ordered"
	guest.order = "Latte"
	cafe.ingredients = {"Beans":1, "Milk":1}
	var first := Staff.new()
	var second := Staff.new()
	cafe.shop_layer.add_child(first)
	cafe.shop_layer.add_child(second)
	cafe.staff.append_array([first, second])
	cafe.give_task(first, {"kind":"make", "guest":guest, "target":Vector2.ZERO, "stage":"work", "remaining":0.0})
	cafe.give_task(second, {"kind":"make", "guest":guest, "target":Vector2.ZERO, "stage":"work", "remaining":0.0})
	assert(second.task.is_empty(), "Only one worker may reserve an order")
	assert(not cafe.ingredients_for("Latte"), "Reserved stock is unavailable")
	cafe.complete_task(first)
	assert(cafe.ingredients.Beans == 0 and cafe.ingredients.Milk == 0)
	assert(cafe.reserved_ingredients.Beans == 0)
	cafe.world.table_states[0] = "Dirty"
	cafe.give_task(first, {"kind":"clean", "table":0, "target":Vector2.ZERO, "stage":"work", "remaining":0.0})
	cafe.give_task(second, {"kind":"clean", "table":0, "target":Vector2.ZERO, "stage":"work", "remaining":0.0})
	assert(second.task.is_empty(), "A dirty table must have one cleaner")
	cafe.complete_task(first)
	assert(cafe.world.table_states[0] == "Free")
	cafe.furniture_items.append({"id":1,"type":"DoubleTable","x":2,"y":6,"rotation":1,"floor":1})
	cafe.sync_furniture_state()
	assert(cafe.active_table_cells()[-1] == Vector2i(2,7), "Rotated seat follows footprint")
	guest.table_index = cafe.table_keys.find("furniture:1:0")
	cafe.table_owner[guest.table_index] = guest
	cafe.world.table_states[guest.table_index] = "Ready"
	cafe.second_floor_unlocked = true
	cafe.second_floor_level = 1
	cafe.sync_furniture_state()
	assert(cafe.table_keys[guest.table_index] == "furniture:1:0", "Expansion preserves table identity")
	assert(cafe.table_owner[guest.table_index] == guest)
	cafe.furniture_items.clear()
	cafe.sync_furniture_state()
	assert(cafe.customers.is_empty(), "Removing an occupied table retires its customer safely")
	assert(cafe.table_owner.size() == 7 and cafe.world.table_states.size() == 7)
	cafe.ingredients = {"Beans":1,"Milk":1}
	var waiting := Customer.new()
	cafe.shop_layer.add_child(waiting)
	cafe.customers.append(waiting)
	waiting.order = "Latte"
	cafe.give_task(first, {"kind":"make", "guest":waiting, "target":Vector2.ZERO, "stage":"move", "remaining":1.0})
	cafe.remove_customer(waiting)
	assert(first.task.is_empty() and cafe.ingredients_for("Latte"), "Cancellation releases stock")
	cafe.staff.clear()
	first.queue_free()
	second.queue_free()
	cafe.spawn_staff()
	var lin: Staff = cafe.staff[0]
	lin.stamina = 12.0
	lin.task = {"kind":"transfer","target":Vector2.ONE,"stage":"move","remaining":0.0}
	cafe.spawn_staff()
	assert(cafe.staff[0] == lin and lin.stamina == 12.0 and not lin.task.is_empty(), "Roster refresh preserves workers")
	cafe.cancel_task(lin)
	lin.stamina = 75.0
	cafe.second_floor_unlocked = false
	cafe.sync_furniture_state()
	cafe.ingredients = {"Beans":100,"Milk":100,"Syrup":100,"Cream":100}
	cafe.spawned_today = 0
	cafe.daily_served = 0
	cafe.spawn_timer = 0.0
	for frame in 2400:
		cafe.simulate(0.1)
	assert(cafe.daily_served > 3, "Full day-one simulation must serve more than three guests")
	assert(cafe.ingredients.Beans >= 0 and cafe.ingredients.Milk >= 0)
	for index in cafe.table_owner.size():
		var owner = cafe.table_owner[index]
		if cafe.world.table_states[index] == "Free": assert(owner == null)
	print("PASS: 240 simulated seconds, served ", cafe.daily_served, " guests with valid table ownership")
	cafe.second_floor_unlocked = true
	cafe.second_floor_level = 1
	cafe.sync_furniture_state()
	for role in ["Barista","Waiter","Cleaner"]:
		var worker := Staff.new()
		worker.role = role
		worker.floor_level = 2
		worker.navigation_floor = 2
		worker.position = cafe.staff_station_point(role,2,worker)
		worker.target_position = worker.position
		cafe.shop_layer.add_child(worker)
		cafe.staff.append(worker)
	cafe.ingredients = {"Beans":150,"Milk":150,"Syrup":150,"Cream":150}
	cafe.event_modifiers["vip"] = true
	cafe.queue_limit = 12
	for frame in 3600: cafe.simulate(0.1)
	assert(cafe.second_floor_served > 0, "Second floor must complete orders and payments")
	assert(cafe.ingredients.Beans >= 0 and cafe.ingredients.Milk >= 0)
	print("PASS: simultaneous two-floor operation, upstairs served ", cafe.second_floor_served)
	print("PASS: day-one continuation, exclusive tasks, stock reservations, cancellation, stable table IDs, rotated seats, roster preservation")
	cafe.queue_free()
	quit()
