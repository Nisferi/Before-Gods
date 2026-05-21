extends Node

# === MAP MODULE ===
signal squad_moved(from_node: String, to_node: String)
signal node_entered(node_id: String)
signal node_event_triggered(event_data: Dictionary)

# === BATTLE MODULE ===
signal battle_started(enemy_data: Dictionary)
signal battle_ended(result: String)  # "win" | "narrow_win" | "draw" | "retreat" | "defeat"
signal battle_preview_requested(node_id: String)
signal unit_died(unit_id: String)
signal unit_injured(unit_id: String, injury_type: String)
signal hero_died()

# === BASE MODULE ===
signal resource_changed(resource_type: String, delta: int)
signal building_upgraded(building_id: String)
signal squad_healed(unit_id: String, amount: int)

# === SQUAD ===
signal squad_updated()
signal morale_changed(new_value: int)

# === EVENTS & FACTIONS ===
signal event_flag_set(flag_key: String, flag_value: Variant)
signal faction_rep_changed(faction_id: String, delta: int)
signal event_choice_made(event_id: String, choice_index: int)

# === HERO MEMORY ===
signal hero_memory_lost(lost_keys: Array[String])
signal hero_respawned(penalties: Dictionary)

# === SYSTEM ===
signal game_saved()
signal game_loaded()
signal scene_transition_requested(scene_path: String)
signal new_run_started(map_seed: int)
