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
	for reverse_order in [false,true]:
		var cafe := make_cafe()
		var up := Customer.new()
		var down := Customer.new()
		for actor in [up,down]: cafe.shop_layer.add_child(actor)
		up.navigation_floor = 1
		up.floor_level = 2
		up.phase = "stairs_up"
		up.position = cafe.cell_to_screen(cafe.navigation.stair(1),1)
		up.target_position = cafe.table_point(5)
		down.navigation_floor = 2
		down.floor_level = 1
		down.phase = "leaving"
		down.position = cafe.cell_to_screen(cafe.navigation.stair(2),2)
		down.target_position = cafe.cell_to_screen(Vector2i(10,10))
		cafe.customers.assign([down,up] if reverse_order else [up,down])
		for tick in 3: cafe.move_visible_actors(0.1)
		var reopened := make_cafe()
		reopened.restore_runtime(JSON.parse_string(JSON.stringify(cafe.snapshot_runtime())))
		assert(reopened.navigation.stair_queue.size() == cafe.navigation.stair_queue.size(), "Waiting order survives reopen")
		for tick in 600: reopened.move_visible_actors(0.1)
		for actor in reopened.customers: assert(reopened.actor_at_target(actor), "Restored passengers finish both journeys")
		reopened.queue_free()
		for tick in 600:
			cafe.move_visible_actors(0.1)
			assert(not (up.stair_elapsed >= 0.0 and down.stair_elapsed >= 0.0), "One actor on staircase at a time")
			if up.navigation_floor == down.navigation_floor and up.stair_elapsed < 0.0 and down.stair_elapsed < 0.0:
				assert(up.position.distance_to(down.position) >= 19.0, "Opposite passengers do not overlap on landing")
		assert(cafe.actor_at_target(up) and cafe.actor_at_target(down), "Opposite passengers must both arrive")
		assert(cafe.navigation.stair_queue.is_empty())
		cafe.queue_free()
	var crowded := make_cafe()
	var lower: Array[Vector2i] = [Vector2i(9,7),Vector2i(10,7),Vector2i(10,6)]
	var upper: Array[Vector2i] = [Vector2i(5,5),Vector2i(5,4),Vector2i(4,5)]
	for i in 3:
		for direction in [1,2]:
			var passenger := Customer.new()
			crowded.shop_layer.add_child(passenger)
			passenger.navigation_floor = direction
			passenger.floor_level = 3-direction
			passenger.phase = "walking"
			passenger.position = crowded.cell_to_screen(lower[i] if direction == 1 else upper[i],direction)
			passenger.target_position = crowded.table_point(5) if direction == 1 else crowded.cell_to_screen(Vector2i(10,10))
			crowded.customers.append(passenger)
	var completed: int = 0
	for tick in 1800:
		crowded.move_visible_actors(0.1)
		if tick in [3,20,50]:
			var reopened := make_cafe()
			reopened.restore_runtime(JSON.parse_string(JSON.stringify(crowded.snapshot_runtime())))
			crowded.queue_free()
			crowded = reopened
		assert(crowded.customers.filter(func(actor): return actor.stair_elapsed >= 0.0).size() <= 1)
		for actor in crowded.customers.duplicate():
			if crowded.actor_at_target(actor):
				completed += 1
				crowded.navigation.release_stairs(actor)
				crowded.customers.erase(actor)
				actor.queue_free()
	assert(completed == 6, "Six mixed-direction passengers must drain the staircase queue")
	crowded.queue_free()
	print("PASS: bidirectional staircase, restored waiting order, exclusive transit, clear landings, six-passenger queue drain with three save/reopen cycles")
	quit()
