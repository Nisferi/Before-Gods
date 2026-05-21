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
var _node_visuals: Dictionary = {}
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
var _unit_cards: Array = []
var _hud_panel: Panel   # kept for card rebuild

var _noise: FastNoiseLite

# ── Setup ─────────────────────────────────────────────────────────────────────

func _ready() -> void:
	map_system = MapSystem.new()
	map_system.setup(TestMapFactory.create(), "camp")
	_squad_draw_pos = NODE_POSITIONS.get("camp", Vector2.ZERO)

	_init_noise()
	_build_background()
	_build_terrain_overlay()
	_build_node_visuals()
	_build_info_panel()
	_build_hud()

	EventBus.squad_moved.connect(_on_squad_moved)
	EventBus.node_event_triggered.connect(_on_event_triggered)
	EventBus.squad_updated.connect(_on_squad_updated)
	EventBus.morale_changed.connect(_on_morale_changed)

	_refresh_visuals()
	_refresh_hud()

func _init_noise() -> void:
	_noise = FastNoiseLite.new()
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_noise.seed = 42
	_noise.frequency = 0.004

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.62, 0.52, 0.36)
	bg.size = Vector2(1280, 720)
	add_child(bg)
	move_child(bg, 0)

func _build_terrain_overlay() -> void:
	var img := Image.create(1280, 720, false, Image.FORMAT_RGBA8)
	for y in range(720):
		for x in range(1280):
			var n: float = _noise.get_noise_2d(float(x), float(y))
			var color: Color
			if n < -0.30:
				color = Color(0.42, 0.34, 0.22, 0.55)
			elif n < -0.05:
				color = Color(0.55, 0.46, 0.30, 0.30)
			elif n < 0.15:
				color = Color(0.65, 0.56, 0.38, 0.08)
			elif n < 0.35:
				color = Color(0.80, 0.70, 0.48, 0.28)
			else:
				color = Color(0.90, 0.82, 0.60, 0.40)
			img.set_pixel(x, y, color)
	var tex := ImageTexture.create_from_image(img)
	var terrain_rect := TextureRect.new()
	terrain_rect.texture = tex
	terrain_rect.size = Vector2(1280, 720)
	terrain_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(terrain_rect)

	var edge := ColorRect.new()
	edge.size = Vector2(1280, 720)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var edge_mat := ShaderMaterial.new()
	edge_mat.shader = VIGNETTE_SHADER
	edge.material = edge_mat
	add_child(edge)

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
	style.bg_color = Color(0.18, 0.14, 0.10, 0.97)
	style.border_color = Color(0.62, 0.50, 0.28, 0.90)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	_info_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)

	_info_title = Label.new()
	_info_title.add_theme_font_size_override("font_size", 16)
	_info_title.add_theme_color_override("font_color", Color(0.98, 0.90, 0.72))
	_info_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_info_type = Label.new()
	_info_type.add_theme_font_size_override("font_size", 12)
	_info_type.add_theme_color_override("font_color", Color(0.72, 0.62, 0.45))

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
	panel.position = Vector2(0, 560)
	panel.size = Vector2(1280, 160)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.09, 0.07, 0.97)
	style.border_color = Color(0.55, 0.44, 0.28, 0.80)
	style.border_width_top = 2
	panel.add_theme_stylebox_override("panel", style)

	_hud_node_lbl = Label.new()
	_hud_node_lbl.position = Vector2(16, 8)
	_hud_node_lbl.size = Vector2(380, 38)
	_hud_node_lbl.add_theme_font_size_override("font_size", 26)
	_hud_node_lbl.add_theme_color_override("font_color", Color(0.97, 0.90, 0.72))

	var morale_lbl := Label.new()
	morale_lbl.position = Vector2(16, 52)
	morale_lbl.text = "МОРАЛЬ"
	morale_lbl.add_theme_font_size_override("font_size", 10)
	morale_lbl.add_theme_color_override("font_color", Color(0.58, 0.50, 0.38))

	var bar_bg := ColorRect.new()
	bar_bg.position = Vector2(16, 66)
	bar_bg.size = Vector2(200, 10)
	bar_bg.color = Color(0.08, 0.06, 0.04)

	_hud_morale_fill = ColorRect.new()
	_hud_morale_fill.position = Vector2(16, 66)
	_hud_morale_fill.size = Vector2(160, 10)
	_hud_morale_fill.color = Color(0.22, 0.62, 0.32)

	_hud_res_lbl = Label.new()
	_hud_res_lbl.position = Vector2(16, 84)
	_hud_res_lbl.size = Vector2(380, 28)
	_hud_res_lbl.add_theme_font_size_override("font_size", 13)
	_hud_res_lbl.add_theme_color_override("font_color", Color(0.78, 0.70, 0.55))

	panel.add_child(_hud_node_lbl)
	panel.add_child(morale_lbl)
	panel.add_child(bar_bg)
	panel.add_child(_hud_morale_fill)
	panel.add_child(_hud_res_lbl)

	_hud_panel = panel
	_build_unit_cards(panel)

	canvas.add_child(panel)
	add_child(canvas)

