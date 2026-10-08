class_name CafeNavigation
extends RefCounted

var grids: Dictionary = {}
var revision: int = 0
var cafe: Node
var crowd: Array = []
var stair_queue: Array = []
var stair_owner: Node = null

func release_stairs(actor: Node) -> void:
	stair_queue.erase(actor)
	if stair_owner == actor: stair_owner = null

func acquire_stairs(actor: Node, destination_floor: int) -> bool:
	if crowd.any(func(other): return is_instance_valid(other) and other != actor and other.stair_elapsed >= 0.0): return false
	stair_queue = stair_queue.filter(func(waiter): return is_instance_valid(waiter) and waiter in crowd and waiter.navigation_floor != waiter.route_floor)
	if is_instance_valid(stair_owner) and stair_owner.stair_elapsed >= 0.0: return stair_owner == actor
	stair_owner = null
	if actor not in stair_queue: stair_queue.append(actor)
	if stair_queue[0] != actor: return false
	var landing: Vector2 = cafe.cell_to_screen(stair(destination_floor),destination_floor)
	for other in crowd:
		if not is_instance_valid(other) or other == actor or other.navigation_floor != destination_floor or other.stair_elapsed >= 0.0: continue
		if other.position.distance_to(landing) >= 24.0: continue
		if other.route_floor != destination_floor and other.route_floor in [1,2]:
			park_landing(other)
		else: request_yield(landing,destination_floor,actor)
		return false
	stair_owner = actor
	return true

func park_landing(actor: Node, depth: int = 0) -> void:
	if depth >= 3: return
	if not actor.traffic_detour.is_empty() or actor.parked_for_stairs: return
	var floor_level: int = actor.navigation_floor
	var origin: Vector2i = cafe.world.screen_to_floor_grid(actor.position,floor_level)
	for offset in [Vector2i(0,-1),Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1)]:
		var cell: Vector2i = origin+offset
		var point: Vector2 = cafe.cell_to_screen(cell,floor_level)
		if not walkable(cell,floor_level) or cell == stair(floor_level): continue
		if point_occupied(point,floor_level,actor):
			for blocker in crowd:
				if not is_instance_valid(blocker) or blocker == actor or blocker.navigation_floor != floor_level: continue
				if blocker.route_floor in [1,2] and blocker.route_floor != floor_level and blocker.position.distance_to(point) < 24.0:
					park_landing(blocker,depth+1)
			continue
		actor.traffic_detour.assign([{"point":point,"floor":floor_level}])
		actor.parked_for_stairs = true
		if actor not in stair_queue: stair_queue.append(actor)
		return

func request_yield(point: Vector2, floor_level: int, requester: Node) -> void:
	for actor in crowd:
		if not is_instance_valid(actor) or not actor is Staff or actor == requester or actor.navigation_floor != floor_level: continue
		if not actor.task.is_empty() or actor.stair_elapsed >= 0.0 or actor.position.distance_to(point) > 30.0: continue
		var origin: Vector2i = cafe.world.screen_to_floor_grid(actor.position,floor_level)
		for radius in [1,2,3]:
			for offset in [Vector2i(radius,0),Vector2i(0,-radius),Vector2i(0,radius),Vector2i(-radius,0)]:
				var cell: Vector2i = origin+offset
				var candidate: Vector2 = cafe.cell_to_screen(cell,floor_level)
				if not walkable(cell,floor_level) or point_occupied(candidate,floor_level,actor): continue
				if requester.route.any(func(waypoint): return waypoint.point.distance_to(candidate) < 1.0): continue
				var path: Array[Dictionary] = crowd_route(actor.position,floor_level,candidate,floor_level,actor)
				if path.is_empty(): continue
				actor.target_position = candidate
				actor.yield_timer = 3.0
				actor.state_text = "让出通道"
				return

func set_crowd(actors: Array) -> void:
	crowd = actors

func point_occupied(point: Vector2, floor_level: int, except_actor: Node) -> bool:
	for actor in crowd:
		if not is_instance_valid(actor) or actor == except_actor or actor.navigation_floor != floor_level or actor.stair_elapsed >= 0.0: continue
		if actor.position.distance_to(point) < 24.0: return true
	return false

func segment_occupied(start: Vector2, end: Vector2, floor_level: int, except_actor: Node) -> bool:
	for actor in crowd:
		if not is_instance_valid(actor) or actor == except_actor or actor.navigation_floor != floor_level or actor.stair_elapsed >= 0.0: continue
		var distance: float = actor.position.distance_to(start)
		if distance < 20.0 and actor.position.distance_to(end) > distance: continue
		if actor.position.distance_to(Geometry2D.get_closest_point_to_segment(actor.position,start,end)) < 20.0: return true
	return false

func crowd_route(start: Vector2, start_floor: int, target: Vector2, target_floor: int, except_actor: Node) -> Array[Dictionary]:
	var blocked: Array[Dictionary] = []
	for actor in crowd:
		if not is_instance_valid(actor) or actor == except_actor or actor.stair_elapsed >= 0.0: continue
		var floor_level: int = actor.navigation_floor
		var cell: Vector2i = cafe.world.screen_to_floor_grid(actor.position,floor_level)
		if walkable(cell,floor_level):
			grids[floor_level].set_point_solid(cell,true)
			blocked.append({"cell":cell,"floor":floor_level})
	var route_start: Vector2 = start
	var cell: Vector2i = cafe.world.screen_to_floor_grid(start,start_floor)
	if not walkable(cell,start_floor):
		var grid: AStarGrid2D = grids[start_floor]
		var nearest_distance: float = INF
		for x in range(grid.region.position.x,grid.region.end.x):
			for y in range(grid.region.position.y,grid.region.end.y):
				var candidate := Vector2i(x,y)
				if absi(candidate.x-cell.x)+absi(candidate.y-cell.y) > 1: continue
				var point: Vector2 = cafe.cell_to_screen(candidate,start_floor)
				if not walkable(candidate,start_floor) or segment_occupied(start,point,start_floor,except_actor): continue
				if start.distance_squared_to(point) < nearest_distance:
					nearest_distance = start.distance_squared_to(point)
					route_start = point
	var result: Array[Dictionary] = route(route_start,start_floor,target,target_floor)
	for entry in blocked: grids[entry.floor].set_point_solid(entry.cell,false)
	return result

