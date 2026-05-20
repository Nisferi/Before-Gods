class_name UnitData
extends Resource

@export var unit_id: String = ""
@export var unit_name: String = "Unknown"
@export var level: int = 1
@export var atk: int = 5
@export var hp: int = 100
@export var hp_max: int = 100
@export var morale: int = 80
@export var is_alive: bool = true
@export var injuries: Array[String] = []
@export var equipment: Array[String] = []

func apply_damage(amount: int) -> void:
	hp = max(0, hp - amount)

func heal(amount: int) -> void:
	hp = min(hp_max, hp + amount)

func is_dead() -> bool:
	return not is_alive or hp <= 0

func mark_dead() -> void:
	is_alive = false
	hp = 0
