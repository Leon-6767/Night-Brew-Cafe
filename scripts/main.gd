extends Node2D

const CustomerScript = preload("res://scripts/customer.gd")
const StaffScript = preload("res://scripts/staff.gd")
const NightBrewTheme = preload("res://themes/night_brew_theme.tres")
const ShopItemCardScene = preload("res://scenes/ui/ShopItemCard.tscn")
const StaffCandidateCardScene = preload("res://scenes/ui/StaffCandidateCard.tscn")
const StaffManagementCardScene = preload("res://scenes/ui/StaffManagementCard.tscn")
const RecipeCardScene = preload("res://scenes/ui/RecipeCard.tscn")
const FurnitureCardScene = preload("res://scenes/ui/FurnitureCard.tscn")
const ConfirmDialogScene = preload("res://scenes/ui/ConfirmDialog.tscn")
const StaffRosterCardScene = preload("res://scenes/ui/StaffRosterCard.tscn")
const StaffDutySlotScene = preload("res://scenes/ui/StaffDutySlot.tscn")
const StaffWarehouseDropScene = preload("res://scenes/ui/StaffWarehouseDrop.tscn")
const TEST_MODE_FORCE_DAY_ONE: bool = false
const TABLES: Array[Vector2i] = [Vector2i(3,4),Vector2i(6,4),Vector2i(3,7),Vector2i(6,7),Vector2i(5,9)]
const QUEUE: Array[Vector2i] = [Vector2i(9,9),Vector2i(8,9),Vector2i(9,8)]
const STATIONS: Dictionary = {"Barista":Vector2i(3,2), "Waiter":Vector2i(2,5), "Cleaner":Vector2i(8,5), "Manager":Vector2i(5,2), "Rest":Vector2i(8,8)}

var world: CafeWorld
var shop_layer: Node2D
var world_camera: Camera2D
# Includes the rear wall, the left wall, the front entrance and the staff rest corner.
# Future expansions only need to enlarge this rectangle.
var camera_bounds: Rect2 = Rect2(-180, 90, 1430, 850)
var camera_target_zoom: float = 1.0
var camera_velocity: Vector2 = Vector2.ZERO
var camera_dragging: bool = false
var last_drag_position: Vector2 = Vector2.ZERO
var touch_points: Dictionary = {}
var last_pinch_distance: float = 0.0
var phase := "Closed"
var day := 1
var elapsed := 0.0
var world_minutes: float = 480.0
var speed_multiplier := 1.0
var paused: bool = false
var spawn_timer := 0.0
var revenue := 0
var daily_ingredient_cost: int = 0
var daily_spoilage_cost: int = 0
var daily_stockout_losses: int = 0
var daily_angry_leaves: int = 0
var daily_served: int = 0
var drink_counts: Dictionary = {}
var spawned_today: int = 0
var day_one_ready_to_close: bool = false
var coins := 800
var owned_staff: Dictionary = {"Lin":true,"June":true,"Bo":true,"Ari":true}
var staff_assignments: Dictionary = {"Lin":true,"June":true,"Bo":false,"Ari":false}
var staff_floors: Dictionary = {"Lin":1,"June":1,"Bo":1,"Ari":1}
var staff_loyalty: Dictionary = {}
var staff_stars: Dictionary = {}
var satisfaction := 100.0
var ingredients: Dictionary = {"Beans":30,"Milk":25,"Syrup":18,"Flour":12,"Cream":12}
var market_prices: Dictionary = {"Beans":2,"Milk":3,"Syrup":3,"Flour":2,"Cream":4}
var market_trends: Dictionary = {}
var market_price_day: int = 0
var fridge_level: int = 0
var researched_menu: Dictionary = {"Americano":true,"Latte":true,"Mocha":false,"Sea Salt Latte":false}
var active_menu: Dictionary = {"Americano":true,"Latte":true,"Mocha":false,"Sea Salt Latte":false}
var upgrades: Dictionary = {"Machine":1,"Register":1,"Tables":1}
var customers: Array[Customer] = []
var staff: Array[Staff] = []
var table_owner: Array = [null,null,null,null,null]
var orders: Array[Dictionary] = []
var hud_label: Label
var debug_label: Label
var alert_label: Label
var staff_panel: PanelContainer
var debug_panel: PanelContainer
var selected_actor: CafeActor
var selection_card: Label
var prep_panel: PanelContainer
var settlement_panel: PanelContainer
var prep_label: Label
var settlement_label: Label
var end_day_button: Button
var supply_panel: PanelContainer
var supply_label: Label
var supply_list_box: VBoxContainer
var menu_panel: PanelContainer
var menu_label: Label
var menu_list: VBoxContainer
var market_panel: PanelContainer
var market_label: Label
var market_candidates_box: VBoxContainer
var market_candidates: Array[Dictionary] = []
var market_day: int = 0
var market_refreshes_today: int = 0
var reputation: int = 1
var reputation_points: int = 0
var coffee_competition_complete: bool = false
var current_event: Dictionary = {}
var event_day: int = 0
var event_resolved: bool = false
var event_result_text: String = ""
var event_label: Label
var event_choice_a: Button
var event_choice_b: Button
var event_modifiers: Dictionary = {"traffic":1.0,"student":false,"blogger":false,"vip":false,"sick":false,"competition":false}
var cleaning_room_level: int = 0
var second_floor_unlocked: bool = false
var second_floor_level: int = 0
var second_floor_revenue: int = 0
var second_floor_served: int = 0
var second_floor_satisfaction_total: float = 0.0
var second_floor_ingredient_cost: int = 0
var active_decor_floor: int = 1
var unlocks: Dictionary = {"Mocha":false,"SecondBarista":false,"PastryCase":false,"TalentMarket":false,"SeaSaltLatte":false}
var employee_levels: Dictionary = {}
var queue_limit := 3
var sss_active := false
var furniture_items: Array[Dictionary] = []
var expansions: Dictionary = {"LeftWindow": false}
var decor_panel: PanelContainer
var decor_label: Label
var decor_cards_box: VBoxContainer
var decor_pending_type: String = ""
var decor_pending_price: int = 0
var decor_rotation: int = 0
var decor_selected_id: int = -1
var next_furniture_id: int = 1
var environment_score: int = 0
var ui_layer: CanvasLayer
var ui_root: Control
var settings_panel: PanelContainer
var staff_list_box: VBoxContainer
var confirm_dialog: Variant
var selected_roster_staff: String = ""
var ui_size_mode: String = "大"
var ui_scale_factor: float = 1.15
var game_orientation: String = "横屏"
var offline_earnings: int = 0
var offline_minutes: int = 0
var settled_real_date: String = ""
var real_time_closing: bool = false
var active_calendar_date: String = ""
var needs_new_calendar_day: bool = true
var financial_days: Array[Dictionary] = []
var finance_panel: PanelContainer
var finance_label: Label
var first_floor_button: Button
var second_floor_button: Button

var furniture_catalog: Dictionary = {
	"SingleTable": {"name":"单人桌","price":80,"size":Vector2i(1,1),"effect":"+1 桌位"},
	"DoubleTable": {"name":"双人桌","price":130,"size":Vector2i(2,1),"effect":"+2 桌位"},
	"CoffeeMachine": {"name":"咖啡机","price":180,"size":Vector2i(1,1),"effect":"制作更快 · +1 咖啡师岗位"},
	"Register": {"name":"收银台","price":140,"size":Vector2i(1,1),"effect":"付款更顺畅"},
	"Sofa": {"name":"沙发","price":90,"size":Vector2i(1,1),"effect":"环境 +3"},
	"Plant": {"name":"盆栽","price":45,"size":Vector2i(1,1),"effect":"环境 +2"}
}

var employee_data: Array[Dictionary] = [
	{"name":"Lin","role":"Barista","quality":"R","make":2,"service":1,"clean":1,"stamina":75,"loyalty":68,"skill":"标准萃取：基础制作效率"},
	{"name":"Bo","role":"Cleaner","quality":"R","make":1,"service":1,"clean":3,"stamina":88,"loyalty":60,"skill":"利落收拾：基础清洁效率"},
	{"name":"Akio","role":"Waiter","quality":"R","make":1,"service":2,"clean":1,"stamina":78,"loyalty":60,"skill":"熟练端盘：基础送餐效率"},
	{"name":"Mei","role":"Cleaner","quality":"R","make":1,"service":1,"clean":2,"stamina":82,"loyalty":64,"skill":"整洁习惯：顾客耐心 +2"},
	{"name":"June","role":"Waiter","quality":"SR","make":1,"service":4,"clean":1,"stamina":82,"loyalty":72,"skill":"热情招待：服务速度明显提升"},
	{"name":"Ari","role":"Manager","quality":"SR","make":1,"service":2,"clean":2,"stamina":90,"loyalty":85,"skill":"店务协调：全员移动效率提升"},
	{"name":"Nora","role":"Barista","quality":"SSR","make":5,"service":2,"clean":1,"stamina":94,"loyalty":80,"skill":"大师萃取：全店咖啡制作更快"},
	{"name":"夜班经理·星野澪","role":"Manager","quality":"SSS","make":3,"service":4,"clean":2,"stamina":100,"loyalty":100,"skill":"午夜特调：夜蓝氛围、VIP 概率与特调收益提升"}
]

func _ready() -> void:
	# Gameplay uses direct 2:1 isometric grid projection; UI remains upright in CanvasLayer.
	shop_layer = Node2D.new()
	add_child(shop_layer)
	world = CafeWorld.new(); shop_layer.add_child(world)
	world_camera = Camera2D.new()
	world_camera.name = "WorldCamera"
	world_camera.position = camera_bounds.get_center()
	world_camera.zoom = Vector2.ONE
	world_camera.position_smoothing_enabled = true
	world_camera.position_smoothing_speed = 8.0
	world.add_child(world_camera)
	if TEST_MODE_FORCE_DAY_ONE: SaveSystem.reset_game()
	else: load_save()
	apply_game_orientation(false)
	sync_furniture_state(); refresh_market_for_day(); refresh_market_prices(); spawn_staff(); build_ui(); update_ui()
	update_world_clock()
	finalize_calendar_rollover()
	begin_auto_business()

func begin_auto_business() -> void:
	# Permanent 24-hour operation never needs the legacy preparation or settlement modal.
	# They may be visible by default when a same-day save is reopened.
	if prep_panel:
		prep_panel.hide()
	if settlement_panel:
		settlement_panel.hide()
	event_resolved = true
	if needs_new_calendar_day:
		start_day()
		needs_new_calendar_day = false
	else:
		phase = "Open"
		spawn_timer = 0.1
	if offline_earnings > 0:
		show_alert("离线营业 %d 分钟：获得 %d 金币" % [offline_minutes, offline_earnings])
	else:
		show_alert("咖啡店已自动营业")

func apply_offline_earnings(last_unix: int) -> void:
	if last_unix <= 0: return
	var now_unix: int = int(Time.get_unix_time_from_system())
	offline_minutes = clampi((now_unix - last_unix) / 60, 0, 480)
	var cycles: int = offline_minutes / 3
	var available_workers: int = 0
	for data in employee_data:
		var staff_name: String = str(data.get("name", ""))
		if bool(owned_staff.get(staff_name, false)) and bool(staff_assignments.get(staff_name, false)): available_workers += 1
	cycles = mini(cycles, available_workers * 40)
	for i in cycles:
		if int(ingredients.get("Beans", 0)) <= 0: break
		ingredients["Beans"] = int(ingredients.get("Beans", 0)) - 1
		var sale: int = 12
		if int(ingredients.get("Milk", 0)) > 0:
			ingredients["Milk"] = int(ingredients.get("Milk", 0)) - 1
			sale = 18
		coins += sale
		revenue += sale
		daily_served += 1
		offline_earnings += sale

func _process(delta: float) -> void:
	var dt: float = 0.0 if paused else delta * speed_multiplier
	update_world_clock()
	finalize_calendar_rollover()
	update_camera(delta)
	move_visible_actors(dt)
	for worker in staff: worker.tick_staff(dt); advance_staff(worker, dt)
	if phase == "Open":
		elapsed += dt; spawn_timer -= dt
		if spawn_timer <= 0.0:
			spawn_customer()
			spawn_timer = 5.0
		for guest in customers.duplicate(): advance_customer(guest, dt)
		assign_tasks()
	update_ui()

func move_visible_actors(delta: float) -> void:
	var actors: Array = []
	actors.append_array(staff)
	actors.append_array(customers)
	for actor in actors:
		if actor.position.distance_to(actor.target_position) > 3.0:
			var movement_multiplier: float = 0.72 if actor is Staff and bool(event_modifiers.get("sick", false)) else 1.0
			actor.position = actor.position.move_toward(actor.target_position, actor.move_speed * movement_multiplier * delta)
			actor.is_moving = true
		else:
			actor.is_moving = false
		actor.z_index = int(actor.position.y)

func update_camera(delta: float) -> void:
	if not world_camera: return
	var desired_zoom: Vector2 = Vector2(camera_target_zoom, camera_target_zoom)
	world_camera.zoom = world_camera.zoom.lerp(desired_zoom, minf(delta * 10.0, 1.0))
	if not camera_dragging and camera_velocity.length() > 1.0:
		world_camera.position += camera_velocity * delta
		camera_velocity = camera_velocity.lerp(Vector2.ZERO, minf(delta * 9.0, 1.0))
	clamp_camera()

func clamp_camera() -> void:
	if not world_camera: return
	var view_size: Vector2 = get_viewport_rect().size / world_camera.zoom
	var half_view: Vector2 = view_size * 0.5
	var center: Vector2 = camera_bounds.get_center()
	var min_x: float = camera_bounds.position.x + half_view.x
	var max_x: float = camera_bounds.end.x - half_view.x
	var min_y: float = camera_bounds.position.y + half_view.y
	var max_y: float = camera_bounds.end.y - half_view.y
	world_camera.position.x = center.x if min_x > max_x else clampf(world_camera.position.x, min_x, max_x)
	world_camera.position.y = center.y if min_y > max_y else clampf(world_camera.position.y, min_y, max_y)

func pan_camera(delta_screen: Vector2) -> void:
	world_camera.position -= delta_screen / world_camera.zoom
	camera_velocity = -delta_screen / world_camera.zoom * 5.0
	clamp_camera()

func set_camera_zoom(value: float, focus: Vector2 = Vector2.ZERO) -> void:
	var old_zoom: float = camera_target_zoom
	camera_target_zoom = clampf(value, 0.75, 1.65)
	if focus != Vector2.ZERO:
		var viewport_center: Vector2 = get_viewport_rect().size * 0.5
		world_camera.position += (focus - viewport_center) * (1.0 / old_zoom - 1.0 / camera_target_zoom)
	clamp_camera()

func reset_world_camera() -> void:
	camera_target_zoom = 1.0
	world_camera.position = camera_bounds.get_center()
	camera_velocity = Vector2.ZERO
	clamp_camera()

func focus_floor(floor_level: int) -> void:
	if floor_level == 2 and not second_floor_unlocked:
		show_alert("二楼入口尚未开放")
		return
	var focus_cell: Vector2i = Vector2i(5,5)
	world_camera.position = cell_to_screen(focus_cell, floor_level)
	camera_target_zoom = 1.15
	camera_velocity = Vector2.ZERO
	clamp_camera()

