// Fond animé façon carte d'état-major : courbes de niveau + quadrillage.
shader_type canvas_item;

uniform vec4 base_color : source_color = vec4(0.08, 0.09, 0.06, 1.0);
uniform vec4 line_color : source_color = vec4(0.22, 0.26, 0.17, 1.0);
uniform float scale = 2.4;
uniform float speed = 0.006;
uniform float aspect = 1.7778;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
			mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV * vec2(aspect, 1.0);
	float h = fbm(uv * scale + vec2(TIME * speed, TIME * speed * 0.4));
	float c = h * 14.0;
	float d = min(fract(c), 1.0 - fract(c));
	float w = fwidth(c);
	float contour = 1.0 - smoothstep(0.0, w * 1.4, d);
	float major = step(4.5, mod(floor(c + 0.5), 5.0));
	vec2 g = abs(fract(uv * 8.0) - 0.5);
	float gw = fwidth(uv.x * 8.0);
	float grid = 1.0 - smoothstep(0.0, gw * 1.2, 0.5 - max(g.x, g.y));
	vec3 col = base_color.rgb;
	col = mix(col, line_color.rgb, contour * (0.35 + 0.45 * major));
	col = mix(col, line_color.rgb, grid * 0.18);
	vec2 v = UV - 0.5;
	col *= 1.0 - dot(v, v) * 1.1;
	COLOR = vec4(col, 1.0);
}
