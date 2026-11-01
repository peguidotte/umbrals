shader_type canvas_item;
render_mode unshaded;

uniform float clock = 0.0;
uniform float motion = 0.0;
uniform float pulse_age = 10.0;
uniform vec2 pulse_origin = vec2(0.7, 0.55);
uniform int selected_menu = 0;
varying highp vec2 image_uv;

void vertex() {
	image_uv = UV;
}

float rect_mask(vec2 p, vec4 r) {
	return step(r.x, p.x) * step(r.y, p.y) * step(p.x, r.z) * step(p.y, r.w);
}

void fragment() {
	highp vec2 uv = image_uv;
	// Light lives in the original artwork. The tiny refraction stays on its cards.
	float field = smoothstep(0.43, 0.58, uv.x) * (1.0 - smoothstep(0.84, 0.91, uv.y));
	float breathe = sin(clock * 1.15) * sin(clock * 0.37);
	uv.y += motion * field * sin(uv.x * 15.0 + clock * 0.65) * breathe * 0.0007;
	vec4 ink = texture(TEXTURE, uv);
	float warm = smoothstep(0.13, 0.42, ink.r - ink.b) * smoothstep(0.38, 0.85, ink.r);
	float sweep = pow(max(0.0, sin(uv.x * 8.0 + uv.y * 4.0 - clock * 1.6)), 18.0);
	ink.rgb += vec3(0.13, 0.065, 0.025) * motion * field * warm * sweep;
	// A touch awakens an expanding, short-lived magical reflection, never gameplay.
	vec2 distance_uv = (image_uv - pulse_origin) * vec2(1.777, 1.0);
	float radius = pulse_age * 0.24;
	float ring = (1.0 - smoothstep(0.005, 0.024, abs(length(distance_uv) - radius))) * max(0.0, 1.0 - pulse_age / 1.5);
	ink.rgb += motion * field * ring * vec3(0.19, 0.09, 0.025);
	for (int i = 0; i < 7; i++) {
		float seed = float(i);
		float life = fract(clock * (0.11 + seed * 0.009) + seed * 0.143);
		vec2 point = vec2(0.48 + seed * 0.067 + sin(life * 5.0 + seed) * 0.025, 0.79 - life * 0.44);
		vec2 d = (image_uv - point) * vec2(1.777, 1.0);
		float spark = (1.0 - smoothstep(0.0008, 0.003, length(d))) * sin(life * 3.14159);
		ink.rgb += motion * spark * vec3(0.38, 0.17, 0.035);
	}
	COLOR = ink;
}
