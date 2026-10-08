extends SceneTree

class TestCafe extends "res://scripts/main.gd":
	func _ready() -> void: pass
	func _process(_delta: float) -> void: pass
	func save_game() -> void: pass
	func show_alert(_message: String) -> void: pass
	func _exit_tree() -> void: pass

func _initialize() -> void: call_deferred("run_checks")

func make_cafe() -> TestCafe:
	var cafe := TestCafe.new()
	root.add_child(cafe)
	cafe.shop_layer = Node2D.new()
	cafe.add_child(cafe.shop_layer)
	cafe.world = CafeWorld.new()
	cafe.shop_layer.add_child(cafe.world)
	cafe.second_floor_unlocked = true
	cafe.second_floor_level = 1
	cafe.sync_furniture_state()
	return cafe

func run_checks() -> void:
	var cafe := make_cafe()
	var guest := Customer.new()
	cafe.shop_layer.add_child(guest)
	cafe.customers.append(guest)
	guest.floor_level = 2
	guest.phase = "stairs_up"
	guest.position = cafe.cell_to_screen(cafe.navigation.stair(1),1)
	guest.target_position = cafe.cell_to_screen(cafe.navigation.stair(2),2)
	guest.follow_route(cafe.navigation,2,0.1)
	assert(guest.stair_elapsed == 0.0 and guest.navigation_floor == 1)
	guest.follow_route(cafe.navigation,2,0.4)
	var midpoint: Vector2 = guest.position
	assert(midpoint != guest.stair_start and midpoint != guest.stair_end)
	guest.follow_route(cafe.navigation,2,0.0)
	assert(guest.position == midpoint, "Paused stairs remain stationary")
	var reopened := make_cafe()
	reopened.restore_runtime(JSON.parse_string(JSON.stringify(cafe.snapshot_runtime())))
	var resumed: Customer = reopened.customers[0]
	assert(resumed.position == midpoint and is_equal_approx(resumed.stair_elapsed,0.4))
	resumed.follow_route(reopened.navigation,2,0.8)
	assert(resumed.navigation_floor == 2 and resumed.position == resumed.stair_end and resumed.stair_elapsed < 0.0)
	var waiter := Staff.new()
	var cleaner := Staff.new()
	waiter.role = "Waiter"
	cleaner.role = "Cleaner"
	for worker in [waiter,cleaner]:
		worker.floor_level = 2
		worker.navigation_floor = 2
		cafe.shop_layer.add_child(worker)
		cafe.staff.append(worker)
	waiter.position = cafe.cell_to_screen(Vector2i(5,3),2)
	waiter.target_position = cafe.cell_to_screen(Vector2i(3,3),2)
	waiter.task = {"kind":"transfer","stage":"move","target":waiter.target_position,"remaining":0.0}
	cleaner.position = cafe.cell_to_screen(Vector2i(4,3),2)
	cleaner.target_position = cleaner.position
	cafe.customers.clear()
	guest.queue_free()
	for frame in 300:
		cafe.move_visible_actors(0.1)
		cafe.advance_staff(cleaner,0.1)
	assert(cafe.actor_at_target(waiter), "Idle worker must yield a narrow work corridor")
	print("PASS: continuous stairs, pause, mid-stair JSON restore, landing arrival, idle staff corridor yield")
	cafe.queue_free()
	reopened.queue_free()
	quit()
