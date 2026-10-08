class_name CafeActor
extends Node2D

const CharacterVisualScene = preload("res://scenes/actors/CharacterVisual.tscn")

var display_name: String = ""
var role: String = ""
var state_text: String = ""
var target_position: Vector2 = Vector2.ZERO
var move_speed: float = 120.0
var is_moving: bool = false
var visual: Node2D
var navigation_floor: int = 1
var route_failed: bool = false
var route: Array[Dictionary] = []
var route_target: Vector2 = Vector2(INF, INF)
var route_floor: int = -1
var route_revision: int = -1
var traffic_wait: float = 0.0
var yield_timer: float = 0.0
var traffic_detour: Array[Dictionary] = []
var parked_for_stairs: bool = false
var last_direction: Vector2 = Vector2.RIGHT
var stair_elapsed: float = -1.0
var stair_start: Vector2 = Vector2.ZERO
var stair_end: Vector2 = Vector2.ZERO
var stair_floor: int = 1
const STAIR_DURATION: float = 1.2

func advance_stairs(delta: float) -> bool:
	if stair_elapsed < 0.0: return false
	if delta <= 0.0: return true
	stair_elapsed = minf(STAIR_DURATION,stair_elapsed+delta)
	position = stair_start.lerp(stair_end,stair_elapsed/STAIR_DURATION)
	last_direction = stair_end-stair_start
	is_moving = true
	if stair_elapsed >= STAIR_DURATION:
		position = stair_end
		navigation_floor = stair_floor
		stair_elapsed = -1.0
		route.clear()
		route_revision = -1
	return true

func follow_route(navigation: CafeNavigation, target_floor: int, delta: float, actors: Array = []) -> void:
	if advance_stairs(delta):
		if stair_elapsed < 0.0: navigation.release_stairs(self)
		return
	if not traffic_detour.is_empty():
		var waypoint: Dictionary = traffic_detour[0]
		is_moving = false
		if navigation.segment_occupied(position,waypoint.point,navigation_floor,self): return
		position = position.move_toward(waypoint.point,move_speed*delta)
		is_moving = delta > 0.0
		if position.distance_to(waypoint.point) < 0.01:
			traffic_detour.pop_front()
			route_revision = -1
		return
	if parked_for_stairs:
		if not navigation.acquire_stairs(self,target_floor):
			is_moving = false
			return
		parked_for_stairs = false
	yield_timer = maxf(0.0,yield_timer-delta)
	traffic_wait = maxf(0.0,traffic_wait-delta)
	if route_target != target_position or route_floor != target_floor or route_revision != navigation.revision:
		route = navigation.route(position,navigation_floor,target_position,target_floor)
		route_target = target_position
		route_floor = target_floor
		route_revision = navigation.revision
		route_failed = route.is_empty()
		if route_failed: state_text = "道路不通"
	var budget: float = move_speed * delta
	var start_position: Vector2 = position
	is_moving = false
	while not route.is_empty() and budget > 0.0:
		var waypoint: Dictionary = route[0]
		if position.distance_to(waypoint.point) < 0.01 and int(waypoint.floor) == navigation_floor:
			route.pop_front()
			continue
		if bool(waypoint.get("stairs",false)):
			if not actors.is_empty():
				if not navigation.acquire_stairs(self,int(waypoint.floor)): break
			stair_start = position
			stair_end = waypoint.point
			stair_floor = int(waypoint.floor)
			stair_elapsed = 0.0
			is_moving = true
			return
		if not actors.is_empty() and navigation.segment_occupied(position,waypoint.point,int(waypoint.floor),self):
			if traffic_wait <= 0.0:
				navigation.request_yield(waypoint.point,int(waypoint.floor),self)
				var detour: Array[Dictionary] = navigation.crowd_route(position,navigation_floor,target_position,target_floor,self)
				if not detour.is_empty(): route = detour
				traffic_wait = 0.5
			break
		var distance: float = position.distance_to(waypoint.point)
		if distance <= budget:
			position = waypoint.point
			budget -= distance
			route.pop_front()
		else:
			position = position.move_toward(waypoint.point,budget)
			budget = 0.0
		is_moving = true
	if position != start_position: last_direction = position-start_position


func _ready() -> void:
	visual = CharacterVisualScene.instantiate()
	add_child(visual)
	visual.call("configure", role, display_name, Color.WHITE)

func refresh_visual(task_name: String = "") -> void:
	if not visual: return
	visual.call("set_status", state_text, is_moving)
	visual.call("set_direction",last_direction)
	visual.call("play_task", task_name)


func move_toward_target(delta: float) -> void:
	var remaining: float = position.distance_to(target_position)
	if remaining <= 1.0:
		position = target_position
		is_moving = false
		return
	position = position.move_toward(target_position, move_speed * delta)
	is_moving = true
	refresh_visual()
