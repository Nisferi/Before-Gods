extends Node2D

# Node screen positions (1280x720 landscape, map area: y 0-570, HUD: y 570-720)
const NODE_POSITIONS: Dictionary = {
	"camp":        Vector2(640, 350),
	"ruins_north": Vector2(640, 190),
	"temple":      Vector2(900, 110),
	"oasis_east":  Vector2(990, 265),
	"city_west":   Vector2(300, 240),
	"ruins_west":  Vector2(155, 400),
	"oasis_south": Vector2(490, 500),
}

const LINE_COLOR:        Color = Color(0.45, 0.4, 0.35, 0.75)
const BG_COLOR:          Color = Color(0.07, 0.06, 0.05)
const COLOR_CAMP:        Color = Color(0.35, 0.75, 0.35)
const COLOR_CITY:        Color = Color(0.80, 0.70, 0.30)
const COLOR_RUINS:       Color = Color(0.55, 0.48, 0.40)
const COLOR_OASIS:       Color = Color(0.25, 0.68, 0.78)
const COLOR_TEMPLE:      Color = Color(0.65, 0.28, 0.68)

var map_system: MapSystem
var node_buttons: Dictionary = {}   # node_id -> Button
var squad_label: Label
var event_panel: PanelContainer
var event_label: Label
var hud_node_label: Label
var hud_morale_label: Label

func _ready() -> void:
	map_system = MapSystem.new()
	map_system.setup(TestMapFactory.create(), "camp")

	_build_background()
	_build_connections()
	_build_nodes()
	_build_squad_marker()
	_build_hud()
	_build_event_panel()

	EventBus.squad_moved.connect(_on_squad_moved)
	EventBus.node_event_triggered.connect(_on_event_triggered)

	_refresh_buttons()
	_refresh_hud()

# ── Visuals ──────────────────────────────────────────────────────────────────

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = BG_COLOR
	bg.size = Vector2(1280, 720)
	add_child(bg)
	move_child(bg, 0)

func _build_connections() -> void:
	for node_id: String in map_system.get_all_nodes():
		var node: NodeData = map_system.get_node(node_id)
		var from: Vector2 = NODE_POSITIONS.get(node_id, Vector2.ZERO)
		for neighbor_id: String in node.connections:
			if neighbor_id > node_id:   # draw each connection once
				var to: Vector2 = NODE_POSITIONS.get(neighbor_id, Vector2.ZERO)
				var line := Line2D.new()
				line.add_point(from)
				line.add_point(to)
				line.width = 3.0
				line.default_color = LINE_COLOR
				add_child(line)

func _build_nodes() -> void:
	for node_id: String in map_system.get_all_nodes():
		var node: NodeData = map_system.get_node(node_id)
		var pos: Vector2 = NODE_POSITIONS.get(node_id, Vector2.ZERO)
		var btn := Button.new()
		btn.text = node.display_name
		btn.custom_minimum_size = Vector2(128, 56)
		btn.position = pos - btn.custom_minimum_size / 2.0
		btn.modulate = _node_color(node.node_type)
		btn.pressed.connect(_on_node_pressed.bind(node_id))
		add_child(btn)
		node_buttons[node_id] = btn

func _build_squad_marker() -> void:
	squad_label = Label.new()
	squad_label.text = "▲ Отряд"
	squad_label.add_theme_color_override("font_color", Color.YELLOW)
	add_child(squad_label)
	_place_squad_marker(map_system.current_node_id)

func _build_hud() -> void:
	var hud := CanvasLayer.new()
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.size = Vector2(1280, 150)
	panel.position = Vector2(0, 570)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)

	hud_node_label = Label.new()
	hud_node_label.text = "Узел: Лагерь"
	hud_node_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	hud_morale_label = Label.new()
	hud_morale_label.text = "Мораль: 80"
	hud_morale_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	hbox.add_child(hud_node_label)
	hbox.add_child(hud_morale_label)
	panel.add_child(hbox)
	hud.add_child(panel)
	add_child(hud)

func _build_event_panel() -> void:
	var canvas := CanvasLayer.new()
	event_panel = PanelContainer.new()
	event_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	event_panel.size = Vector2(600, 80)
	event_panel.position = Vector2(340, 20)
	event_panel.visible = false

	event_label = Label.new()
	event_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_panel.add_child(event_label)
	canvas.add_child(event_panel)
	add_child(canvas)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _node_color(type: NodeData.NodeType) -> Color:
	match type:
		NodeData.NodeType.CAMP:   return COLOR_CAMP
		NodeData.NodeType.CITY:   return COLOR_CITY
		NodeData.NodeType.RUINS:  return COLOR_RUINS
		NodeData.NodeType.OASIS:  return COLOR_OASIS
		NodeData.NodeType.TEMPLE: return COLOR_TEMPLE
		_: return Color.WHITE

func _place_squad_marker(node_id: String) -> void:
	var pos: Vector2 = NODE_POSITIONS.get(node_id, Vector2.ZERO)
	squad_label.position = pos + Vector2(-28, -62)

func _refresh_buttons() -> void:
	var current: String = map_system.current_node_id
	var reachable: Array[String] = map_system.get_neighbors(current)
	for node_id: String in node_buttons:
		var btn: Button = node_buttons[node_id]
		btn.disabled = (node_id == current) or (node_id not in reachable)

func _refresh_hud() -> void:
	var node: NodeData = map_system.get_node(map_system.current_node_id)
	if node:
		hud_node_label.text = "Узел: " + node.display_name
	hud_morale_label.text = "Мораль: " + str(GameManager.squad_morale)

# ── Signals ───────────────────────────────────────────────────────────────────

func _on_node_pressed(node_id: String) -> void:
	map_system.move_squad_to(node_id)

func _on_squad_moved(_from: String, to: String) -> void:
	_place_squad_marker(to)
	_refresh_buttons()
	_refresh_hud()

func _on_event_triggered(event_data: Dictionary) -> void:
	var event_id: String = event_data.get("event_id", "")
	event_label.text = "Ивент: " + event_id
	event_panel.visible = true
	# Hide after 3 seconds
	await get_tree().create_timer(3.0).timeout
	event_panel.visible = false
