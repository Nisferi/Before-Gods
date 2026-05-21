class_name MapNodeVisual
extends Node2D

var node_id: String = ""
var node_type: NodeData.NodeType = NodeData.NodeType.RUINS
var display_name: String = ""
var is_current: bool = false
var is_reachable: bool = false
var is_visited: bool = false

var _pulse_t: float = 0.0

func _process(delta: float) -> void:
	if is_reachable or is_current:
		_pulse_t += delta * 2.5
		queue_redraw()

func get_radius() -> int:
	match node_type:
		NodeData.NodeType.TEMPLE: return 42
		NodeData.NodeType.CITY:   return 38
		NodeData.NodeType.CAMP:   return 32
		_: return 30

func _fog() -> float:
	return 1.0 if (is_visited or is_current) else 0.22

func _draw() -> void:
	var fog: float = _fog()
	match node_type:
		NodeData.NodeType.TEMPLE: _draw_temple(fog)
		NodeData.NodeType.CITY:   _draw_city(fog)
		NodeData.NodeType.CAMP:   _draw_camp(fog)
		NodeData.NodeType.OASIS:  _draw_oasis(fog)
		_:                        _draw_ruins(fog)
	_draw_selection_ring(fog)
	_draw_label(fog)

# ── Temple — stepped pyramid ──────────────────────────────────────────────────

func _draw_temple(fog: float) -> void:
	var base_c  := Color(0.52, 0.28, 0.12, fog)
	var stone_c := Color(0.72, 0.55, 0.32, fog)
	var accent_c := Color(0.90, 0.72, 0.30, fog)
	draw_colored_polygon(
		PackedVector2Array([Vector2(-38,14), Vector2(38,14), Vector2(42,22), Vector2(-42,22)]),
		Color(0, 0, 0, 0.35 * fog))
	draw_colored_polygon(
		PackedVector2Array([Vector2(-38,12), Vector2(38,12), Vector2(34,2), Vector2(-34,2)]),
		base_c)
	draw_polyline(
		PackedVector2Array([Vector2(-38,12), Vector2(38,12), Vector2(34,2), Vector2(-34,2), Vector2(-38,12)]),
		stone_c, 1.2, true)
	draw_colored_polygon(
		PackedVector2Array([Vector2(-26,2), Vector2(26,2), Vector2(22,-8), Vector2(-22,-8)]),
		Color(stone_c.r + 0.06, stone_c.g + 0.04, stone_c.b, fog))
	draw_polyline(
		PackedVector2Array([Vector2(-26,2), Vector2(26,2), Vector2(22,-8), Vector2(-22,-8), Vector2(-26,2)]),
		stone_c, 1.2, true)
	draw_colored_polygon(
		PackedVector2Array([Vector2(-14,-8), Vector2(14,-8), Vector2(10,-18), Vector2(-10,-18)]),
		Color(stone_c.r + 0.10, stone_c.g + 0.08, stone_c.b + 0.02, fog))
	draw_polyline(
		PackedVector2Array([Vector2(-14,-8), Vector2(14,-8), Vector2(10,-18), Vector2(-10,-18), Vector2(-14,-8)]),
		accent_c, 1.0, true)
	if is_visited or is_current:
		draw_circle(Vector2(0, -22), 4.0, Color(1.0, 0.85, 0.20, 0.80 * fog))
		draw_circle(Vector2(0, -22), 2.5, Color(1.0, 1.0, 0.60, 0.95 * fog))

# ── City — walls with towers ──────────────────────────────────────────────────

