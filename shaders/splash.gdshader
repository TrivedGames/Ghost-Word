shader_type canvas_item;

uniform float burn_progress : hint_range(0.0, 1.0) = 0.0; // 0 = intact, 1 = fully burned (based on burn_radius & spread)
uniform vec2 burn_center = vec2(0.5, 0.5); // normalized uv (0..1) where burn originates
uniform float burn_radius = 0.05; // initial core radius
uniform float burn_spread = 0.9; // how far the burn can expand with progress
uniform float edge_width = 0.03; // softness of the char edge
uniform float noise_scale = 18.0; // scale of the noise
uniform float noise_speed = 0.7; // how fast edge noise animates
uniform vec3 char_color = vec3(0.04, 0.03, 0.02); // char (black) tint
uniform vec3 ember_color = vec3(1.0, 0.45, 0.15); // ember glow color
uniform float ember_intensity = 0.9; // intensity of ember glow
uniform float time : hint_range(0.0, 1000.0) = 0.0;

// --- simple hash / noise / fbm (2D) ---
float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
    // four corners
	float a = hash21(i + vec2(0.0,0.0));
	float b = hash21(i + vec2(1.0,0.0));
	float c = hash21(i + vec2(0.0,1.0));
	float d = hash21(i + vec2(1.0,1.0));
	vec2 u = f*f*(3.0-2.0*f);
	return mix(a, b, u.x) + (c - a)*u.y*(1.0 - u.x) + (d - b)*u.x*u.y;
}
float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	mat2 rot = mat2(vec2(1.6, 1.2), vec2(-1.2, 1.6));
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p = rot * (p * 1.9 + 0.37);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 uv = UV;
    // Sample base color (works for ColorRect — COLOR holds the ColorRect color)
	vec4 base = texture(TEXTURE, uv) * COLOR;

    // compute distance from burn center (normalized by rect)
	float d = distance(uv, burn_center);

    // radius grows with progress
	float radius = burn_radius + burn_progress * (burn_spread + 0.0);

    // procedural noisy edge
	float n = fbm(uv * noise_scale + vec2(time * noise_speed, time * noise_speed * 0.7));
    // normalize fbm to -0.5..0.5
	float n_jitter = (n - 0.5) * 0.18;

    // jittered threshold (so the edge is ragged)
	float threshold = radius + n_jitter;

    // burned core mask (1 = burned, 0 = intact), softened
	float burned_core = 1.0 - smoothstep(threshold - edge_width*0.8, threshold + edge_width*0.5, d);

    // char edge mask (0..1) where we apply char color / embe
	float char_mask = smoothstep(threshold - edge_width*1.5, threshold + edge_width*0.5, d);
    char_mask = clamp(char_mask * (burn_progress * 1.5), 0.0, 1.0);

    // ember flicker (depends on noise & time)
	float ember_noise = fbm((uv + 23.1) * noise_scale * 0.6 + vec2(time*2.0, time*2.7));
	float ember = pow(max(0.0, 1.0 - d / (radius + 0.4)), 2.0) * ember_noise;
	ember *= smoothstep(0.02, 1.0, char_mask) * ember_intensity * burn_progress;
    // tiny flicker
	ember *= 0.6 + 0.4 * sin(time * 30.0 + n * 10.0);

    // final color mixing: base -> char_color near edges, full charcoal inside burned core
	vec3 char_mix = mix(base.rgb, char_color, char_mask);
    // add ember glow (subtle)
	vec3 final_rgb = mix(char_mix, ember_color + char_color * 0.2, ember * 0.9);

    // final alpha: reduce alpha inside burned core (make disappear)
	float final_alpha = mix(base.a, 0.0, burned_core);

    // hard discard tiny fragments to remove dead pixels
	if (final_alpha <= 0.02) {
		discard;
	}
	
	COLOR = vec4(final_rgb, final_alpha);
}
