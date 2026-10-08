extends SceneTree

func _initialize() -> void: call_deferred("capture")

func capture() -> void:
	var scene: Node = load("res://scenes/Main.tscn").instantiate()
	root.add_child(scene)
	for frame in 20: await process_frame
	await RenderingServer.frame_post_draw
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if not args.is_empty(): root.get_texture().get_image().save_png(args[0])
	quit()
