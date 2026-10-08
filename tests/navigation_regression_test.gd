extends SceneTree

class TestCafe extends "res://scripts/main.gd":
	func _ready() -> void: pass
	func _process(_delta: float) -> void: pass
	func save_game() -> void: pass
	func show_alert(_message: String) -> void: pass
	func _exit_tree() -> void: pass

func _initialize() -> void: call_deferred("run_checks")

func run_checks() -> void:
	var cafe := TestCafe.new()
	root.add_child(cafe)
	cafe.shop_layer = Node2D.new()
	cafe.add_child(cafe.shop_layer)
	cafe.world = CafeWorld.new()
	cafe.shop_layer.add_child(cafe.world)
	cafe.sync_furniture_state()
	assert(cafe.navigation.layout_accessible())
	assert(not cafe.navigation.walkable(Vector2i(3,2),1), "Counter blocks movement")
	assert(not cafe.navigation.walkable(Vector2i(3,4),1), "Table blocks movement")
	var path: Array[Vector2i] = cafe.navigation.cell_path(Vector2i(3,3),Vector2i(3,5),1)
	assert(path.size() > 3, "Must detour around the table")
	for i in path.size():
		assert(cafe.navigation.walkable(path[i],1))
		if i > 0: assert(absi(path[i].x-path[i-1].x)+absi(path[i].y-path[i-1].y) == 1)
	for level in [1,2,3]:
		cafe.second_floor_unlocked = true
		cafe.second_floor_level = level
		cafe.sync_furniture_state()
		assert(cafe.navigation.layout_accessible(), "Each floor upgrade has reachable facilities")
		var route: Array[Dictionary] = cafe.navigation.route(cafe.cell_to_screen(Vector2i(10,10)),1,cafe.table_point(5),2)
		assert(not route.is_empty())
		var transitions: int = 0
		for i in route.size():
			var waypoint: Dictionary = route[i]
			var cell: Vector2i = cafe.world.screen_to_floor_grid(waypoint.point,int(waypoint.floor))
			assert(cafe.navigation.walkable(cell,int(waypoint.floor)))
			if bool(waypoint.get("stairs",false)):
				transitions += 1
				assert(route[i-1].point == cafe.cell_to_screen(cafe.navigation.stair(1),1))
				assert(waypoint.point == cafe.cell_to_screen(cafe.navigation.stair(2),2))
		assert(transitions == 1)
		var actor := Customer.new()
		cafe.shop_layer.add_child(actor)
		actor.position = cafe.cell_to_screen(Vector2i(10,10))
		actor.target_position = cafe.table_point(5)
		for frame in 300: actor.follow_route(cafe.navigation,2,0.1)
		assert(actor.navigation_floor == 2 and actor.position == actor.target_position)
		actor.target_position = cafe.cell_to_screen(Vector2i(10,10))
		for frame in 300: actor.follow_route(cafe.navigation,1,0.1)
		assert(actor.navigation_floor == 1 and actor.position == actor.target_position)
		actor.queue_free()
	cafe.second_floor_unlocked = false
	cafe.sync_furniture_state()
	for cell in [Vector2i(3,8),Vector2i(4,7),Vector2i(3,6)]:
		assert(cafe.is_valid_furniture_placement("Plant",cell,0))
		cafe.furniture_items.append({"id":cafe.next_furniture_id,"type":"Plant","x":cell.x,"y":cell.y,"rotation":0,"floor":1})
		cafe.next_furniture_id += 1
		cafe.sync_furniture_state()
	assert(not cafe.is_valid_furniture_placement("Plant",Vector2i(2,7),0), "Cannot seal the last table interaction cell")
	cafe.furniture_items.clear()
	cafe.sync_furniture_state()
	var camera := Camera2D.new()
	cafe.shop_layer.add_child(camera)
	camera.position = Vector2(400,350)
	camera.zoom = Vector2(1.4,1.4)
	camera.force_update_scroll()
	var original := cafe.cell_to_screen(Vector2i(2,6))
	var pointer: Vector2 = cafe.shop_layer.get_global_transform_with_canvas() * original
	var recovered: Vector2 = cafe.shop_layer.get_global_transform_with_canvas().affine_inverse() * pointer
	assert(recovered.distance_to(original) < 0.001)
	assert(cafe.world.screen_to_grid(recovered) == Vector2i(2,6))
	print("PASS: obstacle detours, cardinal paths, all floor sizes, stair transitions, upstairs/downstairs arrival, blocked decoration, camera coordinates")
	cafe.queue_free()
	quit()
