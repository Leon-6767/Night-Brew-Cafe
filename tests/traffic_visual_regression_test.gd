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
	var first := Customer.new()
	var second := Customer.new()
	cafe.shop_layer.add_child(first)
	cafe.shop_layer.add_child(second)
	first.position = cafe.cell_to_screen(Vector2i(4,5))
	second.position = cafe.cell_to_screen(Vector2i(6,5))
	first.target_position = second.position
	second.target_position = first.position
	first.phase = "walking"
	second.phase = "walking"
	cafe.customers.append_array([first,second])
	for tick in 300:
		cafe.move_visible_actors(0.1)
		assert(first.position.distance_to(second.position) >= 19.0, "Oncoming actors must not overlap")
	assert(cafe.actor_at_target(first) and cafe.actor_at_target(second), "Oncoming actors must detour and arrive")
	assert(first.z_index > 0 and second.z_index > 0)
	var visual: Node = first.visual
	visual.set_status("制作",false)
	visual.play_task("make")
	var animation: Animation = visual.animator.get_animation("make")
	assert(animation.get_track_count() >= 2)
	visual.animator.advance(0.12)
	var previous: float = visual.animator.current_animation_position
	visual.play_task("make")
	assert(visual.animator.current_animation_position == previous, "Repeating status must not restart animation")
	visual.set_status("移动",true)
	visual.play_task("make")
	assert(visual.animator.current_animation == "walk")
	visual.set_direction(Vector2.LEFT)
	assert(visual.body.flip_h and visual.head.flip_h)
	visual.set_status("待命",false)
	visual.play_task("")
	assert(visual.animator.current_animation == "idle")
	cafe.furniture_items.append({"id":99,"type":"Plant","x":2,"y":6,"rotation":0,"floor":1})
	cafe.sync_furniture_state()
	assert(cafe.world.furniture_nodes.has(99))
	var plant: Node2D = cafe.world.furniture_nodes[99]
	assert(plant.z_index == 1000 + int(plant.position.y))
	cafe.second_floor_unlocked = true
	cafe.second_floor_level = 1
	cafe.sync_furniture_state()
	for table in cafe.world.table_nodes:
		assert(table.z_index > 0, "Upper floor tables remain above background")
	cafe.furniture_items.clear()
	cafe.sync_furniture_state()
	assert(not cafe.world.furniture_nodes.has(99))
	print("PASS: oncoming traffic detours, separation, animation tracks, no animation restart, walk priority, facing, furniture lifecycle, floor depth")
	cafe.queue_free()
	quit()