func update_world_clock() -> void:
	var local_time: Dictionary = Time.get_datetime_dict_from_system()
	world_minutes = float(int(local_time.get("hour", 0)) * 60 + int(local_time.get("minute", 0)))

func calendar_date_key() -> String:
	var local_time: Dictionary = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(local_time.get("year", 0)), int(local_time.get("month", 0)), int(local_time.get("day", 0))]

func finalize_calendar_rollover() -> void:
	var today: String = calendar_date_key()
	if active_calendar_date == "":
		active_calendar_date = today
		needs_new_calendar_day = true
		return
	if active_calendar_date == today: return
	real_time_closing = true
	close_day(false)
	real_time_closing = false
	active_calendar_date = today
	needs_new_calendar_day = true
	apply_day_unlocks()
	refresh_market_for_day()
	refresh_market_prices()
	prepare_daily_event()
	event_resolved = true
	event_result_text = "自动经营：今日事件采用默认方案"
	if settlement_panel: settlement_panel.hide()
	if prep_panel: prep_panel.hide()
	begin_auto_business()


func cell_to_screen(cell: Vector2i, floor_level: int = 1) -> Vector2:
	return world.floor_grid_to_screen(cell, floor_level)

func role_capacity(role: String, floor_level: int = 1) -> int:
	if floor_level == 2:
		if not second_floor_unlocked: return 0
		if second_floor_level == 1:
			return 1 if role in ["Barista", "Waiter", "Cleaner"] else 0
		if second_floor_level == 2:
			return {"Barista":1,"Waiter":2,"Cleaner":1,"Manager":1}.get(role, 0)
		return {"Barista":2,"Waiter":3,"Cleaner":2,"Manager":1}.get(role, 0)
	if role == "Barista": return mini(3, 1 + placed_count("CoffeeMachine"))
	if role == "Waiter": return mini(4, int(upgrades.get("Tables", 1)) + placed_count("SingleTable") + placed_count("DoubleTable"))
	if role == "Cleaner": return mini(2, cleaning_room_level)
	if role == "Manager": return 1 if int(upgrades.get("Tables", 1)) + placed_count("SingleTable") + placed_count("DoubleTable") >= 3 else 0
	return 0

func role_assigned_count(role: String, except_name: String = "", floor_level: int = 1) -> int:
	var total: int = 0
	for data in employee_data:
		var staff_name: String = str(data.get("name", ""))
		if staff_name != except_name and str(data.get("role", "")) == role and bool(owned_staff.get(staff_name, false)) and bool(staff_assignments.get(staff_name, false)) and int(staff_floors.get(staff_name, 1)) == floor_level:
			total += 1
	return total

func assignment_message(staff_name: String) -> String:
	for data in employee_data:
		if str(data.get("name", "")) != staff_name: continue
		var role: String = str(data.get("role", ""))
		var worker_floor: int = int(staff_floors.get(staff_name, 1))
		if role_assigned_count(role, staff_name, worker_floor) >= role_capacity(role, worker_floor):
			if worker_floor == 2: return "二楼该岗位已满，请扩建二楼或调整排班"
			if role == "Barista": return "需要购买第二台咖啡机才能安排更多咖啡师"
			if role == "Waiter": return "需要扩大大厅、增加桌位才能安排更多服务员"
			if role == "Cleaner": return "需要扩建清洁间才能安排清洁员"
			return "需要扩大一楼大厅后才能安排店长"
	return ""

func enforce_staff_capacity() -> void:
	var used: Dictionary = {"Barista":0,"Waiter":0,"Cleaner":0,"Manager":0}
	for data in employee_data:
		var staff_name: String = str(data.get("name", ""))
		var role: String = str(data.get("role", ""))
		if not bool(owned_staff.get(staff_name, false)) or not bool(staff_assignments.get(staff_name, false)): continue
		var worker_floor: int = int(staff_floors.get(staff_name, 1))
		var key: String = "%s_%d" % [role, worker_floor]
		if int(used.get(key, 0)) >= role_capacity(role, worker_floor):
			staff_assignments[staff_name] = false
		else:
			used[key] = int(used.get(key, 0)) + 1

func first_floor_is_complete() -> bool:
	return role_capacity("Barista") >= 3 and role_capacity("Waiter") >= 4 and role_capacity("Cleaner") >= 2 and role_capacity("Manager") >= 1

func active_table_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = world.all_table_cells()
	for item in furniture_items:
		var item_type: String = str(item.get("type", ""))
		if item_type == "SingleTable":
			cells.append(Vector2i(int(item.get("x", 0)), int(item.get("y", 0))))
		elif item_type == "DoubleTable":
			var origin: Vector2i = Vector2i(int(item.get("x", 0)), int(item.get("y", 0)))
			cells.append(origin)
			cells.append(origin + Vector2i(1, 0))
	return cells

func table_cell(index: int) -> Vector2i:
	var cells: Array[Vector2i] = active_table_cells()
	return cells[index] if index >= 0 and index < cells.size() else Vector2i.ZERO

func table_floor(index: int) -> int:
	var base_count: int = world.all_table_cells().size()
	if index >= 0 and index < base_count: return world.table_floor(index)
	var extra_index: int = index - base_count
	for item in furniture_items:
		var item_type: String = str(item.get("type", ""))
		if item_type not in ["SingleTable", "DoubleTable"]: continue
		var slots: int = 2 if item_type == "DoubleTable" else 1
		if extra_index < slots: return int(item.get("floor", 1))
		extra_index -= slots
	return 1

func sync_furniture_state() -> void:
	world.set_second_floor(second_floor_unlocked, second_floor_level)
	var slots: int = active_table_cells().size()
	while table_owner.size() < slots:
		table_owner.append(null)
	while world.table_states.size() < slots:
		world.table_states.append("Free")
	world.set_furniture(furniture_items, expansions, decor_pending_type, Vector2i.ZERO, false, decor_rotation, active_decor_floor)
	if bool(expansions.get("LeftWindow", false)):
		camera_bounds = Rect2(-560, 90, 1810, 850)
	recalculate_environment()

func placed_count(item_type: String) -> int:
	var total: int = 0
	for item in furniture_items:
		if str(item.get("type", "")) == item_type:
			total += 1
	return total

func recalculate_environment() -> void:
	environment_score = placed_count("Sofa") * 3 + placed_count("Plant") * 2

func spawn_staff() -> void:
	for old in staff: old.queue_free()
	staff.clear()
	sss_active = false
	enforce_staff_capacity()
	for i in employee_data.size():
		if not bool(owned_staff.get(str(employee_data[i].get("name", "")), false)):
			continue
		var w: Staff = StaffScript.new(); w.setup(employee_data[i]); w.assigned = bool(staff_assignments.get(w.display_name, false))
		if not w.assigned: continue
		w.floor_level = int(staff_floors.get(w.display_name, 1))
		w.position = cell_to_screen(Vector2i(1 + (i % 2), 4 + int(floor(float(i) / 2.0))), w.floor_level); w.target_position = w.position; w.z_index = int(w.position.y); shop_layer.add_child(w); staff.append(w)
		if w.quality == "SSS" and w.assigned: sss_active = true
	world.night_mode = sss_active
	world.queue_redraw()

func spawn_customer() -> void:
	if phase != "Open": return
	if day == 1 and spawned_today >= 3: return
	if randf() > float(event_modifiers.get("traffic", 1.0)): return
	if free_table() < 0 and customers.filter(func(queued_guest): return queued_guest.phase == "queue").size() >= 1: return
	var queue_count: int = customers.filter(func(queued_guest): return queued_guest.phase == "queue").size()
	if queue_count >= queue_limit:
		return
	var new_customer: Customer = CustomerScript.new()
	var customer_type: String = "普通顾客"
	if bool(event_modifiers.get("blogger", false)): customer_type = "美食博主"; event_modifiers["blogger"] = false
	elif bool(event_modifiers.get("vip", false)): customer_type = "VIP"; event_modifiers["vip"] = false
	elif bool(event_modifiers.get("student", false)) or randf() < 0.22: customer_type = "学生"
	elif randf() < 0.20: customer_type = "白领"
	var vip_chance: float = (0.45 if sss_active else 0.03) + float(environment_score) * 0.01 + float(reputation) * 0.015
	if customer_type == "普通顾客" and randf() < minf(vip_chance, 0.65): customer_type = "VIP"
	var high: bool = customer_type == "VIP"
	new_customer.setup(customer_type, high, customer_type)
	if second_floor_unlocked and (customer_type in ["VIP", "美食博主"] or randf() < 0.28) and free_table_on_floor(2) >= 0:
		new_customer.floor_level = 2
	if customer_type == "学生": new_customer.patience += 45.0
	if customer_type == "白领": new_customer.patience -= 30.0
	new_customer.patience += float(environment_score) * 2.0
	new_customer.position = cell_to_screen(Vector2i(10,10)); new_customer.target_position = cell_to_screen(QUEUE[queue_count]); new_customer.z_index = int(new_customer.position.y); shop_layer.add_child(new_customer); customers.append(new_customer)
	spawned_today += 1

func advance_customer(c: Customer, dt: float) -> void:
	if not is_instance_valid(c): return
	c.tick_customer(dt, true)
	if c.patience <= 0:
		leave(c, false, "Guest left angry!"); return
	if c.phase == "queue" and actor_at_target(c): try_seat(c)
	if c.phase == "stairs_up" and actor_at_target(c):
		c.phase = "walking"
		c.target_position = cell_to_screen(table_cell(c.table_index), 2)
	if c.phase == "drinking" and c.drink_timer <= 0:
		c.phase="paying"; c.state_text="付款中"; c.target_position=cell_to_screen(Vector2i(8,2), c.floor_level)
	if c.phase == "paying" and actor_at_target(c) and not c.payment_recorded:
		record_payment(c)
		c.payment_recorded = true
		c.phase = "leaving"
		c.state_text = "离店中"
		c.target_position = cell_to_screen(Vector2i(9,7), 2) if c.floor_level == 2 else cell_to_screen(Vector2i(10,10))
		if c.floor_level == 2: c.phase = "stairs_down"
	if c.phase == "stairs_down" and actor_at_target(c):
		c.floor_level = 1
		c.phase = "leaving"
		c.target_position = cell_to_screen(Vector2i(10,10))
	if c.phase == "leaving" and actor_at_target(c):
		remove_customer(c)

func try_seat(c: Customer) -> void:
	var available: int = free_table_on_floor(c.floor_level)
	if available < 0 and c.floor_level == 2:
		c.floor_level = 1
		available = free_table_on_floor(1)
	if available < 0: return
	c.table_index = available; table_owner[available] = c; world.table_states[available]="Seating"; world.queue_redraw()
	var destination_floor: int = table_floor(available)
	if destination_floor == 2:
		c.phase="stairs_up"; c.state_text="上楼中"; c.target_position=cell_to_screen(Vector2i(9,7), 2)
	else:
		c.phase="walking"; c.state_text="前往座位"; c.target_position=cell_to_screen(table_cell(available), 1)

func free_table() -> int:
	var usable: int = mini(active_table_cells().size(), 3 + int(upgrades.get("Tables", 1)) + placed_count("SingleTable") + placed_count("DoubleTable") * 2)
	for i in usable:
		if table_owner[i] == null and world.table_states[i] == "Free": return i
	if second_floor_unlocked: return free_table_on_floor(2)
	return -1

func free_table_on_floor(floor_level: int) -> int:
	for i in world.table_states.size():
		if table_floor(i) == floor_level and table_owner[i] == null and world.table_states[i] == "Free": return i
	return -1

func day_goal() -> Dictionary:
	var goals: Array[Dictionary] = [
		{"revenue":20,"satisfaction":55,"drink":"Americano","count":1},
		{"revenue":40,"satisfaction":60,"drink":"Latte","count":1},
		{"revenue":60,"satisfaction":65,"drink":"Latte","count":2},
		{"revenue":80,"satisfaction":68,"drink":"Mocha","count":1},
		{"revenue":100,"satisfaction":70,"drink":"Mocha","count":2}
	]
	return goals[mini(day - 1, goals.size() - 1)]

func available_drinks() -> Array[String]:
	var drinks: Array[String] = []
	for drink in ["Americano", "Latte", "Mocha", "Sea Salt Latte"]:
		if bool(researched_menu.get(drink, false)) and bool(active_menu.get(drink, false)):
			drinks.append(drink)
	return drinks

func menu_recipe(drink: String) -> Dictionary:
	var recipes: Dictionary = {
		"Americano":{"price":12,"time":3.5,"popular":"高","ingredients":{"Beans":1}},
		"Latte":{"price":18,"time":4.3,"popular":"高","ingredients":{"Beans":1,"Milk":1}},
		"Mocha":{"price":24,"time":5.2,"popular":"中","ingredients":{"Beans":1,"Milk":1,"Syrup":1}},
		"Sea Salt Latte":{"price":32,"time":6.5,"popular":"低","ingredients":{"Beans":1,"Milk":1,"Syrup":1,"Cream":1}}
	}
	var recipe_value: Variant = recipes.get(drink, {})
	return recipe_value if recipe_value is Dictionary else {}

func apply_day_unlocks() -> void:
	if day >= 2: unlocks["Mocha"] = true
	if day >= 3: unlocks["SecondBarista"] = true
	if day >= 4: unlocks["PastryCase"] = true
	if day >= 5: unlocks["TalentMarket"] = true

func assign_tasks() -> void:
	# Seat queued guests as soon as a cleaned table becomes available.
	for c in customers:
		if c.phase == "queue": try_seat(c)
		if c.phase == "walking" and actor_at_target(c):
			c.phase="seated"; c.order=available_drinks().pick_random(); c.state_text="点单中"; world.table_states[c.table_index]="Order"; world.queue_redraw()
	# Each order has one state and gets one worker task at a time.
	for order_guest in customers:
		if order_guest.phase == "seated" and not has_order(order_guest):
			var waiter: Staff = idle_role("Waiter", order_guest.floor_level)
			if waiter: give_task(waiter,{"kind":"take","guest":order_guest,"target":order_guest.position,"stage":"move","remaining":1.0})
		if order_guest.phase == "ordered":
			var barista: Staff = idle_role("Barista", order_guest.floor_level)
			if barista and ingredients_for(order_guest.order): give_task(barista,{"kind":"make","guest":order_guest,"target":cell_to_screen(STATIONS.Barista, order_guest.floor_level),"stage":"move","remaining":make_time(barista,order_guest.order)})
			elif not ingredients_for(order_guest.order):
				if order_guest.state_text == "缺货等待":
					continue
				var alternatives: Array[String] = available_drinks().filter(func(drink): return ingredients_for(drink))
				daily_stockout_losses += 1
				satisfaction = maxf(0.0, satisfaction - 2.0)
				if not alternatives.is_empty():
					order_guest.order = alternatives.pick_random()
					order_guest.state_text = "缺货改点"
				else:
					order_guest.state_text = "缺货等待"
				show_alert("缺货：%s" % order_guest.order)
		if order_guest.phase == "ready":
			var server: Staff = idle_role("Waiter", order_guest.floor_level)
			if server: give_task(server,{"kind":"deliver","guest":order_guest,"target":cell_to_screen(STATIONS.Barista, order_guest.floor_level),"stage":"move_pickup","remaining":0.0})
	for i in world.table_states.size():
		if world.table_states[i] == "Dirty":
			var cleaner: Staff = idle_role("Cleaner", table_floor(i))
			if cleaner == null:
				cleaner = idle_role("Waiter", table_floor(i))
			if cleaner: give_task(cleaner,{"kind":"clean","table":i,"target":cell_to_screen(table_cell(i), table_floor(i)),"stage":"move","remaining":max(1.0,3.5-cleaner.clean_skill*.45)})

