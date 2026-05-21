extends Node

func _ready() -> void:
	if SaveSystem.has_save():
		SaveSystem.load_save()
	_init_test_squad()
	get_tree().change_scene_to_file.call_deferred("res://scenes/world/map_scene.tscn")

func _init_test_squad() -> void:
	if not GameManager.squad.is_empty():
		return
	var data := [
		["hero_0",  "Аарон",   3, 12, 120],
		["unit_1",  "Дерек",   2,  9,  90],
		["unit_2",  "Мириам",  1,  7,  80],
		["unit_3",  "Руфь",    2,  8,  95],
	]
	for d in data:
		var u := UnitData.new()
		u.unit_id  = d[0]
		u.unit_name = d[1]
		u.level    = d[2]
		u.atk      = d[3]
		u.hp_max   = d[4]
		u.hp       = d[4]
		GameManager.squad.append(u)