func _build_unit_cards(panel: Panel) -> void:
	var squad: Array = GameManager.squad
	var card_w: int = 140
	var card_h: int = 130
	var start_x: int = 420
	var gap: int = 12

	for i in range(mini(squad.size(), 6)):
		var unit: UnitData = squad[i]
		var cx: int = start_x + i * (card_w + gap)

		var card_bg := Panel.new()
		card_bg.position = Vector2(cx, 10)
		card_bg.size = Vector2(card_w, card_h)
		var card_style := StyleBoxFlat.new()
		card_style.bg_color = Color(0.08, 0.06, 0.04, 0.90)
		card_style.border_color = Color(0.45, 0.36, 0.22, 0.70)
		card_style.set_border_width_all(1)
		card_style.set_corner_radius_all(3)
		card_bg.add_theme_stylebox_override("panel", card_style)

		var name_lbl := Label.new()
		name_lbl.position = Vector2(8, 6)
		name_lbl.size = Vector2(card_w - 16, 20)
		name_lbl.text = unit.unit_name
		name_lbl.add_theme_font_size_override("font_size", 11)
		name_lbl.add_theme_color_override("font_color", Color(0.95, 0.88, 0.70))
		name_lbl.clip_text = true
		card_bg.add_child(name_lbl)

		var lvl_lbl := Label.new()
		lvl_lbl.position = Vector2(8, 26)
		lvl_lbl.size = Vector2(card_w - 16, 18)
		lvl_lbl.text = "Ур. %d" % unit.level
		lvl_lbl.add_theme_font_size_override("font_size", 10)
		lvl_lbl.add_theme_color_override("font_color", Color(0.72, 0.82, 0.42))
		card_bg.add_child(lvl_lbl)

		var stats_lbl := Label.new()
		stats_lbl.position = Vector2(8, 44)
		stats_lbl.size = Vector2(card_w - 16, 18)
		stats_lbl.text = "АТК %d" % unit.atk
		stats_lbl.add_theme_font_size_override("font_size", 10)
		stats_lbl.add_theme_color_override("font_color", Color(0.85, 0.55, 0.38))
		card_bg.add_child(stats_lbl)

		var hp_caption := Label.new()
		hp_caption.position = Vector2(8, 62)
		hp_caption.text = "HP"
		hp_caption.add_theme_font_size_override("font_size", 9)
		hp_caption.add_theme_color_override("font_color", Color(0.55, 0.48, 0.38))
		card_bg.add_child(hp_caption)

		var hp_bg := ColorRect.new()
		hp_bg.position = Vector2(8, 76)
		hp_bg.size = Vector2(card_w - 16, 8)
		hp_bg.color = Color(0.06, 0.04, 0.03)
		card_bg.add_child(hp_bg)

		var hp_pct: float = clampf(float(unit.hp) / float(maxi(unit.hp_max, 1)), 0.0, 1.0)
		var hp_fill := ColorRect.new()
		hp_fill.position = Vector2(8, 76)
		hp_fill.size = Vector2((card_w - 16) * hp_pct, 8)
		hp_fill.color = \
			Color(0.22, 0.70, 0.30) if hp_pct > 0.5 else \
			Color(0.72, 0.55, 0.10) if hp_pct > 0.25 else \
			Color(0.75, 0.18, 0.14)
		card_bg.add_child(hp_fill)

		var hp_lbl := Label.new()
		hp_lbl.position = Vector2(8, 88)
		hp_lbl.size = Vector2(card_w - 16, 16)
		hp_lbl.text = "%d / %d" % [unit.hp, unit.hp_max]
		hp_lbl.add_theme_font_size_override("font_size", 10)
		hp_lbl.add_theme_color_override("font_color", Color(0.70, 0.62, 0.50))
		card_bg.add_child(hp_lbl)

		if not unit.is_alive:
			var dead_overlay := ColorRect.new()
			dead_overlay.position = Vector2(0, 0)
			dead_overlay.size = Vector2(card_w, card_h)
			dead_overlay.color = Color(0.0, 0.0, 0.0, 0.65)
			card_bg.add_child(dead_overlay)
			var dead_lbl := Label.new()
			dead_lbl.position = Vector2(8, 54)
			dead_lbl.size = Vector2(card_w - 16, 20)
			dead_lbl.text = "ПАВШИЙ"
			dead_lbl.add_theme_font_size_override("font_size", 11)
			dead_lbl.add_theme_color_override("font_color", Color(0.80, 0.18, 0.14))
			card_bg.add_child(dead_lbl)

		panel.add_child(card_bg)
		_unit_cards.append(card_bg)

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
				draw_line(from, to, Color(0.22, 0.16, 0.09, 0.95), 8.0, true)
				draw_line(from, to, Color(0.68, 0.54, 0.32, 0.88), 5.0, true)
				draw_line(from, to, Color(0.88, 0.78, 0.55, 0.35), 2.0, true)
			else:
				_draw_dashed(from, to, Color(0.32, 0.24, 0.14, 0.65), 2.5)