func _draw_city(fog: float) -> void:
	var wall_c := Color(0.60, 0.50, 0.35, fog)
	var dark_c := Color(0.30, 0.24, 0.16, fog)
	var roof_c := Color(0.65, 0.22, 0.14, fog)
	draw_rect(Rect2(Vector2(-32, 8), Vector2(64, 8)), Color(0, 0, 0, 0.30 * fog), true)
	draw_rect(Rect2(Vector2(-30, -8), Vector2(60, 20)), wall_c, true)
	draw_rect(Rect2(Vector2(-30, -8), Vector2(60, 20)), dark_c, false, 1.5)
	for i in range(-24, 28, 8):
		draw_rect(Rect2(Vector2(i, -14), Vector2(5, 8)), wall_c, true)
		draw_rect(Rect2(Vector2(i, -14), Vector2(5, 8)), dark_c, false, 1.0)
	draw_rect(Rect2(Vector2(-34, -16), Vector2(14, 28)),
		Color(wall_c.r - 0.05, wall_c.g - 0.04, wall_c.b - 0.03, fog), true)
	draw_rect(Rect2(Vector2(-34, -16), Vector2(14, 28)), dark_c, false, 1.5)
	draw_colored_polygon(
		PackedVector2Array([Vector2(-34, -16), Vector2(-20, -16), Vector2(-27, -28)]), roof_c)
	draw_rect(Rect2(Vector2(20, -16), Vector2(14, 28)),
		Color(wall_c.r - 0.05, wall_c.g - 0.04, wall_c.b - 0.03, fog), true)
	draw_rect(Rect2(Vector2(20, -16), Vector2(14, 28)), dark_c, false, 1.5)
	draw_colored_polygon(
		PackedVector2Array([Vector2(20, -16), Vector2(34, -16), Vector2(27, -28)]), roof_c)
	draw_rect(Rect2(Vector2(-7, -4), Vector2(14, 16)), dark_c, true)
	draw_arc(Vector2(0, -4), 7, PI, TAU, 16, dark_c, 8.0, true)

# ── Camp — tent + fire ────────────────────────────────────────────────────────

func _draw_camp(fog: float) -> void:
	var canvas_c := Color(0.65, 0.55, 0.35, fog)
	var dark_c   := Color(0.28, 0.20, 0.12, fog)
	var fire_c   := Color(0.95, 0.52, 0.10, fog)
	draw_colored_polygon(
		PackedVector2Array([Vector2(-28, 14), Vector2(28, 14), Vector2(22, 18), Vector2(-22, 18)]),
		Color(0, 0, 0, 0.28 * fog))
	draw_colored_polygon(
		PackedVector2Array([Vector2(-26, 12), Vector2(26, 12), Vector2(0, -22)]),
		canvas_c)
	draw_polyline(
		PackedVector2Array([Vector2(-26, 12), Vector2(26, 12), Vector2(0, -22), Vector2(-26, 12)]),
		dark_c, 1.8, true)
	draw_line(Vector2(0, -22), Vector2(0, 12),
		Color(dark_c.r + 0.1, dark_c.g + 0.08, dark_c.b + 0.05, fog * 0.6), 1.0)
	draw_colored_polygon(
		PackedVector2Array([Vector2(-8, 12), Vector2(8, 12), Vector2(0, -4)]),
		Color(dark_c.r, dark_c.g, dark_c.b, fog * 0.55))
	if is_visited or is_current:
		draw_circle(Vector2(18, 10), 6.0, Color(fire_c.r, fire_c.g * 0.4, 0.0, 0.25 * fog))
		draw_colored_polygon(
			PackedVector2Array([Vector2(15, 12), Vector2(21, 12), Vector2(20, 5), Vector2(18, 3), Vector2(16, 5)]),
			fire_c)
		draw_colored_polygon(
			PackedVector2Array([Vector2(16, 8), Vector2(20, 8), Vector2(18, 3)]),
			Color(1.0, 0.85, 0.20, fog))

# ── Oasis — water pool + palm ─────────────────────────────────────────────────

func _draw_oasis(fog: float) -> void:
	var water_c := Color(0.14, 0.48, 0.58, fog)
	var sand_c  := Color(0.72, 0.60, 0.38, fog)
	var leaf_c  := Color(0.20, 0.52, 0.18, fog)
	var trunk_c := Color(0.42, 0.28, 0.12, fog)
	draw_circle(Vector2(2, 6), 22.0, Color(0, 0, 0, 0.22 * fog))
	draw_circle(Vector2(0, 4), 22.0, sand_c)
	draw_circle(Vector2(-4, 8), 13.0, water_c)
	draw_arc(Vector2(-4, 8), 13.0, 0, TAU, 32,
		Color(0.5, 0.8, 0.9, 0.5 * fog), 1.5, true)
	draw_line(Vector2(6, 12), Vector2(4, -14), trunk_c, 3.0, true)
	for angle in [-0.9, -0.45, 0.0, 0.45, 0.9]:
		var tip := Vector2(4, -14) + Vector2(cos(angle - PI / 2.0), sin(angle - PI / 2.0)) * 18.0
		draw_line(Vector2(4, -14), tip, leaf_c, 2.5, true)
		draw_circle(tip, 3.0, Color(leaf_c.r + 0.1, leaf_c.g + 0.1, leaf_c.b, fog))