func advance_staff(w: Staff, _dt: float) -> void:
	if not w.assigned: return
	if w.task.is_empty():
		if w.stamina < 25.0 or w.resting:
			w.resting = true
			w.target_position = w.position
			w.state_text = "原地休息"
			if w.stamina >= 60.0:
				w.resting = false
			return
		var standby_value: Variant = STATIONS.get(w.role, STATIONS.get("Manager", Vector2i.ZERO))
		var standby_cell: Vector2i = standby_value if standby_value is Vector2i else Vector2i.ZERO
		w.target_position = cell_to_screen(standby_cell, w.floor_level)
		w.state_text="待命"
		return
	var task: Dictionary = w.task
	if task.get("kind", "") == "deliver":
		advance_delivery_task(w, task)
		return
	if task.stage == "move" and actor_at_target(w): task.stage="work"; w.task=task; w.state_text=task.kind.capitalize()
	if task.stage == "work" and float(task.remaining) <= 0.0: complete_task(w)

func advance_delivery_task(w: Staff, task: Dictionary) -> void:
	var guest_value: Variant = task.get("guest", null)
	if guest_value == null or not is_instance_valid(guest_value):
		w.task = {}
		return
	var guest: Customer = guest_value as Customer
	if task.get("stage", "") == "move_pickup" and actor_at_target(w):
		# The drink is picked up at the machine, then carried visibly to its table.
		task["stage"] = "move_table"
		task["target"] = guest.position
		w.task = task
		w.target_position = guest.position
		w.state_text = "端咖啡送餐"
		return
	if task.get("stage", "") == "move_table" and actor_at_target(w):
		complete_task(w)

func complete_task(w: Staff) -> void:
	var t: Dictionary = w.task
	if str(t.get("kind", "")) == "transfer":
		w.task = {}
		w.state_text = "二楼待命" if w.floor_level == 2 else "一楼待命"
		return
	var task_guest_value: Variant = t.get("guest", null)
	var task_guest: Customer = null
	if task_guest_value != null and is_instance_valid(task_guest_value):
		task_guest = task_guest_value as Customer
	if t.kind == "take" and is_instance_valid(task_guest) and task_guest.phase == "seated":
		task_guest.phase="ordered"
		task_guest.state_text="订单已送出"
		world.table_states[task_guest.table_index]="Making"
		# Day-one handoff is immediate: taking an order directly reserves Lin's brew task.
		var barista: Staff = idle_role("Barista", task_guest.floor_level)
		if barista and ingredients_for(task_guest.order):
			give_task(barista, {"kind":"make","guest":task_guest,"target":cell_to_screen(STATIONS.Barista, task_guest.floor_level),"stage":"move","remaining":make_time(barista,task_guest.order)})
		else:
			show_alert("咖啡师或食材暂不可用")
	elif t.kind == "make" and is_instance_valid(task_guest) and task_guest.phase == "ordered":
		consume(task_guest.order, task_guest.floor_level); task_guest.phase="ready"; task_guest.state_text="饮品完成"; world.table_states[task_guest.table_index]="Ready"
	elif t.kind == "deliver" and is_instance_valid(task_guest) and task_guest.phase == "ready":
		task_guest.phase="drinking"; task_guest.drink_timer=7.0; task_guest.state_text="享用中"; world.table_states[task_guest.table_index]="Occupied"
		drink_counts[task_guest.order] = int(drink_counts.get(task_guest.order, 0)) + 1
	elif t.kind == "clean":
		var table: int = int(t.get("table", -1)); world.table_states[table]="Free"; table_owner[table]=null; world.queue_redraw()
	w.task={}

func leave(c: Customer, paid: bool, reason: String) -> void:
	if not is_instance_valid(c): return
	if paid:
		record_payment(c)
	else:
		satisfaction=max(0,satisfaction-10); daily_angry_leaves += 1; show_alert(reason)
		if c.customer_type == "美食博主": add_reputation(-12)
	remove_customer(c)

func record_payment(c: Customer) -> void:
	var recipe: Dictionary = menu_recipe(c.order)
	var price: int = int(recipe.get("price", 0))
	if c.customer_type == "学生": price = int(round(float(price) * 0.75))
	elif c.customer_type == "白领": price = int(round(float(price) * 1.1))
	if c.high_spender: price=int(price*2.0)
	if sss_active and c.order == "Sea Salt Latte": price = int(price * 1.5)
	revenue += price; coins += price; satisfaction=clampf(satisfaction+1.0,0,100); daily_served += 1
	if c.floor_level == 2:
		second_floor_revenue += price
		second_floor_served += 1
		second_floor_satisfaction_total += satisfaction
	if c.customer_type == "美食博主":
		add_reputation(8)
		show_alert("美食博主满意分享：声望 +8")
	if day == 1 and daily_served >= 3:
		day_one_ready_to_close = true
		show_alert("三位顾客均已完成服务，可以结算营业")

func remove_customer(c: Customer) -> void:
	if c.table_index >= 0:
		world.table_states[c.table_index]="Dirty"
		world.queue_redraw()
	customers.erase(c); c.queue_free()

func has_order(c: Customer) -> bool:
	for w in staff:
		if not w.task.is_empty() and w.task.get("guest") == c: return true
	return c.phase in ["ordered","ready","drinking","paying"]

func idle_role(role: String, floor_level: int = 1) -> Staff:
	for w in staff:
		if w.role == role and w.floor_level == floor_level and w.assigned and w.task.is_empty() and not w.resting: return w
	return null

func give_task(w: Staff, task: Dictionary) -> void: w.task=task; w.target_position=task.target; w.state_text="前往工作"
func actor_at_target(actor: CafeActor) -> bool: return actor.position.distance_to(actor.target_position) <= 5.0
func ingredients_for(drink: String) -> bool:
	var recipe: Dictionary = menu_recipe(drink)
	var needs_value: Variant = recipe.get("ingredients", {})
	if not needs_value is Dictionary: return false
	for item in needs_value:
		if int(ingredients.get(str(item), 0)) < int(needs_value.get(item, 0)): return false
	return true
func consume(drink: String, floor_level: int = 1) -> void:
	var recipe: Dictionary = menu_recipe(drink)
	var needs_value: Variant = recipe.get("ingredients", {})
	if not needs_value is Dictionary: return
	for item in needs_value:
		var item_name: String = str(item)
		var quantity: int = int(needs_value.get(item, 0))
		ingredients[item_name] = int(ingredients.get(item_name, 0)) - quantity
		var cost: int = int(market_prices.get(item_name, 0)) * quantity
		daily_ingredient_cost += cost
		if floor_level == 2: second_floor_ingredient_cost += cost
func nora_on_duty() -> bool:
	return bool(owned_staff.get("Nora", false)) and bool(staff_assignments.get("Nora", true))

func make_time(w: Staff, drink: String) -> float:
	var recipe: Dictionary = menu_recipe(drink)
	var base_time: float = float(recipe.get("time", 5.2))
	var menu_pressure: float = maxf(0.0, float(available_drinks().size() - 2) * 0.25)
	var sick_penalty: float = 1.0 if bool(event_modifiers.get("sick", false)) else 0.0
	return max(.75, base_time + menu_pressure + sick_penalty - w.make_skill*.55 - upgrades.Machine*.65 - placed_count("CoffeeMachine")*.55 - (0.8 if nora_on_duty() else 0.0))
func delivery_time(w: Staff) -> float: return max(.5, 2.5 - w.service_skill*.3)

func fill_parent(control: Control, margin: float = 0.0) -> void:
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.offset_left = margin
	control.offset_top = margin
	control.offset_right = -margin
	control.offset_bottom = -margin

func center_popup(control: Control, popup_size: Vector2) -> void:
	control.set_anchors_preset(Control.PRESET_CENTER)
	control.offset_left = -popup_size.x * 0.5
	control.offset_top = -popup_size.y * 0.5
	control.offset_right = popup_size.x * 0.5
	control.offset_bottom = popup_size.y * 0.5