func _draw_dashed(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var dash: float = 10.0
	var gap: float = 7.0
	var dir: Vector2 = (to - from).normalized()
	var dist: float = from.distance_to(to)
	var t: float = 0.0
	while t < dist:
		draw_line(from + dir * t, from + dir * minf(t + dash, dist), color, width, true)
		t += dash + gap

func _draw_squad_marker() -> void:
	var pos: Vector2 = _squad_draw_pos
	var d: float = 14.0
	draw_circle(pos, d + 5.0, Color(1.0, 0.85, 0.20, 0.15))
	var shadow_pts := PackedVector2Array([
		pos + Vector2(2, d + 2), pos + Vector2(d + 2, 2),
		pos + Vector2(2, -d + 2), pos + Vector2(-d + 2, 2),
	])
	draw_colored_polygon(shadow_pts, Color(0, 0, 0, 0.40))
	var pts := PackedVector2Array([
		pos + Vector2(0, -d), pos + Vector2(d, 0),
		pos + Vector2(0, d),  pos + Vector2(-d, 0),
	])
	draw_colored_polygon(pts, Color(1.0, 0.88, 0.18, 0.95))
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]),
		Color(1.0, 1.0, 1.0, 0.85), 1.8, true)
	draw_circle(pos, 4.0, Color(0.50, 0.28, 0.0, 1.0))
	draw_circle(pos, 2.0, Color(1.0, 0.72, 0.18, 1.0))

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
		_hud_morale_fill.size.x = 200.0 * clampf(morale / 100.0, 0.0, 1.0)
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

func _on_squad_updated() -> void:
	if not _hud_panel:
		return
	for card in _unit_cards:
		card.queue_free()
	_unit_cards.clear()
	_build_unit_cards(_hud_panel)

func _on_morale_changed(new_value: int) -> void:
	if _hud_morale_fill:
		_hud_morale_fill.size.x = 200.0 * clampf(new_value / 100.0, 0.0, 1.0)
		_hud_morale_fill.color = \
			Color(0.22, 0.62, 0.32) if new_value > 60 else \
			Color(0.72, 0.52, 0.10) if new_value > 30 else \
			Color(0.72, 0.18, 0.14)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _type_label(t: NodeData.NodeType) -> String:
	match t:
		NodeData.NodeType.TEMPLE: return "Храм"
		NodeData.NodeType.CITY:   return "Город"
		NodeData.NodeType.CAMP:   return "Лагерь"
		NodeData.NodeType.OASIS:  return "Оазис"
		_: return "Руины"
