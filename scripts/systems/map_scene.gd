extends Node2D

const NODE_POSITIONS: Dictionary = {
	"camp":        Vector2(640, 350),
	"ruins_north": Vector2(640, 185),
	"temple":      Vector2(905, 108),
	"oasis_east":  Vector2(995, 258),
	"city_west":   Vector2(295, 235),
	"ruins_west":  Vector2(148, 395),
	"oasis_south": Vector2(488, 498),
}

const VIGNETTE_SHADER := preload("res://shaders/vignette.gdshader")

var map_system: MapSystem
var _node_visuals: Dictionary = {}      # node_id -> MapNodeVisual
var _squad_draw_pos: Vector2 = Vector2.ZERO
var _selected_node_id: String = ""

var _info_panel: PanelContainer
var _info_title: Label
var _info_type: Label
var _info_status: Label
var _info_move_btn: Button
var _hud_node_lbl: Label
var _hud_morale_fill: ColorRect
var _hud_res_lbl: Label

# ── Setup ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	map_system = MapSystem.new()
	map_system.setup(TestMapFactory.create(), "camp")
	_squad_draw_pos = NODE_POSITIONS.get("camp", Vector2.ZERO)

	_build_background()
	_build_node_visuals()
	_build_info_panel()
	_build_hud()

	EventBus.squad_moved.connect(_on_squad_moved)
	EventBus.node_event_triggered.connect(_on_event_triggered)

	_refresh_visuals()
	_refresh_hud()

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.055, 0.045, 0.035)
	bg.size = Vector2(1280, 720)
	add_child(bg)
	move_child(bg, 0)

	var vignette_rect := ColorRect.new()
	vignette_rect.size = Vector2(1280, 720)
	vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = VIGNETTE_SHADER
	vignette_rect.material = mat
	add_child(vignette_rect)

func _build_node_visuals() -> void:
	for node_id: String in map_system.get_all_nodes():
		var nd: NodeData = map_system.get_node(node_id)
		var v := MapNodeVisual.new()
		v.node_id = node_id
		v.node_type = nd.node_type
		v.display_name = nd.display_name
		v.is_visited = nd.is_visited
		v.position = NODE_POSITIONS.get(node_id, Vector2.ZERO)
		add_child(v)
		_node_visuals[node_id] = v

func _build_info_panel() -> void:
	var canvas := CanvasLayer.new()

	_info_panel = PanelContainer.new()
	_info_panel.size = Vector2(230, 175)
	_info_panel.position = Vector2(20, 20)
	_info_panel.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.07, 0.06, 0.95)
	style.border_color = Color(0.55, 0.45, 0.30, 0.85)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	_info_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	_info_title = Label.new()
	_info_title.add_theme_font_size_override("font_size", 16)
	_info_title.add_theme_color_override("font_color", Color(0.98, 0.93, 0.80))
	_info_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_info_type = Label.new()
	_info_type.add_theme_font_size_override("font_size", 12)
	_info_type.add_theme_color_override("font_color", Color(0.70, 0.65, 0.55))

	_info_status = Label.new()
	_info_status.add_theme_font_size_override("font_size", 12)

	_info_move_btn = Button.new()
	_info_move_btn.text = "→  Идти сюда"
	_info_move_btn.pressed.connect(_on_info_move_pressed)

	var sep := HSeparator.new()

	var close_btn := Button.new()
	close_btn.text = "✕  Закрыть"
	close_btn.pressed.connect(_close_info_panel)

	vbox.add_child(_info_title)
	vbox.add_child(_info_type)
	vbox.add_child(_info_status)
	vbox.add_child(sep)
	vbox.add_child(_info_move_btn)
	vbox.add_child(close_btn)
	_info_panel.add_child(vbox)
	canvas.add_child(_info_panel)
	add_child(canvas)

