class_name CafeWorld
extends Node2D

const FurnitureVisualScene = preload("res://scenes/furniture/FurnitureVisual.tscn")

const TILE_W: float = 128.0
const TILE_H: float = 64.0
const GRID_SIZE: Vector2i = Vector2i(11, 11)
const ORIGIN: Vector2 = Vector2(540, 240)
const SECOND_FLOOR_OFFSET: Vector2 = Vector2(-360, -390)

var night_mode: bool = false
var decoration_mode: bool = false
var decorations: Array[Vector2] = []
var table_states: Array[String] = ["Free", "Free", "Free", "Free", "Free"]
var table_nodes: Array = []
var furniture_items: Array[Dictionary] = []
var expansions: Dictionary = {"LeftWindow": false}
var preview_type: String = ""
var preview_cell: Vector2i = Vector2i.ZERO
var preview_valid: bool = false
var preview_rotation: int = 0
var preview_floor: int = 1
var second_floor_unlocked: bool = false
var second_floor_level: int = 0

class IsoTable extends Node2D:
	var table_state: String = "Free"
	var visual: Node2D
	func _ready() -> void:
		visual = FurnitureVisualScene.instantiate()
		add_child(visual)
		visual.call("configure", "SingleTable", table_state)
	func refresh_visual() -> void:
		if visual: visual.call("configure", "SingleTable", table_state)

func grid_to_screen(cell: Vector2i) -> Vector2:
	return ORIGIN + Vector2((cell.x - cell.y) * 64.0, (cell.x + cell.y) * 32.0)

func floor_grid_to_screen(cell: Vector2i, floor_level: int = 1) -> Vector2:
	return grid_to_screen(cell) + (SECOND_FLOOR_OFFSET if floor_level == 2 else Vector2.ZERO)

func screen_to_grid(screen_position: Vector2) -> Vector2i:
	var dx: float = (screen_position.x - ORIGIN.x) / 64.0
	var dy: float = (screen_position.y - ORIGIN.y) / 32.0
	return Vector2i(roundi((dx + dy) * 0.5), roundi((dy - dx) * 0.5))

func screen_to_floor_grid(screen_position: Vector2, floor_level: int = 1) -> Vector2i:
	return screen_to_grid(screen_position - (SECOND_FLOOR_OFFSET if floor_level == 2 else Vector2.ZERO))

func set_furniture(items: Array[Dictionary], expansion_data: Dictionary, pending_type: String, pending_cell: Vector2i, is_valid: bool, rotation: int, floor_level: int = 1) -> void:
	furniture_items = items
	expansions = expansion_data
	preview_type = pending_type
	preview_cell = pending_cell
	preview_valid = is_valid
	preview_rotation = rotation
	preview_floor = floor_level
	queue_redraw()

func set_second_floor(unlocked: bool, level: int) -> void:
	second_floor_unlocked = unlocked
	second_floor_level = level
	ensure_table_nodes()
	queue_redraw()

func table_cells() -> Array[Vector2i]:
	return [Vector2i(3,4),Vector2i(6,4),Vector2i(3,7),Vector2i(6,7),Vector2i(5,9)]

func second_floor_table_cells() -> Array[Vector2i]:
	if not second_floor_unlocked: return []
	var cells: Array[Vector2i] = [Vector2i(3,4), Vector2i(6,4)]
	if second_floor_level >= 2: cells.append_array([Vector2i(3,7), Vector2i(6,7)])
	if second_floor_level >= 3: cells.append_array([Vector2i(5,9), Vector2i(8,6)])
	return cells

func all_table_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = table_cells()
	cells.append_array(second_floor_table_cells())
	return cells

func table_floor(index: int) -> int:
	return 1 if index < table_cells().size() else 2

func table_screen_position(index: int) -> Vector2:
	var cells: Array[Vector2i] = all_table_cells()
	return floor_grid_to_screen(cells[index], table_floor(index)) if index >= 0 and index < cells.size() else Vector2.ZERO

func table_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	for cell in table_cells(): positions.append(grid_to_screen(cell))
	return positions

func _ready() -> void:
	ensure_table_nodes()

func ensure_table_nodes() -> void:
	var cells: Array[Vector2i] = all_table_cells()
	while table_nodes.size() < cells.size():
		var table := IsoTable.new()
		add_child(table)
		table_nodes.append(table)
	for i in table_nodes.size():
		if i < cells.size():
			table_nodes[i].visible = true
			table_nodes[i].position = table_screen_position(i)
			table_nodes[i].z_index = int(table_nodes[i].position.y)
		else:
			table_nodes[i].visible = false

