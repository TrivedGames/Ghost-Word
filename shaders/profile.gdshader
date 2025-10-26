shader_type canvas_item;

uniform sampler2D Textr: source_color;

void fragment() {
	COLOR = texture(Textr,UV);
}

