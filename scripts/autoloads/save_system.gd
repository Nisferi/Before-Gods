extends Node

const SAVE_PATH: String = "user://save.dat"

# Survives hero death
var persistent_data: Dictionary = {
	"hero_name": "Unknown",
	"total_deaths": 0,
	"discovered_regions": [],
	"base_buildings": {},
	"unlocked_lore": [],
	"faction_rep": {"nomads": 0, "city_builders": 0, "spirit_walkers": 0},
	"death_milestones": [],
	"hall_of_fallen": [],
}

# Lost on hero death
var run_data: Dictionary = {
	"hero_level": 1,
	"current_xp": 0,
	"learned_skills": [],
	"quest_memory": {},
	"carried_resources": {},
	"map_seed": 0,
	"event_flags": {},
	"squad_snapshot": [],
}

func save() -> void:
	_snapshot_squad()
	var data: Dictionary = {"persistent": persistent_data, "run": run_data}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		EventBus.game_saved.emit()

func load_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return false
	file.close()
	var data: Dictionary = json.get_data()
	persistent_data = data.get("persistent", persistent_data)
	run_data = data.get("run", run_data)
	EventBus.game_loaded.emit()
	return true

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	DirAccess.remove_absolute(SAVE_PATH)

func _snapshot_squad() -> void:
	var snapshot: Array = []
	for unit: UnitData in GameManager.squad:
		snapshot.append({
			"unit_id": unit.unit_id, "unit_name": unit.unit_name,
			"level": unit.level, "atk": unit.atk,
			"hp": unit.hp, "hp_max": unit.hp_max,
			"is_alive": unit.is_alive, "injuries": unit.injuries,
			"portrait_seed": unit.portrait_seed,
			"battle_count": unit.battle_count, "is_veteran": unit.is_veteran,
		})
	run_data["squad_snapshot"] = snapshot

# Called when hero dies — resets run_data, preserves persistent_data
func on_hero_death() -> void:
	persistent_data["total_deaths"] += 1
	var lost_keys: Array[String] = _calculate_memory_loss()
	run_data = {
		"hero_level": 1,
		"current_xp": 0,
		"learned_skills": [],
		"quest_memory": {},
		"carried_resources": {},
	}
	EventBus.hero_memory_lost.emit(lost_keys)
	EventBus.hero_respawned.emit({"death_count": persistent_data["total_deaths"]})
	save()

# More deaths = more memory loss (10% per death, capped at 90%)
func _calculate_memory_loss() -> Array[String]:
	var lost: Array[String] = []
	var severity: float = clamp(persistent_data["total_deaths"] * 0.1, 0.1, 0.9)
	for key in run_data.keys():
		if randf() < severity:
			lost.append(key)
	return lost