func _process(_delta: float) -> void:
	for i in mini(table_nodes.size(), table_states.size()):
		if table_nodes[i].table_state != table_states[i]:
			table_nodes[i].table_state = table_states[i]
			table_nodes[i].refresh_visual()

func _draw() -> void:
	# Warm wood diamond floor, no grid lines unless decoration mode is active.
	for x in GRID_SIZE.x:
		for y in GRID_SIZE.y:
			var center := grid_to_screen(Vector2i(x,y))
			var tile := PackedVector2Array([center+Vector2(0,-32),center+Vector2(64,0),center+Vector2(0,32),center+Vector2(-64,0)])
			draw_colored_polygon(tile, Color("#d7a66e") if (x+y)%2==0 else Color("#c89560"))
			if decoration_mode:
				var outlined_tile := PackedVector2Array([tile[0],tile[1],tile[2],tile[3],tile[0]])
				draw_polyline(outlined_tile,Color(1,1,1,.22),1.0)
	if bool(expansions.get("LeftWindow", false)):
		for x in range(-3, 0):
			for y in range(3, 9):
				var expansion_center: Vector2 = grid_to_screen(Vector2i(x, y))
				var expansion_tile: PackedVector2Array = PackedVector2Array([expansion_center+Vector2(0,-32),expansion_center+Vector2(64,0),expansion_center+Vector2(0,32),expansion_center+Vector2(-64,0)])
				draw_colored_polygon(expansion_tile, Color("#d9ad78"))
				if decoration_mode:
					draw_polyline(PackedVector2Array([expansion_tile[0], expansion_tile[1], expansion_tile[2], expansion_tile[3], expansion_tile[0]]), Color(1,1,1,.22), 1.0)
	if second_floor_unlocked:
		draw_second_floor()
	for item in furniture_items:
		draw_furniture(item, Color.WHITE)
	if preview_type != "":
		var preview_item: Dictionary = {"type": preview_type, "x": preview_cell.x, "y": preview_cell.y, "rotation": preview_rotation, "floor": preview_floor}
		draw_furniture(preview_item, Color(0.35, 0.95, 0.5, 0.55) if preview_valid else Color(1.0, 0.25, 0.25, 0.55))
	# Rooftop-removed interior walls: top rear wall and both side walls.
	var rear := PackedVector2Array([grid_to_screen(Vector2i(0,0))+Vector2(-64,0),grid_to_screen(Vector2i(10,0))+Vector2(64,0),grid_to_screen(Vector2i(10,0))+Vector2(64,-135),grid_to_screen(Vector2i(0,0))+Vector2(-64,-135)])
	draw_colored_polygon(rear, Color("#f2dcba"))
	var left_wall := PackedVector2Array([grid_to_screen(Vector2i(0,0))+Vector2(-64,0),grid_to_screen(Vector2i(0,10))+Vector2(-64,0),grid_to_screen(Vector2i(0,10))+Vector2(-64,-95),grid_to_screen(Vector2i(0,0))+Vector2(-64,-135)])
	draw_colored_polygon(left_wall, Color("#e7c99f"))
	# windows and hanging lamps in iso screen positions
	for cell in [Vector2i(2,0),Vector2i(7,0)]:
		var window := grid_to_screen(cell)+Vector2(0,-86)
		draw_colored_polygon(PackedVector2Array([window+Vector2(0,-22),window+Vector2(30,-7),window+Vector2(0,8),window+Vector2(-30,-7)]),Color("#82bad2") if not night_mode else Color("#253a72"))
	for cell in [Vector2i(3,2),Vector2i(7,3)]:
		var lamp := grid_to_screen(cell)+Vector2(0,-78)
		draw_line(lamp+Vector2(0,-40),lamp,Color("#55362c"),2)
		draw_circle(lamp,12,Color("#ffd37b"))
	# iso bar counter + clearly visible coffee machine, pastry case, staff rest corner
	draw_iso_block(Vector2i(2,1),Vector2i(3,2),Color("#704538"),30)
	var machine := grid_to_screen(Vector2i(3,2)) + Vector2(0,-24)
	draw_colored_polygon(PackedVector2Array([machine+Vector2(0,-20),machine+Vector2(24,-8),machine+Vector2(0,4),machine+Vector2(-24,-8)]),Color("#343941"))
	draw_iso_block(Vector2i(7,1),Vector2i(2,1),Color("#9a6951"),24)
	draw_iso_block(Vector2i(8,8),Vector2i(1,1),Color("#8a6358"),14)
	var plant := grid_to_screen(Vector2i(9,8))+Vector2(0,-25)
	draw_circle(plant,19,Color("#69a477")); draw_rect(Rect2(plant+Vector2(-8,13),Vector2(16,18)),Color("#b77b56"),true)
	# entrance at the front of the iso room
	var entrance := grid_to_screen(Vector2i(10,10))
	draw_colored_polygon(PackedVector2Array([entrance+Vector2(0,-22),entrance+Vector2(45,0),entrance+Vector2(0,22),entrance+Vector2(-45,0)]),Color("#55352d"))
	if night_mode:
		draw_circle(grid_to_screen(Vector2i(3,2)),150,Color(.25,.25,.72,.15))

