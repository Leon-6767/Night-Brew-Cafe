class_name Customer
extends CafeActor

var patience := 135.0
var table_index := -1
var phase := "queue"
var order := "Latte"
var high_spender := false
var customer_type: String = "普通顾客"
var floor_level: int = 1
var drink_timer := 0.0
var warning := false
var payment_recorded: bool = false

func setup(customer_name: String, high: bool, type_name: String = "普通顾客") -> void:
	display_name = customer_name
	role = "Customer"
	high_spender = high
	customer_type = type_name
	state_text = "排队中"

func tick_customer(delta: float, running: bool) -> void:
	if not running: return
	if phase != "drinking": patience -= delta
	if patience <= 18.0 and not warning:
		warning = true
		state_text = "等待不满"
	if phase == "drinking": drink_timer -= delta
