class_name Staff
extends CafeActor

var quality := "R"
var make_skill := 1
var service_skill := 1
var clean_skill := 1
var stamina: float = 100.0
var loyalty := 70
var assigned := true
var floor_level: int = 1
var task: Dictionary = {}
var resting := false

func setup(data: Dictionary) -> void:
	display_name = data.name
	role = data.role
	quality = data.quality
	make_skill = data.make
	service_skill = data.service
	clean_skill = data.clean
	stamina = data.stamina
	loyalty = data.loyalty
	modulate = Color("#b8a6df") if quality in ["SSR", "SSS"] else Color("#85bb9d")
	state_text = "待命"

func tick_staff(delta: float) -> void:
	if not assigned: return
	if not task.is_empty() and str(task.get("stage", "move")).begins_with("work"):
		task.remaining = float(task.remaining) - delta
		stamina = max(0.0, stamina - delta * 1.15)
	if resting: stamina = minf(100.0, stamina + delta * 18.0)
	move_speed = 80.0 if stamina < 30.0 else 145.0 + service_skill * 12.0
	refresh_visual(str(task.get("kind", "")))
