// Kare avatarı yuvarlak keser ve sahibinin rengiyle çerçeveler.
shader_type canvas_item;

uniform vec4 ring_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float ring_width = 0.09;

void fragment() {
	float r = length(UV - vec2(0.5));
	if (r > 0.5) {
		discard;
	}
	if (r > 0.5 - ring_width) {
		COLOR = ring_color;
	}
}