func build_ui() -> void:
	ui_layer = CanvasLayer.new(); add_child(ui_layer)
	ui_root = Control.new(); ui_root.name = "UIRoot"; ui_root.theme = NightBrewTheme; ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE; fill_parent(ui_root); ui_layer.add_child(ui_root)
	var layer: Control = ui_root
	var top: ColorRect = ColorRect.new(); top.set_anchors_preset(Control.PRESET_TOP_WIDE); top.offset_bottom=176; top.color=Color("#fff1d4"); layer.add_child(top)
	hud_label=Label.new(); hud_label.set_anchors_preset(Control.PRESET_TOP_LEFT); hud_label.offset_left=32; hud_label.offset_top=24; hud_label.offset_right=690; hud_label.offset_bottom=150; hud_label.add_theme_font_size_override("font_size",30); hud_label.add_theme_color_override("font_color",Color("#51342e")); top.add_child(hud_label)
	var top_actions: HBoxContainer=HBoxContainer.new(); top_actions.set_anchors_preset(Control.PRESET_TOP_RIGHT); top_actions.offset_left=-235; top_actions.offset_top=44; top_actions.offset_right=-24; top_actions.offset_bottom=130; top_actions.add_theme_constant_override("separation",12); top.add_child(top_actions)
	var camera_home: Button=Button.new(); camera_home.text="⌂"; camera_home.tooltip_text="回到店铺中心"; camera_home.custom_minimum_size=Vector2(90,86); camera_home.pressed.connect(reset_world_camera); top_actions.add_child(camera_home)
	first_floor_button=Button.new(); first_floor_button.text="1F"; first_floor_button.custom_minimum_size=Vector2(76,86); first_floor_button.pressed.connect(focus_floor.bind(1)); first_floor_button.visible=false; top_actions.add_child(first_floor_button)
	second_floor_button=Button.new(); second_floor_button.text="2F"; second_floor_button.custom_minimum_size=Vector2(76,86); second_floor_button.pressed.connect(focus_floor.bind(2)); second_floor_button.visible=false; top_actions.add_child(second_floor_button)
	var wrench: Button=Button.new(); wrench.text="设置"; wrench.custom_minimum_size=Vector2(105,86); wrench.pressed.connect(toggle_settings); top_actions.add_child(wrench)
	var order_button: Button=Button.new(); order_button.text="☕\n订单"; order_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT); order_button.offset_left=20; order_button.offset_top=-430; order_button.offset_right=140; order_button.offset_bottom=-326; layer.add_child(order_button)
	var speed: Button=Button.new(); speed.text="×%d" % int(speed_multiplier); speed.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT); speed.offset_left=-145; speed.offset_top=-430; speed.offset_right=-20; speed.offset_bottom=-348; speed.pressed.connect(cycle_speed.bind(speed)); layer.add_child(speed)
	var pause: Button=Button.new(); pause.text="Ⅱ"; pause.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT); pause.offset_left=-145; pause.offset_top=-335; pause.offset_right=-20; pause.offset_bottom=-253; pause.pressed.connect(toggle_pause.bind(pause)); layer.add_child(pause)
	end_day_button=Button.new(); end_day_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT); end_day_button.offset_left=-320; end_day_button.offset_top=-560; end_day_button.offset_right=-20; end_day_button.offset_bottom=-470; end_day_button.pressed.connect(close_day); end_day_button.name="ShopToggle"; end_day_button.visible=false; layer.add_child(end_day_button)
	var nav: ColorRect=ColorRect.new(); nav.set_anchors_preset(Control.PRESET_BOTTOM_WIDE); nav.offset_top=-250; nav.offset_bottom=-16; nav.color=Color("#fff1d4"); layer.add_child(nav)
	var bar: HBoxContainer=HBoxContainer.new(); fill_parent(bar, 20); bar.add_theme_constant_override("separation",15); nav.add_child(bar)
	for text in ["☕\n店铺","👥\n员工","🪴\n装修","▣\n补给","⌂\n城市"]:
		var b: Button=Button.new(); b.text=text; b.custom_minimum_size=Vector2(190,140); bar.add_child(b)
	bar.get_child(1).pressed.connect(toggle_staff)
	bar.get_child(2).pressed.connect(toggle_decor)
	bar.get_child(3).pressed.connect(toggle_supply_panel)
	bar.get_child(4).pressed.connect(toggle_finance_panel)
	alert_label=Label.new(); alert_label.set_anchors_preset(Control.PRESET_TOP_WIDE); alert_label.offset_left=160; alert_label.offset_top=185; alert_label.offset_right=-220; alert_label.offset_bottom=247; alert_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; alert_label.add_theme_font_size_override("font_size",34); alert_label.add_theme_color_override("font_color",Color("#9a5338")); layer.add_child(alert_label)
	selection_card=Label.new(); selection_card.set_anchors_preset(Control.PRESET_BOTTOM_WIDE); selection_card.offset_left=140; selection_card.offset_top=-390; selection_card.offset_right=-140; selection_card.offset_bottom=-290; selection_card.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; selection_card.add_theme_font_size_override("font_size",30); selection_card.add_theme_color_override("font_color",Color("#51342e")); selection_card.visible=false; layer.add_child(selection_card)
	debug_panel=PanelContainer.new(); center_popup(debug_panel, Vector2(900,620)); debug_panel.visible=false; layer.add_child(debug_panel)
	var debug_box: VBoxContainer=VBoxContainer.new(); debug_panel.add_child(debug_box)
	debug_label=Label.new(); debug_label.add_theme_font_size_override("font_size",30); debug_box.add_child(debug_label)
	for entry in [["Spawn guest",spawn_customer],["×2",set_speed.bind(2.0)],["×4",set_speed.bind(4.0)],["Reset Save",reset_save],["Machine +",upgrade_machine],["Tables +",upgrade_tables]]:
		var tool: Button=Button.new(); tool.text=str(entry[0]); tool.pressed.connect(entry[1]); debug_box.add_child(tool)
	supply_panel=PanelContainer.new(); center_popup(supply_panel, Vector2(880,650)); supply_panel.visible=false; layer.add_child(supply_panel)
	var supply_box: VBoxContainer=VBoxContainer.new(); supply_panel.add_child(supply_box)
	supply_label=Label.new(); supply_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; supply_label.add_theme_font_size_override("font_size",34); supply_box.add_child(supply_label)
	var supply_scroll: ScrollContainer = ScrollContainer.new(); supply_scroll.custom_minimum_size = Vector2(0, 440); supply_box.add_child(supply_scroll)
	supply_list_box = VBoxContainer.new(); supply_list_box.custom_minimum_size = Vector2(820, 760); supply_scroll.add_child(supply_list_box)
	var free_supply_button: Button=Button.new(); free_supply_button.text="领取免费基础补给"; free_supply_button.custom_minimum_size=Vector2(0,82); free_supply_button.pressed.connect(free_supply); supply_box.add_child(free_supply_button)
	var supply_close: Button=Button.new(); supply_close.text="关闭"; supply_close.custom_minimum_size=Vector2(0,82); supply_close.pressed.connect(toggle_supply_panel); supply_box.add_child(supply_close)
	menu_panel=PanelContainer.new(); center_popup(menu_panel, Vector2(900,900)); menu_panel.visible=false; layer.add_child(menu_panel)
	var menu_scroll: ScrollContainer=ScrollContainer.new(); fill_parent(menu_scroll, 12); menu_panel.add_child(menu_scroll)
	var menu_box: VBoxContainer=VBoxContainer.new(); menu_box.custom_minimum_size=Vector2(860,980); menu_scroll.add_child(menu_box)
	menu_label=Label.new(); menu_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; menu_label.add_theme_font_size_override("font_size",34); menu_box.add_child(menu_label)
	menu_list=VBoxContainer.new(); menu_box.add_child(menu_list)
	var fridge_button: Button=Button.new(); fridge_button.text="升级冰箱 · 增加易腐食材容量并降低损耗"; fridge_button.custom_minimum_size=Vector2(0,86); fridge_button.pressed.connect(upgrade_fridge); menu_box.add_child(fridge_button)
	var menu_close: Button=Button.new(); menu_close.text="关闭"; menu_close.custom_minimum_size=Vector2(0,82); menu_close.pressed.connect(toggle_menu_panel); menu_box.add_child(menu_close)
	market_panel=PanelContainer.new(); market_panel.set_anchors_preset(Control.PRESET_FULL_RECT); market_panel.offset_left=40; market_panel.offset_top=200; market_panel.offset_right=-40; market_panel.offset_bottom=-280; market_panel.visible=false; layer.add_child(market_panel)
	var market_scroll: ScrollContainer=ScrollContainer.new(); fill_parent(market_scroll, 12); market_panel.add_child(market_scroll)
	var market_box: VBoxContainer=VBoxContainer.new(); market_box.custom_minimum_size=Vector2(920,1300); market_scroll.add_child(market_box)
	market_label=Label.new(); market_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; market_label.add_theme_font_size_override("font_size",30); market_box.add_child(market_label)
	var gossip_button: Button=Button.new(); gossip_button.text="花 80 金币打听消息并刷新候选人"; gossip_button.custom_minimum_size=Vector2(0,86); gossip_button.pressed.connect(refresh_market_with_gossip); market_box.add_child(gossip_button)
	market_candidates_box=VBoxContainer.new(); market_box.add_child(market_candidates_box)
	var market_close: Button=Button.new(); market_close.text="关闭"; market_close.custom_minimum_size=Vector2(0,82); market_close.pressed.connect(toggle_market_panel); market_box.add_child(market_close)
	finance_panel=PanelContainer.new(); center_popup(finance_panel, Vector2(900,900)); finance_panel.visible=false; layer.add_child(finance_panel)
	var finance_box: VBoxContainer=VBoxContainer.new(); finance_panel.add_child(finance_box)
	finance_label=Label.new(); finance_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; finance_label.add_theme_font_size_override("font_size",30); finance_box.add_child(finance_label)
	var finance_close: Button=Button.new(); finance_close.text="关闭"; finance_close.custom_minimum_size=Vector2(0,82); finance_close.pressed.connect(toggle_finance_panel); finance_box.add_child(finance_close)
	prep_panel=PanelContainer.new(); center_popup(prep_panel, Vector2(940,980)); layer.add_child(prep_panel)
	var prep_box: VBoxContainer=VBoxContainer.new(); prep_panel.add_child(prep_box)
	prep_label=Label.new(); prep_label.add_theme_font_size_override("font_size",42); prep_box.add_child(prep_label)
	event_label=Label.new(); event_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; event_label.add_theme_font_size_override("font_size",30); prep_box.add_child(event_label)
	event_choice_a=Button.new(); event_choice_a.custom_minimum_size=Vector2(0,84); event_choice_a.pressed.connect(choose_daily_event.bind(0)); prep_box.add_child(event_choice_a)
	event_choice_b=Button.new(); event_choice_b.custom_minimum_size=Vector2(0,84); event_choice_b.pressed.connect(choose_daily_event.bind(1)); prep_box.add_child(event_choice_b)
	for entry in [["每日采购",toggle_supply_panel],["菜单与研发",toggle_menu_panel],["员工排班",toggle_staff],["开始营业",start_day]]:
		var prep_button: Button=Button.new(); prep_button.text=str(entry[0]); prep_button.custom_minimum_size=Vector2(0,92); prep_button.pressed.connect(entry[1]); prep_box.add_child(prep_button)
	settlement_panel=PanelContainer.new(); center_popup(settlement_panel, Vector2(920,680)); settlement_panel.visible=false; layer.add_child(settlement_panel)
	var settlement_box: VBoxContainer=VBoxContainer.new(); settlement_panel.add_child(settlement_box)
	settlement_label=Label.new(); settlement_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; settlement_label.add_theme_font_size_override("font_size",42); settlement_box.add_child(settlement_label)
	var next_day: Button=Button.new(); next_day.text="继续自动营业"; next_day.custom_minimum_size=Vector2(0,92); next_day.pressed.connect(begin_next_day_auto); settlement_box.add_child(next_day)
	staff_panel=PanelContainer.new(); staff_panel.set_anchors_preset(Control.PRESET_FULL_RECT); staff_panel.offset_left=55; staff_panel.offset_top=200; staff_panel.offset_right=-55; staff_panel.offset_bottom=-280; staff_panel.visible=false; layer.add_child(staff_panel)
	var staff_scroll: ScrollContainer = ScrollContainer.new(); fill_parent(staff_scroll, 12); staff_panel.add_child(staff_scroll)
	staff_list_box = VBoxContainer.new(); staff_list_box.custom_minimum_size=Vector2(890,2800); staff_scroll.add_child(staff_list_box)
	populate_staff_list()
	decor_panel=PanelContainer.new(); decor_panel.set_anchors_preset(Control.PRESET_FULL_RECT); decor_panel.offset_left=38; decor_panel.offset_top=230; decor_panel.offset_right=-38; decor_panel.offset_bottom=-280; decor_panel.visible=false; layer.add_child(decor_panel)
	var decor_box: VBoxContainer = VBoxContainer.new(); decor_panel.add_child(decor_box)
	decor_label=Label.new(); decor_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; decor_label.add_theme_font_size_override("font_size",30); decor_box.add_child(decor_label)
	var decor_scroll: ScrollContainer = ScrollContainer.new(); decor_scroll.custom_minimum_size = Vector2(0, 760); decor_box.add_child(decor_scroll)
	decor_cards_box = VBoxContainer.new(); decor_cards_box.custom_minimum_size = Vector2(900, 1080); decor_scroll.add_child(decor_cards_box)
	var cleaning_button: Button = Button.new(); cleaning_button.text="扩建清洁间 · 320金币 · +1 清洁员岗位"; cleaning_button.custom_minimum_size=Vector2(0,82); cleaning_button.pressed.connect(expand_cleaning_room); decor_box.add_child(cleaning_button)
	var hall_button: Button = Button.new(); hall_button.text="扩大大厅 · 350金币 · +1 服务员岗位"; hall_button.custom_minimum_size=Vector2(0,82); hall_button.pressed.connect(upgrade_tables); decor_box.add_child(hall_button)
	var floor_button: Button = Button.new(); floor_button.text="建设二楼 · 一楼完成、声望 5、经营 15 天 · 1800金币"; floor_button.custom_minimum_size=Vector2(0,82); floor_button.pressed.connect(try_unlock_second_floor); decor_box.add_child(floor_button)
	var floor_expand_button: Button = Button.new(); floor_expand_button.text="扩建二楼 · 增加桌位与岗位"; floor_expand_button.custom_minimum_size=Vector2(0,82); floor_expand_button.pressed.connect(upgrade_second_floor); decor_box.add_child(floor_expand_button)
	var decor_floor_button: Button = Button.new(); decor_floor_button.text="切换装修楼层（当前 %dF）" % active_decor_floor; decor_floor_button.custom_minimum_size=Vector2(0,82); decor_floor_button.pressed.connect(toggle_decor_floor); decor_box.add_child(decor_floor_button)
	var rotate_button: Button = Button.new(); rotate_button.text="旋转当前家具"; rotate_button.custom_minimum_size=Vector2(0,82); rotate_button.pressed.connect(rotate_selected_or_pending); decor_box.add_child(rotate_button)
	var sell_button: Button = Button.new(); sell_button.text="出售选中家具（返还 50%）"; sell_button.custom_minimum_size=Vector2(0,82); sell_button.pressed.connect(sell_selected_furniture); decor_box.add_child(sell_button)
	var exit_decor: Button = Button.new(); exit_decor.text="完成装修"; exit_decor.custom_minimum_size=Vector2(0,82); exit_decor.pressed.connect(toggle_decor); decor_box.add_child(exit_decor)
	settings_panel=PanelContainer.new(); center_popup(settings_panel, Vector2(780,740)); settings_panel.visible=false; layer.add_child(settings_panel)
	var settings_box: VBoxContainer=VBoxContainer.new(); settings_panel.add_child(settings_box)
	var settings_title: Label=Label.new(); settings_title.text="设置\n界面大小"; settings_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; settings_title.add_theme_font_size_override("font_size",42); settings_box.add_child(settings_title)
	for size_mode in ["标准", "大", "特大"]:
		var size_button: Button=Button.new(); size_button.text=size_mode; size_button.custom_minimum_size=Vector2(0,88); size_button.pressed.connect(set_ui_size.bind(size_mode)); settings_box.add_child(size_button)
	var orientation_title: Label=Label.new(); orientation_title.text="游戏方向"; orientation_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; orientation_title.add_theme_font_size_override("font_size",32); settings_box.add_child(orientation_title)
	var landscape_button: Button=Button.new(); landscape_button.text="横屏（推荐）"; landscape_button.custom_minimum_size=Vector2(0,82); landscape_button.pressed.connect(set_game_orientation.bind("横屏")); settings_box.add_child(landscape_button)
	var portrait_button: Button=Button.new(); portrait_button.text="竖屏"; portrait_button.custom_minimum_size=Vector2(0,82); portrait_button.pressed.connect(set_game_orientation.bind("竖屏")); settings_box.add_child(portrait_button)
	var settings_close: Button=Button.new(); settings_close.text="关闭"; settings_close.custom_minimum_size=Vector2(0,82); settings_close.pressed.connect(toggle_settings); settings_box.add_child(settings_close)
	set_ui_size(ui_size_mode)
	confirm_dialog = ConfirmDialogScene.instantiate()
	center_popup(confirm_dialog, Vector2(860, 520)); confirm_dialog.visible = false; layer.add_child(confirm_dialog)

func populate_staff_list() -> void:
	if not staff_list_box: return
	for child in staff_list_box.get_children(): child.queue_free()
	var title: Label = Label.new(); title.text="员工调度"; title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; title.add_theme_font_size_override("font_size",42); staff_list_box.add_child(title)
	var instruction: Label = Label.new(); instruction.text="① 选择员工仓库中的员工　② 点击空岗位安排上岗\n也可以直接拖动员工卡片；岗位满时会自动拦截。"; instruction.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; instruction.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; instruction.add_theme_font_size_override("font_size",26); staff_list_box.add_child(instruction)
	build_floor_duty_board(1)
	if second_floor_unlocked:
		build_floor_duty_board(2)
	else:
		var locked: Label = Label.new(); locked.text="二楼岗位板 · 尚未解锁"; locked.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; locked.add_theme_font_size_override("font_size",28); staff_list_box.add_child(locked)
	var warehouse: Variant = StaffWarehouseDropScene.instantiate()
	warehouse.setup(move_staff_to_warehouse)
	staff_list_box.add_child(warehouse)
	var warehouse_box: VBoxContainer = VBoxContainer.new(); warehouse.add_child(warehouse_box)
	var warehouse_title: Label = Label.new(); warehouse_title.text="员工仓库 · %s" % ("已选择 %s，请点击上方空岗位" % selected_roster_staff if selected_roster_staff != "" else "点击员工后，再点击上方空岗位"); warehouse_title.add_theme_font_size_override("font_size",32); warehouse_box.add_child(warehouse_title)
	for data in employee_data:
		var staff_name: String = str(data.get("name", ""))
		if not bool(owned_staff.get(staff_name, false)) or bool(staff_assignments.get(staff_name, false)): continue
		var card: Variant = StaffRosterCardScene.instantiate()
		card.setup(data, false, int(staff_floors.get(staff_name, 1)), select_staff_for_assignment.bind(staff_name))
		warehouse_box.add_child(card)
	var market_button: Button = Button.new(); market_button.text="人才市场 · 聘请新员工"; market_button.custom_minimum_size=Vector2(0,92); market_button.pressed.connect(open_talent_market); staff_list_box.add_child(market_button)
	var close: Button = Button.new(); close.text="关闭"; close.custom_minimum_size=Vector2(0,82); close.pressed.connect(func():staff_panel.hide()); staff_list_box.add_child(close)
	apply_ui_readability(staff_list_box)

func build_floor_duty_board(floor_level: int) -> void:
	var board: PanelContainer = PanelContainer.new(); staff_list_box.add_child(board)
	var box: VBoxContainer = VBoxContainer.new(); board.add_child(box)
	var title: Label = Label.new(); title.text="%d楼 · 当前上岗" % floor_level; title.add_theme_font_size_override("font_size",32); box.add_child(title)
	for role_name in ["Barista", "Waiter", "Cleaner", "Manager"]:
		var capacity: int = role_capacity(role_name, floor_level)
		if capacity <= 0: continue
		var assigned: Array[Dictionary] = assigned_staff_for_role(role_name, floor_level)
		for slot_index in range(capacity):
			var occupant: Dictionary = assigned[slot_index] if slot_index < assigned.size() else {}
			var slot: Variant = StaffDutySlotScene.instantiate()
			slot.setup(role_name, floor_level, occupant, slot_index + 1, capacity, assign_staff_to_floor)
			box.add_child(slot)

