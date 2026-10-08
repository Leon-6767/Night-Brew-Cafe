extends SceneTree

class TestCafe extends "res://scripts/main.gd":
	var test_time: int = 0
	func _ready() -> void: pass
	func _process(_delta: float) -> void: pass
	func save_game() -> void: pass
	func show_alert(_message: String) -> void: pass
	func update_ui() -> void: pass
	func _exit_tree() -> void: pass
	func current_unix() -> int: return replay_unix if replay_unix > 0 else test_time

func _initialize() -> void: call_deferred("run_checks")

func make_cafe() -> TestCafe:
	var cafe := TestCafe.new()
	cafe.test_time = int(Time.get_unix_time_from_system())
	root.add_child(cafe)
	cafe.shop_layer = Node2D.new()
	cafe.add_child(cafe.shop_layer)
	cafe.world = CafeWorld.new()
	cafe.shop_layer.add_child(cafe.world)
	cafe.active_calendar_date = cafe.calendar_date_key()
	cafe.sync_furniture_state()
	cafe.spawn_staff()
	cafe.phase = "Open"
	return cafe

func run_checks() -> void:
	seed(6767)
	var cafe := make_cafe()
	cafe.ingredients = {"Beans":10,"Milk":10,"Cream":10,"Syrup":10}
	cafe.spawn_customer()
	var guest: Customer = cafe.customers[0]
	guest.table_index = 0
	cafe.table_owner[0] = guest
	cafe.world.table_states[0] = "Making"
	guest.phase = "ordered"
	guest.order = "Latte"
	guest.customer_type = "普通顾客"
	guest.high_spender = false
	var lin: Staff = cafe.staff[0]
	lin.stamina = 23.0
	cafe.give_task(lin,{"kind":"make","guest":guest,"stage":"work","remaining":2.25,"target":lin.position})
	var runtime: Dictionary = JSON.parse_string(JSON.stringify(cafe.snapshot_runtime()))
	var full_save: Dictionary = JSON.parse_string(JSON.stringify(cafe.build_save_data()))
	assert(full_save.save_version == 3 and full_save.runtime.workers[0].task.guest_index == 0)
	var restored := make_cafe()
	restored.apply_save_data(full_save)
	restored.sync_furniture_state()
	restored.spawn_staff()
	restored.restore_runtime(restored.saved_runtime)
	assert(restored.customers.size() == 1 and restored.customers[0].phase == "ordered")
	assert(restored.table_owner[0] == restored.customers[0])
	assert(restored.staff[0].task.guest == restored.customers[0])
	assert(restored.staff[0].task.remaining == 2.25 and restored.staff[0].stamina == 23.0)
	assert(restored.reserved_ingredients.Beans == 1 and restored.reserved_ingredients.Milk == 1)
	restored.complete_task(restored.staff[0])
	assert(restored.ingredients.Beans == 9 and restored.customers[0].phase == "ready")
	var paid := make_cafe()
	paid.spawn_customer()
	paid.customers[0].phase = "leaving"
	paid.customers[0].payment_recorded = true
	paid.customers[0].patience = 0.1
	paid.customers[0].target_position = paid.customers[0].position
	paid.revenue = 42
	var paid_reopened := make_cafe()
	paid_reopened.apply_save_data(JSON.parse_string(JSON.stringify(paid.build_save_data())))
	paid_reopened.restore_runtime(paid_reopened.saved_runtime)
	paid_reopened.spawn_timer = 1000.0
	paid_reopened.simulate_business(1.0)
	assert(paid_reopened.revenue == 42 and paid_reopened.daily_angry_leaves == 0 and paid_reopened.customers.is_empty(), "Paid customer is not billed or penalized again")
	guest.phase = "drinking"
	guest.drink_timer = 4.0
	cafe.cancel_task(lin)
	cafe.daily_served = 3
	cafe.day_one_ready_to_close = true
	var closing_date: String = cafe.active_calendar_date
	cafe.real_time_closing = true
	cafe.close_day(false)
	assert(cafe.customers.is_empty() and cafe.reserved_ingredients.Beans == 0)
	assert(cafe.financial_days.size() == 1 and cafe.last_settled_date == closing_date)
	assert(cafe.financial_days[0].revenue == 18)
	var coins_after: int = cafe.coins
	cafe.close_day(false)
	assert(cafe.coins == coins_after and cafe.financial_days.size() == 1)
	cafe.test_time += 86400
	cafe.finalize_calendar_rollover()
	assert(cafe.active_calendar_date != closing_date and cafe.phase == "Open")
	assert(cafe.revenue == 0 and cafe.daily_served == 0)
	cafe.finalize_calendar_rollover()
	assert(cafe.financial_days.size() == 1)
	var offline := make_cafe()
	offline.day = 2
	offline.ingredients = {"Beans":40,"Milk":40,"Cream":10,"Syrup":10}
	offline.apply_offline_earnings(offline.test_time-600)
	assert(offline.daily_served > 0 and offline.daily_ingredient_cost > 0)
	assert(offline.ingredients.Beans >= 0 and offline.reserved_ingredients.get("Beans",0) <= offline.ingredients.Beans)
	var unavailable := make_cafe()
	unavailable.staff_assignments["Lin"] = false
	unavailable.spawn_staff()
	unavailable.apply_offline_earnings(unavailable.test_time-600)
	assert(unavailable.revenue == 0, "No barista means no offline sales")
	var paused_cafe := make_cafe()
	paused_cafe.paused = true
	paused_cafe.apply_offline_earnings(paused_cafe.test_time-600)
	assert(paused_cafe.revenue == 0 and paused_cafe.customers.is_empty())
	var midnight := make_cafe()
	var local: Dictionary = midnight.local_datetime()
	midnight.test_time -= int(local.hour)*3600 + int(local.minute)*60 + int(local.second)
	midnight.test_time += 120
	midnight.active_calendar_date = Time.get_date_string_from_unix_time(midnight.test_time-86400 + int(Time.get_time_zone_from_system().bias)*60)
	midnight.day = 2
	midnight.apply_offline_earnings(midnight.test_time-240)
	assert(midnight.financial_days.size() == 1 and midnight.active_calendar_date == midnight.calendar_date_key())
	var money: int = midnight.coins
	midnight.finalize_calendar_rollover()
	assert(midnight.financial_days.size() == 1 and midnight.coins == money)
	var capped := make_cafe()
	capped.day = 2
	capped.apply_offline_earnings(capped.test_time-86400)
	assert(capped.offline_minutes == 480, "Offline replay is capped at eight hours")
	assert(capped.revenue >= 0 and capped.ingredients.Beans >= 0)
	var legacy := make_cafe()
	legacy.apply_save_data({"day":5,"coins":321,"ingredients":{"Beans":7},"financial_days":[{"date":legacy.active_calendar_date}]})
	assert(legacy.coins == 321 and legacy.needs_new_calendar_day)
	var path: String = "user://persistence_regression.json"
	assert(SaveSystem.save_game({"save_version":3,"coins":111},path))
	assert(SaveSystem.save_game({"save_version":3,"coins":222},path))
	assert(SaveSystem.load_game(path).coins == 222)
	var corrupted := FileAccess.open(path,FileAccess.WRITE)
	corrupted.store_string("{interrupted")
	corrupted.close()
	assert(SaveSystem.load_game(path).coins == 111, "Corrupted save falls back to backup")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	print("PASS: JSON runtime round-trip, task/stock restoration, delivered-drink settlement, duplicate settlement guard, rollover reset, offline costs, role requirements, pause, legacy save, atomic write and backup recovery")
	for item in [cafe,restored,offline,unavailable,paused_cafe,legacy,midnight,capped,paid,paid_reopened]: item.queue_free()
	quit()
