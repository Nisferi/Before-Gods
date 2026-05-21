extends Node

enum GameState { MENU, MAP, BATTLE, BASE }

var current_state: GameState = GameState.MENU
var squad: Array[UnitData] = []
var squad_morale: int = 80
var resources: Dictionary = {
	"food": 10,
	"metal": 5,
	"relics": 0,
}

func _ready() -> void:
	EventBus.scene_transition_requested.connect(_on_scene_transition_requested)
	EventBus.unit_died.connect(_on_unit_died)
	EventBus.hero_died.connect(_on_hero_died)
	EventBus.battle_ended.connect(_on_battle_ended)

func set_state(new_state: GameState) -> void:
	current_state = new_state

func add_resource(type: String, amount: int) -> void:
	if type in resources:
		resources[type] += amount
		EventBus.resource_changed.emit(type, amount)

func get_resource(type: String) -> int:
	return resources.get(type, 0)

func get_living_squad() -> Array[UnitData]:
	return squad.filter(func(u: UnitData) -> bool: return u.is_alive)

func apply_morale_change(delta: int) -> void:
	squad_morale = clamp(squad_morale + delta, 0, 100)
	EventBus.morale_changed.emit(squad_morale)

func _on_unit_died(unit_id: String) -> void:
	for unit: UnitData in squad:
		if unit.unit_id == unit_id:
			unit.mark_dead()
	apply_morale_change(-10)
	EventBus.squad_updated.emit()

func _on_hero_died() -> void:
	SaveSystem.on_hero_death()

func _on_battle_ended(result: String) -> void:
	var morale_deltas: Dictionary = {
		"win": 10, "narrow_win": 3, "draw": 0, "retreat": -10, "defeat": -20
	}
	apply_morale_change(morale_deltas.get(result, 0))

func _on_scene_transition_requested(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