func assigned_staff_for_role(role_name: String, floor_level: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for data in employee_data:
		var staff_name: String = str(data.get("name", ""))
		if str(data.get("role", "")) == role_name and bool(owned_staff.get(staff_name, false)) and bool(staff_assignments.get(staff_name, false)) and int(staff_floors.get(staff_name, 1)) == floor_level:
			result.append({"name": staff_name})
	return result

func role_display_name(role_name: String) -> String:
	var names: Dictionary = {"Barista":"咖啡师", "Waiter":"服务员", "Cleaner":"清洁员", "Manager":"店长"}
	return str(names.get(role_name, role_name))

func open_talent_market() -> void:
	if staff_panel: staff_panel.hide()
	if market_panel: market_panel.show()
	refresh_market_panel()

func toggle_settings() -> void:
	if settings_panel:
		settings_panel.visible = not settings_panel.visible

func set_ui_size(size_mode: String) -> void:
	ui_size_mode = size_mode
	if size_mode == "标准":
		ui_scale_factor = 1.0
	elif size_mode == "特大":
		ui_scale_factor = 1.32
	else:
		ui_scale_factor = 1.15
	if ui_root:
		apply_ui_readability(ui_root)
	if settings_panel:
		settings_panel.visible = false
	save_game()

func set_game_orientation(mode: String) -> void:
	game_orientation = mode
	apply_game_orientation(true)
	save_game()

func apply_game_orientation(show_message: bool) -> void:
	var main_window: Window = get_window()
	if game_orientation == "竖屏":
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_PORTRAIT)
		main_window.content_scale_size = Vector2i(1080, 1920)
		if not OS.has_feature("mobile"):
			main_window.size = Vector2i(720, 1280)
	else:
		DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)
		main_window.content_scale_size = Vector2i(1920, 1080)
		if not OS.has_feature("mobile"):
			main_window.size = Vector2i(1280, 720)
	call_deferred("refresh_orientation_layout")
	if show_message:
		show_alert("已切换为%s游玩" % game_orientation)
	if settings_panel:
		settings_panel.hide()

func refresh_orientation_layout() -> void:
	if ui_root:
		fill_parent(ui_root)
	if world_camera:
		clamp_camera()

func apply_ui_readability(node: Node) -> void:
	if node is Label or node is Button:
		var control: Control = node as Control
		var saved_base: int = int(control.get_meta("ui_base_font", 0))
		if saved_base <= 0:
			saved_base = control.get_theme_font_size("font_size")
			if node is Button:
				saved_base = maxi(saved_base, 32)
			else:
				saved_base = maxi(saved_base, 30)
			control.set_meta("ui_base_font", saved_base)
		control.add_theme_font_size_override("font_size", roundi(float(saved_base) * ui_scale_factor))
		if node is Button:
			var button: Button = node as Button
			button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 80.0)
	for child in node.get_children():
		apply_ui_readability(child)

func update_ui() -> void:
	if not hud_label: return
	var activity: String = "营业准备" if phase != "Open" else current_activity()
	var world_hour: int = floori(world_minutes / 60.0)
	var world_minute: int = int(world_minutes) % 60
	var rep_progress: int = reputation_points % 100
	hud_label.text="夜酿咖啡馆 · 第 %d 天 · %02d:%02d\n金币 %d · 声望 Lv.%d（%d/100）· 环境 %d   ·   %s" % [day,world_hour,world_minute,coins,reputation,rep_progress,environment_score,activity]
	if first_floor_button: first_floor_button.visible = second_floor_unlocked
	if second_floor_button: second_floor_button.visible = second_floor_unlocked
	if end_day_button:
		end_day_button.visible = false
	var guest_lines: Array = customers.map(func(c): return "%s:%s" % [c.display_name,c.phase]).slice(0,6)
	var worker_lines: Array = staff.map(func(w): return "%s:%s" % [w.display_name,w.state_text]).slice(0,6)
	debug_label.text="DEV LIVE STATE\nCustomers: %s\nEmployees: %s\nOrder queue: %d | Tables: %s\nInventory: %s" % [", ".join(guest_lines),", ".join(worker_lines),customers.filter(func(c):return c.phase in ["seated","ordered","making","ready"]).size(),", ".join(world.table_states),str(ingredients)]

func current_activity() -> String:
	for w in staff:
		if not w.task.is_empty():
			var labels: Dictionary = {"take":"正在接单","make":"正在制作咖啡","deliver":"正在送餐","clean":"正在清洁"}
			return "%s %s" % [w.display_name, str(labels.get(str(w.task.get("kind", "")), "正在工作"))]
	for c in customers:
		if c.phase in ["queue", "walking"]: return "顾客正在进店入座"
		if c.phase == "paying": return "顾客正在付款"
	return "等待第一位顾客"

func toggle_debug() -> void:
	debug_panel.visible = not debug_panel.visible

func close_navigation_panels(except_panel: Control = null) -> void:
	for panel in [staff_panel, decor_panel, supply_panel, market_panel, menu_panel, finance_panel]:
		if panel and panel != except_panel:
			panel.hide()
	if decor_panel != except_panel and world and world.decoration_mode:
		world.decoration_mode = false
		cancel_furniture_placement()
		world.queue_redraw()

func toggle_decor() -> void:
	var opening: bool = not world.decoration_mode
	if opening: close_navigation_panels(decor_panel)
	world.decoration_mode = opening
	if decor_panel:
		decor_panel.visible = world.decoration_mode
	if not world.decoration_mode:
		cancel_furniture_placement()
		decor_selected_id = -1
	else:
		refresh_decor_panel()
	world.queue_redraw()
	show_alert("装修模式：选择家具后点击等距格子摆放" if world.decoration_mode else "已回到营业视图")

func refresh_decor_panel() -> void:
	if not decor_label: return
	var selection: String = "未选择家具"
	if decor_pending_type != "":
		selection = "摆放中：%s · 点地图格子确认，红色不能放" % str(furniture_catalog.get(decor_pending_type, {}).get("name", ""))
	elif decor_selected_id >= 0:
		selection = "已选中家具：可旋转、出售，或点击其他合法格子移动"
	decor_label.text = "装修模式 · %d楼 · 金币 %d · 环境评分 %d\n%s" % [active_decor_floor, coins, environment_score, selection]
	if not decor_cards_box: return
	for child in decor_cards_box.get_children(): child.queue_free()
	for item_key in ["SingleTable", "DoubleTable", "CoffeeMachine", "Register", "Sofa", "Plant"]:
		var item_data: Dictionary = furniture_catalog.get(item_key, {})
		var item_size_value: Variant = item_data.get("size", Vector2i.ONE)
		var item_size: Vector2i = item_size_value if item_size_value is Vector2i else Vector2i.ONE
		var card: Variant = FurnitureCardScene.instantiate()
		card.setup(str(item_data.get("name", item_key)), int(item_data.get("price", 0)), "%d×%d" % [item_size.x, item_size.y], str(item_data.get("effect", "")), "摆放", begin_furniture_placement.bind(item_key))
		decor_cards_box.add_child(card)
	var expansion: Variant = FurnitureCardScene.instantiate()
	expansion.setup("左侧窗边区", 260, "18 格", "开放更多桌位与动线", "扩建", buy_left_expansion, Color("6b91a7"))
	decor_cards_box.add_child(expansion)

func toggle_decor_floor() -> void:
	if not second_floor_unlocked:
		show_alert("二楼入口尚未开放")
		return
	active_decor_floor = 2 if active_decor_floor == 1 else 1
	cancel_furniture_placement()
	focus_floor(active_decor_floor)
	refresh_decor_panel()

func buildable_cell(cell: Vector2i) -> bool:
	if active_decor_floor == 2:
		var max_size: int = 6 if second_floor_level <= 1 else (8 if second_floor_level == 2 else 10)
		return cell.x >= 1 and cell.x < max_size and cell.y >= 1 and cell.y < max_size
	if cell.x >= 1 and cell.x <= 8 and cell.y >= 3 and cell.y <= 9:
		return true
	if bool(expansions.get("LeftWindow", false)) and cell.x >= -3 and cell.x <= -1 and cell.y >= 3 and cell.y <= 8:
		return true
	return false

func furniture_size(item_type: String, rotation: int) -> Vector2i:
	var item_data: Dictionary = furniture_catalog.get(item_type, {})
	var size_value: Variant = item_data.get("size", Vector2i.ONE)
	var size: Vector2i = size_value if size_value is Vector2i else Vector2i.ONE
	return Vector2i(size.y, size.x) if rotation % 2 == 1 else size

func occupied_by_fixed_layout(cell: Vector2i) -> bool:
	if active_decor_floor == 2:
		return (cell.x >= 1 and cell.x <= 3 and cell.y >= 1 and cell.y <= 2) or cell == Vector2i(9,7)
	if cell == Vector2i(10,10) or cell in TABLES or cell in QUEUE:
		return true
	if cell.x >= 2 and cell.x <= 4 and cell.y >= 1 and cell.y <= 2:
		return true
	return cell == Vector2i(8,2)

func is_valid_furniture_placement(item_type: String, cell: Vector2i, rotation: int, ignore_id: int = -1) -> bool:
	if item_type == "": return false
	var size: Vector2i = furniture_size(item_type, rotation)
	for x in range(size.x):
		for y in range(size.y):
			var test_cell: Vector2i = cell + Vector2i(x, y)
			if not buildable_cell(test_cell) or occupied_by_fixed_layout(test_cell):
				return false
			for item in furniture_items:
				if int(item.get("id", -1)) == ignore_id: continue
				if int(item.get("floor", 1)) != active_decor_floor: continue
				var other_type: String = str(item.get("type", ""))
				var other_origin: Vector2i = Vector2i(int(item.get("x", 0)), int(item.get("y", 0)))
				var other_size: Vector2i = furniture_size(other_type, int(item.get("rotation", 0)))
				if test_cell.x >= other_origin.x and test_cell.x < other_origin.x + other_size.x and test_cell.y >= other_origin.y and test_cell.y < other_origin.y + other_size.y:
					return false
	return true

func begin_furniture_placement(item_type: String) -> void:
	var item_data: Dictionary = furniture_catalog.get(item_type, {})
	var price: int = int(item_data.get("price", 0))
	if coins < price:
		show_alert("金币不足")
		return
	cancel_furniture_placement()
	coins -= price
	decor_pending_type = item_type
	decor_pending_price = price
	decor_rotation = 0
	refresh_decor_panel()
	show_alert("移动到格子预览，点击确认摆放")

func cancel_furniture_placement() -> void:
	if decor_pending_type != "":
		coins += decor_pending_price
	decor_pending_type = ""
	decor_pending_price = 0
	world.set_furniture(furniture_items, expansions, "", Vector2i.ZERO, false, 0, active_decor_floor)

func place_or_select_furniture(screen_position: Vector2) -> void:
	var cell: Vector2i = world.screen_to_floor_grid(shop_layer.to_local(screen_position), active_decor_floor)
	if decor_pending_type != "":
		if is_valid_furniture_placement(decor_pending_type, cell, decor_rotation):
			furniture_items.append({"id":next_furniture_id, "type":decor_pending_type, "x":cell.x, "y":cell.y, "rotation":decor_rotation, "floor":active_decor_floor})
			next_furniture_id += 1
			decor_pending_type = ""
			decor_pending_price = 0
			sync_furniture_state()
			save_game()
			refresh_decor_panel()
			show_alert("家具已摆放")
		else:
			show_alert("这里会重叠或挡住通道，不能摆放")
		return
	if decor_selected_id >= 0:
		for selected_item in furniture_items:
			if int(selected_item.get("id", -1)) == decor_selected_id:
				var selected_type: String = str(selected_item.get("type", ""))
				var selected_rotation: int = int(selected_item.get("rotation", 0))
				if is_valid_furniture_placement(selected_type, cell, selected_rotation, decor_selected_id):
					selected_item["x"] = cell.x
					selected_item["y"] = cell.y
					sync_furniture_state(); save_game(); refresh_decor_panel(); show_alert("家具已移动")
					return
				break
	for item in furniture_items:
		if int(item.get("floor", 1)) != active_decor_floor: continue
		var origin: Vector2i = Vector2i(int(item.get("x", 0)), int(item.get("y", 0)))
		var size: Vector2i = furniture_size(str(item.get("type", "")), int(item.get("rotation", 0)))
		if cell.x >= origin.x and cell.x < origin.x + size.x and cell.y >= origin.y and cell.y < origin.y + size.y:
			decor_selected_id = int(item.get("id", -1))
			refresh_decor_panel()
			show_alert("家具已选中")
			return
	decor_selected_id = -1
	refresh_decor_panel()

func update_furniture_preview(screen_position: Vector2) -> void:
	if not world.decoration_mode or decor_pending_type == "": return
	var cell: Vector2i = world.screen_to_floor_grid(shop_layer.to_local(screen_position), active_decor_floor)
	world.set_furniture(furniture_items, expansions, decor_pending_type, cell, is_valid_furniture_placement(decor_pending_type, cell, decor_rotation), decor_rotation, active_decor_floor)

func rotate_selected_or_pending() -> void:
	if decor_pending_type != "":
		decor_rotation = (decor_rotation + 1) % 2
		refresh_decor_panel()
		return
	if decor_selected_id < 0: return
	for item in furniture_items:
		if int(item.get("id", -1)) == decor_selected_id:
			var next_rotation: int = (int(item.get("rotation", 0)) + 1) % 2
			var origin: Vector2i = Vector2i(int(item.get("x", 0)), int(item.get("y", 0)))
			if is_valid_furniture_placement(str(item.get("type", "")), origin, next_rotation, decor_selected_id):
				item["rotation"] = next_rotation
				sync_furniture_state(); save_game()
			else: show_alert("旋转后会挡住通道")
			return

func sell_selected_furniture() -> void:
	if decor_selected_id < 0: return
	for item in furniture_items.duplicate():
		if int(item.get("id", -1)) == decor_selected_id:
			var item_data: Dictionary = furniture_catalog.get(str(item.get("type", "")), {})
			coins += int(int(item_data.get("price", 0)) * 0.5)
			furniture_items.erase(item)
			decor_selected_id = -1
			sync_furniture_state(); save_game(); refresh_decor_panel(); show_alert("家具已出售")
			return

func buy_left_expansion() -> void:
	if bool(expansions.get("LeftWindow", false)):
		show_alert("左侧窗边区已开放")
		return
	if reputation < 2:
		show_alert("左侧窗边区需要店铺声望 2 级")
		return
	if coins < 260:
		show_alert("金币不足")
		return
	coins -= 260
	expansions["LeftWindow"] = true
	camera_bounds = Rect2(-560, 90, 1810, 850)
	sync_furniture_state(); save_game(); refresh_decor_panel(); show_alert("左侧窗边区已开放")

func toggle_supply_panel() -> void:
	if not supply_panel: return
	var opening: bool = not supply_panel.visible
	if opening: close_navigation_panels(supply_panel)
	supply_panel.visible = opening
	if supply_panel.visible: refresh_supply_panel()

func refresh_supply_panel() -> void:
	if not supply_label: return
	supply_label.text = "每日采购 · 金币 %d · 冰箱 Lv.%d" % [coins, fridge_level]
	if not supply_list_box: return
	for child in supply_list_box.get_children(): child.queue_free()
	for item in ["Beans", "Milk", "Syrup", "Flour", "Cream"]:
		var card: Variant = ShopItemCardScene.instantiate()
		card.setup(item, int(ingredients.get(item, 0)), storage_capacity(item), int(market_prices.get(item, 0)), str(market_trends.get(item, "平稳")), Callable(self, "buy_supply"))
		supply_list_box.add_child(card)
	apply_ui_readability(supply_list_box)

func toggle_market_panel() -> void:
	if not market_panel: return
	var opening: bool = not market_panel.visible
	if opening: close_navigation_panels(market_panel)
	market_panel.visible = opening
	if market_panel.visible: refresh_market_panel()

func toggle_finance_panel() -> void:
	if not finance_panel: return
	var opening: bool = not finance_panel.visible
	if opening: close_navigation_panels(finance_panel)
	finance_panel.visible = opening
	if opening: refresh_finance_panel()

