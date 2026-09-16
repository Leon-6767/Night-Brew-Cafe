class_name VisualCatalog
extends RefCounted

const STAFF_TEXTURES: Dictionary = {
	"Barista": "res://assets/characters/staff/staff_barista_placeholder.svg",
	"Waiter": "res://assets/characters/staff/staff_waiter_placeholder.svg",
	"Cleaner": "res://assets/characters/staff/staff_cleaner_placeholder.svg",
	"Manager": "res://assets/characters/staff/staff_barista_placeholder.svg"
}
const CUSTOMER_TEXTURE: String = "res://assets/characters/customers/customer_placeholder.svg"
const FURNITURE_TEXTURES: Dictionary = {
	"SingleTable": "res://assets/furniture/tables/table_small_placeholder.svg",
	"DoubleTable": "res://assets/furniture/tables/table_small_placeholder.svg",
	"CoffeeMachine": "res://assets/furniture/machines/coffee_machine_placeholder.svg",
	"Register": "res://assets/furniture/counters/counter_placeholder.svg",
	"Counter": "res://assets/furniture/counters/counter_placeholder.svg",
	"Plant": "res://assets/furniture/decor/plant_placeholder.svg"
}

static func actor_texture(role_id: String, _variant_id: String = "") -> Texture2D:
	var path: String = CUSTOMER_TEXTURE if role_id == "Customer" else str(STAFF_TEXTURES.get(role_id, STAFF_TEXTURES["Barista"]))
	return load(path) as Texture2D

static func furniture_texture(furniture_id: String) -> Texture2D:
	return load(str(FURNITURE_TEXTURES.get(furniture_id, FURNITURE_TEXTURES["Counter"]))) as Texture2D

static func state_icon_texture() -> Texture2D:
	return load("res://assets/ui/icons/icon_coffee.svg") as Texture2D
