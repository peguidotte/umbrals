shader_type canvas_item;
uniform float phase = 0.0;
uniform bool moving = true;
uniform float water_start = 0.59;
uniform float sky_fraction = 0.26;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
    vec2 scene_uv = UV;
    scene_uv.y = UV.y < sky_fraction ? UV.y / sky_fraction * 0.26 : 0.26 + (UV.y - sky_fraction) / (1.0 - sky_fraction) * 0.74;
    vec4 original = texture(TEXTURE, scene_uv);
    float water = smoothstep(water_start, water_start + 0.08, scene_uv.y)
        * step(original.r * 1.12, original.b) * step(original.g * 0.98, original.b)
        * step(0.35, original.g);
    vec2 flow = moving ? vec2(sin(scene_uv.y * 140.0 - phase * 1.6) * 0.0008, 0.0) * water : vec2(0.0);
    COLOR = texture(TEXTURE, clamp(scene_uv + flow, vec2(0.0), vec2(1.0))) * tint;
}
