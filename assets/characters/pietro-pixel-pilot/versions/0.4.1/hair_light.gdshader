shader_type canvas_item;
render_mode unshaded;

uniform float softness : hint_range(0.0, 1.0) = 0.65;

void fragment() {
	vec4 pixel = COLOR;
	vec2 p = UV * vec2(1254.0);
	// UV-space selection follows the head while the rig moves. The face and
	// scarf are excluded; the material belongs only to the Pietro draw node.
	bool head = p.x > 475.0 && p.x < 790.0 && p.y > 100.0 && p.y < 345.0;
	bool hair_edge = p.y < 246.0 || p.x < 554.0 || p.x > 753.0;
	// Include the golden edge while retaining the darker shading of the curls.
	bool golden = pixel.r > 0.80 && pixel.g > 0.50 && pixel.g < pixel.r * 0.92 && pixel.b < pixel.r * 0.66;
	if (head && hair_edge && golden) {
		pixel.rgb = mix(pixel.rgb, vec3(0.50, 0.31, 0.18), softness);
	}
	COLOR = pixel;
}
