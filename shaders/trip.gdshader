shader_type canvas_item;
// Effetto a schermo intero per "sballo" (hue shift + onde) e "follia" (rosso + tremolio).

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float trip = 0.0;      // 0..1 funghetti
uniform float madness = 0.0;   // 0..1 follia
uniform float drunk = 0.0;     // 0..1 sbronza (sdoppiamento)

vec3 hue_shift(vec3 c, float a) {
	const vec3 k = vec3(0.57735);
	float ca = cos(a);
	return c * ca + cross(k, c) * sin(a) + k * dot(k, c) * (1.0 - ca);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	uv.x += sin(uv.y * 24.0 + TIME * 4.0) * 0.006 * trip;
	uv.y += cos(uv.x * 18.0 + TIME * 3.0) * 0.004 * trip;
	uv += vec2(sin(TIME * 40.0), cos(TIME * 37.0)) * 0.003 * madness;
	vec3 c = texture(screen_tex, uv).rgb;
	if (drunk > 0.0) {
		vec3 ghost = texture(screen_tex, uv + vec2(0.012 * sin(TIME * 1.7), 0.0)).rgb;
		c = mix(c, ghost, 0.4 * drunk);
	}
	c = mix(c, hue_shift(c, TIME * 2.5), trip);
	c = mix(c, vec3(dot(c, vec3(0.5, 0.3, 0.2)) * 1.4, c.g * 0.4, c.b * 0.4), madness * 0.7);
	COLOR = vec4(c, 1.0);
}