func draw_second_floor() -> void:
	var width: int = 6 if second_floor_level <= 1 else (8 if second_floor_level == 2 else 10)
	var height: int = 6 if second_floor_level <= 1 else (8 if second_floor_level == 2 else 10)
	for x in width:
		for y in height:
			var center: Vector2 = floor_grid_to_screen(Vector2i(x, y), 2)
			var tile: PackedVector2Array = PackedVector2Array([center+Vector2(0,-32),center+Vector2(64,0),center+Vector2(0,32),center+Vector2(-64,0)])
			draw_colored_polygon(tile, Color("#c8915d") if (x+y)%2 == 0 else Color("#b77b50"))
			if decoration_mode:
				draw_polyline(PackedVector2Array([tile[0],tile[1],tile[2],tile[3],tile[0]]),Color(1,1,1,.22),1.0)
	draw_iso_block_floor(Vector2i(1,1), Vector2i(3,2), Color("#62433b"), 26, 2)
	var machine: Vector2 = floor_grid_to_screen(Vector2i(2,2), 2) + Vector2(0,-20)
	draw_circle(machine, 16, Color("#39414c"))
	var stair_bottom: Vector2 = grid_to_screen(Vector2i(9,7))
	var stair_top: Vector2 = floor_grid_to_screen(Vector2i(9,7),2)
	draw_line(stair_bottom, stair_top, Color("#8b5c45"), 18)

func draw_iso_block_floor(cell: Vector2i, size: Vector2i, color: Color, height: float, floor_level: int) -> void:
	var a: Vector2 = floor_grid_to_screen(cell, floor_level)
	var b: Vector2 = floor_grid_to_screen(cell + Vector2i(size.x,0), floor_level)
	var c: Vector2 = floor_grid_to_screen(cell + size, floor_level)
	var d: Vector2 = floor_grid_to_screen(cell + Vector2i(0,size.y), floor_level)
	draw_colored_polygon(PackedVector2Array([a+Vector2(0,-height),b+Vector2(0,-height),c+Vector2(0,-height),d+Vector2(0,-height)]),color.lightened(.12))
	draw_colored_polygon(PackedVector2Array([d+Vector2(0,-height),c+Vector2(0,-height),c,d]),color.darkened(.18))

func draw_iso_block(cell: Vector2i, size: Vector2i, color: Color, height: float) -> void:
	var a := grid_to_screen(cell)
	var b := grid_to_screen(cell + Vector2i(size.x,0))
	var c := grid_to_screen(cell + size)
	var d := grid_to_screen(cell + Vector2i(0,size.y))
	draw_colored_polygon(PackedVector2Array([a+Vector2(0,-height),b+Vector2(0,-height),c+Vector2(0,-height),d+Vector2(0,-height)]),color.lightened(.12))
	draw_colored_polygon(PackedVector2Array([d+Vector2(0,-height),c+Vector2(0,-height),c,d]),color.darkened(.18))

func draw_furniture(item: Dictionary, tint: Color) -> void:
	var item_type: String = str(item.get("type", ""))
	var cell: Vector2i = Vector2i(int(item.get("x", 0)), int(item.get("y", 0)))
	var floor_level: int = int(item.get("floor", 1))
	var center: Vector2 = floor_grid_to_screen(cell, floor_level)
	var color: Color = Color("#9b6249")
	if item_type == "CoffeeMachine": color = Color("#424955")
	elif item_type == "Register": color = Color("#725a4b")
	elif item_type == "Sofa": color = Color("#7a8f9c")
	elif item_type == "Plant": color = Color("#5b9a6a")
	elif item_type == "DoubleTable": color = Color("#b87b52")
	var size: Vector2 = Vector2(30, 17)
	if item_type == "DoubleTable":
		size = Vector2(55, 20) if int(item.get("rotation", 0)) % 2 == 0 else Vector2(30, 35)
	draw_set_transform(center, 0.0, size)
	draw_circle(Vector2.ZERO, 1.0, color * tint)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if item_type == "Plant":
		draw_circle(center + Vector2(0,-20), 14, Color("#6baa70") * tint)