func rebuild(owner: Node, items: Array) -> void:
	cafe = owner
	grids.clear()
	for floor_level in [1, 2]:
		if floor_level == 2 and not cafe.second_floor_unlocked: continue
		var grid := AStarGrid2D.new()
		var width: int = 11 if floor_level == 1 else (6 if cafe.second_floor_level <= 1 else (8 if cafe.second_floor_level == 2 else 10))
		grid.region = Rect2i(-3, 0, 14, 11) if floor_level == 1 and bool(cafe.expansions.get("LeftWindow", false)) else Rect2i(0, 0, width, width)
		grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
		grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
		grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
		grid.update()
		grids[floor_level] = grid
		if grid.region.position.x < 0:
			for x in range(-3, 0):
				for y in 11:
					if y < 3 or y > 8: block(Vector2i(x,y), floor_level)
		var counter: Vector2i = Vector2i(2,1) if floor_level == 1 else Vector2i(1,1)
		for x in 3:
			for y in 2: block(counter + Vector2i(x,y), floor_level)
		if floor_level == 1:
			block(Vector2i(7,1), 1)
			block(Vector2i(8,1), 1)
			block(Vector2i(8,2), 1)
		for i in cafe.world.all_table_cells().size():
			if cafe.world.table_floor(i) == floor_level: block(cafe.world.all_table_cells()[i], floor_level)
		for item in items:
			if int(item.get("floor", 1)) != floor_level: continue
			var size: Vector2i = cafe.furniture_size(str(item.type), int(item.get("rotation", 0)))
			for x in size.x:
				for y in size.y: block(Vector2i(int(item.x)+x,int(item.y)+y), floor_level)
	revision += 1

func block(cell: Vector2i, floor_level: int) -> void:
	var grid: AStarGrid2D = grids[floor_level]
	if grid.is_in_boundsv(cell): grid.set_point_solid(cell)

func walkable(cell: Vector2i, floor_level: int) -> bool:
	if not grids.has(floor_level): return false
	var grid: AStarGrid2D = grids[floor_level]
	return grid.is_in_boundsv(cell) and not grid.is_point_solid(cell)

func stair(floor_level: int) -> Vector2i:
	return Vector2i(9,7) if floor_level == 1 else Vector2i(5,5)

func interaction(cell: Vector2i, floor_level: int) -> Vector2i:
	for offset in [Vector2i(0,1),Vector2i(1,0),Vector2i(0,-1),Vector2i(-1,0)]:
		if walkable(cell + offset, floor_level): return cell + offset
	return Vector2i(-999,-999)

func nearest_walkable(cell: Vector2i, floor_level: int) -> Vector2i:
	if walkable(cell, floor_level): return cell
	if not grids.has(floor_level): return Vector2i(-999,-999)
	var grid: AStarGrid2D = grids[floor_level]
	var best := Vector2i(-999,-999)
	var distance: float = INF
	for x in range(grid.region.position.x, grid.region.end.x):
		for y in range(grid.region.position.y, grid.region.end.y):
			var candidate := Vector2i(x,y)
			if walkable(candidate, floor_level) and Vector2(cell).distance_squared_to(Vector2(candidate)) < distance:
				distance = Vector2(cell).distance_squared_to(Vector2(candidate))
				best = candidate
	return best

func cell_path(start: Vector2i, end: Vector2i, floor_level: int) -> Array[Vector2i]:
	if not walkable(start,floor_level) or not walkable(end,floor_level): return []
	var grid: AStarGrid2D = grids[floor_level]
	return grid.get_id_path(start,end)

func route(start_position: Vector2, start_floor: int, target: Vector2, target_floor: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var start: Vector2i = nearest_walkable(cafe.world.screen_to_floor_grid(start_position,start_floor),start_floor)
	var end: Vector2i = cafe.world.screen_to_floor_grid(target,target_floor)
	if start_floor != target_floor:
		var first: Array[Vector2i] = cell_path(start,stair(start_floor),start_floor)
		var second: Array[Vector2i] = cell_path(stair(target_floor),end,target_floor)
		if first.is_empty() or second.is_empty(): return []
		for cell in first: result.append({"point":cafe.cell_to_screen(cell,start_floor),"floor":start_floor})
		result.append({"point":cafe.cell_to_screen(stair(target_floor),target_floor),"floor":target_floor,"stairs":true})
		for cell in second: result.append({"point":cafe.cell_to_screen(cell,target_floor),"floor":target_floor})
	else:
		for cell in cell_path(start,end,start_floor): result.append({"point":cafe.cell_to_screen(cell,start_floor),"floor":start_floor})
	return result

func layout_accessible() -> bool:
	for floor_level in grids:
		var entrance: Vector2i = Vector2i(10,10) if floor_level == 1 else stair(2)
		var required: Array[Vector2i] = [stair(floor_level),cafe.station_cell("Barista",floor_level),cafe.cashier_cell(floor_level)]
		for i in cafe.world.all_table_cells().size():
			if cafe.world.table_floor(i) == floor_level: required.append(interaction(cafe.world.all_table_cells()[i],floor_level))
		for cell in required:
			if cell_path(entrance,cell,floor_level).is_empty(): return false
	return true
