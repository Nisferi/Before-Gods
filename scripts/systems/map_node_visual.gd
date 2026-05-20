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
	if is_reachable:
		_pulse_t += delta * 3.0
		queue_redraw()

func get_radius() -> int:
	match node_type:
		NodeData.NodeType.TEMPLE: return 38
		NodeData.NodeType.CITY:   return 34
		NodeData.NodeType.CAMP:   return 30
		_: return 26

func _get_fill() -> Color:
	match node_type:
		NodeData.NodeType.TEMPLE: return Color(0.40, 0.10, 0.50)
		NodeData.NodeType.CITY:   return Color(0.50, 0.36, 0.06)
		NodeData.NodeType.CAMP:   return Color(0.10, 0.40, 0.16)
		NodeData.NodeType.OASIS:  return Color(0.06, 0.36, 0.46)
		_: return Color(0.30, 0.23, 0.18)

func _get_symbol() -> String:
	match node_type:
		NodeData.NodeType.TEMPLE: return "T"
		NodeData.NodeType.CITY:   return "C"
		NodeData.NodeType.CAMP:   return "^"
		NodeData.NodeType.OASIS:  return "~"
		_: return "R"

func _draw() -> void:
	var r: float = float(get_radius())
	var fill: Color = _get_fill()
	var fog_a: float = 1.0 if (is_visited or is_current) else 0.18

	# Shadow
	draw_circle(Vector2(3, 5), r + 3.0, Color(0, 0, 0, 0.55 * fog_a))

	# Fill
	draw_circle(Vector2.ZERO, r, Color(fill.r, fill.g, fill.b, fog_a))

	# Inner highlight (top-left)
	draw_circle(Vector2(-r * 0.28, -r * 0.28), r * 0.28,
		Color(1, 1, 1, 0.11 * fog_a))

	# Outline
	var ow: float
	var oc: Color
	if is_current:
		ow = 3.5
		oc = Color(1, 1, 1, 0.95)
	elif is_reachable:
		var p: float = sin(_pulse_t) * 0.5 + 0.5
		ow = 3.0
		oc = Color(1.0, 0.88, 0.22, lerpf(0.50, 1.0, p))
	else:
		ow = 2.0
		oc = Color(0.55, 0.50, 0.44, 0.40 * fog_a)
	draw_arc(Vector2.ZERO, r, 0, TAU, 48, oc, ow, true)

	# Symbol inside
	if is_visited or is_current:
		var font: Font = ThemeDB.fallback_font
		var sym: String = _get_symbol()
		var fs: int = 14
		var sw: float = font.get_string_size(sym, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, Vector2(-sw / 2.0, 5.0), sym,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.82 * fog_a))

	# Name label below
	if fog_a > 0.05:
		var font: Font = ThemeDB.fallback_font
		var fs: int = 12
		var tw: float = font.get_string_size(display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var ly: float = r + 18.0
		draw_rect(Rect2(Vector2(-tw / 2.0 - 4, ly - fs - 1), Vector2(tw + 8, fs + 5)),
			Color(0, 0, 0, 0.62 * fog_a), true)
		draw_string(font, Vector2(-tw / 2.0, ly),
			display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs,
			Color(0.95, 0.90, 0.78, fog_a))
