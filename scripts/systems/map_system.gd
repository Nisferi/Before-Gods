class_name MapSystem
extends RefCounted

var _nodes: Dictionary = {}       # node_id -> NodeData
var current_node_id: String = ""

func setup(node_list: Array[NodeData], start_node_id: String) -> void:
	_nodes.clear()
	for node_data: NodeData in node_list:
		_nodes[node_data.node_id] = node_data
	current_node_id = start_node_id
	if _nodes.has(start_node_id):
		(_nodes[start_node_id] as NodeData).is_visited = true

func get_node(node_id: String) -> NodeData:
	return _nodes.get(node_id, null)

func get_all_nodes() -> Dictionary:
	return _nodes

func get_neighbors(node_id: String) -> Array[String]:
	var node: NodeData = _nodes.get(node_id, null)
	if not node:
		return []
	return node.connections.duplicate()

func can_move_to(target_id: String) -> bool:
	return target_id in get_neighbors(current_node_id)

func move_squad_to(target_id: String) -> bool:
	if not can_move_to(target_id):
		return false
	var from: String = current_node_id
	current_node_id = target_id
	var target: NodeData = _nodes.get(target_id, null)
	if target:
		target.is_visited = true
	EventBus.squad_moved.emit(from, target_id)
	EventBus.node_entered.emit(target_id)
	_try_trigger_event(target_id)
	return true

# BFS: returns step-by-step path from from_id to to_id, empty if unreachable
func find_path(from_id: String, to_id: String) -> Array[String]:
	if from_id == to_id:
		return [from_id]
	var visited: Dictionary = {}
	var queue: Array = [[from_id]]
	while not queue.is_empty():
		var path: Array = queue.pop_front()
		var tip: String = path[-1]
		if tip == to_id:
			var result: Array[String] = []
			for step: String in path:
				result.append(step)
			return result
		if visited.has(tip):
			continue
		visited[tip] = true
		for neighbor: String in get_neighbors(tip):
			if not visited.has(neighbor):
				var next: Array = path.duplicate()
				next.append(neighbor)
				queue.append(next)
	return []

func _try_trigger_event(node_id: String) -> void:
	var node: NodeData = _nodes.get(node_id, null)
	if not node or node.events.is_empty():
		return
	var idx: int = randi() % node.events.size()
	EventBus.node_event_triggered.emit({"event_id": node.events[idx], "node_id": node_id})
