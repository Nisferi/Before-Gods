class_name TestMapFactory

# Test map layout (7 nodes):
#
#   TEMPLE ─── RUINS_N ─── OASIS_E
#                  │
#   CITY_W ──── CAMP ──── OASIS_S
#      │
#   RUINS_W

static func create() -> Array[NodeData]:
	var list: Array[NodeData] = []

	var camp := NodeData.new()
	camp.node_id = "camp"
	camp.display_name = "Лагерь"
	camp.node_type = NodeData.NodeType.CAMP
	camp.combat_difficulty = 0.0
	camp.connections.assign(["ruins_north", "city_west", "oasis_south"])
	camp.is_visited = true
	list.append(camp)

	var ruins_n := NodeData.new()
	ruins_n.node_id = "ruins_north"
	ruins_n.display_name = "Северные Руины"
	ruins_n.node_type = NodeData.NodeType.RUINS
	ruins_n.combat_difficulty = 1.0
	ruins_n.connections.assign(["camp", "temple", "oasis_east"])
	ruins_n.events.assign(["ev_stone_tablet", "ev_old_bones"])
	list.append(ruins_n)

	var temple := NodeData.new()
	temple.node_id = "temple"
	temple.display_name = "Храм Молчания"
	temple.node_type = NodeData.NodeType.TEMPLE
	temple.combat_difficulty = 1.3
	temple.connections.assign(["ruins_north"])
	temple.events.assign(["ev_temple_vision", "ev_ritual_site"])
	temple.lore_text = "Камень помнит имена тех, кто молился до появления слов."
	list.append(temple)

	var oasis_e := NodeData.new()
	oasis_e.node_id = "oasis_east"
	oasis_e.display_name = "Восточный Оазис"
	oasis_e.node_type = NodeData.NodeType.OASIS
	oasis_e.combat_difficulty = 0.8
	oasis_e.connections.assign(["ruins_north"])
	oasis_e.events.assign(["ev_fresh_water", "ev_nomads"])
	list.append(oasis_e)

	var city_w := NodeData.new()
	city_w.node_id = "city_west"
	city_w.display_name = "Западный Город"
	city_w.node_type = NodeData.NodeType.CITY
	city_w.combat_difficulty = 0.8
	city_w.connections.assign(["camp", "ruins_west"])
	city_w.events.assign(["ev_merchant", "ev_recruit"])
	list.append(city_w)

	var ruins_w := NodeData.new()
	ruins_w.node_id = "ruins_west"
	ruins_w.display_name = "Западные Руины"
	ruins_w.node_type = NodeData.NodeType.RUINS
	ruins_w.combat_difficulty = 1.2
	ruins_w.connections.assign(["city_west"])
	ruins_w.events.assign(["ev_ambush", "ev_old_camp"])
	list.append(ruins_w)

	var oasis_s := NodeData.new()
	oasis_s.node_id = "oasis_south"
	oasis_s.display_name = "Южный Оазис"
	oasis_s.node_type = NodeData.NodeType.OASIS
	oasis_s.combat_difficulty = 0.7
	oasis_s.connections.assign(["camp"])
	oasis_s.events.assign(["ev_fresh_water"])
	list.append(oasis_s)

	return list