func _build_hud() -> void:
	var canvas := CanvasLayer.new()
	var panel := Panel.new()
	panel.position = Vector2(0, 570)
	panel.size = Vector2(1280, 150)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.055, 0.045, 0.97)
	style.border_color = Color(0.50, 0.42, 0.30, 0.70)
	style.border_width_top = 1
	panel.add_theme_stylebox_override("panel", style)

	_hud_node_lbl = Label.new()
	_hud_node_lbl.position = Vector2(20, 8)
	_hud_node_lbl.size = Vector2(500, 36)
	_hud_node_lbl.add_theme_font_size_override("font_size", 24)
	_hud_node_lbl.add_theme_color_override("font_color", Color(0.97, 0.92, 0.78))

	var morale_lbl := Label.new()
	morale_lbl.position = Vector2(20, 52)
	morale_lbl.text = "МОРАЛЬ"
	morale_lbl.add_theme_font_size_override("font_size", 10)
	morale_lbl.add_theme_color_override("font_color", Color(0.60, 0.55, 0.48))

	var bar_bg := ColorRect.new()
	bar_bg.position = Vector2(20, 68)
	bar_bg.size = Vector2(220, 10)
	bar_bg.color = Color(0.12, 0.09, 0.07)

	_hud_morale_fill = ColorRect.new()
	_hud_morale_fill.position = Vector2(20, 68)
	_hud_morale_fill.size = Vector2(176, 10)
	_hud_morale_fill.color = Color(0.22, 0.62, 0.32)

	_hud_res_lbl = Label.new()
	_hud_res_lbl.position = Vector2(20, 88)
	_hud_res_lbl.size = Vector2(600, 28)
	_hud_res_lbl.add_theme_font_size_override("font_size", 13)
	_hud_res_lbl.add_theme_color_override("font_color", Color(0.80, 0.75, 0.65))

	panel.add_child(_hud_node_lbl)
	panel.add_child(morale_lbl)
	panel.add_child(bar_bg)
	panel.add_child(_hud_morale_fill)
	panel.add_child(_hud_res_lbl)
	canvas.add_child(panel)
	add_child(canvas)

# ── Drawing ───────────────────────────────────────────────────────────────────

func _draw() -> void:
	_draw_connections()
	_draw_squad_marker()

func _draw_connections() -> void:
	var visited: Dictionary = {}
	for node_id: String in map_system.get_all_nodes():
		if map_system.get_node(node_id).is_visited:
			visited[node_id] = true

	var drawn: Dictionary = {}
	for node_id: String in map_system.get_all_nodes():
		var nd: NodeData = map_system.get_node(node_id)
		var from: Vector2 = NODE_POSITIONS.get(node_id, Vector2.ZERO)
		for nb: String in nd.connections:
			var key: String = node_id + nb if node_id < nb else nb + node_id
			if drawn.has(key):
				continue
			drawn[key] = true
			var to: Vector2 = NODE_POSITIONS.get(nb, Vector2.ZERO)
			if visited.has(node_id) or visited.has(nb):
				# Layered solid road
				draw_line(from, to, Color(0.18, 0.14, 0.10, 0.92), 6.0, true)
				draw_line(from, to, Color(0.62, 0.52, 0.38, 0.78), 4.0, true)
				draw_line(from, to, Color(0.88, 0.80, 0.62, 0.12), 1.5, true)
			else:
				_draw_dashed(from, to, Color(0.38, 0.33, 0.27, 0.28), 2.0)

func _draw_dashed(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var dash: float = 10.0
	var gap: float = 8.0
	var dir: Vector2 = (to - from).normalized()
	var dist: float = from.distance_to(to)
	var t: float = 0.0
	while t < dist:
		draw_line(from + dir * t, from + dir * minf(t + dash, dist),
			color, width, true)
		t += dash + gap

func _draw_squad_marker() -> void:
	var pos: Vector2 = _squad_draw_pos - Vector2(0, 52)
	var d: float = 13.0
	var pts := PackedVector2Array([
		pos + Vector2(0, -d), pos + Vector2(d, 0),
		pos + Vector2(0, d),  pos + Vector2(-d, 0),
	])
	draw_colored_polygon(pts, Color(1.0, 0.88, 0.18, 0.95))
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]),
		Color(1, 1, 1, 0.80), 1.8, true)
	draw_circle(pos, 3.5, Color(0.55, 0.35, 0.0, 0.90))

