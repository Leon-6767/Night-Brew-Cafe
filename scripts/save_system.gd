class_name SaveSystem
extends RefCounted

const SAVE_PATH := "user://night_brew_save.json"

static func save_game(data: Dictionary, path: String = SAVE_PATH) -> bool:
	var temporary: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if not file: return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var status: Error = file.get_error()
	file.close()
	if status != OK: return false
	if not read_dictionary(temporary).is_empty():
		if not read_dictionary(path).is_empty():
			if DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path + ".bak")) != OK: return false
		return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path)) == OK
	return false

static func load_game(path: String = SAVE_PATH) -> Dictionary:
	var current: Dictionary = read_dictionary(path)
	return current if not current.is_empty() else read_dictionary(path + ".bak")

static func read_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK: return {}
	return parser.data if parser.data is Dictionary else {}

static func reset_game() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(SAVE_PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH + suffix))