func refresh_finance_panel() -> void:
	if not finance_label: return
	var daily_total: int = revenue - daily_ingredient_cost - daily_spoilage_cost - daily_wages()
	var monthly_total: int = 0
	var yearly_total: int = 0
	var current_month: String = calendar_date_key().left(7)
	var current_year: String = calendar_date_key().left(4)
	var rows: Array[String] = []
	for entry in financial_days:
		var entry_date: String = str(entry.get("date", ""))
		var profit: int = int(entry.get("profit", 0))
		if entry_date.begins_with(current_month): monthly_total += profit
		if entry_date.begins_with(current_year): yearly_total += profit
		rows.append("%s　营业额 %d　利润 %d" % [entry_date, int(entry.get("revenue", 0)), profit])
	rows.reverse()
	finance_label.text = "财务报表\n今日累计利润：%d\n本月利润：%d\n本年利润：%d\n\n每日结算记录\n%s" % [daily_total, monthly_total, yearly_total, "\n".join(rows.slice(0, 12)) if not rows.is_empty() else "尚无已结算日"]

func refresh_market_for_day() -> void:
	if market_day == day and not market_candidates.is_empty(): return
	market_day = day
	market_refreshes_today = 0
	market_candidates.clear()
	var available: Array[Dictionary] = []
	for data in employee_data:
		if str(data.get("quality", "")) != "SSS" and not bool(owned_staff.get(str(data.get("name", "")), false)):
			available.append(data)
	available.shuffle()
	for i in mini(3, available.size()):
		market_candidates.append(make_market_candidate(available[i]))
	if not market_candidates.is_empty() and day >= 15 and reputation >= 8 and coffee_competition_complete and not bool(owned_staff.get("夜班经理·星野澪", false)):
		market_candidates[0] = make_market_candidate(employee_data[7])

func make_market_candidate(data: Dictionary) -> Dictionary:
	var quality: String = str(data.get("quality", "R"))
	var fee: int = {"R":180,"SR":520,"SSR":1800,"SSS":6500}.get(quality, 180)
	var salary: int = {"R":18,"SR":38,"SSR":85,"SSS":160}.get(quality, 18)
	return {"name":str(data.get("name", "")),"role":str(data.get("role", "")),"quality":quality,"make":int(data.get("make", 0)),"service":int(data.get("service", 0)),"clean":int(data.get("clean", 0)),"skill":str(data.get("skill", "基础技能")),"personality":"勤奋" if quality in ["R","SR"] else "自信","salary":salary,"fee":fee,"loyalty":int(data.get("loyalty", 70))}

func refresh_market_panel() -> void:
	refresh_market_for_day()
	if market_label:
		market_label.text = "人才市场 · 经营金币招聘\n金币：%d · 店铺声望：%d\n候选人每天开店前刷新；签约后需每日支付工资\n星野澪：声望 8、经营 15 天并完成咖啡比赛后才可能出现" % [coins, reputation]
	if not market_candidates_box: return
	for child in market_candidates_box.get_children(): child.queue_free()
	for candidate in market_candidates:
		var card: Variant = StaffCandidateCardScene.instantiate()
		card.setup(candidate, show_candidate_detail.bind(candidate))
		market_candidates_box.add_child(card)
	apply_ui_readability(market_candidates_box)

func refresh_market_with_gossip() -> void:
	if market_refreshes_today >= 1:
		show_alert("今天已经打听过消息了")
		return
	if coins < 80:
		show_alert("金币不足")
		return
	coins -= 80
	market_candidates.clear()
	market_refreshes_today += 1
	var available: Array[Dictionary] = []
	for data in employee_data:
		if str(data.get("quality", "")) != "SSS" and not bool(owned_staff.get(str(data.get("name", "")), false)):
			available.append(data)
	available.shuffle()
	for i in mini(3, available.size()):
		market_candidates.append(make_market_candidate(available[i]))
	if not market_candidates.is_empty() and day >= 15 and reputation >= 8 and coffee_competition_complete and not bool(owned_staff.get("夜班经理·星野澪", false)):
		market_candidates[0] = make_market_candidate(employee_data[7])
	refresh_market_panel()
	save_game()

func hire_market_candidate(staff_name: String) -> void:
	for candidate in market_candidates:
		if str(candidate.get("name", "")) != staff_name: continue
		var fee: int = int(candidate.get("fee", 0))
		var capacity_reason: String = assignment_message(staff_name)
		if capacity_reason != "":
			show_alert("当前没有空余上岗名额：%s。请先扩建或安排待岗员工。" % capacity_reason)
			return
		if coins < fee:
			show_alert("金币不足，无法支付签约费")
			return
		if str(candidate.get("quality", "")) == "SSR" and reputation < 4:
			show_alert("SSR 员工需要店铺声望 4")
			return
		if str(candidate.get("quality", "")) == "SSS" and (reputation < 8 or day < 15 or not coffee_competition_complete):
			show_alert("神秘夜班经理尚未满足出现条件")
			return
		coins -= fee
		owned_staff[staff_name] = true
		staff_assignments[staff_name] = true
		staff_loyalty[staff_name] = int(candidate.get("loyalty", 70))
		market_candidates.erase(candidate)
		spawn_staff(); populate_staff_list(); refresh_market_panel(); save_game()
		show_alert("%s 已签约并上岗" % staff_name)
		return

func show_candidate_detail(candidate: Dictionary) -> void:
	var staff_name: String = str(candidate.get("name", ""))
	var text: String = "%s  [%s]\n%s · %s\n\n制作 %d　服务 %d　清洁 %d\n性格：%s\n技能：%s\n\n签约费：%d 金币\n每日工资：%d 金币" % [staff_name, str(candidate.get("quality", "R")), str(candidate.get("role", "")), str(candidate.get("personality", "")), int(candidate.get("make", 0)), int(candidate.get("service", 0)), int(candidate.get("clean", 0)), str(candidate.get("personality", "")), str(candidate.get("skill", "")), int(candidate.get("fee", 0)), int(candidate.get("salary", 0))]
	if confirm_dialog:
		confirm_dialog.show_confirmation("员工详情", text, "确认聘请", hire_market_candidate.bind(staff_name))

func show_staff_detail(staff_name: String) -> void:
	var data_match: Dictionary = {}
	for data in employee_data:
		if str(data.get("name", "")) == staff_name:
			data_match = data
			break
	if data_match.is_empty(): return
	var is_assigned: bool = bool(staff_assignments.get(staff_name, false))
	var next_action: String = "调为待岗" if is_assigned else "安排上岗"
	var text: String = "%s  [%s] · %s\n\n资料\n制作 %d　服务 %d　清洁 %d\n等级 Lv.%d　忠诚 %d　当前 %d楼\n技能：%s\n\n上岗：%s\n训练：80 金币提升主属性\n升职：消耗经营金币" % [staff_name, str(data_match.get("quality", "R")), str(data_match.get("role", "")), int(data_match.get("make", 0)), int(data_match.get("service", 0)), int(data_match.get("clean", 0)), int(employee_levels.get(staff_name, 0)) + 1, int(staff_loyalty.get(staff_name, data_match.get("loyalty", 70))), int(staff_floors.get(staff_name, 1)), str(data_match.get("skill", "")), "上岗中" if is_assigned else "待岗中"]
	if confirm_dialog:
		confirm_dialog.show_confirmation("员工管理 · 资料／上岗／训练／升职", text, next_action, toggle_employee.bind(staff_name))

func cycle_speed(button: Button) -> void:
	if paused: paused=false
	if speed_multiplier == 1.0: speed_multiplier=2.0
	elif speed_multiplier == 2.0: speed_multiplier=4.0
	else: speed_multiplier=1.0
	button.text="×%d" % int(speed_multiplier)

func toggle_pause(button: Button) -> void:
	paused = not paused
	button.text = "▶" if paused else "Ⅱ"

func _unhandled_input(event: InputEvent) -> void:
	# CanvasLayer controls consume their own events, so only empty shop space reaches here.
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			camera_dragging = event.pressed
			if event.pressed:
				last_drag_position = event.position
				camera_velocity = Vector2.ZERO
			return
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			set_camera_zoom(camera_target_zoom + 0.12, event.position)
			return
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_camera_zoom(camera_target_zoom - 0.12, event.position)
			return
		if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
			return
		if world.decoration_mode:
			place_or_select_furniture(event.position)
			return
		select_actor_at(event.position)
		return
	if event is InputEventMouseMotion:
		update_furniture_preview(event.position)
		if camera_dragging:
			pan_camera(event.relative)
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_points[event.index] = event.position
			camera_velocity = Vector2.ZERO
		else:
			if world.decoration_mode and touch_points.size() == 1:
				place_or_select_furniture(event.position)
			touch_points.erase(event.index)
		if touch_points.size() == 1:
			camera_dragging = true
			last_drag_position = event.position
			last_pinch_distance = 0.0
		elif touch_points.size() >= 2:
			camera_dragging = false
			last_pinch_distance = touch_distance()
		else:
			camera_dragging = false
			last_pinch_distance = 0.0
		return
	if event is InputEventScreenDrag:
		touch_points[event.index] = event.position
		if touch_points.size() == 1:
			camera_dragging = true
			pan_camera(event.relative)
			return
		if touch_points.size() >= 2:
			camera_dragging = false
			var pinch_distance: float = touch_distance()
			if last_pinch_distance > 0.0:
				set_camera_zoom(camera_target_zoom * pinch_distance / last_pinch_distance, touch_midpoint())
			last_pinch_distance = pinch_distance
			return

func touch_distance() -> float:
	var points: Array = touch_points.values()
	if points.size() < 2:
		return 0.0
	var first: Vector2 = points[0]
	var second: Vector2 = points[1]
	return first.distance_to(second)

func touch_midpoint() -> Vector2:
	var points: Array = touch_points.values()
	if points.size() < 2:
		return get_viewport_rect().size * 0.5
	var first: Vector2 = points[0]
	var second: Vector2 = points[1]
	return (first + second) * 0.5

func select_actor_at(screen_position: Vector2) -> void:
	var shop_pointer: Vector2 = shop_layer.to_local(screen_position)
	var closest: CafeActor = null
	var best_distance: float = 48.0
	var actors: Array = []
	actors.append_array(staff)
	actors.append_array(customers)
	for actor in actors:
		var distance: float = actor.position.distance_to(shop_pointer)
		if distance < best_distance:
			closest = actor
			best_distance = distance
	selected_actor = closest
	if selected_actor:
		var fatigue: int = 0
		if selected_actor is Staff:
			var selected_staff: Staff = selected_actor as Staff
			fatigue = int(selected_staff.stamina)
		selection_card.text = "%s · %s · Fatigue %d · %s" % [selected_actor.display_name,selected_actor.role,fatigue,selected_actor.state_text]
		selection_card.visible = true
	else:
		selection_card.visible = false

func toggle_shop() -> void:
	if phase == "Open": close_day()
	else: show_prep_panel()

func show_prep_panel() -> void:
	apply_day_unlocks()
	refresh_market_for_day()
	refresh_market_prices()
	prepare_daily_event()
	if settlement_panel: settlement_panel.hide()
	if prep_panel:
		var goal: Dictionary = day_goal()
		if day == 1:
			prep_label.text = "第 1 天 · 营业准备\n\n今日目标：服务 3 位顾客，营业额达到 %d\n\n上岗员工：Lin（咖啡师） · June（服务员）\n\n基础食材已备齐。%s" % [int(goal.get("revenue",0)), reputation_unlock_hint()]
		else:
			prep_label.text = "第 %d 天 · 营业准备\n营业额 %d · 满意度 %.0f%%\n指定饮品：%d × %s\n%s" % [day,int(goal.get("revenue",0)),float(goal.get("satisfaction",0)),int(goal.get("count",0)),str(goal.get("drink","")),reputation_unlock_hint()]
		prep_panel.show()
	refresh_event_ui()

func start_day() -> void:
	if not event_resolved:
		show_alert("请先选择今日特殊事件的应对方式")
		return
	if day == 1:
		for item in ["Beans", "Milk", "Syrup", "Flour", "Cream"]:
			ingredients[item] = maxi(int(ingredients.get(item, 0)), 20)
	prep_panel.hide()
	phase="Open"; elapsed=0; revenue=0; second_floor_revenue=0; second_floor_served=0; second_floor_satisfaction_total=0.0; second_floor_ingredient_cost=0; spawn_timer=.1; daily_ingredient_cost=0; daily_spoilage_cost=0; daily_stockout_losses=0; daily_angry_leaves=0; daily_served=0; drink_counts={}; spawned_today=0; day_one_ready_to_close=false

func begin_next_day_auto() -> void:
	prepare_daily_event()
	event_resolved = true
	event_result_text = "自动经营：今日事件采用默认方案"
	if settlement_panel: settlement_panel.hide()
	begin_auto_business()

func add_reputation(amount: int) -> void:
	reputation_points = maxi(0, reputation_points + amount)
	reputation = clampi(1 + reputation_points / 100, 1, 10)

func reputation_unlock_hint() -> String:
	if reputation < 2: return "声望 Lv.2 解锁：左侧窗边扩建、摩卡研发资格。"
	if reputation < 3: return "声望 Lv.3 解锁：咖啡比赛邀请。"
	if reputation < 4: return "声望 Lv.4 解锁：海盐拿铁研发、SSR 员工候选人。"
	if reputation < 5: return "声望 Lv.5 解锁：二楼建设资格。"
	return "当前已具备一楼、二楼与比赛的声望资格；继续经营可吸引更高级人才。"

func prepare_daily_event() -> void:
	if event_day == day and not current_event.is_empty(): return
	event_day = day
	event_resolved = false
	event_result_text = ""
	event_modifiers = {"traffic":1.0,"student":false,"blogger":false,"vip":false,"sick":false,"competition":false}
	var event_pool: Array[Dictionary] = [
		{"title":"咖啡豆涨价","detail":"供应商通知：今日咖啡豆成本上升。", "choices":[{"text":"接受涨价：咖啡豆单价 +2","effect":"bean_up"},{"text":"花 30 金币预购 20 份咖啡豆","effect":"bean_stock"}]},
		{"title":"暴雨天","detail":"街上人流减少，店内客流可能下滑。", "choices":[{"text":"照常营业：客流减少","effect":"rain_open"},{"text":"花 40 金币安排配送宣传","effect":"rain_delivery"}]},
		{"title":"美食博主探店","detail":"一位美食博主想在今天到店体验。", "choices":[{"text":"预留体验席：满意可提高声望","effect":"blogger_invite"},{"text":"婉拒：声望 -2","effect":"blogger_decline"}]},
		{"title":"附近学校放学","detail":"学生客流增加，消费低但非常耐心。", "choices":[{"text":"准备平价服务：学生客流增加","effect":"school_event"},{"text":"维持原菜单","effect":"none"}]},
		{"title":"员工身体不适","detail":"一名员工状态不好，今天的工作速度会下降。", "choices":[{"text":"花 60 金币请临时帮手","effect":"sick_clinic"},{"text":"继续营业：员工速度降低","effect":"sick_ignore"}]},
		{"title":"VIP 预约","detail":"一位 VIP 顾客预约到店，期待好环境与高级饮品。", "choices":[{"text":"确认预约：安排一位 VIP 到店","effect":"vip_accept"},{"text":"婉拒预约：声望 -3","effect":"vip_decline"}]},
		{"title":"供应商优惠原料","detail":"供应商提供一批低价易腐原料。", "choices":[{"text":"花 55 金币购入牛奶、奶油各 10","effect":"supplier_buy"},{"text":"不购买","effect":"none"}]},
		{"title":"社区咖啡日","detail":"社区活动带来普通顾客，也可能提高口碑。", "choices":[{"text":"参加：客流提高，满意度 -2","effect":"community_join"},{"text":"专注店内服务：声望 +2","effect":"community_focus"}]}
	]
	if reputation >= 3 and day >= 3 and day % 3 == 0:
		current_event = {"title":"咖啡比赛邀请","detail":"声望达到 Lv.3 后的比赛邀请。报名后根据菜单、咖啡师、环境与今日经营结算成绩。", "choices":[{"text":"报名比赛：支付 120 金币","effect":"competition_join"},{"text":"暂不参加","effect":"none"}]}
	else:
		current_event = event_pool[randi_range(0, event_pool.size() - 1)]
	save_game()