# ── State refresh ─────────────────────────────────────────────────────────────

func _refresh_visuals() -> void:
	var current: String = map_system.current_node_id
	var reachable: Array[String] = map_system.get_neighbors(current)
	for node_id: String in _node_visuals:
		var v: MapNodeVisual = _node_visuals[node_id]
		v.is_current   = (node_id == current)
		v.is_reachable = (node_id in reachable)
		v.is_visited   = map_system.get_node(node_id).is_visited
		v.queue_redraw()
	queue_redraw()

func _refresh_hud() -> void:
	var nd: NodeData = map_system.get_node(map_system.current_node_id)
	if _hud_node_lbl and nd:
		_hud_node_lbl.text = nd.display_name

	var morale: int = GameManager.squad_morale
	if _hud_morale_fill:
		_hud_morale_fill.size.x = 220.0 * clampf(morale / 100.0, 0, 1)
		_hud_morale_fill.color = \
			Color(0.22, 0.62, 0.32) if morale > 60 else \
			Color(0.72, 0.52, 0.10) if morale > 30 else \
			Color(0.72, 0.18, 0.14)

	if _hud_res_lbl:
		var r := GameManager.resources
		_hud_res_lbl.text = "Еда: %d    Металл: %d    Реликвии: %d" % [
			r.get("food", 0), r.get("metal", 0), r.get("relics", 0)
		]

# ── Input ─────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if not (mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT):
		return
	var click: Vector2 = mb.position
	for node_id: String in _node_visuals:
		var v: MapNodeVisual = _node_visuals[node_id]
		if click.distance_to(v.position) <= float(v.get_radius()) + 14.0:
			_select_node(node_id)
			return
	_close_info_panel()

func _select_node(node_id: String) -> void:
	_selected_node_id = node_id
	var nd: NodeData = map_system.get_node(node_id)
	if not nd:
		return
	_info_title.text = nd.display_name
	_info_type.text = _type_label(nd.node_type) + \
		("   ⚔ x%.1f" % nd.combat_difficulty if nd.combat_difficulty > 0 else "")
	_info_status.text = "✓  Посещён" if nd.is_visited else "?  Неизвестно"
	_info_status.add_theme_color_override("font_color",
		Color(0.35, 0.82, 0.42) if nd.is_visited else Color(0.70, 0.60, 0.38))
	_info_move_btn.visible = map_system.can_move_to(node_id)
	_info_panel.visible = true

func _close_info_panel() -> void:
	_info_panel.visible = false
	_selected_node_id = ""

# ── Signals ───────────────────────────────────────────────────────────────────

func _on_info_move_pressed() -> void:
	if _selected_node_id.is_empty():
		return
	_close_info_panel()
	map_system.move_squad_to(_selected_node_id)

func _on_squad_moved(_from: String, to: String) -> void:
	var target: Vector2 = NODE_POSITIONS.get(to, Vector2.ZERO)
	var tw := create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_method(_set_squad_pos, _squad_draw_pos, target, 0.55)
	tw.tween_callback(_refresh_visuals)
	tw.tween_callback(_refresh_hud)

func _set_squad_pos(p: Vector2) -> void:
	_squad_draw_pos = p
	queue_redraw()

func _on_event_triggered(event_data: Dictionary) -> void:
	print("Event: ", event_data.get("event_id", ""))

# ── Helpers ───────────────────────────────────────────────────────────────────

func _type_label(t: NodeData.NodeType) -> String:
	match t:
		NodeData.NodeType.TEMPLE: return "Храм"
		NodeData.NodeType.CITY:   return "Город"
		NodeData.NodeType.CAMP:   return "Лагерь"
		NodeData.NodeType.OASIS:  return "Оазис"
		_: return "Руины"
