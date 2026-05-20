class_name NodeData
extends Resource

enum NodeType { CITY, RUINS, OASIS, TEMPLE, CAMP }

@export var node_id: String = ""
@export var display_name: String = ""
@export var node_type: NodeType = NodeType.RUINS
@export var combat_difficulty: float = 1.0   # 0.8 (easy) .. 1.5 (dangerous)
@export var connections: Array[String] = []   # node_id list of adjacent nodes
@export var events: Array[String] = []        # possible event IDs
@export var is_visited: bool = false
@export var lore_text: String = ""
