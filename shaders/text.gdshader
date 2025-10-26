shader_type canvas_item;

uniform vec4 fill_color : source_color = vec4(0.0, 0.7, 0.8, 1.0);
uniform vec4 outline_color : source_color = vec4(0.0, 0.3, 0.4, 1.0);
uniform float outline_size = 1.5;
uniform float gloss_intensity = 0.7;
uniform vec2 light_dir = vec2(-0.5, -0.8);

void fragment() {
	vec4 base_tex = texture(TEXTURE, UV);
	float alpha = base_tex.a;
	float outline = 0.0;
	for (float x = -1.0; x <= 1.0; x++) {
		for (float y = -1.0; y <= 1.0; y++) {
			vec2 offset = vec2(x, y) * (outline_size / 300.0);
			outline = max(outline, texture(TEXTURE, UV + offset).a);
		}
	}
	vec4 col = mix(outline_color, fill_color, alpha);
	vec2 grad = vec2(dFdx(alpha), dFdy(alpha));
	float light = clamp(dot(normalize(light_dir), normalize(vec2(-grad.y, grad.x))), 0.0, 1.0);
	float gloss = pow(light, 20.0) * gloss_intensity;
	
	col.rgb += gloss;
	col.a = max(alpha, outline);
	COLOR = col;
}
