shader_type canvas_item;

void fragment() {
	vec2 uv = UV * 2.0 - 1.0;
	uv.x *= 1.45;
	float d = length(uv);
	float v = smoothstep(0.50, 1.30, d);
	COLOR = vec4(0.01, 0.008, 0.005, v * 0.78);
}