func refresh_event_ui() -> void:
	if not event_label or not event_choice_a or not event_choice_b: return
	if current_event.is_empty(): return
	var title: String = str(current_event.get("title", "每日事件"))
	var detail: String = str(current_event.get("detail", ""))
	var choices: Array = current_event.get("choices", [])
	event_label.text = "\n今日特殊事件 · %s\n%s" % [title, detail]
	if choices.size() >= 2:
		var first_choice: Dictionary = choices[0] if choices[0] is Dictionary else {}
		var second_choice: Dictionary = choices[1] if choices[1] is Dictionary else {}
		event_choice_a.text = str(first_choice.get("text", "选项一"))
		event_choice_b.text = str(second_choice.get("text", "选项二"))
	event_choice_a.disabled = event_resolved
	event_choice_b.disabled = event_resolved
	if event_resolved: event_label.text += "\n已选择：%s" % event_result_text

func choose_daily_event(index: int) -> void:
	if event_resolved or current_event.is_empty(): return
	var choices: Array = current_event.get("choices", [])
	if index < 0 or index >= choices.size(): return
	var choice: Dictionary = choices[index] if choices[index] is Dictionary else {}
	var effect: String = str(choice.get("effect", "none"))
	event_result_text = str(choice.get("text", "已选择应对方案"))
	match effect:
		"bean_up":
			market_prices["Beans"] = int(market_prices.get("Beans", 2)) + 2; market_trends["Beans"] = "大幅上涨"
		"bean_stock":
			if coins < 30: show_alert("金币不足，无法预购"); return
			coins -= 30; ingredients["Beans"] = mini(storage_capacity("Beans"), int(ingredients.get("Beans", 0)) + 20)
		"rain_open": event_modifiers["traffic"] = 0.55
		"rain_delivery":
			if coins < 40: show_alert("金币不足，无法宣传"); return
			coins -= 40; event_modifiers["traffic"] = 0.9
		"blogger_invite": event_modifiers["blogger"] = true
		"blogger_decline": add_reputation(-2)
		"school_event": event_modifiers["student"] = true
		"sick_ignore":
			event_modifiers["sick"] = true
			for staff_name in staff_loyalty.keys(): staff_loyalty[staff_name] = maxi(0, int(staff_loyalty.get(staff_name, 70)) - 8)
		"sick_clinic":
			if coins < 60: show_alert("金币不足，无法请临时帮手"); return
			coins -= 60
		"vip_accept": event_modifiers["vip"] = true
		"vip_decline": add_reputation(-3)
		"supplier_buy":
			if coins < 55: show_alert("金币不足，无法采购优惠原料"); return
			coins -= 55
			for item in ["Milk", "Cream"]: ingredients[item] = mini(storage_capacity(item), int(ingredients.get(item, 0)) + 10)
		"community_join": event_modifiers["traffic"] = 1.3; satisfaction = maxf(0.0, satisfaction - 2.0)
		"community_focus": add_reputation(2)
		"competition_join":
			if coins < 120: show_alert("金币不足，无法报名比赛"); return
			coins -= 120; event_modifiers["competition"] = true
	event_resolved = true
	refresh_event_ui()
	save_game()
	show_alert("已选择今日应对方案")

func storage_capacity(item: String) -> int:
	if item in ["Milk", "Cream"]: return 25 + fridge_level * 20
	return 60

func refresh_market_prices() -> void:
	if market_price_day == day: return
	market_price_day = day
	for item in ["Beans", "Milk", "Syrup", "Flour", "Cream"]:
		var base: int = {"Beans":2,"Milk":3,"Syrup":3,"Flour":2,"Cream":4}.get(item, 2)
		var price: int = maxi(1, base + randi_range(-1, 1))
		market_prices[item] = price
		market_trends[item] = "上涨" if price > base else ("下降" if price < base else "平稳")

func buy_supply(item: String, amount: int) -> void:
	var stock: int = int(ingredients.get(item, 0))
	if stock + amount > storage_capacity(item):
		show_alert("仓库容量不足：%s %d/%d" % [item,stock,storage_capacity(item)])
		return
	var price: int = int(market_prices.get(item, 0)) * amount
	if coins >= price:
		coins -= price
		ingredients[item] = stock + amount
		refresh_supply_panel()
		show_alert("补给已送达：%s +%d" % [item, amount])
	else: show_alert("金币不足")

func free_supply() -> void:
	for item in ["Beans", "Milk", "Syrup"]: ingredients[item] = mini(storage_capacity(item), int(ingredients.get(item, 0)) + 5)
	refresh_supply_panel()
	show_alert("已领取免费基础补给")

func toggle_menu_panel() -> void:
	if not menu_panel: return
	var opening: bool = not menu_panel.visible
	if opening: close_navigation_panels(menu_panel)
	menu_panel.visible = opening
	if menu_panel.visible: refresh_menu_panel()

func refresh_menu_panel() -> void:
	if not menu_label or not menu_list: return
	menu_label.text = "菜单与研发 · 冰箱 Lv.%d\n高级品项利润更高，但制作更慢、食材成本更高。" % fridge_level
	for child in menu_list.get_children(): child.queue_free()
	for drink in ["Americano", "Latte", "Mocha", "Sea Salt Latte"]:
		var recipe: Dictionary = menu_recipe(drink)
		var card: Variant = RecipeCardScene.instantiate()
		var action: Callable = toggle_menu_item.bind(drink) if bool(researched_menu.get(drink, false)) else research_menu.bind(drink)
		card.setup(drink, recipe, bool(researched_menu.get(drink, false)), bool(active_menu.get(drink, false)), action)
		menu_list.add_child(card)
	apply_ui_readability(menu_list)

func toggle_menu_item(drink: String) -> void:
	active_menu[drink] = not bool(active_menu.get(drink, false))
	refresh_menu_panel(); save_game()

func best_barista_make() -> int:
	var best: int = 0
	for worker in staff:
		if worker.role == "Barista" and worker.assigned: best = maxi(best, worker.make_skill)
	return best

func research_menu(drink: String) -> void:
	var cost: int = 180 if drink == "Mocha" else 320
	var needs: Dictionary = {"Beans":2,"Milk":2,"Syrup":2} if drink == "Mocha" else {"Beans":3,"Milk":3,"Syrup":2,"Cream":2}
	var needed_skill: int = 2 if drink == "Mocha" else 3
	if coins < cost or best_barista_make() < needed_skill or (drink == "Mocha" and reputation < 2) or (drink == "Sea Salt Latte" and reputation < 4):
		show_alert("研发条件不足：金币、食材、咖啡师能力或声望")
		return
	for item in needs:
		if int(ingredients.get(item, 0)) < int(needs.get(item, 0)):
			show_alert("研发食材不足")
			return
	coins -= cost
	for item in needs: ingredients[item] = int(ingredients.get(item, 0)) - int(needs.get(item, 0))
	researched_menu[drink] = true
	active_menu[drink] = true
	refresh_menu_panel(); save_game(); show_alert("%s 研发完成并已上架" % drink)

func upgrade_fridge() -> void:
	var cost: int = 260 * (fridge_level + 1)
	if coins < cost:
		show_alert("升级冰箱需要 %d 金币" % cost)
		return
	coins -= cost
	fridge_level += 1
	refresh_menu_panel(); save_game(); show_alert("冰箱升级完成")

func upgrade_employee(employee_name: String) -> void:
	if coins < 80:
		show_alert("Need 80 coins for employee upgrade"); return
	if int(employee_levels.get(employee_name, 0)) >= 1:
		show_alert("%s is already upgraded" % employee_name); return
	coins -= 80
	employee_levels[employee_name] = 1
	for data in employee_data:
		if str(data.get("name", "")) == employee_name:
			var job: String = str(data.get("role", ""))
			if job == "Barista": data["make"] = int(data.get("make", 1)) + 1
			elif job == "Waiter": data["service"] = int(data.get("service", 1)) + 1
			elif job == "Cleaner": data["clean"] = int(data.get("clean", 1)) + 1
			else: data["service"] = int(data.get("service", 1)) + 1
	spawn_staff()
	show_alert("%s upgraded" % employee_name)

func star_up(employee_name: String) -> void:
	var promotion_cost: int = 220 * (int(staff_stars.get(employee_name, 0)) + 1)
	if coins < promotion_cost:
		show_alert("升职需要 %d 金币" % promotion_cost)
		return
	coins -= promotion_cost
	staff_stars[employee_name] = int(staff_stars.get(employee_name, 0)) + 1
	for data in employee_data:
		if str(data.get("name", "")) == employee_name:
			data["make"] = int(data.get("make", 1)) + 1
			data["service"] = int(data.get("service", 1)) + 1
			data["clean"] = int(data.get("clean", 1)) + 1
	spawn_staff()
	save_game()
	show_alert("%s 升职完成" % employee_name)

func daily_wages() -> int:
	var total: int = 0
	for data in employee_data:
		var staff_name: String = str(data.get("name", ""))
		if bool(owned_staff.get(staff_name, false)) and bool(staff_assignments.get(staff_name, false)):
			var quality: String = str(data.get("quality", "R"))
			total += {"R":18,"SR":38,"SSR":85,"SSS":160}.get(quality, 18)
	return total

func settle_wages(wages: int) -> void:
	if coins >= wages:
		coins -= wages
		for staff_name in owned_staff.keys():
			if bool(staff_assignments.get(staff_name, false)):
				staff_loyalty[staff_name] = mini(100, int(staff_loyalty.get(staff_name, 70)) + 1)
		return
	coins = 0
	var leaving_name: String = ""
	for staff_name in owned_staff.keys():
		if not bool(staff_assignments.get(staff_name, false)): continue
		var loyalty: int = int(staff_loyalty.get(staff_name, 70)) - 18
		staff_loyalty[staff_name] = loyalty
		if loyalty < 25 and staff_name not in ["Lin", "June", "Bo", "Ari"]:
			leaving_name = str(staff_name)
	if leaving_name != "":
		owned_staff.erase(leaving_name)
		staff_assignments.erase(leaving_name)
		show_alert("%s 因长期低薪离职" % leaving_name)
		spawn_staff()

func apply_daily_spoilage() -> void:
	for item in ["Milk", "Cream"]:
		var stock: int = int(ingredients.get(item, 0))
		if stock <= 0: continue
		var loss_rate: float = maxf(0.02, 0.10 - float(fridge_level) * 0.03)
		var lost: int = mini(stock, maxi(1, floori(float(stock) * loss_rate)))
		ingredients[item] = stock - lost
		daily_spoilage_cost += lost * int(market_prices.get(item, 0))
func close_day(show_settlement: bool = true) -> void:
	if day == 1 and not day_one_ready_to_close and not real_time_closing:
		show_alert("请先完成三位顾客的服务")
		return
	if daily_served <= 0 and not real_time_closing:
		show_alert("至少完成一位顾客的服务后才能结算")
		return
	phase="Closed"
	apply_daily_spoilage()
	var wages: int = daily_wages()
	var profit: int = revenue - daily_ingredient_cost - daily_spoilage_cost - wages
	settle_wages(wages)
	record_financial_day(profit, wages)
	var goal: Dictionary = day_goal()
	var stars: int = 1
	var revenue_goal: bool = revenue >= int(goal.get("revenue",0))
	var satisfaction_goal: bool = satisfaction >= float(goal.get("satisfaction",0))
	var drink_goal: bool = int(drink_counts.get(str(goal.get("drink","")),0)) >= int(goal.get("count",0))
	if revenue_goal and satisfaction_goal: stars = 2
	if revenue_goal and satisfaction_goal and drink_goal and daily_angry_leaves == 0: stars = 3
	var reputation_gain: int = stars * 10
	if profit > 0: reputation_gain += mini(12, profit / 20)
	if satisfaction >= 85.0: reputation_gain += 5
	reputation_gain += environment_score / 3
	reputation_gain += maxi(0, available_drinks().size() - 2)
	var competition_text: String = ""
	if bool(event_modifiers.get("competition", false)):
		var competition_score: int = available_drinks().size() * 12 + best_barista_make() * 15 + environment_score * 3 + stars * 12
		if competition_score >= 70:
			coins += 300
			reputation_gain += 35
			coffee_competition_complete = true
			competition_text = "\n咖啡比赛获胜：+300 金币、+35 声望"
		else:
			competition_text = "\n咖啡比赛成绩 %d/70：继续提升菜单、咖啡师与环境。" % competition_score
	add_reputation(reputation_gain)
	var second_floor_satisfaction: int = roundi(second_floor_satisfaction_total / float(second_floor_served)) if second_floor_served > 0 else 0
	settlement_label.text = "第 %d 天 · 营业结算\n%s\n\n营业额：%d（一楼 %d · 二楼 %d）\n二楼：满意度 %s · 食材消耗 %d\n食材成本：-%d · 损耗：-%d · 工资：-%d\n缺货损失：%d 次\n利润：%d\n声望：+%d · 当前 Lv.%d\n今日事件：%s\n应对：%s%s" % [day,"★".repeat(stars)+"☆".repeat(3-stars),revenue,revenue-second_floor_revenue,second_floor_revenue,"%d%%" % second_floor_satisfaction if second_floor_served > 0 else "暂无二楼顾客",second_floor_ingredient_cost,daily_ingredient_cost,daily_spoilage_cost,wages,daily_stockout_losses,profit,reputation_gain,reputation,str(current_event.get("title", "无")),event_result_text,competition_text]
	if show_settlement and settlement_panel:
		settlement_panel.show()
	day += 1
	apply_day_unlocks()
	save_game()

func record_financial_day(profit: int, wages: int) -> void:
	var date_key: String = active_calendar_date if active_calendar_date != "" else calendar_date_key()
	financial_days.append({"date":date_key,"revenue":revenue,"ingredients":daily_ingredient_cost,"spoilage":daily_spoilage_cost,"wages":wages,"profit":profit})
	if financial_days.size() > 370: financial_days.pop_front()
func set_speed(value: float) -> void: speed_multiplier=value
func upgrade_machine() -> void:
	if coins>=120: coins-=120; upgrades.Machine+=1; show_alert("咖啡机升级：制作更快")