# ── Ruins — broken arch ───────────────────────────────────────────────────────

func _draw_ruins(fog: float) -> void:
	var stone_c := Color(0.50, 0.44, 0.35, fog)
	var dark_c  := Color(0.26, 0.22, 0.17, fog)
	draw_rect(Rect2(Vector2(-26, 10), Vector2(52, 6)), Color(0, 0, 0, 0.25 * fog), true)
	draw_rect(Rect2(Vector2(-24, -18), Vector2(10, 28)), stone_c, true)
	draw_rect(Rect2(Vector2(-24, -18), Vector2(10, 28)), dark_c, false, 1.2)
	draw_colored_polygon(
		PackedVector2Array([Vector2(-26, -18), Vector2(-12, -18), Vector2(-14, -24), Vector2(-22, -26)]),
		Color(stone_c.r + 0.06, stone_c.g + 0.05, stone_c.b + 0.04, fog))
	draw_rect(Rect2(Vector2(14, -8), Vector2(10, 18)), stone_c, true)
	draw_rect(Rect2(Vector2(14, -8), Vector2(10, 18)), dark_c, false, 1.2)
	draw_colored_polygon(
		PackedVector2Array([Vector2(14, -8), Vector2(24, -8), Vector2(22, -14),
			Vector2(20, -10), Vector2(17, -16), Vector2(15, -11)]),
		Color(stone_c.r + 0.04, stone_c.g + 0.03, stone_c.b + 0.02, fog))
	draw_rect(Rect2(Vector2(-6, 4), Vector2(16, 8)),
		Color(stone_c.r - 0.04, stone_c.g - 0.04, stone_c.b - 0.03, fog), true)
	draw_rect(Rect2(Vector2(-6, 4), Vector2(16, 8)), dark_c, false, 1.0)
	for p in [Vector2(-18, 12), Vector2(0, 14), Vector2(10, 11), Vector2(-8, 10)]:
		draw_circle(p, 2.0, Color(stone_c.r, stone_c.g, stone_c.b, fog * 0.7))

# ── Selection ring ────────────────────────────────────────────────────────────

func _draw_selection_ring(fog: float) -> void:
	var r := float(get_radius()) + 6.0
	if is_current:
		var p := sin(_pulse_t * 1.5) * 0.5 + 0.5
		draw_arc(Vector2.ZERO, r, 0, TAU, 48,
			Color(1.0, 1.0, 1.0, lerpf(0.70, 1.0, p)), 2.5, true)
		draw_arc(Vector2.ZERO, r + 4.0, 0, TAU, 48,
			Color(1.0, 0.92, 0.50, lerpf(0.20, 0.45, p)), 1.5, true)
	elif is_reachable:
		var p := sin(_pulse_t) * 0.5 + 0.5
		draw_arc(Vector2.ZERO, r, 0, TAU, 48,
			Color(1.0, 0.82, 0.18, lerpf(0.45, 0.95, p)), 2.5, true)
	elif fog < 0.5:
		draw_arc(Vector2.ZERO, r, 0, TAU, 32,
			Color(0.35, 0.30, 0.24, 0.18), 1.2, true)

# ── Name label ────────────────────────────────────────────────────────────────

func _draw_label(fog: float) -> void:
	if fog < 0.10:
		return
	var font: Font = ThemeDB.fallback_font
	var fs: int = 12
	var tw: float = font.get_string_size(display_name,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var ly: float = float(get_radius()) + 20.0
	draw_rect(
		Rect2(Vector2(-tw / 2.0 - 5, ly - fs), Vector2(tw + 10, fs + 6)),
		Color(0.10, 0.08, 0.06, 0.72 * fog), true)
	draw_rect(
		Rect2(Vector2(-tw / 2.0 - 5, ly - fs), Vector2(tw + 10, fs + 6)),
		Color(0.55, 0.45, 0.28, 0.40 * fog), false, 0.8)
	draw_string(font, Vector2(-tw / 2.0, ly),
		display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
		Color(0.95, 0.88, 0.70, fog))