func upgrade_tables() -> void:
	if upgrades.Tables >= 4:
		show_alert("大厅服务区已达到一楼上限")
		return
	if coins >= 350:
		coins -= 350
		upgrades.Tables += 1
		spawn_staff(); populate_staff_list(); save_game(); show_alert("大厅扩大：服务员岗位 +1")
	else: show_alert("金币不足")

func expand_cleaning_room() -> void:
	if cleaning_room_level >= 2:
		show_alert("清洁间已达到一楼上限")
		return
	if coins < 320:
		show_alert("金币不足")
		return
	coins -= 320
	cleaning_room_level += 1
	spawn_staff(); populate_staff_list(); save_game(); show_alert("清洁间扩建完成：清洁员岗位 +1")

func try_unlock_second_floor() -> void:
	if second_floor_unlocked:
		show_alert("二楼入口已开放，可继续扩建雅座区")
		return
	if not first_floor_is_complete() or reputation < 5 or day < 15:
		show_alert("需要完成一楼全部岗位扩建、达到声望 5，并累计经营 15 天")
		return
	if coins < 1800:
		show_alert("建设二楼需要 1800 金币")
		return
	coins -= 1800
	second_floor_unlocked = true
	second_floor_level = 1
	sync_furniture_state()
	save_game()
	show_alert("二楼已开放：2 张桌位、1 个服务区与 3 个岗位已就绪")

func upgrade_second_floor() -> void:
	if not second_floor_unlocked:
		show_alert("请先满足条件建设二楼")
		return
	if second_floor_level >= 3:
		show_alert("二楼已完成全部扩建")
		return
	var cost: int = 900 if second_floor_level == 1 else 1400
	if coins < cost:
		show_alert("二楼扩建需要 %d 金币" % cost)
		return
	coins -= cost
	second_floor_level += 1
	sync_furniture_state()
	spawn_staff()
	populate_staff_list()
	save_game()
	show_alert("二楼扩建完成：新增桌位和岗位")
func toggle_staff() -> void:
	var opening: bool = not staff_panel.visible
	if opening: close_navigation_panels(staff_panel)
	staff_panel.visible=opening
	if staff_panel.visible: populate_staff_list()
func toggle_employee(employee_name: String) -> void:
	if not bool(owned_staff.get(employee_name, false)): return
	if bool(staff_assignments.get(employee_name, false)):
		staff_assignments[employee_name] = false
		show_alert("%s 已调为待岗" % employee_name)
	else:
		var reason: String = assignment_message(employee_name)
		if reason != "":
			show_alert(reason)
			return
		staff_assignments[employee_name] = true
		show_alert("%s 已安排一楼上岗" % employee_name)
	spawn_staff()
	populate_staff_list()
	save_game()

func assign_staff_to_floor(employee_name: String, floor_level: int, target_role: String) -> void:
	if employee_name == "":
		employee_name = selected_roster_staff
	if employee_name == "":
		show_alert("请先在员工仓库选择一名员工")
		return
	if not bool(owned_staff.get(employee_name, false)):
		return
	var worker_role: String = ""
	for data in employee_data:
		if str(data.get("name", "")) == employee_name:
			worker_role = str(data.get("role", ""))
			break
	if worker_role == "" or worker_role != target_role:
		show_alert("只能把%s拖到对应的%s岗位" % [role_display_name(worker_role), role_display_name(target_role)])
		return
	if role_capacity(worker_role, floor_level) <= 0:
		show_alert("这个楼层暂时没有对应岗位")
		return
	if bool(staff_assignments.get(employee_name, false)) and int(staff_floors.get(employee_name, 1)) == floor_level:
		show_alert("%s 已在这个岗位板上" % employee_name)
		return
	if role_assigned_count(worker_role, employee_name, floor_level) >= role_capacity(worker_role, floor_level):
		show_alert("%s 岗位已满，请先扩建设施或将员工拖回仓库" % role_display_name(worker_role))
		return
	staff_floors[employee_name] = floor_level
	staff_assignments[employee_name] = true
	selected_roster_staff = ""
	spawn_staff()
	populate_staff_list()
	save_game()
	show_alert("%s 已安排到 %d楼%s岗位" % [employee_name, floor_level, role_display_name(worker_role)])

func select_staff_for_assignment(employee_name: String) -> void:
	if not bool(owned_staff.get(employee_name, false)) or bool(staff_assignments.get(employee_name, false)):
		return
	selected_roster_staff = employee_name
	populate_staff_list()
	show_alert("已选择 %s：请点击上方对应的空岗位" % employee_name)

func move_staff_to_warehouse(employee_name: String) -> void:
	if not bool(owned_staff.get(employee_name, false)):
		return
	if not bool(staff_assignments.get(employee_name, false)):
		return
	staff_assignments[employee_name] = false
	if selected_roster_staff == employee_name: selected_roster_staff = ""
	spawn_staff()
	populate_staff_list()
	save_game()
	show_alert("%s 已回到员工仓库，今日不再领取完整日薪" % employee_name)

func toggle_employee_floor(employee_name: String) -> void:
	if not second_floor_unlocked or not bool(owned_staff.get(employee_name, false)): return
	var next_floor: int = 2 if int(staff_floors.get(employee_name, 1)) == 1 else 1
	var worker_role: String = ""
	for data in employee_data:
		if str(data.get("name", "")) == employee_name: worker_role = str(data.get("role", ""))
	if bool(staff_assignments.get(employee_name, false)) and role_assigned_count(worker_role, employee_name, next_floor) >= role_capacity(worker_role, next_floor):
		show_alert("二楼该岗位已满，请先扩建或调整排班")
		return
	staff_floors[employee_name] = next_floor
	var moved_worker: Staff = null
	for worker in staff:
		if worker.display_name == employee_name:
			moved_worker = worker
			break
	if moved_worker:
		moved_worker.floor_level = next_floor
		moved_worker.task = {"kind":"transfer","target":cell_to_screen(Vector2i(9,7), next_floor),"stage":"move","remaining":0.0}
		moved_worker.target_position = cell_to_screen(Vector2i(9,7), next_floor)
		moved_worker.state_text = "上下楼中"
	else:
		spawn_staff()
	populate_staff_list()
	save_game()
	show_alert("%s 已安排到 %d楼" % [employee_name, next_floor])

func dismiss_employee(employee_name: String) -> void:
	if not bool(owned_staff.get(employee_name, false)): return
	owned_staff.erase(employee_name)
	staff_assignments.erase(employee_name)
	staff_loyalty.erase(employee_name)
	spawn_staff()
	populate_staff_list()
	save_game()
	show_alert("%s 已解雇" % employee_name)
func show_alert(text: String) -> void: alert_label.text=text
func save_game() -> void: SaveSystem.save_game({"day":day,"coins":coins,"revenue":revenue,"daily_ingredient_cost":daily_ingredient_cost,"daily_spoilage_cost":daily_spoilage_cost,"daily_served":daily_served,"active_calendar_date":active_calendar_date,"financial_days":financial_days,"ingredients":ingredients,"market_prices":market_prices,"market_trends":market_trends,"market_price_day":market_price_day,"fridge_level":fridge_level,"researched_menu":researched_menu,"active_menu":active_menu,"upgrades":upgrades,"unlocks":unlocks,"employee_levels":employee_levels,"owned_staff":owned_staff,"staff_assignments":staff_assignments,"staff_floors":staff_floors,"staff_loyalty":staff_loyalty,"staff_stars":staff_stars,"furniture_items":furniture_items,"expansions":expansions,"next_furniture_id":next_furniture_id,"ui_size_mode":ui_size_mode,"game_orientation":game_orientation,"reputation":reputation,"reputation_points":reputation_points,"coffee_competition_complete":coffee_competition_complete,"current_event":current_event,"event_day":event_day,"event_resolved":event_resolved,"event_result_text":event_result_text,"event_modifiers":event_modifiers,"market_candidates":market_candidates,"market_day":market_day,"market_refreshes_today":market_refreshes_today,"cleaning_room_level":cleaning_room_level,"second_floor_unlocked":second_floor_unlocked,"second_floor_level":second_floor_level,"settled_real_date":settled_real_date,"last_online_unix":int(Time.get_unix_time_from_system())})
func load_save() -> void:
	var data: Dictionary = SaveSystem.load_game()
	if data.is_empty(): return
	day = int(data.get("day", day))
	coins = int(data.get("coins", coins))
	revenue = int(data.get("revenue", revenue))
	daily_ingredient_cost = int(data.get("daily_ingredient_cost", daily_ingredient_cost))
	daily_spoilage_cost = int(data.get("daily_spoilage_cost", daily_spoilage_cost))
	daily_served = int(data.get("daily_served", daily_served))
	active_calendar_date = str(data.get("active_calendar_date", active_calendar_date))
	if active_calendar_date != "": needs_new_calendar_day = false
	var saved_financial_days: Variant = data.get("financial_days", financial_days)
	if saved_financial_days is Array:
		financial_days.clear()
		for entry in saved_financial_days:
			if entry is Dictionary: financial_days.append(entry)
	var saved_ingredients: Variant = data.get("ingredients", ingredients)
	var saved_upgrades: Variant = data.get("upgrades", upgrades)
	if saved_ingredients is Dictionary:
		ingredients = saved_ingredients
	for item in ["Beans", "Milk", "Syrup", "Flour", "Cream"]:
		if not ingredients.has(item): ingredients[item] = 0
	var saved_prices: Variant = data.get("market_prices", market_prices)
	var saved_trends: Variant = data.get("market_trends", market_trends)
	var saved_researched: Variant = data.get("researched_menu", researched_menu)
	var saved_active_menu: Variant = data.get("active_menu", active_menu)
	if saved_prices is Dictionary: market_prices = saved_prices
	if saved_trends is Dictionary: market_trends = saved_trends
	if saved_researched is Dictionary: researched_menu = saved_researched
	if saved_active_menu is Dictionary: active_menu = saved_active_menu
	market_price_day = int(data.get("market_price_day", market_price_day))
	fridge_level = int(data.get("fridge_level", fridge_level))
	if saved_upgrades is Dictionary:
		upgrades = saved_upgrades
	var saved_unlocks: Variant = data.get("unlocks", unlocks)
	var saved_levels: Variant = data.get("employee_levels", employee_levels)
	if saved_unlocks is Dictionary: unlocks = saved_unlocks
	if saved_levels is Dictionary: employee_levels = saved_levels
	var saved_owned: Variant = data.get("owned_staff", owned_staff)
	var saved_assignments: Variant = data.get("staff_assignments", staff_assignments)
	var saved_staff_floors: Variant = data.get("staff_floors", staff_floors)
	var saved_stars: Variant = data.get("staff_stars", staff_stars)
	var saved_loyalty: Variant = data.get("staff_loyalty", staff_loyalty)
	if saved_owned is Dictionary: owned_staff = saved_owned
	if saved_assignments is Dictionary: staff_assignments = saved_assignments
	if saved_staff_floors is Dictionary: staff_floors = saved_staff_floors
	if saved_stars is Dictionary: staff_stars = saved_stars
	if saved_loyalty is Dictionary: staff_loyalty = saved_loyalty
	var saved_furniture: Variant = data.get("furniture_items", furniture_items)
	var saved_expansions: Variant = data.get("expansions", expansions)
	if saved_furniture is Array:
		furniture_items.clear()
		for raw_item in saved_furniture:
			if raw_item is Dictionary:
				furniture_items.append(raw_item)
	if saved_expansions is Dictionary: expansions = saved_expansions
	next_furniture_id = int(data.get("next_furniture_id", next_furniture_id))
	ui_size_mode = str(data.get("ui_size_mode", ui_size_mode))
	game_orientation = str(data.get("game_orientation", game_orientation))
	reputation = int(data.get("reputation", reputation))
	reputation_points = int(data.get("reputation_points", (reputation - 1) * 100))
	coffee_competition_complete = bool(data.get("coffee_competition_complete", coffee_competition_complete))
	var saved_event: Variant = data.get("current_event", current_event)
	var saved_modifiers: Variant = data.get("event_modifiers", event_modifiers)
	if saved_event is Dictionary: current_event = saved_event
	if saved_modifiers is Dictionary: event_modifiers = saved_modifiers
	event_day = int(data.get("event_day", event_day))
	event_resolved = bool(data.get("event_resolved", event_resolved))
	event_result_text = str(data.get("event_result_text", event_result_text))
	var saved_candidates: Variant = data.get("market_candidates", market_candidates)
	if saved_candidates is Array:
		market_candidates.clear()
		for raw_candidate in saved_candidates:
			if raw_candidate is Dictionary: market_candidates.append(raw_candidate)
	market_day = int(data.get("market_day", market_day))
	market_refreshes_today = int(data.get("market_refreshes_today", market_refreshes_today))
	cleaning_room_level = int(data.get("cleaning_room_level", cleaning_room_level))
	second_floor_unlocked = bool(data.get("second_floor_unlocked", second_floor_unlocked))
	second_floor_level = int(data.get("second_floor_level", 1 if second_floor_unlocked else 0))
	settled_real_date = str(data.get("settled_real_date", settled_real_date))
	apply_offline_earnings(int(data.get("last_online_unix", 0)))

func _exit_tree() -> void:
	if is_inside_tree(): save_game()
func reset_save() -> void:
	SaveSystem.reset_game(); day=1; coins=800; ingredients={"Beans":30,"Milk":25,"Syrup":18,"Flour":12,"Cream":12}; market_prices={"Beans":2,"Milk":3,"Syrup":3,"Flour":2,"Cream":4}; market_trends={}; market_price_day=0; fridge_level=0; researched_menu={"Americano":true,"Latte":true,"Mocha":false,"Sea Salt Latte":false}; active_menu={"Americano":true,"Latte":true,"Mocha":false,"Sea Salt Latte":false}; upgrades={"Machine":1,"Register":1,"Tables":1}; unlocks={"Mocha":false,"SecondBarista":false,"PastryCase":false,"TalentMarket":false,"SeaSaltLatte":false}; employee_levels={}; owned_staff={"Lin":true,"June":true,"Bo":true,"Ari":true}; staff_assignments={"Lin":true,"June":true,"Bo":false,"Ari":false}; staff_floors={"Lin":1,"June":1,"Bo":1,"Ari":1}; staff_loyalty={}; staff_stars={}; reputation=1; reputation_points=0; coffee_competition_complete=false; current_event={}; event_day=0; event_resolved=true; event_result_text="自动经营：今日事件采用默认方案"; event_modifiers={"traffic":1.0,"student":false,"blogger":false,"vip":false,"sick":false,"competition":false}; market_candidates=[]; market_day=0; market_refreshes_today=0; cleaning_room_level=0; second_floor_unlocked=false; second_floor_level=0; furniture_items=[]; expansions={"LeftWindow":false}; next_furniture_id=1; active_calendar_date=calendar_date_key(); needs_new_calendar_day=true; sync_furniture_state(); refresh_market_for_day(); refresh_market_prices(); spawn_staff(); populate_staff_list(); if prep_panel: prep_panel.hide(); if settlement_panel: settlement_panel.hide(); begin_auto_business(); show_alert("存档已重置，咖啡店已自动营业")
